import unittest

from flask import json

from openapi_server.models.cards_cid_type_get200_response import CardsCidTypeGet200Response  # noqa: E501
from openapi_server.models.determine_winning_card_request import DetermineWinningCardRequest  # noqa: E501
from openapi_server.models.jasskarte import Jasskarte  # noqa: E501
from openapi_server.models.winning_card_response import WinningCardResponse  # noqa: E501
from openapi_server.test import BaseTestCase


class TestCardsController(BaseTestCase):
    """CardsController integration test stubs"""

    def test_cards_cid_get(self):
        """Test case for cards_cid_get

        Holt eine spezifische Jasskarte anhand ihrer CID.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/cards/{cid}'.format(cid='cid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_cards_cid_type_get(self):
        """Test case for cards_cid_type_get

        Holt den Typ einer spezifischen Karte.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/cards/{cid}/type'.format(cid='cid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_cards_determine_winning_card_post(self):
        """Test case for cards_determine_winning_card_post

        Bestimmt die gewinnende Karte aus einer Liste von gespielten Karten für ein Spiel.
        """
        determine_winning_card_request = {"cards":[{"symbol":"symbol","path":"path","cardtype":"cardtype","cid":"cid"},{"symbol":"symbol","path":"path","cardtype":"cardtype","cid":"cid"}]}
        query_string = [('gid', 'gid_example')]
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/api/cards/determine-winning-card',
            method='POST',
            headers=headers,
            data=json.dumps(determine_winning_card_request),
            content_type='application/json',
            query_string=query_string)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_cards_get(self):
        """Test case for cards_get

        Holt alle verfügbaren Jasskarten.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/cards',
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
