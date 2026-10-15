import os
from pathlib import Path
import runpy
import shutil
import sqlite3
import struct
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]

HARNESS = r'''
#include <array>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <optional>
#include <utility>
#include <vector>
using uint8=std::uint8_t;using uint32=std::uint32_t;
// ENUMS
enum SpellEffIndex : uint8 { EFFECT_0 = 0 };
enum Rates { RATE_DURABILITY_LOSS_ON_SPIRIT_RESURRECT };
enum TeleportToOptions : uint32 { TELE_TO_SPELL = 0x10 };
struct Map { bool instanceable = false; bool Instanceable() const { return instanceable; } };
struct Battlefield { bool war = false; bool IsWarTime() const { return war; } };
struct Teleport { uint32 map; float x; float y; float z; float o; uint32 options; };
struct Player
{
    TeamId team = TEAM_ALLIANCE; uint32 level = 80, mapId = 0, zone = 1; float x = 0, y = 0, z = 0, o = 2;
    bool alive = false, veto = false; Map* map = nullptr;
    std::vector<Teleport> teleports; std::vector<float> resurrected; std::vector<bool> sickness;
    std::vector<double> durability; uint32 bones = 0;
    Player* ToPlayer() { return this; }
    bool IsAlive() const { return alive; }
    uint32 GetLevel() const { return level; }
    TeamId GetTeamId() const { return team; }
    uint32 GetMapId() const { return mapId; }
    uint32 GetZoneId() const { return zone; }
    Map* GetMap() const { return map; }
    float GetOrientation() const { return o; }
    float GetPositionX() const { return x; }
    float GetPositionY() const { return y; }
    float GetPositionZ() const { return z; }
    float GetExactDist2dSq(float px, float py) const { return (px - x) * (px - x) + (py - y) * (py - y); }
    void ResurrectPlayer(float percent, bool sick) { resurrected.push_back(percent); sickness.push_back(sick); alive = !veto; }
    void DurabilityLossAll(double percent, bool inventory) { assert(inventory); durability.push_back(percent); }
    void SpawnCorpseBones() { ++bones; }
    void TeleportTo(uint32 m, float px, float py, float pz, float po, uint32 options)
    { teleports.push_back({ m, px, py, pz, po, options }); }
};
// PROGRESS
struct ScriptMgr
{
    std::vector<std::pair<CoAProgressEvent, uint32>> events;
    void OnPlayerCoAProgress(Player*, CoAProgressEvent event, uint32 value) { events.push_back({ event, value }); }
} scripts;
auto sScriptMgr = &scripts;
bool reportedOnce(uint32 spell)
{
    bool const reported = scripts.events.size() == 1 && scripts.events[0].first == CoAProgressEvent::ClosestResurrection
        && scripts.events[0].second == spell;
    scripts.events.clear();
    return reported;
}
struct SpellInfo { uint32 Id; };
struct TaxiNodesEntry { uint32 map_id = 0; float x = 0, y = 0, z = 0; };
struct TaxiNodesStore
{
    TaxiNodesEntry entry;
    TaxiNodesEntry const* LookupEntry(uint32 id) { return id ? &entry : nullptr; }
} sTaxiNodesStore;
struct ObjectMgr
{
    uint32 node = 0;
    uint32 GetNearestTaxiNode(float, float, float, uint32, uint32) { return node; }
} objectMgr;
auto sObjectMgr = &objectMgr;
struct Battlefields
{
    Battlefield field; uint32 zone = 0;
    Battlefield* GetBattlefieldToZoneId(uint32 id) { return id == zone ? &field : nullptr; }
} battlefields;
auto sBattlefieldMgr = &battlefields;
struct World { float rate = 0.0f; float getRate(Rates) const { return rate; } } realm;
auto sWorld = &realm;

// SOURCE

struct Script
{
    Player* caster; SpellInfo info;
    Player* GetCaster() { return caster; }
    SpellInfo const* GetSpellInfo() { return &info; }
// METHODS
};

Player make(TeamId team, uint32 map, float x, float y, Map* area)
{
    Player p; p.team = team; p.mapId = map; p.x = x; p.y = y; p.map = area; return p;
}

int main()
{
    Map open, dungeon; dungeon.instanceable = true;

    // Closest Town: the nearest flight-master town of the player's faction.
    {
        Player p = make(TEAM_HORDE, 1, -2725.0f, -1115.0f, &open);
        Script town{ &p, { SPELL_RESURRECT_CLOSEST_TOWN } };
        assert(town.Load());
        objectMgr.node = 1;
        sTaxiNodesStore.entry = TaxiNodesEntry{ 1, -2350.0f, -360.0f, -9.0f };
        assert(town.CheckCast() == SPELL_CAST_OK);
        realm.rate = 25.0f;
        town.Resurrect(EFFECT_0);
        assert(reportedOnce(SPELL_RESURRECT_CLOSEST_TOWN));
        assert(p.alive && p.resurrected == std::vector<float>{ 0.5f } && p.sickness == std::vector<bool>{ true });
        assert(p.durability == std::vector<double>{ 0.25 } && p.bones == 1 && p.teleports.size() == 1);
        assert(p.teleports[0].map == 1 && p.teleports[0].x == -2350.0f && p.teleports[0].y == -360.0f);
        assert(p.teleports[0].z == -9.0f && p.teleports[0].o == p.o && p.teleports[0].options == TELE_TO_SPELL);

        // Alive players are refused, and an effect that still fires does nothing to them.
        assert(town.CheckCast() == SPELL_FAILED_TARGET_NOT_DEAD);
        town.Resurrect(EFFECT_0);
        assert(p.teleports.size() == 1 && p.resurrected.size() == 1 && scripts.events.empty());

        // The durability loss follows the realm rate, and no rate means none.
        Player q = make(TEAM_HORDE, 1, 0, 0, &open); realm.rate = 0.0f;
        Script again{ &q, { SPELL_RESURRECT_CLOSEST_TOWN } };
        again.Resurrect(EFFECT_0);
        assert(q.alive && q.durability.empty() && q.teleports.size() == 1 && reportedOnce(SPELL_RESURRECT_CLOSEST_TOWN));

        // No reachable town leaves the spell unusable.
        Player r = make(TEAM_HORDE, 1, 0, 0, &open); objectMgr.node = 0;
        Script none{ &r, { SPELL_RESURRECT_CLOSEST_TOWN } };
        assert(none.CheckCast() == SPELL_FAILED_NOT_HERE);
        none.Resurrect(EFFECT_0);
        assert(!r.alive && r.teleports.empty() && r.resurrected.empty() && scripts.events.empty());
        objectMgr.node = 1;

        // Dungeons, battlegrounds and arenas use the ordinary way back.
        Player d = make(TEAM_HORDE, 1, 0, 0, &dungeon);
        Script inside{ &d, { SPELL_RESURRECT_CLOSEST_TOWN } };
        assert(inside.CheckCast() == SPELL_FAILED_NOT_HERE);

        // A Wintergrasp battle keeps its resurrection queue; outside it the zone is ordinary.
        Player w = make(TEAM_HORDE, 571, 0, 0, &open); w.zone = 4197; battlefields.zone = 4197;
        Script wintergrasp{ &w, { SPELL_RESURRECT_CLOSEST_TOWN } };
        battlefields.field.war = true;
        assert(wintergrasp.CheckCast() == SPELL_FAILED_NOT_HERE);
        battlefields.field.war = false;
        assert(wintergrasp.CheckCast() == SPELL_CAST_OK);
        battlefields.zone = 0;
    }

    // A script that refuses the resurrection, such as a failed permadeath challenge, keeps the player where they are.
    {
        Player p = make(TEAM_ALLIANCE, 0, 0, 0, &open); p.veto = true; realm.rate = 25.0f;
        Script town{ &p, { SPELL_RESURRECT_CLOSEST_TOWN } };
        town.Resurrect(EFFECT_0);
        assert(!p.alive && p.resurrected.size() == 1 && p.durability.empty() && !p.bones && p.teleports.empty());
        assert(scripts.events.empty());
    }

    // Closest City: level gate, then the nearest capital of the player's own faction.
    struct Case { TeamId team; uint32 map; float x; float y; uint32 destMap; float destX; };
    Case const cases[] =
    {
        { TEAM_ALLIANCE, 0, -9000.0f, 400.0f, 0, -8833.38f },       // Elwynn Forest -> Stormwind
        { TEAM_ALLIANCE, 0, -5600.0f, -500.0f, 0, -4918.88f },      // Dun Morogh -> Ironforge
        { TEAM_ALLIANCE, 1, 1629.0f, -4373.0f, 1, 9949.56f },       // next to Orgrimmar -> Darnassus, never Orgrimmar
        { TEAM_ALLIANCE, 530, 0.0f, 0.0f, 530, -3965.7f },          // Outland -> The Exodar
        { TEAM_ALLIANCE, 571, 0.0f, 0.0f, 0, -8833.38f },           // Northrend -> Stormwind
        { TEAM_HORDE, 1, -2725.0f, -1115.0f, 1, -1277.37f },        // Mulgore -> Thunder Bluff
        { TEAM_HORDE, 1, 1000.0f, -4000.0f, 1, 1629.85f },          // Durotar -> Orgrimmar
        { TEAM_HORDE, 0, -8833.0f, 628.0f, 0, 1584.14f },           // next to Stormwind -> Undercity, never Stormwind
        { TEAM_HORDE, 530, 0.0f, 0.0f, 530, 9487.69f },             // Outland -> Silvermoon City
        { TEAM_HORDE, 571, 0.0f, 0.0f, 1, 1629.85f },               // Northrend -> Orgrimmar
    };
    for (Case const& c : cases)
    {
        Player p = make(c.team, c.map, c.x, c.y, &open); p.level = 10; realm.rate = 0.0f;
        Script city{ &p, { SPELL_RESURRECT_CLOSEST_CITY } };
        assert(city.CheckCast() == SPELL_CAST_OK);
        city.Resurrect(EFFECT_0);
        assert(p.alive && p.teleports.size() == 1 && p.bones == 1);
        assert(p.teleports[0].map == c.destMap && p.teleports[0].x == c.destX && p.teleports[0].options == TELE_TO_SPELL);
        assert(p.resurrected == std::vector<float>{ 0.5f } && p.sickness == std::vector<bool>{ true });
        assert(reportedOnce(SPELL_RESURRECT_CLOSEST_CITY));
    }

    Player low = make(TEAM_ALLIANCE, 0, 0, 0, &open); low.level = 9;
    Script gated{ &low, { SPELL_RESURRECT_CLOSEST_CITY } };
    assert(gated.CheckCast() == SPELL_FAILED_LEVEL_REQUIREMENT);
    // The town spell has no level requirement.
    objectMgr.node = 1;
    sTaxiNodesStore.entry = TaxiNodesEntry{ 0, 1.0f, 2.0f, 3.0f };
    Script lowTown{ &low, { SPELL_RESURRECT_CLOSEST_TOWN } };
    assert(lowTown.CheckCast() == SPELL_CAST_OK);
    return 0;
}
'''


def build_harness(source):
    shared = (ROOT / "src/server/shared/SharedDefines.h").read_text(encoding="utf-8")
    enums = "".join(method(shared, "enum " + name) + ";\n" for name in ("TeamId", "SpellCastResult"))
    player_script = (ROOT / "src/server/game/Scripting/ScriptDefines/PlayerScript.h").read_text(encoding="utf-8")
    progress = method(player_script, "enum class CoAProgressEvent") + ";\n"
    start = source.index("enum ClosestResurrection")
    end = source.index("class spell_ascension_closest_resurrection")
    body = source[start:end]
    methods = "".join(method(source, signature).replace(" override", "")
                      for signature in ("bool Load()", "std::optional<Destination> FindDestination(",
                                        "SpellCastResult CheckCast()", "void Resurrect("))
    return (HARNESS.replace("// ENUMS", enums).replace("// PROGRESS", progress).replace("// SOURCE", body)
            .replace("// METHODS", methods))


def compile_and_run(code):
    with tempfile.TemporaryDirectory(prefix="coa-closest-resurrection-", ignore_cleanup_errors=True) as directory:
        out = Path(directory)
        cpp, exe = out / "closest.cpp", out / "closest.exe"
        cpp.write_text(code, encoding="utf-8")
        msvc = shutil.which("cl")
        if msvc is None and os.environ.get("VCToolsInstallDir"):
            msvc = str(Path(os.environ["VCToolsInstallDir"]) / "bin/Hostx64/x64/cl.exe")
        if msvc:
            command = [msvc, "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8", "/UNDEBUG",
                       str(cpp), "/Fe" + str(exe)]
        else:
            compiler = shutil.which(os.environ.get("CXX", "g++"))
            assert compiler, "Run from a Visual Studio developer prompt or set CXX to a C++17 compiler."
            command = [compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)]
        subprocess.run(command, cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)


def check_client_spells(path):
    raw = Path(path).read_bytes()
    count = struct.unpack_from("<I", raw, 4)[0]
    wanted = {84423, 84433}
    rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936]) if r[0] in wanted}
    assert set(rows) == wanted
    for row in rows.values():
        assert row[71] == 3
        assert row[4] & 0x800000


def main():
    source = (ROOT / "src/server/coa/AscensionClosestResurrection.cpp").read_text(encoding="utf-8")
    assert "OnCheckCast += SpellCheckCastFn" in source
    assert "OnEffectHit += SpellEffectFn(spell_ascension_closest_resurrection::Resurrect, EFFECT_0, SPELL_EFFECT_DUMMY)" in source
    assert "PLAYERHOOK_ON_LOGIN" in source and "learnSpell(spellId, false)" in source
    loader = (ROOT / "src/server/coa/CoAScriptLoader.cpp").read_text(encoding="utf-8")
    assert loader.count("AddSC_AscensionClosestResurrection();") == 2
    compile_and_run(build_harness(source))
    if os.environ.get("COA_CLIENT_DBC"):
        check_client_spells(os.environ["COA_CLIENT_DBC"])

    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260919_10_closest_resurrection.sql").read_text()
    db = sqlite3.connect(":memory:")
    db.executescript("CREATE TABLE spell_script_names(spell_id INT,ScriptName TEXT);"
                     "INSERT INTO spell_script_names VALUES(84423,'keep'),(84420,'spell_ascension_ruleset_select');"
                     "INSERT INTO spell_script_names VALUES(84433,'spell_ascension_closest_resurrection');")
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert list(db.iterdump()) == before
    assert db.execute("SELECT spell_id FROM spell_script_names WHERE ScriptName='spell_ascension_closest_resurrection' "
                      "ORDER BY 1").fetchall() == [(84423,), (84433,)]
    assert db.execute("SELECT COUNT(*) FROM spell_script_names WHERE ScriptName IN ('keep','spell_ascension_ruleset_select')"
                      ).fetchone() == (2,)
    print("PASS: town and city destinations, level/death/instance/Wintergrasp gates, vetoed resurrection, "
          "progress reports and SQL binding")


if __name__ == "__main__":
    main()
