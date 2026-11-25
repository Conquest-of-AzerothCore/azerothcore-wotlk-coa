from dataclasses import dataclass, replace
import math

NAME = 'ally_arm'
ORDER = 24
METRIC_EVIDENCE = {'combat_reach': 'state', 'active_power': 'state'}
PRECONDITION_ONLY_METRICS = frozenset(METRIC_EVIDENCE)
ALLY_IDS = ('ally', 'ally2', 'ally3', 'ally4', 'ally5', 'ally6', 'ally7', 'ally8', 'ally9')
SCHEMA_ONE_PLAYERS = 8
RAID_SCHEMA = 2
RAID_SUBGROUP_TWO = ALLY_IDS[4:]
ALLY_CAST_SETTLE_MS = 2000
ALLY_CAST_PROOF_METRIC = 'spell_go_count'
CASTER_SCOPED_METRICS = {'spell_heal_count', 'spell_heal_total', 'spell_effective_heal_total',
                         'spell_energize_count', 'spell_energize_total', 'spell_damage_count', 'spell_damage_total',
                         'spell_log_count', 'spell_absorb_total', 'spell_resist_total', 'spell_go_count',
                         'spell_cast_count', 'spell_proc_count'}
CASTER_ENTRY_METRICS = {'spell_heal_count', 'spell_heal_total', 'spell_effective_heal_total'}
CONTROL_LABEL = 'timed no-cast control'
EXPIRE_LABEL = 'let the first effect fully expire'
KEYS = {'allies', 'ally_health', 'ally_casts', 'control_wait', 'arms', 'ratios', 'reach_source', 'ally_attacks',
        'ally_strikes', 'ally_class', 'ally_power'}
MAX_POWERS = 7
ALLY_ATTACK_KEYS = {'spell', 'power', 'source'}
ALLY_ATTACK_SETTLE_MS = 2000
COA_CLASSES = range(12, 33)
ARM_KEYS = {'actors', 'metric', 'fields', 'before_expected', 'expected', 'tolerance', 'source', 'reach_source',
            'precondition'}
OPTIONAL_ARM_KEYS = {'fields', 'reach_source', 'precondition'}
JUDGED_ARM_KEYS = ('before_expected', 'expected', 'tolerance')
RATIO_ONLY_ARM_KEYS = ARM_KEYS - set(JUDGED_ARM_KEYS) - {'precondition'} | {'count_metric'}
ALLY_CAST_KEYS = {'spell', 'spell_go_per_cast', 'source'}
RATIO_KEYS = {'numerator', 'denominator', 'expected', 'tolerance', 'source'}
FLOOR_COUNT_KEY = 'floor_count'
DISCRIMINATED_DEVIATION = 0.10


@dataclass(frozen=True)
class Arm:
    actors: tuple[str, ...]
    metric: str
    fields: dict
    before_expected: float
    expected: float
    tolerance: float
    source: str
    reach_source: str = ''
    count_metric: str | None = None
    precondition: bool = False

    @property
    def ratio_only(self) -> bool:
        return self.count_metric is not None


@dataclass(frozen=True)
class Ratio:
    numerator: int
    denominator: int | tuple[int, ...]
    expected: float
    tolerance: float
    source: str
    floor_count: int | None = None


@dataclass(frozen=True)
class AllyArm:
    allies: int
    ally_health: tuple[int, int] | None
    ally_casts: tuple[int, ...]
    control_wait: bool
    arms: tuple[Arm, ...]
    go_per_cast: tuple[tuple[int, int, str], ...] = ()
    ratios: tuple[Ratio, ...] = ()
    reach_source: str = ''
    ally_attacks: tuple[tuple[int, int, str], ...] = ()
    ally_strikes: bool = False
    ally_strike_health: int | None = None
    ally_class: int | None = None
    ally_power: tuple[tuple[int, int], ...] = ()

    @property
    def ally_ids(self) -> tuple[str, ...]:
        return ALLY_IDS[:self.allies]

    def spell_go_per_cast(self, spell: int) -> int:
        return next((count for stated, count, _ in self.go_per_cast if stated == spell), 1)


def number(value) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def stated_text(value) -> bool:
    return isinstance(value, str) and bool(value.strip())


def parse_ratio_only_arm(raw: dict) -> Arm:
    if 'precondition' in raw:
        raise ValueError(f'an ally_arm precondition arm states before_expected, expected and tolerance; it is never '
                         f'ratio-only, not {raw!r}')
    if not set(raw) <= RATIO_ONLY_ARM_KEYS or not isinstance(raw.get('actors'), list) or not raw['actors'] \
            or not all(isinstance(actor, str) and actor for actor in raw['actors']) \
            or len(set(raw['actors'])) != len(raw['actors']) \
            or not all(isinstance(raw.get(key), str) and raw[key] for key in ('metric', 'count_metric')) \
            or raw['metric'] == raw['count_metric'] or not isinstance(raw.get('fields', {}), dict) \
            or not stated_text(raw.get('source')) or ('reach_source' in raw and not stated_text(raw['reach_source'])):
        raise ValueError(f'a ratio-only ally_arm arm is {{actors: [unit, ...], metric, count_metric: the count of the '
                         f'same events, fields?, source: text, reach_source?: text}}, judged through a ratio only, not '
                         f'{raw!r}')
    return Arm(tuple(raw['actors']), raw['metric'], dict(raw.get('fields', {})), 0.0, 0.0, 0.0, raw['source'],
               raw.get('reach_source', ''), raw['count_metric'])


def parse_arm(raw) -> Arm:
    if isinstance(raw, dict) and not any(key in raw for key in JUDGED_ARM_KEYS) and 'count_metric' in raw:
        return parse_ratio_only_arm(raw)
    if not isinstance(raw, dict) or not ARM_KEYS - OPTIONAL_ARM_KEYS <= set(raw) <= ARM_KEYS \
            or not isinstance(raw['actors'], list) or not raw['actors'] \
            or not all(isinstance(actor, str) and actor for actor in raw['actors']) \
            or len(set(raw['actors'])) != len(raw['actors']) \
            or not isinstance(raw['metric'], str) or not raw['metric'] \
            or not isinstance(raw.get('fields', {}), dict) \
            or not all(number(raw[key]) for key in ('before_expected', 'expected', 'tolerance')) \
            or raw['tolerance'] < 0 or not stated_text(raw['source']) \
            or ('reach_source' in raw and not stated_text(raw['reach_source'])) \
            or raw.get('precondition', True) is not True:
        raise ValueError(f'an ally_arm arm is {{actors: [unit, ...], metric, fields?, before_expected, expected, '
                         f'tolerance >= 0, source: text, reach_source?: text, precondition?: true}}, finite numbers, '
                         f'every expectation stated with its source, not {raw!r}')
    return Arm(tuple(raw['actors']), raw['metric'], dict(raw.get('fields', {})), float(raw['before_expected']),
               float(raw['expected']), float(raw['tolerance']), raw['source'], raw.get('reach_source', ''),
               precondition='precondition' in raw)


def parse_ally_cast(raw) -> tuple[int, int, str]:
    if type(raw) is int and raw > 0:
        return raw, 1, ''
    if not isinstance(raw, dict) or set(raw) != ALLY_CAST_KEYS or type(raw['spell']) is not int or raw['spell'] <= 0 \
            or type(raw['spell_go_per_cast']) is not int or raw['spell_go_per_cast'] < 2 \
            or not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError(f'an ally_arm ally cast is a spell id (one SPELL_GO per cast) or {{spell, spell_go_per_cast: '
                         f'integer >= 2, source: the code or data line that casts the extra SPELL_GO}}, not {raw!r}')
    return raw['spell'], raw['spell_go_per_cast'], raw['source']


def parse_ally_attack(raw) -> tuple[int, int, str]:
    if not isinstance(raw, dict) or set(raw) != ALLY_ATTACK_KEYS or type(raw['spell']) is not int \
            or raw['spell'] <= 0 or type(raw['power']) is not int or raw['power'] < 0 or not stated_text(raw['source']):
        raise ValueError(f'an ally_arm ally attack is {{spell, power: the ally\'s power set before the cast, an '
                         f'integer >= 0, source: text}}, not {raw!r}')
    return raw['spell'], raw['power'], raw['source']


def parse_ratio(raw, arms: int) -> Ratio:
    floor_count = raw.get(FLOOR_COUNT_KEY) if isinstance(raw, dict) else None
    if isinstance(raw, dict) and FLOOR_COUNT_KEY in raw and (
            type(floor_count) is not int or not 0 <= floor_count < arms
            or not number(raw.get('expected')) or not number(raw.get('tolerance'))
            or raw['tolerance'] >= DISCRIMINATED_DEVIATION * raw['expected']):
        raise ValueError(f'an ally_arm ratio floor_count is the index of an arm below {arms} that counts the '
                         f'truncated events, with a tolerance below {DISCRIMINATED_DEVIATION:.0%} of expected, not '
                         f'{raw!r}')
    listed = None
    if isinstance(raw, dict) and isinstance(raw.get('denominator'), list):
        listed = raw['denominator']
        if len(listed) < 2 or not all(type(index) is int and 0 <= index < arms for index in listed) \
                or len(set(listed)) != len(listed) or raw.get('numerator') in listed:
            raise ValueError(f'an ally_arm ratio denominator list is two or more distinct arm indices below {arms}, '
                             f'without the numerator, not {listed!r}')
        raw = {**raw, 'denominator': next(index for index in range(arms) if index != raw.get('numerator'))}
    if isinstance(raw, dict):
        raw = {key: value for key, value in raw.items() if key != FLOOR_COUNT_KEY}
    if not isinstance(raw, dict) or set(raw) != RATIO_KEYS \
            or not all(type(raw[key]) is int and 0 <= raw[key] < arms for key in ('numerator', 'denominator')) \
            or raw['numerator'] == raw['denominator'] \
            or not all(number(raw[key]) for key in ('expected', 'tolerance')) \
            or raw['expected'] <= 0 or raw['tolerance'] < 0 \
            or not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError(f'an ally_arm ratio is {{numerator, denominator: two distinct arm indices below {arms}, '
                         f'expected > 0, tolerance >= 0, source: text}}, finite numbers, not {raw!r}')
    return Ratio(raw['numerator'], raw['denominator'] if listed is None else tuple(listed), float(raw['expected']),
                 float(raw['tolerance']), raw['source'], floor_count)


def denominator_arms(denominator) -> tuple:
    if isinstance(denominator, (list, tuple)):
        return tuple(denominator)
    return (denominator,)


def parse(raw) -> AllyArm:
    if not isinstance(raw, dict) or not raw or not set(raw) <= KEYS:
        raise ValueError(f'ally_arm is a non-empty object of {sorted(KEYS)}, not {raw!r}')
    allies = raw.get('allies', 1)
    health = raw.get('ally_health')
    casts = raw.get('ally_casts', [])
    if type(allies) is not int or not 0 <= allies <= len(ALLY_IDS):
        raise ValueError(f'ally_arm allies is an integer from 0 to {len(ALLY_IDS)}, not {allies!r}')
    attacks = raw.get('ally_attacks', [])
    if not isinstance(attacks, list) or ('ally_attacks' in raw and not attacks):
        raise ValueError(f'ally_arm ally_attacks is a non-empty list, not {attacks!r}')
    strikes = raw.get('ally_strikes', True)
    strike_health = None
    if isinstance(strikes, dict):
        strike_health = strikes.get('health')
        if set(strikes) != {'health'} or type(strike_health) is not int or strike_health <= 0:
            raise ValueError(f'ally_arm ally_strikes is true or {{health: a positive integer}}, not {strikes!r}')
    elif strikes is not True:
        raise ValueError(f'ally_arm ally_strikes is true or {{health: N}}, not {strikes!r}')
    if allies == 0 and (attacks or 'ally_strikes' in raw):
        raise ValueError('ally_arm allies 0 has no ally to attack or to strike')
    if (attacks or 'ally_strikes' in raw) and 'control_wait' in raw:
        raise ValueError('ally_arm ally_attacks and ally_strikes add waits after the trigger, which control_wait '
                         'does not time')
    if allies == 0 and (health is not None or casts or not raw.get('arms')):
        raise ValueError('ally_arm allies 0 reads caster-only arms: arms, no ally_health and no ally_casts')
    if health is not None and (not isinstance(health, list) or len(health) != 2
                               or not all(type(value) is int for value in health) or not 1 <= health[0] <= health[1]):
        raise ValueError(f'ally_arm ally_health is [value, maximum], integers with 1 <= value <= maximum, '
                         f'not {health!r}')
    if not isinstance(casts, list):
        raise ValueError(f'ally_arm ally_casts is a list of spell ids or stated casts, not {casts!r}')
    stated = [parse_ally_cast(cast) for cast in casts]
    for spell, count, source in stated:
        if any(other == spell and (other_count, other_source) != (count, source)
               for other, other_count, other_source in stated):
            raise ValueError(f'ally_arm ally_casts states {spell} with different SPELL_GO counts or sources')
    if 'reach_source' in raw and not stated_text(raw['reach_source']):
        raise ValueError(f'ally_arm reach_source is text citing the code or data line that reaches raid subgroup 2, '
                         f'not {raw["reach_source"]!r}')
    ally_class = raw.get('ally_class')
    if 'ally_class' in raw and (type(ally_class) is not int or ally_class not in COA_CLASSES or allies == 0):
        raise ValueError(f'ally_arm ally_class is a CoA class id {COA_CLASSES.start} to {COA_CLASSES.stop - 1} and '
                         f'needs at least one ally, not {ally_class!r}')
    power = raw.get('ally_power', [])
    if not isinstance(power, list) or ('ally_power' in raw and (not power or allies == 0)) \
            or not all(isinstance(pair, list) and len(pair) == 2 and all(type(value) is int for value in pair)
                       and 0 <= pair[0] < MAX_POWERS and pair[1] >= 0 for pair in power) \
            or len({pair[0] for pair in power}) != len(power):
        raise ValueError(f'ally_arm ally_power is a non-empty list of [power, value], a power index 0 to '
                         f'{MAX_POWERS - 1} once each and a value of at least 0, and needs at least one ally, '
                         f'not {power!r}')
    if raw.get('control_wait', True) is not True:
        raise ValueError(f'ally_arm control_wait is true, not {raw["control_wait"]!r}')
    arms = raw.get('arms', [])
    if not isinstance(arms, list):
        raise ValueError(f'ally_arm arms is a list, not {arms!r}')
    ratios = raw.get('ratios', [])
    if not isinstance(ratios, list) or ('ratios' in raw and not ratios):
        raise ValueError(f'ally_arm ratios is a non-empty list, not {ratios!r}')
    parsed_arms = tuple(parse_arm(arm) for arm in arms)
    parsed_ratios = tuple(parse_ratio(ratio, len(arms)) for ratio in ratios)
    named = {index for ratio in parsed_ratios
             for index in (ratio.numerator, *denominator_arms(ratio.denominator), ratio.floor_count)}
    if any(index is not None and parsed_arms[index].precondition for index in named):
        raise ValueError('an ally_arm ratio names behaviour arms only, never a precondition arm')
    unnamed = [index for index, arm in enumerate(parsed_arms) if arm.ratio_only and index not in named]
    if unnamed:
        raise ValueError(f'ally_arm ratio-only arms {unnamed} are named by no ratio, so nothing would judge them')
    floors = [ratio.floor_count for ratio in parsed_ratios if ratio.floor_count is not None
              and ratio.floor_count in (ratio.numerator, *denominator_arms(ratio.denominator))
              and not parsed_arms[ratio.floor_count].ratio_only]
    if floors:
        raise ValueError(f'ally_arm ratio floor_count {floors} names a judged arm of its own ratio: name a third arm '
                         f'that counts the events, or a ratio-only arm, whose count_metric is then used')
    uncounted = [index for ratio in parsed_ratios if isinstance(ratio.denominator, tuple)
                 for index in ratio.denominator if not parsed_arms[index].ratio_only]
    if uncounted:
        raise ValueError(f'ally_arm ratio denominator lists name arms {uncounted} that read no count_metric, so they '
                         f'cannot show their events landed')
    return AllyArm(allies, tuple(health) if health is not None else None, tuple(spell for spell, _, _ in stated),
                   'control_wait' in raw, parsed_arms,
                   tuple(dict.fromkeys(cast for cast in stated if cast[1] > 1)),
                   parsed_ratios, raw.get('reach_source', ''),
                   tuple(parse_ally_attack(attack) for attack in attacks), 'ally_strikes' in raw, strike_health,
                   ally_class, tuple(tuple(pair) for pair in power))


def check(spec, ally):
    if ally is None:
        return
    from coverage import READBACK, STATE, metric_evidence
    from profile import CASTER
    from values import TARGET
    dummy = spec.select_dummy or TARGET in (spec.target, spec.measure_actor, spec.fields.get('target'))
    units = {CASTER, *ally.ally_ids, *((TARGET,) if dummy else ())}
    reads = [(spec.measure_actor, spec.metric, spec.fields, 'its main reading')]
    for index, arm in enumerate(ally.arms):
        unknown = sorted(set(arm.actors) - units)
        if unknown:
            raise ValueError(f'{spec.spell} ally_arm reads {unknown}, not a unit of its scenario {sorted(units)}')
        evidence = metric_evidence().get(arm.metric)
        if evidence is None or evidence == READBACK:
            raise ValueError(f'{spec.spell} ally_arm metric {arm.metric!r} needs a METRIC_EVIDENCE row that is not '
                             f'a readback, found {evidence!r}')
        if arm.metric in PRECONDITION_ONLY_METRICS and not arm.precondition:
            raise ValueError(f'{spec.spell} ally_arm arm {index} reads {arm.metric}, a precondition-only metric: '
                             f'state precondition: true, so an off read voids the trial instead of judging it')
        if arm.precondition and evidence != STATE:
            raise ValueError(f'{spec.spell} ally_arm arm {index} is a precondition on {arm.metric!r}, which is not '
                             f'a state metric ({evidence!r}): a precondition reads a state, never a behaviour')
        reads += [(actor, arm.metric, arm.fields, f'arm {index}') for actor in arm.actors]
        if arm.ratio_only:
            counted = metric_evidence().get(arm.count_metric)
            if counted is None or counted == READBACK:
                raise ValueError(f'{spec.spell} ally_arm arm {index} count_metric {arm.count_metric!r} needs a '
                                 f'METRIC_EVIDENCE row that is not a readback, found {counted!r}')
            reads += [(actor, arm.count_metric, arm.fields, f'arm {index} count') for actor in arm.actors]
    reach_check(spec, ally)
    attacked = {spell for spell, _, _ in ally.ally_attacks}
    for actor, metric, fields, read in reads:
        if actor == ALLY_IDS[0] and metric in CASTER_SCOPED_METRICS and fields.get('spell') in attacked:
            continue
        if actor != CASTER and metric in CASTER_SCOPED_METRICS \
                and not (metric in CASTER_ENTRY_METRICS and 'caster_entry' in fields):
            raise ValueError(f'{spec.spell} ally_arm {read} reads {metric} on {actor}: the harness counts only the '
                             f'events {actor} itself (or its pet, or a caster_entry creature for a heal) cast, never '
                             f'the caster\'s; read it on the caster with fields.target {actor!r}')
    if (ally.ally_attacks or ally.ally_strikes) and (spec.gate_timing != 'between' or spec.setup_only_after):
        raise ValueError(f'{spec.spell} ally_arm ally_attacks and ally_strikes run in the default gate timing only, '
                         f'with no setup_only_after')
    if ally.ally_attacks and not dummy:
        raise ValueError(f'{spec.spell} ally_arm ally_attacks cast at the dummy, which its scenario does not have: '
                         f'set select_dummy or read the dummy')
    if ally.ally_strikes and (spec.strike is None or spec.strike.after_trigger_ms is None
                              or spec.strike.owned_entry is not None or spec.strike.dx):
        raise ValueError(f'{spec.spell} ally_arm ally_strikes repeats the entry\'s strike at each ally after the '
                         f'trigger: a strike with after_trigger_ms, no owned_entry and no dx')
    if ally.ally_strike_health is not None and spec.strike is not None \
            and ally.ally_strike_health > spec.strike.max_health:
        raise ValueError(f'{spec.spell} ally_arm ally_strikes health {ally.ally_strike_health} exceeds the strike\'s '
                         f'max_health {spec.strike.max_health}')
    if ally.ally_casts and spec.attack_swings:
        raise ValueError(f'{spec.spell} ally_arm casts at the ally in cast phases only, not between attack swings')
    for spell in ally.ally_casts:
        if spell not in spec.learn or spell == spec.trigger_spell or spell in spec.setup_casts:
            raise ValueError(f'{spec.spell} ally_arm casts {spell} at the ally only when the scenario learns it '
                             f'(learn) and casts it nowhere else (not the trigger or a setup cast), so its '
                             f'{ALLY_CAST_PROOF_METRIC} proof counts the ally casts alone')
    if ally.control_wait and (spec.cast_in_before or spec.gate_timing != 'between' or spec.setup_only_after
                              or spec.setup_in_before or spec.attack_swings or spec.strike is not None
                              or spec.target_casts_before or spec.enemy_casts_in_before):
        raise ValueError(f'{spec.spell} ally_arm control_wait times an uncast before phase only: cast_in_before '
                         f'false, the default gate timing, no setup_only_after, setup_in_before, swings, strike, '
                         f'target casts before or enemy casts in before')
    if ally.control_wait and ((spec.setup_casts and spec.setup_wait_ms) or spec.enemy_casts or spec.helper_casts
                              or spec.target_casts):
        raise ValueError(f'{spec.spell} ally_arm control_wait reads the uncast control at the treatment\'s interval '
                         f'only without after-phase-only acts: no setup_wait_ms, enemy, helper or target casts')


def subgroup_two_units(actors, fields: dict) -> list[str]:
    return sorted(set(RAID_SUBGROUP_TWO) & {*actors, fields.get('target')})


def reach_check(spec, ally: AllyArm):
    reads = [(subgroup_two_units([spec.measure_actor, spec.target], spec.fields), ally.reach_source,
              'its main reading or cast target')]
    reads += [(subgroup_two_units(arm.actors, arm.fields), arm.reach_source, f'arm {index}')
              for index, arm in enumerate(ally.arms)]
    for units, reach, read in reads:
        if units and not reach:
            raise ValueError(f'{spec.spell} ally_arm {read} reads {units} in raid subgroup 2, outside the caster\'s '
                             f'party: state its reach_source, the code or data line that makes the spell reach raid '
                             f'subgroup 2 (for example IsInRaidWith or TARGET_CHECK_ALLY), never a run\'s reading')
        if reach and not units:
            raise ValueError(f'{spec.spell} ally_arm {read} states a reach_source but reads no unit of raid '
                             f'subgroup 2 {list(RAID_SUBGROUP_TWO)}')


def ally_cast_label(spell: int, moment: str, index: int) -> str:
    return f'{spell} {moment} SETUP: ally cast {index} went off'


def ally_cast_step(spell: int) -> dict:
    from profile import CASTER
    return {'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': ALLY_IDS[0]}


def uncast_before(spec) -> bool:
    return not spec.cast_in_before or spec.trigger_only_after


def ally_attack_label(spell: int, moment: str, index: int) -> str:
    return f'{spell} {moment} SETUP: ally attack {index} went off'


def ally_attack_steps(spec, ally: AllyArm, after: bool) -> list[dict]:
    from values import TARGET
    moment = 'after' if after else 'before'
    spells = [spell for spell, _, _ in ally.ally_attacks]
    steps = []
    for index, (spell, power, _) in enumerate(ally.ally_attacks):
        landed = spells[:index + 1].count(spell) + (spells.count(spell) if after else 0)
        steps += [{'action': 'set_power', 'actor': ALLY_IDS[0], 'power': 0, 'value': power},
                  {'action': 'reset_cooldown', 'actor': ALLY_IDS[0], 'spell': spell},
                  {'action': 'cast', 'actor': ALLY_IDS[0], 'spell': spell, 'target': TARGET},
                  {'action': 'wait', 'label': f'{spell} by the ally at the dummy, past the global cooldown',
                   'ms': ALLY_ATTACK_SETTLE_MS},
                  {'action': 'assert', 'label': ally_attack_label(spell, moment, index), 'actor': ALLY_IDS[0],
                   'metric': ALLY_CAST_PROOF_METRIC, 'spell': spell, 'equals': landed}]
    return steps


def strike_label(spec, moment: str, unit: str, edge: str) -> str:
    return f'{arm_label(spec, moment, "strike", unit)} {edge}'


def ally_strike_steps(spec, ally: AllyArm, after: bool) -> list[dict]:
    from behaviours import STRIKER
    from profile import CASTER, measurement
    moment = 'after' if after else 'before'
    strike = spec.strike
    steps = []
    for unit in ally.ally_ids:
        steps.append(measurement(strike_label(spec, moment, unit, 'start'), CASTER, ALLY_CAST_PROOF_METRIC,
                                 spell=strike.spell, caster=STRIKER))
        steps.append({'action': 'set_health', 'actor': unit, 'maximum': strike.max_health,
                      'value': strike.health if ally.ally_strike_health is None else ally.ally_strike_health})
        for _ in range(strike.count):
            steps += [{'action': 'cast', 'actor': STRIKER, 'spell': strike.spell, 'target': unit},
                      {'action': 'wait', 'label': 'strike', 'ms': strike.wait_ms}]
        steps.append(measurement(strike_label(spec, moment, unit, 'end'), CASTER, ALLY_CAST_PROOF_METRIC,
                                 spell=strike.spell, caster=STRIKER))
    return steps


def after_trigger_steps(spec, ally: AllyArm, after: bool) -> list[dict]:
    return (ally_strike_steps(spec, ally, after) if ally.ally_strikes else []) + \
        (ally_attack_steps(spec, ally, after) if ally.ally_attacks else [])


def phase_steps(spec, ally: AllyArm, after: bool) -> list[dict]:
    from profile import CASTER
    moment = 'after' if after else 'before'
    steps = []
    for index, spell in enumerate(ally.ally_casts):
        landed = (ally.ally_casts[:index + 1].count(spell) + (ally.ally_casts.count(spell) if after else 0)) \
            * ally.spell_go_per_cast(spell)
        steps += [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}, ally_cast_step(spell),
                  {'action': 'wait', 'label': f'{spell} at the ally, past the global cooldown',
                   'ms': ALLY_CAST_SETTLE_MS},
                  {'action': 'assert', 'label': ally_cast_label(spell, moment, index), 'actor': CASTER,
                   'metric': ALLY_CAST_PROOF_METRIC, 'spell': spell, 'equals': landed}]
    if ally.ally_health is not None:
        value, maximum = ally.ally_health
        steps += [{'action': 'set_health', 'actor': unit, 'value': value, 'maximum': maximum}
                  for unit in ally.ally_ids]
    steps += [{'action': 'set_power', 'actor': unit, 'power': power, 'value': value}
              for power, value in ally.ally_power for unit in ally.ally_ids]
    if ally.control_wait and not after:
        steps.append({'action': 'wait', 'label': CONTROL_LABEL, 'ms': spec.wait_ms})
    if not after and uncast_before(spec):
        steps += after_trigger_steps(spec, ally, after)
    return steps


def prepared_ally_casts(class_file: dict, ally: AllyArm, steps: list[dict]) -> list[dict]:
    from pathlib import Path
    from behaviours import cast_gate_power_step, reagent_steps
    from classes import dataset
    from profile import DBC_DIR
    from tooltip import Records
    from values import CAST_MARGIN_MS, facts_of, required_aura_steps
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    preparation = {}
    for spell in dict.fromkeys(ally.ally_casts):
        facts = facts_of(records, spell)
        if facts.cast_time_ms + CAST_MARGIN_MS > ALLY_CAST_SETTLE_MS:
            raise ValueError(f'ally_arm casts {spell} at the ally with a {facts.cast_time_ms} ms cast time, above '
                             f'the {ALLY_CAST_SETTLE_MS - CAST_MARGIN_MS} ms its {ALLY_CAST_SETTLE_MS} ms settle '
                             f'covers')
        preparation[spell] = (cast_gate_power_step(facts) + required_aura_steps(facts)
                              + reagent_steps(records, spell))
    casts = {spell: ally_cast_step(spell) for spell in preparation}
    return [prepared for step in steps for prepared in (
        [*preparation[step['spell']], step] if step == casts.get(step.get('spell')) else [step])]


def control_interval_check(spec, steps: list[dict]):
    from behaviours import metric_delta_label
    from metric_delta_options import option_phase_steps

    def waited(part: list[dict]) -> int:
        return sum(step['ms'] for step in part if step['action'] == 'wait')

    labels = [step.get('label') for step in steps]
    before = labels.index(metric_delta_label(spec, 'before'))
    after = labels.index(metric_delta_label(spec, 'after'))
    control = waited(steps[labels.index(CONTROL_LABEL):before])
    treatment = waited(steps[labels.index(EXPIRE_LABEL, before) + 1:after]) - waited(option_phase_steps(spec, True))
    if treatment != control:
        raise ValueError(f'{spec.spell} ally_arm control_wait reads the uncast control {control} ms after the ally '
                         f'fixture but the treatment {treatment} ms after it: no setup_wait_ms, enemy, helper or '
                         f'target casts, or option waits after the trigger, so both intervals match')


def arm_label(spec, moment: str, index: int, actor: str) -> str:
    from behaviours import metric_delta_label
    return f'{metric_delta_label(spec, moment)} ally_arm {index} {actor}'


def arm_count_label(spec, moment: str, index: int, actor: str) -> str:
    return f'{arm_label(spec, moment, index, actor)} count'


def arm_reads(spec, ally: AllyArm, moment: str) -> list[dict]:
    from profile import measurement
    return [read for index, arm in enumerate(ally.arms) for actor in arm.actors for read in (
        [measurement(arm_label(spec, moment, index, actor), actor, arm.metric, **arm.fields)]
        + ([measurement(arm_count_label(spec, moment, index, actor), actor, arm.count_metric, **arm.fields)]
           if arm.ratio_only else []))]


def fixtures(class_file: dict, spec, ally: AllyArm, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, base_steps, player_fixture
    players = scenario['players']
    for unit in ally.ally_ids:
        players.append({**player_fixture(class_file), 'id': unit,
                        **({'class': ally.ally_class} if ally.ally_class is not None else {}),
                        **({'allow_regeneration': False} if spec.disable_regeneration else {})})
    if len(players) > SCHEMA_ONE_PLAYERS:
        scenario['schema'] = RAID_SCHEMA
    steps = scenario['steps']
    settled = len(base_steps(class_file))
    steps[settled:settled] = [{'action': 'group', 'actor': CASTER, 'target': unit} for unit in ally.ally_ids] + \
        [{'action': 'learn', 'actor': ALLY_IDS[0], 'spell': spell}
         for spell in dict.fromkeys(spell for spell, _, _ in ally.ally_attacks)]
    for moment in ('after', 'before'):
        read = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, moment))
        steps[read + 1:read + 1] = arm_reads(spec, ally, moment)
    steps[:] = prepared_ally_casts(class_file, ally, steps)
    if ally.control_wait:
        control_interval_check(spec, steps)
    contract = (f' {ally.allies} grouped ally player(s) {list(ally.ally_ids)} stand with the caster'
                + (', regeneration off' if spec.disable_regeneration else '')
                + (f', of CoA class {ally.ally_class}' if ally.ally_class is not None else '') + '.')
    if scenario['schema'] == RAID_SCHEMA:
        contract += (f' With {len(players)} players the scenario takes schema {RAID_SCHEMA} (more than '
                     f'{SCHEMA_ONE_PLAYERS} players, run.py MAX_PLAYERS).')
    if ally.ally_casts:
        contract += (f' Each phase first casts {list(ally.ally_casts)} at {ALLY_IDS[0]} (learned, its flat power '
                     f'cost, required caster aura and reagents set first), waiting {ALLY_CAST_SETTLE_MS} ms after '
                     f'each, and asserts the caster\'s {ALLY_CAST_PROOF_METRIC} of each, so the scenario fails when '
                     f'an ally cast did not go off.')
        for spell, count, source in ally.go_per_cast:
            contract += f' Each {spell} cast at {ALLY_IDS[0]} counts {count} SPELL_GO ({source}).'
    if ally.ally_health is not None:
        contract += f' Each phase sets the allies\' health to {ally.ally_health[0]} of {ally.ally_health[1]}.'
    for power, value in ally.ally_power:
        contract += (f' Each phase sets the allies\' power {power} to {value} ahead of the trigger (the harness '
                     f'refuses a value above the maximum).')
    if ally.ally_strikes:
        contract += (f' After the trigger and the caster\'s strikes (at the start of an uncast before phase), each '
                     f'ally is set to {spec.strike.health if ally.ally_strike_health is None else ally.ally_strike_health}'
                     f' of {spec.strike.max_health} health and struck '
                     f'{spec.strike.count} time(s) by the striker\'s '
                     f'{spec.strike.spell}; the caster\'s count of the striker\'s {ALLY_CAST_PROOF_METRIC} of it is '
                     f'read around each ally\'s strikes, and a count that did not grow by {spec.strike.count} voids '
                     f'the trial (unmeasured).')
    for spell, power, source in ally.ally_attacks:
        contract += (f' {ALLY_IDS[0]} learns {spell} and, after the trigger (at the same point in an uncast before '
                     f'phase), casts it at the dummy with its power set to {power}, waiting {ALLY_ATTACK_SETTLE_MS} '
                     f'ms, and its own {ALLY_CAST_PROOF_METRIC} of it is asserted, so the scenario fails when the '
                     f'attack did not go off ({source}).')
    if ally.control_wait:
        contract += (f' The uncast before phase waits {spec.wait_ms} ms, the after phase\'s wait, before its '
                     f'reading (timed no-cast control).')
    if ally.reach_source:
        contract += f' The main reading reaches raid subgroup 2 ({ally.reach_source}).'
    for index, arm in enumerate(ally.arms):
        if arm.ratio_only:
            contract += (f' Arm {index}: {arm.metric} {arm.fields} summed over {list(arm.actors)}, read right after '
                         f'each main reading with its {arm.count_metric}, judged only through its ratio, which is '
                         f'unmeasured unless the count moved ({arm.source}).')
        else:
            contract += (f' Arm {index}: {arm.metric} {arm.fields} summed over {list(arm.actors)}, read right after '
                         f'each main reading, expected {arm.before_expected:g} then {arm.expected:g} within '
                         f'{arm.tolerance:g} ({arm.source}).')
        if arm.precondition:
            contract += (f' Arm {index} is a precondition: off or unread, it voids the trial (unmeasured), never '
                         f'an alert or a judgement.')
        if arm.reach_source:
            contract += f' Arm {index} reaches raid subgroup 2 ({arm.reach_source}).'
    for ratio in ally.ratios:
        over = (f'arm {ratio.denominator}' if not isinstance(ratio.denominator, tuple)
                else f'the sum of arms {list(ratio.denominator)}')
        contract += (f' Ratio: arm {ratio.numerator} over {over}, each read as its after sum less '
                     f'its before sum, expected {ratio.expected:g} within {ratio.tolerance:g} ({ratio.source}).')
        if ratio.floor_count is not None:
            contract += (f' Its low end widens by arm {ratio.floor_count}\'s delta over arm {ratio.denominator}\'s, '
                         f'one unit per counted event truncated to an integer, and the ratio is unmeasured when the '
                         f'widened band no longer excludes {DISCRIMINATED_DEVIATION:.0%} below expected.')
    scenario['contract'] += contract


def model(spec, ally: AllyArm) -> dict:
    ratios = {'ratios': [{'numerator': ratio.numerator, 'denominator': ratio.denominator if not isinstance(
                              ratio.denominator, tuple) else list(ratio.denominator), 'expected': ratio.expected,
                          'tolerance': ratio.tolerance, 'source': ratio.source,
                          **({FLOOR_COUNT_KEY: ratio.floor_count} if ratio.floor_count is not None else {})}
                         for ratio in ally.ratios]}
    strikes = {'strike_reads': [[strike_label(spec, moment, unit, 'start'), strike_label(spec, moment, unit, 'end'),
                                 spec.strike.count] for moment in ('before', 'after') for unit in ally.ally_ids]
               } if ally.ally_strikes else {}
    arms = [arm_model(spec, index, arm) for index, arm in enumerate(ally.arms)]
    return {NAME: {'allies': list(ally.ally_ids),
                   **({'ally_class': ally.ally_class} if ally.ally_class is not None else {}),
                   **({'ally_power': [list(pair) for pair in ally.ally_power]} if ally.ally_power else {}),
                   'arms': arms,
                   **(ratios if ally.ratios else {}), **strikes}}


def arm_model(spec, index: int, arm: Arm) -> dict:
    labels = {moment: [arm_label(spec, moment, index, actor) for actor in arm.actors] for moment in ('before', 'after')}
    if arm.ratio_only:
        return {'metric': arm.metric, 'count_metric': arm.count_metric, 'source': arm.source, **labels,
                **{f'count_{moment}': [arm_count_label(spec, moment, index, actor) for actor in arm.actors]
                   for moment in ('before', 'after')}}
    return {'metric': arm.metric, 'before_expected': arm.before_expected, 'expected': arm.expected,
            'tolerance': arm.tolerance, 'source': arm.source, **labels,
            **({'precondition': True} if arm.precondition else {})}


def arm_text(index: int, arm: dict, before: float, after: float, held: bool) -> str:
    return (f'ally arm {index} {arm["metric"]}: {before:g} before (expected {arm["before_expected"]:g}) '
            f'and {after:g} after (expected {arm["expected"]:g}), within {arm["tolerance"]:g}: '
            f'{"ok" if held else "off"} ({arm["source"]})')


def arm_held(arm: dict, before: float, after: float) -> bool:
    return (abs(before - arm['before_expected']) <= arm['tolerance']
            and abs(after - arm['expected']) <= arm['tolerance'])


def void_trial(verdict, run, arms: list[dict]):
    texts = []
    void = False
    for index, arm in enumerate(arms):
        if not arm.get('precondition'):
            continue
        missing = next((label for label in (*arm['before'], *arm['after']) if run.values.get(label) is None), None)
        if missing is not None:
            texts.append(f'precondition arm {index}: {missing} was not read')
            void = True
            continue
        before = sum(run.values[label] for label in arm['before'])
        after = sum(run.values[label] for label in arm['after'])
        held = arm_held(arm, before, after)
        void = void or not held
        texts.append(f'precondition {arm_text(index, arm, before, after, held)}')
    if not void:
        return None, texts
    return replace(verdict, status='unmeasured',
                   explanation='; '.join([verdict.explanation, *texts,
                                          'a precondition failed: the trial is void, not judged'])), texts


def unlanded_strikes(run, ally: dict) -> list[str]:
    texts = []
    for start, end, count in ally.get('strike_reads', []):
        first, last = run.values.get(start), run.values.get(end)
        if first is None or last is None:
            texts.append(f'{start if first is None else end} was not read')
        elif last - first != count:
            texts.append(f'{end}: the striker\'s count grew by {last - first:g}, not {count}')
    return texts


def verdict(verdict, run, ally: dict):
    unlanded = unlanded_strikes(run, ally)
    if unlanded:
        return replace(verdict, status='unmeasured',
                       explanation='; '.join([verdict.explanation, *unlanded,
                                              'an ally strike did not land: the trial is void, not judged']))
    if not ally['arms'] or verdict.status == 'unmeasured':
        return verdict
    voided, texts = void_trial(verdict, run, ally['arms'])
    if voided is not None:
        return voided
    off = False
    deltas = []
    landed_counts = {}
    uncounted = set()
    for index, arm in enumerate(ally['arms']):
        if arm.get('precondition'):
            deltas.append(None)
            continue
        counts = (*arm.get('count_before', ()), *arm.get('count_after', ()))
        missing = next((label for label in (*arm['before'], *arm['after'], *counts)
                        if run.values.get(label) is None), None)
        if missing is not None:
            return replace(verdict, status='alert' if verdict.status == 'alert' else 'unmeasured',
                           explanation=f'{verdict.explanation}; ally arm {index}: {missing} was not read')
        before = sum(run.values[label] for label in arm['before'])
        after = sum(run.values[label] for label in arm['after'])
        deltas.append(after - before)
        if 'count_metric' in arm:
            landed = (sum(run.values[label] for label in arm['count_after'])
                      - sum(run.values[label] for label in arm['count_before']))
            landed_counts[index] = landed
            if landed <= 0:
                uncounted.add(index)
            texts.append(f'ally arm {index} {arm["metric"]}: {before:g} before and {after:g} after, {landed:g} '
                         f'{arm["count_metric"]} events landed, judged through its ratio ({arm["source"]})')
            continue
        held = arm_held(arm, before, after)
        off = off or not held
        texts.append(arm_text(index, arm, before, after, held))
    undiscriminated = False
    for ratio in ally.get('ratios', []):
        numerator = deltas[ratio['numerator']]
        denominator = sum(deltas[index] for index in denominator_arms(ratio['denominator']))
        measured = numerator / denominator if denominator else None
        floor = ratio.get(FLOOR_COUNT_KEY)
        widening = (landed_counts.get(floor, deltas[floor] if floor is not None else 0) / denominator
                    if floor is not None and denominator else 0.0)
        arms = {ratio['numerator'], *denominator_arms(ratio['denominator']), ratio.get(FLOOR_COUNT_KEY)}
        unlanded = sorted(index for index in arms & uncounted)
        if unlanded or (measured is None and arms & {index for index, arm in enumerate(ally['arms'])
                                                     if 'count_metric' in arm}):
            undiscriminated = True
            texts.append(f'ally ratio arm {ratio["numerator"]} / arm {ratio["denominator"]}: unmeasured, '
                         + (f'no event of ratio-only arm(s) {unlanded} landed' if unlanded
                            else 'the denominator arm did not move'))
            continue
        low, high = ratio['expected'] - ratio['tolerance'] - widening, ratio['expected'] + ratio['tolerance']
        if FLOOR_COUNT_KEY in ratio and low <= (1 - DISCRIMINATED_DEVIATION) * ratio['expected']:
            undiscriminated = True
            texts.append(f'ally ratio arm {ratio["numerator"]} / arm {ratio["denominator"]}: the band widened by '
                         f'{widening:g} for arm {ratio[FLOOR_COUNT_KEY]}\'s truncated events reaches {low:g}, no '
                         f'longer excluding {DISCRIMINATED_DEVIATION:.0%} below {ratio["expected"]:g}: unmeasured')
            continue
        held = measured is not None and low <= measured <= high
        off = off or not held
        read = f'{measured:g}' if measured is not None else 'none, the denominator arm did not move'
        band = (f'within {ratio["tolerance"]:g}' if FLOOR_COUNT_KEY not in ratio
                else f'{low:g} to {high:g}, the low end widened by {widening:g} for arm '
                     f'{ratio[FLOOR_COUNT_KEY]}\'s truncated events')
        texts.append(f'ally ratio arm {ratio["numerator"]} / arm {ratio["denominator"]}: {numerator:g} / '
                     f'{denominator:g} = {read} (expected {ratio["expected"]:g} {band}): '
                     f'{"ok" if held else "off"} ({ratio["source"]})')
    explanation = '; '.join([verdict.explanation, *texts])
    status = 'alert' if off else 'unmeasured' if undiscriminated else verdict.status
    return replace(verdict, status=status, explanation=explanation)
