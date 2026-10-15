CLI_DESCRIPTION = """Test #88's Templar callbacks using the existing workspace completion fixture.

All generated test files stay in a temporary directory. Historical completion
reports and their hash checks are not rewritten or used as acceptance evidence.
"""
import argparse
import importlib.util
from pathlib import Path
import sqlite3
import struct
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CASES = r'''
int main()
{
    Player p;
    SpellInfo info;
    Spell spell;
    spell.caster = &p;
    spell.info = &info;
    Casts casts;
    auto count = [&p](uint32 id) {
        return std::count_if(p.casts.begin(), p.casts.end(), [id](auto const& cast) { return cast.id == id; });
    };
    info.Id = 805421;
    casts.OnSpellCast(&spell, &p, &info, false);
    assert(count(680870) == 0);
    p.AddAura(301309, &p);
    for (uint32 id : {805421u, 748505u, 748506u, 748507u, 572739u, 572740u, 572741u})
    {
        manager.roots[id] = 805421;
        info.Id = id;
        auto before = count(680870);
        casts.OnSpellCast(&spell, &p, &info, false);
        assert(count(680870) == before + 1);
    }
    auto before = count(680870);
    spell.triggered = true;
    casts.OnSpellCast(&spell, &p, &info, false);
    assert(count(680870) == before);
    spell.triggered = false;
    p.cls = CLASS_RANGER;
    casts.OnSpellCast(&spell, &p, &info, false);
    assert(count(680870) == before);
    p.cls = CLASS_MONK;
    info.Id = 42;
    casts.OnSpellCast(&spell, &p, &info, false);
    assert(count(680870) == before);

    Life life;
    life.fixtureOwner = life.fixtureCaster = &p;
    life.fixtureId = 706583;
    auto effect = life.fixtureAura.GetEffect(0);
    effect->amount = 0;
    life.fixtureApplication.mode = AURA_REMOVE_BY_ENEMY_SPELL;
    life.Remove(effect, 0);
    assert(count(801546) == 0);
    p.AddAura(804930, &p);
    life.Remove(effect, 0);
    assert(count(801546) == 1);
    for (auto mode : {AURA_REMOVE_BY_EXPIRE, AURA_REMOVE_BY_CANCEL, AURA_REMOVE_BY_DEATH})
    {
        life.fixtureApplication.mode = mode;
        life.Remove(effect, 0);
        assert(count(801546) == 1);
    }
    life.fixtureApplication.mode = AURA_REMOVE_BY_ENEMY_SPELL;
    effect->amount = 1; // A dispelled shield with capacity remaining did not break.
    life.Remove(effect, 0);
    assert(count(801546) == 1);
    effect->amount = 0;
    p.alive = false;
    life.Remove(effect, 0);
    assert(count(801546) == 1);
    p.alive = true;
    Player ally;
    ally.guid = 8;
    life.fixtureOwner = &ally; // This is the Templar's self shield, not somebody else's.
    life.Remove(effect, 0);
    assert(count(801546) == 1);
}
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--source-ref", help="Use older Templar source as a negative control")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    path = args.workspace_tools / "Test-TemplarCompletion.py"
    spec = importlib.util.spec_from_file_location("templar_completion_fixture", path)
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    fixture.MODULE = ROOT / "src/server/coa"
    if args.source_ref:
        fixture.source = lambda name: git_source([
            "git", "show", f"{args.source_ref}:src/server/coa/AscensionTemplar{name}.cpp"
        ], cwd=ROOT).decode("utf-8")
    production = "constexpr uint32 selected[]={806354,807004,561156,681136,712378,524766,806523,524617};\n"
    production += fixture.methods("Abilities", ["Selected", "ConsumeSelected"])
    production += fixture.wrapper("Casts", "Abilities", ["OnSpellCast"])
    production += fixture.wrapper("Life", "Auras", ["First", "Remove"])
    code = fixture.fixture().replace("/*PRODUCTION*/", production).replace("/*CASES*/", CASES)
    with tempfile.TemporaryDirectory(prefix="coa-templar-passives-") as directory:
        fixture.native.OUT = Path(directory)
        result = fixture.native.compile_run(code, "passives")
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)

    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260913_02_templar_passives.sql").read_text()
    db = sqlite3.connect(":memory:")
    db.execute("CREATE TABLE spell_bonus_data (entry INT, direct_bonus REAL, dot_bonus REAL, "
               "ap_bonus REAL, ap_dot_bonus REAL, comments TEXT)")
    db.execute("INSERT INTO spell_bonus_data VALUES (42, 1, 2, 3, 4, 'unrelated')")
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT direct_bonus, ap_bonus FROM spell_bonus_data WHERE entry=801546").fetchone() == (.5, .2)
    assert db.execute("SELECT direct_bonus FROM spell_bonus_data WHERE entry=42").fetchone() == (1,)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {}
        for offset in range(20, 20 + count * 936, 936):
            sid = struct.unpack_from("<I", raw, offset)[0]
            if sid in {680870, 706583, 801546}:
                rows[sid] = struct.unpack_from("<234I", raw, offset)
        assert rows[680870][95] == 101 and rows[680870][80] + rows[680870][74] == 15
        assert rows[706583][95] == 69
        assert rows[801546][71:73] == (2, 63) and rows[801546][225] == 2
    print("PASS: all Reckoning ranks, class/trigger gates, shield-break reasons and scoped coefficient SQL")


if __name__ == "__main__":
    main()
