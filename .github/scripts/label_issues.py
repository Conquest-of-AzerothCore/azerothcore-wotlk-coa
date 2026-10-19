import argparse
import json
import os
import re
import subprocess
import sys


REPO = os.environ.get("GITHUB_REPOSITORY", "")

MANAGED_LABELS = [
    "Barbarian",
    "Bloodmage",
    "Bug",
    "Chronomancer",
    "Config",
    "CPP Edit",
    "Crash Fix",
    "Creature",
    "Cultist",
    "DB",
    "Dungeon",
    "Druid",
    "Feature",
    "Felsworn",
    "Guardian",
    "Hunter",
    "Item",
    "Knight of Xoroth",
    "Mage",
    "Manastorm",
    "Necromancer",
    "Not Tested",
    "Object",
    "Paladin",
    "Primalist",
    "Priest",
    "Pyromancer",
    "Quest",
    "Raid",
    "Ranger",
    "Reaper",
    "Rogue",
    "Runemaster",
    "Script",
    "Shaman",
    "Starcaller",
    "Stormbringer",
    "Sun Cleric",
    "Templar",
    "Tested",
    "Tinker",
    "Venomancer",
    "WarcraftReborn",
    "Warlock",
    "Warrior",
    "Wildcard",
    "Witch Doctor",
    "Witch Hunter",
]


CLASS_PATTERNS = {
    "Barbarian": r"\bbarbarian\b",
    "Bloodmage": r"\bbloodmage\b",
    "Chronomancer": r"\bchronomancer\b",
    "Cultist": r"\bcultist\b",
    "Felsworn": r"\bfelsworn\b",
    "Guardian": r"\bguardian\b",
    "Knight of Xoroth": r"\bknight\s+of\s+xoroth\b",
    "Necromancer": r"\bnecromancer\b",
    "Primalist": r"\bprimalist\b",
    "Pyromancer": r"\bpyromancer\b",
    "Ranger": r"\branger\b",
    "Reaper": r"\breaper\b",
    "Runemaster": r"\brunemaster\b",
    "Starcaller": r"\bstarcaller\b",
    "Stormbringer": r"\bstormbringer\b",
    "Sun Cleric": r"\bsun\s+cleric\b",
    "Templar": r"\btemplar\b",
    "Tinker": r"\btinker\b",
    "Venomancer": r"\bvenomancer\b",
    "Witch Doctor": r"\bwitch\s+doctor\b",
    "Witch Hunter": r"\bwitch\s+hunter\b",
}


CLASS_ID_LABELS = {
    12: "Barbarian",
    13: "Witch Doctor",
    14: "Felsworn",
    15: "Witch Hunter",
    16: "Stormbringer",
    17: "Knight of Xoroth",
    18: "Guardian",
    19: "Templar",
    20: "Bloodmage",
    21: "Ranger",
    22: "Chronomancer",
    23: "Necromancer",
    24: "Pyromancer",
    25: "Cultist",
    26: "Starcaller",
    27: "Sun Cleric",
    28: "Tinker",
    29: "Venomancer",
    30: "Reaper",
    31: "Primalist",
    32: "Runemaster",
}


REBORN_CLASS_ID_LABELS = {
    1: "Warrior",
    2: "Paladin",
    3: "Hunter",
    4: "Rogue",
    5: "Priest",
    7: "Shaman",
    8: "Mage",
    9: "Warlock",
    11: "Druid",
}
REBORN_CLASS_MENTION = re.compile(
    r"\b(?:warcraft\s*)?reborn\s+(" + "|".join(REBORN_CLASS_ID_LABELS.values()) + r")s?\b",
    re.IGNORECASE,
)


REPORT_SECTION_LABELS = {
    "quest": "Quest",
    "item": "Item",
    "dungeon": "Dungeon",
    "raid": "Raid",
    "crash": "Crash Fix",
    "creature": "Creature",
    "npc": "Creature",
    "object": "Object",
    "gameobject": "Object",
    "warcraftreborn": "WarcraftReborn",
}


SCOPE_LABELS = {
    "quest": "Quest",
    "quests": "Quest",
    "item": "Item",
    "items": "Item",
    "dungeon": "Dungeon",
    "dungeons": "Dungeon",
    "raid": "Raid",
    "raids": "Raid",
    "manastorm": "Manastorm",
    "wildcard": "Wildcard",
    "xoroth": "Knight of Xoroth",
    "creature": "Creature",
    "creatures": "Creature",
    "npc": "Creature",
    "npcs": "Creature",
    "object": "Object",
    "objects": "Object",
    "gameobject": "Object",
    "gameobjects": "Object",
    "warcraftreborn": "WarcraftReborn",
    **{label.replace(" ", "").casefold(): label for label in CLASS_ID_LABELS.values()},
    **{label.casefold(): label for label in REBORN_CLASS_ID_LABELS.values()},
}


TITLE_PATTERNS = {
    "Dungeon": r"\bdungeons?\b",
    "Raid": r"\braids?\b",
    "Crash Fix": (
        r"\b(?:client|server|game|realm|worldserver|instant|core)\s+crash"
        r"|\bcrash(?:es|ed|ing)?\s+(?:the\s+|my\s+)?(?:client|server|game|realm|worldserver|wow)\b"
        r"|\b(?:prevent|avoid|fix)\s+(?:a\s+|the\s+)?(?:\w+\s+)?crash\b"
        r"|\bsegfault|\bSIGSEGV\b"
    ),
}


DESCRIPTION_PATTERNS = {
    "Manastorm": r"\bmanastorm\b",
    "Wildcard": r"\bwildcard\b",
    "WarcraftReborn": (
        r"\bwarcraft\s*reborn\b"
        r"|\breborn\s+(?:warrior|paladin|hunter|rogue|priest|death\s+knight|shaman|mage|warlock|druid)s?\b"
    ),
}


REPORTER_LINE = re.compile(
    r"^(?:[ \t]*Class(?:[ \t]+ID)?[ \t]*:|\*\*Character:\*\*).*$",
    re.IGNORECASE | re.MULTILINE,
)
CONVENTIONAL_TITLE = re.compile(r"^(\w+)(?:\(([^)]*)\))?!?:")


CATEGORY_PATTERNS = {
    "CPP Edit": [
        r"\bc\+\+(?!\w)",
        r"\bcpp\b",
        r"\bc\+\+\s+edit\b",
    ],

    "Config": [
        r"\bconfig\b",
        r"\bconfiguration\b",
        r"\bconfiguration\s+issue\b",
    ],

    "DB": [
        r"\bdatabase\b",
        r"\bdb\b",
        r"\bsql\b",
        r"\bworld\s+database\b",
        r"\bcharacters\s+database\b",
        r"\bauth\s+database\b",
    ],

    "Script": [
        r"\bscript\b",
        r"\bscripting\b",
        r"\blua\s+script\b",
    ],

    "Bug": [
        r"\bbug\b",
        r"\bbugs\b",
        r"\bbroken\b",
        r"\bdoesn['’]?t\s+work\b",
        r"\bdoes\s+not\s+work\b",
        r"\bnot\s+working\b",
        r"\bincorrect\b",
        r"\bcrash(?:es|ed|ing)?\b",
        r"\bexception\b",
        r"\bfails?\b",
        r"\bfailure\b",
        r"\berror\b",
    ],
}


def gh(*args):
    command = ["gh", *args]
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print("Command failed:")
        print(" ".join(command))
        print(result.stderr)
        sys.exit(result.returncode)

    return result.stdout.strip()


def get_issue(number):
    output = gh(
        "api",
        f"repos/{REPO}/issues/{number}",
    )

    return json.loads(output)


def get_existing_labels(issue):
    return [
        label["name"]
        for label in issue.get("labels", [])
    ]


def determine_labels(issue):
    title = issue.get("title", "")
    body = issue.get("body") or ""

    text = f"{title}\n{body}"
    is_pull_request = "pull_request" in issue

    labels = []

    if not is_pull_request and is_spell_report(body):
        labels.extend(reporter_classes(body))

    described_text = f"{title}\n{REPORTER_LINE.sub('', body)}"
    for label, pattern in CLASS_PATTERNS.items():
        if re.search(pattern, described_text, re.IGNORECASE):
            labels.append(label)

    if is_pull_request:
        labels.extend(pull_request_title_labels(title))
    else:
        labels.extend(report_section_labels(title, body))

    reported_text = title if is_pull_request else f"{title}\n{report_description(body)}"
    for label, pattern in DESCRIPTION_PATTERNS.items():
        if re.search(pattern, reported_text, re.IGNORECASE):
            labels.append(label)
    labels.extend(reborn_class_mentions(reported_text))

    for label, pattern in TITLE_PATTERNS.items():
        if re.search(pattern, title, re.IGNORECASE):
            labels.append(label)

    for label, patterns in CATEGORY_PATTERNS.items():
        for pattern in patterns:
            if re.search(pattern, text, re.IGNORECASE):
                labels.append(label)
                break

    if any(label in REBORN_CLASS_ID_LABELS.values() for label in labels):
        labels.append("WarcraftReborn")

    status = determine_testing_status(body)
    if status:
        labels.append(status)

    return list(dict.fromkeys(labels))


def is_spell_report(body):
    return bool(re.search(
        r"^(?:####[ \t]+Spell|\*\*Category:\*\*[ \t]*Spell\b)[^\n]*$",
        body,
        re.IGNORECASE | re.MULTILINE,
    ))


def reporter_classes(body):
    labels = []
    for match in re.finditer(
        r"^[ \t]*Class[ \t]+ID[ \t]*:[ \t]*([0-9]{1,3})[ \t]*\r?$",
        body,
        re.IGNORECASE | re.MULTILINE,
    ):
        class_id = int(match.group(1))
        label = CLASS_ID_LABELS.get(class_id) or REBORN_CLASS_ID_LABELS.get(class_id)
        if label:
            labels.append(label)

    for character in re.findall(r"^\*\*Character:\*\*.*$", body, re.IGNORECASE | re.MULTILINE):
        for label, pattern in CLASS_PATTERNS.items():
            if re.search(pattern, character, re.IGNORECASE):
                labels.append(label)
        for label in REBORN_CLASS_ID_LABELS.values():
            if re.search(rf"\blevel\s+\d+\s+{label}\b", character, re.IGNORECASE):
                labels.append(label)
    return labels


def reborn_class_mentions(text):
    by_name = {label.casefold(): label for label in REBORN_CLASS_ID_LABELS.values()}
    return [by_name[match.casefold()] for match in REBORN_CLASS_MENTION.findall(text)]


def report_section_labels(title, body):
    sections = re.findall(r"^####[ \t]+(\w+)[ \t]*\r?$", body, re.MULTILINE)
    categories = re.findall(r"^\*\*Category:\*\*[ \t]*(.+?)[ \t]*\r?$", body, re.IGNORECASE | re.MULTILINE)
    sections += [part for category in categories for part in category.split("/")]
    prefix = re.match(r"\[([^\]]+)\]", title)
    if prefix:
        sections += prefix.group(1).split("/")
    return [
        REPORT_SECTION_LABELS[section.strip().casefold()]
        for section in sections
        if section.strip().casefold() in REPORT_SECTION_LABELS
    ]


def report_description(body):
    match = re.search(
        r"^(?:####[ \t]+Issue|###[ \t]+Description)[ \t]*\r?$(.*?)(?=^Location:|^###[ \t]|^<sub>|\Z)",
        body,
        re.IGNORECASE | re.MULTILINE | re.DOTALL,
    )
    return match.group(1) if match else ""


def pull_request_title_labels(title):
    match = CONVENTIONAL_TITLE.match(title)
    if not match:
        return []

    kind, scope = match.groups()
    labels = ["Feature"] if kind.casefold() == "feat" else []
    for part in (scope or "").split("/"):
        label = SCOPE_LABELS.get(part.strip().casefold())
        if label:
            labels.append(label)
    return labels


def determine_testing_status(body):
    statuses = set()
    awaiting_status = False
    for line in body.splitlines():
        line = line.strip()
        if not line:
            continue

        if re.fullmatch(r"#{1,6}\s+Testing status", line, re.IGNORECASE):
            awaiting_status = True
            continue

        match = re.fullmatch(
            r"(?:Testing status:\s*|[-*]\s+\[[xX]\]\s+)(Tested|Not Tested)",
            line,
            re.IGNORECASE,
        )
        if not match and awaiting_status:
            match = re.fullmatch(r"(Tested|Not Tested)", line, re.IGNORECASE)
        awaiting_status = False
        if match:
            statuses.add(match.group(1).casefold())

    if len(statuses) == 1:
        return "Tested" if "tested" in statuses else "Not Tested"
    return None


def update_issue(number, issue, desired_labels, dry_run=False):
    current_labels = {label.casefold() for label in get_existing_labels(issue)}
    has_testing_status = bool(current_labels & {"tested", "not tested"})
    to_add = [
        label for label in desired_labels
        if label in MANAGED_LABELS
        and label.casefold() not in current_labels
        and not (has_testing_status and label in {"Tested", "Not Tested"})
    ]

    if not to_add:
        print(f"#{number}: no changes")
        return

    verb = "would add" if dry_run else "adding"
    print(f"#{number}: {verb}: {', '.join(to_add)}")
    if not dry_run:
        resource = "pr" if "pull_request" in issue else "issue"
        gh(resource, "edit", str(number), "--add-label", ",".join(to_add), "--repo", REPO)


def label_issue(number, dry_run=False):
    issue = get_issue(number)
    update_issue(number, issue, determine_labels(issue), dry_run)


def main():
    parser = argparse.ArgumentParser(description="Add issue and PR labels while preserving existing labels.")
    parser.add_argument("--all", action="store_true", help="Process all open and closed issues and PRs.")
    parser.add_argument(
        "--dry-run", action="store_true", default=os.environ.get("DRY_RUN", "").lower() == "true",
        help="Print proposed additions without changing any labels.",
    )
    args = parser.parse_args()
    number = os.environ.get("ISSUE_NUMBER", "").strip()
    if not REPO:
        parser.error("GITHUB_REPOSITORY was not supplied.")
    if args.all and number:
        parser.error("Use either ISSUE_NUMBER or --all, not both.")
    if not args.all and not re.fullmatch(r"[1-9][0-9]*", number):
        parser.error("ISSUE_NUMBER must be a positive issue or PR number.")

    if args.all:
        numbers = gh(
            "api", "--paginate", f"repos/{REPO}/issues?state=all&per_page=100",
            "--jq", ".[].number",
        ).splitlines()
    else:
        numbers = [number]

    for number in numbers:
        label_issue(number, args.dry_run)


if __name__ == "__main__":
    main()
