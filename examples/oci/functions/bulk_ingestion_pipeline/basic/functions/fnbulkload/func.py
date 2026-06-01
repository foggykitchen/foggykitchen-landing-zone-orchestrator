import io
import json
import logging
import os
from base64 import b64encode
from urllib.parse import unquote

import oci
from fdk import response


def setup_oci_client(client_type, signer, stream_endpoint=""):
    if DEBUG_MODE:
        logging.getLogger().info(f"Trying to get {client_type} client using resource principals.")

    if client_type == "streaming":
        return oci.streaming.StreamClient(config={}, signer=signer, service_endpoint=stream_endpoint)
    if client_type == "oss":
        return oci.object_storage.ObjectStorageClient(config={}, signer=signer)

    raise ValueError(f"Invalid client type {client_type}")


def parse_event_payload(data):
    payload = json.loads(data.getvalue())
    bucket_name = payload["data"]["additionalDetails"]["bucketName"]
    object_name = unquote(payload["data"]["resourceName"])
    return bucket_name, object_name


DEBUG_MODE = os.getenv("DEBUG_MODE") is not None
stream_ocid = os.getenv("STREAM_OCID")
stream_endpoint = os.getenv("STREAM_ENDPOINT")

if not stream_ocid or not stream_endpoint:
    raise RuntimeError("Missing configuration key STREAM_OCID or STREAM_ENDPOINT")

if DEBUG_MODE:
    logging.getLogger().info("Getting signer using resource principals...")
signer = oci.auth.signers.get_resource_principals_signer()
if DEBUG_MODE:
    logging.getLogger().info("Got signer ok")

stream_client = setup_oci_client("streaming", signer, f"https://{stream_endpoint}")
object_storage_client = setup_oci_client("oss", signer)


def handler(ctx, data: io.BytesIO = None):
    if DEBUG_MODE:
        logging.getLogger().info("Starting fnbulkload handler...")

    try:
        bucket_name, object_name = parse_event_payload(data)
        namespace = object_storage_client.get_namespace().data
        object_response = object_storage_client.get_object(namespace, bucket_name, object_name)
        object_content = json.loads(object_response.data.content.decode("utf-8"))
        if DEBUG_MODE:
            logging.getLogger().info(f"Downloaded object {object_name} from bucket {bucket_name}.")
    except Exception as exc:
        logging.getLogger().error(f"Error retrieving the object payload: {exc}")
        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "Read object from Object Storage",
                    "exception": str(exc),
                },
                indent=2,
            ),
            headers={"Content-Type": "application/json"},
        )

    published_count = 0

    try:
        for device in object_content:
            device_id = str(device.get("device_id"))
            device_data = json.dumps(device.get("device_data", {}))

            stream_message_entry = oci.streaming.models.PutMessagesDetailsEntry(
                key=b64encode(device_id.encode("utf-8")).decode("utf-8"),
                value=b64encode(device_data.encode("utf-8")).decode("utf-8"),
            )
            stream_messages = oci.streaming.models.PutMessagesDetails(messages=[stream_message_entry])
            stream_client.put_messages(stream_ocid, stream_messages)
            published_count += 1

            if DEBUG_MODE:
                logging.getLogger().info(f"Published record for device_id={device_id} to Streaming.")
    except Exception as exc:
        logging.getLogger().error(f"Error pushing data to Streaming: {exc}")
        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "Publish object records to Streaming",
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
                "fnbulkload": "Finished",
                "bucket_name": bucket_name,
                "object_name": object_name,
                "record_count": published_count,
            },
            indent=2,
        ),
        headers={"Content-Type": "application/json"},
    )
