import unittest
from unittest.mock import patch, MagicMock

from openapi_server.controllers import rounds_controller
from openapi_server.models.add_play_request import AddPlayRequest
from openapi_server.models.games_gid_next_player_uid_get200_response import GamesGidNextPlayerUidGet200Response
from openapi_server.models.jasskarte import Jasskarte as ApiJasskarte
from openapi_server.models.rounds_rid_first_card_cid_get200_response import RoundsRidFirstCardCidGet200Response
from openapi_server.models.update_turn_request import UpdateTurnRequest
from openapi_server.models.update_winner_request import UpdateWinnerRequest


class TestRoundsControllerUnit(unittest.TestCase):
    """Unit tests for the Rounds Controller"""

    @patch('openapi_server.controllers.rounds_controller.supabase')
    def test_rounds_rid_first_card_cid_get_success(self, mock_supabase):
        """Test successful retrieval of the first card's CID."""
        mock_response = MagicMock()
        mock_response.data = {'CID': 'test_cid'}
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.maybe_single.return_value.execute.return_value = mock_response

        response, status = rounds_controller.rounds_rid_first_card_cid_get('test_rid')

        self.assertIsInstance(response, RoundsRidFirstCardCidGet200Response)
        self.assertEqual(response.cid, 'test_cid')
        self.assertEqual(status, 200)

    @patch('openapi_server.controllers.rounds_controller.supabase')
    def test_rounds_rid_first_card_cid_get_no_card(self, mock_supabase):
        """Test retrieval when no card has been played."""
        mock_response = MagicMock()
        mock_response.data = None
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.maybe_single.return_value.execute.return_value = mock_response

        response, status = rounds_controller.rounds_rid_first_card_cid_get('test_rid')

        self.assertEqual(response.cid, '')
        self.assertEqual(status, 200)

    @patch('openapi_server.controllers.rounds_controller.supabase')
    def test_rounds_rid_first_card_get_success(self, mock_supabase):
        """Test successful retrieval of the first card object."""
        # Prepare mock responses for 'plays' and 'card' tables
        mock_plays_response = MagicMock()
        mock_plays_response.data = {'CID': 'test_cid'}
        mock_card_response = MagicMock()
        mock_card_response.data = {'CID': 'test_cid', 'symbol': 'Herz', 'cardtype': 'Ass'}

        # Create separate table mocks
        mock_plays_table = MagicMock()
        mock_plays_table.select.return_value.eq.return_value.limit.return_value.maybe_single.return_value.execute.return_value = mock_plays_response
        mock_card_table = MagicMock()
        mock_card_table.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = mock_card_response

        # Route table calls to appropriate mocks
        def table_side_effect(table_name):
            if table_name == 'plays':
                return mock_plays_table
            if table_name == 'card':
                return mock_card_table
            return MagicMock()

        mock_supabase.table.side_effect = table_side_effect

        response, status = rounds_controller.rounds_rid_first_card_get('test_rid')

        self.assertIsInstance(response, ApiJasskarte)
        self.assertEqual(response.cid, 'test_cid')
        self.assertEqual(response.symbol, 'Herz')
        self.assertEqual(status, 200)

    @patch('openapi_server.controllers.rounds_controller.supabase')
    def test_rounds_rid_played_cards_get_success(self, mock_supabase):
        """Test successful retrieval of all played cards in a round."""
        mock_response = MagicMock()
        mock_response.data = [
            {'CID': 'c1', 'card': {'symbol': 's1', 'cardtype': 't1'}},
            {'CID': 'c2', 'card': {'symbol': 's2', 'cardtype': 't2'}}
        ]
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_response

        response, status = rounds_controller.rounds_rid_played_cards_get('test_rid')

        self.assertEqual(len(response), 2)
        self.assertIsInstance(response[0], ApiJasskarte)
        self.assertEqual(response[0].cid, 'c1')
        self.assertEqual(status, 200)

    @patch('openapi_server.controllers.rounds_controller.connexion')
    @patch('openapi_server.controllers.rounds_controller.supabase')
    def test_rounds_rid_plays_post_success(self, mock_supabase, mock_connexion):
        """Test successfully adding a play to a round."""
        mock_connexion.request.get_json.return_value = {'uid': 'u1', 'cid': 'c1'}
        with patch('openapi_server.models.add_play_request.AddPlayRequest.from_dict') as mock_from_dict:
            mock_from_dict.return_value = AddPlayRequest(uid='u1', cid='c1')
            
            mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(error=None)

            response, status = rounds_controller.rounds_rid_plays_post('test_rid', body={})
            
            self.assertIsNone(response)
            self.assertEqual(status, 200)
            mock_supabase.table.return_value.insert.assert_called_once_with({'RID': 'test_rid', 'UID': 'u1', 'CID': 'c1'})

    @patch('openapi_server.controllers.rounds_controller.supabase')
    def test_rounds_rid_turn_get_success(self, mock_supabase):
        """Test successful retrieval of the current player's turn."""
        mock_response = MagicMock()
        mock_response.data = {'whoIsAtTurn': 'test_uid'}
        mock_supabase.table.return_value.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = mock_response

        response, status = rounds_controller.rounds_rid_turn_get('test_rid')

        self.assertIsInstance(response, GamesGidNextPlayerUidGet200Response)
        self.assertEqual(response.uid, 'test_uid')
        self.assertEqual(status, 200)

    @patch('openapi_server.controllers.rounds_controller.connexion')
    @patch('openapi_server.controllers.rounds_controller.supabase')
    def test_rounds_rid_turn_put_success(self, mock_supabase, mock_connexion):
        """Test successfully updating the current player's turn."""
        mock_connexion.request.get_json.return_value = {'uid': 'next_uid'}
        with patch('openapi_server.models.update_turn_request.UpdateTurnRequest.from_dict') as mock_from_dict:
            mock_from_dict.return_value = UpdateTurnRequest(uid='next_uid')

            mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(error=None)

            response, status = rounds_controller.rounds_rid_turn_put('test_rid', body={})

            self.assertIsNone(response)
            self.assertEqual(status, 200)
            mock_supabase.table.return_value.update.assert_called_once_with({'whoIsAtTurn': 'next_uid'})

    @patch('openapi_server.controllers.rounds_controller.connexion')
    @patch('openapi_server.controllers.rounds_controller.supabase')
    def test_rounds_rid_winner_put_success(self, mock_supabase, mock_connexion):
        """Test successfully updating the round's winner."""
        mock_connexion.request.get_json.return_value = {'winner_uid': 'winner_uid'}
        with patch('openapi_server.models.update_winner_request.UpdateWinnerRequest.from_dict') as mock_from_dict:
            mock_from_dict.return_value = UpdateWinnerRequest(winner_uid='winner_uid')

            mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(error=None)

            response, status = rounds_controller.rounds_rid_winner_put('test_rid', body={})

            self.assertIsNone(response)
            self.assertEqual(status, 200)
            mock_supabase.table.return_value.update.assert_called_once_with({'winnerid': 'winner_uid'})

if __name__ == '__main__':
    unittest.main()
