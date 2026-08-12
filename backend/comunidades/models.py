from django.contrib.auth.models import User
from django.db import models


class Categoria(models.Model):
    nombre = models.CharField(max_length=50, unique=True)

    def __str__(self):
        return self.nombre


class Comunidad(models.Model):
    nombre = models.CharField(max_length=120)
    descripcion = models.TextField()
    categoria = models.ForeignKey(Categoria, on_delete=models.PROTECT, related_name='comunidades')
    contacto = models.EmailField(blank=True)
    activa = models.BooleanField(default=True)
    creada_en = models.DateTimeField(auto_now_add=True)
    # responsables de la comunidad; controlan eventos (RF-04) y solicitudes (RF-06)
    gestores = models.ManyToManyField(User, related_name='comunidades_gestionadas', blank=True)

    class Meta:
        ordering = ['nombre']
        verbose_name_plural = 'comunidades'

    def __str__(self):
        return self.nombre

    def total_seguidores(self):
        return self.seguidores.count()


class Seguimiento(models.Model):
    estudiante = models.ForeignKey(User, on_delete=models.CASCADE, related_name='seguimientos')
    comunidad = models.ForeignKey(Comunidad, on_delete=models.CASCADE, related_name='seguidores')
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        # un estudiante no puede seguir dos veces la misma comunidad
        constraints = [
            models.UniqueConstraint(fields=['estudiante', 'comunidad'], name='seguimiento_unico')
        ]

    def __str__(self):
        return f'{self.estudiante.username} sigue a {self.comunidad.nombre}'
