from django.urls import path

from . import views

urlpatterns = [
    # RF-05: consultar solicitudes
    path('solicitudes/', views.mis_solicitudes),
    path('solicitudes/<int:solicitud_id>/', views.detalle_solicitud),
    path('comunidades/<int:comunidad_id>/solicitudes/', views.solicitudes_comunidad),
    # RF-06: gestionar solicitudes de ingreso
    path('comunidades/<int:comunidad_id>/solicitar/', views.solicitar_ingreso),
    path('solicitudes/<int:solicitud_id>/resolver/', views.resolver_solicitud),
]
