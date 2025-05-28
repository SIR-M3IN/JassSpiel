import unittest

from flask import json

from openapi_server.models.user import User  # noqa: E501
from openapi_server.models.user_create import UserCreate  # noqa: E501
from openapi_server.models.user_game import UserGame  # noqa: E501
from openapi_server.test import BaseTestCase


class TestUserController(BaseTestCase):
    """UserController integration test stubs"""

    def test_usergame_post(self):
        """Test case for usergame_post

        Benutzer einem Spiel zuordnen
        """
        user_game = {"UID":"046b6c7f-0b8a-43b9-b35d-6489e6daee91","GID":"PDL96","score":0}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/usergame',
            method='POST',
            headers=headers,
            data=json.dumps(user_game),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_users_get(self):
        """Test case for users_get

        Alle Benutzer abrufen
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/users',
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_users_post(self):
        """Test case for users_post

        Neuen Benutzer erstellen
        """
        user_create = {"name":"Max"}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/users',
            method='POST',
            headers=headers,
            data=json.dumps(user_create),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_users_uid_get(self):
        """Test case for users_uid_get

        Benutzer anhand UID abrufen
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/users/{uid}'.format(uid='uid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
