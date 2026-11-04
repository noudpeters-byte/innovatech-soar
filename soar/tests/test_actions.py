import json
import actions


def test_log_incident_writes_json_line(tmp_path, monkeypatch):
    log = tmp_path / "incidents.jsonl"
    monkeypatch.setattr(actions, "INCIDENT_LOG", str(log))
    actions.log_incident({"type": "auth_fail"}, "R1")
    line = json.loads(log.read_text().strip())
    assert line["rule"] == "R1"
    assert line["event"]["type"] == "auth_fail"


def test_notify_skipped_without_topic(monkeypatch):
    monkeypatch.setattr(actions, "SNS_TOPIC_ARN", "")
    assert actions.notify({"type": "x"}, "R1") is False


def test_run_actions_records_failure(monkeypatch):
    monkeypatch.setattr(actions, "SNS_TOPIC_ARN", "")
    results = actions.run_actions({"type": "x"}, "R1", ["notify", "bogus"])
    assert results == [("notify", False), ("bogus", False)]