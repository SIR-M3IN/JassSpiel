import connexion
from typing import Dict
from typing import Tuple
from typing import Union

from openapi_server.models.add_play_request import AddPlayRequest  # noqa: E501
from openapi_server.models.games_gid_next_player_uid_get200_response import GamesGidNextPlayerUidGet200Response  # noqa: E501
from openapi_server.models.jasskarte import Jasskarte  # noqa: E501
from openapi_server.models.rounds_rid_first_card_cid_get200_response import RoundsRidFirstCardCidGet200Response  # noqa: E501
from openapi_server.models.update_turn_request import UpdateTurnRequest  # noqa: E501
from openapi_server.models.update_winner_request import UpdateWinnerRequest  # noqa: E501
from openapi_server import util


def rounds_rid_first_card_cid_get(rid):  # noqa: E501
    """Holt die CID der ersten gespielten Karte in einer Runde.

     # noqa: E501

    :param rid: 
    :type rid: str

    :rtype: Union[RoundsRidFirstCardCidGet200Response, Tuple[RoundsRidFirstCardCidGet200Response, int], Tuple[RoundsRidFirstCardCidGet200Response, int, Dict[str, str]]
    """
    return 'do some magic!'


def rounds_rid_first_card_get(rid):  # noqa: E501
    """Holt das Objekt der ersten gespielten Karte in einer Runde.

     # noqa: E501

    :param rid: 
    :type rid: str

    :rtype: Union[Jasskarte, Tuple[Jasskarte, int], Tuple[Jasskarte, int, Dict[str, str]]
    """
    return 'do some magic!'


def rounds_rid_played_cards_get(rid):  # noqa: E501
    """Holt alle gespielten Karten einer Runde.

     # noqa: E501

    :param rid: 
    :type rid: str

    :rtype: Union[List[Jasskarte], Tuple[List[Jasskarte], int], Tuple[List[Jasskarte], int, Dict[str, str]]
    """
    return 'do some magic!'


def rounds_rid_plays_post(rid, body):  # noqa: E501
    """Fügt einen Spielzug (gespielte Karte) zu einer Runde hinzu.

     # noqa: E501

    :param rid: 
    :type rid: str
    :param add_play_request: 
    :type add_play_request: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    add_play_request = body
    if connexion.request.is_json:
        add_play_request = AddPlayRequest.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def rounds_rid_turn_get(rid):  # noqa: E501
    """Holt die UID des Spielers, der aktuell am Zug ist.

     # noqa: E501

    :param rid: 
    :type rid: str

    :rtype: Union[GamesGidNextPlayerUidGet200Response, Tuple[GamesGidNextPlayerUidGet200Response, int], Tuple[GamesGidNextPlayerUidGet200Response, int, Dict[str, str]]
    """
    return 'do some magic!'


def rounds_rid_turn_put(rid, body):  # noqa: E501
    """Aktualisiert, welcher Spieler am Zug ist.

     # noqa: E501

    :param rid: 
    :type rid: str
    :param update_turn_request: 
    :type update_turn_request: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    update_turn_request = body
    if connexion.request.is_json:
        update_turn_request = UpdateTurnRequest.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def rounds_rid_winner_put(rid, body):  # noqa: E501
    """Aktualisiert den Gewinner einer Runde.

     # noqa: E501

    :param rid: 
    :type rid: str
    :param update_winner_request: 
    :type update_winner_request: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    update_winner_request = body
    if connexion.request.is_json:
        update_winner_request = UpdateWinnerRequest.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'
