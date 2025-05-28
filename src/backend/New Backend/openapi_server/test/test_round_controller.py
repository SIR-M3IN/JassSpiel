import unittest

from flask import json

from openapi_server.models.play import Play  # noqa: E501
from openapi_server.models.round import Round  # noqa: E501
from openapi_server.test import BaseTestCase


class TestRoundController(BaseTestCase):
    """RoundController integration test stubs"""

    def test_rounds_post(self):
        """Test case for rounds_post

        Neue Runde erstellen
        """
        round = {"RID":"046b6c7f-0b8a-43b9-b35d-6489e6daee91","GID":"PDL96","winnerid":"046b6c7f-0b8a-43b9-b35d-6489e6daee91","whichround":1}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/rounds',
            method='POST',
            headers=headers,
            data=json.dumps(round),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))

    def test_rounds_rid_plays_get(self):
        """Test case for rounds_rid_plays_get

        Alle Spielzüge einer Runde abrufen
        """
        headers = { 
            'Accept': 'application/json',
        }
        response = self.client.open(
            '/rounds/{rid}/plays'.format(rid='rid_example'),
            method='GET',
            headers=headers)
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
