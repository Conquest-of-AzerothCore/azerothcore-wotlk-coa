from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import TARGET, Expectation, dataset, facts_of

KIND = 'shot_ramp'
ORDER = 10

RAMP_ARMS = ('control', 'treatment')
RAMP_READS = ('total', 'count', 'all')
RAMP_MEASURES = ('per_stack', 'maximum')
NEIGHBOUR_STEP = 0.05
ROUNDING_POINTS = 1.0
ROUNDING_SHARE = 1.0
DEFAULT_RESET_MS = 2500
DEFAULT_SEQUENCES = 4
DEFAULT_CASTS = 3


@dataclass(frozen=True)
class ShotRampSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    shot_spell: int
    stack_spell: int
    shots_per_cast: int
    casts: int
    sequences: int
    reset_ms: int
    distance: float
    cast_power: int | None
    caster_auras: tuple[int, ...]
    target_auras: tuple[int, ...]
    learn: tuple[int, ...]
    label_suffix: str


def shot_ramp_spec(entry: dict) -> ShotRampSpec:
    spec = ShotRampSpec(entry['spell'], entry['name'], entry['quote'], int(entry['cast_spell']),
                        int(entry['shot_spell']), int(entry['stack_spell']), int(entry['shots_per_cast']),
                        int(entry.get('casts', DEFAULT_CASTS)), int(entry.get('sequences', DEFAULT_SEQUENCES)),
                        int(entry.get('reset_ms', DEFAULT_RESET_MS)), float(entry['dummy_distance']),
                        entry.get('cast_power'), tuple(int(spell) for spell in entry.get('caster_auras', ())),
                        tuple(int(spell) for spell in entry.get('target_auras', ())),
                        tuple(int(spell) for spell in entry.get('learn', ())),
                        entry.get('label_suffix', 'shot_ramp'))
    if spec.shots_per_cast <= 0 or spec.casts <= 0 or spec.sequences <= 0 or spec.reset_ms <= 0:
        raise ValueError(f'{spec.spell} shot_ramp needs positive shots_per_cast, casts, sequences and reset_ms')
    if spec.distance <= 0:
        raise ValueError(f'{spec.spell} shot_ramp needs a positive dummy_distance')
    return spec


@dataclass(frozen=True)
class RampFacts:
    per_stack: float
    cap: int
    period_ms: int
    travel_ms: int


def ramp_facts(records: Records, spec: ShotRampSpec) -> RampFacts:
    per_stack = (int(records.field('Spell', spec.stack_spell, 'EffectBasePoints[0]')) + 1) / 100
    cap = int(records.field('Spell', spec.stack_spell, 'StackAmount'))
    period_ms = int(records.field('Spell', spec.cast_spell, 'EffectAmplitude[0]'))
    speed = float(records.field('Spell', spec.shot_spell, 'Speed'))
    travel_ms = round(spec.distance / speed * 1000) if speed > 0 else 0
    if per_stack <= 0 or cap <= 0 or period_ms <= 0:
        raise ValueError(f'{spec.spell} shot_ramp: {spec.stack_spell} per stack {per_stack}, cap {cap} and '
                         f'{spec.cast_spell} period {period_ms} must be positive')
    if spec.shots_per_cast * spec.casts <= cap + 1:
        raise ValueError(f'{spec.spell} shot_ramp needs more than {cap + 1} shots per sequence to reach the plateau')
    return RampFacts(per_stack, cap, period_ms, travel_ms)


def arm_sequences(spec: ShotRampSpec) -> dict[str, int]:
    return {'control': 1, 'treatment': spec.sequences}


def ramp_label(spec: ShotRampSpec, arm: str, sequence: int, shot: int | str, read: str) -> str:
    return f'{spec.spell} shot_ramp {spec.label_suffix} {arm}{sequence} shot{shot} {read}'


def stacks_label(spec: ShotRampSpec, arm: str, sequence: int) -> str:
    return f'{spec.spell} shot_ramp {spec.label_suffix} {arm}{sequence} stacks'


def known_label(spec: ShotRampSpec, arm: str) -> str:
    return f'{spec.spell} shot_ramp {spec.label_suffix} {arm} known'


def multiplier(facts: RampFacts, shot: int) -> float:
    return 1 + facts.per_stack * min(shot, facts.cap)


def tolerance_points(mult: float) -> float:
    return ROUNDING_POINTS + ROUNDING_SHARE * mult


def sequence_steps(records: Records, spec: ShotRampSpec, facts: RampFacts, arm: str, sequence: int) -> list[dict]:
    shots = spec.shots_per_cast * spec.casts
    power_type = facts_of(records, spec.cast_spell).power_type

    def reads(shot: int | str) -> list[dict]:
        fields = {'spell': spec.shot_spell, 'target': TARGET}
        plain = {**fields, 'critical': False, 'blocked': False}
        return [measurement(ramp_label(spec, arm, sequence, shot, 'total'), CASTER, 'spell_damage_total', **plain),
                measurement(ramp_label(spec, arm, sequence, shot, 'count'), CASTER, 'spell_damage_count', **plain),
                measurement(ramp_label(spec, arm, sequence, shot, 'all'), CASTER, 'spell_damage_count', **fields)]

    def cast() -> list[dict]:
        steps = [{'action': 'set_aura', 'actor': CASTER, 'target': TARGET, 'spell': aura, 'stacks': stacks}
                 for aura in spec.target_auras for stacks in (0, 1)]
        if spec.cast_power is not None:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': power_type, 'value': spec.cast_power})
        return steps + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell},
                        {'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': TARGET}]

    events = [(index * spec.shots_per_cast * facts.period_ms, 0, cast()) for index in range(spec.casts)]
    events += [(shot * facts.period_ms + facts.travel_ms + facts.period_ms // 2, 1, reads(shot))
               for shot in range(shots)]
    steps = reads('start')
    now = 0
    for at, _, block in sorted(events, key=lambda event: (event[0], event[1])):
        if at > now:
            steps.append({'action': 'wait', 'ms': at - now})
            now = at
        steps += block
    return steps + [measurement(stacks_label(spec, arm, sequence), CASTER, 'aura_stacks', spell=spec.stack_spell),
                    {'action': 'wait', 'label': 'ramp reset', 'ms': spec.reset_ms}]


def shot_ramp_scenario(class_file: dict, spec: ShotRampSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    facts = ramp_facts(records, spec)
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, facts.per_stack)
    shots = spec.shots_per_cast * spec.casts
    steps = (base_steps(class_file)
             + [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1} for aura in spec.caster_auras]
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in spec.learn]
             + [measurement(known_label(spec, 'control'), CASTER, 'aura', spell=spec.spell)]
             + sequence_steps(records, spec, facts, 'control', 0)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                measurement(known_label(spec, 'treatment'), CASTER, 'aura', spell=spec.spell)]
             + [step for sequence in range(spec.sequences)
                for step in sequence_steps(records, spec, facts, 'treatment', sequence)])
    plateau = multiplier(facts, facts.cap)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour shot ramp',
        'contract': (f'{spec.cast_spell} cast {spec.casts} times back to back at the dummy '
                     f'({spec.distance:g} yd), one cast every {spec.shots_per_cast} x {facts.period_ms} ms, so its '
                     f'{shots} shots {spec.shot_spell} sit on one {facts.period_ms} ms grid; the {spec.shot_spell} '
                     f'damage total and count (not critical, not blocked) and its count of every hit are read '
                     f'between landings ({facts.travel_ms} ms travel), so each window holds one shot. One sequence '
                     f'without {spec.spell} (control, every plain shot equal), then {spec.sequences} with it learned '
                     f'(treatment), {spec.reset_ms} ms apart so the {spec.stack_spell} stacks drop. Shot n of a '
                     f'treatment sequence (n from 0) must be the treatment\'s first shot times 1 + '
                     f'{facts.per_stack:g} x min(n, {facts.cap}) ({spec.stack_spell} EffectBasePoints[0] + 1 per '
                     f'stack, StackAmount {facts.cap}; plateau {plateau:g}) within the rounding, '
                     f'{ROUNDING_POINTS:g} + {ROUNDING_SHARE:g} x the multiplier points, and the first shot the '
                     f'control\'s. A critical or blocked shot is left out of its window; each stack count needs '
                     f'one plain shot over the treatment sequences.'),
        'players': [player_fixture(class_file)],
        'creatures': [{**creature_fixture(class_file), 'distance': spec.distance}],
        'steps': steps}
    reads = {arm: [[[ramp_label(spec, arm, sequence, shot, read) for read in RAMP_READS]
                    for shot in ('start', *range(shots))] for sequence in range(count)]
             for arm, count in arm_sequences(spec).items()}
    model = {'kind': KIND, 'metric': 'spell_damage_total', 'quote': entry.quote, 'per_stack': facts.per_stack,
             'stack_spell': spec.stack_spell,
             'cap': facts.cap, 'reads': reads, 'known': {arm: known_label(spec, arm) for arm in RAMP_ARMS},
             'stacks': {arm: [stacks_label(spec, arm, sequence) for sequence in range(count)]
                        for arm, count in arm_sequences(spec).items()}}
    expectations = [
        Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}{suffix}', BEHAVIOUR_METRIC_DELTA,
                    spec.spell, spec.shot_spell, None, f'{value:g}', prose_rule(entry.quote, spec.spell),
                    {**model, 'measure': measure})
        for measure, suffix, value in (('per_stack', '', facts.per_stack),
                                       ('maximum', '_max', facts.per_stack * facts.cap))]
    return timed(scenario, waited_ms(steps)), expectations


def window_shots(run, rows: list[list[str]]) -> tuple[list[float | None], int | None]:
    values = [[run.values[label] for label in row] for row in rows]
    amounts = []
    for shot, (now, before) in enumerate(zip(values[1:], values)):
        total, count, every = (after - earlier for after, earlier in zip(now, before))
        if every != 1:
            return amounts, shot
        amounts.append(total if count == 1 else None)
    return amounts, None


def shot_ramp_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [*model['known'].values(), *(label for arm in RAMP_ARMS for label in model['stacks'][arm]),
              *(label for arm in RAMP_ARMS for rows in model['reads'][arm] for row in rows for label in row)]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    known = {arm: run.values[label] for arm, label in model['known'].items()}
    if known['control'] or not known['treatment']:
        return replace(base, status='unmeasured', explanation=f'the talent aura read {known["control"]:g} before '
                                                              f'it was learned and {known["treatment"]:g} after')
    per_stack, cap = float(model['per_stack']), int(model['cap'])
    stacks = {arm: [run.values[label] for label in model['stacks'][arm]] for arm in RAMP_ARMS}
    if any(stacks['control']) or any(count != cap for count in stacks['treatment']):
        return replace(base, status='alert', explanation=f'{model["stack_spell"]} stacks after the last shot: '
                                                         f'control {stacks["control"]}, treatment '
                                                         f'{stacks["treatment"]}; 0 and {cap} are stated')
    shots = {}
    for arm in RAMP_ARMS:
        shots[arm] = []
        for sequence, rows in enumerate(model['reads'][arm]):
            amounts, broken = window_shots(run, rows)
            if broken is not None:
                return replace(base, status='unmeasured',
                               explanation=f'{arm} sequence {sequence} window of shot {broken} did not hold exactly '
                                           f'one shot; the grid is lost')
            shots[arm].append(amounts)
    control = [amount for amount in shots['control'][0] if amount is not None]
    firsts = [amounts[0] for amounts in shots['treatment'] if amounts[0] is not None]
    covered = {min(shot, cap + 1) for amounts in shots['treatment'] for shot, amount in enumerate(amounts)
               if amount is not None}
    if not control or not firsts or covered != set(range(cap + 2)):
        return replace(base, status='unmeasured',
                       explanation=f'plain shots: control {len(control)}, treatment first shots {len(firsts)}, '
                                   f'stack counts covered {sorted(covered)} of 0..{cap + 1}')
    flat = control[0]
    if any(abs(amount - flat) > tolerance_points(1) for amount in control):
        return replace(base, status='alert', explanation=f'control shots {control} are not flat without the talent')
    first = sum(firsts) / len(firsts)
    if any(abs(amount - first) > tolerance_points(1) for amount in [*firsts, flat]):
        return replace(base, status='alert', explanation=f'treatment first shots {firsts} against the control '
                                                         f'shot {flat:g}: the first shot must be unchanged')
    if first * NEIGHBOUR_STEP <= 2 * tolerance_points(1 + per_stack):
        return replace(base, status='unmeasured',
                       explanation=f'first shot {first:g} too small for the rounding to tell {per_stack:g} from '
                                   f'{per_stack - NEIGHBOUR_STEP:g} per stack')
    off = [(sequence, shot, amount, first * (1 + per_stack * min(shot, cap)))
           for sequence, amounts in enumerate(shots['treatment']) for shot, amount in enumerate(amounts)
           if amount is not None and abs(amount - first * (1 + per_stack * min(shot, cap)))
           > tolerance_points(1 + per_stack * min(shot, cap))]
    ramp = [(amount / first - 1) / shot for amounts in shots['treatment'] for shot, amount in enumerate(amounts)
            if amount is not None and 1 <= shot <= cap]
    plateau = [amount / first - 1 for amounts in shots['treatment'] for shot, amount in enumerate(amounts)
               if amount is not None and shot >= cap]
    measured = (sum(ramp) / len(ramp) if model['measure'] == 'per_stack' else sum(plateau) / len(plateau))
    expected = per_stack if model['measure'] == 'per_stack' else per_stack * cap
    share = tolerance_points(1 + per_stack * cap) / first
    summary = (f'first shot {first:g} ({len(firsts)} sequences, control {flat:g}); per-stack mean '
               f'{sum(ramp) / len(ramp):.4f} over {len(ramp)} ramp shots, plateau bonus (shot / first - 1) '
               f'{sum(plateau) / len(plateau):.4f} over {len(plateau)} shots from stack {cap}; '
               f'{model["stack_spell"]} stacks read after the last shot: treatment {stacks["treatment"]}, control '
               f'{stacks["control"]}; every plain shot against 1 + {per_stack:g} x min(n, {cap}) within '
               f'{ROUNDING_POINTS:g} + {ROUNDING_SHARE:g} x the multiplier points')
    status = 'alert' if off else 'ok'
    explanation = (f'{len(off)} shots off: ' + ', '.join(f'sequence {sequence} shot {shot} {amount:g} against '
                                                          f'{wanted:.1f}' for sequence, shot, amount, wanted in off[:5])
                   + f'; {summary}') if off else summary
    return replace(base, status=status, measured=measured, expected=expected, low=expected - share,
                   high=expected + share, explanation=explanation)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return shot_ramp_scenario(class_file, shot_ramp_spec(entry))


def label(entry: dict) -> list[str]:
    suffix = entry.get('label_suffix', 'shot_ramp')
    return [f"{entry['spell']} behaviour_metric_delta {suffix}",
            f"{entry['spell']} behaviour_metric_delta {suffix}_max"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: shot_ramp_verdict}
