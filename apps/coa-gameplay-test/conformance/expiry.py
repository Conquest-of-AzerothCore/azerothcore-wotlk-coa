from dataclasses import dataclass
import math
from pathlib import Path

from behaviours import (CAST_SETTLE_MS, MECHANIC_DR_RESET_MS, MECHANIC_GAP_MARGIN_MS, STRIKER, STRIKER_DISTANCE,
                        STRIKER_HEALTH, CastAppliesAuraSpec, NotModelled, ally_group_steps, ally_players,
                        behaviour_entry, cast_applies_aura_player,
                        cast_applies_aura_spec, cast_gate_power_step,
                        cast_applies_aura_steps, duration_refresh_spec, duration_spec, extra_cast_setup,
                        extra_cast_steps, mechanic_duration_spec, prose_rule)
from hits import MAIN_HAND, MAX_ACCELERATED_SCENARIO_MS, UNMODELLED, creature_fixture, records_of, timed
from procs import swing_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import FORCED_CRIT_RATING, TARGET, Expectation, armed_for, dataset, facts_of, required_aura_steps

BEHAVIOUR_EXPIRY = 'behaviour_expiry'
EXPIRY_KIND = 'expiry'
PRESENCE_METRIC = 'aura'
CLOCK_STEP_MS = 25
SHIFT_SHARE = 0.05
SHIFT_FLOOR_MS = 2 * CLOCK_STEP_MS
MARGIN_SHARE = 0.025
BEFORE_SLACK_STEPS = 4
AFTER_SLACK_STEPS = 7
ACT_BEFORE_STEPS = 2
ACT_AFTER_STEPS = 4
APPLY_WITHIN_MS = 2000
WITHOUT, WITH = 'without', 'with'
BEHAVIOUR_KINDS = frozenset({'cast_applies_aura', 'duration_refresh', 'duration_ratio', 'duration'})
SCHOOL_LOCKOUT = 'school_lockout'
LOCKOUT_METRIC = 'school_prohibited'
SILENCE_PREVENTION = 1
CHANNEL_INTERRUPT = 0x8
CHANNEL_SETTLE_MS = 300
TRIGGER_KINDS = frozenset({'duration_delta'})


@dataclass(frozen=True)
class ExpiryArm:
    name: str
    expected_ms: float
    act_label: str
    applied_label: str | None
    before_label: str
    after_label: str
    before_margin_ms: int
    after_margin_ms: int
    held_ms: int
    requires: tuple[tuple[str, float], ...] = ()


def shift_of(expected_ms: float) -> float:
    return max(SHIFT_SHARE * expected_ms, SHIFT_FLOOR_MS)


def slack_steps(tail: list[dict]) -> int:
    return len(tail) + sum(step['action'] == 'wait' for step in tail)


def margins_of(expected_ms: float, tail: list[dict]) -> tuple[int, int]:
    shift, slack = shift_of(expected_ms), slack_steps(tail)
    before = max(math.ceil(MARGIN_SHARE * expected_ms), (slack + BEFORE_SLACK_STEPS) * CLOCK_STEP_MS + 1)
    after = min(before, math.ceil(shift) - (slack + AFTER_SLACK_STEPS) * CLOCK_STEP_MS - 1)
    if before > shift - CLOCK_STEP_MS or after < CLOCK_STEP_MS:
        raise NotModelled(f'an end stated at {expected_ms:g} ms with {len(tail)} steps after the act leaves no '
                          f'reading pair that a server {shift:g} ms off would fail at {CLOCK_STEP_MS} ms per step')
    return before, after


def act_margins_of(expected_ms: float) -> tuple[int, int]:
    shift = shift_of(expected_ms)
    before = math.floor(shift) - CLOCK_STEP_MS - 1
    after = CLOCK_STEP_MS + 1
    if before <= ACT_BEFORE_STEPS * CLOCK_STEP_MS or after >= shift - ACT_AFTER_STEPS * CLOCK_STEP_MS:
        raise NotModelled(f'an end stated at {expected_ms:g} ms leaves no reading pair timed from the act itself '
                          f'that a server {shift:g} ms off would fail at {CLOCK_STEP_MS} ms per step')
    return before, after


def act_anchored_arm(prefix: str, name: str, expected_ms: float,
                     requires: tuple[tuple[str, float], ...] = ()) -> ExpiryArm:
    return ExpiryArm(name, float(expected_ms), f'{prefix} {name} expiry act', None, f'{prefix} {name} before_expiry',
                     f'{prefix} {name} after_expiry', *act_margins_of(expected_ms), 0, requires)


def lands_within_its_cast_step(records: Records, spell: int, aura: int) -> bool:
    return aura == spell and facts_of(records, spell).cast_time_ms == 0 and records.field('Spell', spell, 'Speed') == 0


def expiry_arm(prefix: str, name: str, expected_ms: float, tail: list[dict] = (), applied: bool = True,
               requires: tuple[tuple[str, float], ...] = ()) -> ExpiryArm:
    return ExpiryArm(name, float(expected_ms), f'{prefix} {name} expiry act',
                     f'{prefix} {name} expiry applied' if applied else None, f'{prefix} {name} before_expiry',
                     f'{prefix} {name} after_expiry', *margins_of(expected_ms, list(tail)), held_ms(list(tail)),
                     requires)


def acted(step: dict, arm: ExpiryArm) -> dict:
    return {**step, 'label': arm.act_label}


def reading_fields(spell: int, caster: str | None) -> dict:
    return {'spell': spell, **({'caster': caster} if caster else {})}


def applied_step(arm: ExpiryArm, actor: str, spell: int, caster: str | None = None) -> dict:
    return {'action': 'assert', 'label': arm.applied_label, 'actor': actor, 'metric': PRESENCE_METRIC,
            **reading_fields(spell, caster), 'min': 1, 'within_ms': APPLY_WITHIN_MS}


def held_ms(steps: list[dict]) -> int:
    return sum(int(step.get('ms', 0)) for step in steps if step['action'] == 'wait')


def pair_steps(arm: ExpiryArm, actor: str, spell: int, caster: str | None = None, metric: str = PRESENCE_METRIC,
               fields: dict | None = None) -> list[dict]:
    lead = round(arm.expected_ms) - arm.before_margin_ms - arm.held_ms
    if lead < 0:
        raise NotModelled(f'{arm.before_label}: the steps after the act already wait {arm.held_ms} ms, past the '
                          f'reading {arm.before_margin_ms} ms before the stated end of {arm.expected_ms:g} ms')
    fields = reading_fields(spell, caster) if fields is None else fields
    waits = [{'action': 'wait', 'label': f'{arm.before_label} wait', 'ms': lead}] if lead else []
    return waits + [measurement(arm.before_label, actor, metric, **fields),
                    {'action': 'wait', 'label': f'{arm.after_label} wait',
                     'ms': arm.before_margin_ms + arm.after_margin_ms},
                    measurement(arm.after_label, actor, metric, **fields)]


def arm_model(arm: ExpiryArm) -> dict:
    return {'name': arm.name, 'expected_ms': arm.expected_ms, 'act_label': arm.act_label,
            'applied_label': arm.applied_label, 'before_label': arm.before_label, 'after_label': arm.after_label,
            'before_margin_ms': arm.before_margin_ms, 'after_margin_ms': arm.after_margin_ms,
            'shift_ms': shift_of(arm.expected_ms),
            'requires': [[label, value] for label, value in arm.requires]}


def expiry_expectation(label: str, spell: int, rank_id: int, displayed: str, rule: str,
                       arms: list[ExpiryArm], observe_metric: str = PRESENCE_METRIC) -> Expectation:
    model = {'kind': EXPIRY_KIND, 'observe_metric': observe_metric, 'arms': [arm_model(arm) for arm in arms]}
    return Expectation(label, BEHAVIOUR_EXPIRY, spell, rank_id, None, displayed, rule, model)


def expiry_label(spell: int) -> str:
    return f'{spell} {BEHAVIOUR_EXPIRY}'


def step_elapsed(step: dict) -> float:
    return float(step.get('elapsed_ms', 0))


def position(steps: list[dict], label: str | None) -> int | None:
    return next((index for index, step in enumerate(steps) if label and step.get('label') == label), None)


def lower_ms(steps: list[dict], start: int, end: int) -> float:
    return sum(step_elapsed(step) for step in steps[start + 1:end])


def upper_ms(steps: list[dict], start: int, end: int, max_step: float) -> float:
    return sum(step_elapsed(step) + max_step for step in steps[start + 1:end + 1])


@dataclass(frozen=True)
class ArmReading:
    status: str
    explanation: str
    detail: dict


def arm_reading(values: dict, steps: list[dict], max_step: float | None, run_key: str, arm: dict,
                metric: str = PRESENCE_METRIC) -> ArmReading:
    name, expected = arm['name'], arm['expected_ms']
    before, after = values.get(arm['before_label']), values.get(arm['after_label'])
    if before is None or after is None:
        missing = arm['before_label'] if before is None else arm['after_label']
        return ArmReading('alert', f'{name}: no measurement {missing!r} in {run_key}', {})
    for label, value in arm['requires']:
        if values.get(label) != value:
            return ArmReading('unmeasured', f'{name}: {label} read {values.get(label)!r}, not the {value:g} the '
                                            f'pair needs', {})
    if max_step is None:
        return ArmReading('unmeasured', f'{name}: no step timing in {run_key} bounds the readings', {})
    act = position(steps, arm['act_label'])
    applied = position(steps, arm['applied_label']) if arm['applied_label'] else act
    before_at, after_at = position(steps, arm['before_label']), position(steps, arm['after_label'])
    if None in (act, applied, before_at, after_at):
        return ArmReading('unmeasured', f'{name}: the recorded steps of {run_key} lack the act or a reading', {})
    if applied != act and step_elapsed(steps[applied]) > 0:
        slack = max_step
    else:
        slack = step_elapsed(steps[act]) + upper_ms(steps, act, applied, max_step)
    before_low, before_high = lower_ms(steps, applied, before_at), upper_ms(steps, applied, before_at, max_step) + slack
    after_low, after_high = lower_ms(steps, applied, after_at), upper_ms(steps, applied, after_at, max_step) + slack
    shift = arm['shift_ms']
    detail = {'name': name, 'expected_ms': expected, 'before': before, 'after': after,
              'before_ms': [before_low, before_high], 'after_ms': [after_low, after_high], 'shift_ms': shift}
    placed = (f'{name}: {metric} read {before:g} between {before_low:g} and {before_high:g} ms after the '
              f'effect began and {after:g} between {after_low:g} and {after_high:g} ms after it')
    if before_high >= expected or after_low < expected + max_step:
        return ArmReading('unmeasured', f'{placed}; the readings do not bracket the stated end of {expected:g} ms '
                                        f'with one {max_step:g} ms step to spare after it', detail)
    if before_low < expected - shift + max_step or after_high >= expected + shift:
        return ArmReading('unmeasured', f'{placed}; a server {shift:g} ms off the stated {expected:g} ms could still '
                                        f'read the same', detail)
    held = before > 0 and after == 0
    detail['end_ms'] = [before_low, after_high] if held else None
    if held:
        return ArmReading('ok', f'{placed}; the effect ends after {before_low:g} and by {after_high:g} ms, stated '
                                f'{expected:g} ms, so an end at or before {before_low:g} ms or after {after_high:g} '
                                f'ms is excluded', detail)
    return ArmReading('alert', f'{placed}; stated {expected:g} ms, so present before and absent after', detail)


def expiry_readings(values: dict, steps: list[dict], max_step: float | None, run_key: str,
                    model: dict) -> list[ArmReading]:
    return [arm_reading(values, steps, max_step, run_key, arm, model.get('observe_metric', PRESENCE_METRIC))
            for arm in model['arms']]


def combined_status(readings: list[ArmReading]) -> str:
    statuses = [reading.status for reading in readings]
    if 'alert' in statuses:
        return 'alert'
    return 'unmeasured' if 'unmeasured' in statuses else 'ok'


def expiry_scenario_shell(class_file: dict, name: str, contract: str, steps: list[dict]) -> dict:
    return {'schema': 1, 'name': name, 'contract': contract, 'players': [player_fixture(class_file)],
            'steps': steps}


def finished(scenario: dict) -> dict:
    return timed(scenario, held_ms(scenario['steps']) + len(scenario['steps']) * CLOCK_STEP_MS,
                 MAX_ACCELERATED_SCENARIO_MS)


def cast_applies_aura_expiry(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    spec = cast_applies_aura_spec(entry)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    behaviour_entry(records, spec.spell, spec.name, 'cast_applies_aura', spec.quote, spec.expected_ms)
    prefix = f'{spec.spell} {spec.applied_aura}'
    absent = f'{prefix} before cast'
    actor = spec.target
    learned, cast = cast_applies_aura_steps(records, spec)
    learn = [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    if spec.control_ms is None:
        arms = [single_cast_arm(records, spec, prefix, ((absent, 0.0),))]
        steps = (base_steps(class_file) + ally_group_steps({spec.cast_target}) + learn + learned
                 + [measurement(absent, actor, PRESENCE_METRIC, spell=spec.applied_aura)]
                 + cast_arm(cast, arms[0], actor, spec.applied_aura))
        contract = (f'{spec.applied_aura} is absent before {spec.spell} is cast, present {arms[0].before_margin_ms} '
                    f'ms before its stated {spec.expected_ms:g} ms end and absent {arms[0].after_margin_ms} ms after '
                    f'it, timed from the cast.')
    else:
        extra = extra_cast_steps(records, spec.extra_cast) if spec.extra_cast else []
        arms = [expiry_arm(prefix, WITHOUT, spec.control_ms, requires=((absent, 0.0),)),
                expiry_arm(prefix, WITH, spec.expected_ms, extra, requires=((absent, 0.0),))]
        cleared = [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 0,
                    **({'target': actor} if actor != CASTER else {})} for spell in spec.control_clear]
        if spec.extra_cast:
            first, second = learn + learned + extra_cast_setup(records, spec.extra_cast, spec.spell), []
        else:
            first, second = learned, learn
        steps = (base_steps(class_file) + ally_group_steps({spec.cast_target}) + first
                 + [measurement(absent, actor, PRESENCE_METRIC, spell=spec.applied_aura)]
                 + cast_arm(cast, arms[0], actor, spec.applied_aura) + cleared
                 + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell}] + second
                 + cast_arm(cast, arms[1], actor, spec.applied_aura, extra))
        changed = (f'with {spec.spell} cast at the {spec.extra_cast.target} {spec.extra_cast.after_ms} ms after it'
                   if spec.extra_cast else f'with {spec.spell} learned')
        contract = (f'{spec.applied_aura} is absent before {spec.cast_spell} is first cast; cast without '
                    f'{spec.spell}, it is present {arms[0].before_margin_ms} ms before {spec.control_ms:g} ms and '
                    f'absent {arms[0].after_margin_ms} ms after it; cast again {changed}, it is '
                    f'present {arms[1].before_margin_ms} ms before the stated {spec.expected_ms:g} ms end and absent '
                    f'{arms[1].after_margin_ms} ms after it, each timed from its cast.')
    scenario = expiry_scenario_shell(
        class_file, f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour expiry', contract, steps)
    scenario['players'] = [cast_applies_aura_player(class_file, spec)] + ally_players(class_file, {spec.cast_target})
    if TARGET in (spec.target, spec.cast_target, spec.extra_cast and spec.extra_cast.target):
        scenario['creatures'] = [creature_fixture(class_file)]
    label = expiry_label(spec.spell) + (f' {spec.label_suffix}' if spec.label_suffix else '')
    return finished(scenario), [expiry_expectation(label, spec.spell, spec.applied_aura, str(spec.expected_ms),
                                                   prose_rule(spec.quote, spec.spell), arms)]


def single_cast_arm(records: Records, spec: CastAppliesAuraSpec, prefix: str,
                    requires: tuple[tuple[str, float], ...]) -> ExpiryArm:
    try:
        return expiry_arm(prefix, 'cast', spec.expected_ms, requires=requires)
    except NotModelled:
        if not lands_within_its_cast_step(records, spec.cast_spell or spec.spell, spec.applied_aura):
            raise
        return act_anchored_arm(prefix, 'cast', spec.expected_ms, requires)


def cast_arm(cast: list[dict], arm: ExpiryArm, actor: str, aura: int, tail: list[dict] = ()) -> list[dict]:
    applied = [applied_step(arm, actor, aura)] if arm.applied_label else []
    return cast[:-1] + [acted(cast[-1], arm)] + applied + list(tail) + pair_steps(arm, actor, aura)


def duration_refresh_expiry(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    spec = duration_refresh_spec(entry)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    full_ms = records.duration_ms(spec.target_aura)
    behaviour_entry(records, spec.spell, spec.name, 'duration_refresh', spec.quote, full_ms)
    class_file = armed_for(class_file, records, spec.breaker_spell)
    facts_apply, facts_breaker = facts_of(records, spec.apply_spell), facts_of(records, spec.breaker_spell)
    prefix = f'{spec.spell} {spec.target_aura}'

    def apply(arm: ExpiryArm | None) -> list[dict]:
        cast = {'action': 'cast', 'actor': CASTER, 'spell': spec.apply_spell, 'target': TARGET}
        return [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.gating_aura, 'stacks': 1},
                {'action': 'set_power', 'actor': CASTER, 'power': facts_apply.power_type,
                 'value': facts_apply.mana_cost},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.apply_spell},
                acted(cast, arm) if arm else cast]

    def breaker(arm: ExpiryArm | None) -> list[dict]:
        cast = {'action': 'cast', 'actor': CASTER, 'spell': spec.breaker_spell, 'target': TARGET}
        return [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.gating_aura, 'stacks': spec.gating_stacks},
                {'action': 'set_power', 'actor': CASTER, 'power': facts_breaker.power_type,
                 'value': facts_breaker.mana_cost},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.breaker_spell},
                acted(cast, arm) if arm else cast]

    decay = {'action': 'wait', 'label': f'{prefix} decay', 'ms': spec.decay_ms}
    without_tail = [decay] + breaker(None)
    without = expiry_arm(prefix, WITHOUT, full_ms, without_tail)
    with_arm = expiry_arm(prefix, WITH, full_ms, applied=False)
    steps = base_steps(class_file) + [
        {'action': 'learn', 'actor': CASTER, 'spell': spec.apply_spell},
        {'action': 'learn', 'actor': CASTER, 'spell': spec.breaker_spell}]
    steps += apply(without) + [applied_step(without, TARGET, spec.target_aura, CASTER)] + without_tail
    steps += pair_steps(without, TARGET, spec.target_aura, CASTER)
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    steps += apply(None) + [dict(decay, label=f'{prefix} decay with')] + breaker(with_arm)
    steps += pair_steps(with_arm, TARGET, spec.target_aura, CASTER)
    scenario = expiry_scenario_shell(
        class_file, f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour expiry',
        f'Without {spec.spell}, {spec.target_aura} cast {spec.decay_ms} ms before {spec.breaker_spell} still ends '
        f'{full_ms:g} ms after its own cast; with it, it ends {full_ms:g} ms after {spec.breaker_spell}.', steps)
    scenario['creatures'] = [creature_fixture(class_file)]
    return finished(scenario), [expiry_expectation(expiry_label(spec.spell), spec.spell, spec.target_aura,
                                                   str(full_ms), prose_rule(spec.quote, spec.spell),
                                                   [without, with_arm])]


def striker_fixture(class_file: dict, striker_entry: int) -> dict:
    return {'id': STRIKER, 'owner': CASTER, 'entry': striker_entry, 'level': class_file['level'],
            'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 1, 'spell_hit_bonus': 100}


def duration_ratio_expiry(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    spec = mechanic_duration_spec(entry)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    behaviour_entry(records, spec.spell, spec.name, 'ratio', spec.quote, spec.expected_ratio)
    full_ms = records.duration_ms(spec.vehicle_spell)
    prefix = f'{spec.spell} {spec.vehicle_spell}'
    without = expiry_arm(prefix, WITHOUT, full_ms)
    with_arm = expiry_arm(prefix, WITH, round(spec.expected_ratio * full_ms))

    def phase(arm: ExpiryArm) -> list[dict]:
        cast = {'action': 'cast', 'actor': STRIKER, 'spell': spec.vehicle_spell, 'target': CASTER}
        return ([{'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0}, acted(cast, arm),
                 applied_step(arm, CASTER, spec.vehicle_spell)] + pair_steps(arm, CASTER, spec.vehicle_spell))

    steps = (base_steps(class_file) + phase(without) +
             [{'action': 'wait', 'label': f'{prefix} diminishing returns reset',
               'ms': MECHANIC_DR_RESET_MS + MECHANIC_GAP_MARGIN_MS},
              {'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + phase(with_arm))
    scenario = expiry_scenario_shell(
        class_file, f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour expiry',
        f'One {spec.vehicle_spell} cast by a striker ends {full_ms:g} ms after it lands before {spec.spell} is '
        f'learned and {with_arm.expected_ms:g} ms after it ({spec.expected_ratio:g} of it) once learned; the '
        f'arms are {MECHANIC_DR_RESET_MS + MECHANIC_GAP_MARGIN_MS} ms apart after the first effect ends, so '
        f'neither cast is diminished.', steps)
    scenario['creatures'] = [striker_fixture(class_file, spec.striker_entry)]
    return finished(scenario), [expiry_expectation(expiry_label(spec.spell), spec.spell, spec.vehicle_spell,
                                                   str(spec.expected_ratio), prose_rule(spec.quote, spec.spell),
                                                   [without, with_arm])]


def duration_delta_expiry(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    spec = duration_spec(entry)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    behaviour_entry(records, spec.spell, spec.name, 'duration', spec.quote, spec.expected_ms)
    swing_ms = swing_interval(class_file)
    if swing_ms <= CAST_SETTLE_MS:
        raise NotModelled(f'{spec.name} needs a swing interval above {CAST_SETTLE_MS} ms to isolate one forced '
                          f'crit, got {swing_ms} ms')
    full_ms = records.duration_ms(spec.target_aura)
    prefix = f'{spec.spell} {spec.target_aura}'
    fixture = dict(player_fixture(class_file)) | {'melee_crit_rating': FORCED_CRIT_RATING}

    def swing(name: str) -> list[dict]:
        return [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                {'action': 'wait', 'label': f'{prefix} {name} forced swing', 'ms': CAST_SETTLE_MS},
                {'action': 'stop_attack', 'actor': CASTER},
                measurement(f'{prefix} {name} forced_crit_count', CASTER, 'melee_damage_count', hand=MAIN_HAND,
                            critical=True)]

    without = expiry_arm(prefix, WITHOUT, full_ms, swing(WITHOUT),
                         requires=((f'{prefix} {WITHOUT} forced_crit_count', 1.0),))
    with_arm = expiry_arm(prefix, WITH, full_ms - spec.expected_ms, swing(WITH),
                          requires=((f'{prefix} {WITH} forced_crit_count', 2.0),))

    def phase(arm: ExpiryArm) -> list[dict]:
        cast = {'action': 'cast', 'actor': STRIKER, 'spell': spec.breaker_spell, 'target': CASTER}
        debt = {'action': 'assert', 'label': arm.applied_label, 'actor': CASTER, 'metric': 'aura_amount',
                'spell': spec.target_aura, 'effect': 0, 'min': 1, 'within_ms': APPLY_WITHIN_MS}
        return ([{'action': 'set_aura', 'actor': CASTER, 'spell': spec.debt_aura, 'stacks': 1}, acted(cast, arm),
                 debt] + swing(arm.name) + pair_steps(arm, CASTER, spec.target_aura))

    steps = base_steps(class_file) + phase(without) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    steps += phase(with_arm)
    scenario = expiry_scenario_shell(
        class_file, f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour expiry',
        f'A striker hit under {spec.debt_aura} sets {spec.target_aura} to its {full_ms:g} ms duration; one forced '
        f'melee crit follows (crit counts are cumulative: 1, then 2). Before {spec.spell} is learned it ends '
        f'{full_ms:g} ms after the hit, after it {full_ms - spec.expected_ms:g} ms.', steps)
    scenario['players'] = [fixture]
    scenario['creatures'] = [creature_fixture(class_file), striker_fixture(class_file, spec.striker_entry)]
    return finished(scenario), [expiry_expectation(expiry_label(spec.spell), spec.spell, spec.target_aura,
                                                   str(spec.expected_ms), prose_rule(spec.quote, spec.spell),
                                                   [without, with_arm])]


def trigger_duration_expiry(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    aura, trigger, observe = entry['aura'], entry['trigger'], entry['observe_spell']
    records = records_of(class_file)
    class_file = armed_for(armed_for(class_file, records, trigger['spell']), records, observe)
    full_ms = records.duration_ms(observe)
    target = trigger['target']
    prefix = f'{aura} {observe}'
    costs = [facts for facts in (facts_of(records, observe), facts_of(records, trigger['spell']))
             if facts.mana_cost > 0]
    if any(facts.mana_cost_percentage or facts.mana_cost_per_level for facts in costs) or \
            len({facts.power_type for facts in costs}) > 1:
        raise NotModelled(f'{observe} and {trigger["spell"]} need separate power steps; one of them would fall '
                          f'between the act and the readings')
    prepare = [{'action': 'set_power', 'actor': CASTER, 'power': costs[0].power_type,
                'value': sum(facts.mana_cost for facts in costs)}] if costs else []
    prepare += [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell} for spell in (observe, trigger['spell'])]

    def tail(name: str) -> list[dict]:
        return [{'action': 'wait', 'label': f'{prefix} {name} decay', 'ms': entry['decay_wait_ms']},
                {'action': 'cast', 'actor': CASTER, 'spell': trigger['spell'], 'target': target}]

    without = expiry_arm(prefix, WITHOUT, full_ms, tail(WITHOUT))
    with_arm = expiry_arm(prefix, WITH, full_ms + entry['expected_delta_ms'], tail(WITH))

    def phase(arm: ExpiryArm) -> list[dict]:
        cast = {'action': 'cast', 'actor': CASTER, 'spell': observe, 'target': target}
        return (prepare + [acted(cast, arm), applied_step(arm, target, observe, CASTER)] + tail(arm.name) +
                pair_steps(arm, target, observe, CASTER))

    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': trigger['spell']},
                                      {'action': 'learn', 'actor': CASTER, 'spell': observe}]
    steps += phase(without) + [{'action': 'learn', 'actor': CASTER, 'spell': aura}] + phase(with_arm)
    scenario = expiry_scenario_shell(
        class_file, f'Conformance trigger {class_file["name"]} {entry["name"]} {aura} expiry',
        f'{observe} is cast, {trigger["spell"]} follows {entry["decay_wait_ms"]} ms later; {observe} ends '
        f'{full_ms:g} ms after its cast before {aura} is learned and {with_arm.expected_ms:g} ms after it once '
        f'learned.', steps)
    scenario['creatures'] = [creature_fixture(class_file)]
    return finished(scenario), [expiry_expectation(expiry_label(aura), aura, observe, entry['trigger_text'],
                                                   f'{entry["trigger_text"]} ({aura})', [without, with_arm])]


@dataclass(frozen=True)
class SchoolLockoutSpec:
    spell: int
    name: str
    quote: str
    interrupt_spell: int
    cast_spell: int
    channel_spell: int
    label_suffix: str = ''


def school_lockout_spec(entry: dict) -> SchoolLockoutSpec:
    return SchoolLockoutSpec(entry['spell'], entry['name'], entry['quote'], entry['interrupt_spell'],
                             entry['cast_spell'], entry['channel_spell'], entry.get('label_suffix', ''))


def interruptible_channel_school(records: Records, spell: int) -> int:
    prevention = records.field('Spell', spell, 'PreventionType')
    flags = records.field('Spell', spell, 'ChannelInterruptFlags')
    if prevention != SILENCE_PREVENTION or not flags & CHANNEL_INTERRUPT:
        raise ValueError(f'{spell} is not a channel an interrupt stops (PreventionType {prevention}, '
                         f'ChannelInterruptFlags {flags})')
    return int(records.field('Spell', spell, 'SchoolMask'))


def school_lockout_scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    spec = school_lockout_spec(entry)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    expected_ms = records.duration_ms(spec.interrupt_spell)
    behaviour_entry(records, spec.spell, spec.name, SCHOOL_LOCKOUT, spec.quote, expected_ms)
    school = interruptible_channel_school(records, spec.channel_spell)
    facts = facts_of(records, spec.cast_spell)
    if facts.cast_time_ms:
        raise NotModelled(f'{spec.cast_spell} has a cast time; the lockout would not begin within its cast step')
    prefix = f'{spec.spell} {spec.interrupt_spell}'
    arm = act_anchored_arm(prefix, 'cast', expected_ms, ((f'{prefix} lockout before cast', 0.0),
                                                         (f'{prefix} channel before cast', 1.0)))
    fields = {'school_mask': school}
    cast = {'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': TARGET}
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in dict.fromkeys(
                 (spec.spell, spec.cast_spell))]
             + [{'action': 'cast', 'actor': TARGET, 'spell': spec.channel_spell},
                {'action': 'wait', 'label': f'{prefix} channel settle', 'ms': CHANNEL_SETTLE_MS},
                measurement(f'{prefix} channel before cast', TARGET, 'casting'),
                measurement(f'{prefix} lockout before cast', TARGET, LOCKOUT_METRIC, **fields)]
             + cast_gate_power_step(facts) + required_aura_steps(facts) + [acted(cast, arm)]
             + pair_steps(arm, TARGET, spec.interrupt_spell, metric=LOCKOUT_METRIC, fields=fields))
    contract = (f'The {TARGET} channels {spec.channel_spell} (school mask {school}); {spec.cast_spell} cast at it '
                f'interrupts the channel through {spec.interrupt_spell}, whose duration locks that school: locked '
                f'{arm.before_margin_ms} ms before the stated {expected_ms:g} ms end and free {arm.after_margin_ms} '
                f'ms after it, timed from the cast; not locked while the channel runs before the cast.')
    scenario = expiry_scenario_shell(
        class_file, f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour school lockout', contract,
        steps)
    scenario['creatures'] = [creature_fixture(class_file)]
    label = expiry_label(spec.spell) + (f' {spec.label_suffix}' if spec.label_suffix else '')
    return finished(scenario), [expiry_expectation(label, spec.spell, spec.interrupt_spell, str(expected_ms),
                                                   prose_rule(spec.quote, spec.spell), [arm], LOCKOUT_METRIC)]


BEHAVIOUR_EXPIRIES = {'cast_applies_aura': cast_applies_aura_expiry, 'duration_refresh': duration_refresh_expiry,
                      'duration_ratio': duration_ratio_expiry, 'duration': duration_delta_expiry}
TRIGGER_EXPIRIES = {'duration_delta': trigger_duration_expiry}


def built(build, class_file: dict, label: str, spell: int, entry: dict) -> tuple[dict | None, list[Expectation]]:
    try:
        return build(class_file, entry)
    except NotModelled as error:
        return None, [Expectation(label, 'unmodelled', spell, spell, None, '', UNMODELLED + str(error))]


def behaviour_expiry(class_file: dict, entry: dict) -> tuple[dict | None, list[Expectation]] | None:
    build = BEHAVIOUR_EXPIRIES.get(entry.get('kind'))
    return built(build, class_file, expiry_label(entry['spell']), entry['spell'], entry) if build else None


def trigger_expiry(class_file: dict, entry: dict) -> tuple[dict | None, list[Expectation]] | None:
    build = TRIGGER_EXPIRIES.get(entry.get('kind'))
    if not build or entry.get('status'):
        return None
    return built(build, class_file, expiry_label(entry['aura']), entry['aura'], entry)
