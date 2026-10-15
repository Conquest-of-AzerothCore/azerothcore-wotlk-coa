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
HERE = Path(__file__).resolve().parent


def main():
    method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']
    code = (HERE.parent / 'bloodmage_hemostasis/harness.cpp').read_text().split('// SOURCE')[0]
    code = code.replace('// ENUMS', '''
constexpr uint32 CLASS_RANGER = 21, EFFECT_1 = 1, SPELL_EFFECT_TRIGGER_SPELL = 64,
    AURA_STATE_BLEEDING = 1, ALLSPELLHOOK_ON_BEFORE_EFFECTS = 3;
// ENUMS
''')
    code = code.replace('bool IsAlive() const', 'bool bleeding = false;\nbool HasAuraState(uint32) const { return bleeding; }\nbool IsAlive() const')
    code = code.replace('uint32 cls = 20;', 'uint32 cls = 21;')
    code = code.replace('struct SpellScript\n{', '''struct SpellScript
{
    SpellInfo fixtureInfo;
    SpellInfo const* GetSpellInfo() { return &fixtureInfo; }
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual bool Load() { return true; }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }''')
    code = code.replace('struct AuraScript\n{', 'struct AuraScript\n{\nAura* fixtureAura = nullptr;\nAura* GetAura() { return fixtureAura; }')
    code = code.replace('assert(index == 2);', 'assert(index == 1);')
    code = code.replace('virtual bool CanPrepare(', '''
    virtual void OnSpellBeforeEffects(Spell*, Unit*, SpellInfo const*) { }
    virtual bool CanPrepare(''')
    source = (ROOT / 'src/server/coa/AscensionRangerHookshot.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    source = re.sub(r'(: public (?:AuraScript|SpellScript)\n\{)', r'\1\npublic:', source)
    code += source + (HERE / 'cases.cpp').read_text()
    player = (ROOT / 'src/server/game/Entities/Player/Player.cpp').read_text()
    code = code.replace('// NATIVE', method(player, 'void Player::SetTemporarySpellReplacement(') + '\n' +
                        method(player, 'uint32 Player::GetTemporarySpellReplacement('))
    enums = (ROOT / 'src/server/game/Spells/SpellInfo.h').read_text()
    code = code.replace('// ENUMS', method(enums, 'enum SpellCustomAttributes') + ';')
    with tempfile.TemporaryDirectory(prefix='coa-hookshot-') as directory:
        out = Path(directory)
        cpp, exe = out / 'hook.cpp', out / 'hook.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ranks = {800360, 802394, 802395, 802396, 802397, 802398}
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20 + count * 936])
            if r[0] in ranks | {803852, 803857, 803858}}
    assert all(rows[sid][117] == 803857 and rows[sid][29] == 25000 for sid in ranks)
    assert rows[803857][40] == 28 and rows[803852][29] == 0
    assert rows[803852][71:74] == (31, 64, 121) and rows[803852][80] + rows[803852][74] == 300
    assert rows[803852][117] == 803858 and rows[803858][71] == 96
    print('PASS: six ranks, bleeding latch, original target, native buttons, expiry, rank replacement and spell ownership')


if __name__ == '__main__':
    main()
