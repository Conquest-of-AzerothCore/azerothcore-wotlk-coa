from dataclasses import dataclass, replace
import math
from pathlib import Path
import re

from hits import (ARMOR_LABEL, DRAIN_MS, HEAL_KINDS, MAIN_HAND, MAX_ACCELERATED_SCENARIO_MS, MAX_SCENARIO_MS,
                  TIMEOUT_MARGIN_MS, VIEW_LEVEL_LABEL, Unmodelled, aura_modifiers, cast_steps, creature_fixture,
                  SCHOOL_DAMAGE, magic_schools, model_record, reference_script_hit_model, resistance_label, timed)
from procs import cast_interval, swing_interval
from profile import (CASTER, DBC_DIR, DISPEL_TYPE_NAMES, base_steps, measurement, off_hand_steps, off_hand_weapon,
                     one_hand_main, player_fixture)
from tooltip import COLOR_CODE, SKILL_PER_LEVEL, CasterStats, Records, Tooltip
from values import (ALLY, CAST_MARGIN_MS, CHARGE_OFFSET_YD, DUMMY_ENTRY, FORCE_CRIT_RATINGS, FORCED_CRIT_RATING,
                    GCD_WAIT_MS, Expectation, TARGET, armed_for, closes_distance, dataset, facts_of,
                    FIXTURE_MAX_HEALTH, fixture_health_step, required_aura_steps,
                    required_target_health_steps)

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
BEHAVIOUR_OATH_CONSUMPTION = 'behaviour_oath_consumption'
BEHAVIOUR_OATH_CONSUMPTION_REMOVAL = 'behaviour_oath_consumption_removal'
BEHAVIOUR_INTERNAL_COOLDOWN_GATE = 'behaviour_internal_cooldown_gate'
BEHAVIOUR_EXCLUSIVITY = 'behaviour_exclusivity'
BEHAVIOUR_GROUP_STACK_CAP = 'behaviour_group_stack_cap'
BEHAVIOUR_SINGLE_TARGET = 'behaviour_single_target'
BEHAVIOUR_CRIT_MAGNITUDE = 'behaviour_crit_magnitude'
BEHAVIOUR_CHARGE_RECHARGE = 'behaviour_charge_recharge'
BEHAVIOUR_FIXED_COUNT = 'behaviour_fixed_count'
BEHAVIOUR_PARTY_STAT_RATIO = 'behaviour_party_stat_ratio'
BEHAVIOUR_CAST_GATE = 'behaviour_cast_gate'
BEHAVIOUR_CAST_CONDITION = 'behaviour_cast_condition'
BEHAVIOUR_MOUNT_GRANT = 'behaviour_mount_grant'
BEHAVIOUR_INTERNAL_COOLDOWN = 'behaviour_internal_cooldown'
BEHAVIOUR_CAST_COMBAT = 'behaviour_cast_combat'
BEHAVIOUR_AGGRO_REDIRECT = 'behaviour_aggro_redirect'
BEHAVIOUR_HEAL_BLOCK = 'behaviour_heal_block'
BEHAVIOUR_CAST_APPLIES_AURA = 'behaviour_cast_applies_aura'
BEHAVIOUR_METRIC_RATIO_DELTA = 'behaviour_metric_ratio_delta'
BEHAVIOUR_ABSORB_PIERCE_RATIO = 'behaviour_absorb_pierce_ratio'
BEHAVIOUR_HIT_RATIO = 'behaviour_hit_ratio'
BEHAVIOUR_IMMUNITY = 'behaviour_immunity'
BEHAVIOUR_THREAT_SLOPE = 'behaviour_threat_slope'
BEHAVIOUR_EVENT_DELAY = 'behaviour_event_delay'
BEHAVIOUR_PROC_RESET = 'behaviour_proc_reset'
BEHAVIOUR_TAKEN_HIT = 'behaviour_taken_hit'
BEHAVIOUR_THREAT_REDIRECT = 'behaviour_threat_redirect'
BEHAVIOUR_DISPEL_COUNT = 'behaviour_dispel_count'
BEHAVIOUR_TAKEN_OUTCOME = 'behaviour_taken_outcome'
BEHAVIOUR_FALL_DAMAGE = 'behaviour_fall_damage'
BEHAVIOUR_CRIT_RATE = 'behaviour_crit_rate'
BEHAVIOUR_AMOUNT_MATCH = 'behaviour_amount_match'
BEHAVIOUR_SOURCE_STACK = 'behaviour_source_stack'
BEHAVIOUR_CHECKS = (BEHAVIOUR_COUNT, BEHAVIOUR_RATIO, BEHAVIOUR_DURATION, BEHAVIOUR_DURATION_RATIO, BEHAVIOUR_TRIGGER,
                    BEHAVIOUR_METRIC_DELTA, BEHAVIOUR_DURATION_REFRESH, BEHAVIOUR_AMOUNT_DELTA,
                    BEHAVIOUR_CRIT_GUARANTEE, BEHAVIOUR_AURA_GRANT, BEHAVIOUR_OATH_CONSUMPTION,
                    BEHAVIOUR_OATH_CONSUMPTION_REMOVAL, BEHAVIOUR_INTERNAL_COOLDOWN_GATE, BEHAVIOUR_EXCLUSIVITY,
                    BEHAVIOUR_GROUP_STACK_CAP, BEHAVIOUR_SINGLE_TARGET, BEHAVIOUR_CRIT_MAGNITUDE,
                    BEHAVIOUR_CHARGE_RECHARGE, BEHAVIOUR_FIXED_COUNT, BEHAVIOUR_PARTY_STAT_RATIO,
                    BEHAVIOUR_CAST_GATE, BEHAVIOUR_CAST_CONDITION, BEHAVIOUR_MOUNT_GRANT,
                    BEHAVIOUR_INTERNAL_COOLDOWN, BEHAVIOUR_CAST_COMBAT, BEHAVIOUR_AGGRO_REDIRECT,
                    BEHAVIOUR_HEAL_BLOCK, BEHAVIOUR_CAST_APPLIES_AURA, BEHAVIOUR_METRIC_RATIO_DELTA,
                    BEHAVIOUR_ABSORB_PIERCE_RATIO, BEHAVIOUR_HIT_RATIO, BEHAVIOUR_IMMUNITY, BEHAVIOUR_THREAT_SLOPE,
                    BEHAVIOUR_EVENT_DELAY, BEHAVIOUR_PROC_RESET, BEHAVIOUR_TAKEN_HIT, BEHAVIOUR_THREAT_REDIRECT,
                    BEHAVIOUR_DISPEL_COUNT, BEHAVIOUR_TAKEN_OUTCOME, BEHAVIOUR_CRIT_RATE, BEHAVIOUR_AMOUNT_MATCH,
                    BEHAVIOUR_SOURCE_STACK, BEHAVIOUR_FALL_DAMAGE)
KINDS = ('count', 'ratio', 'duration', 'duration_ratio', 'trigger', 'metric_delta', 'duration_refresh',
        'amount_delta', 'crit_guarantee', 'aura_grant', 'oath_consumption', 'oath_consumption_removal',
        'internal_cooldown_gate', 'exclusivity', 'group_stack_cap', 'single_target', 'crit_magnitude',
        'charge_recharge', 'fixed_count', 'party_stat_ratio', 'cast_gate', 'cast_condition', 'mount_grant',
        'internal_cooldown', 'cast_combat', 'aggro_redirect', 'dispel_removal', 'aura_presence', 'heal_block',
        'aura_metric_delta', 'cast_applies_aura', 'cast_stat_ratio', 'threat_tick_ratio', 'absorb_pierce_ratio',
        'hit_ratio', 'cast_state', 'immunity', 'threat_slope', 'group_target', 'cost_gate', 'site_purchase',
        'periodic_dispel', 'event_delay', 'proc_reset', 'taken_hit', 'threat_redirect', 'dispel_count',
        'script_hit', 'taken_outcome', 'charm_immunity', 'school_lockout', 'crit_rate', 'amount_match', 'detection',
        'source_stack', 'mount_block', 'stat_gain', 'fall_damage', 'flee_block')
CRIT_GUARANTEE_ATTEMPTS = 100
CRIT_GUARANTEE_MINIMUM_EVENTS = 5
CRIT_GUARANTEE_CONTROL_TARGET = 'dummy_control'
CRIT_GUARANTEE_CONTROL_MAX_RATIO = 0.9
PROSE = 'prose: '
BEFORE = 'before'
AFTER = 'after'
LEARNED_CONTRAST = 'learned'
CONDITION_CONTRAST = 'condition'
HEALING_RATIO_METRICS = {'effect_value': 'spell_effect_value', 'taken': 'spell_healing_taken'}
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


def count_label_prefix(spec) -> str:
    suffix = getattr(spec, 'label_suffix', '')
    return f'{spec.spell} {suffix}' if suffix else f'{spec.spell}'


def hit_label(spell: TargetCountSpec, index: int, moment: str) -> str:
    return f'{count_label_prefix(spell)} {dummy_id(index)} {spell.metric} {moment}'


def per_cast_label(spec, index: int, cast: int) -> str:
    return hit_label(spec, index, f'cast {cast}')


def per_cast_reads(spec, dummy_count: int, cast: int) -> list[dict]:
    return [hit_measurement(spec, index, f'cast {cast}') for index in range(dummy_count)]


def per_cast_model(spec, dummy_count: int, start: str) -> dict | None:
    if spec.metric != 'spell_damage_count':
        return None
    return {'start': [hit_label(spec, index, start) for index in range(dummy_count)],
            'casts': [[per_cast_label(spec, index, cast) for index in range(dummy_count)]
                      for cast in range(1, spec.repeats + 1)]}


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
    dummy_count = spec.expected + 1 + COUNT_HEADROOM
    primary_distance = 3.0
    distances = [primary_distance] + [
        primary_distance + spec.radius * (index / dummy_count) for index in range(1, dummy_count)]
    creatures = [dummy_fixture(index, class_file, distances[index]) for index in range(dummy_count)]

    facts = facts_of(records, spec.target_rank)
    wait_ms = facts.cast_time_ms + CAST_MARGIN_MS
    per_cast = per_cast_model(spec, dummy_count, BEFORE)

    def cast_steps(read: bool = False) -> list[dict]:
        steps = []
        for cast in range(1, spec.repeats + 1):
            if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
                steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                             'value': facts.mana_cost})
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.target_rank})
            steps += required_aura_steps(facts)
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.target_rank, 'target': dummy_id(0)})
            steps.append({'action': 'wait', 'ms': wait_ms})
            if read and per_cast:
                steps += per_cast_reads(spec, dummy_count, cast)
        return steps

    def measure(moment: str) -> list[dict]:
        return [hit_measurement(spec, index, moment) for index in range(dummy_count)]

    before_labels = [hit_label(spec, index, BEFORE) for index in range(1, dummy_count)]
    after_labels = [hit_label(spec, index, AFTER) for index in range(1, dummy_count)]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour count',
        'contract': f'{spec.repeats} casts per phase, "ever hit at least once" per dummy rather than a single-'
                    f'cast snapshot, {spec.expected + COUNT_HEADROOM} candidates inside the radius for '
                    f'{spec.expected} stated: {spec.radius_reason}',
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.target_rank}] +
                 cast_steps() + measure(BEFORE) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + cast_steps(read=True) +
                 measure(AFTER)}
    label = f'{spec.spell} behaviour_count'
    model = {'kind': 'count', 'dummy_labels': list(zip(before_labels, after_labels)), 'expected': spec.expected,
             'headroom': COUNT_HEADROOM, 'quote': entry.quote}
    if per_cast:
        model['per_cast'] = per_cast
    expectation = Expectation(label, BEHAVIOUR_COUNT, spec.spell, spec.target_rank, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


@dataclass(frozen=True)
class FixedTargetCountSpec:
    spell: int
    name: str
    quote: str
    expected: int
    radius: float
    radius_reason: str
    cast_spell: int = 0
    target_rank: int = 0
    metric: str = 'spell_damage_count'
    repeats: int = 5
    clear_auras: tuple[int, ...] = ()
    cast_target: str = TARGET
    cast_target_health_pct: int | None = None
    learn: tuple[int, ...] = ()
    uncapped: bool = False
    auras: tuple[tuple[int, int], ...] = ()
    pull_reads: bool = False
    settle_ms: int = 0
    layout: str = ''
    headroom: int | None = None
    far_dummy: bool = True
    primary_distance_reads: bool = False
    label_suffix: str = ''
    behind_yd: float | None = None
    cluster_yd: float | None = None

    def __post_init__(self):
        if not self.cast_spell:
            object.__setattr__(self, 'cast_spell', self.spell)
        if not self.target_rank:
            object.__setattr__(self, 'target_rank', self.cast_spell)


FIXED_COUNT_FAR_MARGIN_YD = 5.0
PULL_MINIMUM_YD = 1.0
PULL_STILL_YD = 0.5


def pull_label(spec, index: int, moment: str) -> str:
    return f'{spec.spell} {dummy_id(index)} distance {moment}'
COUNT_HEADROOM = 1


def fixed_target_count_scenario(class_file: dict, spec: FixedTargetCountSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'fixed_count', spec.quote, spec.expected)
    if spec.cast_target not in (TARGET, CASTER):
        raise ValueError(f'{spec.spell} fixed_count casts at {TARGET} or {CASTER}, not {spec.cast_target!r}')
    if spec.layout not in ('', CASTER) or spec.settle_ms < 0:
        raise ValueError(f'{spec.spell} fixed_count layout {spec.layout!r} is not the caster, or its settle is '
                         f'negative')
    if spec.headroom is not None and (spec.uncapped or spec.headroom < 1):
        raise ValueError(f'{spec.spell} fixed_count states a headroom of {spec.headroom} for a capped count only')
    if not spec.far_dummy and spec.pull_reads:
        raise ValueError(f'{spec.spell} fixed_count reads pulls against a far dummy it does not place')
    if spec.behind_yd is not None and not 0 < spec.behind_yd <= spec.radius:
        raise ValueError(f'{spec.spell} fixed_count behind_yd {spec.behind_yd!r} must lie inside the radius '
                         f'{spec.radius:g} yd, where only the facing keeps it unhit')
    if spec.cluster_yd is not None and (spec.cast_target == CASTER or spec.layout == CASTER
                                        or not 0 < spec.cluster_yd < spec.radius or not spec.primary_distance_reads):
        raise ValueError(f'{spec.spell} fixed_count clusters its dummies within {spec.cluster_yd} yd of the primary '
                         f'only around a target, inside the radius and with the primary distances read')
    headroom = 0 if spec.uncapped else (COUNT_HEADROOM if spec.headroom is None else spec.headroom)
    dummy_count = spec.expected + 1 + headroom
    if spec.cast_target == CASTER or spec.layout == CASTER:
        distances = [spec.radius * (index + 1) / (dummy_count + 1) for index in range(dummy_count)]
        distances.append(spec.radius + FIXED_COUNT_FAR_MARGIN_YD)
    else:
        primary_distance = 3.0
        spread = spec.radius if spec.cluster_yd is None else spec.cluster_yd
        distances = [primary_distance] + [
            primary_distance + spread * (index / dummy_count) for index in range(1, dummy_count)]
        distances.append(primary_distance + spec.radius + FIXED_COUNT_FAR_MARGIN_YD)
    far_index = dummy_count
    placed = far_index + 1 if spec.far_dummy else dummy_count
    distances = distances[:placed]
    relocation = []
    if spec.behind_yd is not None:
        shift = 2 * spec.behind_yd
        distances = [distance + shift for distance in distances] + [spec.behind_yd]
        relocation = [{'action': 'relocate', 'actor': CASTER, 'dx': shift}]
    last_index = len(distances) - 1
    creatures = [dummy_fixture(index, class_file, distances[index]) for index in range(last_index + 1)]
    primary_distances = [f'{spec.spell} {dummy_id(index)} distance_2d primary'
                         for index in range(1, dummy_count)] if spec.primary_distance_reads else []

    facts = facts_of(records, spec.cast_spell)
    wait_ms = facts.cast_time_ms + CAST_MARGIN_MS
    per_cast = per_cast_model(spec, dummy_count, 'cast 0')

    def distance_reads(moment: str) -> list[dict]:
        if not spec.pull_reads:
            return []
        return [measurement(pull_label(spec, index, moment), dummy_id(index), 'distance_2d', target=CASTER)
                for index in range(last_index + 1)]

    def cast_steps() -> list[dict]:
        steps = per_cast_reads(spec, dummy_count, 0) if per_cast else []
        steps += [measurement(label, dummy_id(index), 'distance_2d', target=dummy_id(0))
                  for index, label in enumerate(primary_distances, start=1)]
        steps += distance_reads(BEFORE)
        for cast in range(1, spec.repeats + 1):
            if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
                steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                             'value': facts.mana_cost})
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell})
            steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 0} for aura in spec.clear_auras]
            steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks}
                      for aura, stacks in spec.auras]
            steps += required_aura_steps(facts)
            if spec.cast_target_health_pct is not None:
                steps.append(fixture_health_step(spec.cast_target, spec.cast_target_health_pct))
            cast_target = dummy_id(0) if spec.cast_target == TARGET else spec.cast_target
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': cast_target})
            steps.append({'action': 'wait', 'ms': wait_ms})
            if spec.settle_ms:
                steps.append({'action': 'wait', 'label': f'cast {cast} settle', 'ms': spec.settle_ms})
            if per_cast:
                steps += per_cast_reads(spec, dummy_count, cast)
        return steps

    def measure() -> list[dict]:
        return distance_reads(AFTER) + [hit_measurement(spec, index, AFTER) for index in range(last_index + 1)]

    extra_labels = [hit_label(spec, index, AFTER) for index in range(1, dummy_count)]
    far_label = hit_label(spec, far_index, AFTER) if spec.far_dummy else None
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour fixed count',
        'contract': f'{spec.repeats} casts{" at the caster" if spec.cast_target == CASTER else ""}, "ever hit at '
                    f'least once" per dummy, single phase (the breadth is '
                    f'inherent to the cast, not gated by a separate passive learn), '
                    f'{spec.expected + headroom} candidates inside the radius for {spec.expected} stated, '
                    + (f'plus one dummy '
                       f'{FIXED_COUNT_FAR_MARGIN_YD:g} yd beyond the radius that must stay unhit, proving the limit '
                       f'and not only the count' if spec.far_dummy else 'with no dummy beyond the radius')
                    + (f', and one dummy {spec.behind_yd:g} yd behind the caster, inside the radius, that must stay '
                       f'unhit, proving the facing (every dummy spawns {2 * spec.behind_yd:g} yd further out and the '
                       f'caster steps that far forward along its facing before the casts)'
                       if spec.behind_yd is not None else '')
                    + f': {spec.radius_reason}',
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                                           for spell in dict.fromkeys((*spec.learn, spec.cast_spell))] +
                 relocation + cast_steps() + measure()}
    if spec.settle_ms:
        timed(scenario, waited_ms(scenario['steps']))
    label = f'{count_label_prefix(spec)} behaviour_fixed_count'
    within = spec.radius if spec.cluster_yd is None else spec.cluster_yd
    if primary_distances:
        scenario['contract'] += (f' Every additional dummy\'s distance to the primary is read before the casts and '
                                 f'must be under {within:g} yd.')
    model = {'kind': 'fixed_count', 'dummy_labels': extra_labels, 'far_label': far_label, 'expected': spec.expected,
             'headroom': headroom, 'quote': entry.quote}
    if spec.uncapped:
        model['all_offered'] = True
    if spec.behind_yd is not None:
        model['behind_label'] = hit_label(spec, last_index, AFTER)
    if per_cast:
        model['per_cast'] = per_cast
    if primary_distances:
        model.update({'primary_distances': primary_distances, 'radius': within})
    if spec.pull_reads:
        model['pull'] = {'near': [[pull_label(spec, index, BEFORE), pull_label(spec, index, AFTER)]
                                  for index in range(dummy_count)],
                         'far': [pull_label(spec, far_index, BEFORE), pull_label(spec, far_index, AFTER)],
                         'minimum_yd': PULL_MINIMUM_YD, 'still_yd': PULL_STILL_YD}
    expectation = Expectation(label, BEHAVIOUR_FIXED_COUNT, spec.spell, spec.target_rank, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


PARTY_STAT_RATIO_SETTLE_MS = 2000
PARTY_ALLY_NEAR_DISTANCE_YD = 3.0
PARTY_ALLY_FAR_MARGIN_YD = 15.0


@dataclass(frozen=True)
class PartyStatRatioSpec:
    spell: int
    name: str
    quote: str
    expected: float
    metric: str
    metric_fields: tuple[tuple[str, object], ...] = ()
    radius: float | None = None
    radius_reason: str = ''
    near_distance: float = PARTY_ALLY_NEAR_DISTANCE_YD
    far_margin: float = PARTY_ALLY_FAR_MARGIN_YD
    needs_dummy_target: bool = False
    settle_ms: int = PARTY_STAT_RATIO_SETTLE_MS


RELOCATE_STEP_LIMIT_YD = 20.0


def relocate_steps(actor: str, distance: float) -> list[dict]:
    steps = []
    remaining = distance
    while remaining > 0:
        chunk = min(remaining, RELOCATE_STEP_LIMIT_YD)
        steps.append({'action': 'relocate', 'actor': actor, 'dx': chunk})
        remaining -= chunk
    return steps


def party_ally_id(index: int) -> str:
    return 'ally' if index == 0 else 'ally_far'


def party_ally_fixture(index: int, class_file: dict) -> dict:
    fixture = player_fixture(class_file)
    fixture['id'] = party_ally_id(index)
    return fixture


def party_stat_label(spec: PartyStatRatioSpec, ally: str, moment: str) -> str:
    return f'{spec.spell} {ally} {spec.metric} {moment}'


def party_stat_measurement(spec: PartyStatRatioSpec, ally: str, moment: str) -> tuple[str, dict]:
    label = party_stat_label(spec, ally, moment)
    fields = dict(spec.metric_fields)
    if spec.needs_dummy_target:
        fields['target'] = dummy_id(0)
    return label, measurement(label, ally, spec.metric, **fields)


def party_stat_ratio_scenario(class_file: dict, spec: PartyStatRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'party_stat_ratio', spec.quote, spec.expected)
    far = spec.radius is not None
    allies = [party_ally_fixture(0, class_file)] + ([party_ally_fixture(1, class_file)] if far else [])
    creatures = [dummy_fixture(0, class_file, 5.0)] if spec.needs_dummy_target else []

    near_before_label, near_before_step = party_stat_measurement(spec, party_ally_id(0), BEFORE)
    near_after_label, near_after_step = party_stat_measurement(spec, party_ally_id(0), AFTER)
    far_before_label = far_after_label = None
    far_before_steps: list[dict] = []
    far_after_steps: list[dict] = []
    if far:
        far_before_label, far_before_step = party_stat_measurement(spec, party_ally_id(1), BEFORE)
        far_after_label, far_after_step = party_stat_measurement(spec, party_ally_id(1), AFTER)
        far_before_steps = [far_before_step]
        far_after_steps = [far_after_step]

    position_steps = relocate_steps(party_ally_id(0), spec.near_distance) + [
        {'action': 'group', 'actor': CASTER, 'target': party_ally_id(0)}]
    if far:
        position_steps += relocate_steps(party_ally_id(1), spec.radius + spec.far_margin) + [
            {'action': 'group', 'actor': CASTER, 'target': party_ally_id(1)}]

    radius_clause = (f'; a second ally beyond the {spec.radius:g} yd radius must show no change ('
                     f'{spec.radius_reason})') if far else '; raid- or party-wide, no distance token in the tooltip'
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour party stat ratio',
        'contract': f'No-combat with/without check: {spec.metric} measured on a grouped, non-caster ally before '
                    f'and after {spec.spell} is learned on the caster, settling {spec.settle_ms} ms for the aura '
                    f'to propagate{radius_clause}.',
        'players': [player_fixture(class_file)] + allies,
        'creatures': creatures,
        'steps': base_steps(class_file) + position_steps + [near_before_step] + far_before_steps +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                  {'action': 'wait', 'ms': spec.settle_ms}] +
                 [near_after_step] + far_after_steps}
    model = {'kind': 'party_stat_ratio', 'near_before_label': near_before_label,
             'near_after_label': near_after_label, 'far_before_label': far_before_label,
             'far_after_label': far_after_label, 'expected': spec.expected, 'metric': spec.metric,
             'quote': entry.quote}
    label = f'{spec.spell} behaviour_party_stat_ratio'
    expectation = Expectation(label, BEHAVIOUR_PARTY_STAT_RATIO, spec.spell, spec.spell, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def party_stat_ratio_spec(entry: dict) -> PartyStatRatioSpec:
    return PartyStatRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['metric'],
                              tuple(entry.get('metric_fields', {}).items()), entry.get('radius'),
                              entry.get('radius_reason', ''),
                              entry.get('near_distance', PARTY_ALLY_NEAR_DISTANCE_YD),
                              entry.get('far_margin', PARTY_ALLY_FAR_MARGIN_YD),
                              entry.get('needs_dummy_target', False),
                              entry.get('settle_ms', PARTY_STAT_RATIO_SETTLE_MS))


NEARBY_ALLY_DISTANCE_YD = 3.0
NEARBY_ALLY_TRIGGER_DISTANCE_YD = 3.0


def nearby_ally_id(index: int) -> str:
    return f'nearby_ally{index}'


def nearby_ally_fixture(index: int, class_file: dict) -> dict:
    fixture = player_fixture(class_file)
    fixture['id'] = nearby_ally_id(index)
    return fixture


@dataclass(frozen=True)
class AllyHealBreadthSpec:
    spell: int
    name: str
    quote: str
    expected: int
    heal_spell: int
    trigger_spell: int
    radius_reason: str
    near_distance: float = NEARBY_ALLY_DISTANCE_YD
    repeats: int = 5


def ally_heal_label(spec: AllyHealBreadthSpec, index: int, moment: str) -> str:
    return f'{spec.spell} {nearby_ally_id(index)} spell_heal_count {moment}'


def ally_heal_measurement(spec: AllyHealBreadthSpec, index: int, moment: str) -> dict:
    label = ally_heal_label(spec, index, moment)
    return measurement(label, CASTER, 'spell_heal_count', spell=spec.heal_spell, target=nearby_ally_id(index))


def ally_heal_breadth_scenario(class_file: dict, spec: AllyHealBreadthSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'count', spec.quote, spec.expected)
    class_file = armed_for(class_file, records, spec.trigger_spell)
    allies = [nearby_ally_fixture(index, class_file) for index in range(spec.expected)]
    creatures = [dummy_fixture(0, class_file, NEARBY_ALLY_TRIGGER_DISTANCE_YD)]

    facts = facts_of(records, spec.trigger_spell)
    wait_ms = facts.cast_time_ms + CAST_MARGIN_MS

    def cast_steps() -> list[dict]:
        steps = []
        for _ in range(spec.repeats):
            if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
                steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                             'value': facts.mana_cost})
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
            steps += required_aura_steps(facts)
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': dummy_id(0)})
            steps.append({'action': 'wait', 'ms': wait_ms})
        return steps

    def measure(moment: str) -> list[dict]:
        return [ally_heal_measurement(spec, index, moment) for index in range(spec.expected)]

    def activation_steps() -> list[dict]:
        aura = facts_of(records, spec.spell)
        if aura.passive:
            return []
        steps = [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
        if aura.mana_cost > 0 and not aura.mana_cost_percentage and not aura.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': aura.power_type, 'value': aura.mana_cost})
        return steps + required_aura_steps(aura) + [
            {'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': CASTER},
            {'action': 'wait', 'ms': aura.cast_time_ms + CAST_MARGIN_MS}]

    position_steps = []
    for index in range(spec.expected):
        position_steps += relocate_steps(nearby_ally_id(index), spec.near_distance) + [
            {'action': 'group', 'actor': CASTER, 'target': nearby_ally_id(index)}]

    before_labels = [ally_heal_label(spec, index, BEFORE) for index in range(spec.expected)]
    after_labels = [ally_heal_label(spec, index, AFTER) for index in range(spec.expected)]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour ally heal breadth',
        'contract': f'{spec.repeats} casts of {spec.trigger_spell} per phase, before without {spec.spell} known '
                    f'and after with it learned and, unless passive, cast on the caster, counting spell_heal_count '
                    f'of {spec.heal_spell} toward {spec.expected} grouped, non-caster ally fixtures '
                    f'{spec.near_distance:g} yd from the caster: '
                    f'{spec.radius_reason}',
        'players': [player_fixture(class_file)] + allies,
        'creatures': creatures,
        'steps': base_steps(class_file) + position_steps +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}] +
                 cast_steps() + measure(BEFORE) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + activation_steps() + cast_steps() +
                 measure(AFTER)}
    label = f'{spec.spell} behaviour_count'
    model = {'kind': 'count', 'dummy_labels': list(zip(before_labels, after_labels)), 'expected': spec.expected,
             'all_offered': True, 'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_COUNT, spec.spell, spec.trigger_spell, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def ally_heal_breadth_spec(entry: dict) -> AllyHealBreadthSpec:
    return AllyHealBreadthSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['heal_spell'],
                               entry['trigger_spell'], entry.get('radius_reason', ''),
                               entry.get('near_distance', NEARBY_ALLY_DISTANCE_YD), entry.get('repeats', 5))


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
                 'expected': spec.expected, 'quote': entry.quote, 'target_name': target.name,
                 'metric': HEALING_RATIO_METRICS.get(target.method, 'spell_healing_done')}
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


SPELL_ATTR3_IGNORE_CASTER_MODIFIERS = 0x20000000
SPELL_ATTR6_IGNORE_HEALTH_MODIFIERS = 0x08000000


def ignores_caster_heal_modifiers(records: Records, spell_id: int) -> bool:
    return bool(records.field('Spell', spell_id, 'AttributesEx3') & SPELL_ATTR3_IGNORE_CASTER_MODIFIERS or
                records.field('Spell', spell_id, 'AttributesEx6') & SPELL_ATTR6_IGNORE_HEALTH_MODIFIERS)


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
                    'target_name': f'{spec.name} (before learning it)', 'metric': 'spell_heal_total'}),
        Expectation(f'{spec.spell} {spec.target_rank} leech_ratio after', BEHAVIOUR_RATIO, spec.spell,
                   spec.target_rank, None, str(spec.expected_after * heal_factor), prose_rule(entry.quote, spec.spell),
                   {'kind': 'leech_ratio', 'damage_label': leech_ratio_label(spec, LEECH_RATIO_DAMAGE, AFTER),
                    'heal_label': leech_ratio_label(spec, LEECH_RATIO_HEAL, AFTER),
                    'heal_baseline_label': leech_ratio_label(spec, LEECH_RATIO_HEAL, BEFORE),
                    'expected': spec.expected_after * heal_factor, 'quote': entry.quote,
                    'target_name': f'{spec.name} (after learning it)', 'metric': 'spell_heal_total'}),
    ]
    return scenario, expectations


def leech_ratio_spec(entry: dict) -> LeechRatioSpec:
    return LeechRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['target_rank'],
                          entry['expected_before'], entry['expected_after'])


@dataclass(frozen=True)
class CastLeechRatioSpec:
    spell: int
    name: str
    quote: str
    heal_spell: int
    expected: float
    cast_spell: int = 0
    auras: tuple[tuple[int, int], ...] = ()
    label_suffix: str = ''

    def __post_init__(self):
        if not self.cast_spell:
            object.__setattr__(self, 'cast_spell', self.spell)


def cast_leech_ratio_scenario(class_file: dict, spec: CastLeechRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'ratio', spec.quote, spec.expected)
    facts = facts_of(records, spec.cast_spell)
    dummy = creature_fixture(class_file)
    heal_factor = (1.0 if ignores_caster_heal_modifiers(records, spec.heal_spell)
                  else leech_heal_modifier_factor(records, class_file))
    prefix = f'{spec.spell} cast_leech_ratio' + (f' {spec.label_suffix}' if spec.label_suffix else '')
    damage_label = f'{prefix} damage'
    heal_label = f'{prefix} heal'
    control_labels = (f'{prefix} control damage', f'{prefix} control heal') if spec.auras else None

    def cast() -> list[dict]:
        steps = []
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                          'value': facts.mana_cost})
        steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell})
        steps += required_aura_steps(facts)
        steps += required_target_health_steps(facts, dummy['id'])
        steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': dummy['id']})
        steps.append({'action': 'wait', 'ms': facts.cast_time_ms + CAST_MARGIN_MS})
        return steps

    def reads(labels: tuple[str, str]) -> list[dict]:
        return [measurement(labels[0], CASTER, 'spell_damage_total', spell=spec.cast_spell, target=dummy['id']),
                measurement(labels[1], CASTER, 'spell_heal_total', spell=spec.heal_spell, target=CASTER)]

    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell}]
    if control_labels:
        steps += cast() + reads(control_labels) + [{'action': 'wait', 'ms': GCD_WAIT_MS}]
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                  for spell, stacks in spec.auras]
    steps += cast() + reads((damage_label, heal_label))
    contract = (f'Single real cast of {spec.spell} against a dummy, measuring its own spell_damage_total and '
                f'the self-heal spell {spec.heal_spell}\'s spell_heal_total from that one cast, which share '
                f'the triggering hit\'s damage roll, so the heal/damage ratio is exactly deterministic once '
                f'the reference character\'s own known heal-done modifiers are folded in.')
    if control_labels:
        contract = (f'A cast of {spec.cast_spell} against a dummy without the auras {list(spec.auras)} (the control, '
                    f'which must heal nothing with {spec.heal_spell}), then one with them set on the caster; the '
                    f'second cast\'s damage and the {spec.heal_spell} healing it gives are read from the combat '
                    f'logs, the heal/damage ratio judged once the reference character\'s known heal-done modifiers '
                    f'are folded in.')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cast leech ratio'
                + (f' {spec.label_suffix}' if spec.label_suffix else ''),
        'contract': contract,
        'players': [player_fixture(class_file)],
        'creatures': [dummy],
        'steps': steps}
    model = {'kind': 'leech_ratio', 'damage_label': damage_label, 'heal_label': heal_label,
             'heal_baseline_label': None, 'expected': spec.expected * heal_factor,
             'quote': entry.quote, 'target_name': spec.name, 'metric': 'spell_heal_total'}
    if control_labels:
        model.update({'damage_baseline_label': control_labels[0], 'heal_baseline_label': control_labels[1],
                      'control_heal_label': control_labels[1]})
    label = f'{spec.spell} {spec.heal_spell} behaviour_ratio' + (f' {spec.label_suffix}' if spec.label_suffix else '')
    expectation = Expectation(label, BEHAVIOUR_RATIO, spec.spell,
                              spec.heal_spell, None, str(spec.expected * heal_factor),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def cast_leech_ratio_spec(entry: dict) -> CastLeechRatioSpec:
    return CastLeechRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['heal_spell'], entry['expected'],
                              entry.get('cast_spell', 0),
                              tuple((int(spell), int(stacks)) for spell, stacks in entry.get('auras', ())),
                              entry.get('label_suffix', ''))


@dataclass(frozen=True)
class CastStatRatioSpec:
    spell: int
    name: str
    quote: str
    stat_metric: str
    expected: float
    effect: int = 0


def cast_stat_ratio_scenario(class_file: dict, spec: CastStatRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'cast_stat_ratio', spec.quote, spec.expected)
    facts = facts_of(records, spec.spell)
    stat_label = f'{spec.spell} {spec.stat_metric} cast_stat_ratio stat'
    amount_label = f'{spec.spell} {spec.effect} aura_amount cast_stat_ratio amount'
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost})
    steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell})
    steps += required_aura_steps(facts)
    steps.append(measurement(stat_label, CASTER, spec.stat_metric))
    steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': CASTER})
    steps.append({'action': 'wait', 'ms': facts.cast_time_ms + CAST_MARGIN_MS})
    steps.append(measurement(amount_label, CASTER, 'aura_amount', spell=spec.spell, effect=spec.effect))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cast stat ratio',
        'contract': f'Real cast of {spec.spell} on the caster, measuring the caster\'s own {spec.stat_metric} stat '
                    f'right before the cast and the magnitude {spec.spell} applies to its own effect {spec.effect} '
                    f'aura on the caster right after, proving that magnitude tracks the stat (a script-computed '
                    f'amount, not a fixed Spell.dbc base point) rather than only matching it by the coincidence of '
                    f'the reference character\'s own fixed stat value.',
        'players': [player_fixture(class_file)],
        'steps': steps}
    label = f'{spec.spell} behaviour_ratio'
    model = {'kind': 'stat_ratio', 'stat_label': stat_label, 'amount_label': amount_label,
             'expected': spec.expected, 'quote': entry.quote, 'target_name': spec.name,
             'stat_metric': spec.stat_metric, 'metric': 'aura_amount'}
    expectation = Expectation(label, BEHAVIOUR_RATIO, spec.spell, spec.spell, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def cast_stat_ratio_spec(entry: dict) -> CastStatRatioSpec:
    return CastStatRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['stat_metric'], entry['expected'],
                             entry.get('effect', 0))


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
                 'quote': entry.quote, 'target_name': f'{health_pct}% health', 'metric': 'script_spell_damage_taken'}
        expectations.append(Expectation(f'{spec.spell} {health_pct} behaviour_ratio', BEHAVIOUR_RATIO, spec.spell,
                                        health_pct, None, str(expected_ratio), prose_rule(entry.quote, spec.spell),
                                        model))
    return scenario, expectations


def health_ratio_spec(entry: dict) -> HealthRatioSpec:
    return HealthRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['probe_spell'],
                           tuple((pct, ratio) for pct, ratio in entry['levels']))


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
    first_tick: bool = False


SPREAD_CLEARANCE_YD = 5.0
SPREAD_EDGE_YD = 0.5


def spread_tick(records: Records, rank: int) -> tuple[int, int, float]:
    for effect in range(3):
        tick = records.field('Spell', rank, f'EffectTriggerSpell[{effect}]')
        amplitude = records.field('Spell', rank, f'EffectAmplitude[{effect}]')
        if tick and amplitude:
            radii = [records.radius(tick, index) for index in range(3)
                     if records.field('Spell', tick, f'EffectRadiusIndex[{index}]')]
            if not radii:
                raise NotModelled(f'{tick}, the periodic trigger of {rank}, has no radius')
            return effect, tick, max(radii)
    raise NotModelled(f'{rank} has no periodic trigger whose first tick can be read alone')


def spread_distances(primary: float, reach: float, radius: float, extras: int) -> list[float]:
    low, high = reach + SPREAD_CLEARANCE_YD, primary + radius - SPREAD_EDGE_YD
    if extras < 2 or high <= low:
        raise NotModelled(f'no {extras} dummies fit beyond the {reach:g} yd reach and within {radius:g} yd of the '
                          f'primary dummy')
    step = (high - low) / (extras - 1)
    return [low + step * index for index in range(extras)]


def aura_spread_label(spec: AuraSpreadSpec, index: int, moment: str) -> str:
    return f'{spec.spell} {dummy_id(index)} aura {moment}'


def aura_spread_scenario(class_file: dict, spec: AuraSpreadSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'count', spec.quote, spec.expected)
    primary_distance = 3.0
    duration_ms = int(records.duration_ms(spec.target_rank))
    if spec.first_tick:
        dummy_count = spec.expected + 2
        tick_effect, tick_spell, reach = spread_tick(records, spec.target_rank)
        amplitude = int(records.amplitude_ms(spec.target_rank, tick_effect))
        distances = [primary_distance] + spread_distances(primary_distance, reach, spec.radius, dummy_count - 1)
        wait_ms = amplitude // 2
        settle_ms = duration_ms - wait_ms + CAST_MARGIN_MS
    else:
        dummy_count = spec.expected + 1
        distances = [primary_distance] + [
            primary_distance + spec.radius * (index / dummy_count) for index in range(1, dummy_count)]
        wait_ms = duration_ms + CAST_MARGIN_MS
        settle_ms = 0
    creatures = [dummy_fixture(index, class_file, distances[index]) for index in range(dummy_count)]

    seed_facts = facts_of(records, spec.seed_spell)
    tempest_facts = facts_of(records, spec.target_rank)
    repeats = 1 if spec.first_tick else spec.repeats

    def power_step(facts) -> list[dict]:
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            return [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost}]
        return []

    def primary_hits(moment: str, edge: str) -> list[dict]:
        if not spec.first_tick:
            return []
        return [measurement(f'{spec.spell} primary hits {moment} {edge}', CASTER, 'spell_damage_count',
                            spell=tick_spell, target=dummy_id(0))]

    def cast_steps(moment: str) -> list[dict]:
        steps = []
        for _ in range(repeats):
            steps += power_step(seed_facts)
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.seed_spell})
            steps += required_aura_steps(seed_facts)
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.seed_spell, 'target': dummy_id(0)})
            steps.append({'action': 'wait', 'ms': seed_facts.cast_time_ms + CAST_MARGIN_MS})
            steps.append({'action': 'wait', 'label': 'Global cooldown', 'ms': GCD_WAIT_MS})
            steps += power_step(tempest_facts)
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.target_rank})
            steps += required_aura_steps(tempest_facts)
            steps += primary_hits(moment, 'start')
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.target_rank})
            steps.append({'action': 'wait', 'ms': wait_ms})
            steps += primary_hits(moment, 'end')
        return steps

    def measure(moment: str) -> list[dict]:
        reads = [measurement(aura_spread_label(spec, index, moment), dummy_id(index), 'aura', spell=spec.aura_spell,
                             caster=CASTER)
                 for index in range(1, dummy_count)]
        settle = settle_ms and moment == BEFORE
        return reads + ([{'action': 'wait', 'label': 'periodic buff end', 'ms': settle_ms}] if settle else [])

    before_labels = [aura_spread_label(spec, index, BEFORE) for index in range(1, dummy_count)]
    after_labels = [aura_spread_label(spec, index, AFTER) for index in range(1, dummy_count)]
    learn_ranks = [{'action': 'learn', 'actor': CASTER, 'spell': rank}
                  for rank in dict.fromkeys((spec.seed_spell, spec.target_rank))]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour count',
        'contract': (f'one seed+cast per phase: seed {spec.seed_spell} on the primary dummy, cast {spec.target_rank} '
                     f'and count the afflicted dummies after the first hit of {tick_spell} on the primary dummy, '
                     f'with one dummy beyond the stated count, all beyond its reach: {spec.radius_reason}'
                     if spec.first_tick else
                     f'{spec.repeats} seed+cast cycles per phase: seed {spec.seed_spell} on the primary dummy, cast '
                     f'{spec.target_rank} and wait its full periodic buff, then count newly-afflicted nearby '
                     f'dummies: {spec.radius_reason}'),
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': base_steps(class_file) + learn_ranks + cast_steps(BEFORE) + measure(BEFORE) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + cast_steps(AFTER) + measure(AFTER)}
    label = f'{spec.spell} behaviour_count'
    model = {'kind': 'count', 'dummy_labels': list(zip(before_labels, after_labels)), 'expected': spec.expected,
             'headroom': dummy_count - 1 - spec.expected, 'quote': entry.quote}
    if spec.first_tick:
        model['primary_hits'] = [[f'{spec.spell} primary hits {moment} {edge}' for edge in ('start', 'end')]
                                 for moment in (BEFORE, AFTER)]
    expectation = Expectation(label, BEHAVIOUR_COUNT, spec.spell, spec.target_rank, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return (timed(scenario, waited_ms(scenario['steps'])) if spec.first_tick else scenario), [expectation]


def aura_spread_spec(entry: dict) -> AuraSpreadSpec:
    return AuraSpreadSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['seed_spell'],
                          entry['aura_spell'], entry['target_rank'], entry['radius'], entry['radius_reason'],
                          entry.get('repeats', 3), entry.get('first_tick', False))


def target_count_spec(entry: dict) -> TargetCountSpec:
    return TargetCountSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['target_rank'],
                           entry['radius'], entry['radius_reason'], entry.get('metric', 'spell_damage_count'),
                           entry.get('repeats', 5))


def fixed_target_count_spec(entry: dict) -> FixedTargetCountSpec:
    return FixedTargetCountSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['radius'],
                                entry['radius_reason'], entry.get('cast_spell', 0), entry.get('target_rank', 0),
                                entry.get('metric', 'spell_damage_count'), entry.get('repeats', 5),
                                tuple(entry.get('clear_auras', ())), entry.get('cast_target', TARGET),
                                entry.get('cast_target_health_pct'), tuple(entry.get('learn', ())),
                                entry.get('uncapped', False),
                                tuple((int(spell), int(stacks)) for spell, stacks in entry.get('auras', ())),
                                bool(entry.get('pull_reads', False)), int(entry.get('settle_ms', 0)),
                                entry.get('layout', ''), entry.get('headroom'), bool(entry.get('far_dummy', True)),
                                bool(entry.get('primary_distance_reads', False)), entry.get('label_suffix', ''),
                                None if entry.get('behind_yd') is None else float(entry['behind_yd']),
                                entry.get('cluster_yd'))


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
DEFAULT_ABSORB_PIERCE_WAIT_MS = 3000


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
    setup_only_after: bool = False
    measure_actor: str = CASTER
    tolerance: float | None = None
    cast_in_before: bool = True
    gate_timing: str = 'between'
    trigger_only_after: bool = False
    expiry_wait_ms: int | None = None
    after_expiry_expected: float | None = None
    attack_swings: int = 0
    force_crit: str | None = None
    setup_wait_ms: int = 0
    phase_auras: tuple[tuple[int, int, str, str], ...] = ()
    after_auras: tuple[tuple[int, int, str, str], ...] = ()
    select_dummy: bool = False
    after_at_least: float | None = None
    cast_power: int | None = None
    enemy_player_race: int = 0


ENEMY_PLAYER = 'enemy'
ENEMY_PLAYER_SETTLE_MS = 500
PHASE_AURA_UNITS = frozenset({CASTER, TARGET})


def phase_aura(raw) -> tuple[int, int, str, str]:
    spell, stacks, on, by = raw
    if on not in PHASE_AURA_UNITS or by not in PHASE_AURA_UNITS:
        raise ValueError(f'aura {spell} is set on {on!r} by {by!r}, not on and by {sorted(PHASE_AURA_UNITS)}')
    return int(spell), int(stacks), str(on), str(by)


def phase_aura_step(aura: tuple[int, int, str, str]) -> dict:
    spell, stacks, on, by = aura
    return {'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks,
            **({'target': on} if on != CASTER else {}), **({'caster': by} if by != on else {})}


def metric_delta_label(spec: MetricDeltaSpec, moment: str) -> str:
    return f'{spec.spell} {spec.metric} {moment}'


def metric_delta_scenario(class_file: dict, spec: MetricDeltaSpec) -> tuple[dict, list[Expectation]]:
    if spec.setup_only_after and not spec.setup_casts:
        raise ValueError(f'{spec.spell} sets setup_only_after without a setup_casts to withhold then apply')
    if (spec.expiry_wait_ms is None) != (spec.after_expiry_expected is None):
        raise ValueError(f'{spec.spell} must set expiry_wait_ms and after_expiry_expected together')
    if spec.expiry_wait_ms is not None and spec.gate_timing != 'start':
        raise ValueError(f'{spec.spell} sets expiry_wait_ms but gate_timing is not "start"')
    if spec.attack_swings and (spec.gate_timing != 'between' or spec.setup_casts or spec.target != TARGET
                               or spec.setup_actor_aura is not None or spec.trigger_only_after
                               or spec.phase_auras or spec.after_auras):
        raise ValueError(f'{spec.spell} attacks the dummy as its trigger, so it learns the gate between the two '
                         f'attack phases and takes no setup casts, setup aura or after-only trigger')
    if spec.force_crit is not None and spec.force_crit not in FORCE_CRIT_RATINGS:
        raise ValueError(f'{spec.spell} has an unknown force_crit {spec.force_crit!r}')
    if bool(spec.enemy_player_race) != (ENEMY_PLAYER in (spec.target, spec.measure_actor)):
        raise ValueError(f'{spec.spell} names the enemy player as its target or measured unit only with an '
                         f'enemy_player_race, and the race only with it')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'metric_delta', spec.quote, spec.expected)
    facts = facts_of(records, spec.trigger_spell)
    class_file = armed_for(class_file, records, spec.trigger_spell)

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
            if spec.setup_wait_ms:
                steps.append({'action': 'wait', 'ms': spec.setup_wait_ms})
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
        return steps

    def cast_steps(apply_setup_casts: bool = True, include_cast: bool = True, after: bool = True) -> list[dict]:
        steps = [{'action': 'select', 'actor': CASTER, 'target': TARGET}] if spec.select_dummy else []
        if spec.setup_actor_aura is not None:
            steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.setup_actor_aura, 'stacks': 1})
        steps += [phase_aura_step(aura) for aura in (*(spec.after_auras if after else ()), *spec.phase_auras)]
        if not include_cast:
            return steps
        if spec.cast_power is not None:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': spec.cast_power})
        elif facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
        steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
        steps += required_aura_steps(facts)
        if apply_setup_casts:
            steps += setup_cast_steps()
        steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': spec.target})
        steps.append({'action': 'wait', 'ms': spec.wait_ms})
        return steps

    if spec.gate_timing not in ('between', 'start'):
        raise ValueError(f'unknown gate_timing {spec.gate_timing!r}')
    gate_spell = spec.gate_spell if spec.gate_spell is not None else spec.spell
    gate_step = [{'action': 'learn', 'actor': CASTER, 'spell': gate_spell}]
    start_gate_steps = gate_step if spec.gate_timing == 'start' else []
    between_gate_steps = gate_step if spec.gate_timing == 'between' else []

    before_label = metric_delta_label(spec, BEFORE)
    after_label = metric_delta_label(spec, AFTER)
    gate_learn_step = {'action': 'learn', 'actor': CASTER, 'spell': gate_spell}
    if spec.setup_only_after:
        contract = (f'A/B target-condition check: {spec.metric} {spec.fields} around a cast of '
                    f'{spec.trigger_spell}, with {gate_spell} known throughout, once with none of '
                    f'{spec.setup_casts} applied first and once with them applied first, waiting '
                    f'{spec.expire_ms} ms between phases for the first cast\'s effect to fully expire before '
                    f'the second cast.')
        learn_steps = [gate_learn_step, {'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}] + \
            [{'action': 'learn', 'actor': CASTER, 'spell': setup_spell} for setup_spell in spec.setup_casts]
        steps = (base_steps(class_file) + learn_steps + cast_steps(apply_setup_casts=False, after=False) +
                 [measurement(before_label, spec.measure_actor, spec.metric, **spec.fields)] +
                 [{'action': 'wait', 'label': 'let the first phase fully expire', 'ms': spec.expire_ms}] +
                 cast_steps(apply_setup_casts=True) +
                 [measurement(after_label, spec.measure_actor, spec.metric, **spec.fields)])
    elif spec.gate_timing == 'start':
        contract = (f'With/without-the-buff check: {spec.metric} {spec.fields} measured once with no cast of '
                    f'{spec.trigger_spell} and once right after casting it, {gate_spell} already learned '
                    f'throughout, isolating whether the buff is actually active rather than whether the passive '
                    f'is known.')
        learn_steps = [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}] + \
            [{'action': 'learn', 'actor': CASTER, 'spell': setup_spell} for setup_spell in spec.setup_casts]
        if spec.expiry_wait_ms is not None:
            contract += (f' A third measurement follows {spec.expiry_wait_ms} ms later, past the triggering '
                         f'cast\'s own aura duration, to confirm the effect actually ends rather than '
                         f'outliving the aura it is scoped to.')
        steps = (base_steps(class_file) + learn_steps + start_gate_steps +
                 cast_steps(include_cast=not spec.trigger_only_after, after=False) +
                 [measurement(before_label, spec.measure_actor, spec.metric, **spec.fields)] +
                 between_gate_steps +
                 [{'action': 'wait', 'label': 'let the first effect fully expire', 'ms': spec.expire_ms}] +
                 cast_steps() + [measurement(after_label, spec.measure_actor, spec.metric, **spec.fields)])
        if spec.expiry_wait_ms is not None:
            expired_label = metric_delta_label(spec, 'expired')
            steps = steps + [{'action': 'wait', 'label': 'let the triggering aura actually expire',
                              'ms': spec.expiry_wait_ms},
                             measurement(expired_label, spec.measure_actor, spec.metric, **spec.fields)]
    elif spec.attack_swings:
        swings = [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                  {'action': 'wait', 'label': 'swings', 'ms': spec.attack_swings * swing_interval(class_file)},
                  {'action': 'stop_attack', 'actor': CASTER}]
        contract = (f'With/without check: {spec.metric} {spec.fields} after {spec.attack_swings} auto-attack swing '
                    f'intervals at the dummy, measured before and after {gate_spell} is learned, waiting '
                    f'{spec.expire_ms} ms between phases for the first phase\'s effect to fully expire.')
        steps = (base_steps(class_file) + swings
                 + [measurement(before_label, spec.measure_actor, spec.metric, **spec.fields), gate_learn_step]
                 + [{'action': 'wait', 'label': 'let the first effect fully expire', 'ms': spec.expire_ms}]
                 + swings + [measurement(after_label, spec.measure_actor, spec.metric, **spec.fields)])
    else:
        contract = (f'No-combat with/without check: {spec.metric} {spec.fields} around a cast of '
                    f'{spec.trigger_spell}, measured before and after {gate_spell} is learned, waiting '
                    f'{spec.expire_ms} ms between phases for the first cast\'s effect to fully expire before the '
                    f'second cast.' + ('' if spec.cast_in_before else ' The before phase skips casting '
                    f'{spec.trigger_spell} entirely (cast_in_before=False), measuring the baseline state alone.'))
        learn_steps = [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}] + \
            [{'action': 'learn', 'actor': CASTER, 'spell': setup_spell} for setup_spell in spec.setup_casts]
        steps = (base_steps(class_file) + learn_steps +
                 cast_steps(include_cast=spec.cast_in_before and not spec.trigger_only_after, after=False) +
                 [measurement(before_label, spec.measure_actor, spec.metric, **spec.fields), gate_learn_step] +
                 [{'action': 'wait', 'label': 'let the first effect fully expire', 'ms': spec.expire_ms}] +
                 cast_steps() + [measurement(after_label, spec.measure_actor, spec.metric, **spec.fields)])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour metric delta',
        'contract': contract,
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}] if spec.disable_regeneration
                   else [player_fixture(class_file)],
        'steps': steps}
    if spec.force_crit:
        scenario['players'][0][FORCE_CRIT_RATINGS[spec.force_crit]] = FORCED_CRIT_RATING
    if spec.enemy_player_race:
        settled = len(base_steps(class_file))
        steps[settled:settled] = [{'action': 'pvp', 'actor': CASTER, 'enabled': True},
                                  {'action': 'pvp', 'actor': ENEMY_PLAYER, 'enabled': True},
                                  {'action': 'wait', 'label': 'pvp settle', 'ms': ENEMY_PLAYER_SETTLE_MS}]
        scenario['players'].append({**player_fixture(class_file), 'id': ENEMY_PLAYER, 'race': spec.enemy_player_race})
        scenario['location'] = dict(TAKEN_HIT_PVP_LOCATION)
    if spec.attack_swings:
        timed(scenario, sum(step['ms'] for step in steps if step['action'] == 'wait'))
    if spec.select_dummy or TARGET in (spec.target, spec.measure_actor) or any(
            TARGET in aura[2:] for aura in (*spec.phase_auras, *spec.after_auras)):
        scenario['creatures'] = [creature_fixture(class_file)]
    label = f'{spec.spell} behaviour_metric_delta' + (f' {spec.label_suffix}' if spec.label_suffix else '')
    model = {'kind': 'metric_delta', 'before_label': before_label, 'after_label': after_label,
             'expected': spec.expected, 'before_expected': spec.before_expected, 'metric': spec.metric,
             'contrast': CONDITION_CONTRAST if spec.setup_only_after else LEARNED_CONTRAST, 'quote': entry.quote}
    if spec.tolerance is not None:
        model['tolerance'] = spec.tolerance
    if spec.after_at_least is not None:
        model['after_at_least'] = spec.after_at_least
    if spec.expiry_wait_ms is not None:
        model['expired_label'] = metric_delta_label(spec, 'expired')
        model['after_expiry_expected'] = spec.after_expiry_expected
    expectation = Expectation(label, BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell, None,
                              str(spec.expected), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def metric_delta_spec(entry: dict) -> MetricDeltaSpec:
    return MetricDeltaSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['trigger_spell'],
                           entry['metric'], entry['fields'], entry['before_expected'],
                           entry.get('wait_ms', DEFAULT_METRIC_DELTA_WAIT_MS),
                           entry.get('expire_ms', DEFAULT_METRIC_DELTA_EXPIRE_MS), entry.get('target', CASTER),
                           entry.get('disable_regeneration', False), tuple(entry.get('setup_casts', ())),
                           entry.get('setup_actor_aura'), entry.get('gate_spell'), entry.get('label_suffix', ''),
                           entry.get('setup_only_after', False),
                           entry.get('measure_actor', CASTER), entry.get('tolerance'),
                           entry.get('cast_in_before', True),
                           entry.get('gate_timing', 'between'), entry.get('trigger_only_after', False),
                           entry.get('expiry_wait_ms'), entry.get('after_expiry_expected'),
                           entry.get('attack_swings', 0), entry.get('force_crit'), entry.get('setup_wait_ms', 0),
                           tuple(phase_aura(raw) for raw in entry.get('phase_auras', ())),
                           tuple(phase_aura(raw) for raw in entry.get('after_auras', ())),
                           entry.get('select_dummy', False), entry.get('after_at_least'), entry.get('cast_power'),
                           entry.get('enemy_player_race', 0))


CRIT_MAGNITUDE_DEFAULT_ATTEMPTS = 10
CRIT_MAGNITUDE_OBSERVE_METRICS = frozenset({'spell_energize_total'})


@dataclass(frozen=True)
class CritMagnitudeSpec:
    spell: int
    name: str
    quote: str
    observe_spell: int
    metric: str
    base_expected: float
    crit_bonus_expected: float
    attempts: int = CRIT_MAGNITUDE_DEFAULT_ATTEMPTS
    force_crit: str = 'melee'


def crit_magnitude_labels(spec: CritMagnitudeSpec) -> dict[str, str]:
    base = f'{spec.spell} {spec.observe_spell} crit_magnitude'
    return {'attempts': f'{base} attempts', 'crits': f'{base} crits', 'total': f'{base} total'}


def crit_magnitude_contract(spec: CritMagnitudeSpec) -> str:
    return (f'Forced-crit melee check: {spec.metric} of {spec.observe_spell} over {spec.attempts} forced-crit '
            f'({FORCE_CRIT_RATINGS[spec.force_crit]} {FORCED_CRIT_RATING}) swings matches melee_attack_count x '
            f'{spec.base_expected:g} plus melee_damage_count(critical) x {spec.crit_bonus_expected:g}.')


def crit_magnitude_scenario(class_file: dict, spec: CritMagnitudeSpec) -> tuple[dict, list[Expectation]]:
    if spec.metric not in CRIT_MAGNITUDE_OBSERVE_METRICS:
        raise ValueError(f'crit_magnitude metric must be one of {sorted(CRIT_MAGNITUDE_OBSERVE_METRICS)}, not '
                         f'{spec.metric!r}')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'crit_magnitude', spec.quote,
                            spec.base_expected + spec.crit_bonus_expected)
    interval = swing_interval(class_file)
    labels = crit_magnitude_labels(spec)
    steps = [
        {'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
        {'action': 'attack', 'actor': CASTER, 'target': TARGET},
        {'action': 'wait', 'label': f'{spec.spell} crit_magnitude swings', 'ms': spec.attempts * interval},
        {'action': 'stop_attack', 'actor': CASTER},
        {'action': 'wait', 'label': f'{spec.spell} crit_magnitude drain', 'ms': DRAIN_MS},
        measurement(labels['attempts'], CASTER, 'melee_attack_count', hand=MAIN_HAND),
        measurement(labels['crits'], CASTER, 'melee_damage_count', hand=MAIN_HAND, critical=True),
        measurement(labels['total'], CASTER, spec.metric, spell=spec.observe_spell),
    ]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour crit magnitude',
        'contract': crit_magnitude_contract(spec),
        'players': [{**player_fixture(class_file), FORCE_CRIT_RATINGS[spec.force_crit]: FORCED_CRIT_RATING}],
        'creatures': [creature_fixture(class_file)],
        'steps': base_steps(class_file) + steps}
    label = f'{spec.spell} behaviour_crit_magnitude'
    model = {'kind': 'crit_magnitude', 'attempts_label': labels['attempts'], 'crits_label': labels['crits'],
            'total_label': labels['total'], 'base_expected': spec.base_expected,
            'crit_bonus_expected': spec.crit_bonus_expected, 'metric': spec.metric, 'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_CRIT_MAGNITUDE, spec.spell, spec.observe_spell, None,
                              str(spec.base_expected + spec.crit_bonus_expected), prose_rule(entry.quote, spec.spell),
                              model)
    return scenario, [expectation]


def crit_magnitude_spec(entry: dict) -> CritMagnitudeSpec:
    return CritMagnitudeSpec(entry['spell'], entry['name'], entry['quote'], entry['observe_spell'], entry['metric'],
                             entry['base_expected'], entry['crit_bonus_expected'],
                             entry.get('attempts', CRIT_MAGNITUDE_DEFAULT_ATTEMPTS), entry.get('force_crit', 'melee'))


DEFAULT_DISPEL_REMOVAL_WAIT_MS = 1500


@dataclass(frozen=True)
class DispelRemovalSpec:
    spell: int
    name: str
    quote: str
    debuffs: tuple[int, ...]
    target: str = CASTER
    wait_ms: int = DEFAULT_DISPEL_REMOVAL_WAIT_MS
    label_suffix: str = ''
    gameplay_clock: str | None = None
    arms: tuple['DispelArm', ...] = ()


@dataclass(frozen=True)
class DispelArm:
    name: str
    target: str
    removed: bool
    away_yd: float = 0.0
    refused: int = 0
    caster_removed: bool | None = None

    def removed_on(self, unit: str) -> bool:
        return self.caster_removed if unit == CASTER and self.caster_removed is not None else self.removed


DISPEL_ARM_STEP_YD = 20.0


def dispel_removal_label(spec: DispelRemovalSpec, debuff: int, moment: str) -> str:
    return f'{spec.spell} aura {debuff} {moment}'


def dispel_arm_outcome(arm: DispelArm) -> str:
    caster, target = ('removed' if arm.removed_on(unit) else 'kept' for unit in (CASTER, arm.target))
    return caster if caster == target else f'{caster} on the caster, {target} on the target'


def dispel_arm_label(spec: DispelRemovalSpec, arm: DispelArm, unit: str, debuff: int, moment: str) -> str:
    return f'{spec.spell} {arm.name} {unit} aura {debuff} {moment}'


def dispel_arm_cast_label(spec: DispelRemovalSpec, arm: DispelArm) -> str:
    return f'{spec.spell} {arm.name} cast_failure'


def dispel_arm_relocation(distance: float) -> list[dict]:
    steps, left = [], abs(distance)
    while left > 0:
        step = min(DISPEL_ARM_STEP_YD, left)
        steps.append({'action': 'relocate', 'actor': CASTER, 'dx': step if distance > 0 else -step})
        left -= step
    return steps


def dispel_set_step(unit: str, debuff: int) -> dict:
    if unit == TARGET:
        return {'action': 'set_aura', 'actor': CASTER, 'spell': debuff, 'stacks': 1, 'target': TARGET}
    return {'action': 'set_aura', 'actor': unit, 'spell': debuff, 'stacks': 1}


def dispel_arms_scenario(class_file: dict, spec: DispelRemovalSpec, entry, facts) -> tuple[dict, list[Expectation]]:
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    expectations = []
    for arm in spec.arms:
        if arm.target not in (TARGET, ALLY) or arm.away_yd < 0:
            raise ValueError(f'{spec.spell} dispel arm {arm.name} casts at {arm.target!r} from {arm.away_yd} yd; it '
                             f'needs the dummy or the ally and a distance of at least 0')
        units = (CASTER, arm.target)
        steps += [dispel_set_step(unit, debuff) for unit in units for debuff in spec.debuffs]
        steps += [measurement(dispel_arm_label(spec, arm, unit, debuff, BEFORE), unit, 'aura', spell=debuff)
                  for unit in units for debuff in spec.debuffs]
        steps += dispel_arm_relocation(arm.away_yd)
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                          'value': facts.mana_cost})
        steps += [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}] + required_aura_steps(facts)
        steps += [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': arm.target},
                  {'action': 'wait', 'ms': spec.wait_ms},
                  measurement(dispel_arm_cast_label(spec, arm), CASTER, 'cast_failure', spell=spec.spell)]
        expectations.append(Expectation(dispel_arm_cast_label(spec, arm), BEHAVIOUR_CAST_CONDITION, spec.spell,
                                        spec.spell, None, str(arm.refused), prose_rule(entry.quote, spec.spell),
                                        {'kind': 'cast_gate', 'arm': arm.name, 'quote': entry.quote}))
        steps += [measurement(dispel_arm_label(spec, arm, unit, debuff, AFTER), unit, 'aura', spell=debuff)
                  for unit in units for debuff in spec.debuffs]
        steps += dispel_arm_relocation(-arm.away_yd)
        for unit in units:
            removed = arm.removed_on(unit)
            for debuff in spec.debuffs:
                model = {'kind': 'metric_delta', 'before_label': dispel_arm_label(spec, arm, unit, debuff, BEFORE),
                         'after_label': dispel_arm_label(spec, arm, unit, debuff, AFTER),
                         'expected': 0.0 if removed else 1.0, 'before_expected': 1.0, 'metric': 'aura',
                         'quote': entry.quote, 'gameplay_clock': spec.gameplay_clock}
                label = (f'{spec.spell} behaviour_dispel_removal {debuff} {arm.name} '
                         f'{"caster" if unit == CASTER else "target"}')
                expectations.append(Expectation(label, BEHAVIOUR_METRIC_DELTA, spec.spell, spec.spell, None,
                                                '0' if removed else '1', prose_rule(entry.quote, spec.spell),
                                                model))
    arms_text = '; '.join(f'{arm.name}: cast at the {arm.target} from {arm.away_yd:g} yd, {dispel_arm_outcome(arm)}'
                          for arm in spec.arms)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour dispel removal arms',
        'contract': f'Debuffs {list(spec.debuffs)} set on the caster and on the arm\'s target, each read before and '
                    f'{spec.wait_ms} ms after a cast of {spec.spell} at that target ({arms_text}).',
        'players': [player_fixture(class_file)] + ([{**player_fixture(class_file), 'id': ALLY}]
                                                   if any(arm.target == ALLY for arm in spec.arms) else []),
        'steps': steps}
    if any(arm.target == TARGET for arm in spec.arms):
        scenario['creatures'] = [creature_fixture(class_file)]
    return scenario, expectations


def dispel_removal_scenario(class_file: dict, spec: DispelRemovalSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'dispel_removal', spec.quote, 0.0)
    facts = facts_of(records, spec.spell)
    if spec.arms:
        return dispel_arms_scenario(class_file, spec, entry, facts)

    debuff_steps = [{'action': 'set_aura', 'actor': spec.target, 'spell': debuff, 'stacks': 1}
                   for debuff in spec.debuffs]
    before_measurements = [measurement(dispel_removal_label(spec, debuff, BEFORE), spec.target, 'aura', spell=debuff)
                           for debuff in spec.debuffs]
    after_measurements = [measurement(dispel_removal_label(spec, debuff, AFTER), spec.target, 'aura', spell=debuff)
                          for debuff in spec.debuffs]
    cast_steps = []
    if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        cast_steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                           'value': facts.mana_cost})
    cast_steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell})
    cast_steps += required_aura_steps(facts)
    cast_steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': spec.target})
    cast_steps.append({'action': 'wait', 'ms': spec.wait_ms})

    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour dispel removal',
        'contract': f'Debuffs {list(spec.debuffs)} applied to {spec.target}, then {spec.spell} cast on them; each '
                    f'debuff\'s aura metric is measured before and after, waiting {spec.wait_ms} ms for the '
                    f'removal to take effect.',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
                + debuff_steps + before_measurements + cast_steps + after_measurements}
    if spec.target != CASTER:
        scenario['players'].append({**player_fixture(class_file), 'id': spec.target})

    expectations = []
    for debuff in spec.debuffs:
        before_label = dispel_removal_label(spec, debuff, BEFORE)
        after_label = dispel_removal_label(spec, debuff, AFTER)
        model = {'kind': 'metric_delta', 'before_label': before_label, 'after_label': after_label,
                 'expected': 0.0, 'before_expected': 1.0, 'metric': 'aura', 'quote': entry.quote,
                 'gameplay_clock': spec.gameplay_clock}
        label = f'{spec.spell} behaviour_dispel_removal {debuff}' + \
            (f' {spec.label_suffix}' if spec.label_suffix else '')
        expectations.append(Expectation(label, BEHAVIOUR_METRIC_DELTA, spec.spell, spec.spell, None, '0',
                                        prose_rule(entry.quote, spec.spell), model))
    return scenario, expectations


def dispel_removal_spec(entry: dict) -> DispelRemovalSpec:
    return DispelRemovalSpec(entry['spell'], entry['name'], entry['quote'], tuple(entry['debuffs']),
                             entry.get('target', CASTER), entry.get('wait_ms', DEFAULT_DISPEL_REMOVAL_WAIT_MS),
                             entry.get('label_suffix', ''), entry.get('gameplay_clock'),
                             tuple(DispelArm(str(arm['name']), str(arm['target']), bool(arm['removed']),
                                             float(arm.get('away_yd', 0.0)), int(arm.get('refused', 0)),
                                             None if arm.get('caster_removed') is None
                                             else bool(arm['caster_removed']))
                                   for arm in entry.get('arms', ())))


AMOUNT_MATCH_SIDES = ('first', 'second')
AMOUNT_MATCH_METRICS = {'spell_damage_total': 'spell_damage_count', 'spell_heal_total': 'spell_heal_count'}


@dataclass(frozen=True)
class AmountSide:
    metric: str
    spell: int
    target: str


@dataclass(frozen=True)
class AmountMatchSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    cast_target: str
    first: AmountSide
    second: AmountSide
    trials: int = 20
    tolerance: float = 1.0
    auras: tuple[tuple[int, int], ...] = ()
    group: bool = False
    wait_ms: int = 1000


def amount_match_label(spec: AmountMatchSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_AMOUNT_MATCH}'


def amount_match_reads(spec: AmountMatchSpec, side: str, mark) -> tuple[str, str]:
    base = f'{amount_match_label(spec)} {side} {mark}'
    return f'{base} total', f'{base} count'


def amount_match_scenario(class_file: dict, spec: AmountMatchSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'amount_match', spec.quote, 1.0)
    sides = {'first': spec.first, 'second': spec.second}
    for side in sides.values():
        if side.metric not in AMOUNT_MATCH_METRICS or side.target not in (TARGET, ALLY, CASTER):
            raise ValueError(f'{spec.spell} amount_match reads {side.metric!r} on {side.target!r}, not one of '
                             f'{sorted(AMOUNT_MATCH_METRICS)} on the dummy, the ally or the caster')
    if spec.trials < 1 or spec.tolerance < 0:
        raise ValueError(f'{spec.spell} amount_match needs at least one trial and a non-negative tolerance')

    def reads(mark) -> list[dict]:
        steps = []
        for name, side in sides.items():
            total, count = amount_match_reads(spec, name, mark)
            fields = {'spell': side.spell, 'target': side.target, 'critical': False}
            steps += [measurement(total, CASTER, side.metric, **fields),
                      measurement(count, CASTER, AMOUNT_MATCH_METRICS[side.metric], **fields)]
        return steps

    allies = any(side.target == ALLY for side in sides.values()) or spec.cast_target == ALLY
    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell}]
             + ([{'action': 'group', 'actor': CASTER, 'target': ALLY}] if spec.group and allies else [])
             + reads('start'))
    for trial in range(1, spec.trials + 1):
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks}
                  for aura, stacks in spec.auras]
        steps += hit_ratio_cast(records, spec.cast_spell, CASTER, spec.cast_target)
        steps += [{'action': 'wait', 'label': f'trial {trial} amounts', 'ms': spec.wait_ms}] + reads(trial)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour amount match',
        'contract': f'{spec.trials} casts of {spec.cast_spell} at the {spec.cast_target}; after each, the non-critical '
                    f'{spec.first.metric} of {spec.first.spell} on the {spec.first.target} and '
                    f'{spec.second.metric} of {spec.second.spell} on the {spec.second.target} are read; in every '
                    f'trial with both, the per-event amounts must be equal within {spec.tolerance:g}.',
        'players': [player_fixture(class_file)] + ([{**player_fixture(class_file), 'id': ALLY}] if allies else []),
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'amount_match', 'trials': spec.trials, 'tolerance': spec.tolerance, 'quote': entry.quote,
             'reads': {name: [list(amount_match_reads(spec, name, mark))
                              for mark in ('start', *range(1, spec.trials + 1))] for name in sides},
             'minimum_trials': max(1, spec.trials // 2)}
    expectation = Expectation(amount_match_label(spec), BEHAVIOUR_AMOUNT_MATCH, spec.spell, spec.cast_spell, None,
                              '1', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def amount_match_spec(entry: dict) -> AmountMatchSpec:
    def side(raw: dict) -> AmountSide:
        return AmountSide(raw['metric'], int(raw['spell']), raw['target'])
    return AmountMatchSpec(entry['spell'], entry['name'], entry['quote'], int(entry['cast_spell']),
                           entry.get('cast_target', TARGET), side(entry['first']), side(entry['second']),
                           int(entry.get('trials', 20)), float(entry.get('tolerance', 1.0)),
                           tuple((int(spell), int(stacks)) for spell, stacks in entry.get('auras', ())),
                           bool(entry.get('group', False)), int(entry.get('wait_ms', 1000)))


DEFAULT_AURA_PRESENCE_WAIT_MS = 1500


@dataclass(frozen=True)
class AuraPresenceSpec:
    spell: int
    name: str
    quote: str
    metric: str
    fields: dict
    target: str = CASTER
    wait_ms: int = DEFAULT_AURA_PRESENCE_WAIT_MS
    label_suffix: str = ''
    caster_auras: tuple[int, ...] = ()
    target_distance: float = 0.0
    present: bool = True


def aura_presence_label(spec: AuraPresenceSpec, moment: str) -> str:
    return f'{spec.spell} {spec.metric} {moment}'


def aura_presence_scenario(class_file: dict, spec: AuraPresenceSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'aura_presence', spec.quote, 1.0)
    facts = facts_of(records, spec.spell)

    before_label = aura_presence_label(spec, BEFORE)
    after_label = aura_presence_label(spec, AFTER)

    cast_steps = []
    if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        cast_steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                           'value': facts.mana_cost})
    cast_steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell})
    cast_steps += required_aura_steps(facts)
    cast_steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1} for aura in spec.caster_auras]
    cast_steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': CASTER})
    cast_steps.append({'action': 'wait', 'ms': spec.wait_ms})

    if (spec.target_distance or not spec.present) and spec.target == CASTER:
        raise ValueError(f'{spec.spell} aura_presence places or excludes the target, so the target is not the caster')
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    if spec.target != CASTER:
        steps.append({'action': 'group', 'actor': CASTER, 'target': spec.target})
        steps += relocate_steps(spec.target, spec.target_distance)
    caster_before, caster_label = aura_presence_label(spec, 'caster before'), aura_presence_label(spec, 'caster')
    steps.append(measurement(before_label, spec.target, spec.metric, **spec.fields))
    if not spec.present:
        steps.append(measurement(caster_before, CASTER, spec.metric, **spec.fields))
    steps += cast_steps
    steps.append(measurement(after_label, spec.target, spec.metric, **spec.fields))
    if not spec.present:
        steps.append(measurement(caster_label, CASTER, spec.metric, **spec.fields))

    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura presence',
        'contract': f'{spec.metric} measured on {spec.target} before and after casting {spec.spell} on the caster, '
                    f'waiting {spec.wait_ms} ms for the area aura to apply.',
        'players': [player_fixture(class_file)],
        'steps': steps}
    if spec.target != CASTER:
        scenario['players'].append({**player_fixture(class_file), 'id': spec.target})

    if spec.target_distance:
        scenario['contract'] += f' {spec.target} stands {spec.target_distance:g} yd away.'
    if not spec.present:
        scenario['contract'] += f' {spec.target} must stay without it while the caster carries it.'
    present = 1.0 if spec.present else 0.0
    model = {'kind': 'metric_delta', 'before_label': before_label, 'after_label': after_label, 'expected': present,
             'before_expected': 0.0, 'metric': spec.metric, 'quote': entry.quote}
    label = f'{spec.spell} behaviour_aura_presence' + (f' {spec.label_suffix}' if spec.label_suffix else '')
    expectations = [Expectation(label, BEHAVIOUR_METRIC_DELTA, spec.spell, spec.spell, None, f'{present:g}',
                                prose_rule(entry.quote, spec.spell), model)]
    if not spec.present:
        caster_model = {'kind': 'metric_delta', 'before_label': caster_before, 'after_label': caster_label,
                        'expected': 1.0, 'before_expected': 0.0, 'metric': spec.metric, 'quote': entry.quote}
        expectations.append(Expectation(f'{label} caster', BEHAVIOUR_METRIC_DELTA, spec.spell, spec.spell, None, '1',
                                        prose_rule(entry.quote, spec.spell), caster_model))
    return scenario, expectations


def aura_presence_spec(entry: dict) -> AuraPresenceSpec:
    return AuraPresenceSpec(entry['spell'], entry['name'], entry['quote'], entry['metric'], entry.get('fields', {}),
                            entry.get('target', CASTER), entry.get('wait_ms', DEFAULT_AURA_PRESENCE_WAIT_MS),
                            entry.get('label_suffix', ''), tuple(int(aura) for aura in entry.get('caster_auras', ())),
                            float(entry.get('target_distance', 0.0)), bool(entry.get('present', True)))


DEFAULT_HEAL_BLOCK_WAIT_MS = 1000


@dataclass(frozen=True)
class HealBlockSpec:
    spell: int
    name: str
    quote: str
    creature_entry: int
    block_spell: int
    blocked: bool
    wait_ms: int = DEFAULT_HEAL_BLOCK_WAIT_MS
    label_suffix: str = ''


def heal_block_label(spec: HealBlockSpec, moment: str) -> str:
    return f'{spec.spell} aura {spec.block_spell} {spec.creature_entry} {moment}'


def heal_block_scenario(class_file: dict, spec: HealBlockSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'heal_block', spec.quote, 1.0 if spec.blocked else 0.0)
    facts = facts_of(records, spec.spell)

    before_label = heal_block_label(spec, BEFORE)
    after_label = heal_block_label(spec, AFTER)

    cast_steps = []
    if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        cast_steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                           'value': facts.mana_cost})
    cast_steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell})
    cast_steps += required_aura_steps(facts)
    cast_steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': TARGET})
    cast_steps.append({'action': 'wait', 'ms': spec.wait_ms})

    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour heal block '
                f'{spec.creature_entry}',
        'contract': f'{spec.spell} cast on a creature (entry {spec.creature_entry}); the creature\'s own '
                    f'{spec.block_spell} (the heal-block aura {spec.spell} triggers) is measured before the cast '
                    f'and {spec.wait_ms} ms after.',
        'players': [player_fixture(class_file)],
        'creatures': [{'id': TARGET, 'owner': CASTER, 'entry': spec.creature_entry, 'level': class_file['level'],
                       'health': 100000, 'distance': 3, 'stationary': True}],
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] +
                 [measurement(before_label, TARGET, 'aura', spell=spec.block_spell)] + cast_steps +
                 [measurement(after_label, TARGET, 'aura', spell=spec.block_spell)]}

    model = {'kind': 'heal_block', 'before_label': before_label, 'after_label': after_label, 'blocked': spec.blocked,
             'quote': entry.quote}
    label = f'{spec.spell} behaviour_heal_block {spec.creature_entry}' + \
        (f' {spec.label_suffix}' if spec.label_suffix else '')
    expectation = Expectation(label, BEHAVIOUR_HEAL_BLOCK, spec.spell, spec.spell, None,
                              'blocked' if spec.blocked else 'heals', prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def heal_block_spec(entry: dict) -> HealBlockSpec:
    return HealBlockSpec(entry['spell'], entry['name'], entry['quote'], entry['creature_entry'], entry['block_spell'],
                        entry['blocked'], entry.get('wait_ms', DEFAULT_HEAL_BLOCK_WAIT_MS),
                        entry.get('label_suffix', ''))


@dataclass(frozen=True)
class AuraMetricDeltaSpec:
    spell: int
    name: str
    quote: str
    expected: float
    aura_spell: int
    metric: str
    fields: dict
    before_expected: float
    aura_stacks: int = 1
    target: str = CASTER
    label_suffix: str = ''


def aura_metric_delta_label(spec: AuraMetricDeltaSpec, moment: str) -> str:
    return f'{spec.spell} {spec.metric} aura_gated {moment}'


def aura_metric_delta_scenario(class_file: dict, spec: AuraMetricDeltaSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'aura_metric_delta', spec.quote, spec.expected)
    before_label = aura_metric_delta_label(spec, BEFORE)
    after_label = aura_metric_delta_label(spec, AFTER)
    steps = base_steps(class_file) + [
        measurement(before_label, CASTER, spec.metric, **spec.fields),
        {'action': 'set_aura', 'actor': CASTER, 'spell': spec.aura_spell, 'stacks': spec.aura_stacks},
        measurement(after_label, CASTER, spec.metric, **spec.fields)]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura metric delta',
        'contract': f'{spec.metric} {spec.fields} is read once with no aura on the caster and once right after '
                    f'{spec.aura_spell} is set directly on the caster at {spec.aura_stacks} stack(s), isolating the '
                    f'aura\'s own effect from however it is normally applied in play (already proven by a separate '
                    f'verdict).',
        'players': [player_fixture(class_file)],
        'steps': steps}
    if spec.target == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    label = f'{spec.spell} behaviour_metric_delta' + (f' {spec.label_suffix}' if spec.label_suffix else '')
    model = {'kind': 'metric_delta', 'before_label': before_label, 'after_label': after_label,
             'expected': spec.expected, 'before_expected': spec.before_expected, 'metric': spec.metric,
             'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura_spell, None,
                              str(spec.expected), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def aura_metric_delta_spec(entry: dict) -> AuraMetricDeltaSpec:
    return AuraMetricDeltaSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['aura_spell'],
                               entry['metric'], entry['fields'], entry['before_expected'],
                               entry.get('aura_stacks', 1), entry.get('target', CASTER),
                               entry.get('label_suffix', ''))


@dataclass(frozen=True)
class ThreatTickRatioSpec:
    spell: int
    name: str
    quote: str
    expected_ratio: float
    aura_spell: int
    attack_wait_ms: int
    tick_wait_ms: int
    tolerance: float
    aura_stacks: int = 1
    ticks: int = 1
    label_suffix: str = ''
    cast_target: str | None = None
    threat_unit: str = CASTER


def threat_tick_ratio_label(spec: ThreatTickRatioSpec, moment: str) -> str:
    return f'{spec.spell} threat aura_gated {moment}'


def threat_tick_aura_label(spec: ThreatTickRatioSpec, moment: str) -> str:
    return f'{spec.spell} {spec.aura_spell} aura_duration_ms threat_tick_cast {moment}'


def threat_tick_application(records: Records, spec: ThreatTickRatioSpec) -> tuple[list[dict], list[dict]]:
    if spec.cast_target is None:
        return [], [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.aura_spell, 'stacks': spec.aura_stacks}]
    facts = facts_of(records, spec.aura_spell)
    return ([{'action': 'learn', 'actor': CASTER, 'spell': spec.aura_spell}],
            [measurement(threat_tick_aura_label(spec, BEFORE), spec.cast_target, 'aura_duration_ms',
                         spell=spec.aura_spell)]
            + cast_gate_power_step(facts) + required_aura_steps(facts)
            + [{'action': 'cast', 'actor': CASTER, 'spell': spec.aura_spell, 'target': spec.cast_target},
               measurement(threat_tick_aura_label(spec, AFTER), spec.cast_target, 'aura_duration_ms',
                           spell=spec.aura_spell)])


def tick_words(ticks: int) -> tuple[str, str]:
    if ticks == 1:
        return 'let exactly one periodic tick fire', 'exactly one of its periodic ticks fires'
    return f'let exactly {ticks} periodic ticks fire', f'exactly {ticks} of its periodic ticks fire'


def threat_tick_ratio_scenario(class_file: dict, spec: ThreatTickRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'threat_tick_ratio', spec.quote, spec.expected_ratio)
    before_label = threat_tick_ratio_label(spec, BEFORE)
    after_label = threat_tick_ratio_label(spec, AFTER)
    wait_words, contract_words = tick_words(spec.ticks)
    learned, application = threat_tick_application(records, spec)
    attackers = [CASTER] + ([ALLY] if spec.cast_target == ALLY else [])
    attack = ([{'action': 'attack', 'actor': unit, 'target': TARGET} for unit in attackers]
              + [{'action': 'wait', 'label': 'build threat on the dummy', 'ms': spec.attack_wait_ms}]
              + [{'action': 'stop_attack', 'actor': unit} for unit in attackers])
    before = [measurement(before_label, TARGET, 'threat', target=spec.threat_unit)]
    tick = [{'action': 'wait', 'label': wait_words, 'ms': spec.tick_wait_ms},
            measurement(after_label, TARGET, 'threat', target=spec.threat_unit)]
    ordered = attack + application + before if spec.cast_target else attack + before + application
    steps = base_steps(class_file) + ally_group_steps(set(attackers)) + learned + ordered + tick
    suffix = f' {spec.label_suffix}' if spec.label_suffix else ''
    applied = (f'{spec.aura_spell} is cast by the caster on the {spec.cast_target} (its aura read absent before '
               f'the cast and present after it) and' if spec.cast_target
               else f'{spec.aura_spell} is set directly on the caster and')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour threat tick ratio{suffix}',
        'contract': f'The dummy\'s own threat against the {spec.threat_unit} is read once after '
                    f'{" and ".join(f"the {unit}" for unit in attackers)} build'
                    f'{"s" if len(attackers) == 1 else ""} it through '
                    f'real melee attacks, and once more after {applied} '
                    f'{contract_words} ({spec.tick_wait_ms} ms), isolating the percentage '
                    f'the tick removes as a ratio rather than an absolute value, since the baseline threat a real '
                    f'attack sequence builds is not a deterministic number.',
        'players': [player_fixture(class_file)] + ally_players(class_file, set(attackers)),
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    label = threat_tick_ratio_entry_label(spec.spell, spec.label_suffix)
    model = {'kind': 'metric_ratio_delta', 'before_label': before_label, 'after_label': after_label,
             'expected_ratio': spec.expected_ratio, 'tolerance': spec.tolerance, 'metric': 'threat',
             'quote': entry.quote}
    if spec.ticks != 1:
        model['ticks'] = spec.ticks
    if spec.cast_target:
        model['aura_before_label'] = threat_tick_aura_label(spec, BEFORE)
        model['aura_after_label'] = threat_tick_aura_label(spec, AFTER)
    expectation = Expectation(label, BEHAVIOUR_METRIC_RATIO_DELTA, spec.spell, spec.aura_spell, None,
                              str(spec.expected_ratio), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def threat_tick_ratio_entry_label(spell: int, suffix: str = '') -> str:
    return f'{spell} {BEHAVIOUR_METRIC_RATIO_DELTA}' + (f' {suffix}' if suffix else '')


def threat_tick_ratio_spec(entry: dict) -> ThreatTickRatioSpec:
    cast_target = entry.get('cast_target')
    threat_unit = entry.get('threat_unit', cast_target or CASTER)
    if cast_target not in (None, CASTER, ALLY):
        raise ValueError(f'{entry["spell"]} threat_tick_ratio casts {entry["aura_spell"]} on {cast_target!r}, not '
                         f'on {CASTER!r} or {ALLY!r}')
    if threat_unit not in (CASTER, cast_target):
        raise ValueError(f'{entry["spell"]} threat_tick_ratio reads the threat of {threat_unit!r}, which neither '
                         f'casts nor receives {entry["aura_spell"]}')
    if cast_target and entry.get('aura_stacks', 1) != 1:
        raise ValueError(f'{entry["spell"]} threat_tick_ratio casts {entry["aura_spell"]}, which applies one stack, '
                         f'not aura_stacks {entry["aura_stacks"]}')
    return ThreatTickRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['expected_ratio'],
                               entry['aura_spell'], entry.get('attack_wait_ms', 3000),
                               entry.get('tick_wait_ms', 1200), entry.get('tolerance', 0.005),
                               entry.get('aura_stacks', 1), entry.get('ticks', 1), entry.get('label_suffix', ''),
                               cast_target, threat_unit)


@dataclass(frozen=True)
class AbsorbPierceRatioSpec:
    spell: int
    name: str
    quote: str
    expected_ratio: float
    damage_spell: int
    shield_aura: int
    tolerance: float
    wait_ms: int = DEFAULT_ABSORB_PIERCE_WAIT_MS
    target_auras: tuple[tuple[int, int], ...] = ()


def absorb_pierce_damage_label(spec: AbsorbPierceRatioSpec, phase: str) -> str:
    return f'{spec.spell} {spec.damage_spell} spell_damage_total {phase}'


def absorb_pierce_shield_label(spec: AbsorbPierceRatioSpec, moment: str) -> str:
    return f'{spec.spell} {spec.shield_aura} aura_amount {moment}'


def absorb_pierce_ratio_scenario(class_file: dict, spec: AbsorbPierceRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'absorb_pierce_ratio', spec.quote, spec.expected_ratio)
    facts = facts_of(records, spec.spell)
    zero_label = absorb_pierce_damage_label(spec, 'zero')
    unshielded_label = absorb_pierce_damage_label(spec, 'unshielded')
    shielded_label = absorb_pierce_damage_label(spec, 'shielded')
    shield_before_label = absorb_pierce_shield_label(spec, BEFORE)
    shield_after_label = absorb_pierce_shield_label(spec, AFTER)

    def cast_steps() -> list[dict]:
        steps = [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
        steps += required_aura_steps(facts)
        steps += [{'action': 'set_aura', 'actor': CASTER, 'target': TARGET, 'spell': aura, 'stacks': stacks}
                  for aura, stacks in spec.target_auras]
        steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': TARGET})
        steps.append({'action': 'wait', 'label': f'{spec.spell} settle', 'ms': spec.wait_ms})
        return steps

    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + [
        measurement(zero_label, CASTER, 'spell_damage_total', spell=spec.damage_spell, target=TARGET)] + \
        cast_steps() + [
        measurement(unshielded_label, CASTER, 'spell_damage_total', spell=spec.damage_spell, target=TARGET),
        {'action': 'set_aura', 'actor': CASTER, 'target': TARGET, 'spell': spec.shield_aura, 'stacks': 1},
        {'action': 'assert', 'label': f'{spec.spell} SETUP: the shield is up on the dummy', 'actor': TARGET,
         'metric': 'aura', 'spell': spec.shield_aura, 'equals': 1, 'within_ms': 2000},
        measurement(shield_before_label, TARGET, 'aura_amount', spell=spec.shield_aura, effect=0)] + \
        cast_steps() + [
        measurement(shielded_label, CASTER, 'spell_damage_total', spell=spec.damage_spell, target=TARGET),
        measurement(shield_after_label, TARGET, 'aura_amount', spell=spec.shield_aura, effect=0)]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour absorb pierce ratio',
        'contract': f'{spec.damage_spell}\'s own cumulative spell_damage_total against the dummy is read once '
                    f'with no shield present and once more after {spec.shield_aura} is set directly on the '
                    f'dummy (recipient of its own real SPELL_AURA_SCHOOL_ABSORB effect), isolating whether the '
                    f'second cast\'s own damage increment is reduced by that shield; {spec.shield_aura}\'s own '
                    f'remaining aura_amount is read immediately before and after that second cast too, so a '
                    f'shield the piercing claim should leave untouched cannot quietly absorb part of the hit '
                    f'without the damage ratio catching it.',
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    label = f'{spec.spell} {BEHAVIOUR_ABSORB_PIERCE_RATIO}'
    model = {'kind': 'absorb_pierce_ratio', 'zero_label': zero_label, 'unshielded_label': unshielded_label,
             'shielded_label': shielded_label, 'shield_before_label': shield_before_label,
             'shield_after_label': shield_after_label, 'expected_ratio': spec.expected_ratio,
             'tolerance': spec.tolerance, 'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_ABSORB_PIERCE_RATIO, spec.spell, spec.shield_aura, None,
                              str(spec.expected_ratio), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def absorb_pierce_ratio_spec(entry: dict) -> AbsorbPierceRatioSpec:
    return AbsorbPierceRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['expected_ratio'],
                                 entry['damage_spell'], entry['shield_aura'], entry.get('tolerance', 0.05),
                                 entry.get('wait_ms', DEFAULT_ABSORB_PIERCE_WAIT_MS),
                                 tuple((int(spell), int(stacks)) for spell, stacks in entry.get('target_auras', ())))


@dataclass(frozen=True)
class CastAppliesAuraSpec:
    spell: int
    name: str
    quote: str
    expected_ms: float
    applied_aura: int
    target: str = CASTER
    cast_spell: int | None = None
    cast_target: str | None = None
    control_ms: float | None = None
    control_clear: tuple[int, ...] = ()
    label_suffix: str = ''
    extra_cast: 'ExtraCast | None' = None
    cast_target_health_pct: int | None = None
    force_crit: str | None = None
    caster_auras: tuple[int, ...] = ()


@dataclass(frozen=True)
class ExtraCast:
    spell: int
    target: str
    after_ms: int


def cast_applies_aura_steps(records: Records, spec: CastAppliesAuraSpec) -> tuple[list[dict], list[dict]]:
    auras = [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1} for aura in spec.caster_auras]
    if spec.cast_spell is None:
        return [], auras + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': spec.target}]
    facts = facts_of(records, spec.cast_spell)
    target = spec.cast_target or spec.target
    health = [] if spec.cast_target_health_pct is None else [fixture_health_step(target, spec.cast_target_health_pct)]
    return ([{'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell}],
            cast_gate_power_step(facts) + required_aura_steps(facts) + auras + health
            + [{'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': target}])


def extra_cast_setup(records: Records, extra: ExtraCast | None, known: int) -> list[dict]:
    if extra is None:
        return []
    learn = [] if extra.spell == known else [{'action': 'learn', 'actor': CASTER, 'spell': extra.spell}]
    return learn + required_target_health_steps(facts_of(records, extra.spell), extra.target)


def extra_cast_steps(records: Records, extra: ExtraCast) -> list[dict]:
    facts = facts_of(records, extra.spell)
    return ([{'action': 'wait', 'label': f'{extra.spell} extra cast wait', 'ms': extra.after_ms},
             {'action': 'reset_cooldown', 'actor': CASTER, 'spell': extra.spell}]
            + cast_gate_power_step(facts) + required_aura_steps(facts)
            + [{'action': 'cast', 'actor': CASTER, 'spell': extra.spell, 'target': extra.target}])


def cast_applies_aura_label(spec: CastAppliesAuraSpec, moment: str) -> str:
    return f'{spec.spell} {spec.applied_aura} aura_duration_ms cast_applies_aura {moment}'


def cast_applies_aura_scenario(class_file: dict, spec: CastAppliesAuraSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'cast_applies_aura', spec.quote, spec.expected_ms)
    before_label = cast_applies_aura_label(spec, BEFORE)
    after_label = cast_applies_aura_label(spec, AFTER)
    learned, cast = cast_applies_aura_steps(records, spec)
    extra = extra_cast_steps(records, spec.extra_cast) if spec.extra_cast else []
    expected_ms = spec.expected_ms - (spec.extra_cast.after_ms if spec.extra_cast else 0)
    steps = (base_steps(class_file) + ally_group_steps({spec.cast_target})
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + learned
             + extra_cast_setup(records, spec.extra_cast, spec.spell)
             + [measurement(before_label, spec.target, 'aura_duration_ms', spell=spec.applied_aura)] + cast + extra
             + [measurement(after_label, spec.target, 'aura_duration_ms', spell=spec.applied_aura)])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cast applies aura',
        'contract': f'{spec.applied_aura}\'s remaining aura_duration_ms on the {spec.target} is read once right '
                    f'after {spec.spell} is learned, before it is ever cast (expected absent, 0 ms, since nothing else '
                    f'in this scenario could have applied {spec.applied_aura}), and once right after casting '
                    f'{spec.spell} (expected within {CAST_MARGIN_MS:g} ms below its own SpellDuration.dbc value '
                    f'of {spec.expected_ms:g} ms, the same instant-cast tick loss every aura_duration_ms check in '
                    f'this tool tolerates), proving the cast itself applies {spec.applied_aura} rather than only '
                    f'its $d token matching when read without a cast.',
        'players': [cast_applies_aura_player(class_file, spec)] + ally_players(class_file, {spec.cast_target}),
        'steps': steps}
    if TARGET in (spec.target, spec.cast_target):
        scenario['creatures'] = [creature_fixture(class_file)]
    label = f'{spec.spell} behaviour_cast_applies_aura' + (f' {spec.label_suffix}' if spec.label_suffix else '')
    if spec.extra_cast:
        scenario['contract'] += (f' {spec.extra_cast.spell} is cast at the {spec.extra_cast.target} '
                                 f'{spec.extra_cast.after_ms} ms after the cast and before the second read, which '
                                 f'expects the stated {spec.expected_ms:g} ms less those {spec.extra_cast.after_ms} '
                                 f'ms.')
    model = {'kind': 'cast_applies_aura', 'before_label': before_label, 'after_label': after_label,
             'expected_ms': expected_ms, 'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_CAST_APPLIES_AURA, spec.spell, spec.applied_aura, None,
                              str(spec.expected_ms), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def cast_applies_aura_player(class_file: dict, spec: CastAppliesAuraSpec) -> dict:
    player = player_fixture(class_file)
    return {**player, FORCE_CRIT_RATINGS[spec.force_crit]: FORCED_CRIT_RATING} if spec.force_crit else player


def cast_applies_aura_spec(entry: dict) -> CastAppliesAuraSpec:
    control = entry.get('control')
    force_crit = entry.get('force_crit')
    if force_crit is not None and (force_crit not in FORCE_CRIT_RATINGS or entry.get('cast_spell') is None):
        raise ValueError(f'{entry["spell"]} cast_applies_aura forces a {force_crit!r} crit, which needs a cast_spell '
                         f'and one of {sorted(FORCE_CRIT_RATINGS)}')
    if control is not None and entry.get('cast_spell') is None:
        raise ValueError(f'{entry["spell"]} cast_applies_aura sets a control arm without a cast_spell to cast '
                         f'before {entry["spell"]} is learned')
    raw = control.get('extra_cast') if control else None
    if raw is not None and set(raw) != {'spell', 'target', 'after_ms'}:
        raise ValueError(f'{entry["spell"]} cast_applies_aura extra_cast names {sorted(raw)}, not spell, target and '
                         f'after_ms')
    extra = ExtraCast(raw['spell'], raw['target'], int(raw['after_ms'])) if raw is not None else None
    return CastAppliesAuraSpec(entry['spell'], entry['name'], entry['quote'], entry['expected_ms'],
                               entry['applied_aura'], entry.get('target', CASTER), entry.get('cast_spell'),
                               entry.get('cast_target'), control['expected_ms'] if control else None,
                               tuple(control.get('clear_auras', ())) if control else (),
                               entry.get('label_suffix', ''), extra, entry.get('cast_target_health_pct'), force_crit,
                               tuple(int(aura) for aura in entry.get('caster_auras', ())))


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


def crit_guarantee_control_labels(spec: CritGuaranteeSpec) -> tuple[str, str]:
    return (f'{spec.spell} {spec.trial_spell} crit_guarantee control crit',
            f'{spec.spell} {spec.trial_spell} crit_guarantee control noncrit')


def crit_guarantee_scenario(class_file: dict, spec: CritGuaranteeSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'crit_guarantee', spec.quote, 1.0)
    crit_label, noncrit_label = crit_guarantee_labels(spec)
    control_crit_label, control_noncrit_label = crit_guarantee_control_labels(spec)
    attempt_ms = swing_interval(class_file)
    waited_ms = spec.attempts * attempt_ms
    target = {**creature_fixture(class_file), 'entry': spec.target_entry, 'reaction': 0}
    control = {**creature_fixture(class_file), 'id': CRIT_GUARANTEE_CONTROL_TARGET, 'reaction': 0}
    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
             {'action': 'attack', 'actor': CASTER, 'target': TARGET},
             {'action': 'wait', 'label': 'swings', 'ms': waited_ms},
             {'action': 'stop_attack', 'actor': CASTER},
             {'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS},
             measurement(crit_label, CASTER, 'spell_damage_count', spell=spec.trial_spell, target=TARGET,
                        critical=True),
             measurement(noncrit_label, CASTER, 'spell_damage_count', spell=spec.trial_spell, target=TARGET,
                        critical=False),
             {'action': 'attack', 'actor': CASTER, 'target': CRIT_GUARANTEE_CONTROL_TARGET},
             {'action': 'wait', 'label': 'control swings', 'ms': waited_ms},
             {'action': 'stop_attack', 'actor': CASTER},
             {'action': 'wait', 'label': 'control drain', 'ms': DRAIN_MS},
             measurement(control_crit_label, CASTER, 'spell_damage_count', spell=spec.trial_spell,
                        target=CRIT_GUARANTEE_CONTROL_TARGET, critical=True),
             measurement(control_noncrit_label, CASTER, 'spell_damage_count', spell=spec.trial_spell,
                        target=CRIT_GUARANTEE_CONTROL_TARGET, critical=False)])
    scenario = {'schema': 1,
               'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour crit guarantee',
               'contract': f'{spec.attempts} auto-attack swings against a {spec.target_type_name} target '
                           f'(creature_template.type {spec.target_type}, entry {spec.target_entry}); every '
                           f'triggered hit of {spec.trial_spell} logged against it must be critical. A further '
                           f'{spec.attempts} swings against a non-{spec.target_type_name} control target (entry '
                           f'{DUMMY_ENTRY}) must NOT read an unconditional 100% crit ratio, proving the guarantee '
                           f'is specific to {spec.target_type_name} and not a universal crit override.',
               'players': [player_fixture(class_file)], 'creatures': [target, control], 'steps': steps,
               'timeout_ms': 2 * (waited_ms + DRAIN_MS) + TIMEOUT_MARGIN_MS}
    label = f'{spec.spell} behaviour_crit_guarantee {spec.trial_spell}'
    model = {'crit_label': crit_label, 'noncrit_label': noncrit_label, 'minimum_events': spec.minimum_events,
            'trial_spell': spec.trial_spell, 'target_name': f'{spec.target_type_name} (entry {spec.target_entry})',
            'creature_type_source': f'creature_template.type {spec.target_type} ({spec.target_type_name})',
            'control_crit_label': control_crit_label, 'control_noncrit_label': control_noncrit_label,
            'control_target_name': f'a non-{spec.target_type_name} control (entry {DUMMY_ENTRY})',
            'control_max_ratio': CRIT_GUARANTEE_CONTROL_MAX_RATIO, 'quote': entry.quote}
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


OATH_CONSUMPTION_SETTLE_MS = 500


@dataclass(frozen=True)
class OathConsumptionSpec:
    spell: int
    name: str
    quote: str
    trigger_spell: int
    oath_spell: int
    relation: str
    expected: float
    metric: str
    effect: int = 0
    periodic: bool = False
    target: str = TARGET
    other_oath_spell: int = 0


def oath_consumption_label(spec: OathConsumptionSpec, moment: str) -> str:
    return f'{spec.spell} {spec.metric} oath_consumption_{moment}'


def oath_consumption_scenario(class_file: dict, spec: OathConsumptionSpec) -> tuple[dict, list[Expectation]]:
    if spec.relation not in ('ratio', 'flat'):
        raise NotModelled(f'oath_consumption relation {spec.relation!r} is neither ratio nor flat')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'oath_consumption', spec.quote, spec.expected)
    class_file = armed_for(class_file, records, spec.trigger_spell)
    facts = facts_of(records, spec.trigger_spell)
    before_label = oath_consumption_label(spec, BEFORE)
    after_label = oath_consumption_label(spec, AFTER)
    stacks_label = f'{spec.oath_spell} aura_stacks oath_consumption {spec.spell} after'
    read_fields = {'spell': spec.trigger_spell, 'target': spec.target, 'effect': spec.effect,
                  'periodic': spec.periodic}
    steps = [measurement(before_label, CASTER, spec.metric, **read_fields),
             {'action': 'set_aura', 'actor': CASTER, 'spell': spec.oath_spell, 'stacks': 1},
             measurement(after_label, CASTER, spec.metric, **read_fields)]
    other_alone_label = other_label = other_stacks_label = None
    if spec.other_oath_spell:
        other_alone_label = f'{spec.other_oath_spell} {spec.metric} oath_consumption_other_alone'
        other_label = f'{spec.oath_spell}+{spec.other_oath_spell} {spec.metric} oath_consumption_both'
        other_stacks_label = f'{spec.other_oath_spell} aura_stacks oath_consumption {spec.spell} after'
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.oath_spell, 'stacks': 0},
                 {'action': 'set_aura', 'actor': CASTER, 'spell': spec.other_oath_spell, 'stacks': 1},
                 measurement(other_alone_label, CASTER, spec.metric, **read_fields),
                 {'action': 'set_aura', 'actor': CASTER, 'spell': spec.oath_spell, 'stacks': 1},
                 measurement(other_label, CASTER, spec.metric, **read_fields)]
    if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                     'value': facts.mana_cost})
    steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
    steps += required_aura_steps(facts)
    steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': spec.target})
    steps.append({'action': 'wait', 'ms': OATH_CONSUMPTION_SETTLE_MS})
    steps.append(measurement(stacks_label, CASTER, 'aura_stacks', spell=spec.oath_spell))
    if spec.other_oath_spell:
        steps.append(measurement(other_stacks_label, CASTER, 'aura_stacks', spell=spec.other_oath_spell))
    other_contract = ''
    if spec.other_oath_spell:
        other_contract = (f' A second, different Oath aura {spec.other_oath_spell} is also fixtured alone (with '
                          f'{spec.oath_spell} cleared) and then together with {spec.oath_spell}; the combined '
                          f'reading must match each Oath\'s own standalone contribution over the no-Oath baseline '
                          f'(ratio relations compound multiplicatively, flat relations add), proving the plural '
                          f'"for each consumed" wording credits distinct held Oaths rather than crediting only '
                          f'one. {spec.other_oath_spell}\'s own aura_stacks must also read 0 after the cast: every '
                          f'held Oath type is consumed, not just the one this metric happens to measure.')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour oath consumption',
        'contract': f'{spec.metric} of {spec.trigger_spell} (effect {spec.effect}) is read once with no Oath held '
                    f'and once immediately after fixturing Oath aura {spec.oath_spell} to 1 stack (set_aura, no '
                    f'cast), a deterministic formula call with no combat roll; the {spec.relation} delta between '
                    f'the two readings must match the Oath\'s own Spell.dbc SpellMod effect. {spec.trigger_spell} '
                    f'is then actually cast once and {spec.oath_spell}\'s aura_stacks is read afterward, which '
                    f'must read 0: casting a Breaker spell consumes the Oath (AscensionTemplar.cpp '
                    f'ClearOaths).{other_contract}',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}]
                 + steps}
    if spec.target == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    label = f'{spec.spell} behaviour_oath_consumption'
    model = {'kind': 'oath_consumption', 'before_label': before_label, 'after_label': after_label,
            'stacks_label': stacks_label, 'relation': spec.relation, 'expected': spec.expected,
            'metric': spec.metric, 'oath_spell': spec.oath_spell, 'quote': entry.quote}
    if spec.other_oath_spell:
        model.update(other_oath_spell=spec.other_oath_spell, other_alone_label=other_alone_label,
                     both_label=other_label, other_stacks_label=other_stacks_label)
    expectation = Expectation(label, BEHAVIOUR_OATH_CONSUMPTION, spec.spell, spec.trigger_spell, None,
                              str(spec.expected), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def oath_consumption_spec(entry: dict) -> OathConsumptionSpec:
    return OathConsumptionSpec(entry['spell'], entry['name'], entry['quote'], entry['trigger_spell'],
                               entry['oath_spell'], entry['relation'], entry['expected'], entry['metric'],
                               entry.get('effect', 0), entry.get('periodic', False), entry.get('target', TARGET),
                               entry.get('other_oath_spell', 0))


OATH_CONSUMPTION_REMOVAL_SETTLE_MS = 500
OATH_CONSUMPTION_REMOVAL_EXPIRE_MARGIN_MS = 1500


@dataclass(frozen=True)
class OathConsumptionRemovalSpec:
    spell: int
    name: str
    quote: str
    trigger_spell: int
    oath_spells: tuple[int, ...]
    oath_effect: int = 2
    settle_ms: int = OATH_CONSUMPTION_REMOVAL_SETTLE_MS
    expire_margin_ms: int = OATH_CONSUMPTION_REMOVAL_EXPIRE_MARGIN_MS


def oath_consumption_removal_amount_label(spec: OathConsumptionRemovalSpec, oath: int) -> str:
    return f'{spec.spell} {oath} aura_amount oath_consumption_removal before'


def oath_consumption_removal_script_label(spec: OathConsumptionRemovalSpec) -> str:
    return f'{spec.spell} aura_script_value oath_consumption_removal'


def oath_consumption_removal_stacks_label(spec: OathConsumptionRemovalSpec, oath: int, moment: str) -> str:
    return f'{spec.spell} {oath} aura_stacks oath_consumption_removal {moment}'


def oath_consumption_removal_scenario(class_file: dict, spec: OathConsumptionRemovalSpec
                                      ) -> tuple[dict, list[Expectation]]:
    if not spec.oath_spells:
        raise NotModelled('oath_consumption_removal needs at least one oath_spell')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'oath_consumption_removal', spec.quote, 0.0)
    class_file = armed_for(class_file, records, spec.trigger_spell)
    facts = facts_of(records, spec.trigger_spell)
    amount_labels = [oath_consumption_removal_amount_label(spec, oath) for oath in spec.oath_spells]
    script_label = oath_consumption_removal_script_label(spec)
    before_removal_labels = [oath_consumption_removal_stacks_label(spec, oath, 'held') for oath in spec.oath_spells]
    after_removal_labels = [oath_consumption_removal_stacks_label(spec, oath, 'removed')
                            for oath in spec.oath_spells]
    duration_ms = records.duration_ms(spec.trigger_spell)
    remaining_ms = max(0, int(duration_ms) - spec.settle_ms) + spec.expire_margin_ms
    steps = []
    if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                     'value': facts.mana_cost})
    steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell})
    steps += required_aura_steps(facts)
    for oath in spec.oath_spells:
        steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': oath, 'stacks': 1})
    for oath, label in zip(spec.oath_spells, amount_labels):
        steps.append(measurement(label, CASTER, 'aura_amount', spell=oath, effect=spec.oath_effect))
    steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': CASTER})
    steps.append({'action': 'wait', 'label': f'{spec.spell} oath consumption removal settle', 'ms': spec.settle_ms})
    steps.append(measurement(script_label, CASTER, 'aura_script_value', spell=spec.trigger_spell,
                             key=spec.trigger_spell))
    for oath, label in zip(spec.oath_spells, before_removal_labels):
        steps.append(measurement(label, CASTER, 'aura_stacks', spell=oath))
    steps.append({'action': 'wait', 'label': f'{spec.spell} let the lifecycle aura expire', 'ms': remaining_ms})
    for oath, label in zip(spec.oath_spells, after_removal_labels):
        steps.append(measurement(label, CASTER, 'aura_stacks', spell=oath))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour oath consumption removal',
        'contract': f'Each of {spec.oath_spells} is fixtured to 1 stack (set_aura, no cast) and its own EFFECT_'
                    f'{spec.oath_effect} aura_amount is read; {spec.trigger_spell} is then cast once at the caster '
                    f'and, {spec.settle_ms} ms later (well inside its own {duration_ms:g} ms duration), its own '
                    f'applied aura\'s aura_script_value (key {spec.trigger_spell}) must equal the sum of the '
                    f'fixtured Oaths\' own aura_amount readings; every Oath\'s own aura_stacks must still read 1 at '
                    f'that same moment (the Oath is not consumed by the cast), then after waiting out the rest of '
                    f'the aura\'s duration plus a {spec.expire_margin_ms} ms margin so it expires naturally, every '
                    f'Oath\'s own aura_stacks must read 0 (consumed only once the lifecycle aura is removed, '
                    f'AscensionTemplarAuras.cpp aura_ascension_templar_lifecycle::Remove).',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}]
                 + steps}
    label = f'{spec.spell} behaviour_oath_consumption_removal'
    model = {'kind': 'oath_consumption_removal', 'amount_labels': amount_labels, 'script_label': script_label,
            'before_removal_labels': before_removal_labels, 'after_removal_labels': after_removal_labels,
            'oath_spells': list(spec.oath_spells), 'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_OATH_CONSUMPTION_REMOVAL, spec.spell, spec.trigger_spell, None,
                              'sum(oath aura_amount)', prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def oath_consumption_removal_spec(entry: dict) -> OathConsumptionRemovalSpec:
    return OathConsumptionRemovalSpec(entry['spell'], entry['name'], entry['quote'], entry['trigger_spell'],
                                      tuple(entry['oath_spells']), entry.get('oath_effect', 2),
                                      entry.get('settle_ms', OATH_CONSUMPTION_REMOVAL_SETTLE_MS),
                                      entry.get('expire_margin_ms', OATH_CONSUMPTION_REMOVAL_EXPIRE_MARGIN_MS))


ICD_GATE_REOPEN_MARGIN_MS = 500
ICD_GATE_FORCE_CRIT_RATINGS = {'melee': 'melee_crit_rating', 'spell': 'spell_crit_rating'}


@dataclass(frozen=True)
class IcdGateSpec:
    spell: int
    name: str
    quote: str
    trigger_spell: int
    observe_spell: int
    internal_cooldown_ms: int
    target: str | None = TARGET
    caster_health_pct: int | None = None
    restore_charges: bool = False
    force_crit: str | None = None
    reopen_margin_ms: int = ICD_GATE_REOPEN_MARGIN_MS
    trigger_actor: str = CASTER
    striker_entry: int | None = None


def icd_gate_label(spec: IcdGateSpec, moment: str) -> str:
    return f'{spec.spell} spell_cast_count icd_gate_{moment}'


def icd_gate_attempt_fixtures(spec: IcdGateSpec) -> list[dict]:
    fixtures = []
    if spec.target == ALLY:
        fixtures.append({'action': 'relocate', 'actor': CASTER, 'dx': CHARGE_OFFSET_YD})
    if spec.restore_charges:
        fixtures.append({'action': 'restore_charges', 'actor': CASTER, 'spell': spec.trigger_spell})
    if spec.caster_health_pct is not None:
        fixtures.append(fixture_health_step(CASTER, spec.caster_health_pct))
    return fixtures


def icd_gate_striker_attempt(spec: IcdGateSpec, gap_ms: int) -> list[dict]:
    return [{'action': 'cast', 'actor': STRIKER, 'spell': spec.trigger_spell, 'target': CASTER},
            {'action': 'wait', 'ms': gap_ms}]


def icd_gate_scenario(class_file: dict, spec: IcdGateSpec) -> tuple[dict, list[Expectation]]:
    if spec.internal_cooldown_ms <= 0:
        raise NotModelled('internal_cooldown_gate needs a positive internal_cooldown_ms')
    if spec.trigger_actor == STRIKER and not (spec.striker_entry and spec.striker_entry > 0):
        raise ValueError(f'{spec.spell} internal_cooldown_gate needs a positive striker_entry when triggered by a '
                          f'striker')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'internal_cooldown_gate', spec.quote, 0.0)
    short_gap_ms = max(1, spec.internal_cooldown_ms // 2)
    reopen_gap_ms = spec.internal_cooldown_ms - short_gap_ms + spec.reopen_margin_ms
    labels = {moment: icd_gate_label(spec, moment) for moment in ('after1', 'after2', 'after3')}
    steps = []
    learn_steps = [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    if spec.trigger_actor == STRIKER:
        attempt = lambda gap_ms: icd_gate_striker_attempt(spec, gap_ms)
    else:
        class_file = armed_for(class_file, records, spec.trigger_spell)
        facts = facts_of(records, spec.trigger_spell)
        cast_target = spec.target if spec.target in (TARGET, ALLY) else None
        fixtures = icd_gate_attempt_fixtures(spec)
        attempt = lambda gap_ms: cast_steps(facts, spec.trigger_spell, cast_target, gap_ms, 1, fixtures)
        learn_steps = [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}] + learn_steps
        if spec.target == ALLY:
            steps.append({'action': 'group', 'actor': CASTER, 'target': ALLY})
    steps += attempt(short_gap_ms)
    steps.append(measurement(labels['after1'], CASTER, 'spell_cast_count', spell=spec.observe_spell))
    steps += attempt(reopen_gap_ms)
    steps.append(measurement(labels['after2'], CASTER, 'spell_cast_count', spell=spec.observe_spell))
    steps += attempt(DRAIN_MS)
    steps.append(measurement(labels['after3'], CASTER, 'spell_cast_count', spell=spec.observe_spell))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour internal cooldown gate',
        'contract': f'Three {"strikes" if spec.trigger_actor == STRIKER else "casts"} of {spec.trigger_spell}, '
                    f'{short_gap_ms} ms then {reopen_gap_ms} ms apart (total {short_gap_ms + reopen_gap_ms} ms, '
                    f'{spec.reopen_margin_ms} ms past the tooltip\'s own {spec.internal_cooldown_ms} ms internal '
                    f'cooldown): {spec.observe_spell}\'s spell_cast_count is read after each. It must not increase '
                    f'between the first and second cast (the gate is still closed {short_gap_ms} ms after the '
                    f'first fire, inside the {spec.internal_cooldown_ms} ms window) and must increase by exactly 1 '
                    f'between the second and third (the gate has reopened by then).',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file) + learn_steps + steps}
    if spec.trigger_actor == STRIKER:
        scenario['creatures'] = [{'id': STRIKER, 'owner': CASTER, 'entry': spec.striker_entry,
                                  'level': class_file['level'], 'health': STRIKER_HEALTH,
                                  'distance': STRIKER_DISTANCE, 'reaction': 0, 'stationary': True}]
    elif spec.target == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    if spec.target == ALLY:
        scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    if spec.force_crit:
        scenario['players'][0][ICD_GATE_FORCE_CRIT_RATINGS[spec.force_crit]] = FORCED_CRIT_RATING
    model = {'kind': 'internal_cooldown_gate', 'after1_label': labels['after1'], 'after2_label': labels['after2'],
            'after3_label': labels['after3'], 'internal_cooldown_ms': spec.internal_cooldown_ms,
            'short_gap_ms': short_gap_ms, 'reopen_gap_ms': reopen_gap_ms, 'quote': entry.quote}
    expectation = Expectation(f'{spec.spell} behaviour_internal_cooldown_gate', BEHAVIOUR_INTERNAL_COOLDOWN_GATE,
                              spec.spell, spec.trigger_spell, None, '1', prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def icd_gate_spec(entry: dict) -> IcdGateSpec:
    return IcdGateSpec(entry['spell'], entry['name'], entry['quote'], entry['trigger_spell'],
                      entry['observe_spell'], entry['internal_cooldown_ms'], entry.get('target', TARGET),
                      entry.get('caster_health_pct'), entry.get('restore_charges', False),
                      entry.get('force_crit'), entry.get('reopen_margin_ms', ICD_GATE_REOPEN_MARGIN_MS),
                      entry.get('trigger_actor', CASTER), entry.get('striker_entry'))
EXCLUSIVITY_CAST_WAIT_MS = 300


@dataclass(frozen=True)
class ExclusivityChainSpec:
    spell: int
    name: str
    quote: str
    chain: tuple[int, ...]
    wait_ms: int = EXCLUSIVITY_CAST_WAIT_MS


def exclusivity_label(spell: int, phase: str) -> str:
    return f'{spell} aura {phase}'


def exclusivity_chain_scenario(class_file: dict, spec: ExclusivityChainSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    if len(spec.chain) < 2:
        raise ValueError(f'{spec.name} exclusivity chain needs at least 2 spells, got {spec.chain}')
    for member in spec.chain:
        behaviour_entry(records, member, spec.name, 'exclusivity', spec.quote, 1.0)

    def cast_steps(sid: int) -> list[dict]:
        facts = facts_of(records, sid)
        steps = []
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
        steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': sid})
        steps += required_aura_steps(facts)
        steps.append({'action': 'cast', 'actor': CASTER, 'spell': sid, 'target': CASTER})
        steps.append({'action': 'wait', 'ms': spec.wait_ms})
        return steps

    sequence = list(spec.chain) + [spec.chain[0]]
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': sid} for sid in spec.chain]
    steps += cast_steps(sequence[0])
    steps.append(measurement(exclusivity_label(sequence[0], 'kept_initial'), CASTER, 'aura', spell=sequence[0]))
    expectations = []
    for previous, following in zip(sequence, sequence[1:]):
        steps += cast_steps(following)
        removed_label = exclusivity_label(previous, f'removed_by_{following}')
        kept_label = exclusivity_label(following, f'kept_after_{previous}')
        steps.append(measurement(removed_label, CASTER, 'aura', spell=previous))
        steps.append(measurement(kept_label, CASTER, 'aura', spell=following))
        model = {'kind': 'exclusivity', 'removed_label': removed_label, 'kept_label': kept_label,
                 'removed_spell': previous, 'kept_spell': following, 'quote': spec.quote}
        expectations.append(Expectation(f'{previous} behaviour_exclusivity', BEHAVIOUR_EXCLUSIVITY, previous,
                                        following, None, '0', prose_rule(spec.quote, previous), model))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} behaviour exclusivity',
        'contract': f'Casts each spell of the mutual exclusivity chain {spec.chain} in turn, looping back to the '
                    f'first member, and after each cast reads the just-cast member\'s own aura (expected 1, kept) '
                    f'and the previous member\'s aura (expected 0, removed): {spec.quote!r}.',
        'players': [player_fixture(class_file)],
        'steps': steps}
    return scenario, expectations


def exclusivity_chain_spec(entry: dict) -> ExclusivityChainSpec:
    return ExclusivityChainSpec(entry['spell'], entry['name'], entry['quote'], tuple(entry['chain']),
                                entry.get('wait_ms', EXCLUSIVITY_CAST_WAIT_MS))


GROUP_STACK_CAP_LEARN_WAIT_MS = 300
SWING_INTERVAL_METRIC = 'event_interval_median_ms'


@dataclass(frozen=True)
class GroupStackCapSpec:
    spell: int
    name: str
    quote: str
    effect: int
    partner: int
    partner_effect: int
    metric: str
    fields: dict
    personal_effect: int | None = None
    wait_ms: int = GROUP_STACK_CAP_LEARN_WAIT_MS
    mechanism: str = 'spell_group'
    value_spell: int | None = None
    swing_ms: int = 0
    marker_spell: int | None = None
    tolerance: float | None = None


def strongest_percent(*percents: float) -> float:
    if any(value > 0 for value in percents) and any(value < 0 for value in percents):
        raise ValueError(f'percentages {list(percents)} move the metric in opposite directions; the stack cap of '
                         f'similar effects compares effects of one direction')
    return max(percents, key=abs)


def group_stack_cap_label(spec: GroupStackCapSpec, moment: str) -> str:
    return f'{spec.spell} {spec.partner} {spec.metric} {moment}'


GROUP_STACK_CAP_MECHANISM_PHRASES = {
    'spell_group': 'a different spell carrying the identical SPELL_GROUP_STACK_RULE_EXCLUSIVE_SAME_EFFECT '
                   'spell_group membership (stock Unit::GetHighestExclusiveSameEffectSpellGroupValue)',
    'aura_cap': "a different spell whose own aura is capped by the same aura type's global cap (stock "
                'Unit::GetMaxPositiveAuraModifier), with no spell_group row needed at all',
}


def group_stack_cap_scenario(class_file: dict, spec: GroupStackCapSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'group_stack_cap', spec.quote, 1.0)
    if spec.swing_ms and (spec.marker_spell is None or spec.metric != SWING_INTERVAL_METRIC
                          or spec.fields.get('since_spell') != spec.marker_spell):
        raise ValueError(f'{spec.spell} group_stack_cap swings read {SWING_INTERVAL_METRIC} since its marker_spell')
    own_pct = records.single_value(spec.value_spell or spec.spell, spec.effect)
    partner_pct = records.single_value(spec.partner, spec.partner_effect)
    personal_pct = records.single_value(spec.spell, spec.personal_effect) if spec.personal_effect is not None \
        else 0.0
    baseline_label = group_stack_cap_label(spec, 'baseline')
    own_label = group_stack_cap_label(spec, 'own')
    combined_label = group_stack_cap_label(spec, 'combined')
    def swings() -> list[dict]:
        if not spec.swing_ms:
            return []
        return [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.marker_spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.marker_spell, 'target': CASTER},
                {'action': 'attack', 'actor': CASTER, 'target': TARGET},
                {'action': 'wait', 'label': 'swings', 'ms': spec.swing_ms},
                {'action': 'stop_attack', 'actor': CASTER},
                {'action': 'wait', 'label': 'swings settle', 'ms': SWING_SETTLE_MS}]

    marker = [{'action': 'learn', 'actor': CASTER, 'spell': spec.marker_spell}] if spec.swing_ms else []
    steps = base_steps(class_file) + marker + swings() + [
        measurement(baseline_label, CASTER, spec.metric, **spec.fields)]
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
    steps.append({'action': 'wait', 'ms': spec.wait_ms})
    steps += swings() + [measurement(own_label, CASTER, spec.metric, **spec.fields)]
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.partner})
    steps.append({'action': 'wait', 'ms': spec.wait_ms})
    steps += swings() + [measurement(combined_label, CASTER, spec.metric, **spec.fields)]
    mechanism_phrase = GROUP_STACK_CAP_MECHANISM_PHRASES[spec.mechanism]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour group stack cap',
        'contract': f'Reads {spec.metric} with neither passive known, after learning {spec.spell} alone '
                    f'({own_pct:g}%, effect {spec.effect}, plus an uncapped personal '
                    f'{personal_pct:g}% from effect {spec.personal_effect} when one is given), waiting '
                    f'{spec.wait_ms} ms for the area aura\'s own target-map rescan (Aura::UpdateOwner, '
                    f'SpellAuras.cpp) to reach the caster, and again after additionally learning {spec.partner} '
                    f'({partner_pct:g}%, effect {spec.partner_effect}), {mechanism_phrase}: {spec.quote!r}. The '
                    f'combined reading must reflect only the stronger of the two area-aura percentages, never '
                    f'their sum, while any separate personal (non-area) effect of {spec.spell} keeps applying '
                    f'in full.',
        'players': [player_fixture(class_file)],
        'steps': steps}
    if spec.fields.get('target') == TARGET or spec.swing_ms:
        scenario['creatures'] = [creature_fixture(class_file)]
    if spec.swing_ms:
        timed(scenario, waited_ms(steps))
    label = f'{spec.spell} behaviour_group_stack_cap'
    model = {'kind': 'group_stack_cap', 'baseline_label': baseline_label, 'own_label': own_label,
             'combined_label': combined_label, 'own_pct': own_pct, 'partner_pct': partner_pct,
             'mechanism': spec.mechanism, 'metric': spec.metric,
             'personal_pct': personal_pct, 'quote': entry.quote}
    if spec.swing_ms:
        model['relation'] = 'inverse'
    if spec.tolerance is not None:
        model['tolerance'] = spec.tolerance
    expectation = Expectation(label, BEHAVIOUR_GROUP_STACK_CAP, spec.spell, spec.partner, None,
                              str(strongest_percent(own_pct, partner_pct)), prose_rule(entry.quote, spec.spell),
                              model)
    return scenario, [expectation]


def group_stack_cap_spec(entry: dict) -> GroupStackCapSpec:
    return GroupStackCapSpec(entry['spell'], entry['name'], entry['quote'], entry['effect'], entry['partner'],
                             entry['partner_effect'], entry['metric'], entry.get('fields', {}),
                             entry.get('personal_effect'), entry.get('wait_ms', GROUP_STACK_CAP_LEARN_WAIT_MS),
                             entry.get('mechanism', 'spell_group'), entry.get('value_spell'),
                             entry.get('swing_ms', 0), entry.get('marker_spell'), entry.get('tolerance'))


SINGLE_TARGET_CAST_WAIT_MS = 300
SINGLE_TARGET_SECOND_ALLY = 'ally2'
SINGLE_TARGET_GCD_WAIT_MS = 1600


@dataclass(frozen=True)
class SingleTargetSpec:
    spell: int
    name: str
    quote: str
    wait_ms: int = SINGLE_TARGET_CAST_WAIT_MS


def single_target_label(spec: SingleTargetSpec, moment: str) -> str:
    return f'{spec.spell} {moment}'


def single_target_scenario(class_file: dict, spec: SingleTargetSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'single_target', spec.quote, 1.0)
    class_file = armed_for(class_file, records, spec.spell)
    facts = facts_of(records, spec.spell)
    second_ally = SINGLE_TARGET_SECOND_ALLY

    def cast_steps(target: str) -> list[dict]:
        steps = []
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
        steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell})
        steps += required_aura_steps(facts)
        steps += required_target_health_steps(facts, target)
        steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': target})
        steps.append({'action': 'wait', 'ms': spec.wait_ms})
        return steps

    first_label = single_target_label(spec, 'first_after_first_cast')
    removed_label = single_target_label(spec, 'first_after_second_cast')
    second_label = single_target_label(spec, 'second_after_second_cast')
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                                      {'action': 'group', 'actor': CASTER, 'target': ALLY},
                                      {'action': 'group', 'actor': CASTER, 'target': second_ally}]
    steps += cast_steps(ALLY)
    steps.append(measurement(first_label, ALLY, 'aura', spell=spec.spell))
    steps.append({'action': 'wait', 'label': 'Global cooldown', 'ms': SINGLE_TARGET_GCD_WAIT_MS})
    steps += cast_steps(second_ally)
    steps.append(measurement(removed_label, ALLY, 'aura', spell=spec.spell))
    steps.append(measurement(second_label, second_ally, 'aura', spell=spec.spell))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour single target',
        'contract': f'Casts {spec.spell} on a first grouped ally, reads its own aura ({first_label!r}, expected '
                    f'present), then casts it again on a second grouped ally and reads the first ally\'s aura '
                    f'again ({removed_label!r}, expected removed) alongside the second ally\'s aura '
                    f'({second_label!r}, expected present): {spec.quote!r}.',
        'players': [player_fixture(class_file), {**player_fixture(class_file), 'id': ALLY},
                   {**player_fixture(class_file), 'id': second_ally}],
        'steps': steps}
    label = f'{spec.spell} behaviour_single_target'
    model = {'kind': 'single_target', 'first_label': first_label, 'removed_label': removed_label,
             'second_label': second_label, 'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_SINGLE_TARGET, spec.spell, spec.spell, None, '0',
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def single_target_spec(entry: dict) -> SingleTargetSpec:
    return SingleTargetSpec(entry['spell'], entry['name'], entry['quote'],
                            entry.get('wait_ms', SINGLE_TARGET_CAST_WAIT_MS))


GROUP_TARGET_FILLERS = ('ally2', 'ally3', 'ally4')
GROUP_TARGET_RAIDER = 'ally5'
SPELL_FAILED_BAD_TARGETS = 12


@dataclass(frozen=True)
class GroupTargetSpec:
    spell: int
    name: str
    quote: str
    outsider_result: int = SPELL_FAILED_BAD_TARGETS
    raid: bool = True


def group_target_label(spell: int, arm: str, metric: str) -> str:
    return f'{spell} group_target {arm} {metric}'


def group_target_arms(spec: GroupTargetSpec) -> list[tuple[str, str, int, int]]:
    arms = [('outsider', ALLY, spec.outsider_result, 0), ('party', ALLY, NO_CAST_FAILURE, STATE_PRESENT)]
    if spec.raid:
        arms.append(('raid', GROUP_TARGET_RAIDER, NO_CAST_FAILURE, STATE_PRESENT))
    return arms


def group_target_scenario(class_file: dict, spec: GroupTargetSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'group_target', spec.quote, NO_CAST_FAILURE)
    facts = facts_of(records, spec.spell)
    joins = {'party': [ALLY], 'raid': [*GROUP_TARGET_FILLERS, GROUP_TARGET_RAIDER]}
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    expectations = []
    rule = prose_rule(entry.quote, spec.spell)
    model = {'kind': 'group_target', 'quote': entry.quote}
    for arm, target, result, presence in group_target_arms(spec):
        steps += [{'action': 'group', 'actor': CASTER, 'target': member} for member in joins.get(arm, ())]
        cast_label = group_target_label(spec.spell, arm, 'cast')
        aura_label = group_target_label(spec.spell, arm, 'aura')
        steps += ([{'action': 'wait', 'label': f'{arm} global cooldown', 'ms': SINGLE_TARGET_GCD_WAIT_MS},
                   {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
                  + cast_gate_power_step(facts)
                  + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': target},
                     {'action': 'wait', 'ms': CAST_GATE_WAIT_MS},
                     measurement(cast_label, CASTER, 'cast_failure', spell=spec.spell),
                     measurement(aura_label, target, 'aura', spell=spec.spell)])
        expectations += [Expectation(cast_label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.spell, None,
                                     str(result), rule, dict(model)),
                         Expectation(aura_label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.spell, None,
                                     str(presence), rule, dict(model))]
    members = [ALLY, *(GROUP_TARGET_FILLERS + (GROUP_TARGET_RAIDER,) if spec.raid else ())]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour group target',
        'contract': f'{spec.spell} is cast at an ungrouped player (refused with {spec.outsider_result}, no aura), '
                    f'then at the same player once grouped (cast goes through, aura present)'
                    + (f', then the group is filled to a raid and {spec.spell} is cast at the member that '
                       f'converted it (cast goes through, aura present)' if spec.raid else '')
                    + f', proving the "{spec.quote}" clause.',
        'players': [player_fixture(class_file)] + [{**player_fixture(class_file), 'id': member} for member in members],
        'steps': steps}
    return scenario, expectations


def group_target_spec(entry: dict) -> GroupTargetSpec:
    return GroupTargetSpec(entry['spell'], entry['name'], entry['quote'],
                           entry.get('outsider_result', SPELL_FAILED_BAD_TARGETS), entry.get('raid', True))


SPELL_FAILED_NOT_READY = 67
SPELL_FAILED_NO_POWER = 85
COST_GATE_RESOURCES = {'power': SPELL_FAILED_NO_POWER, 'cooldown': SPELL_FAILED_NOT_READY}
COST_GATE_MARGIN_MS = 500
COST_GATE_DURATION_MARGIN_MS = 300


@dataclass(frozen=True)
class CostGateSpec:
    spell: int
    name: str
    quote: str
    gated_spell: int
    resource: str
    reduction: float
    target: str = TARGET
    talent_aura: int | None = None
    setup_casts: tuple[tuple[int, str], ...] = ()
    margin_ms: int = COST_GATE_MARGIN_MS
    label_suffix: str = ''
    next_arm: bool = False
    aura_duration_ms: int | None = None
    duration_margin_ms: int = COST_GATE_DURATION_MARGIN_MS
    after_casts: tuple[tuple[int, str], ...] = ()
    after_wait_ms: int = 0
    resets: bool = False
    talent_aura_each_arm: bool = False
    restore_charges: bool = False
    target_health_pct: int | None = None
    unset_arm: bool = False
    charges: int | None = None
    arm_wait_ms: int = 0
    cast_power: int | None = None
    removal_wait_ms: int | None = None


@dataclass(frozen=True)
class CostGateArm:
    name: str
    with_talent: bool
    level: float
    result: int
    setup: bool = True
    held_ms: int = 0
    skip_setup: bool = False


def cost_gate_label(spec: CostGateSpec, arm: str) -> str:
    suffix = f' {spec.label_suffix}' if spec.label_suffix else ''
    return f'{spec.spell} cost_gate {spec.gated_spell}{suffix} {arm}'


def cost_gate_base(spec: CostGateSpec, facts) -> float:
    if spec.resource == 'power':
        if facts.mana_cost <= 0 or facts.mana_cost_percentage or facts.mana_cost_per_level:
            raise NotModelled(f'{spec.gated_spell} has no plain power cost to gate')
        return float(facts.mana_cost)
    if facts.recast_ms <= 0:
        raise NotModelled(f'{spec.gated_spell} has no cooldown to gate')
    return float(facts.recast_ms)


def cost_gate_levels(spec: CostGateSpec, base: float) -> tuple[float, float | None]:
    if spec.resets:
        opened = spec.after_wait_ms + spec.margin_ms
        if spec.resource != 'cooldown' or not spec.after_casts or not GCD_WAIT_MS <= opened < base:
            raise ValueError(f'{spec.spell} resets a running cooldown through after_casts, with the attempt '
                             f'{opened} ms after the priming cast below the {base:g} ms cooldown')
        return opened, opened
    reduced = base - spec.reduction
    if removes_cooldown(spec, base):
        allowed = spec.removal_wait_ms if spec.removal_wait_ms is not None else GCD_WAIT_MS + spec.margin_ms
        if not allowed < base:
            raise NotModelled(f'{spec.gated_spell} cooldown {base:g} ms leaves no wait above the global cooldown '
                              f'that only its removal separates')
        return allowed, None
    if spec.resource == 'power':
        allowed = math.ceil(reduced)
        if allowed == reduced == 0 < base:
            return 0, None
        if lengthens(spec):
            if reduced != allowed or not base < allowed - 1:
                raise NotModelled(f'{spec.gated_spell} cost {base:g} plus {-spec.reduction:g} leaves no whole power '
                                  f'level that only the increase separates')
            return allowed, allowed - 1
        beyond = allowed - 1 if allowed == reduced else allowed - 2
        if not 0 <= beyond < allowed < base:
            raise NotModelled(f'{spec.gated_spell} cost {base:g} less {spec.reduction:g} leaves no power level that '
                              f'only the reduction separates')
        return allowed, beyond
    allowed, beyond = reduced + spec.margin_ms, reduced - spec.margin_ms
    if lengthens(spec):
        if not base + spec.margin_ms < beyond:
            raise NotModelled(f'{spec.gated_spell} cooldown {base:g} ms plus {-spec.reduction:g} ms leaves no wait '
                              f'that only the increase separates at {spec.margin_ms} ms')
        return allowed, beyond
    if not GCD_WAIT_MS <= beyond < allowed < base:
        raise NotModelled(f'{spec.gated_spell} cooldown {base:g} ms less {spec.reduction:g} ms leaves no wait that '
                          f'only the reduction separates at {spec.margin_ms} ms')
    return allowed, beyond


def lengthens(spec: CostGateSpec) -> bool:
    return spec.reduction < 0


def removes_cooldown(spec: CostGateSpec, base: float) -> bool:
    return spec.resource == 'cooldown' and spec.reduction == base and not spec.resets


def cost_gate_arms(spec: CostGateSpec, base: float) -> list[CostGateArm]:
    refused = COST_GATE_RESOURCES[spec.resource]
    allowed, beyond = cost_gate_levels(spec, base)
    if spec.resets:
        return [CostGateArm('without', False, allowed, refused), CostGateArm('with', True, allowed, NO_CAST_FAILURE)]
    if lengthens(spec):
        if spec.next_arm or spec.aura_duration_ms is not None or spec.after_casts:
            raise ValueError(f'{spec.spell} lengthens a cooldown, which takes no next, duration or after-cast arms')
        opened = base + spec.margin_ms if spec.resource == 'cooldown' else base
        return [CostGateArm('without', False, opened, NO_CAST_FAILURE), CostGateArm('base', True, opened, refused),
                CostGateArm('with', True, allowed, NO_CAST_FAILURE), CostGateArm('beyond', True, beyond, refused)]
    arms = [CostGateArm('without', False, allowed, refused), CostGateArm('with', True, allowed, NO_CAST_FAILURE)]
    if spec.next_arm:
        arms.append(CostGateArm('next', True, allowed, refused, setup=False))
    if spec.unset_arm:
        if not spec.setup_casts:
            raise ValueError(f'{spec.spell} cost_gate unset_arm withholds setup_casts it does not have')
        arms.append(CostGateArm('unset', True, allowed, refused, skip_setup=True))
    if beyond is not None:
        arms.append(CostGateArm('beyond', True, beyond, refused))
    if spec.aura_duration_ms is not None:
        if spec.resource != 'power' or not spec.setup_casts:
            raise ValueError(f'{spec.spell} aura_duration_ms needs a power gate opened by setup_casts')
        lead = spec.aura_duration_ms - SINGLE_TARGET_GCD_WAIT_MS
        if lead - spec.duration_margin_ms <= 0:
            raise NotModelled(f'{spec.spell} aura of {spec.aura_duration_ms} ms ends within the setup wait')
        arms += [CostGateArm('held', True, allowed, NO_CAST_FAILURE, held_ms=lead - spec.duration_margin_ms),
                 CostGateArm('expired', True, allowed, refused, held_ms=lead + spec.duration_margin_ms)]
    return arms


def cost_gate_scenario(class_file: dict, spec: CostGateSpec) -> tuple[dict, list[Expectation]]:
    if spec.resource not in COST_GATE_RESOURCES:
        raise ValueError(f'{spec.spell} cost_gate resource {spec.resource!r} is not one of '
                         f'{sorted(COST_GATE_RESOURCES)}')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    class_file = armed_for(class_file, records, spec.gated_spell)
    entry = behaviour_entry(records, spec.spell, spec.name, 'cost_gate', spec.quote, spec.reduction)
    facts = facts_of(records, spec.gated_spell)
    base = cost_gate_base(spec, facts)
    if spec.after_casts and not spec.resets and (spec.resource != 'cooldown'
                                                 or not 0 <= spec.after_wait_ms < cost_gate_levels(spec, base)[1]):
        raise ValueError(f'{spec.spell} after_casts needs a cooldown gate and an after_wait_ms below the beyond wait')
    if spec.cast_power is not None and spec.resource != 'cooldown':
        raise ValueError(f'{spec.spell} cost_gate cast_power sets the power of a cooldown gate only')
    full_power = (cast_gate_power_step(facts) if spec.cast_power is None
                  else [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.cast_power}])
    approach = ([{'action': 'relocate', 'actor': CASTER, 'dx': CHARGE_OFFSET_YD}]
                if spec.target == ALLY and closes_distance(facts) else [])

    def setup() -> list[dict]:
        steps = []
        for spell, target in spec.setup_casts:
            setup_facts = facts_of(records, spell)
            steps += ([{'action': 'relocate', 'actor': CASTER, 'dx': CHARGE_OFFSET_YD}]
                      if target == ALLY and closes_distance(setup_facts) else [])
            steps += ([{'action': 'restore_charges', 'actor': CASTER, 'spell': spell}] if spec.restore_charges else [])
            steps += ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}]
                      + cast_gate_power_step(setup_facts) + required_aura_steps(setup_facts)
                      + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': target},
                         {'action': 'wait', 'ms': SINGLE_TARGET_GCD_WAIT_MS}])
        return steps

    if spec.charges is not None and (spec.charges < 1 or spec.resource != 'cooldown' or not spec.talent_aura
                                     or spec.resets or lengthens(spec) or spec.setup_casts or spec.after_casts):
        raise ValueError(f'{spec.spell} cost_gate charges chain a cooldown gate of a talent aura with no setup or '
                         f'after casts')
    if spec.target_health_pct is not None and (spec.target != TARGET or not 0 < spec.target_health_pct < 100):
        raise ValueError(f'{spec.spell} cost_gate holds a target health of {spec.target_health_pct}, which needs the '
                         f'dummy as its target and a percent between 0 and 100')

    def attempt(label: str, power: list[dict]) -> list[dict]:
        return (approach + power + required_aura_steps(facts)
                + [{'action': 'cast', 'actor': CASTER, 'spell': spec.gated_spell, 'target': spec.target},
                   {'action': 'wait', 'ms': CAST_GATE_WAIT_MS},
                   measurement(label, CASTER, 'cast_failure', spell=spec.gated_spell)])

    def after_casts(arm: CostGateArm) -> tuple[tuple[int, str], ...]:
        return spec.after_casts if arm.with_talent else tuple(
            (spell, target) for spell, target in spec.after_casts if spell != spec.spell)

    def after(arm: CostGateArm) -> list[dict]:
        if not after_casts(arm):
            return []
        steps = [{'action': 'wait', 'label': f'{arm.name} wait before the after casts', 'ms': spec.after_wait_ms}]
        for spell, target in after_casts(arm):
            after_facts = facts_of(records, spell)
            steps += ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}]
                      + cast_gate_power_step(after_facts) + required_aura_steps(after_facts)
                      + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': target}])
        return steps

    def cooldown_wait(arm: CostGateArm) -> int:
        return int(arm.level) - (spec.after_wait_ms if after_casts(arm) else 0)

    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.gated_spell}]
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in dict.fromkeys(
        spell for spell, _ in spec.setup_casts + spec.after_casts if spell != spec.spell)]
    if spec.target_health_pct is not None:
        steps += [{'action': 'set_health_pct', 'actor': CASTER, 'target': TARGET, 'pct': spec.target_health_pct},
                  {'action': 'wait', 'ms': HIT_RATIO_HEALTH_SETTLE_MS}]
    expectations = []
    rule = prose_rule(entry.quote, spec.spell)
    model = {'kind': 'cost_gate', 'resource': spec.resource, 'base': base, 'reduction': spec.reduction,
             'quote': entry.quote}
    if removes_cooldown(spec, base):
        global_cooldown = int(records.field('Spell', spec.gated_spell, 'StartRecoveryTime'))
        if spec.removal_wait_ms is not None and not global_cooldown < spec.removal_wait_ms < base:
            raise ValueError(f'{spec.spell} removal_wait_ms {spec.removal_wait_ms} must lie between the '
                             f'{global_cooldown} ms global cooldown and the {base:g} ms cooldown')
        model['removal'] = {'global_cooldown_ms': global_cooldown, 'gcd_wait_ms': GCD_WAIT_MS}
    talent_steps = ([{'action': 'set_aura', 'actor': CASTER, 'spell': spec.talent_aura, 'stacks': 1}]
                    if spec.talent_aura else [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}])
    if spec.talent_aura and spec.talent_aura_each_arm:
        talent_steps = [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.talent_aura, 'stacks': 0}] + talent_steps
    learned = False
    for arm in cost_gate_arms(spec, base):
        if arm.with_talent and (not learned or (spec.talent_aura_each_arm and arm.setup)):
            steps += talent_steps
            learned = True
        label = cost_gate_label(spec, arm.name)
        steps.append({'action': 'wait', 'label': f'{arm.name} global cooldown',
                      'ms': SINGLE_TARGET_GCD_WAIT_MS + spec.arm_wait_ms})
        if arm.setup:
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.gated_spell})
        opening = setup() if arm.setup and not arm.skip_setup else []
        if arm.held_ms:
            opening.append({'action': 'wait', 'label': f'{arm.name} aura wait', 'ms': arm.held_ms})
        if spec.talent_aura and arm.with_talent:
            aura_label = f'{label} aura'
            opening.append(measurement(aura_label, CASTER, 'aura', spell=spec.talent_aura))
            expectations.append(Expectation(aura_label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.talent_aura, None,
                                            str(STATE_PRESENT), rule, {**model, 'arm': arm.name, 'reading': 'aura'}))
        if spec.resource == 'power':
            steps += opening + attempt(label, [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                                                'value': int(arm.level)}])
        else:
            steps += (opening + full_power + required_aura_steps(facts)
                      + [{'action': 'cast', 'actor': CASTER, 'spell': spec.gated_spell, 'target': spec.target}]
                      + ([measurement(f'{label} cooldown', CASTER, 'cooldown_ms', spell=spec.gated_spell)]
                         if spec.removal_wait_ms is not None else [])
                      + after(arm)
                      + [{'action': 'wait', 'label': f'{arm.name} cooldown wait', 'ms': cooldown_wait(arm)}]
                      + attempt(label, full_power))
        expectations.append(Expectation(label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.gated_spell, None,
                                        str(arm.result), rule,
                                        {**model, 'arm': arm.name, 'level': arm.level, 'held_ms': arm.held_ms}))
        if spec.charges and arm.name == 'with':
            for cast in range(3, spec.charges + 3):
                chained = cost_gate_label(spec, f'cast_{cast}')
                steps += ([{'action': 'wait', 'label': f'{chained} cooldown wait', 'ms': cooldown_wait(arm)}]
                          + attempt(chained, full_power))
                result = NO_CAST_FAILURE if cast <= spec.charges + 1 else COST_GATE_RESOURCES[spec.resource]
                expectations.append(Expectation(chained, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.gated_spell,
                                                None, str(result), rule,
                                                {**model, 'arm': f'cast_{cast}', 'level': arm.level, 'held_ms': 0}))
        if spec.removal_wait_ms is not None and arm.with_talent:
            expectations.append(Expectation(f'{label} cooldown', BEHAVIOUR_CAST_CONDITION, spec.spell,
                                            spec.gated_spell, None, '0', rule,
                                            {'kind': 'cost_gate', 'arm': arm.name, 'reading': 'cooldown_ms'}))
    unit = 'power' if spec.resource == 'power' else 'ms after a cast'
    players = [{**player_fixture(class_file), 'allow_regeneration': False}]
    if ALLY in (spec.target, *(target for _, target in (*spec.setup_casts, *spec.after_casts))):
        players.append({**player_fixture(class_file), 'id': ALLY})
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cost gate'
                + (f' {spec.label_suffix}' if spec.label_suffix else ''),
        'contract': f'{spec.gated_spell} is attempted at {base:g} less {spec.reduction:g} {unit}: without '
                    f'{spec.spell} it must be refused, with it it must go through, and one step beyond the stated '
                    f'reduction it must be refused again, proving the "{spec.quote}" clause.'
                    + (f' The dummy is set to {spec.target_health_pct}% health before the arms.'
                       if spec.target_health_pct is not None else '')
                    + (f' After the with arm, {spec.gated_spell} is attempted again at the same wait after each cast, '
                       f'without a fresh {spec.talent_aura}: casts 3 to {spec.charges + 1} go through and cast '
                       f'{spec.charges + 2} is refused, since only the first {spec.charges} casts are reduced.'
                       if spec.charges else '')
                    + (f' The reduction is negative, a longer cooldown: without {spec.spell} the cast goes through '
                       f'{spec.margin_ms} ms after the base cooldown, with it it is refused there, goes through '
                       f'{spec.margin_ms} ms after the lengthened cooldown and is refused {spec.margin_ms} ms before '
                       f'it.' if lengthens(spec) and spec.resource == 'cooldown' else '')
                    + (f' The reduction is negative, a higher cost: without {spec.spell} the cast goes through at '
                       f'{base:g} power, with it it is refused there, goes through at the raised cost and is refused '
                       f'one point below it.' if lengthens(spec) and spec.resource == 'power' else '')
                    + (f' The talent removes the cooldown: the attempt comes {spec.margin_ms} ms after the global '
                       f'cooldown, refused without {spec.spell}, through with it; no later wait is refused, so there '
                       f'is no beyond arm.' if removes_cooldown(spec, base) else '')
                    + (f' The talent resets the running cooldown: both arms attempt {spec.gated_spell} '
                       f'{spec.margin_ms} ms after the after casts, refused without {spec.spell}, through with it.'
                       if spec.resets else '')
                    + (f' {[spell for spell, _ in spec.after_casts]} are cast {spec.after_wait_ms} ms after the '
                       f'priming cast, in every arm except {spec.spell} itself, which only the arms with it cast and '
                       f'learn.' if spec.after_casts else ''),
        'players': players,
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    limit = MAX_ACCELERATED_SCENARIO_MS if spec.resource == 'cooldown' else MAX_SCENARIO_MS
    return timed(scenario, waited_ms(steps), limit), expectations


def cost_gate_spec(entry: dict) -> CostGateSpec:
    return CostGateSpec(entry['spell'], entry['name'], entry['quote'], entry['gated_spell'], entry['resource'],
                        float(entry['reduction']), entry.get('target', TARGET), entry.get('talent_aura'),
                        tuple((int(spell), target) for spell, target in entry.get('setup_casts', ())),
                        entry.get('margin_ms', COST_GATE_MARGIN_MS), entry.get('label_suffix', ''),
                        entry.get('next_arm', False), entry.get('aura_duration_ms'),
                        entry.get('duration_margin_ms', COST_GATE_DURATION_MARGIN_MS),
                        tuple((int(spell), target) for spell, target in entry.get('after_casts', ())),
                        entry.get('after_wait_ms', 0), entry.get('resets', False),
                        bool(entry.get('talent_aura_each_arm', False)), bool(entry.get('restore_charges', False)),
                        entry.get('target_health_pct'), bool(entry.get('unset_arm', False)), entry.get('charges'),
                        int(entry.get('arm_wait_ms', 0)), entry.get('cast_power'), entry.get('removal_wait_ms'))


SITE_PURCHASE_SETTLE_MS = 3000


@dataclass(frozen=True)
class PurchaseSite:
    map: int
    x: float
    y: float
    z: float
    reward: int


@dataclass(frozen=True)
class SitePurchaseSpec:
    spell: int
    name: str
    quote: str
    price: int
    sites: tuple[PurchaseSite, PurchaseSite]
    outside: PurchaseSite
    settle_ms: int = SITE_PURCHASE_SETTLE_MS


def site_purchase_label(spell: int, arm: str) -> str:
    return f'{spell} site_purchase {arm}'


def site_purchase_scenario(class_file: dict, spec: SitePurchaseSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'site_purchase', spec.quote, spec.price)
    first, second = spec.sites

    def go(site: PurchaseSite) -> list[dict]:
        return [{'action': 'teleport', 'actor': CASTER, 'map': site.map, 'x': site.x, 'y': site.y, 'z': site.z},
                {'action': 'wait', 'label': 'teleport settle', 'ms': spec.settle_ms}]

    def pay(arm: str, reward: int, copper: int = 0) -> list[dict]:
        purse = [{'action': 'money', 'actor': CASTER, 'copper': copper}] if copper else []
        return purse + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell},
                        {'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': CASTER},
                        {'action': 'wait', 'ms': SINGLE_TARGET_GCD_WAIT_MS},
                        measurement(site_purchase_label(spec.spell, arm), CASTER, 'knows_spell', spell=reward)]

    arms = [('outside', first.reward, NO_CAST_FAILURE), ('paid', first.reward, STATE_PRESENT),
            ('spent', second.reward, NO_CAST_FAILURE), ('topped_up', second.reward, STATE_PRESENT)]
    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + go(spec.outside) + pay('outside', first.reward, spec.price) + go(first) + pay('paid', first.reward)
             + go(second) + pay('spent', second.reward, spec.price - 1) + pay('topped_up', second.reward, 1))
    rule = prose_rule(entry.quote, spec.spell)
    model = {'kind': 'site_purchase', 'price': spec.price, 'quote': entry.quote}
    expectations = [Expectation(site_purchase_label(spec.spell, arm), BEHAVIOUR_CAST_CONDITION, spec.spell, reward,
                                None, str(known), rule, {**model, 'arm': arm}) for arm, reward, known in arms]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour site purchase',
        'contract': f'{spec.spell} is cast with {spec.price} copper away from any site (reward {first.reward} not '
                    f'learned), at the first site (learned), then at the second site with {spec.price - 1} copper '
                    f'added (reward {second.reward} not learned: the first payment was spent) and once more after 1 '
                    f'copper more (learned), proving the "{spec.quote}" clause.',
        'players': [player_fixture(class_file)],
        'steps': steps}
    return timed(scenario, waited_ms(steps)), expectations


def site_purchase_spec(entry: dict) -> SitePurchaseSpec:
    def site(raw: dict, reward: int) -> PurchaseSite:
        return PurchaseSite(int(raw['map']), float(raw['x']), float(raw['y']), float(raw['z']), reward)

    sites = tuple(site(raw, int(raw['reward'])) for raw in entry['sites'])
    if len(sites) != 2:
        raise ValueError(f'{entry["spell"]} site_purchase needs exactly two sites')
    return SitePurchaseSpec(entry['spell'], entry['name'], entry['quote'], int(entry['price']), sites,
                            site(entry['outside'], 0), entry.get('settle_ms', SITE_PURCHASE_SETTLE_MS))


PERIODIC_DISPEL_MARGIN_MS = 200


@dataclass(frozen=True)
class PeriodicDispelSpec:
    spell: int
    name: str
    quote: str
    debuffs: tuple[int, ...]
    period_ms: int
    margin_ms: int = PERIODIC_DISPEL_MARGIN_MS
    power: int | None = None


def periodic_dispel_label(spell: int, moment: str, debuff: int | None = None) -> str:
    return f'{spell} periodic_dispel {moment}' + (f' {debuff}' if debuff is not None else '')


def periodic_dispel_scenario(class_file: dict, spec: PeriodicDispelSpec) -> tuple[dict, list[Expectation]]:
    if len(spec.debuffs) < 2:
        raise ValueError(f'{spec.spell} periodic_dispel needs at least two debuffs to count one removal per period')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    count = len(spec.debuffs)
    entry = behaviour_entry(records, spec.spell, spec.name, 'periodic_dispel', spec.quote, 1.0)
    facts = facts_of(records, spec.spell)

    def place() -> list[dict]:
        return [{'action': 'set_aura', 'actor': CASTER, 'spell': debuff, 'stacks': 1} for debuff in spec.debuffs]

    def read(moment: str) -> list[dict]:
        return [measurement(periodic_dispel_label(spec.spell, moment, debuff), CASTER, 'aura', spell=debuff)
                for debuff in spec.debuffs]

    moments = [('before_first', spec.period_ms - spec.margin_ms, count)]
    moments += [(f'after_{tick}', tick * spec.period_ms + spec.margin_ms, max(count - tick, 0))
                for tick in range(1, count + 1)]
    control_wait = moments[-1][1]
    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + place()
             + [{'action': 'wait', 'label': 'control without the spell wait', 'ms': control_wait}] + read('control')
             + [{'action': 'set_aura', 'actor': CASTER, 'spell': debuff, 'stacks': 0} for debuff in spec.debuffs]
             + place()
             + ([{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.power}]
                if spec.power is not None else cast_gate_power_step(facts))
             + required_aura_steps(facts)
             + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': CASTER}])
    elapsed = 0
    for moment, at_ms, _ in moments:
        steps += [{'action': 'wait', 'label': f'{moment} wait', 'ms': at_ms - elapsed}] + read(moment)
        elapsed = at_ms
    rule = prose_rule(entry.quote, spec.spell)
    model = {'kind': 'periodic_dispel', 'period_ms': spec.period_ms, 'quote': entry.quote}
    expectations = [Expectation(periodic_dispel_label(spec.spell, moment), BEHAVIOUR_CAST_CONDITION, spec.spell,
                                spec.spell, None, str(present), rule,
                                {**model, 'sum_labels': [periodic_dispel_label(spec.spell, moment, debuff)
                                                         for debuff in spec.debuffs]})
                    for moment, present in [('control', count)] + [(m, n) for m, _, n in moments]]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour periodic dispel',
        'contract': f'{count} debuffs {list(spec.debuffs)} stay on the caster for {control_wait} ms without '
                    f'{spec.spell}; with it cast, all are present {spec.margin_ms} ms before its first period and one '
                    f'fewer is present {spec.margin_ms} ms after each period of {spec.period_ms} ms, proving the '
                    f'"{spec.quote}" clause.',
        'players': [player_fixture(class_file)],
        'steps': steps}
    return timed(scenario, waited_ms(steps)), expectations


def periodic_dispel_spec(entry: dict) -> PeriodicDispelSpec:
    return PeriodicDispelSpec(entry['spell'], entry['name'], entry['quote'], tuple(int(d) for d in entry['debuffs']),
                              int(entry['period_ms']), entry.get('margin_ms', PERIODIC_DISPEL_MARGIN_MS),
                              entry.get('power'))


SPELL_FAILED_TARGET_AURASTATE = 111
NO_CAST_FAILURE = 0
CAST_GATE_WAIT_MS = CAST_MARGIN_MS


@dataclass(frozen=True)
class CastGateSpec:
    spell: int
    name: str
    quote: str
    bypass_spell: int
    bypass_name: str
    bypass_quote: str


def cast_gate_label(spell: int, moment: str) -> str:
    return f'{spell} cast_gate {moment}'


def cast_gate_power_step(facts) -> list[dict]:
    if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        return [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost}]
    return []


def cast_gate_attempt(spell: int, facts, moment: str, label_spell: int | None = None) -> list[dict]:
    label = cast_gate_label(label_spell if label_spell is not None else spell, moment)
    return ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}] + cast_gate_power_step(facts)
            + required_aura_steps(facts)
            + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': TARGET},
               {'action': 'wait', 'ms': CAST_GATE_WAIT_MS},
               measurement(label, CASTER, 'cast_failure', spell=spell)])


def cast_gate_scenario(class_file: dict, spec: CastGateSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    gated_entry = behaviour_entry(records, spec.spell, spec.name, 'cast_gate', spec.quote, NO_CAST_FAILURE)
    bypass_entry = behaviour_entry(records, spec.bypass_spell, spec.bypass_name, 'cast_gate', spec.bypass_quote,
                                   NO_CAST_FAILURE)
    gated_facts = facts_of(records, spec.spell)
    bypass_facts = facts_of(records, spec.bypass_spell)
    if not gated_facts.target_aura_state:
        raise NotModelled(f'{spec.spell} has no TargetAuraState to gate on')
    blocked_label = cast_gate_label(spec.spell, 'blocked')
    allowed_label = cast_gate_label(spec.spell, 'allowed')
    bypassed_label = cast_gate_label(spec.bypass_spell, 'bypassed')
    bypass_cast_steps = ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.bypass_spell}]
                         + cast_gate_power_step(bypass_facts)
                         + [{'action': 'cast', 'actor': CASTER, 'spell': spec.bypass_spell, 'target': CASTER},
                            {'action': 'wait', 'ms': CAST_GATE_WAIT_MS}])
    steps = (base_steps(class_file)
            + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
               {'action': 'learn', 'actor': CASTER, 'spell': spec.bypass_spell}]
            + cast_gate_attempt(spec.spell, gated_facts, 'blocked')
            + bypass_cast_steps
            + cast_gate_attempt(spec.spell, gated_facts, 'bypassed', label_spell=spec.bypass_spell)
            + [{'action': 'unlearn', 'actor': CASTER, 'spell': spec.bypass_spell}]
            + required_target_health_steps(gated_facts)
            + cast_gate_attempt(spec.spell, gated_facts, 'allowed'))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cast gate',
        'contract': f'No-combat cast-attempt check: {spec.spell} is attempted at the dummy fixture\'s default '
                    f'(full) health and must be refused with SPELL_FAILED_TARGET_AURASTATE '
                    f'({SPELL_FAILED_TARGET_AURASTATE}); {spec.bypass_spell} is then cast on the caster and the '
                    f'same attempt at the same full health '
                    f'must succeed; {spec.bypass_spell} is unlearned, the target\'s health is lowered to the DBC\'s '
                    f'own TargetAuraState fixture and the same attempt must succeed through the health gate itself.',
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    blocked_model = {'kind': 'cast_gate', 'quote': gated_entry.quote}
    allowed_model = {'kind': 'cast_gate', 'quote': gated_entry.quote}
    bypassed_model = {'kind': 'cast_gate', 'quote': bypass_entry.quote}
    expectations = [
        Expectation(blocked_label, BEHAVIOUR_CAST_GATE, spec.spell, spec.spell, None,
                   str(SPELL_FAILED_TARGET_AURASTATE), prose_rule(gated_entry.quote, spec.spell), blocked_model),
        Expectation(allowed_label, BEHAVIOUR_CAST_GATE, spec.spell, spec.spell, None, str(NO_CAST_FAILURE),
                   prose_rule(gated_entry.quote, spec.spell), allowed_model),
        Expectation(bypassed_label, BEHAVIOUR_CAST_GATE, spec.bypass_spell, spec.spell, None, str(NO_CAST_FAILURE),
                   prose_rule(bypass_entry.quote, spec.bypass_spell), bypassed_model),
    ]
    return scenario, expectations


def cast_gate_spec(entry: dict) -> CastGateSpec:
    return CastGateSpec(entry['spell'], entry['name'], entry['quote'], entry['bypass_spell'], entry['bypass_name'],
                        entry['bypass_quote'])


SPELL_FAILED_ONLY_OUTDOORS = 93
SPELL_FAILED_ONLY_MOUNTED = 91
CAST_CONDITION_OUTDOORS = 'outdoors'
CAST_CONDITION_MOUNTED = 'mounted'
CAST_CONDITION_AVOIDED = 'avoided'
CAST_CONDITIONS = (CAST_CONDITION_OUTDOORS, CAST_CONDITION_MOUNTED, CAST_CONDITION_AVOIDED)
AVOIDING_ATTACKER = 'attacker'
AVOIDING_ROOT = 42716
AVOIDING_DODGE = 26669
AVOIDING_ENGAGE_MS = 2800
AVOIDING_SWINGS_MS = 6000
GENERIC_GROUND_MOUNT_SPELL = 458
OUTDOOR_LOCATION = {'map': 0, 'x': -9617.06, 'y': -288.949, 'z': 57.3053}
INDOOR_LOCATION = {'map': 0, 'x': -4840.67, 'y': -857.094, 'z': 501.997}


@dataclass(frozen=True)
class CastConditionSpec:
    spell: int
    name: str
    quote: str
    condition: str
    blocked_result: int
    learn: tuple[int, ...] = ()


def avoided_setup(spell: int) -> list[dict]:
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': AVOIDING_DODGE, 'stacks': 1},
            {'action': 'attack', 'actor': CASTER, 'target': AVOIDING_ATTACKER},
            {'action': 'wait', 'label': 'engage the attacker', 'ms': AVOIDING_ENGAGE_MS},
            {'action': 'stop_attack', 'actor': CASTER},
            {'action': 'wait', 'label': 'attacker swings', 'ms': AVOIDING_SWINGS_MS},
            measurement(cast_condition_label(spell, 'dodges'), CASTER, 'melee_attacks_taken', victim_state=2)]


def cast_condition_label(spell: int, moment: str) -> str:
    return f'{spell} cast_condition {moment}'


def cast_condition_attempt(spell: int, facts, moment: str) -> list[dict]:
    label = cast_condition_label(spell, moment)
    return ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}] + cast_gate_power_step(facts)
            + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': CASTER},
               {'action': 'wait', 'ms': CAST_GATE_WAIT_MS},
               measurement(label, CASTER, 'cast_failure', spell=spell)])


def cast_condition_scenario(class_file: dict, spec: CastConditionSpec) -> tuple[dict, list[Expectation]]:
    if spec.condition not in CAST_CONDITIONS:
        raise NotModelled(f'{spec.spell} cast_condition {spec.condition!r} is not modelled')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'cast_condition', spec.quote, NO_CAST_FAILURE)
    facts = facts_of(records, spec.spell)
    blocked_label = cast_condition_label(spec.spell, 'blocked')
    allowed_label = cast_condition_label(spec.spell, 'allowed')
    if spec.condition == CAST_CONDITION_OUTDOORS:
        setup_blocked = [{'action': 'teleport', 'actor': CASTER, **INDOOR_LOCATION},
                         {'action': 'wait', 'ms': 2000}]
        setup_allowed = [{'action': 'teleport', 'actor': CASTER, **OUTDOOR_LOCATION},
                         {'action': 'wait', 'ms': 2000}]
        mechanism = (f'Location pair reused from the existing indoor/outdoor fixture already verified in '
                    f'scenarios/reaper-ghost-form-indoor-corpse-reclaim-6437.json: Firebrew Inn indoor at '
                    f'map {INDOOR_LOCATION["map"]} ({INDOOR_LOCATION["x"]}, {INDOOR_LOCATION["y"]}, '
                    f'{INDOOR_LOCATION["z"]}), open-world outdoor at ({OUTDOOR_LOCATION["x"]}, '
                    f'{OUTDOOR_LOCATION["y"]}, {OUTDOOR_LOCATION["z"]}).')
    elif spec.condition == CAST_CONDITION_AVOIDED:
        setup_blocked = [{'action': 'set_health', 'actor': CASTER, 'value': STRIKER_HEALTH, 'maximum': STRIKER_HEALTH},
                         {'action': 'set_aura', 'actor': CASTER, 'target': AVOIDING_ATTACKER,
                          'caster': AVOIDING_ATTACKER, 'spell': AVOIDING_ROOT, 'stacks': 1}]
        setup_allowed = avoided_setup(spec.spell)
        mechanism = (f'An aggressive, rooted attacker (creature {TAKEN_HIT_STRIKER_ENTRY}, Self Root Forever '
                     f'{AVOIDING_ROOT}) stands 3 yd in front of the caster. Blocked: no attack has been avoided yet. '
                     f'Allowed: with Evasion {AVOIDING_DODGE} on the caster, the caster engages the attacker with one '
                     f'swing interval and stops, then takes its swings for {AVOIDING_SWINGS_MS} ms; the dodges are '
                     f'read.')
    else:
        setup_blocked = [{'action': 'set_aura', 'actor': CASTER, 'spell': GENERIC_GROUND_MOUNT_SPELL, 'stacks': 0}]
        setup_allowed = [{'action': 'set_aura', 'actor': CASTER, 'spell': GENERIC_GROUND_MOUNT_SPELL, 'stacks': 1}]
        mechanism = (f'Mounted state is set directly via a fixture aura of {GENERIC_GROUND_MOUNT_SPELL} (Brown '
                    f'Horse, Spell.dbc EffectApplyAuraName[0] SPELL_AURA_MOUNTED), independent of any class '
                    f'mount ability.')
    steps = (base_steps(class_file)
            + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (spec.spell, *spec.learn)]
            + setup_blocked
            + cast_condition_attempt(spec.spell, facts, 'blocked')
            + setup_allowed
            + cast_condition_attempt(spec.spell, facts, 'allowed'))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cast condition',
        'contract': f'No-combat cast-attempt check of {spec.spell}\'s own "{spec.quote}" clause: the spell is '
                    f'attempted once with the {spec.condition} condition unmet, expecting refusal with code '
                    f'{spec.blocked_result}, then once with it met, expecting {NO_CAST_FAILURE} (no failure). '
                    + mechanism,
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    if spec.condition == CAST_CONDITION_AVOIDED:
        scenario['creatures'].append({'id': AVOIDING_ATTACKER, 'owner': CASTER, 'entry': TAKEN_HIT_STRIKER_ENTRY,
                                      'level': class_file['level'], 'health': STRIKER_HEALTH,
                                      'distance': STRIKER_DISTANCE, 'reaction': 2, 'stationary': True})
    model = {'kind': 'cast_condition', 'quote': entry.quote}
    expectations = [
        Expectation(blocked_label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.spell, None,
                   str(spec.blocked_result), prose_rule(entry.quote, spec.spell), model),
        Expectation(allowed_label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.spell, None, str(NO_CAST_FAILURE),
                   prose_rule(entry.quote, spec.spell), model),
    ]
    return scenario, expectations


def cast_condition_spec(entry: dict) -> CastConditionSpec:
    return CastConditionSpec(entry['spell'], entry['name'], entry['quote'], entry['condition'],
                             entry['blocked_result'], tuple(entry.get('learn', ())))


CAST_COMBAT_SETTLE_MS = CAST_MARGIN_MS


CAST_COMBAT_RESURRECT_RESPONSE_OPCODE = 348
CAST_COMBAT_RESURRECT_SETTLE_MS = 1000


@dataclass(frozen=True)
class CastCombatSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int = 0
    resurrect: bool = False
    label_suffix: str = ''

    def __post_init__(self):
        if not self.cast_spell:
            object.__setattr__(self, 'cast_spell', self.spell)


def cast_combat_label(spell: int, metric: str, suffix: str = '') -> str:
    return f'{spell} cast_combat {suffix} {metric}' if suffix else f'{spell} cast_combat {metric}'


def resurrect_response(label: str) -> list[dict]:
    return [{'action': 'client_packet', 'label': label, 'actor': ALLY, 'opcode': CAST_COMBAT_RESURRECT_RESPONSE_OPCODE,
             'fields': [{'actor_guid': CASTER}, {'u8': 1}], 'consumed': False},
            {'action': 'wait', 'ms': CAST_COMBAT_RESURRECT_SETTLE_MS}]


def cast_combat_scenario(class_file: dict, spec: CastCombatSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'cast_combat', spec.quote, NO_CAST_FAILURE)
    facts = facts_of(records, spec.cast_spell)
    combat_label = cast_combat_label(spec.spell, 'combat', spec.label_suffix)
    cast_label = cast_combat_label(spec.spell, 'cast_failure', spec.label_suffix)
    alive_before = cast_combat_label(spec.spell, 'alive before', spec.label_suffix)
    alive_after = cast_combat_label(spec.spell, 'alive after', spec.label_suffix)
    control = (resurrect_response('accept with no resurrection offered')
               + [measurement(alive_before, ALLY, 'alive')]) if spec.resurrect else []
    revival = (resurrect_response('accept the resurrection')
               + [measurement(alive_after, ALLY, 'alive')]) if spec.resurrect else []
    steps = (base_steps(class_file)
            + [{'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell},
               {'action': 'die', 'actor': ALLY}]
            + control
            + [
               {'action': 'attack', 'actor': CASTER, 'target': TARGET},
               {'action': 'wait', 'ms': CAST_COMBAT_SETTLE_MS},
               measurement(combat_label, CASTER, 'combat'),
               {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell}]
            + cast_gate_power_step(facts)
            + required_aura_steps(facts)
            + [{'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': ALLY},
               {'action': 'wait', 'ms': facts.cast_time_ms + CAST_GATE_WAIT_MS},
               measurement(cast_label, CASTER, 'cast_failure', spell=spec.cast_spell),
               {'action': 'stop_attack', 'actor': CASTER}]
            + revival)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cast combat',
        'contract': f'Combat-attempt check: the caster attacks a dummy fixture to enter real combat '
                    f'(Unit::IsInCombat(), the "combat" metric), then attempts {spec.spell} at a dead ally '
                    f'({spec.spell}\'s only effect is SPELL_EFFECT_RESURRECT, the same dead-ally fixture shape '
                    f'proven by the generic rank scenario\'s own targets_resurrect() path) while still fighting '
                    f'the dummy; cast_failure must read {NO_CAST_FAILURE} (no refusal), proving the '
                    f'"{spec.quote}" clause.'
                    + (f' The dead ally sends the resurrection response before the cast (the control: it stays '
                       f'dead) and after it (it must be alive), the stock CMSG_RESURRECT_RESPONSE '
                       f'{CAST_COMBAT_RESURRECT_RESPONSE_OPCODE}.' if spec.resurrect else ''),
        'players': [player_fixture(class_file), {**player_fixture(class_file), 'id': ALLY}],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'cast_combat', 'quote': entry.quote}
    expectations = [
        Expectation(combat_label, BEHAVIOUR_CAST_COMBAT, spec.spell, spec.spell, None, '1',
                   prose_rule(entry.quote, spec.spell), dict(model)),
        Expectation(cast_label, BEHAVIOUR_CAST_COMBAT, spec.spell, spec.spell, None, str(NO_CAST_FAILURE),
                   prose_rule(entry.quote, spec.spell), dict(model)),
    ]
    if spec.resurrect:
        expectations += [
            Expectation(alive_before, BEHAVIOUR_CAST_COMBAT, spec.spell, spec.cast_spell, None, str(STATE_ABSENT),
                        prose_rule(entry.quote, spec.spell), {**model, 'reading': 'alive', 'arm': 'control'}),
            Expectation(alive_after, BEHAVIOUR_CAST_COMBAT, spec.spell, spec.cast_spell, None, str(STATE_PRESENT),
                        prose_rule(entry.quote, spec.spell), {**model, 'reading': 'alive', 'arm': 'cast'})]
    return scenario, expectations


def cast_combat_spec(entry: dict) -> CastCombatSpec:
    return CastCombatSpec(entry['spell'], entry['name'], entry['quote'], int(entry.get('cast_spell', 0)),
                          bool(entry.get('resurrect', False)), entry.get('label_suffix', ''))


STATE_PRESENT = 1
STATE_ABSENT = 0


@dataclass(frozen=True)
class CastStateSpec:
    spell: int
    name: str
    quote: str
    state_aura: int
    control_spell: int
    blocked_result: int


def cast_state_label(spell: int, moment: str) -> str:
    return f'{spell} cast_state {moment}'


def self_cast_attempt(spell: int, facts, label: str) -> list[dict]:
    return ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}] + cast_gate_power_step(facts)
            + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': CASTER},
               {'action': 'wait', 'ms': CAST_GATE_WAIT_MS},
               measurement(label, CASTER, 'cast_failure', spell=spell)])


def cast_state_scenario(class_file: dict, spec: CastStateSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'cast_state', spec.quote, NO_CAST_FAILURE)
    control_label = cast_state_label(spec.spell, 'control')
    state_label = cast_state_label(spec.spell, 'state')
    allowed_label = cast_state_label(spec.spell, 'allowed')
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                {'action': 'learn', 'actor': CASTER, 'spell': spec.control_spell},
                {'action': 'set_aura', 'actor': CASTER, 'caster': TARGET, 'spell': spec.state_aura, 'stacks': 1}]
             + self_cast_attempt(spec.control_spell, facts_of(records, spec.control_spell), control_label)
             + [measurement(state_label, CASTER, 'aura', spell=spec.state_aura)]
             + self_cast_attempt(spec.spell, facts_of(records, spec.spell), allowed_label))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cast state',
        'contract': f'The dummy applies {spec.state_aura} to the caster; the control spell {spec.control_spell} is '
                    f'attempted on the caster and must be refused with code {spec.blocked_result}, '
                    f'{spec.state_aura} must still be present, then {spec.spell} is attempted on the caster and '
                    f'must go through ({NO_CAST_FAILURE}), proving the "{spec.quote}" clause.',
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'cast_state', 'quote': entry.quote}
    rule = prose_rule(entry.quote, spec.spell)
    expectations = [
        Expectation(control_label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.control_spell, None,
                    str(spec.blocked_result), rule, dict(model)),
        Expectation(state_label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.state_aura, None, str(STATE_PRESENT),
                    rule, dict(model)),
        Expectation(allowed_label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.spell, None, str(NO_CAST_FAILURE),
                    rule, dict(model)),
    ]
    return scenario, expectations


def cast_state_spec(entry: dict) -> CastStateSpec:
    return CastStateSpec(entry['spell'], entry['name'], entry['quote'], entry['state_aura'], entry['control_spell'],
                         entry['blocked_result'])


SPELL_FAILED_CASTER_AURASTATE = 22
SPELL_AURA_MOUNTED = 78
MOUNT_BLOCK_SETTLE_MS = 2000
MOUNT_BLOCK_MOMENTS = ('blocked', 'unmounted', 'allowed', 'mounted', 'held', 'dismounted')
MOUNT_BLOCK_EXPECTED = {'blocked': SPELL_FAILED_CASTER_AURASTATE, 'unmounted': STATE_ABSENT,
                        'allowed': NO_CAST_FAILURE, 'mounted': STATE_PRESENT, 'held': STATE_PRESENT,
                        'dismounted': STATE_ABSENT}


@dataclass(frozen=True)
class MountBlockSpec:
    spell: int
    name: str
    quote: str
    mount_spell: int = GENERIC_GROUND_MOUNT_SPELL


def mount_block_label(spec: MountBlockSpec, moment: str) -> str:
    return f'{spec.spell} mount_block {spec.mount_spell} {moment}'


def mount_block_scenario(class_file: dict, spec: MountBlockSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'mount_block', spec.quote, NO_CAST_FAILURE)
    mount = facts_of(records, spec.mount_spell)
    if SPELL_AURA_MOUNTED not in mount.aura_names:
        raise ValueError(f'{spec.spell} mount_block mount {spec.mount_spell} applies no SPELL_AURA_MOUNTED')

    def label(moment: str) -> str:
        return mount_block_label(spec, moment)

    brand = {'action': 'set_aura', 'actor': CASTER, 'spell': spec.spell}
    mounted_read_ms = mount.cast_time_ms + CAST_GATE_WAIT_MS
    steps = (base_steps(class_file)
             + [{'action': 'teleport', 'actor': CASTER, **OUTDOOR_LOCATION},
                {'action': 'wait', 'ms': MOUNT_BLOCK_SETTLE_MS},
                {'action': 'learn', 'actor': CASTER, 'spell': spec.mount_spell},
                {**brand, 'stacks': 1}]
             + self_cast_attempt(spec.mount_spell, mount, label('blocked'))
             + [{'action': 'wait', 'ms': mounted_read_ms},
                measurement(label('unmounted'), CASTER, 'aura', spell=spec.mount_spell),
                {**brand, 'stacks': 0}]
             + self_cast_attempt(spec.mount_spell, mount, label('allowed'))
             + [{'action': 'wait', 'ms': mounted_read_ms},
                measurement(label('mounted'), CASTER, 'aura', spell=spec.mount_spell),
                {'action': 'wait', 'ms': CAST_GATE_WAIT_MS},
                measurement(label('held'), CASTER, 'aura', spell=spec.mount_spell),
                {**brand, 'stacks': 1},
                {'action': 'wait', 'ms': CAST_GATE_WAIT_MS},
                measurement(label('dismounted'), CASTER, 'aura', spell=spec.mount_spell)])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour mount block',
        'contract': f'Outdoors, the caster holds {spec.spell} (set by itself, so its apply hooks run) and casts the '
                    f'mount {spec.mount_spell}: refused with code {SPELL_FAILED_CASTER_AURASTATE} and not mounted. '
                    f'Without {spec.spell} the same cast goes through ({NO_CAST_FAILURE}) and mounts (the control). '
                    f'The mount holds over the same wait without {spec.spell}; then {spec.spell} is set again on '
                    f'the mounted caster, which must lose the mount, proving the '
                    f'"{spec.quote}" clause.',
        'players': [player_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'mount_block', 'quote': entry.quote}
    rule = prose_rule(entry.quote, spec.spell)
    expectations = [Expectation(label(moment), BEHAVIOUR_CAST_CONDITION, spec.spell, spec.mount_spell, None,
                                str(MOUNT_BLOCK_EXPECTED[moment]), rule, dict(model))
                    for moment in MOUNT_BLOCK_MOMENTS]
    return scenario, expectations


def mount_block_spec(entry: dict) -> MountBlockSpec:
    return MountBlockSpec(entry['spell'], entry['name'], entry['quote'],
                          int(entry.get('mount_spell', GENERIC_GROUND_MOUNT_SPELL)))


FLEE_BLOCK_ENGAGE_MS = 1000
FLEE_BLOCK_HEALTH = 1000000
FLEE_BLOCK_REACTION_DEFENSIVE = 1
FLEE_BLOCK_BRANDED = 'flee_branded'
FLEE_BLOCK_CONTROL = 'flee_control'


@dataclass(frozen=True)
class FleeBlockSpec:
    spell: int
    name: str
    quote: str
    creature_entry: int
    flee_health_pct: int
    reads: int
    read_interval_ms: int


def flee_block_label(spec: FleeBlockSpec, moment: str) -> str:
    return f'{spec.spell} flee_block {spec.creature_entry} {moment}'


def flee_block_scenario(class_file: dict, spec: FleeBlockSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'flee_block', spec.quote, STATE_ABSENT)
    if not 1 <= spec.flee_health_pct <= 99 or spec.reads < 1 or spec.read_interval_ms < 1:
        raise ValueError(f'{spec.spell} flee_block needs flee_health_pct 1..99, reads and read_interval_ms above 0')

    def label(moment: str) -> str:
        return flee_block_label(spec, moment)

    def provoked(creature: str, arm: str) -> list[dict]:
        reads = []
        for read in range(1, spec.reads + 1):
            reads += [{'action': 'wait', 'ms': spec.read_interval_ms},
                      measurement(label(f'{arm} read {read}'), creature, 'moving')]
        return ([{'action': 'attack', 'actor': CASTER, 'target': creature},
                 {'action': 'wait', 'label': f'{arm} engage', 'ms': FLEE_BLOCK_ENGAGE_MS},
                 {'action': 'stop_attack', 'actor': CASTER},
                 {'action': 'set_health_pct', 'actor': CASTER, 'target': creature, 'pct': spec.flee_health_pct}]
                + reads)

    def read_labels(arm: str) -> list[str]:
        return [label(f'{arm} read {read}') for read in range(1, spec.reads + 1)]

    brand = facts_of(records, spec.spell)
    creatures = [{'id': creature, 'owner': CASTER, 'entry': spec.creature_entry, 'level': class_file['level'],
                  'health': FLEE_BLOCK_HEALTH, 'reaction': FLEE_BLOCK_REACTION_DEFENSIVE}
                 for creature in (FLEE_BLOCK_BRANDED, FLEE_BLOCK_CONTROL)]
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
             + cast_gate_power_step(brand) + required_aura_steps(brand)
             + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': FLEE_BLOCK_BRANDED},
                {'action': 'wait', 'ms': CAST_GATE_WAIT_MS},
                measurement(label('cast'), CASTER, 'cast_failure', spell=spec.spell),
                measurement(label('branded'), FLEE_BLOCK_BRANDED, 'aura', spell=spec.spell)]
             + provoked(FLEE_BLOCK_BRANDED, 'branded')
             + [measurement(label('held'), FLEE_BLOCK_BRANDED, 'aura', spell=spec.spell)]
             + provoked(FLEE_BLOCK_CONTROL, 'control'))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour flee block',
        'contract': f'Two defensive {spec.creature_entry} creatures, whose SmartAI flees for assistance at low '
                    f'health, stand by the caster. The caster casts {spec.spell} at the first (cast and aura read), '
                    f'attacks it for {FLEE_BLOCK_ENGAGE_MS} ms so it fights back, stops, and brings it to '
                    f'{spec.flee_health_pct}% health; its movement is read {spec.reads} times '
                    f'{spec.read_interval_ms} ms apart and must never read moving, and the brand must still be up '
                    f'after the reads. The second creature, without the brand, goes through the same steps and must '
                    f'read moving at least once (the control), proving the "{spec.quote}" clause.',
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': steps}
    model = {'kind': 'flee_block', 'quote': entry.quote}
    rule = prose_rule(entry.quote, spec.spell)
    expectations = [
        Expectation(label('cast'), BEHAVIOUR_CAST_CONDITION, spec.spell, spec.spell, None, str(NO_CAST_FAILURE),
                    rule, dict(model)),
        Expectation(label('branded'), BEHAVIOUR_CAST_CONDITION, spec.spell, spec.spell, None, str(STATE_PRESENT),
                    rule, dict(model)),
        Expectation(label('blocked'), BEHAVIOUR_CAST_CONDITION, spec.spell, spec.creature_entry, None,
                    str(STATE_ABSENT), rule, {**model, 'sum_labels': read_labels('branded')}),
        Expectation(label('held'), BEHAVIOUR_CAST_CONDITION, spec.spell, spec.spell, None, str(STATE_PRESENT),
                    rule, dict(model)),
        Expectation(label('control'), BEHAVIOUR_CAST_CONDITION, spec.spell, spec.creature_entry, None,
                    str(STATE_PRESENT), rule, {**model, 'sum_labels': read_labels('control'), 'at_least': True})]
    return scenario, expectations


def flee_block_spec(entry: dict) -> FleeBlockSpec:
    return FleeBlockSpec(entry['spell'], entry['name'], entry['quote'], int(entry['creature_entry']),
                         int(entry['flee_health_pct']), int(entry['reads']), int(entry['read_interval_ms']))


IMMUNITY_CASTS = 3
IMMUNITY_CAST_WAIT_MS = CAST_MARGIN_MS


@dataclass(frozen=True)
class ImmunityEffect:
    spell: int
    words: str


@dataclass(frozen=True)
class ImmunitySpec:
    spell: int
    name: str
    quote: str
    effects: tuple[ImmunityEffect, ...]
    target: str = CASTER


def immunity_label(spec: ImmunitySpec, subject: int, moment: str) -> str:
    return f'{spec.spell} immunity {subject} {moment}'


def dummy_casts_at_caster(spell: int, subject: str = CASTER) -> list[dict]:
    return [step for _ in range(IMMUNITY_CASTS)
            for step in ({'action': 'cast', 'actor': TARGET, 'spell': spell, 'target': subject},
                         {'action': 'wait', 'ms': IMMUNITY_CAST_WAIT_MS})]


def immunity_scenario(class_file: dict, spec: ImmunitySpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'immunity', spec.quote, STATE_ABSENT)
    for effect in spec.effects:
        if effect.words not in entry.quote:
            raise ValueError(f'{spec.spell} immunity quote {entry.quote!r} does not name {effect.words!r}')
    if spec.target not in (CASTER, ALLY):
        raise ValueError(f'{spec.spell} immunity target {spec.target!r} is the caster or the grouped ally')
    subject = spec.target
    who = 'the caster' if subject == CASTER else 'the grouped ally'
    applied_label = immunity_label(spec, spec.spell, 'applied')
    steps = (base_steps(class_file) + ally_group_steps({subject})
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}])
    for effect in spec.effects:
        steps += [{'action': 'set_aura', 'actor': subject, 'caster': TARGET, 'spell': effect.spell, 'stacks': 1},
                  measurement(immunity_label(spec, effect.spell, 'without'), subject, 'aura', spell=effect.spell),
                  {'action': 'set_aura', 'actor': subject, 'caster': TARGET, 'spell': effect.spell, 'stacks': 0}]
    cast = self_cast_attempt(spec.spell, facts_of(records, spec.spell), immunity_label(spec, spec.spell, 'cast'))
    steps += [{**step, 'target': subject} if step['action'] == 'cast' else step for step in cast]
    steps.append(measurement(applied_label, subject, 'aura', spell=spec.spell))
    for effect in spec.effects:
        steps += dummy_casts_at_caster(effect.spell, subject)
        steps.append(measurement(immunity_label(spec, effect.spell, 'with'), subject, 'aura', spell=effect.spell))
    duration_ms = int(records.duration_ms(spec.spell))
    if duration_ms <= 0:
        raise ValueError(f'{spec.spell} immunity needs a finite aura duration for its control, not {duration_ms}')
    with_arm_ms = len(spec.effects) * IMMUNITY_CASTS * IMMUNITY_CAST_WAIT_MS
    expired_label = immunity_label(spec, spec.spell, 'expired')
    steps += [{'action': 'wait', 'ms': max(CAST_MARGIN_MS, duration_ms + CAST_MARGIN_MS - with_arm_ms)},
              measurement(expired_label, subject, 'aura', spell=spec.spell)]
    for effect in spec.effects:
        steps += dummy_casts_at_caster(effect.spell, subject)
        steps += [measurement(immunity_label(spec, effect.spell, 'control'), subject, 'aura', spell=effect.spell),
                  {'action': 'set_aura', 'actor': subject, 'caster': TARGET, 'spell': effect.spell, 'stacks': 0}]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour immunity',
        'contract': f'Each named effect ({", ".join(f"{e.words} {e.spell}" for e in spec.effects)}) is applied to '
                    f'{who} by the dummy and must be present; {spec.spell} is then cast on {who}, and the '
                    f'dummy casts each effect at {who} {IMMUNITY_CASTS} times: none may be present. Once '
                    f'{spec.spell} has expired ({duration_ms} ms), the same casts from the same dummy must land, '
                    f'the control that the cast route lands at all, proving the "{spec.quote}" clause.',
        'players': [player_fixture(class_file)] + ally_players(class_file, {subject}),
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    rule = prose_rule(entry.quote, spec.spell)
    expectations = [Expectation(immunity_label(spec, spec.spell, 'cast'), BEHAVIOUR_IMMUNITY, spec.spell, spec.spell,
                                None, str(NO_CAST_FAILURE), rule, {'kind': 'immunity', 'quote': entry.quote}),
                    Expectation(applied_label, BEHAVIOUR_IMMUNITY, spec.spell, spec.spell, None, str(STATE_PRESENT),
                                rule, {'kind': 'immunity', 'quote': entry.quote})]
    for effect in spec.effects:
        model = {'kind': 'immunity', 'quote': entry.quote, 'words': effect.words}
        expectations += [
            Expectation(immunity_label(spec, effect.spell, 'without'), BEHAVIOUR_IMMUNITY, spec.spell, effect.spell,
                        None, str(STATE_PRESENT), rule, dict(model)),
            Expectation(immunity_label(spec, effect.spell, 'with'), BEHAVIOUR_IMMUNITY, spec.spell, effect.spell,
                        None, str(STATE_ABSENT), rule, dict(model)),
            Expectation(immunity_label(spec, effect.spell, 'control'), BEHAVIOUR_IMMUNITY, spec.spell, effect.spell,
                        None, str(STATE_PRESENT), rule, dict(model))]
    expectations.append(Expectation(expired_label, BEHAVIOUR_IMMUNITY, spec.spell, spec.spell, None,
                                    str(STATE_ABSENT), rule, {'kind': 'immunity', 'quote': entry.quote}))
    return scenario, expectations


def immunity_spec(entry: dict) -> ImmunitySpec:
    return ImmunitySpec(entry['spell'], entry['name'], entry['quote'],
                        tuple(ImmunityEffect(effect['spell'], effect['words']) for effect in entry['effects']),
                        entry.get('target', CASTER))


SPELL_EFFECT_THREAT = 63
THREAT_SLOPE_WAIT_MS = CAST_MARGIN_MS


@dataclass(frozen=True)
class ThreatSlopeSpec:
    spell: int
    name: str
    quote: str
    hit_spell: int
    expected_slope: float
    flat_spells: tuple[int, ...] = ()


def threat_slope_label(spec: ThreatSlopeSpec, metric: str, moment: str) -> str:
    return f'{spec.spell} threat_slope {spec.hit_spell} {metric} {moment}'


def flat_threat(records: Records, spell_id: int) -> float:
    flat = 0.0
    for effect in range(3):
        if records.field('Spell', spell_id, f'Effect[{effect}]') == SPELL_EFFECT_THREAT:
            flat += records.single_value(spell_id, effect)
    return flat


def threat_slope_scenario(class_file: dict, spec: ThreatSlopeSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'threat_slope', spec.quote, spec.expected_slope)
    facts = facts_of(records, spec.hit_spell)
    labels = {key: threat_slope_label(spec, *key.split(' ')) for key in
              ('health before', 'health after', 'threat after', 'cast_failure after')}
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.hit_spell},
                measurement(labels['health before'], TARGET, 'health'),
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.hit_spell}]
             + cast_gate_power_step(facts) + required_aura_steps(facts)
             + [{'action': 'cast', 'actor': CASTER, 'spell': spec.hit_spell, 'target': TARGET},
                {'action': 'wait', 'ms': facts.cast_time_ms + THREAT_SLOPE_WAIT_MS},
                measurement(labels['cast_failure after'], CASTER, 'cast_failure', spell=spec.hit_spell),
                measurement(labels['health after'], TARGET, 'health'),
                measurement(labels['threat after'], TARGET, 'threat', target=CASTER)])
    flat = flat_threat(records, spec.hit_spell) + sum(flat_threat(records, spell) for spell in spec.flat_spells)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour threat slope',
        'contract': f'{spec.hit_spell} is cast once at a fresh dummy; the dummy\'s threat on the caster less the flat '
                    f'{flat:g} of its SPELL_EFFECT_THREAT effects'
                    + (f' and those of {", ".join(str(spell) for spell in spec.flat_spells)}, which it triggers on '
                       f'the dummy' if spec.flat_spells else '')
                    + f', divided by the health it lost, must equal '
                    f'{spec.expected_slope:g}, proving the "{spec.quote}" clause.',
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'threat_slope', 'quote': entry.quote, 'flat': flat, 'expected': spec.expected_slope,
             'health_before_label': labels['health before'], 'health_after_label': labels['health after'],
             'threat_label': labels['threat after'], 'cast_label': labels['cast_failure after']}
    expectation = Expectation(f'{spec.spell} behaviour_threat_slope {spec.hit_spell}', BEHAVIOUR_THREAT_SLOPE,
                              spec.spell, spec.hit_spell, None, f'{spec.expected_slope:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def threat_slope_spec(entry: dict) -> ThreatSlopeSpec:
    return ThreatSlopeSpec(entry['spell'], entry['name'], entry['quote'], entry['hit_spell'],
                           float(entry['expected_slope']), tuple(int(spell) for spell in entry.get('flat_spells', ())))


EVENT_DELAY_TRIALS = 3
EVENT_DELAY_WAIT_MS = 3000


@dataclass(frozen=True)
class EventDelaySpec:
    spell: int
    name: str
    quote: str
    expected_ms: float
    observe_spell: int
    trials: int = EVENT_DELAY_TRIALS
    wait_ms: int = EVENT_DELAY_WAIT_MS


def event_delay_label(spec: EventDelaySpec, trial: int, reading: str) -> str:
    return f'{spec.spell} event_delay {trial} {reading}'


def event_delay_scenario(class_file: dict, spec: EventDelaySpec) -> tuple[dict, list[Expectation]]:
    if spec.trials < 1:
        raise ValueError(f'{spec.spell} event_delay needs at least one trial')
    if spec.observe_spell == spec.spell:
        raise ValueError(f'{spec.spell} event_delay observes its own cast; it times a different, delayed spell')
    if spec.wait_ms <= spec.expected_ms:
        raise ValueError(f'{spec.spell} event_delay waits {spec.wait_ms} ms per cast, not past the stated '
                         f'{spec.expected_ms:g} ms')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'event_delay', spec.quote, spec.expected_ms)
    facts = facts_of(records, spec.spell)
    stamp = {'stream': 'spell_damage', 'spell': spec.observe_spell, 'target': TARGET}
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    reads = []
    for trial in range(1, spec.trials + 1):
        labels = {reading: event_delay_label(spec, trial, reading) for reading in ('since_cast', 'since_hit_cast',
                                                                                   'hits')}
        reads.append(labels)
        steps += ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
                  + cast_gate_power_step(facts) + required_aura_steps(facts)
                  + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': TARGET},
                     {'action': 'wait', 'ms': facts.cast_time_ms + spec.wait_ms},
                     measurement(labels['since_cast'], CASTER, 'event_first_ms', **stamp, since_spell=spec.spell),
                     measurement(labels['since_hit_cast'], CASTER, 'event_first_ms', **stamp,
                                 since_spell=spec.observe_spell),
                     measurement(labels['hits'], CASTER, 'spell_damage_count', spell=spec.observe_spell,
                                 target=TARGET)])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour event delay',
        'contract': f'{spec.trials} casts of {spec.spell} at the dummy, {spec.wait_ms} ms apart; after each, the first '
                    f'damage of {spec.observe_spell} is stamped twice: from the cast packet of {spec.spell} and from '
                    f'the cast packet of {spec.observe_spell} itself (its own cast-to-hit time, such as a missile\'s '
                    f'travel). Their difference is the time from the cast to the delayed cast, and must land within '
                    f'the tolerance of the stated {spec.expected_ms:g} ms.',
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'event_delay', 'quote': entry.quote, 'expected_ms': spec.expected_ms, 'reads': reads,
             'observe_spell': spec.observe_spell}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_EVENT_DELAY}', BEHAVIOUR_EVENT_DELAY, spec.spell,
                              spec.observe_spell, None, f'{spec.expected_ms:g}', prose_rule(entry.quote, spec.spell),
                              model)
    return scenario, [expectation]


def event_delay_spec(entry: dict) -> EventDelaySpec:
    return EventDelaySpec(entry['spell'], entry['name'], entry['quote'], float(entry['expected_ms']),
                          entry['observe_spell'], entry.get('trials', EVENT_DELAY_TRIALS),
                          entry.get('wait_ms', EVENT_DELAY_WAIT_MS))


PROC_RESET_TRIALS = 100
PROC_RESET_BASELINE_TRIALS = 20
PROC_RESET_MIN_EVENTS = 3
PROC_RESET_READINGS = ('cooldown', 'power', 'procs')
SPELL_AURA_ADD_PCT_MODIFIER = 108
COST_MODIFIER_AURAS = frozenset({107, SPELL_AURA_ADD_PCT_MODIFIER})
SPELLMOD_COST = 14


@dataclass(frozen=True)
class ProcResetSpec:
    spell: int
    name: str
    quote: str
    reset_spell: int
    marker_spell: int
    trials: int = PROC_RESET_TRIALS
    baseline_trials: int = PROC_RESET_BASELINE_TRIALS
    min_events: int = PROC_RESET_MIN_EVENTS


def proc_reset_label(spec: ProcResetSpec, phase: str, trial: int, reading: str) -> str:
    return f'{spec.spell} proc_reset {phase} {trial} {reading}'


def next_cast_cost(records: Records, marker: int, cost: int) -> float | None:
    modifiers = [(records.field('Spell', marker, f'EffectApplyAuraName[{effect}]'),
                  records.field('Spell', marker, f'EffectBasePoints[{effect}]') + 1) for effect in range(3)
                 if records.field('Spell', marker, f'EffectMiscValue[{effect}]') == SPELLMOD_COST
                 and records.field('Spell', marker, f'EffectApplyAuraName[{effect}]') in COST_MODIFIER_AURAS]
    if len(modifiers) != 1 or modifiers[0][0] != SPELL_AURA_ADD_PCT_MODIFIER:
        return None
    return cost * (100 + modifiers[0][1]) / 100


def proc_reset_scenario(class_file: dict, spec: ProcResetSpec) -> tuple[dict, list[Expectation]]:
    if min(spec.trials, spec.baseline_trials) < 1:
        raise ValueError(f'{spec.spell} proc_reset needs trials with and without the passive')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'proc_reset', spec.quote, 0)
    facts = facts_of(records, spec.reset_spell)
    if facts.recast_ms <= 0:
        raise NotModelled(f'{spec.reset_spell} has no cooldown to reset')
    if facts.mana_cost <= 0 or facts.mana_cost_percentage or facts.mana_cost_per_level:
        raise NotModelled(f'{spec.reset_spell} has no plain power cost to read')
    level = 2 * facts.mana_cost
    interval = cast_interval(class_file, spec.reset_spell)
    if interval >= facts.recast_ms:
        raise NotModelled(f'{spec.reset_spell} recovers in {facts.recast_ms} ms, within the {interval} ms between '
                          f'its trials')
    reduced = next_cast_cost(records, spec.marker_spell, facts.mana_cost)
    if reduced is None:
        raise NotModelled(f'{spec.marker_spell} carries no single SPELLMOD_COST percent modifier, so the cost of the '
                          f'cast after a proc has no stated value')
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.reset_spell}]
    phases = {}
    for phase, trials in (('without', spec.baseline_trials), ('with', spec.trials)):
        if phase == 'with':
            steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
        start = proc_reset_label(spec, phase, 0, 'procs')
        steps.append(measurement(start, CASTER, 'spell_cast_count', spell=spec.marker_spell))
        reads = []
        for trial in range(1, trials + 1):
            labels = {reading: proc_reset_label(spec, phase, trial, reading) for reading in PROC_RESET_READINGS}
            reads.append(labels)
            steps += ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.reset_spell},
                       {'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': level}]
                      + required_aura_steps(facts)
                      + [{'action': 'cast', 'actor': CASTER, 'spell': spec.reset_spell, 'target': TARGET},
                         {'action': 'wait', 'ms': interval},
                         measurement(labels['cooldown'], CASTER, 'cooldown_ms', spell=spec.reset_spell),
                         measurement(labels['power'], CASTER, 'power', power=facts.power_type),
                         measurement(labels['procs'], CASTER, 'spell_cast_count', spell=spec.marker_spell)])
        phases[phase] = {'start': start, 'reads': reads}
    players = [{**player_fixture(class_file), 'allow_regeneration': False}]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour proc reset',
        'contract': f'{spec.baseline_trials} casts of {spec.reset_spell} without {spec.spell}, then {spec.trials} '
                    f'with it, each from a reset cooldown and {level} power: after each cast its cooldown, the power '
                    f'left and the casts of {spec.marker_spell}, the spell each proc casts, are read. A trial whose '
                    f'proc fired must read no cooldown, a trial without one the cooldown still running, and the cast '
                    f'after a proc must cost {reduced if reduced is not None else facts.mana_cost:g} instead of '
                    f'{facts.mana_cost}, proving the "{spec.quote}" clause.',
        'players': players,
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'proc_reset', 'quote': entry.quote, 'phases': phases, 'power_level': level,
             'cost': facts.mana_cost, 'reduced_cost': reduced, 'min_events': spec.min_events,
             'marker_spell': spec.marker_spell, 'reset_spell': spec.reset_spell}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_PROC_RESET}', BEHAVIOUR_PROC_RESET, spec.spell,
                              spec.reset_spell, None, '0', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def proc_reset_spec(entry: dict) -> ProcResetSpec:
    return ProcResetSpec(entry['spell'], entry['name'], entry['quote'], entry['reset_spell'], entry['marker_spell'],
                         entry.get('trials', PROC_RESET_TRIALS),
                         entry.get('baseline_trials', PROC_RESET_BASELINE_TRIALS),
                         entry.get('min_events', PROC_RESET_MIN_EVENTS))


AGGRO_SETTLE_MS = 300
AGGRO_REDIRECT_REACTION = 1


@dataclass(frozen=True)
class AggroTarget:
    distance: float
    expected_redirect: bool


@dataclass(frozen=True)
class AggroRedirectSpec:
    spell: int
    name: str
    quote: str
    targets: tuple[AggroTarget, ...]
    self_cast: bool = False
    label_suffix: str = ''
    rooted: bool = False
    geometry: bool = False


AGGRO_REDIRECT_ROOT = 42716
AGGRO_REDIRECT_DUMMY_GEOMETRY = ('combat_reach', 'position_z')
AGGRO_REDIRECT_CASTER_GEOMETRY = ('combat_reach', 'position_z', 'run_speed_rate')
AGGRO_REDIRECT_PLACEMENT_YD = 0.25


def aggro_redirect_label(spell: int, index: int, moment: str, suffix: str = '') -> str:
    return f'{spell} aggro_redirect {suffix + " " if suffix else ""}{dummy_id(index)} {moment}'


def aggro_redirect_caster_label(spell: int, metric: str, suffix: str) -> str:
    return f'{spell} aggro_redirect {suffix + " " if suffix else ""}{CASTER} {metric}'


def aggro_redirect_scenario(class_file: dict, spec: AggroRedirectSpec) -> tuple[dict, list[Expectation]]:
    if spec.geometry and not spec.rooted:
        raise ValueError(f'{spec.spell} aggro_redirect reads geometry on rooted dummies only')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'aggro_redirect', spec.quote, 1)
    facts = facts_of(records, spec.spell)
    creatures = [{**dummy_fixture(index, class_file, target.distance), 'reaction': AGGRO_REDIRECT_REACTION}
                for index, target in enumerate(spec.targets)]
    swing_ms = swing_interval(class_file)
    engage_steps = [{'action': 'set_aura', 'actor': CASTER, 'target': dummy_id(index), 'caster': dummy_id(index),
                     'spell': AGGRO_REDIRECT_ROOT, 'stacks': 1}
                    for index in range(len(spec.targets))] if spec.rooted else []
    ally_offset = 0.0
    for index, target in enumerate(spec.targets):
        engage_steps += [
            {'action': 'relocate', 'actor': ALLY, 'dx': target.distance - ally_offset},
            {'action': 'attack', 'actor': ALLY, 'target': dummy_id(index)},
            {'action': 'wait', 'ms': swing_ms + AGGRO_SETTLE_MS},
            {'action': 'stop_attack', 'actor': ALLY},
            measurement(aggro_redirect_label(spec.spell, index, 'before', spec.label_suffix), dummy_id(index),
                        'victim', target=ALLY),
        ]
        ally_offset = target.distance
    distance_reads = [measurement(aggro_redirect_label(spec.spell, index, 'distance', spec.label_suffix),
                                  dummy_id(index), 'distance_2d', target=CASTER)
                      for index in range(len(spec.targets))] if spec.rooted else []
    if spec.geometry:
        distance_reads += [measurement(aggro_redirect_label(spec.spell, index, metric, spec.label_suffix),
                                       dummy_id(index), metric)
                           for index in range(len(spec.targets)) for metric in AGGRO_REDIRECT_DUMMY_GEOMETRY]
        distance_reads += [measurement(aggro_redirect_caster_label(spec.spell, metric, spec.label_suffix), CASTER,
                                       metric)
                           for metric in AGGRO_REDIRECT_CASTER_GEOMETRY]
    cast_step = {'action': 'cast', 'actor': CASTER, 'spell': spec.spell}
    if not spec.self_cast:
        cast_step['target'] = dummy_id(0)
    steps = (base_steps(class_file)
            + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
            + engage_steps
            + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
            + cast_gate_power_step(facts)
            + required_aura_steps(facts)
            + distance_reads
            + [cast_step, {'action': 'wait', 'ms': facts.cast_time_ms + CAST_GATE_WAIT_MS}])
    for index in range(len(spec.targets)):
        steps.append(measurement(aggro_redirect_label(spec.spell, index, 'after', spec.label_suffix),
                                 dummy_id(index), 'victim', target=CASTER))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aggro redirect',
        'contract': f'Each listed dummy fixture is spawned with reaction {AGGRO_REDIRECT_REACTION} '
                    f'(REACT_DEFENSIVE): CreatureAI::UpdateVictim (CreatureAI.cpp) calls AttackStop() on every AI '
                    f'tick for a REACT_PASSIVE creature that already has a victim, which is why every other '
                    f'fixture in this harness (REACT_PASSIVE by default) can never sustain real combat, '
                    f'confirmed empirically before this fix (two independent gameplay runs, one via a forced '
                    f'Unit::Attack and one via a real player swing, both showed Unit::GetVictim() revert to null '
                    f'within the first AI tick while REACT_PASSIVE); REACT_DEFENSIVE keeps the dummy from '
                    f'auto-aggroing on sight (no proactive engagement) while still letting UpdateVictim\'s own '
                    f'threat-based SelectVictim path run once it is actually attacked. {ALLY} is relocated next '
                    f'to each dummy in turn (the fixtures are stationary, so this keeps the melee swing below in '
                    f'range without moving the dummy itself off the distance its own Absolution-radius clause is '
                    f'judged against) and real-attacks it for one swing interval (existing "attack" action), '
                    f'generating real threat so the dummy\'s own retaliation sets Unit::GetVictim() to {ALLY} '
                    f'with a non-empty threat list, the precondition Spell::EffectTaunt itself requires; the '
                    f'"before" reading on each dummy asserts that precondition. {spec.spell} is then cast '
                    f'{"at self" if spec.self_cast else f"at {dummy_id(0)}"}; the "after" reading on each dummy '
                    f'checks whether its own victim switched to {CASTER}, proving "{spec.quote}" per dummy.',
        'players': [player_fixture(class_file), {**player_fixture(class_file), 'id': ALLY}],
        'creatures': creatures,
        'steps': steps}
    if spec.rooted:
        scenario['contract'] += (f' Every dummy is rooted (Self Root Forever {AGGRO_REDIRECT_ROOT}), and its distance '
                                 f'to the caster is read right before the cast: within {AGGRO_REDIRECT_PLACEMENT_YD:g} '
                                 f'yd of its placed distance.')
    if spec.geometry:
        scenario['contract'] += (f' The combat reach and height of every dummy, and the combat reach, height and run '
                                 f'speed rate of {CASTER}, are read with the distances, as information.')
    model = {'kind': 'aggro_redirect', 'quote': entry.quote}
    expectations = []
    for index, target in enumerate(spec.targets):
        expected = '1' if target.expected_redirect else '0'
        placement = ({'distance_label': aggro_redirect_label(spec.spell, index, 'distance', spec.label_suffix),
                      'distance': target.distance, 'placement_yd': AGGRO_REDIRECT_PLACEMENT_YD}
                     if spec.rooted else {})
        expectations.append(Expectation(aggro_redirect_label(spec.spell, index, 'after', spec.label_suffix),
                                        BEHAVIOUR_AGGRO_REDIRECT, spec.spell, spec.spell, None, expected,
                                        prose_rule(entry.quote, spec.spell), {**model, **placement}))
    return scenario, expectations


def aggro_redirect_spec(entry: dict) -> AggroRedirectSpec:
    targets = tuple(AggroTarget(raw['distance'], raw['expected_redirect']) for raw in entry['targets'])
    return AggroRedirectSpec(entry['spell'], entry['name'], entry['quote'], targets, entry.get('self_cast', False),
                             entry.get('label_suffix', ''), bool(entry.get('rooted', False)),
                             bool(entry.get('geometry', False)))


@dataclass(frozen=True)
class MountGrantSpec:
    spell: int
    name: str
    grant_quote: str
    persist_quote: str
    mount_display_id: int
    persist_spell: int


def mount_grant_label(spec: MountGrantSpec, actor: str, moment: str) -> str:
    return f'{spec.spell} mount_grant {actor} {moment}'


def mount_grant_scenario(class_file: dict, spec: MountGrantSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    grant_entry = behaviour_entry(records, spec.spell, spec.name, 'mount_grant', spec.grant_quote,
                                  spec.mount_display_id)
    persist_entry = behaviour_entry(records, spec.spell, spec.name, 'mount_grant', spec.persist_quote,
                                    spec.mount_display_id)
    facts = facts_of(records, spec.spell)
    persist_facts = facts_of(records, spec.persist_spell)
    caster_granted_label = mount_grant_label(spec, CASTER, 'granted')
    ally_granted_label = mount_grant_label(spec, ALLY, 'granted')
    caster_persisted_label = mount_grant_label(spec, CASTER, 'persisted')
    ally_persisted_label = mount_grant_label(spec, ALLY, 'persisted')
    grant_steps = ([{'action': 'group', 'actor': CASTER, 'target': ALLY},
                    {'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                    {'action': 'learn', 'actor': CASTER, 'spell': spec.persist_spell},
                    {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
                  + cast_gate_power_step(facts)
                  + required_aura_steps(facts)
                  + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell},
                     {'action': 'wait', 'ms': CAST_MARGIN_MS},
                     measurement(caster_granted_label, CASTER, 'mount_display_id'),
                     measurement(ally_granted_label, ALLY, 'mount_display_id')])
    persist_steps = ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.persist_spell}]
                     + cast_gate_power_step(persist_facts)
                     + required_aura_steps(persist_facts)
                     + [{'action': 'cast', 'actor': CASTER, 'spell': spec.persist_spell, 'target': CASTER},
                        {'action': 'wait', 'ms': persist_facts.cast_time_ms + CAST_MARGIN_MS},
                        measurement(caster_persisted_label, CASTER, 'mount_display_id'),
                        measurement(ally_persisted_label, ALLY, 'mount_display_id')])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour mount grant',
        'contract': f'No-combat check: {spec.spell} is cast once with the caster grouped with an ally in range; '
                    f'both actors\' mount_display_id (Unit::GetMountID()) must read {spec.mount_display_id} '
                    f'(the display id the spell\'s own 527272/Mount() chain applies). The caster then casts the '
                    f'unrelated {spec.persist_spell} while still mounted on the steed; both actors\' '
                    f'mount_display_id must still read {spec.mount_display_id} afterwards, proving the cast did '
                    f'not dismount either of them.',
        'players': [player_fixture(class_file), {**player_fixture(class_file), 'id': ALLY}],
        'steps': base_steps(class_file) + grant_steps + persist_steps}
    grant_model = {'kind': 'mount_grant', 'caster_label': caster_granted_label, 'ally_label': ally_granted_label,
                  'expected': spec.mount_display_id, 'moment': 'granted', 'quote': grant_entry.quote}
    persist_model = {'kind': 'mount_grant', 'caster_label': caster_persisted_label,
                     'ally_label': ally_persisted_label, 'expected': spec.mount_display_id, 'moment': 'persisted',
                     'quote': persist_entry.quote}
    expectations = [
        Expectation(f'{spec.spell} behaviour_mount_grant granted', BEHAVIOUR_MOUNT_GRANT, spec.spell, spec.spell,
                   None, str(spec.mount_display_id), prose_rule(grant_entry.quote, spec.spell), grant_model),
        Expectation(f'{spec.spell} behaviour_mount_grant persisted', BEHAVIOUR_MOUNT_GRANT, spec.spell,
                   spec.persist_spell, None, str(spec.mount_display_id),
                   prose_rule(persist_entry.quote, spec.spell), persist_model),
    ]
    return scenario, expectations


def mount_grant_spec(entry: dict) -> MountGrantSpec:
    return MountGrantSpec(entry['spell'], entry['name'], entry['grant_quote'], entry['persist_quote'],
                          entry['mount_display_id'], entry['persist_spell'])


INTERNAL_COOLDOWN_SETTLE_MS = 200


@dataclass(frozen=True)
class InternalCooldownSpec:
    spell: int
    name: str
    quote: str
    window_ms: float
    trigger_spell: int
    observe_spell: int
    item: int
    item_spell: int
    allowed_wait_ms: int
    caster_health_pct: int = 50
    target: str = CASTER


def internal_cooldown_label(spec: InternalCooldownSpec, moment: str) -> str:
    return f'{spec.spell} internal_cooldown {moment}'


def internal_cooldown_scenario(class_file: dict, spec: InternalCooldownSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'internal_cooldown', spec.quote, spec.window_ms)
    facts = facts_of(records, spec.trigger_spell)

    def cast_trigger_steps() -> list[dict]:
        steps = [fixture_health_step(spec.target, spec.caster_health_pct),
                 {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell}]
        steps += required_aura_steps(facts)
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
        steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': spec.target})
        return steps

    first_label = internal_cooldown_label(spec, 'first')
    blocked_label = internal_cooldown_label(spec, 'blocked')
    allowed_label = internal_cooldown_label(spec, 'allowed')

    def observe(label: str) -> dict:
        return measurement(label, CASTER, 'spell_cast_count', spell=spec.observe_spell)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour internal cooldown',
        'contract': f'Window check: {spec.trigger_spell} is cast once, then item {spec.item} (own spell has '
                    f'StartRecoveryTime 0, so it shares no global cooldown with {spec.trigger_spell}) heals the '
                    f'same caster again well inside {spec.window_ms:g} ms of the first heal; {spec.observe_spell} '
                    f'spell_cast_count must stay unchanged across that second heal. After waiting '
                    f'{spec.allowed_wait_ms} ms past the window, {spec.trigger_spell} is cast again and '
                    f'{spec.observe_spell} spell_cast_count must then increase by exactly one.',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                  {'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell},
                  {'action': 'add_item', 'actor': CASTER, 'item': spec.item}] +
                 cast_trigger_steps() +
                 [{'action': 'wait', 'ms': INTERNAL_COOLDOWN_SETTLE_MS}, observe(first_label),
                  fixture_health_step(spec.target, spec.caster_health_pct),
                  {'action': 'use_item', 'actor': CASTER, 'item': spec.item, 'spell': spec.item_spell},
                  {'action': 'wait', 'ms': INTERNAL_COOLDOWN_SETTLE_MS}, observe(blocked_label),
                  {'action': 'wait', 'ms': spec.allowed_wait_ms}] +
                 cast_trigger_steps() +
                 [{'action': 'wait', 'ms': INTERNAL_COOLDOWN_SETTLE_MS}, observe(allowed_label)]}
    if spec.target == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]
    label = f'{spec.spell} behaviour_internal_cooldown'
    model = {'kind': 'internal_cooldown', 'first_label': first_label, 'blocked_label': blocked_label,
             'allowed_label': allowed_label, 'window_ms': spec.window_ms, 'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_INTERNAL_COOLDOWN, spec.spell, spec.trigger_spell, None,
                              str(spec.window_ms), prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def internal_cooldown_spec(entry: dict) -> InternalCooldownSpec:
    return InternalCooldownSpec(entry['spell'], entry['name'], entry['quote'], entry['window_ms'],
                                entry['trigger_spell'], entry['observe_spell'], entry['item'], entry['item_spell'],
                                entry['allowed_wait_ms'], entry.get('caster_health_pct', 50),
                                entry.get('target', CASTER))


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


CHARGE_RECHARGE_TARGETS = frozenset({CASTER, TARGET, ALLY})
DEFAULT_CHARGE_RECHARGE_TOLERANCE = 0.05


@dataclass(frozen=True)
class ChargeRechargeSpec:
    spell: int
    name: str
    quote: str
    max_charges: int
    recharge_ms: int
    target: str = CASTER
    tolerance: float = DEFAULT_CHARGE_RECHARGE_TOLERANCE


def charge_recharge_label(spec: ChargeRechargeSpec, moment: str) -> str:
    return f'{spec.spell} spell_charges {moment}'


def charge_recharge_scenario(class_file: dict, spec: ChargeRechargeSpec) -> tuple[dict, list[Expectation]]:
    if spec.target not in CHARGE_RECHARGE_TARGETS:
        raise NotModelled(f'charge recharge target {spec.target!r} is not one of {sorted(CHARGE_RECHARGE_TARGETS)}')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'charge_recharge', spec.quote, float(spec.max_charges))
    facts = facts_of(records, spec.spell)
    interval_ms = cast_interval(class_file, spec.spell)

    def attempt_steps() -> list[dict]:
        steps = [{'action': 'relocate', 'actor': CASTER, 'dx': CHARGE_OFFSET_YD}] \
            if spec.target == ALLY and closes_distance(facts) else []
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                         'value': facts.mana_cost})
        steps += required_aura_steps(facts)
        cast = {'action': 'cast', 'actor': CASTER, 'spell': spec.spell}
        if spec.target != CASTER:
            cast['target'] = spec.target
        steps.append(cast)
        steps.append({'action': 'wait', 'ms': interval_ms})
        return steps

    initial_label = charge_recharge_label(spec, 'initial')
    attempt_labels = [charge_recharge_label(spec, f'after_attempt_{i}') for i in range(1, spec.max_charges + 1)]
    overcast_label = charge_recharge_label(spec, 'after_overcast')
    cast_failure_label = f'{spec.spell} cast_failure overcast'
    before_recharge_label = charge_recharge_label(spec, 'before_recharge')
    after_recharge_label = charge_recharge_label(spec, 'after_recharge')

    elapsed_since_first_charge_consumed_ms = (spec.max_charges + 1) * interval_ms
    target_before_ms = spec.recharge_ms * (1.0 - spec.tolerance)
    target_after_ms = spec.recharge_ms * (1.0 + spec.tolerance)
    if elapsed_since_first_charge_consumed_ms >= target_before_ms:
        raise NotModelled(f'{spec.spell} spends {elapsed_since_first_charge_consumed_ms} ms casting its '
                          f'{spec.max_charges} charges and one over-cast attempt, which already reaches the '
                          f'{spec.tolerance:g} tolerance lower bound of its {spec.recharge_ms} ms recharge window')
    early_wait_ms = round(target_before_ms - elapsed_since_first_charge_consumed_ms)
    late_wait_ms = round(target_after_ms - elapsed_since_first_charge_consumed_ms) - early_wait_ms

    steps = [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    if spec.target == ALLY:
        steps.append({'action': 'group', 'actor': CASTER, 'target': ALLY})
    steps.append(measurement(initial_label, CASTER, 'spell_charges', spell=spec.spell))
    for label in attempt_labels:
        steps += attempt_steps()
        steps.append(measurement(label, CASTER, 'spell_charges', spell=spec.spell))
    steps += attempt_steps()
    steps.append(measurement(overcast_label, CASTER, 'spell_charges', spell=spec.spell))
    steps.append(measurement(cast_failure_label, CASTER, 'cast_failure', spell=spec.spell))
    steps.append({'action': 'wait', 'label': 'up to the recharge window', 'ms': early_wait_ms})
    steps.append(measurement(before_recharge_label, CASTER, 'spell_charges', spell=spec.spell))
    steps.append({'action': 'wait', 'label': 'through the recharge window', 'ms': late_wait_ms})
    steps.append(measurement(after_recharge_label, CASTER, 'spell_charges', spell=spec.spell))

    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour charge recharge',
        'contract': f'Spends all {spec.max_charges} native charges of {spec.spell} one cast at a time, confirms an '
                    f'over-cast attempt beyond the last charge is refused rather than granting a fourth, then '
                    f'brackets the {spec.recharge_ms} ms recharge window at +-{spec.tolerance * 100:g}% to prove '
                    f'one charge returns neither early nor late.',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file) + steps}
    if spec.target == ALLY:
        scenario['players'].append({**player_fixture(class_file), 'id': ALLY})
    elif spec.target == TARGET:
        scenario['creatures'] = [creature_fixture(class_file)]

    label = f'{spec.spell} behaviour_charge_recharge'
    model = {'kind': 'charge_recharge', 'initial_label': initial_label, 'attempt_labels': attempt_labels,
             'overcast_label': overcast_label, 'cast_failure_label': cast_failure_label,
             'before_recharge_label': before_recharge_label, 'after_recharge_label': after_recharge_label,
             'max_charges': spec.max_charges, 'recharge_ms': spec.recharge_ms, 'tolerance': spec.tolerance,
             'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_CHARGE_RECHARGE, spec.spell, spec.spell, None,
                              f'{spec.max_charges} charges, {spec.recharge_ms} ms recharge',
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


def charge_recharge_spec(entry: dict) -> ChargeRechargeSpec:
    return ChargeRechargeSpec(entry['spell'], entry['name'], entry['quote'], entry['max_charges'],
                              entry['recharge_ms'], entry.get('target', CASTER),
                              entry.get('tolerance', DEFAULT_CHARGE_RECHARGE_TOLERANCE))


HIT_RATIO_TRIALS = 60
HIT_RATIO_MINIMUM_SHARE = 0.5
HIT_RATIO_PILOT_TRIALS = 20
HIT_RATIO_ARMS = ('control', 'treatment')
HIT_RATIO_HEALTH_SETTLE_MS = 500


@dataclass(frozen=True)
class HitArm:
    auras: tuple[tuple[int, int], ...] = ()
    casts: tuple[int, ...] = ()
    learn: tuple[int, ...] = ()


@dataclass(frozen=True)
class HitRatioSpec:
    spell: int
    name: str
    quote: str
    expected: float
    observe_spell: int
    control: HitArm
    treatment: HitArm
    learn: tuple[int, ...] = ()
    trials: int = HIT_RATIO_TRIALS
    critical: bool | None = None
    force_crit: str | None = None
    target_health_pct: int | None = None
    label_suffix: str = ''
    metric: str = 'spell_damage_total'
    caster: str = CASTER
    target: str = TARGET
    fixture: tuple[tuple[str, int], ...] = ()
    warmup: tuple[int, ...] = ()
    off_hand_item: int | None = None
    swing_hand: int | None = None
    cast_spell: int | None = None
    cast_wait_ms: int = 0
    cast_power: int | None = None
    level: int | None = None
    target_entry: int | None = None
    refresh: bool = False
    expected_token: str = ''
    scale_auras: tuple[tuple[int, int], ...] = ()
    parts: int = 1
    rate: str = ''
    rate_spell: int | None = None
    expected_points: float | None = None
    ally_distance: float | None = None
    stated: tuple[float, tuple[float, ...]] | None = None
    stated_truncated: bool = False


ENGINE_AMOUNT_EPSILON = 1e-6


def engine_amount(amount: float) -> int:
    return int(amount + math.copysign(ENGINE_AMOUNT_EPSILON, amount))


def stated_ratio(bonus: float, parts: tuple[float, ...], truncated: bool = False) -> float:
    if truncated:
        return (math.prod(1 + engine_amount(part * (1 + bonus / 100)) / 100 for part in parts)
                / math.prod(1 + part / 100 for part in parts))
    return math.prod(1 + part * (1 + bonus / 100) / 100 for part in parts) / math.prod(1 + part / 100 for part in parts)


HIT_RATIO_METRICS = {'spell_damage_total': 'spell_damage_count', 'spell_heal_total': 'spell_heal_count',
                     'melee_damage_total': 'melee_damage_count'}
HIT_RATIO_WORDS = {'spell_damage_total': 'damage', 'spell_heal_total': 'heal', 'melee_damage_total': 'melee damage'}
SWING_METRIC = 'melee_damage_total'
SWING_HANDS = frozenset({MAIN_HAND, 1})
SWING_SETTLE_MS = 100
HIT_RATIO_FIXTURE_STATS = frozenset({'attack_power', 'ranged_attack_power', 'spell_power'})
HIT_RATIO_RATES = ('critical', 'proc')


def hit_ratio_fixture(raw: dict) -> tuple[tuple[str, int], ...]:
    unknown = set(raw) - HIT_RATIO_FIXTURE_STATS
    if unknown:
        raise ValueError(f'hit_ratio fixture fields {sorted(unknown)} are not {sorted(HIT_RATIO_FIXTURE_STATS)}')
    return tuple(sorted((name, int(value)) for name, value in raw.items()))


def hit_arm(raw: dict) -> HitArm:
    unknown = set(raw) - {'auras', 'casts', 'learn'}
    if unknown:
        raise ValueError(f'hit_ratio arm fields {sorted(unknown)} are not auras, casts or learn')
    return HitArm(tuple((int(spell), int(stacks)) for spell, stacks in raw.get('auras', ())),
                  tuple(int(spell) for spell in raw.get('casts', ())),
                  tuple(int(spell) for spell in raw.get('learn', ())))


def hit_ratio_label(spell: int, suffix: str = '') -> str:
    return f'{spell} {BEHAVIOUR_HIT_RATIO}' + (f' {suffix}' if suffix else '')


def hit_ratio_entry_label(entry: dict) -> str:
    return hit_ratio_label(entry['spell'], entry.get('label_suffix', ''))


def hit_ratio_reads(spec: HitRatioSpec, arm: str) -> list[tuple[str, str]]:
    base = f'{hit_ratio_label(spec.spell, spec.label_suffix)} {arm}'
    return [(f'{base} {mark} total', f'{base} {mark} count') for mark in ('start', *range(1, spec.trials + 1))]


def hit_ratio_scale_label(spec: HitRatioSpec, arm: str, spell: int, effect: int) -> str:
    return f'{hit_ratio_label(spec.spell, spec.label_suffix)} {arm} scale {spell} e{effect}'


def hit_ratio_cast(records: Records, spell: int, actor: str = CASTER, target: str = TARGET,
                   power: int | None = None) -> list[dict]:
    facts = facts_of(records, spell)
    steps = []
    if power is not None:
        steps.append({'action': 'set_power', 'actor': actor, 'power': facts.power_type, 'value': power})
    elif facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        steps.append({'action': 'set_power', 'actor': actor, 'power': facts.power_type, 'value': facts.mana_cost})
    steps.append({'action': 'reset_cooldown', 'actor': actor, 'spell': spell})
    steps += [{**step, 'actor': actor} for step in required_aura_steps(facts)]
    steps.append({'action': 'cast', 'actor': actor, 'spell': spell, 'target': target})
    steps.append({'action': 'wait', 'ms': max(GCD_WAIT_MS, facts.cast_time_ms + GCD_WAIT_MS)})
    return steps


def hit_ratio_steps(records: Records, spec: HitRatioSpec, swing_ms: int = 0) -> list[dict]:
    fields = ({'hand': spec.swing_hand, 'glancing': False} if spec.swing_hand is not None
              else {'spell': spec.observe_spell, 'target': spec.target})
    if spec.critical is not None:
        fields['critical'] = spec.critical
    total_metric, count_metric = spec.metric, HIT_RATIO_METRICS[spec.metric]
    event_fields = fields
    if spec.rate:
        total_metric = count_metric
        fields = {key: value for key, value in fields.items() if key != 'critical'}
        event_fields = ({**fields, 'critical': True} if spec.rate == 'critical'
                        else {**fields, 'spell': spec.rate_spell})

    def reads(labels: tuple[str, str]) -> list[dict]:
        return [measurement(labels[0], spec.caster, total_metric, **event_fields),
                measurement(labels[1], spec.caster, count_metric, **fields)]

    steps = []
    healed = []
    if spec.target_health_pct is not None:
        if not 0 < spec.target_health_pct < 100:
            raise ValueError(f'target health percent {spec.target_health_pct} must lie between 0 and 100')
        if spec.target == TARGET:
            steps += [{'action': 'set_health_pct', 'actor': CASTER, 'target': TARGET, 'pct': spec.target_health_pct},
                      {'action': 'wait', 'ms': HIT_RATIO_HEALTH_SETTLE_MS}]
        else:
            healed = [fixture_health_step(spec.target, spec.target_health_pct)]
    for name in HIT_RATIO_ARMS:
        arm = getattr(spec, name)
        marks = hit_ratio_reads(spec, name)
        steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in arm.learn]
        if spec.swing_hand is not None:
            steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                      for spell, stacks in arm.auras]
            for spell in spec.warmup:
                steps += hit_ratio_cast(records, spell)
            steps += reads(marks[0])
            steps += [measurement(hit_ratio_scale_label(spec, name, spell, effect), CASTER, 'aura_amount', spell=spell,
                                  effect=effect) for spell, effect in spec.scale_auras]
            for trial in range(1, spec.trials + 1):
                if spec.refresh:
                    steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                              for spell, stacks in arm.auras]
                for cast in arm.casts:
                    steps += hit_ratio_cast(records, cast)
                steps += [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                          {'action': 'wait', 'label': f'{name} swing {trial}', 'ms': swing_ms},
                          {'action': 'stop_attack', 'actor': CASTER},
                          {'action': 'wait', 'label': f'{name} swing {trial} settle', 'ms': SWING_SETTLE_MS}]
                steps += reads(marks[trial])
            steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 0} for spell, _ in arm.auras]
            steps += [{'action': 'unlearn', 'actor': CASTER, 'spell': spell} for spell in arm.learn]
            continue
        if spec.warmup:
            steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                      for spell, stacks in arm.auras]
            for spell in spec.warmup:
                steps += healed + hit_ratio_cast(records, spell, spec.caster, spec.target)
        steps += reads(marks[0])
        for trial in range(1, spec.trials + 1):
            steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                      for spell, stacks in arm.auras]
            for cast in arm.casts:
                steps += hit_ratio_cast(records, cast)
            steps += healed + hit_ratio_cast(records, spec.cast_spell or spec.observe_spell, spec.caster, spec.target,
                                             spec.cast_power)
            if spec.cast_wait_ms:
                steps.append({'action': 'wait', 'label': f'{name} trial {trial} hits', 'ms': spec.cast_wait_ms})
            if trial == spec.trials:
                steps.append({'action': 'wait', 'label': f'{name} drain', 'ms': DRAIN_MS})
            steps += reads(marks[trial])
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 0} for spell, _ in arm.auras]
        steps += [{'action': 'unlearn', 'actor': CASTER, 'spell': spell} for spell in arm.learn]
    return steps


def waited_ms(steps: list[dict]) -> int:
    return sum(step.get('ms', 0) for step in steps if step['action'] == 'wait')


def hit_ratio_trial_limit(class_file: dict, spec: HitRatioSpec, swing_ms: int = 0) -> int:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    one = waited_ms(hit_ratio_steps(records, replace(spec, trials=1), swing_ms))
    two = waited_ms(hit_ratio_steps(records, replace(spec, trials=2), swing_ms))
    per_trial = two - one
    return max(1, (MAX_SCENARIO_MS - TIMEOUT_MARGIN_MS - (one - per_trial)) // per_trial)


def hit_ratio_level_value(records: Records, class_file: dict, spec: HitRatioSpec) -> float:
    skills = {line: SKILL_PER_LEVEL * class_file['level'] for line in class_file.get('skill_lines', [])}
    values = set()
    for stat in (0.0, 100.0):
        caster = CasterStats(class_file['level'], stat, stat, {school: stat for school in range(7)},
                             {index: stat for index in range(5)}, skills, race=class_file['race'],
                             class_id=class_file['class_id'])
        readout = Tooltip(records, spec.spell, caster).read(records.field('Spell', spec.spell, 'Description[enUS]'))
        values |= {value.value for value in readout.values if value.text == spec.expected_token}
    if len(values) != 1:
        raise NotModelled(f'{spec.spell} hit_ratio expected_token {spec.expected_token!r} reads {sorted(values)}, not '
                          f'one value at level {class_file["level"]} whatever the stats')
    return values.pop()


def hit_ratio_scenario(class_file: dict, spec: HitRatioSpec) -> tuple[dict, list[Expectation]]:
    if spec.trials < 1:
        raise ValueError(f'{spec.spell} hit_ratio needs at least one trial')
    if spec.level is not None:
        if not 0 < spec.level <= class_file['level']:
            raise ValueError(f'{spec.spell} hit_ratio level {spec.level} lies above the class level '
                             f'{class_file["level"]} or below 1')
        class_file = {**class_file, 'level': spec.level}
    if spec.parts < 1:
        raise ValueError(f'{spec.spell} hit_ratio needs at least one part')
    if spec.rate and (spec.rate not in HIT_RATIO_RATES or spec.expected_points is None or spec.expected_token
                      or (spec.rate == 'proc') != (spec.rate_spell is not None) or spec.critical is not None):
        raise ValueError(f'{spec.spell} hit_ratio rate {spec.rate!r} is one of {HIT_RATIO_RATES}, states '
                         f'expected_points, no expected_token or critical filter, and a rate_spell exactly for proc')
    if (spec.expected_token or spec.scale_auras) and spec.swing_hand is None:
        raise ValueError(f'{spec.spell} hit_ratio judges a flat expected_token on swings only')
    if spec.scale_auras and not spec.expected_token:
        raise ValueError(f'{spec.spell} hit_ratio scale_auras scale a flat expected_token')
    if spec.control == spec.treatment:
        raise ValueError(f'{spec.spell} hit_ratio arms are identical; the contrast would measure nothing')
    if spec.force_crit is not None and spec.force_crit not in FORCE_CRIT_RATINGS:
        raise ValueError(f'{spec.spell} force_crit {spec.force_crit!r} is not one of {sorted(FORCE_CRIT_RATINGS)}')
    if spec.metric not in HIT_RATIO_METRICS:
        raise ValueError(f'{spec.spell} hit_ratio metric {spec.metric!r} is not one of {sorted(HIT_RATIO_METRICS)}')
    swinging = spec.swing_hand is not None
    if swinging != (spec.metric == SWING_METRIC) or (swinging and spec.swing_hand not in SWING_HANDS):
        raise ValueError(f'{spec.spell} hit_ratio reads {SWING_METRIC} exactly when it sets a swing_hand of '
                         f'{sorted(SWING_HANDS)}, here metric {spec.metric!r} and swing_hand {spec.swing_hand!r}')
    if swinging and (spec.caster != CASTER or spec.target != TARGET or spec.target_health_pct):
        raise ValueError(f'{spec.spell} hit_ratio swings at the dummy from the caster, with no target health')
    if swinging and spec.swing_hand and spec.off_hand_item is None:
        raise ValueError(f'{spec.spell} hit_ratio reads off-hand swings without an off_hand_item')
    if (spec.cast_spell is None and spec.cast_wait_ms and swinging) or (spec.cast_spell is not None and swinging) or \
            spec.cast_spell == spec.observe_spell or spec.cast_wait_ms < 0:
        raise ValueError(f'{spec.spell} hit_ratio casts {spec.cast_spell} to read the hits of another spell, with a '
                         f'non-negative cast_wait_ms and no swings')
    if spec.ally_distance is not None and (ALLY not in (spec.caster, spec.target) or spec.ally_distance < 0):
        raise ValueError(f'{spec.spell} hit_ratio groups the ally at {spec.ally_distance} yd, which needs the ally as '
                         f'its caster or target and a distance not below 0')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'hit_ratio', spec.quote, spec.expected)
    if spec.off_hand_item is not None:
        off_hand = off_hand_weapon(class_file, spec.off_hand_item)
        one_handed = one_hand_main(class_file)
        if one_handed is None:
            raise NotModelled(f'{spec.spell} hit_ratio dual wields, which needs a one-handed main-hand weapon in '
                              f'the class file')
        class_file = one_handed
        equip = off_hand_steps(spec.off_hand_item)
    else:
        off_hand, equip = None, []
        if not swinging:
            class_file = armed_for(class_file, records, spec.cast_spell or spec.observe_spell)
    swing_ms = (off_hand['speed_ms'] if spec.swing_hand else swing_interval(class_file)) if swinging else 0
    learned = (*spec.learn, *spec.control.casts, *spec.treatment.casts, *spec.warmup)
    observed = [] if swinging else [{'action': 'learn', 'actor': spec.caster,
                                     'spell': spec.cast_spell or spec.observe_spell}]
    grouped = ([] if spec.ally_distance is None else [{'action': 'group', 'actor': CASTER, 'target': ALLY}]
               + relocate_steps(ALLY, spec.ally_distance))
    steps = (equip + observed +
             [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in dict.fromkeys(learned)
              if swinging or spell != (spec.cast_spell or spec.observe_spell) or spec.caster != CASTER] +
             grouped + hit_ratio_steps(records, spec, swing_ms))
    waited = waited_ms(steps)
    if waited + TIMEOUT_MARGIN_MS > MAX_SCENARIO_MS:
        raise NotModelled(f'{spec.spell} hit_ratio waits {waited} ms over {spec.trials} trials, beyond one '
                          f'scenario\'s {MAX_SCENARIO_MS} ms; at most '
                          f'{hit_ratio_trial_limit(class_file, spec, swing_ms)} trials fit')
    player = {**player_fixture(class_file), **dict(spec.fixture)}
    if spec.force_crit is not None:
        player[FORCE_CRIT_RATINGS[spec.force_crit]] = FORCED_CRIT_RATING
    critical = '' if spec.critical is None else f', counting only hits with critical={spec.critical}'
    suffix = f' {spec.label_suffix}' if spec.label_suffix else ''
    ally = {**player_fixture(class_file), 'id': ALLY, **(dict(spec.fixture) if spec.caster == ALLY else {})}
    players = [player] + ([ally] if ALLY in (spec.caster, spec.target) else [])
    observed_text = (f'{spec.trials} {"off-hand" if spec.swing_hand else "main-hand"} swing intervals of '
                     f'{swing_ms} ms at {spec.target}' if swinging
                     else f'{spec.trials} casts of {spec.cast_spell}, each followed by {spec.cast_wait_ms} ms for the '
                          f'hits of {spec.observe_spell}, by {spec.caster} at {spec.target}' if spec.cast_spell
                     else f'{spec.trials} casts of {spec.observe_spell} by {spec.caster} at {spec.target}'
                          + (f', each followed by {spec.cast_wait_ms} ms for its periodic hits' if spec.cast_wait_ms
                             else ''))
    wielded = f', off-hand item {spec.off_hand_item} equipped' if spec.off_hand_item is not None else ''
    if spec.ally_distance is not None:
        wielded += f', the ally grouped with the caster and {spec.ally_distance:g} yd away'
    if spec.control.learn or spec.treatment.learn:
        wielded += (f', the spells {list(spec.control.learn)} / {list(spec.treatment.learn)} learned for their own arm '
                    f'only')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour hit ratio{suffix}',
        'contract': f'{observed_text} per arm{wielded}, '
                    f'control first, with the '
                    f'arm\'s auras {list(spec.control.auras)} / {list(spec.treatment.auras)} set and its casts '
                    f'{list(spec.control.casts)} / {list(spec.treatment.casts)} made before every observed cast, '
                    f'the cumulative {HIT_RATIO_WORDS[spec.metric]} and hit count read after every trial{critical}; '
                    f'the per-hit mean '
                    f'of the treatment arm over the control arm must give the stated bonus of '
                    f'{(spec.expected - 1) * 100:+g}%',
        'players': players,
        'creatures': [{**creature_fixture(class_file),
                       **({'entry': spec.target_entry} if spec.target_entry is not None else {})}],
        'steps': base_steps(class_file) + steps,
        'timeout_ms': waited + TIMEOUT_MARGIN_MS}
    if spec.expected_token:
        delta = hit_ratio_level_value(records, class_file, spec)
        scenario['contract'] += (f'; the treatment arm\'s non-critical, non-glancing swings must exceed the control '
                                 f'arm\'s by the {spec.expected_token} of {delta:g} the tooltip reads at level '
                                 f'{class_file["level"]}'
                                 + (f', times 1 + each percent of the auras {list(spec.scale_auras)} read on the '
                                    f'caster' if spec.scale_auras else ''))
    model = {'kind': 'hit_ratio', 'reads': {name: hit_ratio_reads(spec, name) for name in HIT_RATIO_ARMS},
             'expected': spec.expected, 'expected_bonus': (spec.expected - 1) * 100, 'trials': spec.trials,
             'trial_limit': hit_ratio_trial_limit(class_file, spec, swing_ms),
             'minimum_hits': max(1, int(spec.trials * HIT_RATIO_MINIMUM_SHARE)),
             'metric': spec.metric,
             'quote': entry.quote}
    if spec.expected_token:
        model['expected_delta'] = delta
    if spec.rate:
        model.update({'expected_delta': float(spec.expected_points), 'rate': spec.rate})
        scenario['contract'] += (f'; the arms\' {spec.rate} rate in percent per {HIT_RATIO_WORDS[spec.metric]} '
                                 f'event must differ by the stated {spec.expected_points:g} points')
    if spec.parts > 1:
        model['parts'] = spec.parts
        scenario['contract'] += f'; one of {spec.parts} identical parts whose trials are pooled'
    if spec.stated is not None:
        bonus, parts = spec.stated
        ratio = stated_ratio(bonus, parts, spec.stated_truncated)
        if abs(ratio - spec.expected) > 5e-4:
            raise ValueError(f'{spec.spell} hit_ratio expected {spec.expected} is not the ratio '
                             f'{ratio:.5g} that a {bonus:g}% bonus on the parts {list(parts)} '
                             f'gives' + (' with int32 amounts' if spec.stated_truncated else ''))
        model['stated'] = {'bonus': bonus, 'parts': list(parts)}
        if spec.stated_truncated:
            model['stated']['truncated'] = True
    if spec.scale_auras:
        model['scale_reads'] = {name: [hit_ratio_scale_label(spec, name, spell, effect)
                                       for spell, effect in spec.scale_auras] for name in HIT_RATIO_ARMS}
    expectation = Expectation(hit_ratio_label(spec.spell, spec.label_suffix), BEHAVIOUR_HIT_RATIO, spec.spell,
                              spec.observe_spell, None, str(spec.expected), prose_rule(entry.quote, spec.spell),
                              model)
    return scenario, [expectation]


def hit_ratio_spec(entry: dict) -> HitRatioSpec:
    observe = entry.get('observe_spell', 0) if entry.get('swing_hand') is not None else entry['observe_spell']
    return HitRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], observe,
                        hit_arm(entry.get('control', {})), hit_arm(entry.get('treatment', {})),
                        tuple(entry.get('learn', ())), entry.get('trials', HIT_RATIO_TRIALS), entry.get('critical'),
                        entry.get('force_crit'), entry.get('target_health_pct'), entry.get('label_suffix', ''),
                        entry.get('metric', 'spell_damage_total'), entry.get('caster', CASTER),
                        entry.get('target', TARGET), hit_ratio_fixture(entry.get('fixture', {})),
                        tuple(int(spell) for spell in entry.get('warmup', ())), entry.get('off_hand_item'),
                        entry.get('swing_hand'), entry.get('cast_spell'), int(entry.get('cast_wait_ms', 0)),
                        entry.get('cast_power'), entry.get('level'), entry.get('target_entry'),
                        bool(entry.get('refresh', False)), entry.get('expected_token', ''),
                        tuple((int(spell), int(effect)) for spell, effect in entry.get('scale_auras', ())),
                        int(entry.get('parts', 1)), entry.get('rate', ''), entry.get('rate_spell'),
                        entry.get('expected_points'), entry.get('ally_distance'),
                        None if entry.get('stated') is None else
                        (float(entry['stated']['bonus']), tuple(float(part) for part in entry['stated']['parts'])),
                        bool((entry.get('stated') or {}).get('truncated', False)))


CRIT_RATE_TRIALS = 300
CRIT_RATE_READS = ('hits', 'crits')


def crit_rate_reads(spec: HitRatioSpec, arm: str) -> dict[str, dict[str, str]]:
    base = f'{spec.spell} {BEHAVIOUR_CRIT_RATE}' + (f' {spec.label_suffix}' if spec.label_suffix else '')
    return {mark: {read: f'{base} {arm} {mark} {read}' for read in CRIT_RATE_READS} for mark in ('start', 'end')}


def crit_rate_scenario(class_file: dict, spec: HitRatioSpec) -> tuple[dict, list[Expectation]]:
    if spec.trials < 1 or spec.control == spec.treatment:
        raise ValueError(f'{spec.spell} crit_rate needs trials and two different arms')
    if spec.force_crit is not None or spec.critical is not None or spec.cast_spell is not None or \
            spec.swing_hand is not None:
        raise ValueError(f'{spec.spell} crit_rate counts every landed hit of its own casts, with no forced crit, '
                         f'crit filter, other cast or swing')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'crit_rate', spec.quote, spec.expected)
    class_file = armed_for(class_file, records, spec.observe_spell)
    fields = {'spell': spec.observe_spell, 'target': spec.target}
    learned = (*spec.learn, *spec.control.casts, *spec.treatment.casts)
    steps = [{'action': 'learn', 'actor': spec.caster, 'spell': spec.observe_spell}]
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in dict.fromkeys(learned)
              if spell != spec.observe_spell or spec.caster != CASTER]
    reads = {}
    for name in HIT_RATIO_ARMS:
        arm = getattr(spec, name)
        marks = reads[name] = crit_rate_reads(spec, name)

        def read(mark: str) -> list[dict]:
            return [measurement(marks[mark]['hits'], spec.caster, 'spell_damage_count', **fields),
                    measurement(marks[mark]['crits'], spec.caster, 'spell_damage_count', **fields, critical=True)]

        steps += read('start')
        for _ in range(spec.trials):
            steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                      for spell, stacks in arm.auras]
            for cast in arm.casts:
                steps += hit_ratio_cast(records, cast)
            steps += hit_ratio_cast(records, spec.observe_spell, spec.caster, spec.target)
        steps.append({'action': 'wait', 'label': f'{name} drain', 'ms': DRAIN_MS})
        steps += read('end')
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 0} for spell, _ in arm.auras]
    player = {**player_fixture(class_file), **dict(spec.fixture)}
    suffix = f' {spec.label_suffix}' if spec.label_suffix else ''
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour crit rate{suffix}',
        'contract': f'{spec.trials} casts of {spec.observe_spell} by {spec.caster} at {spec.target} per arm, control '
                    f'first, the arm\'s auras {list(spec.control.auras)} / {list(spec.treatment.auras)} set before '
                    f'every cast; the landed hits and the critical ones are counted at the start and the end of each '
                    f'arm; the treatment\'s critical share must exceed the control\'s by {spec.expected:g} points',
        'players': [player],
        'creatures': [creature_fixture(class_file)],
        'steps': base_steps(class_file) + steps}
    model = {'kind': 'crit_rate', 'reads': reads, 'expected': spec.expected, 'trials': spec.trials,
             'minimum_hits': max(1, int(spec.trials * HIT_RATIO_MINIMUM_SHARE)), 'quote': entry.quote}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_CRIT_RATE}' + suffix, BEHAVIOUR_CRIT_RATE, spec.spell,
                              spec.observe_spell, None, str(spec.expected), prose_rule(entry.quote, spec.spell),
                              model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


TAKEN_HIT_TRIALS = 10
TAKEN_HIT_STRIKE_WAIT_MS = 300
TAKEN_HIT_SETTLE_MS = 500
TAKEN_HIT_OPENING_SETTLE_MS = 1500
TAKEN_HIT_DEBT_MARGIN_MS = 500
TAKEN_HIT_STRIKER_ENTRY = 36
TAKEN_HIT_MINIMUM_SHARE = 0.5
TAKEN_HIT_JUDGES = ('damage_ratio', 'absorb', 'resist_rate')
TAKEN_HIT_ABSORBS = ('none', 'formula', 'share')
TAKEN_HIT_KEYS = ('damage', 'count', 'absorb', 'logs')
TAKEN_HIT_REDUCTIONS = ('none', 'formula')
TAKEN_HIT_RETURNED_KEYS = ('returned', 'returned count', 'returned logs', 'returned absorb', 'returned resist')
TAKEN_HIT_CONTROL_ARM = 'control'
TAKEN_HIT_PVP_LOCATION = {'map': 0, 'x': -9617.06, 'y': -288.949, 'z': 57.3053, 'o': 0}


@dataclass(frozen=True)
class TakenArm:
    name: str
    auras: tuple[tuple[int, int], ...] = ()
    casts: tuple[tuple[int, str], ...] = ()
    after_casts: tuple[tuple[int, str], ...] = ()
    absorb: str = 'none'
    share_pct: int = 0
    debt_removed_pct: int | None = None
    strikes: int | None = None
    opening_casts: tuple[tuple[int, str], ...] = ()
    select: str | None = None
    select_settle_ms: int = 0
    checks: tuple[tuple[tuple[str, object], ...], ...] = ()
    reduction: str = 'none'
    returned_pct: int | None = None
    refresh: bool = False


@dataclass(frozen=True)
class AbsorbTerm:
    coefficient: float
    reads: tuple[tuple[str, tuple[tuple[str, int], ...]], ...]


@dataclass(frozen=True)
class TakenHitSpec:
    spell: int
    name: str
    quote: str
    judge: str
    strike_spell: int
    arms: tuple[TakenArm, ...]
    expected: float = 1.0
    striker_entry: int = TAKEN_HIT_STRIKER_ENTRY
    strikes: int = 1
    trials: int = TAKEN_HIT_TRIALS
    caster_health_pct: int | None = None
    caster_max_health: int | None = None
    absorb_constant: float = 0.0
    absorb_terms: tuple[AbsorbTerm, ...] = ()
    debt_spell: int = 0
    learn: tuple[int, ...] = ()
    label_suffix: str = ''
    debt_ends: bool = False
    targets: tuple[tuple[str, float], ...] = ()
    cast_power: int | None = None
    settle_ms: int = TAKEN_HIT_SETTLE_MS
    striker_race: int = 0
    returned_spell: int = 0
    expected_points: float | None = None
    ally_health_pct: int | None = None


def ally_cast_targets(spec: TakenHitSpec) -> bool:
    return any(target == ALLY for arm in spec.arms for _, target in (*arm.opening_casts, *arm.casts, *arm.after_casts))


def ally_players(class_file: dict, targets) -> list[dict]:
    return [{**player_fixture(class_file), 'id': ALLY}] if ALLY in targets else []


def ally_group_steps(targets) -> list[dict]:
    return [{'action': 'group', 'actor': CASTER, 'target': ALLY}] if ALLY in targets else []


def taken_hit_cast(records: Records, spec: TakenHitSpec, spell: int, target: str,
                   power: int | None = None) -> list[dict]:
    health = ([fixture_health_step(ALLY, spec.ally_health_pct)]
              if target == ALLY and spec.ally_health_pct is not None else [])
    return health + hit_ratio_cast(records, spell, CASTER, target, power)


def taken_hit_label(spec: TakenHitSpec) -> str:
    check = BEHAVIOUR_HIT_RATIO if spec.judge == 'damage_ratio' else BEHAVIOUR_TAKEN_HIT
    return f'{spec.spell} {check}' + (f' {spec.label_suffix}' if spec.label_suffix else '')


def taken_hit_mark(spec: TakenHitSpec, arm: str, mark, key: str) -> str:
    return f'{taken_hit_label(spec)} {arm} {mark} {key}'


def taken_hit_reads(spec: TakenHitSpec, arm: str, mark, debt: bool) -> list[dict]:
    strike = {'spell': spec.strike_spell, 'caster': STRIKER, 'target': CASTER}
    noncritical = {**strike, 'critical': False} if spec.judge == 'damage_ratio' else strike
    steps = [measurement(taken_hit_mark(spec, arm, mark, 'damage'), CASTER, 'spell_damage_total', **noncritical),
             measurement(taken_hit_mark(spec, arm, mark, 'count'), CASTER, 'spell_damage_count', **noncritical),
             measurement(taken_hit_mark(spec, arm, mark, 'absorb'), CASTER, 'spell_absorb_total', **strike),
             measurement(taken_hit_mark(spec, arm, mark, 'logs'), CASTER, 'spell_log_count', **strike)]
    if debt:
        steps.append(measurement(taken_hit_mark(spec, arm, mark, 'paid'), CASTER, 'spell_damage_total',
                                 spell=spec.debt_spell, target=CASTER))
    if spec.returned_spell:
        returned = {'spell': spec.returned_spell, 'caster': CASTER, 'target': STRIKER}
        steps += [measurement(taken_hit_mark(spec, arm, mark, 'returned'), CASTER, 'spell_damage_total',
                              **returned, critical=False),
                  measurement(taken_hit_mark(spec, arm, mark, 'returned count'), CASTER, 'spell_damage_count',
                              **returned, critical=False),
                  measurement(taken_hit_mark(spec, arm, mark, 'returned logs'), CASTER, 'spell_log_count',
                              **returned),
                  measurement(taken_hit_mark(spec, arm, mark, 'returned absorb'), CASTER, 'spell_absorb_total',
                              **returned, critical=False),
                  measurement(taken_hit_mark(spec, arm, mark, 'returned resist'), CASTER, 'spell_resist_total',
                              **returned, critical=False)]
    return steps


def taken_hit_debt_reads(spec: TakenHitSpec, arm: str, trial: int, moment: str) -> list[dict]:
    return [measurement(taken_hit_mark(spec, arm, trial, f'paid {moment}'), CASTER, 'spell_damage_total',
                        spell=spec.debt_spell, target=CASTER),
            measurement(taken_hit_mark(spec, arm, trial, f'payments {moment}'), CASTER, 'spell_damage_count',
                        spell=spec.debt_spell, target=CASTER),
            measurement(taken_hit_mark(spec, arm, trial, f'debt {moment}'), CASTER, 'aura', spell=spec.debt_spell)]


def taken_hit_term_label(spec: TakenHitSpec, arm: str, term: int, read: int) -> str:
    return taken_hit_mark(spec, arm, 'term', f'{term} {read}')


def taken_rate_label(spec: TakenHitSpec, arm: str, trial: int) -> str:
    return taken_hit_mark(spec, arm, trial, 'applied')


def taken_rate_arm_steps(spec: TakenHitSpec, arm: TakenArm) -> list[dict]:
    auras = [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks} for spell, stacks in arm.auras]
    removals = [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 0} for spell, _ in arm.auras]
    steps = []
    for trial in range(1, spec.trials + 1):
        steps += (removals if arm.refresh else []) + auras
        steps += [{'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
                  {'action': 'wait', 'label': f'{arm.name} strike {trial}', 'ms': TAKEN_HIT_STRIKE_WAIT_MS},
                  measurement(taken_rate_label(spec, arm.name, trial), CASTER, 'aura', spell=spec.strike_spell),
                  {'action': 'set_aura', 'actor': CASTER, 'spell': spec.strike_spell, 'stacks': 0}]
    return steps + removals


def taken_hit_arm_steps(records: Records, spec: TakenHitSpec, arm: TakenArm) -> list[dict]:
    if spec.judge == 'resist_rate':
        return taken_rate_arm_steps(spec, arm)
    debt = arm.debt_removed_pct is not None
    auras = [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks} for spell, stacks in arm.auras]
    health = []
    if spec.caster_health_pct is not None:
        maximum = spec.caster_max_health or FIXTURE_MAX_HEALTH
        health = [{'action': 'set_health', 'actor': CASTER, 'value': spec.caster_health_pct * maximum // 100,
                   'maximum': maximum}]
    steps = auras + health
    for spell, target in arm.opening_casts:
        steps += taken_hit_cast(records, spec, spell, target)
    if arm.opening_casts:
        steps.append({'action': 'wait', 'label': f'{arm.name} opening settle', 'ms': TAKEN_HIT_OPENING_SETTLE_MS})
    if arm.select:
        steps += [{'action': 'select', 'actor': CASTER, 'target': arm.select},
                  {'action': 'wait', 'label': f'{arm.name} select settle', 'ms': arm.select_settle_ms}]
    for index, check in enumerate(arm.checks):
        steps.append({'action': 'assert', 'label': taken_hit_mark(spec, arm.name, 'check', str(index)),
                      'actor': CASTER, **dict(check)})
    if 'formula' in (arm.absorb, arm.reduction):
        for term_index, term in enumerate(spec.absorb_terms):
            for read_index, (metric, fields) in enumerate(term.reads):
                steps.append(measurement(taken_hit_term_label(spec, arm.name, term_index, read_index), CASTER,
                                         metric, **dict(fields)))
    steps += taken_hit_reads(spec, arm.name, 'start', debt)
    removals = [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 0} for spell, _ in arm.auras]
    for trial in range(1, spec.trials + 1):
        steps += (removals if arm.refresh else []) + auras + health
        for spell, target in arm.casts:
            steps += taken_hit_cast(records, spec, spell, target, spec.cast_power)
        for _ in range(arm.strikes or spec.strikes):
            steps += [{'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
                      {'action': 'wait', 'label': f'{arm.name} strike {trial}', 'ms': TAKEN_HIT_STRIKE_WAIT_MS}]
        after = []
        for spell, target in arm.after_casts:
            after += taken_hit_cast(records, spec, spell, target)
        steps += after
        if debt:
            early = int(records.duration_ms(spec.debt_spell)) - TAKEN_HIT_DEBT_MARGIN_MS - \
                TAKEN_HIT_STRIKE_WAIT_MS - waited_ms(after)
            if early <= 0:
                raise NotModelled(f'{spec.spell} taken_hit after-casts outlast the debt {spec.debt_spell}')
            steps.append({'action': 'wait', 'label': f'{arm.name} debt {trial} early', 'ms': early})
            steps += taken_hit_debt_reads(spec, arm.name, trial, 'early')
            steps.append({'action': 'wait', 'label': f'{arm.name} debt {trial} late',
                          'ms': 2 * TAKEN_HIT_DEBT_MARGIN_MS})
            steps += taken_hit_debt_reads(spec, arm.name, trial, 'late')
        else:
            steps.append({'action': 'wait', 'label': f'{arm.name} settle {trial}', 'ms': spec.settle_ms})
        steps += taken_hit_reads(spec, arm.name, trial, debt)
    steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 0} for spell, _ in arm.auras]
    return steps


def taken_hit_validate(spec: TakenHitSpec):
    if spec.judge not in TAKEN_HIT_JUDGES:
        raise ValueError(f'{spec.spell} taken_hit judge {spec.judge!r} is not one of {TAKEN_HIT_JUDGES}')
    if spec.trials < 1 or spec.strikes < 1:
        raise ValueError(f'{spec.spell} taken_hit needs at least one trial and one strike')
    if spec.ally_health_pct is not None and (not ally_cast_targets(spec) or not 0 < spec.ally_health_pct < 100):
        raise ValueError(f'{spec.spell} taken_hit ally health {spec.ally_health_pct} needs a cast at the ally and a '
                         f'percent between 0 and 100')
    names = [arm.name for arm in spec.arms]
    if len(set(names)) != len(names) or len(names) < 2:
        raise ValueError(f'{spec.spell} taken_hit needs at least two distinct arms, here {names}')
    if len({(arm.auras, arm.opening_casts, arm.casts, arm.after_casts, arm.select)
            for arm in spec.arms}) != len(spec.arms):
        raise ValueError(f'{spec.spell} taken_hit arms are identical; the contrast would measure nothing')
    if spec.judge == 'damage_ratio' and names != list(HIT_RATIO_ARMS):
        raise ValueError(f'{spec.spell} taken_hit damage_ratio compares exactly the arms {HIT_RATIO_ARMS}')
    for arm in spec.arms:
        if arm.absorb not in TAKEN_HIT_ABSORBS:
            raise ValueError(f'{spec.spell} taken_hit arm {arm.name} absorb {arm.absorb!r} is not one of '
                             f'{TAKEN_HIT_ABSORBS}')
        if arm.strikes is not None and arm.strikes < 1:
            raise ValueError(f'{spec.spell} taken_hit arm {arm.name} needs at least one strike')
        if arm.absorb == 'share' and ((arm.strikes or spec.strikes) != 1 or not 0 < arm.share_pct <= 100):
            raise ValueError(f'{spec.spell} taken_hit arm {arm.name} judges a share of one strike per trial')
        if arm.absorb == 'formula' and not spec.absorb_terms:
            raise ValueError(f'{spec.spell} taken_hit arm {arm.name} judges a formula without absorb_terms')
        if arm.debt_removed_pct is not None and (not spec.debt_spell or not 0 <= arm.debt_removed_pct <= 100):
            raise ValueError(f'{spec.spell} taken_hit arm {arm.name} judges a debt without a debt_spell')
    if spec.debt_ends and all(arm.debt_removed_pct is None for arm in spec.arms):
        raise ValueError(f'{spec.spell} taken_hit judges when a debt ends without an arm that reads one')
    if spec.caster_health_pct is not None and not 0 < spec.caster_health_pct <= 100:
        raise ValueError(f'{spec.spell} taken_hit caster health {spec.caster_health_pct} is not a percent')
    fixtures = [name for name, _ in spec.targets]
    if len(set(fixtures)) != len(fixtures) or {STRIKER, TARGET, CASTER} & set(fixtures):
        raise ValueError(f'{spec.spell} taken_hit targets {fixtures} must be distinct new fixture ids')
    for arm in spec.arms:
        if arm.select is not None and arm.select not in fixtures:
            raise ValueError(f'{spec.spell} taken_hit arm {arm.name} selects {arm.select!r}, not one of its targets')
        if arm.select is None and arm.select_settle_ms:
            raise ValueError(f'{spec.spell} taken_hit arm {arm.name} settles after a selection it does not make')
        for check in arm.checks:
            named = dict(check)
            if 'metric' not in named or not {'equals', 'min', 'max'} & set(named):
                raise ValueError(f'{spec.spell} taken_hit arm {arm.name} check {named} needs a metric and a bound')
    if spec.settle_ms < 0 or spec.striker_race < 0:
        raise ValueError(f'{spec.spell} taken_hit settle_ms and striker_race are not negative')
    for arm in spec.arms:
        if arm.reduction not in TAKEN_HIT_REDUCTIONS:
            raise ValueError(f'{spec.spell} taken_hit arm {arm.name} reduction {arm.reduction!r} is not one of '
                             f'{TAKEN_HIT_REDUCTIONS}')
        if arm.reduction == 'formula' and (arm.absorb == 'formula' or not spec.absorb_terms or spec.judge != 'absorb'
                                           or TAKEN_HIT_CONTROL_ARM not in names
                                           or arm.name == TAKEN_HIT_CONTROL_ARM):
            raise ValueError(f'{spec.spell} taken_hit arm {arm.name} judges a reduction formula against the '
                             f'{TAKEN_HIT_CONTROL_ARM} arm with absorb_terms, the absorb judge and no absorb formula')
        if (arm.returned_pct is None) != (not spec.returned_spell) or not 0 <= (arm.returned_pct or 0) <= 100:
            raise ValueError(f'{spec.spell} taken_hit arm {arm.name} states a returned percent exactly when the '
                             f'entry names a returned_spell')
    if (spec.judge == 'resist_rate') != (spec.expected_points is not None) or (
            spec.judge == 'resist_rate' and (names != list(HIT_RATIO_ARMS) or spec.debt_spell or spec.returned_spell
                                             or spec.absorb_terms or spec.caster_health_pct is not None)):
        raise ValueError(f'{spec.spell} taken_hit resist_rate states expected_points, compares exactly the arms '
                         f'{HIT_RATIO_ARMS} and reads no debt, return, absorb or health')
    if spec.returned_spell and (spec.judge != 'absorb' or all(arm.returned_pct == 0 for arm in spec.arms)):
        raise ValueError(f'{spec.spell} taken_hit returned_spell needs the absorb judge and an arm that returns')


def taken_hit_strike_base(records: Records, spec: TakenHitSpec) -> int:
    effects = [records.field('Spell', spec.strike_spell, f'Effect[{index}]') for index in range(3)]
    sides = records.field('Spell', spec.strike_spell, 'EffectDieSides[0]')
    if (effects != [SCHOOL_DAMAGE, 0, 0] or sides > 1
            or records.field('Spell', spec.strike_spell, 'EffectRealPointsPerLevel[0]')):
        raise NotModelled(f'{spec.spell} taken_hit reduction needs a strike {spec.strike_spell} of one fixed '
                          f'school damage effect')
    return int(records.field('Spell', spec.strike_spell, 'EffectBasePoints[0]')) + int(sides)


def taken_hit_scenario(class_file: dict, spec: TakenHitSpec) -> tuple[dict, list[Expectation]]:
    taken_hit_validate(spec)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'taken_hit', spec.quote, spec.expected)
    learned = dict.fromkeys((*spec.learn, *(spell for arm in spec.arms
                                            for spell, _ in (*arm.opening_casts, *arm.casts, *arm.after_casts))))
    targets = {target for arm in spec.arms for _, target in (*arm.opening_casts, *arm.casts, *arm.after_casts)}
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned] + ally_group_steps(targets)
    if spec.striker_race:
        steps += [{'action': 'pvp', 'actor': CASTER, 'enabled': True},
                  {'action': 'pvp', 'actor': STRIKER, 'enabled': True},
                  {'action': 'learn', 'actor': STRIKER, 'spell': spec.strike_spell}]
    for arm in spec.arms:
        steps += taken_hit_arm_steps(records, spec, arm)
    waited = waited_ms(steps)
    if waited + TIMEOUT_MARGIN_MS > MAX_SCENARIO_MS:
        raise NotModelled(f'{spec.spell} taken_hit waits {waited} ms, beyond one scenario\'s {MAX_SCENARIO_MS} ms')
    striker = {'id': STRIKER, 'owner': CASTER, 'entry': spec.striker_entry, 'level': class_file['level'],
               'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'stationary': True}
    creatures = ([] if spec.striker_race else [striker]) + ([creature_fixture(class_file)] if TARGET in targets else [])
    creatures += [{**creature_fixture(class_file), 'id': name, 'distance': distance} for name, distance in spec.targets]
    players = [player_fixture(class_file)] + ally_players(class_file, targets)
    if spec.striker_race:
        players.append({**player_fixture(class_file), 'id': STRIKER, 'race': spec.striker_race})
    health = (f', the caster held at {spec.caster_health_pct}% of {spec.caster_max_health or FIXTURE_MAX_HEALTH} '
              f'health before every trial' if spec.caster_health_pct is not None else '')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour taken hit'
                + (f' {spec.label_suffix}' if spec.label_suffix else ''),
        'contract': (f'A PvP-flagged player striker of race {spec.striker_race} (level {class_file["level"]}), '
                     f'hostile to the PvP-flagged caster, casts ' if spec.striker_race else
                     f'A passive, stationary striker (creature entry {spec.striker_entry}, level '
                     f'{class_file["level"]}) casts ')
                    + f'{spec.strike_spell} at the caster {spec.strikes} time(s) per trial, {spec.trials} trials per '
                    f'arm {[arm.name for arm in spec.arms]}{health}; each arm sets its auras and makes its casts '
                    f'before every strike and its after-casts after it; the damage and the absorbed amount of '
                    f'every strike are read from the spell damage logs the caster receives'
                    + (f', and the {spec.debt_spell} damage the caster pays is read just before and just after '
                       f'that debt\'s duration' if spec.debt_spell else '')
                    + (f', and the {spec.returned_spell} damage the caster deals back to the striker is read after '
                       f'each strike' if spec.returned_spell else ''),
        'players': players,
        'creatures': creatures,
        'steps': base_steps(class_file) + steps,
        'timeout_ms': waited + TIMEOUT_MARGIN_MS}
    if spec.striker_race:
        scenario['location'] = dict(TAKEN_HIT_PVP_LOCATION)
    label = taken_hit_label(spec)
    if spec.judge == 'resist_rate':
        model = {'kind': 'taken_rate', 'reads': {arm.name: [taken_rate_label(spec, arm.name, trial)
                                                            for trial in range(1, spec.trials + 1)]
                                                 for arm in spec.arms},
                 'expected_points': float(spec.expected_points), 'trials': spec.trials, 'quote': entry.quote}
        scenario['contract'] += (f'; each trial reads whether {spec.strike_spell} took hold on the caster and removes '
                                 f'it, and the treatment arm must resist it {spec.expected_points:g} points more often')
        return scenario, [Expectation(label, BEHAVIOUR_TAKEN_HIT, spec.spell, spec.strike_spell, None,
                                      str(spec.expected_points), prose_rule(entry.quote, spec.spell), model)]
    if spec.judge == 'damage_ratio':
        reads = {arm.name: [(taken_hit_mark(spec, arm.name, mark, 'damage'),
                             taken_hit_mark(spec, arm.name, mark, 'count'))
                            for mark in ('start', *range(1, spec.trials + 1))] for arm in spec.arms}
        model = {'kind': 'hit_ratio', 'reads': reads, 'expected': spec.expected,
                 'expected_bonus': (spec.expected - 1) * 100, 'trials': spec.trials, 'trial_limit': spec.trials,
                 'minimum_hits': max(1, int(spec.trials * TAKEN_HIT_MINIMUM_SHARE)), 'metric': 'spell_damage_total',
                 'quote': entry.quote}
        return scenario, [Expectation(label, BEHAVIOUR_HIT_RATIO, spec.spell, spec.strike_spell, None,
                                      str(spec.expected), prose_rule(entry.quote, spec.spell), model)]
    arms = []
    for arm in spec.arms:
        debt = arm.debt_removed_pct is not None
        keys = (*TAKEN_HIT_KEYS, *(('paid',) if debt else ()),
                *(TAKEN_HIT_RETURNED_KEYS if spec.returned_spell else ()))
        marks = {str(mark): {key: taken_hit_mark(spec, arm.name, mark, key) for key in keys}
                 for mark in ('start', *range(1, spec.trials + 1))}
        for trial in range(1, spec.trials + 1):
            if debt:
                for moment in ('early', 'late'):
                    marks[str(trial)][f'paid {moment}'] = taken_hit_mark(spec, arm.name, trial, f'paid {moment}')
                    marks[str(trial)][f'debt {moment}'] = taken_hit_mark(spec, arm.name, trial, f'debt {moment}')
        terms = ([[taken_hit_term_label(spec, arm.name, term_index, read_index)
                   for read_index in range(len(term.reads))]
                  for term_index, term in enumerate(spec.absorb_terms)]
                 if 'formula' in (arm.absorb, arm.reduction) else [])
        arms.append({'name': arm.name, 'absorb': arm.absorb, 'share_pct': arm.share_pct,
                     'debt_removed_pct': arm.debt_removed_pct, 'strikes': arm.strikes or spec.strikes,
                     'marks': marks, 'terms': terms,
                     **({'reduction': arm.reduction} if arm.reduction != 'none' else {}),
                     **({'returned_pct': arm.returned_pct} if arm.returned_pct is not None else {})})
    model = {'kind': 'taken_hit', 'arms': arms, 'trials': spec.trials,
             'minimum_trials': max(1, int(spec.trials * TAKEN_HIT_MINIMUM_SHARE)),
             'absorb_constant': spec.absorb_constant, 'debt_ends': spec.debt_ends,
             'absorb_coefficients': [term.coefficient for term in spec.absorb_terms], 'quote': entry.quote}
    if any(arm.reduction != 'none' for arm in spec.arms):
        model['strike_base'] = taken_hit_strike_base(records, spec)
    return scenario, [Expectation(label, BEHAVIOUR_TAKEN_HIT, spec.spell, spec.strike_spell, None, '0',
                                  prose_rule(entry.quote, spec.spell), model)]


def taken_arm(raw: dict) -> TakenArm:
    unknown = set(raw) - {'name', 'auras', 'casts', 'after_casts', 'absorb', 'share_pct', 'debt_removed_pct',
                          'strikes', 'opening_casts', 'select', 'select_settle_ms', 'checks', 'reduction',
                          'returned_pct', 'refresh'}
    if unknown:
        raise ValueError(f'taken_hit arm fields {sorted(unknown)} are not known')
    return TakenArm(raw['name'], tuple((int(spell), int(stacks)) for spell, stacks in raw.get('auras', ())),
                    tuple((int(spell), str(target)) for spell, target in raw.get('casts', ())),
                    tuple((int(spell), str(target)) for spell, target in raw.get('after_casts', ())),
                    raw.get('absorb', 'none'), int(raw.get('share_pct', 0)), raw.get('debt_removed_pct'),
                    raw.get('strikes'),
                    tuple((int(spell), str(target)) for spell, target in raw.get('opening_casts', ())),
                    raw.get('select'), int(raw.get('select_settle_ms', 0)),
                    tuple(tuple(sorted(check.items())) for check in raw.get('checks', ())),
                    raw.get('reduction', 'none'), raw.get('returned_pct'), bool(raw.get('refresh', False)))


def absorb_term(raw: dict) -> AbsorbTerm:
    return AbsorbTerm(float(raw['coefficient']),
                      tuple((read['metric'], tuple(sorted((key, int(value)) for key, value in read.items()
                                                          if key != 'metric'))) for read in raw['reads']))


def taken_hit_spec(entry: dict) -> TakenHitSpec:
    return TakenHitSpec(entry['spell'], entry['name'], entry['quote'], entry['judge'], entry['strike_spell'],
                        tuple(taken_arm(arm) for arm in entry['arms']), entry.get('expected', 1.0),
                        entry.get('striker_entry', TAKEN_HIT_STRIKER_ENTRY), entry.get('strikes', 1),
                        entry.get('trials', TAKEN_HIT_TRIALS), entry.get('caster_health_pct'),
                        entry.get('caster_max_health'), float(entry.get('absorb_constant', 0.0)),
                        tuple(absorb_term(term) for term in entry.get('absorb_terms', ())),
                        entry.get('debt_spell', 0), tuple(entry.get('learn', ())), entry.get('label_suffix', ''),
                        entry.get('debt_ends', False),
                        tuple((str(name), float(distance)) for name, distance in entry.get('targets', ())),
                        entry.get('cast_power'), entry.get('settle_ms', TAKEN_HIT_SETTLE_MS),
                        entry.get('striker_race', 0), entry.get('returned_spell', 0), entry.get('expected_points'),
                        entry.get('ally_health_pct'))


THREAT_REDIRECT_SWINGS = 3
THREAT_REDIRECT_SETTLE_MS = 3500
THREAT_REDIRECT_PHASES = ('control', 'treatment')


@dataclass(frozen=True)
class ThreatRedirectSpec:
    spell: int
    name: str
    quote: str
    swings: int = THREAT_REDIRECT_SWINGS
    settle_ms: int = THREAT_REDIRECT_SETTLE_MS


def threat_redirect_label(spec: ThreatRedirectSpec, phase: str, moment: str, holder: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_THREAT_REDIRECT} {phase} {moment} {holder}'


def threat_redirect_reads(spec: ThreatRedirectSpec, phase: str, moment: str) -> list[dict]:
    return [measurement(threat_redirect_label(spec, phase, moment, holder), TARGET, 'threat', target=holder)
            for holder in (ALLY, CASTER)]


def threat_redirect_scenario(class_file: dict, spec: ThreatRedirectSpec) -> tuple[dict, list[Expectation]]:
    if spec.swings < 1:
        raise ValueError(f'{spec.spell} threat_redirect needs at least one swing')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'threat_redirect', spec.quote, 1)
    facts = facts_of(records, spec.spell)
    dummy = {**creature_fixture(class_file), 'reaction': AGGRO_REDIRECT_REACTION}
    swing_ms = swing_interval(class_file)

    def swings(phase: str) -> list[dict]:
        return (threat_redirect_reads(spec, phase, BEFORE) +
                [{'action': 'attack', 'actor': ALLY, 'target': TARGET},
                 {'action': 'wait', 'label': f'{phase} swings', 'ms': spec.swings * swing_ms + AGGRO_SETTLE_MS},
                 {'action': 'stop_attack', 'actor': ALLY},
                 {'action': 'wait', 'label': f'{phase} settle', 'ms': AGGRO_SETTLE_MS}] +
                threat_redirect_reads(spec, phase, AFTER))

    steps = (base_steps(class_file) +
             [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
              {'action': 'group', 'actor': CASTER, 'target': ALLY}] +
             relocate_steps(ALLY, dummy['distance']) + swings('control') +
             [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}] + cast_gate_power_step(facts) +
             required_aura_steps(facts) +
             [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell},
              {'action': 'wait', 'label': 'redirect settle', 'ms': facts.cast_time_ms + spec.settle_ms}] +
             swings('treatment'))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour threat redirect',
        'contract': f'{ALLY}, grouped with the caster, melee-attacks a REACT_DEFENSIVE dummy for {spec.swings} swing '
                    f'intervals before and after the caster casts {spec.spell} at itself, {spec.settle_ms} ms '
                    f'before the second attack; the dummy\'s threat on {ALLY} and on the caster is read before and '
                    f'after each attack: without {spec.spell} the threat {ALLY} generates is its own, with it the '
                    f'whole of it goes to the caster',
        'players': [player_fixture(class_file), {**player_fixture(class_file), 'id': ALLY}],
        'creatures': [dummy],
        'steps': steps}
    model = {'kind': 'threat_redirect', 'quote': entry.quote,
             'reads': {phase: {moment: {holder: threat_redirect_label(spec, phase, moment, holder)
                                        for holder in (ALLY, CASTER)} for moment in (BEFORE, AFTER)}
                       for phase in THREAT_REDIRECT_PHASES}}
    return scenario, [Expectation(f'{spec.spell} {BEHAVIOUR_THREAT_REDIRECT}', BEHAVIOUR_THREAT_REDIRECT, spec.spell,
                                  spec.spell, None, '1', prose_rule(entry.quote, spec.spell), model)]


def threat_redirect_spec(entry: dict) -> ThreatRedirectSpec:
    return ThreatRedirectSpec(entry['spell'], entry['name'], entry['quote'],
                              entry.get('swings', THREAT_REDIRECT_SWINGS),
                              entry.get('settle_ms', THREAT_REDIRECT_SETTLE_MS))


SCRIPT_HIT_SETTLE_MS = 500
SCRIPT_HIT_RECEIVERS = (TARGET, STRIKER, CASTER)


@dataclass(frozen=True)
class ScriptHitSpec:
    spell: int
    name: str
    quote: str
    hit_spell: int
    trials: int
    minimum_hits: int
    casts: tuple[tuple[int, str], ...] = ()
    strike_spell: int = 0
    striker_entry: int = TAKEN_HIT_STRIKER_ENTRY
    caster_auras: tuple[tuple[int, int], ...] = ()
    caster_health_pct: int | None = None
    settle_ms: int = SCRIPT_HIT_SETTLE_MS
    learn: tuple[int, ...] = ()
    receiver: str = TARGET
    control_casts: tuple[tuple[int, str], ...] | None = None
    value_spell: int | None = None
    value_effect: int = 0
    model_auras: tuple[int, ...] = ()
    unresisted: bool = False
    stat_auras: tuple[tuple[int, int], ...] = ()
    label_suffix: str = ''


def script_hit_label(spec: ScriptHitSpec) -> str:
    return f'{spec.spell} script_hit {spec.hit_spell}' + (f' {spec.label_suffix}' if spec.label_suffix else '')


def script_hit_validate(spec: ScriptHitSpec):
    if spec.hit_spell == spec.spell:
        raise ValueError(f'{spec.spell} script_hit measures another spell than the one whose tooltip states it')
    if spec.trials < 1 or not 1 <= spec.minimum_hits:
        raise ValueError(f'{spec.spell} script_hit needs at least one trial and one hit')
    if not spec.casts and not spec.strike_spell:
        raise ValueError(f'{spec.spell} script_hit needs a cast or a strike to set off the script')
    if spec.receiver not in SCRIPT_HIT_RECEIVERS:
        raise ValueError(f'{spec.spell} script_hit receiver {spec.receiver!r} is not one of {SCRIPT_HIT_RECEIVERS}')
    if spec.receiver == STRIKER and not spec.strike_spell:
        raise ValueError(f'{spec.spell} script_hit is received by a striker that never strikes')
    if spec.caster_health_pct is not None and not 0 < spec.caster_health_pct <= 100:
        raise ValueError(f'{spec.spell} script_hit caster health {spec.caster_health_pct} is not a percent')
    cast = {spell for spell, _ in spec.casts}
    if any(aura not in cast for aura in spec.model_auras):
        raise ValueError(f'{spec.spell} script_hit models auras {list(spec.model_auras)} that its casts do not apply')
    if spec.control_casts is not None and tuple(spec.control_casts) == tuple(spec.casts):
        raise ValueError(f'{spec.spell} script_hit control_casts repeat the casts; the arms would differ in nothing')


def script_hit_trial(records: Records, spec: ScriptHitSpec, arm: str, trial: int) -> list[dict]:
    steps = [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
             for spell, stacks in spec.caster_auras]
    if spec.caster_health_pct is not None:
        steps.append({'action': 'set_health', 'actor': CASTER,
                      'value': spec.caster_health_pct * FIXTURE_MAX_HEALTH // 100, 'maximum': FIXTURE_MAX_HEALTH})
    casts = spec.control_casts if arm == 'control' and spec.control_casts is not None else spec.casts
    for spell, target in casts:
        steps += hit_ratio_cast(records, spell, CASTER, target)
    if spec.strike_spell:
        steps += [{'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
                  {'action': 'wait', 'label': f'{arm} strike {trial}', 'ms': TAKEN_HIT_STRIKE_WAIT_MS}]
    return steps + [{'action': 'wait', 'label': f'{arm} settle {trial}', 'ms': spec.settle_ms}]


def script_hit_scenario(class_file: dict, spec: ScriptHitSpec) -> tuple[dict, list[Expectation]]:
    script_hit_validate(spec)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'script_hit', spec.quote, 1)
    try:
        model = reference_script_hit_model(class_file, spec.spell, spec.hit_spell, spec.value_spell, spec.value_effect,
                                           spec.model_auras, spec.unresisted)
    except Unmodelled as error:
        raise NotModelled(f'{spec.spell} script_hit {spec.hit_spell}: {error.reason}') from error
    label = script_hit_label(spec)
    school_mask = records.field('Spell', spec.hit_spell, 'SchoolMask')
    heal = model.kind in HEAL_KINDS
    if spec.receiver == CASTER and not heal:
        raise ValueError(f'{spec.spell} script_hit reads a hit on the caster only for a heal')
    family = 'spell_heal' if heal else 'spell_damage'
    unblocked = {} if heal else {'blocked': False}
    receiver = {'target': spec.receiver}
    labels = {'total': f'{label} total', 'count': f'{label} count'}
    reads = []
    if not heal:
        reads = [measurement(ARMOR_LABEL, spec.receiver, 'armor'),
                 measurement(VIEW_LEVEL_LABEL, CASTER, 'view_level', target=spec.receiver)]
        labels.update({'armor': ARMOR_LABEL, 'view_level': VIEW_LEVEL_LABEL})
        for school in magic_schools(school_mask):
            reads.append(measurement(resistance_label(school), spec.receiver, 'resistance', school=school))
            labels[f'resistance {school}'] = resistance_label(school)
    control_label = f'{label} control count'
    learned = dict.fromkeys((*spec.learn, *(spell for spell, _ in spec.casts),
                             *(spell for spell, _ in spec.control_casts or ()),
                             *((spec.spell,) if spec.control_casts is not None else ())))
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned] + reads
    for trial in range(1, spec.trials + 1):
        steps += script_hit_trial(records, spec, 'control', trial)
    steps += [{'action': 'wait', 'label': 'control drain', 'ms': DRAIN_MS},
              measurement(control_label, CASTER, f'{family}_count', spell=spec.hit_spell, **receiver),
              {'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    for trial in range(1, spec.trials + 1):
        steps += script_hit_trial(records, spec, 'treatment', trial)
    steps.append({'action': 'wait', 'label': 'drain', 'ms': DRAIN_MS})
    for part in ('total', 'count'):
        steps.append(measurement(labels[part], CASTER, f'{family}_{part}', spell=spec.hit_spell, **receiver,
                                 critical=False, **unblocked))
    steps.append(measurement(f'{label} critical_hits', CASTER, f'{family}_count', spell=spec.hit_spell, **receiver,
                             critical=True))
    steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 0} for spell, _ in spec.caster_auras]
    waited = waited_ms(steps)
    if waited + TIMEOUT_MARGIN_MS > MAX_ACCELERATED_SCENARIO_MS:
        raise NotModelled(f'{spec.spell} script_hit waits {waited} ms, beyond the accelerated cap '
                          f'{MAX_ACCELERATED_SCENARIO_MS} ms')
    creatures = ([creature_fixture(class_file)] if spec.receiver == TARGET
                 or any(target == TARGET for _, target in spec.casts) else [])
    if spec.strike_spell:
        creatures.append({'id': STRIKER, 'owner': CASTER, 'entry': spec.striker_entry, 'level': class_file['level'],
                          'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'stationary': True})
    setup = ([f'casts {[spell for spell, _ in spec.casts]}'] if spec.casts else []) + \
        ([f'a passive, stationary striker (creature entry {spec.striker_entry}) casts {spec.strike_spell} at the '
          f'caster'] if spec.strike_spell else [])
    if spec.control_casts is None:
        control_text, control_rule = f'without {spec.spell} known', f'without {spec.spell}'
    else:
        control_text = (f'with {spec.spell} known that make the casts {[spell for spell, _ in spec.control_casts]} '
                        f'instead')
        control_rule = f'with the casts {[spell for spell, _ in spec.control_casts]} instead'
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour script hit {spec.hit_spell}',
        'contract': f'Each trial the caster {" and ".join(setup)}, {spec.trials} trials {control_text} '
                    f'(the control, which must count no {spec.hit_spell} hit) and {spec.trials} with it; the mean '
                    f'non-critical {spec.hit_spell} hit on {spec.receiver} is judged against the {spec.spell} '
                    f'tooltip read with the measured stats, its known modifiers and mitigation.'
                    + (f' {[spell for spell, _ in spec.stat_auras]} are set on the caster before its stats are '
                       f'measured.' if spec.stat_auras else ''),
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                  for spell, stacks in spec.stat_auras] + base_steps(class_file) + steps,
        'timeout_ms': waited + TIMEOUT_MARGIN_MS}
    rule = f'{model.kind} hit of script-cast spell {spec.hit_spell} read from the {spec.spell} tooltip, ' \
           f'integer steps modelled; control arm {control_rule}; {prose_rule(entry.quote, spec.spell)}'
    record = {**model_record(model, school_mask, None, labels, spec.minimum_hits), 'hit_spell': spec.hit_spell,
              'tooltip_spell': spec.spell, 'control_label': control_label, 'gate_multiplier': 1.0, 'part': 0,
              'parts': 1, 'part_casts': spec.trials}
    if spec.control_casts is not None:
        record['control_text'] = control_rule
    if spec.value_spell is not None:
        record.update({'value_spell': spec.value_spell, 'value_effect': spec.value_effect})
    if spec.model_auras:
        record['model_auras'] = list(spec.model_auras)
    if spec.unresisted:
        record['unresisted'] = True
    return scenario, [Expectation(label, 'hit_mean', spec.spell, spec.hit_spell, 0, ' | '.join(model.displayed), rule,
                                  record)]


def script_hit_spec(entry: dict) -> ScriptHitSpec:
    return ScriptHitSpec(entry['spell'], entry['name'], entry['quote'], entry['hit_spell'], entry['trials'],
                         entry['minimum_hits'],
                         tuple((int(spell), str(target)) for spell, target in entry.get('casts', ())),
                         entry.get('strike_spell', 0), entry.get('striker_entry', TAKEN_HIT_STRIKER_ENTRY),
                         tuple((int(spell), int(stacks)) for spell, stacks in entry.get('caster_auras', ())),
                         entry.get('caster_health_pct'), entry.get('settle_ms', SCRIPT_HIT_SETTLE_MS),
                         tuple(entry.get('learn', ())), entry.get('receiver', TARGET),
                         None if 'control_casts' not in entry
                         else tuple((int(spell), str(target)) for spell, target in entry['control_casts']),
                         entry.get('value_spell'), int(entry.get('value_effect', 0)),
                         tuple(int(spell) for spell in entry.get('model_auras', ())),
                         bool(entry.get('unresisted', False)),
                         tuple((int(spell), int(stacks)) for spell, stacks in entry.get('stat_auras', ())),
                         entry.get('label_suffix', ''))


TAKEN_OUTCOME_ATTACKERS = 8
TAKEN_OUTCOME_REFRESH_MS = 4000
TAKEN_OUTCOME_ENGAGE_MS = 3000
TAKEN_OUTCOME_HEALTH = 1_000_000
TAKEN_OUTCOME_ARMS = ('control', 'treatment')
TAKEN_OUTCOME_MAX_STATE = 8
TAKEN_OUTCOME_SWING_MARGIN_MS = 300


@dataclass(frozen=True)
class TakenOutcomeSpec:
    spell: int
    name: str
    quote: str
    victim_state: int
    aura: int
    stacks: int
    expected_points: float
    arm_ms: int
    attackers: int = TAKEN_OUTCOME_ATTACKERS
    attacker_entry: int = DUMMY_ENTRY
    attacker_auras: tuple[int, ...] = ()
    refresh_ms: int = TAKEN_OUTCOME_REFRESH_MS
    learn: tuple[int, ...] = ()
    state_metric: str = ''


def taken_outcome_label(spec: TakenOutcomeSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_TAKEN_OUTCOME} {spec.aura}'


def taken_outcome_attacker(index: int) -> str:
    return f'attacker{index + 1}'


def taken_outcome_reads(spec: TakenOutcomeSpec, arm: str, moment: str) -> list[dict]:
    label = taken_outcome_label(spec)
    return [measurement(f'{label} {arm} {moment} swings', CASTER, 'melee_attacks_taken'),
            measurement(f'{label} {arm} {moment} outcomes', CASTER, 'melee_attacks_taken',
                        victim_state=spec.victim_state)]


def taken_outcome_validate(spec: TakenOutcomeSpec):
    if not 0 <= spec.victim_state <= TAKEN_OUTCOME_MAX_STATE:
        raise ValueError(f'{spec.spell} taken_outcome victim_state {spec.victim_state} is not a VictimState')
    if not 1 <= spec.attackers <= TAKEN_OUTCOME_ATTACKERS:
        raise ValueError(f'{spec.spell} taken_outcome needs 1 to {TAKEN_OUTCOME_ATTACKERS} attackers')
    if spec.stacks < 1 or spec.arm_ms < spec.refresh_ms or spec.refresh_ms <= 0:
        raise ValueError(f'{spec.spell} taken_outcome needs a stacked aura and arms of whole refresh cycles')


def taken_outcome_scenario(class_file: dict, spec: TakenOutcomeSpec) -> tuple[dict, list[Expectation]]:
    taken_outcome_validate(spec)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'taken_outcome', spec.quote, spec.expected_points)
    attackers = [taken_outcome_attacker(index) for index in range(spec.attackers)]
    health = {'action': 'set_health', 'actor': CASTER, 'value': TAKEN_OUTCOME_HEALTH, 'maximum': TAKEN_OUTCOME_HEALTH}
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in spec.learn] + [health]
    swing_ms = swing_interval(class_file) + TAKEN_OUTCOME_SWING_MARGIN_MS
    for attacker in attackers:
        steps += [{'action': 'set_aura', 'actor': CASTER, 'target': attacker, 'caster': attacker, 'spell': aura,
                   'stacks': 1} for aura in spec.attacker_auras]
        steps += [{'action': 'attack', 'actor': CASTER, 'target': attacker},
                  {'action': 'wait', 'label': f'engage {attacker}', 'ms': swing_ms}, health]
    steps += [{'action': 'stop_attack', 'actor': CASTER},
              {'action': 'wait', 'label': 'engage', 'ms': TAKEN_OUTCOME_ENGAGE_MS}]
    cycles = spec.arm_ms // spec.refresh_ms
    for arm in TAKEN_OUTCOME_ARMS:
        steps += taken_outcome_reads(spec, arm, 'start')
        aura = ([{'action': 'set_aura', 'actor': CASTER, 'spell': spec.aura, 'stacks': 0},
                 {'action': 'set_aura', 'actor': CASTER, 'spell': spec.aura, 'stacks': spec.stacks}]
                if arm == 'treatment' else [])
        for cycle in range(cycles):
            steps += aura + [health, {'action': 'wait', 'label': f'{arm} swings {cycle + 1}', 'ms': spec.refresh_ms}]
            if spec.state_metric and cycle == 0:
                steps.append(measurement(f'{taken_outcome_label(spec)} {arm} {spec.state_metric}', CASTER,
                                         spec.state_metric))
        steps += taken_outcome_reads(spec, arm, 'end')
    steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.aura, 'stacks': 0})
    waited = waited_ms(steps)
    if waited + TIMEOUT_MARGIN_MS > MAX_ACCELERATED_SCENARIO_MS:
        raise NotModelled(f'{spec.spell} taken_outcome waits {waited} ms, beyond the accelerated cap '
                          f'{MAX_ACCELERATED_SCENARIO_MS} ms')
    creatures = [{'id': attacker, 'owner': CASTER, 'entry': spec.attacker_entry, 'level': class_file['level'],
                  'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 2, 'stationary': True}
                 for attacker in attackers]
    hasted = f' each carrying {list(spec.attacker_auras)}' if spec.attacker_auras else ''
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour taken outcome {spec.aura}',
        'contract': f'{spec.attackers} aggressive, stationary attackers (creature entry {spec.attacker_entry}, level '
                    f'{class_file["level"]}){hasted} melee the caster in front of it; the melee packets the caster '
                    f'receives are counted with and without victim state {spec.victim_state}, {spec.arm_ms} ms '
                    f'without {spec.aura} (the control) and {spec.arm_ms} ms with {spec.aura} removed and set again '
                    f'at {spec.stacks} stacks every {spec.refresh_ms} ms (set_aura keeps the duration of an aura it '
                    f'finds); the outcome rates are compared. The caster engages each '
                    f'attacker with one swing interval of auto attack, then stops'
                    + (f'; it knows {list(spec.learn)} in both arms' if spec.learn else '') + '.',
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': base_steps(class_file) + steps,
        'timeout_ms': waited + TIMEOUT_MARGIN_MS}
    label = taken_outcome_label(spec)
    reads = {arm: {f'{moment} {key}': f'{label} {arm} {moment} {key}' for moment in ('start', 'end')
                   for key in ('swings', 'outcomes')} for arm in TAKEN_OUTCOME_ARMS}
    if spec.state_metric:
        model_states = {arm: f'{label} {arm} {spec.state_metric}' for arm in TAKEN_OUTCOME_ARMS}
    else:
        model_states = {}
    model = {'kind': 'taken_outcome', 'reads': reads, 'states': model_states, 'expected_points': spec.expected_points,
             'victim_state': spec.victim_state, 'stacks': spec.stacks, 'quote': entry.quote}
    return scenario, [Expectation(label, BEHAVIOUR_TAKEN_OUTCOME, spec.spell, spec.aura, None,
                                  str(spec.expected_points), prose_rule(entry.quote, spec.spell), model)]


def taken_outcome_spec(entry: dict) -> TakenOutcomeSpec:
    return TakenOutcomeSpec(entry['spell'], entry['name'], entry['quote'], entry['victim_state'], entry['aura'],
                            entry['stacks'], float(entry['expected_points']), entry['arm_ms'],
                            entry.get('attackers', TAKEN_OUTCOME_ATTACKERS),
                            entry.get('attacker_entry', DUMMY_ENTRY), tuple(entry.get('attacker_auras', ())),
                            entry.get('refresh_ms', TAKEN_OUTCOME_REFRESH_MS), tuple(entry.get('learn', ())),
                            entry.get('state_metric', ''))


CHARM_READ_MS = 500
CHARM_CLEANUP_MS = 15000
CHARM_SPELL_HIT_BONUS = 100.0
CHARM_FACTION_SNAPSHOT = 'faction_before_charm'


@dataclass(frozen=True)
class CharmImmunitySpec:
    spell: int
    name: str
    quote: str
    charm_spell: int
    words: str = 'charm'


def charm_immunity_label(spec: CharmImmunitySpec, arm: str) -> str:
    return f'{spec.spell} charm_immunity {spec.charm_spell} {arm}'


def charm_cleanup_steps(spec: CharmImmunitySpec, arm: str) -> list[dict]:
    def held(label: str, actor: str, metric: str, equals: int, **fields) -> dict:
        return {'action': 'assert', 'label': f'{spec.spell} {arm} CLEANUP: {label}', 'actor': actor,
                'metric': metric, **fields, 'equals': equals, 'within_ms': CHARM_CLEANUP_MS}

    return [{'action': 'set_aura', 'actor': CASTER, 'caster': TARGET, 'spell': spec.charm_spell, 'stacks': 0},
            held('no charm aura', CASTER, 'aura', 0, spell=spec.charm_spell),
            held('no charmer', CASTER, 'charmed', 0),
            held('control back', CASTER, 'controls_self', 1),
            held('faction back', CASTER, 'faction', 0, relative_to=CHARM_FACTION_SNAPSHOT),
            held('dummy attacks nobody', TARGET, 'victim', 0, target=CASTER),
            measurement(f'{spec.spell} {arm} dummy combat', TARGET, 'combat')]


def charm_immunity_scenario(class_file: dict, spec: CharmImmunitySpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'charm_immunity', spec.quote, STATE_ABSENT)
    if spec.words not in entry.quote:
        raise ValueError(f'{spec.spell} charm_immunity quote {entry.quote!r} does not name {spec.words!r}')

    def charm(arm: str) -> list[dict]:
        return [{'action': 'cast', 'actor': TARGET, 'spell': spec.charm_spell, 'target': CASTER},
                {'action': 'wait', 'label': f'{arm} charm', 'ms': CHARM_READ_MS},
                measurement(charm_immunity_label(spec, arm), CASTER, 'aura', spell=spec.charm_spell)]

    applied_label = charm_immunity_label(spec, 'applied')
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                {'action': 'snapshot', 'actor': CASTER, 'metric': 'faction', 'save_as': CHARM_FACTION_SNAPSHOT}]
             + charm('without') + charm_cleanup_steps(spec, 'without')
             + self_cast_attempt(spec.spell, facts_of(records, spec.spell), charm_immunity_label(spec, 'cast'))
             + [measurement(applied_label, CASTER, 'aura', spell=spec.spell)]
             + charm('with') + charm_cleanup_steps(spec, 'with'))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour charm immunity',
        'contract': f'The dummy casts {spec.charm_spell} at the caster without {spec.spell} (the control) and again '
                    f'with {spec.spell} up; each time the charm aura is read {CHARM_READ_MS} ms after the cast, '
                    f'inside the charm, and the charm is then removed; after each arm the scenario asserts no charm '
                    f'aura, no charmer, the caster\'s own control and faction back and a dummy that attacks nobody, '
                    f'and fails otherwise; the dummy\'s combat state is read, not asserted, because a passive '
                    f'creature keeps a PvE combat reference (CreatureAI::UpdateVictim).',
        'players': [player_fixture(class_file)],
        'creatures': [{**creature_fixture(class_file), 'spell_hit_bonus': CHARM_SPELL_HIT_BONUS}],
        'steps': steps}
    waited = waited_ms(steps)
    cleanup_asserts = sum(step.get('within_ms') == CHARM_CLEANUP_MS for step in steps)
    scenario['timeout_ms'] = waited + cleanup_asserts * CHARM_CLEANUP_MS + TIMEOUT_MARGIN_MS
    rule = prose_rule(entry.quote, spec.spell)
    model = {'kind': 'charm_immunity', 'quote': entry.quote}
    return scenario, [
        Expectation(charm_immunity_label(spec, 'without'), BEHAVIOUR_IMMUNITY, spec.spell, spec.charm_spell, None,
                    str(STATE_PRESENT), rule, model),
        Expectation(charm_immunity_label(spec, 'cast'), BEHAVIOUR_IMMUNITY, spec.spell, spec.spell, None,
                    str(NO_CAST_FAILURE), rule, model),
        Expectation(applied_label, BEHAVIOUR_IMMUNITY, spec.spell, spec.spell, None, str(STATE_PRESENT), rule,
                    model),
        Expectation(charm_immunity_label(spec, 'with'), BEHAVIOUR_IMMUNITY, spec.spell, spec.charm_spell, None,
                    str(STATE_ABSENT), rule, model)]


def charm_immunity_spec(entry: dict) -> CharmImmunitySpec:
    return CharmImmunitySpec(entry['spell'], entry['name'], entry['quote'], entry['charm_spell'],
                             entry.get('words', 'charm'))


def sized_behaviour(entry: dict, trials: dict[str, int] | None) -> dict:
    if not trials or entry.get('kind') != 'hit_ratio':
        return entry
    label = hit_ratio_entry_label(entry)
    return {**entry, 'trials': trials[label]} if label in trials else entry


DETECTION_WAIT_MS = 1500
DETECTION_DISTANCE_YD = 10.0
DETECTION_METRIC = 'can_detect'
DETECTION_MOMENTS = ('shown', 'hidden', 'revealed', 'unrevealed')
DETECTION_PREDICATE = 'predicate'
DETECTION_CLIENT = 'client'
DETECTION_CLIENT_METRIC = 'nearby_creature_at_client'
DETECTION_STEP_YD = 3.0
DETECTION_STEP_WAIT_MS = 1000


@dataclass(frozen=True)
class DetectionSpec:
    spell: int
    name: str
    quote: str
    reveal_aura: int
    hide_auras: tuple[tuple[int, str], ...]
    distance: float = DETECTION_DISTANCE_YD
    wait_ms: int = DETECTION_WAIT_MS
    read: str = DETECTION_PREDICATE
    step_yd: float = DETECTION_STEP_YD
    step_wait_ms: int = DETECTION_STEP_WAIT_MS


def detection_label(spec: DetectionSpec, name: str, moment: str) -> str:
    reading = ' client' if spec.read == DETECTION_CLIENT else ''
    return f'{spec.spell} behaviour_detection{reading} {name} {moment}'


def detection_metric(spec: DetectionSpec) -> str:
    return DETECTION_CLIENT_METRIC if spec.read == DETECTION_CLIENT else DETECTION_METRIC


def detection_scenario(class_file: dict, spec: DetectionSpec) -> tuple[dict, list[Expectation]]:
    if not spec.hide_auras or len({name for _, name in spec.hide_auras}) != len(spec.hide_auras):
        raise ValueError(f'{spec.spell} detection needs hide auras with distinct names')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'detection', spec.quote, 1.0)
    dummy = {**creature_fixture(class_file), 'distance': spec.distance}

    def read(name: str, moment: str) -> list[dict]:
        settle = [{'action': 'wait', 'label': f'{name} {moment} settle', 'ms': spec.wait_ms}]
        if spec.read != DETECTION_CLIENT:
            return settle + [measurement(detection_label(spec, name, moment), CASTER, DETECTION_METRIC,
                                         target=TARGET)]
        steps = [{'action': 'relocate', 'actor': CASTER, 'dy': spec.step_yd},
                 {'action': 'wait', 'label': f'{name} {moment} step out', 'ms': spec.step_wait_ms},
                 {'action': 'relocate', 'actor': CASTER, 'dy': -spec.step_yd},
                 {'action': 'wait', 'label': f'{name} {moment} step back', 'ms': spec.step_wait_ms}]
        return settle + steps + [measurement(detection_label(spec, name, moment), CASTER, DETECTION_CLIENT_METRIC,
                                             entry=dummy['entry'])]

    def aura(spell: int, stacks: int, caster: str | None = None) -> dict:
        return {'action': 'set_aura', 'actor': CASTER, 'target': TARGET, 'spell': spell, 'stacks': stacks,
                **({'caster': caster} if caster else {})}

    steps = base_steps(class_file)
    expectations = []
    for hide, name in spec.hide_auras:
        steps += (read(name, 'shown') + [aura(hide, 1)] + read(name, 'hidden')
                  + [aura(spec.reveal_aura, 1, CASTER)] + read(name, 'revealed')
                  + [aura(spec.reveal_aura, 0, CASTER)] + read(name, 'unrevealed') + [aura(hide, 0)])
        for before, after, before_expected, expected in (('shown', 'hidden', 1.0, 0.0),
                                                         ('hidden', 'revealed', 0.0, 1.0),
                                                         ('revealed', 'unrevealed', 1.0, 0.0)):
            model = {'kind': 'metric_delta', 'before_label': detection_label(spec, name, before),
                     'after_label': detection_label(spec, name, after), 'expected': expected,
                     'before_expected': before_expected, 'metric': detection_metric(spec), 'quote': entry.quote}
            expectations.append(Expectation(detection_label(spec, name, after), BEHAVIOUR_METRIC_DELTA, spec.spell,
                                            spec.reveal_aura, None, f'{expected:g}',
                                            prose_rule(entry.quote, spec.spell), model))
    if spec.read == DETECTION_CLIENT:
        title = f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour detection client'
        contract = (f'The caster has a dummy {spec.distance:g} yd away in its client-visible set; for each of '
                    f'{list(spec.hide_auras)} the dummy leaves that set once hidden by that aura, returns once '
                    f'{spec.reveal_aura} is set on it with the caster as its caster, and leaves it once that is '
                    f'removed; before each read the caster steps {spec.step_yd:g} yd aside and back, '
                    f'{spec.step_wait_ms} ms apart, so the server runs its own visibility update.')
    else:
        title = f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour detection'
        contract = (f'The caster can detect a dummy {spec.distance:g} yd away (Unit::CanSeeOrDetect); for each of '
                    f'{list(spec.hide_auras)} it is hidden by that aura (not detected), then {spec.reveal_aura} is set '
                    f'on it with the caster as its caster (detected again), then removed (hidden again); each read '
                    f'follows {spec.wait_ms} ms.')
    scenario = {
        'schema': 1,
        'name': title,
        'contract': contract,
        'players': [player_fixture(class_file)],
        'creatures': [dummy],
        'steps': steps}
    return scenario, expectations


def detection_spec(entry: dict) -> DetectionSpec:
    return DetectionSpec(entry['spell'], entry['name'], entry['quote'], int(entry['reveal_aura']),
                         tuple((int(spell), str(name)) for spell, name in entry['hide_auras']),
                         float(entry.get('distance', DETECTION_DISTANCE_YD)),
                         int(entry.get('wait_ms', DETECTION_WAIT_MS)),
                         detection_read(entry.get('read', DETECTION_PREDICATE), entry['spell']),
                         float(entry.get('step_yd', DETECTION_STEP_YD)),
                         int(entry.get('step_wait_ms', DETECTION_STEP_WAIT_MS)))


def detection_read(read: str, spell: int) -> str:
    if read not in (DETECTION_PREDICATE, DETECTION_CLIENT):
        raise ValueError(f'{spell} detection read {read!r} is neither {DETECTION_PREDICATE!r} nor '
                         f'{DETECTION_CLIENT!r}')
    return read


SOURCE_STACK_WAIT_MS = 1500
SOURCE_STACK_ARMS = ('none', 'one', 'two')


@dataclass(frozen=True)
class SourceStackSpec:
    spell: int
    name: str
    quote: str
    metrics: tuple[str, ...]
    caster_auras: tuple[int, ...] = ()
    wait_ms: int = SOURCE_STACK_WAIT_MS


def source_stack_label(spec: SourceStackSpec, metric: str, arm: str) -> str:
    return f'{spec.spell} behaviour_source_stack {metric} {arm}'


def source_stack_scenario(class_file: dict, spec: SourceStackSpec) -> tuple[dict, list[Expectation]]:
    if not spec.metrics:
        raise ValueError(f'{spec.spell} source_stack reads at least one stat')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'source_stack', spec.quote, 1.0)
    facts = facts_of(records, spec.spell)

    def cast(actor: str) -> list[dict]:
        return ([{'action': 'set_aura', 'actor': actor, 'spell': aura, 'stacks': 1} for aura in spec.caster_auras]
                + [{'action': 'reset_cooldown', 'actor': actor, 'spell': spec.spell}]
                + [{**step, 'actor': actor} for step in required_aura_steps(facts)]
                + [{'action': 'cast', 'actor': actor, 'spell': spec.spell, 'target': actor},
                   {'action': 'wait', 'label': f'{actor} {spec.spell} settle', 'ms': spec.wait_ms}])

    def reads(arm: str) -> list[dict]:
        return ([measurement(source_stack_label(spec, metric, arm), CASTER, metric) for metric in spec.metrics]
                + [measurement(source_stack_label(spec, f'aura {source}', arm), CASTER, 'aura', spell=spec.spell,
                               caster=source) for source in (CASTER, ALLY)])

    second = {'cast failure': measurement(source_stack_label(spec, 'ally cast failure', 'two'), ALLY, 'cast_failure',
                                          spell=spec.spell),
              'own copy': measurement(source_stack_label(spec, 'ally carries ally', 'two'), ALLY, 'aura',
                                      spell=spec.spell, caster=ALLY)}
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': actor, 'spell': spec.spell} for actor in (CASTER, ALLY)]
             + [{'action': 'group', 'actor': CASTER, 'target': ALLY}]
             + [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1} for aura in spec.caster_auras]
             + [{'action': 'wait', 'label': 'mounted settle', 'ms': spec.wait_ms}]
             + reads('none') + cast(CASTER) + reads('one') + cast(ALLY) + reads('two') + list(second.values()))
    model = {'kind': 'source_stack', 'metrics': list(spec.metrics), 'quote': entry.quote,
             'reads': {metric: {arm: source_stack_label(spec, metric, arm) for arm in SOURCE_STACK_ARMS}
                       for metric in spec.metrics},
             'sources': {arm: [source_stack_label(spec, f'aura {source}', arm) for source in (CASTER, ALLY)]
                         for arm in SOURCE_STACK_ARMS},
             'second_source': {key: step['label'] for key, step in second.items()}}
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour source stack',
        'contract': f'The caster and a grouped {ALLY}, both carrying {list(spec.caster_auras)}, each cast '
                    f'{spec.spell}; {list(spec.metrics)} are read on the caster with no source, with its own and '
                    f'with both, and each stat with both sources must read the one-source value; the ally\'s cast '
                    f'failure and its own copy are read after its cast.',
        'players': [player_fixture(class_file), {**player_fixture(class_file), 'id': ALLY}],
        'steps': steps}
    return scenario, [Expectation(f'{spec.spell} behaviour_source_stack', BEHAVIOUR_SOURCE_STACK, spec.spell,
                                  spec.spell, None, 'one source', prose_rule(entry.quote, spec.spell), model)]


def source_stack_spec(entry: dict) -> SourceStackSpec:
    return SourceStackSpec(entry['spell'], entry['name'], entry['quote'], tuple(entry['metrics']),
                           tuple(int(aura) for aura in entry.get('caster_auras', ())),
                           int(entry.get('wait_ms', SOURCE_STACK_WAIT_MS)))


STAT_GAIN_SETTLE_MS = 200
STAT_GAIN_WAIT_MS = 500
STAT_GAIN_RETURN = 'return'


@dataclass(frozen=True)
class StatGainArm:
    name: str
    learn: tuple[int, ...] = ()
    auras: tuple[tuple[int, int], ...] = ()
    gain: float | None = None


@dataclass(frozen=True)
class StatGainSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    metric: str
    arms: tuple[StatGainArm, ...]
    terms: tuple[AbsorbTerm, ...]
    cast_target: str = CASTER
    fields: tuple[tuple[str, int], ...] = ()
    clear_auras: tuple[int, ...] = ()
    target_health_pct: int | None = None
    label_suffix: str = ''
    wait_ms: int = STAT_GAIN_WAIT_MS


def stat_gain_label(spec: StatGainSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA}' + (f' {spec.label_suffix}' if spec.label_suffix else '')


def stat_gain_mark(spec: StatGainSpec, arm: str, key: str) -> str:
    return f'{stat_gain_label(spec)} {arm} {key}'


STAT_GAIN_AURA_EFFECTS = frozenset({6, 35, 65, 119, 128, 129, 143})
STAT_GAIN_TRIGGER_EFFECTS = frozenset({64, 142})
STAT_GAIN_ATTRIBUTION = 'attribution'
STAT_GAIN_READS = {
    'armor': 'Unit::GetArmor, the client field UNIT_FIELD_RESISTANCES + 0',
    'attack_power': 'Unit::GetTotalAttackPowerValue(BASE_ATTACK), from the client fields UNIT_FIELD_ATTACK_POWER, '
                    'UNIT_FIELD_ATTACK_POWER_MODS and UNIT_FIELD_ATTACK_POWER_MULTIPLIER',
    'spell_power': 'Unit::SpellBaseDamageBonusDone(school mask), the function the engine calls at use time; '
                   'in the source, Player::UpdateSpellDamageAndHealingBonus (StatSystem.cpp:282-291) copies it to '
                   'PLAYER_FIELD_MOD_DAMAGE_DONE_POS + school, a field this run does not read',
}


def applies_aura(records: Records, spell: int) -> bool:
    return any(effect in STAT_GAIN_AURA_EFFECTS for effect in facts_of(records, spell).effects)


def cast_auras(records: Records, spell: int) -> list[int]:
    found = [spell] if applies_aura(records, spell) else []
    for effect, kind in enumerate(facts_of(records, spell).effects):
        triggered = records.field('Spell', spell, f'EffectTriggerSpell[{effect}]')
        if kind in STAT_GAIN_TRIGGER_EFFECTS and triggered and applies_aura(records, triggered):
            found.append(triggered)
    return found


def stat_gain_withheld_arm(spec: StatGainSpec) -> str | None:
    if (spec.spell in spec.arms[0].learn or spec.arms[0].gain is None
            or not any(spec.spell in arm.learn for arm in spec.arms[1:])):
        return None
    return spec.arms[0].name


def stat_gain_attribution(records: Records, spec: StatGainSpec) -> dict | None:
    own_cast = spec.cast_spell == spec.spell and spec.spell in spec.clear_auras
    withheld = stat_gain_withheld_arm(spec)
    read = STAT_GAIN_READS.get(spec.metric)
    if not spec.clear_auras or not (own_cast or withheld) or read is None:
        return None
    candidates = list(dict.fromkeys([*spec.clear_auras, *cast_auras(records, spec.cast_spell)]))
    return {'spell': spec.spell, 'auras': list(spec.clear_auras), 'candidates': candidates, 'withheld_arm': withheld,
            'read': read}


def target_aura_steps(spec: StatGainSpec, spells, stacks: int = 0) -> list[dict]:
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks,
             **({'target': spec.cast_target} if spec.cast_target != CASTER else {})} for spell in spells]


def stat_gain_aura_reads(spec: StatGainSpec, arm: str, candidates: list[int], moment: str) -> tuple[list, dict]:
    labels = [[aura, stat_gain_mark(spec, arm, f'aura {aura} {moment}')] for aura in candidates]
    count = stat_gain_mark(spec, arm, f'auras {moment}')
    casts = stat_gain_mark(spec, arm, f'casts {moment}')
    steps = [measurement(label, spec.cast_target, 'aura', spell=aura) for aura, label in labels]
    steps += [measurement(count, spec.cast_target, 'applied_aura_count'),
              measurement(casts, CASTER, 'spell_cast_count', spell=spec.cast_spell)]
    return steps, {'auras': labels, 'count': count, 'casts': casts}


def stat_gain_validate(spec: StatGainSpec):
    names = [arm.name for arm in spec.arms]
    if len(names) < 2 or len(set(names)) != len(names):
        raise ValueError(f'{spec.spell} stat_gain needs at least two distinct arms, here {names}')
    if spec.cast_target not in (CASTER, ALLY):
        raise ValueError(f'{spec.spell} stat_gain casts at the caster or the ally, not {spec.cast_target!r}')
    if not spec.terms and any(arm.gain is None for arm in spec.arms):
        raise ValueError(f'{spec.spell} stat_gain judges an arm by a formula without terms')
    if not any(arm.gain is None for arm in spec.arms):
        raise ValueError(f'{spec.spell} stat_gain needs an arm judged by the formula')
    if spec.target_health_pct is not None and spec.cast_target != ALLY:
        raise ValueError(f'{spec.spell} stat_gain sets the health of an ally it does not cast at')


def stat_gain_scenario(class_file: dict, spec: StatGainSpec) -> tuple[dict, list[Expectation]]:
    stat_gain_validate(spec)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'stat_gain', spec.quote, 0.0)
    facts = facts_of(records, spec.cast_spell)
    attribution = stat_gain_attribution(records, spec)
    steps = (base_steps(class_file) + ally_group_steps({spec.cast_target})
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell}])
    arms = []
    for arm in spec.arms:
        steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in arm.learn]
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                  for spell, stacks in arm.auras]
        steps += target_aura_steps(spec, spec.clear_auras)
        steps.append({'action': 'wait', 'label': f'{arm.name} settle', 'ms': STAT_GAIN_SETTLE_MS})
        terms = []
        for term_index, term in enumerate(spec.terms):
            labels = []
            for read_index, (metric, fields) in enumerate(term.reads):
                label = stat_gain_mark(spec, arm.name, f'term {term_index} {read_index}')
                steps.append(measurement(label, CASTER, metric, **dict(fields)))
                labels.append(label)
            terms.append(labels)
        before, after = stat_gain_mark(spec, arm.name, BEFORE), stat_gain_mark(spec, arm.name, AFTER)
        reads = {}
        if attribution:
            aura_steps, reads[BEFORE] = stat_gain_aura_reads(spec, arm.name, attribution['candidates'], BEFORE)
            steps += aura_steps
        steps.append(measurement(before, spec.cast_target, spec.metric, **dict(spec.fields)))
        if spec.target_health_pct is not None:
            steps.append(fixture_health_step(spec.cast_target, spec.target_health_pct))
        steps += ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell}]
                  + cast_gate_power_step(facts) + required_aura_steps(facts)
                  + [{'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': spec.cast_target},
                     {'action': 'wait', 'label': f'{arm.name} cast wait', 'ms': facts.cast_time_ms + spec.wait_ms},
                     measurement(after, spec.cast_target, spec.metric, **dict(spec.fields))])
        if attribution:
            aura_steps, reads[AFTER] = stat_gain_aura_reads(spec, arm.name, attribution['candidates'], AFTER)
            reads[STAT_GAIN_RETURN] = stat_gain_mark(spec, arm.name, STAT_GAIN_RETURN)
            steps += (aura_steps + target_aura_steps(spec, spec.clear_auras)
                      + [{'action': 'wait', 'label': f'{arm.name} return', 'ms': STAT_GAIN_SETTLE_MS},
                         measurement(reads[STAT_GAIN_RETURN], spec.cast_target, spec.metric, **dict(spec.fields))])
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 0} for spell, _ in arm.auras]
        arms.append({'name': arm.name, 'before': before, 'after': after, 'gain': arm.gain, 'terms': terms,
                     **({STAT_GAIN_ATTRIBUTION: reads} if attribution else {})})
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour stat gain'
                + (f' {spec.label_suffix}' if spec.label_suffix else ''),
        'contract': f'Each arm {[arm.name for arm in spec.arms]} learns its spells, sets its auras on the caster, '
                    f'reads the caster\'s stats the formula names, then the {spec.metric} of the '
                    f'{spec.cast_target} right before and right after a real cast of {spec.cast_spell} at it; the '
                    f'gain is judged exactly against the arm\'s stated gain, or within the truncation of the '
                    f'formula on the stats read.'
                    + (f' Around each cast it reads the auras {attribution["candidates"]} and the aura count of the '
                       f'{spec.cast_target} and the caster\'s casts of {spec.cast_spell}, then removes '
                       f'{attribution["auras"]} and reads the {spec.metric} again.'
                       if attribution else ''),
        'players': [player_fixture(class_file)] + ally_players(class_file, {spec.cast_target}),
        'steps': steps}
    model = {'kind': 'stat_gain', 'arms': arms, 'coefficients': [term.coefficient for term in spec.terms],
             'metric': spec.metric, 'quote': entry.quote,
             **({STAT_GAIN_ATTRIBUTION: attribution} if attribution else {})}
    return scenario, [Expectation(stat_gain_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.cast_spell, None,
                                  '0', prose_rule(entry.quote, spec.spell), model)]


def stat_gain_spec(entry: dict) -> StatGainSpec:
    arms = []
    for raw in entry['arms']:
        unknown = set(raw) - {'name', 'learn', 'auras', 'gain'}
        if unknown:
            raise ValueError(f'stat_gain arm fields {sorted(unknown)} are not known')
        arms.append(StatGainArm(raw['name'], tuple(raw.get('learn', ())),
                                tuple((int(spell), int(stacks)) for spell, stacks in raw.get('auras', ())),
                                raw.get('gain')))
    return StatGainSpec(entry['spell'], entry['name'], entry['quote'], entry['cast_spell'], entry['metric'],
                        tuple(arms), tuple(absorb_term(term) for term in entry.get('terms', ())),
                        entry.get('cast_target', CASTER), tuple(sorted(entry.get('fields', {}).items())),
                        tuple(entry.get('clear_auras', ())), entry.get('target_health_pct'),
                        entry.get('label_suffix', ''), entry.get('wait_ms', STAT_GAIN_WAIT_MS))


FALL_DAMAGE_AURA_SETTLE_MS = 1500
FALL_DAMAGE_SETTLE_MS = 500
FALL_DAMAGE_ARMS = ('without', 'with')


@dataclass(frozen=True)
class FallDamageSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    height: float
    receiver: str = ALLY
    label_suffix: str = ''


def fall_damage_label(spec: FallDamageSpec, arm: str, moment: str) -> str:
    suffix = f' {spec.label_suffix}' if spec.label_suffix else ''
    return f'{spec.spell} {BEHAVIOUR_FALL_DAMAGE}{suffix} {arm} {moment}'


def fall_damage_scenario(class_file: dict, spec: FallDamageSpec) -> tuple[dict, list[Expectation]]:
    if spec.receiver not in (CASTER, ALLY):
        raise ValueError(f'{spec.spell} fall_damage lands the caster or the ally, not {spec.receiver!r}')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'fall_damage', spec.quote, spec.height)
    facts = facts_of(records, spec.cast_spell)

    def landing(arm: str) -> list[dict]:
        return [fixture_health_step(spec.receiver, 100),
                {'action': 'wait', 'ms': FALL_DAMAGE_SETTLE_MS},
                measurement(fall_damage_label(spec, arm, BEFORE), spec.receiver, 'health'),
                {'action': 'fall', 'label': f'{arm} landing', 'actor': spec.receiver, 'height': spec.height},
                measurement(fall_damage_label(spec, arm, AFTER), spec.receiver, 'health')]

    aura_label = fall_damage_label(spec, 'with', 'aura')
    group = [{'action': 'group', 'actor': CASTER, 'target': ALLY}] if spec.receiver == ALLY else []
    steps = (base_steps(class_file) + group
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell}]
             + landing('without')
             + cast_gate_power_step(facts) + required_aura_steps(facts)
             + [{'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': CASTER},
                {'action': 'wait', 'ms': FALL_DAMAGE_AURA_SETTLE_MS},
                measurement(aura_label, spec.receiver, 'aura', spell=spec.cast_spell)]
             + landing('with'))
    players = [player_fixture(class_file)] + ([{**player_fixture(class_file), 'id': ALLY}]
                                              if spec.receiver == ALLY else [])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour fall damage'
                + (f' {spec.label_suffix}' if spec.label_suffix else ''),
        'contract': f'The {spec.receiver} lands from {spec.height:g} yd at {FIXTURE_MAX_HEALTH} maximum health, '
                    f'once before and once after a real cast of {spec.cast_spell} puts its aura on it. The landing '
                    f'is harness-simulated: the fall action feeds the server\'s own landing handler '
                    f'(Player::HandleFall) a MovementInfo, as a client MSG_MOVE_FALL_LAND would. The health lost with '
                    f'the aura must be below the health lost without it, proving the "{spec.quote}" clause.',
        'players': players,
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'fall_damage', 'height': spec.height, 'quote': entry.quote,
             'arms': {arm: [fall_damage_label(spec, arm, BEFORE), fall_damage_label(spec, arm, AFTER)]
                      for arm in FALL_DAMAGE_ARMS}}
    rule = prose_rule(entry.quote, spec.spell)
    return scenario, [
        Expectation(fall_damage_label(spec, 'with', 'reduced'), BEHAVIOUR_FALL_DAMAGE, spec.spell, spec.cast_spell,
                    None, 'below the health lost without the aura', rule, model),
        Expectation(aura_label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.cast_spell, None, str(STATE_PRESENT),
                    rule, {'kind': 'fall_damage', 'reading': 'aura'})]


def fall_damage_spec(entry: dict) -> FallDamageSpec:
    return FallDamageSpec(entry['spell'], entry['name'], entry['quote'], int(entry['cast_spell']),
                          float(entry['height']), entry.get('receiver', ALLY), entry.get('label_suffix', ''))


def behaviour_scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    if entry['kind'] == 'fall_damage':
        return fall_damage_scenario(class_file, fall_damage_spec(entry))
    if entry['kind'] == 'school_lockout':
        from expiry import school_lockout_scenario
        return school_lockout_scenario(class_file, entry)
    if entry['kind'] == 'count':
        return target_count_scenario(class_file, target_count_spec(entry))
    if entry['kind'] == 'fixed_count':
        return fixed_target_count_scenario(class_file, fixed_target_count_spec(entry))
    if entry['kind'] == 'party_stat_ratio':
        return party_stat_ratio_scenario(class_file, party_stat_ratio_spec(entry))
    if entry['kind'] == 'ally_heal_breadth':
        return ally_heal_breadth_scenario(class_file, ally_heal_breadth_spec(entry))
    if entry['kind'] == 'ratio':
        return healing_ratio_scenario(class_file, healing_ratio_spec(entry))
    if entry['kind'] == 'leech_ratio':
        return leech_ratio_scenario(class_file, leech_ratio_spec(entry))
    if entry['kind'] == 'cast_leech_ratio':
        return cast_leech_ratio_scenario(class_file, cast_leech_ratio_spec(entry))
    if entry['kind'] == 'stat_gain':
        return stat_gain_scenario(class_file, stat_gain_spec(entry))
    if entry['kind'] == 'cast_stat_ratio':
        return cast_stat_ratio_scenario(class_file, cast_stat_ratio_spec(entry))
    if entry['kind'] == 'spread':
        return aura_spread_scenario(class_file, aura_spread_spec(entry))
    if entry['kind'] == 'trigger':
        return shield_break_trigger_scenario(class_file, shield_break_trigger_spec(entry))
    if entry['kind'] == 'metric_delta':
        return metric_delta_scenario(class_file, metric_delta_spec(entry))
    if entry['kind'] == 'aura_metric_delta':
        return aura_metric_delta_scenario(class_file, aura_metric_delta_spec(entry))
    if entry['kind'] == 'cast_applies_aura':
        return cast_applies_aura_scenario(class_file, cast_applies_aura_spec(entry))
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
    if entry['kind'] == 'oath_consumption':
        return oath_consumption_scenario(class_file, oath_consumption_spec(entry))
    if entry['kind'] == 'oath_consumption_removal':
        return oath_consumption_removal_scenario(class_file, oath_consumption_removal_spec(entry))
    if entry['kind'] == 'internal_cooldown_gate':
        return icd_gate_scenario(class_file, icd_gate_spec(entry))
    if entry['kind'] == 'exclusivity':
        return exclusivity_chain_scenario(class_file, exclusivity_chain_spec(entry))
    if entry['kind'] == 'group_stack_cap':
        return group_stack_cap_scenario(class_file, group_stack_cap_spec(entry))
    if entry['kind'] == 'single_target':
        return single_target_scenario(class_file, single_target_spec(entry))
    if entry['kind'] == 'crit_magnitude':
        return crit_magnitude_scenario(class_file, crit_magnitude_spec(entry))
    if entry['kind'] == 'charge_recharge':
        return charge_recharge_scenario(class_file, charge_recharge_spec(entry))
    if entry['kind'] == 'cast_gate':
        return cast_gate_scenario(class_file, cast_gate_spec(entry))
    if entry['kind'] == 'cast_condition':
        return cast_condition_scenario(class_file, cast_condition_spec(entry))
    if entry['kind'] == 'mount_grant':
        return mount_grant_scenario(class_file, mount_grant_spec(entry))
    if entry['kind'] == 'internal_cooldown':
        return internal_cooldown_scenario(class_file, internal_cooldown_spec(entry))
    if entry['kind'] == 'cast_combat':
        return cast_combat_scenario(class_file, cast_combat_spec(entry))
    if entry['kind'] == 'cast_state':
        return cast_state_scenario(class_file, cast_state_spec(entry))
    if entry['kind'] == 'mount_block':
        return mount_block_scenario(class_file, mount_block_spec(entry))
    if entry['kind'] == 'flee_block':
        return flee_block_scenario(class_file, flee_block_spec(entry))
    if entry['kind'] == 'immunity':
        return immunity_scenario(class_file, immunity_spec(entry))
    if entry['kind'] == 'threat_slope':
        return threat_slope_scenario(class_file, threat_slope_spec(entry))
    if entry['kind'] == 'event_delay':
        return event_delay_scenario(class_file, event_delay_spec(entry))
    if entry['kind'] == 'proc_reset':
        return proc_reset_scenario(class_file, proc_reset_spec(entry))
    if entry['kind'] == 'aggro_redirect':
        return aggro_redirect_scenario(class_file, aggro_redirect_spec(entry))
    if entry['kind'] == 'dispel_removal':
        return dispel_removal_scenario(class_file, dispel_removal_spec(entry))
    if entry['kind'] == 'amount_match':
        return amount_match_scenario(class_file, amount_match_spec(entry))
    if entry['kind'] == 'aura_presence':
        return aura_presence_scenario(class_file, aura_presence_spec(entry))
    if entry['kind'] == 'heal_block':
        return heal_block_scenario(class_file, heal_block_spec(entry))
    if entry['kind'] == 'threat_tick_ratio':
        return threat_tick_ratio_scenario(class_file, threat_tick_ratio_spec(entry))
    if entry['kind'] == 'group_target':
        return group_target_scenario(class_file, group_target_spec(entry))
    if entry['kind'] == 'cost_gate':
        return cost_gate_scenario(class_file, cost_gate_spec(entry))
    if entry['kind'] == 'site_purchase':
        return site_purchase_scenario(class_file, site_purchase_spec(entry))
    if entry['kind'] == 'periodic_dispel':
        return periodic_dispel_scenario(class_file, periodic_dispel_spec(entry))
    if entry['kind'] == 'absorb_pierce_ratio':
        return absorb_pierce_ratio_scenario(class_file, absorb_pierce_ratio_spec(entry))
    if entry['kind'] == 'hit_ratio':
        return hit_ratio_scenario(class_file, hit_ratio_spec(entry))
    if entry['kind'] == 'crit_rate':
        return crit_rate_scenario(class_file, hit_ratio_spec({'trials': CRIT_RATE_TRIALS, **entry}))
    if entry['kind'] == 'taken_hit':
        return taken_hit_scenario(class_file, taken_hit_spec(entry))
    if entry['kind'] == 'threat_redirect':
        return threat_redirect_scenario(class_file, threat_redirect_spec(entry))
    if entry['kind'] == 'dispel_count':
        return dispel_count_scenario(class_file, dispel_count_spec(entry))
    if entry['kind'] == 'script_hit':
        return script_hit_scenario(class_file, script_hit_spec(entry))
    if entry['kind'] == 'taken_outcome':
        return taken_outcome_scenario(class_file, taken_outcome_spec(entry))
    if entry['kind'] == 'charm_immunity':
        return charm_immunity_scenario(class_file, charm_immunity_spec(entry))
    if entry['kind'] == 'detection':
        return detection_scenario(class_file, detection_spec(entry))
    if entry['kind'] == 'source_stack':
        return source_stack_scenario(class_file, source_stack_spec(entry))
    raise NotModelled(f'behaviour kind {entry["kind"]!r} has no scenario builder')


DISPEL_COUNT_TARGET = ALLY
DISPEL_COUNT_TRIALS = 3
DISPEL_COUNT_WAIT_MS = 800


@dataclass(frozen=True)
class DispelCountArm:
    name: str
    auras: tuple[tuple[int, int], ...]
    expected: tuple[tuple[int, int], ...]


@dataclass(frozen=True)
class DispelCountSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    debuffs: tuple[tuple[int, tuple[int, ...]], ...]
    arms: tuple[DispelCountArm, ...]
    trials: int = DISPEL_COUNT_TRIALS
    wait_ms: int = DISPEL_COUNT_WAIT_MS
    label_suffix: str = ''


def dispel_count_check(spec: DispelCountSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_DISPEL_COUNT}' + (f' {spec.label_suffix}' if spec.label_suffix else '')


def dispel_count_read_label(spec: DispelCountSpec, arm: str, trial: int, debuff: int, moment: str) -> str:
    return f'{dispel_count_check(spec)} {arm} {trial} {debuff} {moment}'


def dispel_count_label(spec: DispelCountSpec, arm: str, dispel_type: int) -> str:
    return f'{dispel_count_check(spec)} {arm} {DISPEL_TYPE_NAMES[dispel_type]}'


def dispel_count_validate(records: Records, spec: DispelCountSpec):
    names = [arm.name for arm in spec.arms]
    if len(set(names)) != len(names) or len(names) < 2:
        raise ValueError(f'{spec.spell} dispel_count needs at least two distinct arms, here {names}')
    if not any(not arm.auras for arm in spec.arms):
        raise ValueError(f'{spec.spell} dispel_count needs a control arm without auras')
    types = [dispel_type for dispel_type, _ in spec.debuffs]
    for dispel_type, debuffs in spec.debuffs:
        if dispel_type not in DISPEL_TYPE_NAMES or not debuffs:
            raise ValueError(f'{spec.spell} dispel_count type {dispel_type} needs a known dispel type and debuffs')
        for debuff in debuffs:
            if records.field('Spell', debuff, 'Dispel') != dispel_type:
                raise ValueError(f'{spec.spell} dispel_count debuff {debuff} is not of dispel type {dispel_type}')
    for arm in spec.arms:
        if sorted(dispel_type for dispel_type, _ in arm.expected) != sorted(types):
            raise ValueError(f'{spec.spell} dispel_count arm {arm.name} must state a count for every dispel type')
        for dispel_type, count in arm.expected:
            if not 0 <= count <= len(dict(spec.debuffs)[dispel_type]):
                raise ValueError(f'{spec.spell} dispel_count arm {arm.name} expects {count} of type {dispel_type}, '
                                 f'more than the {len(dict(spec.debuffs)[dispel_type])} debuffs it carries')


def dispel_count_scenario(class_file: dict, spec: DispelCountSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    dispel_count_validate(records, spec)
    entry = behaviour_entry(records, spec.spell, spec.name, 'dispel_count', spec.quote, 0.0)
    debuffs = [debuff for _, group in spec.debuffs for debuff in group]
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell}]
    for arm in spec.arms:
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                  for spell, stacks in arm.auras]
        for trial in range(1, spec.trials + 1):
            steps += [{'action': 'set_aura', 'actor': DISPEL_COUNT_TARGET, 'spell': debuff, 'stacks': 1}
                      for debuff in debuffs]
            steps += [measurement(dispel_count_read_label(spec, arm.name, trial, debuff, BEFORE), DISPEL_COUNT_TARGET,
                                  'aura', spell=debuff) for debuff in debuffs]
            steps += hit_ratio_cast(records, spec.cast_spell, CASTER, DISPEL_COUNT_TARGET)
            steps.append({'action': 'wait', 'ms': spec.wait_ms})
            steps += [measurement(dispel_count_read_label(spec, arm.name, trial, debuff, AFTER), DISPEL_COUNT_TARGET,
                                  'aura', spell=debuff) for debuff in debuffs]
            steps += [{'action': 'set_aura', 'actor': DISPEL_COUNT_TARGET, 'spell': debuff, 'stacks': 0}
                      for debuff in debuffs]
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 0} for spell, _ in arm.auras]
    waited = waited_ms(steps)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour dispel count'
                + (f' {spec.label_suffix}' if spec.label_suffix else ''),
        'contract': f'The ally carries {[list(group) for _, group in spec.debuffs]} (dispel types '
                    f'{[dispel_type for dispel_type, _ in spec.debuffs]}); the caster casts {spec.cast_spell} on it '
                    f'{spec.trials} times per arm {[arm.name for arm in spec.arms]}, each arm setting its auras first; '
                    f'each debuff is read before and {spec.wait_ms} ms after every cast, and the removals are counted '
                    f'per dispel type.',
        'players': [player_fixture(class_file), {**player_fixture(class_file), 'id': DISPEL_COUNT_TARGET}],
        'steps': base_steps(class_file) + steps,
        'timeout_ms': waited + TIMEOUT_MARGIN_MS}
    expectations = []
    for arm in spec.arms:
        for dispel_type, count in arm.expected:
            group = dict(spec.debuffs)[dispel_type]
            reads = [[[dispel_count_read_label(spec, arm.name, trial, debuff, BEFORE),
                       dispel_count_read_label(spec, arm.name, trial, debuff, AFTER)] for debuff in group]
                     for trial in range(1, spec.trials + 1)]
            model = {'kind': 'dispel_count', 'arm': arm.name, 'dispel_type': dispel_type, 'reads': reads,
                     'expected': count, 'quote': entry.quote}
            expectations.append(Expectation(dispel_count_label(spec, arm.name, dispel_type), BEHAVIOUR_DISPEL_COUNT,
                                            spec.spell, spec.cast_spell, None, str(count),
                                            prose_rule(entry.quote, spec.spell), model))
    return scenario, expectations


def dispel_count_spec(entry: dict) -> DispelCountSpec:
    arms = tuple(DispelCountArm(arm['name'], tuple((int(spell), int(stacks)) for spell, stacks in arm.get('auras', ())),
                                tuple((int(kind), int(count)) for kind, count in arm['expected']))
                 for arm in entry['arms'])
    debuffs = tuple((int(kind), tuple(int(debuff) for debuff in group)) for kind, group in entry['debuffs'])
    return DispelCountSpec(entry['spell'], entry['name'], entry['quote'], entry['cast_spell'], debuffs, arms,
                           entry.get('trials', DISPEL_COUNT_TRIALS), entry.get('wait_ms', DISPEL_COUNT_WAIT_MS),
                           entry.get('label_suffix', ''))


def behaviour_entries(class_file: dict, spell_ids: list[int] | None) -> list[dict]:
    entries = class_file.get('behaviours', [])
    if spell_ids is None:
        return entries
    chosen = [entry for entry in entries if entry['spell'] in spell_ids]
    unknown = set(spell_ids) - {entry['spell'] for entry in chosen}
    if unknown:
        raise ValueError(f'Spells {sorted(unknown)} are not {class_file["name"]} behaviour entries')
    return chosen
