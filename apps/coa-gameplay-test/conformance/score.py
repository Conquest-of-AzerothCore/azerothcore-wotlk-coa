CLI_DESCRIPTION = """Score a directory of reader records against an existing class file's hand-written entries.

For each of the 9 entry kinds, classifies every ground-truth and generated entry (matched by the kind's key
field, e.g. 'aura' for procs/triggers, 'spell' for behaviours, ('spell', 'effect') for the per-effect kinds) as
match, miss, false_claim or wrong_value, then reports precision and recall per kind and overall.
"""

import argparse
import json
from pathlib import Path
import sys

from compare import ABSOLUTE_TOLERANCE, RELATIVE_TOLERANCE
from records import ENTRY_KINDS, KEY_FIELDS, key_of, load_records


def ground_truth_entries(class_file: dict, kind: str) -> dict:
    grouped: dict = {}
    for entry in class_file.get(kind, []):
        grouped.setdefault(key_of(kind, entry), []).append(entry)
    return grouped


def generated_entries(records: list[dict], kind: str) -> dict:
    grouped: dict = {}
    for record in records:
        if record['entry_kind'] == kind:
            grouped.setdefault(key_of(kind, record['entry']), []).append(record['entry'])
    return grouped


def values_equal(expected, actual) -> bool:
    if isinstance(expected, (int, float)) and not isinstance(expected, bool) and isinstance(actual, (int, float)):
        margin = max(ABSOLUTE_TOLERANCE, RELATIVE_TOLERANCE * abs(float(expected)))
        return abs(float(expected) - float(actual)) <= margin
    if isinstance(expected, dict) and isinstance(actual, dict):
        return set(expected) == set(actual) and all(values_equal(expected[key], actual[key]) for key in expected)
    if isinstance(expected, (list, tuple)) and isinstance(actual, (list, tuple)):
        return len(expected) == len(actual) and all(values_equal(a, b) for a, b in zip(expected, actual))
    return expected == actual


def entries_match(kind: str, expected: dict, actual: dict) -> bool:
    fields = set(expected) | set(actual)
    return all(values_equal(expected.get(field), actual.get(field)) for field in fields)


def score_kind(class_file: dict, records: list[dict], kind: str) -> dict:
    truth = ground_truth_entries(class_file, kind)
    generated = generated_entries(records, kind)
    match = miss = false_claim = wrong_value = 0
    for key, expected_entries in truth.items():
        remaining = list(generated.get(key, []))
        for expected in expected_entries:
            matched = next((candidate for candidate in remaining if entries_match(kind, expected, candidate)), None)
            if matched is not None:
                match += 1
                remaining.remove(matched)
            elif remaining:
                wrong_value += 1
                remaining.pop(0)
            else:
                miss += 1
        generated[key] = remaining
    for entries in generated.values():
        false_claim += len(entries)
    precision_base = match + false_claim + wrong_value
    recall_base = match + miss
    return {
        'kind': kind,
        'match': match,
        'miss': miss,
        'false_claim': false_claim,
        'wrong_value': wrong_value,
        'precision': match / precision_base if precision_base else None,
        'recall': match / recall_base if recall_base else None,
    }


def score(class_file: dict, records: list[dict]) -> dict:
    per_kind = {kind: score_kind(class_file, records, kind) for kind in ENTRY_KINDS}
    total_match = sum(entry['match'] for entry in per_kind.values())
    total_miss = sum(entry['miss'] for entry in per_kind.values())
    total_false = sum(entry['false_claim'] for entry in per_kind.values())
    total_wrong = sum(entry['wrong_value'] for entry in per_kind.values())
    precision_base = total_match + total_false + total_wrong
    recall_base = total_match + total_miss
    return {
        'per_kind': per_kind,
        'overall': {
            'match': total_match, 'miss': total_miss, 'false_claim': total_false, 'wrong_value': total_wrong,
            'precision': total_match / precision_base if precision_base else None,
            'recall': total_match / recall_base if recall_base else None,
        },
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--records', type=Path, required=True, help='a directory of generated record JSON files')
    parser.add_argument('--class-file', type=Path, required=True, help='the hand-written classes/<name>.json file')
    parser.add_argument('--out', type=Path, help='write the score JSON here instead of stdout only')
    args = parser.parse_args(argv)
    class_file = json.loads(args.class_file.read_text(encoding='utf-8'))
    records = load_records(args.records)
    result = score(class_file, records)
    text = json.dumps(result, indent=2, sort_keys=True)
    if args.out:
        args.out.write_text(text + '\n', encoding='utf-8')
        print(args.out)
    else:
        print(text)
    overall = result['overall']
    print(f"overall: match={overall['match']} miss={overall['miss']} false_claim={overall['false_claim']} "
         f"wrong_value={overall['wrong_value']} precision={overall['precision']} recall={overall['recall']}",
         file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main())
