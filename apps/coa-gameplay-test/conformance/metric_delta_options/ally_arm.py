from dataclasses import dataclass, replace
import math

NAME = 'ally_arm'
ORDER = 24
METRIC_EVIDENCE = {'combat_reach': 'state'}
PRECONDITION_ONLY_METRICS = frozenset(METRIC_EVIDENCE)
ALLY_IDS = ('ally', 'ally2', 'ally3', 'ally4', 'ally5', 'ally6', 'ally7')
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
KEYS = {'allies', 'ally_health', 'ally_casts', 'control_wait', 'arms', 'ratios', 'reach_source'}
ARM_KEYS = {'actors', 'metric', 'fields', 'before_expected', 'expected', 'tolerance', 'source', 'reach_source',
            'precondition'}
OPTIONAL_ARM_KEYS = {'fields', 'reach_source', 'precondition'}
ALLY_CAST_KEYS = {'spell', 'spell_go_per_cast', 'source'}
RATIO_KEYS = {'numerator', 'denominator', 'expected', 'tolerance', 'source'}


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
    precondition: bool = False


@dataclass(frozen=True)
class Ratio:
    numerator: int
    denominator: int
    expected: float
    tolerance: float
    source: str


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

    @property
    def ally_ids(self) -> tuple[str, ...]:
        return ALLY_IDS[:self.allies]

    def spell_go_per_cast(self, spell: int) -> int:
        return next((count for stated, count, _ in self.go_per_cast if stated == spell), 1)


def number(value) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def stated_text(value) -> bool:
    return isinstance(value, str) and bool(value.strip())


def parse_arm(raw) -> Arm:
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
               'precondition' in raw)


def parse_ally_cast(raw) -> tuple[int, int, str]:
    if type(raw) is int and raw > 0:
        return raw, 1, ''
    if not isinstance(raw, dict) or set(raw) != ALLY_CAST_KEYS or type(raw['spell']) is not int or raw['spell'] <= 0 \
            or type(raw['spell_go_per_cast']) is not int or raw['spell_go_per_cast'] < 2 \
            or not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError(f'an ally_arm ally cast is a spell id (one SPELL_GO per cast) or {{spell, spell_go_per_cast: '
                         f'integer >= 2, source: the code or data line that casts the extra SPELL_GO}}, not {raw!r}')
    return raw['spell'], raw['spell_go_per_cast'], raw['source']


def parse_ratio(raw, arms: int) -> Ratio:
    if not isinstance(raw, dict) or set(raw) != RATIO_KEYS \
            or not all(type(raw[key]) is int and 0 <= raw[key] < arms for key in ('numerator', 'denominator')) \
            or raw['numerator'] == raw['denominator'] \
            or not all(number(raw[key]) for key in ('expected', 'tolerance')) \
            or raw['expected'] <= 0 or raw['tolerance'] < 0 \
            or not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError(f'an ally_arm ratio is {{numerator, denominator: two distinct arm indices below {arms}, '
                         f'expected > 0, tolerance >= 0, source: text}}, finite numbers, not {raw!r}')
    return Ratio(raw['numerator'], raw['denominator'], float(raw['expected']), float(raw['tolerance']), raw['source'])


def parse(raw) -> AllyArm:
    if not isinstance(raw, dict) or not raw or not set(raw) <= KEYS:
        raise ValueError(f'ally_arm is a non-empty object of {sorted(KEYS)}, not {raw!r}')
    allies = raw.get('allies', 1)
    health = raw.get('ally_health')
    casts = raw.get('ally_casts', [])
    if type(allies) is not int or not 1 <= allies <= len(ALLY_IDS):
        raise ValueError(f'ally_arm allies is an integer from 1 to {len(ALLY_IDS)}, not {allies!r}')
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
    if any(parsed_arms[index].precondition for ratio in parsed_ratios
           for index in (ratio.numerator, ratio.denominator)):
        raise ValueError('an ally_arm ratio names behaviour arms only, never a precondition arm')
    return AllyArm(allies, tuple(health) if health is not None else None, tuple(spell for spell, _, _ in stated),
                   'control_wait' in raw, parsed_arms,
                   tuple(dict.fromkeys(cast for cast in stated if cast[1] > 1)),
                   parsed_ratios, raw.get('reach_source', ''))


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
    reach_check(spec, ally)
    for actor, metric, fields, read in reads:
        if actor != CASTER and metric in CASTER_SCOPED_METRICS \
                and not (metric in CASTER_ENTRY_METRICS and 'caster_entry' in fields):
            raise ValueError(f'{spec.spell} ally_arm {read} reads {metric} on {actor}: the harness counts only the '
                             f'events {actor} itself (or its pet, or a caster_entry creature for a heal) cast, never '
                             f'the caster\'s; read it on the caster with fields.target {actor!r}')
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
    if ally.control_wait and not after:
        steps.append({'action': 'wait', 'label': CONTROL_LABEL, 'ms': spec.wait_ms})
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


def arm_reads(spec, ally: AllyArm, moment: str) -> list[dict]:
    from profile import measurement
    return [measurement(arm_label(spec, moment, index, actor), actor, arm.metric, **arm.fields)
            for index, arm in enumerate(ally.arms) for actor in arm.actors]


def fixtures(class_file: dict, spec, ally: AllyArm, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, base_steps, player_fixture
    players = scenario['players']
    for unit in ally.ally_ids:
        players.append({**player_fixture(class_file), 'id': unit,
                        **({'allow_regeneration': False} if spec.disable_regeneration else {})})
    steps = scenario['steps']
    settled = len(base_steps(class_file))
    steps[settled:settled] = [{'action': 'group', 'actor': CASTER, 'target': unit} for unit in ally.ally_ids]
    for moment in ('after', 'before'):
        read = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, moment))
        steps[read + 1:read + 1] = arm_reads(spec, ally, moment)
    steps[:] = prepared_ally_casts(class_file, ally, steps)
    if ally.control_wait:
        control_interval_check(spec, steps)
    contract = (f' {ally.allies} grouped ally player(s) {list(ally.ally_ids)} stand with the caster'
                + (', regeneration off' if spec.disable_regeneration else '') + '.')
    if ally.ally_casts:
        contract += (f' Each phase first casts {list(ally.ally_casts)} at {ALLY_IDS[0]} (learned, its flat power '
                     f'cost, required caster aura and reagents set first), waiting {ALLY_CAST_SETTLE_MS} ms after '
                     f'each, and asserts the caster\'s {ALLY_CAST_PROOF_METRIC} of each, so the scenario fails when '
                     f'an ally cast did not go off.')
        for spell, count, source in ally.go_per_cast:
            contract += f' Each {spell} cast at {ALLY_IDS[0]} counts {count} SPELL_GO ({source}).'
    if ally.ally_health is not None:
        contract += f' Each phase sets the allies\' health to {ally.ally_health[0]} of {ally.ally_health[1]}.'
    if ally.control_wait:
        contract += (f' The uncast before phase waits {spec.wait_ms} ms, the after phase\'s wait, before its '
                     f'reading (timed no-cast control).')
    if ally.reach_source:
        contract += f' The main reading reaches raid subgroup 2 ({ally.reach_source}).'
    for index, arm in enumerate(ally.arms):
        contract += (f' Arm {index}: {arm.metric} {arm.fields} summed over {list(arm.actors)}, read right after each '
                     f'main reading, expected {arm.before_expected:g} then {arm.expected:g} within '
                     f'{arm.tolerance:g} ({arm.source}).')
        if arm.precondition:
            contract += (f' Arm {index} is a precondition: off or unread, it voids the trial (unmeasured), never '
                         f'an alert or a judgement.')
        if arm.reach_source:
            contract += f' Arm {index} reaches raid subgroup 2 ({arm.reach_source}).'
    for ratio in ally.ratios:
        contract += (f' Ratio: arm {ratio.numerator} over arm {ratio.denominator}, each read as its after sum less '
                     f'its before sum, expected {ratio.expected:g} within {ratio.tolerance:g} ({ratio.source}).')
    scenario['contract'] += contract


def model(spec, ally: AllyArm) -> dict:
    ratios = {'ratios': [{'numerator': ratio.numerator, 'denominator': ratio.denominator, 'expected': ratio.expected,
                          'tolerance': ratio.tolerance, 'source': ratio.source} for ratio in ally.ratios]}
    return {NAME: {'allies': list(ally.ally_ids), 'arms': [
        {'metric': arm.metric, 'before_expected': arm.before_expected, 'expected': arm.expected,
         'tolerance': arm.tolerance, 'source': arm.source,
         'before': [arm_label(spec, 'before', index, actor) for actor in arm.actors],
         'after': [arm_label(spec, 'after', index, actor) for actor in arm.actors],
         **({'precondition': True} if arm.precondition else {})}
        for index, arm in enumerate(ally.arms)], **(ratios if ally.ratios else {})}}


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


def verdict(verdict, run, ally: dict):
    if not ally['arms'] or verdict.status == 'unmeasured':
        return verdict
    voided, texts = void_trial(verdict, run, ally['arms'])
    if voided is not None:
        return voided
    off = False
    deltas = []
    for index, arm in enumerate(ally['arms']):
        if arm.get('precondition'):
            deltas.append(None)
            continue
        missing = next((label for label in (*arm['before'], *arm['after']) if run.values.get(label) is None), None)
        if missing is not None:
            return replace(verdict, status='alert' if verdict.status == 'alert' else 'unmeasured',
                           explanation=f'{verdict.explanation}; ally arm {index}: {missing} was not read')
        before = sum(run.values[label] for label in arm['before'])
        after = sum(run.values[label] for label in arm['after'])
        deltas.append(after - before)
        held = arm_held(arm, before, after)
        off = off or not held
        texts.append(arm_text(index, arm, before, after, held))
    for ratio in ally.get('ratios', []):
        numerator, denominator = deltas[ratio['numerator']], deltas[ratio['denominator']]
        measured = numerator / denominator if denominator else None
        held = measured is not None and abs(measured - ratio['expected']) <= ratio['tolerance']
        off = off or not held
        read = f'{measured:g}' if measured is not None else 'none, the denominator arm did not move'
        texts.append(f'ally ratio arm {ratio["numerator"]} / arm {ratio["denominator"]}: {numerator:g} / '
                     f'{denominator:g} = {read} (expected {ratio["expected"]:g} within {ratio["tolerance"]:g}): '
                     f'{"ok" if held else "off"} ({ratio["source"]})')
    explanation = '; '.join([verdict.explanation, *texts])
    return replace(verdict, status='alert' if off else verdict.status, explanation=explanation)
