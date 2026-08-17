#!/bin/sh
set -e

echo "==> Aplicando migraciones"
python manage.py migrate --noinput

# Los tres comandos son idempotentes: se pueden correr en cada arranque.
if [ "${SEED_DATA:-1}" = "1" ]; then
  echo "==> Cargando datos de ejemplo"
  python manage.py cargar_datos
  python manage.py cargar_solicitudes
  python manage.py cargar_eventos
fi

exec "$@"
