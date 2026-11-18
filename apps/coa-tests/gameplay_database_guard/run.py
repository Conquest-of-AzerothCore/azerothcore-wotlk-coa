from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[3]
source = (ROOT / "modules/mod-playerbots/src/Script/Playerbots.cpp").read_text()
start = source.index("    bool OnDatabasesLoading() override")
body = source.index("{", start)
end = body + 1
depth = 1
while depth:
    depth += (source[end] == "{") - (source[end] == "}")
    end += 1
method = source[start:end].replace("bool OnDatabasesLoading() override", "bool LoadPlayerbots()")
code = r'''
#include <cassert>
#include <string>
#include <type_traits>
int loads = 0;
struct Config
{
    bool gameplay = true;
    std::string info;
    template<class T> T GetOption(std::string const& name, T const&, bool = true)
    {
        if constexpr (std::is_same_v<T, bool>)
            return name == "CoAGameplayTest.Enable" ? gameplay : true;
        else
            return info;
    }
} config;
Config* sConfigMgr = &config;
struct DatabaseLoader
{
    static constexpr int DATABASE_PLAYERBOTS = 1;
    explicit DatabaseLoader(char const*) { }
    void SetUpdateFlags(int) { }
    void AddDatabase(int, char const*) { }
    bool Load() { ++loads; return true; }
};
int PlayerbotsDatabase = 0;
#define LOG_ERROR(...) static_cast<void>(0)
'''
code += method
code += r'''
int main()
{
    for (auto const& info : {"", "invalid", "127.0.0.1;3306;user;fixture;acore_playerbots"})
    {
        config.info = info;
        assert(!LoadPlayerbots());
        assert(loads == 0);
    }
    config.info = "127.0.0.1;33306;user;fixture;coa_test_012345abcdef_playerbots";
    assert(LoadPlayerbots() && loads == 1);
    config.gameplay = false;
    config.info = "127.0.0.1;3306;user;fixture;acore_playerbots";
    assert(LoadPlayerbots() && loads == 2);
}
'''
with tempfile.TemporaryDirectory(prefix="coa-database-guard-") as directory:
    target = Path(directory)
    (target / "check.cpp").write_text(code)
    subprocess.run(["g++", "-std=c++20", "-Wall", "-Wextra", "-Werror", str(target / "check.cpp"),
                    "-o", str(target / "check")], check=True)
    subprocess.run([str(target / "check")], check=True)
print("PASS: gameplay verification refuses live Playerbots pools before opening them; normal servers are unchanged")
