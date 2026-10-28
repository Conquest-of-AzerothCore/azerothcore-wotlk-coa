import argparse
import re
import sys

from wildcard_data import Dbc, add_dbc_argument, write_lines

CLASSES = {
    "Warrior": 1, "Paladin": 2, "Hunter": 3, "Rogue": 4, "Priest": 5, "Death Knight": 6, "Shaman": 7, "Mage": 8,
    "Warlock": 9, "Hero": 10, "Druid": 11, "Barbarian": 12, "Witch Doctor": 13, "Felsworn": 14, "Witch Hunter": 15,
    "Stormbringer": 16, "Knight of Xoroth": 17, "Guardian": 18, "Templar": 19, "Son of Arugal": 20, "Bloodmage": 20,
    "Ranger": 21, "Chronomancer": 22, "Necromancer": 23, "Pyromancer": 24, "Cultist": 25, "Starcaller": 26,
    "Sun Cleric": 27, "Tinker": 28, "Venomancer": 29, "Reaper": 30, "Primalist": 31, "Runemaster": 32,
}
RACES = {
    "Human": 1, "Orc": 2, "Dwarf": 3, "Night Elf": 4, "Undead": 5, "Forsaken": 5, "Tauren": 6, "Gnome": 7,
    "Troll": 8, "Blood Elf": 10, "Draenei": 11,
}
MODES = [
    (re.compile(r"\bIronman\b"), 0x002, "ironman"),
    (re.compile(r"\bSurvivalist\b"), 0x004, "survivalist"),
    (re.compile(r"\bDraft\b"), 0x008, "draft"),
    (re.compile(r"\bResolute\b|\bAbsolute Resolve\b"), 0x020, "resolute"),
    (re.compile(r"\bWild[Cc]ard\b"), 0x040, "wildcard"),
    (re.compile(r"\bFelforged\b"), 0x080, "felforged"),
    (re.compile(r"\bNightmare Mode\b"), 0x100, "nightmare"),
]
SCRIPT_PREFIX = "achievement_coa_game_mode_"
STOCK_CLASS_RACE_CRITERIA = {5018, *range(5213, 5222), *range(5229, 5239)}
CRITERIA_REACH_LEVEL = 5
DATA_SCRIPT, DATA_CLASS_RACE = 11, 21


def subject(title):
    match = re.search(r"Level \d+ (.+)$", title)
    if not match:
        return 0, 0
    words = match.group(1)
    race = 0
    for name in sorted(RACES, key=len, reverse=True):
        if words == name or words.startswith(name + " "):
            race = RACES[name]
            words = words[len(name):].strip()
            break
    cls = CLASSES.get(words, 0)
    if words and not cls:
        raise SystemExit(f"unknown subject in {title!r}: {words!r}")
    return cls, race


parser = argparse.ArgumentParser(description="Writes the class, race and game mode conditions of Ascension's "
                                             "reach-level achievements as achievement_criteria_data.")
add_dbc_argument(parser)
parser.add_argument("output")
args = parser.parse_args()

achievements = Dbc(args.dbc, "Achievement.dbc")
titles = {row[0]: achievements.text(row[4]) for row in achievements.rows}
rows = []
scripts = {}
for row in Dbc(args.dbc, "Achievement_Criteria.dbc").rows:
    criteria_id, achievement, kind = row[0], row[1], row[2]
    if kind != CRITERIA_REACH_LEVEL or achievement not in titles:
        continue
    title = titles[achievement]
    cls, race = subject(title)
    if (cls or race) and criteria_id not in STOCK_CLASS_RACE_CRITERIA:
        rows.append((criteria_id, DATA_CLASS_RACE, cls, race, "", title))
    modes = [(bit, name) for pattern, bit, name in MODES if pattern.search(title)]
    if modes:
        script = SCRIPT_PREFIX + "_".join(name for _, name in modes)
        scripts[script] = sum(bit for bit, _ in modes)
        rows.append((criteria_id, DATA_SCRIPT, 0, 0, script, title))

rows.sort()
lines = [
    "-- Ascension names the class, race and game mode of its reach-level achievements (\"Level 60 Barbarian\",",
    "-- \"Realm First! Level 60 Human\", \"WildCard Level 60\") but Achievement_Criteria.dbc only asks for the level,",
    "-- so every character reaching a level earned all of them. Class and race become S_PLAYER_CLASS_RACE data like",
    "-- the stock realm-first rows; game modes a scripted check of the character's game mode mask.",
    "-- Generated from Achievement.dbc and Achievement_Criteria.dbc by "
    "apps/coa-wildcard/level_achievement_conditions.py.",
]
for kind in (DATA_CLASS_RACE, DATA_SCRIPT):
    ids = sorted({r[0] for r in rows if r[1] == kind})
    lines.append(f"DELETE FROM `achievement_criteria_data` WHERE `type` = {kind} AND `criteria_id` IN (")
    for start in range(0, len(ids), 14):
        chunk = ", ".join(map(str, ids[start:start + 14]))
        lines.append(chunk + ("," if start + 14 < len(ids) else ");"))
lines.append("INSERT INTO `achievement_criteria_data` (`criteria_id`, `type`, `value1`, `value2`, `ScriptName`) VALUES")
for index, (criteria_id, kind, value1, value2, script, title) in enumerate(rows):
    end = "," if index + 1 < len(rows) else ";"
    line = f"({criteria_id}, {kind}, {value1}, {value2}, '{script}'){end} -- {title.replace('--', '-')}"
    lines.append(line if len(line) <= 120 else line[:117] + "...")
write_lines(args.output, lines)
print(f"{len(rows)} rows for {len({r[0] for r in rows})} criteria", file=sys.stderr)
for script, mask in sorted(scripts.items(), key=lambda item: item[1]):
    print(f"{script} 0x{mask:03X}", file=sys.stderr)
