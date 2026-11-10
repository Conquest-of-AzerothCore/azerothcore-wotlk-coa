from dataclasses import dataclass
from pathlib import Path
import re

from hits import DRAIN_MS, MAIN_HAND, TIMEOUT_MARGIN_MS, aura_modifiers, creature_fixture
from procs import swing_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import COLOR_CODE, Records
from values import (CAST_MARGIN_MS, FORCED_CRIT_RATING, Expectation, TARGET, armed_for, dataset, facts_of,
                    fixture_health_step, required_aura_steps, required_target_health_steps)

BEHAVIOUR_COUNT = 'behaviour_count'
BEHAVIOUR_RATIO = 'behaviour_ratio'
BEHAVIOUR_DURATION = 'behaviour_duration'
BEHAVIOUR_DURATION_RATIO = 'behaviour_duration_ratio'
BEHAVIOUR_TRIGGER = 'behaviour_trigger'
BEHAVIOUR_METRIC_DELTA = 'behaviour_metric_delta'
BEHAVIOUR_DURATION_REFRESH = 'behaviour_duration_refresh'
BEHAVIOUR_AMOUNT_DELTA = 'behaviour_amount_delta'
BEHAVIOUR_CRIT_GUARANTEE = 'behaviour_crit_guarantee'
BEHAVIOUR_AURA_GRANT = 'behaviour_aura_grant'
BEHAVIOUR_CHECKS = (BEHAVIOUR_COUNT, BEHAVIOUR_RATIO, BEHAVIOUR_DURATION, BEHAVIOUR_DURATION_RATIO, BEHAVIOUR_TRIGGER,
                    BEHAVIOUR_METRIC_DELTA, BEHAVIOUR_DURATION_REFRESH, BEHAVIOUR_AMOUNT_DELTA,
                    BEHAVIOUR_CRIT_GUARANTEE, BEHAVIOUR_AURA_GRANT)
KINDS = ('count', 'ratio', 'duration', 'duration_ratio', 'trigger', 'metric_delta', 'duration_refresh',
        'amount_delta', 'crit_guarantee', 'aura_grant')
CRIT_GUARANTEE_ATTEMPTS = 100
CRIT_GUARANTEE_MINIMUM_EVENTS = 5
PROSE = 'prose: '
BEFORE = 'before'
AFTER = 'after'
LINE_BREAKS = re.compile(r'\s+')


class NotModelled(Exception):
    pass


@dataclass(frozen=True)
class BehaviourEntry:
    spell: int
    name: str
    tooltip: str
    kind: str
    quote: str
    expected: float


def cleaned_tooltip(records: Records, spell_id: int) -> str:
    return LINE_BREAKS.sub(' ', COLOR_CODE.sub('', records.field('Spell', spell_id, 'Description[enUS]')))


def prose_rule(quote: str, spell_id: int) -> str:
    return f'{PROSE}"{quote}" ({spell_id})'


def behaviour_entry(records: Records, spell_id: int, name: str, kind: str, quote: str, expected: float
                    ) -> BehaviourEntry:
    if kind not in KINDS:
        raise ValueError(f'behaviour kind {kind!r} is not one of {KINDS}')
    tooltip = cleaned_tooltip(records, spell_id)
    if quote not in tooltip:
        raise ValueError(f'{spell_id} tooltip {tooltip!r} does not contain the quote {quote!r}')
    return BehaviourEntry(spell_id, name, tooltip, kind, quote, expected)


HIT_METRICS = frozenset({'spell_damage_count', 'aura'})


@dataclass(frozen=True)
class TargetCountSpec:
    spell: int
    name: str
    quote: str
    expected: int
    target_rank: int
    radius: float
    radius_reason: str
    metric: str = 'spell_damage_count'
    repeats: int = 5


def dummy_id(index: int) -> str:
    return 'primary' if index == 0 else f'extra{index}'


def dummy_fixture(index: int, class_file: dict, distance: float) -> dict:
    fixture = creature_fixture(class_file)
    fixture['id'] = dummy_id(index)
    fixture['distance'] = distance
    return fixture


def hit_label(spell: TargetCountSpec, index: int, moment: str) -> str:
    return f'{spell.spell} {dummy_id(index)} {spell.metric} {moment}'


def hit_measurement(spec: TargetCountSpec, index: int, moment: str) -> dict:
    if spec.metric not in HIT_METRICS:
        raise NotModelled(f'target-count metric {spec.metric!r} is not one of {sorted(HIT_METRICS)}')
    label = hit_label(spec, index, moment)
    if spec.metric == 'spell_damage_count':
        return measurement(label, CASTER, spec.metric, spell=spec.target_rank, target=dummy_id(index))
    return measurement(label, dummy_id(index), spec.metric, spell=spec.target_rank, caster=CASTER)


def target_count_scenario(class_file: dict, spec: TargetCountSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'count', spec.quote, spec.expected)
    dummy_count = spec.expected + 1
    primary_distance = 3.0
    distances = [primary_distance] + [
        primary_distance + spec.radius * (index / dummy_count) for index in range(1, dummy_count)]
    creatures = [dummy_fixture(index, class_file, distances[index]) for index in range(dummy_count)]

    facts = facts_of(records, spec.target_rank)
    wait_ms = facts.cast_time_ms + CAST_MARGIN_MS

    def cast_steps() -> list[dict]:
        steps = []
        for _ in range(spec.repeats):
            if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
                steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                             'value': facts.mana_cost})
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.target_rank})
            steps += required_aura_steps(facts)
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.target_rank, 'target': dummy_id(0)})
            steps.append({'action': 'wait', 'ms': wait_ms})
        return steps

    def measure(moment: str) -> list[dict]:
        return [hit_measurement(spec, index, moment) for index in range(dummy_count)]

    before_labels = [hit_label(spec, index, BEFORE) for index in range(1, dummy_count)]
    after_labels = [hit_label(spec, index, AFTER) for index in range(1, dummy_count)]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour count',
        'contract': f'{spec.repeats} casts per phase, "ever hit at least once" per dummy rather than a single-'
                    f'cast snapshot: {spec.radius_reason}',
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.target_rank}] +
                 cast_steps() + measure(BEFORE) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + cast_steps() + measure(AFTER)}
    label = f'{spec.spell} behaviour_count'
    model = {'kind': 'count', 'dummy_labels': list(zip(before_labels, after_labels)), 'expected': spec.expected,
             'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_COUNT, spec.spell, spec.target_rank, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


@dataclass(frozen=True)
class HealingRatioTarget:
    spell: int
    name: str
    method: str = 'cast'
    effect: int = 0


def healing_ratio_target(raw) -> HealingRatioTarget:
    if len(raw) == 2:
        rank_id, name = raw
        return HealingRatioTarget(rank_id, name)
    rank_id, name, extra = raw
    return HealingRatioTarget(rank_id, name, extra.get('method', 'cast'), extra.get('effect', 0))


@dataclass(frozen=True)
class HealingRatioSpec:
    spell: int
    name: str
    quote: str
    expected: float
    targets: tuple[HealingRatioTarget, ...]


def healing_ratio_scenario(class_file: dict, spec: HealingRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'ratio', spec.quote, spec.expected)

    def label(target: HealingRatioTarget, moment: str) -> str:
        if target.method == 'effect_value':
            return f'{spec.spell} {target.spell} spell_effect_value {moment}'
        if target.method == 'taken':
            return f'{spec.spell} {target.spell} spell_healing_taken {moment}'
        return f'{spec.spell} {target.spell} spell_healing_done {moment}'

    def cast_all() -> list[dict]:
        steps = []
        for target in spec.targets:
            if target.method not in ('cast', 'taken'):
                continue
            facts = facts_of(records, target.spell)
            if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
                steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                             'value': facts.mana_cost})
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': target.spell})
            steps += required_aura_steps(facts)
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': target.spell, 'target': CASTER})
            steps.append({'action': 'wait', 'ms': facts.cast_time_ms + CAST_MARGIN_MS})
        return steps

    def measure(moment: str) -> list[dict]:
        steps = []
        for target in spec.targets:
            if target.method == 'effect_value':
                steps.append(measurement(label(target, moment), CASTER, 'spell_effect_value', spell=target.spell,
                                         effect=target.effect))
            elif target.method == 'taken':
                steps.append(measurement(label(target, moment), CASTER, 'spell_healing_taken', spell=target.spell,
                                         target=CASTER))
            else:
                steps.append(measurement(label(target, moment), CASTER, 'spell_healing_done', spell=target.spell,
                                         target=CASTER))
        return steps

    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour ratio',
        'contract': 'No-combat with/without check: healing of the named spells, measured before and after the '
                    'passive is learned.',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file) + cast_all() + measure(BEFORE) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + cast_all() + measure(AFTER)}
    expectations = []
    for target in spec.targets:
        model = {'kind': 'ratio', 'before_label': label(target, BEFORE), 'after_label': label(target, AFTER),
                 'expected': spec.expected, 'quote': entry.quote, 'target_name': target.name}
        expectations.append(Expectation(f'{spec.spell} {target.spell} behaviour_ratio', BEHAVIOUR_RATIO, spec.spell,
                                        target.spell, None, str(spec.expected), prose_rule(entry.quote, spec.spell),
                                        model))
    return scenario, expectations


LEECH_RATIO_DAMAGE = 'damage'
LEECH_RATIO_HEAL = 'heal'


@dataclass(frozen=True)
class LeechRatioSpec:
    spell: int
    name: str
    quote: str
    target_rank: int
    expected_before: float
    expected_after: float


def leech_ratio_dummy_id(phase: str) -> str:
    return f'leech_{phase}'


def leech_ratio_label(spec: LeechRatioSpec, part: str, phase: str) -> str:
    return f'{spec.target_rank} {part} {phase}'


def leech_ratio_phase_steps(class_file: dict, facts, spec: LeechRatioSpec, phase: str) -> list[dict]:
    dummy_id = leech_ratio_dummy_id(phase)
    steps = []
    if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost})
    steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.target_rank})
    steps += required_aura_steps(facts)
    steps += required_target_health_steps(facts, dummy_id)
    steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.target_rank, 'target': dummy_id})
    steps.append({'action': 'wait', 'ms': facts.cast_time_ms + CAST_MARGIN_MS})
    steps.append(measurement(leech_ratio_label(spec, LEECH_RATIO_DAMAGE, phase), CASTER, 'spell_damage_total',
                             spell=spec.target_rank, target=dummy_id))
    steps.append(measurement(leech_ratio_label(spec, LEECH_RATIO_HEAL, phase), CASTER, 'spell_heal_total',
                             spell=spec.target_rank, target=CASTER))
    return steps


def leech_heal_modifier_factor(records: Records, class_file: dict) -> float:
    factor = 1.0
    for modifier in aura_modifiers(records, class_file.get('known_auras', []), class_file['level']):
        if modifier.applies_to == 'heal':
            factor *= (100 + modifier.percent) / 100
    return factor


def leech_ratio_scenario(class_file: dict, spec: LeechRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'ratio', spec.quote, spec.expected_after)
    facts = facts_of(records, spec.target_rank)
    before_dummy = dict(creature_fixture(class_file)) | {'id': leech_ratio_dummy_id(BEFORE)}
    after_dummy = dict(creature_fixture(class_file)) | {'id': leech_ratio_dummy_id(AFTER)}
    heal_factor = leech_heal_modifier_factor(records, class_file)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour leech ratio',
        'contract': f'Real cast of {spec.target_rank} against a dummy below its own TargetAuraState health '
                    f'threshold, once before {spec.name} is learned and once after, measuring the real heal and '
                    f'damage of the same cast, which share one random roll, so their ratio is exactly deterministic '
                    f'per cast once the reference character\'s own known heal-done modifiers are folded in.',
        'players': [player_fixture(class_file)],
        'creatures': [before_dummy, after_dummy],
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.target_rank}] +
                 leech_ratio_phase_steps(class_file, facts, spec, BEFORE) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] +
                 leech_ratio_phase_steps(class_file, facts, spec, AFTER)}
    expectations = [
        Expectation(f'{spec.spell} {spec.target_rank} leech_ratio before', BEHAVIOUR_RATIO, spec.spell,
                   spec.target_rank, None, str(spec.expected_before * heal_factor),
                   prose_rule('healing you equal to the damage dealt', spec.target_rank),
                   {'kind': 'leech_ratio', 'damage_label': leech_ratio_label(spec, LEECH_RATIO_DAMAGE, BEFORE),
                    'heal_label': leech_ratio_label(spec, LEECH_RATIO_HEAL, BEFORE), 'heal_baseline_label': None,
                    'expected': spec.expected_before * heal_factor, 'quote': 'healing you equal to the damage dealt',
                    'target_name': f'{spec.name} (before learning it)'}),
        Expectation(f'{spec.spell} {spec.target_rank} leech_ratio after', BEHAVIOUR_RATIO, spec.spell,
                   spec.target_rank, None, str(spec.expected_after * heal_factor), prose_rule(entry.quote, spec.spell),
                   {'kind': 'leech_ratio', 'damage_label': leech_ratio_label(spec, LEECH_RATIO_DAMAGE, AFTER),
                    'heal_label': leech_ratio_label(spec, LEECH_RATIO_HEAL, AFTER),
                    'heal_baseline_label': leech_ratio_label(spec, LEECH_RATIO_HEAL, BEFORE),
                    'expected': spec.expected_after * heal_factor, 'quote': entry.quote,
                    'target_name': f'{spec.name} (after learning it)'}),
    ]
    return scenario, expectations


def leech_ratio_spec(entry: dict) -> LeechRatioSpec:
    return LeechRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['target_rank'],
                          entry['expected_before'], entry['expected_after'])


@dataclass(frozen=True)
class HealthRatioSpec:
    spell: int
    name: str
    quote: str
    probe_spell: int
    levels: tuple[tuple[int, float], ...]


def health_ratio_label(spec: HealthRatioSpec, health_pct: int, moment: str) -> str:
    return f'{spec.spell} {health_pct} script_spell_damage_taken {moment}'


def health_threshold_ratio_scenario(class_file: dict, spec: HealthRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'ratio', spec.quote, spec.levels[0][1])

    def measure(moment: str) -> list[dict]:
        steps = []
        for health_pct, _ in spec.levels:
            steps.append(fixture_health_step(CASTER, health_pct))
            steps.append(measurement(health_ratio_label(spec, health_pct, moment), CASTER,
                                      'script_spell_damage_taken', spell=spec.probe_spell, target=TARGET))
        return steps

    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour health ratio',
        'contract': 'No-combat with/without check: scripted spell damage taken at caster health 90%/50%/10%, '
                    'measured before and after the passive is learned, proving both the reduction and the '
                    '"while above 80% or below 20% health" gate.',
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': base_steps(class_file) + measure(BEFORE) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + measure(AFTER)}
    expectations = []
    for health_pct, expected_ratio in spec.levels:
        model = {'kind': 'ratio', 'before_label': health_ratio_label(spec, health_pct, BEFORE),
                 'after_label': health_ratio_label(spec, health_pct, AFTER), 'expected': expected_ratio,
                 'quote': entry.quote, 'target_name': f'{health_pct}% health'}
        expectations.append(Expectation(f'{spec.spell} {health_pct} behaviour_ratio', BEHAVIOUR_RATIO, spec.spell,
                                        health_pct, None, str(expected_ratio), prose_rule(entry.quote, spec.spell),
                                        model))
    return scenario, expectations


def health_ratio_spec(entry: dict) -> HealthRatioSpec:
    return HealthRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['probe_spell'],
                           tuple((pct, ratio) for pct, ratio in entry['levels']))


GCD_WAIT_MS = 1600


@dataclass(frozen=True)
class AuraSpreadSpec:
    spell: int
    name: str
    quote: str
    expected: int
    seed_spell: int
    aura_spell: int
    target_rank: int
    radius: float
    radius_reason: str
    repeats: int = 3


def aura_spread_label(spec: AuraSpreadSpec, index: int, moment: str) -> str:
    return f'{spec.spell} {dummy_id(index)} aura {moment}'


def aura_spread_scenario(class_file: dict, spec: AuraSpreadSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'count', spec.quote, spec.expected)
    dummy_count = spec.expected + 1
    primary_distance = 3.0
    distances = [primary_distance] + [
        primary_distance + spec.radius * (index / dummy_count) for index in range(1, dummy_count)]
    creatures = [dummy_fixture(index, class_file, distances[index]) for index in range(dummy_count)]

    seed_facts = facts_of(records, spec.seed_spell)
    tempest_facts = facts_of(records, spec.target_rank)
    wait_ms = int(records.duration_ms(spec.target_rank)) + CAST_MARGIN_MS

    def power_step(facts) -> list[dict]:
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            return [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost}]
        return []

    def cast_steps() -> list[dict]:
        steps = []
        for _ in range(spec.repeats):
            steps += power_step(seed_facts)
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.seed_spell})
            steps += required_aura_steps(seed_facts)
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.seed_spell, 'target': dummy_id(0)})
            steps.append({'action': 'wait', 'ms': seed_facts.cast_time_ms + CAST_MARGIN_MS})
            steps.append({'action': 'wait', 'label': 'Global cooldown', 'ms': GCD_WAIT_MS})
            steps += power_step(tempest_facts)
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.target_rank})
            steps += required_aura_steps(tempest_facts)
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.target_rank})
            steps.append({'action': 'wait', 'ms': wait_ms})
        return steps

    def measure(moment: str) -> list[dict]:
        return [measurement(aura_spread_label(spec, index, moment), dummy_id(index), 'aura', spell=spec.aura_spell,
                            caster=CASTER)
                for index in range(1, dummy_count)]

    before_labels = [aura_spread_label(spec, index, BEFORE) for index in range(1, dummy_count)]
    after_labels = [aura_spread_label(spec, index, AFTER) for index in range(1, dummy_count)]
    learn_ranks = [{'action': 'learn', 'actor': CASTER, 'spell': rank}
                  for rank in dict.fromkeys((spec.seed_spell, spec.target_rank))]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour count',
        'contract': f'{spec.repeats} seed+cast cycles per phase: seed {spec.seed_spell} on the primary dummy, cast '
                    f'{spec.target_rank} and wait its full periodic buff, then count newly-afflicted nearby '
                    f'dummies: {spec.radius_reason}',
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': base_steps(class_file) + learn_ranks + cast_steps() + measure(BEFORE) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + cast_steps() + measure(AFTER)}
    label = f'{spec.spell} behaviour_count'
    model = {'kind': 'count', 'dummy_labels': list(zip(before_labels, after_labels)), 'expected': spec.expected,
             'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_COUNT, spec.spell, spec.target_rank, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def aura_spread_spec(entry: dict) -> AuraSpreadSpec:
    return AuraSpreadSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['seed_spell'],
                          entry['aura_spell'], entry['target_rank'], entry['radius'], entry['radius_reason'],
                          entry.get('repeats', 3))


def target_count_spec(entry: dict) -> TargetCountSpec:
    return TargetCountSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['target_rank'],
                           entry['radius'], entry['radius_reason'], entry.get('metric', 'spell_damage_count'),
                           entry.get('repeats', 5))


def healing_ratio_spec(entry: dict) -> HealingRatioSpec:
    return HealingRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'],
                            tuple(healing_ratio_target(raw) for raw in entry['targets']))


STRIKER = 'striker'
STRIKER_HEALTH = 1_000_000
STRIKER_DISTANCE = 3.0
DEFAULT_BREAK_TIMEOUT_MS = 3000
CAST_SETTLE_MS = 500


@dataclass(frozen=True)
class ShieldBreakTriggerSpec:
    spell: int
    name: str
    quote: str
    expected: float
    shield_aura: int
    trigger_spell: int
    breaker_spell: int
    striker_entry: int
    break_timeout_ms: int = DEFAULT_BREAK_TIMEOUT_MS


def trigger_label(spec: ShieldBreakTriggerSpec, phase: str, moment: str) -> str:
    return f'{spec.spell} {phase} {spec.trigger_spell} {moment}'


def shield_break_phase(spec: ShieldBreakTriggerSpec, phase: str) -> tuple[list[dict], str, str]:
    before = trigger_label(spec, phase, BEFORE)
    after = trigger_label(spec, phase, AFTER)
    steps = [
        {'action': 'set_aura', 'actor': CASTER, 'spell': spec.shield_aura, 'stacks': 1},
        {'action': 'assert', 'label': f'{spec.spell} {phase} SETUP: the shield is up', 'actor': CASTER,
         'metric': 'aura', 'spell': spec.shield_aura, 'equals': 1, 'within_ms': 2000},
        measurement(before, CASTER, 'spell_damage_count', spell=spec.trigger_spell, target=STRIKER),
        {'action': 'cast', 'actor': STRIKER, 'spell': spec.breaker_spell, 'target': CASTER},
        {'action': 'wait', 'label': f'{spec.spell} {phase} settle', 'ms': CAST_SETTLE_MS},
        {'action': 'assert', 'label': f'{spec.spell} {phase} SETUP: the shield is fully consumed by real damage',
         'actor': CASTER, 'metric': 'aura', 'spell': spec.shield_aura, 'equals': 0,
         'within_ms': spec.break_timeout_ms},
        measurement(after, CASTER, 'spell_damage_count', spell=spec.trigger_spell, target=STRIKER),
    ]
    return steps, before, after


def shield_break_trigger_scenario(class_file: dict, spec: ShieldBreakTriggerSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'trigger', spec.quote, spec.expected)
    striker = {'id': STRIKER, 'owner': CASTER, 'entry': spec.striker_entry, 'level': class_file['level'],
              'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 1}
    without_steps, without_before, without_after = shield_break_phase(spec, 'without')
    with_steps, with_before, with_after = shield_break_phase(spec, 'with')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour trigger',
        'contract': f'A striker (creature entry {spec.striker_entry}) casts {spec.breaker_spell} directly at the '
                    f'caster, the one school of damage shield aura {spec.shield_aura} actually absorbs, to fully '
                    f'consume it deterministically (melee from a hostile creature cannot: {spec.shield_aura} only '
                    f'absorbs its own school, not the physical damage a generic striker swings for), once without '
                    f'{spec.name} known and once with it known, counting {spec.trigger_spell} casts on the '
                    f'striker each time.',
        'players': [player_fixture(class_file)],
        'creatures': [striker],
        'steps': base_steps(class_file) + without_steps +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + with_steps}
    label = f'{spec.spell} behaviour_trigger'
    model = {'kind': 'trigger', 'without_before_label': without_before, 'without_after_label': without_after,
             'with_before_label': with_before, 'with_after_label': with_after, 'expected': spec.expected,
             'trigger_spell': spec.trigger_spell, 'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_TRIGGER, spec.spell, spec.trigger_spell, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def shield_break_trigger_spec(entry: dict) -> ShieldBreakTriggerSpec:
    return ShieldBreakTriggerSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'],
                                  entry['shield_aura'], entry['trigger_spell'], entry['breaker_spell'],
                                  entry['striker_entry'], entry.get('break_timeout_ms', DEFAULT_BREAK_TIMEOUT_MS))


DEFAULT_METRIC_DELTA_WAIT_MS = 3000
DEFAULT_METRIC_DELTA_EXPIRE_MS = 20500


@dataclass(frozen=True)
class MetricDeltaSpec:
    spell: int
    name: str
    quote: str
    expected: float
    trigger_spell: int
    metric: str
    fields: dict
    before_expected: float
    wait_ms: int = DEFAULT_METRIC_DELTA_WAIT_MS
    expire_ms: int = DEFAULT_METRIC_DELTA_EXPIRE_MS
    target: str = CASTER
    disable_regeneration: bool = False
    setup_casts: tuple[int, ...] = ()
    setup_actor_aura: int | None = None
    gate_spell: int | None = None
    label_suffix: str = ''


def metric_delta_label(spec: MetricDeltaSpec, moment: str) -> str:
    return f'{spec.spell} {spec.metric} {moment}'


def metric_delta_scenario(class_file: dict, spec: MetricDeltaSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
    facts = facts_of(records, spec.trigger_spell)

    def setup_cast_steps() -> list[dict]:
        if not spec.setup_casts:
            return []
        steps = []
        for setup_spell in spec.setup_casts:
            setup_facts = facts_of(records, setup_spell)
            if setup_facts.mana_cost > 0 and not setup_facts.mana_cost_percentage \
                    and not setup_facts.mana_cost_per_level:
                steps.append({'action': 'set_power', 'actor': CASTER, 'power': setup_facts.power_type,
                             'value': setup_facts.mana_cost})
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': setup_spell})
            steps += required_aura_steps(setup_facts)
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': setup_spell, 'target': spec.target})
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
        return steps

    def cast_steps() -> list[dict]:
        steps = []
        if spec.setup_actor_aura is not None:
            steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.setup_actor_aura, 'stacks': 1})
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
        steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
        steps += required_aura_steps(facts)
        steps += setup_cast_steps()
        steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': spec.target})
        steps.append({'action': 'wait', 'ms': spec.wait_ms})
        return steps

    before_label = metric_delta_label(spec, BEFORE)
    after_label = metric_delta_label(spec, AFTER)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour metric delta',
        'contract': f'No-combat with/without check: {spec.metric} {spec.fields} around a cast of {spec.trigger_spell},'
                    f' measured before and after '
                    f'{spec.gate_spell if spec.gate_spell is not None else spec.spell} is learned, waiting '
                    f'{spec.expire_ms} ms between phases for the first cast\'s effect to fully expire before the '
                    f'second cast.',
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}] if spec.disable_regeneration
                   else [player_fixture(class_file)],
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}] +
                 [{'action': 'learn', 'actor': CASTER, 'spell': setup_spell} for setup_spell in spec.setup_casts] +
                 cast_steps() + [measurement(before_label, CASTER, spec.metric, **spec.fields)] +
                 [{'action': 'learn', 'actor': CASTER, 'spell':
                   spec.gate_spell if spec.gate_spell is not None else spec.spell}] +
                 [{'action': 'wait', 'label': 'let the first effect fully expire', 'ms': spec.expire_ms}] +
                 cast_steps() + [measurement(after_label, CASTER, spec.metric, **spec.fields)]}
    if spec.target == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    label = f'{spec.spell} behaviour_metric_delta' + (f' {spec.label_suffix}' if spec.label_suffix else '')
    model = {'kind': 'metric_delta', 'before_label': before_label, 'after_label': after_label,
             'expected': spec.expected, 'before_expected': spec.before_expected, 'metric': spec.metric,
             'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell, None,
                              str(spec.expected), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def metric_delta_spec(entry: dict) -> MetricDeltaSpec:
    return MetricDeltaSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['trigger_spell'],
                           entry['metric'], entry['fields'], entry['before_expected'],
                           entry.get('wait_ms', DEFAULT_METRIC_DELTA_WAIT_MS),
                           entry.get('expire_ms', DEFAULT_METRIC_DELTA_EXPIRE_MS), entry.get('target', CASTER),
                           entry.get('disable_regeneration', False), tuple(entry.get('setup_casts', ())),
                           entry.get('setup_actor_aura'), entry.get('gate_spell'), entry.get('label_suffix', ''))


DEBT_ASSERT_TIMEOUT_MS = 2000
AMOUNT_DELTA_CAST_WAIT_MS = 150


@dataclass(frozen=True)
class DurationSpec:
    spell: int
    name: str
    quote: str
    expected_ms: float
    target_aura: int
    debt_aura: int
    breaker_spell: int
    striker_entry: int
    mechanism_file: str
    override_file: str
    reduce_function: str


def duration_label(spec: DurationSpec, moment: str) -> str:
    return f'{spec.spell} {spec.target_aura} duration {moment}'


def duration_crit_label(spec: DurationSpec) -> str:
    return f'{spec.spell} forced_crit_count'


def duration_debt_label(spec: DurationSpec) -> str:
    return f'{spec.spell} {spec.target_aura} debt_amount'


def duration_scenario(class_file: dict, spec: DurationSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'duration', spec.quote, spec.expected_ms)
    swing_ms = swing_interval(class_file)
    if swing_ms <= CAST_SETTLE_MS:
        raise NotModelled(f'{spec.name} needs a swing interval above {CAST_SETTLE_MS} ms to isolate one forced '
                          f'crit from the next natural swing, got {swing_ms} ms')
    fixture = dict(player_fixture(class_file)) | {'melee_crit_rating': FORCED_CRIT_RATING}
    target = creature_fixture(class_file)
    striker = {'id': STRIKER, 'owner': CASTER, 'entry': spec.striker_entry, 'level': class_file['level'],
              'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 1, 'spell_hit_bonus': 100}
    before_label = duration_label(spec, BEFORE)
    after_label = duration_label(spec, AFTER)
    crit_label = duration_crit_label(spec)
    debt_label = duration_debt_label(spec)
    steps = base_steps(class_file) + [
        {'action': 'set_aura', 'actor': CASTER, 'spell': spec.debt_aura, 'stacks': 1},
        {'action': 'cast', 'actor': STRIKER, 'spell': spec.breaker_spell, 'target': CASTER},
        {'action': 'wait', 'label': f'{spec.spell} debt settle', 'ms': CAST_SETTLE_MS},
        {'action': 'assert', 'label': debt_label, 'actor': CASTER, 'metric': 'aura_amount', 'spell': spec.target_aura,
         'effect': 0, 'min': 1, 'within_ms': DEBT_ASSERT_TIMEOUT_MS},
        {'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
        measurement(before_label, CASTER, 'aura_duration_ms', spell=spec.target_aura),
        {'action': 'attack', 'actor': CASTER, 'target': TARGET},
        {'action': 'wait', 'label': 'forced swing', 'ms': CAST_SETTLE_MS},
        {'action': 'stop_attack', 'actor': CASTER},
        measurement(after_label, CASTER, 'aura_duration_ms', spell=spec.target_aura),
        measurement(crit_label, CASTER, 'melee_damage_count', hand=MAIN_HAND, critical=True),
    ]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour duration',
        'contract': f'A striker (creature entry {spec.striker_entry}) casts {spec.breaker_spell} directly at the '
                    f'caster, who carries {spec.debt_aura} (the real "delay 40% of direct damage taken" shield), '
                    f'so the real damage-absorb hook applies a nonzero debt to {spec.target_aura} and resets its '
                    f'duration to its DBC maximum (`{spec.mechanism_file}` `Delay`), rather than `set_aura`-ing '
                    f'{spec.target_aura} directly: a stacks-only fixture leaves its debt amount at 0 (the '
                    f'SPELL_AURA_PERIODIC_DUMMY `BasePoints -1` override in `{spec.override_file}`), and '
                    f'a zero debt makes `{spec.reduce_function}`\'s own `reduction >= amount` branch remove the '
                    f'aura outright on the very first crit regardless of whether {spec.name}\'s duration claim '
                    f'holds, which would misjudge every run as `alert` for the wrong reason (confirmed by an '
                    f'exploratory `coa-verify --ram` run of the `set_aura`-only shape). A single forced melee crit '
                    f'({FORCED_CRIT_RATING} melee_crit_rating on the scenario\'s own player fixture, not the class '
                    f'file\'s shared ratings) against a plain dummy then reads {spec.target_aura}\'s '
                    f'aura_duration_ms before and after a {CAST_SETTLE_MS} ms wait: starting an attack lands its '
                    f'first swing immediately (observed: a {swing_ms} ms wait after \'attack\' measures two '
                    f'crits, one immediate and one at the weapon\'s own {swing_ms} ms speed, so the wait here is '
                    f'kept under {swing_ms} ms to isolate exactly one), and the natural elapsed time the engine '
                    f'decrements regardless is this wait, plus {spec.expected_ms:g} ms if the passive\'s own '
                    f'claim holds. The striker\'s spell_hit_bonus is forced to 100 so this single direct-damage '
                    f'swing cannot miss (Unit::MagicSpellHitResult, Unit.cpp:3970-4028, gives Smite only a base '
                    f'~96% hit chance at equal level otherwise), which was the actual source of a round-2 flaky '
                    f'failure (round2/run-report.md), misdiagnosed there as a wait-margin issue.',
        'players': [fixture],
        'creatures': [target, striker],
        'steps': steps}
    label = f'{spec.spell} behaviour_duration'
    model = {'kind': 'duration', 'before_label': before_label, 'after_label': after_label,
             'count_label': crit_label, 'expected_ms': spec.expected_ms, 'wait_ms': CAST_SETTLE_MS,
             'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_DURATION, spec.spell, spec.target_aura, None, str(spec.expected_ms),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def duration_spec(entry: dict) -> DurationSpec:
    return DurationSpec(entry['spell'], entry['name'], entry['quote'], entry['expected_ms'], entry['target_aura'],
                        entry['debt_aura'], entry['breaker_spell'], entry['striker_entry'],
                        entry['mechanism_file'], entry['override_file'], entry['reduce_function'])


@dataclass(frozen=True)
class AmountDeltaSpec:
    spell: int
    name: str
    quote: str
    fraction: float
    target_aura: int
    debt_aura: int
    breaker_spell: int
    striker_entry: int
    trigger_spell: int
    mechanism_file: str
    reduce_function: str
    mechanism_label: str


def amount_delta_label(spec: AmountDeltaSpec, phase: str, moment: str) -> str:
    return f'{spec.target_aura} amount {phase} {moment}'


def amount_delta_phase_steps(spec: AmountDeltaSpec, facts_trigger, phase: str) -> tuple[list[dict], str, str]:
    before_label = amount_delta_label(spec, phase, BEFORE)
    after_label = amount_delta_label(spec, phase, AFTER)
    steps = [
        {'action': 'set_aura', 'actor': CASTER, 'spell': spec.debt_aura, 'stacks': 1},
        {'action': 'cast', 'actor': STRIKER, 'spell': spec.breaker_spell, 'target': CASTER},
        {'action': 'wait', 'label': f'{spec.spell} {phase} debt settle', 'ms': CAST_SETTLE_MS},
        {'action': 'assert', 'label': f'{spec.spell} {phase} SETUP: the debt is established', 'actor': CASTER,
         'metric': 'aura_amount', 'spell': spec.target_aura, 'effect': 0, 'min': 1,
         'within_ms': DEBT_ASSERT_TIMEOUT_MS},
        measurement(before_label, CASTER, 'aura_amount', spell=spec.target_aura, effect=0),
    ]
    if facts_trigger.mana_cost > 0 and not facts_trigger.mana_cost_percentage and not facts_trigger.mana_cost_per_level:
        steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts_trigger.power_type,
                     'value': facts_trigger.mana_cost})
    steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
    steps += required_aura_steps(facts_trigger)
    steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': CASTER})
    steps.append({'action': 'wait', 'label': f'{spec.spell} {phase} cast settle', 'ms': AMOUNT_DELTA_CAST_WAIT_MS})
    steps.append(measurement(after_label, CASTER, 'aura_amount', spell=spec.target_aura, effect=0))
    return steps, before_label, after_label


def amount_delta_scenario(class_file: dict, spec: AmountDeltaSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'amount_delta', spec.quote, spec.fraction)
    class_file = armed_for(class_file, records, spec.trigger_spell)
    facts_trigger = facts_of(records, spec.trigger_spell)
    striker = {'id': STRIKER, 'owner': CASTER, 'entry': spec.striker_entry, 'level': class_file['level'],
              'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 1, 'spell_hit_bonus': 100}
    without_steps, without_before, without_after = amount_delta_phase_steps(spec, facts_trigger, 'without')
    with_steps, with_before, with_after = amount_delta_phase_steps(spec, facts_trigger, 'with')
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}] \
        + without_steps + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + with_steps
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour amount delta',
        'contract': f'A striker (creature entry {spec.striker_entry}, forced to hit) casts {spec.breaker_spell} '
                    f'directly at the caster, who carries {spec.debt_aura}, to apply a nonzero debt to '
                    f'{spec.target_aura}; {spec.target_aura}\'s aura_amount effect 0 is read before and after a '
                    f'cast of {spec.trigger_spell}, once before {spec.name} is learned (the '
                    f'`{spec.mechanism_file}` `{spec.reduce_function}` call is gated on the passive and must leave '
                    f'the amount unchanged) and once after (must drop by {spec.fraction:.0%}, truncating integer '
                    f'division), each phase re-establishing its own debt from a fresh striker hit rather than '
                    f'reusing one amount across phases. The wait after the cast is kept at '
                    f'{AMOUNT_DELTA_CAST_WAIT_MS} ms, well under {spec.target_aura}\'s own 1000 ms periodic tick '
                    f'(EffectAmplitude[0] of {spec.target_aura}, which releases part of the staggered debt on its '
                    f'own schedule regardless of {spec.mechanism_label}), so neither read straddles a natural tick '
                    f'and the measured delta is attributable only to the cast.',
        'players': [player_fixture(class_file)],
        'creatures': [striker],
        'steps': steps}
    label = f'{spec.spell} behaviour_amount_delta'
    model = {'kind': 'amount_delta', 'without_before_label': without_before, 'without_after_label': without_after,
             'with_before_label': with_before, 'with_after_label': with_after, 'fraction': spec.fraction,
             'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_AMOUNT_DELTA, spec.spell, spec.target_aura, None,
                              str(spec.fraction), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def amount_delta_spec(entry: dict) -> AmountDeltaSpec:
    return AmountDeltaSpec(entry['spell'], entry['name'], entry['quote'], entry['fraction'], entry['target_aura'],
                           entry['debt_aura'], entry['breaker_spell'], entry['striker_entry'],
                           entry['trigger_spell'], entry['mechanism_file'], entry['reduce_function'],
                           entry['mechanism_label'])


@dataclass(frozen=True)
class CritGuaranteeSpec:
    spell: int
    name: str
    quote: str
    trial_spell: int
    target_entry: int
    target_type: int
    target_type_name: str
    attempts: int = CRIT_GUARANTEE_ATTEMPTS
    minimum_events: int = CRIT_GUARANTEE_MINIMUM_EVENTS


def crit_guarantee_labels(spec: CritGuaranteeSpec) -> tuple[str, str]:
    return (f'{spec.spell} {spec.trial_spell} crit_guarantee crit',
            f'{spec.spell} {spec.trial_spell} crit_guarantee noncrit')


def crit_guarantee_scenario(class_file: dict, spec: CritGuaranteeSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'crit_guarantee', spec.quote, 1.0)
    crit_label, noncrit_label = crit_guarantee_labels(spec)
    attempt_ms = swing_interval(class_file)
    waited_ms = spec.attempts * attempt_ms
    target = {**creature_fixture(class_file), 'entry': spec.target_entry, 'reaction': 0}
    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
             {'action': 'attack', 'actor': CASTER, 'target': TARGET},
             {'action': 'wait', 'label': 'swings', 'ms': waited_ms},
             {'action': 'stop_attack', 'actor': CASTER},
             {'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS},
             measurement(crit_label, CASTER, 'spell_damage_count', spell=spec.trial_spell, target=TARGET,
                        critical=True),
             measurement(noncrit_label, CASTER, 'spell_damage_count', spell=spec.trial_spell, target=TARGET,
                        critical=False)])
    scenario = {'schema': 1,
               'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour crit guarantee',
               'contract': f'{spec.attempts} auto-attack swings against a {spec.target_type_name} target '
                           f'(creature_template.type {spec.target_type}, entry {spec.target_entry}); every '
                           f'triggered hit of {spec.trial_spell} logged against it must be critical.',
               'players': [player_fixture(class_file)], 'creatures': [target], 'steps': steps,
               'timeout_ms': waited_ms + TIMEOUT_MARGIN_MS}
    label = f'{spec.spell} behaviour_crit_guarantee {spec.trial_spell}'
    model = {'crit_label': crit_label, 'noncrit_label': noncrit_label, 'minimum_events': spec.minimum_events,
            'trial_spell': spec.trial_spell, 'target_name': f'{spec.target_type_name} (entry {spec.target_entry})',
            'creature_type_source': f'creature_template.type {spec.target_type} ({spec.target_type_name})',
            'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_CRIT_GUARANTEE, spec.spell, spec.trial_spell, None, '1.0',
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def crit_guarantee_spec(entry: dict) -> CritGuaranteeSpec:
    return CritGuaranteeSpec(entry['spell'], entry['name'], entry['quote'], entry['trial_spell'],
                             entry['target_entry'], entry['target_type'], entry['target_type_name'],
                             entry.get('attempts', CRIT_GUARANTEE_ATTEMPTS),
                             entry.get('minimum_events', CRIT_GUARANTEE_MINIMUM_EVENTS))


AURA_GRANT_SETTLE_MS = 500
DEFAULT_CHAIN_AURA = 704576


@dataclass(frozen=True)
class AuraGrantSpec:
    spell: int
    name: str
    quote: str
    trigger_spell: int
    oath_aura: int
    chain_aura: int = DEFAULT_CHAIN_AURA


def aura_grant_label(spec: AuraGrantSpec, moment: str) -> str:
    return f'{spec.chain_aura} amount grant {spec.spell} {moment}'


def aura_grant_scenario(class_file: dict, spec: AuraGrantSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'aura_grant', spec.quote, 1)
    class_file = armed_for(class_file, records, spec.trigger_spell)
    facts = facts_of(records, spec.trigger_spell)
    before_label = aura_grant_label(spec, BEFORE)
    after_label = aura_grant_label(spec, AFTER)
    oath_label = f'{spec.oath_aura} aura grant {spec.spell} after'
    steps = []
    if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost})
    steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
    steps += required_aura_steps(facts)
    steps.append(measurement(before_label, CASTER, 'aura_stacks', spell=spec.chain_aura))
    steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET})
    steps.append({'action': 'wait', 'ms': AURA_GRANT_SETTLE_MS})
    steps.append(measurement(after_label, CASTER, 'aura_stacks', spell=spec.chain_aura))
    steps.append(measurement(oath_label, CASTER, 'aura', spell=spec.oath_aura))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura grant',
        'contract': f'A single cast of {spec.trigger_spell} against a fresh target, by a caster holding no prior '
                    f'Oath, grants Oath aura {spec.oath_aura} and increases the Oath Chain ({spec.chain_aura}) '
                    f'stack by exactly 1, read via aura_stacks before and after the cast.',
        'players': [player_fixture(class_file)], 'creatures': [creature_fixture(class_file)],
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}]
                 + steps}
    label = f'{spec.spell} behaviour_aura_grant'
    model = {'kind': 'aura_grant', 'before_label': before_label, 'after_label': after_label,
            'oath_label': oath_label, 'oath_aura': spec.oath_aura, 'chain_aura': spec.chain_aura, 'expected': 1,
            'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_AURA_GRANT, spec.spell, spec.trigger_spell, None, '1',
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def aura_grant_spec(entry: dict) -> AuraGrantSpec:
    return AuraGrantSpec(entry['spell'], entry['name'], entry['quote'], entry['trigger_spell'], entry['oath_aura'],
                        entry.get('chain_aura', DEFAULT_CHAIN_AURA))


MECHANIC_DR_RESET_MS = 15000
MECHANIC_GAP_MARGIN_MS = 2000
MECHANIC_LAND_ATTEMPTS = 3
MECHANIC_RETRY_WAIT_MS = 500


@dataclass(frozen=True)
class MechanicDurationSpec:
    spell: int
    name: str
    quote: str
    expected_ratio: float
    vehicle_spell: int
    striker_entry: int = 36


def mechanic_duration_label(spec: MechanicDurationSpec, moment: str) -> str:
    return f'{spec.spell} {spec.vehicle_spell} duration {moment}'


def mechanic_duration_scenario(class_file: dict, spec: MechanicDurationSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'ratio', spec.quote, spec.expected_ratio)
    striker = {'id': STRIKER, 'owner': CASTER, 'entry': spec.striker_entry, 'level': class_file['level'],
              'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 1, 'spell_hit_bonus': 100}
    before_label = mechanic_duration_label(spec, BEFORE)
    after_label = mechanic_duration_label(spec, AFTER)
    unreduced_ms = records.duration_ms(spec.vehicle_spell)
    gap_ms = int(unreduced_ms) + MECHANIC_DR_RESET_MS + MECHANIC_GAP_MARGIN_MS

    def phase(label: str) -> list[dict]:
        steps = [{'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0}]
        for attempt in range(MECHANIC_LAND_ATTEMPTS):
            steps.append({'action': 'cast', 'actor': STRIKER, 'spell': spec.vehicle_spell, 'target': CASTER})
            if attempt < MECHANIC_LAND_ATTEMPTS - 1:
                steps.append({'action': 'wait', 'label': f'{spec.spell} {label} land attempt {attempt + 1}',
                             'ms': MECHANIC_RETRY_WAIT_MS})
        steps.append({'action': 'wait', 'label': f'{spec.spell} {label} settle', 'ms': CAST_MARGIN_MS})
        steps.append(measurement(label, CASTER, 'aura_duration_ms', spell=spec.vehicle_spell))
        return steps

    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour duration ratio',
        'contract': f'The caster\'s dodge and parry chance are forced to 0 (set_combat_avoidance, a Player-only '
                    f'fixture overriding Player::m_realDodge/m_realParry directly, the same fields '
                    f'Unit::MeleeSpellHitResult reads via GetUnitDodgeChance/GetUnitParryChance) before a striker '
                    f'(creature entry {spec.striker_entry}, spell_hit_bonus forced to 100) casts '
                    f'{spec.vehicle_spell} directly at the caster up to {MECHANIC_LAND_ATTEMPTS} times '
                    f'(DmgClass SPELL_DAMAGE_CLASS_MELEE: spell_hit_bonus only removes the miss roll, not the '
                    f'separate dodge/parry roll of the melee combat table, so without this override a single cast '
                    f'could still land on no one; the retries stay as a safety margin, no longer load-bearing); '
                    f'{spec.vehicle_spell} does not stack and refreshes to its full duration on every landed '
                    f'cast, so whichever of the attempts lands last is what the final read reflects, with '
                    f'{MECHANIC_RETRY_WAIT_MS} ms between attempts), once before {spec.name} is learned and once '
                    f'after, reading the applied aura\'s aura_duration_ms each time (the live, decrementing '
                    f'remaining duration, consistent across both reads since each is taken after the same '
                    f'{CAST_MARGIN_MS} ms settle wait from the last attempt, with the judge\'s own margin sized '
                    f'on that settle window to absorb the ms-level jitter of exactly when each cast\'s effect '
                    f'actually lands), with a {gap_ms} ms gap between the two phases so the {spec.vehicle_spell} '
                    f'aura has fully expired and a {MECHANIC_DR_RESET_MS} ms margin has passed, a conservative '
                    f'allowance against this vehicle possibly carrying its own stock diminishing-returns '
                    f'reduction against a non-player caster (SpellMgr.cpp), which is not assumed to apply (each '
                    f'vehicle\'s actual diminishing-returns group must be checked on its own, not inferred from '
                    f'its mechanic alone) but costs nothing if it does not, so neither reading risks being '
                    f'itself diminished.',
        'players': [player_fixture(class_file)],
        'creatures': [striker],
        'steps': base_steps(class_file) + phase(before_label) +
                 [{'action': 'wait', 'label': f'{spec.spell} let the vehicle aura and its DR window expire',
                  'ms': gap_ms},
                 {'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + phase(after_label)}
    label = f'{spec.spell} behaviour_duration_ratio'
    model = {'kind': 'duration_ratio', 'before_label': before_label, 'after_label': after_label,
             'expected': spec.expected_ratio, 'quote': entry.quote, 'target_name': spec.name,
             'vehicle_spell': spec.vehicle_spell}
    expectation = Expectation(label, BEHAVIOUR_DURATION_RATIO, spec.spell, spec.vehicle_spell, None,
                              str(spec.expected_ratio), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def mechanic_duration_spec(entry: dict) -> MechanicDurationSpec:
    return MechanicDurationSpec(entry['spell'], entry['name'], entry['quote'], entry['expected_ratio'],
                                entry['vehicle_spell'], entry.get('striker_entry', 36))


DEFAULT_DURATION_REFRESH_DECAY_MS = 4000
DEFAULT_DURATION_REFRESH_MARGIN_MS = 500


@dataclass(frozen=True)
class DurationRefreshSpec:
    spell: int
    name: str
    quote: str
    target_aura: int
    gating_aura: int
    gating_stacks: int
    apply_spell: int
    breaker_spell: int
    decay_ms: int = DEFAULT_DURATION_REFRESH_DECAY_MS
    refresh_margin_ms: int = DEFAULT_DURATION_REFRESH_MARGIN_MS


def duration_refresh_label(spec: DurationRefreshSpec, phase: str, moment: str) -> str:
    return f'{spec.target_aura} duration {phase} {moment}'


def duration_refresh_phase_steps(spec: DurationRefreshSpec, facts_apply, facts_breaker, phase: str) -> list[dict]:
    before_label = duration_refresh_label(spec, phase, BEFORE)
    after_label = duration_refresh_label(spec, phase, AFTER)
    return [
        {'action': 'set_aura', 'actor': CASTER, 'spell': spec.gating_aura, 'stacks': 1},
        {'action': 'set_power', 'actor': CASTER, 'power': facts_apply.power_type, 'value': facts_apply.mana_cost},
        {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.apply_spell},
        {'action': 'cast', 'actor': CASTER, 'spell': spec.apply_spell, 'target': TARGET},
        {'action': 'wait', 'label': f'{phase} decay', 'ms': spec.decay_ms},
        measurement(before_label, TARGET, 'aura_duration_ms', spell=spec.target_aura, caster=CASTER),
        {'action': 'set_aura', 'actor': CASTER, 'spell': spec.gating_aura, 'stacks': spec.gating_stacks},
        {'action': 'set_power', 'actor': CASTER, 'power': facts_breaker.power_type, 'value': facts_breaker.mana_cost},
        {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.breaker_spell},
        {'action': 'cast', 'actor': CASTER, 'spell': spec.breaker_spell, 'target': TARGET},
        measurement(after_label, TARGET, 'aura_duration_ms', spell=spec.target_aura, caster=CASTER),
    ]


def duration_refresh_scenario(class_file: dict, spec: DurationRefreshSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    full_duration_ms = records.duration_ms(spec.target_aura)
    entry = behaviour_entry(records, spec.spell, spec.name, 'duration_refresh', spec.quote, full_duration_ms)
    class_file = armed_for(class_file, records, spec.breaker_spell)
    facts_apply = facts_of(records, spec.apply_spell)
    facts_breaker = facts_of(records, spec.breaker_spell)
    target = creature_fixture(class_file)
    without_before = duration_refresh_label(spec, 'without', BEFORE)
    without_after = duration_refresh_label(spec, 'without', AFTER)
    with_before = duration_refresh_label(spec, 'with', BEFORE)
    with_after = duration_refresh_label(spec, 'with', AFTER)
    steps = base_steps(class_file) + [
        {'action': 'learn', 'actor': CASTER, 'spell': spec.apply_spell},
        {'action': 'learn', 'actor': CASTER, 'spell': spec.breaker_spell},
    ]
    steps += duration_refresh_phase_steps(spec, facts_apply, facts_breaker, 'without')
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
    steps += duration_refresh_phase_steps(spec, facts_apply, facts_breaker, 'with')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour duration refresh',
        'contract': f'No-combat with/without check: {spec.apply_spell} is cast on the target, left to decay '
                    f'{spec.decay_ms} ms, then {spec.breaker_spell} is cast at {spec.gating_stacks} stacks of '
                    f'{spec.gating_aura}; {spec.target_aura}\'s aura_duration_ms is read before and after the '
                    f'breaker cast, once before {spec.name} is learned (must keep decaying, no refresh) and once '
                    f'after (must return to within {spec.refresh_margin_ms} ms of its own {full_duration_ms:g} ms '
                    f'full duration, read from SpellDuration.dbc).',
        'players': [player_fixture(class_file)],
        'creatures': [target],
        'steps': steps}
    label = f'{spec.spell} behaviour_duration_refresh'
    model = {'kind': 'duration_refresh', 'without_before_label': without_before, 'without_after_label': without_after,
             'with_before_label': with_before, 'with_after_label': with_after, 'full_duration_ms': full_duration_ms,
             'refresh_margin_ms': spec.refresh_margin_ms, 'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_DURATION_REFRESH, spec.spell, spec.target_aura, None,
                              str(full_duration_ms), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def duration_refresh_spec(entry: dict) -> DurationRefreshSpec:
    return DurationRefreshSpec(entry['spell'], entry['name'], entry['quote'], entry['target_aura'],
                               entry['gating_aura'], entry['gating_stacks'], entry['apply_spell'],
                               entry['breaker_spell'], entry.get('decay_ms', DEFAULT_DURATION_REFRESH_DECAY_MS),
                               entry.get('refresh_margin_ms', DEFAULT_DURATION_REFRESH_MARGIN_MS))


def behaviour_scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    if entry['kind'] == 'count':
        return target_count_scenario(class_file, target_count_spec(entry))
    if entry['kind'] == 'ratio':
        return healing_ratio_scenario(class_file, healing_ratio_spec(entry))
    if entry['kind'] == 'leech_ratio':
        return leech_ratio_scenario(class_file, leech_ratio_spec(entry))
    if entry['kind'] == 'spread':
        return aura_spread_scenario(class_file, aura_spread_spec(entry))
    if entry['kind'] == 'trigger':
        return shield_break_trigger_scenario(class_file, shield_break_trigger_spec(entry))
    if entry['kind'] == 'metric_delta':
        return metric_delta_scenario(class_file, metric_delta_spec(entry))
    if entry['kind'] == 'health_ratio':
        return health_threshold_ratio_scenario(class_file, health_ratio_spec(entry))
    if entry['kind'] == 'duration':
        return duration_scenario(class_file, duration_spec(entry))
    if entry['kind'] == 'duration_ratio':
        return mechanic_duration_scenario(class_file, mechanic_duration_spec(entry))
    if entry['kind'] == 'duration_refresh':
        return duration_refresh_scenario(class_file, duration_refresh_spec(entry))
    if entry['kind'] == 'amount_delta':
        return amount_delta_scenario(class_file, amount_delta_spec(entry))
    if entry['kind'] == 'crit_guarantee':
        return crit_guarantee_scenario(class_file, crit_guarantee_spec(entry))
    if entry['kind'] == 'aura_grant':
        return aura_grant_scenario(class_file, aura_grant_spec(entry))
    raise NotModelled(f'behaviour kind {entry["kind"]!r} has no scenario builder')


def behaviour_entries(class_file: dict, spell_ids: list[int] | None) -> list[dict]:
    entries = class_file.get('behaviours', [])
    if spell_ids is None:
        return entries
    chosen = [entry for entry in entries if entry['spell'] in spell_ids]
    unknown = set(spell_ids) - {entry['spell'] for entry in chosen}
    if unknown:
        raise ValueError(f'Spells {sorted(unknown)} are not {class_file["name"]} behaviour entries')
    return chosen
