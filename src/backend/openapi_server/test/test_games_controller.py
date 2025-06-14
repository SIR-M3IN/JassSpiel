import unittest

from flask import json

from openapi_server.models.add_player_request import AddPlayerRequest  # noqa: E501
from openapi_server.models.card_details_response import CardDetailsResponse  # noqa: E501
from openapi_server.models.error import Error  # noqa: E501
from openapi_server.models.games_gid_current_round_id_get200_response import GamesGidCurrentRoundIdGet200Response  # noqa: E501
from openapi_server.models.games_gid_current_round_number_get200_response import GamesGidCurrentRoundNumberGet200Response  # noqa: E501
from openapi_server.models.games_gid_next_player_uid_get200_response import GamesGidNextPlayerUidGet200Response  # noqa: E501
from openapi_server.models.games_gid_update_scores_post200_response import GamesGidUpdateScoresPost200Response  # noqa: E501
from openapi_server.models.games_gid_users_uid_card_count_get200_response import GamesGidUsersUidCardCountGet200Response  # noqa: E501
from openapi_server.models.games_gid_users_uid_player_number_get200_response import GamesGidUsersUidPlayerNumberGet200Response  # noqa: E501
from openapi_server.models.games_post201_response import GamesPost201Response  # noqa: E501
from openapi_server.models.jasskarte import Jasskarte  # noqa: E501
from openapi_server.models.save_points_request import SavePointsRequest  # noqa: E501
from openapi_server.models.spieler import Spieler  # noqa: E501
from openapi_server.models.start_new_round_request import StartNewRoundRequest  # noqa: E501
from openapi_server.models.update_trumpf_request import UpdateTrumpfRequest  # noqa: E501
from openapi_server.test import BaseTestCase


class TestGamesController(BaseTestCase):
    """GamesController integration test stubs"""

    def test_games_gid_card_info_cid_get(self):
        """Test case for games_gid_card_info_cid_get

        Holt eine Karte in einer Runde
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/card-info/{cid}'.format(gid='gid_example', cid='cid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_cards_shuffle_post(self):
        """Test case for games_gid_cards_shuffle_post

        Mischt und verteilt Karten an die Spieler eines Spiels.
        """
        headers = { 
        }
        response = self.client.open(
            '/api/games/{gid}/cards/shuffle'.format(gid='gid_example'),
            method='POST',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_current_round_id_get(self):
        """Test case for games_gid_current_round_id_get

        Holt die ID der aktuellen Runde für ein Spiel.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/current-round-id'.format(gid='gid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_current_round_number_get(self):
        """Test case for games_gid_current_round_number_get

        Holt die Nummer der aktuellen Runde.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/current-round-number'.format(gid='gid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_join_post(self):
        """Test case for games_gid_join_post

        Lässt einen Spieler einem Spiel beitreten.
        """
        headers = { 
        }
        response = self.client.open(
            '/api/games/{gid}/join'.format(gid='gid_example'),
            method='POST',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_next_player_uid_get(self):
        """Test case for games_gid_next_player_uid_get

        Holt die UID des nächsten Spielers basierend auf der Spielernummer.
        """
        query_string = [('playernumber', 56)]
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/next-player-uid'.format(gid='gid_example'),
            method='GET',
            headers=headers,
            query_string=query_string)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_players_get(self):
        """Test case for games_gid_players_get

        Lädt alle Spieler für ein Spiel.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/players'.format(gid='gid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_players_post(self):
        """Test case for games_gid_players_post

        Fügt einen Spieler zu einem Spiel hinzu.
        """
        add_player_request = {"uid":"uid","name":"name"}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/players'.format(gid='gid_example'),
            method='POST',
            headers=headers,
            data=json.dumps(add_player_request),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_rounds_post(self):
        """Test case for games_gid_rounds_post

        Startet eine neue Runde in einem Spiel.
        """
        start_new_round_request = {"whichround":0}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/rounds'.format(gid='gid_example'),
            method='POST',
            headers=headers,
            data=json.dumps(start_new_round_request),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_trumpf_suit_put(self):
        """Test case for games_gid_trumpf_suit_put

        Aktualisiert die Trumpffarbe für ein Spiel.
        """
        update_trumpf_request = {"trumpfSymbol":"trumpfSymbol"}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/trumpf-suit'.format(gid='gid_example'),
            method='PUT',
            headers=headers,
            data=json.dumps(update_trumpf_request),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_update_scores_post(self):
        """Test case for games_gid_update_scores_post

        Speichert Punkte für Gewinner und Teamkollegen.
        """
        save_points_request = {"winnerUid":"winnerUid","teammateUid":"teammateUid","playedCards":[{"symbol":"symbol","path":"path","cardtype":"cardtype","cid":"cid"},{"symbol":"symbol","path":"path","cardtype":"cardtype","cid":"cid"}]}
        headers = { 
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/update-scores'.format(gid='gid_example'),
            method='POST',
            headers=headers,
            data=json.dumps(save_points_request),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_users_uid_card_count_get(self):
        """Test case for games_gid_users_uid_card_count_get

        Holt die Anzahl der Karten eines Spielers.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/users/{uid}/card-count'.format(gid='gid_example', uid='uid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_users_uid_cards_get(self):
        """Test case for games_gid_users_uid_cards_get

        Holt die Karten eines bestimmten Spielers in einem Spiel.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/users/{uid}/cards'.format(gid='gid_example', uid='uid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_gid_users_uid_player_number_get(self):
        """Test case for games_gid_users_uid_player_number_get

        Holt die Spielernummer eines Benutzers in einem Spiel.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/games/{gid}/users/{uid}/player-number'.format(gid='gid_example', uid='uid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_games_post(self):
        """Test case for games_post

        Erstellt ein neues Spiel.
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/api/games',
            method='POST',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
