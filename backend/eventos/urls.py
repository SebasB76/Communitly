from django.urls import path

from . import views

urlpatterns = [
    path('eventos/', views.eventos),
    path('eventos/<int:evento_id>/', views.detalle_evento),
]