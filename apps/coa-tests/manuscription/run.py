CLI_DESCRIPTION = """Regress Manuscription's cast lifecycle and native Chapter data."""
import argparse
import importlib.util
from pathlib import Path
import sqlite3
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]
CASES = r'''
int main()
{
    Player player;
    player.cls = CLASS_SPIRIT_MAGE;
    Unit enemy, second;
    enemy.guid = 2;
    second.guid = 3;
    Manuscription hook;
    for (Chapter const& chapter : Chapters)
    {
        auto& info = manager.rows[chapter.AuraId];
        info.Id = chapter.AuraId;
        info.SpellFamilyName = 38;
        info.Effects[0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
        ApplyAscensionManuscriptionContracts(&info);
        assert(info.ProcCharges == 10 && !info.ProcFlags && info.Effects[0].ApplyAuraName == SPELL_AURA_DUMMY);
    }
    SpellInfo manuscript;
    manuscript.Id = 524952;
    manuscript.SpellFamilyName = 38;
    manuscript.Effects[0].Effect = SPELL_EFFECT_APPLY_AURA;
    Spell start;
    start.caster = &player;
    start.info = &manuscript;
    hook.OnSpellPrepare(&start, &player, &manuscript);
    hook.OnSpellCast(&start, &player, &manuscript, false);
    assert(player.HasAura(TRANSCRIBING) && !start.GetScriptValue(SELECTED_CHAPTER));
    Application tattoo;
    tattoo.aura = player.AddAura(803749, &player);
    player.applications[0] = &tattoo;
    SpellInfo direct;
    direct.Id = 801179;
    direct.SpellFamilyName = 38;
    direct.Effects[0].Effect = SPELL_EFFECT_SCHOOL_DAMAGE;
    Spell release;
    release.info = &direct;
    release.caster = &player;
    hook.OnSpellPrepare(&release, &player, &direct);
    hook.OnSpellCast(&release, &player, &direct, false);
    assert(!player.HasAura(TRANSCRIBING) && player.GetAura(525327)->GetCharges() == 10);
    assert(!release.GetScriptValue(TRANSCRIBING)); // Newly granted Chapter starts with the next cast.
    player.casts.clear();
    direct.Id = 1234;
    auto count = [&] {
        return std::count_if(player.casts.begin(), player.casts.end(), [](auto const& cast) { return cast.id == 525601; });
    };
    for (uint8 i = 0; i < 10; ++i)
    {
        Spell cast;
        cast.info = &direct;
        cast.caster = &player;
        hook.OnSpellPrepare(&cast, &player, &direct);
        assert(cast.GetScriptValue(SELECTED_CHAPTER) == 525327);
        if (i % 2)
            hook.OnSpellCast(&cast, &player, &direct, false); // Delayed hit, including the tenth charge.
        auto before = count();
        hook.OnSpellHitResult(&cast, &enemy, SPELL_MISS_IMMUNE, 0, 0, false);
        assert(count() == before);
        hook.OnSpellHitResult(&cast, &enemy, SPELL_MISS_NONE, 0, 0, false); // Absorption still admits the cast.
        hook.OnSpellHitResult(&cast, &second, SPELL_MISS_NONE, 100, 0, false);
        assert(count() == before + 1);
        if (!(i % 2))
            hook.OnSpellCast(&cast, &player, &direct, false);
        if (i < 9)
            assert(player.GetAura(525327)->GetCharges() == 9 - i);
    }
    assert(!player.HasAura(525327) && count() == 10);
    Spell empty;
    empty.info = &direct;
    empty.caster = &player;
    hook.OnSpellPrepare(&empty, &player, &direct);
    hook.OnSpellHitResult(&empty, &enemy, SPELL_MISS_NONE, 100, 0, false);
    assert(count() == 10);
    // Every authored tattoo school/rank maps to one of the existing four Chapters.
    for (auto const& [id, chapter] : std::map<uint32, uint32>{{801106,525327},{803753,525327},{801107,525363},
        {803785,525363},{807834,525363},{807839,525363},{801094,525387},{803758,525387},{802630,525387},
        {803748,525400},{803763,525400}})
    {
        tattoo.aura = player.AddAura(id, &player);
        assert(AttunedChapter(&player) == chapter);
        tattoo.aura->caster = 99;
        assert(!AttunedChapter(&player));
        tattoo.aura->caster = player.guid;
    }
    player.applications.clear();
    assert(!AttunedChapter(&player));
    Application fire, earth;
    fire.aura = player.AddAura(801106, &player);
    earth.aura = player.AddAura(801094, &player);
    player.applications = {{0, &fire}, {1, &earth}};
    player.AddAura(TRANSCRIBING, &player);
    direct.Id = 804550;
    hook.OnSpellCast(&empty, &player, &direct, false);
    assert(player.HasAura(TRANSCRIBING) && !AttunedChapter(&player));
    player.applications.erase(1);
    hook.OnSpellCast(&empty, &player, &direct, false);
    assert(player.GetAura(525327)->GetCharges() == 10);
    // Triggered damage, channels and pure DoTs do not spend direct-cast charges.
    for (int mode = 0; mode < 3; ++mode)
    {
        Spell excluded;
        excluded.caster = &player;
        excluded.info = &direct;
        excluded.triggered = mode == 0;
        direct.fixtureChannel = mode == 1;
        direct.Effects[0].Effect = mode == 2 ? SPELL_EFFECT_APPLY_AURA : SPELL_EFFECT_SCHOOL_DAMAGE;
        hook.OnSpellPrepare(&excluded, &player, &direct);
        assert(!excluded.GetScriptValue(SELECTED_CHAPTER));
    }
    direct.fixtureChannel = false;
    // Parent casts which launch damage through native E142 still count once.
    direct.Effects[0].Effect = SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE;
    direct.Effects[0].TriggerSpell = 4321;
    manager.rows[4321].Effects[0].Effect = SPELL_EFFECT_SCHOOL_DAMAGE;
    Spell forwarded;
    forwarded.caster = &player;
    forwarded.info = &direct;
    hook.OnSpellPrepare(&forwarded, &player, &direct);
    assert(forwarded.GetScriptValue(SELECTED_CHAPTER) == 525327);
    hook.OnSpellCast(&forwarded, &player, &direct, false); // A cast with no successful target still spends one.
    assert(player.GetAura(525327)->GetCharges() == 9);
    SpellInfo transcribe;
    transcribe.Id = TRANSCRIBING;
    transcribe.SpellFamilyName = 38;
    transcribe.Effects[2].Effect = SPELL_EFFECT_TRIGGER_SPELL;
    ApplyAscensionManuscriptionContracts(&transcribe);
    assert(!transcribe.Effects[2].Effect && !transcribe.ProcFlags);
}
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("doctor_fixture",
                                                 args.workspace_tools / "Test-WitchDoctorCompletion.py")
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    read = fixture.read
    def fixture_read(path):
        code = read(path)
        if path.name == "WitchDoctorCompletionHarness.cpp":
            code = code.replace("struct SpellInfo {", "struct SpellInfo { uint32 ProcFlags=0; "
                "bool fixtureChannel=false; bool IsChanneled() const { return fixtureChannel; }")
            code = code.replace("struct Aura {", "struct Aura { uint8 GetCharges() const { return uint8(charges); }")
            code = code.replace("a.casterUnit=this;return &a;", "a.casterUnit=this;a.charges=a.info->ProcCharges;return &a;")
        return code
    fixture.read = fixture_read
    source = (ROOT / "src/server/coa/AscensionRunemasterManuscription.cpp").read_text()
    production = source[source.index("struct Chapter"):source.index("class runemaster_manuscription_casts")]
    production += "struct Manuscription {\n" + "\n".join(fixture.fn(source, name)
        for name in ["OnSpellPrepare", "OnSpellCast", "OnSpellHitResult"]) + "\n};\n"
    production += fixture.fn(source, "ApplyAscensionManuscriptionContracts")
    with tempfile.TemporaryDirectory(prefix="coa-manuscription-") as directory:
        fixture.native.OUT = Path(directory)
        fixture.Tests().run_cpp("manuscription", production, CASES)
    db = sqlite3.connect(":memory:")
    db.execute("CREATE TABLE spell_bonus_data (entry INT, direct_bonus REAL, dot_bonus REAL, "
               "ap_bonus REAL, ap_dot_bonus REAL, comments TEXT)")
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_01_manuscription.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT dot_bonus FROM spell_bonus_data WHERE entry=525302").fetchone() == (.38,)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {}
        for offset in range(20, 20 + count * 936, 936):
            sid = struct.unpack_from("<I", raw, offset)[0]
            if sid in {525302, 525601, 525516, 525395, 525401}:
                rows[sid] = struct.unpack_from("<234I", raw, offset)
        assert len(rows) == 5
        for sid, row in rows.items():
            assert row[104] == 7 and row[212] == 8
            if sid != 525302:
                multiplier = struct.unpack("<f", struct.pack("<I", row[216]))[0]
                assert abs(multiplier - .8) < 1e-6 and row[92] == 197
    print("PASS: Transcribing, tattoo-school selection, ten casts, last-charge delayed hit, chaining data and DoT SQL")


if __name__ == "__main__":
    main()
