import unittest

from flask import json

from openapi_server.models.card import Card  # noqa: E501
from openapi_server.models.card_in_game import CardInGame  # noqa: E501
from openapi_server.test import BaseTestCase


class TestCardController(BaseTestCase):
    """CardController integration test stubs"""

    def test_cardingame_post(self):
        """Test case for cardingame_post

        Karte einem Benutzer in einem Spiel zuweisen
        """
        card_in_game = {"CID":"046b6c7f-0b8a-43b9-b35d-6489e6daee91","UID":"046b6c7f-0b8a-43b9-b35d-6489e6daee91","GID":"PDL96","isTrumpf":True,"CIGID":"11111111-1111-1111-1111-111111111111"}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/cardingame',
            method='POST',
            headers=headers,
            data=json.dumps(card_in_game),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

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


if __name__ == '__main__':
    unittest.main()
