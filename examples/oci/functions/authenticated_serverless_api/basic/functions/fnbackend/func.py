import io
import json

from fdk import response


def handler(ctx, data: io.BytesIO = None):
    payload = {}

    try:
        if data is not None:
            body = data.getvalue()
            if body:
                payload = json.loads(body)
    except Exception:
        payload = {}

    return response.Response(
        ctx,
        response_data=json.dumps(
            {
                "status": 0,
                "fnbackend": "Finished",
                "message": "Authenticated request accepted",
                "input": payload,
            }
        ),
        headers={"Content-Type": "application/json"},
    )
