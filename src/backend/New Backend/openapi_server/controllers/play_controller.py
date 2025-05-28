import connexion
from typing import Dict
from typing import Tuple
from typing import Union

from openapi_server.models.play import Play  # noqa: E501
from openapi_server import util


def plays_post(body):  # noqa: E501
    """Spielzug erfassen

     # noqa: E501

    :param play: 
    :type play: dict | bytes

    :rtype: Union[None, Tuple[None, int], Tuple[None, int, Dict[str, str]]
    """
    play = body
    if connexion.request.is_json:
        play = Play.from_dict(connexion.request.get_json())  # noqa: E501
    return 'do some magic!'
