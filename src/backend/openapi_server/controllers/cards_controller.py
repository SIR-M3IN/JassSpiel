"""
@file cards_controller.py
@brief Controller für Karten-bezogene API-Endpunkte des Jass-Spiels
@details Behandelt alle HTTP-Anfragen für Kartenoperationen wie Abrufen von Kartendetails,
         Bestimmung der Gewinnerkarte und Laden aller verfügbaren Karten.
"""

import connexion
from typing import Dict, List, Tuple, Union

from openapi_server.models.cards_cid_type_get200_response import CardsCidTypeGet200Response
from openapi_server.models.determine_winning_card_request import DetermineWinningCardRequest
from openapi_server.models.jasskarte import Jasskarte as ApiJasskarte
from openapi_server.models.winning_card_response import WinningCardResponse
from openapi_server.db import supabase
from openapi_server.logger import logger
from ..cards_determine import get_winning_card, Jasskarte as LogicJasskarte


def cards_cid_get(cid: str) -> Tuple[Union[Dict,str], int]:
    """
    @brief Ruft Kartendetails anhand der Karten-ID ab
    @param cid Eindeutige Karten-ID
    @return Tuple mit Kartendetails (Dict) und HTTP-Status (int)
    @details Lädt Kartendaten aus der Datenbank und gibt Symbol, Typ und Pfad zurück
    """
    logger.info(f"cards_cid_get called with cid={cid}")
    try:
        resp = supabase.table('card') \
                       .select('CID, symbol, cardtype') \
                       .eq('CID', cid) \
                       .limit(1) \
                       .execute()
        if resp and resp.data:
            d = resp.data[0]
            logger.debug(f"cards_cid_get found data: {d}")
            return {
                "cid": d['CID'],
                "symbol": d['symbol'],
                "cardtype": d['cardtype'],
                "path": f"assets/{d['symbol']}/{d['symbol']}_{d['cardtype']}.png"
            }, 200
        logger.warning(f"cards_cid_get no data found for cid={cid}")
        return {"message": "not found"}, 404
    except Exception as e:
        logger.exception(f"cards_cid_get error: {e}")
        return {"message": "error1"}, 500

def cards_cid_type_get(cid: str) -> Tuple[Dict,int]:
    """
    @brief Ruft nur den Kartentyp anhand der Karten-ID ab
    @param cid Eindeutige Karten-ID
    @return Tuple mit Kartentyp (Dict) und HTTP-Status (int)
    @details Lädt nur den Typ einer Karte (z.B. 'Ass', 'König', '7') aus der Datenbank
    """
    logger.info(f"cards_cid_type_get called with cid={cid}")
    try:
        resp = supabase.table('card') \
                       .select('cardtype') \
                       .eq('CID', cid) \
                       .limit(1) \
                       .execute()
        if resp and resp.data:
            cardtype = resp.data[0]['cardtype']
            logger.debug(f"cards_cid_type_get found cardtype: {cardtype}")
            return {"cardtype": cardtype}, 200
        logger.info(f"cards_cid_type_get empty data for cid={cid}")
        return {"cardtype": ""}, 200
    except Exception as e:
        logger.exception(f"cards_cid_type_get error: {e}")
        return {"message": "error2"}, 500

def cards_determine_winning_card_post(
         gid: str, body: Dict
     ) -> Tuple[WinningCardResponse, int]:
    """
    @brief Bestimmt die Gewinnerkarte aus einer Liste gespielter Karten
    @param gid Spiel-ID für Kontext (Trumpf-Status)
    @param body Request-Body mit Liste der gespielten Karten
    @return Tuple mit WinningCardResponse (UID des Gewinners) und HTTP-Status
    @details Verwendet die Spiellogik um basierend auf Jass-Regeln die stärkste Karte zu ermitteln
    """
    logger.info(f"cards_determine_winning_card_post called with gid={gid}, body={body}")
    try:
        req = DetermineWinningCardRequest.from_dict(body)
        logger.debug(f"Request parsed: {req.cards}")
        logic_cards = [LogicJasskarte(cid=c.cid) for c in (req.cards or []) if c and c.cid]
        if not logic_cards:
            logger.info("No cards provided, returning empty winner")
            return WinningCardResponse(winner_uid=""), 200
        winner = get_winning_card(logic_cards, gid)
        logger.info(f"Winning card UID: {winner}")
        return WinningCardResponse(winner_uid=winner), 200
    except Exception as e:
        logger.exception(f"cards_determine_winning_card_post error: {e}")
        return WinningCardResponse(winner_uid=""), 500

def cards_get():
    """
    @brief Ruft alle verfügbaren Karten aus der Datenbank ab
    @return Tuple mit Liste aller Karten (List[ApiJasskarte]) und HTTP-Status (int)
    @details Lädt das komplette Kartendeck mit allen Details (ID, Symbol, Typ, Pfad)
    """
    logger.info("cards_get called")
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
        logger.debug(f"cards_get returning {len(lst)} cards")
        return lst, 200
    except Exception as e:
        logger.exception(f"cards_get error: {e}")
        return {"message": "error4"}, 500