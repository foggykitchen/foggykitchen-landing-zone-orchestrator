import datetime
import io
import json
import logging
import os

from datetime import timedelta
from fdk import response


def handler(ctx, data: io.BytesIO = None):
    request_payload = {}
    token = None
    configured_token = os.environ.get("FN_JWT_TOKEN", "")
    expires_at = (
        datetime.datetime.utcnow() + timedelta(seconds=60)
    ).replace(tzinfo=datetime.timezone.utc).astimezone().replace(microsecond=0).isoformat()

    try:
        if data is not None:
          body = data.getvalue()
          if body:
              request_payload = json.loads(body)
        token = request_payload.get("token")
    except Exception as exc:
        logging.getLogger().info("error parsing auth payload: %s", exc)

    if token and configured_token and token == configured_token:
        return response.Response(
            ctx,
            status_code=200,
            response_data=json.dumps(
                {
                    "active": True,
                    "principal": "foggykitchen-user",
                    "scope": "serverless-api",
                    "clientId": "foggykitchen-client",
                    "expiresAt": expires_at,
                    "context": {"username": "foggykitchen-user"},
                }
            ),
        )

    return response.Response(
        ctx,
        status_code=401,
        response_data=json.dumps({"active": False, "wwwAuthenticate": "API-key"}),
    )
