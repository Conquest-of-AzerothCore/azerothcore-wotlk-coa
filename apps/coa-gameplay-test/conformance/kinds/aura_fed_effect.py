from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, ally_group_steps, ally_players, behaviour_entry, dummy_fixture, dummy_id,
                        prose_rule, waited_ms)
from compare import FLOAT_EPSILON, Run, Verdict, missing_measurement
from hits import timed
from procs import HEAL_POOL
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import ALLY, CAST_MARGIN_MS, GCD_WAIT_MS, Expectation, cast_distance, dataset, facts_of

KIND = 'aura_fed_effect'
ORDER = 32
VARIANTS = ('instant', 'damage', 'heal')
ARMS = ('control', 'treatment')
EXTRA_INITIAL_PERIOD = 0x200
CASTING_READ_MS = 300
PAIR_RUNS = 2


@dataclass(frozen=True)
class AuraFedSpec:
    spell: int
    name: str
    quote: str
    variant: str
    feed_spell: int
    aura: int
    effect_spell: int
    every_ms: int
    residual_target: float
    feed_power: int
    effect_power: int
    expected: float
    trials: int
    caster_auras: tuple[int, ...]
    fixture: tuple[tuple[str, int], ...]
    label_suffix: str
    chance_spell: int = 0


def aura_fed_spec(entry: dict) -> AuraFedSpec:
    spec = AuraFedSpec(int(entry['spell']), entry['name'], entry['quote'], entry['variant'],
                       int(entry['feed_spell']), int(entry['aura']), int(entry['effect_spell']),
                       int(entry['every_ms']), float(entry['residual_target']), int(entry['feed_power']),
                       int(entry['effect_power']), float(entry['expected']), int(entry.get('trials', 1)),
                       tuple(int(spell) for spell in entry.get('caster_auras', ())),
                       tuple(sorted((name, int(value)) for name, value in entry.get('fixture', {}).items())),
                       entry.get('label_suffix', KIND), int(entry.get('chance_spell', 0)))
    if spec.variant not in VARIANTS or not 0 < spec.residual_target < 1 or spec.trials < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a variant of {VARIANTS}, a residual_target in (0, 1) and at '
                         f'least one trial')
    if spec.variant == 'instant' and (spec.trials != 1 or spec.expected != 0):
        raise ValueError(f'{spec.spell} {KIND} instant reads casting 0 after one fed cast')
    return spec


def mark(spec: AuraFedSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def feed_ticks(records: Records, spell: int, variant: str = 'damage') -> int:
    if variant == 'heal':
        return 1
    duration = records.duration_ms(spell)
    amplitude = records.amplitude_ms(spell, 0)
    if duration <= 0 or amplitude <= 0:
        raise ValueError(f'{spell} {KIND} feed spell needs a periodic effect 0 with a duration')
    extra = 1 if records.field('Spell', spell, 'AttributesEx5') & EXTRA_INITIAL_PERIOD else 0
    return int(duration // amplitude) + extra


def feed_casts(records: Records, spec: AuraFedSpec) -> tuple[int, float]:
    chance = records.field('Spell', spec.chance_spell or spec.spell, 'ProcChance') / 100
    if not 0 < chance < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a proc chance between 0 and 100%')
    miss = (1 - chance) ** feed_ticks(records, spec.feed_spell, spec.variant)
    per_feed = spec.residual_target / (PAIR_RUNS * spec.trials)
    return math.ceil(math.log(per_feed) / math.log(miss)), miss


def aura_fed_scenario(class_file: dict, spec: AuraFedSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.expected)
    max_casts, miss = feed_casts(records, spec)
    channel_ms = (facts_of(records, spec.feed_spell).cast_time_ms if spec.variant == 'heal'
                  else int(records.duration_ms(spec.feed_spell)))
    if spec.every_ms <= max(channel_ms, GCD_WAIT_MS):
        raise ValueError(f'{spec.spell} {KIND} every_ms {spec.every_ms} must exceed the feed duration {channel_ms} ms '
                         f'and the global cooldown')
    distance = cast_distance(records, spec.effect_spell)
    effect = facts_of(records, spec.effect_spell)
    speed = records.field('Spell', spec.effect_spell, 'Speed')
    travel_ms = math.ceil(distance / speed * 1000) if speed else 0
    heal = spec.variant == 'heal'
    target = ALLY if heal else dummy_id(0)

    def effect_cast() -> list[dict]:
        return [{'action': 'set_power', 'actor': CASTER, 'power': effect.power_type, 'value': spec.effect_power},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.effect_spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.effect_spell, 'target': target}]

    def damage_reads(arm: str, trial: int) -> list[dict]:
        return [measurement(mark(spec, f'{arm} {trial} {read}'), CASTER, metric, spell=spec.effect_spell,
                            target=target, critical=False)
                for read, metric in (('hits', 'spell_damage_count'), ('damage', 'spell_damage_total'))]

    def heal_reads(arm: str, index: int, part: str) -> list[dict]:
        return [measurement(mark(spec, f'{arm} {index} {part}{read}'), CASTER, metric, spell=spec.effect_spell,
                            target=ALLY, critical=False)
                for read, metric in (('hits', 'spell_heal_count'), ('heal', 'spell_heal_total'))]

    def trial(arm: str, index: int) -> list[dict]:
        if heal:
            return heal_trial(arm, index)
        if arm == ARMS[0]:
            opening = [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura}]
        else:
            opening = [{'action': 'cast_until_aura', 'label': mark(spec, f'{arm} {index} feed'), 'actor': CASTER,
                        'spell': spec.feed_spell, 'target': target, 'aura': spec.aura, 'every_ms': spec.every_ms,
                        'max_casts': max_casts, 'cast_power': spec.feed_power, 'reset_cooldown': True},
                       {'action': 'wait', 'label': f'{arm} {index} feed ends', 'ms': channel_ms + CAST_MARGIN_MS}]
        steps = opening + [measurement(mark(spec, f'{arm} {index} aura'), CASTER, 'aura', spell=spec.aura)]
        steps += effect_cast()
        if spec.variant == 'instant':
            return steps + [{'action': 'wait', 'label': f'{arm} {index} casting read', 'ms': CASTING_READ_MS},
                            measurement(mark(spec, f'{arm} {index} casting'), CASTER, 'casting'),
                            {'action': 'wait', 'label': f'{arm} {index} cast ends',
                             'ms': effect.cast_time_ms + travel_ms + GCD_WAIT_MS},
                            measurement(mark(spec, f'{arm} {index} went'), CASTER, 'spell_go_count',
                                        spell=spec.effect_spell)]
        return steps + [{'action': 'wait', 'label': f'{arm} {index} hit',
                         'ms': effect.cast_time_ms + travel_ms + GCD_WAIT_MS}] + damage_reads(arm, index)

    def heal_trial(arm: str, index: int) -> list[dict]:
        steps = [{'action': 'set_health', 'actor': ALLY, 'value': 1, 'maximum': HEAL_POOL}]
        if arm == ARMS[0]:
            steps.append({'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura})
        else:
            steps += [{'action': 'cast_until_aura', 'label': mark(spec, f'{arm} {index} feed'), 'actor': CASTER,
                       'spell': spec.feed_spell, 'target': target, 'aura': spec.aura, 'every_ms': spec.every_ms,
                       'max_casts': max_casts, 'cast_power': spec.feed_power, 'reset_cooldown': True},
                      {'action': 'wait', 'label': f'{arm} {index} feed ends', 'ms': channel_ms + CAST_MARGIN_MS}]
        steps.append(measurement(mark(spec, f'{arm} {index} aura'), CASTER, 'aura', spell=spec.aura))
        landed = effect.cast_time_ms + travel_ms + GCD_WAIT_MS
        steps += effect_cast() + [{'action': 'wait', 'label': f'{arm} {index} heal', 'ms': landed}]
        steps += heal_reads(arm, index, '')
        if arm == ARMS[1]:
            steps += effect_cast() + [{'action': 'wait', 'label': f'{arm} {index} next heal', 'ms': landed}]
            steps += heal_reads(arm, index, 'next ')
        return steps

    steps = (base_steps(class_file)
             + (ally_group_steps({ALLY}) if heal else [])
             + [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1} for aura in spec.caster_auras]
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.feed_spell, spec.effect_spell, spec.spell))])
    for arm in ARMS:
        for index in range(spec.trials):
            steps += trial(arm, index)
    windows = spec.trials * max_casts * spec.every_ms
    reads = {arm: [{'aura': mark(spec, f'{arm} {index} aura'),
                    **({'casting': mark(spec, f'{arm} {index} casting'), 'went': mark(spec, f'{arm} {index} went')}
                       if spec.variant == 'instant' else
                       {'hits': mark(spec, f'{arm} {index} hits'), 'damage': mark(spec, f'{arm} {index} damage')}
                       if spec.variant == 'damage' else
                       {'hits': mark(spec, f'{arm} {index} hits'), 'heal': mark(spec, f'{arm} {index} heal'),
                        **({'next_hits': mark(spec, f'{arm} {index} next hits'),
                            'next_heal': mark(spec, f'{arm} {index} next heal')} if arm == ARMS[1] else {}),
                        })}
                   for index in range(spec.trials)] for arm in ARMS}
    expected_text = (f'casting reads 1 in the control and 0 in the treatment, and each judged {spec.effect_spell} '
                     f'cast must go off (spell_go_count +1 per trial)' if spec.variant == 'instant' else
                     f'the mean non-critical {spec.effect_spell} heal on the ally of the treatment is '
                     f'{spec.expected:g} times the control mean, and a second {spec.effect_spell} cast right after it '
                     f'is back at the control mean (the aura is consumed once), within the DBC dice spread'
                     if heal else
                     f'the mean non-critical {spec.effect_spell} hit of the treatment is {spec.expected:g} times the '
                     f'control mean within the DBC dice spread')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura fed effect',
        'contract': (f'{spec.spell} is learned. Control trials cancel {spec.aura} and cast {spec.effect_spell}; '
                     f'treatment trials cast {spec.feed_spell} every {spec.every_ms} ms (cast_until_aura, at most '
                     f'{max_casts} casts: miss chance per cast {miss:.4f} from ProcChance and '
                     f'{feed_ticks(records, spec.feed_spell, spec.variant)} ticks, residual target {spec.residual_target:g} per '
                     f'pair) until {spec.aura} is on the caster, then cast {spec.effect_spell}; the aura is never '
                     f'set by the harness. Each trial reads {spec.aura} right before the judged cast; a trial whose '
                     f'read disagrees with its arm makes the run unmeasured. {expected_text}.'),
        'players': [{**player_fixture(class_file), **dict(spec.fixture)}]
        + (ally_players(class_file, {ALLY}) if heal else []),
        'creatures': [dummy_fixture(0, class_file, distance)],
        'steps': steps}
    model = {'kind': KIND, 'variant': spec.variant, 'metric': 'casting' if spec.variant == 'instant' else
             'spell_heal_total' if heal else 'spell_damage_total', 'quote': entry.quote, 'expected': spec.expected,
             'reads': reads}
    if spec.variant in ('damage', 'heal'):
        model['dice'] = float(records.field('Spell', spec.effect_spell, 'EffectDieSides[0]'))
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.effect_spell, None,
                              f'{spec.expected:g}', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps) + windows), [expectation]


def aura_fed_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [label for arm in ARMS for trial in model['reads'][arm] for label in trial.values()]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    for arm, wanted in zip(ARMS, (0.0, 1.0)):
        held = [run.values[trial['aura']] for trial in model['reads'][arm]]
        if any(value != wanted for value in held):
            return replace(base, status='unmeasured',
                           explanation=f'precondition: the aura read {held} in the {arm} trials, {wanted:g} needed')
    if model['variant'] == 'instant':
        control = [run.values[trial['casting']] for trial in model['reads'][ARMS[0]]]
        treatment = [run.values[trial['casting']] for trial in model['reads'][ARMS[1]]]
        if any(value != 1 for value in control):
            return replace(base, status='unmeasured',
                           explanation=f'the control cast was not running {CASTING_READ_MS} ms in: {control}')
        went = {arm: [run.values[trial['went']] for trial in model['reads'][arm]] for arm in ARMS}
        control_went = list(range(1, len(control) + 1))
        if went[ARMS[0]] != control_went:
            return replace(base, status='unmeasured',
                           explanation=f'the control casts did not all go off: {went[ARMS[0]]}, {control_went} needed')
        fed_went = list(range(len(control) + 1, len(control) + len(treatment) + 1))
        landed = went[ARMS[1]] == fed_went
        status = 'ok' if landed and all(value == model['expected'] for value in treatment) else 'alert'
        return replace(base, status=status, measured=max(treatment), expected=model['expected'], low=0.0, high=0.0,
                       explanation=f'casting {CASTING_READ_MS} ms after the cast: control {control}, fed {treatment}; '
                                   f'casts gone off {went[ARMS[0]]} and {went[ARMS[1]]}, {fed_went} needed fed')
    heal = model['variant'] == 'heal'
    total_key = 'heal' if heal else 'damage'
    hits = {arm: [] for arm in ARMS}
    next_hits = []
    count_before, total_before = 0.0, 0.0
    for arm in ARMS:
        for trial in model['reads'][arm]:
            count, total = run.values[trial['hits']], run.values[trial[total_key]]
            if count - count_before == 1:
                hits[arm].append(total - total_before)
            count_before, total_before = count, total
            if heal and arm == ARMS[1]:
                count, total = run.values[trial['next_hits']], run.values[trial['next_heal']]
                if count - count_before == 1:
                    next_hits.append(total - total_before)
                count_before, total_before = count, total
    if not hits[ARMS[0]] or not hits[ARMS[1]]:
        return replace(base, status='unmeasured', explanation=f'no usable non-critical hit: {hits}')
    means = [sum(hits[arm]) / len(hits[arm]) for arm in ARMS]
    ratio = means[1] / means[0]
    spread = model['expected'] * model['dice'] / means[0]
    low, high = model['expected'] - spread, model['expected'] + spread
    status = 'ok' if low - FLOAT_EPSILON <= ratio <= high + FLOAT_EPSILON else 'alert'
    if heal:
        if not next_hits:
            return replace(base, status='unmeasured', explanation=f'no usable non-critical second heal: {next_hits}')
        again = sum(next_hits) / len(next_hits) / means[0]
        consumed_spread = model['dice'] / means[0]
        if abs(again - 1) > consumed_spread + FLOAT_EPSILON:
            status = 'alert'
        return replace(base, status=status, measured=ratio, expected=model['expected'], low=low, high=high,
                       explanation=f'mean heal {means[1]:g} fed against {means[0]:g} control ({len(hits[ARMS[1]])} '
                                   f'and {len(hits[ARMS[0]])} non-critical heals), band from the {model["dice"]:g} die '
                                   f'sides; the second cast after it reads {again:.3f} times the control mean '
                                   f'({len(next_hits)} heals), within {1 - consumed_spread:.3f} to '
                                   f'{1 + consumed_spread:.3f} when the aura is consumed once')
    return replace(base, status=status, measured=ratio, expected=model['expected'], low=low, high=high,
                   explanation=f'mean hit {means[1]:g} fed against {means[0]:g} control ({len(hits[ARMS[1]])} and '
                               f'{len(hits[ARMS[0]])} non-critical hits), band from the {model["dice"]:g} die sides')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return aura_fed_scenario(class_file, aura_fed_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: aura_fed_verdict}
