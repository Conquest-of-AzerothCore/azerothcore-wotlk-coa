CLI_DESCRIPTION = """Check which stock-class tests a classless Hero passes, without a server.

Compiles AscensionHeroClass.h and checks each class context the core asks a Hero about: relics and shields, the
reactive Overpower and Counterattack states (answered from what the Hero owns), Death Knight runes, Shaman
weapon imbues, Druid forms, Priest Spirit of Redemption, tamed pets and charmed demons, and that the contexts
which choose a stock class's start, quests, armor specialization or stats stay unanswered.
No database, server build or game client is needed.
"""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]

MAIN = r"""
#include "AscensionHeroClass.h"
#include <cstdio>
#include <set>

using namespace AscensionHeroClass;

namespace
{
int failures = 0;
void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

std::set<std::uint32_t> spellbook;
bool HasSpell(std::uint32_t spellId) { return spellbook.count(spellId) != 0; }
std::optional<bool> Ask(std::uint8_t stockClass, std::uint8_t context)
{
    return Answer(stockClass, context, HasSpell);
}
bool Yes(std::uint8_t stockClass, std::uint8_t context)
{
    return Ask(stockClass, context) == std::optional<bool>(true);
}
bool Unanswered(std::uint8_t stockClass, std::uint8_t context) { return !Ask(stockClass, context).has_value(); }

constexpr std::uint8_t CONTEXT_INIT = 1;
constexpr std::uint8_t CONTEXT_QUEST = 3;
constexpr std::uint8_t CONTEXT_STATS = 4;
constexpr std::uint8_t CONTEXT_TELEPORT = 2;
constexpr std::uint8_t CONTEXT_EQUIP_ARMOR_CLASS = 14;
}

int main()
{
    bool relics = true;
    for (std::uint8_t stockClass : { PALADIN, DRUID, SHAMAN, WARLOCK, DEATH_KNIGHT })
        relics = relics && Yes(stockClass, CONTEXT_EQUIP_RELIC);
    Check(relics, "a Hero equips librams, idols, totems, misc relics and sigils");
    Check(Yes(PALADIN, CONTEXT_EQUIP_SHIELDS) && Yes(WARRIOR, CONTEXT_EQUIP_SHIELDS) &&
        Yes(SHAMAN, CONTEXT_EQUIP_SHIELDS), "a Hero equips shields");

    Check(Yes(DEATH_KNIGHT, CONTEXT_ABILITY), "a Hero has runes and runic power");
    Check(Yes(SHAMAN, CONTEXT_ABILITY), "a Hero's weapon imbues scale with weapon speed");
    Check(Yes(DRUID, CONTEXT_ABILITY), "a Hero leaving a druid form returns to mana");
    Check(Yes(PRIEST, CONTEXT_ABILITY), "a Hero can trigger Spirit of Redemption");
    Check(Unanswered(PALADIN, CONTEXT_ABILITY), "a specialization switch leaves a Hero's Righteous Fury");
    Check(Unanswered(ROGUE, CONTEXT_ABILITY), "rogue ability tests stay stock");

    Check(Ask(WARRIOR, CONTEXT_ABILITY_REACTIVE) == std::optional<bool>(false) &&
            Ask(HUNTER, CONTEXT_ABILITY_REACTIVE) == std::optional<bool>(false),
        "without Overpower or Counterattack a Hero sets neither reactive state");
    spellbook = { 7384 };
    Check(Yes(WARRIOR, CONTEXT_ABILITY_REACTIVE) &&
            Ask(HUNTER, CONTEXT_ABILITY_REACTIVE) == std::optional<bool>(false),
        "Overpower makes a dodged attack ready Overpower");
    spellbook = { 19308 };
    Check(Yes(HUNTER, CONTEXT_ABILITY_REACTIVE), "any Counterattack rank makes a parry ready Counterattack");
    Check(Unanswered(ROGUE, CONTEXT_ABILITY_REACTIVE),
        "a Hero's dodge still lights Revenge rather than Riposte's skip");
    spellbook.clear();

    Check(Yes(HUNTER, CONTEXT_PET), "a Hero's tamed pets are hunter pets");
    Check(Unanswered(DEATH_KNIGHT, CONTEXT_PET) && Unanswered(WARLOCK, CONTEXT_PET),
        "warlock and ghoul pet rules stay stock");
    Check(Yes(WARLOCK, CONTEXT_PET_CHARM), "a charmed demon gets the warlock pet bar");

    bool stockStart = true;
    for (std::uint8_t context : { CONTEXT_INIT, CONTEXT_QUEST, CONTEXT_TELEPORT, CONTEXT_EQUIP_ARMOR_CLASS })
        stockStart = stockStart && Unanswered(DEATH_KNIGHT, context);
    Check(stockStart, "a Hero never starts, quests or teleports as a Death Knight");
    bool stats = true;
    for (std::uint8_t stockClass : { WARRIOR, PALADIN, HUNTER, ROGUE, SHAMAN, DRUID })
        stats = stats && Unanswered(stockClass, CONTEXT_STATS);
    Check(stats, "a Hero's attack power keeps its own formula");

    return failures ? 1 : 0;
}
"""


def main():
    argparse.ArgumentParser(description=CLI_DESCRIPTION).parse_args()
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-hero-class-") as directory:
        out = Path(directory)
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        executable = out / ("contexts.exe" if os.name == "nt" else "contexts")
        include = ROOT / "src/server/coa"
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/I" + str(include), str(out / "main.cpp"),
                     "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-I" + str(include), str(out / "main.cpp"), "-o",
                     str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Hero class context harness did not compile:\n" + build.stdout + build.stderr)
        raise SystemExit(subprocess.run([str(executable)], text=True).returncode)


if __name__ == "__main__":
    main()
