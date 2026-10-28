import argparse
import re
import sys

from wildcard_data import Dbc, add_dbc_argument, write_lines

PRESTIGE_CREDIT = 888101
CRITERIA_KILL_CREATURE = 0
DATA_NONE, DATA_CLASS_RACE = 0, 21
CLASSES = {
    "Warrior": 1, "Paladin": 2, "Hunter": 3, "Rogue": 4, "Priest": 5, "Death Knight": 6, "Shaman": 7, "Mage": 8,
    "Warlock": 9, "Druid": 11,
}
RACES = {
    "Human": 1, "Orc": 2, "Dwarf": 3, "Night Elf": 4, "Undead": 5, "Forsaken": 5, "Tauren": 6, "Gnome": 7,
    "Troll": 8, "Blood Elf": 10, "Draenei": 11,
}

parser = argparse.ArgumentParser(description="Writes the achievement_criteria_data and title rewards that let the "
                                             "Prestige achievements complete.")
add_dbc_argument(parser)
parser.add_argument("output")
args = parser.parse_args()

achievements = Dbc(args.dbc, "Achievement.dbc")
titles = {row[0]: achievements.text(row[4]) for row in achievements.rows}
rows = []
for row in Dbc(args.dbc, "Achievement_Criteria.dbc").rows:
    criteria_id, achievement, kind, creature = row[0], row[1], row[2], row[3]
    title = titles.get(achievement, "")
    if kind != CRITERIA_KILL_CREATURE or creature != PRESTIGE_CREDIT or \
            not re.match(r"(Realm First! )?Prestige \d+", title):
        continue
    words = re.sub(r"^(Realm First! )?Prestige \d+ ?", "", title)
    race = 0
    for name in sorted(RACES, key=len, reverse=True):
        if words == name or words.startswith(name + " "):
            race = RACES[name]
            words = words[len(name):].strip()
            break
    cls = CLASSES.get(words, 0)
    if words and not cls:
        raise SystemExit(f"unknown subject in {title!r}: {words!r}")
    rows.append((criteria_id, DATA_CLASS_RACE if cls or race else DATA_NONE, cls, race, title))
rows.sort()

lines = [
    "-- The Prestige achievements count kill credit of creature 888101, which mod-coa-prestige grants once per",
    "-- activation. AzerothCore counts a kill-creature criterion only when achievement_criteria_data holds a row for",
    "-- it, so Prestige 1-10 never completed. Plain criteria get a NONE row; the race and class realm firsts get",
    "-- S_PLAYER_CLASS_RACE like the level realm firsts.",
    "-- Generated from Achievement.dbc and Achievement_Criteria.dbc by apps/coa-wildcard/prestige_achievements.py.",
    "DELETE FROM `achievement_criteria_data` WHERE `type` IN (0, 21) AND `criteria_id` IN (",
]
ids = [r[0] for r in rows]
for start in range(0, len(ids), 14):
    lines.append(", ".join(map(str, ids[start:start + 14])) + ("," if start + 14 < len(ids) else ");"))
lines.append("INSERT INTO `achievement_criteria_data` (`criteria_id`, `type`, `value1`, `value2`, `ScriptName`) VALUES")
for index, (criteria_id, kind, cls, race, title) in enumerate(rows):
    end = "," if index + 1 < len(rows) else ";"
    lines.append(f"({criteria_id}, {kind}, {cls}, {race}, ''){end} -- {title}")
lines += [
    "",
    "-- Each Prestige level earns its title: Prestige 1-9 (13100-13108) award CharTitles 200-208 (\"%s I\" to",
    "-- \"%s IX\") and Prestige 10 (13109) awards 209 (\"The Prestigious %s\").",
    "DELETE FROM `achievement_reward` WHERE `ID` BETWEEN 13100 AND 13109;",
    "INSERT INTO `achievement_reward` (`ID`, `TitleA`, `TitleH`, `ItemID`, `Sender`, `Subject`, `Body`,",
    "    `MailTemplateID`) VALUES",
]
for level in range(10):
    end = "," if level < 9 else ";"
    lines.append(f"({13100 + level}, {200 + level}, {200 + level}, 0, 0, NULL, NULL, 0){end}")
write_lines(args.output, lines)
print(f"{len(rows)} criteria rows ({sum(1 for r in rows if r[1] == DATA_NONE)} plain)", file=sys.stderr)
