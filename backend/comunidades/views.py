import json

from django.conf import settings
from django.contrib.auth.models import User
from django.db.models import Q
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from .models import Comunidad, Seguimiento


def responder(datos, status=200):
    # ensure_ascii en False para que las tildes se vean bien en la respuesta
    return JsonResponse(datos, status=status, json_dumps_params={'ensure_ascii': False})


def obtener_estudiante(request):
    """Devuelve el estudiante que envia el request.

    Por ahora el id llega en el cuerpo (o en la url) porque la autenticacion
    es infraestructura compartida y todavia no esta implementada.
    """
    try:
        cuerpo = json.loads(request.body or '{}')
    except json.JSONDecodeError:
        cuerpo = {}

    estudiante_id = cuerpo.get('estudiante_id') or request.GET.get('estudiante_id')
    try:
        return User.objects.filter(id=int(estudiante_id)).first()
    except (TypeError, ValueError):
        return None


def url_logo(request, comunidad):
    if not comunidad.logo:
        return ''
    return request.build_absolute_uri(f'/{settings.MEDIA_URL}logos/{comunidad.logo}'.replace('//', '/'))


def comunidad_a_dict(request, comunidad, seguidas=None):
    datos = {
        'id': comunidad.id,
        'nombre': comunidad.nombre,
        'descripcion': comunidad.descripcion,
        'categoria': comunidad.categoria.nombre,
        'contacto': comunidad.contacto,
        'logo': url_logo(request, comunidad),
        'seguidores': comunidad.total_seguidores(),
    }
    if seguidas is not None:
        datos['siguiendo'] = comunidad.id in seguidas
    return datos


def comunidades_seguidas(request):
    """Ids de las comunidades que sigue el estudiante, si se envio uno."""
    estudiante = obtener_estudiante(request)
    if estudiante is None:
        return None
    return set(estudiante.seguimientos.values_list('comunidad_id', flat=True))


def listar_comunidades(request):
    """RF-01: catalogo de comunidades con busqueda por texto y filtro por categoria."""
    comunidades = Comunidad.objects.filter(activa=True)

    texto = request.GET.get('q', '').strip()
    if texto:
        comunidades = comunidades.filter(
            Q(nombre__icontains=texto)
            | Q(descripcion__icontains=texto)
            | Q(categoria__nombre__icontains=texto)
        )

    categoria = request.GET.get('categoria', '').strip()
    if categoria:
        comunidades = comunidades.filter(categoria__nombre__iexact=categoria)

    seguidas = comunidades_seguidas(request)
    resultados = [comunidad_a_dict(request, c, seguidas) for c in comunidades]
    return responder({'total': len(resultados), 'comunidades': resultados})


def detalle_comunidad(request, comunidad_id):
    """RF-01: detalle de una comunidad."""
    comunidad = Comunidad.objects.filter(id=comunidad_id, activa=True).first()
    if comunidad is None:
        return responder({'error': 'La comunidad no existe o no está activa'}, status=404)

    return responder(comunidad_a_dict(request, comunidad, comunidades_seguidas(request)))


@csrf_exempt
def seguir_comunidad(request, comunidad_id):
    """RF-02: seguir (POST) o dejar de seguir (DELETE) una comunidad."""
    if request.method not in ('POST', 'DELETE'):
        return responder({'error': 'Método no permitido'}, status=405)

    comunidad = Comunidad.objects.filter(id=comunidad_id, activa=True).first()
    if comunidad is None:
        return responder({'error': 'La comunidad no existe o no está activa'}, status=404)

    estudiante = obtener_estudiante(request)
    if estudiante is None:
        return responder({'error': 'Debe enviar un estudiante_id válido'}, status=400)

    if request.method == 'POST':
        seguimiento, creado = Seguimiento.objects.get_or_create(
            estudiante=estudiante, comunidad=comunidad
        )
        if not creado:
            return responder({'error': f'Ya sigues a {comunidad.nombre}'}, status=400)

        return responder({
            'mensaje': f'Ahora sigues a {comunidad.nombre}',
            'siguiendo': True,
            'seguidores': comunidad.total_seguidores(),
        }, status=201)

    seguimiento = Seguimiento.objects.filter(estudiante=estudiante, comunidad=comunidad).first()
    if seguimiento is None:
        return responder({'error': f'No sigues a {comunidad.nombre}'}, status=400)

    seguimiento.delete()
    return responder({
        'mensaje': f'Dejaste de seguir a {comunidad.nombre}',
        'siguiendo': False,
        'seguidores': comunidad.total_seguidores(),
    })
