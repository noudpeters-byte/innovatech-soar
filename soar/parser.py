import re
from datetime import datetime, timezone

KV = re.compile(r'(\w+)=(\S+)')

def parse_line(raw: str, source_ip: str) -> dict:
    """Turn one syslog line into a normalised event dict."""
    line = raw.strip()
    fields = dict(KV.findall(line))
    return {
        "type": fields.get("type", "unknown"),
        "severity": fields.get("severity", "low"),
        "src_ip": fields.get("src_ip", source_ip),
        "user": fields.get("user"),
        "count": int(fields.get("count", 1)),
        "host": fields.get("host", source_ip),
        "raw": line,
        "received_at": datetime.now(timezone.utc).isoformat(),
    }