from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, LEARNED_CONTRAST, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset

KIND = 'pick_effect'
ORDER = 41
PICK_EFFECT_METRIC = 'pick_effect'
CONTROL = 'control'
TREATMENT = 'treatment'
RATIO = 'ratio'
GAIN = 'gain'
READ_METRICS = frozenset({'cast_speed_multiplier', 'attack_time_ms', 'spell_crit_chance', 'melee_crit_chance',
                          'spell_healing_taken', 'melee_damage_taken'})
ATTACKER_METRICS = frozenset({'melee_damage_taken'})
MINIMUM_TRIALS = 20


@dataclass(frozen=True)
class PickRead:
    metric: str
    fields: tuple[tuple[str, object], ...]
    change: str
    expected: float
    tolerance: float


@dataclass(frozen=True)
class Pick:
    aura: int
    label_suffix: str
    quote: str
    reads: tuple[PickRead, ...]


@dataclass(frozen=True)
class PickEffectSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    cast_power: int
    wait_ms: int
    trials: int
    control_trials: int
    picks: tuple[Pick, ...]
    label_suffix: str


def pick_read(raw: dict, where: str) -> PickRead:
    if not isinstance(raw, dict) or set(raw) - {'metric', 'fields', 'ratio', 'gain', 'tolerance'} \
            or raw.get('metric') not in READ_METRICS or ('ratio' in raw) == ('gain' in raw) \
            or not isinstance(raw.get('tolerance'), (int, float)) or raw['tolerance'] <= 0:
        raise ValueError(f'{where} read is {{"metric": one of {sorted(READ_METRICS)}, "fields", "ratio" or "gain", '
                         f'"tolerance" > 0}}, not {raw!r}')
    change = RATIO if 'ratio' in raw else GAIN
    expected = float(raw[change])
    if abs(expected - (1.0 if change == RATIO else 0.0)) <= 2 * raw['tolerance']:
        raise ValueError(f'{where} read {raw["metric"]} states a change within twice its tolerance of no change')
    return PickRead(raw['metric'], tuple(sorted((raw.get('fields') or {}).items())), change, expected,
                    float(raw['tolerance']))


def pick_effect_spec(entry: dict) -> PickEffectSpec:
    where = f'{entry["spell"]} {KIND}'
    picks = []
    for raw in entry.get('picks') or ():
        if not isinstance(raw, dict) or not {'aura', 'label_suffix', 'reads'} <= set(raw) or not raw['reads']:
            raise ValueError(f'{where} pick is {{"aura", "label_suffix", "reads", optional "quote"}}, not {raw!r}')
        picks.append(Pick(int(raw['aura']), str(raw['label_suffix']), raw.get('quote', entry['quote']),
                          tuple(pick_read(read, f'{where} pick {raw["aura"]}') for read in raw['reads'])))
    spec = PickEffectSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['cast_spell']),
                          int(entry['cast_power']), int(entry.get('wait_ms', 0)), int(entry['trials']),
                          int(entry.get('control_trials', 2)), tuple(picks), entry.get('label_suffix', 'pick'))
    if len(spec.picks) < 2 or len({pick.aura for pick in spec.picks}) != len(spec.picks):
        raise ValueError(f'{where} needs two or more distinct pick auras')
    if spec.trials < MINIMUM_TRIALS or spec.control_trials < 1:
        raise ValueError(f'{where} needs at least {MINIMUM_TRIALS} trials and a control trial')
    return spec


def trial_label(spec: PickEffectSpec, phase: str, trial: int, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {phase} {trial} {read}'


def read_key(read: PickRead) -> str:
    return ' '.join([read.metric, *(f'{key} {value}' for key, value in read.fields)])


def read_name(read: PickRead, moment: str) -> str:
    return f'{read_key(read)} {moment}'


def all_reads(spec: PickEffectSpec) -> list[PickRead]:
    return list(dict.fromkeys(read for pick in spec.picks for read in pick.reads))


def read_step(label: str, read: PickRead) -> dict:
    fields = dict(read.fields)
    if read.metric in ATTACKER_METRICS:
        fields.setdefault('target', TARGET)
    return measurement(label, CASTER, read.metric, **fields)


def trial_steps(records: Records, spec: PickEffectSpec, phase: str, trial: int) -> tuple[list[dict], dict]:
    reads = all_reads(spec)
    steps = [{'action': 'set_aura', 'actor': CASTER, 'spell': pick.aura, 'stacks': 0} for pick in spec.picks]
    steps += [read_step(trial_label(spec, phase, trial, read_name(read, 'pre')), read) for read in reads]
    cast = hit_ratio_cast(records, spec.cast_spell, CASTER, CASTER, spec.cast_power)
    if spec.wait_ms:
        cast[-1] = {**cast[-1], 'ms': max(cast[-1]['ms'], spec.wait_ms)}
    steps += cast
    steps += [measurement(trial_label(spec, phase, trial, f'aura {pick.aura}'), CASTER, 'aura', spell=pick.aura)
              for pick in spec.picks]
    steps += [read_step(trial_label(spec, phase, trial, read_name(read, 'post')), read) for read in reads]
    row = {'phase': phase, 'auras': {str(pick.aura): trial_label(spec, phase, trial, f'aura {pick.aura}')
                                     for pick in spec.picks},
           'reads': {read_key(read): [trial_label(spec, phase, trial, read_name(read, 'pre')),
                                           trial_label(spec, phase, trial, read_name(read, 'post'))]
                     for read in reads}}
    return steps, row


def read_model(read: PickRead) -> dict:
    return {'key': read_key(read), 'metric': read.metric, 'change': read.change, 'expected': read.expected,
            'tolerance': read.tolerance}


def pick_effect_scenario(class_file: dict, spec: PickEffectSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    steps = [{**step, 'refresh_stats': True} if step['action'] == 'set_skill' else step
             for step in base_steps(class_file)]
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell})
    rows = []
    for phase, trials in ((CONTROL, spec.control_trials), (TREATMENT, spec.trials)):
        if phase == TREATMENT:
            steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
        for trial in range(1, trials + 1):
            part, row = trial_steps(records, spec, phase, trial)
            steps += part
            rows.append(row)
    auras = ', '.join(str(pick.aura) for pick in spec.picks)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour pick effect',
        'contract': (f'Each trial removes the auras {auras} from the caster, reads the judged states, makes a real '
                     f'cast of {spec.cast_spell} at the caster (mana {spec.cast_power}, cooldown reset), then reads '
                     f'which of the auras the cast left and the same states again. {spec.control_trials} control '
                     f'trial(s) run before {spec.spell} is learned and must leave none of them; each of the '
                     f'{spec.trials} trials after it must leave exactly one. A pick\'s reads must show its stated '
                     f'change in the trials that left it and no change in the others.'),
        'players': [player_fixture(class_file)],
        'steps': steps}
    if any(read.metric in ATTACKER_METRICS for read in all_reads(spec)):
        scenario['creatures'] = [creature_fixture(class_file)]
    expectations = []
    for pick in spec.picks:
        entry = behaviour_entry(records, spec.spell, spec.name, KIND, pick.quote, 1.0)
        model = {'kind': KIND, 'metric': PICK_EFFECT_METRIC, 'contrast': LEARNED_CONTRAST, 'quote': entry.quote,
                 'aura': pick.aura, 'picks': [str(other.aura) for other in spec.picks], 'rows': rows,
                 'reads': [read_model(read) for read in pick.reads]}
        expectations.append(Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {pick.label_suffix}',
                                        BEHAVIOUR_METRIC_DELTA, spec.spell, spec.cast_spell, None, '1',
                                        prose_rule(entry.quote, spec.spell), model))
    return timed(scenario, waited_ms(steps)), expectations


def changed(pre: float, post: float, read: dict) -> float:
    if read['change'] == RATIO:
        return post / pre if pre else float('nan')
    return post - pre


def read_fault(pre: float, post: float, read: dict, picked: bool) -> str | None:
    found = changed(pre, post, read)
    stated = read['expected'] if picked else (1.0 if read['change'] == RATIO else 0.0)
    if abs(found - stated) <= read['tolerance']:
        return None
    return f'{read["key"]} {read["change"]} {found:.6g} (expected {stated:g})'


def pick_effect_verdict(base, run, model: dict):
    aura = str(model['aura'])
    labels = [label for row in model['rows'] for label in (*row['auras'].values(),
                                                           *(item for pair in row['reads'].values() for item in pair))]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=f'no reading for {missing}')
    faults, picked, control, others = [], 0, 0, 0
    for row in model['rows']:
        present = [name for name, label in row['auras'].items() if run.values[label] >= 0.5]
        treatment = row['phase'] == TREATMENT
        if not treatment:
            control += 1
            if present:
                faults.append(f'a control trial left {present}')
        elif len(present) != 1:
            faults.append(f'a trial left {len(present)} of the auras ({present})')
            continue
        chosen = treatment and present == [aura]
        picked += chosen
        others += treatment and not chosen
        for read in model['reads']:
            pre, post = (run.values[label] for label in row['reads'][read['key']])
            fault = read_fault(pre, post, read, chosen)
            if fault is not None:
                faults.append(f'{row["phase"]} trial with {present or "no aura"}: {fault}')
    if not faults and not picked:
        return replace(base, status='unmeasured', explanation=f'no trial picked {aura}; nothing to judge')
    stated = '; '.join(f'{read["key"]} {read["change"]} {read["expected"]:g} within {read["tolerance"]:g}'
                       for read in model['reads'])
    explanation = (f'{control} control trials left no aura; {picked} trials picked {aura} and {others} picked '
                   f'another aura; with {aura}: {stated}, without it no change')
    if faults:
        return replace(base, status='alert', measured=float(picked), expected=1.0,
                       explanation=f'{explanation}: {"; ".join(faults[:5])}')
    return replace(base, status='ok', measured=1.0, expected=1.0, low=1.0, high=1.0,
                   explanation=f'{explanation}: every trial held')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return pick_effect_scenario(class_file, pick_effect_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {pick['label_suffix']}" for pick in entry.get('picks') or ()]


JUDGES = {BEHAVIOUR_METRIC_DELTA: pick_effect_verdict}
METRIC_EVIDENCE = {PICK_EFFECT_METRIC: 'readback'}
CONTRAST_PROOF = {PICK_EFFECT_METRIC: LEARNED_CONTRAST}
STATE_PROMISES = {PICK_EFFECT_METRIC: r'empower\w*'}
