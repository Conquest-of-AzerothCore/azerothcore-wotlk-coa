import argparse
import os
from pathlib import Path
import runpy
import sqlite3
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
extract = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']
SQL = ROOT / 'data/sql/updates/pending_db_world/rev_1789365018824773600.sql'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dbc-dir', type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()
    db = sqlite3.connect(':memory:')
    db.executescript('''
        CREATE TABLE creature_template (entry INT PRIMARY KEY, name TEXT, minlevel INT, maxlevel INT,
            faction INT, unit_class INT, type INT);
        CREATE TABLE creature_template_model (CreatureID INT, Idx INT, CreatureDisplayID INT,
            DisplayScale REAL, Probability REAL);
        CREATE TABLE creaturedisplayinfo_dbc (ID INT PRIMARY KEY, ModelID INT, CreatureModelScale REAL,
            CreatureModelAlpha INT, TextureVariation_1 TEXT);
        CREATE TABLE creaturemodeldata_dbc (ID INT PRIMARY KEY, Flags INT, ModelName TEXT,
            ModelScale REAL, CollisionWidth REAL, CollisionHeight REAL, MountHeight REAL);
        CREATE TABLE creature_model_info (DisplayID INT PRIMARY KEY, BoundingRadius REAL,
            CombatReach REAL, Gender INT);
        CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);
        INSERT INTO creature_template VALUES (28017,'Bloodworm',1,1,14,1,8);
        INSERT INTO spell_script_names VALUES (573299,'other_script');
    ''')
    sql = SQL.read_text()
    assert not db.execute('SELECT * FROM creature_template WHERE entry=325301').fetchall()
    db.executescript(sql)
    once = list(db.iterdump())
    db.executescript(sql)
    assert list(db.iterdump()) == once
    assert db.execute('SELECT name FROM creature_template WHERE entry=28017').fetchone() == ('Bloodworm',)
    assert db.execute("SELECT COUNT(*) FROM spell_script_names WHERE ScriptName='other_script'").fetchone() == (1,)
    assert dict(db.execute('SELECT CreatureID,CreatureDisplayID FROM creature_template_model')) == {
        315301: 93307, 325301: 15983, 335301: 236827}

    def dbc(name):
        b = (args.dbc_dir / name).read_bytes()
        magic, count, fields, size, _ = struct.unpack_from('<4s4I', b)
        assert magic == b'WDBC' and size == fields * 4
        return {r[0]: r for r in struct.iter_unpack('<' + str(fields) + 'I', b[20:20 + count * size])}

    spells = dbc('Spell.dbc')
    displays = dbc('CreatureDisplayInfo.dbc')
    models = dbc('CreatureModelData.dbc')
    assert displays[15983][1] in models
    assert dbc('SummonProperties.dbc')[61][1:4] == (1, 0, 2)
    for spell_id, entry, count in ((573299, 325301, 2), (573356, 335301, 5), (573357, 315301, 1)):
        row = spells[spell_id]
        assert row[71] == 28 and row[110] == entry and row[113] == 61
        assert row[80] + row[74] == count and row[117] == 712417
        assert db.execute('SELECT COUNT(*) FROM creature_template WHERE entry=?', (entry,)).fetchone() == (1,)
    for display, model in ((93307, 10899), (236827, 110722)):
        assert db.execute('SELECT ModelID FROM creaturedisplayinfo_dbc WHERE ID=?', (display,)).fetchone() == (model,)
        assert db.execute('SELECT COUNT(*) FROM creaturemodeldata_dbc WHERE ID=?', (model,)).fetchone() == (1,)
        assert db.execute('SELECT COUNT(*) FROM creature_model_info WHERE DisplayID=?', (display,)).fetchone() == (1,)
    scale_sql = ROOT / 'data/sql/updates/pending_db_world/rev_20260920_01_animated_blood_amalgam_scale.sql'
    db.executescript(scale_sql.read_text())
    db.executescript(scale_sql.read_text())
    display_scales = dict(db.execute('SELECT CreatureID,DisplayScale FROM creature_template_model'))
    assert display_scales == {315301: 0.25, 325301: 1, 335301: 1}
    box = struct.unpack_from('<6f', struct.pack('<6I', *models[10899][16:22]))
    rendered = (box[5] - box[2]) * struct.unpack('<f', struct.pack('<I', displays[93307][4]))[0] * display_scales[315301]
    assert rendered < 4
    source = (ROOT / 'src/server/coa/AscensionBloodmageTalents.cpp').read_text()
    assert 'OnEffectLaunch +=' in extract(source, 'class spell_ascension_animated_blood')
    assert spells[712417][86:92] == (18, 0, 0, 72, 0, 0)
    assert spells[712383][122:125] == spells[712417][209:212] == (0, 0, 4096)
    core = (ROOT / 'src/server/game/Spells/SpellEffects.cpp').read_text()
    count_switch = extract(extract(core, 'void Spell::EffectSummonType('), 'switch (properties->Id)')
    code = r'''
#include <cassert>
#include <array>
#include <cstdint>
#include <initializer_list>
using uint8=std::uint8_t;using uint32=std::uint32_t;
using SpellEffIndex=uint8;
constexpr uint32 EFFECT_1=1,SPELL_EFFECT_TRIGGER_SPELL=64,SPELLVALUE_BASE_POINT0=0;
struct Effect {uint32 TriggerSpell=712417;};
struct SpellInfo {std::array<Effect,3> Effects;};
struct Aura
{
    uint8 count=0;bool removed=false;
    uint8 GetStackAmount()const{return count;}void Remove(){removed=true;}
};
struct Unit
{
    Aura aura;uint32 spawned=0;
    uint32 GetGUID()const{return 1;}
    Aura* GetAura(uint32 id,uint32 owner)
    {assert(id==712383 && owner==1);return aura.count && !aura.removed?&aura:nullptr;}
    void CastCustomSpell(uint32 id,uint32 slot,uint32 count,Unit* target,bool triggered)
    {assert(id==712417 && slot==0 && target==this && triggered);spawned+=count;}
};
struct SpellScript
{
    Unit owner;SpellInfo info;bool prevented=false;
    virtual bool Validate(SpellInfo const*){return true;}virtual void Register(){}
    bool ValidateSpellInfo(std::initializer_list<uint32> ids){return ids.size()==2;}
    Unit* GetCaster(){return &owner;}SpellInfo const* GetSpellInfo(){return &info;}
    void PreventHitDefaultEffect(SpellEffIndex index){assert(index==1);prevented=true;}
    struct Hook {void operator+=(int){}} OnEffectLaunch;
};
#define PrepareSpellScript(name) public:
#define SpellEffectFn(...) 0
'''
    code += extract(source, 'enum BloodmageTalentSpells') + ';\n'
    code += extract(source, 'class spell_ascension_animated_blood') + ';\n'
    code += '\nuint32 NativeCount(uint32 damage) {struct Props {uint32 Id=61;} p; auto properties=&p;'
    code += 'uint32 numSummons;\n' + count_switch + '\nreturn numSummons;}\n'
    code += r'''
int main()
{
    // Before the callback, the unconditionally triggered helper's zero value summons an extra worm.
    assert(NativeCount(0)==1);
    for (uint32 rankCount:{2u,5u,1u})
        for (uint8 stacks:std::array<uint8,3>{0,1,10})
        {
            spell_ascension_animated_blood script;
            script.owner.aura.count=stacks;
            assert(script.Validate(nullptr));
            script.HandleExtraWorms(EFFECT_1);
            assert(script.prevented && script.owner.spawned==stacks);
            assert(NativeCount(rankCount)+script.owner.spawned==rankCount+stacks);
            script.HandleExtraWorms(EFFECT_1);
            assert(script.owner.spawned==stacks); // Consumed stacks cannot be used twice.
        }
    spell_ascension_animated_blood other;
    other.info.Effects[1].TriggerSpell=1;
    other.HandleExtraWorms(EFFECT_1);assert(!other.prevented && !other.owner.spawned);
}
'''
    compiler = str(Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe')
    with tempfile.TemporaryDirectory(prefix='coa-animated-blood-') as directory:
        out = Path(directory)
        cpp, exe = out / 'blood.cpp', out / 'blood.exe'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: rank summon dependencies, idempotent SQL, native counts and consumed Darkcasting extras')


if __name__ == '__main__':
    main()
