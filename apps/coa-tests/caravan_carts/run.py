import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]
MIGRATIONS = ("rev_20260924_50_coa_road_caravans.sql", "rev_20260924_51_coa_barrens_caravans.sql")
KALIMDOR_INSTANCE = 33
UNKNOWN_MAP = 9999

HARNESS = r'''
#include <algorithm>
#include <array>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <format>
#include <map>
#include <set>
#include <string>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>
using int8 = std::int8_t;
using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
// GRID
// HOOKS
// MAPTYPES
struct MapEntry
{
    uint32 map_type = MAP_COMMON;
    // INSTANCEABLE
};
struct MapStore
{
    std::map<uint32, MapEntry> entries;
    MapEntry const* LookupEntry(uint32 id) const
    {
        auto found = entries.find(id);
        return found == entries.end() ? nullptr : &found->second;
    }
} sMapStore;
struct CreatureData
{
    uint32 id = 0;
    uint16 mapid = 0;
    float posX = 0.0f;
    float posY = 0.0f;
};
struct ObjectMgr
{
    std::unordered_map<uint32, CreatureData> spawns;
    std::unordered_map<uint32, CreatureData> const& GetAllCreatureData() const { return spawns; }
} objectMgr;
ObjectMgr* sObjectMgr = &objectMgr;
struct Map
{
    uint32 id = 0;
    std::vector<std::pair<float, float>> loads;
    void LoadGrid(float x, float y) { loads.emplace_back(x, y); }
};
struct MapMgr
{
    std::map<uint32, Map> maps;
    Map* CreateBaseMap(uint32 id)
    {
        MapEntry const* entry = sMapStore.LookupEntry(id);
        assert(entry && !entry->Instanceable());
        Map& map = maps[id];
        map.id = id;
        return &map;
    }
} mapMgr;
MapMgr* sMapMgr = &mapMgr;
std::vector<std::string> infoLines;
template <class... Args>
void LogInfo(char const* category, std::format_string<Args...> text, Args&&... args)
{
    assert(std::string(category) == "server.loading");
    infoLines.push_back(std::format(text, std::forward<Args>(args)...));
}
#define LOG_INFO(category, ...) LogInfo(category, __VA_ARGS__)
struct WorldScript;
std::vector<WorldScript*> worldScripts;
struct WorldScript
{
    std::string name;
    std::vector<uint16> hooks;
    WorldScript(char const* scriptName, std::vector<uint16> enabledHooks) : name(scriptName), hooks(enabledHooks)
    {
        worldScripts.push_back(this);
    }
    virtual ~WorldScript() = default;
    virtual void OnStartup() { }
    virtual void OnBeforeWorldInitialized() { }
};

// SOURCE

using GridKey = std::tuple<uint32, uint32, uint32>;

GridKey KeyOf(uint32 mapId, float x, float y)
{
    GridCoord grid = Acore::ComputeGridCoord(x, y);
    return { mapId, grid.x_coord, grid.y_coord };
}

std::set<GridKey> LoadedGrids()
{
    std::set<GridKey> loaded;
    for (auto const& [mapId, map] : mapMgr.maps)
        for (auto const& [x, y] : map.loads)
            assert(loaded.insert(KeyOf(mapId, x, y)).second);
    return loaded;
}

void Reset()
{
    objectMgr.spawns.clear();
    mapMgr.maps.clear();
    infoLines.clear();
    sMapStore.entries = { { 0, { MAP_COMMON } }, { 1, { MAP_COMMON } }, { // INSTANCE_MAP, { MAP_INSTANCE } } };
}

WorldScript* Registered()
{
    worldScripts.clear();
    AddSC_AscensionCaravanCarts();
    assert(worldScripts.size() == 1);
    WorldScript* script = worldScripts.back();
    assert(script->name == "CoACaravanCartGrids");
    assert(script->hooks == std::vector<uint16>{ WORLDHOOK_ON_BEFORE_WORLD_INITIALIZED });
    return script;
}

void RoadCaravanCarts()
{
    Reset();
    objectMgr.spawns = {
// SPAWNS
    };
    std::set<GridKey> const expected = {
// EXPECTED
    };
    uint32 const cartSpawns = // CART_SPAWNS;

    WorldScript* script = Registered();
    script->OnStartup();
    assert(mapMgr.maps.empty() && infoLines.empty());
    script->OnBeforeWorldInitialized();

    assert(LoadedGrids() == expected);
    for (auto const& [mapId, map] : mapMgr.maps)
    {
        assert(map.id == mapId && (mapId == 0 || mapId == 1));
        for (auto const& [x, y] : map.loads)
        {
            bool cartHere = false;
            for (auto const& [spawnId, spawn] : objectMgr.spawns)
                cartHere |= spawn.mapid == mapId && spawn.posX == x && spawn.posY == y && IsCaravanCart(spawn);
            assert(cartHere);
        }
    }
    assert(infoLines == std::vector<std::string>{ std::format(">> Loaded {} grids for {} caravan cart spawns",
                                                              expected.size(), cartSpawns) });
    delete script;
}

void NoCarts()
{
    Reset();
    objectMgr.spawns = { { 1, { 3, 0, -9416.0f, 23.0f } }, { 2, { 50470, // INSTANCE_MAP, 0.0f, 0.0f } },
                         { 3, { 50473, // UNKNOWN_MAP, 0.0f, 0.0f } } };
    WorldScript* script = Registered();
    script->OnBeforeWorldInitialized();
    assert(mapMgr.maps.empty());
    assert(infoLines == std::vector<std::string>{ ">> Loaded 0 grids for 0 caravan cart spawns" });
    delete script;
}

int main()
{
    RoadCaravanCarts();
    NoCarts();
    return 0;
}
'''

SIZE_OF_GRIDS = 533.3333
CENTER_GRID_ID = 32


def creature_rows(sql):
    block = re.search(r"INSERT INTO `creature` \([^)]*\)\s*VALUES\s*(.*?);\s*$", sql, re.S | re.M).group(1)
    rows = []
    for match in re.finditer(r"^\((\d+), (\d+), (\d+), \d+, \d+, \d+, \d+, \d+, (-?[\d.]+), (-?[\d.]+), ", block,
                             re.M):
        guid, entry, map_id, x, y = match.groups()
        rows.append((int(guid), int(entry), int(map_id), float(x), float(y)))
    assert rows and len(rows) == block.count("\n(") + 1, "every creature row must parse"
    return rows


def grid_of(map_id, x, y):
    return (map_id, max(0, int(CENTER_GRID_ID - x / SIZE_OF_GRIDS)), max(0, int(CENTER_GRID_ID - y / SIZE_OF_GRIDS)))


def cart_entries(source):
    listed = re.search(r"constexpr std::array<uint32, (\d+)> CaravanCartEntries = \{ ([\d, ]+) \};", source)
    entries = [int(entry) for entry in listed.group(2).split(", ")]
    assert int(listed.group(1)) == len(entries)
    return set(entries)


def spawns_and_expectation(entries):
    rows = []
    for name in MIGRATIONS:
        rows += creature_rows((ROOT / "data/sql/updates/pending_db_world" / name).read_text(encoding="utf-8"))
    carts = [row for row in rows if row[1] in entries]
    assert {row[1] for row in rows} == entries, "the entry list must match the caravan cart spawns"
    assert len(carts) == 11
    decoys = [
        (9100001, 3, 0, -8000.0, 400.0),
        (9100002, 50470, KALIMDOR_INSTANCE, -3072.0, 78.0),
        (9100003, 50476, UNKNOWN_MAP, -9416.0, 23.0),
        (9100004, 50474, 0, 1.0e6, 49.0),
        (9100005, 50475, 1, 10164.0, 690.0),
    ]
    spawns = rows + decoys
    valid = [row for row in spawns if row[1] in entries and row[2] in (0, 1) and abs(row[3]) < 17066.0]
    expected = {grid_of(map_id, x, y) for _, _, map_id, x, y in valid}
    assert len(valid) == 12 and len(expected) < len(valid)
    return spawns, expected, len(valid)


def build_harness(source):
    grid_text = (ROOT / "src/server/game/Grids/GridDefines.h").read_text(encoding="utf-8")
    map_defines = (ROOT / "src/common/Collision/Maps/MapDefines.h").read_text(encoding="utf-8")
    world_script = (ROOT / "src/server/game/Scripting/ScriptDefines/WorldScript.h").read_text(encoding="utf-8")
    dbc_enums = (ROOT / "src/server/shared/DataStores/DBCEnums.h").read_text(encoding="utf-8")
    dbc_structure = (ROOT / "src/server/shared/DataStores/DBCStructure.h").read_text(encoding="utf-8")
    defines = "".join(re.search(rf"#define {name} .*\n", text).group(0) for text, name in (
        (map_defines, "MAX_NUMBER_OF_GRIDS"), (map_defines, "MAX_NUMBER_OF_CELLS"), (map_defines, "SIZE_OF_GRIDS"),
        (grid_text, "CENTER_GRID_ID"), (grid_text, "SIZE_OF_GRID_CELL"), (grid_text, "CENTER_GRID_CELL_ID"),
        (grid_text, "TOTAL_NUMBER_OF_CELLS_PER_MAP"), (grid_text, "MAP_SIZE"), (grid_text, "MAP_HALFSIZE")))
    start = grid_text.index("template<uint32 LIMIT>\nstruct CoordPair")
    end = grid_text.index("typedef CoordPair<TOTAL_NUMBER_OF_CELLS_PER_MAP> CellCoord;\n")
    grid = defines + grid_text[start:end] + "typedef CoordPair<TOTAL_NUMBER_OF_CELLS_PER_MAP> CellCoord;\n"
    grid += "#pragma warning(push)\n#pragma warning(disable: 4244)\n" if os.name == "nt" else ""
    grid += method(grid_text, "namespace Acore") + "\n"
    grid += "#pragma warning(pop)\n" if os.name == "nt" else ""
    instanceable = re.search(r"\[\[nodiscard\]\] bool Instanceable\(\) const \{[^\n]*\}", dbc_structure).group(0)
    body = "\n".join(line for line in source.splitlines() if not line.startswith("#include"))
    body, removed = re.subn(r"\nstruct npc_coa_caravan_cart : public VehicleAI\n\{.*?\n\};\n", "\n", body, flags=re.S)
    assert removed == 1, "the cart AI is outside this grid-loading harness"
    body, removed = re.subn(r"\nconstexpr \w+ (SPELL_RUN_STATE|SPELL_REINS|NPC_CARAVAN_HARNESS|DRIVER_SEAT) = [^;\n]+;",
                            "", body)
    assert removed == 4, "the cart AI's constants are outside this grid-loading harness"
    body = body.replace("    RegisterCreatureAI(npc_coa_caravan_cart);\n", "")

    spawns, expected, cart_spawns = spawns_and_expectation(cart_entries(source))
    spawn_rows = ",\n".join(f"        {{ {guid}, {{ {entry}, {map_id}, {x!r}f, {y!r}f }} }}"
                            for guid, entry, map_id, x, y in spawns)
    expected_rows = ",\n".join(f"        {{ {map_id}, {gx}, {gy} }}" for map_id, gx, gy in sorted(expected))
    return (HARNESS.replace("// GRID", grid)
            .replace("// HOOKS", method(world_script, "enum WorldHook") + ";")
            .replace("// MAPTYPES", method(dbc_enums, "enum MapTypes") + ";")
            .replace("// INSTANCEABLE", instanceable)
            .replace("// SOURCE", body)
            .replace("// SPAWNS", spawn_rows)
            .replace("// EXPECTED", expected_rows)
            .replace("// CART_SPAWNS", str(cart_spawns))
            .replace("// INSTANCE_MAP", str(KALIMDOR_INSTANCE))
            .replace("// UNKNOWN_MAP", str(UNKNOWN_MAP))), len(expected), cart_spawns


def compile_and_run(code):
    with tempfile.TemporaryDirectory(prefix="coa-caravan-carts-", ignore_cleanup_errors=True) as directory:
        out = Path(directory)
        cpp, exe = out / "carts.cpp", out / "carts.exe"
        cpp.write_text(code, encoding="utf-8")
        msvc = shutil.which("cl")
        if msvc is None and os.environ.get("VCToolsInstallDir"):
            msvc = str(Path(os.environ["VCToolsInstallDir"]) / "bin/Hostx64/x64/cl.exe")
        if msvc:
            command = [msvc, "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8", "/UNDEBUG",
                       str(cpp), "/Fe" + str(exe)]
        else:
            compiler = shutil.which(os.environ.get("CXX", "g++"))
            assert compiler, "Run from a Visual Studio developer prompt or set CXX to a C++20 compiler."
            command = [compiler, "-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)]
        subprocess.run(command, cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)


def check_startup_order():
    world = (ROOT / "src/server/game/World/World.cpp").read_text(encoding="utf-8")
    hook = world.index("sScriptMgr->OnBeforeWorldInitialized();")
    for loaded in ("sObjectMgr->LoadCreatures();", "sObjectMgr->LoadVehicleAccessories();", "sWaypointMgr->Load();",
                   "sSmartScriptMgr->LoadSmartAIFromDB();", "sMapMgr->Initialize();"):
        assert world.index(loaded) < hook, loaded
    assert hook < world.index("if (getBoolConfig(CONFIG_PRELOAD_ALL_NON_INSTANCED_MAP_GRIDS))")
    grid_loader = (ROOT / "src/server/game/Grids/GridObjectLoader.cpp").read_text(encoding="utf-8")
    assert re.search(r"AddObjectHelper<Creature>\(map, obj\);\s+(//[^\n]*\s+)?"
                     r"if \(Vehicle\* vehicle = obj->GetVehicleKit\(\)\)\s+vehicle->Reset\(\);", grid_loader)
    loader = (ROOT / "src/server/coa/CoAScriptLoader.cpp").read_text(encoding="utf-8")
    assert loader.count("AddSC_AscensionCaravanCarts();") == 2


def main():
    source = (ROOT / "src/server/coa/AscensionCaravanCarts.cpp").read_text(encoding="utf-8")
    check_startup_order()
    code, grids, carts = build_harness(source)
    compile_and_run(code)
    print(f"PASS: before world initialization every open-world caravan cart spawn loads its grid once "
          f"({carts} cart spawns including a duplicate, {grids} distinct grids on maps 0 and 1); non-cart spawns, "
          f"instanced or unknown maps and invalid coordinates load nothing; one info line with the counts; the hook "
          f"runs after creatures, vehicle accessories, waypoints, SmartAI and the map manager are loaded and before "
          f"the all-grid preload; grid-loaded vehicles seat their accessories; loader registration")


if __name__ == "__main__":
    main()
