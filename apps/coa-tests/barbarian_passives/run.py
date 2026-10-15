CLI_DESCRIPTION = """Regress Might of Utgarde against the existing Barbarian completion fixture."""
import argparse
import importlib.util
from pathlib import Path
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
    Unit enemy, pet;
    enemy.guid = 2;
    pet.guid = 3;
    pet.entryId = 51265;
    pet.ownerGuid = player.guid;
    DamageInfo damage;
    ProcEventInfo event{&player, &enemy, nullptr, &damage, nullptr, 1, 4};
    Event script;
    script.fixtureOwner = script.fixtureCaster = &player;
    script.fixtureId = 801782;
    auto count = [&](uint32 id) {
        return std::count_if(player.casts.begin(), player.casts.end(),
            [id](auto const& cast) { return cast.id == id; });
    };
    assert(script.Check(event));
    script.Proc(event);
    assert(count(801783) == 1 && count(804769) == 0);
    add(player, 804768);
    script.Proc(event);
    assert(count(804769) == 0);
    player.pet = &pet;
    script.Proc(event);
    assert(count(804769) == 1);
    assert(player.casts.back().target == player.guid); // Native helper selects the owner's pet.
    pet.alive = false;
    script.Proc(event);
    pet.alive = true;
    pet.ownerGuid = 42;
    script.Proc(event);
    pet.ownerGuid = player.guid;
    pet.entryId = 42;
    script.Proc(event);
    assert(count(804769) == 1);
    pet.entryId = 51265;
    add(player, 500061);
    script.Proc(event);
    assert(count(804769) == 2 && count(805813) == 1 && count(801783) == 7);
    SpellInfo info;
    info.Id = 801783;
    event.info = &info;
    assert(!script.Check(event)); // Additional attack cannot recursively proc itself.
    event.info = nullptr;
    event.actor = &enemy;
    assert(!script.Check(event));
    event.actor = &player;
    damage.value = 0;
    assert(!script.Check(event));
    damage.value = 1000;
    event.type = PROC_FLAG_DONE_PERIODIC;
    assert(!script.Check(event));
    event.type = 4;
    player.cls = 17;
    assert(!script.Check(event));
}
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--source-ref", help="Use earlier Barbarian events for a negative control")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("barbarian_completion_fixture",
                                                 args.workspace_tools / "Test-BarbarianCompletion.py")
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    fixture.MODULE = ROOT / "src/server/coa"
    source = ((fixture.MODULE / "AscensionBarbarianEvents.cpp").read_text() if not args.source_ref else
              git_source(["git", "show",
                  f"{args.source_ref}:src/server/coa/AscensionBarbarianEvents.cpp"],
                  cwd=ROOT).decode("utf-8"))
    extract = fixture.extract
    code = fixture.common() + "\n" + "\n".join(extract(source, r"(?:bool|void) " + name + r"\([^)]*\)")
                                               for name in ["Damage", "Direct", "Melee", "Ranged", "Bleed"])
    block = extract(source, r"class aura_ascension_barbarian_event\b")
    code += ("\nstruct Event : Context { ObjectGuid _challenge=0; bool _executing=false; "
             "int32 _startingDuration=-1, _extensionUsed=0;\n")
    code += "\n".join(extract(block, r"(?:bool|void) " + name + r"\([^)]*\)")
                      for name in ["ExtendLimited", "Check", "Proc"]) + "\n};"
    with tempfile.TemporaryDirectory(prefix="coa-barbarian-passives-") as directory:
        fixture.native.OUT = Path(directory)
        fixture.Tests().run_cpp("utgarde", code, CASES)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        for offset in range(20, 20 + count * 936, 936):
            if struct.unpack_from("<I", raw, offset)[0] == 804769:
                row = struct.unpack_from("<234I", raw, offset)
                assert row[71:73] == (140, 136) and row[86:88] == (5, 5)
                assert row[116] == 804756 and row[81] + row[75] == 5
                break
        else:
            raise AssertionError("Missing Utgarde native pet whirlwind/heal helper")
    print("PASS: Utgarde proc, talent/ancestor ownership and life gates, recursion and native helper contract")


if __name__ == "__main__":
    main()
