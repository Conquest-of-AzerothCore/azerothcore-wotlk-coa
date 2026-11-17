from dataclasses import replace
import json
from pathlib import Path

from compare import CONFORMANT, DATA_ONLY, NOT_MEASURED, Verdict, observed, read_verdicts
from coverage import (BY_METRIC, EVIDENCE, ClauseCoverage, clause_coverage, clause_labels, load_clauses,
                      load_consumption, resolved_labels)
from values import Expectation

ALERT = 'alert'
CONFORMANT_CLASS = 'conformant'
EXPLANATION_LIMIT = 300


def status_class(verdict: Verdict) -> tuple[str, bool]:
    return (CONFORMANT_CLASS if verdict.status in CONFORMANT else verdict.status,
            bool((verdict.detail or {}).get(DATA_ONLY)))


def manifest_stamps(manifest: dict) -> dict[str, dict]:
    found = {}
    for entry in manifest['scenarios']:
        for data in entry['expectations']:
            stamp = observed(Expectation(**data))
            if stamp:
                found.setdefault(data['label'], []).append(stamp)
    return {label: stamps[0] for label, stamps in found.items() if all(stamp == stamps[0] for stamp in stamps)}


def stamped(verdict: Verdict, stamps: dict[str, dict]) -> Verdict:
    if EVIDENCE.get(verdict.check) != BY_METRIC or (verdict.detail or {}).get('metric'):
        return verdict
    stamp = stamps.get(verdict.label)
    return replace(verdict, detail={**(verdict.detail or {}), **stamp}) if stamp else verdict


def hooked_labels(document) -> set[str]:
    if isinstance(document, dict):
        document = document.get('labels', [])
    return {label for item in document for label in (item['labels'] if isinstance(item, dict) else [item])}


def merged_verdicts(runs: list[list[Verdict]]) -> list[Verdict]:
    order, latest = [], {}
    for run in runs:
        for verdict in run:
            if verdict.label not in latest:
                order.append(verdict.label)
            latest[verdict.label] = verdict
    return [latest[label] for label in order]


def disagreements(runs: list[tuple[str, list[Verdict]]]) -> list[dict]:
    seen = {}
    for name, verdicts in runs:
        for verdict in verdicts:
            seen.setdefault(verdict.label, []).append((name, verdict))
    rows = []
    for label, found in sorted(seen.items()):
        classes = {status_class(verdict) for _, verdict in found}
        if len(classes) > 1:
            rows.append({'label': label, 'runs': [{'results': name, 'status': verdict.status,
                                                   DATA_ONLY: status_class(verdict)[1]} for name, verdict in found]})
    return rows


def single_build(verdicts: list[Verdict]) -> str | None:
    builds = {verdict.build for verdict in verdicts}
    return builds.pop() if len(builds) == 1 else None


def figures(result: ClauseCoverage) -> dict:
    return {'claims': result.total, 'behaviour': result.behaviour, 'data': result.data,
            'unproven': result.total - result.proven, 'resolved': result.resolved,
            'not_measured': len(result.not_measured), 'tool_gaps_pending': result.pending_tool_gaps}


def clause_rows(result: ClauseCoverage, verdicts: list[Verdict]) -> list[dict]:
    statuses = {verdict.label: verdict.status for verdict in verdicts}
    by_label = {verdict.label: verdict for verdict in verdicts}
    rows = []
    for index, ((clause, status), per_claim) in enumerate(zip(result.evidence, result.claim_evidence)):
        labels = clause_labels(clause)
        matched = {label: resolved_labels(label, statuses) for label in labels}
        alerts = sorted({match for found in matched.values() for match in found if statuses[match] == ALERT})
        rows.append({'index': index, 'spell': clause['spell'], 'clause': clause['clause'], 'evidence': status,
                     'claim_evidence': per_claim, 'labels': labels,
                     'missing_labels': sorted(label for label, found in matched.items() if not found),
                     'label_statuses': {match: statuses[match] for found in matched.values() for match in found},
                     'alert_labels': alerts,
                     'alert_explanations': {label: by_label[label].explanation[:EXPLANATION_LIMIT]
                                            for label in alerts}})
    return rows


def audit_document(class_id: int, ledger: Path, results: list[Path], base_results: Path | None = None,
                   manifest: Path | None = None, hooked: Path | None = None, build: str | None = None,
                   consumption: Path | None = None) -> dict:
    stamps = manifest_stamps(json.loads(Path(manifest).read_text(encoding='utf-8'))) if manifest else {}
    forced = hooked_labels(json.loads(Path(hooked).read_text(encoding='utf-8'))) if hooked else set()

    def prepared(directory: Path) -> list[Verdict]:
        verdicts = [stamped(verdict, stamps) for verdict in read_verdicts(directory)[1]]
        verdicts = [replace(verdict, status=NOT_MEASURED) if verdict.label in forced else verdict
                    for verdict in verdicts]
        return [replace(verdict, build=build) for verdict in verdicts] if build else verdicts

    base = prepared(base_results) if base_results else []
    runs = [(str(directory), prepared(directory)) for directory in results]
    verdicts = merged_verdicts([base] + [run for _, run in runs])
    clauses = load_clauses(ledger)
    rows = load_consumption(consumption) if consumption else ()
    result = clause_coverage(clauses, verdicts, build or single_build(verdicts), rows)
    base_labels = {verdict.label for verdict in base}
    latest = {verdict.label for _, run in runs for verdict in run}
    return {'class_id': class_id,
            'inputs': {'ledger': str(ledger), 'results': [name for name, _ in runs],
                       'base_results': str(base_results) if base_results else None,
                       'manifest': str(manifest) if manifest else None, 'hooked': str(hooked) if hooked else None,
                       'consumption': str(consumption) if consumption else None, 'build': build,
                       'result_builds': sorted({str(verdict.build) for _, run in runs for verdict in run})},
            'results_replaced': sorted(latest & base_labels), 'results_added': sorted(latest - base_labels),
            'results_disagree': disagreements(runs), 'figures': figures(result),
            'no_claim_entries': sum(entry.get('kind') == 'no_claim' for entry in clauses),
            'clauses': clause_rows(result, verdicts),
            'statuses': {verdict.label: verdict.status for verdict in verdicts}}
