from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path
import sys
from typing import Sequence

from compare import Verdict
from profile import CASTER
from prove import judged, status_class

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

MUTANT_ACTION = 'spell_mod_mutant'
ACTIVE_METRIC = 'spell_mod_mutants'
ACTIVE_LABEL = 'spell modifier mutants still active'
DOUBLE = 2.0
ZERO = 0.0
MUTANT_FACTORS = (DOUBLE, ZERO)
SPELL_MOD_OPS = {'duration': 1, 'effect1': 3, 'radius': 6, 'all_effects': 8, 'cooldown': 11, 'effect2': 12,
                 'jump_targets': 17, 'chance_of_success': 18, 'effect3': 23, 'value_multiplier': 27}
MUTANT_FIELDS = frozenset({'label', 'spell', 'op', 'factor'})
SETTLE_LABEL = 'settle'
MANIFEST_KEY = 'mutants'


class MutantError(ValueError):
    pass


@dataclass(frozen=True)
class Mutant:
    label: str
    spell: int
    op: str
    factor: float

    @property
    def percent(self) -> int:
        return round((self.factor - 1.0) * 100)

    def step(self) -> dict:
        return {'action': MUTANT_ACTION, 'actor': CASTER, 'spell': self.spell, 'op': SPELL_MOD_OPS[self.op],
                'percent': self.percent}


def load_mutants(path: Path) -> list[Mutant]:
    document = json.loads(Path(path).read_text(encoding='utf-8'))
    if not isinstance(document, list) or not document:
        raise MutantError(f'{path} is not a non-empty JSON array of server mutants')
    mutants = []
    for index, item in enumerate(document):
        where = f'{path}[{index}]'
        if not isinstance(item, dict) or set(item) != MUTANT_FIELDS:
            raise MutantError(f'{where}: a mutant has exactly the fields {sorted(MUTANT_FIELDS)}')
        if not isinstance(item['label'], str) or not item['label']:
            raise MutantError(f'{where}: label is the verdict label of the mutated scenarios')
        if not isinstance(item['spell'], int) or isinstance(item['spell'], bool) or item['spell'] < 1:
            raise MutantError(f'{where}: spell is a positive spell id')
        if item['op'] not in SPELL_MOD_OPS:
            raise MutantError(f'{where}: op must be one of {sorted(SPELL_MOD_OPS)}')
        if isinstance(item['factor'], bool) or item['factor'] not in MUTANT_FACTORS:
            raise MutantError(f'{where}: factor must be one of {MUTANT_FACTORS} (a consumption probe asks whether the '
                              f'value is read, so the change must lie far outside every tolerance)')
        mutants.append(Mutant(item['label'], item['spell'], item['op'], float(item['factor'])))
    keys = [(mutant.label, mutant.spell, mutant.op) for mutant in mutants]
    if len(set(keys)) != len(keys):
        raise MutantError(f'{path} names the same label, spell and op twice')
    return mutants


def expectation_labels(entry: dict) -> set[str]:
    return {expectation['label'] for expectation in entry['expectations']}


def active_check(count: int) -> dict:
    return {'action': 'assert', 'label': ACTIVE_LABEL, 'actor': CASTER, 'metric': ACTIVE_METRIC, 'equals': count}


def mutated_steps(steps: list[dict], mutants: Sequence[Mutant], key: str) -> list[dict]:
    if not steps or steps[0].get('action') != 'wait' or steps[0].get('label') != SETTLE_LABEL:
        raise MutantError(f'{key}: the scenario does not start with the {SETTLE_LABEL!r} wait, so no step can come '
                          f'before its arms')
    return [steps[0], *(mutant.step() for mutant in mutants), *steps[1:], active_check(len(mutants))]


def mutate(manifest_path: Path, mutants: Sequence[Mutant]) -> Path:
    manifest_path = Path(manifest_path)
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    if MANIFEST_KEY in manifest:
        raise MutantError(f'{manifest_path} is already mutated')
    applied = {mutant: [] for mutant in mutants}
    for entry in manifest['scenarios']:
        chosen = [mutant for mutant in mutants if mutant.label in expectation_labels(entry)]
        if not chosen or not entry['file']:
            continue
        path = manifest_path.parent / entry['file']
        scenario = json.loads(path.read_text(encoding='utf-8'))
        scenario['steps'] = mutated_steps(scenario['steps'], chosen, entry['key'])
        text = json.dumps(run.validate(scenario), indent=2) + '\n'
        path.write_text(text, encoding='utf-8')
        entry['sha256'] = hashlib.sha256(text.encode('utf-8')).hexdigest()
        for mutant in chosen:
            applied[mutant].append(entry['key'])
    unused = [mutant.label for mutant, keys in applied.items() if not keys]
    if unused:
        raise MutantError(f'no generated scenario carries the mutant labels {unused}')
    manifest[MANIFEST_KEY] = [{**asdict(mutant), 'percent': mutant.percent, 'op_id': SPELL_MOD_OPS[mutant.op],
                               'scenarios': keys} for mutant, keys in applied.items()]
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    return manifest_path


def mutated_scenarios(manifest: dict) -> set[str]:
    return {key for mutant in manifest.get(MANIFEST_KEY, []) for key in mutant['scenarios']}


def scenario_statuses(runs: Sequence[Sequence[Verdict]], mutated: set[str]) -> dict[tuple[str, str, str], list]:
    keys = sorted({(verdict.label, verdict.check, verdict.scenario) for verdicts in runs for verdict in verdicts
                   if verdict.scenario not in mutated})
    found = [{(verdict.label, verdict.check, verdict.scenario): verdict.status for verdict in verdicts}
             for verdicts in runs]
    return {key: [statuses.get(key) for statuses in found] for key in keys}


def classes_of(statuses: Sequence[str | None]) -> set[str | None]:
    return {None if status is None else status_class(status) for status in statuses
            if status is None or judged(status)}


def contamination(baseline: Sequence[Sequence[Verdict]], mutant: Sequence[Sequence[Verdict]],
                  mutated: set[str]) -> list[dict]:
    before = scenario_statuses(baseline, mutated)
    after = scenario_statuses(mutant, mutated)
    changed = []
    for key in sorted(set(before) | set(after)):
        seen_before = before.get(key, [None] * len(baseline))
        seen_after = after.get(key, [None] * len(mutant))
        if len(classes_of([*seen_before, *seen_after])) > 1:
            changed.append({'label': key[0], 'check': key[1], 'scenario': key[2], 'baseline': seen_before,
                            'mutant': seen_after})
    return changed
