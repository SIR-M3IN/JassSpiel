import unittest

from flask import json

from openapi_server.models.card import Card  # noqa: E501
from openapi_server.models.card_in_games import CardInGames  # noqa: E501
from openapi_server.test import BaseTestCase


class TestCardController(BaseTestCase):
    """CardController integration test stubs"""

    def test_cards_get(self):
        """Test case for cards_get

        Alle Karten abrufen
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/cards',
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_cardsingame_post(self):
        """Test case for cardsingame_post

        Karte einem Benutzer in einem Spiel zuweisen
        """
        card_in_games = {"UID":"046b6c7f-0b8a-43b9-b35d-6489e6daee91","GID":"PDL96","CID":"046b6c7f-0b8a-43b9-b35d-6489e6daee91"}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/cardsingame',
            method='POST',
            headers=headers,
            data=json.dumps(card_in_games),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
