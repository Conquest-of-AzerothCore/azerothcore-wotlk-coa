import os
from pathlib import Path
import runpy
import shutil
import sqlite3
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def main():
    source = (ROOT / "src/server/coa/AscensionTravelPermit.cpp").read_text(encoding="utf-8")
    shared = (ROOT / "src/server/shared/SharedDefines.h").read_text(encoding="utf-8")
    code = "#include <array>\n#include <cassert>\n#include <cstdint>\n#include <vector>\n"
    code += "using uint8=std::uint8_t;using uint32=std::uint32_t;\n"
    for enum in ("TeamId", "Races", "SpellCastResult"):
        code += method(shared, "enum " + enum) + ";\n"
    code += r'''
constexpr uint32 GOSSIP_ICON_TAXI=1, DEFAULT_GOSSIP_MESSAGE=1;
struct Item {uint32 id=977028;uint32 GetEntry()const{return id;}uint32 GetGUID()const{return 42;}};
struct MapEntry {uint32 expansion;uint32 Expansion()const{return expansion;}};
struct MapStore
{
    MapEntry azeroth{0},outland{1};
    MapEntry const* LookupEntry(uint32 id)const{return id==530?&outland:&azeroth;}
} sMapStore;
struct Session {uint32 expansion=2;uint32 Expansion()const{return expansion;}};
struct Player
{
    uint32 level=1;TeamId team=TEAM_ALLIANCE;bool alive=true,combat=false;Session session;
    std::vector<uint32> menu;uint32 shown=0,closed=0,teleports=0,destination=0;float x=0;
    Session const* GetSession()const{return &session;}
    Player* ToPlayer(){return this;}uint32 GetLevel()const{return level;}uint32 getClass()const{return 29;}
    bool IsAlive()const{return alive;}bool IsInCombat()const{return combat;}TeamId GetTeamId()const{return team;}
    void TeleportTo(uint32 map,float tx,float,float,float){++teleports;destination=map;x=tx;}
};
struct PlayerInfo{uint32 mapId;float positionX=1,positionY=2,positionZ=3,orientation=4;};
struct Manager
{
    uint32 missing=0;PlayerInfo row{};
    PlayerInfo const* GetPlayerInfo(uint32 race,uint32 cls){assert(cls==29);row.mapId=race;return race==missing?nullptr:&row;}
} manager;
auto sObjectMgr=&manager;
void ClearGossipMenuFor(Player* p){p->menu.clear();}
void CloseGossipMenuFor(Player* p){++p->closed;}
void AddGossipItemFor(Player* p,uint32,char const*,uint32 sender,uint32 action)
{assert(sender==977028);p->menu.push_back(action);}
void SendGossipMenuFor(Player* p,uint32,uint32 guid){assert(guid==42);++p->shown;}
'''
    code += source[source.index("enum TravelPermit"):source.index("class spell_ascension_travel_permit")]
    code += "struct PermitSpell {Player* player;Item* item;Player* GetCaster(){return player;}"
    code += "Item* GetCastItem(){return item;}\n"
    for signature in ("bool Load()", "SpellCastResult CheckCast()", "void OpenMenu("):
        code += method(source, signature).replace(" override", "")
    code += "};struct PermitItem {" + method(source, "void OnGossipSelect(").replace(" override", "") + "};\n"
    code += r'''
int main()
{
    Item item;PermitItem select;
    for (TeamId team : {TEAM_ALLIANCE,TEAM_HORDE}) for (uint32 level : {1u,8u})
    {
        Player p;p.team=team;p.level=level;PermitSpell spell{&p,&item};
        assert(spell.Load() && spell.CheckCast()==SPELL_CAST_OK);spell.OpenMenu();
        assert(p.shown==1 && p.menu.size()==4);
        auto actions=p.menu;
        bool starter=false;
        for (uint32 action:actions)
            starter=starter||Destinations[action].race==(team==TEAM_ALLIANCE?RACE_DRAENEI:RACE_BLOODELF);
        assert(starter);  // The Draenei and Blood Elf starts are offered, not just the six vanilla ones.
        for (uint32 action:actions)
        {
            auto before=p.teleports;select.OnGossipSelect(&p,&item,SenderTravelPermit,action);
            assert(p.teleports==before+1 && p.destination==Destinations[action].mapId && p.menu.empty());
            assert(p.x==Destinations[action].x);
        }
        auto before=p.teleports;
        select.OnGossipSelect(&p,&item,SenderTravelPermit,team==TEAM_ALLIANCE?4:0);
        select.OnGossipSelect(&p,&item,SenderTravelPermit,99);
        select.OnGossipSelect(&p,&item,0,actions[0]);
        assert(p.teleports==before);
        p.level=9;assert(spell.CheckCast()==SPELL_FAILED_HIGHLEVEL);
        select.OnGossipSelect(&p,&item,SenderTravelPermit,actions[0]);assert(p.teleports==before);
        p.level=8;p.combat=true;assert(spell.CheckCast()==SPELL_FAILED_AFFECTING_COMBAT);
        select.OnGossipSelect(&p,&item,SenderTravelPermit,actions[0]);assert(p.teleports==before);
        p.combat=false;p.alive=false;assert(spell.CheckCast()==SPELL_FAILED_CASTER_DEAD);
    }
    for (TeamId team : {TEAM_ALLIANCE,TEAM_HORDE})
    {
        Player p;p.team=team;p.session.expansion=0;PermitSpell spell{&p,&item};spell.OpenMenu();
        assert(p.shown==1 && p.menu.size()==3);
        for (uint32 action:p.menu)
            assert(Destinations[action].mapId!=530);
        uint32 outland=team==TEAM_ALLIANCE?3:7;
        assert(Destinations[outland].mapId==530 && Destinations[outland].team==team);
        select.OnGossipSelect(&p,&item,SenderTravelPermit,outland);assert(!p.teleports);
        p.session.expansion=1;select.OnGossipSelect(&p,&item,SenderTravelPermit,outland);
        assert(p.teleports==1 && p.destination==530);
    }
    Player p;PermitSpell spell{&p,&item};manager.missing=RACE_HUMAN;spell.OpenMenu();
    assert(p.menu.size()==3);select.OnGossipSelect(&p,&item,SenderTravelPermit,0);assert(!p.teleports);
    item.id=1;assert(!spell.Load());select.OnGossipSelect(&p,&item,SenderTravelPermit,1);assert(!p.teleports);
    spell.item=nullptr;assert(!spell.Load());spell.OpenMenu();
}
'''
    assert "OnCheckCast += SpellCheckCastFn" in source and "AfterCast += SpellCastFn" in source
    assert "bool OnUse(" not in source
    compiler = shutil.which(os.environ.get("CXX", "g++"))
    assert compiler, "Set CXX to a C++17 compiler."
    with tempfile.TemporaryDirectory(prefix="coa-travel-permit-") as directory:
        out = Path(directory)
        cpp, exe = out / "permit.cpp", out / "permit.exe"
        cpp.write_text(code, encoding="utf-8")
        subprocess.run([compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)],
                       cwd=out, check=True)
        subprocess.run([str(exe)], cwd=out, check=True)
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_1789359910633744100.sql").read_text()
    db = sqlite3.connect(":memory:")
    db.executescript("CREATE TABLE item_template(entry INT,ScriptName TEXT);"
                    "CREATE TABLE spell_script_names(spell_id INT,ScriptName TEXT);"
                    "INSERT INTO item_template VALUES(977028,''),(1,'keep');"
                    "INSERT INTO spell_script_names VALUES(1001088,'keep');")
    db.executescript(sql);db.executescript(sql)
    assert db.execute("SELECT * FROM item_template ORDER BY entry").fetchall() == [
        (1,"keep"),(977028,"item_ascension_travel_permit")]
    assert db.execute("SELECT COUNT(*) FROM spell_script_names").fetchone() == (2,)
    print("PASS: faction destinations, session expansion maps, level/combat/death gates, stale selections, "
          "missing starts and SQL bindings")


if __name__ == "__main__":
    main()
