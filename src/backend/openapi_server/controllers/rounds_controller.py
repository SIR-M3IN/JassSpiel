import connexion
from typing import Dict, List, Tuple, Union

from openapi_server.models.add_play_request import AddPlayRequest
from openapi_server.models.games_gid_next_player_uid_get200_response import GamesGidNextPlayerUidGet200Response
from openapi_server.models.jasskarte import Jasskarte as ApiJasskarte
from openapi_server.models.rounds_rid_first_card_cid_get200_response import RoundsRidFirstCardCidGet200Response
from openapi_server.models.update_turn_request import UpdateTurnRequest
from openapi_server.models.update_winner_request import UpdateWinnerRequest
from openapi_server.db import supabase


def rounds_rid_first_card_cid_get(rid: str) -> Tuple[RoundsRidFirstCardCidGet200Response, int]:  # noqa: E501
    try:
        resp = supabase.table('plays').select('CID').eq('RID', rid).limit(1).maybe_single().execute()
        cid = resp.data.get('CID') if resp and resp.data else ''
        return RoundsRidFirstCardCidGet200Response(cid=cid), 200
    except Exception as e:
        print(f"Error in rounds_rid_first_card_cid_get: {e}")
        return RoundsRidFirstCardCidGet200Response(cid=""), 500


def rounds_rid_first_card_get(rid: str) -> Tuple[Union[ApiJasskarte, None], int]:  # noqa: E501
    try:
        resp = supabase.table('plays').select('CID').eq('RID', rid).limit(1).maybe_single().execute()
        cid = resp.data.get('CID') if resp and resp.data else None
        if not cid:
            return None, 200
        card_resp = supabase.table('card').select('CID, symbol, cardtype').eq('CID', cid).maybe_single().execute()
        d = card_resp.data if card_resp and card_resp.data else {}
        return ApiJasskarte(cid=d.get('CID'), symbol=d.get('symbol'), cardtype=d.get('cardtype'), path=f"assets/{d.get('symbol')}/{d.get('symbol')}_{d.get('cardtype')}.png"), 200
    except Exception as e:
        print(f"Error in rounds_rid_first_card_get: {e}")
        return None, 500


def rounds_rid_played_cards_get(rid: str) -> Tuple[List[ApiJasskarte], int]:  # noqa: E501
    try:
        resp = supabase.table('plays').select('CID, card(symbol,cardtype)').eq('RID', rid).execute()
        cards: List[ApiJasskarte] = []
        for rec in (resp.data or []):
            c = rec.get('card') or {}
            cards.append(ApiJasskarte(cid=rec.get('CID'), symbol=c.get('symbol'), cardtype=c.get('cardtype'), path=f"assets/{c.get('symbol')}/{c.get('symbol')}_{c.get('cardtype')}.png"))
        return cards, 200
    except Exception as e:
        print(f"Error in rounds_rid_played_cards_get: {e}")
        return [], 500


def rounds_rid_plays_post(rid: str, body: Dict) -> Tuple[None, int]:  # noqa: E501
    try:
        req = AddPlayRequest.from_dict(connexion.request.get_json())
        supabase.table('plays').insert({'RID': rid, 'UID': req.uid, 'CID': req.cid}).execute()
        return None, 200
    except Exception as e:
        print(f"Error in rounds_rid_plays_post: {e}")
        return None, 500


def rounds_rid_turn_get(rid: str) -> Tuple[GamesGidNextPlayerUidGet200Response, int]:  # noqa: E501
    try:
        resp = supabase.table('rounds').select('whoIsAtTurn').eq('RID', rid).maybe_single().execute()
        uid = resp.data.get('whoIsAtTurn') if resp and resp.data else ''
        return GamesGidNextPlayerUidGet200Response(uid=uid), 200
    except Exception as e:
        print(f"Error in rounds_rid_turn_get: {e}")
        return GamesGidNextPlayerUidGet200Response(uid=""), 500


def rounds_rid_turn_put(rid: str, body: Dict) -> Tuple[None, int]:  # noqa: E501
    try:
        req = UpdateTurnRequest.from_dict(connexion.request.get_json())
        supabase.table('rounds').update({'whoIsAtTurn': req.uid}).eq('RID', rid).execute()
        return None, 200
    except Exception as e:
        print(f"Error in rounds_rid_turn_put: {e}")
        return None, 500


def rounds_rid_winner_put(rid: str, body: Dict) -> Tuple[None, int]:  # noqa: E501
    try:
        req = UpdateWinnerRequest.from_dict(connexion.request.get_json())
        supabase.table('rounds').update({'winnerid': req.winner_uid}).eq('RID', rid).execute()
        return None, 200
    except Exception as e:
        print(f"Error in rounds_rid_winner_put: {e}")
        return None, 500
