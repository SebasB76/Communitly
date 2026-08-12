from django.contrib import admin

from .models import Evento


@admin.register(Evento)
class EventoAdmin(admin.ModelAdmin):
    list_display = ('titulo', 'comunidad', 'fecha', 'hora', 'cupo', 'estado', 'gestor')
    list_filter = ('estado', 'comunidad')
    search_fields = ('titulo', 'descripcion', 'lugar')
