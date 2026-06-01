import io
import json
import logging
import os
import secrets
import string
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


def valid_pw(password):
    return any(character.isdigit() for character in password)


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
        if DEBUG_MODE:
            logging.getLogger().info(f"Trying to get wallet for ADB: {adb_ocid}")

        adb_wallet_pwd = ""
        while not valid_pw(adb_wallet_pwd):
            adb_wallet_pwd = "".join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(15))

        adb_wallet_details = oci.database.models.GenerateAutonomousDatabaseWalletDetails(password=adb_wallet_pwd)
        wallet_data = adb_client.generate_autonomous_database_wallet(adb_ocid, adb_wallet_details)

        with open(wallet_zip_path, "w+b") as wallet_file:
            for chunk in wallet_data.data.raw.stream(1024 * 1024, decode_content=False):
                wallet_file.write(chunk)

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


DEBUG_MODE = os.getenv("DEBUG_MODE") is not None
adb_ocid = os.getenv("ADB_OCID")
adb_admin_user = "ADMIN"
adb_admin_password = os.getenv("ADB_ADMIN_PASSWORD")
adb_app_user_name = os.getenv("ADB_APP_USER_NAME")
adb_app_user_password = os.getenv("ADB_APP_USER_PASSWORD")
adb_sqlnet_alias = os.getenv("ADB_SQLNET_ALIAS")
adb_wallet_content = os.getenv("ADB_WALLET_CONTENT") or """__ADB_WALLET_CONTENT__"""
adb_wallet_password = os.getenv("ADB_WALLET_PASSWORD") or "__ADB_WALLET_PASSWORD__"
adb_wallet_dir = "/tmp/adb_wallet"
adb_wallet_file = os.path.join(os.path.dirname(__file__), "adb_wallet.b64")

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
        logging.getLogger().info("Using python-oracledb thin mode with Autonomous Database wallet.")

    try:
        adb_connection = oracledb.connect(
            user=adb_admin_user,
            password=adb_admin_password,
            dsn=adb_sqlnet_alias,
            config_dir=adb_wallet_dir,
            wallet_location=adb_wallet_dir,
            wallet_password=adb_wallet_password,
        )
        if DEBUG_MODE:
            logging.getLogger().info(f"DB connection acquired for ADMIN User (dsn={adb_sqlnet_alias}).")
    except Exception as exc:
        logging.getLogger().error(f"Error getting DB connection for ADMIN User (dsn={adb_sqlnet_alias}): {exc}.")
        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "DB Connection for ADMIN User",
                    "exception": str(exc),
                },
                indent=2,
            ),
            headers={"Content-Type": "application/json"},
        )

    try:
        adb_cursor = adb_connection.cursor()
    except Exception as exc:
        logging.getLogger().error(f"Error creating DB cursor for ADMIN User: {exc}")
        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "DB cursor creation for ADMIN User",
                    "exception": str(exc),
                },
                indent=2,
            ),
            headers={"Content-Type": "application/json"},
        )

    admin_steps = [
        f"create user {adb_app_user_name} identified by {adb_app_user_password}",
        f"grant create session to {adb_app_user_name}",
        f"grant create table to {adb_app_user_name}",
        f"grant create sequence to {adb_app_user_name}",
        f"grant unlimited tablespace to {adb_app_user_name}",
    ]

    try:
        for statement in admin_steps:
            adb_cursor.execute(statement)
        adb_connection.close()
    except Exception as exc:
        logging.getLogger().error(f"Error during APPUSER bootstrap: {exc}")
        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "App user bootstrap",
                    "exception": str(exc),
                },
                indent=2,
            ),
            headers={"Content-Type": "application/json"},
        )

    try:
        adb_connection = oracledb.connect(
            user=adb_app_user_name,
            password=adb_app_user_password,
            dsn=adb_sqlnet_alias,
            config_dir=adb_wallet_dir,
            wallet_location=adb_wallet_dir,
            wallet_password=adb_wallet_password,
        )
        adb_cursor = adb_connection.cursor()
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
        adb_cursor.execute(
            "CREATE TABLE iot_data(id NUMBER, device_id VARCHAR2(1000), temperature NUMBER(5, 2), humidity NUMBER(5, 2), time_stamp TIMESTAMP, CONSTRAINT iot_data_pk PRIMARY KEY (id))"
        )
        adb_cursor.execute(
            "insert into iot_data values (:id, :device_id, :temperature, :humidity, TO_TIMESTAMP(:time_stamp, 'YYYY-MM-DD HH24:MI:SS'))",
            {"id": 1, "device_id": "device1", "temperature": 89.1, "humidity": 2.2, "time_stamp": "2024-06-11 10:00:00"},
        )
        adb_cursor.execute(
            "insert into iot_data values (:id, :device_id, :temperature, :humidity, TO_TIMESTAMP(:time_stamp, 'YYYY-MM-DD HH24:MI:SS'))",
            {"id": 2, "device_id": "device2", "temperature": 54.2, "humidity": 10.5, "time_stamp": "2024-06-11 10:01:00"},
        )
        adb_cursor.execute(
            "insert into iot_data values (:id, :device_id, :temperature, :humidity, TO_TIMESTAMP(:time_stamp, 'YYYY-MM-DD HH24:MI:SS'))",
            {"id": 3, "device_id": "device3", "temperature": 12.5, "humidity": 11.7, "time_stamp": "2024-06-11 10:02:00"},
        )
        adb_cursor.execute("create sequence iot_data_seq start with 4 increment by 1 nocache nocycle")
        adb_cursor.execute("select iot_data_seq.nextval from dual")
        adb_connection.commit()
    except Exception as exc:
        logging.getLogger().error(f"Error preparing APPUSER objects: {exc}")
        return response.Response(
            ctx,
            response_data=json.dumps(
                {
                    "status": 1,
                    "step": "Prepare APPUSER schema objects",
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
                "fnadbsetup": "Finished",
            },
            indent=2,
        ),
        headers={"Content-Type": "application/json"},
    )
