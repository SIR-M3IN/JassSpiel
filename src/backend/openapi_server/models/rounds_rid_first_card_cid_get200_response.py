from datetime import date, datetime  # noqa: F401

from typing import List, Dict  # noqa: F401

from openapi_server.models.base_model import Model
from openapi_server import util


class RoundsRidFirstCardCidGet200Response(Model):
    """NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).

    Do not edit the class manually.
    """

    def __init__(self, cid=None):  # noqa: E501
        """RoundsRidFirstCardCidGet200Response - a model defined in OpenAPI

        :param cid: The cid of this RoundsRidFirstCardCidGet200Response.  # noqa: E501
        :type cid: str
        """
        self.openapi_types = {
            'cid': str
        }

        self.attribute_map = {
            'cid': 'cid'
        }

        self._cid = cid

    @classmethod
    def from_dict(cls, dikt) -> 'RoundsRidFirstCardCidGet200Response':
        """Returns the dict as a model

        :param dikt: A dict.
        :type: dict
        :return: The rounds_rid_first_card_cid_get_200_response of this RoundsRidFirstCardCidGet200Response.  # noqa: E501
        :rtype: RoundsRidFirstCardCidGet200Response
        """
        return util.deserialize_model(dikt, cls)

    @property
    def cid(self) -> str:
        """Gets the cid of this RoundsRidFirstCardCidGet200Response.


        :return: The cid of this RoundsRidFirstCardCidGet200Response.
        :rtype: str
        """
        return self._cid

    @cid.setter
    def cid(self, cid: str):
        """Sets the cid of this RoundsRidFirstCardCidGet200Response.


        :param cid: The cid of this RoundsRidFirstCardCidGet200Response.
        :type cid: str
        """

        self._cid = cid
