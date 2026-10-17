from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]


class IronayaBootstrapTests(unittest.TestCase):
    def test_native_unlock_and_private_instance_boundaries(self):
        source = (ROOT / "modules/mod-manastorm-endless/src/ManastormMgr.cpp").read_text()
        start = source.index("    bool IsUldamanIronayaStage(")
        end = source.index("    bool IsUldamanArchaedasStage(", start)
        production = source[start:end]
        definitions = (ROOT / "src/server/game/Entities/Unit/UnitDefines.h").read_text()
        flags = []
        for name in ("UNIT_FLAG_NON_ATTACKABLE", "UNIT_FLAG_NOT_SELECTABLE"):
            value = re.search(r"\b" + name + r"\s*=\s*(0x[0-9A-Fa-f]+)", definitions).group(1)
            flags.append(f"constexpr unsigned {name} = {value};")
        fixture = r"""
#include <cassert>
#include <cstdint>
#include <map>
#include <string>
using uint32 = std::uint32_t;
constexpr uint32 MANASTORM_MAP_ULDAMAN=70, NPC_ULDAMAN_IRONAYA=7228;
constexpr uint32 SEGMENT_IRONAYA_NORMAL=694, SEGMENT_IRONAYA_ENDGAME=693;
constexpr uint32 DATA_ULDAMAN_IRONAYA_DOORS=0, DONE=3;
constexpr uint32 GO_ULDAMAN_IRONAYA_SEAL=124372, GO_ULDAMAN_KEYSTONE=124371;
constexpr uint32 GO_FLAG_NOT_SELECTABLE=16;
#define LOG_INFO(...)
struct ObjectGuid {
    using LowType = uint32;
    uint32 value=1;
    static ObjectGuid Empty;
    uint32 GetRawValue() const { return value; }
    bool operator!=(ObjectGuid other) const { return value!=other.value; }
};
ObjectGuid ObjectGuid::Empty{0};
struct ManastormSegment {
    uint32 MapId=70, ObjectiveCreatureEntry=7228, SegmentId=694;
    uint32 Difficulty=0, DungeonEncounterId=549, StartGameTeleId=2170;
};
struct ManastormRun {
    ManastormSegment segment;
    ObjectGuid objective{0};
    ManastormSegment const& GetSegment() const {return segment;}
    uint32 GetInstanceId() const {return 4;}
    uint32 GetRunId() const {return 1;}
    ObjectGuid GetObjectiveCreatureGuid() const {return objective;}
} run;
struct Creature {
    uint32 flags=33554434u|256u;
    bool alive=true;
    bool IsInWorld() const {return true;}
    bool IsAlive() const {return alive;}
    uint32 GetEntry() const {return 7228;}
    ObjectGuid GetGUID() const {return {10};}
    void RemoveUnitFlag(uint32 flag) {flags &= ~flag;}
} boss;
struct GameObject {
    bool IsInWorld() const {return true;}
    uint32 GetEntry() const {return 124372;}
    void SetGameObjectFlag(uint32) {}
};
struct InstanceScript {
    uint32 state=0;
    uint32 GetData(uint32) const {return state;}
    void SetData(uint32, uint32 value) {state=value;}
    void HandleGameObject(ObjectGuid,bool,GameObject*) {}
} instance;
struct InstanceMap {
    InstanceScript* GetInstanceScript() {return &instance;}
} instanceMap;
struct Map {
    bool privateMap=true;
    uint32 id=70, instanceId=4;
    std::multimap<uint32,Creature*> creatures{{54080,&boss}};
    std::map<uint32,GameObject*> objects;
    uint32 GetId() const {return id;}
    bool IsScriptedPrivateInstance() const {return privateMap;}
    uint32 GetInstanceId() const {return instanceId;}
    InstanceMap* ToInstanceMap() {return &instanceMap;}
    void LoadGrid(float,float) {}
    auto const& GetGameObjectBySpawnIdStore() const {return objects;}
    auto const& GetCreatureBySpawnIdStore() const {return creatures;}
};
struct GameTele {float position_x=0,position_y=0;} tele;
struct CreatureData {uint32 mapid=70,id=7228;} spawnData;
struct ObjectMgr {
    GameTele const* GetGameTele(uint32) {return &tele;}
    CreatureData const* GetCreatureData(uint32) {return &spawnData;}
} objectMgr;
auto sObjectMgr=&objectMgr;
struct Field {template<class T> T Get() const {return T(54080);}};
struct Result {
    Field fields[3];
    Field* Fetch() {return fields;}
    Result* operator->() {return this;}
    explicit operator bool() const {return true;}
};
using QueryResult=Result;
struct Database {Result Query(char const*) {return {};}} WorldDatabase;
struct ManastormMgr {
    static ManastormMgr& Instance() {static ManastormMgr manager; return manager;}
    void OnCreatureAddWorld(Creature* creature) {run.objective=creature->GetGUID();}
};
""" + "\n".join(flags) + "\n" + production + r"""
int main() {
    std::string error;
    Map map;
    assert(!BootstrapUldamanIronayaEncounter(nullptr,run,error));
    auto rejected=[&]() {
        boss.flags=33554434u|256u;
        instance.state=0;
        assert(!BootstrapUldamanIronayaEncounter(&map,run,error));
        assert(boss.flags==(33554434u|256u));
        assert(instance.state==0);
    };
    map.privateMap=false; rejected(); map.privateMap=true;
    map.id=1; rejected(); map.id=70;
    map.instanceId=5; rejected(); map.instanceId=4;
    run.segment.SegmentId=1; rejected(); run.segment.SegmentId=694;
    run.segment.DungeonEncounterId=1; rejected(); run.segment.DungeonEncounterId=549;
    for (bool endgame : {false,true}) {
        run.segment.SegmentId=endgame?693:694;
        run.segment.Difficulty=endgame?2:0;
        run.segment.DungeonEncounterId=endgame?2549:549;
        boss.flags=33554434u|256u;
        assert(BootstrapUldamanIronayaEncounter(&map,run,error));
        assert(error.empty());
        assert(instance.state==DONE);
        assert(run.objective.value==10);
        assert(boss.flags==256u);
        assert(BootstrapUldamanIronayaEncounter(&map,run,error));
        assert(boss.flags==256u);
    }
}
"""
        with tempfile.TemporaryDirectory(prefix="manastorm-ironaya-") as directory:
            temporary = Path(directory)
            (temporary / "fixture.cpp").write_text(fixture, encoding="utf-8")
            if os.name == "nt":
                installs = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Microsoft Visual Studio"
                vcvars = next(installs.glob("2022/*/VC/Auxiliary/Build/vcvars64.bat"), None)
                self.assertIsNotNone(vcvars)
                command = f'cmd.exe /d /c call "{vcvars}" >nul && cl /nologo /std:c++20 /EHsc fixture.cpp /Fe:fixture.exe /Fo:fixture.obj'
                executable = temporary / "fixture.exe"
            else:
                compiler = shutil.which("c++") or shutil.which("clang++") or shutil.which("g++")
                self.assertIsNotNone(compiler)
                command = [compiler, "-std=c++20", "fixture.cpp", "-o", "fixture"]
                executable = temporary / "fixture"
            compiled = subprocess.run(command, cwd=temporary, text=True, capture_output=True)
            self.assertEqual(compiled.returncode, 0, compiled.stdout + compiled.stderr)
            executed = subprocess.run([str(executable)], cwd=temporary, text=True, capture_output=True)
            self.assertEqual(executed.returncode, 0, executed.stdout + executed.stderr)


if __name__ == "__main__":
    unittest.main()
