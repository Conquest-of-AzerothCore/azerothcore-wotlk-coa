import argparse
import json
import os
from pathlib import Path
import re
import runpy
import sqlite3
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402
from client_data import dbc_dir  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
extract = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dbc-dir', type=Path)
    parser.add_argument('--datamine-dir', type=Path, required=True)
    parser.add_argument('--source-ref')
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()

    def source(name):
        path = 'src/server/coa/' + name
        return (git_source(['git', 'show', args.source_ref + ':' + path], cwd=ROOT).decode()
                if args.source_ref else (ROOT / path).read_text())

    blob = (args.dbc_dir / 'Spell.dbc').read_bytes()
    count, _, size = struct.unpack_from('<3I', blob, 4)
    rows = {r[0]: r for r in struct.iter_unpack('<234I', blob[20:20 + count * size])}
    slap, firebolt = rows[630930], rows[800444]
    assert (slap[29], slap[41], slap[204], slap[46]) == (3000, 0, 3, 2)
    assert slap[71:74] == (2, 177, 0) and slap[111] == 630933 and slap[81] + 1 == 2000
    assert (firebolt[28], firebolt[29], firebolt[42], firebolt[204]) == (1, 0, 0, 0)
    assert firebolt[117] == 578318
    pool = blob[20 + count * size:]
    desc = pool[slap[170]:pool.find(b'\0', slap[170])].decode()
    assert '$m1*$<scalingbp>+$AP*0.3+$SP*0.6' in desc
    variables = args.datamine_dir / 'raw/tables/SpellDescriptionVariables/000-999.jsonl'
    row = next(r for r in map(json.loads, variables.read_text().splitlines()) if r['f0'] == 182)
    formula = row['f1'].split('=${', 1)[1].rstrip('}')
    expected = [155 * eval(formula.replace('$PL', str(level)), {'__builtins__': {}})
                for level in (10, 40, 80)]

    sql = (ROOT / 'data/sql/updates/pending_db_world/rev_1789367099733683000.sql').read_text()
    db = sqlite3.connect(':memory:')
    db.execute('CREATE TABLE spell_bonus_data(entry PRIMARY KEY,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments)')
    db.execute("INSERT INTO spell_bonus_data VALUES(800444,0,0,0,0,'temporary imp')")
    db.executescript(sql)
    db.executescript(sql)
    assert db.execute('SELECT direct_bonus,ap_bonus FROM spell_bonus_data WHERE entry=630930').fetchone() == (.6, .3)
    assert db.execute('SELECT comments FROM spell_bonus_data WHERE entry=800444').fetchone() == ('temporary imp',)
    assert not re.search(r'\{630930,', source('AscensionXorothData.h'))

    pet_block = extract(source('AscensionXoroth.cpp'),
                        'if (Pet* pet = player->GetPet(); pet && pet->GetEntry() == 510100)')
    contracts = source('AscensionXorothContracts.cpp')
    scaling = (extract(contracts, 'if (info->Id == 630930 && index == EFFECT_0')
               if 'info->Id == 630930' in contracts else '')
    code = r'''
#include <cassert>
#include <cmath>
#include <cstdint>
#include <set>
using uint32=std::uint32_t;
constexpr int EFFECT_0=0;
struct SpellInfo {uint32 Id;};
struct Manager {SpellInfo info{0};SpellInfo const* GetSpellInfo(uint32 id){info.Id=id;return &info;}} mgr;
auto sSpellMgr=&mgr;
struct Pet
{
    uint32 entry=510100,level=10;std::set<uint32> spells,autocast;
    uint32 GetEntry()const{return entry;} uint32 GetLevel()const{return level;}
    bool HasAura(uint32)const{return true;}bool HasSpell(uint32 id)const{return spells.count(id)!=0;}
    void learnSpell(uint32 id){spells.insert(id);}
    void ToggleAutocast(SpellInfo const* info,bool on)
    {if(on)autocast.insert(info->Id);else autocast.erase(info->Id);}
    void removeSpell(uint32 id,bool previous){assert(!previous);spells.erase(id);}
};
struct Player {Pet* pet=nullptr;int refreshes=0;Pet* GetPet(){return pet;}void PetSpellInitialize(){++refreshes;}};
void Cast(Player*,Pet*,uint32){}
void Refresh(Player* player)
{
''' + pet_block + r'''
}
float Scale(Pet const* caster,SpellInfo const* info,int index,float value)
{
    (void)caster;(void)info;(void)index;
''' + scaling + r'''
    return value;
}
int main()
{
    Pet pet;Player player{&pet};Refresh(&player);
    assert(pet.spells==std::set<uint32>({630930,630931}));
    assert(pet.autocast==pet.spells && player.refreshes==1);
    pet.autocast.erase(630930);Refresh(&player);
    assert(!pet.autocast.count(630930) && player.refreshes==1); // Preserve a user's disabled autocast.
    pet.spells.insert(800444);pet.autocast.insert(800444);Refresh(&player);
    assert(!pet.spells.count(800444) && !pet.autocast.count(800444));
    pet.entry=50301;pet.spells={800444};pet.autocast={800444};Refresh(&player);
    assert(pet.spells==std::set<uint32>({800444}) && pet.autocast==pet.spells);
    player.pet=nullptr;Refresh(&player);
    SpellInfo slap{630930},bolt{800444};
    assert(Scale(&pet,&slap,0,155)==155); // Temporary summons do not get permanent-pet scaling.
    pet.entry=510100;
    assert(Scale(&pet,&slap,1,2000)==2000 && Scale(&pet,&bolt,0,58)==58);
''' + '\n'.join(f'    pet.level={level};assert(std::abs(Scale(&pet,&slap,0,155)-{value:.10f})<0.001);'
                for level, value in zip((10, 40, 80), expected)) + '\n}\n'
    compiler = str(Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe')
    with tempfile.TemporaryDirectory(prefix='coa-greater-imp-') as directory:
        out = Path(directory)
        cpp, exe = out / 'imp.cpp', out / 'imp.exe'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '/nologo', '/std:c++17', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: pet spell migration, preserved autocast preferences, authored pacing/scaling and idempotent SQL')


if __name__ == '__main__':
    main()
