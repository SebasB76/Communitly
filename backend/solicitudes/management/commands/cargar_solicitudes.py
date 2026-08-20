from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from django.utils import timezone

from comunidades.models import Comunidad
from solicitudes.models import Solicitud

# (usuario del gestor, comunidad que administra)
GESTORES = [
    ('gestor_ciap', 'CIAP'),
    ('gestor_robota', 'ROBOTA'),
    ('gestor_ieee', 'IEEE ESPOL Student Branch'),
    ('gestor_taws', 'TAWS'),
]

ESTUDIANTES = ['estudiante1', 'estudiante2', 'estudiante3', 'estudiante4']

# (estudiante, comunidad, mensaje, estado, observacion)
SOLICITUDES = [
    ('estudiante1', 'CIAP',
     'Me interesa el machine learning y quiero participar en los proyectos del club.',
     Solicitud.PENDIENTE, ''),
    ('estudiante2', 'CIAP',
     'Estudio ciencia de datos y me gustaría aportar en los talleres.',
     Solicitud.PENDIENTE, ''),
    ('estudiante3', 'CIAP',
     'Quiero aprender sobre redes neuronales desde cero.',
     Solicitud.PENDIENTE, ''),
    ('estudiante4', 'CIAP',
     'Busco integrarme al equipo de investigación del club.',
     Solicitud.PENDIENTE, ''),
    ('estudiante1', 'ROBOTA',
     'Tengo experiencia con Arduino y quiero competir este semestre.',
     Solicitud.APROBADA, 'Bienvenido, te esperamos en la reunión del viernes.'),
    ('estudiante2', 'ROBOTA',
     'Quiero conocer el club y sus actividades.',
     Solicitud.RECHAZADA, 'Las inscripciones de este semestre ya cerraron.'),
    ('estudiante3', 'IEEE ESPOL Student Branch',
     'Me interesan las conferencias de ingeniería eléctrica.',
     Solicitud.PENDIENTE, ''),
    ('estudiante4', 'IEEE ESPOL Student Branch',
     'Consulté los horarios y por ahora no puedo participar.',
     Solicitud.RETIRADA, ''),
    ('estudiante1', 'TAWS',
     'Quiero aprender desarrollo web y sumarme a los proyectos del grupo.',
     Solicitud.PENDIENTE, ''),
    ('estudiante2', 'TAWS',
     'Me interesa la investigación en ciencia de datos.',
     Solicitud.PENDIENTE, ''),
    ('estudiante3', 'TAWS',
     'Ya trabajé en un proyecto móvil y me gustaría aportar al club.',
     Solicitud.APROBADA, 'Bienvenido al equipo, escríbenos al correo del club.'),
]


class Command(BaseCommand):
    help = 'Carga gestores y solicitudes de ingreso de prueba (RF-05 y RF-06)'

    def handle(self, *args, **options):
        if not Comunidad.objects.exists():
            self.stdout.write(self.style.ERROR(
                'No hay comunidades cargadas: ejecute primero "manage.py cargar_datos"'
            ))
            return

        gestores = {}
        for username, nombre_comunidad in GESTORES:
            comunidad = Comunidad.objects.filter(nombre=nombre_comunidad).first()
            if comunidad is None:
                self.stdout.write(self.style.WARNING(
                    f'No existe la comunidad {nombre_comunidad}: se omite {username}'
                ))
                continue

            gestor = self.crear_usuario(username)
            comunidad.gestores.add(gestor)
            gestores[nombre_comunidad] = gestor

        for username in ESTUDIANTES:
            self.crear_usuario(username)

        creadas = 0
        for username, nombre_comunidad, mensaje, estado, observacion in SOLICITUDES:
            comunidad = Comunidad.objects.filter(nombre=nombre_comunidad).first()
            if comunidad is None:
                continue

            estudiante = User.objects.get(username=username)
            if Solicitud.objects.filter(estudiante=estudiante, comunidad=comunidad).exists():
                continue

            resuelta = estado in (Solicitud.APROBADA, Solicitud.RECHAZADA)
            Solicitud.objects.create(
                estudiante=estudiante,
                comunidad=comunidad,
                mensaje=mensaje,
                estado=estado,
                observacion=observacion,
                resuelta_por=gestores.get(nombre_comunidad) if resuelta else None,
                resuelta_en=timezone.now() if resuelta else None,
            )
            creadas += 1

        self.stdout.write(self.style.SUCCESS(
            f'Listo: {len(gestores)} comunidades con gestor, '
            f'{creadas} solicitudes nuevas, '
            f'{Solicitud.objects.count()} solicitudes en total'
        ))

    def crear_usuario(self, username):
        usuario = User.objects.filter(username=username).first()
        if usuario is None:
            usuario = User.objects.create_user(username=username, password='espol2026')
        return usuario
