from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, SPELL_FAILED_NOT_READY, ally_group_steps, ally_players,
                        behaviour_entry, cleaned_tooltip, dummy_fixture, dummy_id, prose_rule, waited_ms)
from aura_fed_rate import (DAMAGE_RATE, HEAL_RATE, is_rate, is_rate_model, pooled_rate_verdict, rate_scenario,
                           rate_verdict)
from bonus import bonus_of, per_event_sample
from compare import FLOAT_EPSILON, NO_CAST_FAILURE, Run, Verdict, describe_failures, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, MAX_SCENARIO_MS, timed
from procs import HEAL_POOL
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import ALLY, CAST_MARGIN_MS, GCD_WAIT_MS, Expectation, cast_distance, dataset, facts_of

KIND = 'aura_fed_effect'
ORDER = 32
RESET_RECAST = 'cooldown_reset_recast'
VARIANTS = ('instant', 'damage', 'heal', 'cooldown', RESET_RECAST)
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
COOLDOWN_READ_MS = 500
RESET_TOLERANCE_MS = 100
RESET_ATTEMPTS = 2
COOLDOWN_BAND = 0.1
INSTANT_EVIDENCE_METRIC = 'aura_fed_instant_casting'
INSTANT_CONTRAST = 'aura_fed'
EVIDENCE_METRICS = {'cast_failure': 'cooldown', INSTANT_EVIDENCE_METRIC: 'instant'}
RECAST_ATTEMPTS = 1


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
    evidence_metric: str = ''

    @property
    def family(self) -> str:
        if self.variant.startswith('heal'):
            return 'heal'
        return 'cooldown' if self.variant.startswith('cooldown') else self.variant

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
                       int(entry.get('min_hits', 0)), bool(entry.get('consumed', False)),
                       entry.get('evidence_metric', ''))
    if spec.family not in VARIANTS or not 0 < spec.residual_target < 1 or spec.trials < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a variant of {VARIANTS}, a residual_target in (0, 1) and at '
                         f'least one trial')
    if spec.family == 'cooldown' and spec.expected != 0:
        raise ValueError(f'{spec.spell} {KIND} cooldown reads the remaining cooldown, expected 0 (no cooldown)')
    if spec.evidence_metric and EVIDENCE_METRICS.get(spec.evidence_metric) != spec.variant:
        raise ValueError(f'{spec.spell} {KIND} evidence_metric is cast_failure on the cooldown variant or '
                         f'{INSTANT_EVIDENCE_METRIC} on the instant variant')
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
    if variant in ('heal', 'cooldown'):
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
    if spec.family == 'cooldown':
        attempts = RECAST_ATTEMPTS if spec.variant == RESET_RECAST else RESET_ATTEMPTS
        usable = 1 - miss ** attempts
        need = math.ceil(math.log(spec.residual_target / PAIR_RUNS) / math.log(1 - usable))
        if spec.trials < need:
            raise ValueError(f'{spec.spell} {KIND} cooldown needs {need} trials: a trial reads the reset only when '
                             f'the aura came within {attempts} casts (chance {usable:.4f}), and a run with none '
                             f'is unmeasured, at most {spec.residual_target:g} per pair')
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
    channel_ms = (facts_of(records, spec.feed_spell).cast_time_ms if spec.family in ('heal', 'cooldown')
                  else int(records.duration_ms(spec.feed_spell)))
    if spec.every_ms <= max(channel_ms, GCD_WAIT_MS):
        raise ValueError(f'{spec.spell} {KIND} every_ms {spec.every_ms} must exceed the feed duration {channel_ms} ms '
                         f'and the global cooldown')
    distance = cast_distance(records, spec.effect_spell)
    effect = facts_of(records, spec.effect_spell)
    if spec.variant == RESET_RECAST:
        return reset_recast_scenario(class_file, spec, records, entry, effect, distance, max_casts)
    if spec.family == 'cooldown':
        return cooldown_scenario(class_file, spec, records, entry, effect, distance, max_casts, miss)
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
    if spec.evidence_metric == INSTANT_EVIDENCE_METRIC:
        model.update({'evidence_metric': INSTANT_EVIDENCE_METRIC, 'contrast': INSTANT_CONTRAST})
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.effect_spell, None,
                              f'{spec.expected:g}', prose_rule(entry.quote, spec.spell), model)
    limit = MAX_ACCELERATED_SCENARIO_MS if spec.judged_figure else MAX_SCENARIO_MS
    return (timed(scenario, waited_ms(steps) + windows, limit),
            [expectation])


def cooldown_scenario(class_file: dict, spec: AuraFedSpec, records: Records, entry, effect, distance: float,
                      max_casts: int, miss: float) -> tuple[dict, list[Expectation]]:
    recovery = int(max(records.field('Spell', spec.effect_spell, field) for field in
                       ('RecoveryTime', 'CategoryRecoveryTime')))
    if recovery <= RESET_ATTEMPTS * spec.every_ms + int(COOLDOWN_BAND * recovery):
        raise ValueError(f'{spec.spell} {KIND} cooldown: {spec.effect_spell} cooldown {recovery} ms must outlast '
                         f'{RESET_ATTEMPTS} feed casts {spec.every_ms} ms apart')
    target = dummy_id(0)

    def gavel(reset: bool) -> list[dict]:
        return ([{'action': 'set_power', 'actor': CASTER, 'power': effect.power_type, 'value': spec.effect_power}]
                + ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.effect_spell}] if reset else [])
                + [{'action': 'cast', 'actor': CASTER, 'spell': spec.effect_spell, 'target': target}])

    def read(arm: str, index: int, part: str, metric: str, spell: int) -> dict:
        return measurement(mark(spec, f'{arm} {index} {part}'), CASTER, metric, spell=spell)

    def wait(arm: str, index: int, part: str, ms: int) -> dict:
        return {'action': 'wait', 'label': f'{arm} {index} {part}', 'ms': ms}

    def trial(arm: str, index: int) -> list[dict]:
        steps = [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura}] + gavel(True)
        steps += [wait(arm, index, 'primed', GCD_WAIT_MS), read(arm, index, 'pre', 'cooldown_ms', spec.effect_spell)]
        if arm == ARMS[1]:
            steps += [{'action': 'cast_until_aura', 'label': mark(spec, f'{arm} {index} feed'), 'actor': CASTER,
                       'spell': spec.feed_spell, 'target': target, 'aura': spec.aura, 'every_ms': spec.every_ms,
                       'max_casts': max_casts, 'cast_power': spec.feed_power, 'reset_cooldown': True},
                      read(arm, index, 'reset', 'cooldown_ms', spec.effect_spell),
                      read(arm, index, 'fed', 'spell_go_count', spec.feed_spell)]
        else:
            steps += [wait(arm, index, 'late', spec.every_ms),
                      read(arm, index, 'reset', 'cooldown_ms', spec.effect_spell)]
        steps += [read(arm, index, 'aura', 'aura', spec.aura), wait(arm, index, 'settled', GCD_WAIT_MS)]
        steps += gavel(True)
        steps += [wait(arm, index, 'free', COOLDOWN_READ_MS),
                  read(arm, index, 'free', 'cooldown_ms', spec.effect_spell),
                  wait(arm, index, 'second', GCD_WAIT_MS - COOLDOWN_READ_MS)] + gavel(False)
        steps += [wait(arm, index, 'second lands', CAST_MARGIN_MS),
                  read(arm, index, 'second go', 'spell_go_count', spec.effect_spell),
                  read(arm, index, 'second failure', 'cast_failure', spec.effect_spell)]
        if arm == ARMS[1]:
            steps += [wait(arm, index, 'third', GCD_WAIT_MS)] + gavel(False)
            steps += [wait(arm, index, 'third lands', CAST_MARGIN_MS),
                      read(arm, index, 'third go', 'spell_go_count', spec.effect_spell),
                      read(arm, index, 'third failure', 'cast_failure', spec.effect_spell)]
        return steps + [wait(arm, index, 'trial ends', GCD_WAIT_MS)]

    steps = (base_steps(class_file)
             + [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1} for aura in spec.caster_auras]
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.feed_spell, spec.effect_spell, spec.spell))])
    for arm in ARMS:
        for index in range(spec.trials):
            steps += trial(arm, index)
    parts = ('pre', 'reset', 'aura', 'free', 'second go', 'second failure')
    reads = {arm: [{**{part.replace(' ', '_'): mark(spec, f'{arm} {index} {part}')
                       for part in parts + (('fed', 'third go', 'third failure') if arm == ARMS[1] else ())}}
                   for index in range(spec.trials)] for arm in ARMS}
    chance = records.field('Spell', spec.chance_spell or spec.spell, 'ProcChance')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura fed effect',
        'contract': (f'{spec.spell} is learned. Every trial casts {spec.effect_spell} for real and reads its remaining '
                     f'cooldown {GCD_WAIT_MS} ms later. Control trials then wait {spec.every_ms} ms and read it again '
                     f'(the natural cooldown, {recovery} ms: CategoryRecoveryTime of Spell.dbc); '
                     f'treatment trials cast {spec.feed_spell} '
                     f'every {spec.every_ms} ms (cast_until_aura, at most {max_casts} casts: ProcChance {chance}%, '
                     f'residual target {spec.residual_target:g} per pair) until {spec.aura} is on the caster and read '
                     f'the cooldown right after: 0 when the roll that granted the aura also reset it, judged only '
                     f'when {RESET_ATTEMPTS} or fewer feed casts went off (spell_go_count of {spec.feed_spell}), '
                     f'because a later cast finds the natural cooldown over. The aura is never set by the harness and '
                     f'is read before the next cast (0 in the control, 1 in the treatment). The cooldown of '
                     f'{spec.effect_spell} is then reset as a precondition fixture and it is cast (A), read '
                     f'{COOLDOWN_READ_MS} ms later (cooldown_ms is readback data), and cast again {GCD_WAIT_MS} ms '
                     f'after A (B): the behaviour is B going off without the refusal {SPELL_FAILED_NOT_READY} in the '
                     f'treatment (spell_go_count, cast_failure) and refused in the control; treatment trials cast it '
                     f'a third time (C), which must be refused, so only the next cast is free. Every cast '
                     f'follows the previous one by more than the global cooldown.'),
        'players': [{**player_fixture(class_file), **dict(spec.fixture)}],
        'creatures': [dummy_fixture(0, class_file, distance)],
        'steps': steps}
    model = {'kind': KIND, 'variant': 'cooldown', 'metric': 'cooldown_ms', 'quote': entry.quote,
             'expected': spec.expected, 'recovery': recovery, 'every_ms': spec.every_ms,
             'refused': SPELL_FAILED_NOT_READY, 'read_ms': COOLDOWN_READ_MS, 'reads': reads,
             **({'evidence_metric': spec.evidence_metric} if spec.evidence_metric else {})}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.effect_spell, None,
                              f'{spec.expected:g}', prose_rule(entry.quote, spec.spell), model)
    return (timed(scenario, waited_ms(steps) + spec.trials * max_casts * spec.every_ms, MAX_ACCELERATED_SCENARIO_MS),
            [expectation])


def reset_recast_scenario(class_file: dict, spec: AuraFedSpec, records: Records, entry, effect, distance: float,
                          max_casts: int) -> tuple[dict, list[Expectation]]:
    recovery = int(max(records.field('Spell', spec.effect_spell, field) for field in
                       ('RecoveryTime', 'CategoryRecoveryTime')))
    recast_ms = 2 * GCD_WAIT_MS
    if recovery <= recast_ms + int(COOLDOWN_BAND * recovery):
        raise ValueError(f'{spec.spell} {KIND} reset_recast: {spec.effect_spell} cooldown {recovery} ms must outlast '
                         f'the recast {recast_ms} ms after the first cast')
    target = dummy_id(0)

    def gavel(reset: bool) -> list[dict]:
        return ([{'action': 'set_power', 'actor': CASTER, 'power': effect.power_type, 'value': spec.effect_power}]
                + ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.effect_spell}] if reset else [])
                + [{'action': 'cast', 'actor': CASTER, 'spell': spec.effect_spell, 'target': target}])

    def read(arm: str, index: int, part: str, metric: str, spell: int) -> dict:
        return measurement(mark(spec, f'{arm} {index} {part}'), CASTER, metric, spell=spell)

    def wait(arm: str, index: int, part: str, ms: int) -> dict:
        return {'action': 'wait', 'label': f'{arm} {index} {part}', 'ms': ms}

    def trial(arm: str, index: int) -> list[dict]:
        steps = [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura}] + gavel(True)
        steps += [wait(arm, index, 'primed', GCD_WAIT_MS), read(arm, index, 'pre', 'cooldown_ms', spec.effect_spell),
                  read(arm, index, 'pre go', 'spell_go_count', spec.effect_spell)]
        if arm == ARMS[1]:
            steps += [{'action': 'cast_until_aura', 'label': mark(spec, f'{arm} {index} feed'), 'actor': CASTER,
                       'spell': spec.feed_spell, 'target': target, 'aura': spec.aura, 'every_ms': spec.every_ms,
                       'max_casts': max_casts, 'cast_power': spec.feed_power, 'reset_cooldown': True},
                      read(arm, index, 'fed', 'spell_go_count', spec.feed_spell)]
        steps += [read(arm, index, 'aura', 'aura', spec.aura), wait(arm, index, 'recast', GCD_WAIT_MS)]
        steps += gavel(False) + [wait(arm, index, 'recast lands', CAST_MARGIN_MS),
                                 read(arm, index, 'recast go', 'spell_go_count', spec.effect_spell),
                                 read(arm, index, 'recast failure', 'cast_failure', spec.effect_spell)]
        return steps + [wait(arm, index, 'trial ends', GCD_WAIT_MS)]

    steps = (base_steps(class_file)
             + [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1} for aura in spec.caster_auras]
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.feed_spell, spec.effect_spell, spec.spell))])
    for arm in ARMS:
        for index in range(spec.trials):
            steps += trial(arm, index)
    parts = ('pre', 'pre go', 'aura', 'recast go', 'recast failure')
    reads = {arm: [{part.replace(' ', '_'): mark(spec, f'{arm} {index} {part}')
                    for part in parts + (('fed',) if arm == ARMS[1] else ())}
                   for index in range(spec.trials)] for arm in ARMS}
    chance = records.field('Spell', spec.chance_spell or spec.spell, 'ProcChance')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura fed effect reset recast',
        'contract': (f'{spec.spell} is learned. Every trial resets the cooldown of {spec.effect_spell} as a '
                     f'precondition fixture, casts it for real and reads its remaining cooldown {GCD_WAIT_MS} ms '
                     f'later (the natural cooldown, {recovery} ms: CategoryRecoveryTime of Spell.dbc; a primer that '
                     f'is not natural within {COOLDOWN_BAND:.0%} voids the run). Treatment trials then cast '
                     f'{spec.feed_spell} every {spec.every_ms} ms (cast_until_aura, at most {max_casts} casts: '
                     f'ProcChance {chance}%, residual target {spec.residual_target:g} per pair) until {spec.aura} is '
                     f'on the caster; control trials cast no feed and never hold the aura. The aura is never set by '
                     f'the harness and is read before the recast (0 in the control, 1 in the treatment). '
                     f'{GCD_WAIT_MS} ms later (past the global cooldown) {spec.effect_spell} is cast again (R), '
                     f'{recast_ms} ms after the primer, with the natural cooldown still running: the behaviour is R '
                     f'going off (spell_go_count, cast_failure 0) in the treatment, where the roll that granted the '
                     f'aura reset the cooldown, and refused with {SPELL_FAILED_NOT_READY} in the control. Treatment '
                     f'trials are judged only when the aura came at the first feed cast (spell_go_count of '
                     f'{spec.feed_spell}): the selection rests on the aura timing, never on the outcome of R, since a '
                     f'later grant puts R near the natural end of the cooldown. A refused feed cast voids the run '
                     f'(unmeasured); the refusal of R in the control is the judged read, not a void.'),
        'players': [{**player_fixture(class_file), **dict(spec.fixture)}],
        'creatures': [dummy_fixture(0, class_file, distance)],
        'steps': steps}
    model = {'kind': KIND, 'variant': RESET_RECAST, 'metric': 'cast_failure',
             'quote': entry.quote, 'expected': spec.expected, 'recovery': recovery, 'feed_spell': spec.feed_spell,
             'refused': SPELL_FAILED_NOT_READY, 'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.effect_spell, None,
                              f'{spec.expected:g}', prose_rule(entry.quote, spec.spell), model)
    return (timed(scenario, waited_ms(steps) + spec.trials * max_casts * spec.every_ms, MAX_ACCELERATED_SCENARIO_MS),
            [expectation])


def reset_recast_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    refused_feed = [reason for reason in run.cast_failures.get(model['feed_spell'], []) if reason != NO_CAST_FAILURE]
    if refused_feed:
        return replace(base, status='unmeasured',
                       explanation=f'the run is void, a feed cast was refused ({describe_failures(refused_feed)})')
    trials = {arm: [{key: run.values[label] for key, label in trial.items()} for trial in model['reads'][arm]]
              for arm in ARMS}
    for arm, wanted in zip(ARMS, (0.0, 1.0)):
        held = [trial['aura'] for trial in trials[arm]]
        if any(value != wanted for value in held):
            return replace(base, status='unmeasured',
                           explanation=f'precondition: the aura read {held} in the {arm} trials, {wanted:g} needed')
    primed_wanted, band = model['recovery'] - GCD_WAIT_MS, COOLDOWN_BAND * model['recovery']
    primed = [trial['pre'] for arm in ARMS for trial in trials[arm]]
    if any(abs(value - primed_wanted) > band for value in primed):
        return replace(base, status='unmeasured',
                       explanation=f'the run is void: the primer cooldown reads {primed} are not the natural '
                                   f'{primed_wanted} ms within {band:g} ms')
    fed = [trial['fed'] for trial in trials[ARMS[1]]]
    attempts = [int(value - (fed[index - 1] if index else 0)) for index, value in enumerate(fed)]
    selected = [trial for trial, count in zip(trials[ARMS[1]], attempts) if count == RECAST_ATTEMPTS]
    if not selected:
        return replace(base, status='unmeasured',
                       explanation=f'no feed reached the aura at its first cast: {attempts}')
    refused = float(model['refused'])

    def went(trial: dict) -> bool:
        return trial['recast_failure'] == 0 and trial['recast_go'] - trial['pre_go'] == 1

    control = [trial['recast_failure'] for trial in trials[ARMS[0]]]
    control_ok = all(value == refused and trial['recast_go'] == trial['pre_go']
                     for value, trial in zip(control, trials[ARMS[0]]))
    treated = [trial['recast_failure'] for trial in selected]
    ok = control_ok and all(went(trial) for trial in selected)
    return replace(base, status='ok' if ok else 'alert', measured=max(treated), expected=model['expected'],
                   low=0.0, high=0.0,
                   explanation=f'treatment: recast failures {treated} on the {len(selected)} of {len(attempts)} trials '
                               f'whose aura came at the first feed cast (feed casts {attempts}), go deltas '
                               f'{[trial["recast_go"] - trial["pre_go"] for trial in selected]}; control: recast '
                               f'failures {control} ({model["refused"]} needed), go deltas '
                               f'{[trial["recast_go"] - trial["pre_go"] for trial in trials[ARMS[0]]]}')


def cooldown_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    recovery, every, band = model['recovery'], model['every_ms'], COOLDOWN_BAND * model['recovery']
    trials = {arm: [{key: run.values[label] for key, label in trial.items()} for trial in model['reads'][arm]]
              for arm in ARMS}
    for arm, wanted in zip(ARMS, (0.0, 1.0)):
        held = [trial['aura'] for trial in trials[arm]]
        if any(value != wanted for value in held):
            return replace(base, status='unmeasured',
                           explanation=f'precondition: the aura read {held} in the {arm} trials, {wanted:g} needed')
    primed = [trial['pre'] for arm in ARMS for trial in trials[arm]]
    natural = [(trial['pre'], recovery - 1600) for trial in trials[ARMS[0]]] + \
              [(trial['reset'], recovery - 1600 - every) for trial in trials[ARMS[0]]]
    if any(abs(value - wanted) > band for value, wanted in natural) or min(primed) <= RESET_TOLERANCE_MS:
        return replace(base, status='unmeasured',
                       explanation=f'precondition: the control cooldown reads {natural} are not the natural '
                                   f'{recovery} ms cooldown within {band:g} ms')
    fed = [trial['fed'] for trial in trials[ARMS[1]]]
    attempts = [int(value - (fed[index - 1] if index else 0)) for index, value in enumerate(fed)]
    usable = [trial for trial, count in zip(trials[ARMS[1]], attempts) if 1 <= count <= RESET_ATTEMPTS]
    if not usable:
        return replace(base, status='unmeasured',
                       explanation=f'no feed reached the aura in {RESET_ATTEMPTS} casts: {attempts}')
    reset = [trial['reset'] for trial in usable]
    free = [trial['free'] for trial in trials[ARMS[1]]]
    control_free = [trial['free'] for trial in trials[ARMS[0]]]
    free_wanted = recovery - COOLDOWN_READ_MS
    control_ok = all(abs(value - free_wanted) <= band for value in control_free)
    refused = float(model['refused'])
    control_second = all(trial['second_failure'] == refused for trial in trials[ARMS[0]])
    second = all(trial['second_failure'] == 0 for trial in trials[ARMS[1]])
    go = [trial['second_go'] for arm in ARMS for trial in trials[arm]]
    third = all(trial['third_failure'] == refused and trial['third_go'] == trial['second_go']
                for trial in trials[ARMS[1]])
    reset_ok = all(value <= RESET_TOLERANCE_MS for value in reset)
    free_ok = all(value <= RESET_TOLERANCE_MS for value in free)
    ok = reset_ok and free_ok and control_ok and control_second and second and third
    return replace(base, status='ok' if ok else 'alert', measured=max(free + reset), expected=model['expected'],
                   low=0.0, high=float(RESET_TOLERANCE_MS),
                   explanation=f'treatment: reset reads {reset} on {len(usable)} of {len(attempts)} trials '
                               f'(feed casts {attempts}), free cooldown reads {free}, second cast failures '
                               f'{[trial["second_failure"] for trial in trials[ARMS[1]]]}, third '
                               f'{[trial["third_failure"] for trial in trials[ARMS[1]]]}; control: free cooldown reads '
                               f'{control_free} (natural {free_wanted}), second cast failures '
                               f'{[trial["second_failure"] for trial in trials[ARMS[0]]]}, go counts {go}')


def aura_fed_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    if model.get('variant') == WINDOW_VARIANT:
        return window_verdict(base, run, model)
    if is_rate_model(model):
        return rate_verdict(base, run, model)
    labels = [label for arm in ARMS for trial in model['reads'][arm] for label in trial.values()]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    if model['variant'] == RESET_RECAST:
        return reset_recast_verdict(base, run, model)
    if model['variant'] == 'cooldown':
        return cooldown_verdict(base, run, model)
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


WINDOW_VARIANT = 'window'
WINDOW_SIDES = ('held', 'gone')
WINDOW_SHARES = {'held': (0.9, 0.965), 'gone': (1.04, 1.1)}
WINDOW_DETECTION_MS = 25
WINDOW_FEED_TICKS = 1
WINDOW_CHANNEL_CLEAR_MS = 4500
WINDOW_TRIAL_READS = ('known start', 'grants start', 'aura stop', 'grants stop', 'casting clear', 'ticks relearn',
                      'known relearn', 'ticks cast', 'grants cast', 'aura cast', 'casting', 'went')
WINDOW_EVIDENCE_METRIC = 'aura_fed_window_casting'
WINDOW_CONTRAST = 'aura_window'


@dataclass(frozen=True)
class WindowSpec:
    spell: int
    name: str
    quote: str
    feed_spell: int
    aura: int
    effect_spell: int
    every_ms: int
    residual_target: float
    feed_power: int
    effect_power: int
    trials: int
    min_judged: int
    held_ms: int
    gone_ms: int
    caster_auras: tuple[int, ...]
    label_suffix: str
    quote_spell: int | None = None


def window_spec(entry: dict) -> WindowSpec:
    spec = WindowSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['feed_spell']), int(entry['aura']),
                      int(entry['effect_spell']), int(entry['every_ms']), float(entry['residual_target']),
                      int(entry['feed_power']), int(entry['effect_power']), int(entry['trials']),
                      int(entry['min_judged']), int(entry['held_ms']), int(entry['gone_ms']),
                      tuple(int(spell) for spell in entry.get('caster_auras', ())), entry.get('label_suffix', KIND),
                      int(entry['quote_spell']) if 'quote_spell' in entry else None)
    if not 0 < spec.residual_target < 1 or not 1 <= spec.min_judged <= spec.trials:
        raise ValueError(f'{spec.spell} {KIND} {WINDOW_VARIANT} needs a residual_target in (0, 1) and min_judged '
                         f'from 1 to trials per side')
    if spec.every_ms < GCD_WAIT_MS or not WINDOW_CHANNEL_CLEAR_MS < spec.held_ms < spec.gone_ms:
        raise ValueError(f'{spec.spell} {KIND} {WINDOW_VARIANT} feeds past the global cooldown and judges after the '
                         f'{WINDOW_CHANNEL_CLEAR_MS} ms channel clearance, held_ms before gone_ms')
    return spec


def window_mark(spec: WindowSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def window_bounds(duration_ms: int, side: str) -> tuple[float, float]:
    low, high = WINDOW_SHARES[side]
    return duration_ms * low, duration_ms * high


def window_scenario(class_file: dict, spec: WindowSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    quoted = spec.spell
    if spec.quote_spell is not None and spec.quote_spell != spec.spell:
        if f'@s:{spec.quote_spell}:' not in cleaned_tooltip(records, spec.spell):
            raise ValueError(f'{spec.spell} {KIND} {WINDOW_VARIANT} quotes {spec.quote_spell}, whose tooltip the '
                             f'{spec.spell} tooltip does not embed')
        quoted = spec.quote_spell
    entry = behaviour_entry(records, quoted, spec.name, KIND, spec.quote, 0.0)
    duration = int(records.duration_ms(spec.aura))
    tick_spell = int(records.field('Spell', spec.feed_spell, 'EffectTriggerSpell[0]'))
    chance = records.field('Spell', spec.spell, 'ProcChance') / 100
    if duration <= 0 or not tick_spell or not 0 < chance < 1:
        raise ValueError(f'{spec.spell} {KIND} {WINDOW_VARIANT} needs a timed aura, a periodic trigger on the feed '
                         f'and a proc chance between 0 and 100%')
    miss = (1 - chance) ** WINDOW_FEED_TICKS
    max_casts = math.ceil(math.log(spec.residual_target / (PAIR_RUNS * len(WINDOW_SIDES) * spec.trials))
                          / math.log(miss))
    effect = facts_of(records, spec.effect_spell)
    distance = cast_distance(records, spec.effect_spell)
    speed = records.field('Spell', spec.effect_spell, 'Speed')
    travel_ms = math.ceil(distance / speed * 1000) if speed else 0
    target = dummy_id(0)
    offsets = {'held': spec.held_ms, 'gone': spec.gone_ms}

    def read(side: str, index: int, name: str, metric: str, **fields) -> dict:
        return measurement(window_mark(spec, f'{side} {index} {name}'), CASTER, metric, **fields)

    def trial(side: str, index: int) -> list[dict]:
        grants = {'spell': spec.aura}
        ticks = {'spell': tick_spell, 'target': target}
        return [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura},
                {'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                read(side, index, 'known start', 'knows_spell', spell=spec.spell),
                read(side, index, 'grants start', 'aura_apply_count', **grants),
                {'action': 'cast_until_aura', 'label': window_mark(spec, f'{side} {index} feed'), 'actor': CASTER,
                 'spell': spec.feed_spell, 'target': target, 'aura': spec.aura, 'every_ms': spec.every_ms,
                 'max_casts': max_casts, 'cast_power': spec.feed_power, 'reset_cooldown': True},
                {'action': 'unlearn', 'actor': CASTER, 'spell': spec.spell},
                read(side, index, 'aura stop', 'aura', spell=spec.aura),
                read(side, index, 'grants stop', 'aura_apply_count', **grants),
                {'action': 'wait', 'label': f'{side} {index} channel clears', 'ms': WINDOW_CHANNEL_CLEAR_MS},
                read(side, index, 'casting clear', 'casting'),
                read(side, index, 'ticks relearn', 'spell_damage_count', **ticks),
                {'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                read(side, index, 'known relearn', 'knows_spell', spell=spec.spell),
                {'action': 'wait', 'label': f'{side} {index} window', 'ms': offsets[side] - WINDOW_CHANNEL_CLEAR_MS},
                read(side, index, 'ticks cast', 'spell_damage_count', **ticks),
                read(side, index, 'grants cast', 'aura_apply_count', **grants),
                read(side, index, 'aura cast', 'aura', spell=spec.aura),
                {'action': 'set_power', 'actor': CASTER, 'power': effect.power_type, 'value': spec.effect_power},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.effect_spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.effect_spell, 'target': target},
                {'action': 'wait', 'label': f'{side} {index} casting read', 'ms': CASTING_READ_MS},
                read(side, index, 'casting', 'casting'),
                {'action': 'wait', 'label': f'{side} {index} cast ends',
                 'ms': effect.cast_time_ms + travel_ms + GCD_WAIT_MS},
                read(side, index, 'went', 'spell_go_count', spell=spec.effect_spell),
                {'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura}]

    steps = (base_steps(class_file)
             + [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1} for aura in spec.caster_auras]
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.feed_spell, spec.effect_spell, spec.spell))])
    for side in WINDOW_SIDES:
        for index in range(spec.trials):
            steps += trial(side, index)
    reads = {side: [{name: window_mark(spec, f'{side} {index} {name}') for name in WINDOW_TRIAL_READS}
                    for index in range(spec.trials)] for side in WINDOW_SIDES}
    bounds = {side: window_bounds(duration, side) for side in WINDOW_SIDES}
    ages = {side: (offsets[side], offsets[side] + WINDOW_DETECTION_MS) for side in WINDOW_SIDES}
    windows = len(WINDOW_SIDES) * spec.trials * max_casts * spec.every_ms
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura fed window',
        'contract': (
            f'{spec.aura} lasts {duration} ms (DBC). Each trial casts {spec.feed_spell} every {spec.every_ms} ms '
            f'(cast_until_aura, at most {max_casts} casts) until {spec.aura} is on the caster; the step checks the '
            f'aura on every world update (CoAGameplayTest.cpp CastUntilAura), so the grant is at most '
            f'{WINDOW_DETECTION_MS} ms old when it stops, and the harness never sets the aura. {spec.spell} is then '
            f'unlearned, because the running channel keeps ticking (set_moving does not stop it) and Chance() rolls '
            f'only while the caster holds {spec.spell} (AscensionSunCleric.cpp:199): no later tick may refresh '
            f'{spec.aura}. {spec.aura} is read present right after the unlearn and its application count is read '
            f'unchanged up to the judged cast; {spec.spell} is relearned {WINDOW_CHANNEL_CLEAR_MS} ms after the stop, '
            f'once the channel is over (casting 0, no new {tick_spell} tick up to the judged cast), so the talent is '
            f'known at cast time. The judged read is the {spec.effect_spell} cast itself, {CASTING_READ_MS} ms after '
            f'it starts: held trials cast it {spec.held_ms} ms after the stop (age {ages["held"][0]} to '
            f'{ages["held"][1]} ms, window {bounds["held"][0]:g} to {bounds["held"][1]:g}): instant (casting 0); '
            f'gone trials {spec.gone_ms} ms after it (age {ages["gone"][0]} to {ages["gone"][1]} ms, window '
            f'{bounds["gone"][0]:g} to {bounds["gone"][1]:g}): its normal {effect.cast_time_ms} ms cast (casting 1). '
            f'Each cast must go off. A trial off a precondition is void; an age outside its window voids its side; '
            f'fewer than {spec.min_judged} judged trials on a side is unmeasured. Aura presence is supporting data.'),
        'players': [player_fixture(class_file)],
        'creatures': [dummy_fixture(0, class_file, distance)],
        'steps': steps}
    model = {'kind': KIND, 'variant': WINDOW_VARIANT, 'metric': 'casting', 'evidence_metric': WINDOW_EVIDENCE_METRIC,
             'contrast': WINDOW_CONTRAST, 'quote': entry.quote,
             'expected': float(duration), 'reads': reads, 'bounds': bounds, 'ages': ages,
             'min_judged': spec.min_judged, 'max_casts': max_casts}
    expectation = Expectation(window_mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura, None,
                              f'{duration}', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps) + windows, MAX_ACCELERATED_SCENARIO_MS), [expectation]


def window_usable(values: dict, trial: dict, went_before: float) -> str | None:
    checks = (('known start', values[trial['known start']] == 1),
              ('one grant', values[trial['grants stop']] - values[trial['grants start']] == 1),
              ('aura after the unlearn', values[trial['aura stop']] == 1),
              ('channel over', values[trial['casting clear']] == 0),
              ('relearned', values[trial['known relearn']] == 1),
              ('no tick after the relearn', values[trial['ticks cast']] == values[trial['ticks relearn']]),
              ('no refresh', values[trial['grants cast']] == values[trial['grants stop']]),
              ('went off', values[trial['went']] - went_before == 1))
    return next((name for name, held in checks if not held), None)


def window_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [label for side in WINDOW_SIDES for trial in model['reads'][side] for label in trial.values()]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    judged = {side: [] for side in WINDOW_SIDES}
    void = []
    went_before = 0.0
    for side in WINDOW_SIDES:
        low, high = model['bounds'][side]
        youngest, oldest = model['ages'][side]
        inside = low < youngest and oldest < high
        for index, trial in enumerate(model['reads'][side]):
            reason = window_usable(run.values, trial, went_before)
            went_before = run.values[trial['went']]
            if reason is not None:
                void.append(f'{side} {index}: {reason}')
            elif not inside:
                void.append(f'{side} {index}: age {youngest} to {oldest} ms outside {low:g} to {high:g}')
            else:
                judged[side].append(run.values[trial['casting']])
    text = (f'held casting {judged["held"]}, gone casting {judged["gone"]} (ages {model["ages"]["held"]} and '
            f'{model["ages"]["gone"]} ms against the {model["expected"]:g} ms duration)'
            + (f'; void: {", ".join(void)}' if void else ''))
    short = [side for side in WINDOW_SIDES if len(judged[side]) < model['min_judged']]
    if short:
        return replace(base, status='unmeasured', explanation=f'{text}; fewer than {model["min_judged"]} judged '
                                                              f'trials on {", ".join(short)}')
    wrong = ([value for value in judged['held'] if value != 0] + [value for value in judged['gone'] if value != 1])
    status = 'alert' if wrong else 'ok'
    return replace(base, status=status, measured=model['expected'] if status == 'ok' else None,
                   expected=model['expected'], low=model['bounds']['held'][0], high=model['bounds']['gone'][1],
                   explanation=f'{text}; instant inside the window and a normal cast past it: {status}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    if entry.get('variant') == WINDOW_VARIANT:
        return window_scenario(class_file, window_spec(entry))
    if is_rate(entry):
        return rate_scenario(class_file, entry)
    return aura_fed_scenario(class_file, aura_fed_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: aura_fed_verdict}
METRIC_EVIDENCE = {WINDOW_EVIDENCE_METRIC: 'state', INSTANT_EVIDENCE_METRIC: 'state'}
CONTRAST_PROOF = {WINDOW_EVIDENCE_METRIC: WINDOW_CONTRAST, INSTANT_EVIDENCE_METRIC: INSTANT_CONTRAST}
STATE_PROMISES = {WINDOW_EVIDENCE_METRIC: r'within', INSTANT_EVIDENCE_METRIC: r'instant'}


def pooled_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    if not is_rate_model(model):
        return replace(base, status='unmeasured',
                       explanation=f'{KIND} pools only the {HEAL_RATE} and {DAMAGE_RATE} variants')
    return pooled_rate_verdict(base, runs, model)


POOLED_JUDGE = pooled_verdict
