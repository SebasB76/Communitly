from django.db.models import Q
from django.http import JsonResponse

from .models import Comunidad


def responder(datos, status=200):
    # ensure_ascii en False para que las tildes se vean bien en la respuesta
    return JsonResponse(datos, status=status, json_dumps_params={'ensure_ascii': False})


def comunidad_a_dict(comunidad):
    return {
        'id': comunidad.id,
        'nombre': comunidad.nombre,
        'descripcion': comunidad.descripcion,
        'categoria': comunidad.categoria.nombre,
        'contacto': comunidad.contacto,
        'seguidores': comunidad.total_seguidores(),
    }


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

    resultados = [comunidad_a_dict(c) for c in comunidades]
    return responder({'total': len(resultados), 'comunidades': resultados})


def detalle_comunidad(request, comunidad_id):
    """RF-01: detalle de una comunidad."""
    comunidad = Comunidad.objects.filter(id=comunidad_id, activa=True).first()
    if comunidad is None:
        return responder({'error': 'La comunidad no existe o no está activa'}, status=404)

    return responder(comunidad_a_dict(comunidad))
