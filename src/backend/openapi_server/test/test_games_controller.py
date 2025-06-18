import unittest
from unittest.mock import patch, MagicMock

from openapi_server.controllers import games_controller
from openapi_server.models.add_player_request import AddPlayerRequest
from openapi_server.models.card_details_response import CardDetailsResponse
from openapi_server.models.error import Error
from openapi_server.models.games_gid_current_round_id_get200_response import GamesGidCurrentRoundIdGet200Response
from openapi_server.models.games_gid_update_scores_post200_response import GamesGidUpdateScoresPost200Response
from openapi_server.models.games_gid_users_uid_card_count_get200_response import GamesGidUsersUidCardCountGet200Response
from openapi_server.models.games_gid_users_uid_player_number_get200_response import GamesGidUsersUidPlayerNumberGet200Response
from openapi_server.models.games_post201_response import GamesPost201Response
from openapi_server.models.jasskarte import Jasskarte
from openapi_server.models.save_points_request import SavePointsRequest
from openapi_server.models.spieler import Spieler
from openapi_server.models.start_new_round_request import StartNewRoundRequest
from openapi_server.models.update_trumpf_request import UpdateTrumpfRequest


class TestGamesControllerUnit(unittest.TestCase):
    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_card_info_cid_get_success(self, mock_supabase):
        # Setup mocks for different table calls
        mock_cardingames_table = MagicMock()
        mock_card_table = MagicMock()

        def table_side_effect(table_name):
            if table_name == 'cardingames':
                return mock_cardingames_table
            if table_name == 'card':
                return mock_card_table
            return MagicMock()

        mock_supabase.table.side_effect = table_side_effect

        # Mock first query (isTrumpf)
        trumpf_resp = MagicMock()
        trumpf_resp.data = {'isTrumpf': True}
        mock_cardingames_table.select.return_value.eq.return_value.eq.return_value.maybe_single.return_value.execute.return_value = trumpf_resp

        # Mock second query (cardtype)
        cardtype_resp = MagicMock()
        cardtype_resp.data = {'cardtype': 'Ass'}
        mock_card_table.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = cardtype_resp
        
        # Call function
        response, status = games_controller.games_gid_card_info_cid_get('GID1', 'CID1')
        self.assertIsInstance(response, CardDetailsResponse)
        self.assertEqual(status, 200)
        self.assertEqual(response.is_trumpf, True)
        self.assertEqual(response.value, 11)
        self.assertEqual(response.worth, 19) # 11 (value) + 8 (trumpf bonus)

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_current_round_id_get_error(self, mock_supabase):
        mock_supabase.table.side_effect = Exception("DB Error")
        response, status = games_controller.games_gid_current_round_id_get('GID1')
        self.assertIsInstance(response, GamesGidCurrentRoundIdGet200Response)
        self.assertEqual(response.rid, '')
        self.assertEqual(status, 500)

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_join_post_not_found(self, mock_supabase):
        table = mock_supabase.table.return_value
        table.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = MagicMock(data=None)
        response, status = games_controller.games_gid_join_post('GID1')
        self.assertIsInstance(response, Error)
        self.assertEqual(status, 404)



    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_cards_shuffle_post_success(self, mock_supabase):
        # Mock table calls
        mock_cardingames_table = MagicMock()
        mock_card_table = MagicMock()
        mock_usergame_table = MagicMock()

        def table_side_effect(table_name):
            if table_name == 'cardingames':
                return mock_cardingames_table
            if table_name == 'card':
                return mock_card_table
            if table_name == 'usergame':
                return mock_usergame_table
            return MagicMock()
        
        mock_supabase.table.side_effect = table_side_effect

        # Mock delete
        mock_cardingames_table.delete.return_value.eq.return_value.execute.return_value = MagicMock(error=None)
        
        # Mock cards query
        cards_resp = MagicMock()
        cards_resp.data = [{'CID': f'c{i}'} for i in range(36)]
        mock_card_table.select.return_value.execute.return_value = cards_resp
        
        # Mock players query
        players_resp = MagicMock()
        players_resp.data = [{'UID': f'u{i}'} for i in range(4)]
        mock_usergame_table.select.return_value.eq.return_value.execute.return_value = players_resp
        
        # Mock successful insert
        mock_cardingames_table.insert.return_value.execute.return_value = MagicMock(error=None)
        
        response, status = games_controller.games_gid_cards_shuffle_post('GID1')
        self.assertIsNone(response)
        self.assertEqual(status, 200)
        mock_cardingames_table.insert.assert_called_once()
        self.assertEqual(len(mock_cardingames_table.insert.call_args[0][0]), 36)

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_cards_shuffle_post_error(self, mock_supabase):
        mock_supabase.table.return_value.delete.return_value.eq.return_value.execute.side_effect = Exception("DB Error")
        response, status = games_controller.games_gid_cards_shuffle_post('GID1')
        self.assertIsInstance(response, Error)
        self.assertEqual(status, 500)

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_players_get_error(self, mock_supabase):
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.side_effect = Exception("DB Error")
        response, status = games_controller.games_gid_players_get('GID1')
        self.assertEqual(response, [])
        self.assertEqual(status, 500)

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_players_post_existing(self, mock_supabase):
        # Mock connexion.request
        with patch('openapi_server.controllers.games_controller.connexion') as mock_connexion:
            mock_connexion.request.is_json = True
            mock_connexion.request.get_json.return_value = {'uid':'u1','name':'n'}
            
            # Mock AddPlayerRequest.from_dict
            with patch('openapi_server.controllers.games_controller.AddPlayerRequest') as mock_request:
                mock_req_instance = AddPlayerRequest(uid='u1', name='n')
                mock_request.from_dict.return_value = mock_req_instance

                mock_user_table = MagicMock()
                mock_usergame_table = MagicMock()
                def table_side_effect(table_name):
                    if table_name == 'User':
                        return mock_user_table
                    if table_name == 'usergame':
                        return mock_usergame_table
                    return MagicMock()
                mock_supabase.table.side_effect = table_side_effect

                mock_user_table.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = MagicMock(data={'UID': 'u1'})
                
                mock_usergame_table.select.return_value.eq.return_value.eq.return_value.maybe_single.return_value.execute.return_value = MagicMock(data={'UID': 'u1', 'GID': 'GID1'})

                response, status = games_controller.games_gid_players_post('GID1', body={})
                
                self.assertEqual(response, "Spieler existiert schon")
                self.assertEqual(status, 200)

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_players_post_success_new_player(self, mock_supabase):
        with patch('openapi_server.controllers.games_controller.connexion') as mock_connexion:
            mock_connexion.request.is_json = True
            mock_connexion.request.get_json.return_value = {'uid': 'u_new', 'name': 'new_name'}
            
            with patch('openapi_server.controllers.games_controller.AddPlayerRequest') as mock_request:
                mock_req_instance = AddPlayerRequest(uid='u_new', name='new_name')
                mock_request.from_dict.return_value = mock_req_instance

                mock_user_table = MagicMock()
                mock_usergame_table = MagicMock()
                def table_side_effect(table_name):
                    if table_name == 'User':
                        return mock_user_table
                    if table_name == 'usergame':
                        return mock_usergame_table
                    return MagicMock()
                mock_supabase.table.side_effect = table_side_effect

                # user does not exist
                mock_user_table.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = MagicMock(data=None)
                mock_user_table.insert.return_value.execute.return_value = MagicMock(error=None)
                
                # usergame link does not exist
                mock_usergame_table.select.return_value.eq.return_value.eq.return_value.maybe_single.return_value.execute.return_value = MagicMock(data=None)
                
                # get next player number
                mock_usergame_table.select.return_value.eq.return_value.execute.return_value = MagicMock(data=[{'playernumber': 1}])
                
                # insert into usergame
                mock_usergame_table.insert.return_value.execute.return_value = MagicMock(error=None)

                response, status = games_controller.games_gid_players_post('GID1', body={})
                
                self.assertIsNone(response)
                self.assertEqual(status, 201)
                mock_user_table.insert.assert_called_once_with({'UID': 'u_new', 'name': 'new_name'})
                mock_usergame_table.insert.assert_called_once_with({'GID': 'GID1', 'UID': 'u_new', 'playernumber': 2})

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_rounds_post_success(self, mock_supabase):
        with patch('openapi_server.controllers.games_controller.connexion') as mock_connexion:
            mock_connexion.request.is_json = True
            mock_connexion.request.get_json.return_value = {'whichround': 2}
            
            with patch('openapi_server.controllers.games_controller.StartNewRoundRequest') as mock_request:
                mock_req_instance = StartNewRoundRequest(whichround=2)
                mock_request.from_dict.return_value = mock_req_instance

                mock_supabase.table.return_value.insert.return_value.execute.return_value = MagicMock(error=None)

                response, status = games_controller.games_gid_rounds_post('GID1', body={})
                
                self.assertIsNone(response)
                self.assertEqual(status, 201)
                mock_supabase.table.return_value.insert.assert_called_once_with({'GID': 'GID1', 'whichround': 2})

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_trumpf_suit_put_success(self, mock_supabase):
        with patch('openapi_server.controllers.games_controller.connexion') as mock_connexion:
            mock_connexion.request.is_json = True
            mock_connexion.request.get_json.return_value = {'trumpf_symbol': 'S'}
            
            with patch('openapi_server.controllers.games_controller.UpdateTrumpfRequest') as mock_request:
                mock_req_instance = UpdateTrumpfRequest(trumpf_symbol='S')
                mock_request.from_dict.return_value = mock_req_instance

                mock_cardingames_table = MagicMock()
                mock_card_table = MagicMock()
                def table_side_effect(table_name):
                    if table_name == 'cardingames':
                        return mock_cardingames_table
                    if table_name == 'card':
                        return mock_card_table
                    return MagicMock()
                mock_supabase.table.side_effect = table_side_effect

                mock_cardingames_table.update.return_value.eq.return_value.execute.return_value = MagicMock(error=None)
                
                cards_resp = MagicMock()
                cards_resp.data = [{'CID': 'c1'}, {'CID': 'c2'}]
                mock_card_table.select.return_value.eq.return_value.execute.return_value = cards_resp

                mock_cardingames_table.update.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(error=None)

                response, status = games_controller.games_gid_trumpf_suit_put('GID1', body={})
                
                self.assertIsNone(response)
                self.assertEqual(status, 200)

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_update_scores_post_success(self, mock_supabase):
        with patch('openapi_server.controllers.games_controller.connexion') as mock_connexion:
            req_body = {
                'winner_uid': 'u1',
                'teammate_uid': 'u3',
                'played_cards': [{'cid': 'c1'}, {'cid': 'c2'}]
            }
            mock_connexion.request.is_json = True
            mock_connexion.request.get_json.return_value = req_body
            
            with patch('openapi_server.controllers.games_controller.SavePointsRequest') as mock_request:
                # We need to mock the nested objects as well
                card1 = MagicMock()
                card1.cid = 'c1'
                card2 = MagicMock()
                card2.cid = 'c2'
                mock_req_instance = SavePointsRequest(winner_uid='u1', teammate_uid='u3', played_cards=[card1, card2])
                mock_request.from_dict.return_value = mock_req_instance

                mock_card_table = MagicMock()
                mock_cardingames_table = MagicMock()
                mock_usergame_table = MagicMock()
                def table_side_effect(table_name):
                    if table_name == 'card':
                        return mock_card_table
                    if table_name == 'cardingames':
                        return mock_cardingames_table
                    if table_name == 'usergame':
                        return mock_usergame_table
                    return MagicMock()
                mock_supabase.table.side_effect = table_side_effect

                mock_card_table.select.return_value.eq.return_value.maybe_single.return_value.execute.side_effect = [
                    MagicMock(data={'cardtype': 'Ass'}),
                    MagicMock(data={'cardtype': 'König'})
                ]
                mock_cardingames_table.select.return_value.eq.return_value.eq.return_value.maybe_single.return_value.execute.side_effect = [
                    MagicMock(data={'isTrumpf': True}),
                    MagicMock(data={'isTrumpf': False})
                ]

                old_scores_resp = MagicMock()
                old_scores_resp.data = [
                    {'UID': 'u1', 'score': 100},
                    {'UID': 'u3', 'score': 120}
                ]
                mock_usergame_table.select.return_value.eq.return_value.in_.return_value.execute.return_value = old_scores_resp

                mock_usergame_table.upsert.return_value.execute.return_value = MagicMock(error=None)

                response, status = games_controller.games_gid_update_scores_post('GID1', body=req_body)
                
                self.assertIsInstance(response, GamesGidUpdateScoresPost200Response)
                self.assertEqual(status, 200)
                self.assertEqual(response.total_points, 15) # 11 (Ass) + 4 (König)

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_users_uid_card_count_get_success(self, mock_supabase):
        resp = MagicMock()
        resp.data = [1, 2, 3] # Simulate 3 cards found
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = resp
        
        response, status = games_controller.games_gid_users_uid_card_count_get('GID1', 'u1')
        
        self.assertIsInstance(response, GamesGidUsersUidCardCountGet200Response)
        self.assertEqual(response.count, 3)
        self.assertEqual(status, 200)

    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_users_uid_cards_get_error(self, mock_supabase):
        mock_supabase.table.side_effect = Exception('fail')
        response, status = games_controller.games_gid_users_uid_cards_get('GID1', 'u1')
        self.assertEqual(response, [])
        self.assertEqual(status, 500)


    @patch('openapi_server.controllers.games_controller.supabase')
    def test_games_gid_users_uid_player_number_get_success(self, mock_supabase):
        resp = MagicMock()
        resp.data = {'playernumber': 2}
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.maybe_single.return_value.execute.return_value = resp
        
        response, status = games_controller.games_gid_users_uid_player_number_get('GID1', 'u1')
        
        self.assertIsInstance(response, GamesGidUsersUidPlayerNumberGet200Response)
        self.assertEqual(response.playernumber, 2)
        self.assertEqual(status, 200)

if __name__ == '__main__':
    unittest.main()
