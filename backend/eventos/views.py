import json
from datetime import datetime

from django.contrib.auth.models import User
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from comunidades.models import Comunidad
from .models import Evento

def responder(datos, status=200):
    return JsonResponse(datos, status=status, json_dumps_params={'ensure_ascii': False})


def obtener_cuerpo(request):
    """Parsea el body JSON de la petición; devuelve {} si viene vacío o inválido."""
    try:
        return json.loads(request.body or '{}')
    except json.JSONDecodeError:
        return {}


def obtener_gestor(request, cuerpo=None):
    """Devuelve el usuario gestor que envía la petición.

    Igual que 'obtener_estudiante' en comunidades: el id llega en el cuerpo
    o en la URL porque la autenticación/roles todavía no está implementada
    como infraestructura compartida.
    """
    cuerpo = cuerpo if cuerpo is not None else obtener_cuerpo(request)
    gestor_id = cuerpo.get('gestor_id') or request.GET.get('gestor_id')
    try:
        return User.objects.filter(id=int(gestor_id)).first()
    except (TypeError, ValueError):
        return None


def es_gestor(usuario, comunidad):
    """Solo un gestor autorizado puede crear, editar o cancelar eventos de su comunidad."""
    return usuario is not None and comunidad.gestores.filter(id=usuario.id).exists()


def evento_a_dict(evento):
    return {
        'id': evento.id,
        'titulo': evento.titulo,
        'descripcion': evento.descripcion,
        'comunidad': evento.comunidad_id,
        'comunidad_nombre': evento.comunidad.nombre,
        'fecha': evento.fecha.isoformat(),
        'hora': evento.hora.strftime('%H:%M'),
        'lugar': evento.lugar,
        'cupo': evento.cupo,
        'estado': evento.estado,
        'gestor': evento.gestor_id,
    }


def _parsear_fecha(valor):
    try:
        return datetime.strptime(valor, '%Y-%m-%d').date()
    except (TypeError, ValueError):
        return None


def _parsear_hora(valor):
    for formato in ('%H:%M', '%H:%M:%S'):
        try:
            return datetime.strptime(valor, formato).time()
        except (TypeError, ValueError):
            continue
    return None


@csrf_exempt
def eventos(request):
    """RF-03 (GET): listar próximos eventos, con filtro por comunidad o fecha.
    RF-04 (POST): crear un evento nuevo (gestor)."""

    if request.method == 'GET':
        return _listar_eventos(request)

    if request.method == 'POST':
        return _crear_evento(request)

    return responder({'error': 'Método no permitido'}, status=405)


def _listar_eventos(request):
    """RF-03: lista los próximos eventos activos, filtrando por comunidad y/o fecha."""
    queryset = Evento.objects.filter(estado=Evento.ACTIVO)

    comunidad_id = request.GET.get('comunidad', '').strip()
    if comunidad_id:
        try:
            queryset = queryset.filter(comunidad_id=int(comunidad_id))
        except ValueError:
            return responder({'error': 'comunidad debe ser un id numérico'}, status=400)

    fecha_texto = request.GET.get('fecha', '').strip()
    if fecha_texto:
        fecha = _parsear_fecha(fecha_texto)
        if fecha is None:
            return responder({'error': 'fecha debe tener el formato YYYY-MM-DD'}, status=400)
        queryset = queryset.filter(fecha=fecha)
    else:
        # Sin fecha específica, "próximos eventos" son los de hoy en adelante.
        queryset = queryset.filter(fecha__gte=datetime.now().date())

    resultados = [evento_a_dict(evento) for evento in queryset]
    return responder({'total': len(resultados), 'eventos': resultados})


def _crear_evento(request):
    """RF-04: el gestor crea un evento con título, descripción, fecha, hora,
    lugar y cupo opcional."""
    cuerpo = obtener_cuerpo(request)

    gestor = obtener_gestor(request, cuerpo)
    if gestor is None:
        return responder({'error': 'Debe enviar un gestor_id válido'}, status=400)

    comunidad_id = cuerpo.get('comunidad_id')
    comunidad = Comunidad.objects.filter(id=comunidad_id, activa=True).first()
    if comunidad is None:
        return responder({'error': 'La comunidad no existe o no está activa'}, status=404)

    if not es_gestor(gestor, comunidad):
        return responder({'error': f'No es gestor de {comunidad.nombre}'}, status=403)

    titulo = (cuerpo.get('titulo') or '').strip()
    descripcion = (cuerpo.get('descripcion') or '').strip()
    lugar = (cuerpo.get('lugar') or '').strip()
    fecha = _parsear_fecha(cuerpo.get('fecha'))
    hora = _parsear_hora(cuerpo.get('hora'))

    if not titulo or not descripcion or not lugar or fecha is None or hora is None:
        return responder(
            {'error': 'titulo, descripcion, lugar, fecha (YYYY-MM-DD) y hora (HH:MM) son obligatorios'},
            status=400,
        )

    cupo = cuerpo.get('cupo')
    if cupo is not None:
        try:
            cupo = int(cupo)
            if cupo < 0:
                raise ValueError
        except (TypeError, ValueError):
            return responder({'error': 'cupo debe ser un número entero positivo'}, status=400)

    evento = Evento.objects.create(
        comunidad=comunidad,
        titulo=titulo,
        descripcion=descripcion,
        fecha=fecha,
        hora=hora,
        lugar=lugar,
        cupo=cupo,
        gestor=gestor,
    )

    return responder(
        {'mensaje': f'Evento "{evento.titulo}" creado', 'evento': evento_a_dict(evento)},
        status=201,
    )


@csrf_exempt
def detalle_evento(request, evento_id):
    """RF-03 (GET): detalle de un evento.
    RF-04 (PUT/PATCH): editar un evento existente.
    RF-04 (DELETE): cancelar un evento (borrado lógico, no se elimina el registro)."""

    evento = Evento.objects.filter(id=evento_id).first()
    if evento is None:
        return responder({'error': 'El evento no existe'}, status=404)

    if request.method == 'GET':
        return responder(evento_a_dict(evento))

    if request.method in ('PUT', 'PATCH'):
        return _editar_evento(request, evento)

    if request.method == 'DELETE':
        return _cancelar_evento(request, evento)

    return responder({'error': 'Método no permitido'}, status=405)


def _editar_evento(request, evento):
    """RF-04: el gestor edita título, descripción, fecha, hora, lugar y/o cupo."""
    cuerpo = obtener_cuerpo(request)

    gestor = obtener_gestor(request, cuerpo)
    if gestor is None:
        return responder({'error': 'Debe enviar un gestor_id válido'}, status=400)

    if not es_gestor(gestor, evento.comunidad):
        return responder({'error': f'No es gestor de {evento.comunidad.nombre}'}, status=403)

    if evento.cancelado():
        return responder({'error': 'No se puede editar un evento cancelado'}, status=400)

    if 'titulo' in cuerpo:
        titulo = (cuerpo.get('titulo') or '').strip()
        if not titulo:
            return responder({'error': 'El título no puede quedar vacío'}, status=400)
        evento.titulo = titulo

    if 'descripcion' in cuerpo:
        descripcion = (cuerpo.get('descripcion') or '').strip()
        if not descripcion:
            return responder({'error': 'La descripción no puede quedar vacía'}, status=400)
        evento.descripcion = descripcion

    if 'lugar' in cuerpo:
        lugar = (cuerpo.get('lugar') or '').strip()
        if not lugar:
            return responder({'error': 'El lugar no puede quedar vacío'}, status=400)
        evento.lugar = lugar

    if 'fecha' in cuerpo:
        fecha = _parsear_fecha(cuerpo.get('fecha'))
        if fecha is None:
            return responder({'error': 'fecha debe tener el formato YYYY-MM-DD'}, status=400)
        evento.fecha = fecha

    if 'hora' in cuerpo:
        hora = _parsear_hora(cuerpo.get('hora'))
        if hora is None:
            return responder({'error': 'hora debe tener el formato HH:MM'}, status=400)
        evento.hora = hora

    if 'cupo' in cuerpo:
        cupo = cuerpo.get('cupo')
        if cupo is not None:
            try:
                cupo = int(cupo)
                if cupo < 0:
                    raise ValueError
            except (TypeError, ValueError):
                return responder({'error': 'cupo debe ser un número entero positivo'}, status=400)
        evento.cupo = cupo

    evento.save()
    return responder({'mensaje': f'Evento "{evento.titulo}" actualizado', 'evento': evento_a_dict(evento)})


def _cancelar_evento(request, evento):
    """RF-04: el gestor cancela un evento (no se borra, queda marcado como cancelado)."""
    gestor = obtener_gestor(request)
    if gestor is None:
        return responder({'error': 'Debe enviar un gestor_id válido'}, status=400)

    if not es_gestor(gestor, evento.comunidad):
        return responder({'error': f'No es gestor de {evento.comunidad.nombre}'}, status=403)

    if evento.cancelado():
        return responder({'error': f'El evento "{evento.titulo}" ya estaba cancelado'}, status=400)

    evento.estado = Evento.CANCELADO
    evento.save()
    return responder({'mensaje': f'Evento "{evento.titulo}" cancelado', 'evento': evento_a_dict(evento)})