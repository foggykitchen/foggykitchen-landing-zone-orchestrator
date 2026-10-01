import json
import logging
import os
import uuid

import azure.functions as func
from azure.eventhub import EventData, EventHubProducerClient
from azure.identity import DefaultAzureCredential
import psycopg

app = func.FunctionApp()


def _credential() -> DefaultAzureCredential:
    client_id = os.getenv("AZURE_CLIENT_ID")
    return DefaultAzureCredential(managed_identity_client_id=client_id) if client_id else DefaultAzureCredential()


def _publish(records: list[dict], source: str) -> None:
    namespace = os.environ["EVENTHUB_CONNECTION__fullyQualifiedNamespace"]
    eventhub_name = os.environ["EVENTHUB_NAME"]
    credential = _credential()

    producer = EventHubProducerClient(
        fully_qualified_namespace=namespace,
        eventhub_name=eventhub_name,
        credential=credential,
    )

    with producer:
        batch = producer.create_batch()
        for record in records:
            payload = {
                "id": str(uuid.uuid4()),
                "source": source,
                "record": record,
            }
            batch.add(EventData(json.dumps(payload)))
        producer.send_batch(batch)


def _normalize_payload(payload: object) -> list[dict]:
    if isinstance(payload, list):
        return [item if isinstance(item, dict) else {"value": item} for item in payload]
    if isinstance(payload, dict):
        return [payload]
    return [{"value": payload}]


def _postgres_conninfo() -> str:
    return (
        f"host={os.environ['POSTGRES_HOST']} "
        f"port={os.environ.get('POSTGRES_PORT', '5432')} "
        f"dbname={os.environ['POSTGRES_DATABASE']} "
        f"user={os.environ['POSTGRES_USER']} "
        f"password={os.environ['POSTGRES_PASSWORD']} "
        f"sslmode={os.environ.get('POSTGRES_SSLMODE', 'require')}"
    )


@app.route(route="fninitiator", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
def fninitiator(req: func.HttpRequest) -> func.HttpResponse:
    try:
        payload = req.get_json()
        records = _normalize_payload(payload)
        _publish(records, "api")
        return func.HttpResponse(json.dumps({"accepted": len(records)}), mimetype="application/json", status_code=202)
    except Exception as exc:
        logging.exception("fninitiator failed")
        return func.HttpResponse(json.dumps({"error": str(exc)}), mimetype="application/json", status_code=500)


@app.event_hub_message_trigger(
    arg_name="event",
    event_hub_name="%EVENTHUB_NAME%",
    connection="EVENTHUB_CONNECTION",
)
def fncollector(event: func.EventHubEvent) -> None:
    payload = json.loads(event.get_body().decode("utf-8"))
    record = payload.get("record", {})

    with psycopg.connect(_postgres_conninfo()) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                create table if not exists iot_data (
                  id text primary key,
                  source text not null,
                  payload jsonb not null,
                  created_at timestamptz not null default now()
                )
                """
            )
            cur.execute(
                "insert into iot_data (id, source, payload) values (%s, %s, %s::jsonb) on conflict (id) do nothing",
                (payload["id"], payload.get("source", "unknown"), json.dumps(record)),
            )
        conn.commit()
    logging.info(
        "fncollector stored event_id=%s source=%s validation_id=%s",
        payload["id"],
        payload.get("source", "unknown"),
        record.get("validation_id", ""),
    )


@app.route(route="fnvalidator", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
def fnvalidator(req: func.HttpRequest) -> func.HttpResponse:
    validation_id = req.params.get("validation_id")
    if not validation_id:
        return func.HttpResponse(
            json.dumps({"error": "validation_id query parameter is required"}),
            mimetype="application/json",
            status_code=400,
        )

    try:
        with psycopg.connect(_postgres_conninfo()) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    select
                      count(*)::int,
                      max(source),
                      max(payload->>'device'),
                      max(payload->>'validation_id'),
                      max(created_at)::text
                    from iot_data
                    where payload->>'validation_id' = %s
                    """,
                    (validation_id,),
                )
                count, source, device, matched_validation_id, last_created_at = cur.fetchone()

        return func.HttpResponse(
            json.dumps(
                {
                    "validation_id": validation_id,
                    "count": count,
                    "source": source,
                    "device": device,
                    "matched_validation_id": matched_validation_id,
                    "last_created_at": last_created_at,
                }
            ),
            mimetype="application/json",
            status_code=200,
        )
    except Exception as exc:
        logging.exception("fnvalidator failed")
        return func.HttpResponse(json.dumps({"error": str(exc)}), mimetype="application/json", status_code=500)
