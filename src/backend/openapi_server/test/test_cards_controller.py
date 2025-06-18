import unittest
from unittest.mock import patch, MagicMock

from openapi_server.controllers import cards_controller
from openapi_server.models.cards_cid_type_get200_response import CardsCidTypeGet200Response
from openapi_server.models.jasskarte import Jasskarte as ApiJasskarte
from openapi_server.models.winning_card_response import WinningCardResponse

class TestCardsControllerUnit(unittest.TestCase):
    """Unit tests for Cards Controller"""

    @patch('openapi_server.controllers.cards_controller.supabase')
    def test_cards_cid_get_success(self, mock_supabase):
        # Mock database response with one card
        data = [{'CID': 'C1', 'symbol': 'Herz', 'cardtype': 'Ass'}]
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(data=data)

        response, status = cards_controller.cards_cid_get('C1')

        self.assertEqual(status, 200)
        self.assertIsInstance(response, dict)
        self.assertEqual(response['cid'], 'C1')
        self.assertEqual(response['symbol'], 'Herz')
        self.assertEqual(response['cardtype'], 'Ass')

    @patch('openapi_server.controllers.cards_controller.supabase')
    def test_cards_cid_get_not_found(self, mock_supabase):
        # Mock empty data
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(data=None)

        response, status = cards_controller.cards_cid_get('C2')

        self.assertEqual(status, 404)
        self.assertIn('message', response)

    @patch('openapi_server.controllers.cards_controller.supabase')
    def test_cards_cid_get_error(self, mock_supabase):
        # Simulate exception
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.side_effect = Exception()

        response, status = cards_controller.cards_cid_get('C3')

        self.assertEqual(status, 500)
        self.assertIn('message', response)

    @patch('openapi_server.controllers.cards_controller.supabase')
    def test_cards_cid_type_get_success(self, mock_supabase):
        # Mock type
        data = [{'cardtype': 'Ass'}]
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(data=data)

        response, status = cards_controller.cards_cid_type_get('C1')

        self.assertEqual(status, 200)
        self.assertIsInstance(response, dict)
        self.assertEqual(response['cardtype'], 'Ass')

    @patch('openapi_server.controllers.cards_controller.supabase')
    def test_cards_cid_type_get_empty(self, mock_supabase):
        # Empty data
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = MagicMock(data=None)

        response, status = cards_controller.cards_cid_type_get('C2')

        self.assertEqual(status, 200)
        self.assertEqual(response['cardtype'], '')

    @patch('openapi_server.controllers.cards_controller.supabase')
    def test_cards_cid_type_get_error(self, mock_supabase):
        mock_supabase.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.side_effect = Exception()

        response, status = cards_controller.cards_cid_type_get('C3')

        self.assertEqual(status, 500)
        self.assertIn('message', response)

    @patch('openapi_server.controllers.cards_controller.get_winning_card')
    @patch('openapi_server.controllers.cards_controller.DetermineWinningCardRequest')
    def test_cards_determine_winning_card_post_success(self, mock_request, mock_get_winner):
        # Mock request body conversion
        body = {'cards': []}
        mock_request.from_dict.return_value = MagicMock(cards=[])
        # No cards => should return empty winner
        response, status = cards_controller.cards_determine_winning_card_post('G1', body)
        self.assertEqual(status, 200)
        self.assertIsInstance(response, WinningCardResponse)
        self.assertEqual(response.winner_uid, '')

        # Now simulate cards and winner
        card_obj = MagicMock(cid='C1')
        mock_request.from_dict.return_value = MagicMock(cards=[card_obj])
        mock_get_winner.return_value = 'U1'
        response, status = cards_controller.cards_determine_winning_card_post('G1', body)
        self.assertEqual(status, 200)
        self.assertEqual(response.winner_uid, 'U1')

    @patch('openapi_server.controllers.cards_controller.get_winning_card')
    @patch('openapi_server.controllers.cards_controller.DetermineWinningCardRequest')
    def test_cards_determine_winning_card_post_error(self, mock_request, mock_get_winner):
        # Simulate exception in logic
        mock_request.from_dict.side_effect = Exception()
        response, status = cards_controller.cards_determine_winning_card_post('G1', {})
        self.assertEqual(status, 500)
        self.assertIsInstance(response, WinningCardResponse)
        self.assertEqual(response.winner_uid, '')

    @patch('openapi_server.controllers.cards_controller.supabase')
    def test_cards_get_success(self, mock_supabase):
        # Mock multiple cards
        data = [{'CID': 'C1', 'symbol': 'S1', 'cardtype': 'T1'}, {'CID': 'C2', 'symbol': 'S2', 'cardtype': 'T2'}]
        mock_supabase.table.return_value.select.return_value.execute.return_value = MagicMock(data=data)

        response, status = cards_controller.cards_get()
        self.assertEqual(status, 200)
        self.assertIsInstance(response, list)
        self.assertTrue(all(isinstance(c, ApiJasskarte) for c in response))
        self.assertEqual(response[0].cid, 'C1')

    @patch('openapi_server.controllers.cards_controller.supabase')
    def test_cards_get_error(self, mock_supabase):
        mock_supabase.table.return_value.select.return_value.execute.side_effect = Exception()

        response, status = cards_controller.cards_get()
        self.assertEqual(status, 500)
        self.assertIn('message', response)

if __name__ == '__main__':
    unittest.main()
