CLI_DESCRIPTION = """Compare the actual Witch Hunter night rule (the shared realm clock) with the native packed realm clock."""

import argparse
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Read the pre-fix Night function from a local Git ref.")
    args = parser.parse_args()
    path = "src/server/coa/AscensionWitchHunterDefenses.cpp"
    source = (git_source(["git", "show", f"{args.source_ref}:{path}"], cwd=ROOT).decode()
              if args.source_ref else ROOT.joinpath(path).read_text())
    timer = ROOT.joinpath("src/common/Utilities/Timer.cpp").read_text()
    packet = ROOT.joinpath("src/server/shared/Packets/ByteBuffer.cpp").read_text()
    code = r"""
#include <cassert>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <initializer_list>
using uint32=std::uint32_t; using uint64=std::uint64_t; using Seconds=std::chrono::seconds;
using namespace std::chrono_literals;
Seconds now{1};
Seconds GetEpochTime(){return now;}
namespace GameTime { Seconds GetGameTime(){return now;} }
namespace Acore::Time { std::tm TimeBreakdown(time_t); uint32 GetHours(Seconds); }
#ifdef _WIN32
std::tm* localtime_r(time_t const* time,std::tm* result){localtime_s(result,time);return result;}
#endif
struct ByteBuffer
{
    uint32 packed=0;
    template<class T> void append(T value){packed=uint32(value);}
    void AppendPackedTime(time_t time);
};
"""
    code += method(timer, "std::tm Acore::Time::TimeBreakdown(")
    code += method(timer, "uint32 Acore::Time::GetHours(")
    code += method(packet, "void ByteBuffer::AppendPackedTime(")
    if "bool Night(" in source:
        code += method(source, "bool Night(")
    else:
        realm_clock = ROOT.joinpath("src/server/coa/AscensionRealmClock.h").read_text()
        code += method(realm_clock, "inline bool IsNight(")
        code += "\nbool Night(){return IsNight();}\n"
    code += r"""
int main()
{
    for (char const* zone : {"UTC0","MSK-3","PST8","JST-9"})
    {
#ifdef _WIN32
        _putenv_s("TZ",zone); _tzset();
#else
        setenv("TZ",zone,1); tzset();
#endif
        for(int hour=0;hour<24;++hour) for(int minute:{0,59})
        {
            std::tm local{};
            local.tm_year=126;local.tm_mon=8;local.tm_mday=14;
            local.tm_hour=hour;local.tm_min=minute;local.tm_isdst=-1;
            now=Seconds{std::mktime(&local)};
            ByteBuffer clock;
            clock.AppendPackedTime(now.count());
            assert(((clock.packed>>6)&31u)==uint32(hour));
            assert(Night()==(hour<6 || hour>=18));
        }
    }
}
"""
    vc_tools = os.environ.get("VCToolsInstallDir")
    compiler = (str(Path(vc_tools) / "bin/Hostx64/x64/cl.exe") if vc_tools else
                shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++")))
    if not compiler:
        raise RuntimeError("Enable a C++20 compiler (VS Developer PowerShell on Windows).")
    with tempfile.TemporaryDirectory(prefix="coa-witch-hunter-clock-") as directory:
        out = Path(directory)
        cpp = out / "clock.cpp"
        cpp.write_text(code, encoding="utf-8")
        executable = out / ("clock.exe" if os.name == "nt" else "clock")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8", str(cpp), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=60)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=15)
    print("PASS: 192 clock cases across four time zones, including 05:59/06:00 and 17:59/18:00")


if __name__ == "__main__":
    main()
