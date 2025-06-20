from datetime import date, datetime  # noqa: F401

from typing import List, Dict  # noqa: F401

from openapi_server.models.base_model import Model
from openapi_server import util


class WinningCardResponse(Model):
    """NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).

    Do not edit the class manually.
    """

    def __init__(self, winner_uid=None):  # noqa: E501
        """WinningCardResponse - a model defined in OpenAPI

        :param winner_uid: The winner_uid of this WinningCardResponse.  # noqa: E501
        :type winner_uid: str
        """
        self.openapi_types = {
            'winner_uid': str
        }

        self.attribute_map = {
            'winner_uid': 'winnerUid'
        }

        self._winner_uid = winner_uid

    @classmethod
    def from_dict(cls, dikt) -> 'WinningCardResponse':
        """Returns the dict as a model

        :param dikt: A dict.
        :type: dict
        :return: The WinningCardResponse of this WinningCardResponse.  # noqa: E501
        :rtype: WinningCardResponse
        """
        return util.deserialize_model(dikt, cls)

    @property
    def winner_uid(self) -> str:
        """Gets the winner_uid of this WinningCardResponse.


        :return: The winner_uid of this WinningCardResponse.
        :rtype: str
        """
        return self._winner_uid

    @winner_uid.setter
    def winner_uid(self, winner_uid: str):
        """Sets the winner_uid of this WinningCardResponse.


        :param winner_uid: The winner_uid of this WinningCardResponse.
        :type winner_uid: str
        """

        self._winner_uid = winner_uid
