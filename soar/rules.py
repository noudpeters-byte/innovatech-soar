import yaml

def load_rules(path="rules.yaml"):
    with open(path) as f:
        return yaml.safe_load(f)

def match_rule(event: dict, rules: dict) -> dict:
    """Return the first rule whose conditions all match. First match wins."""
    for rule in rules["rules"]:
        conditions = rule.get("match", {})
        if any(event.get(k) != v for k, v in conditions.items()):
            continue
        if event.get("count", 1) < rule.get("min_count", 1):
            continue
        return {"name": rule["name"], "actions": rule["actions"]}
    return {"name": "default", "actions": rules["default_actions"]}