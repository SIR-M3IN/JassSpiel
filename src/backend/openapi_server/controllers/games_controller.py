import connexion
from typing import Dict
from typing import Tuple
from typing import Union

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


def games_gid_card_info_cid_get(gid, cid):  # noqa: E501
    """Holt eine Karte in einer Runde

     # noqa: E501

    :param gid: 
    :type gid: str
    :param cid: 
    :type cid: str

    :rtype: Union[CardDetailsResponse, Tuple[CardDetailsResponse, int], Tuple[CardDetailsResponse, int, Dict[str, str]]
    """
    return 'do some magic!'


def games_gid_cards_shuffle_post(gid):  # noqa: E501
    """Mischt und verteilt Karten an die Spieler eines Spiels.

     # noqa: E501

    :param gid: 
    :type gid: str

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    return 'do some magic!'


def games_gid_current_round_id_get(gid):  # noqa: E501
    """Holt die ID der aktuellen Runde für ein Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str

    :rtype: Union[GamesGidCurrentRoundIdGet200Response, Tuple[GamesGidCurrentRoundIdGet200Response, int], Tuple[GamesGidCurrentRoundIdGet200Response, int, Dict[str, str]]
    """
    return 'do some magic!'


def games_gid_current_round_number_get(gid):  # noqa: E501
    """Holt die Nummer der aktuellen Runde.

     # noqa: E501

    :param gid: 
    :type gid: str

    :rtype: Union[GamesGidCurrentRoundNumberGet200Response, Tuple[GamesGidCurrentRoundNumberGet200Response, int], Tuple[GamesGidCurrentRoundNumberGet200Response, int, Dict[str, str]]
    """
    return 'do some magic!'


def games_gid_join_post(gid):  # noqa: E501
    """Lässt einen Spieler einem Spiel beitreten.

    Aktualisiert die Teilnehmerzahl des Spiels. # noqa: E501

    :param gid: 
    :type gid: str

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    return 'do some magic!'


def games_gid_next_player_uid_get(gid, playernumber):  # noqa: E501
    """Holt die UID des nächsten Spielers basierend auf der Spielernummer.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param playernumber: 
    :type playernumber: int

    :rtype: Union[GamesGidNextPlayerUidGet200Response, Tuple[GamesGidNextPlayerUidGet200Response, int], Tuple[GamesGidNextPlayerUidGet200Response, int, Dict[str, str]]
    """
    return 'do some magic!'


def games_gid_players_get(gid):  # noqa: E501
    """Lädt alle Spieler für ein Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str

    :rtype: Union[List[Spieler], Tuple[List[Spieler], int], Tuple[List[Spieler], int, Dict[str, str]]
    """
    return 'do some magic!'


def games_gid_players_post(gid, body):  # noqa: E501
    """Fügt einen Spieler zu einem Spiel hinzu.

    Speichert den Benutzer falls nötig und weist ihm eine Spielernummer zu. # noqa: E501

    :param gid: 
    :type gid: str
    :param add_player_request: 
    :type add_player_request: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    add_player_request = body
    if connexion.request.is_json:
        add_player_request = AddPlayerRequest.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def games_gid_rounds_post(gid, body):  # noqa: E501
    """Startet eine neue Runde in einem Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param start_new_round_request: 
    :type start_new_round_request: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    start_new_round_request = body
    if connexion.request.is_json:
        start_new_round_request = StartNewRoundRequest.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def games_gid_trumpf_suit_put(gid, body):  # noqa: E501
    """Aktualisiert die Trumpffarbe für ein Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param update_trumpf_request: 
    :type update_trumpf_request: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    update_trumpf_request = body
    if connexion.request.is_json:
        update_trumpf_request = UpdateTrumpfRequest.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def games_gid_update_scores_post(gid, body):  # noqa: E501
    """Speichert Punkte für Gewinner und Teamkollegen.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param save_points_request: 
    :type save_points_request: dict | bytes

    :rtype: Union[GamesGidUpdateScoresPost200Response, Tuple[GamesGidUpdateScoresPost200Response, int], Tuple[GamesGidUpdateScoresPost200Response, int, Dict[str, str]]
    """
    save_points_request = body
    if connexion.request.is_json:
        save_points_request = SavePointsRequest.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def games_gid_users_uid_card_count_get(gid, uid):  # noqa: E501
    """Holt die Anzahl der Karten eines Spielers.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param uid: 
    :type uid: str

    :rtype: Union[GamesGidUsersUidCardCountGet200Response, Tuple[GamesGidUsersUidCardCountGet200Response, int], Tuple[GamesGidUsersUidCardCountGet200Response, int, Dict[str, str]]
    """
    return 'do some magic!'


def games_gid_users_uid_cards_get(gid, uid):  # noqa: E501
    """Holt die Karten eines bestimmten Spielers in einem Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param uid: 
    :type uid: str

    :rtype: Union[List[Jasskarte], Tuple[List[Jasskarte], int], Tuple[List[Jasskarte], int, Dict[str, str]]
    """
    return 'do some magic!'


def games_gid_users_uid_player_number_get(gid, uid):  # noqa: E501
    """Holt die Spielernummer eines Benutzers in einem Spiel.

     # noqa: E501

    :param gid: 
    :type gid: str
    :param uid: 
    :type uid: str

    :rtype: Union[GamesGidUsersUidPlayerNumberGet200Response, Tuple[GamesGidUsersUidPlayerNumberGet200Response, int], Tuple[GamesGidUsersUidPlayerNumberGet200Response, int, Dict[str, str]]
    """
    return 'do some magic!'


def games_post():  # noqa: E501
    """Erstellt ein neues Spiel.

    Generiert einen einzigartigen Spielcode (GID) und initialisiert das Spiel. # noqa: E501


    :rtype: Union[GamesPost201Response, Tuple[GamesPost201Response, int], Tuple[GamesPost201Response, int, Dict[str, str]]
    """
    return 'do some magic!'
