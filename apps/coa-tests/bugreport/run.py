CLI_DESCRIPTION = """Check the in-game bug report service without a server.

Compiles src/server/coa/CoABugReportService.h into a program that submits reports the way the native
CMSG_CREATE_BUG_REPORT handler does, then reads every spool file it wrote with the relay's own parser.
No database, server build, relay network access or game client is needed.
"""

import argparse
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]

MAIN = r"""
#include "CoABugReportService.h"
#include <cstdio>
#include <fstream>
#include <iterator>
#include <string>

using namespace CoABugReport;

namespace
{
int failures = 0;
void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

Report Public(std::string title, std::string description)
{
    Report report;
    report.Category = 3;
    report.Priority = 1;
    report.Public = true;
    report.Title = std::move(title);
    report.Description = std::move(description);
    return report;
}

std::string Read(std::filesystem::path const& path)
{
    std::ifstream input(path, std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(input), std::istreambuf_iterator<char>());
}
}

int main(int, char** argv)
{
    std::filesystem::path const spool(argv[1]);
    std::string const context = "\n\n### Server context\nClass ID: 31\n";
    Service service(spool, 120);
    std::uint64_t const now = 1790000000;

    Report hidden = Public("Ability fails", "Expected damage, saw none.");
    hidden.Public = false;
    Outcome const refused = service.Submit(7, hidden, context, now);
    Check(refused.Error == Private && std::filesystem::is_empty(spool), "a private report is refused and not written");

    Outcome const queued = service.Submit(7, Public("Ability fails", "Expected damage, saw none."), context, now);
    std::filesystem::path const file = spool / "7-000000006ab13b80.report";
    Check(queued.Error.empty() && queued.Id == std::uint32_t(now), "a public report is queued under the time as its id");
    Check(Read(file) == "COABUG1\nAbility fails\nExpected damage, saw none." + context,
          "the spool file holds the format marker, title, description and server context");
    Check(!std::filesystem::exists(spool / "7-000000006ab13b80.part"), "no partial file is left behind");

    Check(service.Submit(7, Public("Second report", "Body"), context, now + 119).Error == Cooldown,
          "the same account waits for the cooldown");
    Check(service.Submit(8, Public("Other account", "Body"), context, now + 1).Error.empty(),
          "another account is not held by that cooldown");
    Check(service.Submit(7, Public("After cooldown", "Body"), context, now + 121).Error.empty(),
          "the account can report again after the cooldown");

    Check(service.Submit(9, Public("ab", "Body"), context, now).Error == Invalid, "a two-byte title is refused");
    Check(service.Submit(9, Public("Tab\there", "Body"), context, now).Error == Invalid,
          "a title with a tab is refused");
    Check(service.Submit(9, Public(std::string(MaxTitle + 1, 'a'), "Body"), context, now).Error == Invalid,
          "a title past the client limit is refused");
    Check(service.Submit(9, Public("Title", " \n\t"), context, now).Error == Invalid,
          "a blank description is refused");
    Check(service.Submit(9, Public("Title", std::string("bell\a")), context, now).Error == Invalid,
          "a description with a control character is refused");
    Check(service.Submit(9, Public("Title", std::string(MaxDescription + 1, 'a')), context, now).Error == Invalid,
          "a description past the client limit is refused");

    Service shortCooldown(spool, 10);
    Check(shortCooldown.Submit(10, Public("First", "Body"), context, now).Error.empty() &&
              shortCooldown.Submit(10, Public("Early", "Body"), context, now + 59).Error == Cooldown &&
              shortCooldown.Submit(10, Public("Later", "Body"), context, now + 61).Error.empty(),
          "the cooldown is at least 60 seconds");

    Service missing(spool / "missing", 120);
    Check(missing.Submit(11, Public("Title", "Body"), context, now).Error == Storage,
          "a missing spool directory is reported as a storage failure");

    return failures ? 1 : 0;
}
"""


def relay():
    spec = importlib.util.spec_from_file_location("coa_bug_relay", ROOT / "apps/coa-bugreport/relay.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    argparse.ArgumentParser(description=CLI_DESCRIPTION).parse_args()
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-bug-report-") as directory:
        out = Path(directory)
        spool = out / "spool"
        spool.mkdir()
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        executable = out / ("service.exe" if os.name == "nt" else "service")
        include = ROOT / "src/server/coa"
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/I" + str(include), str(out / "main.cpp"),
                     "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-I" + str(include), str(out / "main.cpp"),
                     "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Bug report harness did not compile:\n" + build.stdout + build.stderr)
        result = subprocess.run([str(executable), str(spool)], text=True)

        reports = sorted(spool.glob("*.report"))
        parsed = True
        for path in reports:
            try:
                relay().read_report(path)
            except ValueError:
                parsed = False
        accepted = parsed and len(reports) == 5
        print(f"{'PASS' if accepted else 'FAIL'}: the relay reads every spool file the service wrote")
        raise SystemExit(result.returncode or (0 if accepted else 1))


if __name__ == "__main__":
    main()
