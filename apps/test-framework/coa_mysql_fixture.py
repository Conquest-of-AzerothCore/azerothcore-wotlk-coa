"""Disposable MySQL lifecycle adapted from test_enchantment_migrations.py.

A unique named pipe/socket and --skip-networking isolate each fixture. Windows
--no-monitor ensures the owned process is the server, so cleanup cannot orphan a child.
"""
import os
from pathlib import Path
import subprocess
import tempfile
import time
import uuid

PROCESS_OPTIONS = {"creationflags": subprocess.CREATE_NO_WINDOW} if os.name == "nt" else {}

class CreatureMySQLFixture:
    @classmethod
    def start_mysql(cls):
        suffix = ".exe" if os.name == "nt" else ""
        cls.mysql = cls.mysql_bin / ("mysql" + suffix)
        cls.mysqld = cls.mysql_bin / ("mysqld" + suffix)
        if not cls.mysql.is_file() or not cls.mysqld.is_file():
            raise RuntimeError("--mysql-bin must contain both mysql and mysqld")

        cls.temporary = tempfile.TemporaryDirectory(prefix="coa-creature-")
        cls.directory = Path(cls.temporary.name).resolve()
        cls.process = None
        cls.addClassCleanup(cls.stop_mysql)
        cls.log = cls.directory / "mysql.log"
        server = [str(cls.mysqld), "--no-defaults", f"--basedir={cls.mysql_bin.parent}",
                  f"--datadir={cls.directory / 'data'}", f"--log-error={cls.log}"]
        print("Initializing isolated MySQL data directory...", flush=True)
        subprocess.run(server + ["--initialize-insecure"], check=True, capture_output=True,
                       timeout=90, **PROCESS_OPTIONS)

        endpoint = ("coa_creature_" + uuid.uuid4().hex if os.name == "nt"
                    else str(cls.directory / "mysql.sock"))
        cls.client = [str(cls.mysql), "--no-defaults", "--no-login-paths", "--user=root", "--batch",
                      "--skip-column-names", "--default-character-set=utf8mb4", "--connect-timeout=1",
                      "--max-allowed-packet=1GB", f"--socket={endpoint}"]
        server += ["--skip-networking", "--mysqlx=OFF", "--max-allowed-packet=1GB", f"--socket={endpoint}"]
        if os.name == "nt":
            server += ["--enable-named-pipe", "--no-monitor"]
            cls.client += ["--protocol=PIPE", "--host=."]
        else:
            cls.client.append("--protocol=SOCKET")
        cls.process = subprocess.Popen(server, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                       **PROCESS_OPTIONS)
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            if cls.process.poll() is not None:
                raise RuntimeError(cls.log.read_text(encoding="utf-8"))
            result = subprocess.run(cls.client, input="SELECT 1;\n", text=True, capture_output=True,
                                    timeout=30, **PROCESS_OPTIONS)
            if result.returncode == 0 and result.stdout.strip() == "1":
                break
            time.sleep(0.2)
        else:
            raise RuntimeError("Isolated MySQL startup timed out: " + cls.log.read_text(encoding="utf-8"))

    @classmethod
    def stop_mysql(cls):
        if cls.process is not None and cls.process.poll() is None:
            try:
                subprocess.run(cls.client, input="SHUTDOWN;\n", text=True, capture_output=True,
                               timeout=10, **PROCESS_OPTIONS)
                cls.process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                cls.process.kill()
                cls.process.wait(timeout=10)
        # Only clean the exact temporary directory created by this test, after its server exits.
        if cls.directory.parent != Path(tempfile.gettempdir()).resolve() or not cls.directory.name.startswith(
                "coa-creature-"):
            raise RuntimeError("Unexpected test data directory; refusing cleanup")
        cls.temporary.cleanup()

    @classmethod
    def query(cls, sql, database="creature_test", expected_error=None):
        marker = "creature_test_" + uuid.uuid4().hex
        command = cls.client + ([database] if database else [])
        result = subprocess.run(command, input=f"SELECT '{marker}_begin';\n{sql}\nSELECT '{marker}_end';\n",
                                text=True, encoding="utf-8", capture_output=True, timeout=120, **PROCESS_OPTIONS)
        lines = result.stdout.splitlines()
        if not lines or lines[0] != marker + "_begin":
            raise AssertionError("Missing MySQL result frame: " + result.stderr)
        if expected_error:
            if result.returncode == 0 or expected_error not in result.stderr:
                raise AssertionError("Expected SQL failure was not reproduced: " + result.stderr)
            if marker + "_end" in lines:
                raise AssertionError("MySQL continued after a failed migration")
            return result.stderr
        if result.returncode or lines[-1] != marker + "_end":
            raise AssertionError("Migration/query failed: " + result.stderr)
        return [tuple(line.split("\t")) for line in lines[1:-1]]
