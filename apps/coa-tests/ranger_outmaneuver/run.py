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
    code = '#include <algorithm>\n' + (HERE.parent / 'runemaster_travel/harness.cpp').read_text().split('// ACTUAL_SOURCE')[0]
    code = code.replace('using uint8 =', 'using uint64 = std::uint64_t;\nusing AuraEffectHandleModes = uint32_t;\nusing uint8 =')
    code = code.replace('uint32 value = 0;', '''uint64 value = 0;
    ObjectGuid(uint64 raw = 0) : value(raw) { }
    uint64 GetRawValue() const { return value; }''', 1)
    code = code.replace('struct SpellImplicitTargetInfo', 'using WorldLocation = Position;\nstruct SpellImplicitTargetInfo', 1)
    code = code.replace('bool maskInitialized = false;', 'uint32 AttributesCu = 0;\nbool maskInitialized = false;')
    code = code.replace('struct Spell { bool triggered = false; bool IsTriggered() const { return triggered; } };', '''
struct Unit;
struct SpellCastTargets
{
    Unit* target = nullptr;
    void SetUnitTarget(Unit* value) { target = value; }
    Unit* GetUnitTarget() const { return target; }
};
struct Spell
{
    Unit* caster = nullptr;
    SpellInfo info;
    SpellCastTargets m_targets;
    Unit* GetCaster() const { return caster; }
    SpellInfo const* GetSpellInfo() const { return &info; }
};
''')
    code = code.replace('struct Aura\n{', '''struct Aura
{
    std::map<uint32, uint64> values;
    uint8 stacks = 1;
    uint64 GetScriptValue(uint32 key) const { auto it = values.find(key); return it == values.end() ? 0 : it->second; }
    void SetScriptValue(uint32 key, uint64 value) { values[key] = value; }
    void ModStackAmount(int32 amount) { stacks = uint8(std::min(20, int(stacks) + amount)); }
''')
    code = code.replace('virtual Player* ToPlayer()', 'Unit* ToUnit() { return this; }\nvirtual Player* ToPlayer()', 1)
    code = code.replace('bool alive = true, inWorld = true, samePhase = true, los = true;',
                        'bool alive = true, inWorld = true, samePhase = true, los = true, friendly = false;')
    code = code.replace('ObjectGuid GetGUID() const', '''
    bool IsValidAttackTarget(Unit* unit) const { return unit != this && !unit->friendly; }
    Aura* GetAura(uint32 id, ObjectGuid caster)
    { auto it = auras.find(id); return it != auras.end() && it->second.caster == caster ? &it->second : nullptr; }
    Aura* AddAura(uint32 id, Unit* target)
    { Aura& aura = target->auras[id]; aura.id = id; aura.caster = guid; return &aura; }
    ObjectGuid GetGUID() const''', 1)
    cast = method(code, 'void CastSpell(Unit* target, uint32 id, bool triggered)')
    code = code.replace(cast, '''void CastSpell(Unit* target, uint32 id, bool triggered)
    { assert(target && triggered); casts.push_back(id); }''')
    code = code.replace('virtual void UpdateAI(uint32) { }', 'virtual void UpdateAI(uint32) { }\nvirtual void JustDied(Unit*) { }')
    code = code.replace('Hook OnCheckCast, OnEffectHit, OnEffectHitTarget, OnEffectLaunchTarget;', '''
    Unit* hit = nullptr;
    WorldLocation fixtureDestination;
    Aura* hitAura = nullptr;
    Unit* GetHitUnit() { return hit; }
    Unit* GetExplTargetUnit() { return hit; }
    WorldLocation const* GetExplTargetDest() { return &fixtureDestination; }
    Aura* GetHitAura() { return hitAura; }
    Hook BeforeCast, AfterCast, OnHit, OnCheckCast, OnEffectHit, OnEffectHitTarget, OnEffectLaunchTarget;''')
    code += (HERE / 'support.cpp').read_text()
    source = (ROOT / 'src/server/coa/AscensionRangerOutmaneuver.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    source = re.sub(r'(: public (?:AuraScript|SpellScript)\n\{)', r'\1\npublic:', source)
    code += source + (HERE / 'cases.cpp').read_text()
    enums = []
    for path, names in [
        ('src/server/shared/SharedDefines.h', ['Classes', 'SpellEffects', 'Targets', 'SpellCastResult']),
        ('src/server/game/Spells/Auras/SpellAuraDefines.h', ['AuraRemoveMode']),
        ('src/server/game/Movement/MotionMaster.h', ['ForcedMovement']),
        ('src/server/game/Entities/Object/Object.h', ['TempSummonType']),
        ('src/server/game/Spells/SpellInfo.h', ['SpellCustomAttributes']),
    ]:
        text = (ROOT / path).read_text()
        enums.extend(method(text, 'enum ' + name) + ';' for name in names)
    code = code.replace('// NATIVE_ENUMS', '\n'.join(enums))
    player = (ROOT / 'src/server/game/Entities/Player/Player.cpp').read_text()
    code = code.replace('// NATIVE_REPLACEMENTS', method(player, 'void Player::SetTemporarySpellReplacement(') + '\n' +
                        method(player, 'uint32 Player::GetTemporarySpellReplacement('))
    with tempfile.TemporaryDirectory(prefix='coa-outmaneuver-') as directory:
        out = Path(directory)
        cpp, exe = out / 'decoy.cpp', out / 'decoy.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20 + count * 936]) if r[0] in {557325, 557326, 557328}}
    assert rows[557326][86] == 53 and rows[557326][110] == 50171
    assert rows[557325][89] == 65 and rows[557325][40] == rows[557326][40] == 31
    assert rows[557325][97] == 271 and rows[557325][82] + rows[557325][76] == 30
    assert rows[557325][49] == 20 and rows[557325][130] & rows[557328][211] != 0
    print('PASS: decoy at enemy position, native button, mark stacking, return after kill, expiry and failure cleanup')


if __name__ == '__main__':
    main()
