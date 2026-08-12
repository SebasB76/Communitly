# Solicitudes de ingreso — RF-05 y RF-06

Responsable: **Angel Pilataxi**

| Requerimiento | Tipo | Descripción |
|---|---|---|
| RF-05 · Consultar solicitudes | Lectura | El estudiante consulta el estado de sus solicitudes y el gestor las solicitudes recibidas por su comunidad. |
| RF-06 · Gestionar solicitudes de ingreso | Escritura | El estudiante envía o retira una solicitud; el gestor la aprueba o rechaza con una observación opcional. |

La lógica de negocio está escrita en Python (`models.py` y `views.py`); Django se usa
como apoyo estructural para el enrutamiento y el acceso a datos. Las respuestas son
JSON, para que el frontend en Dart las consuma por HTTP.

## Modelo `Solicitud`

| Campo | Descripción |
|---|---|
| `estudiante` | Usuario que postula. |
| `comunidad` | Comunidad a la que postula. |
| `mensaje` | Motivo o interés del estudiante (opcional, máx. 500 caracteres). |
| `estado` | `pendiente`, `aprobada`, `rechazada` o `retirada`. |
| `observacion` | Comentario opcional del gestor al resolver (máx. 500 caracteres). |
| `resuelta_por`, `resuelta_en` | Gestor y fecha de la resolución. |
| `creada_en`, `actualizada_en` | Fechas de control. |

Reglas garantizadas por el modelo y las vistas:

- **No se duplican solicitudes pendientes:** una restricción única parcial
  (`estudiante`, `comunidad`) sobre el estado `pendiente` lo impide en la base de datos,
  y la vista además responde con un mensaje claro.
- **Se conserva el historial:** retirar o rechazar no borra el registro; solo cambia su
  estado. Por eso un estudiante rechazado o que retiró su solicitud sí puede volver a
  postular, pero uno ya aprobado no.
- **Solo el gestor autorizado resuelve:** las vistas verifican que el usuario esté en
  `Comunidad.gestores` de esa comunidad; en caso contrario responden 403.

## Identificación del usuario

La autenticación es infraestructura compartida y todavía no está implementada, así que
—igual que en RF-01 y RF-02— el id del usuario viaja en el cuerpo JSON o en la query
string: `estudiante_id` para el estudiante y `gestor_id` para el gestor. Al conectar la
autenticación institucional, basta reemplazar `obtener_usuario()` en `views.py`.

## Endpoints

Todos cuelgan de `/api/`.

### RF-05 · Consultar solicitudes

#### `GET /api/solicitudes/?estudiante_id=1[&estado=pendiente]`

Solicitudes enviadas por el estudiante. `resumen` trae el conteo por estado y **no**
cambia con el filtro, para alimentar las pestañas de la interfaz.

```json
{
  "total": 2,
  "resumen": {"pendiente": 1, "aprobada": 1, "rechazada": 0, "retirada": 0},
  "solicitudes": [
    {
      "id": 5,
      "estado": "aprobada",
      "estado_texto": "Aprobada",
      "mensaje": "Tengo experiencia con Arduino",
      "observacion": "Bienvenido, te esperamos el viernes.",
      "comunidad": {"id": 6, "nombre": "ROBOTA"},
      "estudiante": {"id": 1, "usuario": "estudiante1"},
      "creada_en": "2026-08-11T20:14:49.664198+00:00",
      "resuelta_en": "2026-08-12T01:02:03.000000+00:00",
      "resuelta_por": "gestor_robota"
    }
  ]
}
```

#### `GET /api/comunidades/<id>/solicitudes/?gestor_id=3[&estado=pendiente]`

Bandeja del gestor: solicitudes recibidas por esa comunidad. Agrega la clave
`comunidad`. Responde 403 si quien consulta no es gestor de la comunidad.

#### `GET /api/solicitudes/<id>/?estudiante_id=1` (o `?gestor_id=3`)

Detalle de una solicitud. Solo la puede ver el estudiante que la envió o un gestor de
la comunidad.

### RF-06 · Gestionar solicitudes de ingreso

#### `POST /api/comunidades/<id>/solicitar/`

```json
{"estudiante_id": 1, "mensaje": "Me interesa el machine learning"}
```

Responde `201` con la solicitud creada. `mensaje` es opcional.

#### `DELETE /api/comunidades/<id>/solicitar/`

```json
{"estudiante_id": 1}
```

Retira la solicitud pendiente: pasa a estado `retirada` y se conserva en el historial.

#### `POST /api/solicitudes/<id>/resolver/`

```json
{"gestor_id": 3, "accion": "aprobar", "observacion": "Bienvenido al club"}
```

`accion` debe ser `aprobar` o `rechazar`; `observacion` es opcional. Solo funciona
sobre solicitudes pendientes.

### Respuestas de error

Toda operación devuelve confirmación o un mensaje de validación comprensible:

| Código | Casos |
|---|---|
| 400 | Falta `estudiante_id`/`gestor_id`, solicitud pendiente duplicada, estudiante ya aprobado, acción o estado inválido, solicitud ya resuelta, texto demasiado largo. |
| 403 | El usuario no es gestor de la comunidad o no es dueño de la solicitud. |
| 404 | La comunidad no existe o está inactiva; la solicitud no existe. |
| 405 | Método HTTP no permitido. |

```json
{"error": "Ya tienes una solicitud pendiente en CIAP"}
```

## Cómo probarlo

```bash
cd backend
python manage.py migrate
python manage.py cargar_datos         # comunidades y estudiantes (RF-01)
python manage.py cargar_solicitudes   # gestores y solicitudes de ejemplo
python manage.py test solicitudes     # 47 pruebas
python manage.py runserver
```

`cargar_solicitudes` crea los gestores `gestor_ciap`, `gestor_robota` y `gestor_ieee`
(contraseña `espol2026`), los asigna a su comunidad y carga solicitudes de ejemplo en
los cuatro estados. Ambos comandos son idempotentes.
