from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
MODULE = ROOT / 'modules/mod-manastorm-endless'

STUBS = {
    'Define.h': '''#pragma once
#include <cstdint>
using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using int32 = std::int32_t;
''',
    'Config.h': '''#pragma once
#include <map>
#include <string>
#include <type_traits>
struct ConfigStub
{
    std::map<std::string, std::string> values;
    template <class T> T GetOption(std::string const& name, T const& fallback) const
    {
        auto const found = values.find(name);
        if (found == values.end())
            return fallback;
        if constexpr (std::is_same_v<T, bool>)
            return found->second == "1";
        else if constexpr (std::is_floating_point_v<T>)
            return T(std::stod(found->second));
        else
            return T(std::stoll(found->second));
    }
};
inline ConfigStub* ConfigInstance()
{
    static ConfigStub config;
    return &config;
}
#define sConfigMgr ConfigInstance()
''',
    'Log.h': '''#pragma once
inline int& LogErrors()
{
    static int errors = 0;
    return errors;
}
#define LOG_ERROR(...) (++LogErrors())
#define LOG_WARN(...) ((void)0)
#define LOG_INFO(...) ((void)0)
#define LOG_DEBUG(...) ((void)0)
''',
    'AscensionFreepick.h': '''#pragma once
namespace AscensionFreepick
{
    struct Realm
    {
        bool ConquestOfAzeroth = true;
    };
    inline Realm ReadRealm() { return {}; }
}
''',
    'ManastormReleaseStage.h': '''#pragma once
#include "Define.h"
namespace RaidRelease
{
    inline uint32 ReleasedStage() { return 8; }
}
namespace ManastormReleaseStage
{
    constexpr uint32 AllReleased = 8;
}
''',
}


def method(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def main():
    conf = (MODULE / 'conf/manastorm-endless.conf.dist').read_text(encoding='utf-8')
    assert re.search(r'^Manastorm\.ExperienceRate = 0\.3$', conf, re.M), 'conf.dist must ship the 0.3 rate'
    manager = (MODULE / 'src/ManastormMgr.cpp').read_text(encoding='utf-8')
    experience = (MODULE / 'src/ManastormExperience.cpp').read_text(encoding='utf-8')
    constant = re.search(r'constexpr double ENDLESS_XP_BONUS_PER_DEPTH = [0-9.]+;', manager)
    assert constant
    helpers = '\n'.join([constant.group(0),
                         method(manager, 'double GetEndlessExperienceMultiplier('),
                         method(manager, 'uint32 ScaleUnsignedValue('),
                         method(experience, 'uint32 ClampXP(')])
    methods = '\n'.join([method(manager, 'void ManastormMgr::OnPlayerGiveXP('),
                         method(experience, 'bool ManastormExperience::PrepareCompletion(')])
    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable the C++20 compiler environment.'
    with tempfile.TemporaryDirectory(prefix='manastorm-experience-rate-') as directory:
        out = Path(directory)
        for name, text in STUBS.items():
            (out / name).write_text(text, encoding='utf-8')
        for name in ['ManastormModuleConfig.h', 'ManastormModuleConfig.cpp']:
            shutil.copyfile(MODULE / 'src' / name, out / name)
        harness = out / 'harness.cpp'
        harness.write_text((HERE / 'harness.cpp').read_text(encoding='utf-8')
                           .replace('// ACTUAL_HELPERS', helpers).replace('// ACTUAL_METHODS', methods),
                           encoding='utf-8')
        sources = [str(harness), str(out / 'ManastormModuleConfig.cpp')]
        exe = out / ('checks.exe' if os.name == 'nt' else 'checks')
        flags = (['/nologo', '/std:c++20', '/EHsc', '/I' + str(out), *sources, '/Fe' + str(exe)]
                 if Path(compiler).stem.lower() == 'cl'
                 else ['-std=c++20', '-I' + str(out), *sources, '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)


if __name__ == '__main__':
    main()
