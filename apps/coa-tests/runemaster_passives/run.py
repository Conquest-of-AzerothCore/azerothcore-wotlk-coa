CLI_DESCRIPTION = """Test Runemaster aura transitions using the bounded talent fixture."""
import argparse
import importlib.util
from pathlib import Path
import re
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
CASES = r'''
int main()
{
    Player player;
    player.cls = CLASS_SPIRIT_MAGE;
    runemaster_talent_events events;
    Aura talent;
    talent.id = 707157;
    events.OnAuraApply(&player, &talent);
    assert(player.casts.empty());
    player.auras.insert(707157);
    events.OnAuraApply(&player, &talent);
    assert(player.casts.empty());
    for (uint32 id : {801094u, 803754u, 803755u, 803756u, 803757u, 803758u})
    {
        Aura earth;
        earth.id = id;
        player.auras.insert(id);
        events.OnAuraApply(&player, &earth);
        assert(player.HasAura(712310) && player.casts.size() == 1);
        events.OnAuraApply(&player, &earth); // Reapplication preserves the current periodic timer.
        assert(player.casts.size() == 1);
        player.auras.erase(id);
        AuraApplication removed;
        removed.aura = earth;
        events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_CANCEL);
        assert(!player.HasAura(712310));
        player.casts.clear();
    }
    // The talent can be acquired after Earth Tattoos or removed before the tattoos.
    player.auras.insert(801094);
    events.OnAuraApply(&player, &talent);
    assert(player.HasAura(712310));
    player.auras.erase(707157);
    AuraApplication removed;
    removed.aura = talent;
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_DEFAULT);
    assert(!player.HasAura(712310));
    // A restored orphan helper is cleared until its parents are restored too.
    Aura helper;
    helper.id = 712310;
    player.auras.insert(712310);
    events.OnAuraApply(&player, &helper);
    assert(!player.HasAura(712310));
    player.auras.insert(707157);
    player.alive = false;
    events.OnAuraApply(&player, &talent);
    assert(!player.HasAura(712310));
    player.alive = true;
    player.cls = CLASS_WILDWALKER;
    events.OnAuraApply(&player, &talent);
    assert(!player.HasAura(712310));
    player.cls = CLASS_SPIRIT_MAGE;

    removed.aura.id = 500288;
    player.casts.clear();
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_CANCEL);
    assert(player.casts.empty());
    player.auras.insert(520054);
    for (auto mode : {AURA_REMOVE_BY_EXPIRE, AURA_REMOVE_BY_CANCEL, AURA_REMOVE_BY_ENEMY_SPELL})
    {
        player.casts.clear();
        events.OnAuraRemove(&player, &removed, mode);
        assert(player.casts.size() == 1 && std::get<1>(player.casts[0]) == 520768);
    }
    player.casts.clear();
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_DEATH);
    removed.aura.caster = 42;
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_CANCEL);
    removed.aura.caster = player.guid;
    removed.aura.id = 500510;
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_CANCEL);
    assert(player.casts.empty());
    SpellInfo info;
    info.Id = 712310;
    info.SpellFamilyName = 38;
    info.Effects[0].Effect = 6;
    info.Effects[0].ApplyAuraName = 23;
    info.Effects[0].TriggerSpell = 712337;
    info.Effects[0].Amplitude = 4000;
    info.Effects[2].MiscValue = 98;
    ApplyAscensionRunemasterTalentContracts(&info);
    assert(info.Effects[1].Effect == 6 && info.Effects[1].ApplyAuraName == 37 &&
        info.Effects[1].MiscValue == 144 && !info.Effects[1].BasePoints && !info.Effects[1].DieSides);
    assert(info.Effects[0].ApplyAuraName == 23 && info.Effects[0].TriggerSpell == 712337 &&
        info.Effects[0].Amplitude == 4000 && info.Effects[2].MiscValue == 98);

    runemaster_runic_tempest_events tempest;
    Player tempestCaster;
    tempestCaster.cls = CLASS_SPIRIT_MAGE;
    Aura runicTempest;
    runicTempest.id = 560036;
    AuraApplication tempestEnd;
    tempestEnd.aura = runicTempest;
    AuraApplication shroudEnd;
    shroudEnd.aura.id = 500288;
    tempestCaster.auras.insert(560036);
    tempest.OnAuraApply(&tempestCaster, &runicTempest);
    assert(tempestCaster.HasAura(808089));
    events.OnAuraRemove(&tempestCaster, &shroudEnd, AURA_REMOVE_BY_CANCEL);
    assert(!tempestCaster.HasAura(808089));
    tempest.OnAuraRemove(&tempestCaster, &shroudEnd, AURA_REMOVE_BY_CANCEL);
    assert(tempestCaster.HasAura(808089));
    tempestCaster.auras.erase(560036);
    tempest.OnAuraRemove(&tempestCaster, &tempestEnd, AURA_REMOVE_BY_EXPIRE);
    assert(!tempestCaster.HasAura(808089));
    tempestCaster.auras.insert(560036);
    tempest.OnAuraApply(&tempestCaster, &runicTempest);
    tempestCaster.auras.insert(500288);
    tempestCaster.auras.erase(560036);
    tempest.OnAuraRemove(&tempestCaster, &tempestEnd, AURA_REMOVE_BY_CANCEL);
    assert(tempestCaster.HasAura(808089));
    tempestCaster.auras.erase(500288);
    tempestCaster.auras.insert(560036);
    tempestCaster.alive = false;
    tempestCaster.auras.erase(808089);
    tempest.OnAuraRemove(&tempestCaster, &shroudEnd, AURA_REMOVE_BY_DEATH);
    assert(!tempestCaster.HasAura(808089));
    tempestCaster.alive = true;
    tempestCaster.cls = CLASS_WILDWALKER;
    tempest.OnAuraApply(&tempestCaster, &runicTempest);
    assert(!tempestCaster.HasAura(808089));

    Player waveforged;
    waveforged.cls = CLASS_SPIRIT_MAGE;
    Aura waveforgedTalent;
    waveforgedTalent.id = 705565;
    waveforged.auras.insert(705565);
    events.OnAuraApply(&waveforged, &waveforgedTalent);
    assert(!waveforged.HasAura(808089));
    Aura waveforgedWindow;
    waveforgedWindow.id = 500469;
    waveforged.auras.insert(500469);
    events.OnAuraApply(&waveforged, &waveforgedWindow);
    assert(waveforged.HasAura(808089));
    waveforged.auras.erase(500469);
    AuraApplication windowEnd;
    windowEnd.aura = waveforgedWindow;
    events.OnAuraRemove(&waveforged, &windowEnd, AURA_REMOVE_BY_EXPIRE);
    assert(!waveforged.HasAura(808089) && waveforged.HasAura(705565));
}
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("native_compile",
                                                 args.workspace_tools / "Test-LocalLoginCollections.py")
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    enums = []
    for path, name in [("src/server/game/Entities/Unit/UnitDefines.h", "UnitState"),
                       ("src/server/game/Spells/Auras/SpellAuraDefines.h", "AuraRemoveMode"),
                       ("src/server/shared/SharedDefines.h", "SpellCastResult")]:
        enums.append(native.extractor.extract((ROOT / path).read_text(), r"enum " + name + r"\b") + ";")
    enums.append("constexpr uint32 CLASS_SPIRIT_MAGE=32, UNITHOOK_ON_AURA_APPLY=4, EFFECT_1=1, "
                 "SPELL_EFFECT_APPLY_AURA=6, SPELL_AURA_EFFECT_IMMUNITY=37, SPELL_EFFECT_KNOCK_BACK_DEST=144, "
                 "SPELL_AURA_DUMMY=4, SPELL_ATTR0_PASSIVE=0x40, PLAYERHOOK_ON_LOGIN=5;\n#define LOG_ERROR(...)")
    code = (HERE.parent / "primalist_talents/harness.cpp").read_text().split("// ACTUAL_SOURCE")[0]
    code = code.replace("// NATIVE_ENUMS", "\n".join(enums))
    code = code.replace("struct SpellInfo\n{", "struct FixtureEffect { uint32 Effect=0, ApplyAuraName=0, "
        "TriggerSpell=0, Amplitude=0, DieSides=0; std::int32_t BasePoints=0, MiscValue=0; "
        "bool IsAura(uint32 aura) const { return Effect == SPELL_EFFECT_APPLY_AURA && ApplyAuraName == aura; } };\n"
        "struct SpellInfo\n{ std::array<FixtureEffect, 3> Effects{}; uint32 Attributes = 0;")
    code = code.replace("struct Hook {", "struct PlayerScript\n{\n"
        "    PlayerScript(char const*, std::initializer_list<int>) { }\n"
        "    virtual void OnPlayerLogin(Player*) { }\n};\nstruct Hook {")
    code = code.replace("bool HasAura(uint32 id) const", "bool HasAura(uint32 id, uint32 = 0) const")
    code = code.replace("void CastSpell(Unit* target, uint32 id, bool triggered) { casts.emplace_back(target, id, triggered); }",
        "void CastSpell(Unit* target, uint32 id, bool triggered) { casts.emplace_back(target, id, triggered); "
        "target->auras.insert(id); }\nvoid RemoveAurasDueToSpell(uint32 id, uint32) { auras.erase(id); }")
    code = code.replace("virtual void OnDamage", "virtual void OnAuraApply(Unit*, Aura*) {}\nvirtual void OnDamage")
    source = (ROOT / "src/server/coa/AscensionRunemasterTalents.cpp").read_text()
    code += re.sub(r"^#include.*\n", "", source, flags=re.M) + CASES
    with tempfile.TemporaryDirectory(prefix="coa-runemaster-passives-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "runemaster-passives")
        assert result.returncode == 0, result.stdout + result.stderr
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {}
        for offset in range(20, 20 + count * 936, 936):
            sid = struct.unpack_from("<I", raw, offset)[0]
            if sid in {520768, 712310, 712337}:
                rows[sid] = struct.unpack_from("<234I", raw, offset)
        assert rows[520768][95] == 290 and rows[520768][80] + rows[520768][74] == 10
        assert rows[712310][95] == 23 and rows[712310][98] == 4000 and rows[712310][116] == 712337
        assert rows[712310][97] == 37 and rows[712310][112] == 98
        assert rows[712337][71] == 136 and rows[712337][80] + rows[712337][74] == 3
    print("PASS: Earth Tattoo ranks, acquisition/removal ordering, helper continuity, Runeshroud exit gates, "
          "the Runic Tempest marker and the Waveforged window")


if __name__ == "__main__":
    main()
