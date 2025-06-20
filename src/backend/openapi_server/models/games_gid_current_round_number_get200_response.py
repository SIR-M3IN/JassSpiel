from datetime import date, datetime  # noqa: F401

from typing import List, Dict  # noqa: F401

from openapi_server.models.base_model import Model
from openapi_server import util


class GamesGidCurrentRoundNumberGet200Response(Model):
    """NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).

    Do not edit the class manually.
    """

    def __init__(self, whichround=None):  # noqa: E501
        """GamesGidCurrentRoundNumberGet200Response - a model defined in OpenAPI

        :param whichround: The whichround of this GamesGidCurrentRoundNumberGet200Response.  # noqa: E501
        :type whichround: int
        """
        self.openapi_types = {
            'whichround': int
        }

        self.attribute_map = {
            'whichround': 'whichround'
        }

        self._whichround = whichround

    @classmethod
    def from_dict(cls, dikt) -> 'GamesGidCurrentRoundNumberGet200Response':
        """Returns the dict as a model

        :param dikt: A dict.
        :type: dict
        :return: The games_gid_current_round_number_get_200_response of this GamesGidCurrentRoundNumberGet200Response.  # noqa: E501
        :rtype: GamesGidCurrentRoundNumberGet200Response
        """
        return util.deserialize_model(dikt, cls)

    @property
    def whichround(self) -> int:
        """Gets the whichround of this GamesGidCurrentRoundNumberGet200Response.


        :return: The whichround of this GamesGidCurrentRoundNumberGet200Response.
        :rtype: int
        """
        return self._whichround

    @whichround.setter
    def whichround(self, whichround: int):
        """Sets the whichround of this GamesGidCurrentRoundNumberGet200Response.


        :param whichround: The whichround of this GamesGidCurrentRoundNumberGet200Response.
        :type whichround: int
        """

        self._whichround = whichround
