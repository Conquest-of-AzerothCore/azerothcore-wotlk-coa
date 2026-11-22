from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, ally_group_steps, ally_players, behaviour_entry, dummy_fixture,
                        dummy_id, prose_rule, waited_ms)
from bonus import bonus_of, per_event_sample
from compare import FLOAT_EPSILON, Run, Verdict, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, MAX_SCENARIO_MS, timed
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
ADD_PCT_MODIFIER = 108
SPELLMOD_DAMAGE = 0
FIGURE_BAND = 0.1
HEAL_MULTIPLIED_AT = 'Unit::SpellHealingBonusDone, Unit.cpp:10932'
DAMAGE_MULTIPLIED_AT = 'Unit::SpellDamageBonusDone, Unit.cpp:9973'
HEAL_MIN_HITS = 2


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
    sized: bool = False
    figure_effect: int = 0
    min_hits: int = 0
    consumed: bool = False

    @property
    def family(self) -> str:
        return 'heal' if self.variant.startswith('heal') else self.variant

    @property
    def judged_figure(self) -> bool:
        return self.family == 'heal' or self.sized

    @property
    def next_cast(self) -> bool:
        return self.family == 'heal' or (self.sized and self.consumed)


def aura_fed_spec(entry: dict) -> AuraFedSpec:
    spec = AuraFedSpec(int(entry['spell']), entry['name'], entry['quote'], entry['variant'],
                       int(entry['feed_spell']), int(entry['aura']), int(entry['effect_spell']),
                       int(entry['every_ms']), float(entry['residual_target']), int(entry['feed_power']),
                       int(entry['effect_power']), float(entry['expected']), int(entry.get('trials', 1)),
                       tuple(int(spell) for spell in entry.get('caster_auras', ())),
                       tuple(sorted((name, int(value)) for name, value in entry.get('fixture', {}).items())),
                       entry.get('label_suffix', KIND), int(entry.get('chance_spell', 0)),
                       bool(entry.get('sized', False)), int(entry.get('figure_effect', 0)),
                       int(entry.get('min_hits', 0)), bool(entry.get('consumed', False)))
    if spec.family not in VARIANTS or not 0 < spec.residual_target < 1 or spec.trials < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a variant of {VARIANTS}, a residual_target in (0, 1) and at '
                         f'least one trial')
    if spec.variant == 'instant' and (spec.trials != 1 or spec.expected != 0):
        raise ValueError(f'{spec.spell} {KIND} instant reads casting 0 after one fed cast')
    if spec.sized and (spec.family != 'damage' or not 2 <= spec.min_hits <= spec.trials
                       or not isinstance(entry.get('consumed'), bool)):
        raise ValueError(f'{spec.spell} {KIND} sized needs the damage variant, min_hits from 2 to trials and an '
                         f'explicit consumed (true when the tooltip says next or consumes)')
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
    miss = (1 - chance) ** feed_ticks(records, spec.feed_spell, spec.family)
    per_feed = spec.residual_target / (PAIR_RUNS * spec.trials)
    return math.ceil(math.log(per_feed) / math.log(miss)), miss


def aura_figure(records: Records, spec: AuraFedSpec) -> float:
    index = spec.figure_effect
    aura = (records.field('Spell', spec.aura, f'EffectApplyAuraName[{index}]'),
            records.field('Spell', spec.aura, f'EffectMiscValue[{index}]'))
    if aura != (ADD_PCT_MODIFIER, SPELLMOD_DAMAGE):
        raise ValueError(f'{spec.spell} {KIND} {spec.family} needs {spec.aura} Effect[{index}] aura '
                         f'{ADD_PCT_MODIFIER} on SPELLMOD_DAMAGE, read {aura}')
    figure = records.single_value(spec.aura, index) / 100
    if abs(spec.expected - (1 + figure)) > FLOAT_EPSILON:
        raise ValueError(f'{spec.spell} {KIND} {spec.family} expects {spec.expected:g}, but {spec.aura} '
                         f'Effect[{index}] gives {1 + figure:g}')
    return figure


def aura_fed_scenario(class_file: dict, spec: AuraFedSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    figure = aura_figure(records, spec) if spec.judged_figure else None
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.expected)
    max_casts, miss = feed_casts(records, spec)
    channel_ms = (facts_of(records, spec.feed_spell).cast_time_ms if spec.family == 'heal'
                  else int(records.duration_ms(spec.feed_spell)))
    if spec.every_ms <= max(channel_ms, GCD_WAIT_MS):
        raise ValueError(f'{spec.spell} {KIND} every_ms {spec.every_ms} must exceed the feed duration {channel_ms} ms '
                         f'and the global cooldown')
    distance = cast_distance(records, spec.effect_spell)
    effect = facts_of(records, spec.effect_spell)
    speed = records.field('Spell', spec.effect_spell, 'Speed')
    travel_ms = math.ceil(distance / speed * 1000) if speed else 0
    heal = spec.family == 'heal'
    target = ALLY if heal else dummy_id(0)

    def effect_cast() -> list[dict]:
        return [{'action': 'set_power', 'actor': CASTER, 'power': effect.power_type, 'value': spec.effect_power},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.effect_spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.effect_spell, 'target': target}]

    def damage_reads(arm: str, trial: int, part: str = '') -> list[dict]:
        return [measurement(mark(spec, f'{arm} {trial} {part}{read}'), CASTER, metric, spell=spec.effect_spell,
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
        landed = effect.cast_time_ms + travel_ms + GCD_WAIT_MS
        steps += [{'action': 'wait', 'label': f'{arm} {index} hit', 'ms': landed}] + damage_reads(arm, index)
        if spec.next_cast and arm == ARMS[1]:
            steps += effect_cast() + [{'action': 'wait', 'label': f'{arm} {index} next hit', 'ms': landed}]
            steps += damage_reads(arm, index, 'next ')
        return steps

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
                       {'hits': mark(spec, f'{arm} {index} hits'), 'damage': mark(spec, f'{arm} {index} damage'),
                        **({'next_hits': mark(spec, f'{arm} {index} next hits'),
                            'next_damage': mark(spec, f'{arm} {index} next damage')}
                           if spec.next_cast and arm == ARMS[1] else {})}
                       if spec.variant == 'damage' else
                       {'hits': mark(spec, f'{arm} {index} hits'), 'heal': mark(spec, f'{arm} {index} heal'),
                        **({'next_hits': mark(spec, f'{arm} {index} next hits'),
                            'next_heal': mark(spec, f'{arm} {index} next heal')} if arm == ARMS[1] else {}),
                        })}
                   for index in range(spec.trials)] for arm in ARMS}
    expected_text = (f'casting reads 1 in the control and 0 in the treatment, and each judged {spec.effect_spell} '
                     f'cast must go off (spell_go_count +1 per trial)' if spec.variant == 'instant' else
                     f'the mean non-critical {spec.effect_spell} heal on the ally of the treatment is '
                     f'{spec.expected:g} times the control mean: {spec.aura} Effect[0] adds {figure:.4g} on '
                     f'SPELLMOD_DAMAGE, which multiplies the whole heal, spell power part included '
                     f'({HEAL_MULTIPLIED_AT}); the 99% interval of the ratio must lie inside '
                     f'{1 + figure * (1 - FIGURE_BAND):.4g} to {1 + figure * (1 + FIGURE_BAND):.4g} (the figure '
                     f'+-{FIGURE_BAND:.0%}, G-19); a second {spec.effect_spell} cast right after it is back at the '
                     f'control mean within the DBC dice spread (the aura is consumed once)'
                     if heal else
                     f'the mean non-critical {spec.effect_spell} hit of the treatment is {spec.expected:g} times the '
                     f'control mean: {spec.aura} Effect[{spec.figure_effect}] adds {figure:.4g} on SPELLMOD_DAMAGE, '
                     f'which multiplies the whole hit, spell power part included ({DAMAGE_MULTIPLIED_AT}); the 99% '
                     f'interval of the ratio must lie inside {1 + figure * (1 - FIGURE_BAND):.4g} to '
                     f'{1 + figure * (1 + FIGURE_BAND):.4g} (the figure +-{FIGURE_BAND:.0%}, G-19), each arm needs '
                     f'at least {spec.min_hits} non-critical hits (fewer is unmeasured)'
                     + (f'; a second {spec.effect_spell} cast right after it is back at the control mean within the '
                        f'DBC dice spread (the aura is consumed once)' if spec.consumed else
                        '; no second cast is judged (the tooltip does not say next or consumed)')
                     if spec.sized else
                     f'the mean non-critical {spec.effect_spell} hit of the treatment is {spec.expected:g} times the '
                     f'control mean within the DBC dice spread')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura fed effect',
        'contract': (f'{spec.spell} is learned. Control trials cancel {spec.aura} and cast {spec.effect_spell}; '
                     f'treatment trials cast {spec.feed_spell} every {spec.every_ms} ms (cast_until_aura, at most '
                     f'{max_casts} casts: miss chance per cast {miss:.4f} from ProcChance and '
                     f'{feed_ticks(records, spec.feed_spell, spec.family)} ticks, residual target '
                     f'{spec.residual_target:g} per '
                     f'pair) until {spec.aura} is on the caster, then cast {spec.effect_spell}; the aura is never '
                     f'set by the harness. Each trial reads {spec.aura} right before the judged cast; a trial whose '
                     f'read disagrees with its arm makes the run unmeasured. {expected_text}.'),
        'players': [{**player_fixture(class_file), **dict(spec.fixture)}]
        + (ally_players(class_file, {ALLY}) if heal else []),
        'creatures': [dummy_fixture(0, class_file, distance)],
        'steps': steps}
    model = {'kind': KIND, 'variant': spec.family, 'metric': 'casting' if spec.variant == 'instant' else
             'spell_heal_total' if heal else 'spell_damage_total', 'quote': entry.quote, 'expected': spec.expected,
             'reads': reads}
    if spec.family in ('damage', 'heal'):
        model['dice'] = float(records.field('Spell', spec.effect_spell, 'EffectDieSides[0]'))
    if heal:
        model['figure'] = figure
    if spec.sized:
        model.update({'sized': True, 'figure': figure, 'min_hits': spec.min_hits, 'consumed': spec.consumed})
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.effect_spell, None,
                              f'{spec.expected:g}', prose_rule(entry.quote, spec.spell), model)
    limit = MAX_ACCELERATED_SCENARIO_MS if spec.judged_figure else MAX_SCENARIO_MS
    return (timed(scenario, waited_ms(steps) + windows, limit),
            [expectation])


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
    next_cast = heal or model.get('consumed', False)
    hits = {arm: [] for arm in ARMS}
    next_hits = []
    count_before, total_before = 0.0, 0.0
    for arm in ARMS:
        for trial in model['reads'][arm]:
            count, total = run.values[trial['hits']], run.values[trial[total_key]]
            if count - count_before == 1:
                hits[arm].append(total - total_before)
            count_before, total_before = count, total
            if next_cast and arm == ARMS[1]:
                count, total = run.values[trial['next_hits']], run.values[trial[f'next_{total_key}']]
                if count - count_before == 1:
                    next_hits.append(total - total_before)
                count_before, total_before = count, total
    if not hits[ARMS[0]] or not hits[ARMS[1]]:
        return replace(base, status='unmeasured', explanation=f'no usable non-critical hit: {hits}')
    means = [sum(hits[arm]) / len(hits[arm]) for arm in ARMS]
    if heal or model.get('sized'):
        return figure_verdict(base, model, hits, next_hits, means, HEAL_MIN_HITS if heal else model['min_hits'],
                              next_cast)
    ratio = means[1] / means[0]
    spread = model['expected'] * model['dice'] / means[0]
    low, high = model['expected'] - spread, model['expected'] + spread
    status = 'ok' if low - FLOAT_EPSILON <= ratio <= high + FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=ratio, expected=model['expected'], low=low, high=high,
                   explanation=f'mean hit {means[1]:g} fed against {means[0]:g} control ({len(hits[ARMS[1]])} and '
                               f'{len(hits[ARMS[0]])} non-critical hits), band from the {model["dice"]:g} die sides')


def figure_verdict(base: Verdict, model: dict, hits: dict, next_hits: list[float], means: list[float],
                   min_hits: int, next_cast: bool) -> Verdict:
    noun = 'heal' if model['variant'] == 'heal' else 'hit'
    if next_cast and not next_hits:
        return replace(base, status='unmeasured', explanation=f'no usable non-critical second {noun}: {next_hits}')
    if min(len(hits[arm]) for arm in ARMS) < min_hits:
        return replace(base, status='unmeasured',
                       explanation=f'an arm has fewer than {min_hits} non-critical {noun}s: {hits}')
    figure = 100 * model['figure']
    low, high = figure * (1 - FIGURE_BAND), figure * (1 + FIGURE_BAND)
    bonus = bonus_of(*(per_event_sample(hits[arm], [1.0] * len(hits[arm])) for arm in reversed(ARMS)), figure)
    inside = math.isfinite(bonus.half) and low - FLOAT_EPSILON <= bonus.low and bonus.high <= high + FLOAT_EPSILON
    explanation = (f'mean {noun} {means[1]:g} fed against {means[0]:g} control ({len(hits[ARMS[1]])} and '
                   f'{len(hits[ARMS[0]])} non-critical {noun}s): bonus {bonus.measured:+.4g}%, 99% interval '
                   f'{bonus.low:+.4g}% to {bonus.high:+.4g}%, which must lie inside {low:+.4g}% to {high:+.4g}% (the '
                   f'DBC figure {figure:g}% +-{FIGURE_BAND:.0%})')
    consumed = True
    if next_cast:
        again = sum(next_hits) / len(next_hits) / means[0]
        consumed_spread = model['dice'] / means[0]
        consumed = abs(again - 1) <= consumed_spread + FLOAT_EPSILON
        explanation += (f'; the second cast after it reads {again:.4f} times the control mean ({len(next_hits)} '
                        f'{noun}s), within {1 - consumed_spread:.4f} to {1 + consumed_spread:.4f} when the aura is '
                        f'consumed once')
    return replace(base, status='ok' if inside and consumed else 'alert', measured=1 + bonus.measured / 100,
                   expected=model['expected'], low=1 + low / 100, high=1 + high / 100, explanation=explanation)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return aura_fed_scenario(class_file, aura_fed_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: aura_fed_verdict}
