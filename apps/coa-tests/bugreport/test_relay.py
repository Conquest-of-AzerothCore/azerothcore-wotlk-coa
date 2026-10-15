from contextlib import contextmanager
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import urllib.error

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("coa_bug_relay", ROOT / "apps/coa-bugreport/relay.py")
relay = importlib.util.module_from_spec(spec)
spec.loader.exec_module(relay)
ID = "1-" + "a" * 32


class FakeGitHub:
    def __init__(self):
        self.posts = []
        self.searches = []
        self.error = None
        self.found = None

    def create(self, title, body):
        self.posts.append((title, body))
        if self.error:
            raise self.error
        return 37

    def find(self, marker, attempted):
        self.searches.append((marker, attempted))
        return self.found


class RelayTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="coa-relay-test-")
        self.root = Path(self.temporary.name)
        self.path = self.root / (ID + ".report")
        self.path.write_bytes(b"COABUG1\nAbility fails\nExpected: damage\nActual: nothing\n")
        self.github = FakeGitHub()
        self.now = 10000
        self.worker = relay.Relay(self.root, self.github, lambda: self.now)

    def tearDown(self):
        self.worker.close()
        self.temporary.cleanup()

    def status(self):
        return self.path.with_suffix(".status").read_text().strip()

    def test_create_and_repeat_returns_same_issue(self):
        self.assertEqual(self.worker.process(self.path), "created")
        self.assertEqual(self.status(), "created|37")
        self.worker.process(self.path)
        self.assertEqual(len(self.github.posts), 1)
        self.assertEqual(self.github.posts[0][1], "Expected: damage\nActual: nothing\n")
        self.assertNotIn(ID, self.github.posts[0][1])

    def test_restart_repairs_missing_status_without_posting(self):
        self.worker.process(self.path)
        self.path.with_suffix(".status").unlink()
        self.worker.close()
        self.worker = relay.Relay(self.root, self.github, lambda: self.now)
        self.worker.process(self.path)
        self.assertEqual(self.status(), "created|37")
        self.assertEqual(len(self.github.posts), 1)

    def test_ambiguous_timeout_never_reposts_when_absent(self):
        self.github.error = relay.DeliveryError("uncertain")
        self.assertEqual(self.worker.process(self.path), "uncertain")
        self.github.error = None
        for i in range(3):
            self.now += 301
            self.worker.process(self.path)
        self.assertEqual(len(self.github.posts), 1)
        self.assertEqual(len(self.github.searches), 0)
        self.assertEqual(self.status(), "uncertain")

    def test_lost_response_needs_review_without_github_reads(self):
        self.github.error = relay.DeliveryError("uncertain")
        self.worker.process(self.path)
        self.now += 301
        self.github.found = 82
        self.assertEqual(self.worker.process(self.path), "uncertain")
        self.assertEqual(self.status(), "uncertain")
        self.assertEqual(self.github.searches, [])
        self.assertEqual(len(self.github.posts), 1)

    def test_crash_after_post_intent_requires_reconciliation(self):
        self.github.error = RuntimeError("Simulated process crash after request")
        with self.assertRaises(RuntimeError):
            self.worker.process(self.path)
        self.worker.close()
        self.worker = relay.Relay(self.root, self.github, lambda: self.now)
        self.now += 301
        self.github.found = 99
        self.worker.process(self.path)
        self.assertEqual(self.status(), "uncertain")
        self.assertEqual(self.github.searches, [])
        self.assertEqual(len(self.github.posts), 1)

    def test_rate_limit_delays_all_reports_then_retries(self):
        self.github.error = relay.DeliveryError("limited", 90)
        self.worker.process(self.path)
        other = self.root / ("2-" + "b" * 32 + ".report")
        other.write_bytes(self.path.read_bytes())
        self.now += 89
        self.worker.process(self.path)
        self.worker.process(other)
        self.assertEqual(len(self.github.posts), 1)
        self.github.error = None
        self.now += 2
        self.worker.process(self.path)
        self.assertEqual(self.status(), "created|37")
        self.assertEqual(len(self.github.posts), 2)

    def test_token_failure_stays_blocked_until_retry(self):
        self.github.error = relay.DeliveryError("blocked")
        self.worker.process(self.path)
        self.assertEqual(self.status(), "blocked")
        self.github.error = None
        self.now += 301
        self.worker.process(self.path)
        self.assertEqual(self.status(), "created|37")

    def test_validation_error_is_not_retried(self):
        self.github.error = relay.DeliveryError("invalid")
        self.worker.process(self.path)
        self.now += 1000
        self.worker.process(self.path)
        self.assertEqual(self.status(), "failed")
        self.assertEqual(len(self.github.posts), 1)

    def test_edited_report_cannot_reuse_delivery_id(self):
        self.worker.process(self.path)
        self.path.write_text("COABUG1\nChanged report\nDifferent body", encoding="utf-8")
        self.assertEqual(self.worker.process(self.path), "changed")
        self.assertEqual(len(self.github.posts), 1)

    def test_utf8_and_mentions(self):
        self.path.write_text("COABUG1\nОшибка @someone\nШаги: нажать кнопку @org/team", encoding="utf-8")
        self.worker.process(self.path)
        title, body = self.github.posts[0]
        self.assertIn("Ошибка", title)
        self.assertIn("@someone", title)
        self.assertIn("@org/team", body)
        self.assertNotIn("<!-- coa-report:", body)

    def test_bad_files_never_reach_github(self):
        for raw in [b"bad", b"COABUG1\nab\nbody", b"COABUG1\nabc\n\xff",
                    b"COABUG1\nabc\n\0", b"COABUG1\nabc\n" + b"x" * 16000]:
            with self.subTest(raw=raw[:20]):
                self.path.write_bytes(raw)
                self.assertEqual(self.worker.process(self.path), "failed")
        self.assertEqual(self.github.posts, [])

    def test_single_worker_lock(self):
        with relay.worker_lock(self.root):
            with self.assertRaises(RuntimeError):
                with relay.worker_lock(self.root):
                    self.fail("Second worker acquired lock")

    def test_dry_run_does_not_write_or_connect(self):
        before = {p.name: p.read_bytes() for p in self.root.iterdir()}
        with (patch("sys.argv", ["relay.py", "--spool", str(self.root)]),
              patch.object(relay, "ReportService") as client):
            with patch("sys.stdout", new=io.StringIO()):
                self.assertEqual(relay.main(), 0)
            client.assert_not_called()
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.root.iterdir()})


class Response(io.BytesIO):
    status = 201
    headers = {}


class HttpTests(unittest.TestCase):
    def setUp(self):
        self.client = relay.ReportService("fake-test-token")

    def test_exact_endpoint_and_server_token(self):
        requests = []
        def open_request(request, timeout):
            requests.append(request)
            return Response(json.dumps({"status": "created", "issue_number": 3, "issue_url": relay.WEB + "3"}).encode())
        self.client.opener.open = open_request
        self.assertEqual(self.client.create("Bug title", "Bug body"), 3)
        request = requests[0]
        self.assertEqual(request.full_url, relay.API)
        self.assertEqual(request.get_header("Authorization"), "Bearer fake-test-token")
        self.assertEqual(json.loads(request.data), {"title": "Bug title", "body": "Bug body"})

    def test_redirect_is_never_followed(self):
        redirect = relay.NoRedirect()
        self.assertIsNone(redirect.redirect_request(None, None, 302, "", {}, "https://unrelated.example"))

    def test_http_failures_are_classified_without_echoing_content(self):
        cases = [(401, {}, "blocked"), (403, {}, "blocked"), (429, {"Retry-After": "73"}, "limited"),
                 (429, {}, "limited"), (422, {}, "invalid"), (500, {}, "uncertain"), (302, {}, "blocked")]
        for code, headers, expected in cases:
            with self.subTest(code=code, headers=headers):
                error = urllib.error.HTTPError(relay.API, code, "secret response", headers, None)
                with patch.object(self.client.opener, "open", side_effect=error):
                    with self.assertRaises(relay.DeliveryError) as caught:
                        self.client.create("title", "body")
                self.assertEqual(caught.exception.kind, expected)
                self.assertNotIn("secret", str(caught.exception))

    def test_untrusted_success_url_is_not_shown(self):
        with self.assertRaises(relay.DeliveryError):
            relay.ReportService.issue_number({"status": "created", "issue_number": 3,
                                              "issue_url": "https://unrelated.example/3"})

    def test_service_duplicate_returns_existing_issue(self):
        response = Response(json.dumps({"status": "created", "duplicate": True,
                                        "issue_number": 9, "issue_url": relay.WEB + "9"}).encode())
        response.status = 200
        with patch.object(self.client.opener, "open", return_value=response):
            self.assertEqual(self.client.create("title", "body"), 9)

    def test_service_pending_is_retryable_without_claiming_success(self):
        response = Response(b'{"status":"pending","retry_after":2}')
        response.status, response.headers = 202, {"Retry-After": "2"}
        with patch.object(self.client.opener, "open", return_value=response):
            with self.assertRaises(relay.DeliveryError) as caught:
                self.client.create("title", "body")
        self.assertEqual((caught.exception.kind, caught.exception.delay), ("pending", 2))

    def test_service_config_error_differs_from_ambiguous_failure(self):
        for data, expected in [({"status": "failed", "error": "github_access_denied"}, "blocked"),
                               ({"status": "unknown", "error": "internal_error"}, "uncertain")]:
            error = urllib.error.HTTPError(relay.API, 503, "Service unavailable", {},
                                           io.BytesIO(json.dumps(data).encode()))
            with patch.object(self.client.opener, "open", side_effect=error):
                with self.assertRaises(relay.DeliveryError) as caught:
                    self.client.create("title", "body")
            self.assertEqual(caught.exception.kind, expected)


if __name__ == "__main__":
    unittest.main(verbosity=2)
