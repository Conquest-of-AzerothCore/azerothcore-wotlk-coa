from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[3]
source = (ROOT / "src/common/Configuration/Config.cpp").read_text()
start = source.index("static std::string ModuleConfigPath()")
end = source.index("\n}\n", start) + 3
method = source[start:end]
code = r'''
#include <cassert>
#include <filesystem>
#include <string>
struct Config
{
    std::string directory;
    template<class T> T GetOption(std::string const& key, T const&, bool)
    {
        assert(key == "Modules.ConfigDirectory");
        return directory;
    }
    std::string GetConfigPath() { return "/installed/etc/"; }
} config;
Config* sConfigMgr = &config;
'''
code += method
code += r'''
int main()
{
    assert(ModuleConfigPath() == "/installed/etc/modules");
    config.directory = "/private/test configs/modules";
    assert(ModuleConfigPath() == config.directory);
    assert((std::filesystem::path(ModuleConfigPath()) / "coa.conf").string()
        == "/private/test configs/modules/coa.conf");
    config.directory = "/private/modules/";
    assert((std::filesystem::path(ModuleConfigPath()) / "coa.conf").string() == "/private/modules/coa.conf");
    config.directory.clear();
    assert(ModuleConfigPath() == "/installed/etc/modules");
}
'''
with tempfile.TemporaryDirectory(prefix="coa-module-config-") as directory:
    target = Path(directory)
    (target / "check.cpp").write_text(code)
    subprocess.run(["g++", "-std=c++20", "-Wall", "-Wextra", "-Werror", str(target / "check.cpp"),
                    "-o", str(target / "check")], check=True)
    subprocess.run([str(target / "check")], check=True)
print("PASS: default module paths are preserved and explicit isolated directories are honored")
