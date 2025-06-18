import unittest
from unittest.mock import patch, MagicMock
from openapi_server.controllers import users_controller
# Viel KI für Unit-Tests Herr Diem: "KI ist perfekt fürs Unit Test"

class TestUsersControllerUnit(unittest.TestCase):
    def setUp(self):
        self.uid = 'test_uid'
        self.name = 'Test User'
        self.body = {'name': self.name}

    @patch('openapi_server.controllers.users_controller.supabase')
    @patch('openapi_server.controllers.users_controller.connexion')
    def test_create_user_success(self, mock_connexion, mock_supabase):
        # Mock request body
        mock_connexion.request.get_json.return_value = self.body
        # Mock user does not exist
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(
            error=None, data=[])
        # Mock insert success
        mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(error=None)
        resp, status = users_controller.users_uid_put(self.uid, self.body)
        self.assertEqual(status, 201)
        self.assertEqual(resp['message'], 'Benutzer erfolgreich erstellt.')
        self.assertEqual(resp['uid'], self.uid)
        self.assertEqual(resp['name'], self.name)

    @patch('openapi_server.controllers.users_controller.supabase')
    @patch('openapi_server.controllers.users_controller.connexion')
    def test_update_user_success(self, mock_connexion, mock_supabase):
        mock_connexion.request.get_json.return_value = self.body
        # Mock user exists
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(
            error=None, data=[{'UID': self.uid}])
        # Mock update success
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(error=None)
        resp, status = users_controller.users_uid_put(self.uid, self.body)
        self.assertEqual(status, 200)
        self.assertEqual(resp['message'], 'Benutzer erfolgreich aktualisiert.')
        self.assertEqual(resp['uid'], self.uid)
        self.assertEqual(resp['name'], self.name)

    @patch('openapi_server.controllers.users_controller.supabase')
    @patch('openapi_server.controllers.users_controller.connexion')
    def test_missing_name(self, mock_connexion, mock_supabase):
        mock_connexion.request.get_json.return_value = {}
        resp, status = users_controller.users_uid_put(self.uid, {})
        self.assertEqual(status, 400)
        self.assertIn('Name ist im Request-Body erforderlich.', resp['message'])

    @patch('openapi_server.controllers.users_controller.supabase')
    @patch('openapi_server.controllers.users_controller.connexion')
    def test_supabase_select_error(self, mock_connexion, mock_supabase):
        mock_connexion.request.get_json.return_value = self.body
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(
            error=MagicMock(message='Fehler!'), data=None)
        resp, status = users_controller.users_uid_put(self.uid, self.body)
        self.assertEqual(status, 500)
        self.assertIn('Fehler beim Abrufen der Benutzerdaten.', resp['message'])

    @patch('openapi_server.controllers.users_controller.supabase')
    @patch('openapi_server.controllers.users_controller.connexion')
    def test_supabase_insert_error(self, mock_connexion, mock_supabase):
        mock_connexion.request.get_json.return_value = self.body
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(
            error=None, data=[])
        mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(error=MagicMock(message='Fehler!'))
        resp, status = users_controller.users_uid_put(self.uid, self.body)
        self.assertEqual(status, 500)
        self.assertIn('Fehler beim Erstellen des Benutzers.', resp['message'])

    @patch('openapi_server.controllers.users_controller.supabase')
    @patch('openapi_server.controllers.users_controller.connexion')
    def test_supabase_update_error(self, mock_connexion, mock_supabase):
        mock_connexion.request.get_json.return_value = self.body
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(
            error=None, data=[{'UID': self.uid}])
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(error=MagicMock(message='Fehler!'))
        resp, status = users_controller.users_uid_put(self.uid, self.body)
        self.assertEqual(status, 500)
        self.assertIn('Fehler beim Aktualisieren des Benutzers.', resp['message'])


if __name__ == '__main__':
    unittest.main()
