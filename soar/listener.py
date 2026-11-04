import logging
import socketserver
import threading
from parser import parse_line
from rules import load_rules, match_rule
from actions import run_actions

RULES = load_rules("rules.yaml")

PORT = 514
log = logging.getLogger("soar.listener")


def process_event(event: dict) -> None:
    """Parse -> match rule -> run actions. Failures are logged, never fatal."""
    rule = match_rule(event, RULES)
    results = run_actions(event, rule["name"], rule["actions"])
    log.info("rule=%s actions=%s", rule["name"], results)

    
class UDPHandler(socketserver.BaseRequestHandler):
    def handle(self):
        data = self.request[0].decode("utf-8", errors="replace")
        process_event(parse_line(data, self.client_address[0]))


class TCPHandler(socketserver.StreamRequestHandler):
    def handle(self):
        for raw in self.rfile:
            line = raw.decode("utf-8", errors="replace")
            if line.strip():
                process_event(parse_line(line, self.client_address[0]))


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    udp = socketserver.ThreadingUDPServer(("0.0.0.0", PORT), UDPHandler)
    tcp = socketserver.ThreadingTCPServer(("0.0.0.0", PORT), TCPHandler)
    threading.Thread(target=udp.serve_forever, daemon=True).start()
    log.info("SOAR listener on UDP and TCP %d", PORT)
    tcp.serve_forever()