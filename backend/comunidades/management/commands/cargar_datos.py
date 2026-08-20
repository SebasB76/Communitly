from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from comunidades.models import Categoria, Comunidad

COMUNIDADES = [
    ('CIAP', 'Tecnología',
     'Promovemos el aprendizaje e investigación en inteligencia artificial y análisis de datos, '
     'ofreciendo talleres, conferencias y proyectos colaborativos para desarrollar habilidades '
     'aplicables en el entorno empresarial.',
     'ciap@espol.edu.ec', True, 'ciap.png'),
    ('TAWS', 'Tecnología',
     'Buscamos contribuir a la formación integral de jóvenes investigadores precursores en el '
     'desarrollo de tecnologías de la información.',
     'taws@espol.edu.ec', True, 'taws.png'),
    ('NIOT', 'Tecnología',
     'Fomentamos la investigación, innovación y desarrollo tecnológico en TI, comunicaciones e IoT, '
     'impulsando la participación en programas educativos y concursos.',
     'niot@espol.edu.ec', True, 'niot.png'),
    ('KOKOA', 'Tecnología',
     'Investigadores y estudiantes interesados en promover el uso y distribución del Software Libre, '
     'con la convicción de que el software debe ser un recurso accesible para todos.',
     'kokoa@espol.edu.ec', True, 'kokoa.png'),
    ('PHYCOM', 'Tecnología',
     'Impulsa el aprendizaje de electrónica, programación y robótica con proyectos creativos, '
     'inclusivos e interdisciplinarios, combinando ciencia, arte y resolución de problemas.',
     'phycom@espol.edu.ec', True, 'phycom.png'),
    ('IEEE ESPOL Student Branch', 'Tecnología',
     'Organización sin fines de lucro que fomenta y promueve la investigación, desarrollando el '
     'interés de los futuros ingenieros en la consecución de avances tecnológicos.',
     'ieee@espol.edu.ec', True, 'ieee.png'),
    ('AEFIEC', 'Tecnología',
     'La Asociación Estudiantil de la FIEC promueve actividades culturales, deportivas y '
     'profesionales en pro de los estudiantes de las diferentes carreras.',
     'aefiec@espol.edu.ec', True, 'aefiec.png'),
    ('Célula Estudiantil Microsoft', 'Tecnología',
     'Fomentamos el estudio e investigación en tecnologías como ingeniería de software, robótica e '
     'interacción humano-máquina, para generar soluciones con impacto técnico, ambiental y social.',
     'celula@espol.edu.ec', True, 'celula.png'),
    ('ROBOTA', 'Tecnología',
     'Club de Robótica de ESPOL. Construcción de robots, talleres de Arduino y competencias '
     'nacionales.',
     'robota@espol.edu.ec', True, ''),
    ('GISSC', 'Ciencias',
     'Proporciona nexos entre los miembros del club e investigadores para involucrarse en '
     'actividades multidisciplinares con el uso de los Sistemas de Información Geográfica (GIS) y '
     'teledetección a nivel regional.',
     'gissc@espol.edu.ec', True, 'gissc.png'),
    ('IFT ESPOL', 'Ciencias',
     'Capítulo estudiantil que representa a la institución internacional más importante de '
     'ingeniería en alimentos, contribuyendo al perfil profesional desde los inicios de la carrera.',
     'ift@espol.edu.ec', True, 'ift.png'),
    ('AAPG', 'Ciencias',
     'Proporciona a sus miembros habilidades valiosas para su vida profesional mediante '
     'conferencias, cursos y actividades con información actualizada sobre la ciencia de la '
     'geología del petróleo.',
     'aapg@espol.edu.ec', True, 'aapg.jpg'),
    ('CIMAT', 'Ciencias',
     'Club de Ciencias e Ingeniería en Materiales. Investigación, visitas técnicas y charlas del '
     'área de materiales.',
     'cimat@espol.edu.ec', True, ''),
    ('Politécnicas en STEAM', 'Ciencias',
     'Comunidad que promueve la participación de mujeres en ciencia, tecnología, ingeniería, arte y '
     'matemáticas.',
     'steam@espol.edu.ec', True, ''),
    ('IISE ESPOL', 'Ingeniería',
     'Capítulo estudiantil del Institute of Industrial Engineers, dedicado a la difusión de los '
     'conocimientos y aplicaciones de la Ingeniería Industrial.',
     'iise@espol.edu.ec', True, 'iise.png'),
    ('ASME ESPOL', 'Ingeniería',
     'Sociedad sin fines de lucro que busca servir a los futuros ingenieros en su formación '
     'académica, mediante la organización de cursos, charlas, capacitaciones y demás actividades '
     'que permitan obtener un crecimiento profesional.',
     'asme@espol.edu.ec', True, 'asme.png'),
    ('ASCE ESPOL', 'Ingeniería',
     'La American Society of Civil Engineers en ESPOL fomenta la interacción entre el ámbito '
     'académico y profesional de la Ingeniería Civil a través de investigaciones, ponencias, '
     'capacitaciones y visitas técnicas.',
     'asce@espol.edu.ec', True, 'asce.png'),
    ('Club de Mecatrónica', 'Ingeniería',
     'Impulsa el desarrollo de competencias en el ámbito tecnológico, particularmente en sistemas '
     'mecatrónicos, IoT, manufactura aditiva, software y aplicaciones para el control y '
     'automatización de procesos.',
     'mecatronica@espol.edu.ec', True, 'mecatronica.png'),
    ('SPE ESPOL', 'Ingeniería',
     'Capítulo estudiantil de la Society of Petroleum Engineers. Charlas técnicas y visitas al '
     'sector energético.',
     'spe@espol.edu.ec', True, ''),
    ('SME ESPOL', 'Ingeniería',
     'Capítulo estudiantil SME. Actividades técnicas y networking profesional para estudiantes de '
     'ingeniería.',
     'sme@espol.edu.ec', True, ''),
    ('CLIP', 'Negocios',
     'Impulsa la carrera de Ingeniería en Logística y Transporte mediante la investigación y '
     'desarrollo de proyectos multidisciplinarios que beneficien a la sociedad y a la comunidad '
     'politécnica.',
     'clip@espol.edu.ec', True, 'clip.png'),
    ('CADIEC', 'Negocios',
     'Club de Aplicación, Desarrollo e Investigaciones Económicas. Análisis económico, seminarios y '
     'publicaciones.',
     'cadiec@espol.edu.ec', True, ''),
    ('Tweening', 'Arte',
     'Club de ilustración, animación y guion. Sus actividades permiten a cada miembro mejorar sus '
     'habilidades estéticas y gramaticales, creando piezas originales con estilos diferentes.',
     'tweening@espol.edu.ec', True, 'tweening.png'),
    ('BREIK', 'Arte',
     'Club de comunicación audiovisual. Producción de video, fotografía y proyectos multimedia.',
     'breik@espol.edu.ec', True, ''),
    ('Argumentum', 'Cultura',
     'Crea líderes de opinión y pensamiento crítico capaces de expandir la cultura del debate y la '
     'oratoria, mediante actividades formativas y evaluativas para sus miembros.',
     'argumentum@espol.edu.ec', True, 'argumentum.png'),
    ('FANPOL', 'Cultura',
     'Club cultural fundado por estudiantes de la ESPOL que convierte el interés por la cultura y '
     'las tendencias de la sociedad asiática en actividades didácticas y recreativas.',
     'fanpol@espol.edu.ec', True, 'fanpol.png'),
    ('Acción Universitaria', 'Cultura',
     'Promovemos líderes jóvenes comprometidos con el cambio del mundo desde una perspectiva '
     'católica.',
     'accion@espol.edu.ec', True, 'accion.png'),
    ('Acción Cultural Politécnica', 'Cultura',
     'Club cultural de la comunidad politécnica de la ESPOL.',
     'acp@espol.edu.ec', True, 'acp.png'),
    ('Club de Arqueología', 'Cultura',
     'Fomenta, promueve e incentiva el conocimiento de la arqueología y la antropología desde una '
     'nueva relación entre el ser humano y la historia, contribuyendo al redescubrimiento del '
     'pasado y la identidad cultural en la región.',
     'arqueologia@espol.edu.ec', False, 'arqueologia.jpg'),
]

ESTUDIANTES = ['estudiante1', 'estudiante2']


class Command(BaseCommand):
    help = 'Carga categorias, comunidades y estudiantes de prueba'

    def handle(self, *args, **options):
        for nombre, categoria, descripcion, contacto, activa, logo in COMUNIDADES:
            cat, _ = Categoria.objects.get_or_create(nombre=categoria)
            Comunidad.objects.update_or_create(
                nombre=nombre,
                defaults={
                    'descripcion': descripcion,
                    'categoria': cat,
                    'contacto': contacto,
                    'activa': activa,
                    'logo': logo,
                },
            )

        for username in ESTUDIANTES:
            if not User.objects.filter(username=username).exists():
                User.objects.create_user(username=username, password='espol2026')

        con_logo = Comunidad.objects.exclude(logo='').count()
        self.stdout.write(self.style.SUCCESS(
            f'Listo: {Categoria.objects.count()} categorias, '
            f'{Comunidad.objects.count()} comunidades ({con_logo} con logo), '
            f'{User.objects.count()} usuarios'
        ))
