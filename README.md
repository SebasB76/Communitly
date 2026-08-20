# ESPOL Communities

Plataforma web para descubrir y gestionar los clubes y comunidades estudiantiles de ESPOL.
Backend en **Python (Django)** y frontend en **Dart (Flutter Web)**, comunicados por HTTP con JSON.

Proyecto de la materia Lenguajes de Programación — Sebastian Barco, Angel Cedeño y Angel Pilataxi.

## Herramientas y versiones

| Herramienta | Versión | Uso |
|---|---|---|
| Python | 3.12 o superior | Lenguaje del backend |
| Django | 6.0.7 | Framework de apoyo del backend |
| django-cors-headers | 4.9.0 | Permite que el navegador consuma la API desde otro puerto |
| Flutter | 3.47.0 (estable) | Framework de apoyo del frontend |
| Dart | 3.13.0 | Lenguaje del frontend (viene incluido con Flutter) |
| SQLite | incluido con Python | Base de datos |
| Google Chrome | reciente | Navegador donde corre la app |

Los paquetes exactos del backend están en `backend/requirements.txt` y los del frontend en
`frontend/pubspec.yaml` (los principales: `http`, `go_router`, `shared_preferences`, `intl`).

También se puede levantar todo con Docker: ver [DOCKER.md](DOCKER.md).

## Probar el backend

Desde la carpeta del repositorio:

```
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py cargar_datos
python manage.py cargar_eventos
python manage.py cargar_solicitudes
python manage.py runserver
```

Los tres comandos `cargar_*` llenan la base con datos de prueba (comunidades con sus logos,
eventos, solicitudes y usuarios). Solo hacen falta la primera vez.

El servidor queda en `http://127.0.0.1:8000`. Pruebas rápidas desde el navegador:

- `http://127.0.0.1:8000/api/comunidades/` — catálogo de comunidades activas
- `http://127.0.0.1:8000/api/comunidades/?q=robot` — búsqueda por texto
- `http://127.0.0.1:8000/api/eventos/` — próximos eventos

Las operaciones de escritura (POST/DELETE) se pueden probar con curl o Postman, por ejemplo:

```
curl -X POST http://127.0.0.1:8000/api/comunidades/9/seguir/ -H "Content-Type: application/json" -d "{\"estudiante_id\": 1}"
```

Para correr las pruebas automatizadas del backend:

```
python manage.py test
```

## Probar el frontend

Con el backend corriendo, en otra terminal:

```
cd frontend
flutter pub get
flutter run -d chrome --web-port=5000
```

Se abre Chrome con la aplicación. Si la API corre en otra dirección, se puede cambiar al compilar
con `--dart-define=API_BASE=http://otra-direccion/api`.

Para correr las pruebas y el análisis estático del frontend:

```
flutter analyze
flutter test
```

## Usuarios de prueba

Todos con la contraseña `espol2026`:

| Usuario | Rol |
|---|---|
| `estudiante1` | Estudiante |
| `estudiante2` | Estudiante |
| `gestor_ciap` | Gestor de CIAP |
| `gestor_taws` | Gestor de TAWS |
| `gestor_robota` | Gestor de ROBOTA |
| `gestor_ieee` | Gestor de IEEE ESPOL Student Branch |

Con un usuario estudiante se puede buscar comunidades, seguirlas, ver eventos y enviar
solicitudes de ingreso. Con un usuario gestor además se pueden crear, editar y cancelar los
eventos de su comunidad y aprobar o rechazar las solicitudes recibidas.

## Estructura del repositorio

```
backend/    proyecto Django (apps: comunidades, eventos, solicitudes, cuentas)
frontend/   aplicación Flutter Web (lib/modelos, lib/servicios, lib/pantallas)
```
