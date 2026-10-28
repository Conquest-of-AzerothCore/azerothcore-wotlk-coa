from pathlib import Path
import os
import re
import shutil
import sqlite3
import struct
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
SQL = ROOT / 'data/sql/updates/pending_db_world/rev_20261027_01_wildcard_skillcard_proc_repairs.sql'


def sql_checks():
    connection = sqlite3.connect(':memory:')
    connection.executescript("CREATE TABLE spell_proc (SpellId INTEGER PRIMARY KEY, SchoolMask, SpellFamilyName, SpellFamilyMask0, SpellFamilyMask1, SpellFamilyMask2, ProcFlags, SpellTypeMask, SpellPhaseMask, HitMask, AttributesMask, DisableEffectsMask, ProcsPerMinute, Chance, Cooldown, Charges); CREATE TABLE spell_script_names (spell_id, ScriptName, PRIMARY KEY (spell_id, ScriptName)); CREATE TABLE spell_bonus_data (entry INTEGER PRIMARY KEY, direct_bonus, dot_bonus, ap_bonus, ap_dot_bonus, comments); INSERT INTO spell_proc VALUES (999999,0,0,0,0,0,1,0,0,0,0,0,0,100,0,0); INSERT INTO spell_script_names VALUES (285541,'unrelated_binding');")
    sql = SQL.read_text(encoding='utf-8').replace('START TRANSACTION;', 'BEGIN TRANSACTION;')
    connection.executescript(sql)
    before = [connection.execute('SELECT * FROM '+table+' ORDER BY 1,2').fetchall() for table in ['spell_proc', 'spell_script_names', 'spell_bonus_data']]
    connection.executescript(sql)
    after = [connection.execute('SELECT * FROM '+table+' ORDER BY 1,2').fetchall() for table in ['spell_proc', 'spell_script_names', 'spell_bonus_data']]
    assert before == after
    assert connection.execute('SELECT COUNT(*) FROM spell_proc WHERE SpellId=999999').fetchone()[0] == 1
    assert connection.execute("SELECT COUNT(*) FROM spell_script_names WHERE spell_id=285541 AND ScriptName='unrelated_binding'").fetchone()[0] == 1
    parents = {row[0] for row in connection.execute("SELECT spell_id FROM spell_script_names WHERE ScriptName='aura_wildcard_skillcard_proc'")}
    assert len(parents) == 35
    assert not parents.intersection({281681,284943,278510,284057,277818})
    for id, cooldown in [(282105,1000),(283238,5000),(273595,16000),(270424,1000),(277505,4000),(283471,10000),(273121,4500)]:
        assert connection.execute('SELECT Cooldown FROM spell_proc WHERE SpellId=?',(id,)).fetchone()[0] == cooldown
    assert connection.execute('SELECT HitMask FROM spell_proc WHERE SpellId=282040').fetchone()[0] == 4
    assert connection.execute('SELECT SchoolMask,Charges,SpellPhaseMask FROM spell_proc WHERE SpellId=283635').fetchone() == (4,1,4)
    assert connection.execute('SELECT Charges,DisableEffectsMask FROM spell_proc WHERE SpellId=276809').fetchone() == (5,2)
    for id in [285242,281472,274126,270301,277510,277513]:
        assert connection.execute('SELECT Charges,AttributesMask FROM spell_proc WHERE SpellId=?',(id,)).fetchone() == (1,8)
    assert connection.execute('SELECT Charges,AttributesMask FROM spell_proc WHERE SpellId=281711').fetchone() == (3,8)
    names={row[0] for row in connection.execute('SELECT DISTINCT ScriptName FROM spell_script_names') if row[0]!='unrelated_binding'}
    source=(ROOT/'src/server/coa/AscensionWildcardSkillcards.cpp').read_text(encoding='utf-8')
    registered=set(re.findall(r'RegisterSpellScript\((\w+)\)',source))
    assert names <= registered
    data = Path(os.environ.get('COA_DBC_DIR',ROOT/'ManastormTestRepack/Data/dbc'))/'Spell.dbc'
    raw=data.read_bytes(); magic,n,fields,size,strings=struct.unpack_from('<4s4I',raw)
    assert magic==b'WDBC' and fields==234 and size==936
    spells={struct.unpack_from('<I',raw,20+i*size)[0]:struct.unpack_from('<234I',raw,20+i*size) for i in range(n)}
    for id in parents:
        row=spells[id]
        assert row[71:74]==(6,0,0) and row[95:98]==(42,0,0) and row[34]==0
        assert row[116] in spells
    for id in [276809,285539]:
        assert spells[id][95]==42
    for id, name in connection.execute('SELECT spell_id,ScriptName FROM spell_script_names'):
        if name=='spell_wildcard_bandage_reset':
            assert spells[id][3]==16 and 8 in spells[id][95:98]
    assert connection.execute('SELECT direct_bonus,ap_bonus FROM spell_bonus_data WHERE entry=270431').fetchone()==(.18,.117)
    print('PASS: pending SQL is repeatable, preserves unrelated rows/bindings, supplies all 35 parent routes and native charge/ICD contracts; bindings validate against installed DBC effects.')


def syntax_check(compiler,folder):
    project=ROOT/'build/src/server/coa/coa.vcxproj'
    assert os.name=='nt' and project.exists(), 'Real-header syntax prerequisites unavailable'
    ns={'m':'http://schemas.microsoft.com/developer/msbuild/2003'}
    tree=ET.parse(project)
    group=next(x for x in tree.findall('m:ItemDefinitionGroup',ns) if 'RelWithDebInfo' in x.attrib.get('Condition',''))
    node=group.find('m:ClCompile',ns)
    includes=node.find('m:AdditionalIncludeDirectories',ns).text.split(';')
    defines=node.find('m:PreprocessorDefinitions',ns).text.split(';')
    args=[compiler,'/nologo','/std:c++20','/Zs','/EHsc','/utf-8','/MD','/bigobj','/I'+str(ROOT/'src/server/coa')]
    args+=['/I'+x for x in includes if x and '$(' not in x and '%(' not in x]
    cache=(ROOT/'build/CMakeCache.txt').read_text(encoding='utf-8')
    for key in ['OPENSSL_INCLUDE_DIR','MYSQL_INCLUDE_DIR']:
        match=re.search(r'^'+key+r':PATH=(.+)$',cache,re.M)
        if match:args.append('/I'+match.group(1))
    args+=['/D'+x.replace('\\"','"') for x in defines if x and '$(' not in x and '%(' not in x]
    for name in ['AscensionWildcardSkillcards.cpp','CoAScriptLoader.cpp']:
        subprocess.run([*args,str(ROOT/'src/server/coa'/name)],cwd=folder,check=True,timeout=120)
    print('PASS: both changed translation units parse with real cached CoA headers.')


def main():
    sql_checks()
    compiler=shutil.which('cl' if os.name=='nt' else 'c++')
    assert compiler
    code=r"""
#include "AscensionSkillcardProcRules.h"
#include <cassert>
#include <iostream>
using namespace AscensionSkillcard;
int main()
{
    unsigned count=0;
    for (unsigned id:ImplementedSpells)
    {
        Event e;
        switch(id)
        {
            case 299986: e.Name="Arcane Barrage"; e.Damage=true; break;
            case 285930: e.Name="Blink"; e.Cast=true; break;
            case 282040: e.Miss=true; break;
            case 282105: e.Kill=true; e.Qualified=true; break;
            case 285537: e.Name="Wrath"; e.Damage=true; e.Critical=true; e.Qualified=true; break;
            case 285240: e.Name="Lightning Bolt"; e.Cast=true; break;
            case 282029: e.Name="Tranquility"; e.Heal=true; break;
            case 283949: e.Heal=true; e.Qualified=true; break;
            case 283251: e.Name="Consecration"; e.Damage=true; e.Periodic=true; break;
            case 276808: e.Name="Shadow Bolt"; e.Damage=true; break;
            case 281471: e.Name="Drain Soul"; e.Damage=true; e.Periodic=true; break;
            case 277185: e.Name="Incinerate"; e.Cast=true; break;
            case 283175: e.Name="Desperate Prayer"; e.Heal=true; e.Qualified=true; break;
            case 283700: e.Name="Renew"; e.Heal=true; e.Periodic=true; break;
            case 283634: e.Damage=true; e.Fire=true; break;
            case 285749: e.Name="Windfury Attack"; e.Damage=true; break;
            case 285865: e.Damage=true; e.Frost=true; e.Qualified=true; break;
            case 283238: e.Name="Shadow Bolt"; e.Damage=true; break;
            case 273595: e.Damage=true; e.Offhand=true; e.Qualified=true; break;
            case 283465: e.Name="Demonic Leap"; e.Cast=true; break;
            case 293200: e.Damage=true; e.Fire=true; break;
            case 270424: e.Damage=true; e.Magic=true; e.Qualified=true; break;
            case 285100: e.Name="Hellfire"; e.Damage=true; e.Periodic=true; break;
            case 283927: e.Name="Holy Fire"; e.Damage=true; break;
            case 285739: e.Name="Holy Nova"; e.Cast=true; break;
            case 274125: e.Name="Cone of Cold"; e.Cast=true; break;
            case 277505: e.Cast=true; e.MeleeAbility=true; e.GlobalCooldown=true; break;
            case 270327: e.Damage=true; e.Fire=true; break;
            case 283471: e.Damage=true; e.Fire=true; e.Qualified=true; break;
            case 273121: e.Damage=true; break;
            case 281712: e.Name="Mangle (Cat)"; e.Cast=true; break;
            case 281710: e.Cast=true; e.HunterShot=true; break;
            case 285780: e.Name="Colossus Smash"; e.Damage=true; break;
            case 277143: e.Name="Drain Soul"; e.Damage=true; e.Periodic=true; e.Qualified=true; break;
            case 274268: e.Name="Javelin"; e.Damage=true; break;
            default: assert(false);
        }
        assert(Allows(id,e));
        assert(!Allows(id,Event{}));
        Event stale=e;stale.Damage=stale.Heal=stale.Cast=stale.Miss=stale.Kill=false;
        assert(!Allows(id,stale));
        ++count;
    }
    Event e; e.Cast=true;e.MeleeAbility=true;e.Hunter=true;e.GlobalCooldown=true;
    assert(!Allows(277505,e));e.Hunter=false;assert(Allows(277505,e));e.GlobalCooldown=false;assert(!Allows(277505,e));
    e={};e.Name="Holy Fire";e.Damage=true;e.Periodic=true;assert(!Allows(283927,e));
    e={};e.Name="Arcane Barrage";e.Damage=true;e.Periodic=true;assert(!Allows(299986,e));
    e={};e.Name="Life Tap";e.Cast=true;assert(Allows(281471,e));
    e={};e.Name="Lightning Rod";e.Damage=true;assert(Allows(285240,e));
    e={};e.Name="Stagger";e.Damage=true;e.Periodic=true;assert(Allows(285780,e));
    e={};e.Name="Wrath";e.Damage=true;e.Critical=true;assert(!Allows(285537,e));e.Qualified=true;assert(Allows(285537,e));e.Critical=false;assert(!Allows(285537,e));
    for (unsigned id:{281681u,284943u,278510u,284057u,277818u})assert(!Implemented(id));
    assert(count==35);
    assert(ClearsCooldown(0,-4000));assert(ClearsCooldown(1,-4000));assert(ClearsCooldown(4000,-4000));assert(!ClearsCooldown(4001,-4000));assert(!ClearsCooldown(5000,4000));assert(ClearsCooldown(5000,INT32_MIN));
    for(unsigned value=0;value<255;++value)assert(AddCharge(value,3)==(value<3?value+1:3));
    assert(!FullHealthAfterHeal(99,100,1));assert(FullHealthAfterHeal(100,100,1));assert(!FullHealthAfterHeal(100,100,0));assert(!FullHealthAfterHeal(0,0,1));
    std::cout<<"PASS: all35 real event rules, negative events, periodic/direct filtering, qualification gates, native alternate events, charge cap and full-heal boundary\n";
}
"""
    source=(ROOT/'src/server/coa/AscensionWildcardSkillcards.cpp').read_text(encoding='utf-8')
    start=source.index('    void OnLoadSpellCustomAttr(')
    first=source.index('{',start)
    end=first+1;depth=1
    while depth:
        depth+=(source[end]=='{')-(source[end]=='}');end+=1
    actual=source[first:end]
    fixture=r"""
constexpr unsigned SPELL_AURA_ADD_PCT_MODIFIER=108,SPELL_AURA_DUMMY=4,SPELL_AURA_MOD_DAMAGE_FROM_CASTER=271,SPELL_AURA_MOD_HEALING_RECEIVED=283,SPELL_AURA_MOD_HEALING_PCT=118;
constexpr unsigned EFFECT_0=0,EFFECT_1=1,EFFECT_2=2;
constexpr unsigned SPELL_AURA_ADD_FLAT_MODIFIER=107,SPELLMOD_IGNORE_ARMOR=13,SPELLMOD_COOLDOWN=11,SPELL_EFFECT_NONE=0,SPELL_AURA_NONE=0;
using uint8=unsigned char;
struct EffectSlot{unsigned ApplyAuraName=0;unsigned MiscValue=0;unsigned Effect=6;bool IsAura(unsigned type)const{return ApplyAuraName==type;}};
struct SpellInfo{unsigned Id;EffectSlot Effects[3];};
void Apply(SpellInfo* info) ACTUAL
void Contracts(){SpellInfo hunt{277513,{{108,36,6},{108,13,6},{107,11,6}}};Apply(&hunt);assert(hunt.Effects[0].Effect==6&&hunt.Effects[0].ApplyAuraName==108&&hunt.Effects[1].Effect==0&&hunt.Effects[2].Effect==0);SpellInfo faith{283701,{{271},{283},{}}};Apply(&faith);assert(faith.Effects[0].ApplyAuraName==283&&faith.Effects[1].ApplyAuraName==118);Apply(&faith);assert(faith.Effects[0].ApplyAuraName==283&&faith.Effects[1].ApplyAuraName==118);SpellInfo changed{283701,{{4},{283},{}}};Apply(&changed);assert(changed.Effects[0].ApplyAuraName==4&&changed.Effects[1].ApplyAuraName==283);SpellInfo bandage{283951,{{},{108},{}}};Apply(&bandage);assert(bandage.Effects[1].ApplyAuraName==4);SpellInfo unrelated{1,{{271},{108},{}}};Apply(&unrelated);assert(unrelated.Effects[0].ApplyAuraName==271&&unrelated.Effects[1].ApplyAuraName==108);}
""".replace('ACTUAL',actual)
    code=code.replace('int main()',fixture+'\nint main()').replace('    unsigned count=0;','    Contracts();\n    unsigned count=0;')
    with tempfile.TemporaryDirectory(prefix='skillcard-procs-') as name:
        folder=Path(name);cpp=folder/'checks.cpp';exe=folder/'checks.exe'
        cpp.write_text(code,encoding='utf-8')
        flags=['/nologo','/std:c++20','/EHsc','/I'+str(ROOT/'src/server/coa'),str(cpp),'/Fe'+str(exe)]
        subprocess.run([compiler,*flags],cwd=folder,check=True,timeout=40)
        subprocess.run([str(exe)],cwd=folder,check=True,timeout=10)
        syntax_check(compiler,folder)


if __name__=='__main__':
    main()
