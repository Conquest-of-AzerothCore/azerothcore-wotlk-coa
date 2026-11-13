from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from bonus import bonus_detail, bonus_of, bonus_status, bonus_text, per_event_sample
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset

KIND = 'minion_swing_arms'
ORDER = 33

MINION_SWING_ARMS_METRIC = 'minion_swing_arm_damage'
MINION_SWING_ARMS_RAISE_WAIT_MS = 3100
MINION_SWING_ARMS_MINIMUM_WINDOWS = 4
ARMS = ('control', 'treatment')
AURA_HOLDERS = ('owner', 'dummy')


@dataclass(frozen=True)
class MinionSwingArmsSpec:
    spell: int
    name: str
    quote: str
    raise_spell: int
    command_spell: int
    minion_entry: int
    aura: int
    aura_effect: int
    stacks: int
    holder: str
    expected: float
    windows: int
    window_ms: int
    settle_ms: int = 1000
    command_power: int | None = None
    player_spell_power: int | None = None
    learn: tuple[int, ...] = ()
    label_suffix: str = 'swing_arms'


def minion_swing_arms_spec(entry: dict) -> MinionSwingArmsSpec:
    spec = MinionSwingArmsSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['raise_spell']),
                               int(entry['command_spell']), int(entry['minion_entry']), int(entry['aura']),
                               int(entry.get('aura_effect', 0)), int(entry['stacks']), entry['holder'],
                               float(entry['expected']), int(entry['windows']), int(entry['window_ms']),
                               int(entry.get('settle_ms', 1000)), entry.get('command_power'),
                               entry.get('player_spell_power'), tuple(int(spell) for spell in entry.get('learn', [])),
                               entry.get('label_suffix', 'swing_arms'))
    if spec.holder not in AURA_HOLDERS:
        raise ValueError(f'{spec.spell} minion_swing_arms holds its aura on one of {AURA_HOLDERS}')
    if spec.stacks < 1:
        raise ValueError(f'{spec.spell} minion_swing_arms needs a treatment arm that carries the aura: without it '
                         f'the arms do not differ and there is no contrast')
    if spec.windows < MINION_SWING_ARMS_MINIMUM_WINDOWS or spec.window_ms <= 0 or spec.settle_ms < 0:
        raise ValueError(f'{spec.spell} minion_swing_arms needs at least {MINION_SWING_ARMS_MINIMUM_WINDOWS} windows '
                         f'per arm and a positive window')
    return spec


def stated_bonus(records: Records, spec: MinionSwingArmsSpec) -> float:
    effect = spec.aura_effect
    amount = (int(records.field('Spell', spec.aura, f'EffectBasePoints[{effect}]'))
              + int(records.field('Spell', spec.aura, f'EffectDieSides[{effect}]')))
    return float(amount * spec.stacks)


def arms_label(spec: MinionSwingArmsSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}'


def window_labels(spec: MinionSwingArmsSpec, arm: str, window: int) -> dict[str, str]:
    base = f'{arms_label(spec)} {arm} {window}'
    return {'start total': f'{base} start total', 'start count': f'{base} start count',
            'end total': f'{base} end total', 'end count': f'{base} end count', 'aura': f'{base} aura'}


def aura_steps(spec: MinionSwingArmsSpec, stacks: int) -> list[dict]:
    step = {'action': 'set_aura', 'actor': CASTER, 'spell': spec.aura, 'stacks': stacks}
    if spec.holder == 'dummy':
        step.update(target=TARGET, caster=CASTER)
    return [step]


def aura_read(spec: MinionSwingArmsSpec, label: str) -> dict:
    if spec.holder == 'dummy':
        return measurement(label, TARGET, 'aura_stacks', spell=spec.aura, caster=CASTER)
    return measurement(label, CASTER, 'owned_creature_count', entry=spec.minion_entry, spell=spec.aura)


def minion_swing_arms_scenario(class_file: dict, spec: MinionSwingArmsSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    expected = stated_bonus(records, spec)
    if abs(expected - spec.expected) > 1e-9:
        raise ValueError(f'{spec.spell} minion_swing_arms states {spec.expected:g}% but {spec.stacks} stacks of '
                         f'{spec.aura} effect {spec.aura_effect} give {expected:g}% in the DBC')
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, expected)

    def swing_reads(labels: dict[str, str], moment: str) -> list[dict]:
        return [measurement(labels[f'{moment} total'], CASTER, 'pet_melee_plain_damage', entry=spec.minion_entry),
                measurement(labels[f'{moment} count'], CASTER, 'pet_melee_plain_count', entry=spec.minion_entry)]

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((*spec.learn, spec.raise_spell, spec.command_spell))]
             + hit_ratio_cast(records, spec.raise_spell, CASTER, CASTER)
             + [{'action': 'wait', 'label': 'raise', 'ms': MINION_SWING_ARMS_RAISE_WAIT_MS},
                {'action': 'assert', 'label': f'SETUP: the {spec.minion_entry} minion is raised', 'actor': CASTER,
                 'metric': 'owned_creature_count', 'entry': spec.minion_entry, 'equals': 1}]
             + hit_ratio_cast(records, spec.command_spell, CASTER, TARGET, spec.command_power))
    windows = {arm: [] for arm in ARMS}
    for window in range(spec.windows):
        for arm in ARMS:
            labels = window_labels(spec, arm, window)
            steps += aura_steps(spec, 0)
            if arm == 'treatment':
                steps += aura_steps(spec, spec.stacks)
            steps += ([{'action': 'wait', 'label': f'{arm} settle', 'ms': spec.settle_ms}]
                      + swing_reads(labels, 'start')
                      + [{'action': 'wait', 'label': f'{arm} swings', 'ms': spec.window_ms}]
                      + swing_reads(labels, 'end') + [aura_read(spec, labels['aura'])])
            windows[arm].append(labels)
    steps += aura_steps(spec, 0)
    holder = 'the dummy (cast by the caster)' if spec.holder == 'dummy' else 'the caster, which gives it to its minions'
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour minion swing arms',
        'contract': (f'A real {spec.raise_spell} raises creature {spec.minion_entry}; one {spec.command_spell} sends '
                     f'it onto the dummy. Then {spec.windows} control and {spec.windows} treatment windows alternate: '
                     f'aura {spec.aura} is removed, and in a treatment window set again at {spec.stacks} stacks on '
                     f'{holder}; after {spec.settle_ms} ms the minion\'s plain melee swings (no crit, no glancing) '
                     f'are counted over {spec.window_ms} ms, and the aura is read at the window end. The per-swing '
                     f'mean of the treatment windows over that of the control windows is judged against the '
                     f'stated {expected:g}% bonus in the G-19 band, with the 99% interval rules of the hit ratio '
                     f'judge; an aura missing from a treatment window or present in a control window is '
                     f'unmeasured.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    if spec.player_spell_power is not None:
        scenario['players'][0]['spell_power'] = spec.player_spell_power
        scenario['contract'] += (f' The caster holds {spec.player_spell_power} spell power (harness fixture), which '
                                 f'raises the minion\'s attack power and narrows the spread of its swings.')
    model = {'kind': KIND, 'metric': MINION_SWING_ARMS_METRIC, 'quote': entry.quote, 'expected': expected,
             'stacks': spec.stacks, 'holder': spec.holder, 'windows': windows}
    expectation = Expectation(arms_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura, None, f'{expected:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def aura_mismatch(model: dict, values: dict) -> str | None:
    held_by_treatment = model['stacks'] if model['holder'] == 'dummy' else 1
    for arm, wanted in (('control', 0), ('treatment', held_by_treatment)):
        for index, labels in enumerate(model['windows'][arm]):
            held = values[labels['aura']]
            if held != wanted:
                return f'{arm} window {index} read the aura at {held:g}, not {wanted:g}'
    return None


def minion_swing_arms_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for arm in ARMS for window in model['windows'][arm] for label in window.values()]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    mismatch = aura_mismatch(model, run.values)
    if mismatch:
        return replace(base, status='unmeasured', explanation=f'not judged: the arms did not hold: {mismatch}')
    samples = {}
    for arm in ARMS:
        windows = model['windows'][arm]
        totals = [run.values[window['end total']] - run.values[window['start total']] for window in windows]
        counts = [run.values[window['end count']] - run.values[window['start count']] for window in windows]
        if sum(counts) < len(windows):
            return replace(base, status='unmeasured',
                           explanation=f'{sum(counts):g} plain swings in the {len(windows)} {arm} windows; each arm '
                                       f'needs at least one per window on average')
        samples[arm] = per_event_sample(totals, counts)
    bonus = bonus_of(samples['treatment'], samples['control'], float(model['expected']))
    status, reason, needed = bonus_status(bonus)
    control, treatment = samples['control'], samples['treatment']
    return replace(base, status=status, measured=bonus.measured, expected=bonus.expected,
                   low=bonus.expected - bonus.band, high=bonus.expected + bonus.band,
                   detail={'bonus': bonus_detail(bonus), 'trials_needed': needed},
                   explanation=f'per-swing mean {treatment.mean:.6g} over {treatment.events:g} treatment swings '
                               f'against {control.mean:.6g} over {control.events:g} control swings, ratio '
                               f'{treatment.mean / control.mean:.5g}; {bonus_text(bonus)}; {reason}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return minion_swing_arms_scenario(class_file, minion_swing_arms_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'swing_arms')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: minion_swing_arms_verdict}
METRIC_EVIDENCE = {MINION_SWING_ARMS_METRIC: 'event'}
