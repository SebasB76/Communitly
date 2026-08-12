import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('comunidades', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Evento',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('titulo', models.CharField(max_length=150)),
                ('descripcion', models.TextField()),
                ('fecha', models.DateField()),
                ('hora', models.TimeField()),
                ('lugar', models.CharField(max_length=150)),
                ('cupo', models.PositiveIntegerField(blank=True, null=True)),
                ('estado', models.CharField(choices=[('activo', 'Activo'), ('cancelado', 'Cancelado')], default='activo', max_length=10)),
                ('creado_en', models.DateTimeField(auto_now_add=True)),
                ('actualizado_en', models.DateTimeField(auto_now=True)),
                ('comunidad', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='eventos', to='comunidades.comunidad')),
                ('gestor', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='eventos_gestionados', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['fecha', 'hora'],
            },
        ),
    ]
