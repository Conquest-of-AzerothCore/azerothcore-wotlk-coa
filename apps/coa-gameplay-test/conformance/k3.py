from dataclasses import dataclass
import json
from pathlib import Path
import re
from typing import Sequence

from compare import CONFORMANT, Verdict, banded_status, read_verdicts
from coverage import CONSUMED, CONSUMPTION_FIELDS, K3, NOT_CONSUMED, acting, consumption_row, load_consumption
from mutants import Mutant

PROBE_FIELDS = frozenset({'label', 'spell', 'effect', 'observation'})
OPTIONAL_PROBE_FIELDS = frozenset({'mutant', 'predicted'})
ALERT = 'alert'
RUN_PREFIX = 'run'
MIN_RUNS = 2
COA_SOURCE = Path(__file__).resolve().parents[3] / 'src' / 'server' / 'coa'
SOURCE_SUFFIXES = ('.cpp', '.h')


class ProbeError(ValueError):
    pass


@dataclass(frozen=True)
class Probe:
    label: str
    spell: int
    effect: int
    observation: str
    mutant: str
    predicted: float | None = None


def load_probes(path: Path) -> list[Probe]:
    document = json.loads(Path(path).read_text(encoding='utf-8'))
    if not isinstance(document, list) or not document:
        raise ProbeError(f'{path} is not a non-empty JSON array of K3 probes')
    probes = []
    for index, item in enumerate(document):
        where = f'{path}[{index}]'
        if not isinstance(item, dict) or not PROBE_FIELDS <= set(item) <= PROBE_FIELDS | OPTIONAL_PROBE_FIELDS:
            raise ProbeError(f'{where}: a probe has the fields {sorted(PROBE_FIELDS)} and optionally '
                             f'{sorted(OPTIONAL_PROBE_FIELDS)}')
        if not all(isinstance(item[name], str) and item[name] for name in ('label', 'observation')):
            raise ProbeError(f'{where}: label and observation are non-empty strings')
        if not all(isinstance(item[name], int) and not isinstance(item[name], bool) and item[name] >= 0
                   for name in ('spell', 'effect')):
            raise ProbeError(f'{where}: spell and effect are non-negative integers')
        mutant = item.get('mutant', item['observation'])
        if not isinstance(mutant, str) or not mutant:
            raise ProbeError(f'{where}: mutant is a non-empty string')
        predicted = item.get('predicted')
        if predicted is not None and (isinstance(predicted, bool) or not isinstance(predicted, (int, float))):
            raise ProbeError(f'{where}: predicted is the number the observation reads under the mutant')
        probes.append(Probe(item['label'], item['spell'], item['effect'], item['observation'], mutant,
                            None if predicted is None else float(predicted)))
    labels = [probe.label for probe in probes]
    if len(set(labels)) != len(labels):
        raise ProbeError(f'{path} probes the same label twice')
    return probes


def by_label(verdicts: Sequence[Verdict]) -> dict[str, Verdict]:
    return {verdict.label: verdict for verdict in verdicts}


def baseline_reason(label: str, runs: Sequence[dict[str, Verdict]]) -> str | None:
    for number, verdicts in enumerate(runs, start=1):
        verdict = verdicts.get(label)
        if verdict is None:
            return f'baseline run {number} has no verdict for {label}'
        if verdict.status not in CONFORMANT:
            return f'baseline run {number} is {verdict.status} for {label}'
        if not acting(verdict):
            return (f'baseline run {number} reads {label} with check {verdict.check}, which observes no acting '
                    f'outcome, so its movement cannot show consumption')
    return None


def literal_modifier_sites(spell: int, root: Path = COA_SOURCE) -> list[str]:
    pattern = re.compile(rf'ApplySpellMod\(\s*{spell}\b')
    sites = []
    for path in sorted(Path(root).rglob('*')):
        if path.suffix not in SOURCE_SUFFIXES or path.name.startswith('CoAGameplayTest'):
            continue
        for number, line in enumerate(path.read_text(encoding='utf-8', errors='replace').splitlines(), start=1):
            if pattern.search(line):
                sites.append(f'{path.name}:{number}')
    return sites


def separation_reason(probe: Probe, expected: float | None) -> str | None:
    if probe.predicted is None:
        return 'the probe states no predicted reading, so a conformant mutant cannot show the value unconsumed'
    if expected is None:
        return 'the baseline verdict has no expected value to separate the predicted reading from'
    if banded_status(probe.predicted, expected, expected, expected) != ALERT:
        return (f'the predicted mutant reading {probe.predicted:g} lies within the tolerance of the expected '
                f'{expected:g}, so a conformant mutant cannot show the value unconsumed')
    return None


def mutant_result(label: str, runs: Sequence[dict[str, Verdict]], probe: Probe,
                  expected: float | None) -> tuple[str | None, str]:
    seen = [verdicts[label].status if label in verdicts else None for verdicts in runs]
    if all(status == ALERT for status in seen):
        unmeasured = [number for number, verdicts in enumerate(runs, start=1) if verdicts[label].measured is None]
        if unmeasured:
            return None, (f'the mutant reading alerts without a measured value in runs {unmeasured} (a missing '
                          f'reading, not a moved one), so the alert shows nothing about consumption')
        return CONSUMED, f'the mutant reading alerts in every run: {seen}'
    if all(status in CONFORMANT for status in seen):
        reason = separation_reason(probe, expected)
        if reason:
            return None, f'the mutant reading stays conformant in every run ({seen}), but {reason}'
        return NOT_CONSUMED, f'the mutant reading stays conformant in every run: {seen}'
    return None, f'the mutant statuses {seen} are neither alerts in every run nor conformant in every run'


def shared_build(baseline: Sequence[dict], mutant: Sequence[dict]) -> str:
    builds = {header.get('build') for header in (*baseline, *mutant)}
    if len(builds) != 1 or None in builds:
        raise ProbeError(f'baseline and mutant runs must share one worldserver build, found {sorted(map(str, builds))}')
    return builds.pop()


def mutated_spell(probe: Probe, mutants: Sequence[Mutant]) -> int | None:
    spells = {mutant.spell for mutant in mutants if mutant.label == probe.mutant}
    return spells.pop() if len(spells) == 1 else None


def k3_rows(probes: Sequence[Probe], mutants: Sequence[Mutant], baseline: Sequence[tuple[dict, list[Verdict]]],
            mutant: Sequence[tuple[dict, list[Verdict]]], evidence: str,
            root: Path = COA_SOURCE) -> tuple[list[dict], list[dict]]:
    if len(baseline) < MIN_RUNS or len(mutant) < MIN_RUNS:
        raise ProbeError(f'K3 needs at least {MIN_RUNS} baseline and {MIN_RUNS} mutant runs')
    build = shared_build([header for header, _ in baseline], [header for header, _ in mutant])
    before = [by_label(verdicts) for _, verdicts in baseline]
    after = [by_label(verdicts) for _, verdicts in mutant]
    rows, outcomes = [], []
    for probe in probes:
        spell = mutated_spell(probe, mutants)
        sites = literal_modifier_sites(spell, root) if spell is not None else []
        reason = baseline_reason(probe.observation, before)
        if spell is None:
            reason = f'no single mutant carries the label {probe.mutant}'
        elif sites:
            reason = (f'CoA code passes its own amount through the modifier channel of {spell} ({", ".join(sites)}), '
                      f'so a spell modifier mutant moves the reading whether or not the DBC value is read')
        expected = None if reason else before[0][probe.observation].expected
        result, why = (None, reason) if reason else mutant_result(probe.mutant, after, probe, expected)
        outcomes.append({'label': probe.label, 'observation': probe.observation, 'mutant': probe.mutant,
                         'mutated_spell': spell, 'predicted': probe.predicted, 'expected': expected,
                         'measured': [verdicts[probe.mutant].measured if probe.mutant in verdicts else None
                                      for verdicts in after],
                         'result': result, 'reason': why})
        if result is not None:
            row = {'label': probe.label, 'route': K3, 'spell': probe.spell, 'effect': probe.effect, 'build': build,
                   'evidence': evidence, 'result': result}
            consumption_row(row, probe.label)
            rows.append(row)
    return rows, outcomes


def compare_runs(directory: Path) -> list[tuple[dict, list[Verdict]]]:
    runs = sorted(Path(directory).glob(f'{RUN_PREFIX}[0-9]*'), key=lambda path: int(path.name[len(RUN_PREFIX):]))
    if len(runs) < MIN_RUNS:
        raise ProbeError(f'{directory} holds {len(runs)} compare outputs run<N>; K3 needs {MIN_RUNS}')
    return [read_verdicts(run) for run in runs]


def merge_consumption(path: Path, rows: Sequence[dict]) -> Path:
    path = Path(path)
    replaced = {(row['label'], row['build']) for row in rows}
    kept = [{name: getattr(row, name) for name in CONSUMPTION_FIELDS} for row in load_consumption(path)
            if (row.label, row.build) not in replaced]
    document = sorted([*kept, *rows], key=lambda row: (row['label'], row['build']))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps([dict(sorted(row.items())) for row in document], indent=2) + '\n', encoding='utf-8')
    return path
