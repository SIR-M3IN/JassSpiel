import connexion
from typing import Dict
from typing import Tuple
from typing import Union

from openapi_server.models.user import User  # noqa: E501
from openapi_server.models.user_create import UserCreate  # noqa: E501
from openapi_server.models.user_game import UserGame  # noqa: E501
from openapi_server import util


def usergame_post(body):  # noqa: E501
    """Benutzer einem Spiel zuordnen

     # noqa: E501

    :param user_game: 
    :type user_game: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    user_game = body
    if connexion.request.is_json:
        user_game = UserGame.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def users_get():  # noqa: E501
    """Alle Benutzer abrufen

     # noqa: E501


    :rtype: Union[List[User], Tuple[List[User], int], Tuple[List[User], int, Dict[str, str]]
    """
    return 'do some magic!'


def users_post(body):  # noqa: E501
    """Neuen Benutzer erstellen

     # noqa: E501

    :param user_create: 
    :type user_create: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    user_create = body
    if connexion.request.is_json:
        user_create = UserCreate.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def users_uid_get(uid):  # noqa: E501
    """Benutzer anhand UID abrufen

     # noqa: E501

    :param uid: 
    :type uid: str
    :type uid: str

    :rtype: Union[User, Tuple[User, int], Tuple[User, int, Dict[str, str]]
    """
    return 'do some magic!'
