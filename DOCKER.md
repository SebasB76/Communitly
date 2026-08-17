# Communitly con Docker

Levanta el backend (Django + SQLite) y el frontend (Flutter web) sin instalar
Python ni el SDK de Flutter en la maquina. Solo hace falta Docker Desktop.

## Arranque

```bash
docker compose up --build
```

| Servicio | URL | Que es |
|---|---|---|
| `backend` | http://localhost:8000/api/ | API de Django |
| `frontend` | http://localhost:8080 | Flutter web compilado, servido por nginx |

La primera vez tarda: baja el SDK de Flutter y compila el bundle web.

El backend aplica las migraciones y carga los datos de ejemplo en cada arranque;
los tres comandos (`cargar_datos`, `cargar_solicitudes`, `cargar_eventos`) son
idempotentes, asi que repetirlos no duplica nada. Para arrancar con la base vacia,
pon `SEED_DATA: "0"` en `docker-compose.yml`.

Para apagar todo:

```bash
docker compose down
```

## Si un puerto esta ocupado

`docker compose up` falla con `ports are not available` cuando otro programa ya
usa el puerto. Los tres puertos del host son configurables: copia `.env.example`
a `.env` y cambia el que choque.

```bash
cp .env.example .env    # en PowerShell: copy .env.example .env
```

```ini
BACKEND_PORT=8000
FRONTEND_PORT=8080
FRONTEND_DEV_PORT=8081
```

Tambien sirve una sola vez, sin crear el archivo:

```bash
FRONTEND_PORT=8085 docker compose up
```

Si cambias `BACKEND_PORT`, reconstruye el frontend: la URL de la API se compila
dentro del bundle.

```bash
docker compose build frontend
```

## Solo el backend

```bash
docker compose up backend
```

Comprobacion rapida:

```bash
curl "http://localhost:8000/api/comunidades/?estudiante_id=1"
curl "http://localhost:8000/api/solicitudes/?estudiante_id=1"
```

Usuarios de prueba: `estudiante1` (id 1) y los gestores `gestor_ciap`,
`gestor_robota`, `gestor_ieee` y `gestor1`, todos con contrasena `espol2026`.

## Comandos de Django dentro del contenedor

```bash
docker compose exec backend python manage.py test
docker compose exec backend python manage.py createsuperuser
docker compose exec backend python manage.py shell
```

Si el contenedor no esta arriba, usa `run --rm` en lugar de `exec`:

```bash
docker compose run --rm backend python manage.py test
```

## Frontend en modo desarrollo

El servicio `frontend` sirve un build de produccion: cada cambio en Dart obliga a
reconstruir la imagen. Para trabajar con recarga, usa el perfil `dev`, que corre
el SDK de Flutter dentro del contenedor:

```bash
docker compose --profile dev up frontend-dev
```

Queda en http://localhost:8081 (puerto distinto para no chocar con el servicio
`frontend`). La consola queda interactiva: `R` recarga y `q` sale.

## Detalles que conviene saber

- **La base de datos vive en el host.** `./backend` esta montado como volumen, asi
  que `backend/db.sqlite3` es el mismo archivo dentro y fuera del contenedor. El
  `.venv` de Windows queda tapado por un volumen anonimo, porque no sirve en Linux.
- **`runserver` recarga solo.** Al ser volumen montado, editar un `.py` reinicia el
  servidor sin reconstruir la imagen.
- **La version de Flutter esta fijada.** `frontend/Dockerfile` baja el SDK oficial
  3.47.0, que es el primero con Dart 3.13 (lo que exige `pubspec.yaml`). Las
  imagenes de Flutter de la comunidad van atrasadas y no sirven. Para cambiarla:
  `docker compose build --build-arg FLUTTER_VERSION=3.48.0 frontend`.
- **La URL de la API se fija al compilar.** `frontend/lib/servicios/api.dart` la lee
  de `--dart-define=API_BASE`, con `http://127.0.0.1:8000/api` por defecto. El
  `docker-compose.yml` la pasa como `API_BASE: http://localhost:8000/api` porque el
  navegador corre en el host, no dentro de la red de Docker.
- **CORS ya esta abierto** (`CORS_ALLOW_ALL_ORIGINS = True`), por eso el frontend en
  el puerto 8080 puede llamar al backend en el 8000.
- **Esto es para desarrollo.** `DEBUG = True`, `SECRET_KEY` en el codigo y el
  servidor de desarrollo de Django no son configuracion de produccion.

## Sin Docker

Ver los pasos con `venv` en `backend/solicitudes/README.md`.
