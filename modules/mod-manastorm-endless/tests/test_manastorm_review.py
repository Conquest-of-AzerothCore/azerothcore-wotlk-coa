import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / "modules/mod-manastorm-endless"


def function(source, signature):
    start = source.index(signature)
    brace = source.index("{", start)
    depth = 1
    end = brace + 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


class ReviewRegressions(unittest.TestCase):
    def compile_and_run(self, source, defines=()):
        with tempfile.TemporaryDirectory(prefix="manastorm-review-") as directory:
            directory = Path(directory)
            (directory / "fixture.cpp").write_text(source, encoding="utf-8")
            if os.name == "nt":
                installs = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Microsoft Visual Studio"
                vcvars = next(installs.glob("2022/*/VC/Auxiliary/Build/vcvars64.bat"), None)
                self.assertIsNotNone(vcvars)
                flags = " ".join("/D" + value for value in defines)
                command = (f'cmd.exe /d /c call "{vcvars}" >nul && '
                           f'cl /nologo /std:c++20 /EHsc {flags} fixture.cpp /Fe:fixture.exe /Fo:fixture.obj')
                executable = directory / "fixture.exe"
            else:
                compiler = shutil.which("c++") or shutil.which("clang++") or shutil.which("g++")
                self.assertIsNotNone(compiler)
                command = [compiler, "-std=c++20", *["-D" + value for value in defines],
                           "fixture.cpp", "-o", "fixture"]
                executable = directory / "fixture"
            result = subprocess.run(command, cwd=directory, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            result = subprocess.run([str(executable)], cwd=directory, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_automatic_migrations_stay_in_selected_database(self):
        for path in (MODULE / "data/sql").rglob("*.sql"):
            with self.subTest(path=path.name):
                sql = re.sub(r"--[^\n]*|/\*.*?\*/", "", path.read_text(encoding="utf-8"), flags=re.S)
                self.assertIsNone(re.search(r"\bUSE\s+", sql, re.I))
                self.assertIsNone(re.search(r"`?acore_(?:world|characters|auth)`?\s*\.", sql, re.I))

    def test_activation_failure_propagates_without_run_access(self):
        source = (MODULE / "src/ManastormMgr.cpp").read_text(encoding="utf-8")
        activation = function(source, "bool ManastormMgr::OnPlayerEnterMap(")
        failures = re.findall(r"FailRun\([\s\S]*?;\s*return (\w+);", activation)
        self.assertEqual(failures, ["false", "false", "false"])
        damage = function(source, "void ManastormMgr::OnDamage(")
        self.assertRegex(damage, r"if \(!OnPlayerEnterMap\([\s\S]*?attackingPlayer\)\)\s*return;")
        transition = function(source, "bool ManastormMgr::TransitionToNextStage(")
        self.assertRegex(transition, r"if \(!OnPlayerEnterMap\([\s\S]*?return false;\s*\}")
        portal = function(source, "bool ManastormMgr::UseStagePortal(")
        self.assertRegex(portal, r"if \(_runs.find\(runId\) == _runs.end\(\)\)\s*\{[^}]*return false;")
        update = function(source, "void ManastormMgr::Update(")
        self.assertRegex(update, r"if \(_runs.find\(runId\) == _runs.end\(\)\)\s*continue;")

    def test_original_difficulties_restore_once_and_survive_offline_exit(self):
        source = (MODULE / "src/ManastormMgr.cpp").read_text(encoding="utf-8")
        restore = function(source, "void ManastormMgr::RestoreOriginalDifficulties(")
        fixture = r"""
#include <cassert>
#include <unordered_map>
struct Guid { unsigned GetCounter() const { return 7; } };
struct Player {
    int dungeon = 0, raid = 0;
    Guid GetGUID() const { return {}; }
    void SetDungeonDifficulty(int value) { dungeon = value; }
    void SetRaidDifficulty(int value) { raid = value; }
};
struct ManastormMgr {
    struct Settings { int Dungeon; int Raid; };
    std::unordered_map<unsigned, Settings> _originalDifficulties;
    void RestoreOriginalDifficulties(Player* player);
};
""" + restore + r"""
int main() {
    ManastormMgr manager;
    Player player;
    manager.RestoreOriginalDifficulties(&player);
    assert(player.dungeon == 0 && player.raid == 0);
    manager._originalDifficulties.emplace(7, ManastormMgr::Settings{1, 3});
    manager._originalDifficulties.emplace(7, ManastormMgr::Settings{0, 2});
    manager.RestoreOriginalDifficulties(&player);
    assert(player.dungeon == 1 && player.raid == 3);
    assert(manager._originalDifficulties.empty());
    player.dungeon = 4;
    manager.RestoreOriginalDifficulties(&player);
    assert(player.dungeon == 4 && player.raid == 3);
}
"""
        self.compile_and_run(fixture)
        start = function(source, "ManastormRun* ManastormMgr::StartRun(")
        self.assertLess(start.index("_originalDifficulties.emplace"), start.index("if (!PrepareStage"))
        self.assertIn("member->GetDungeonDifficulty(), member->GetRaidDifficulty()", start)
        for signature in ("void ManastormMgr::FailRun(", "bool ManastormMgr::StopRun("):
            body = function(source, signature)
            self.assertLess(body.index("RestoreOriginalDifficulties(member)"),
                            body.index("member->ClearScriptedPrivateInstance()"))
            offline = body[body.index("if (!member)"):body.index("RestoreOriginalDifficulties(member)")]
            self.assertIn("continue;", offline)
            self.assertNotIn("_originalDifficulties.erase", offline)
        login = function(source, "void ManastormMgr::OnPlayerLogin(")
        self.assertRegex(login, r"if \(!run\)\s*\{\s*RestoreOriginalDifficulties\(player\);")

    def test_database_preparation_with_module_enabled_and_disabled(self):
        bodies = []
        ids = set()
        for name in ("World", "Character"):
            source = (ROOT / f"src/server/database/Database/Implementation/{name}Database.cpp").read_text()
            body = function(source, f"void {name}DatabaseConnection::DoPrepareStatements()")
            ids.update(re.findall(r"PrepareStatement\(\s*(\w+)", body))
            body = body[body.index("{") + 1:-1]
            body = re.sub(r"if \(!m_reconnecting\)\s*m_stmts.resize\([^;]+;", "", body)
            bodies.append(f"void prepare{name}() {{\n{body}\n}}")
        fixture = r"""
#include <cassert>
#include <string>
#include <string_view>
#include <vector>
struct Config {
    template<class T> T GetOption(char const*, T value) { return value; }
} config;
auto sConfigMgr = &config;
void Execute(char const*) {}
constexpr int CONNECTION_SYNCH = 1, CONNECTION_ASYNC = 2, CONNECTION_BOTH = 3;
std::vector<std::string> prepared;
void PrepareStatement(int, char const* sql, int) { prepared.emplace_back(sql); }
""" + "enum Statements {" + ",".join(sorted(ids)) + "};\n" + "\n".join(bodies) + r"""
int main() {
    prepareWorld();
    prepareCharacter();
    unsigned moduleQueries = 0;
    bool upstreamQueries = false, nativeQueries = false;
    for (auto const& sql : prepared) {
        if (sql.find("manastorm_private_creature") != std::string::npos ||
            sql.find("manastorm_floor_experience") != std::string::npos ||
            sql.find("character_manastorm_completion_reward_state") != std::string::npos ||
            sql.find("character_manastorm_pending_experience") != std::string::npos)
            ++moduleQueries;
        upstreamQueries |= sql.find("SELECT Experience FROM player_xp_for_level") != std::string::npos;
        nativeQueries |= sql.find("SELECT mode, depth FROM ascension_manastorm_clear") != std::string::npos;
    }
    assert(upstreamQueries && nativeQueries);
#ifdef MOD_MANASTORM_ENDLESS
    assert(moduleQueries == 7);
#else
    assert(moduleQueries == 0);
#endif
}
"""
        self.compile_and_run(fixture)
        self.compile_and_run(fixture, ("MOD_MANASTORM_ENDLESS",))


if __name__ == "__main__":
    unittest.main()
