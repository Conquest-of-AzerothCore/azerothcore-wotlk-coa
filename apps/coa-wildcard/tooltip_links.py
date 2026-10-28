import argparse
import re
import sys

from wildcard_data import Dbc, add_dbc_argument, write_lines

SPELL_NAME, SPELL_DESCRIPTION = 136, 170
CA_ID, CA_TYPE, CA_SPELLS, CA_FLAGS, CA_MODES = 0, 1, 5, 120, 121
DRAFT_ONLY = 0x1000000
MIN_NAME = 4
COLOR = re.compile(r"\|c[0-9A-Fa-f]{8}|\|r")
REQUIRED = re.compile(r"@req:(\d+)@")

parser = argparse.ArgumentParser(description="Writes ascension_wildcard_tooltip_links: every Wildcard ability a "
                                             "talent's tooltip names.")
add_dbc_argument(parser)
parser.add_argument("output")
args = parser.parse_args()

spells = Dbc(args.dbc, "Spell.dbc")
spell_rows = {row[0]: row for row in spells.rows}
advancement = Dbc(args.dbc, "CharacterAdvancement.dbc")

entries = []
for row in advancement.rows:
    kind = advancement.text(row[CA_TYPE])
    ranks = [spell for spell in row[CA_SPELLS:CA_SPELLS + 5] if spell]
    if (kind in ("Ability", "Talent", "TalentAbility") and ((row[CA_MODES] >> 8) & 0xFF) == 1
            and not row[CA_FLAGS] & DRAFT_ONLY and row[CA_ID] <= 0xFFFFF and ranks and ranks[0] in spell_rows):
        entries.append((row[CA_ID], kind == "Talent", ranks))

abilities_by_name = {}
abilities_by_spell = {}
for entry, talent, ranks in entries:
    if talent:
        continue
    name = spells.text(spell_rows[ranks[0]][SPELL_NAME])
    if len(name) >= MIN_NAME:
        abilities_by_name.setdefault(name, set()).add(entry)
    for spell in ranks:
        abilities_by_spell[spell] = entry
patterns = [(name, re.compile(r"(?<![A-Za-z'])" + re.escape(name) + r"(?![A-Za-z'])"))
            for name in sorted(abilities_by_name, key=len, reverse=True)]

links = set()
for entry, talent, ranks in entries:
    if not talent:
        continue
    text = COLOR.sub("", spells.text(spell_rows[ranks[0]][SPELL_DESCRIPTION]))
    for spell in REQUIRED.findall(text):
        if int(spell) in abilities_by_spell:
            links.add((entry, abilities_by_spell[int(spell)]))
    taken = []
    for name, pattern in patterns:
        for match in pattern.finditer(text):
            if any(start <= match.start() and match.end() <= end for start, end in taken):
                continue
            taken.append(match.span())
            links.update((entry, ability) for ability in abilities_by_name[name])

lines = [
    "-- Ascension's own talents name the abilities they work with in their tooltips (Explosive Eruption: Pyroblast",
    "-- refreshes the cooldown of Lava Lash) or require them with @req:<spell>@; "
    "many of these interactions are scripted",
    "-- and invisible to spell class masks. Each talent is linked to every Wildcard ability its rank 1 tooltip names",
    "-- (longest name wins, so Seal of Arcane Wrath is not Wrath), and a Wildcard synergy roll scores the pair.",
    "-- Generated from Spell.dbc and CharacterAdvancement.dbc by apps/coa-wildcard/tooltip_links.py.",
    "DROP TABLE IF EXISTS `ascension_wildcard_tooltip_links`;",
    "CREATE TABLE `ascension_wildcard_tooltip_links` (",
    "  `Talent` INT UNSIGNED NOT NULL,",
    "  `Ability` INT UNSIGNED NOT NULL,",
    "  PRIMARY KEY (`Talent`, `Ability`)",
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
    "",
    "DELETE FROM `ascension_wildcard_tooltip_links`;",
    "INSERT INTO `ascension_wildcard_tooltip_links` (`Talent`, `Ability`) VALUES",
]
pairs = sorted(links)
for start in range(0, len(pairs), 6):
    chunk = ", ".join(f"({talent}, {ability})" for talent, ability in pairs[start:start + 6])
    lines.append(chunk + ("," if start + 6 < len(pairs) else ";"))
write_lines(args.output, lines)
print(f"{len(pairs)} links from {len({talent for talent, _ in pairs})} talents", file=sys.stderr)
