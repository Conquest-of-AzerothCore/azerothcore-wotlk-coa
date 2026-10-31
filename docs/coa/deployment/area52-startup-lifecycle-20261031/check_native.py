from pathlib import Path
import json,subprocess,tempfile,itertools
T=Path('/results')
def block(text,marker):
    start=text.index(marker);pos=text.index('{',start);end=pos+1;depth=1
    while depth:
        depth+=(text[end]=='{')-(text[end]=='}');end+=1
    return text[start:end]
def run(code,label):
    (T/(label+'.cpp')).write_text(code)
    subprocess.run(['g++','-std=c++20','-Wall','-Wextra',str(T/(label+'.cpp')),'-o',str(T/label)],check=True)
    subprocess.run([str(T/label)],check=True)
records={r['id']:r for r in json.loads((T/'spell-records.json').read_text())}
steps=[records[id]['base'][1]+1 for id in (33388,33391,34090,34091)]
assert steps==[2,3,4,5]
dbc=json.loads((T/'riding-dbc.json').read_text())
assert dbc['SkillRaceClassInfo'][0][1:4]==[762,4294967295,4294967295]
assert dbc['SkillTiers'][0][17:23]==[50,100,150,225,300,375]
for variant in ('baseline','source'):
    root=T/variant/'src/server'
    player=(root/'game/Entities/Player/Player.cpp').read_text()
    compat=(root/'coa/AscensionCompat.cpp').read_text()
    normalize=''
    if variant=='source':
        normalize=player[player.index('    SpellLearnSkillNode ridingSkill;'):player.index('    SkillLineAbilityMapBounds skill_bounds',player.index('    SpellLearnSkillNode ridingSkill;'))]
    ranks=player[player.index('    if (spellLearnSkill)'):player.index('    else\n    {\n        // not ranked skills')]
    code=r'''
#include <algorithm>
#include <cassert>
#include <cstdint>
#include <set>
#include <vector>
using uint16=uint16_t;using uint32=uint32_t;
constexpr uint32 SKILL_RIDING=762,MAX_SKILL_STEP=16;
struct SpellLearnSkillNode {uint16 skill,step,value,maxvalue;};
struct Tiers {uint16 Value[16]={50,100,150,225,300,375};} tiers;
struct Store {Tiers* LookupEntry(uint32){return &tiers;}} store;
auto* sSkillTiersStore=&store;
struct RC {uint32 SkillTierID=223;} rc;
RC* GetSkillRaceClassInfo(uint32,uint32,uint32){return &rc;}
struct Player;namespace AscensionFreePick {bool Applies(Player*);}
struct Player {
 bool area52=true;uint16 value=300,maximum=300,step=5;int writes=0;
 uint32 getRace(){return 10;}uint32 getClass(){return 10;}
 uint16 GetSkillStep(uint32){return step;}uint16 GetPureSkillValue(uint32){return value;}
 uint16 GetPureMaxSkillValue(uint32){return maximum;}
 void SetSkill(uint32,uint16 s,uint16 v,uint16 m){step=s;value=v;maximum=m;++writes;}
 void restore(SpellLearnSkillNode const* spellLearnSkill){uint16 maxskill=5;
 NORMALIZE
 RANKS
 }
};
namespace AscensionFreePick {bool Applies(Player* p){return p->area52;}}
int main(){
 std::vector<uint16> order{2,3,4,5};
 do {Player p;for(int login=0;login<20;++login){
   for(auto step:order){SpellLearnSkillNode n{762,step,uint16(step*75),uint16(step*75)};p.restore(&n);}
   if(FIXED){assert(p.value==300&&p.maximum==300&&p.writes==0);}
   else {assert(p.value==375&&p.maximum==375);p.SetSkill(762,4,300,300);}
 }}while(std::next_permutation(order.begin(),order.end()));
 Player fresh;fresh.value=fresh.maximum=fresh.step=0;
 for(uint16 step=2;step<=5;++step){SpellLearnSkillNode n{762,step,uint16(step*75),uint16(step*75)};fresh.restore(&n);}
 assert(fresh.value==(FIXED?300:375));
 Player high;high.value=high.maximum=375;high.step=6;
 SpellLearnSkillNode artisan{762,5,375,375};high.restore(&artisan);assert(high.value==375&&high.writes==0);
 Player other;other.area52=false;other.restore(&artisan);assert(other.value==375);
 Player profession;SpellLearnSkillNode tailor{197,5,1,375};profession.restore(&tailor);assert(profession.maximum==375);
}
'''.replace('auto* sSkillTiersStore=&store;','auto& sSkillTiersStore=store;').replace('NORMALIZE',normalize).replace('RANKS',ranks).replace('FIXED','true' if variant=='source' else 'false')
    run(code,'riding-'+variant)
    prefix=r'''
#include <cassert>
#include <cstdint>
#include <map>
#include <vector>
#include <algorithm>
#include <functional>
using uint32=uint32_t;using uint8=uint8_t;
constexpr int PLAYERSPELL_REMOVED=3,SMSG_SUPERCEDED_SPELL=1,SMSG_REMOVED_SPELL=2;
#define LOG_DEBUG(...)
struct SpellInfo {bool IsDeprecatedForPlayers=false;};
struct Spell {int State=0;bool Active=true;bool IsInSpec(int)const{return true;}};
using PlayerSpellMap=std::map<uint32,Spell*>;
using SpellsRequiringSpellMap=std::map<uint32,uint32>;
using SpellsRequiringSpellMapBounds=std::pair<SpellsRequiringSpellMap::const_iterator,SpellsRequiringSpellMap::const_iterator>;
struct Manager {SpellsRequiringSpellMap requirements;SpellInfo* GetSpellInfo(uint32){return nullptr;}
uint32 GetNextSpellInChain(uint32){return 0;}auto GetSpellsRequiringSpellBounds(uint32){return std::make_pair(requirements.cbegin(),requirements.cend());}} manager;
auto* sSpellMgr=&manager;bool IsAscensionClass(int){return false;}
struct ScriptMgr {std::function<void(uint32)> hook=[](uint32){};void OnPlayerLearnSpell(void*,uint32 s){hook(s);}} scripts;
auto* sScriptMgr=&scripts;
struct WorldPacket {int opcode,size;std::vector<uint32> ids;WorldPacket(int op,int n):opcode(op),size(n){}WorldPacket& operator<<(uint32 n){ids.push_back(n);return *this;}};
struct Session {
 std::vector<uint32> book;std::vector<uint32> bars;
 void remove(uint32 id){auto i=std::find(book.begin(),book.end(),id);if(i!=book.end())book.erase(i);}
 void SendPacket(WorldPacket* p){assert(p->ids.size()==2);remove(p->ids[0]);
  if(p->opcode==SMSG_REMOVED_SPELL){assert(p->size==5&&p->ids[1]==0);return;}
  book.push_back(p->ids[1]);for(auto& b:bars)if(b==p->ids[0])b=p->ids[1];}
};
struct Player;namespace AscensionFreePick{bool Applies(Player const*);}
struct Player {
 bool area52=true;Session session;PlayerSpellMap m_spells;std::map<uint32,Spell> storage;std::map<uint32,uint32> m_temporarySpellReplacements;
 bool HasSpell(uint32 id)const{return m_spells.contains(id);}bool HasActiveSpell(uint32 id)const{return HasSpell(id);}
 int getClass(){return 1;}bool IsInWorld(){return true;}uint8 GetLearnSpellSpecMask(uint32){return 1;}Session* GetSession(){return &session;}
 int m_activeSpec=0;
 void SendLearnPacket(uint32 id,bool learn){if(learn)session.book.push_back(id);else session.remove(id);}
 bool addSpell(uint32 id,uint8,bool,bool temporary,bool skill){m_spells[id]=&storage[id];if(temporary&&!skill)SendLearnPacket(id,true);return true;}
 void learnSpell(uint32,bool=false,bool=false,bool=true);
 uint32 GetTemporarySpellReplacement(uint32) const;
 void SetTemporarySpellReplacement(uint32,uint32);
};
namespace AscensionFreePick{bool Applies(Player const* p){return p->area52;}}
'''
    code=prefix
    for signature in ('void Player::learnSpell(', 'uint32 Player::GetTemporarySpellReplacement(', 'void Player::SetTemporarySpellReplacement('):
        code+=block(player,signature)+'\n'
    code+=r'''
int main(){
 Player p;p.learnSpell(20243);p.learnSpell(954082,false,false,false);
 p.session.bars={20243,999};
 p.session.book={20243,954082};
 p.SetTemporarySpellReplacement(20243,954082);
 assert(std::count(p.session.book.begin(),p.session.book.end(),954082)==(FIXED?1:2));
 assert(p.session.bars==std::vector<uint32>({954082,999}));
 p.SetTemporarySpellReplacement(20243,954082);
 if(FIXED){
   p.SetTemporarySpellReplacement(20243,0);
   assert(std::count(p.session.book.begin(),p.session.book.end(),20243)==1);
   assert(std::count(p.session.book.begin(),p.session.book.end(),954082)==1);
   for(int login=0;login<20;++login){p.m_temporarySpellReplacements.clear();p.session.book={20243,954082};p.SetTemporarySpellReplacement(20243,954082);assert(p.session.book==std::vector<uint32>{954082});}
   Player during;scripts.hook=[&](uint32 id){if(id==20243){during.learnSpell(954082,false,false,false);during.SetTemporarySpellReplacement(20243,954082);}};
   during.learnSpell(20243);assert(during.session.book==std::vector<uint32>{954082});scripts.hook=[](uint32){};
   Player normal;normal.learnSpell(100);assert(normal.session.book==std::vector<uint32>{100});
   Player nimble;nimble.learnSpell(6117);nimble.learnSpell(978701);nimble.SetTemporarySpellReplacement(6117,978701);assert(nimble.session.book==std::vector<uint32>{978701});
   for(auto pair:std::vector<std::pair<uint32,uint32>>{{20243,954082},{302035,954443},{302036,954444},{302037,954445},{302038,954446},{30016,954447},{30022,954448},{47497,954449},{47498,954450},{47540,92754},{26573,926574},{14251,983241}}){
     Player rank;rank.learnSpell(pair.first);rank.learnSpell(pair.second);rank.session.bars={pair.first,pair.second,777};
     rank.SetTemporarySpellReplacement(pair.first,pair.second);
     assert(rank.session.book==std::vector<uint32>{pair.second});
     assert(rank.session.bars==std::vector<uint32>({pair.second,pair.second,777}));
     rank.m_spells.erase(pair.second);rank.session.remove(pair.second);rank.SetTemporarySpellReplacement(pair.first,0);
     assert(rank.session.book==std::vector<uint32>{pair.first});
   }
   Player elsewhere;elsewhere.area52=false;elsewhere.learnSpell(20243);elsewhere.learnSpell(954082);
   elsewhere.SetTemporarySpellReplacement(20243,954082);assert(elsewhere.session.book.size()==2);
   Player absent;absent.SetTemporarySpellReplacement(20243,954082);assert(absent.session.book.empty());
 }
}
'''.replace('FIXED','true' if variant=='source' else 'false')
    run(code,'packets-'+variant)
    starter=block(compat,'  static void LearnHeroProficiencies(') if variant=='source' else ''
    before=block(compat,'  void PrepareHeroProficienciesBeforeMap(') if variant=='source' else ''
    login=compat[compat.index('  void OnPlayerLogin(Player *player) {'):]
    login=login[login.index('{')+1:login.index('    if (!IsAscensionCustomClass(player))')]
    code=r'''
#include <array>
#include <cassert>
#include <cstdint>
#include <set>
using uint32=uint32_t;constexpr int CLASS_HERO=10;
struct Manager{bool GetSpellInfo(uint32){return true;}}manager;auto* sSpellMgr=&manager;
struct Session{bool loading=true;bool PlayerLoading(){return loading;}};
struct Player {Session s;bool world=false;int cls=10;int wandNotices=0,initials=0;std::set<uint32> known;
 bool IsInWorld(){return world;}Session* GetSession(){return &s;}int getClass(){return cls;}
 bool HasSpell(uint32 id){return known.contains(id);}
 void learnSpell(uint32 id,bool){known.insert(id);if(id==5009){known.insert(5019);if(world)++wandNotices;}}
 void SendInitialSpells(){++initials;}
};
struct Service {
 STARTER
 BEFORE
 void login(Player* player){LOGIN}
};
int main(){Player p;Service service;
 PREPARE
 p.world=true;p.s.loading=false;service.login(&p);
 assert(p.HasSpell(5009)&&p.HasSpell(5019));assert(p.wandNotices==(FIXED?0:1));
 service.login(&p);assert(p.wandNotices==(FIXED?0:1));
 Player other;other.cls=1;
 PREPARE_OTHER
 assert(other.known.empty());
}
'''.replace('STARTER',starter).replace('BEFORE',before).replace('LOGIN',login).replace('PREPARE_OTHER','service.PrepareHeroProficienciesBeforeMap(&other);' if variant=='source' else '').replace('PREPARE','service.PrepareHeroProficienciesBeforeMap(&p);' if variant=='source' else '').replace('FIXED','true' if variant=='source' else 'false')
    run(code,'proficiencies-'+variant)
print('Baseline defects reproduced; actual candidate tier restoration, packet normalization and pre-map proficiency methods pass. Client packet and Player adapters are not live gameplay.')
