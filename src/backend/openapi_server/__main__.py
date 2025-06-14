#!/usr/bin/env python3

import connexion
from flask_cors import CORS

from openapi_server import encoder


def main():
    app = connexion.App(__name__, specification_dir='./openapi/')
    app.app.json_encoder = encoder.JSONEncoder
    CORS(app.app, resources={r"/*": {"origins": "*"}})    
    app.add_api('openapi.yaml',
                arguments={'title': 'JassSpiel API'},
                pythonic_params=True)

    app.run(port=8080, debug=True, use_reloader=True, use_evalex=True)


if __name__ == '__main__':
    main()
