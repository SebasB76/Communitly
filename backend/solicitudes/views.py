import json

from django.contrib.auth.models import User
from django.db import IntegrityError
from django.db.models import Count
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt

from comunidades.models import Comunidad
from comunidades.views import responder

from .models import Solicitud

# limite de los textos libres que escriben el estudiante y el gestor
MAX_TEXTO = 500


def leer_cuerpo(request):
    """Cuerpo JSON del request; devuelve {} si viene vacio o mal formado."""
    try:
        cuerpo = json.loads(request.body or '{}')
    except ValueError:
        return {}

    return cuerpo if isinstance(cuerpo, dict) else {}


def leer_texto(cuerpo, campo, etiqueta):
    """Lee un texto opcional del cuerpo y devuelve (valor, error)."""
    valor = cuerpo.get(campo) or ''
    if not isinstance(valor, str):
        return '', f'{etiqueta} debe ser texto'

    valor = valor.strip()
    if len(valor) > MAX_TEXTO:
        return '', f'{etiqueta} no puede superar los {MAX_TEXTO} caracteres'

    return valor, None


def obtener_usuario(request, campo, cuerpo=None):
    """Devuelve el usuario que envia el request.

    Igual que en RF-01 y RF-02, el id llega en el cuerpo o en la url porque la
    autenticacion es infraestructura compartida y todavia no esta implementada.
    """
    if cuerpo is None:
        cuerpo = leer_cuerpo(request)

    valor = cuerpo.get(campo) or request.GET.get(campo)
    try:
        return User.objects.filter(id=int(valor)).first()
    except (TypeError, ValueError):
        return None


def es_gestor(usuario, comunidad):
    """Solo un gestor autorizado puede revisar o resolver las solicitudes."""
    return usuario is not None and comunidad.gestores.filter(id=usuario.id).exists()


def solicitud_a_dict(solicitud):
    return {
        'id': solicitud.id,
        'estado': solicitud.estado,
        'estado_texto': solicitud.get_estado_display(),
        'mensaje': solicitud.mensaje,
        'observacion': solicitud.observacion,
        'comunidad': {
            'id': solicitud.comunidad_id,
            'nombre': solicitud.comunidad.nombre,
        },
        'estudiante': {
            'id': solicitud.estudiante_id,
            'usuario': solicitud.estudiante.username,
        },
        'creada_en': solicitud.creada_en.isoformat(),
        'resuelta_en': solicitud.resuelta_en.isoformat() if solicitud.resuelta_en else None,
        'resuelta_por': solicitud.resuelta_por.username if solicitud.resuelta_por else None,
    }


def resumen_estados(solicitudes):
    """Cantidad de solicitudes por estado, para las pestañas del gestor."""
    conteos = {estado: 0 for estado, _ in Solicitud.ESTADOS}
    for fila in solicitudes.values('estado').annotate(total=Count('id')):
        conteos[fila['estado']] = fila['total']
    return conteos


def filtrar_por_estado(solicitudes, request):
    """Aplica el filtro ?estado=... y devuelve (solicitudes, error)."""
    estado = request.GET.get('estado', '').strip().lower()
    if not estado:
        return solicitudes, None

    if estado not in dict(Solicitud.ESTADOS):
        validos = ', '.join(dict(Solicitud.ESTADOS))
        return solicitudes, f'Estado no válido: use {validos}'

    return solicitudes.filter(estado=estado), None


def con_relaciones(solicitudes):
    return solicitudes.select_related('comunidad', 'estudiante', 'resuelta_por')


# --- RF-05: consultar solicitudes -------------------------------------------

def mis_solicitudes(request):
    """RF-05: estado de las solicitudes que envio el estudiante."""
    if request.method != 'GET':
        return responder({'error': 'Método no permitido'}, status=405)

    estudiante = obtener_usuario(request, 'estudiante_id')
    if estudiante is None:
        return responder({'error': 'Debe enviar un estudiante_id válido'}, status=400)

    solicitudes = con_relaciones(Solicitud.objects.filter(estudiante=estudiante))
    resumen = resumen_estados(solicitudes)

    solicitudes, error = filtrar_por_estado(solicitudes, request)
    if error:
        return responder({'error': error}, status=400)

    resultados = [solicitud_a_dict(s) for s in solicitudes]
    return responder({
        'total': len(resultados),
        'resumen': resumen,
        'solicitudes': resultados,
    })


def solicitudes_comunidad(request, comunidad_id):
    """RF-05: solicitudes recibidas por una comunidad; solo para su gestor."""
    if request.method != 'GET':
        return responder({'error': 'Método no permitido'}, status=405)

    comunidad = Comunidad.objects.filter(id=comunidad_id, activa=True).first()
    if comunidad is None:
        return responder({'error': 'La comunidad no existe o no está activa'}, status=404)

    gestor = obtener_usuario(request, 'gestor_id')
    if gestor is None:
        return responder({'error': 'Debe enviar un gestor_id válido'}, status=400)
    if not es_gestor(gestor, comunidad):
        return responder({'error': f'No es gestor de {comunidad.nombre}'}, status=403)

    solicitudes = con_relaciones(comunidad.solicitudes.all())
    resumen = resumen_estados(solicitudes)

    solicitudes, error = filtrar_por_estado(solicitudes, request)
    if error:
        return responder({'error': error}, status=400)

    resultados = [solicitud_a_dict(s) for s in solicitudes]
    return responder({
        'comunidad': {'id': comunidad.id, 'nombre': comunidad.nombre},
        'total': len(resultados),
        'resumen': resumen,
        'solicitudes': resultados,
    })


def detalle_solicitud(request, solicitud_id):
    """RF-05: detalle de una solicitud para su estudiante o para el gestor."""
    if request.method != 'GET':
        return responder({'error': 'Método no permitido'}, status=405)

    solicitud = con_relaciones(Solicitud.objects.filter(id=solicitud_id)).first()
    if solicitud is None:
        return responder({'error': 'La solicitud no existe'}, status=404)

    estudiante = obtener_usuario(request, 'estudiante_id')
    es_dueno = estudiante is not None and solicitud.estudiante_id == estudiante.id
    if not es_dueno and not es_gestor(obtener_usuario(request, 'gestor_id'), solicitud.comunidad):
        return responder({'error': 'No tiene permiso para consultar esta solicitud'}, status=403)

    return responder(solicitud_a_dict(solicitud))


# --- RF-06: gestionar solicitudes de ingreso --------------------------------

@csrf_exempt
def solicitar_ingreso(request, comunidad_id):
    """RF-06: el estudiante envia (POST) o retira (DELETE) su solicitud."""
    if request.method not in ('POST', 'DELETE'):
        return responder({'error': 'Método no permitido'}, status=405)

    comunidad = Comunidad.objects.filter(id=comunidad_id, activa=True).first()
    if comunidad is None:
        return responder({'error': 'La comunidad no existe o no está activa'}, status=404)

    cuerpo = leer_cuerpo(request)
    estudiante = obtener_usuario(request, 'estudiante_id', cuerpo)
    if estudiante is None:
        return responder({'error': 'Debe enviar un estudiante_id válido'}, status=400)

    if request.method == 'DELETE':
        return retirar_solicitud(estudiante, comunidad)
    return enviar_solicitud(estudiante, comunidad, cuerpo)


def enviar_solicitud(estudiante, comunidad, cuerpo):
    """Registra una nueva solicitud si el estudiante no tiene una en curso."""
    solicitudes = Solicitud.objects.filter(estudiante=estudiante, comunidad=comunidad)
    if solicitudes.filter(estado=Solicitud.PENDIENTE).exists():
        return responder(
            {'error': f'Ya tienes una solicitud pendiente en {comunidad.nombre}'}, status=400
        )
    if solicitudes.filter(estado=Solicitud.APROBADA).exists():
        return responder({'error': f'Ya formas parte de {comunidad.nombre}'}, status=400)

    mensaje, error = leer_texto(cuerpo, 'mensaje', 'El mensaje')
    if error:
        return responder({'error': error}, status=400)

    try:
        solicitud = Solicitud.objects.create(
            estudiante=estudiante, comunidad=comunidad, mensaje=mensaje
        )
    except IntegrityError:
        # la restriccion de la base de datos cubre dos envios simultaneos
        return responder(
            {'error': f'Ya tienes una solicitud pendiente en {comunidad.nombre}'}, status=400
        )

    return responder({
        'mensaje': f'Solicitud enviada a {comunidad.nombre}',
        'solicitud': solicitud_a_dict(solicitud),
    }, status=201)


def retirar_solicitud(estudiante, comunidad):
    """Retira la solicitud pendiente; queda en el historial con su estado."""
    solicitud = Solicitud.objects.filter(
        estudiante=estudiante, comunidad=comunidad, estado=Solicitud.PENDIENTE
    ).select_related('comunidad', 'estudiante').first()
    if solicitud is None:
        return responder(
            {'error': f'No tienes una solicitud pendiente en {comunidad.nombre}'}, status=400
        )

    solicitud.estado = Solicitud.RETIRADA
    solicitud.save(update_fields=['estado', 'actualizada_en'])

    return responder({
        'mensaje': f'Retiraste tu solicitud en {comunidad.nombre}',
        'solicitud': solicitud_a_dict(solicitud),
    })


@csrf_exempt
def resolver_solicitud(request, solicitud_id):
    """RF-06: el gestor aprueba o rechaza con una observación opcional."""
    if request.method != 'POST':
        return responder({'error': 'Método no permitido'}, status=405)

    solicitud = con_relaciones(Solicitud.objects.filter(id=solicitud_id)).first()
    if solicitud is None:
        return responder({'error': 'La solicitud no existe'}, status=404)

    cuerpo = leer_cuerpo(request)
    gestor = obtener_usuario(request, 'gestor_id', cuerpo)
    if gestor is None:
        return responder({'error': 'Debe enviar un gestor_id válido'}, status=400)
    if not es_gestor(gestor, solicitud.comunidad):
        return responder(
            {'error': f'No es gestor de {solicitud.comunidad.nombre}'}, status=403
        )

    accion = cuerpo.get('accion')
    accion = accion.strip().lower() if isinstance(accion, str) else ''
    if accion not in Solicitud.RESOLUCIONES:
        return responder({'error': 'La acción debe ser "aprobar" o "rechazar"'}, status=400)

    if not solicitud.pendiente:
        estado = solicitud.get_estado_display().lower()
        return responder({'error': f'La solicitud ya fue {estado}'}, status=400)

    observacion, error = leer_texto(cuerpo, 'observacion', 'La observación')
    if error:
        return responder({'error': error}, status=400)

    solicitud.estado = Solicitud.RESOLUCIONES[accion]
    solicitud.observacion = observacion
    solicitud.resuelta_por = gestor
    solicitud.resuelta_en = timezone.now()
    solicitud.save(update_fields=[
        'estado', 'observacion', 'resuelta_por', 'resuelta_en', 'actualizada_en',
    ])

    return responder({
        'mensaje': f'Solicitud {solicitud.get_estado_display().lower()}',
        'solicitud': solicitud_a_dict(solicitud),
    })
