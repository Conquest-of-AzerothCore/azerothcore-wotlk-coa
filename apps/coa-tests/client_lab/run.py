CLI_DESCRIPTION = """Check a running client lab through the server probe relay, then through the lab client's own
process memory.

Reads the lab descriptor written by the guide's `coa-client-lab login ACCOUNT PASSWORD CHARACTER`, then asks the
lab client's CoaProbe addon for spell 501281 three times over SOAP `.labprobe` (each answer within 5 s, one UI
load, tooltip line 1 equal to the server DBC spell name) and checks two refusals. It verifies the deployed lab
slot, not the build stage's binary. See docs/coa/client-lab-probe-relay.md.

It then reads the lab client process's own memory (process_vm_readv, read only) and checks it against the
relay: the active player name and health/max health match `probe state`, every aura `probe auras` lists is in
the memory aura array (memory also holds auras the UI hides, such as SPELL_ATTR5_NO_CASTER_AURA_ICON ones),
and `probe errors` answers through ERROR_HANDLER_DATABASE. The descriptor needs `client_dir` and
`worldserver_conf`, written by a guide new enough to carry them; an older descriptor reports one FAIL line and
the relay checks still run. See docs/coa/client-lab-memory.md.
"""

import argparse
from datetime import datetime
import importlib.util
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SPELL = 501281
UNKNOWN_SPELL = 999999999
PROBES = 3
MAX_ELAPSED_MS = 5000

spec = importlib.util.spec_from_file_location("coa_lab_relay", HERE / "lab_relay.py")
lab_relay = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lab_relay)

memory_spec = importlib.util.spec_from_file_location("coa_lab_memory", HERE / "lab_memory.py")
lab_memory = importlib.util.module_from_spec(memory_spec)
memory_spec.loader.exec_module(lab_memory)

MEMORY_DESCRIPTOR_KEYS = ("client_dir", "worldserver_conf")
MEMORY_SAMPLE_RETRIES = 1


def spell_name(dbc_dir, spell):
    sys.path.insert(0, str(ROOT / "apps/coa-dbc"))
    import inspect_dbc
    with tempfile.TemporaryDirectory(prefix="coa-client-lab-") as directory:
        shutil.copyfile(Path(dbc_dir) / "Spell.dbc", Path(directory) / "Spell.dbc")
        record = inspect_dbc.DataSet(directory).record("Spell", spell)
    return next(field["value"] for field in record["fields"] if field["name"] == "SpellName[enUS]")


def preflight_problem(descriptor):
    if descriptor["preflight"] != "pass":
        return f"lab preflight is {descriptor['preflight']!r}"
    if descriptor["preflight_slot"] != descriptor["slot"]:
        return f"lab preflight was recorded for slot {descriptor['preflight_slot']}, not slot {descriptor['slot']}"
    try:
        checked = datetime.fromisoformat(descriptor["preflight_time"])
        deployed = datetime.fromisoformat(descriptor["deployed_at"])
    except (TypeError, ValueError):
        return (f"lab preflight time {descriptor['preflight_time']!r} or deploy time "
                f"{descriptor['deployed_at']!r} is unreadable")
    if checked < deployed:
        return f"lab preflight ({descriptor['preflight_time']}) is older than the deploy ({descriptor['deployed_at']})"
    return None


def checkout_head():
    result = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "HEAD"], capture_output=True, text=True)
    return result.stdout.strip() or "unknown"


class Checks:
    def __init__(self):
        self.failures = 0

    def check(self, value, name, detail=""):
        self.failures += not value
        print(f"{'PASS' if value else 'FAIL'}: {name}{f' ({detail})' if detail and not value else ''}")


def run_checks(descriptor, expected_name, checks):
    answers = [lab_relay.probe(descriptor, f"spell {SPELL}") for _ in range(PROBES)]
    for index, answer in enumerate(answers, 1):
        print(f"probe {index}: elapsed_ms={answer.get('elapsed_ms')} loadId={answer.get('loadId')}")
        checks.check(answer.get("error") is None, f"probe {index} answered without error", answer.get("error"))
        checks.check(answer.get("elapsed_ms", MAX_ELAPSED_MS + 1) <= MAX_ELAPSED_MS,
                     f"probe {index} answered within {MAX_ELAPSED_MS} ms", answer.get("elapsed_ms"))
        tooltip = (answer.get("result") or {}).get("tooltip") or [{}]
        checks.check(tooltip[0].get("left") == expected_name, f"probe {index} tooltip line 1 is {expected_name!r}",
                     tooltip[0].get("left"))
    load_ids = {answer.get("loadId") for answer in answers}
    checks.check(len(load_ids) == 1 and None not in load_ids, "all answers come from one UI load", load_ids)

    unknown = lab_relay.probe(descriptor, f"spell {UNKNOWN_SPELL}")
    checks.check(unknown.get("error") == f"unknown spell {UNKNOWN_SPELL}", "unknown spell is reported",
                 unknown.get("error"))

    password = Path(descriptor["soap_password_file"]).read_text(encoding="utf-8").strip()
    try:
        output = lab_relay.soap_execute(descriptor["soap_url"], descriptor["soap_account"], password,
                                        f".labprobe send {descriptor['character']} r1 eval 1")
        checks.check(False, "eval is refused by the relay", output)
    except lab_relay.SoapFault as fault:
        checks.check("not a read-only probe request" in str(fault), "eval is refused by the relay", fault)


def check_memory_guards(descriptor, checks):
    try:
        pid = lab_memory.find_lab_client_pid(descriptor)
    except lab_memory.GuardError as error:
        checks.check(False, "memory guards pass for the lab client process", error)
        return None
    checks.check(True, "memory guards pass for the lab client process", f"pid {pid}")
    return pid


def check_memory_player_name(descriptor, pid, checks):
    if pid is None:
        checks.check(False, "memory active player name equals the descriptor character", "no lab client pid")
        return
    try:
        name = lab_memory.read_active_player(pid)["name"]
    except lab_memory.MemoryError_ as error:
        checks.check(False, "memory active player name equals the descriptor character", error)
        return
    checks.check(name == descriptor["character"], "memory active player name equals the descriptor character", name)


def check_memory_health(descriptor, pid, checks):
    if pid is None:
        checks.check(False, "memory player health and max health equal probe state", "no lab client pid")
        return
    detail = "no sample taken"
    for _attempt in range(MEMORY_SAMPLE_RETRIES + 1):
        answer = lab_relay.probe(descriptor, "state")
        try:
            player = lab_memory.read_active_player(pid)
        except lab_memory.MemoryError_ as error:
            checks.check(False, "memory player health and max health equal probe state", error)
            return
        probed = (answer.get("result") or {}).get("player") or {}
        detail = (f"probe health={probed.get('health')}/{probed.get('maxHealth')} "
                  f"memory={player['health']}/{player['max_health']}")
        if (answer.get("error") is None and probed.get("health") == player["health"]
                and probed.get("maxHealth") == player["max_health"]):
            checks.check(True, "memory player health and max health equal probe state", detail)
            return
    checks.check(False, "memory player health and max health equal probe state", detail)


def check_memory_auras(descriptor, pid, checks):
    if pid is None:
        checks.check(False, "memory active aura spell ids include probe auras player", "no lab client pid")
        return
    detail = "no sample taken"
    for _attempt in range(MEMORY_SAMPLE_RETRIES + 1):
        answer = lab_relay.probe(descriptor, "auras player")
        try:
            player = lab_memory.read_active_player(pid)
        except lab_memory.MemoryError_ as error:
            checks.check(False, "memory active aura spell ids include probe auras player", error)
            return
        probed_ids = {aura.get("spellId") for aura in (answer.get("result") or {}).get("auras") or []}
        memory_ids = {aura["spell_id"] for aura in player["auras"]}
        detail = f"probe={sorted(probed_ids)} memory={sorted(memory_ids)} memory_only={sorted(memory_ids - probed_ids)}"
        if answer.get("error") is None and probed_ids <= memory_ids:
            checks.check(True, "memory active aura spell ids include probe auras player", detail)
            return
    checks.check(False, "memory active aura spell ids include probe auras player", detail)


def check_probe_errors(descriptor, checks):
    answer = lab_relay.probe(descriptor, "errors")
    result = answer.get("result") or {}
    checks.check(answer.get("error") is None and result.get("source") == "ERROR_HANDLER_DATABASE",
                 "probe errors answers without error with source ERROR_HANDLER_DATABASE",
                 answer.get("error") or result.get("source"))


def run_memory_checks(descriptor, checks):
    missing = [key for key in MEMORY_DESCRIPTOR_KEYS if not descriptor.get(key)]
    if missing:
        checks.check(False, "lab descriptor carries the memory diagnostics keys", f"missing {', '.join(missing)}")
    else:
        pid = check_memory_guards(descriptor, checks)
        check_memory_player_name(descriptor, pid, checks)
        check_memory_health(descriptor, pid, checks)
        check_memory_auras(descriptor, pid, checks)
    check_probe_errors(descriptor, checks)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--client-lab", type=Path, required=True)
    parser.add_argument("--dbc-dir", type=Path, required=True)
    args = parser.parse_args()
    descriptor = lab_relay.load_descriptor(args.client_lab)
    print(f"lab slot {descriptor['slot']}, deployed {descriptor['deployed_commit']}, checkout {checkout_head()}, "
          f"character {descriptor['character']}")
    problem = preflight_problem(descriptor)
    if problem:
        print(f"FAIL: {problem}; run coa-client-lab preflight N")
        return 1
    checks = Checks()
    try:
        run_checks(descriptor, spell_name(args.dbc_dir, SPELL), checks)
        run_memory_checks(descriptor, checks)
    except (lab_relay.SoapFault, TimeoutError, OSError, ValueError, KeyError, StopIteration) as error:
        checks.check(False, "relay reachable", error)
    print(f"client lab: {checks.failures} failure(s)")
    return 1 if checks.failures else 0


if __name__ == "__main__":
    sys.exit(main())
