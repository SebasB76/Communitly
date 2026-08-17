from django.urls import path

from . import views

urlpatterns = [
    # POST inicia sesion, GET consulta los permisos vigentes
    path('sesion/', views.sesion),
]
