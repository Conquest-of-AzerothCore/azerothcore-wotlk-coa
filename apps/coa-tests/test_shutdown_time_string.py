import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
HEADER = ROOT / "src/server/game/World/AscensionServerMessageTime.h"
COMMON = """#pragma once
#include <cstdint>
using uint64 = std::uint64_t;
constexpr uint64 SECOND = 1;
constexpr uint64 MINUTE = SECOND * 60;
constexpr uint64 HOUR = MINUTE * 60;
constexpr uint64 DAY = HOUR * 24;
"""
MAIN = r"""
#include "AscensionServerMessageTime.h"
#include <cstdio>
#include <cstdlib>

int main(int argc, char** argv)
{
    for (int index = 1; index < argc; ++index)
        std::printf("%s\n", AscensionServerMessage::ShutdownTimeString(std::strtoull(argv[index], nullptr, 10)).c_str());
    return 0;
}
"""
RESTART_TIMER_MINUTES = re.compile(r"(\d+) Minute")
RESTART_TIMER_SECONDS = re.compile(r"(\d+) Second")


def format_times(values):
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-shutdown-time-") as directory:
        out = Path(directory)
        (out / "Common.h").write_text(COMMON, encoding="utf-8")
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        executable = out / ("format.exe" if os.name == "nt" else "format")
        includes = [out, HEADER.parent]
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", *["/I" + str(p) for p in includes], str(out / "main.cpp"),
                     "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", *["-I" + str(p) for p in includes], str(out / "main.cpp"), "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise RuntimeError("Shutdown time formatter did not compile:\n" + build.stdout + build.stderr)
        result = subprocess.run([str(executable), *map(str, values)], check=True, capture_output=True, text=True)
        return result.stdout.splitlines()


def restart_timer_seconds(message):
    minutes = RESTART_TIMER_MINUTES.search(message)
    seconds = RESTART_TIMER_SECONDS.search(message)
    return (int(minutes[1]) if minutes else 0) * 60 + (int(seconds[1]) if seconds else 0)


class ShutdownTimeString(unittest.TestCase):
    def test_uses_the_unit_words_of_the_client_restart_timer(self):
        values = [0, 45, 300, 330, 5400, 2 * 86400 + 3 * 3600 + 4 * 60 + 5]
        self.assertEqual(format_times(values), [
            "0 Second(s)", "45 Second(s)", "5 Minute(s)", "5 Minute(s) 30 Second(s)", "1 Hour(s) 30 Minute(s)",
            "2 Day(s) 3 Hour(s) 4 Minute(s) 5 Second(s)"])

    def test_every_countdown_below_an_hour_reads_back_as_its_duration(self):
        values = list(range(1, 3600))
        for seconds, text in zip(values, format_times(values)):
            with self.subTest(seconds=seconds):
                self.assertEqual(restart_timer_seconds(f"[SERVER] Restart in {text}."), seconds)


if __name__ == "__main__":
    unittest.main()
