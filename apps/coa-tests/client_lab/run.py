CLI_DESCRIPTION = """Check a running client lab through the server probe relay.

Reads the lab descriptor written by the guide's `coa-client-lab login ACCOUNT PASSWORD CHARACTER`, then asks the
lab client's CoaProbe addon for spell 501281 three times over SOAP `.labprobe` (each answer within 5 s, one UI
load, tooltip line 1 equal to the server DBC spell name) and checks two refusals. It verifies the deployed lab
slot, not the build stage's binary. See docs/coa/client-lab-probe-relay.md.
"""

import argparse
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


def spell_name(dbc_dir, spell):
    sys.path.insert(0, str(ROOT / "apps/coa-dbc"))
    import inspect_dbc
    with tempfile.TemporaryDirectory(prefix="coa-client-lab-") as directory:
        shutil.copyfile(Path(dbc_dir) / "Spell.dbc", Path(directory) / "Spell.dbc")
        record = inspect_dbc.DataSet(directory).record("Spell", spell)
    return next(field["value"] for field in record["fields"] if field["name"] == "SpellName[enUS]")


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


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--client-lab", type=Path, required=True)
    parser.add_argument("--dbc-dir", type=Path, required=True)
    args = parser.parse_args()
    descriptor = lab_relay.load_descriptor(args.client_lab)
    print(f"lab slot {descriptor['slot']}, deployed {descriptor['deployed_commit']}, checkout {checkout_head()}, "
          f"character {descriptor['character']}")
    if descriptor["preflight"] != "pass":
        print(f"FAIL: lab preflight is {descriptor['preflight']!r}; run coa-client-lab preflight N")
        return 1
    checks = Checks()
    try:
        run_checks(descriptor, spell_name(args.dbc_dir, SPELL), checks)
    except (lab_relay.SoapFault, TimeoutError, OSError) as error:
        checks.check(False, "relay reachable", error)
    print(f"client lab: {checks.failures} failure(s)")
    return 1 if checks.failures else 0


if __name__ == "__main__":
    sys.exit(main())
