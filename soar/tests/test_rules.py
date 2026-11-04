from rules import load_rules, match_rule
import pathlib

RULES = load_rules(str(pathlib.Path(__file__).parent.parent / "rules.yaml"))

def test_r1_fires_on_burst():
    e = {"type": "auth_fail", "severity": "medium", "count": 6}
    assert match_rule(e, RULES)["name"] == "R1_failed_login_burst"

def test_r1_needs_five_attempts():
    e = {"type": "auth_fail", "severity": "medium", "count": 2}
    assert match_rule(e, RULES)["name"] != "R1_failed_login_burst"

def test_r3_low_severity():
    e = {"type": "info", "severity": "low", "count": 1}
    assert match_rule(e, RULES)["name"] == "R3_low_severity"

def test_default_when_no_match():
    e = {"type": "other", "severity": "medium", "count": 1}
    assert match_rule(e, RULES)["name"] == "default"