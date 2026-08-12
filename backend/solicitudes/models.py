from django.contrib.auth.models import User
from django.db import models

from comunidades.models import Comunidad


class Solicitud(models.Model):
    """Solicitud de ingreso de un estudiante a una comunidad (RF-05 y RF-06)."""

    PENDIENTE = 'pendiente'
    APROBADA = 'aprobada'
    RECHAZADA = 'rechazada'
    RETIRADA = 'retirada'

    ESTADOS = [
        (PENDIENTE, 'Pendiente'),
        (APROBADA, 'Aprobada'),
        (RECHAZADA, 'Rechazada'),
        (RETIRADA, 'Retirada'),
    ]

    # acciones que el gestor puede ejecutar sobre una solicitud pendiente
    RESOLUCIONES = {'aprobar': APROBADA, 'rechazar': RECHAZADA}

    estudiante = models.ForeignKey(User, on_delete=models.CASCADE, related_name='solicitudes')
    comunidad = models.ForeignKey(Comunidad, on_delete=models.CASCADE, related_name='solicitudes')
    # motivo o interes que escribe el estudiante al postular
    mensaje = models.TextField(blank=True)
    estado = models.CharField(max_length=12, choices=ESTADOS, default=PENDIENTE)
    # observacion opcional que deja el gestor al aprobar o rechazar
    observacion = models.TextField(blank=True)
    resuelta_por = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='solicitudes_resueltas',
    )
    resuelta_en = models.DateTimeField(null=True, blank=True)
    creada_en = models.DateTimeField(auto_now_add=True)
    actualizada_en = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-creada_en']
        constraints = [
            # un estudiante no puede duplicar una solicitud pendiente en la misma
            # comunidad; las resueltas si se conservan para el historial
            models.UniqueConstraint(
                fields=['estudiante', 'comunidad'],
                condition=models.Q(estado='pendiente'),
                name='solicitud_pendiente_unica',
            )
        ]

    def __str__(self):
        return f'{self.estudiante.username} -> {self.comunidad.nombre} ({self.estado})'

    @property
    def pendiente(self):
        return self.estado == self.PENDIENTE
