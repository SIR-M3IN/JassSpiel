import unittest

from flask import json

from openapi_server.models.users_uid_put_request import UsersUidPutRequest  # noqa: E501
from openapi_server.test import BaseTestCase


class TestUsersController(BaseTestCase):
    """UsersController integration test stubs"""

    def test_users_uid_put(self):
        """Test case for users_uid_put

        Erstellt einen Benutzer.
        """
        users_uid_put_request = openapi_server.UsersUidPutRequest()
        headers = { 
            'Content-Type': 'application/json',
        }
        response = self.client.open(
            '/api/users/{uid}'.format(uid='uid_example'),
            method='PUT',
            headers=headers,
            data=json.dumps(users_uid_put_request),
            content_type='application/json')
        self.assert200(response,
                       'Response body is : ' + response.data.decode('utf-8'))


if __name__ == '__main__':
    unittest.main()
