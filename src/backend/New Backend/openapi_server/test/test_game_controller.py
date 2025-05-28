import unittest

from flask import json

from openapi_server.models.game import Game  # noqa: E501
from openapi_server.models.game_update import GameUpdate  # noqa: E501
from openapi_server.test import BaseTestCase


class TestGameController(BaseTestCase):
    """GameController integration test stubs"""

    def test_games_get(self):
        """Test case for games_get

        Alle Spiele abrufen
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/games',
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_get(self):
        """Test case for games_gid_get

        Spiel anhand GID abrufen
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/games/{gid}'.format(gid='gid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_post(self):
        """Test case for games_post

        Neues Spiel erstellen
        """
        game = {"GID":"PDL96","status":"waiting","room_name":"Neuer Raum","participants":1}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/games',
            method='POST',
            headers=headers,
            data=json.dumps(game),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_update_game(self):
        """Test case for update_game

        Aktualisiere die Teilnehmerzahl
        """
        game_update = {"participants":0}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/games/{gid}'.format(gid='gid_example'),
            method='PUT',
            headers=headers,
            data=json.dumps(game_update),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
