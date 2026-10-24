import os
from pathlib import Path
import runpy
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]


def main():
    extract = runpy.run_path(str(ROOT / "apps/coa-tests/client_compat/run.py"))["method"]
    service = extract((ROOT / "src/server/coa/AscensionCompat.cpp").read_text(encoding="utf-8"),
                      "class AscensionResourceService")
    code = """#include <algorithm>
#include <cassert>
#include <cstdint>
#include <mutex>
#include <thread>
#include <unordered_map>
#include <vector>

using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using ObjectGuid = uint64;

struct ResourceService
{
"""
    code += "\n".join(extract(service, signature) for signature in (
        "uint32 AdvanceStaticDecay(", "void ForgetStaticDecay(")) + """
    mutable std::mutex _staticDecayTimersLock;
    mutable std::unordered_map<ObjectGuid, uint32> _staticDecayTimers;
};
"""
    code += Path(__file__).with_name("cases.cpp").read_text(encoding="utf-8")
    with tempfile.TemporaryDirectory(prefix="coa-static-decay-") as directory:
        out = Path(directory)
        cpp, exe = out / "decay.cpp", out / "decay.exe"
        cpp.write_text(code, encoding="utf-8")
        compiler = Path(os.environ["VCToolsInstallDir"]) / "bin/Hostx64/x64/cl.exe"
        subprocess.run([str(compiler), "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8",
                        str(cpp), "/Fe" + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=60)
    print("PASS: Static decay grace, per-second loss, reset and timers shared by concurrent map updaters")


if __name__ == "__main__":
    main()
