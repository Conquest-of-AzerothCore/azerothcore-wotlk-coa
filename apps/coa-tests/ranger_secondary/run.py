import importlib.util
import os
from pathlib import Path
import re
import runpy
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]


def target_counts():
    path = ROOT.parent / 'tools/Test-AdditionalTargetContracts.py'
    spec = importlib.util.spec_from_file_location('ranger_native_targets', path)
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    base = fixture.base
    rows, _, reader = fixture.audit.installed()
    ids = [560966, 561184, 561185, 561186, 561187]
    mask = rows[801429][125:128]
    assert all(rows[sid][210] & mask[1] for sid in ids)
    definitions = 'struct Fixture { SpellInfo spell; SpellEffIndex index; uint32 bonus; std::vector<uint32> targets; };\n'
    definitions += 'std::array<Fixture, 5> fixtures = {{\n' + ',\n'.join(
        '{' + fixture.cpp_spell(rows[801429], reader) + ',EFFECT_1,' + str(stacks) + ',{' +
        ','.join(map(str, ids)) + '}}' for stacks in range(1, 6)) + '\n}};\n'
    definitions += 'std::array<SpellInfo, 5> targets = {{\n' + ',\n'.join(
        fixture.cpp_spell(rows[sid], reader) for sid in ids) + '\n}};\n'
    spell = (base.CORE / 'Spells/Spell.cpp').read_text()
    limit = base.extract(base.function(spell, 'Spell::SelectImplicitAreaTargets'),
                         r'if \(uint32 maxTargets = m_spellValue->MaxAffectedTargets\)')
    unit = (base.CORE / 'Entities/Unit/Unit.cpp').read_text()
    functions = [base.function(fixture.SOURCE.read_text(), 'ApplyAdditionalTargetContracts'),
                 base.function((base.CORE / 'Spells/SpellInfo.cpp').read_text(), 'SpellInfo::IsAffected'),
                 base.function((base.CORE / 'Spells/Auras/SpellAuraEffects.cpp').read_text(), 'AuraEffect::IsAffectedOnSpell'),
                 base.extract(unit, r'int32 Unit::GetTotalAuraModifier\(AuraType auraType, std::function<bool\(AuraEffect const\*\)> const& predicate\) const'),
                 base.extract(unit, r'int32 Unit::GetTotalAuraModifier\(AuraType first, AuraType second, std::function<bool\(AuraEffect const\*\)> const& predicate\) const'),
                 base.extract(unit, r'int32 Unit::GetTotalAuraModifierByAffectMask\([^)]*\) const')]
    containers = (ROOT / 'src/common/Utilities/Containers.h').read_text()
    resize = base.extract(containers, r'template<class C>\s+void RandomResize\(C& container, std::size_t requestedSize\)')
    code = (ROOT.parent / 'tools/tests/AdditionalTargetContractsHarness.cpp').read_text()
    code = code.replace('// ACTUAL_FUNCTIONS', '\n'.join(functions)).replace('// ACTUAL_TARGET_LIMIT', limit)
    code = code.replace('// ACTUAL_RESIZE', resize).replace('// ACTUAL_FIXTURES', definitions)
    code = code.replace('assert(errors == 54);', 'assert(errors == 45);')
    code = code.replace('int errors = 0;', 'constexpr uint32 SPELL_AURA_NONE = 0;\nint errors = 0;')
    code = code.replace('int32 GetAmount() const { return amount; }',
                        'int32 GetAmount() const { return amount; }\nuint32 GetEffIndex() const { return m_effIndex; }')
    code = code.replace('SpellInfo const*, uint32, int32, std::map', 'SpellInfo const*, uint32, uint32, int32, std::map')
    code = code.replace('int32 GetTotalAuraModifierByAffectMask',
                        'int32 GetTotalAuraModifier(AuraType, AuraType, std::function<bool(AuraEffect const*)> const&) const;\n'
                        'int32 GetTotalAuraModifierByAffectMask', 1)
    code = code.replace('6 modifier records, 15 target ranks', '5 stack counts, 5 Quills ranks')
    with tempfile.TemporaryDirectory(prefix='coa-quills-targets-') as directory:
        base.native.OUT = Path(directory)
        result = base.native.compile_run(code, 'quills-target-counts')
        assert result.returncode == 0, result.stdout + result.stderr
        print(result.stdout)


def main():
    method = runpy.run_path(str(ROOT / 'apps/coa-tests/client_compat/run.py'))['method']
    source = (ROOT / 'src/server/coa/AscensionRangerSecondary.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    source = source.replace(': public AuraScript\n{', ': public AuraScript\n{\npublic:')
    enums = (ROOT / 'src/server/game/Spells/SpellInfo.h').read_text()
    code = Path(__file__).with_name('harness.cpp').read_text().replace('// SOURCE', source)
    code = code.replace('// ENUMS', method(enums, 'enum SpellCustomAttributes') + ';')
    with tempfile.TemporaryDirectory(prefix='coa-ranger-secondary-') as directory:
        out = Path(directory)
        cpp, exe = out / 'ranger.cpp', out / 'ranger.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
        persistent = Path(__file__).with_name('persistent.cpp').read_text()
        effects = (ROOT / 'src/server/game/Spells/SpellEffects.cpp').read_text()
        cpp.write_text(persistent.replace('// NATIVE', method(effects, 'void Spell::EffectPersistentAA(')), encoding='utf-8')
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ids = {804329, 704337, 801429, 801700, 500616, 570167, 803104, 803105, 803106}
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20 + count * 936]) if r[0] in ids}
    assert all(rows[sid][49] == 5 for sid in (804329, 704337, 801429, 801700))
    assert rows[704337][80] + rows[704337][74] == 1000
    assert rows[500616][211] & rows[704337][124] != 0
    assert rows[570167][40] == 23 and rows[570167][4] & 0x4000000
    assert rows[803104][116] == 803105 and rows[803104][98] == 250 and rows[803104][40] == 36
    target_counts()
    print('PASS: owned Advantage stacks/cleanup, loaded stacks, bleed-hit guards and Branded exclusion')


if __name__ == '__main__':
    main()
