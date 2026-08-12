from django.contrib import admin

from .models import Solicitud


@admin.register(Solicitud)
class SolicitudAdmin(admin.ModelAdmin):
    list_display = ['estudiante', 'comunidad', 'estado', 'creada_en', 'resuelta_por']
    list_filter = ['estado', 'comunidad']
    search_fields = ['estudiante__username', 'comunidad__nombre']
