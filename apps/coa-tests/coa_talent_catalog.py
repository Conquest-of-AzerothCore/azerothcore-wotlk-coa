import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
STUBS = {
    "Define.h": """#pragma once
#include <cstddef>
#include <cstdint>
using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using int8 = std::int8_t;
using int16 = std::int16_t;
using int32 = std::int32_t;
using int64 = std::int64_t;
#define ACORE_ENDIAN 0
#define ACORE_BIGENDIAN 1
""",
    "Errors.h": """#pragma once
#include <cassert>
#define ASSERT(condition, ...) assert(condition)
""",
    "Log.h": """#pragma once
#include <cstdio>
#define LOG_ERROR(filter, ...) (void)std::fprintf(stderr, "logged error\\n")
#define LOG_INFO(filter, ...) (void)0
""",
    "DBCStores.h": """#pragma once
#include <string>
#include <string_view>
inline std::string DbcDirectory;
inline std::string GetClientDBCPath(std::string_view name) { return DbcDirectory + std::string(name); }
""",
}
MAIN = r"""
#include "AscensionCoATalentData.h"
#include "DBCStores.h"
#include <cstdio>

using namespace AscensionCompatData;

int main(int, char** argv)
{
    DbcDirectory = std::string(argv[1]) + "/";
    if (!LoadCoATalentData())
        return 1;
    std::puts("CoATalentEntries =\n{{");
    for (CoATalentEntry const& e : CoATalentEntries)
        std::printf("    {%u, %u, %u, %u, %u, %u, %u, {{%u, %u, %u}}},\n", e.EntryId, e.ClassId, e.SpecId, e.SpellCount,
            e.AECost, e.TECost, e.RequiredLevel, e.SpellIds[0], e.SpellIds[1], e.SpellIds[2]);
    std::puts("}};\nCoASelectableFreeEntries =\n{{");
    for (CoASelectableFreeEntry const& e : CoASelectableFreeEntries)
        std::printf("    {%u, %u},\n", e.EntryId, e.GroupId);
    std::puts("}};\nCoAAutomaticDependencies =\n{{");
    for (CoAAutomaticDependency const& e : CoAAutomaticDependencies)
        std::printf("    {%u, {{%u, %u}}},\n", e.EntryId, e.RequiredEntryIds[0], e.RequiredEntryIds[1]);
    std::puts("}};");
    return 0;
}
"""


def catalog_text(dbc_dir):
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-talent-catalog-") as directory:
        out = Path(directory)
        for name, text in STUBS.items():
            (out / name).write_text(text, encoding="utf-8")
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        includes = [out, ROOT / "src/server/coa", ROOT / "src/server/shared/DataStores",
                    ROOT / "src/common"]
        sources = [out / "main.cpp", ROOT / "src/server/coa/AscensionCoATalentData.cpp",
                   ROOT / "src/server/shared/DataStores/ClientDBC.cpp"]
        executable = out / ("catalog.exe" if os.name == "nt" else "catalog")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/D_CRT_SECURE_NO_WARNINGS",
                     *["/I" + str(p) for p in includes], *map(str, sources), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", *["-I" + str(p) for p in includes], *map(str, sources), "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise RuntimeError("Talent catalog loader did not compile:\n" + build.stdout + build.stderr)
        return subprocess.run([str(executable), str(Path(dbc_dir).resolve())], check=True, capture_output=True,
                              text=True).stdout


if __name__ == "__main__":
    import sys
    print(catalog_text(sys.argv[1]), end="")
