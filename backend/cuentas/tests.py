import json

from django.contrib.auth.models import User
from django.test import TestCase

from comunidades.models import Categoria, Comunidad

JSON = 'application/json'
CLAVE = 'espol2026'


class BaseCuentas(TestCase):
    """Un estudiante sin comunidades y un gestor con una activa y una inactiva."""

    def setUp(self):
        categoria = Categoria.objects.create(nombre='Tecnología')
        self.comunidad = Comunidad.objects.create(
            nombre='CIAP', descripcion='Club de inteligencia artificial',
            categoria=categoria,
        )
        self.inactiva = Comunidad.objects.create(
            nombre='Club de Arqueología', descripcion='Club inactivo',
            categoria=categoria, activa=False,
        )

        self.estudiante = User.objects.create_user(
            username='estudiante1', password=CLAVE,
        )
        self.gestor = User.objects.create_user(
            username='gestor_ciap', password=CLAVE,
        )
        self.comunidad.gestores.add(self.gestor)
        self.inactiva.gestores.add(self.gestor)

    def entrar(self, usuario, contrasena=CLAVE):
        return self.client.post(
            '/api/sesion/',
            json.dumps({'usuario': usuario, 'contrasena': contrasena}),
            content_type=JSON,
        )


class IniciarSesion(BaseCuentas):

    def test_estudiante_entra_con_su_clave(self):
        respuesta = self.entrar('estudiante1')
        datos = respuesta.json()

        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(datos['usuario']['id'], self.estudiante.id)
        self.assertEqual(datos['usuario']['usuario'], 'estudiante1')
        self.assertIn('estudiante1', datos['mensaje'])

    def test_el_estudiante_no_gestiona_comunidades(self):
        datos = self.entrar('estudiante1').json()

        self.assertFalse(datos['usuario']['es_gestor'])
        self.assertEqual(datos['usuario']['comunidades_gestionadas'], [])

    def test_el_gestor_recibe_las_comunidades_que_gestiona(self):
        datos = self.entrar('gestor_ciap').json()
        gestionadas = datos['usuario']['comunidades_gestionadas']

        self.assertTrue(datos['usuario']['es_gestor'])
        self.assertEqual(gestionadas, [{'id': self.comunidad.id, 'nombre': 'CIAP'}])

    def test_las_comunidades_inactivas_no_se_listan(self):
        datos = self.entrar('gestor_ciap').json()
        nombres = [c['nombre'] for c in datos['usuario']['comunidades_gestionadas']]

        self.assertNotIn('Club de Arqueología', nombres)

    def test_contrasena_incorrecta(self):
        respuesta = self.entrar('estudiante1', 'otra-clave')

        self.assertEqual(respuesta.status_code, 401)
        self.assertEqual(respuesta.json()['error'], 'Usuario o contraseña incorrectos')

    def test_usuario_inexistente(self):
        respuesta = self.entrar('nadie')

        self.assertEqual(respuesta.status_code, 401)

    def test_cuenta_desactivada_no_entra(self):
        self.estudiante.is_active = False
        self.estudiante.save(update_fields=['is_active'])

        self.assertEqual(self.entrar('estudiante1').status_code, 401)

    def test_faltan_credenciales(self):
        respuesta = self.client.post('/api/sesion/', '{}', content_type=JSON)

        self.assertEqual(respuesta.status_code, 400)
        self.assertEqual(respuesta.json()['error'], 'Debe enviar usuario y contraseña')

    def test_credenciales_que_no_son_texto(self):
        respuesta = self.client.post(
            '/api/sesion/',
            json.dumps({'usuario': 1, 'contrasena': CLAVE}),
            content_type=JSON,
        )

        self.assertEqual(respuesta.status_code, 400)

    def test_cuerpo_mal_formado(self):
        respuesta = self.client.post('/api/sesion/', 'no es json', content_type=JSON)

        self.assertEqual(respuesta.status_code, 400)

    def test_la_contrasena_nunca_vuelve_en_la_respuesta(self):
        cuerpo = self.entrar('estudiante1').content.decode()

        self.assertNotIn(CLAVE, cuerpo)
        self.assertNotIn('password', cuerpo)


class ConsultarPermisos(BaseCuentas):

    def test_devuelve_los_permisos_del_usuario(self):
        respuesta = self.client.get(f'/api/sesion/?usuario_id={self.gestor.id}')
        datos = respuesta.json()

        self.assertEqual(respuesta.status_code, 200)
        self.assertTrue(datos['usuario']['es_gestor'])
        self.assertEqual(datos['usuario']['usuario'], 'gestor_ciap')

    def test_refleja_un_permiso_quitado(self):
        self.comunidad.gestores.remove(self.gestor)

        datos = self.client.get(f'/api/sesion/?usuario_id={self.gestor.id}').json()

        self.assertFalse(datos['usuario']['es_gestor'])

    def test_usuario_inexistente(self):
        respuesta = self.client.get('/api/sesion/?usuario_id=9999')

        self.assertEqual(respuesta.status_code, 404)

    def test_sin_usuario_id(self):
        respuesta = self.client.get('/api/sesion/')

        self.assertEqual(respuesta.status_code, 400)

    def test_usuario_id_no_numerico(self):
        respuesta = self.client.get('/api/sesion/?usuario_id=abc')

        self.assertEqual(respuesta.status_code, 400)


class MetodosNoPermitidos(BaseCuentas):

    def test_delete_no_esta_permitido(self):
        respuesta = self.client.delete('/api/sesion/')

        self.assertEqual(respuesta.status_code, 405)
