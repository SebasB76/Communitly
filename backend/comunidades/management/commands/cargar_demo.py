from datetime import date, time, timedelta

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from django.utils import timezone

from comunidades.models import Comunidad, Seguimiento
from eventos.models import Evento
from solicitudes.models import Solicitud

ESTUDIANTES = [
    ('mfernandez', 'María', 'Fernández'),
    ('jzambrano', 'José', 'Zambrano'),
    ('acastro', 'Andrea', 'Castro'),
    ('dvillacis', 'Daniel', 'Villacís'),
    ('kmorales', 'Karla', 'Morales'),
    ('lespinoza', 'Luis', 'Espinoza'),
    ('pvera', 'Paula', 'Vera'),
    ('rmacias', 'Ricardo', 'Macías'),
    ('sponce', 'Sofía', 'Ponce'),
    ('cmendoza', 'Carlos', 'Mendoza'),
    ('vloor', 'Valeria', 'Loor'),
    ('gsalazar', 'Gabriel', 'Salazar'),
]

GESTORES = {
    'gestor_ciap': 'CIAP',
    'gestor_taws': 'TAWS',
    'gestor_robota': 'ROBOTA',
    'gestor_ieee': 'IEEE ESPOL Student Branch',
    'gestor_niot': 'NIOT',
    'gestor_kokoa': 'KOKOA',
    'gestor_phycom': 'PHYCOM',
    'gestor_breik': 'BREIK',
    'gestor_cadiec': 'CADIEC',
    'gestor_gissc': 'GISSC',
    'gestor_mecatronica': 'Club de Mecatrónica',
}

EVENTOS = [
    ('TAWS', 'Noche de juegos y networking',
     'Una noche para conocer a los miembros del club entre juegos de mesa y pizza.',
     1, time(19, 0), 'Patio de comidas FIEC', 40),
    ('CIAP', 'Taller de Machine Learning con Python',
     'Taller práctico desde cero: clasificación de imágenes con scikit-learn y un dataset propio.',
     5, time(16, 0), 'Aula STEM-102', 40),
    ('NIOT', 'Workshop de IoT con ESP32',
     'Arma tu primer sensor conectado a internet. Incluye kit prestado por el club.',
     6, time(14, 30), 'Laboratorio de Telemática', 25),
    ('BREIK', 'Taller de fotografía con celular',
     'Composición, luz y edición rápida para redes sociales, solo con tu teléfono.',
     7, time(16, 30), 'Plaza de FADCOM', 25),
    ('TAWS', 'Bootcamp de Desarrollo Web',
     'Tres sesiones intensivas de HTML, CSS y JavaScript para construir tu primer sitio.',
     8, time(15, 0), 'Lab de Software FIEC', 35),
    ('KOKOA', 'Install Fest de Linux',
     'Trae tu laptop y sal con Linux instalado y funcionando. Todas las distros bienvenidas.',
     9, time(10, 0), 'Aula 21 FIEC', 30),
    ('GISSC', 'Mapatón OpenStreetMap',
     'Jornada de mapeo colaborativo de zonas rurales del Guayas para proyectos comunitarios.',
     10, time(9, 30), 'Laboratorio de Geomática', 20),
    ('IEEE ESPOL Student Branch', 'Charla: Energías renovables en Ecuador',
     'Panel con ingenieros del sector eléctrico sobre el futuro energético del país.',
     11, time(17, 0), 'Auditorio FIEC', None),
    ('CIAP', 'Charla: IA generativa en la industria',
     'Cómo las empresas ecuatorianas están adoptando modelos de lenguaje en producción.',
     12, time(18, 0), 'Auditorio FIEC', None),
    ('CADIEC', 'Seminario de economía digital',
     'Criptomonedas, comercio electrónico y el impacto de la digitalización en la economía local.',
     13, time(18, 30), 'Aula FCSH-201', None),
    ('PHYCOM', 'Robótica para principiantes',
     'Primeros pasos con Arduino: sensores, motores y tu primer robot que sigue líneas.',
     15, time(15, 0), 'Laboratorio de Física', 20),
    ('ROBOTA', 'Competencia interna de sumo bots',
     'Los equipos del club se enfrentan en la arena. Público bienvenido, habrá premios.',
     18, time(13, 0), 'Coliseo ESPOL', None),
    ('IEEE ESPOL Student Branch', 'Preparación IEEE Xtreme',
     'Sesión de práctica para la competencia mundial de programación de 24 horas.',
     20, time(9, 0), 'Lab de Software FIEC', 50),
    ('Club de Mecatrónica', 'Demo de brazo robótico',
     'Presentación del brazo robótico construido por el club y sesión de preguntas.',
     22, time(14, 0), 'Laboratorio de Mecatrónica FIMCP', None),
    ('KOKOA', 'Hacktoberfest: contribuye a open source',
     'Aprende a hacer tu primer pull request a un proyecto de código abierto real.',
     27, time(15, 30), 'Aula 21 FIEC', 30),
]

EVENTO_CANCELADO = ('CIAP', 'Visita técnica a data center',
                    'Recorrido por el centro de datos de un proveedor local de nube.',
                    9, time(8, 0), 'Punto de encuentro: garita ESPOL', 15)

SEGUIDORES = {
    'TAWS': 11, 'CIAP': 10, 'IEEE ESPOL Student Branch': 9, 'ROBOTA': 8,
    'KOKOA': 7, 'NIOT': 6, 'PHYCOM': 6, 'BREIK': 5, 'GISSC': 4,
    'Club de Mecatrónica': 5, 'CADIEC': 4, 'Célula Estudiantil Microsoft': 4,
    'AEFIEC': 3, 'IFT ESPOL': 3, 'ASME ESPOL': 3, 'Tweening': 3,
    'FANPOL': 4, 'IISE ESPOL': 2, 'ASCE ESPOL': 2, 'SPE ESPOL': 2,
    'SME ESPOL': 2, 'CLIP': 2, 'AAPG': 2, 'Argumentum': 2,
    'Acción Universitaria': 1, 'Acción Cultural Politécnica': 1,
}

SOLICITUDES = [
    ('mfernandez', 'TAWS', 'Me interesa el desarrollo web y quiero unirme al bootcamp.', 'pendiente', ''),
    ('jzambrano', 'TAWS', 'Tengo experiencia con Flutter y quiero aportar en proyectos.', 'pendiente', ''),
    ('acastro', 'CIAP', 'Quiero aprender machine learning desde cero.', 'pendiente', ''),
    ('dvillacis', 'CIAP', 'Trabajo con datos en mis prácticas y quiero profundizar.', 'aprobada',
     'Bienvenido, la próxima reunión es el viernes.'),
    ('kmorales', 'NIOT', 'Me apasiona el IoT y ya hice proyectos con ESP32.', 'pendiente', ''),
    ('lespinoza', 'KOKOA', 'Uso Linux desde el colegio y quiero ayudar en los install fest.', 'aprobada',
     'Excelente perfil, te esperamos en la reunión del club.'),
    ('pvera', 'BREIK', 'Hago fotografía como hobby y quiero aprender producción.', 'pendiente', ''),
    ('rmacias', 'ROBOTA', 'Competí en robótica en el colegio y quiero seguir.', 'pendiente', ''),
    ('sponce', 'IEEE ESPOL Student Branch', 'Quiero participar en IEEE Xtreme este año.', 'pendiente', ''),
    ('cmendoza', 'GISSC', 'Me interesan los mapas y los sistemas de información geográfica.', 'pendiente', ''),
    ('vloor', 'PHYCOM', 'Estoy en primer semestre y quiero empezar con Arduino.', 'aprobada',
     'Bienvenida, el taller de principiantes es ideal para ti.'),
    ('gsalazar', 'CADIEC', 'Estudio economía y quiero participar en los seminarios.', 'pendiente', ''),
    ('mfernandez', 'CIAP', 'También me gustaría explorar la IA aplicada.', 'rechazada',
     'Cupo lleno este semestre, vuelve a postular el próximo.'),
    ('jzambrano', 'KOKOA', 'Consulté los horarios y este semestre no me alcanza el tiempo.', 'retirada', ''),
    ('acastro', 'TAWS', 'Quiero sumarme al área de data science del grupo.', 'pendiente', ''),
    ('kmorales', 'Club de Mecatrónica', 'Me interesa la manufactura aditiva.', 'pendiente', ''),
]


class Command(BaseCommand):
    help = 'Llena la base con datos de demostración: usuarios, seguidores, eventos y solicitudes'

    def handle(self, *args, **options):
        for username, nombre, apellido in ESTUDIANTES:
            if not User.objects.filter(username=username).exists():
                User.objects.create_user(
                    username=username, password='espol2026',
                    first_name=nombre, last_name=apellido,
                )

        for username, nombre_comunidad in GESTORES.items():
            comunidad = Comunidad.objects.filter(nombre=nombre_comunidad).first()
            if comunidad is None:
                continue
            gestor = User.objects.filter(username=username).first()
            if gestor is None:
                gestor = User.objects.create_user(username=username, password='espol2026')
            comunidad.gestores.add(gestor)

        seguidores_nuevos = 0
        usuarios = [User.objects.get(username=u) for u, _, _ in ESTUDIANTES]
        usuarios += list(User.objects.filter(username__startswith='estudiante'))
        for indice, (nombre_comunidad, cantidad) in enumerate(SEGUIDORES.items()):
            comunidad = Comunidad.objects.filter(nombre=nombre_comunidad).first()
            if comunidad is None:
                continue
            for paso in range(min(cantidad, len(usuarios))):
                usuario = usuarios[(indice * 3 + paso) % len(usuarios)]
                _, creado = Seguimiento.objects.get_or_create(
                    estudiante=usuario, comunidad=comunidad,
                )
                seguidores_nuevos += creado

        hoy = date.today()
        eventos_nuevos = 0
        for nombre_comunidad, titulo, descripcion, dias, hora, lugar, cupo in EVENTOS:
            comunidad = Comunidad.objects.filter(nombre=nombre_comunidad).first()
            if comunidad is None:
                continue
            _, creado = Evento.objects.get_or_create(
                comunidad=comunidad, titulo=titulo,
                defaults={
                    'descripcion': descripcion,
                    'fecha': hoy + timedelta(days=dias),
                    'hora': hora,
                    'lugar': lugar,
                    'cupo': cupo,
                    'gestor': comunidad.gestores.first(),
                },
            )
            eventos_nuevos += creado

        nombre_comunidad, titulo, descripcion, dias, hora, lugar, cupo = EVENTO_CANCELADO
        comunidad = Comunidad.objects.filter(nombre=nombre_comunidad).first()
        if comunidad is not None:
            Evento.objects.get_or_create(
                comunidad=comunidad, titulo=titulo,
                defaults={
                    'descripcion': descripcion,
                    'fecha': hoy + timedelta(days=dias),
                    'hora': hora,
                    'lugar': lugar,
                    'cupo': cupo,
                    'estado': Evento.CANCELADO,
                    'gestor': comunidad.gestores.first(),
                },
            )

        solicitudes_nuevas = 0
        for username, nombre_comunidad, mensaje, estado, observacion in SOLICITUDES:
            estudiante = User.objects.filter(username=username).first()
            comunidad = Comunidad.objects.filter(nombre=nombre_comunidad).first()
            if estudiante is None or comunidad is None:
                continue
            if Solicitud.objects.filter(estudiante=estudiante, comunidad=comunidad).exists():
                continue
            resuelta = estado in (Solicitud.APROBADA, Solicitud.RECHAZADA)
            Solicitud.objects.create(
                estudiante=estudiante,
                comunidad=comunidad,
                mensaje=mensaje,
                estado=estado,
                observacion=observacion,
                resuelta_por=comunidad.gestores.first() if resuelta else None,
                resuelta_en=timezone.now() if resuelta else None,
            )
            solicitudes_nuevas += 1

        self.stdout.write(self.style.SUCCESS(
            f'Demo lista: {User.objects.count()} usuarios, '
            f'{Seguimiento.objects.count()} seguimientos (+{seguidores_nuevos}), '
            f'{Evento.objects.count()} eventos (+{eventos_nuevos}), '
            f'{Solicitud.objects.count()} solicitudes (+{solicitudes_nuevas})'
        ))
