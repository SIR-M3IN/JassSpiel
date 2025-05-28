import connexion
from typing import Dict
from typing import Tuple
from typing import Union
from openapi_server.db import supabase 
from openapi_server.models.game import Game  # noqa: E501
from openapi_server import util


def games_get():  # noqa: E501
    """Alle Spiele abrufen

     # noqa: E501


    :rtype: Union[List[Game], Tuple[List[Game], int], Tuple[List[Game], int, Dict[str, str]]
    """  
    try:
        response = supabase.table("games").select("GID, status, room_name, participants").execute()
        games_data = response.data or []
        games = [Game.from_dict(g) for g in games_data]
        return games, 200
    except Exception as e:
        print(f"Fehler beim Abrufen der Spiele: {e}")
        return [], 500



def games_gid_get(gid):  # noqa: E501
    """Spiel anhand GID abrufen

     # noqa: E501

    :param gid: 
    :type gid: str

    :rtype: Union[Game, Tuple[Game, int], Tuple[Game, int, Dict[str, str]]
    """
    try:
        response = supabase.table("games").select("GID, status, room_name, participants").eq("GID",gid).execute()
        games_data = response.data or []
        games = [Game.from_dict(g) for g in games_data]
        return games, 200
    except Exception as e:
        print(f"Fehler beim Abrufen der Spiele: {e}")
        return [], 500


def games_post(body) -> Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]]:
    """Neues Spiel erstellen

    :param body: Spiel-Daten als JSON
    :type body: dict | bytes
    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]]
    """
    if connexion.request.is_json:
        game = Game.from_dict(connexion.request.get_json())
        print(game)
        game_data = {
            "GID": game.gid,
            "status": game.status,
            "room_name": game.room_name,
            "participants": game.participants
        }
        try:
            response = supabase.table("games").insert(game_data).execute()
            if response.data:
                return None, 201  # Created
            else:
                return None, 500, {"error": "Insertion failed"}
        except Exception as e:
            print("Error")
            return None, 500, {"error": str(e)}
    
    return None, 400, {"error": "Invalid JSON"}
def update_game(gid, body):
    participants = body.get("participants")
    if participants is None:
        return {"message": "Keine gültigen Felder zum Aktualisieren angegeben."}, 400

    result = (
        supabase.table("games")
        .update({"participants": participants})
        .eq("GID", gid)
        .execute()
    )
    result.get("data", [])
    # if result.error:
    #     return {"message": f"Fehler beim Aktualisieren: {result.error}"}, 500

    # if not result.data:
    #     return {"message": "Spiel nicht gefunden."}, 404

    return {"message": "Spiel erfolgreich aktualisiert."}, 200    
