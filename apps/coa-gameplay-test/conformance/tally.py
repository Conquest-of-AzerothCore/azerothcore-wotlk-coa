from collections import Counter, defaultdict
from dataclasses import dataclass
import json
from pathlib import Path

from prove import CONFORMANT, NOT_JUDGED, status_class

FINAL = ('1', '2', '3', '4', '5')
RULED = ('2', '3', '4', '5')
RULING_REQUIRED = ('3', '4', '5')
NOT_FINAL = 'not final'
VERDICTS_FILE = 'verdicts.json'


class TallyError(ValueError):
    pass


@dataclass(frozen=True)
class Decisions:
    candidates: dict
    rulings: dict
    counted: frozenset
    text_changed: frozenset


@dataclass(frozen=True)
class TallyInputs:
    ledger: Path
    record_status: Path
    record_compare: tuple
    record_manifest: Path
    compare: tuple
    coverage: tuple
    manifest: Path
    decisions: Decisions


def load(path: Path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def load_decisions(path: Path | None) -> Decisions:
    document = load(path) if path else {}
    unknown = set(document) - {'candidates', 'rulings', 'counted', 'text_changed'}
    if unknown:
        raise TallyError(f'{path}: unknown decision fields {sorted(unknown)}')
    rulings = {}
    for key, ruling in document.get('rulings', {}).items():
        if str(ruling.get('status')) not in RULED:
            raise TallyError(f'{path}: ruling {key} has status {ruling.get("status")!r}, not one of {RULED}; '
                             f'status 1 comes only from a counted pair, through a candidate or the record')
        rulings[key] = (str(ruling['status']), ruling.get('why', ''))
    return Decisions(dict(document.get('candidates', {})), rulings, frozenset(document.get('counted', [])),
                     frozenset(document.get('text_changed', [])))


def parts(row: dict) -> list:
    if 'claims' in row:
        return [(claim['claim'], claim.get('labels', [])) for claim in row['claims']]
    return [(row['clause'], row.get('labels', []))]


def verdict_index(directory: Path) -> dict:
    by_label = defaultdict(dict)
    for verdict in load(Path(directory) / VERDICTS_FILE)['verdicts']:
        by_label[verdict['label']][(verdict['check'], verdict['scenario'])] = verdict['status']
    return by_label


def scenario_shas(manifest: dict) -> dict:
    return {entry['key']: entry.get('sha256') for entry in manifest['scenarios']}


def expectations(manifest: dict) -> dict:
    return {(expectation['label'], scenario['key']): json.dumps(expectation, sort_keys=True)
            for scenario in manifest['scenarios'] for expectation in scenario['expectations']}


def value_link_labels(manifest: dict) -> set:
    return {link['label'] for link in manifest['class_file'].get('value_links', [])}


def judge_changed(record_manifest: dict, manifest: dict) -> set:
    old, now = expectations(record_manifest), expectations(manifest)
    changed = {label for (label, key), text in now.items() if (label, key) in old and old[(label, key)] != text}
    return changed | (value_link_labels(manifest) - value_link_labels(record_manifest))


def judged_classes(statuses) -> set:
    return {status_class(status) for status in statuses if status is not None and status != NOT_JUDGED}


def flips(labels, new_runs, old_runs, old_sha, now_sha, changed) -> tuple:
    inside, against = [], []
    for label in labels:
        keys = set().union(*(run.get(label, {}).keys() for run in new_runs))
        recorded = set().union(*(run.get(label, {}).keys() for run in old_runs))
        for key in sorted(keys | recorded):
            seen = [run.get(label, {}).get(key) for run in new_runs]
            if key in keys and (None in seen or len(judged_classes(seen)) > 1):
                inside.append({'label': label, 'check': key[0], 'scenario': key[1], 'statuses': seen})
            old = [run.get(label, {}).get(key) for run in old_runs]
            if all(status is None for status in old):
                continue
            if old_sha.get(key[1]) is None or old_sha.get(key[1]) != now_sha.get(key[1]) or label in changed:
                continue
            if len(judged_classes(seen + old)) > 1 or (None in old) != (None in seen):
                against.append({'label': label, 'check': key[0], 'scenario': key[1], 'record': old, 'pair': seen})
    return inside, against


def label_statuses(runs, labels) -> dict:
    return {label: [sorted({status for status in run.get(label, {}).values()}) for run in runs] for label in labels}


def labels_pass(runs, labels) -> tuple:
    failing = {label: statuses for label, statuses in label_statuses(runs, labels).items()
               if not all(found and set(found) <= CONFORMANT for found in statuses)}
    return not failing, failing


def classify(rec: dict, prior: dict, new_runs, decisions: Decisions) -> tuple:
    key, behaviour = rec['key'], rec['evidence'] == 'behaviour'
    flip_text = '; '.join(f"{flip['label']} {flip['statuses']}" for flip in rec['flips_in_pair'])
    flip_text += '; '.join(f"{flip['label']} record {flip['record']} pair {flip['pair']}"
                           for flip in rec['flips_vs_record'])
    if key in decisions.rulings:
        status, why = decisions.rulings[key]
        alerts = [label for label, found in label_statuses(new_runs, rec['labels']).items()
                  if any('alert' in statuses for statuses in found)]
        return status, 'ruled', why + (f'; alerting labels kept as evidence: {alerts}' if alerts else '')
    if rec['flips_in_pair'] or rec['flips_vs_record']:
        return NOT_FINAL, 'flip', flip_text
    if key in decisions.candidates:
        passing, failing = labels_pass(new_runs, rec['labels'])
        if behaviour and passing:
            return '1', 'candidate', (decisions.candidates[key]
                                      + '; behaviour both runs, every label conformant, no flip')
        return NOT_FINAL, 'candidate', (decisions.candidates[key] + f"; this pair {rec['run1']}/{rec['run2']}; "
                                        f'labels not passing {failing}')
    if key in decisions.counted and behaviour:
        return '1', 'counted', 'ledger-only re-audit correction on the count-of-record pair, behaviour both runs'
    status = prior['status']
    if status == '1':
        if behaviour:
            return '1', 'kept', prior.get('detail') or ''
        return NOT_FINAL, 'lost', f"status 1 in the record; this pair {rec['run1']}/{rec['run2']}"
    if status == '2':
        if behaviour or rec['evidence'] == prior['evidence']:
            return '2', 'kept', prior.get('detail') or ''
        return NOT_FINAL, 'lost', (f"status 2 in the record ({prior['evidence']}); this pair "
                                   f"{rec['run1']}/{rec['run2']}")
    return NOT_FINAL, 'carried', prior.get('detail') or ''


def record_rows(path: Path) -> dict:
    return {(row['index'], row['part']): row for row in load(path)}


def new_prior(index: int, part: int, row: dict, text: str) -> dict:
    return {'key': f'new {index}.{part}', 'status': NOT_FINAL, 'evidence': 'new', 'claim': text,
            'spell': row['spell'], 'detail': 'new claim'}


def ledger_keys(rows: list, record: dict) -> dict:
    return {(index, part): record[(index, part)]['key'] if (index, part) in record else f'new {index}.{part}'
            for index, row in enumerate(rows) for part in range(len(parts(row)))}


def check_decisions(keys: dict, record: dict, decisions: Decisions) -> None:
    unknown = (set(decisions.candidates) | set(decisions.rulings) | decisions.counted
               | decisions.text_changed) - set(keys.values())
    if unknown:
        raise TallyError(f'decision keys that name no claim of this ledger: {sorted(unknown)}')
    unruled = [record[place]['key'] for place in keys if place in record
               and record[place]['status'] in RULING_REQUIRED and record[place]['key'] not in decisions.rulings
               and record[place]['key'] not in decisions.candidates]
    if unruled:
        raise TallyError(f'recorded status 3-5 claims without a ruling in the decisions file: {unruled}')


def missing_rows(keys: dict, record: dict) -> list:
    return [{'key': row['key'], 'index': row['index'], 'part': row['part'], 'record_status': row['status'],
             'basis': 'missing', 'detail': f"record row {row['index']}.{row['part']} reached by no ledger claim"}
            for place, row in sorted(record.items()) if place not in keys]


def tally(inputs: TallyInputs) -> dict:
    decisions = inputs.decisions
    rows = [row for row in load(inputs.ledger) if row['kind'] == 'claim']
    record = record_rows(inputs.record_status)
    keys = ledger_keys(rows, record)
    check_decisions(keys, record, decisions)
    audits = [load(path) for path in inputs.coverage]
    new_runs = [verdict_index(path) for path in inputs.compare]
    old_runs = [verdict_index(path) for path in inputs.record_compare]
    record_manifest, manifest = load(inputs.record_manifest), load(inputs.manifest)
    old_sha, now_sha = scenario_shas(record_manifest), scenario_shas(manifest)
    changed = judge_changed(record_manifest, manifest)
    for path, audit in zip(inputs.coverage, audits):
        if len(audit['clauses']) != len(rows):
            raise TallyError(f'{path}: {len(audit["clauses"])} audit rows for {len(rows)} ledger claims')
    out = []
    for index, row in enumerate(rows):
        for part, (text, labels) in enumerate(parts(row)):
            prior = record.get((index, part)) or new_prior(index, part, row, text)
            if (index, part) in record:
                if prior['spell'] != row['spell']:
                    raise TallyError(f'claim {index}.{part}: spell {row["spell"]} in the ledger, '
                                     f'{prior["spell"]} in the record')
                if prior['claim'] != text and prior['key'] not in decisions.text_changed:
                    raise TallyError(f'claim {prior["key"]}: the ledger text differs from the record; list the '
                                     f'key under text_changed when the change is intended')
            runs = [audit['clauses'][index]['claim_evidence'][part] for audit in audits]
            inside, against = flips(labels, new_runs, old_runs, old_sha, now_sha, changed)
            rec = {'key': prior['key'], 'index': index, 'part': part, 'spell': row['spell'], 'claim': text,
                   'labels': labels, 'evidence': runs[0] if runs[0] == runs[1] else 'flip', 'run1': runs[0],
                   'run2': runs[1], 'record_status': prior['status'], 'record_evidence': prior['evidence'],
                   'flips_in_pair': inside, 'flips_vs_record': against}
            status, basis, detail = classify(rec, prior, new_runs, decisions)
            rec.update({'status': status, 'basis': basis, 'detail': detail})
            out.append(rec)
    return summary(out, changed, decisions, missing_rows(keys, record), record)


def summary(out: list, changed: set, decisions: Decisions, missing: list, record: dict) -> dict:
    counts = Counter(row['status'] for row in out)
    return {
        'rows': out,
        'judge_changed': sorted(changed),
        'missing': missing,
        'total': len(out),
        'counts': {status: counts[status] for status in (*FINAL, NOT_FINAL) if counts[status]},
        'record_final': sum(1 for row in record.values() if row['status'] in FINAL),
        'final': sum(counts[status] for status in FINAL),
        'lost': [row for row in out if row['record_status'] in FINAL and row['status'] not in FINAL]
        + [row for row in missing if row['record_status'] in FINAL],
        'gained': [row for row in out if row['record_status'] not in FINAL and row['status'] in FINAL],
        'candidates_not_final': [row for row in out if row['key'] in decisions.candidates
                                 and row['status'] not in FINAL],
        'flips_in_pair': [row['key'] for row in out if row['flips_in_pair']],
        'flips_vs_record': [row['key'] for row in out if row['flips_vs_record']],
    }


def tally_lines(result: dict) -> list:
    lines = [f"judge changed since the record (no like-for-like record comparison): {result['judge_changed']}",
             f"{result['total']} {result['counts']} record {result['record_final']} final {result['final']}"]
    lines += [f"LOST {row['key']} {row['basis']} {str(row['detail'])[:200]}" for row in result['lost']]
    lines += [f"GAIN {row['key']} {row['status']} {row['basis']} {str(row['detail'])[:120]}"
              for row in result['gained']]
    lines += [f"CAND-NF {row['key']} {row['run1']} {row['run2']} {str(row['detail'])[:300]}"
              for row in result['candidates_not_final']]
    lines += [f"FLIP {key}" for key in result['flips_in_pair']]
    lines += [f"FLIP-RECORD {key}" for key in result['flips_vs_record']]
    return lines


def status_markdown(result: dict, title: str) -> str:
    total = result['total']
    share = f"{100.0 * result['final'] / total:.1f}%" if total else 'n/a'
    lines = [f'# {title}', '', f"Final: **{result['final']} / {total} = {share}**; record {result['record_final']}.",
             '', '| Status | Claims |', '|---|---:|']
    lines += [f'| {status} | {count} |' for status, count in result['counts'].items()]
    lines += ['', f"Flips in the pair: {len(result['flips_in_pair'])}; against the record: "
                  f"{len(result['flips_vs_record'])}.", '']
    for heading, rows in (('Lost', result['lost']), ('Gained', result['gained'])):
        lines.append(f'{heading}: ' + (', '.join(row['key'] for row in rows) or 'none') + '.')
    lines += ['', '| Key | Spell | Status | Basis | Evidence | Record |', '|---|---:|---|---|---|---|']
    lines += [f"| {row['key']} | {row['spell']} | {row['status']} | {row['basis']} | {row['evidence']} | "
              f"{row['record_status']} |" for row in result['rows']]
    return '\n'.join(lines) + '\n'


def write_status(result: dict, json_path: Path, markdown_path: Path, title: str) -> None:
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(result['rows'], indent=1) + '\n', encoding='utf-8')
    markdown_path.write_text(status_markdown(result, title), encoding='utf-8')
