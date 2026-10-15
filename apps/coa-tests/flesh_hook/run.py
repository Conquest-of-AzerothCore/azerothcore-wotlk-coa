import argparse
import os
from pathlib import Path
import runpy
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
    parser.add_argument('--source-ref')
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()
    path = 'src/server/coa/AscensionXorothContracts.cpp'
    contracts = (git_source(['git', 'show', args.source_ref + ':' + path], cwd=ROOT).decode()
                 if args.source_ref else (ROOT / path).read_text())
    correction = (extract(contracts, 'if (id == SPELL_FLESH_HOOK_PULL)')
                  if 'if (id == SPELL_FLESH_HOOK_PULL)' in contracts else '')
    blob = (args.dbc_dir / 'Spell.dbc').read_bytes()
    count, _, size = struct.unpack_from('<3I', blob, 4)
    rows = {row[0]: row for row in struct.iter_unpack('<234I', blob[20:20 + count * size])}
    parents = (500020, 501488, 501489, 501490)
    callers = {row[0] for row in rows.values() if 800605 in row[110:119]}
    assert callers == set(parents), callers
    for parent in parents:
        assert rows[parent][71:74] == (2, 183, 30) and rows[parent][117] == 800605
    helper = rows[800605]
    assert helper[71:74] == (6, 145, 68) and helper[3] == 6
    blob = (args.dbc_dir / 'SpellRange.dbc').read_bytes()
    count, _, size = struct.unpack_from('<3I', blob, 4)
    ranges = {struct.unpack_from('<I', blob, 20 + i * size)[0]:
              struct.unpack_from('<I4fI', blob, 20 + i * size) for i in range(count)}
    assert ranges[4][1:] == (0., 0., 30., 30., 0)
    assert ranges[helper[46]][1:5] == (5., 5., 30., 30.)
    code = r'''
#include <algorithm>
#include <array>
#include <cassert>
#include <cmath>
#include <cstdint>
using uint8=std::uint8_t;using uint32=std::uint32_t;using int32=std::int32_t;
constexpr float M_PI=3.14159265f,MIN_MELEE_REACH=2.0f;
enum SpellMissInfo {SPELL_MISS_NONE,SPELL_MISS_MISS,SPELL_MISS_DODGE,SPELL_MISS_IMMUNE,
    SPELL_MISS_EVADE,SPELL_MISS_REFLECT};
enum SpellCastResult {SPELL_CAST_OK,SPELL_FAILED_OUT_OF_RANGE,SPELL_FAILED_TOO_CLOSE,
    SPELL_FAILED_UNIT_NOT_INFRONT};
enum {SPELL_DAMAGE_CLASS_NONE=0,SPELL_DAMAGE_CLASS_MAGIC=1,SPELL_DAMAGE_CLASS_MELEE=2,
    SPELL_DAMAGE_CLASS_RANGED=3,SPELL_RANGE_MELEE=1,SPELL_RANGE_RANGED=2,EFFECT_0=0,MAX_SPELL_EFFECTS=3,
    SPELL_EFFECT_DISPEL=38,SPELL_EFFECT_SCHOOL_DAMAGE=2,SPELL_EFFECT_SKINNING=95,SPELL_AURA_PERIODIC_DAMAGE=3,
    SPELL_AURA_CONTROL_VEHICLE=236,SPELL_AURA_REFLECT_SPELLS=28,SPELL_AURA_REFLECT_SPELLS_SCHOOL=74,
    SPELL_FACING_FLAG_INFRONT=1,SPELL_ATTR3_ALWAYS_HIT=1,SPELL_ATTR0_CU_IGNORE_EVADE=2,
    SPELL_ATTR1_AURA_STAYS_AFTER_COMBAT=3,SPELL_FLESH_HOOK_PULL=800605,SPELL_RANGE_THIRTY_YARDS=4};
bool roll_chance_i(int32) {return true;}
struct Range {uint32 ID;float minimum,maximum;uint32 Flags=0;};
struct Store
{
    Range row{4,0,30};
    Range const* LookupEntry(uint32 id)const {assert(id==4);return &row;}
} sSpellRangeStore;
struct EffectSlot {uint32 Effect=0,ApplyAuraName=0;};
struct SpellInfo
{
    uint32 Id=800605,DmgClass=2,SpellFamilyName=23,FacingCasterFlags=0,Mechanic=6;
    Range const* RangeEntry=nullptr;std::array<EffectSlot,3> Effects{};
    bool HasAttribute(uint32)const{return false;}
    bool IsPositive()const{return false;}
    bool HasEffect(uint32 id)const
    {return std::any_of(Effects.begin(),Effects.end(),[id](auto const& e){return e.Effect==id;});}
    bool HasAura(uint32)const{return false;}uint32 GetSchoolMask()const{return 1;}
};
struct Player;
struct Unit
{
    float x=0;bool immune=false,evading=false;int meleeRolls=0;
    bool IsImmunedToSpell(SpellInfo const* info)const {assert(info->Mechanic==6);return immune;}
    bool IsHostileTo(Unit*)const{return true;}bool IsCreature()const{return true;}
    Unit* ToCreature(){return this;}bool IsEvadingAttacks()const{return evading;}
    int32 GetTotalAuraModifier(uint32)const{return 0;}
    int32 GetTotalAuraModifierByMiscMask(uint32,uint32)const{return 0;}
    SpellMissInfo MeleeSpellHitResult(Unit*,SpellInfo const*) {++meleeRolls;return SPELL_MISS_DODGE;}
    SpellMissInfo MagicSpellHitResult(Unit*,SpellInfo const*) {return SPELL_MISS_MISS;}
    SpellMissInfo SpellHitResult(Unit*,SpellInfo const*,bool);
    bool IsPlayer()const{return true;}virtual Player* ToPlayer(){return nullptr;}
    Unit* GetSpellModOwner(){return nullptr;}void ApplySpellMod(uint32,uint32,float&,void*){}
    float GetSpellMaxRangeForTarget(Unit*,SpellInfo const* info)const{return info->RangeEntry->maximum;}
    float GetSpellMinRangeForTarget(Unit*,SpellInfo const* info)const{return info->RangeEntry->minimum;}
    struct Guid {bool IsPlayer()const{return true;}};
    Guid GetOwnerGUID()const{return {};}
    Unit* GetVehicleBase(){return nullptr;}float GetLeewayBonusRange(Unit*)const{return 0;}
    bool IsWithinMeleeRange(Unit* target,float range)const{return std::abs(x-target->x)<=range;}
    bool IsWithinCombatRange(Unit* target,float range)const{return IsWithinMeleeRange(target,range);}
    bool IsWithinRange(Unit* target,float range)const{return IsWithinMeleeRange(target,range);}
    bool HasInArc(float,Unit*)const{return true;}bool IsWithinBoundaryRadius(Unit*)const{return false;}
    bool IgnoresSpellMinRange(SpellInfo const*)const{return false;}float GetMeleeRange(Unit*)const{return 0;}
    bool IsWithinDist3d(float const* point,float range)const{return std::abs(x-*point)<=range;}
    float GetLeewayBonusRadius()const{return 0;}
};
struct Player:Unit
{
    Unit* scopedTarget=nullptr;
    Player* ToPlayer()override{return this;}
    bool IsWithinLootDistance(Unit* target)const
    {return std::abs(x-target->x)<=5 || target==scopedTarget;}
};
struct GameObject {bool IsAtInteractDistance(Player*,SpellInfo const*)const{return true;}};
struct Targets
{
    Unit* target=nullptr;Unit* GetUnitTarget()const{return target;}
    GameObject* GetGOTarget()const{return nullptr;}
    bool HasDst()const{return false;}bool HasTraj()const{return false;}
    float const* GetDstPos()const{return nullptr;}
};
constexpr uint32 SPELLMOD_RANGE=0;
struct Spell
{
    int m_casttime=0;Unit* m_caster;SpellInfo const* m_spellInfo;Targets m_targets;
    bool triggered=false;bool IsTriggered()const{return triggered;}
    Unit* GetCaster(){return m_caster;}SpellCastResult CheckRange(bool);
};
'''
    code = code.replace('Unit* GetSpellModOwner()', 'Player* GetSpellModOwner()')
    unit = (ROOT / 'src/server/game/Entities/Unit/Unit.cpp').read_text()
    spell = (ROOT / 'src/server/game/Spells/Spell.cpp').read_text()
    code += extract(unit, 'SpellMissInfo Unit::SpellHitResult(Unit* victim, SpellInfo const* spell, bool CanReflect)')
    code += extract(spell, 'SpellCastResult Spell::CheckRange(bool strict)')
    code += '\nvoid Apply(SpellInfo* info) {uint32 id=info->Id; (void)id;\n' + correction + '\n}\n'
    code += r'''
int main()
{
    Range original{54,5,30};SpellInfo pull;pull.RangeEntry=&original;
    Unit caster,target;target.x=20;
    assert(caster.SpellHitResult(&target,&pull,false)==SPELL_MISS_DODGE);
    Spell cast{0,&caster,&pull,{&target}};
    target.x=4;assert(cast.CheckRange(true)==SPELL_FAILED_TOO_CLOSE);
    Apply(&pull);
    assert(caster.SpellHitResult(&target,&pull,false)==SPELL_MISS_NONE && caster.meleeRolls==1);
    assert(cast.CheckRange(true)==SPELL_CAST_OK);
    target.x=30;assert(cast.CheckRange(true)==SPELL_CAST_OK);
    target.x=31;assert(cast.CheckRange(true)==SPELL_FAILED_OUT_OF_RANGE);
    target.immune=true;assert(caster.SpellHitResult(&target,&pull,false)==SPELL_MISS_IMMUNE);
    target.immune=false;target.evading=true;
    assert(caster.SpellHitResult(&target,&pull,false)==SPELL_MISS_EVADE);
    target.evading=false;
    {
        Player gatherer;Range skinRange{2,0,5};SpellInfo skin;
        skin.RangeEntry=&skinRange;skin.Effects[0].Effect=SPELL_EFFECT_SKINNING;
        Spell skinCast{0,&gatherer,&skin,{&target}};skinCast.triggered=true;
        target.x=20;assert(skinCast.CheckRange(true)==SPELL_FAILED_OUT_OF_RANGE);
        gatherer.scopedTarget=&target;assert(skinCast.CheckRange(true)==SPELL_CAST_OK);
        skinCast.triggered=false;assert(skinCast.CheckRange(true)==SPELL_FAILED_OUT_OF_RANGE);
        skinCast.triggered=true;gatherer.scopedTarget=nullptr;
        assert(skinCast.CheckRange(true)==SPELL_FAILED_OUT_OF_RANGE);
    }
    for (uint32 id:{500020u,501488u,501489u,501490u})
    {
        SpellInfo parent;parent.Id=id;parent.DmgClass=SPELL_DAMAGE_CLASS_MAGIC;parent.RangeEntry=&original;
        Apply(&parent);assert(parent.RangeEntry==&original);
        assert(caster.SpellHitResult(&target,&parent,false)==SPELL_MISS_MISS);
    }
}
'''
    compiler = str(Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe')
    with tempfile.TemporaryDirectory(prefix='coa-flesh-hook-') as directory:
        out = Path(directory)
        cpp, exe = out / 'hook.cpp', out / 'hook.exe'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: native helper hit/range checks, grip immunity, evade and unchanged parent ranks')


if __name__ == '__main__':
    main()
