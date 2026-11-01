from pathlib import Path
import subprocess
T=Path('/results')
source=(T/'source/src/server/coa/AscensionMysticEnchant.cpp').read_text()
baseline=(T/'baseline/src/server/coa/AscensionMysticEnchant.cpp').read_text()
def block(text,marker):
    start=text.index(marker);pos=text.index('{',start);end=pos+1;depth=1
    while depth:
        depth+=(text[end]=='{')-(text[end]=='}');end+=1
    return text[start:end]
assert block(source,'bool GrantDraftReward(')==block(baseline,'bool GrantDraftReward(')
assert 'AddTestAccess(owner, current->Known);' in source
assert 'AddTestAccess(player, known);' in source
code=r'''
#include <boost/property_tree/json_parser.hpp>
#include <cassert>
#include <fstream>
#include <map>
#include "source/src/server/coa/Area52MysticTestAccess.h"
using uint32=std::uint32_t;
using namespace AscensionMysticEnchant;
#define LOG_ERROR(...) ((void)0)
#define LOG_INFO(...) ((void)0)
bool Active=false;
std::set<uint32> TestAccess,TestAccessExcludedAccounts;
struct {std::map<uint32,int> BySpell;} Data;
std::map<uint32,int> Connected;
struct Config {
 std::string excluded="32",file="/results/report-fixture.json";bool enabled=true;
 template<class T> T GetOption(std::string const& name,T fallback) {
  if constexpr(std::is_same_v<T,bool>) return enabled;
  else return name.find("ExcludedAccounts")!=std::string::npos?excluded:file;
 }
} config;
Config* sConfigMgr=&config;
struct Session {uint32 id;uint32 GetAccountId(){return id;}};
struct Player {Session* s;Session* GetSession(){return s;}};
'''+block(source,'void AddTestAccess(')+'\n'+block(source,'void RefreshTestAccess()')+r'''
int main(){
 assert(ParseTestAccessExcludedAccounts("").empty());
 assert(ParseTestAccessExcludedAccounts("32, 33,32")==std::set<uint32>({32,33}));
 for(auto text:{"0","-1","32,","32,,33","garbage","4294967296","32 x"}){
  bool rejected=false;try{ParseTestAccessExcludedAccounts(text);}catch(std::exception const&){rejected=true;}assert(rejected);
 }
 std::ofstream(config.file)<<R"({"schema":1,"entries":[{"kind":"mystic","id":101,"status":"VERIFIED"},{"kind":"mystic","id":102,"status":"CERTIFIED"}]})";
 Data.BySpell={{101,0},{102,0}};Connected=Data.BySpell;
 Session excluded{32},tester{33};Player owner{&excluded},other{&tester};std::set<uint32> known;
 RefreshTestAccess();AddTestAccess(&owner,known);assert(known.empty());
 Active=true;RefreshTestAccess();assert(TestAccess==std::set<uint32>({101,102}));
 AddTestAccess(&owner,known);assert(known.empty());
 AddTestAccess(&other,known);assert(known==TestAccess);
 known={999};AddTestAccess(&owner,known);assert(known==std::set<uint32>({999}));
 known.insert(101);AddTestAccess(&owner,known);assert(known==std::set<uint32>({101,999}));
 for(int i=0;i<20;++i){RefreshTestAccess();AddTestAccess(&owner,known);assert(known==std::set<uint32>({101,999}));}
 config.excluded="33";RefreshTestAccess();known.clear();AddTestAccess(&other,known);assert(known.empty());
 AddTestAccess(&owner,known);assert(known==TestAccess);
 config.excluded="";RefreshTestAccess();known.clear();AddTestAccess(&other,known);assert(known==TestAccess);
 config.excluded="bad";RefreshTestAccess();assert(TestAccess.empty());
 config.excluded="32";config.enabled=false;RefreshTestAccess();assert(TestAccess.empty());
 AddTestAccess(nullptr,known);
}
'''
(T/'native.cpp').write_text(code)
subprocess.run(['g++','-std=c++20','-Wall','-Wextra',str(T/'native.cpp'),'-o',str(T/'native-check')],check=True)
subprocess.run([str(T/'native-check')],check=True)
print('PASS native exclusion parser, cold startup/refresh, per-account grants, permanent ownership preservation, and unchanged Draft reward implementation')
