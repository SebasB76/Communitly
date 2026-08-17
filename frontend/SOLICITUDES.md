# Frontend de solicitudes — RF-05 y RF-06

Responsable: **Angel Pilataxi**

Contraparte en Dart del módulo `backend/solicitudes`. La lógica está escrita en
Dart —conversión del JSON, estado de las pantallas, validación de la interacción—
y Flutter se usa como apoyo para construir la interfaz. El frontend no toca la
base de datos: todo llega por HTTP desde las vistas en Python.

| Requerimiento | Qué hace el estudiante | Qué hace el gestor |
|---|---|---|
| RF-05 · Consultar solicitudes | Ve el estado de cada solicitud que envió. | Ve la bandeja de su comunidad. |
| RF-06 · Gestionar solicitudes | Envía o retira su solicitud. | Aprueba o rechaza con una observación. |

## Archivos

| Archivo | Contenido |
|---|---|
| `lib/modelos/solicitud.dart` | `Solicitud`, `ResumenSolicitudes` y `ListaSolicitudes`. |
| `lib/servicios/api_solicitudes.dart` | Las cinco llamadas HTTP del módulo. |
| `lib/pantallas/mis_solicitudes.dart` | Pantalla del estudiante (RF-05 + retiro). |
| `lib/pantallas/bandeja_gestor.dart` | Pantalla del gestor (RF-05 + resolución). |
| `lib/pantallas/solicitudes_widgets.dart` | Piezas compartidas y botón de ingreso. |
| `test/solicitud_test.dart` | 15 pruebas de conversión, errores e interfaz. |

Reutiliza `Api.base` y `Api.estudianteId` de `lib/servicios/api.dart`, para no
duplicar la configuración que ya definió el módulo de comunidades.

Sesión y permisos, que son compartidos y los usa toda la aplicación:

| Archivo | Contenido |
|---|---|
| `lib/modelos/usuario.dart` | `UsuarioSesion` y las comunidades que gestiona. |
| `lib/servicios/sesion.dart` | Sesión activa y consulta de permisos. |
| `lib/servicios/api_sesion.dart` | Login y refresco de permisos. |
| `lib/pantallas/login.dart` | Pantalla de entrada. |
| `test/sesion_test.dart` | 11 pruebas de sesión y permisos. |

## Modelos

`Solicitud` refleja campo por campo lo que arma `solicitud_a_dict()` en Python.
Aprovecha el tipado estático de Dart: las fechas llegan como `DateTime`,
`resueltaEn` es `DateTime?` porque una solicitud pendiente todavía no tiene
resolución, y los textos opcionales (`mensaje`, `observacion`) se normalizan a
cadena vacía para que la interfaz no tenga que comprobar `null` en cada uso.

`ResumenSolicitudes` guarda el conteo por estado que devuelve el backend. Como
ese resumen no cambia con el filtro activo, los chips muestran el total real de
cada estado aunque se esté viendo solo uno.

## Pantallas

### Mis solicitudes (estudiante)

Se abre desde el ícono de la barra superior del catálogo. Lista las solicitudes
del estudiante en tarjetas con su estado, el mensaje que escribió, la
observación del gestor y la fecha de resolución. Los chips filtran por estado y
cada tarjeta pendiente ofrece **Retirar solicitud**.

### Bandeja del gestor

Se abre desde el detalle de una comunidad, y **solo aparece si el usuario
conectado gestiona esa comunidad**. Muestra las solicitudes que recibió, con los
mismos filtros, y cada pendiente ofrece **Aprobar** y **Rechazar**; ambas piden
una observación opcional antes de enviar.

Ocultar el botón no es la validación: si alguien llama la API por su cuenta, la
vista en Python responde 403 igual que antes, y la pantalla muestra ese mensaje.

### Solicitar ingreso

`BotonSolicitarIngreso` se incrusta en el detalle de la comunidad y consulta el
estado del estudiante para mostrar la acción que corresponde:

| Situación | Qué muestra |
|---|---|
| Sin solicitud, o rechazada o retirada | Botón **Solicitar ingreso**, con un mensaje opcional. |
| Solicitud pendiente | Botón **Retirar solicitud**. |
| Solicitud aprobada | Etiqueta **Ya eres miembro**. |

## Manejo de estados y validaciones

Las dos pantallas contemplan los cuatro estados de una consulta: carga en
progreso, error, resultado vacío y datos disponibles. Los botones se deshabilitan
mientras hay una operación en curso, para evitar envíos repetidos.

Los mensajes de validación que devuelve Python se muestran tal como llegan
—«Ya tienes una solicitud pendiente en CIAP», «No es gestor de ROBOTA»—; la
función `mensajeDeError()` los distingue de una caída de conexión, que sí recibe
un texto propio del frontend. La interfaz no reimplementa ninguna regla de
negocio: el backend sigue siendo el que decide.

## Identificación del usuario

El usuario entra con su cuenta en `lib/pantallas/login.dart` y queda guardado en
`lib/servicios/sesion.dart`, que es infraestructura compartida (ver
`backend/cuentas/README.md`). De ahí salen tanto `Api.estudianteId` como
`ApiSolicitudes.gestorId`: ambos son ahora el id del usuario conectado, no
constantes.

`Sesion.gestiona(comunidadId)` responde si el usuario conectado gestiona esa
comunidad, y es lo que decide qué acción se muestra en el detalle. La misma
función sirve para RF-04 (gestionar eventos), que también es solo para gestores.

## Cómo probarlo

Con el backend corriendo (ver `backend/solicitudes/README.md` o `DOCKER.md`):

```bash
cd frontend
flutter pub get
flutter analyze
flutter test          # 15 pruebas
flutter run -d chrome
```

Recorrido sugerido con los datos de ejemplo. Todas las cuentas usan la
contraseña `espol2026`.

Como **estudiante1**:

1. Abrir **CIAP** → hay una solicitud pendiente, así que el botón ofrece
   **Retirar solicitud**. No aparece la bandeja del gestor.
2. Abrir **ROBOTA** → ya fue aprobado, aparece **Ya eres miembro**.
3. Abrir cualquier otra comunidad → **Solicitar ingreso**; al intentar dos veces,
   el backend responde con el mensaje de solicitud duplicada.
4. Ícono de la barra superior → **Mis solicitudes**, con los filtros por estado.

Cerrar sesión y entrar como **gestor_ciap**:

5. Abrir **CIAP** → ahora aparece **Ver solicitudes recibidas**, y no el botón
   de postular.
6. Aprobar o rechazar una pendiente con una observación.
7. Abrir **ROBOTA**, que no gestiona → vuelve a verse **Solicitar ingreso**, sin
   rastro de la bandeja.
