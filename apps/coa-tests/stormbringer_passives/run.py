CLI_DESCRIPTION = """Exercise Cloudburst and Shock's actual callbacks, including the triggered repeat."""
import argparse
import importlib.util
from pathlib import Path
import re
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HARNESS = r'''
#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <array>
#include <set>
#include <map>
#include <vector>
using uint32 = std::uint32_t;
using int32 = std::int32_t;
using uint8 = std::uint8_t;
using uint64 = std::uint64_t;
// NATIVE_CLASSES
constexpr int ALLSPELLHOOK_ON_CAST = 1, ALLSPELLHOOK_ON_HIT_RESULT = 2,
    GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 3, EFFECT_0 = 0, EFFECT_1 = 1, EFFECT_2 = 2, SPELL_MISS_NONE = 0,
    SPELLVALUE_BASE_POINT0 = 0, SPELL_ATTR2_CANT_CRIT = 1,
    SPELL_ATTR3_IGNORE_CASTER_MODIFIERS = 2, SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS = 4;
constexpr uint32 SPELL_AURA_ADD_PCT_MODIFIER = 108, SPELLMOD_BONUS_MULTIPLIER = 24;
struct flag96
{
    uint32 part[3];
    flag96(uint32 first = 0, uint32 second = 0, uint32 third = 0):part{first,second,third}{}
    flag96& operator|=(flag96 const& right)
    {for(int i=0;i<3;++i)part[i]|=right.part[i];return *this;}
    bool operator==(flag96 const& right) const
    {return part[0]==right.part[0]&&part[1]==right.part[1]&&part[2]==right.part[2];}
};
struct SpellEffectInfo
{
    uint32 Effect = 0;float BonusMultiplier = 1.0f;
    uint32 ApplyAuraName = 0;int32 MiscValue = 0;flag96 SpellClassMask;
};
struct SpellInfo
{
    uint32 Id = 801838, SpellFamilyName = 22, AttributesEx2 = 0, AttributesEx3 = 0, AttributesEx4 = 0;
    bool AscensionInheritsResolvedAmount = false;uint32 StackAmount=20;
    std::array<SpellEffectInfo,3> Effects;
};
struct Unit;
struct Spell
{
    bool triggered = false;Unit* owner = nullptr;SpellInfo* info = nullptr;std::map<uint32,uint64> markers;
    bool IsTriggered() const { return triggered; }
    Unit* GetCaster() const {return owner;}SpellInfo const* GetSpellInfo() const {return info;}
    uint64 GetScriptValue(uint32 key) {return markers[key];}
    void SetScriptValue(uint32 key,uint64 value){markers[key]=value;}
};
struct SpellMgr
{
    SpellInfo row;SpellInfo const* GetSpellInfo(uint32){return &row;}
    uint32 GetFirstSpellInChain(uint32 id) const
    {return ((id>=503326 && id<=503332)||id==504634) ? 804020 : id;}
} manager;
SpellMgr* sSpellMgr = &manager;
struct Aura {uint32 stacks=0;uint32 GetStackAmount() const {return stacks;}};
struct Player;
struct Unit
{
    bool friendly=false, moving=false;uint32 guid=1;std::set<uint32> auras;
    std::map<uint32,Aura> owned;std::vector<uint32> casts;
    int32 periodicShare = 10;
    int32 CalculateSpellDamage(Unit const*, SpellInfo const*, uint8) const {return periodicShare;}
    bool isMoving()const{return moving;}bool HasAura(uint32 id)const{return auras.contains(id);}
    Aura* GetAura(uint32 id){return HasAura(id)?&owned[id]:nullptr;}
    void RemoveAurasDueToSpell(uint32 id){auras.erase(id);owned.erase(id);}
    void CastSpell(Unit* target,uint32 id,bool triggered)
    {
        assert(target==this && triggered);casts.push_back(id);
        if(id==800299 || id==803790){auras.insert(id);++owned[id].stacks;}
    }
    virtual ~Unit() = default;virtual Player* ToPlayer() { return nullptr; }
    uint32 GetGUID() const {return guid;}
    void AddAura(uint32 id,Unit* target){target->auras.insert(id);}
    void RemoveAurasDueToSpell(uint32 id,uint32 casterGuid){assert(casterGuid==guid);auras.erase(id);}
};
struct Player : Unit
{
    uint32 cls = CLASS_STORMBRINGER;
    std::vector<int32> dotAmounts;
    std::set<uint32> known;
    Player* ToPlayer() override { return this; }
    uint32 getClass() const { return cls; }
    bool HasSpell(uint32 id) const {return known.contains(id);}
    bool IsFriendlyTo(Unit* unit) const {return unit->friendly;}
    void CastCustomSpell(uint32 id, uint32 slot, int32 amount, Unit* target, bool triggered)
    {
        assert(id == 560336 && slot == 0 && target != this && !target->friendly && triggered);
        dotAmounts.push_back(amount);
    }
};
struct AllSpellScript
{
    AllSpellScript(char const*, std::initializer_list<int>) { }
    virtual void OnSpellCast(Spell*, Unit*, SpellInfo const*, bool) { }
    virtual void OnSpellHitResult(Spell*, Unit*, uint8, uint32, uint32, bool) { }
};
struct GlobalScript
{GlobalScript(char const*,std::initializer_list<int>){}virtual void OnLoadSpellCustomAttr(SpellInfo*){}};
using AuraEffectHandleModes=uint32;
constexpr uint32 SPELL_AURA_DUMMY=4,AURA_EFFECT_HANDLE_REAL=1,
    SPELL_AURA_PERIODIC_TRIGGER_SPELL=23,SPELL_AURA_HASTE_SPELLS=216;
struct AuraEffect {};
struct Hook {template<class T>void operator+=(T){}};
struct AuraScript
{
    Unit* caster=nullptr;Unit* target=nullptr;Hook AfterEffectApply,AfterEffectRemove,OnEffectPeriodic;
    bool prevented=false;void PreventDefaultAction(){prevented=true;}
    virtual bool Validate(SpellInfo const*){return true;}virtual void Register(){}
    bool ValidateSpellInfo(std::initializer_list<uint32>){return true;}
    Unit* GetCaster()const{return caster;}Unit* GetTarget()const{return target;}
    uint32 GetCasterGUID()const{return caster?caster->GetGUID():0;}
};
#define PrepareAuraScript(name)
#define RegisterSpellScript(name)
#define AuraEffectApplyFn(...) 0
#define AuraEffectRemoveFn(...) 0
#define AuraEffectPeriodicFn(...) 0
// ACTUAL_SOURCE
int main()
{
    Player player;
    Unit creature;
    creature.guid=2;
    aura_ascension_barometric_pressure pressure;
    pressure.caster=&player;pressure.target=&creature;
    pressure.Apply(nullptr,1);assert(creature.auras.empty() && player.auras.empty());
    pressure.target=&player;
    pressure.Apply(nullptr,1);assert(player.auras.contains(803566));
    pressure.caster=&creature;
    pressure.OnRemove(nullptr,1);assert(player.auras.contains(803566));
    pressure.caster=&player;
    pressure.OnRemove(nullptr,1);assert(!player.auras.contains(803566));
    aura_ascension_electrical_charge electrical;
    electrical.caster=&player;electrical.target=&player;player.moving=true;
    electrical.Tick(nullptr);assert(electrical.prevented && player.casts.empty());
    player.moving=false;
    for(int tick=0;tick<19;++tick)electrical.Tick(nullptr);
    assert(player.GetAura(800299)->GetStackAmount()==19 && !player.HasAura(803790));
    electrical.Tick(nullptr);
    assert(player.GetAura(800299)->GetStackAmount()==20 && player.HasAura(803790));
    electrical.Tick(nullptr);assert(player.GetAura(800299)->GetStackAmount()==20);
    aura_ascension_charged_conduit conduit;conduit.target=&player;
    player.RemoveAurasDueToSpell(803790);conduit.OnRemove(nullptr,1);assert(!player.HasAura(800299));
    electrical.Tick(nullptr);assert(player.GetAura(800299)->GetStackAmount()==1);
    electrical.OnRemove(nullptr,1);assert(!player.HasAura(800299) && !player.HasAura(803790));
    player.casts.clear();
    Spell spell;
    SpellInfo info;
    stormbringer_talent_casts hook;
    hook.OnSpellCast(&spell, &player, &info, false);
    assert(player.casts == std::vector<uint32>{802385});
    info.Id = 802385;
    hook.OnSpellCast(&spell, &player, &info, false);
    info.Id = 801838;
    spell.triggered = true;
    hook.OnSpellCast(&spell, &player, &info, false);
    spell.triggered = false;
    info.SpellFamilyName = 3;
    hook.OnSpellCast(&spell, &player, &info, false);
    info.SpellFamilyName = 22;
    player.cls = CLASS_MAGE;
    hook.OnSpellCast(&spell, &player, &info, false);
    hook.OnSpellCast(&spell, &creature, &info, false);
    hook.OnSpellCast(&spell, nullptr, &info, false);
    assert(player.casts.size() == 1);
    player.cls = CLASS_STORMBRINGER;
    for(uint32 id : {804020u,503326u,503327u,503328u,503329u,503330u,503331u,503332u,504634u,570054u})
    {
        player.casts.clear();player.dotAmounts.clear();player.known.clear();player.auras.clear();
        info.Id=id;info.SpellFamilyName=22;spell.info=&info;spell.owner=&player;spell.markers.clear();
        spell.triggered=id==570054;
        hook.OnSpellHitResult(&spell,&creature,0,100,0,false);assert(player.casts.empty());
        player.auras.insert(500040); // An aura with this ID is not the learned-spell gate.
        hook.OnSpellHitResult(&spell,&creature,0,100,0,false);assert(player.casts.empty());
        player.known.insert(500040);player.auras.insert(800098);
        hook.OnSpellHitResult(&spell,&creature,0,100,0,false);assert(player.casts.empty());
        player.auras.erase(800098);
        hook.OnSpellHitResult(&spell,&creature,1,100,0,false);
        hook.OnSpellHitResult(&spell,&player,0,100,0,false);
        creature.friendly=true;hook.OnSpellHitResult(&spell,&creature,0,100,0,false);creature.friendly=false;
        assert(player.casts.empty());
        hook.OnSpellHitResult(&spell,&creature,0,100,0,false);
        hook.OnSpellHitResult(&spell,&creature,0,100,0,true);
        assert(player.casts==std::vector<uint32>{804086});
        assert(player.dotAmounts==std::vector<int32>{10});
        // Ward suppresses Static, but not the two damage ticks.
        spell.markers.clear();player.casts.clear();player.dotAmounts.clear();player.auras.insert(800098);
        hook.OnSpellHitResult(&spell,&creature,0,259,0,true);
        assert(player.casts.empty() && player.dotAmounts==std::vector<int32>{25});
        spell.markers.clear();player.dotAmounts.clear();
        hook.OnSpellHitResult(&spell,&creature,0,0,0,false);
        hook.OnSpellHitResult(&spell,&creature,1,259,0,false);
        creature.friendly=true;hook.OnSpellHitResult(&spell,&creature,0,259,0,false);creature.friendly=false;
        hook.OnSpellHitResult(&spell,&player,0,259,0,false);
        assert(player.dotAmounts.empty());
    }
    info.Id=804020;spell.triggered=true;spell.markers.clear();player.casts.clear();
    hook.OnSpellHitResult(&spell,&creature,0,100,0,false);assert(player.casts.empty());
    info.Id=570054;info.SpellFamilyName=3;
    hook.OnSpellHitResult(&spell,&creature,0,100,0,false);assert(player.casts.empty());
    info.SpellFamilyName=22;player.cls=CLASS_MAGE;
    hook.OnSpellHitResult(&spell,&creature,0,100,0,false);assert(player.casts.empty());
    assert(player.dotAmounts.empty());
    player.cls=CLASS_STORMBRINGER;player.periodicShare=15;
    spell.markers.clear();player.casts.clear();player.dotAmounts.clear();
    info=SpellInfo{};info.Id=804020;info.SpellFamilyName=22;
    spell.info=&info;spell.owner=&player;spell.triggered=false;
    hook.OnSpellHitResult(&spell,&creature,0,100,0,false);
    assert(player.dotAmounts==std::vector<int32>{15});
    spell.markers.clear();player.dotAmounts.clear();
    hook.OnSpellHitResult(&spell,&creature,0,259,0,false);
    assert(player.dotAmounts==std::vector<int32>{38});
    player.periodicShare=10;spell.markers.clear();player.casts.clear();player.dotAmounts.clear();
    hook.OnSpellHitResult(&spell,&creature,0,259,0,false);
    assert(player.dotAmounts==std::vector<int32>{25});
    stormbringer_resource_contracts contracts;
    player.cls=CLASS_STORMBRINGER;
    info.Id=560336;contracts.OnLoadSpellCustomAttr(&info);
    assert(info.AscensionInheritsResolvedAmount && !info.Effects[0].BonusMultiplier);
    assert(info.AttributesEx2 & SPELL_ATTR2_CANT_CRIT);
    assert(info.AttributesEx3 & SPELL_ATTR3_IGNORE_CASTER_MODIFIERS);
    assert(info.AttributesEx4 & SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS);
    info=SpellInfo{};info.Id=560336;info.SpellFamilyName=3;
    contracts.OnLoadSpellCustomAttr(&info);assert(!info.AscensionInheritsResolvedAmount);
    info.Id=570054;info.SpellFamilyName=22;
    info.Effects[0].Effect=2;info.Effects[1].Effect=64;
    contracts.OnLoadSpellCustomAttr(&info);assert(info.Effects[0].Effect==2 && !info.Effects[1].Effect);
    info.Id=803790;info.Effects[2].Effect=164;
    contracts.OnLoadSpellCustomAttr(&info);assert(!info.Effects[2].Effect);
    info.Id=804020;info.Effects[1].Effect=64;
    contracts.OnLoadSpellCustomAttr(&info);assert(info.Effects[1].Effect==64);
    for(uint32 id : {705667u,707793u})
    {
        info=SpellInfo{};info.Id=id;info.SpellFamilyName=22;
        info.Effects[0].ApplyAuraName=SPELL_AURA_ADD_PCT_MODIFIER;info.Effects[0].MiscValue=41;
        info.Effects[0].SpellClassMask=flag96(2048,16,0);
        contracts.OnLoadSpellCustomAttr(&info);
        assert(info.Effects[0].MiscValue==int32(SPELLMOD_BONUS_MULTIPLIER));
        assert(info.Effects[0].SpellClassMask==flag96(2048,18,0));
        info=SpellInfo{};info.Id=id;info.SpellFamilyName=3;
        info.Effects[0].ApplyAuraName=SPELL_AURA_ADD_PCT_MODIFIER;info.Effects[0].MiscValue=41;
        info.Effects[0].SpellClassMask=flag96(2048,16,0);
        contracts.OnLoadSpellCustomAttr(&info);
        assert(info.Effects[0].MiscValue==41 && info.Effects[0].SpellClassMask==flag96(2048,16,0));
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("storm_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    classes = native.extractor.extract((ROOT / "src/server/shared/SharedDefines.h").read_text(), r"enum Classes\b")
    source = (ROOT / "src/server/coa/AscensionStormbringerTalents.cpp").read_text()
    source = source.replace(': public AuraScript\n{', ': public AuraScript\n{\npublic:')
    code = HARNESS.replace("// NATIVE_CLASSES", classes + ";")
    code = code.replace("// ACTUAL_SOURCE", re.sub(r"^#include.*\n", "", source, flags=re.M))
    with tempfile.TemporaryDirectory(prefix="coa-stormbringer-passives-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "stormbringer-passives")
        assert result.returncode == 0, result.stdout + result.stderr
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936])
                if r[0] in {801838, 802385, 570054, 804086, 500040, 803563, 803566, 560336, 707058, 704149, 800299,
                            803790, 705639, 705667, 707793, 567518}}
        parent, child = rows[801838], rows[802385]
        assert parent[71:74] == (3, 64, 0) and parent[92] == 0 and parent[117] == 32991
        assert parent[208:212] == child[208:212] == (22, 0, 0, 8388608)
        assert child[71:74] == (98, 0, 0) and child[86] == 18 and child[89] == 16
        assert child[110] == 180 and child[80] + child[74] == 101 and child[92] == 45
        assert rows[570054][72] == 64 and rows[570054][117] == 804084
        assert rows[804086][72] == 175 and rows[804086][111] == 20 and rows[804086][117] == 803102
        assert rows[500040][71] == 2
        assert rows[803563][71:73] == rows[803566][71:73] == (129, 6)
        assert rows[803563][95:97] == (65, 4) and rows[803566][95:97] == (33, 4)
        assert rows[803563][92] == rows[803566][92] != 0
        assert rows[704149][95] == 23 and rows[704149][98] == 1000 and rows[704149][116] == 800299
        assert rows[800299][49] == 20 and rows[803790][40] == 1
        assert rows[803790][73] == 164 and rows[803790][118] == 800299
        dot, passive = rows[560336], rows[707058]
        assert dot[208] == 22 and dot[95] == 3 and dot[98] == 500 and dot[40] == 36
        assert passive[80] + passive[74] == 10 and passive[116] == 560336
        bursts = rows[705639]
        assert bursts[95] == 108 and bursts[110] == 3 and bursts[80] + bursts[74] == 50
        assert bursts[124] == passive[211] == 268435456
        first, second, thorim = rows[705667], rows[707793], rows[567518]
        assert first[95] == second[95] == 108 and first[110] == second[110] == 41
        assert first[122:124] == second[122:124] == (2048, 16) and first[124] == second[124] == 0
        assert first[80] + first[74] == 15 and second[80] + second[74] == 30
        assert thorim[208] == 22 and thorim[209:212] == (0, 2, 32)
        raw = (args.spell_dbc.parent / "SpellDuration.dbc").read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        durations = {r[0]: r[1] for r in struct.iter_unpack("<4i", raw[20:20 + count * 16])}
        assert durations[36] // dot[98] == 2 and durations[1] == 10000
        raw = (args.spell_dbc.parent / "SpellRadius.dbc").read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        radius = {r[0]: r[1] for r in struct.iter_unpack("<I3f", raw[20:20 + count * 16])}
        assert radius[45] == 10
    print("PASS: Cloudburst; Shock ranks/repeat, the hidden passive's periodic share, Invoking Storms' modifier "
          "contract, learned-spell gate, ward/hostile/miss/trigger guards and helper data")


if __name__ == "__main__":
    main()
