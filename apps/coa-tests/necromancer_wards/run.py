CLI_DESCRIPTION = """Exercise actual ward callbacks with bounded aura reapplication and caster targeting.

Reuses the workspace Necromancer fixture. Compiles only an isolated test executable,
without building the server or changing installed data. --source-ref reproduces #108.
"""

import argparse
import importlib.util
from pathlib import Path
import re
import struct
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).parent


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--source-ref")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location(
        "necro_fixture", args.workspace_tools / "Test-NecromancerCompletion.py")
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    fixture.REPO = ROOT
    fixture.MODULE = ROOT / "src/server/coa"
    fixture.CORE = ROOT / "src/server/game"
    path = "src/server/coa/AscensionNecromancerAuras.cpp"
    source = (git_source(["git", "show", f"{args.source_ref}:{path}"], cwd=ROOT).decode()
              if args.source_ref else (ROOT / path).read_text(encoding="utf-8"))
    production = "\n".join(re.findall(r"enum \w+\s*\{[^}]+\};", source))
    production += "\nstruct Lifecycle : Context { int32 _cost = 0; bool _expired = false;\n"
    production += "\n".join(fixture.fn(source, name) for name in ("First", "Apply", "Removed")) + "\n};\n"
    spell = (fixture.CORE / "Spells/Spell.cpp").read_text(encoding="utf-8")
    target_selection = fixture.fn(spell, "Spell::SelectImplicitCasterObjectTargets")
    assert re.search(r"case TARGET_UNIT_CASTER:\s*target = m_caster;", target_selection)
    unit = (fixture.CORE / "Entities/Unit/Unit.cpp").read_text(encoding="utf-8")
    add_aura = fixture.extract(unit, r"Aura\* Unit::AddAura\(SpellInfo const\*")
    assert "TryRefreshStackOrCreate(spellInfo, effMask, target, this)" in add_aura
    aura = (fixture.CORE / "Spells/Auras/SpellAuras.cpp").read_text(encoding="utf-8")
    assert "ChangeAmount(m_effects[i]->CalculateAmount(caster), false, true)" in fixture.fn(
        aura, "Aura::SetStackAmount")
    assert "AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK" in fixture.fn(source, "Register")
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        magic, count, fields, size, _ = struct.unpack_from("<4s4I", raw)
        assert magic == b"WDBC" and fields == 234 and size == 936
        rows = {row[0]: row for row in struct.iter_unpack("<234I", raw[20:20 + count * size])}
        for spell_id in (680388, 681460, 681529):
            row = rows[spell_id]
            assert row[208] == 29
            assert all(row[86 + i] == 1 and row[89 + i] == 0 for i in range(3) if row[71 + i])

    original_read = fixture.read

    def read(path):
        code = original_read(path)
        if path.name != "NecromancerCompletionHarness.cpp":
            return code
        code = "#include <iostream>\n#include <stdexcept>\n" + code
        for pattern, replacement in (
            (r" Aura\* AddAura\(uint32 id,Unit\* target\)[^\n]+", " Aura* AddAura(uint32 id, Unit* target);"),
            (r" void CastSpell\(Unit\* t,uint32 id,bool\)[^\n]+", " void CastSpell(Unit* t, uint32 id, bool);"),
            (r" void RemoveAurasDueToSpell\(uint32 id,ObjectGuid caster=\{\}\)[^\n]+",
             " void RemoveAurasDueToSpell(uint32 id, ObjectGuid caster = {});"),
            (r"Aura\* GetAura\(\)\{return &fixtureAura;\}",
             "Aura* GetAura(){ auto a=fixtureOwner->GetAura(fixtureId); return a?a:&fixtureAura; }"),
            (r"int32 GetDuration\(\)const\{return fixtureAura.duration;\}",
             "int32 GetDuration()const{ auto a=fixtureOwner->GetAura(fixtureId); "
             "return a?a->duration:fixtureAura.duration; }"),
        ):
            code, count = re.subn(pattern, lambda _: replacement, code)
            assert count == 1, pattern
        return code

    fixture.read = read
    with tempfile.TemporaryDirectory(prefix="coa-necromancer-wards-") as directory:
        fixture.native.OUT = Path(directory)
        fixture.Tests().run_cpp("necromancer-wards", production, HERE.joinpath("cases.cpp").read_text())
    print("PASS: ward application, refresh, switching, removal, ownership and bounded recursion regression")


if __name__ == "__main__":
    main()
