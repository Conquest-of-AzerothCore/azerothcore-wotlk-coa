from pathlib import Path
from typing import Callable, Mapping, Sequence

from coverage import (BEHAVIOUR, CLAIM_WORDS, DATA, DECLARED_CLAIMS, claim_rows, clause_claims, clause_coverage,
                      load_clauses, require_claims, resolved_labels)
from profile import require_server_sha
from prove import RunOutcome


def manifest_labels(manifest: dict) -> dict[str, str]:
    return {expectation['label']: '' for entry in manifest['scenarios']
            for expectation in entry.get('expectations', [])}


def running_labels(labels: list[str], present: dict[str, str]) -> list[str] | None:
    matched = [resolved_labels(label, present) for label in labels]
    if not labels or not all(matched):
        return None
    return [match for matches in matched for match in matches]


def clause_rows(clause: dict, present: dict[str, str]) -> list[dict]:
    if DECLARED_CLAIMS not in clause:
        labels = running_labels(clause.get('labels') or [], present)
        return [] if labels is None else [{**clause, 'labels': labels}]
    claims = [(claim, running_labels(claim['labels'], present)) for claim in clause_claims(clause)]
    if all(labels is not None for _, labels in claims):
        return [{**clause, DECLARED_CLAIMS: [{**claim, 'labels': labels} for claim, labels in claims]}]
    base = {key: value for key, value in clause.items() if key != DECLARED_CLAIMS}
    return [{**base, CLAIM_WORDS: claim[CLAIM_WORDS], 'labels': labels} for claim, labels in claims
            if labels is not None]


def ledger_rows(ledger: Sequence[dict]) -> Callable[[dict], list[dict]]:
    require_claims(list(ledger))

    def rows(manifest: dict) -> list[dict]:
        present = manifest_labels(manifest)
        return [row for clause in ledger if clause.get('kind') == 'claim' for row in clause_rows(clause, present)]
    return rows


def ledger_evidence(rows: list[dict], outcomes: Sequence[RunOutcome]) -> list[dict]:
    results = [clause_coverage(rows, outcome.verdicts, outcome.header.get('build')) for outcome in outcomes]
    sha = [require_server_sha(outcome.header.get('spell_dbc_sha256'), f'verdicts of {outcome.header.get("results")}')
           for outcome in outcomes][0]
    kept = []
    for index, row in enumerate(rows):
        per_run = [result.claim_evidence[index] for result in results]
        statuses = [BEHAVIOUR if {run[claim] for run in per_run} == {BEHAVIOUR} else DATA
                    for claim in range(len(per_run[0]))]
        kept += claim_rows(row, statuses, sha)
    return kept


def coverage_figures(ledger: Sequence[dict], outcome: RunOutcome) -> dict:
    result = clause_coverage(list(ledger), outcome.verdicts, outcome.header.get('build'))
    return {'proven': result.proven, 'behaviour': result.behaviour, 'data': result.data, 'total': result.total,
            'not_measured': len(result.not_measured), 'tool_gaps_accepted': result.accepted_tool_gaps,
            'tool_gaps_pending': result.pending_tool_gaps, 'resolved': result.resolved}


def ledger_coverage(ledger: Sequence[dict]) -> Callable[[Sequence[RunOutcome]], Mapping]:
    def annotate(outcomes: Sequence[RunOutcome]) -> Mapping:
        return {'coverage': [coverage_figures(ledger, outcome) for outcome in outcomes]}
    return annotate


def ledger_hooks(path: Path):
    ledger = load_clauses(path)
    return ledger_rows(ledger), ledger_evidence, ledger_coverage(ledger)
