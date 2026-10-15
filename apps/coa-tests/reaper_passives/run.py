CLI_DESCRIPTION = """Exercise Reaper talent procs and the actual shared resource dispatcher."""
import argparse
import importlib.util
from pathlib import Path
import sqlite3
import struct
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
CASES = r'''
int main()
{
    Player player;
    player.cls = CLASS_REAPER;
    Unit enemy;
    enemy.guid = 2;
    Harvester harvester;
    harvester.fixtureOwner = &player;
    DamageInfo damage;
    ProcEventInfo event;
    event.actor = &player;
    event.target = &enemy;
    event.damage = &damage;
    manager.rows[500283].Effects[0].BasePoints = 14;
    manager.rows[500283].Effects[0].DieSides = 1;
    assert(harvester.CheckProc(event));
    harvester.Heal(nullptr, event);
    assert(player.casts.back().id == 504565 && player.casts.back().amount == 150);
    damage.value = 0;
    assert(!harvester.CheckProc(event));
    damage.value = 1000;
    event.actor = &enemy;
    assert(!harvester.CheckProc(event));
    event.actor = &player;
    event.target = &player;
    assert(!harvester.CheckProc(event));
    event.target = &enemy;
    enemy.friendly = true;
    assert(!harvester.CheckProc(event));
    enemy.friendly = false;
    enemy.alive = false; // Killing hits still have a native damage event.
    assert(harvester.CheckProc(event));
    player.cls = CLASS_RANGER;
    assert(!harvester.CheckProc(event));
    player.cls = CLASS_REAPER;

    auto count = [&] { return std::count_if(player.casts.begin(), player.casts.end(),
        [](auto const& cast) { return cast.id == 805720; }); };
    ModifyAuraStacks(&player, 500363, 1);
    assert(count() == 0 && player.GetAura(500363)->GetStackAmount() == 1);
    player.AddAura(805719, &player);
    ModifyAuraStacks(&player, 500363, 1);
    assert(count() == 1 && player.GetAura(500363)->GetStackAmount() == 2);
    ModifyAuraStacks(&player, 500363, 3);
    assert(count() == 2 && player.GetAura(500363)->GetStackAmount() == 3);
    ModifyAuraStacks(&player, 500363, 1);
    ModifyAuraStacks(&player, 500363, 0);
    assert(count() == 2);
    ModifyAuraStacks(&player, 500363, -3);
    assert(!player.HasAura(500363) && count() == 2);
    ModifyAuraStacks(&player, 500363, 3);
    assert(player.GetAura(500363)->GetStackAmount() == 3 && count() == 3);
    ModifyAuraStacks(&player, 805077, 1); // Soul Fragments use the unchanged generic path.
    assert(player.HasAura(805077) && count() == 3);
    Hooks hooks;
    Aura removed;
    removed.id = 800797;
    removed.caster = player.guid;
    AuraApplication application;
    application.aura = &removed;
    player.AddAura(561099, &player);
    for (auto mode : {AURA_REMOVE_BY_EXPIRE, AURA_REMOVE_BY_CANCEL, AURA_REMOVE_BY_ENEMY_SPELL})
    {
        auto before = player.casts.size();
        hooks.OnAuraRemove(&player, &application, mode);
        assert(player.casts.size() == before + 1 && player.casts.back().id == 561128);
    }
    auto before = player.casts.size();
    hooks.OnAuraRemove(&player, &application, AURA_REMOVE_BY_DEATH);
    removed.id = 800842;
    hooks.OnAuraRemove(&player, &application, AURA_REMOVE_BY_EXPIRE);
    removed.id = 800797;
    removed.caster = 99;
    hooks.OnAuraRemove(&player, &application, AURA_REMOVE_BY_EXPIRE);
    assert(player.casts.size() == before);
    SpellInfo info;
    info.Id = 805720;
    info.SpellFamilyName = 36;
    info.Effects[0].Effect = 6;
    info.Effects[0].ApplyAuraName = 3;
    float value = 4;
    hooks.ModifySpellEffectBaseValue(&player, &info, EFFECT_0, value);
    assert(value == 74); // Base 4 plus 3.5% of 2000 Stamina; native AP remains separate.
    value = 4;
    info.Id = 42;
    hooks.ModifySpellEffectBaseValue(&player, &info, EFFECT_0, value);
    assert(value == 4);
}
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    parser.add_argument("--source-ref", help="Use an older resource dispatcher as a negative control")
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("doctor_fixture",
                                                 args.workspace_tools / "Test-WitchDoctorCompletion.py")
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    read = fixture.read
    def fixture_read(path):
        code = read(path)
        if path.name == "WitchDoctorCompletionHarness.cpp":
            code = code.replace("/*ENUMS*/", "/*ENUMS*/\n" + fixture.extract(read(ROOT /
                "src/server/game/Spells/Auras/SpellAuraDefines.h"), r"enum AuraRemoveMode\b") + ";\n")
            code = code.replace("struct Application {", "struct AuraApplication { Aura* aura=nullptr; "
                "Aura* GetBase() const { return aura; } }; struct Application {")
            code = code.replace("virtual uint32 getClass()const{return 0;}",
                "virtual uint32 getClass()const{return 0;} float GetStat(uint32) const { return 2000; }")
            code = code.replace("void DropCharge()", "void ModStackAmount(int32 delta) { "
                "int32 next=std::clamp(int32(stacks)+delta,0,id==500363?3:255); "
                "stacks=uint32(next); removed=!next; } void DropCharge()")
            code = code.replace("a.id=id;a.caster=guid;", "a.id=id;a.caster=guid;a.removed=false;a.stacks=1;")
        return code
    fixture.read = fixture_read
    source = (ROOT / "src/server/coa/AscensionReaperTalents.cpp").read_text()
    production = "#include <limits>\n" + fixture.extract(source, r"enum ReaperTalentSpells\b") + ";\n"
    production += "struct Harvester:Context {\n" + fixture.fn(source, "CheckProc") + fixture.fn(source, "Heal") + "};\n"
    production += "struct Hooks {\n" + fixture.fn(source, "OnAuraRemove") + fixture.fn(source, "ModifySpellEffectBaseValue") + "};\n"
    production += fixture.fn(source, "HandleAscensionReaperResource")
    for namespace in ["AscensionPyromancer", "AscensionCultist", "AscensionVenomancer", "AscensionTinker", "AscensionSunCleric"]:
        production += f"namespace {namespace} {{ bool Resource(Player*, uint32, int32) {{ return false; }} }}\n"
    production += "namespace AscensionFelsworn { void Generated(Player*, uint32) {} }\n"
    production += "constexpr uint32 SPELL_PRIMALIST_EARTHSHAPING=680441;\n"
    dispatcher = (git_source(["git", "show",
        f"{args.source_ref}:src/server/coa/AscensionCompat.cpp"], cwd=ROOT).decode("utf-8")
        if args.source_ref else read(ROOT / "src/server/coa/AscensionCompat.cpp"))
    production += fixture.fn(dispatcher, "ModifyAuraStacks")
    with tempfile.TemporaryDirectory(prefix="coa-reaper-passives-") as directory:
        fixture.native.OUT = Path(directory)
        fixture.Tests().run_cpp("reaper-passives", production, CASES)
    db = sqlite3.connect(":memory:")
    db.executescript("CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT); "
        "CREATE TABLE spell_proc (SpellId INT, ProcFlags INT, SpellTypeMask INT, SpellPhaseMask INT, HitMask INT, "
        "AttributesMask INT, Chance REAL); CREATE TABLE spell_bonus_data (entry INT, direct_bonus REAL, dot_bonus REAL, "
        "ap_bonus REAL, ap_dot_bonus REAL, comments TEXT);")
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_05_reaper_talents.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT ProcFlags, SpellTypeMask, SpellPhaseMask, HitMask, AttributesMask FROM spell_proc "
        "WHERE SpellId=92145").fetchone() == (332116, 1, 2, 3, 2)
    assert db.execute("SELECT ap_dot_bonus, dot_bonus FROM spell_bonus_data WHERE entry=805720").fetchone() == (.05, 0)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {}
        for offset in range(20, 20 + count * 936, 936):
            sid = struct.unpack_from("<I", raw, offset)[0]
            if sid in {500283, 504565, 561128, 805720}:
                rows[sid] = struct.unpack_from("<234I", raw, offset)
        assert rows[500283][80] + rows[500283][74] == 15 and rows[500283][116] == 504565
        assert rows[504565][71] == 10 and rows[504565][213] == 0
        assert rows[561128][95] == 290 and rows[561128][80] + rows[561128][74] == 10
        assert rows[805720][95] == 3 and rows[805720][98] == 2000
    print("PASS: Harvester damage events, owned Underwalk exit, real resource gains/caps/spending and Splinter scaling")


if __name__ == "__main__":
    main()
