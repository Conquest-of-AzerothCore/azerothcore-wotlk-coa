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
    code = '#include <algorithm>\n' + code
    code = code.replace('using uint64 = std::uint64_t;', 'using uint64 = std::uint64_t;\nusing uint8 = std::uint8_t;')
    code = code.replace('// ENUMS', '''
constexpr uint32 CLASS_RANGER = 21, SPELL_AURA_PROC_TRIGGER_SPELL = 42,
    AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK = 3, ALLSPELLHOOK_ON_HIT_RESULT = 3,
    ALLSPELLHOOK_ON_BEFORE_EFFECTS = 4, SPELL_FAILED_CASTER_AURASTATE = 20, SPELL_MISS_NONE = 0;
// ENUMS
''')
    code = code.replace('struct Aura\n{', 'struct Aura\n{\nuint8 stacks = 0;\nuint8 GetStackAmount() const { return stacks; }')
    code = code.replace('bool HasAura(uint32 id, ObjectGuid owner)', '''
bool IsFriendlyTo(Unit* other) const { return other->friendly; }
bool HasAura(uint32 id) const
{ return std::any_of(auras.begin(), auras.end(), [id](auto const& entry) { return entry.first.first == id; }); }
bool HasAura(uint32 id, ObjectGuid owner)''')
    code = code.replace('return &other->auras[{id, guid}];', '''
auto& aura = other->auras[{id, guid}];
aura.stacks = uint8(std::min(2, int(aura.stacks) + 1)); return &aura;''')
    code = code.replace('uint32 cls = 20;', '''uint32 cls = 21;
std::vector<uint32> casts;
void CastSpell(Unit* target, uint32 id, bool triggered);''')
    code = code.replace('struct Spell\n{', '''struct Spell
{
    std::map<uint32, uint64> markers;
    bool triggered = false;
    bool IsTriggered() const { return triggered; }
    uint64 GetScriptValue(uint32 id) const { auto it = markers.find(id); return it == markers.end() ? 0 : it->second; }
    void SetScriptValue(uint32 id, uint64 value) { markers[id] = value; }''')
    code = code.replace('virtual bool CanPrepare(', '''
    virtual void OnSpellBeforeEffects(Spell*, Unit*, SpellInfo const*) { }
    virtual void OnSpellHitResult(Spell*, Unit*, uint8, uint32, uint32, bool) { }
    virtual bool CanPrepare(''')
    code += '''
struct SpellMgr
{
    std::map<uint32, uint32> roots;
    uint32 GetFirstSpellInChain(uint32 id) { auto it = roots.find(id); return it == roots.end() ? id : it->second; }
} manager;
SpellMgr* sSpellMgr = &manager;
'''
    source = (ROOT / 'src/server/coa/AscensionRangerDirtyFighter.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    source = source.replace(': public AuraScript\n{', ': public AuraScript\n{\npublic:')
    code += source + (HERE / 'cases.cpp').read_text()
    player = (ROOT / 'src/server/game/Entities/Player/Player.cpp').read_text()
    code = code.replace('// NATIVE', method(player, 'void Player::SetTemporarySpellReplacement(') + '\n' +
                        method(player, 'uint32 Player::GetTemporarySpellReplacement('))
    enums = (ROOT / 'src/server/game/Spells/SpellInfo.h').read_text()
    code = code.replace('// ENUMS', method(enums, 'enum SpellCustomAttributes') + ';')
    with tempfile.TemporaryDirectory(prefix='coa-dirty-fighter-') as directory:
        out = Path(directory)
        cpp, exe = out / 'fighter.cpp', out / 'fighter.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ids = {806978, 684329, 681787, 681235, 681786, 681498}
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20 + count * 936]) if r[0] in ids}
    assert rows[806978][34] == 0 and rows[684329][49] == 2 and rows[684329][40] == 9
    assert rows[681787][40] == 8 and rows[681235][117:119] == (681498, 681786)
    assert rows[681498][80] + rows[681498][74] == 10 and rows[681498][123] == rows[681235][210]
    assert rows[681786][71:73] == (64, 176) and rows[681786][116] == rows[681786][111] == 804329
    print('PASS: every second qualifying crit, counter expiry, native rank replacements, one use and ownership cleanup')


if __name__ == '__main__':
    main()
