import json
import os
import uuid
from datetime import datetime, timezone

REGION = os.environ.get("AWS_REGION", "eu-central-1")
INCIDENT_LOG = os.environ.get("INCIDENT_LOG", "/var/log/soar/incidents.jsonl")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")
SECRET_ID = os.environ.get("SECRET_ID", "")


def _now():
    return datetime.now(timezone.utc).isoformat()


def _aws_cfg():
    # Fail fast instead of hanging the listener if an endpoint is unreachable
    from botocore.config import Config
    return Config(connect_timeout=5, read_timeout=5, retries={"max_attempts": 1})


def log_incident(event, rule):
    """Action 1: append one JSON line to the incident file."""
    os.makedirs(os.path.dirname(INCIDENT_LOG), exist_ok=True)
    with open(INCIDENT_LOG, "a") as f:
        f.write(json.dumps({"logged_at": _now(), "rule": rule, "event": event}) + "\n")
    return True


def notify(event, rule):
    """Action 2: publish the incident to the SNS topic (email)."""
    if not SNS_TOPIC_ARN:
        return False
    import boto3
    boto3.client("sns", region_name=REGION, config=_aws_cfg()).publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"SOAR {rule}"[:99],
        Message=json.dumps(event, default=str),
    )
    return True


def _db_connection():
    import boto3
    import psycopg2
    secret = boto3.client("secretsmanager", region_name=REGION, config=_aws_cfg())
    creds = json.loads(secret.get_secret_value(SecretId=SECRET_ID)["SecretString"])
    return psycopg2.connect(
        host=creds["host"], port=creds["port"], dbname=creds["dbname"],
        user=creds["username"], password=creds["password"], connect_timeout=5,
    )


def store_incident(event, rule):
    """Action 3: write the incident to the PostgreSQL incidents table."""
    conn = _db_connection()
    try:
        with conn, conn.cursor() as cur:
            cur.execute("""CREATE TABLE IF NOT EXISTS incidents (
                id UUID PRIMARY KEY, logged_at TIMESTAMPTZ, rule TEXT,
                type TEXT, severity TEXT, src_ip TEXT, host TEXT)""")
            cur.execute("INSERT INTO incidents VALUES (%s,%s,%s,%s,%s,%s,%s)", (
                str(uuid.uuid4()), _now(), rule,
                str(event.get("type", "unknown")), str(event.get("severity", "unknown")),
                str(event.get("src_ip", "unknown")), str(event.get("host", "unknown")),
            ))
        return True
    finally:
        conn.close()


def log_unhandled(event, rule):
    return log_incident(event, rule)


ACTIONS = {
    "log_incident": log_incident,
    "notify": notify,
    "store_incident": store_incident,
    "log_unhandled": log_unhandled,
}


def run_actions(event, rule, names):
    """Run actions in order. A failure is printed and recorded, never fatal."""
    results = []
    for name in names:
        try:
            results.append((name, bool(ACTIONS[name](event, rule))))
        except Exception as exc:
            print(f"action {name} failed: {exc}", flush=True)
            results.append((name, False))
    return results