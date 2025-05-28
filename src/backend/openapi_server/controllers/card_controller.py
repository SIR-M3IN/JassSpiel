import connexion
from typing import Dict
from typing import Tuple
from typing import Union

from openapi_server.models.card import Card  # noqa: E501
from openapi_server.models.card_in_games import CardInGames  # noqa: E501
from openapi_server import util


def cards_get():  # noqa: E501
    """Alle Karten abrufen

     # noqa: E501


    :rtype: Union[List[Card], Tuple[List[Card], int], Tuple[List[Card], int, Dict[str, str]]
    """
    
    return 'do some magic!'


def cardsingame_post(body):  # noqa: E501
    """Karte einem Benutzer in einem Spiel zuweisen

     # noqa: E501

    :param card_in_games: 
    :type card_in_games: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    card_in_games = body
    if connexion.request.is_json:
        card_in_games = CardInGames.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'
