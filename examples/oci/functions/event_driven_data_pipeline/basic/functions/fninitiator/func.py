import io
import json
import logging
import os
from base64 import b64encode

import oci
from fdk import response


def setup_oci_client(client_type, signer, stream_endpoint):
    try:
        if DEBUG_MODE:
            logging.getLogger().info(f"Trying to get {client_type} Client using resource principals.")

        if client_type == "streaming":
            oci_client = oci.streaming.StreamClient(
                config={},
                signer=signer,
                service_endpoint=stream_endpoint,
            )
        else:
            raise ValueError(f"Invalid Client type {client_type}")

        if DEBUG_MODE:
            logging.getLogger().info(f"Got {client_type} Client ok")

        return oci_client

    except Exception as exc:
        logging.getLogger().info(f"Raised exception: {exc} attempting to initialize {client_type} Client")
        raise


def normalize_stream_records(body):
    base_device_id = body.get("device_id")
    device_data = body.get("device_data", {})

    if isinstance(device_data, list):
        records = []
        for index, item in enumerate(device_data, start=1):
            record_device_id = item.get("device_id", base_device_id)
            if record_device_id is None:
                raise ValueError(f"Missing device_id for record {index}.")

            records.append({
                "device_id": str(record_device_id),
                "payload": item,
            })
        return records

    if base_device_id is None:
        raise ValueError("device_id must be provided for single-record payloads.")

    return [{
        "device_id": str(base_device_id),
        "payload": device_data,
    }]


DEBUG_MODE = os.getenv("DEBUG_MODE") is not None

stream_ocid = os.getenv("STREAM_OCID")
stream_endpoint = os.getenv("STREAM_ENDPOINT")

if not stream_ocid or not stream_endpoint:
    logging.getLogger().error("Missing configuration key STREAM_OCID or STREAM_ENDPOINT")

if DEBUG_MODE:
    logging.getLogger().info("Getting signer using resource principals...")
signer = oci.auth.signers.get_resource_principals_signer()
if DEBUG_MODE:
    logging.getLogger().info("Got signer ok")

stream_client = setup_oci_client("streaming", signer, f"https://{stream_endpoint}")


def handler(ctx, data: io.BytesIO = None):
    if DEBUG_MODE:
        logging.getLogger().info("Starting fninitiator handler...")

    try:
        body = json.loads(data.getvalue())
        records = normalize_stream_records(body)

        if DEBUG_MODE:
            logging.getLogger().info(f"Preparing asynchronous processing for {len(records)} record(s).")

        stream_messages = oci.streaming.models.PutMessagesDetails()
        stream_messages.messages = []

        for record in records:
            stream_message_entry = oci.streaming.models.PutMessagesDetailsEntry()
            stream_message_entry.key = b64encode(record["device_id"].encode("utf-8")).decode("utf-8")
            stream_message_entry.value = b64encode(
                json.dumps(record["payload"]).encode("utf-8")
            ).decode("utf-8")
            stream_messages.messages.append(stream_message_entry)

        stream_client.put_messages(stream_ocid, stream_messages)

        if DEBUG_MODE:
            logging.getLogger().info(f"Sent {len(stream_messages.messages)} message(s) to stream.")

    except Exception as exc:
        logging.getLogger().error(f"Error pushing data to Stream: {exc}")
        logging.getLogger().info("Leaving handler w/errors")

        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "Connect to Stream and push the message",
                    "exception": str(exc),
                },
                indent=2,
            ),
            headers={"Content-Type": "application/json"},
        )

    return response.Response(
        ctx,
        response_data=json.dumps(
            {
                "status": 0,
                "fninitiator": "Finished",
                "record_count": len(records),
                "device_id": records[0]["device_id"] if records else None,
            },
            indent=2,
        ),
        headers={"Content-Type": "application/json"},
    )
