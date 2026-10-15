
from __future__ import annotations

CLI_DESCRIPTION = """Deliver in-game reports through the configured CoA Railway service. Standard library only.

Dry-run is the default. --send uses the bundled report-service URL and intake key.
Never run two instances against the same spool; the CLI enforces an OS file lock.
"""

import argparse
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import time
import urllib.error
import urllib.request

REPOSITORY = "jealous-sound/azerothcore-wotlk-coa"
SERVICE_URL = "https://coa-bug-report.up.railway.app"
API = SERVICE_URL + "/v1/reports"
DEFAULT_API_KEY = "coa_zRatxUHShOn-HEkoreKGME6sd3DdMG7eKTTKlj2JCK4"
WEB = f"https://github.com/{REPOSITORY}/issues/"
KEY = re.compile(r"[1-9][0-9]{0,9}-[0-9a-f]{16,48}")
MAX_FILE = 16000
MAX_RESPONSE = 64 * 1024


class DeliveryError(Exception):
    def __init__(self, kind: str, delay: int = 300):
        super().__init__(kind)
        self.kind = kind
        self.delay = delay


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class ReportService:
    def __init__(self, api_key: str = DEFAULT_API_KEY):
        if not api_key or not api_key.isascii() or any(c.isspace() for c in api_key):
            raise ValueError("Configure a valid report-service intake key.")
        self.api_key = api_key
        self.opener = urllib.request.build_opener(NoRedirect())

    @staticmethod
    def retry_delay(headers, default=300):
        try:
            return max(1, min(int(headers.get("Retry-After", default)), 86400))
        except (ValueError, TypeError):
            return default

    @staticmethod
    def read_json(response):
        raw = response.read(MAX_RESPONSE + 1)
        if len(raw) > MAX_RESPONSE:
            raise ValueError("Oversized service response")
        data = json.loads(raw)
        if not isinstance(data, dict):
            raise ValueError("Invalid service response")
        return data

    def create(self, title: str, body: str) -> int:
        request = urllib.request.Request(
            API,
            data=json.dumps({"title": title, "body": body}).encode("utf-8"),
            method="POST",
            headers={
                "Authorization": "Bearer " + self.api_key,
                "Accept": "application/json",
                "Content-Type": "application/json",
                "User-Agent": "CoA-InGame-BugReport/1",
            },
        )
        try:
            with self.opener.open(request, timeout=30) as response:
                data = self.read_json(response)
                if response.status == 202 and data.get("status") == "pending":
                    raise DeliveryError("pending", self.retry_delay(response.headers, 2))
                if response.status not in (200, 201):
                    raise DeliveryError("uncertain")
                return self.issue_number(data)
        except urllib.error.HTTPError as error:
            if error.code == 429:
                raise DeliveryError("limited", self.retry_delay(error.headers)) from None
            if error.code in (400, 413, 415, 422):
                raise DeliveryError("invalid") from None
            if error.code in (301, 302, 303, 307, 308, 401, 403, 404, 405):
                raise DeliveryError("blocked") from None
            if error.code == 503:
                try:
                    data = self.read_json(error)
                except (OSError, ValueError, TypeError):
                    data = {}
                if data.get("status") == "failed" and data.get("error") == "github_access_denied":
                    raise DeliveryError("blocked", self.retry_delay(error.headers)) from None
            raise DeliveryError("uncertain") from None
        except (urllib.error.URLError, TimeoutError, OSError, ValueError):
            raise DeliveryError("uncertain") from None

    @staticmethod
    def issue_number(issue):
        if not isinstance(issue, dict):
            raise DeliveryError("uncertain")
        number = issue.get("issue_number")
        if (issue.get("status") != "created" or type(number) is not int or not 0 < number <= 4294967295
                or issue.get("issue_url") != WEB + str(number)):
            raise DeliveryError("uncertain")
        return number

def read_report(path: Path):
    if not KEY.fullmatch(path.stem) or path.is_symlink() or path.stat().st_size > MAX_FILE:
        raise ValueError("Invalid report file")
    raw = path.read_bytes()
    text = raw.decode("utf-8").replace("\r\n", "\n")
    if not text.startswith("COABUG1\n"):
        raise ValueError("Unsupported report format")
    title, separator, body = text[8:].partition("\n")
    if (not separator or not 3 <= len(title.encode("utf-8")) <= 200 or not body.strip()
            or any(ord(c) < 32 for c in title)
            or any(ord(c) < 32 and c not in "\r\n\t" for c in body)):
        raise ValueError("Invalid report content")
    digest = hashlib.sha256(raw).hexdigest()
    report_id = hashlib.sha256((path.stem + ":" + digest).encode("ascii")).hexdigest()
    marker = f"<!-- coa-report:{report_id} -->"
    return digest, marker, title, body


def write_status(root: Path, key: str, state: str, number: int | None = None):
    value = f"created|{number}" if state == "created" else state
    data = (value + "\n").encode("ascii")
    destination = root / (key + ".status")
    if destination.exists() and destination.read_bytes() == data:
        return
    temporary = root / (key + ".status.tmp")
    with temporary.open("wb") as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, destination)


class Relay:
    def __init__(self, root: Path, service, clock=time.time):
        self.root, self.service, self.clock = root, service, clock
        self.database = sqlite3.connect(root / "relay.sqlite3")
        self.database.row_factory = sqlite3.Row
        self.database.execute("PRAGMA synchronous=FULL")
        self.database.execute("""CREATE TABLE IF NOT EXISTS deliveries (
            key TEXT PRIMARY KEY, digest TEXT NOT NULL, marker TEXT NOT NULL, state TEXT NOT NULL,
            number INTEGER, attempted REAL NOT NULL DEFAULT 0, next_try REAL NOT NULL DEFAULT 0
        )""")
        self.database.execute("CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value REAL NOT NULL)")
        self.database.execute("UPDATE deliveries SET state='uncertain' WHERE state='posting'")
        self.database.commit()

    def close(self):
        self.database.close()

    def set_state(self, key: str, state: str, number=None, delay=0):
        with self.database:
            self.database.execute("UPDATE deliveries SET state=?, number=?, next_try=? WHERE key=?",
                                  (state, number, self.clock() + delay, key))
        write_status(self.root, key, state, number)

    def process(self, path: Path) -> str:
        key = path.stem
        if not KEY.fullmatch(key):
            return "ignored"
        try:
            digest, marker, title, body = read_report(path)
        except (ValueError, OSError):
            write_status(self.root, key, "failed")
            return "failed"
        with self.database:
            self.database.execute(
                "INSERT OR IGNORE INTO deliveries(key,digest,marker,state) VALUES(?,?,?,'queued')",
                (key, digest, marker))
        row = self.database.execute("SELECT * FROM deliveries WHERE key=?", (key,)).fetchone()
        if row["digest"] != digest:
            write_status(self.root, key, "failed")
            return "changed"
        if row["state"] in ("created", "failed", "uncertain"):
            write_status(self.root, key, row["state"], row["number"])
            return row["state"]
        if row["next_try"] > self.clock():
            write_status(self.root, key, row["state"])
            return row["state"]
        gate = self.database.execute("SELECT value FROM settings WHERE key='next_network'").fetchone()
        if gate and gate[0] > self.clock():
            write_status(self.root, key, row["state"])
            return row["state"]
        with self.database:
            self.database.execute("INSERT OR REPLACE INTO settings VALUES('next_network',?)", (self.clock() + 5,))

        with self.database:
            self.database.execute("UPDATE deliveries SET state='posting', attempted=? WHERE key=?", (self.clock(), key))
        try:
            number = self.service.create(title, body)
        except DeliveryError as error:
            state = {"limited": "queued", "pending": "queued", "blocked": "blocked", "invalid": "failed"}.get(
                error.kind, "uncertain")
            self.set_state(key, state, delay=error.delay)
            if error.kind in ("limited", "blocked"):
                with self.database:
                    self.database.execute("INSERT OR REPLACE INTO settings VALUES('next_network',?)",
                                          (self.clock() + error.delay,))
            return state
        self.set_state(key, "created", number)
        return "created"


@contextmanager
def worker_lock(root: Path):
    with (root / "relay.lock").open("a+b") as lock:
        lock.seek(0, os.SEEK_END)
        if lock.tell() == 0:
            lock.write(b"0")
            lock.flush()
        lock.seek(0)
        try:
            if os.name == "nt":
                import msvcrt
                msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            raise RuntimeError("Another bug-report relay is already using this spool.") from None
        try:
            yield
        finally:
            if os.name == "nt":
                lock.seek(0)
                msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(lock.fileno(), fcntl.LOCK_UN)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--spool", type=Path, required=True)
    parser.add_argument("--once", action="store_true", help="Process one pass, then exit.")
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--send", action="store_true", help="Enable real delivery through Railway.")
    modes.add_argument("--dry-run", action="store_true", help="Validate files without writes or network (default).")
    args = parser.parse_args()
    root = args.spool.resolve(strict=True)
    if not root.is_dir():
        parser.error("--spool must be an existing private directory")
    os.umask(0o077)
    if not args.send:
        count = 0
        for path in sorted(root.glob("*.report")):
            read_report(path)
            count += 1
        print(f"Dry run: {count} report(s) valid; no network requests or file writes.")
        return 0
    service = ReportService(os.environ.get("COA_BUGREPORT_API_KEY", DEFAULT_API_KEY))
    with worker_lock(root):
        relay = Relay(root, service)
        try:
            while True:
                for path in sorted(root.glob("*.report")):
                    relay.process(path)
                if args.once:
                    break
                time.sleep(5)
        finally:
            relay.close()
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(0)
    except (OSError, ValueError, RuntimeError, sqlite3.Error) as error:
        print(f"Relay stopped ({type(error).__name__}). Check configuration, permissions and the delivery journal.")
        raise SystemExit(1)
