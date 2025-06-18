## @file users_controller.py
# @brief Controller für Benutzer-Endpunkte
import connexion
from typing import Dict
from typing import Tuple
from typing import Union

from openapi_server.models.users_uid_put_request import UsersUidPutRequest  # noqa: E501
from openapi_server import util
from openapi_server.db import supabase
from openapi_server import util
from openapi_server.logger import logger

## @brief Aktualisiert oder erstellt einen Benutzer basierend auf der UID
# @param uid Die eindeutige ID des Benutzers
# @param body Der Request-Body, der die Benutzerdaten enthält
# @return Ein Dictionary mit einer Erfolgsmeldung und den Benutzerdaten + eine 200/201-Response, oder eine Fehlermeldung und 400/500-Response bei einem Fehler
def users_uid_put(uid, body):  # noqa: E501
    try:
        logger.info(f"users_uid_put called with uid={uid}")
        body_data = connexion.request.get_json()
        logger.debug(f"Request body data: {body_data}")
        name = body_data.get('name')

        if not name:
            logger.warning("Name ist im Request-Body erforderlich.")
            return {"message": "Name ist im Request-Body erforderlich."}, 400
        response = supabase.table('User').select('UID').eq('UID', uid).limit(1).execute()
        if hasattr(response, 'error') and response.error:
            logger.error(f"Supabase select error: {response.error.message}")
            return {"message": "Fehler beim Abrufen der Benutzerdaten."}, 500  
        existing_user_data = response.data
        if not existing_user_data:
            insert_response = supabase.table('User').insert({'UID': uid, 'name': name}).execute()
            if hasattr(insert_response, 'error') and insert_response.error:
                logger.error(f"Supabase insert error: {insert_response.error.message}")
                return {"message": "Fehler beim Erstellen des Benutzers."}, 500
            logger.info(f"Benutzer {uid} erfolgreich erstellt.")
            return {"message": "Benutzer erfolgreich erstellt.", "uid": uid, "name": name}, 201

        else:
            update_response = supabase.table('User').update({'name': name}).eq('UID', uid).execute()

            if hasattr(update_response, 'error') and update_response.error:
                logger.error(f"Supabase update error: {update_response.error.message}")
                return {"message": "Fehler beim Aktualisieren des Benutzers."}, 500
            logger.info(f"Benutzer {uid} erfolgreich aktualisiert.")
            return {"message": "Benutzer erfolgreich aktualisiert.", "uid": uid, "name": name}, 200

    except Exception as e:
        logger.exception(f"Ungeplanter Fehler in users_uid_put: {e}")
        return {"message": "Ein interner Serverfehler ist aufgetreten."}, 500