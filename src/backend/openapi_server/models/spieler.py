from datetime import date, datetime  # noqa: F401

from typing import List, Dict  # noqa: F401

from openapi_server.models.base_model import Model
from openapi_server import util


class Spieler(Model):
    """NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).

    Do not edit the class manually.
    """

    def __init__(self, uid=None, name=None, playernumber=None):  # noqa: E501
        """Spieler - a model defined in OpenAPI

        :param uid: The uid of this Spieler.  # noqa: E501
        :type uid: str
        :param name: The name of this Spieler.  # noqa: E501
        :type name: str
        :param playernumber: The playernumber of this Spieler.  # noqa: E501
        :type playernumber: int
        """
        self.openapi_types = {
            'uid': str,
            'name': str,
            'playernumber': int
        }

        self.attribute_map = {
            'uid': 'uid',
            'name': 'name',
            'playernumber': 'playernumber'
        }

        self._uid = uid
        self._name = name
        self._playernumber = playernumber

    @classmethod
    def from_dict(cls, dikt) -> 'Spieler':
        """Returns the dict as a model

        :param dikt: A dict.
        :type: dict
        :return: The Spieler of this Spieler.  # noqa: E501
        :rtype: Spieler
        """
        return util.deserialize_model(dikt, cls)

    @property
    def uid(self) -> str:
        """Gets the uid of this Spieler.

        Eindeutige ID des Spielers.  # noqa: E501

        :return: The uid of this Spieler.
        :rtype: str
        """
        return self._uid

    @uid.setter
    def uid(self, uid: str):
        """Sets the uid of this Spieler.

        Eindeutige ID des Spielers.  # noqa: E501

        :param uid: The uid of this Spieler.
        :type uid: str
        """

        self._uid = uid

    @property
    def name(self) -> str:
        """Gets the name of this Spieler.

        Name des Spielers.  # noqa: E501

        :return: The name of this Spieler.
        :rtype: str
        """
        return self._name

    @name.setter
    def name(self, name: str):
        """Sets the name of this Spieler.

        Name des Spielers.  # noqa: E501

        :param name: The name of this Spieler.
        :type name: str
        """

        self._name = name

    @property
    def playernumber(self) -> int:
        """Gets the playernumber of this Spieler.

        Spielernummer im aktuellen Spiel.  # noqa: E501

        :return: The playernumber of this Spieler.
        :rtype: int
        """
        return self._playernumber

    @playernumber.setter
    def playernumber(self, playernumber: int):
        """Sets the playernumber of this Spieler.

        Spielernummer im aktuellen Spiel.  # noqa: E501

        :param playernumber: The playernumber of this Spieler.
        :type playernumber: int
        """

        self._playernumber = playernumber
