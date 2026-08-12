"""Demostración de RF-05 y RF-06 contra el servidor de desarrollo.

Recorre el flujo completo de solicitudes de ingreso e imprime cada petición con
su respuesta, para documentar el funcionamiento en el informe.

Uso (con el servidor levantado en otra terminal):

    python manage.py runserver
    python demo_solicitudes.py
"""

import json
import os
import sys
import urllib.error
import urllib.request

import django

BASE = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:8000'

# la consola de Windows usa cp1252 por defecto y rompe las tildes en pantalla
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth.models import User  # noqa: E402

from comunidades.models import Comunidad  # noqa: E402
from solicitudes.models import Solicitud  # noqa: E402


def titulo(numero, texto):
    print()
    print('=' * 78)
    print(f'{numero}. {texto}')
    print('=' * 78)


def llamar(metodo, ruta, cuerpo=None, espera=None):
    """Ejecuta la petición e imprime la respuesta con formato legible."""
    datos = json.dumps(cuerpo, ensure_ascii=False).encode() if cuerpo else None
    peticion = urllib.request.Request(
        BASE + ruta, data=datos, method=metodo,
        headers={'Content-Type': 'application/json'},
    )

    print(f'\n  {metodo} {ruta}')
    if cuerpo:
        print(f'  cuerpo: {json.dumps(cuerpo, ensure_ascii=False)}')

    try:
        with urllib.request.urlopen(peticion) as respuesta:
            estado, contenido = respuesta.status, json.loads(respuesta.read().decode())
    except urllib.error.HTTPError as error:
        estado, contenido = error.code, json.loads(error.read().decode())
    except urllib.error.URLError:
        sys.exit(f'\n  No hay servidor en {BASE}. Ejecute: python manage.py runserver')

    marca = 'OK' if espera is None or estado == espera else 'INESPERADO'
    print(f'  --> {estado} [{marca}]')
    for linea in json.dumps(contenido, ensure_ascii=False, indent=2).splitlines():
        print(f'      {linea}')
    return contenido


def preparar():
    """Deja el escenario en su estado inicial para que la demo sea repetible."""
    comunidad = Comunidad.objects.filter(nombre='CIAP', gestores__isnull=False).first()
    otra = Comunidad.objects.filter(nombre='NIOT', activa=True).first()
    if comunidad is None or otra is None:
        sys.exit('Faltan datos: ejecute cargar_datos y luego cargar_solicitudes')

    estudiante, _ = User.objects.get_or_create(username='estudiante_demo')
    Solicitud.objects.filter(estudiante=estudiante).delete()
    return estudiante, comunidad.gestores.first(), comunidad, otra


estudiante, gestor, comunidad, otra = preparar()

print(f'Servidor    : {BASE}')
print(f'Estudiante  : {estudiante.username} (id={estudiante.id})')
print(f'Gestor      : {gestor.username} (id={gestor.id}) — administra {comunidad.nombre}')
print(f'Comunidades : {comunidad.nombre} (id={comunidad.id}), {otra.nombre} (id={otra.id})')

titulo(1, 'RF-06 · El estudiante envía una solicitud de ingreso')
creada = llamar('POST', f'/api/comunidades/{comunidad.id}/solicitar/', {
    'estudiante_id': estudiante.id,
    'mensaje': 'Me interesa el machine learning y quiero participar en los proyectos.',
}, espera=201)
solicitud_id = creada['solicitud']['id']

titulo(2, 'RF-06 · No se permite duplicar una solicitud pendiente')
llamar('POST', f'/api/comunidades/{comunidad.id}/solicitar/', {
    'estudiante_id': estudiante.id,
}, espera=400)

titulo(3, 'RF-05 · El estudiante consulta el estado de sus solicitudes')
llamar('GET', f'/api/solicitudes/?estudiante_id={estudiante.id}', espera=200)

titulo(4, 'RF-05 · El gestor revisa las solicitudes pendientes de su comunidad')
llamar('GET',
       f'/api/comunidades/{comunidad.id}/solicitudes/?gestor_id={gestor.id}&estado=pendiente',
       espera=200)

titulo(5, 'RF-05 · Un usuario que no es gestor de la comunidad no puede revisarlas')
llamar('GET', f'/api/comunidades/{comunidad.id}/solicitudes/?gestor_id={estudiante.id}',
       espera=403)

titulo(6, 'RF-06 · Un estudiante no puede resolver una solicitud')
llamar('POST', f'/api/solicitudes/{solicitud_id}/resolver/', {
    'estudiante_id': estudiante.id, 'gestor_id': estudiante.id, 'accion': 'aprobar',
}, espera=403)

titulo(7, 'RF-06 · El gestor aprueba la solicitud con una observación')
llamar('POST', f'/api/solicitudes/{solicitud_id}/resolver/', {
    'gestor_id': gestor.id,
    'accion': 'aprobar',
    'observacion': 'Bienvenido al club, te esperamos en la reunión del viernes.',
}, espera=200)

titulo(8, 'RF-06 · Una solicitud ya resuelta no se puede volver a resolver')
llamar('POST', f'/api/solicitudes/{solicitud_id}/resolver/', {
    'gestor_id': gestor.id, 'accion': 'rechazar',
}, espera=400)

titulo(9, 'RF-06 · Un estudiante ya aprobado no puede volver a postular')
llamar('POST', f'/api/comunidades/{comunidad.id}/solicitar/', {
    'estudiante_id': estudiante.id,
}, espera=400)

titulo(10, 'RF-06 · El estudiante envía y luego retira una solicitud en otra comunidad')
llamar('POST', f'/api/comunidades/{otra.id}/solicitar/', {
    'estudiante_id': estudiante.id, 'mensaje': 'Me interesan las redes y el IoT.',
}, espera=201)
llamar('DELETE', f'/api/comunidades/{otra.id}/solicitar/', {
    'estudiante_id': estudiante.id,
}, espera=200)

titulo(11, 'RF-05 · Estado final: la solicitud retirada permanece en el historial')
llamar('GET', f'/api/solicitudes/?estudiante_id={estudiante.id}', espera=200)

print()
print('=' * 78)
print('Demostración completada.')
print('=' * 78)
