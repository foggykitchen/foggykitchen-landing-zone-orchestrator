import io
import json
import logging
import os
from base64 import b64decode
from zipfile import ZipFile

import oci
import oracledb
from fdk import response


def setup_oci_client(client_type, signer):
    try:
        if DEBUG_MODE:
            logging.getLogger().info(f"Trying to get {client_type} Client using resource principals.")

        if client_type == "adb":
            oci_client = oci.database.DatabaseClient(config={}, signer=signer)
        else:
            raise ValueError(f"Invalid Client type {client_type}")

        if DEBUG_MODE:
            logging.getLogger().info(f"Got {client_type} Client ok")

        return oci_client

    except Exception as exc:
        logging.getLogger().info(f"Raised exception: {exc} attempting to initialize {client_type} Client")
        raise


def read_and_log_file_content(file_path):
    try:
        with open(file_path, "r") as file:
            content = file.read()
        logging.getLogger().info(f"Content of {file_path}:\n{content}")
    except FileNotFoundError:
        logging.getLogger().error(f"The file {file_path} does not exist.")
    except IOError:
        logging.getLogger().error(f"An error occurred while reading the file {file_path}.")


def prepare_wallet(adb_client, adb_ocid, wallet_dir, wallet_content_b64=None):
    os.makedirs(wallet_dir, exist_ok=True)
    for file_name in os.listdir(wallet_dir):
        file_path = os.path.join(wallet_dir, file_name)
        if os.path.isfile(file_path):
            os.remove(file_path)

    wallet_zip_path = os.path.join(wallet_dir, "dbwallet.zip")

    if wallet_content_b64:
        if DEBUG_MODE:
            logging.getLogger().info("Using wallet content provided via function configuration.")
        with open(wallet_zip_path, "wb") as wallet_file:
            wallet_file.write(b64decode(wallet_content_b64))
    else:
        raise RuntimeError("Wallet content must be provided for lesson7.")

    if DEBUG_MODE:
        logging.getLogger().info(f"Unziping the wallet to directory {wallet_dir}")

    with ZipFile(wallet_zip_path, "r") as zip_object:
        zip_object.extractall(wallet_dir)

    tnsnames_file = os.path.join(wallet_dir, "tnsnames.ora")
    sqlnet_file = os.path.join(wallet_dir, "sqlnet.ora")

    if DEBUG_MODE:
        read_and_log_file_content(tnsnames_file)
        read_and_log_file_content(sqlnet_file)

    if not os.path.exists(tnsnames_file) or not os.path.exists(sqlnet_file):
        raise FileNotFoundError(f"ADB wallet files were not extracted correctly into {wallet_dir}.")


def normalize_messages(payload):
    if isinstance(payload, list):
        return payload

    if isinstance(payload, dict):
        if isinstance(payload.get("data"), list):
            return payload["data"]
        return [payload]

    raise ValueError("Unexpected SCH payload format.")


DEBUG_MODE = os.getenv("DEBUG_MODE") is not None
adb_ocid = os.getenv("ADB_OCID")
adb_app_user_name = os.getenv("ADB_APP_USER_NAME")
adb_app_user_password = os.getenv("ADB_APP_USER_PASSWORD")
adb_sqlnet_alias = os.getenv("ADB_SQLNET_ALIAS")
adb_wallet_content = os.getenv("ADB_WALLET_CONTENT") or """__ADB_WALLET_CONTENT__"""
adb_wallet_password = os.getenv("ADB_WALLET_PASSWORD") or "__ADB_WALLET_PASSWORD__"
adb_wallet_dir = "/tmp/adb_wallet"
adb_wallet_file = os.path.join(os.path.dirname(__file__), "adb_wallet.b64")

if not adb_ocid or not adb_app_user_name or not adb_app_user_password or not adb_sqlnet_alias:
    logging.getLogger().error("Missing database configuration keys")

if DEBUG_MODE:
    logging.getLogger().info("Getting signer using resource principals...")
signer = oci.auth.signers.get_resource_principals_signer()
if DEBUG_MODE:
    logging.getLogger().info("Got signer ok")

adb_client = setup_oci_client("adb", signer)

try:
    if DEBUG_MODE:
        logging.getLogger().info(f"Retrieving wallet from ADB: {adb_ocid}.")
    if not adb_wallet_content and os.path.exists(adb_wallet_file):
        with open(adb_wallet_file, "r") as wallet_file:
            adb_wallet_content = wallet_file.read().strip()
    prepare_wallet(adb_client, adb_ocid, adb_wallet_dir, adb_wallet_content)
    os.environ["TNS_ADMIN"] = adb_wallet_dir
    if DEBUG_MODE:
        logging.getLogger().info(f"DB wallet dir content = {os.listdir(adb_wallet_dir)}")
except Exception as wallet_exception:
    logging.getLogger().error(f"Error retrieving DB wallet from ADB: {wallet_exception}")

try:
    if DEBUG_MODE:
        logging.getLogger().info("Updating sqlnet.ora.")
    with open(os.path.join(adb_wallet_dir, "sqlnet.ora")) as sqlnet_ora_orig:
        new_text = sqlnet_ora_orig.read().replace(
            'DIRECTORY="?/network/admin"',
            f'DIRECTORY="{adb_wallet_dir}"',
        )
    with open(os.path.join(adb_wallet_dir, "sqlnet.ora"), "w") as sqlnet_ora_new:
        sqlnet_ora_new.write(new_text)
except Exception as sqlnet_exception:
    logging.getLogger().error(f"Error updating sqlnet.ora: {sqlnet_exception}")


def handler(ctx, data: io.BytesIO = None):
    if DEBUG_MODE:
        logging.getLogger().info("Starting fncollector handler...")

    try:
        messages = normalize_messages(json.loads(data.getvalue()))
        if DEBUG_MODE:
            logging.getLogger().info(f"SCH delivered {len(messages)} message(s) to fncollector.")
    except Exception as exc:
        logging.getLogger().error(f"Error parsing SCH payload: {exc}")
        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "Parse SCH payload",
                    "exception": str(exc),
                },
                indent=2,
            ),
            headers={"Content-Type": "application/json"},
        )

    try:
        if DEBUG_MODE:
            logging.getLogger().info("Using python-oracledb thin mode with Autonomous Database wallet.")
        adb_connection = oracledb.connect(
            user=adb_app_user_name,
            password=adb_app_user_password,
            dsn=adb_sqlnet_alias,
            config_dir=adb_wallet_dir,
            wallet_location=adb_wallet_dir,
            wallet_password=adb_wallet_password,
        )
        if DEBUG_MODE:
            logging.getLogger().info(f"DB connection acquired for APPUSER User (dsn={adb_sqlnet_alias}).")
    except Exception as exc:
        logging.getLogger().error(f"Error getting DB connection for APPUSER User (dsn={adb_sqlnet_alias}): {exc}.")
        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "DB Connection for APPUSER",
                    "exception": str(exc),
                },
                indent=2,
            ),
            headers={"Content-Type": "application/json"},
        )

    try:
        adb_cursor = adb_connection.cursor()
        if DEBUG_MODE:
            logging.getLogger().info("DB cursor created for APPUSER.")
    except Exception as exc:
        logging.getLogger().error(f"Error creating DB cursor for APPUSER: {exc}")
        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "DB cursor creation for APPUSER",
                    "exception": str(exc),
                },
                indent=2,
            ),
            headers={"Content-Type": "application/json"},
        )

    inserted_count = 0

    try:
        for message in messages:
            cursor_result = adb_cursor.execute("select iot_data_seq.nextval from dual")
            row = cursor_result.fetchone()
            new_id = row[0]
            new_device = str(b64decode(message.get("key")).decode("utf-8"))
            new_device_data = json.loads(b64decode(message.get("value")).decode("utf-8"))
            new_temperature = new_device_data.get("temperature")
            new_humidity = new_device_data.get("humidity")
            adb_cursor.execute(
                "insert into iot_data values (:id, :device_id, :temperature, :humidity, SYSDATE)",
                {
                    "id": new_id,
                    "device_id": new_device,
                    "temperature": new_temperature,
                    "humidity": new_humidity,
                },
            )
            inserted_count += 1
            if DEBUG_MODE:
                logging.getLogger().info(
                    "IOT_DATA table inserted: "
                    f"id={new_id}, device_id={new_device}, temperature={new_temperature}, humidity={new_humidity}."
                )

        adb_connection.commit()

    except Exception as exc:
        logging.getLogger().error(f"Error inserting data into IOT_DATA table: {exc}")
        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "Update iot_data table with SCH-delivered stream payload",
                    "exception": str(exc),
                },
                indent=2,
            ),
            headers={"Content-Type": "application/json"},
        )
    finally:
        try:
            adb_cursor.close()
        except Exception:
            pass
        try:
            adb_connection.close()
        except Exception:
            pass

    return response.Response(
        ctx,
        response_data=json.dumps(
            {
                "status": 0,
                "fncollector": "Finished",
                "record_count": inserted_count,
            },
            indent=2,
        ),
        headers={"Content-Type": "application/json"},
    )
