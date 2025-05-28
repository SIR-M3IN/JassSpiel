import unittest

from flask import json

from openapi_server.models.play import Play  # noqa: E501
from openapi_server.test import BaseTestCase


class TestPlayController(BaseTestCase):
    """PlayController integration test stubs"""

    def test_plays_post(self):
        """Test case for plays_post

        Spielzug erfassen
        """
        play = {"UID":"046b6c7f-0b8a-43b9-b35d-6489e6daee91","PID":"046b6c7f-0b8a-43b9-b35d-6489e6daee91","RID":"046b6c7f-0b8a-43b9-b35d-6489e6daee91","CardPlayed":"046b6c7f-0b8a-43b9-b35d-6489e6daee91"}
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/plays',
            method='POST',
            headers=headers,
            data=json.dumps(play),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
