from pathlib import Path
from typing import Callable, Mapping, Sequence

from coverage import BEHAVIOUR, DATA, clause_coverage, fragment_entries, load_clauses, resolved_labels
from prove import RunOutcome


def manifest_labels(manifest: dict) -> dict[str, str]:
    return {expectation['label']: '' for entry in manifest['scenarios']
            for expectation in entry.get('expectations', [])}


def ledger_rows(ledger: Sequence[dict]) -> Callable[[dict], list[dict]]:
    def rows(manifest: dict) -> list[dict]:
        present = manifest_labels(manifest)
        found = []
        for clause in ledger:
            labels = clause.get('labels') or []
            if clause.get('kind') != 'claim' or not labels:
                continue
            matched = [resolved_labels(label, present) for label in labels]
            if all(matched):
                found.append({**clause, 'labels': [match for matches in matched for match in matches]})
        return found
    return rows


def ledger_evidence(rows: list[dict], outcomes: Sequence[RunOutcome]) -> list[dict]:
    per_run = [fragment_entries(clause_coverage(rows, outcome.verdicts, outcome.header.get('build')), outcome.header)
               for outcome in outcomes]
    return [{**per_run[0][index],
             'evidence': BEHAVIOUR if {run[index]['evidence'] for run in per_run} == {BEHAVIOUR} else DATA}
            for index in range(len(rows))]


def coverage_figures(ledger: Sequence[dict], outcome: RunOutcome) -> dict:
    result = clause_coverage(list(ledger), outcome.verdicts, outcome.header.get('build'))
    return {'proven': result.proven, 'behaviour': result.behaviour, 'data': result.data, 'total': result.total,
            'not_measured': len(result.not_measured)}


def ledger_coverage(ledger: Sequence[dict]) -> Callable[[Sequence[RunOutcome]], Mapping]:
    def annotate(outcomes: Sequence[RunOutcome]) -> Mapping:
        return {'coverage': [coverage_figures(ledger, outcome) for outcome in outcomes]}
    return annotate


def ledger_hooks(path: Path):
    ledger = load_clauses(path)
    return ledger_rows(ledger), ledger_evidence, ledger_coverage(ledger)
