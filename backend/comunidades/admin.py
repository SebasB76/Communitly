from django.contrib import admin

from .models import Categoria, Comunidad, Seguimiento


@admin.register(Categoria)
class CategoriaAdmin(admin.ModelAdmin):
    list_display = ['nombre']


@admin.register(Comunidad)
class ComunidadAdmin(admin.ModelAdmin):
    list_display = ['nombre', 'categoria', 'activa']
    list_filter = ['categoria', 'activa']
    search_fields = ['nombre', 'descripcion']


@admin.register(Seguimiento)
class SeguimientoAdmin(admin.ModelAdmin):
    list_display = ['estudiante', 'comunidad', 'fecha']
