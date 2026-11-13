from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset

KIND = 'minion_haste_gate'
ORDER = 42

SPELL_FAILED_NOT_READY = 67
CAST_MARGIN_MS = 500
CLEAR_SETTLE_MS = 200
TIMING_MARGIN = 1.1
ATTACK_TIME_TOLERANCE = 0.01
CRIT_SHARE_FLOOR = 0.6


@dataclass(frozen=True)
class HasteArm:
    attack_ms: int
    early_ms: int
    late_ms: int


@dataclass(frozen=True)
class MinionHasteGateSpec:
    spell: int
    name: str
    quote: str
    learn: tuple[int, ...]
    raise_spell: int
    creature: int
    raise_settle_ms: int
    base_attack_ms: int
    crit_aura: tuple[int, int]
    haste_aura: tuple[int, int]
    gate_ms: int
    cut_ms: int
    observe_spell: int
    observe_power: int
    cleared_auras: tuple[int, ...]
    window_ms: int
    arms: tuple[HasteArm, ...]
    label_suffix: str = 'once_per_sec_arms'


def haste_amount(spec: MinionHasteGateSpec, arm: HasteArm) -> int:
    return round((spec.base_attack_ms / arm.attack_ms - 1) * 100)


def accepted_interval(spec: MinionHasteGateSpec, attack_ms: int, gate_ms: int) -> int:
    return attack_ms * max(1, math.ceil(gate_ms / attack_ms))


def clear_ms(cooldown_ms: int, cut_ms: int, interval_ms: int) -> float:
    return cooldown_ms / (1 + cut_ms / interval_ms)


def checked_arm(spec: MinionHasteGateSpec, arm: HasteArm, cooldown_ms: int) -> None:
    where = f'{spec.spell} {KIND} arm {arm.attack_ms} ms'
    if spec.base_attack_ms * 100 % (100 + haste_amount(spec, arm)) or \
            spec.base_attack_ms * 100 // (100 + haste_amount(spec, arm)) != arm.attack_ms:
        raise ValueError(f'{where}: no whole haste percent turns {spec.base_attack_ms} ms into {arm.attack_ms} ms')
    accepted = accepted_interval(spec, arm.attack_ms, spec.gate_ms)
    expected = clear_ms(cooldown_ms, spec.cut_ms, accepted)
    if not arm.early_ms * TIMING_MARGIN <= expected <= arm.late_ms / TIMING_MARGIN:
        raise ValueError(f'{where}: the stated gate clears the cooldown at {expected:.0f} ms, not between the '
                         f'attempts with a {TIMING_MARGIN:g} margin')
    if arm.late_ms * 1.05 > clear_ms(cooldown_ms, spec.cut_ms, accepted + arm.attack_ms):
        raise ValueError(f'{where}: one crit fewer per cut would still clear the cooldown by the late attempt')
    if accepted > arm.attack_ms and arm.early_ms < TIMING_MARGIN * clear_ms(cooldown_ms, spec.cut_ms, arm.attack_ms):
        raise ValueError(f'{where}: an ungated cut would not yet have cleared the cooldown at the early attempt')


def minion_haste_gate_spec(entry: dict, cooldown_ms: int) -> MinionHasteGateSpec:
    spell, creature, settle = entry['raise']
    spec = MinionHasteGateSpec(int(entry['spell']), entry['name'], entry['quote'],
                               tuple(int(spell) for spell in entry.get('learn', [])), int(spell), int(creature),
                               int(settle), int(entry['base_attack_ms']),
                               (int(entry['crit_aura'][0]), int(entry['crit_aura'][1])),
                               (int(entry['haste_aura'][0]), int(entry['haste_aura'][1])), int(entry['gate_ms']),
                               int(entry['cut_ms']), int(entry['observe_spell']), int(entry['observe_power']),
                               tuple(int(aura) for aura in entry.get('cleared_auras', [])), int(entry['window_ms']),
                               tuple(HasteArm(int(arm['attack_ms']), int(arm['attempts_ms'][0]),
                                              int(arm['attempts_ms'][1])) for arm in entry['arms']),
                               entry.get('label_suffix', 'once_per_sec_arms'))
    if len(spec.arms) != 2 or len({arm.attack_ms for arm in spec.arms}) != 2:
        raise ValueError(f'{spec.spell} {KIND} has two arms of distinct swing intervals')
    binding = [accepted_interval(spec, arm.attack_ms, spec.gate_ms) > arm.attack_ms for arm in spec.arms]
    if sorted(binding) != [False, True]:
        raise ValueError(f'{spec.spell} {KIND} needs one arm the stated gate leaves ungated and one it gates')
    if not 2000 <= spec.window_ms <= 8000:
        raise ValueError(f'{spec.spell} {KIND} refreshes its fixture auras every 2000 to 8000 ms')
    for arm in spec.arms:
        checked_arm(spec, arm, cooldown_ms)
    return spec


def gate_label(spec: MinionHasteGateSpec, arm: HasteArm, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {arm.attack_ms} ms {read}'


def fixture_steps(spec: MinionHasteGateSpec, arm: HasteArm) -> list[dict]:
    owned = {'action': 'set_aura', 'actor': CASTER, 'owned_entry': spec.creature}
    crit, crit_amount = spec.crit_aura
    haste, effect = spec.haste_aura
    return [{**owned, 'spell': crit, 'stacks': 0}, {**owned, 'spell': crit, 'stacks': 1, 'amount': crit_amount},
            {**owned, 'spell': haste, 'stacks': 0},
            {**owned, 'spell': haste, 'stacks': 1, 'effect': effect, 'amount': haste_amount(spec, arm)}]


def observe_cast(spec: MinionHasteGateSpec) -> list[dict]:
    return [{'action': 'set_power', 'actor': CASTER, 'power': 0, 'value': spec.observe_power},
            {'action': 'cast', 'actor': CASTER, 'spell': spec.observe_spell, 'target': CASTER}]


def arm_steps(spec: MinionHasteGateSpec, arm: HasteArm) -> list[dict]:
    cleared = [step for aura in spec.cleared_auras for step in (
        {'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 0},
        {'action': 'set_aura', 'actor': CASTER, 'owned_entry': spec.creature, 'spell': aura, 'stacks': 0})]
    steps = (fixture_steps(spec, arm)
             + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.observe_spell}] + observe_cast(spec)
             + [{'action': 'wait', 'label': 'prime settle', 'ms': CLEAR_SETTLE_MS}] + cleared
             + [measurement(gate_label(spec, arm, 'attack time'), CASTER, 'owned_creature_attack_time_ms',
                            entry=spec.creature),
                measurement(gate_label(spec, arm, 'primed'), CASTER, 'cooldown_ms', spell=spec.observe_spell),
                measurement(gate_label(spec, arm, 'primed crits'), CASTER, 'pet_melee_crits', entry=spec.creature)])
    elapsed = CLEAR_SETTLE_MS
    for moment_ms in (arm.early_ms, arm.late_ms):
        while elapsed < moment_ms:
            chunk = min(spec.window_ms, moment_ms - elapsed)
            steps += fixture_steps(spec, arm) + [{'action': 'wait', 'label': 'gate window', 'ms': chunk}]
            elapsed += chunk
        steps += (observe_cast(spec)
                  + [{'action': 'wait', 'ms': CAST_MARGIN_MS},
                     measurement(gate_label(spec, arm, f'attempt {moment_ms}'), CASTER, 'cast_failure',
                                 spell=spec.observe_spell),
                     measurement(gate_label(spec, arm, f'attempt {moment_ms} crits'), CASTER, 'pet_melee_crits',
                                 entry=spec.creature)])
        elapsed += CAST_MARGIN_MS
    return steps


def arm_model(spec: MinionHasteGateSpec, arm: HasteArm, cooldown_ms: int) -> dict:
    accepted = accepted_interval(spec, arm.attack_ms, spec.gate_ms)
    return {'attack_ms': arm.attack_ms, 'attempts_ms': [arm.early_ms, arm.late_ms],
            'accepted_ms': accepted, 'clear_ms': round(clear_ms(cooldown_ms, spec.cut_ms, accepted)),
            'attack_time': gate_label(spec, arm, 'attack time'), 'primed': gate_label(spec, arm, 'primed'),
            'primed_crits': gate_label(spec, arm, 'primed crits'),
            'attempts': [gate_label(spec, arm, f'attempt {moment}') for moment in (arm.early_ms, arm.late_ms)],
            'crits': [gate_label(spec, arm, f'attempt {moment} crits') for moment in (arm.early_ms, arm.late_ms)]}


def minion_haste_gate_scenario(class_file: dict, entry_row: dict) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    cooldown_ms = int(records.field('Spell', int(entry_row['observe_spell']), 'RecoveryTime'))
    spec = minion_haste_gate_spec(entry_row, cooldown_ms)
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.gate_ms))
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((*spec.learn, spec.raise_spell, spec.observe_spell, spec.spell))]
             + hit_ratio_cast(records, spec.raise_spell, CASTER, CASTER)
             + [{'action': 'wait', 'label': 'raise settle', 'ms': spec.raise_settle_ms},
                {'action': 'assert', 'label': f'SETUP: the {spec.creature} minion is raised', 'actor': CASTER,
                 'metric': 'owned_creature_count', 'entry': spec.creature, 'equals': 1},
                {'action': 'attack', 'actor': CASTER, 'target': TARGET}])
    for arm in spec.arms:
        steps += arm_steps(spec, arm)
    steps.append({'action': 'stop_attack', 'actor': CASTER})
    arms = ', '.join(f'{arm.attack_ms} ms (haste {haste_amount(spec, arm)}%, accepted every '
                     f'{accepted_interval(spec, arm.attack_ms, spec.gate_ms)} ms, refused at {arm.early_ms} ms and '
                     f'cast at {arm.late_ms} ms)' for arm in spec.arms)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour minion haste gate',
        'contract': (f'With {spec.spell} learned, one creature {spec.creature} attacks the dummy with the caster, '
                     f'forced to crit by aura {spec.crit_aura[0]} at amount {spec.crit_aura[1]} and swinging at a set '
                     f'interval through aura {spec.haste_aura[0]} effect {spec.haste_aura[1]} (from '
                     f'{spec.base_attack_ms} ms). In each arm {spec.observe_spell} is cast, its own auras '
                     f'{list(spec.cleared_auras)} are cleared from the caster and the creature, then it is attempted '
                     f'twice. Each crit cuts {spec.cut_ms} ms at most once per {spec.gate_ms} ms: arms {arms}.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'cast_failure', 'quote': entry.quote, 'gate_ms': spec.gate_ms,
             'arms': [arm_model(spec, arm, cooldown_ms) for arm in spec.arms]}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.spell, None, 'refused early, cast late in both arms',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def arm_reading(run, arm: dict) -> tuple[str | None, str]:
    attack = run.values[arm['attack_time']]
    if abs(attack - arm['attack_ms']) > ATTACK_TIME_TOLERANCE * arm['attack_ms']:
        return 'unmeasured', f'the minion swings every {attack:g} ms, not {arm["attack_ms"]} ms'
    early, late = (run.values[label] for label in arm['attempts'])
    crits = run.values[arm['crits'][-1]] - run.values[arm['primed_crits']]
    floor = CRIT_SHARE_FLOOR * arm['attempts_ms'][-1] / arm['attack_ms']
    if crits < floor:
        return 'unmeasured', f'{crits:g} crits by the late attempt, under {floor:.0f}'
    status = 'ok' if early == SPELL_FAILED_NOT_READY and late == 0 else 'alert'
    early_ms, late_ms = arm['attempts_ms']
    return status, (f'{arm["attack_ms"]} ms arm (one cut every {arm["accepted_ms"]} ms clears at about '
                    f'{arm["clear_ms"]} ms): primed {run.values[arm["primed"]]:g} ms, {crits:g} crits; attempt at '
                    f'{early_ms} ms {early:g} (expected {SPELL_FAILED_NOT_READY}), at {late_ms} ms {late:g} '
                    f'(expected 0)')


def minion_haste_gate_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for arm in model['arms'] for label in
              (arm['attack_time'], arm['primed'], arm['primed_crits'], *arm['attempts'], *arm['crits'])]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    readings = [arm_reading(run, arm) for arm in model['arms']]
    statuses = [status for status, _ in readings]
    status = 'unmeasured' if 'unmeasured' in statuses else 'alert' if 'alert' in statuses else 'ok'
    late = [run.values[arm['attempts'][-1]] for arm in model['arms']]
    return replace(base, status=status, measured=float(max(late)), expected=0.0,
                   explanation='; '.join(text for _, text in readings))


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return minion_haste_gate_scenario(class_file, entry)


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'once_per_sec_arms')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: minion_haste_gate_verdict}
