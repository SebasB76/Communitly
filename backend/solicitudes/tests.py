import json

from django.contrib.auth.models import User
from django.db import IntegrityError, transaction
from django.test import TestCase

from comunidades.models import Categoria, Comunidad

from .models import Solicitud

JSON = 'application/json'


class BaseSolicitudes(TestCase):
    """Datos comunes: una comunidad con gestor, otra sin gestor y una inactiva."""

    def setUp(self):
        categoria = Categoria.objects.create(nombre='Tecnología')
        self.comunidad = Comunidad.objects.create(
            nombre='CIAP', descripcion='Club de inteligencia artificial',
            categoria=categoria, contacto='ciap@espol.edu.ec',
        )
        self.otra = Comunidad.objects.create(
            nombre='ROBOTA', descripcion='Club de robótica', categoria=categoria,
        )
        self.inactiva = Comunidad.objects.create(
            nombre='Club de Arqueología', descripcion='Club inactivo',
            categoria=categoria, activa=False,
        )

        # create() en vez de create_user(): las pruebas no usan contraseñas
        self.estudiante = User.objects.create(username='estudiante1')
        self.otro_estudiante = User.objects.create(username='estudiante2')
        self.gestor = User.objects.create(username='gestor_ciap')
        self.intruso = User.objects.create(username='gestor_robota')

        self.comunidad.gestores.add(self.gestor)
        self.otra.gestores.add(self.intruso)

    def crear_solicitud(self, estudiante=None, comunidad=None, **extra):
        return Solicitud.objects.create(
            estudiante=estudiante or self.estudiante,
            comunidad=comunidad or self.comunidad,
            **extra,
        )

    def enviar(self, comunidad_id, datos):
        return self.client.post(
            f'/api/comunidades/{comunidad_id}/solicitar/',
            data=json.dumps(datos), content_type=JSON,
        )

    def retirar(self, comunidad_id, datos):
        return self.client.delete(
            f'/api/comunidades/{comunidad_id}/solicitar/',
            data=json.dumps(datos), content_type=JSON,
        )

    def resolver(self, solicitud_id, datos):
        return self.client.post(
            f'/api/solicitudes/{solicitud_id}/resolver/',
            data=json.dumps(datos), content_type=JSON,
        )


class ModeloSolicitudTests(BaseSolicitudes):
    """Reglas de negocio que protege la base de datos."""

    def test_estado_inicial_es_pendiente(self):
        self.assertEqual(self.crear_solicitud().estado, Solicitud.PENDIENTE)

    def test_no_permite_dos_solicitudes_pendientes_en_la_misma_comunidad(self):
        self.crear_solicitud()
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                self.crear_solicitud()

    def test_permite_volver_a_postular_si_la_anterior_fue_resuelta(self):
        self.crear_solicitud(estado=Solicitud.RECHAZADA)
        self.crear_solicitud()
        self.assertEqual(Solicitud.objects.count(), 2)


class MisSolicitudesTests(BaseSolicitudes):
    """RF-05: el estudiante consulta el estado de sus solicitudes."""

    def test_exige_estudiante_id(self):
        respuesta = self.client.get('/api/solicitudes/')
        self.assertEqual(respuesta.status_code, 400)
        self.assertIn('estudiante_id', respuesta.json()['error'])

    def test_devuelve_solo_las_solicitudes_del_estudiante(self):
        self.crear_solicitud()
        self.crear_solicitud(estudiante=self.otro_estudiante)

        datos = self.client.get(
            '/api/solicitudes/', {'estudiante_id': self.estudiante.id}
        ).json()

        self.assertEqual(datos['total'], 1)
        self.assertEqual(datos['solicitudes'][0]['estudiante']['id'], self.estudiante.id)
        self.assertEqual(datos['solicitudes'][0]['comunidad']['nombre'], 'CIAP')

    def test_incluye_resumen_por_estado(self):
        self.crear_solicitud()
        self.crear_solicitud(comunidad=self.otra, estado=Solicitud.APROBADA)

        datos = self.client.get(
            '/api/solicitudes/', {'estudiante_id': self.estudiante.id}
        ).json()

        self.assertEqual(datos['resumen']['pendiente'], 1)
        self.assertEqual(datos['resumen']['aprobada'], 1)
        self.assertEqual(datos['resumen']['rechazada'], 0)

    def test_filtra_por_estado(self):
        self.crear_solicitud()
        self.crear_solicitud(comunidad=self.otra, estado=Solicitud.APROBADA)

        datos = self.client.get(
            '/api/solicitudes/', {'estudiante_id': self.estudiante.id, 'estado': 'aprobada'}
        ).json()

        self.assertEqual(datos['total'], 1)
        self.assertEqual(datos['solicitudes'][0]['estado'], 'aprobada')
        # el resumen no cambia con el filtro: alimenta las pestañas de la interfaz
        self.assertEqual(datos['resumen']['pendiente'], 1)

    def test_rechaza_un_estado_invalido(self):
        respuesta = self.client.get(
            '/api/solicitudes/', {'estudiante_id': self.estudiante.id, 'estado': 'inventado'}
        )
        self.assertEqual(respuesta.status_code, 400)

    def test_no_acepta_post(self):
        self.assertEqual(self.client.post('/api/solicitudes/').status_code, 405)


class SolicitudesComunidadTests(BaseSolicitudes):
    """RF-05: el gestor consulta las solicitudes recibidas por su comunidad."""

    def url(self, comunidad=None):
        return f'/api/comunidades/{(comunidad or self.comunidad).id}/solicitudes/'

    def test_el_gestor_ve_las_solicitudes_de_su_comunidad(self):
        self.crear_solicitud()
        self.crear_solicitud(estudiante=self.otro_estudiante)
        self.crear_solicitud(comunidad=self.otra)

        datos = self.client.get(self.url(), {'gestor_id': self.gestor.id}).json()

        self.assertEqual(datos['total'], 2)
        self.assertEqual(datos['comunidad']['nombre'], 'CIAP')
        self.assertEqual(datos['resumen']['pendiente'], 2)

    def test_filtra_por_estado(self):
        self.crear_solicitud()
        self.crear_solicitud(estudiante=self.otro_estudiante, estado=Solicitud.RECHAZADA)

        datos = self.client.get(
            self.url(), {'gestor_id': self.gestor.id, 'estado': 'pendiente'}
        ).json()

        self.assertEqual(datos['total'], 1)
        self.assertEqual(datos['resumen']['rechazada'], 1)

    def test_bloquea_a_un_gestor_de_otra_comunidad(self):
        respuesta = self.client.get(self.url(), {'gestor_id': self.intruso.id})
        self.assertEqual(respuesta.status_code, 403)

    def test_bloquea_a_un_estudiante(self):
        respuesta = self.client.get(self.url(), {'gestor_id': self.estudiante.id})
        self.assertEqual(respuesta.status_code, 403)

    def test_exige_gestor_id(self):
        self.assertEqual(self.client.get(self.url()).status_code, 400)

    def test_comunidad_inactiva_o_inexistente(self):
        self.assertEqual(
            self.client.get(self.url(self.inactiva), {'gestor_id': self.gestor.id}).status_code,
            404,
        )
        self.assertEqual(
            self.client.get('/api/comunidades/9999/solicitudes/',
                            {'gestor_id': self.gestor.id}).status_code,
            404,
        )


class DetalleSolicitudTests(BaseSolicitudes):
    """RF-05: detalle visible para el estudiante dueño y para el gestor."""

    def setUp(self):
        super().setUp()
        self.solicitud = self.crear_solicitud(mensaje='Me interesa el club')

    def url(self):
        return f'/api/solicitudes/{self.solicitud.id}/'

    def test_el_estudiante_ve_su_solicitud(self):
        datos = self.client.get(self.url(), {'estudiante_id': self.estudiante.id}).json()
        self.assertEqual(datos['id'], self.solicitud.id)
        self.assertEqual(datos['mensaje'], 'Me interesa el club')
        self.assertEqual(datos['estado_texto'], 'Pendiente')

    def test_el_gestor_ve_la_solicitud(self):
        respuesta = self.client.get(self.url(), {'gestor_id': self.gestor.id})
        self.assertEqual(respuesta.status_code, 200)

    def test_otro_estudiante_no_puede_verla(self):
        respuesta = self.client.get(self.url(), {'estudiante_id': self.otro_estudiante.id})
        self.assertEqual(respuesta.status_code, 403)

    def test_sin_identificacion_no_puede_verla(self):
        self.assertEqual(self.client.get(self.url()).status_code, 403)

    def test_solicitud_inexistente(self):
        respuesta = self.client.get('/api/solicitudes/9999/',
                                    {'estudiante_id': self.estudiante.id})
        self.assertEqual(respuesta.status_code, 404)


class EnviarSolicitudTests(BaseSolicitudes):
    """RF-06: el estudiante envía una solicitud de ingreso."""

    def test_envia_una_solicitud(self):
        respuesta = self.enviar(self.comunidad.id, {
            'estudiante_id': self.estudiante.id, 'mensaje': 'Quiero aprender IA',
        })

        self.assertEqual(respuesta.status_code, 201)
        datos = respuesta.json()
        self.assertIn('CIAP', datos['mensaje'])
        self.assertEqual(datos['solicitud']['estado'], 'pendiente')

        solicitud = Solicitud.objects.get()
        self.assertEqual(solicitud.mensaje, 'Quiero aprender IA')
        self.assertEqual(solicitud.estudiante, self.estudiante)

    def test_el_mensaje_es_opcional(self):
        respuesta = self.enviar(self.comunidad.id, {'estudiante_id': self.estudiante.id})
        self.assertEqual(respuesta.status_code, 201)
        self.assertEqual(Solicitud.objects.get().mensaje, '')

    def test_no_permite_duplicar_una_solicitud_pendiente(self):
        self.crear_solicitud()

        respuesta = self.enviar(self.comunidad.id, {'estudiante_id': self.estudiante.id})

        self.assertEqual(respuesta.status_code, 400)
        self.assertIn('pendiente', respuesta.json()['error'])
        self.assertEqual(Solicitud.objects.count(), 1)

    def test_no_permite_postular_si_ya_fue_aprobada(self):
        self.crear_solicitud(estado=Solicitud.APROBADA)

        respuesta = self.enviar(self.comunidad.id, {'estudiante_id': self.estudiante.id})

        self.assertEqual(respuesta.status_code, 400)
        self.assertIn('Ya formas parte', respuesta.json()['error'])

    def test_permite_postular_de_nuevo_tras_un_rechazo(self):
        self.crear_solicitud(estado=Solicitud.RECHAZADA)

        respuesta = self.enviar(self.comunidad.id, {'estudiante_id': self.estudiante.id})

        self.assertEqual(respuesta.status_code, 201)
        self.assertEqual(Solicitud.objects.count(), 2)

    def test_rechaza_un_mensaje_demasiado_largo(self):
        respuesta = self.enviar(self.comunidad.id, {
            'estudiante_id': self.estudiante.id, 'mensaje': 'a' * 501,
        })
        self.assertEqual(respuesta.status_code, 400)
        self.assertFalse(Solicitud.objects.exists())

    def test_rechaza_un_mensaje_que_no_es_texto(self):
        respuesta = self.enviar(self.comunidad.id, {
            'estudiante_id': self.estudiante.id, 'mensaje': 123,
        })
        self.assertEqual(respuesta.status_code, 400)
        self.assertFalse(Solicitud.objects.exists())

    def test_exige_estudiante_id(self):
        respuesta = self.enviar(self.comunidad.id, {})
        self.assertEqual(respuesta.status_code, 400)

    def test_cuerpo_que_no_es_un_objeto_json(self):
        respuesta = self.client.post(
            f'/api/comunidades/{self.comunidad.id}/solicitar/',
            data='[1, 2, 3]', content_type=JSON,
        )
        self.assertEqual(respuesta.status_code, 400)

    def test_comunidad_inactiva(self):
        respuesta = self.enviar(self.inactiva.id, {'estudiante_id': self.estudiante.id})
        self.assertEqual(respuesta.status_code, 404)

    def test_no_acepta_get(self):
        respuesta = self.client.get(f'/api/comunidades/{self.comunidad.id}/solicitar/')
        self.assertEqual(respuesta.status_code, 405)


class RetirarSolicitudTests(BaseSolicitudes):
    """RF-06: el estudiante retira su solicitud pendiente."""

    def test_retira_la_solicitud_y_conserva_el_historial(self):
        solicitud = self.crear_solicitud()

        respuesta = self.retirar(self.comunidad.id, {'estudiante_id': self.estudiante.id})

        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(respuesta.json()['solicitud']['estado'], 'retirada')
        solicitud.refresh_from_db()
        self.assertEqual(solicitud.estado, Solicitud.RETIRADA)
        self.assertEqual(Solicitud.objects.count(), 1)

    def test_puede_volver_a_postular_despues_de_retirar(self):
        self.crear_solicitud()
        self.retirar(self.comunidad.id, {'estudiante_id': self.estudiante.id})

        respuesta = self.enviar(self.comunidad.id, {'estudiante_id': self.estudiante.id})

        self.assertEqual(respuesta.status_code, 201)
        self.assertEqual(Solicitud.objects.filter(estado=Solicitud.PENDIENTE).count(), 1)

    def test_no_puede_retirar_si_no_hay_pendiente(self):
        respuesta = self.retirar(self.comunidad.id, {'estudiante_id': self.estudiante.id})
        self.assertEqual(respuesta.status_code, 400)

    def test_no_puede_retirar_una_solicitud_ya_aprobada(self):
        self.crear_solicitud(estado=Solicitud.APROBADA)

        respuesta = self.retirar(self.comunidad.id, {'estudiante_id': self.estudiante.id})

        self.assertEqual(respuesta.status_code, 400)
        self.assertEqual(Solicitud.objects.get().estado, Solicitud.APROBADA)


class ResolverSolicitudTests(BaseSolicitudes):
    """RF-06: el gestor aprueba o rechaza con observación opcional."""

    def setUp(self):
        super().setUp()
        self.solicitud = self.crear_solicitud()

    def test_el_gestor_aprueba_con_observacion(self):
        respuesta = self.resolver(self.solicitud.id, {
            'gestor_id': self.gestor.id, 'accion': 'aprobar',
            'observacion': 'Bienvenido al club',
        })

        self.assertEqual(respuesta.status_code, 200)
        self.solicitud.refresh_from_db()
        self.assertEqual(self.solicitud.estado, Solicitud.APROBADA)
        self.assertEqual(self.solicitud.observacion, 'Bienvenido al club')
        self.assertEqual(self.solicitud.resuelta_por, self.gestor)
        self.assertIsNotNone(self.solicitud.resuelta_en)

    def test_el_gestor_rechaza_sin_observacion(self):
        respuesta = self.resolver(self.solicitud.id, {
            'gestor_id': self.gestor.id, 'accion': 'rechazar',
        })

        self.assertEqual(respuesta.status_code, 200)
        self.solicitud.refresh_from_db()
        self.assertEqual(self.solicitud.estado, Solicitud.RECHAZADA)
        self.assertEqual(self.solicitud.observacion, '')

    def test_un_gestor_de_otra_comunidad_no_puede_resolver(self):
        respuesta = self.resolver(self.solicitud.id, {
            'gestor_id': self.intruso.id, 'accion': 'aprobar',
        })

        self.assertEqual(respuesta.status_code, 403)
        self.solicitud.refresh_from_db()
        self.assertEqual(self.solicitud.estado, Solicitud.PENDIENTE)

    def test_un_estudiante_no_puede_resolver(self):
        respuesta = self.resolver(self.solicitud.id, {
            'gestor_id': self.estudiante.id, 'accion': 'aprobar',
        })
        self.assertEqual(respuesta.status_code, 403)

    def test_exige_gestor_id(self):
        respuesta = self.resolver(self.solicitud.id, {'accion': 'aprobar'})
        self.assertEqual(respuesta.status_code, 400)

    def test_rechaza_una_accion_invalida(self):
        respuesta = self.resolver(self.solicitud.id, {
            'gestor_id': self.gestor.id, 'accion': 'eliminar',
        })
        self.assertEqual(respuesta.status_code, 400)
        self.assertIn('aprobar', respuesta.json()['error'])

    def test_no_permite_resolver_dos_veces(self):
        self.resolver(self.solicitud.id, {'gestor_id': self.gestor.id, 'accion': 'aprobar'})

        respuesta = self.resolver(self.solicitud.id, {
            'gestor_id': self.gestor.id, 'accion': 'rechazar',
        })

        self.assertEqual(respuesta.status_code, 400)
        self.assertIn('ya fue aprobada', respuesta.json()['error'])
        self.solicitud.refresh_from_db()
        self.assertEqual(self.solicitud.estado, Solicitud.APROBADA)

    def test_no_permite_resolver_una_solicitud_retirada(self):
        self.solicitud.estado = Solicitud.RETIRADA
        self.solicitud.save()

        respuesta = self.resolver(self.solicitud.id, {
            'gestor_id': self.gestor.id, 'accion': 'aprobar',
        })
        self.assertEqual(respuesta.status_code, 400)

    def test_rechaza_una_observacion_demasiado_larga(self):
        respuesta = self.resolver(self.solicitud.id, {
            'gestor_id': self.gestor.id, 'accion': 'aprobar', 'observacion': 'a' * 501,
        })

        self.assertEqual(respuesta.status_code, 400)
        self.solicitud.refresh_from_db()
        self.assertEqual(self.solicitud.estado, Solicitud.PENDIENTE)

    def test_solicitud_inexistente(self):
        respuesta = self.resolver(9999, {'gestor_id': self.gestor.id, 'accion': 'aprobar'})
        self.assertEqual(respuesta.status_code, 404)

    def test_no_acepta_get(self):
        respuesta = self.client.get(f'/api/solicitudes/{self.solicitud.id}/resolver/')
        self.assertEqual(respuesta.status_code, 405)

    def test_cuerpo_mal_formado(self):
        respuesta = self.client.post(
            f'/api/solicitudes/{self.solicitud.id}/resolver/',
            data='{no es json}', content_type=JSON,
        )
        self.assertEqual(respuesta.status_code, 400)
