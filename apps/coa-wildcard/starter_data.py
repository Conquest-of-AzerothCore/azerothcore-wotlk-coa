import argparse
import collections
import re
import sys
from pathlib import Path

from wildcard_data import Dbc, add_dbc_argument, write_lines

CA_TYPE, CA_SPELLS, CA_LEVEL, CA_FLAGS, CA_MODES = 1, 5, 28, 120, 121
DRAFT_ONLY = 0x1000000
NUMBER = re.compile(r"(-?\d+)\s*,\s*--")
EVENT = re.compile(r'\["ev"\] = "([A-Z_]+)"')
ARGUMENTS = re.compile(r'\["args"\] = \{([^}]*)\}')


def events(text):
    body = None
    for line in text.splitlines():
        if line == "\t\t\t{":
            body = []
        elif body is not None and line.startswith("\t\t\t}, -- ["):
            yield "\n".join(body)
            body = None
        elif body is not None:
            body.append(line)


def rolls(path):
    found, learned = [], []
    for body in events(path.read_text(encoding="utf-8", errors="replace")):
        event = EVENT.search(body)
        if not event:
            continue
        if event.group(1) == "WILDCARD_ENTRY_LEARNED":
            learned.append(int(NUMBER.findall(ARGUMENTS.search(body).group(1))[0]))
        elif event.group(1) == "WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT":
            found.append(learned)
            learned = []
    return found


def table(name, weights, spells):
    lines = [f"inline constexpr std::array<Entry, {len(weights)}> {name} =", "{{"]
    lines += [f"    {{ {entry}, {spells[entry]}, {weight} }}," for entry, weight in sorted(weights.items())]
    return lines + ["}};"]


parser = argparse.ArgumentParser(description="Writes AscensionWildcardStarterData.h, the weights of the starting "
                                             "abilities, from Wildcard roll harvests of Darkmoon - Season 10.")
add_dbc_argument(parser)
parser.add_argument("harvest", type=Path, nargs="+",
                    help="WildcardHarvest SavedVariables files with starting ability rerolls")
parser.add_argument("output")
args = parser.parse_args()

advancement = Dbc(args.dbc, "CharacterAdvancement.dbc")
spells = {row[0]: row[CA_SPELLS] for row in advancement.rows}
pool = {row[0] for row in advancement.rows if advancement.text(row[CA_TYPE]) == "Ability" and row[CA_LEVEL] <= 1
        and not row[CA_FLAGS] & DRAFT_ONLY and ((row[CA_MODES] >> 8) & 0xFF) == 1}
starts = [roll for path in args.harvest for roll in rolls(path)]
first = collections.Counter(roll[0] for roll in starts)
other = collections.Counter(entry for roll in starts for entry in roll[1:])
if not all(len(roll) == 4 and len(set(roll)) == 4 for roll in starts) or not set(first) <= pool \
        or not set(other) <= pool:
    raise SystemExit("the harvest holds starting rolls that are not four distinct starting abilities")

write_lines(args.output, [
    "#ifndef ASCENSION_WILDCARD_STARTER_DATA_H",
    "#define ASCENSION_WILDCARD_STARTER_DATA_H",
    "",
    "#include <array>",
    "#include <cstdint>",
    "",
    "namespace AscensionWildcardStarterData",
    "{",
    "struct Entry",
    "{",
    "    std::uint32_t EntryId;",
    "    std::uint32_t SpellId;",
    "    std::uint32_t Weight;",
    "};",
    "",
    *table("FirstAbility", dict(first), spells),
    "",
    *table("OtherAbilities", {entry: other.get(entry, 1) for entry in pool}, spells),
    "}",
    "",
    "#endif",
])
print(f"{len(starts)} starting rolls, {len(first)} first abilities, {len(pool)} others", file=sys.stderr)
