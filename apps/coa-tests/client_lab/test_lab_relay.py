import base64
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
import io
import json
from pathlib import Path
import re
import tempfile
import threading
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch
from xml.sax.saxutils import escape, unescape

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("coa_lab_relay", HERE / "lab_relay.py")
lab_relay = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lab_relay)
run_spec = importlib.util.spec_from_file_location("coa_client_lab_run", HERE / "run.py")
lab_run = importlib.util.module_from_spec(run_spec)
run_spec.loader.exec_module(lab_run)

RESULT = ('<?xml version="1.0" encoding="UTF-8"?><SOAP-ENV:Envelope '
          'xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="urn:AC"><SOAP-ENV:Body>'
          '<ns1:executeCommandResponse><result>{}</result></ns1:executeCommandResponse></SOAP-ENV:Body>'
          '</SOAP-ENV:Envelope>')
FAULT = ('<?xml version="1.0" encoding="UTF-8"?><SOAP-ENV:Envelope '
         'xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Body><SOAP-ENV:Fault>'
         '<faultcode>SOAP-ENV:Client</faultcode><faultstring>{}</faultstring><detail>{}</detail>'
         '</SOAP-ENV:Fault></SOAP-ENV:Body></SOAP-ENV:Envelope>')


class FakeSoap:
    def __init__(self):
        self.commands, self.auth, self.replies = [], [], []
        outer = self

        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                body = self.rfile.read(int(self.headers["Content-Length"])).decode()
                outer.commands.append(unescape(re.search(r"<command>(.*)</command>", body).group(1)))
                outer.auth.append(self.headers.get("Authorization"))
                kind, text = outer.replies.pop(0) if outer.replies else ("result", "unknown")
                payload = (RESULT.format(escape(text)) if kind == "result"
                           else FAULT.format(escape(text), escape(text))).encode()
                self.send_response(200 if kind == "result" else 500)
                self.send_header("Content-Type", "text/xml")
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)

            def log_message(self, *args):
                pass

        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.url = f"http://127.0.0.1:{self.server.server_address[1]}/"
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def close(self):
        self.server.shutdown()
        self.server.server_close()


class LabRelayTest(unittest.TestCase):
    def setUp(self):
        self.soap = FakeSoap()
        self.tmp = tempfile.TemporaryDirectory()
        self.password_file = Path(self.tmp.name) / "soap.password"
        self.password_file.write_text("SECRET\n")
        self.descriptor = {
            "instance": "", "slot": 2, "soap_url": self.soap.url, "soap_account": "COALABSOAP",
            "soap_password_file": str(self.password_file), "account": "COALAB1", "character": "Coalabone",
            "deployed_commit": "abc", "deployed_at": "2026-10-26T00:32:54+01:00", "preflight": "pass",
            "preflight_slot": 2, "preflight_time": "2026-10-26T00:36:21+01:00",
        }

    def tearDown(self):
        self.soap.close()
        self.tmp.cleanup()

    def test_send_then_poll_until_complete(self):
        answer = {"req": "x", "result": {"tooltip": [{"left": "Fel Fireball"}]}}
        encoded = base64.b64encode(json.dumps(answer).encode()).decode()
        self.soap.replies = [("result", "sent x"), ("result", "pending 0/0"), ("result", "pending 1/2"),
                             ("result", f"complete {encoded}")]
        result = lab_relay.probe(self.descriptor, "spell 501281", timeout=5, poll=0.01)
        self.assertEqual(result["result"], answer["result"])
        self.assertIsInstance(result["elapsed_ms"], int)
        send = self.soap.commands[0]
        self.assertRegex(send, r"^\.labprobe send Coalabone r[0-9a-f]{12} spell 501281$")
        self.assertEqual(self.soap.commands[1:], [f".labprobe result Coalabone {send.split()[3]}"] * 3)

    def test_probe_raises_on_soap_fault_without_polling(self):
        self.soap.replies = [("fault", "There is no such command")]
        with self.assertRaisesRegex(lab_relay.SoapFault, "There is no such command"):
            lab_relay.probe(self.descriptor, "ping", timeout=5, poll=0.01)
        self.assertEqual(len(self.soap.commands), 1)

    def test_probe_timeout_names_character_and_status(self):
        self.soap.replies = [("result", "sent x")] + [("result", "pending 1/3")] * 200
        with self.assertRaises(TimeoutError) as caught:
            lab_relay.probe(self.descriptor, "ping", timeout=0.2, poll=0.01)
        self.assertIn("Coalabone", str(caught.exception))
        self.assertRegex(str(caught.exception), r"r[0-9a-f]{12}")
        self.assertIn("pending 1/3", str(caught.exception))

    def test_basic_auth_header_sent(self):
        self.soap.replies = [("result", "Server info")]
        self.assertEqual(lab_relay.soap_execute(self.soap.url, "COALABSOAP", "SECRET", ".server info"),
                         "Server info")
        self.assertEqual(self.soap.auth, ["Basic " + base64.b64encode(b"COALABSOAP:SECRET").decode()])

    def test_descriptor_requires_every_key(self):
        path = Path(self.tmp.name) / "lab.json"
        for key in lab_relay.DESCRIPTOR_KEYS:
            partial = dict(self.descriptor)
            del partial[key]
            path.write_text(json.dumps(partial))
            with self.assertRaisesRegex(ValueError, key):
                lab_relay.load_descriptor(path)

    def test_run_fails_when_preflight_not_pass(self):
        path = Path(self.tmp.name) / "lab.json"
        path.write_text(json.dumps({**self.descriptor, "preflight": "fail"}))
        argv = ["run.py", "--client-lab", str(path), "--dbc-dir", self.tmp.name]
        with patch("sys.argv", argv), redirect_stdout(io.StringIO()) as output:
            self.assertEqual(lab_run.main(), 1)
        self.assertEqual(self.soap.commands, [])
        self.assertIn("lab preflight is 'fail'", output.getvalue())

    def test_run_fails_on_a_stale_preflight_before_any_soap_call(self):
        path = Path(self.tmp.name) / "lab.json"
        stale = {"another slot": {"preflight_slot": 3}, "older than the deploy":
                 {"preflight_time": "2026-10-26T00:30:00+01:00"}, "unreadable time": {"preflight_time": "unknown"}}
        for name, change in stale.items():
            with self.subTest(name):
                path.write_text(json.dumps({**self.descriptor, **change}))
                argv = ["run.py", "--client-lab", str(path), "--dbc-dir", self.tmp.name]
                with patch("sys.argv", argv), redirect_stdout(io.StringIO()) as output:
                    self.assertEqual(lab_run.main(), 1)
                self.assertIn("FAIL: lab preflight", output.getvalue())
        self.assertEqual(self.soap.commands, [])

    def test_run_passes_with_three_fast_answers_from_one_load(self):
        def complete(answer):
            return ("result", "complete " + base64.b64encode(json.dumps(answer).encode()).decode())
        spell = {"result": {"tooltip": [{"left": "Fel Fireball", "right": ""}]}, "loadId": "7-1"}
        self.soap.replies = ([("result", "sent"), complete(spell)] * 3
                             + [("result", "sent"), complete({"error": "unknown spell 999999999", "loadId": "7-1"})]
                             + [("fault", "not a read-only probe request")])
        path = Path(self.tmp.name) / "lab.json"
        path.write_text(json.dumps(self.descriptor))
        argv = ["run.py", "--client-lab", str(path), "--dbc-dir", self.tmp.name]
        with patch("sys.argv", argv), patch.object(lab_run, "spell_name", return_value="Fel Fireball"), \
                patch.object(lab_run, "run_memory_checks"), redirect_stdout(io.StringIO()) as output:
            self.assertEqual(lab_run.main(), 0, output.getvalue())
        self.assertIn(".labprobe send Coalabone r1 eval 1", self.soap.commands)

    def test_run_fails_on_a_changed_load(self):
        def complete(answer):
            return ("result", "complete " + base64.b64encode(json.dumps(answer).encode()).decode())
        replies = []
        for load in ("1", "1", "2"):
            replies += [("result", "sent"),
                        complete({"result": {"tooltip": [{"left": "Fel Fireball"}]}, "loadId": load})]
        self.soap.replies = (replies + [("result", "sent"),
                                        complete({"error": "unknown spell 999999999", "loadId": "2"})]
                             + [("fault", "not a read-only probe request")])
        path = Path(self.tmp.name) / "lab.json"
        path.write_text(json.dumps(self.descriptor))
        argv = ["run.py", "--client-lab", str(path), "--dbc-dir", self.tmp.name]
        with patch("sys.argv", argv), patch.object(lab_run, "spell_name", return_value="Fel Fireball"), \
                patch.object(lab_run, "run_memory_checks"), redirect_stdout(io.StringIO()) as output:
            self.assertEqual(lab_run.main(), 1)
        self.assertIn("FAIL: all answers come from one UI load", output.getvalue())


if __name__ == "__main__":
    unittest.main()
