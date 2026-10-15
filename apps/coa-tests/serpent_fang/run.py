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
    code = (HERE.parent / 'ranger_secondary/harness.cpp').read_text().split('// SOURCE')[0]
    code = code.replace('// ENUMS', 'constexpr uint32 CLASS_PROPHET = 29, TARGET_DEST_DEST = 87;\n' +
                        method((ROOT / 'src/server/game/Spells/SpellInfo.h').read_text(), 'enum SpellCustomAttributes') + ';')
    code = code.replace('struct SpellInfo', '''struct SpellImplicitTargetInfo
{
    uint32 target = 0;
    SpellImplicitTargetInfo(uint32 value = 0) : target(value) { }
};
struct SpellInfo''', 1)
    code = code.replace('bool UseRangedAttackPowerForDamage', '''
    struct Effect { SpellImplicitTargetInfo TargetA; } Effects[3];
    bool rebuilt = false;
    void _InitializeExplicitTargetMask() { rebuilt = true; }
    bool UseRangedAttackPowerForDamage''')
    code = code.replace('id == 801935', 'id == 560202')
    code = code.replace('uint32 cls = 21;', 'uint32 cls = 29;')
    code = code.replace('uint32 guid = 1;', '''uint32 guid = 1, map = 1;
    bool inWorld = true, phase = true;
    bool IsInWorld() const { return inWorld; }
    uint32 GetMap() const { return map; }
    bool InSamePhase(Unit* unit) const { return phase && unit->phase; }''')
    code = code.replace('assert(targets.unit && targets.unit->GetPosition() == targets.position);',
                        'assert(targets.unit == nullptr && values == nullptr);')
    code = code.replace('flares.emplace_back(targets.position, values->duration);',
                        'flares.emplace_back(targets.position, 0);')
    source = (ROOT / 'src/server/coa/AscensionVenomancerSerpentFang.cpp').read_text()
    code += re.sub(r'^#include.*\n', '', source, flags=re.M)
    progression = (ROOT / 'src/server/coa/AscensionSpellProgressionData.h').read_text()
    ranks = [800946] + [int(n) for n in re.findall(r'\{\s*29,\s*800946,\s*(\d+),', progression)]
    code += 'int main()\n{\n Player player; Unit enemy; enemy.guid=42; Spell spell; spell.caster=&player;\n'
    code += ' spell.info.SpellFamilyName=35; venomancer_serpent_fang hook;\n'
    code += ' for(uint32 id : {' + ','.join(str(n) + 'u' for n in ranks) + '})\n'
    code += r'''
    {
        manager.roots[id]=800946; spell.info.Id=id;
        for(bool triggered : {false,true}) for(bool alive : {false,true}) for(uint32 damage : {0u,100u})
        {
            player.flares.clear(); spell.markers.clear(); spell.triggered=triggered; enemy.alive=alive;
            hook.OnSpellHitResult(&spell,&enemy,0,damage,0,false);
            assert(player.flares.size()==1 && player.flares.back().first==enemy.guid);
            hook.OnSpellHitResult(&spell,&enemy,0,damage,0,false); assert(player.flares.size()==1);
        }
    }
    enemy.alive=true; spell.info.Id=800946;
    for(int guard=0;guard<8;++guard)
    {
        player.flares.clear(); spell.markers.clear();
        player.cls=guard==0?21:29; player.alive=guard!=1; player.inWorld=guard!=2;
        enemy.inWorld=guard!=3; enemy.friendly=guard==4; enemy.map=guard==5?2:1; enemy.phase=guard!=6;
        hook.OnSpellHitResult(&spell,&enemy,guard==7?1:0,100,0,false); assert(player.flares.empty());
    }
    player.cls=29; player.alive=player.inWorld=true;
    enemy.inWorld=enemy.phase=true; enemy.friendly=false; enemy.map=1;
    spell.info.Id=560202; spell.markers.clear(); hook.OnSpellHitResult(&spell,&enemy,0,100,0,false);
    assert(player.flares.empty());
    venomancer_serpent_fang_metadata metadata; SpellInfo info; info.Id=560202; info.SpellFamilyName=35;
    metadata.OnLoadSpellCustomAttr(&info); assert(info.rebuilt && info.Effects[0].TargetA.target==TARGET_DEST_DEST);
    info.rebuilt=false; info.SpellFamilyName=27; metadata.OnLoadSpellCustomAttr(&info); assert(!info.rebuilt);
}
'''
    with tempfile.TemporaryDirectory(prefix='coa-serpent-fang-') as directory:
        out = Path(directory)
        cpp, exe = out / 'fang.cpp', out / 'fang.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    rows = {r[0]:r for r in struct.iter_unpack('<234I', raw[20:20+count*936]) if r[0] in {*ranks,560202,706477}}
    assert rows[560202][212] == 5 and rows[560202][89] == 31 and rows[560202][92] == 18
    assert rows[706477][80] + rows[706477][74] == 5 and rows[706477][122] & rows[560202][209]
    assert all(rows[sid][71] == 2 and rows[sid][208] == 35 for sid in ranks)
    print(f'PASS: {len(ranks)} ranks, killing blows, absorbed hits, triggered casts, once-only healing and invalid targets')


if __name__ == '__main__':
    main()
