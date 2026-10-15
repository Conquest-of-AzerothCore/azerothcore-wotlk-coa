import argparse
import struct
import sys
from pathlib import Path

from wildcard_data import add_world_arguments, world_query, write_lines

S10_REALMS = ("Darkmoon - Season 10 Wildcard", "darkmoon-wild-10")
SEASON_EVENT = 194
BOARD_SORTS = (-380, -381, -382)
HANDLED_ELSEWHERE = {100077, 100078, 100079, 81341}
NEEDS_EVENT_CREDIT = {865006, 777902}
CUSTOM_ITEM_FLOOR = 50000
ALLIANCE, HORDE = 1101, 690
FACTION_ONLY = {81255: ALLIANCE, 81250: HORDE}
BOARDS = {ALLIANCE: [402000], HORDE: [402001], 0: [402000, 402001]}
HEAD = ["QuestId", "Method", "QuestLevel", "MinLevel", "QuestSortID", "QuestInfoID", "SuggestedGroupNum",
        "RequiredFactionId1", "RequiredFactionValue1", "RequiredFactionId2", "RequiredFactionValue2",
        "NextQuestInChain",
        "RewardXPDifficulty", "RewardMoney", "RewardBonusMoney", "RewardDisplaySpell", "RewardSpell", "RewardHonor",
        "RewardKillHonor", "StartItem", "Flags", "RewardTitle", "RequiredPlayerKills", "RewardTalents",
        "RewardArenaPoints", "Unknown"]
SIGNED = {"QuestLevel", "QuestSortID", "RewardMoney", "RewardSpell"}


def signed(value):
    return value - (1 << 32) if value >= 1 << 31 else value


def strings(record, position, count):
    texts = []
    for _ in range(count):
        end = record.find(b"\0", position)
        texts.append(record[position:end].decode("utf-8", "replace"))
        position = end + 1
    return texts, position


def parse(record):
    quest = dict(zip(HEAD, struct.unpack_from("<26I", record, 0)))
    for key in SIGNED:
        quest[key] = signed(quest[key])
    items = struct.unpack_from("<8I", record, 104)
    choices = struct.unpack_from("<12I", record, 136)
    quest["RewardItems"] = [(items[i], items[i + 1]) for i in range(0, 8, 2)]
    quest["RewardChoices"] = [(choices[i], choices[i + 1]) for i in range(0, 12, 2)]
    texts, position = strings(record, 260, 5)
    quest["LogTitle"], quest["LogDescription"], quest["QuestDescription"], quest["AreaDescription"], \
        quest["QuestCompletionLog"] = texts
    objectives = struct.unpack_from("<16I", record, position)
    quest["RequiredNpcOrGo"] = [(signed(objectives[i * 4]), objectives[i * 4 + 1]) for i in range(4)]
    required = struct.unpack_from("<12I", record, position + 64)
    quest["RequiredItems"] = [(required[i], required[i + 1]) for i in range(0, 12, 2)]
    quest["ObjectiveTexts"], _ = strings(record, position + 64 + 48, 4)
    return quest


def records(path):
    data = path.read_bytes()
    if data[:4] != b"TSQW":
        return
    position = 24
    while position + 8 <= len(data):
        record_id, size = struct.unpack_from("<II", data, position)
        if (record_id == 0 and size == 0) or size > 100000:
            break
        yield record_id, data[position + 8:position + 8 + size]
        position += 8 + size


def season_quests(root):
    quests = {}
    for path in sorted(root.rglob("questcache.wdb")):
        if path.parent.name not in S10_REALMS:
            continue
        for record_id, record in records(path):
            if record_id not in quests and len(record) > 300:
                quests[record_id] = parse(record)
    return quests


def sql_text(text):
    return "'" + text.replace("\\", "\\\\").replace("'", "''").replace("\r", "").replace("\n", "\\n") + "'"


def wrap(prefix, words, width=120):
    lines, line = [], prefix
    for word in words:
        if len(line) + len(word) + 1 > width:
            lines.append(line.rstrip())
            line = ""
        line += word + " "
    lines.append(line.rstrip())
    return lines


parser = argparse.ArgumentParser(description="Writes the Call Board quests of Darkmoon - Season 10 Wildcard from "
                                             "that realm's client quest caches.")
parser.add_argument("--caches", type=Path, required=True,
                    help=f"directory searched for questcache.wdb in folders named {' or '.join(S10_REALMS)}")
add_world_arguments(parser)
parser.add_argument("output")
args = parser.parse_args()
query = world_query(args)


def ids_in(table, column, values, extra=""):
    if not values:
        return set()
    return {int(row[0]) for row in query(f"SELECT {column} FROM {table} WHERE {column} IN "
                                         f"({','.join(map(str, values))}){extra}")}


quests = {qid: q for qid, q in season_quests(args.caches).items() if q["QuestSortID"] in BOARD_SORTS
          and q["MinLevel"] <= 60 and qid not in HANDLED_ELSEWHERE and qid not in NEEDS_EVENT_CREDIT}
existing = ids_in("quest_template", "ID", set(quests),
                  f" AND ID NOT IN (SELECT quest FROM game_event_gameobject_quest WHERE eventEntry = {SEASON_EVENT})")
quests = {qid: q for qid, q in quests.items() if qid not in existing}

creatures = {o[0] for q in quests.values() for o in q["RequiredNpcOrGo"] if o[0] > 0}
objects = {-o[0] for q in quests.values() for o in q["RequiredNpcOrGo"] if o[0] < 0}
items = {item for q in quests.values() for item, _ in q["RequiredItems"] if item}
spawned = ids_in("creature", "id", creatures) | ids_in("gameobject", "id", objects)
sourced = (ids_in("creature_loot_template", "Item", items) | ids_in("gameobject_loot_template", "Item", items)
           | ids_in("reference_loot_template", "Item", items) | ids_in("npc_vendor", "item", items))
known_items = ids_in("item_template", "entry", items)
obtainable = {item for item in known_items if item in sourced or item < CUSTOM_ITEM_FLOOR}

chosen, skipped = {}, {}
for qid, q in sorted(quests.items()):
    targets = [abs(o[0]) for o in q["RequiredNpcOrGo"] if o[0]]
    needed = [item for item, _ in q["RequiredItems"] if item]
    missing = [t for t in targets if t not in spawned] + [i for i in needed if i not in obtainable]
    if missing:
        skipped[qid] = (q["LogTitle"], missing)
    else:
        chosen[qid] = q

columns = ["ID", "QuestType", "QuestLevel", "MinLevel", "QuestSortID", "QuestInfoID", "SuggestedGroupNum",
           "RewardXPDifficulty", "RewardMoney", "RewardHonor", "Flags", "AllowableRaces"]
columns += [f"{kind}{i}" for i in range(1, 5) for kind in ("RewardItem", "RewardAmount")]
columns += [f"{kind}{i}" for i in range(1, 7) for kind in ("RewardChoiceItemID", "RewardChoiceItemQuantity")]
columns += ["RewardArenaPoints", "LogTitle", "LogDescription", "QuestDescription", "AreaDescription",
            "QuestCompletionLog"]
columns += [f"RequiredNpcOrGo{i}" for i in range(1, 5)] + [f"RequiredNpcOrGoCount{i}" for i in range(1, 5)]
columns += [f"{kind}{i}" for i in range(1, 7) for kind in ("RequiredItemId", "RequiredItemCount")]
columns += [f"ObjectiveText{i}" for i in range(1, 5)]


def row(qid, q):
    values = [qid, 2, q["QuestLevel"], q["MinLevel"], q["QuestSortID"], q["QuestInfoID"], q["SuggestedGroupNum"],
              q["RewardXPDifficulty"], q["RewardMoney"], q["RewardHonor"], q["Flags"], FACTION_ONLY.get(qid, 0)]
    for item, amount in q["RewardItems"]:
        values += [item, amount]
    for item, amount in q["RewardChoices"]:
        values += [item, amount]
    values += [q["RewardArenaPoints"], sql_text(q["LogTitle"]), sql_text(q["LogDescription"]),
               sql_text(q["QuestDescription"]), sql_text(q["AreaDescription"]), sql_text(q["QuestCompletionLog"])]
    values += [o[0] for o in q["RequiredNpcOrGo"]] + [o[1] for o in q["RequiredNpcOrGo"]]
    for item, count in q["RequiredItems"]:
        values += [item, count]
    values += [sql_text(text) for text in q["ObjectiveTexts"]]
    return "(" + ", ".join(map(str, values)) + ")"


ids = ", ".join(map(str, chosen))
lines = [
    "-- Call Board quests of Darkmoon - Season 10 Wildcard up to level 60, taken from that realm's quest cache: "
    "profession",
    "-- orders, City Siege: Battle for Thunder Bluff (Alliance), Hero's Call: Ruins of Ahn'Qiraj, the Threats to",
    "-- Azeroth (Setis, Taerar) and Gorilla Warfare. Quests whose targets are not spawned here or whose items have no",
    "-- source here are left out. The boards offer them only on a Wildcard realm, whose worldserver starts the season",
    f"-- event ({SEASON_EVENT}). Generated by apps/coa-wildcard/call_board_s10_quests.py.",
]
header = "INSERT INTO `quest_template` (" + ", ".join(f"`{c}`" for c in columns) + ")"
lines += wrap("", header.split(" ")) + ["VALUES"]
rows = [row(qid, q) for qid, q in chosen.items()]
lines += [text + ("," if index + 1 < len(rows) else "") for index, text in enumerate(rows)]
updates = [f"`{c}` = VALUES(`{c}`)," for c in columns[1:]]
updates[-1] = updates[-1].rstrip(",") + ";"
lines += wrap("ON DUPLICATE KEY UPDATE", updates)
lines += wrap("DELETE FROM `quest_template_addon` WHERE `ID` IN (", (ids + ");").split(" "))
lines.append("INSERT INTO `quest_template_addon` (`ID`, `SpecialFlags`) VALUES")
lines += [f"({qid}, 1)" + ("," if index + 1 < len(chosen) else ";") for index, qid in enumerate(chosen)]
pairs = [(board, qid) for qid in chosen for board in BOARDS[FACTION_ONLY.get(qid, 0)]]
lines += wrap("DELETE FROM `gameobject_queststarter` WHERE `quest` IN (", (ids + ");").split(" "))
lines += wrap("DELETE FROM `game_event_gameobject_quest` WHERE `quest` IN (", (ids + ");").split(" "))
lines.append("INSERT INTO `game_event_gameobject_quest` (`eventEntry`, `id`, `quest`) VALUES")
lines += [f"({SEASON_EVENT}, {board}, {qid})" + ("," if index + 1 < len(pairs) else ";")
          for index, (board, qid) in enumerate(pairs)]
lines += wrap("DELETE FROM `gameobject_questender` WHERE `quest` IN (", (ids + ");").split(" "))
lines.append("INSERT INTO `gameobject_questender` (`id`, `quest`) VALUES")
lines += [f"({board}, {qid})" + ("," if index + 1 < len(pairs) else ";") for index, (board, qid) in enumerate(pairs)]
write_lines(args.output, lines)
print(f"{len(chosen)} quests written", file=sys.stderr)
for qid, (title, missing) in sorted(skipped.items()):
    print(f"skipped {qid} {title}: missing {missing}", file=sys.stderr)
