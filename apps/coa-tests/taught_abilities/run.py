CLI_DESCRIPTION = """Check reviewed talent grants and native temporary spell ownership without a server.

Extracts the actual service, callbacks and Player spell-map/save code. Skill,
achievement, aura, rank and packet APIs are bounded dependencies; this is not a
combat test. --dbc-dir checks the grants against the talent catalog the module loads from the
client DBCs; --spell-dbc additionally checks authored teaching and transformation clauses;
--trainer-policy checks the captured level gates of replacement ranks.
"""

import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]
catalog_text = runpy.run_path(str(HERE.parent / "coa_talent_catalog.py"))["catalog_text"]
NEW_GRANTS = {804729: 804834, 561069: 801662, 92097: 804019, 92114: 800157,
              92119: 806291, 92131: 520326, 680750: 567524}
ARCHIVED_NODES = {707717: 707876}
REPLACEMENT_ROOTS = {
    (14, 9, 520853, 500028): 500610,
    (17, 18, 570727, 801059): 802581,
    (17, 17, 301302, 801016): 804353,
    (17, 17, 706755, 804883): 707666,
    (16, 13, 707615, 800227): 802354,
    (16, 13, 707615, 500040): 801839,
    (16, 14, 560020, 804020): 807105,
    (16, 14, 560020, 500040): 804017,
    (16, 13, 704222, 526362): 704201,
    (20, 25, 505188, 562720): 680692,
    (20, 26, 504728, 562720): 801076,
    (20, 27, 504710, 562720): 562572,
    (22, 32, 707430, 520175): 801291,
    (22, 33, 804478, 804418): 561284,
    (30, 56, 805708, 500376): 572382,
    (30, 56, 504269, 803985): 807234,
}


def check_data(header, catalog, replacement_header, dbc, trainer):
    entries = [tuple(map(int, row)) for row in
               re.findall(r"\{ (\d+), (\d+), (\d+), (\d+), (\d+) \}", header)]
    nodes = [tuple(map(int, re.findall(r"\d+", line))) for line in (catalog or "").splitlines()
             if line.startswith("    {")]
    assert entries and len({entry[4] for entry in entries}) == len(entries), "Child ownership must be unique"
    assert not {entry[3] for entry in entries} & {entry[4] for entry in entries}, "Grant callbacks must not cycle"
    assert {entry[4]: entry[3] for entry in entries if entry[4] in ARCHIVED_NODES} == ARCHIVED_NODES
    for cls, spec, level, parent, child in entries if catalog else ():
        archived = child in ARCHIVED_NODES
        assert not archived or not any(len(node) == 10 and child in node[7:] for node in nodes), child
        assert any(len(node) == 10 and node[1] == cls and node[2] == spec and
                   (node[6] <= level if archived else node[6] == level) and parent in node[7:]
                   for node in nodes), (cls, spec, level, parent)
    replacements = []
    replacement_roots = {}
    for cls, spec, parent, original, body in re.findall(
            r"\{ (\d+), (\d+), (\d+), (\d+), \{\{(.*?)\}\} \}", replacement_header, re.S):
        ranks = [tuple(map(int, pair)) for pair in re.findall(r"\{ (\d+), (\d+) \}", body)]
        cls, spec, parent, original = map(int, (cls, spec, parent, original))
        assert not catalog or any(len(node) == 10 and node[1] == cls and node[2] == spec and parent in node[7:]
                                  for node in nodes)
        assert ranks and ranks[0][1] == 0 and sorted(ranks, key=lambda rank: rank[1]) == ranks
        key = cls, spec, parent, original
        assert key not in replacement_roots, f"Duplicate replacement route: {key}"
        replacement_roots[key] = ranks[0][0]
        replacements.append((cls, parent, original, ranks))
    assert replacement_roots == REPLACEMENT_ROOTS, (replacement_roots, REPLACEMENT_ROOTS)
    children = {spell for _, _, _, ranks in replacements for spell, _ in ranks}
    assert not children & {value for _, parent, original, _ in replacements for value in (parent, original)}
    assert not children & {entry[4] for entry in entries}, "Replacement and taught ownership must be disjoint"
    if trainer:
        import json
        policy = json.loads(trainer.read_text(encoding="utf-8"))
        for cls, _, _, ranks in replacements:
            captured = {row["spell_id"]: row for row in policy["classes"][str(cls)]["conditional_acquisition"]}
            for spell, level in ranks[1:]:
                row = captured[spell]
                assert row["required_level"] == level
                assert row["reasons"] == ["rank-one-root-identity-or-acquisition-not-proven"]
                assert row["skill_requirement_evidence"]["status"] == "satisfied-by-fixed-level-one-class-skill"
    if not dbc:
        return
    raw = dbc.read_bytes()
    magic, count, fields, size, strings_size = struct.unpack_from("<4s4I", raw)
    assert magic == b"WDBC" and fields == 234 and size == 936
    strings_at = 20 + count * size
    assert len(raw) == strings_at + strings_size
    wanted = set(NEW_GRANTS) | set(NEW_GRANTS.values()) | {674, 801343, 578118, 680263}
    for _, parent, original, ranks in replacements:
        wanted.update([parent, original, *(spell for spell, _ in ranks)])
    rows = {row[0]: row for row in struct.iter_unpack("<234I", raw[20:strings_at]) if row[0] in wanted}

    assert rows[801343][71] == 56 and rows[801343][110] == 50124
    assert rows[578118][208] == 21 and rows[578118][71] == 109
    assert rows[680263][208] == 21 and rows[680263][71] == 102

    def text(offset):
        start = strings_at + offset
        return raw[start:raw.index(b"\0", start)].decode("utf-8")

    for parent, child in NEW_GRANTS.items():
        row = rows[parent]
        description = text(row[170])
        assert "Teaches" in description and f"@s:{child}:0@" in description, parent
        assert not rows[child][4] & 64, f"{child} is a passive, not an active taught ability"
        assert 36 not in row[71:74], f"{parent} already has native LEARN_SPELL"
    assert "dual wield" in text(rows[92114][170])
    assert rows[674][71:74] == (40, 0, 0) and rows[674][4] & 64
    for _, parent, original, ranks in replacements:
        root = rows[ranks[0][0]]
        description = text(rows[parent][170])
        assert f"@s:{root[0]}:0@" in description and text(rows[original][136]) in description, parent
        assert rows[parent][208] == (27 if parent == 804478 else root[208]), parent
        for spell, level in ranks:
            row = rows[spell]
            assert not row[4] & 64 and row[208] == root[208] == rows[original][208], spell
            assert text(row[136]) == text(root[136]) and (not level or row[39] == level)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Read production source from a local Git ref for a negative control.")
    parser.add_argument("--service-ref", help="Use an older class service with current policy to test missing routing.")
    parser.add_argument("--dbc-dir", type=Path)
    parser.add_argument("--spell-dbc", type=Path)
    parser.add_argument("--trainer-policy", type=Path)
    args = parser.parse_args()

    def source(path):
        if args.source_ref:
            return git_source(["git", "show", f"{args.source_ref}:{path}"], cwd=ROOT).decode("utf-8")
        return (ROOT / path).read_text(encoding="utf-8")

    service = source("src/server/coa/AscensionCompat.cpp")
    if args.service_ref:
        service = git_source(["git", "show",
            f"{args.service_ref}:src/server/coa/AscensionCompat.cpp"], cwd=ROOT).decode("utf-8")
    header = source("src/server/coa/AscensionTaughtAbilityData.h")
    replacement_header = (ROOT / "src/server/coa/AscensionTalentReplacementData.h").read_text()
    check_data(header, catalog_text(args.dbc_dir) if args.dbc_dir else None, replacement_header,
               args.spell_dbc, args.trainer_policy)
    player = source("src/server/game/Entities/Player/Player.cpp")
    player_header = source("src/server/game/Entities/Player/Player.h")
    storage = source("src/server/game/Entities/Player/PlayerStorage.cpp")
    add = method(player, "bool Player::_addSpell(")
    add = add[:add.index("    if (!((1 << GetActiveSpec()) & addSpecMask))")] + "    return true;\n}"
    remove = method(player, "void Player::removeSpell(")
    remove = remove[:remove.index("    RemoveOwnedAura(spell_id);")]
    remove += "    sScriptMgr->OnPlayerForgotSpell(this, spell_id);\n}"
    replacement_service = "\n".join(method(service, signature) for signature in (
        "bool AffectsTalentReplacements(", "uint32 SynchronizeTalentReplacements(")) if (
            "uint32 SynchronizeTalentReplacements(" in service) else (
                "bool AffectsTalentReplacements(uint32) const { return false; }\n"
                "uint32 SynchronizeTalentReplacements(Player*) { return 0; }")
    harness = (HERE / "harness.cpp").read_text(encoding="utf-8")
    for marker, code in (
        ("CLASSES", method(source("src/server/shared/SharedDefines.h"), "enum Classes\n") + ";"),
        ("STATE", method(player_header, "enum PlayerSpellState") + ";"),
        ("SPELL_RECORD", method(player_header, "struct PlayerSpell\n") + ";"),
        ("DATA", header + "\n" + replacement_header),
        ("SERVICE", "\n".join(method(service, signature) for signature in (
            "bool AffectsTaughtAbilities(", "uint32 SynchronizeTaughtAbilities(",
            "uint32 GetActiveSpecialization(")) + "\n" + replacement_service),
        ("HOOKS", "\n".join(method(service, signature).replace(" override", "") for signature in (
            "void OnPlayerLearnSpell(", "void OnPlayerForgotSpell(", "void OnPlayerAfterSpecSlotChanged("))),
        ("PLAYER", "\n".join((add, remove, method(player, "void Player::learnSpell("),
            method(player, "void Player::learnSpellWithoutAnnouncement("),
            method(player, "void Player::_learnSpell("),
            method(player, "bool Player::HasSpell("), method(player, "bool Player::HasActiveSpell("),
            method(storage, "void Player::_SaveSpells("), method(player, "void Player::SetTemporarySpellReplacement("),
            method(player, "uint32 Player::GetTemporarySpellReplacement(")))),
    ):
        harness = harness.replace("// ACTUAL_" + marker, code)

    vc_tools = os.environ.get("VCToolsInstallDir")
    compiler = (str(Path(vc_tools) / "bin/Hostx64/x64/cl.exe") if vc_tools else
                shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++")))
    if not compiler:
        raise RuntimeError("Enable a C++20 compiler (VS Developer PowerShell on Windows).")
    with tempfile.TemporaryDirectory(prefix="coa-taught-") as directory:
        out = Path(directory)
        cpp = out / "harness.cpp"
        cpp.write_text(harness, encoding="utf-8")
        executable = out / ("taught.exe" if os.name == "nt" else "taught")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8",
                     str(cpp), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        subprocess.run([str(executable)], cwd=out, check=True)


if __name__ == "__main__":
    main()
