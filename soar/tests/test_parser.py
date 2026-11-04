from parser import parse_line

def test_parses_auth_fail():
    e = parse_line("type=auth_fail user=bob src_ip=203.0.113.50 severity=medium count=6", "10.10.0.5")
    assert e["type"] == "auth_fail"
    assert e["src_ip"] == "203.0.113.50"
    assert e["count"] == 6

def test_falls_back_to_sender_ip():
    e = parse_line("type=malware severity=high", "10.10.0.5")
    assert e["src_ip"] == "10.10.0.5"

def test_unknown_when_no_type():
    assert parse_line("hello world", "10.10.0.5")["type"] == "unknown"