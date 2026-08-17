import json

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.views.decorators.csrf import csrf_exempt

from comunidades.views import responder


def leer_cuerpo(request):
    """Cuerpo JSON del request; devuelve {} si viene vacio o mal formado."""
    try:
        cuerpo = json.loads(request.body or '{}')
    except ValueError:
        return {}

    return cuerpo if isinstance(cuerpo, dict) else {}


def usuario_a_dict(usuario):
    """Identidad y permisos del usuario.

    `comunidades_gestionadas` es lo que permite al frontend saber, sin
    adivinar, que acciones de gestor puede ofrecer y sobre que comunidad.
    """
    gestionadas = usuario.comunidades_gestionadas.filter(activa=True).order_by('nombre')
    comunidades = [{'id': c.id, 'nombre': c.nombre} for c in gestionadas]

    return {
        'id': usuario.id,
        'usuario': usuario.username,
        'nombre': usuario.get_full_name() or usuario.username,
        'es_gestor': bool(comunidades),
        'comunidades_gestionadas': comunidades,
    }


@csrf_exempt
def sesion(request):
    """POST inicia la sesion; GET devuelve los permisos vigentes."""
    if request.method == 'POST':
        return iniciar_sesion(request)
    if request.method == 'GET':
        return consultar_permisos(request)

    return responder({'error': 'Método no permitido'}, status=405)


def iniciar_sesion(request):
    """Valida las credenciales y devuelve la identidad con sus permisos."""
    cuerpo = leer_cuerpo(request)
    nombre = cuerpo.get('usuario')
    contrasena = cuerpo.get('contrasena')

    if not isinstance(nombre, str) or not isinstance(contrasena, str):
        return responder({'error': 'Debe enviar usuario y contraseña'}, status=400)

    nombre = nombre.strip()
    if not nombre or not contrasena:
        return responder({'error': 'Debe enviar usuario y contraseña'}, status=400)

    # authenticate compara el hash y rechaza las cuentas desactivadas
    cuenta = authenticate(username=nombre, password=contrasena)
    if cuenta is None:
        return responder({'error': 'Usuario o contraseña incorrectos'}, status=401)

    return responder({
        'mensaje': f'Sesión iniciada como {cuenta.username}',
        'usuario': usuario_a_dict(cuenta),
    })


def consultar_permisos(request):
    """Permisos actuales de un usuario, para refrescarlos sin volver a entrar."""
    try:
        usuario_id = int(request.GET.get('usuario_id'))
    except (TypeError, ValueError):
        return responder({'error': 'Debe enviar un usuario_id válido'}, status=400)

    cuenta = User.objects.filter(id=usuario_id).first()
    if cuenta is None:
        return responder({'error': 'El usuario no existe'}, status=404)

    return responder({'usuario': usuario_a_dict(cuenta)})
