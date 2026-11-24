from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, STRIKER_DISTANCE, STRIKER_HEALTH, TAKEN_OUTCOME_ATTACKERS,
                        TAKEN_OUTCOME_ENGAGE_MS, TAKEN_OUTCOME_HEALTH, TAKEN_OUTCOME_SWING_MARGIN_MS,
                        behaviour_entry, cleaned_tooltip, hit_ratio_cast, prose_rule, waited_ms)
from bonus import Bonus, bonus_detail, bonus_status
from hits import MAX_ACCELERATED_SCENARIO_MS, Z_99, base_mana_steps, timed
from procs import swing_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import CAST_MARGIN_MS, DUMMY_ENTRY, Expectation, dataset, facts_of

KIND = 'attacker_miss_share'
ORDER = 46

ATTACKER_MISS_METRIC = 'melee_attacks_taken'
MISS_VICTIM_STATE = 0
MOD_HIT_CHANCE_AURA = 54
MELEE_MISS_CLAMP = (0.0, 60.0)
MINIMUM_SWINGS = 100
MAX_STEPS = 10000
ARMS = ('control', 'treatment')
READ_KEYS = ('swings', 'misses')
MOMENTS = ('start', 'end')


@dataclass(frozen=True)
class AttackerMissShareSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    aura: int
    aura_effect: int
    expected: float
    arm_ms: int
    cycle_ms: int
    settle_ms: int
    attackers: int = TAKEN_OUTCOME_ATTACKERS
    attacker_entry: int = DUMMY_ENTRY
    learn: tuple[int, ...] = ()
    label_suffix: str = 'attacker_miss'
    quote_spell: int | None = None
    pre_cast: tuple[int, ...] = ()
    relocate_dx: float | None = None


def attacker_miss_share_spec(entry: dict) -> AttackerMissShareSpec:
    spec = AttackerMissShareSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['cast_spell']),
                                 int(entry['aura']), int(entry.get('aura_effect', 0)), float(entry['expected']),
                                 int(entry['arm_ms']), int(entry['cycle_ms']), int(entry['settle_ms']),
                                 int(entry.get('attackers', TAKEN_OUTCOME_ATTACKERS)),
                                 int(entry.get('attacker_entry', DUMMY_ENTRY)),
                                 tuple(int(spell) for spell in entry.get('learn', [])),
                                 entry.get('label_suffix', 'attacker_miss'),
                                 int(entry['quote_spell']) if 'quote_spell' in entry else None,
                                 tuple(int(spell) for spell in entry.get('pre_cast', [])),
                                 float(entry['relocate_dx']) if 'relocate_dx' in entry else None)
    if spec.relocate_dx is not None and (not math.isfinite(spec.relocate_dx) or spec.relocate_dx == 0
                                         or abs(spec.relocate_dx) >= STRIKER_DISTANCE):
        raise ValueError(f'{spec.spell} attacker_miss_share relocate_dx is nonzero and under {STRIKER_DISTANCE:g} yd, '
                         f'the distance of the attackers, not {spec.relocate_dx!r}')
    if not 1 <= spec.attackers <= TAKEN_OUTCOME_ATTACKERS:
        raise ValueError(f'{spec.spell} attacker_miss_share needs 1 to {TAKEN_OUTCOME_ATTACKERS} attackers')
    if spec.cycle_ms <= 0 or spec.arm_ms < spec.cycle_ms or spec.arm_ms % spec.cycle_ms:
        raise ValueError(f'{spec.spell} attacker_miss_share needs arms of whole, positive cast cycles')
    if spec.expected == 0:
        raise ValueError(f'{spec.spell} attacker_miss_share needs a stated, nonzero change of the miss share')
    return spec


def stated_points(records: Records, spec: AttackerMissShareSpec) -> float:
    effect = spec.aura_effect
    aura_name = int(records.field('Spell', spec.aura, f'EffectApplyAuraName[{effect}]'))
    if aura_name != MOD_HIT_CHANCE_AURA:
        raise ValueError(f'{spec.spell} attacker_miss_share reads aura {spec.aura} effect {effect}, aura '
                         f'{aura_name}, not SPELL_AURA_MOD_HIT_CHANCE {MOD_HIT_CHANCE_AURA}')
    amount = (int(records.field('Spell', spec.aura, f'EffectBasePoints[{effect}]'))
              + int(records.field('Spell', spec.aura, f'EffectDieSides[{effect}]')))
    return float(-amount)


def quoted_spell(records: Records, spec: AttackerMissShareSpec) -> int:
    if spec.quote_spell is None or spec.quote_spell == spec.spell:
        return spec.spell
    if f'@s:{spec.quote_spell}:' not in cleaned_tooltip(records, spec.spell):
        raise ValueError(f'{spec.spell} attacker_miss_share quotes {spec.quote_spell}, whose tooltip the '
                         f'{spec.spell} tooltip does not embed (@s:{spec.quote_spell}:N@)')
    return spec.quote_spell


def aura_duration_ms(records: Records, aura: int) -> int:
    index = int(records.field('Spell', aura, 'DurationIndex'))
    return int(records.field('SpellDuration', index, 'Duration')) if index else 0


def share_label(spec: AttackerMissShareSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}'


def attacker_id(index: int) -> str:
    return f'attacker{index + 1}'


def read_labels(spec: AttackerMissShareSpec, arm: str) -> dict[str, str]:
    return {f'{moment} {key}': f'{share_label(spec)} {arm} {moment} {key}' for moment in MOMENTS for key in READ_KEYS}


def count_reads(spec: AttackerMissShareSpec, arm: str, moment: str) -> list[dict]:
    labels = read_labels(spec, arm)
    return [measurement(labels[f'{moment} swings'], CASTER, ATTACKER_MISS_METRIC),
            measurement(labels[f'{moment} misses'], CASTER, ATTACKER_MISS_METRIC, victim_state=MISS_VICTIM_STATE)]


def aura_reads(spec: AttackerMissShareSpec, arm: str, moment: str) -> list[dict]:
    return [measurement(f'{share_label(spec)} {arm} aura {moment} {attacker_id(index)}', attacker_id(index), 'aura',
                        spell=spec.aura, caster=CASTER) for index in range(spec.attackers)]


def attacker_miss_share_scenario(class_file: dict, spec: AttackerMissShareSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    expected = stated_points(records, spec)
    if abs(expected - spec.expected) > 1e-9:
        raise ValueError(f'{spec.spell} attacker_miss_share states {spec.expected:g} points but aura {spec.aura} '
                         f'effect {spec.aura_effect} changes the attackers\' miss share by {expected:g} points')
    duration = aura_duration_ms(records, spec.aura)
    if duration <= 0 or spec.cycle_ms >= duration:
        raise ValueError(f'{spec.spell} attacker_miss_share casts every {spec.cycle_ms} ms; the cycle must stay '
                         f'under the {duration} ms duration of aura {spec.aura}')
    facts = facts_of(records, spec.cast_spell)
    pre_facts = [facts_of(records, spell) for spell in spec.pre_cast]
    sequence_ms = sum(pre.cast_time_ms + CAST_MARGIN_MS for pre in pre_facts) + facts.cast_time_ms
    if spec.settle_ms < sequence_ms:
        raise ValueError(f'{spec.spell} attacker_miss_share settles {spec.settle_ms} ms, under the '
                         f'{sequence_ms} ms of the casts of {(*spec.pre_cast, spec.cast_spell)}')
    if pre_facts and spec.cycle_ms < sequence_ms:
        raise ValueError(f'{spec.spell} attacker_miss_share recasts every {spec.cycle_ms} ms, under the '
                         f'{sequence_ms} ms of its pre_cast sequence')
    power = base_mana_steps(class_file, facts)
    if facts.mana_cost_percentage and not power:
        raise ValueError(f'{spec.spell} attacker_miss_share casts {spec.cast_spell}, whose cost is a percentage of '
                         f'base mana, from a class file without base_mana')
    entry = behaviour_entry(records, quoted_spell(records, spec), spec.name, KIND, spec.quote, expected)
    attackers = [attacker_id(index) for index in range(spec.attackers)]
    health = {'action': 'set_health', 'actor': CASTER, 'value': TAKEN_OUTCOME_HEALTH, 'maximum': TAKEN_OUTCOME_HEALTH}
    pre = []
    for spell, pre_fact in zip(spec.pre_cast, pre_facts):
        pre_power = base_mana_steps(class_file, pre_fact)
        if pre_fact.mana_cost_percentage and not pre_power:
            raise ValueError(f'{spec.spell} attacker_miss_share pre_casts {spell}, whose cost is a percentage of '
                             f'base mana, from a class file without base_mana')
        pre += (pre_power + [step for step in hit_ratio_cast(records, spell, CASTER, attackers[0])
                             if step['action'] != 'wait']
                + [{'action': 'wait', 'label': f'pre cast {spell}', 'ms': pre_fact.cast_time_ms + CAST_MARGIN_MS}])
    cast = pre + power + [step for step in hit_ratio_cast(records, spec.cast_spell, CASTER, attackers[0])
                          if step['action'] != 'wait']
    swing_ms = swing_interval(class_file) + TAKEN_OUTCOME_SWING_MARGIN_MS
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': spell}
             for spell in dict.fromkeys((*spec.learn, spec.cast_spell))] + [health]
    for attacker in attackers:
        steps += [{'action': 'attack', 'actor': CASTER, 'target': attacker},
                  {'action': 'wait', 'label': f'engage {attacker}', 'ms': swing_ms}, health]
    steps += [{'action': 'stop_attack', 'actor': CASTER},
              {'action': 'wait', 'label': 'engage', 'ms': TAKEN_OUTCOME_ENGAGE_MS}]
    if spec.relocate_dx is not None:
        steps.append({'action': 'relocate', 'actor': CASTER, 'dx': spec.relocate_dx})
    cycles = spec.arm_ms // spec.cycle_ms
    steps += count_reads(spec, 'control', 'start')
    for cycle in range(1, cycles + 1):
        steps += ([health, {'action': 'wait', 'label': f'control swings {cycle}', 'ms': spec.cycle_ms}]
                  + aura_reads(spec, 'control', str(cycle)))
    steps += count_reads(spec, 'control', 'end')
    steps += ([health] + cast + [{'action': 'wait', 'label': 'treatment settle', 'ms': spec.settle_ms}]
              + aura_reads(spec, 'treatment', 'ready') + count_reads(spec, 'treatment', 'start'))
    for cycle in range(1, cycles + 1):
        steps += ([health] + cast + [{'action': 'wait', 'label': f'treatment swings {cycle}', 'ms': spec.cycle_ms}]
                  + aura_reads(spec, 'treatment', str(cycle)))
    steps += count_reads(spec, 'treatment', 'end')
    steps = base_steps(class_file) + steps
    if len(steps) > MAX_STEPS:
        raise ValueError(f'{spec.spell} attacker_miss_share needs {len(steps)} steps, over the {MAX_STEPS} step cap')
    creatures = [{'id': attacker, 'owner': CASTER, 'entry': spec.attacker_entry, 'level': class_file['level'],
                  'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 2, 'stationary': True}
                 for attacker in attackers]
    moments = [str(cycle) for cycle in range(1, cycles + 1)]
    auras = {'control': [step['label'] for moment in moments for step in aura_reads(spec, 'control', moment)],
             'treatment': [step['label'] for moment in ('ready', *moments)
                           for step in aura_reads(spec, 'treatment', moment)]}
    pre_text = f' after {", ".join(str(spell) for spell in spec.pre_cast)}' if spec.pre_cast else ''
    fixture = (f'reset_cooldown {spec.cast_spell} before every cast (RecoveryTime {facts.recast_ms} ms), a named '
               f'precondition fixture, not the subject (G-21 point 6)')
    if spec.pre_cast:
        fixture += (f'; reset_cooldown of {", ".join(str(spell) for spell in spec.pre_cast)} before every pre cast, '
                    f'the same named fixture')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour attacker miss share',
        'contract': (f'{spec.attackers} aggressive, stationary attackers (creature entry {spec.attacker_entry}, level '
                     f'{class_file["level"]}) melee the caster after one engaging swing each. The control arm counts '
                     f'the swings the caster takes and those with victim state {MISS_VICTIM_STATE} (a miss) over '
                     f'{spec.arm_ms} ms with no cast; the caster\'s health is set every {spec.cycle_ms} ms and aura '
                     f'{spec.aura} is read on every attacker at each cycle end. The treatment arm casts '
                     f'{spec.cast_spell} at {attackers[0]}{pre_text} every {spec.cycle_ms} ms ({fixture}); counting '
                     f'starts {spec.settle_ms} ms after the first cast, once aura {spec.aura} from the caster is read '
                     f'on '
                     f'every attacker, and the aura is read again on every attacker at each cycle end. The miss '
                     f'shares of the two arms are compared against the stated {expected:+g} points with the '
                     f'taken-outcome 99% interval; a lapsed treatment aura, a control aura or a control share '
                     f'within {abs(expected):g} points of the {MELEE_MISS_CLAMP[0]:g} to {MELEE_MISS_CLAMP[1]:g}% '
                     f'miss clamp is unmeasured.'
                     + (f' Before the first read the caster is moved {spec.relocate_dx:+g} yd along x (the harness '
                        f'relocate step) so that every attacker, which settles on a {STRIKER_DISTANCE:g} yd circle around '
                        f'the caster, stays inside the 180 degree front arc of the caster, which faces +x, that the '
                        f'player cast needs (Spell.cpp:7351-7352): the arc then covers attackers up to '
                        f'{math.degrees(math.acos(max(-1.0, spec.relocate_dx / STRIKER_DISTANCE))):.1f} degrees from '
                        f'the facing. This is a margin, not a proof: the attackers can slide around the caster during an '
                        f'arm (ADR 1234). A refused cast leaves the ready read at 0 and the part unmeasured, with the refusal '
                        f'reason as invalid setup.' if spec.relocate_dx is not None else '')),
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': steps}
    model = {'kind': KIND, 'metric': ATTACKER_MISS_METRIC, 'quote': entry.quote, 'expected': expected,
             'victim_state': MISS_VICTIM_STATE, 'reads': {arm: read_labels(spec, arm) for arm in ARMS},
             'auras': auras, 'clamp': list(MELEE_MISS_CLAMP), 'fixture': fixture}
    expectation = Expectation(share_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura, None, f'{expected:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def run_failure(base, run, model: dict, prefix: str):
    from compare import missing_measurement
    labels = [label for arm in ARMS for label in model['reads'][arm].values()]
    labels += [label for arm in ARMS for label in model['auras'][arm]]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=f'{prefix}{missing_measurement(run, missing)}')
    for arm, wanted in (('control', 0), ('treatment', 1)):
        wrong = next((label for label in model['auras'][arm] if run.values[label] != wanted), None)
        if wrong is not None:
            return replace(base, status='unmeasured', explanation=f'{prefix}not judged: {wrong} read '
                                                                  f'{run.values[wrong]:g}, not {wanted}'
                                                                  f'{refused_casts(run)}')
    return None


def refused_casts(run) -> str:
    from compare import cast_result_name, failure_reasons
    refusals = []
    for spell in sorted(run.cast_failures):
        reasons = failure_reasons(run, spell)
        if reasons:
            names = ', '.join(sorted({cast_result_name(reason) for reason in reasons}))
            refusals.append(f'{len(reasons)} casts of {spell} refused, {names}')
    return f'; invalid setup: {"; ".join(refusals)}' if refusals else ''


def arm_counts(runs: list, model: dict, arm: str) -> tuple[float, float]:
    reads = model['reads'][arm]
    swings = sum(run.values[reads['end swings']] - run.values[reads['start swings']] for run in runs)
    misses = sum(run.values[reads['end misses']] - run.values[reads['start misses']] for run in runs)
    return swings, misses


def share_judgement(base, runs: list, model: dict, note: str = ''):
    parts = model.get('parts', 1)
    if len(runs) != parts:
        return replace(base, status='unmeasured', explanation=f'{len(runs)} of {parts} pooled parts ran')
    for run in runs:
        unusable = run_failure(base, run, model, f'{run.key}: ' if parts > 1 else '')
        if unusable is not None:
            return unusable
    shares = {}
    for arm in ARMS:
        swings, misses = arm_counts(runs, model, arm)
        if swings < MINIMUM_SWINGS or not 0 <= misses <= swings:
            return replace(base, status='unmeasured',
                           explanation=f'{arm} arm: {misses:g} misses over {swings:g} swings taken; each arm needs '
                                       f'at least {MINIMUM_SWINGS} swings')
        shares[arm] = (misses / swings, swings, misses)
    (control, control_swings, control_misses), (treated, treated_swings, treated_misses) = \
        shares['control'], shares['treatment']
    expected = float(model['expected'])
    low_clamp, high_clamp = model['clamp']
    if not low_clamp + abs(expected) <= control * 100 <= high_clamp - abs(expected):
        return replace(base, status='unmeasured',
                       explanation=f'control miss share {control:.2%} lies within {abs(expected):g} points of the '
                                   f'{low_clamp:g} to {high_clamp:g}% miss clamp, which could hide the change')
    spread = control * (1 - control) / control_swings + treated * (1 - treated) / treated_swings
    bonus = Bonus((treated - control) * 100, Z_99 * math.sqrt(spread) * 100, expected,
                  int(min(control_swings, treated_swings)))
    status, reason, needed = bonus_status(bonus)
    low, high = bonus.excluded
    return replace(base, status=status, measured=bonus.measured, expected=bonus.expected,
                   low=bonus.expected - bonus.band, high=bonus.expected + bonus.band,
                   detail={'bonus': bonus_detail(bonus), 'swings_needed': needed, 'parts': parts,
                           'fixture': model['fixture']},
                   explanation=f'{control_misses:g} misses of {control_swings:g} swings taken in the control arm '
                               f'({control:.2%}), {treated_misses:g} of {treated_swings:g} with the aura held '
                               f'({treated:.2%}); difference {bonus.measured:+.4g} points (99% interval '
                               f'{bonus.low:+.4g} to {bonus.high:+.4g}) against the stated {expected:+g} points, '
                               f'band +-{bonus.band:.3g}; excludes below {low:+.4g} or above {high:+.4g} points; '
                               f'{reason}; {model["fixture"]}{note}')


SPELL_VARIANT = 'spell_clamp'
ATTACKER_SPELL_HIT_AURA = 186
MAGIC_DAMAGE_CLASS = 1
SAME_LEVEL_SPELL_HIT = 96
FULL_HIT = 100
EDGE_MISS_CHANCE = 0.01
SPELL_RESIDUAL = 0.001
SPELL_CAST_GAP_MS = 300
SPELL_SETTLE_MS = 1000
SPELL_ATTACKER_DISTANCE = 10.0
SPELL_ARMS = (('control', 'clamp'), ('control', 'edge'), ('treatment', 'clamp'), ('treatment', 'edge'))
SPELL_READ_KEYS = ('casts', 'landed')


@dataclass(frozen=True)
class SpellClampSpec:
    spell: int
    name: str
    quote: str
    attacker_spell: int
    expected: float
    aura_effect: int = 0
    attacker_entry: int = DUMMY_ENTRY
    label_suffix: str = 'spell_hit_taken'
    casts: int | None = None


def spell_clamp_spec(entry: dict) -> SpellClampSpec:
    spec = SpellClampSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['attacker_spell']),
                          float(entry['expected']), int(entry.get('aura_effect', 0)),
                          int(entry.get('attacker_entry', DUMMY_ENTRY)), entry.get('label_suffix', 'spell_hit_taken'),
                          entry.get('casts'))
    if spec.casts is not None and (type(spec.casts) is not int or spec.casts < spell_clamp_casts()):
        raise ValueError(f'{spec.spell} attacker_miss_share {SPELL_VARIANT} casts {spec.casts!r} per arm: a whole '
                         f'count of at least {spell_clamp_casts()}, the smallest for the residual')
    if spec.expected <= 0 or spec.expected != int(spec.expected):
        raise ValueError(f'{spec.spell} attacker_miss_share {SPELL_VARIANT} states a whole, positive reduction of the '
                         f'attackers\' spell hit chance, not {spec.expected:g}')
    return spec


def spell_clamp_casts() -> int:
    return math.ceil(math.log(SPELL_RESIDUAL / 4) / math.log(1 - EDGE_MISS_CHANCE))


def spell_clamp_points(records: Records, spec: SpellClampSpec) -> int:
    effect = spec.aura_effect
    aura_name = int(records.field('Spell', spec.spell, f'EffectApplyAuraName[{effect}]'))
    if aura_name != ATTACKER_SPELL_HIT_AURA:
        raise ValueError(f'{spec.spell} attacker_miss_share {SPELL_VARIANT} reads effect {effect}, aura {aura_name}, '
                         f'not SPELL_AURA_MOD_ATTACKER_SPELL_HIT_CHANCE {ATTACKER_SPELL_HIT_AURA}')
    schools = int(records.field('Spell', spec.spell, f'EffectMiscValue[{effect}]'))
    if not schools & int(records.field('Spell', spec.attacker_spell, 'SchoolMask')):
        raise ValueError(f'{spec.spell} attacker_miss_share {SPELL_VARIANT}: aura school mask {schools} leaves out '
                         f'the school of {spec.attacker_spell}')
    if int(records.field('Spell', spec.attacker_spell, 'DmgClass')) != MAGIC_DAMAGE_CLASS:
        raise ValueError(f'{spec.spell} attacker_miss_share {SPELL_VARIANT} needs a magic attacker spell, not '
                         f'{spec.attacker_spell}')
    return -(int(records.field('Spell', spec.spell, f'EffectBasePoints[{effect}]'))
             + int(records.field('Spell', spec.spell, f'EffectDieSides[{effect}]')))


def spell_clamp_label(spec: SpellClampSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}'


def spell_arm_name(arm: tuple[str, str]) -> str:
    return f'{arm[0]} {arm[1]}'


def spell_arm_attacker(index: int) -> str:
    return attacker_id(index)


def spell_arm_bonus(arm: tuple[str, str], points: int) -> int:
    phase, edge = arm
    return FULL_HIT - SAME_LEVEL_SPELL_HIT + (points if phase == 'treatment' else 0) - (1 if edge == 'edge' else 0)


def spell_read_labels(spec: SpellClampSpec, arm: tuple[str, str]) -> dict[str, str]:
    return {f'{moment} {key}': f'{spell_clamp_label(spec)} {spell_arm_name(arm)} {moment} {key}'
            for moment in MOMENTS for key in SPELL_READ_KEYS}


def spell_reads(spec: SpellClampSpec, arm: tuple[str, str], attacker: str, moment: str) -> list[dict]:
    labels = spell_read_labels(spec, arm)
    return [measurement(labels[f'{moment} casts'], CASTER, 'spell_go_count', spell=spec.attacker_spell,
                        caster=attacker),
            measurement(labels[f'{moment} landed'], CASTER, 'spell_log_count', spell=spec.attacker_spell,
                        caster=attacker, target=CASTER)]


def spell_clamp_scenario(class_file: dict, spec: SpellClampSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    points = spell_clamp_points(records, spec)
    if points != spec.expected:
        raise ValueError(f'{spec.spell} attacker_miss_share states {spec.expected:g} points but effect '
                         f'{spec.aura_effect} lowers the attackers\' spell hit chance by {points} points')
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(points))
    casts = spell_clamp_casts() if spec.casts is None else spec.casts
    health = {'action': 'set_health', 'actor': CASTER, 'value': TAKEN_OUTCOME_HEALTH, 'maximum': TAKEN_OUTCOME_HEALTH}
    aura_labels = {phase: f'{spell_clamp_label(spec)} {phase} aura' for phase in ('control', 'treatment')}
    steps = [health, measurement(aura_labels['control'], CASTER, 'aura', spell=spec.spell)]
    for index, arm in enumerate(SPELL_ARMS):
        attacker = spell_arm_attacker(index)
        if arm == ('treatment', 'clamp'):
            steps += [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                      measurement(aura_labels['treatment'], CASTER, 'aura', spell=spec.spell)]
        steps += [health] + spell_reads(spec, arm, attacker, 'start')
        for _ in range(casts):
            steps += [{'action': 'cast', 'actor': attacker, 'spell': spec.attacker_spell, 'target': CASTER},
                      {'action': 'wait', 'ms': SPELL_CAST_GAP_MS}]
        steps += [{'action': 'wait', 'label': f'{spell_arm_name(arm)} settle', 'ms': SPELL_SETTLE_MS}]
        steps += spell_reads(spec, arm, attacker, 'end')
    steps = base_steps(class_file) + steps
    if len(steps) > MAX_STEPS:
        raise ValueError(f'{spec.spell} attacker_miss_share needs {len(steps)} steps, over the {MAX_STEPS} step cap')
    bonuses = {spell_arm_name(arm): spell_arm_bonus(arm, points) for arm in SPELL_ARMS}
    creatures = [{'id': spell_arm_attacker(index), 'owner': CASTER, 'entry': spec.attacker_entry,
                  'level': class_file['level'], 'health': STRIKER_HEALTH, 'distance': SPELL_ATTACKER_DISTANCE,
                  'reaction': 2, 'stationary': True, 'spell_hit_bonus': bonuses[spell_arm_name(arm)]}
                 for index, arm in enumerate(SPELL_ARMS)]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour attacker spell hit clamp',
        'contract': (f'Four stationary hostile attackers (creature entry {spec.attacker_entry}, the class level '
                     f'{class_file["level"]}, so the same-level spell hit chance is {SAME_LEVEL_SPELL_HIT}%, '
                     f'Unit::MagicSpellHitResult) each cast {spec.attacker_spell} at the caster {casts} times, '
                     f'{SPELL_CAST_GAP_MS} ms apart (the harness creature cast, TRIGGERED_FULL_MASK). Their fixture '
                     f'spell hit bonuses place the hit chance on the 100% clamp or one point under it: control '
                     f'(without {spec.spell}) {bonuses["control clamp"]} and {bonuses["control edge"]}, treatment '
                     f'(with {spec.spell} learned, read on the caster) {bonuses["treatment clamp"]} and '
                     f'{bonuses["treatment edge"]}, for the stated reduction of {points} points (DBC). Misses are the '
                     f'SPELL_GO count less the damage logs. A clamp arm must show no miss and an edge arm at least '
                     f'one; a control arm off its expectation (another base than {SAME_LEVEL_SPELL_HIT}%) is '
                     f'unmeasured. With integer points the treatment arms then fix the reduction at exactly '
                     f'{points}: a clamp miss means more, a missless edge arm less. An edge arm shows no miss on a '
                     f'correct server with probability {(1 - EDGE_MISS_CHANCE) ** casts:.2e} per arm and run, at most '
                     f'{4 * (1 - EDGE_MISS_CHANCE) ** casts:.2e} per pair.'),
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': steps}
    model = {'kind': KIND, 'metric': 'spell_log_count', 'quote': entry.quote, 'expected': float(points),
             SPELL_VARIANT: {'casts': casts, 'auras': aura_labels, 'bonuses': bonuses,
                             'reads': {spell_arm_name(arm): spell_read_labels(spec, arm) for arm in SPELL_ARMS}}}
    expectation = Expectation(spell_clamp_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.spell, None,
                              f'{points:g}', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def spell_clamp_judgement(base, run, model: dict):
    from compare import missing_measurement
    clamp = model[SPELL_VARIANT]
    labels = [*clamp['auras'].values()] + [label for reads in clamp['reads'].values() for label in reads.values()]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    for phase, wanted in (('control', 0), ('treatment', 1)):
        read = run.values[clamp['auras'][phase]]
        if read != wanted:
            return replace(base, status='unmeasured', explanation=f'not judged: the {phase} aura read {read:g}, '
                                                                  f'not {wanted}')
    misses = {}
    for arm, reads in clamp['reads'].items():
        casts = run.values[reads['end casts']] - run.values[reads['start casts']]
        landed = run.values[reads['end landed']] - run.values[reads['start landed']]
        if casts != clamp['casts'] or not 0 <= landed <= casts:
            return replace(base, status='unmeasured', explanation=f'not judged: {arm} arm {casts:g} casts and '
                                                                  f'{landed:g} landed, not {clamp["casts"]} casts')
        misses[arm] = casts - landed
    expected = float(model['expected'])
    text = ', '.join(f'{arm} (hit bonus {clamp["bonuses"][arm]}) {misses[arm]:g} misses of {clamp["casts"]}'
                     for arm in misses)
    if misses['control clamp'] != 0 or misses['control edge'] == 0:
        return replace(base, status='unmeasured', explanation=f'{text}; the control arms do not place the base '
                                                              f'spell hit chance at {SAME_LEVEL_SPELL_HIT}%, so the '
                                                              f'clamp edge is unknown')
    if misses['treatment clamp'] != 0:
        return replace(base, status='alert', measured=expected + 1, expected=expected, low=expected, high=expected,
                       explanation=f'{text}; a miss on the treatment clamp arm: the reduction exceeds {expected:g} '
                                   f'points')
    if misses['treatment edge'] == 0:
        return replace(base, status='alert', measured=expected - 1, expected=expected, low=expected, high=expected,
                       explanation=f'{text}; no miss on the treatment edge arm: the reduction is under {expected:g} '
                                   f'points')
    return replace(base, status='ok', measured=expected, expected=expected, low=expected, high=expected,
                   explanation=f'{text}; the reduction is exactly {expected:g} points (clamp arm missless, edge arm '
                               f'missing), {expected - 1:g} and {expected + 1:g} excluded')


def attacker_miss_share_verdict(base, run, model: dict):
    if SPELL_VARIANT in model:
        return spell_clamp_judgement(base, run, model)
    return share_judgement(base, [run], model)


def attacker_miss_share_pooled_verdict(base, runs: list, model: dict):
    if SPELL_VARIANT in model:
        if len(runs) != 1:
            return replace(base, status='unmeasured', explanation=f'{len(runs)} parts ran for a one-part scenario')
        return spell_clamp_judgement(base, runs[0], model)
    return share_judgement(base, runs, model, f'; {len(runs)} parts pooled, the swings of every part summed per arm')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    if entry.get('variant') == SPELL_VARIANT:
        return spell_clamp_scenario(class_file, spell_clamp_spec(entry))
    return attacker_miss_share_scenario(class_file, attacker_miss_share_spec(entry))


def label(entry: dict) -> list[str]:
    default = 'spell_hit_taken' if entry.get('variant') == SPELL_VARIANT else 'attacker_miss'
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', default)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: attacker_miss_share_verdict}
POOLED_JUDGE = attacker_miss_share_pooled_verdict
