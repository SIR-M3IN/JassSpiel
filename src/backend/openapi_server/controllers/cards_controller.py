import connexion
from typing import Dict, List, Tuple, Union

from openapi_server.models.cards_cid_type_get200_response import CardsCidTypeGet200Response
from openapi_server.models.determine_winning_card_request import DetermineWinningCardRequest
from openapi_server.models.jasskarte import Jasskarte as ApiJasskarte
from openapi_server.models.winning_card_response import WinningCardResponse
from openapi_server.db import supabase

from ..cards_determine import get_winning_card, Jasskarte as LogicJasskarte

def cards_cid_get(cid: str) -> Tuple[Union[Dict,str], int]:
    try:
        resp = supabase.table('card') \
                       .select('CID, symbol, cardtype') \
                       .eq('CID', cid) \
                       .limit(1) \
                       .execute()
        if resp and resp.data:
            d = resp.data[0]
            return {
                "cid": d['CID'],
                "symbol": d['symbol'],
                "cardtype": d['cardtype'],
                "path": f"assets/{d['symbol']}/{d['symbol']}_{d['cardtype']}.png"
            }, 200
        return {"message": "not found"}, 404
    except:
        return {"message": "error1"}, 500

def cards_cid_type_get(cid: str) -> Tuple[Dict,int]:
    try:
        resp = supabase.table('card') \
                       .select('cardtype') \
                       .eq('CID', cid) \
                       .limit(1) \
                       .execute()
        if resp and resp.data:
            return {"cardtype": resp.data[0]['cardtype']}, 200
        return {"cardtype": ""}, 200
    except:
        return {"message": "error2"}, 500

def cards_determine_winning_card_post(
        gid: str, body: Dict
    ) -> Tuple[WinningCardResponse, int]:
    # Todo
    try:
        req = DetermineWinningCardRequest.from_dict(body)
        logic_cards = [LogicJasskarte(cid=c.cid) for c in (req.cards or []) if c and c.cid]
        if not logic_cards:
            return WinningCardResponse(winner_uid=""), 200
        winner = get_winning_card(logic_cards, gid)
        return WinningCardResponse(winner_uid=winner), 200
    except Exception:
        return WinningCardResponse(winner_uid=""), 500

def cards_get():
    try:
        resp = supabase.table('card').select('CID, symbol, cardtype').execute()
        lst = [
            ApiJasskarte(
                cid=d['CID'],
                symbol=d['symbol'],
                cardtype=d['cardtype'],
                path=f"assets/{d['symbol']}/{d['symbol']}_{d['cardtype']}.png"
            )
            for d in (resp.data or [])
        ]
        return lst, 200
    except:
        return {"message": "error4"}, 500