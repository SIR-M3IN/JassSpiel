import connexion
from typing import Dict
from typing import Tuple
from typing import Union
from db import supabase
from openapi_server.models.card import Card  # noqa: E501
from openapi_server.models.card_in_game import CardInGame  # noqa: E501
from openapi_server import util


def cardingame_post(body):  # noqa: E501
    """Karte einem Benutzer in einem Spiel zuweisen

     # noqa: E501

    :param body: 
    :type body: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    if not connexion.request.is_json:
        return None, 400, {"error": "Invalid JSON"}

    try:
        data = connexion.request.get_json()
        print(data)

        response = supabase.table("cardingames").insert(data).execute()

        if response.data:
            return None, 201  # Created
        else:
            return None, 500, {"error": "Insertion failed"}

    except Exception as e:
        print(f"Fehler beim Einfügen der Karte: {e}")
        return None, 500, {"error": str(e)}
def cards_get():  # noqa: E501
    """Alle Karten abrufen

     # noqa: E501


    :rtype: Union[List[Card], Tuple[List[Card], int], Tuple[List[Card], int, Dict[str, str]]
    """
    try:
        response = supabase.table("card").select("CID, symbol, cardtype").execute()
        cards_data = response.data or []
        cards = [Card.from_dict(c) for c in cards_data]
        return cards, 200
    except Exception as e:
        print(f"Fehler beim Abrufen der Karten: {e}")
        return [], 500