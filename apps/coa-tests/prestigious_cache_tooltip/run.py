from pathlib import Path
import subprocess,tempfile
r=Path(__file__).resolve().parents[3]
after=(r/"src/server/game/Handlers/ItemHandler.cpp").read_text()
start=after.index('        uint32 const requiredLevel =')
end=after.index('        queryData << pProto->RequiredSkill;',start)
block=after[start:end]
code=r'''
#include <cassert>
#include <cstdint>
#include <string>
using uint32=std::uint32_t;
constexpr int CONFIG_MAX_PLAYER_LEVEL=1;
struct World {unsigned cap;unsigned getIntConfig(int){return cap;}} world,*sWorld=&world;
struct Manager {unsigned id=7;unsigned GetScriptId(std::string const& name){assert(name=="item_ascension_prestigious_cache");return id;}} manager,*sObjectMgr=&manager;
struct Item {unsigned ScriptId,RequiredLevel;};
struct Packet {unsigned value=0,bytes=0;void operator<<(uint32 n){value=n;bytes+=sizeof(n);}};
unsigned query(Item const* pProto){Packet queryData;
'''+block+r'''
assert(queryData.bytes==4);return queryData.value;}
int main(){Item cache{7,60},other{8,35},unbound{0,60};
for(unsigned cap:{60,70,80}){world.cap=cap;assert(query(&cache)==cap);assert(query(&other)==35);assert(query(&unbound)==60);}
world.cap=80;assert(cache.RequiredLevel==60 && cache.RequiredLevel!=query(&cache));
manager.id=0;assert(query(&unbound)==60);assert(query(&cache)==60);
}
'''
with tempfile.TemporaryDirectory() as folder:
 p=Path(folder)/'check.cpp';p.write_text(code);exe=p.with_suffix('')
 subprocess.run(['g++','-std=c++20',str(p),'-o',str(exe)],check=True)
 subprocess.run([str(exe)],check=True)
print('PASS extracted query serialization: caps60/70/80, uint32 width, unrelated/unbound items, missing script guard; configured cap serialized; item record unchanged.')
