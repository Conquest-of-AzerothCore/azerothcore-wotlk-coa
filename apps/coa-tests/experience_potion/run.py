CLI_DESCRIPTION = """Exercise the potion's actual duration hooks without building the server."""

import argparse
import os
from pathlib import Path
import runpy
import shutil
import sqlite3
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--before", action="store_true", help="Exercise the native refresh without the new hooks.")
    args = parser.parse_args()
    source = ROOT.joinpath("src/server/coa/AscensionCompat.cpp").read_text(encoding="utf-8")
    script = method(source, "class spell_ascension_experience_potion")
    for hook in ("BeforeHit += BeforeSpellHitFn", "AfterHit += SpellHitFn"):
        assert hook in script
    assert "RegisterSpellScript(spell_ascension_experience_potion);" in source
    sql = ROOT.joinpath("data/sql/updates/pending_db_world/rev_1789354335247519200.sql").read_text()
    db = sqlite3.connect(":memory:")
    db.execute("CREATE TABLE spell_script_names (spell_id INTEGER, ScriptName TEXT)")
    db.execute("INSERT INTO spell_script_names VALUES (818046, 'unrelated')")
    db.executescript(sql)
    db.executescript(sql)
    assert db.execute("SELECT * FROM spell_script_names ORDER BY ScriptName").fetchall() == [
        (818046, "spell_ascension_experience_potion"), (818046, "unrelated")]
    code = r"""
#include <algorithm>
#include <cassert>
#include <cstdint>
#include <limits>
using int32=std::int32_t; using int64=std::int64_t;
enum SpellMissInfo { SPELL_MISS_NONE, SPELL_MISS_IMMUNE };
constexpr int32 hour=3600000;
struct Aura
{
    int32 duration=hour, maximum=hour;
    int32 GetDuration() const { return duration; }
    void SetDuration(int32 value) { duration=value; }
    void SetMaxDuration(int32 value) { maximum=value; }
};
struct Unit
{
    Aura* existing=nullptr;
    Aura* GetAura(int32 id, int32 caster) { assert(id==818046 && caster==7); return existing; }
    int32 GetGUID() const { return 7; }
};
struct SpellInfo { int32 Id=818046; };
struct Potion
{
    int32 _remaining=0;
    Unit target;
    Aura* applied=nullptr;
    SpellInfo info;
    Unit* GetHitUnit() { return &target; }
    Unit* GetCaster() { return &target; }
    SpellInfo* GetSpellInfo() { return &info; }
    Aura* GetHitAura() { return applied; }
"""
    if args.before:
        code += "void SnapshotDuration(SpellMissInfo) {} void ExtendDuration() {}\n"
    else:
        code += method(script, "void SnapshotDuration(") + method(script, "void ExtendDuration(")
    code += r"""
};
int main()
{
    Aura buff;
    for (int32 remaining : {0, hour, hour/2, hour*2, -1, std::numeric_limits<int32>::max()-1})
    {
        buff.duration=remaining;
        Potion potion;
        potion.target.existing=remaining ? &buff : nullptr;
        potion.SnapshotDuration(SPELL_MISS_NONE);
        // Native aura refresh recalculates the normal one-hour duration.
        buff.duration=buff.maximum=hour;
        potion.applied=&buff;
        potion.ExtendDuration();
        int32 expected=int32(std::min<int64>(int64(hour)+std::max(0,remaining),
            std::numeric_limits<int32>::max()));
        assert(buff.duration==expected && buff.maximum==expected);
    }
    Potion failed;
    buff.duration=hour/2;
    failed.target.existing=&buff;
    failed.SnapshotDuration(SPELL_MISS_IMMUNE);
    failed.ExtendDuration();
    assert(buff.duration==hour/2);
    failed.SnapshotDuration(SPELL_MISS_NONE);
    failed.ExtendDuration(); // No aura applied: leave the original duration alone.
    assert(buff.duration==hour/2);
}
"""
    compiler = shutil.which(os.environ.get("CXX", "g++"))
    if not compiler:
        raise RuntimeError("Set CXX to a C++17 compiler.")
    with tempfile.TemporaryDirectory(prefix="coa-experience-potion-") as directory:
        out = Path(directory)
        cpp, executable = out / "cases.cpp", out / "cases.exe"
        cpp.write_text(code, encoding="utf-8")
        subprocess.run([compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(executable)],
                       cwd=out, check=True, timeout=60)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=15)
    print("PASS: first use, repeated potions, partial duration, overflow, failed hits, and SQL binding")


if __name__ == "__main__":
    main()
