import unittest

from flask import json

from openapi_server.models.add_play_request import AddPlayRequest  # noqa: E501
from openapi_server.models.games_gid_next_player_uid_get200_response import GamesGidNextPlayerUidGet200Response  # noqa: E501
from openapi_server.models.jasskarte import Jasskarte  # noqa: E501
from openapi_server.models.rounds_rid_first_card_cid_get200_response import RoundsRidFirstCardCidGet200Response  # noqa: E501
from openapi_server.models.update_turn_request import UpdateTurnRequest  # noqa: E501
from openapi_server.models.update_winner_request import UpdateWinnerRequest  # noqa: E501
from openapi_server.test import BaseTestCase


class TestRoundsController(BaseTestCase):
    """RoundsController integration test stubs"""

    def test_rounds_rid_first_card_cid_get(self):
        """Test case for rounds_rid_first_card_cid_get

        Holt die CID der ersten gespielten Karte in einer Runde.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/rounds/{rid}/first-card-cid'.format(rid='rid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_rounds_rid_first_card_get(self):
        """Test case for rounds_rid_first_card_get

        Holt das Objekt der ersten gespielten Karte in einer Runde.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/rounds/{rid}/first-card'.format(rid='rid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_rounds_rid_played_cards_get(self):
        """Test case for rounds_rid_played_cards_get

        Holt alle gespielten Karten einer Runde.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/rounds/{rid}/played-cards'.format(rid='rid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_rounds_rid_plays_post(self):
        """Test case for rounds_rid_plays_post

        Fügt einen Spielzug (gespielte Karte) zu einer Runde hinzu.
        """
        add_play_request = {"uid":"uid","cid":"cid"}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/api/rounds/{rid}/plays'.format(rid='rid_example'),
            method='POST',
            headers=headers,
            data=json.dumps(add_play_request),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_rounds_rid_turn_get(self):
        """Test case for rounds_rid_turn_get

        Holt die UID des Spielers, der aktuell am Zug ist.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/rounds/{rid}/turn'.format(rid='rid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_rounds_rid_turn_put(self):
        """Test case for rounds_rid_turn_put

        Aktualisiert, welcher Spieler am Zug ist.
        """
        update_turn_request = {"uid":"uid"}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/api/rounds/{rid}/turn'.format(rid='rid_example'),
            method='PUT',
            headers=headers,
            data=json.dumps(update_turn_request),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_rounds_rid_winner_put(self):
        """Test case for rounds_rid_winner_put

        Aktualisiert den Gewinner einer Runde.
        """
        update_winner_request = {"winnerUid":"winnerUid"}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/api/rounds/{rid}/winner'.format(rid='rid_example'),
            method='PUT',
            headers=headers,
            data=json.dumps(update_winner_request),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
