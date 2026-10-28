import importlib.util
import io
from contextlib import redirect_stdout
from pathlib import Path
from unittest import TestCase
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
run_spec = importlib.util.spec_from_file_location("coa_client_lab_run_memory", HERE / "run.py")
lab_run = importlib.util.module_from_spec(run_spec)
run_spec.loader.exec_module(lab_run)

DESCRIPTOR = {"slot": 2, "character": "Coalabone", "client_dir": "/client-lab/ascension-lab",
              "worldserver_conf": "/slots/s2/etc/worldserver.conf"}


class RunMemoryChecksTest(TestCase):
    def run_checks(self, descriptor):
        checks = lab_run.Checks()
        with redirect_stdout(io.StringIO()) as output:
            lab_run.run_memory_checks(descriptor, checks)
        return checks, output.getvalue()

    def test_missing_descriptor_keys_fail_once_and_skip_memory_reads(self):
        descriptor = {"slot": 2, "character": "Coalabone"}
        with patch.object(lab_run.lab_memory, "find_lab_client_pid") as find_pid, \
                patch.object(lab_run.lab_relay, "probe", return_value={"result": {"source": "ERROR_HANDLER_DATABASE"}}):
            checks, output = self.run_checks(descriptor)
        find_pid.assert_not_called()
        self.assertIn("FAIL: lab descriptor carries the memory diagnostics keys (missing client_dir, "
                      "worldserver_conf)", output)
        self.assertIn("PASS: probe errors answers without error with source ERROR_HANDLER_DATABASE", output)

    def test_guard_failure_fails_every_memory_check_but_still_checks_errors(self):
        with patch.object(lab_run.lab_memory, "find_lab_client_pid",
                           side_effect=lab_run.lab_memory.GuardError("slot 1 refused")), \
                patch.object(lab_run.lab_relay, "probe", return_value={"result": {"source": "ERROR_HANDLER_DATABASE"}}):
            checks, output = self.run_checks(DESCRIPTOR)
        self.assertIn("FAIL: memory guards pass for the lab client process (slot 1 refused)", output)
        self.assertIn("FAIL: memory active player name equals the descriptor character (no lab client pid)", output)
        self.assertIn("FAIL: memory player health and max health equal probe state (no lab client pid)", output)
        self.assertIn("FAIL: memory active aura spell ids include probe auras player (no lab client pid)", output)
        self.assertIn("PASS: probe errors answers without error with source ERROR_HANDLER_DATABASE", output)

    def test_all_memory_checks_pass_on_a_matching_sample(self):
        player = {"name": "Coalabone", "health": 100, "max_health": 100, "auras": [{"spell_id": 589}]}
        probe_answers = {
            "state": {"result": {"player": {"health": 100, "maxHealth": 100}}},
            "auras player": {"result": {"auras": [{"spellId": 589}]}},
            "errors": {"result": {"source": "ERROR_HANDLER_DATABASE"}},
        }
        with patch.object(lab_run.lab_memory, "find_lab_client_pid", return_value=4242), \
                patch.object(lab_run.lab_memory, "read_active_player", return_value=player), \
                patch.object(lab_run.lab_relay, "probe", side_effect=lambda descriptor, line: probe_answers[line]):
            checks, output = self.run_checks(DESCRIPTOR)
        self.assertEqual(checks.failures, 0, output)
        self.assertIn("PASS: memory guards pass for the lab client process", output)
        self.assertIn("PASS: memory active player name equals the descriptor character", output)
        self.assertIn("PASS: memory player health and max health equal probe state", output)
        self.assertIn("PASS: memory active aura spell ids include probe auras player", output)
        self.assertIn("PASS: probe errors answers without error with source ERROR_HANDLER_DATABASE", output)

    def test_memory_only_aura_hidden_by_the_ui_passes(self):
        player = {"name": "Coalabone", "health": 100, "max_health": 100,
                  "auras": [{"spell_id": 707763}, {"spell_id": 9931032}]}
        probe_answers = {
            "state": {"result": {"player": {"health": 100, "maxHealth": 100}}},
            "auras player": {"result": {"auras": [{"spellId": 9931032}]}},
            "errors": {"result": {"source": "ERROR_HANDLER_DATABASE"}},
        }
        with patch.object(lab_run.lab_memory, "find_lab_client_pid", return_value=4242), \
                patch.object(lab_run.lab_memory, "read_active_player", return_value=player), \
                patch.object(lab_run.lab_relay, "probe", side_effect=lambda descriptor, line: probe_answers[line]):
            checks, output = self.run_checks(DESCRIPTOR)
        self.assertEqual(checks.failures, 0, output)
        self.assertIn("memory_only=[707763]", output)

    def test_probe_aura_missing_from_memory_fails(self):
        player = {"name": "Coalabone", "health": 100, "max_health": 100, "auras": []}
        probe_answers = {
            "state": {"result": {"player": {"health": 100, "maxHealth": 100}}},
            "auras player": {"result": {"auras": [{"spellId": 589}]}},
            "errors": {"result": {"source": "ERROR_HANDLER_DATABASE"}},
        }
        with patch.object(lab_run.lab_memory, "find_lab_client_pid", return_value=4242), \
                patch.object(lab_run.lab_memory, "read_active_player", return_value=player), \
                patch.object(lab_run.lab_relay, "probe", side_effect=lambda descriptor, line: probe_answers[line]):
            checks, output = self.run_checks(DESCRIPTOR)
        self.assertIn("FAIL: memory active aura spell ids include probe auras player", output)

    def test_health_mismatch_retries_once_then_fails(self):
        player = {"name": "Coalabone", "health": 90, "max_health": 100, "auras": []}
        probe_answers = {
            "state": {"result": {"player": {"health": 100, "maxHealth": 100}}},
            "auras player": {"result": {"auras": []}},
            "errors": {"result": {"source": "ERROR_HANDLER_DATABASE"}},
        }
        calls = {"state": 0}

        def probe(descriptor, line):
            if line == "state":
                calls["state"] += 1
            return probe_answers[line]

        with patch.object(lab_run.lab_memory, "find_lab_client_pid", return_value=4242), \
                patch.object(lab_run.lab_memory, "read_active_player", return_value=player), \
                patch.object(lab_run.lab_relay, "probe", side_effect=probe):
            checks, output = self.run_checks(DESCRIPTOR)
        self.assertEqual(calls["state"], lab_run.MEMORY_SAMPLE_RETRIES + 1)
        self.assertIn("FAIL: memory player health and max health equal probe state", output)

    def test_health_mismatch_recovers_on_retry(self):
        samples = [{"health": 90, "max_health": 100, "name": "Coalabone", "auras": []},
                   {"health": 100, "max_health": 100, "name": "Coalabone", "auras": []}]
        probe_answers = {"state": {"result": {"player": {"health": 100, "maxHealth": 100}}}}

        def read_active_player(pid):
            return samples.pop(0)

        with patch.object(lab_run.lab_memory, "find_lab_client_pid", return_value=4242), \
                patch.object(lab_run.lab_memory, "read_active_player", side_effect=read_active_player), \
                patch.object(lab_run.lab_relay, "probe", side_effect=lambda descriptor, line: probe_answers[line]):
            checks = lab_run.Checks()
            with redirect_stdout(io.StringIO()) as output:
                lab_run.check_memory_health(DESCRIPTOR, 4242, checks)
        self.assertEqual(checks.failures, 0)
        self.assertIn("PASS: memory player health and max health equal probe state", output.getvalue())

    def test_probe_errors_reports_the_wrong_source(self):
        with patch.object(lab_run.lab_relay, "probe", return_value={"result": {"source": "OWN_HANDLER"}}):
            checks = lab_run.Checks()
            with redirect_stdout(io.StringIO()) as output:
                lab_run.check_probe_errors(DESCRIPTOR, checks)
        self.assertEqual(checks.failures, 1)
        self.assertIn("FAIL: probe errors answers without error with source ERROR_HANDLER_DATABASE (OWN_HANDLER)",
                      output.getvalue())
