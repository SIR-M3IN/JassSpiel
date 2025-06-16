import connexion
from typing import Dict
from typing import Tuple
from typing import Union
import random

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
from openapi_server import util
from openapi_server.db import supabase
from tenacity import retry, stop_after_attempt, wait_fixed, retry_if_exception_type

def games_gid_card_info_cid_get(gid, cid):  # noqa: E501
    """Holt eine Karte in einer Runde

     # noqa: E501

    :param gid: 
    :type gid: str
    :param cid: 
    :type cid: str

    :rtype: Union[CardDetailsResponse, Tuple[CardDetailsResponse, int], Tuple[CardDetailsResponse, int, Dict[str, str]]
    """
    try:
        # Check if card is trumpf in this game
        resp = supabase.table('cardingames').select('isTrumpf').eq('GID', gid).eq('CID', cid).maybe_single().execute()
        is_trumpf = bool(resp.data.get('isTrumpf')) if resp and resp.data else False
        # Retrieve card type
        ct_resp = supabase.table('card').select('cardtype').eq('CID', cid).maybe_single().execute()
        cardtype = ct_resp.data.get('cardtype') if ct_resp and ct_resp.data else ''
        # Determine value
        if is_trumpf:
            value_map = {'Ass': 11, 'König': 4, 'Ober': 3, 'Unter': 20, '10': 10, '9': 14}
        else:
            value_map = {'Ass': 11, 'König': 4, 'Ober': 3, 'Unter': 2, '10': 10, '9': 0}
        value = value_map.get(cardtype, 0)
        # Determine worth
        if is_trumpf:
            worth_map = {'Ass': 19, 'König': 18, 'Ober': 17, 'Unter': 16, '10': 15, '9': 14, '8': 13, '7': 12, '6': 11}
        else:
            worth_map = {'Ass': 9, 'König': 8, 'Ober': 7, 'Unter': 6, '10': 5, '9': 4, '8': 3, '7': 2, '6': 1}
        worth = worth_map.get(cardtype, 0)
        return CardDetailsResponse(cid=cid, is_trumpf=is_trumpf, value=value, worth=worth), 200
    except Exception as e:
        print(f"Error in games_gid_card_info_cid_get: {e}")
        return Error(message="Fehler beim Abrufen der Karteninfo."), 500

def games_gid_cards_shuffle_post(gid): #!  # noqa: E501
    """Mischt und verteilt Karten an die Spieler eines Spiels.

     # noqa: E501

    :param gid: 
    :type gid: str

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    try:
        supabase.table('cardingames').delete().eq('GID', gid).execute()
        cards_resp = supabase.table('card').select('CID').execute()
        cids = [d['CID'] for d in (cards_resp.data or [])]
        players_resp = supabase.table('usergame').select('UID').eq('GID', gid).execute()
        uids = [d['UID'] for d in (players_resp.data or [])]
        random.shuffle(cids)
        records = []
        if uids and cids:
            hand_size = len(cids) // len(uids)
            for i, uid in enumerate(uids):
                start = i * hand_size
                end = start + hand_size
                for cid in cids[start:end]:
                    records.append({'UID': uid, 'CID': cid, 'GID': gid})
        if records:
            print(f"DEBUG shuffle: inserting {len(records)} cards for game {gid}")
            insert_resp = supabase.table('cardingames').insert(records).execute()
            if hasattr(insert_resp, 'error') and insert_resp.error:
                print(f"Error inserting cards: {insert_resp.error.message}")
                raise Exception(insert_resp.error.message)
        return None, 200
    except Exception as e:
        print(f"Error in games_gid_cards_shuffle_post: {e}")
        return Error(message="Fehler beim Mischen der Karten."), 500

def games_gid_current_round_id_get(gid: str) -> Tuple[GamesGidCurrentRoundIdGet200Response, int]:
    try:
        resp = (
            supabase
            .table('rounds')
            .select('RID')
            .eq('GID', gid)
            .order('whichround', desc=False)
            .limit(1)
            .maybe_single()
            .execute()
        )
        rid = resp.data.get('RID', '') if resp and resp.data else ''
        print(f"Found RID: {rid}")
        return GamesGidCurrentRoundIdGet200Response(rid=rid), 200

    except Exception as e:
        print(f"Error in games_gid_current_round_id_get: {e}")
        return GamesGidCurrentRoundIdGet200Response(rid=""), 500


def games_gid_current_round_number_get(gid):  # noqa: E501
    """Holt die Nummer der aktuellen Runde.

     # noqa: E501

    :param gid: 
    :type gid: str

    :rtype: Union[GamesGidCurrentRoundNumberGet200Response, Tuple[GamesGidCurrentRoundNumberGet200Response, int], Tuple[GamesGidCurrentRoundNumberGet200Response, int, Dict[str, str]]
    """
    try:
        resp = supabase.table('rounds') \
                      .select('whichround') \
                      .eq('GID', gid) \
                      .order('whichround', desc=False) \
                      .limit(1) \
                      .maybe_single() \
                      .execute()
        which = resp.data.get('whichround') if resp and resp.data else 0
        return GamesGidCurrentRoundNumberGet200Response(whichround=which), 200
    except Exception as e:
        print(f"Error in games_gid_current_round_number_get: {e}")
        return GamesGidCurrentRoundNumberGet200Response(whichround=0), 500


def games_gid_join_post(gid):  # noqa: E501
    """Lässt einen Spieler einem Spiel beitreten.

    Aktualisiert die Teilnehmerzahl des Spiels. # noqa: E501

    :param gid: 
    :type gid: str

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    try:
        resp = supabase.table('games').select('participants').eq('GID', gid).maybe_single().execute()
        if not resp or not resp.data:
            return Error(message="Spiel nicht gefunden."), 404
        current = resp.data.get('participants', 0)
        supabase.table('games').update({'participants': current + 1}).eq('GID', gid).execute()
        return None, 200
    except Exception as e:
        print(f"Error in games_gid_join_post: {e}")
        return Error(message="Fehler beim Beitreten zum Spiel."), 500


def games_gid_next_player_uid_get(gid, playernumber):  # noqa: E501
    """Holt die UID des nächsten Spielers basierend auf der Spielernummer.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param playernumber: 
    :type playernumber: int

    :rtype: Union[GamesGidNextPlayerUidGet200Response, Tuple[GamesGidNextPlayerUidGet200Response, int], Tuple[GamesGidNextPlayerUidGet200Response, int, Dict[str, str]]
    """
    try:
        resp = supabase.table('usergame').select('UID').eq('GID', gid).eq('playernumber', playernumber).maybe_single().execute()
        uid = resp.data.get('UID') if resp and resp.data else ''
        return GamesGidNextPlayerUidGet200Response(uid=uid), 200
    except Exception as e:
        print(f"Error in games_gid_next_player_uid_get: {e}")
        return GamesGidNextPlayerUidGet200Response(uid=""), 500


def games_gid_players_get(gid):  # noqa: E501
    """Lädt alle Spieler für ein Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str

    :rtype: Union[List[Spieler], Tuple[List[Spieler], int], Tuple[List[Spieler], int, Dict[str, str]]
    """
    try:
        resp = supabase.table('usergame').select('playernumber,User!usergame_UID_fkey(UID,name)').eq('GID', gid).execute()
        players = []
        for d in (resp.data or []):
            user = d.get('User') or {}
            players.append(Spieler(uid=user.get('UID'), name=user.get('name'), playernumber=d.get('playernumber')))
        return players, 200
    except Exception as e:
        print(f"Error in games_gid_players_get: {e}")
        return [], 500


def games_gid_players_post(gid, body):  # noqa: E501
    """Fügt einen Spieler zu einem Spiel hinzu.

    Speichert den Benutzer falls nötig und weist ihm eine Spielernummer zu. # noqa: E501

    :param gid: 
    :type gid: str
    :param add_player_request: 
    :type add_player_request: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    try:
        if connexion.request.is_json:
            req = AddPlayerRequest.from_dict(connexion.request.get_json())
        else:
            req = body
        usr = supabase.table('User').select('UID').eq('UID', req.uid).maybe_single().execute()
        if not usr or not usr.data:
            supabase.table('User').insert({'UID': req.uid, 'name': req.name}).execute()
        else:
            supabase.table('User').update({'name': req.name}).eq('UID', req.uid).execute()
        exist = supabase.table('usergame').select('UID').eq('GID', gid).eq('UID', req.uid).maybe_single().execute()
        if exist and exist.data:
            return "Spieler existiert schon", 200
        ug = supabase.table('usergame').select('playernumber').eq('GID', gid).execute()
        nums = [d.get('playernumber', 0) for d in (ug.data or [])]
        next_num = max(nums) + 1 if nums else 1
        supabase.table('usergame').insert({'GID': gid, 'UID': req.uid, 'playernumber': next_num}).execute()
        return None, 201
    except Exception as e:
        print(f"Error in games_gid_players_post: {e}")
        return Error(message="Fehler beim Hinzufügen des Spielers."), 500


def games_gid_rounds_post(gid, body):  # noqa: E501
    """Startet eine neue Runde in einem Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param start_new_round_request: 
    :type start_new_round_request: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    try:
        if connexion.request.is_json:
            req = StartNewRoundRequest.from_dict(connexion.request.get_json())
        else:
            req = body
        supabase.table('rounds').insert({'GID': gid, 'whichround': req.whichround}).execute()
        return None, 201
    except Exception as e:
        print(f"Error in games_gid_rounds_post: {e}")
        return Error(message="Fehler beim Starten einer neuen Runde."), 500


def games_gid_trumpf_suit_put(gid, body):  # noqa: E501
    """Aktualisiert die Trumpffarbe für ein Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param update_trumpf_request: 
    :type update_trumpf_request: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    try:
        if connexion.request.is_json:
            req = UpdateTrumpfRequest.from_dict(connexion.request.get_json())
        else:
            req = body
        supabase.table('cardingames').update({'isTrumpf': False}).eq('GID', gid).execute()
        cards = supabase.table('card').select('CID').eq('symbol', req.trumpf_symbol).execute()
        for c in (cards.data or []):
            supabase.table('cardingames').update({'isTrumpf': True}).eq('GID', gid).eq('CID', c.get('CID')).execute()
        return None, 200
    except Exception as e:
        print(f"Error in games_gid_trumpf_suit_put: {e}")
        return Error(message="Fehler beim Aktualisieren der Trumpffarbe."), 500


def games_gid_update_scores_post(gid, body):  # noqa: E501
    try:
        # 1. Request parsen
        if connexion.request.is_json:
            req = SavePointsRequest.from_dict(connexion.request.get_json())
        else:
            req = SavePointsRequest.from_dict(body)

        # 2. Punkte berechnen
        total_points = 0
        for card in (req.played_cards or []):
            cid = card.cid
            # Kartentyp
            ct = supabase.table('card') \
                        .select('cardtype') \
                        .eq('CID', cid) \
                        .maybe_single() \
                        .execute()
            cardtype = ct.data.get('cardtype', '') if ct and ct.data else ''
            # Trumpf?
            tr = supabase.table('cardingames') \
                        .select('isTrumpf') \
                        .eq('GID', gid) \
                        .eq('CID', cid) \
                        .maybe_single() \
                        .execute()
            is_tr = bool(tr.data.get('isTrumpf', False)) if tr and tr.data else False
            # Wertetabelle
            val_map = (
                {'Ass':11,'König':4,'Ober':3,'Unter':20,'10':10,'9':14}
                if is_tr
                else {'Ass':11,'König':4,'Ober':3,'Unter':2,'10':10,'9':0}
            )
            total_points += val_map.get(cardtype, 0)

        # 3. Alte Scores holen
        resp = supabase.table('usergame') \
                       .select('UID,score') \
                       .eq('GID', gid) \
                       .in_('UID', [req.winner_uid, req.teammate_uid]) \
                       .execute()
        existing = {d['UID']: d.get('score', 0) for d in (resp.data or [])}

        # 4. Upsert der neuen Scores
        updates = [
            {'GID': gid, 'UID': req.winner_uid,
             'score': existing.get(req.winner_uid, 0) + total_points},
            {'GID': gid, 'UID': req.teammate_uid,
             'score': existing.get(req.teammate_uid, 0) + total_points},
        ]
        supabase.table('usergame').upsert(updates).execute()

        # 5. Antwort zurückgeben (Param-Name totalPoints)
        return GamesGidUpdateScoresPost200Response(total_points=total_points), 200

    except Exception as e:
        print(f"Error in games_gid_update_scores_post: {e}")
        return

def games_gid_users_uid_card_count_get(gid, uid):  # noqa: E501
    """Holt die Anzahl der Karten eines Spielers.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param uid: 
    :type uid: str

    :rtype: Union[GamesGidUsersUidCardCountGet200Response, Tuple[GamesGidUsersUidCardCountGet200Response, int], Tuple[GamesGidUsersUidCardCountGet200Response, int, Dict[str, str]]
    """
    try:
        resp = supabase.table('cardingames').select('CID').eq('GID', gid).eq('UID', uid).execute()
        count = len(resp.data or [])
        return GamesGidUsersUidCardCountGet200Response(count=count), 200
    except Exception as e:
        print(f"Error in games_gid_users_uid_card_count_get: {e}")
        return GamesGidUsersUidCardCountGet200Response(count=0), 500


def games_gid_users_uid_cards_get(gid, uid):  # noqa: E501
    """Holt die Karten eines bestimmten Spielers in einem Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param uid: 
    :type uid: str

    :rtype: Union[List[Jasskarte], Tuple[List[Jasskarte], int], Tuple[List[Jasskarte], int, Dict[str, str]]
    """
    try:
        resp = supabase.table('cardingames').select('CID,card(symbol,cardtype)').eq('GID', gid).eq('UID', uid).execute()
        cards = []
        for d in (resp.data or []):
            card = d.get('card') or {}
            cards.append(Jasskarte(cid=d.get('CID'), symbol=card.get('symbol'), cardtype=card.get('cardtype'), path=f"assets/{card.get('symbol')}/{card.get('symbol')}_{card.get('cardtype')}.png"))
        return cards, 200
    except Exception as e:
        print(f"Error in games_gid_users_uid_cards_get: {e}")
        return [], 500


def games_gid_users_uid_player_number_get(gid, uid):  # noqa: E501
    """Holt die Spielernummer eines Benutzers in einem Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param uid: 
    :type uid: str

    :rtype: Union[GamesGidUsersUidPlayerNumberGet200Response, Tuple[GamesGidUsersUidPlayerNumberGet200Response, int], Tuple[GamesGidUsersUidPlayerNumberGet200Response, int, Dict[str, str]]
    """
    try:
        resp = supabase.table('usergame').select('playernumber').eq('GID', gid).eq('UID', uid).maybe_single().execute()
        num = resp.data.get('playernumber') if resp and resp.data else 0
        return GamesGidUsersUidPlayerNumberGet200Response(playernumber=num), 200
    except Exception as e:
        print(f"Error in games_gid_users_uid_player_number_get: {e}")
        return GamesGidUsersUidPlayerNumberGet200Response(playernumber=0), 500


def games_post():  # noqa: E501
    """Erstellt ein neues Spiel.

    Generiert einen einzigartigen Spielcode (GID) und initialisiert das Spiel. # noqa: E501


    :rtype: Union[GamesPost201Response, Tuple[GamesPost201Response, int], Tuple[GamesPost201Response, int, Dict[str, str]]
    """
    try:
        # Generate unique game code
        chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
        code = ''
        while True:
            code = ''.join(random.choice(chars) for _ in range(4))
            chk = supabase.table('games').select('GID').eq('GID', code).maybe_single().execute()
            if not chk or not chk.data:
                break
        # Insert new game
        supabase.table('games').insert({'GID': code, 'status': 'waiting', 'participants': 1, 'room_name': 'Neuer Raum'}).execute()
        return GamesPost201Response(gid=code), 201
    except Exception as e:
        print(f"Error in games_post: {e}")
        return Error(message="Fehler beim Erstellen des Spiels."), 500
