from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from comunidades.models import Categoria, Comunidad

# (nombre, categoria, descripcion, contacto, activa)
COMUNIDADES = [
    ('Rama IEEE ESPOL', 'Tecnologia',
     'Espacio para estudiantes interesados en tecnologia, proyectos y actividades de vinculacion.',
     'ieee@espol.edu.ec', True),
    ('Club de Ajedrez', 'Deportes',
     'Practicas semanales y torneos internos de ajedrez para toda la comunidad politecnica.',
     'ajedrez@espol.edu.ec', True),
    ('Club de Fotografia', 'Arte',
     'Salidas fotograficas, talleres de edicion y exposiciones dentro del campus.',
     'foto@espol.edu.ec', True),
    ('Grupo de Danza Folclorica', 'Cultura',
     'Ensayos y presentaciones de danza tradicional ecuatoriana en eventos de la universidad.',
     'danza@espol.edu.ec', True),
    ('ESPOL Game Dev', 'Tecnologia',
     'Comunidad de desarrollo de videojuegos, game jams y proyectos con Unity y Godot.',
     'gamedev@espol.edu.ec', True),
    ('Club de Robotica', 'Tecnologia',
     'Construccion de robots para competencias nacionales y talleres de Arduino.',
     'robotica@espol.edu.ec', True),
    ('Club de Futbol', 'Deportes',
     'Entrenamientos y campeonatos interfacultades de futbol masculino y femenino.',
     'futbol@espol.edu.ec', True),
    ('Club de Teatro', 'Arte',
     'Comunidad inactiva por el momento, se mantiene en el sistema como historial.',
     'teatro@espol.edu.ec', False),
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
