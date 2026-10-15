import argparse
import os
from pathlib import Path
import runpy
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
extract = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dbc-dir', type=Path)
    parser.add_argument('--before', action='store_true')
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()

    def source(path):
        return (ROOT / path).read_text()

    def rows(name):
        blob = (args.dbc_dir / (name + '.dbc')).read_bytes()
        count, fields, size = struct.unpack_from('<3I', blob, 4)
        return {r[0]: r for r in struct.iter_unpack('<' + str(fields) + 'I', blob[20:20 + count * size])}

    spells, xp = rows('Spell'), rows('QuestXP')
    ids = (57353, 71354, 157353, 818046, 819046, 818059, 804821, 302053, 302882)
    init = []
    for sid in ids:
        r = spells[sid]
        init.append(f'    spells[{sid}].Id={sid};')
        for i in range(3):
            base = struct.unpack('<i', struct.pack('<I', r[80 + i]))[0]
            init.append(f'    spells[{sid}].Effects[{i}]={{ {i},{r[71+i]},{r[95+i]},'
                        f'{base},{r[74+i]},{r[110+i]},{r[86+i]},{r[89+i]},{r[92+i]} }};')
    compat = source('src/server/coa/AscensionCompat.cpp')
    correction = (extract(compat, 'static bool IsAdventureModeTierAura')
                  + extract(compat, 'void ApplyAscensionExperienceContracts'))
    assert 'ApplyAscensionExperienceContracts(spellInfo);' in compat
    quest_source = source('src/server/game/Entities/Player/PlayerQuest.cpp')
    quest = extract(quest_source, 'uint32 Player::CalculateQuestRewardXP')
    multiplier = extract(source('src/server/game/Entities/Unit/Unit.cpp'),
                         'float Unit::GetTotalAuraMultiplier(AuraType auraType,')
    xp_value = extract(source('src/server/game/Quests/QuestDef.cpp'), 'uint32 Quest::XPValue')
    kills = source('src/server/game/Entities/Player/KillRewarder.cpp')
    start = kills.index('bool const recruitAFriend')
    kills = kills[start:kills.index('sScriptMgr->OnPlayerGiveXP', start)]
    manastorm = source('src/server/coa/AscensionManastorm.cpp')
    snapshot = manastorm[manastorm.index('bool const recruitAFriend'):]
    snapshot = snapshot[:snapshot.index('uint32 const xp')]
    header = (ROOT / 'src/server/game/Miscellaneous/LocalLevelScaling.h').as_posix()
    code = r'''
#include <array>
#include <cassert>
#include <cstdint>
#include <functional>
#include <map>
#include <vector>
#include "''' + header + r'''"
using uint8=std::uint8_t;using uint32=std::uint32_t;using int32=std::int32_t;
using AuraType=int;using SpellGroup=int;
constexpr int SPELL_AURA_MOD_XP_PCT=200,SPELL_AURA_MOD_XP_QUEST_PCT=291,
    SPELL_EFFECT_APPLY_AREA_AURA_PARTY=35,EFFECT_1=1,EFFECT_2=2;
struct SpellEffectInfo
{int EffectIndex=0,Effect=0,ApplyAuraName=0,BasePoints=0,DieSides=0,MiscValue=0,TargetA=0,TargetB=0,RadiusEntry=0;};
struct SpellInfo {uint32 Id=0;std::array<SpellEffectInfo,3> Effects;};
struct AuraEffect
{
    SpellInfo const* spell;uint8 index;
    uint32 GetId()const{return spell->Id;}SpellInfo const* GetSpellInfo()const{return spell;}
    uint8 GetEffIndex()const{return index;}int GetAmount()const{return spell->Effects[index].BasePoints+1;}
};
using AuraEffectList=std::vector<AuraEffect const*>;
template<class T> void AddPct(T& value,int amount){value*=1.0f+amount/100.0f;}
struct Manager
{
    bool AddSameEffectStackRuleSpellGroups(SpellInfo const*,uint8,uint32,int,std::map<int,int>&){return false;}
} manager;
auto sSpellMgr=&manager;
struct Unit
{
    std::map<AuraType,AuraEffectList> auras;
    AuraEffectList const& GetAuraEffectsByType(AuraType type)const
    {static AuraEffectList empty;auto i=auras.find(type);return i==auras.end()?empty:i->second;}
    float GetTotalAuraMultiplier(AuraType,std::function<bool(AuraEffect const*)> const&)const;
};
struct QuestXPEntry {std::array<uint32,10> Exp{};};
struct XPStore {std::map<int,QuestXPEntry> data;QuestXPEntry const* LookupEntry(int id){return &data.at(id);}};
XPStore sQuestXPStore;
struct Quest {int Level=7;uint32 RewardXPDifficulty=5;uint32 XPValue(uint8,bool)const;bool IsDFQuest()const{return false;}
    int GetQuestLevel()const{return Level;}};
class Player:public Unit
{
public:
    uint8 playerLevel=13;bool raf=false;
    uint8 GetLevel()const{return playerLevel;}float GetQuestRate(bool,int)const{return 1;}
    bool GetsRecruitAFriendBonus(bool)const{return raf;}
    uint32 CalculateQuestRewardXP(Quest const*);uint32 KillXP(uint32);float ManastormMultiplier();
};
struct ScriptMgr {void OnPlayerBeforeGetLevelForXPGain(Player*,uint8&) {}} scripts;
auto sScriptMgr=&scripts;
''' + correction + multiplier + xp_value + quest + r'''
uint32 Player::KillXP(uint32 xp){Player* player=this;
''' + kills + r'''return xp;}
float Player::ManastormMultiplier(){Player* player=this;
''' + snapshot + r'''return xpMultiplier;}
int main()
{
    std::map<uint32,SpellInfo> spells;
''' + '\n'.join(init) + '\n' + '\n'.join(
        f'    sQuestXPStore.data[{level}].Exp[5]={xp[level][6]};' for level in (7, 13, 20)) + r'''
    LocalLevelScaling::QuestEnabled=true;
    Player player;Quest quest;
    assert(player.CalculateQuestRewardXP(&quest)==900);
    player.playerLevel=20;assert(player.CalculateQuestRewardXP(&quest)==1550);player.playerLevel=13;
    LocalLevelScaling::QuestEnabled=false;
    assert(player.CalculateQuestRewardXP(&quest)==500);LocalLevelScaling::QuestEnabled=true;
''' + ('' if args.before else '    for(auto& pair:spells)ApplyAscensionExperienceContracts(&pair.second);\n') + r'''
    std::vector<AuraEffect> active;
    auto equip=[&](std::initializer_list<uint32> ids)
    {
        active.clear();player.auras.clear();active.reserve(20);
        for(uint32 id:ids)for(uint8 i=0;i<3;++i)
        {
            auto& effect=spells[id].Effects[i];
            if(effect.Effect && (effect.ApplyAuraName==200 || effect.ApplyAuraName==291))
            {active.push_back({&spells[id],i});player.auras[effect.ApplyAuraName].push_back(&active.back());}
        }
    };
    equip({818046});assert(player.CalculateQuestRewardXP(&quest)==1125 && player.KillXP(100)==125);
    equip({819046});assert(player.CalculateQuestRewardXP(&quest)==1350 && player.KillXP(100)==107);
    for(uint32 id:{57353u,71354u})
    {equip({id});assert(player.CalculateQuestRewardXP(&quest)==990 && player.KillXP(100)==110);}
    equip({157353});assert(player.CalculateQuestRewardXP(&quest)==1080 && player.KillXP(100)==120);
    equip({818059});assert(player.CalculateQuestRewardXP(&quest)==1350 && player.KillXP(100)==150);
    assert(player.ManastormMultiplier()==1.5f);
    auto const& party=spells[818059];
    assert(party.Effects[2].EffectIndex==2 && party.Effects[2].Effect==35 && party.Effects[2].RadiusEntry==30);
    player.raf=true;
    assert(player.CalculateQuestRewardXP(&quest)==900 && player.KillXP(100)==100);
    assert(player.ManastormMultiplier()==1.0f);
    equip({818046,818059});assert(player.CalculateQuestRewardXP(&quest)==1125 && player.KillXP(100)==125);
    player.raf=false;equip({});assert(player.CalculateQuestRewardXP(&quest)==900);
    equip({302053});assert(player.CalculateQuestRewardXP(&quest)==1800 && player.KillXP(100)==50);
    equip({302882});assert(player.CalculateQuestRewardXP(&quest)==2250 && player.KillXP(100)==50);
    assert(spells[804821].Effects[0].ApplyAuraName==200); // Unrelated profession aura is unchanged.
}
'''
    compiler = str(Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe')
    with tempfile.TemporaryDirectory(prefix='coa-quest-xp-') as directory:
        out = Path(directory)
        cpp, exe = out / 'xp.cpp', out / 'xp.exe'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '/nologo', '/std:c++17', '/EHsc', '/W4', '/WX', '/wd4244', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: scaled Pelt Collection XP; potions/heirlooms/party aura; separate kill/quest bonuses; RaF exclusion; '
          'Adventure Mode quest bonus and kill penalty')


if __name__ == '__main__':
    main()
