CLI_DESCRIPTION = """Score a directory of reader records against an existing class file's hand-written entries.

For each of the 8 scored kinds (unmodelled_effects merges into effect_notes, same required fields, one claim),
classifies every ground-truth and generated entry (matched by the kind's key field, e.g. 'aura' for
procs/triggers, 'spell' for behaviours, ('spell', 'effect') for the per-effect kinds) as match, miss,
false_claim or wrong_value, then reports precision and recall per kind and overall. Matching compares
operational fields only by default (free-text wording excluded, numeric fields within compare.py's tolerance);
pass --strict for full field-for-field equality. Pass --records-b for a second reader's directory to score only
the records both sides agree on (same key, entries_match) against the class file.
"""

import argparse
import json
from pathlib import Path
import sys

from compare import ABSOLUTE_TOLERANCE, RELATIVE_TOLERANCE
from records import ENTRY_KINDS, KEY_FIELDS, key_of, load_records

OPERATIONAL_FIELDS = {
    'procs': frozenset({'aura', 'proc_spell', 'spell_proc', 'chance_token'}),
    'triggers': frozenset({'aura', 'observe_spell'}),
    'behaviours': frozenset({'spell', 'kind', 'expected', 'expected_before', 'expected_after', 'before_expected',
                             'expected_ms', 'expected_ratio', 'levels', 'fraction'}),
    'passive_targets': frozenset({'spell', 'effect', 'targets'}),
    'talent_modifiers': frozenset({'talent', 'source'}),
    'effect_overrides': frozenset({'spell', 'effect', 'misc_value', 'base_points'}),
    'unmodelled_effects': frozenset({'spell', 'effect'}),
    'literal_tokens': frozenset({'spell', 'effect', 'value'}),
    'effect_notes': frozenset({'spell', 'effect'}),
}
KIND_MERGES = {'unmodelled_effects': 'effect_notes', 'effect_notes': 'effect_notes'}
SCORED_KINDS = tuple(kind for kind in ENTRY_KINDS if kind != 'unmodelled_effects')


def operational_scope(kind: str) -> frozenset:
    return OPERATIONAL_FIELDS.get(kind, frozenset()) | frozenset(KEY_FIELDS.get(kind, ()))


def canonical_kind(kind: str) -> str:
    return KIND_MERGES.get(kind, kind)


def ground_truth_entries(class_file: dict, kind: str) -> dict:
    grouped: dict = {}
    for source_kind in (k for k in class_file if canonical_kind(k) == kind):
        for entry in class_file.get(source_kind, []) or []:
            if isinstance(entry, dict) and set(KEY_FIELDS.get(kind, ())) <= set(entry):
                grouped.setdefault(key_of(kind, entry), []).append(entry)
    return grouped


def generated_entries(records: list[dict], kind: str) -> dict:
    grouped: dict = {}
    for record in records:
        if canonical_kind(record['entry_kind']) == kind:
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


def scored_fields(kind: str, fields: set, strict: bool) -> set:
    if strict:
        return fields
    return fields & operational_scope(kind)


def entries_match(kind: str, expected: dict, actual: dict, strict: bool = False) -> bool:
    fields = scored_fields(kind, set(expected) | set(actual), strict)
    return all(values_equal(expected.get(field), actual.get(field)) for field in fields)


def score_kind(class_file: dict, records: list[dict], kind: str, strict: bool = False) -> dict:
    truth = ground_truth_entries(class_file, kind)
    generated = generated_entries(records, kind)
    match = miss = false_claim = wrong_value = 0
    for key, expected_entries in truth.items():
        remaining = list(generated.get(key, []))
        for expected in expected_entries:
            matched = next((candidate for candidate in remaining
                           if entries_match(kind, expected, candidate, strict)), None)
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


def score(class_file: dict, records: list[dict], strict: bool = False) -> dict:
    per_kind = {kind: score_kind(class_file, records, kind, strict) for kind in SCORED_KINDS}
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


def merge_sides(records_a: list[dict], records_b: list[dict], strict: bool = False) -> dict:
    def grouped(records):
        out: dict = {}
        for record in records:
            kind = canonical_kind(record['entry_kind'])
            out.setdefault((kind, key_of(kind, record['entry'])), []).append(record)
        return out

    group_a, group_b = grouped(records_a), grouped(records_b)
    merged, only_a, only_b, conflicts = [], [], [], []
    for group_key in sorted(set(group_a) | set(group_b), key=repr):
        side_a, side_b = group_a.get(group_key, []), group_b.get(group_key, [])
        kind = group_key[0]
        if side_a and side_b:
            remaining_a, remaining_b = list(side_a), list(side_b)
            for record in side_a:
                match = next((candidate for candidate in remaining_b
                             if entries_match(kind, record['entry'], candidate['entry'], strict)), None)
                if match is not None:
                    merged.append(record)
                    remaining_a.remove(record)
                    remaining_b.remove(match)
            while remaining_a and remaining_b:
                conflicts.append({'a': remaining_a.pop(0), 'b': remaining_b.pop(0)})
            only_a.extend(remaining_a)
            only_b.extend(remaining_b)
        elif side_a:
            only_a.extend(side_a)
        else:
            only_b.extend(side_b)
    return {'merged': merged, 'only_a': only_a, 'only_b': only_b, 'conflicts': conflicts}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--records', type=Path, required=True, help='a directory of generated record JSON files')
    parser.add_argument('--records-b', type=Path,
                        help='a second reader-side directory; scores only the records both sides agree on')
    parser.add_argument('--class-file', type=Path, required=True, help='the hand-written classes/<name>.json file')
    parser.add_argument('--strict', action='store_true',
                        help='match on every entry field, including free-text wording, instead of the default '
                             'operational fields only')
    parser.add_argument('--out', type=Path, help='write the score JSON here instead of stdout only')
    args = parser.parse_args(argv)
    class_file = json.loads(args.class_file.read_text(encoding='utf-8'))
    records_a = load_records(args.records)
    merge_info = None
    if args.records_b is not None:
        records_b = load_records(args.records_b)
        merge_info = merge_sides(records_a, records_b, args.strict)
        records = merge_info['merged']
    else:
        records = records_a
    result = score(class_file, records, args.strict)
    if merge_info is not None:
        result['merge'] = {
            'merged': len(merge_info['merged']), 'only_a': len(merge_info['only_a']),
            'only_b': len(merge_info['only_b']), 'conflicts': len(merge_info['conflicts']),
        }
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
