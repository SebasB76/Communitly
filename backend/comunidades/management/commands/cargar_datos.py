from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from comunidades.models import Categoria, Comunidad

# (nombre, categoria, descripcion, contacto, activa)
COMUNIDADES = [
    ('CIAP', 'Tecnología',
     'Club de Inteligencia Artificial Politécnico. Charlas, talleres y proyectos de machine learning y ciencia de datos.',
     'ciap@espol.edu.ec', True),
    ('TAWS', 'Tecnología',
     'Comunidad de estudiantes de computación enfocada en desarrollo de software y proyectos web.',
     'taws@espol.edu.ec', True),
    ('NIOT', 'Tecnología',
     'Club de computación dedicado a redes, internet de las cosas y sistemas embebidos.',
     'niot@espol.edu.ec', True),
    ('KOKOA', 'Tecnología',
     'Comunidad de computación que organiza talleres de programación y proyectos colaborativos.',
     'kokoa@espol.edu.ec', True),
    ('PHYCOM', 'Tecnología',
     'Club de computación con actividades de programación competitiva y desarrollo de proyectos.',
     'phycom@espol.edu.ec', True),
    ('ROBOTA', 'Tecnología',
     'Club de Robótica de ESPOL. Construcción de robots, talleres de Arduino y competencias nacionales.',
     'robota@espol.edu.ec', True),
    ('IEEE ESPOL Student Branch', 'Tecnología',
     'Rama estudiantil IEEE. Conferencias, concursos y proyectos de ingeniería eléctrica y computación.',
     'ieee@espol.edu.ec', True),
    ('GISSC', 'Ciencias',
     'Geographic Information System Student Club. Talleres de sistemas de información geográfica y análisis espacial.',
     'gissc@espol.edu.ec', True),
    ('CIMAT', 'Ciencias',
     'Club de Ciencias e Ingeniería en Materiales. Investigación, visitas técnicas y charlas del área de materiales.',
     'cimat@espol.edu.ec', True),
    ('IFT ESPOL', 'Ciencias',
     'Capítulo ESPOL del Institute of Food Technologists. Actividades sobre ciencia y tecnología de alimentos.',
     'ift@espol.edu.ec', True),
    ('Politécnicas en STEAM', 'Ciencias',
     'Comunidad que promueve la participación de mujeres en ciencia, tecnología, ingeniería, arte y matemáticas.',
     'steam@espol.edu.ec', True),
    ('IISE ESPOL', 'Ingeniería',
     'Capítulo 771 del Institute of Industrial and Systems Engineers. Talleres y competencias de ingeniería industrial.',
     'iise@espol.edu.ec', True),
    ('SPE ESPOL', 'Ingeniería',
     'Capítulo estudiantil de la Society of Petroleum Engineers. Charlas técnicas y visitas al sector energético.',
     'spe@espol.edu.ec', True),
    ('SME ESPOL', 'Ingeniería',
     'Capítulo estudiantil SME. Actividades técnicas y networking profesional para estudiantes de ingeniería.',
     'sme@espol.edu.ec', True),
    ('CADIEC', 'Negocios',
     'Club de Aplicación, Desarrollo e Investigaciones Económicas. Análisis económico, seminarios y publicaciones.',
     'cadiec@espol.edu.ec', True),
    ('CLIP', 'Negocios',
     'Club Logístico Mercantil Politécnico. Actividades sobre logística, comercio exterior y cadena de suministro.',
     'clip@espol.edu.ec', True),
    ('BREIK', 'Arte',
     'Club de comunicación audiovisual. Producción de video, fotografía y proyectos multimedia.',
     'breik@espol.edu.ec', True),
    ('Club de Arqueología', 'Cultura',
     'Comunidad dedicada a la difusión del patrimonio arqueológico y salidas de campo.',
     'arqueologia@espol.edu.ec', False),
]

ESTUDIANTES = ['estudiante1', 'estudiante2']


class Command(BaseCommand):
    help = 'Carga categorias, comunidades y estudiantes de prueba'

    def handle(self, *args, **options):
        for nombre, categoria, descripcion, contacto, activa in COMUNIDADES:
            cat, _ = Categoria.objects.get_or_create(nombre=categoria)
            Comunidad.objects.get_or_create(
                nombre=nombre,
                defaults={
                    'descripcion': descripcion,
                    'categoria': cat,
                    'contacto': contacto,
                    'activa': activa,
                },
            )

        for username in ESTUDIANTES:
            if not User.objects.filter(username=username).exists():
                User.objects.create_user(username=username, password='espol2026')

        self.stdout.write(self.style.SUCCESS(
            f'Listo: {Categoria.objects.count()} categorias, '
            f'{Comunidad.objects.count()} comunidades, '
            f'{User.objects.count()} usuarios'
        ))
