from dataclasses import dataclass
from pathlib import Path
import re

from hits import creature_fixture
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import COLOR_CODE, Records
from values import CAST_MARGIN_MS, Expectation, TARGET, dataset, facts_of, required_aura_steps

BEHAVIOUR_COUNT = 'behaviour_count'
BEHAVIOUR_RATIO = 'behaviour_ratio'
BEHAVIOUR_DURATION = 'behaviour_duration'
BEHAVIOUR_TRIGGER = 'behaviour_trigger'
BEHAVIOUR_METRIC_DELTA = 'behaviour_metric_delta'
BEHAVIOUR_CHECKS = (BEHAVIOUR_COUNT, BEHAVIOUR_RATIO, BEHAVIOUR_DURATION, BEHAVIOUR_TRIGGER, BEHAVIOUR_METRIC_DELTA)
KINDS = ('count', 'ratio', 'duration', 'trigger', 'metric_delta')
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
        'steps': base_steps(class_file) + cast_steps() + measure(BEFORE) +
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
        return f'{spec.spell} {target.spell} spell_healing_done {moment}'

    def cast_all() -> list[dict]:
        steps = []
        for target in spec.targets:
            if target.method != 'cast':
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


HEALTH_RATIO_MAX_HEALTH = 10000


@dataclass(frozen=True)
class HealthRatioSpec:
    spell: int
    name: str
    quote: str
    probe_spell: int
    levels: tuple[tuple[int, float], ...]


def health_ratio_label(spec: HealthRatioSpec, health_pct: int, moment: str) -> str:
    return f'{spec.spell} {health_pct} script_spell_damage_taken {moment}'


def health_ratio_set_health_step(health_pct: int) -> dict:
    value = (health_pct * HEALTH_RATIO_MAX_HEALTH) // 100
    return {'action': 'set_health', 'actor': CASTER, 'value': value, 'maximum': HEALTH_RATIO_MAX_HEALTH}


def health_threshold_ratio_scenario(class_file: dict, spec: HealthRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'ratio', spec.quote, spec.levels[0][1])

    def measure(moment: str) -> list[dict]:
        steps = []
        for health_pct, _ in spec.levels:
            steps.append(health_ratio_set_health_step(health_pct))
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


def metric_delta_label(spec: MetricDeltaSpec, moment: str) -> str:
    return f'{spec.spell} {spec.metric} {moment}'


def metric_delta_scenario(class_file: dict, spec: MetricDeltaSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
    facts = facts_of(records, spec.trigger_spell)

    def cast_steps() -> list[dict]:
        steps = []
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
        steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
        steps += required_aura_steps(facts)
        steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': CASTER})
        steps.append({'action': 'wait', 'ms': spec.wait_ms})
        return steps

    before_label = metric_delta_label(spec, BEFORE)
    after_label = metric_delta_label(spec, AFTER)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour metric delta',
        'contract': f'No-combat with/without check: {spec.metric} {spec.fields} around a cast of {spec.trigger_spell},'
                    f' measured before and after the passive is learned, waiting {spec.expire_ms} ms between phases '
                    f'for the first cast\'s effect to fully expire before the second cast.',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}] +
                 cast_steps() + [measurement(before_label, CASTER, spec.metric, **spec.fields)] +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] +
                 [{'action': 'wait', 'label': 'let the first effect fully expire', 'ms': spec.expire_ms}] +
                 cast_steps() + [measurement(after_label, CASTER, spec.metric, **spec.fields)]}
    label = f'{spec.spell} behaviour_metric_delta'
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
                           entry.get('expire_ms', DEFAULT_METRIC_DELTA_EXPIRE_MS))


def behaviour_scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    if entry['kind'] == 'count':
        return target_count_scenario(class_file, target_count_spec(entry))
    if entry['kind'] == 'ratio':
        return healing_ratio_scenario(class_file, healing_ratio_spec(entry))
    if entry['kind'] == 'spread':
        return aura_spread_scenario(class_file, aura_spread_spec(entry))
    if entry['kind'] == 'trigger':
        return shield_break_trigger_scenario(class_file, shield_break_trigger_spec(entry))
    if entry['kind'] == 'metric_delta':
        return metric_delta_scenario(class_file, metric_delta_spec(entry))
    if entry['kind'] == 'health_ratio':
        return health_threshold_ratio_scenario(class_file, health_ratio_spec(entry))
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
