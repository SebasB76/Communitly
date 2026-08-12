from django.urls import path

from . import views

urlpatterns = [
    path('comunidades/', views.listar_comunidades),
    path('comunidades/<int:comunidad_id>/', views.detalle_comunidad),
]
