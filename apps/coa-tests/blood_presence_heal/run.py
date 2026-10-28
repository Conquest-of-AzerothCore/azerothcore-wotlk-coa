CLI_DESCRIPTION = """Check that Blood Presence heals for its percent of damage dealt on Ascension's Spell.dbc, without a server.

Stock 63611 Improved Blood Presence Triggered carries its proc aura in effect 1; Ascension's carries it in effect 0
and leaves effect 1 empty, so a handler bound to EFFECT_1 never runs and Blood Presence never heals. This checks that
shape in Spell.dbc (--dbc-dir), the tooltip's 5% of health cap, and that spell_dk.cpp binds the handler to the effect
that carries the aura, caps the heal and passes the talent's retained amount to that effect.
No database, server build or game client is needed.
"""

import argparse
from pathlib import Path
import re
import struct
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402

SOURCE = ROOT / "src/server/scripts/Spells/spell_dk.cpp"

EFFECT, BASE, AURA, DESCRIPTION = 71, 80, 95, 170
APPLY_AURA, PROC_TRIGGER_SPELL = 6, 42
BLOOD_PRESENCE, BLOOD_PRESENCE_TRIGGERED = 48266, 63611

failures = 0


def check(value, name):
    global failures
    failures += not value
    print(("PASS" if value else "FAIL") + ": " + name)


def load_spells(directory):
    raw = (directory / "Spell.dbc").read_bytes()
    count, fields, size, _ = struct.unpack_from("<IIII", raw, 4)
    strings = raw[20 + count * size:]
    rows = {row[0]: row for row in struct.iter_unpack(f"<{fields}i", raw[20:20 + count * size])}
    return rows, lambda offset: strings[offset:strings.index(b"\0", offset)].decode("utf-8", "replace")


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    spells, text = load_spells(args.dbc_dir or dbc_dir())

    triggered = spells[BLOOD_PRESENCE_TRIGGERED]
    check(triggered[EFFECT] == APPLY_AURA and triggered[AURA] == PROC_TRIGGER_SPELL and triggered[EFFECT + 1] == 0,
          "63611 carries its proc aura in effect 0 and has no effect 1")
    tooltip = text(spells[BLOOD_PRESENCE][DESCRIPTION])
    check("$63611s1% of your damage dealt" in tooltip and "maximum of 5% of your health per hit" in tooltip,
          "Blood Presence's tooltip heals a percent of damage dealt, at most 5% of health per hit")

    source = SOURCE.read_text(encoding="utf-8")
    script = source.split("class spell_dk_improved_blood_presence_triggered", 1)[-1].split("\n};", 1)[0]
    check("HandleProc, EFFECT_FIRST_FOUND, SPELL_AURA_PROC_TRIGGER_SPELL" in script,
          "the heal handler binds to whichever effect carries the proc aura")
    check("BLOOD_PRESENCE_HEAL_MAX_HEALTH_PCT = 5;" in source and
          "CountPctFromMaxHealth(BLOOD_PRESENCE_HEAL_MAX_HEALTH_PCT)" in script, "the heal is capped at 5% of max health")
    casts = re.findall(r"CastCustomSpell\(SPELL_DK_IMPROVED_BLOOD_PRESENCE_TRIGGERED, (\w+)\(?\)?,", source)
    check(len(casts) == 2 and all(mod == "ImprovedBloodPresenceAmountMod" for mod in casts),
          "the talent's retained healing goes to the effect that carries the proc aura")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
