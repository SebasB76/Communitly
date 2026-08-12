from datetime import date, time, timedelta

from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from comunidades.models import Comunidad
from eventos.models import Evento

GESTORES = ['gestor1']


class Command(BaseCommand):
    help = 'Crea un gestor y algunos eventos de prueba para RF-03/RF-04'

    def handle(self, *args, **options):
        for username in GESTORES:
            if not User.objects.filter(username=username).exists():
                User.objects.create_user(username=username, password='espol2026')
        gestor = User.objects.filter(username=GESTORES[0]).first()

        comunidades = list(Comunidad.objects.filter(activa=True)[:3])
        if not comunidades:
            self.stdout.write(self.style.WARNING(
                'No hay comunidades cargadas. Corre primero "python manage.py cargar_datos".'
            ))
            return

        hoy = date.today()
        datos_eventos = [
            (comunidades[0], 'Taller de introducción', hoy + timedelta(days=3), time(15, 0), 'Aula 12, FIEC', 30),
            (comunidades[0 if len(comunidades) == 1 else 1], 'Charla de proyectos', hoy + timedelta(days=10), time(17, 30), 'Auditorio principal', None),
            (comunidades[-1], 'Evento pasado (para pruebas de filtro)', hoy - timedelta(days=5), time(10, 0), 'Coliseo ESPOL', 50),
        ]

        creados = 0
        for comunidad, titulo, fecha, hora, lugar, cupo in datos_eventos:
            _, creado = Evento.objects.get_or_create(
                comunidad=comunidad,
                titulo=titulo,
                defaults={
                    'descripcion': f'Evento de prueba organizado por {comunidad.nombre}.',
                    'fecha': fecha,
                    'hora': hora,
                    'lugar': lugar,
                    'cupo': cupo,
                    'gestor': gestor,
                },
            )
            creados += 1 if creado else 0

        self.stdout.write(self.style.SUCCESS(
            f'Listo: {creados} eventos nuevos creados. Gestor de prueba: {GESTORES[0]} / espol2026'
        ))
