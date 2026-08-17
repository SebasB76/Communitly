# Cuentas y permisos — infraestructura compartida

Responsable: **Angel Pilataxi**

Esta app resuelve la autenticación que el resto de módulos daba por pendiente.
No agrega requerimientos funcionales: es la función transversal que RF-01 a
RF-06 necesitaban para saber quién opera y qué puede hacer.

No define modelos propios. Usa el `User` de Django y la relación
`Comunidad.gestores` que ya existía, así que **no hay migraciones nuevas**.

## Qué resuelve

Antes, cada operación recibía un `estudiante_id` o un `gestor_id` en el cuerpo o
en la query string, porque no había forma de saber quién estaba conectado. Ahora:

1. El usuario entra con su usuario y contraseña.
2. El backend valida las credenciales y devuelve su identidad **con sus permisos**.
3. El frontend guarda esa identidad y la usa en las peticiones siguientes.

Las vistas de comunidades, eventos y solicitudes **no cambiaron**: siguen
recibiendo el id y siguen comprobando los permisos por su cuenta. Lo que cambia
es de dónde sale ese id: de una sesión real y no de una constante.

## Endpoints

### `POST /api/sesion/`

```json
{"usuario": "gestor_ciap", "contrasena": "espol2026"}
```

Responde `200` con la identidad y los permisos:

```json
{
  "mensaje": "Sesión iniciada como gestor_ciap",
  "usuario": {
    "id": 3,
    "usuario": "gestor_ciap",
    "nombre": "gestor_ciap",
    "es_gestor": true,
    "comunidades_gestionadas": [{"id": 1, "nombre": "CIAP"}]
  }
}
```

`comunidades_gestionadas` es la pieza clave: permite al frontend saber, sin
adivinar ni provocar un error, qué acciones de gestor ofrecer y sobre qué
comunidad. Un estudiante recibe la lista vacía y `es_gestor` en `false`.

Las comunidades inactivas no se listan, aunque el usuario figure como gestor.

### `GET /api/sesion/?usuario_id=3`

Devuelve el mismo bloque `usuario`, para refrescar los permisos sin volver a
pedir la contraseña (por ejemplo, si a alguien lo nombran gestor de otra
comunidad mientras usa la aplicación).

### Respuestas de error

| Código | Caso |
|---|---|
| 400 | Falta el usuario o la contraseña; falta o es inválido el `usuario_id`. |
| 401 | Usuario o contraseña incorrectos, o la cuenta está desactivada. |
| 404 | El `usuario_id` consultado no existe. |
| 405 | Método HTTP no permitido. |

```json
{"error": "Usuario o contraseña incorrectos"}
```

La respuesta nunca incluye la contraseña ni el hash. `authenticate()` de Django
compara contra el hash almacenado y rechaza las cuentas desactivadas, así que un
usuario inhabilitado no puede entrar aunque acierte la clave.

## Permisos en la interfaz y en el servidor

Ocultar un botón **no** es la validación. El frontend usa
`comunidades_gestionadas` para no ofrecer lo que el usuario no puede hacer, pero
cada vista sigue comprobando el permiso y respondiendo `403` por su cuenta. Las
dos capas son independientes: si alguien llama la API directamente, el resultado
es el mismo que antes.

## Cómo probarlo

```bash
cd backend
python manage.py migrate
python manage.py cargar_datos
python manage.py cargar_solicitudes
python manage.py test cuentas      # 17 pruebas
python manage.py runserver
```

Todas las cuentas de ejemplo usan la contraseña `espol2026`:

| Usuario | Rol |
|---|---|
| `estudiante1`, `estudiante2` | Estudiantes, sin comunidades a cargo. |
| `gestor_ciap` | Gestor de CIAP. |
| `gestor_robota` | Gestor de ROBOTA. |
| `gestor_ieee` | Gestor de IEEE ESPOL Student Branch. |

```bash
curl -X POST http://127.0.0.1:8000/api/sesion/ \
  -H "Content-Type: application/json" \
  -d '{"usuario":"gestor_ciap","contrasena":"espol2026"}'
```
