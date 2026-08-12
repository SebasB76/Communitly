from django.contrib.auth.models import User
from django.db import models

from comunidades.models import Comunidad

class Evento(models.Model):
    """Evento organizado por una comunidad (RF-03 / RF-04)."""

    ACTIVO = 'activo'
    CANCELADO = 'cancelado'
    ESTADOS = [
        (ACTIVO, 'Activo'),
        (CANCELADO, 'Cancelado'),
    ]

    comunidad = models.ForeignKey(
        Comunidad, on_delete=models.CASCADE, related_name='eventos'
    )
    titulo = models.CharField(max_length=150)
    descripcion = models.TextField()
    fecha = models.DateField()
    hora = models.TimeField()
    lugar = models.CharField(max_length=150)
    cupo = models.PositiveIntegerField(null=True, blank=True)
    estado = models.CharField(max_length=10, choices=ESTADOS, default=ACTIVO)
    gestor = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name='eventos_gestionados'
    )
    creado_en = models.DateTimeField(auto_now_add=True)
    actualizado_en = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['fecha', 'hora']

    def __str__(self):
        return f'{self.titulo} ({self.comunidad.nombre})'

    def cancelado(self):
        return self.estado == self.CANCELADO
