import connexion
from typing import Dict
from typing import Tuple
from typing import Union

from openapi_server.models.play import Play  # noqa: E501
from openapi_server.models.round import Round  # noqa: E501
from openapi_server import util


def rounds_post(body):  # noqa: E501
    """Neue Runde erstellen

     # noqa: E501

    :param round: 
    :type round: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    round = body
    if connexion.request.is_json:
        round = Round.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'


def rounds_rid_plays_get(rid):  # noqa: E501
    """Alle Spielzüge einer Runde abrufen

     # noqa: E501

    :param rid: 
    :type rid: str
    :type rid: str

    :rtype: Union[List[Play], Tuple[List[Play], int], Tuple[List[Play], int, Dict[str, str]]
    """
    return 'do some magic!'
