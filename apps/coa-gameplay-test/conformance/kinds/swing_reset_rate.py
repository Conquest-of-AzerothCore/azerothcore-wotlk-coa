from dataclasses import dataclass
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from hits import MAX_ACCELERATED_SCENARIO_MS, creature_fixture, timed
from kinds.cooldown_reset_rate import (CLEAR_COOLDOWN_OPCODE, cooldown_reset_rate_pooled_verdict, kind_residual,
                                       minimum_trials)
from procs import RESIDUAL_TARGET
from profile import (CASTER, DBC_DIR, EQUIPMENT_SLOT_MAIN_HAND, EQUIPMENT_SLOT_OFF_HAND, base_steps, equipped_weapons,
                     for_entry, measurement, player_fixture)
from tooltip import Records
from values import Expectation, TARGET, dataset

KIND = 'swing_reset_rate'
ORDER = 46
HIT_METRIC = 'melee_damage_count'
SETTLE_MS = 1000
MELEE_SLOTS = (EQUIPMENT_SLOT_MAIN_HAND, EQUIPMENT_SLOT_OFF_HAND)
MARKS = ('control hits', 'control resets', 'treatment hits', 'treatment resets')


@dataclass(frozen=True)
class SwingResetRateSpec:
    spell: int
    name: str
    quote: str
    talent: int
    reset_spell: int
    chance_pct: float
    control_ms: int
    attack_ms: int
    parts: int = 1
    label_suffix: str = 'swing_reset_rate'
    residual: dict | None = None


def swing_reset_rate_spec(entry: dict) -> SwingResetRateSpec:
    spec = SwingResetRateSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['talent']),
                              int(entry['reset_spell']), float(entry['chance_pct']), int(entry['control_ms']),
                              int(entry['attack_ms']), int(entry.get('parts', 1)),
                              entry.get('label_suffix', 'swing_reset_rate'),
                              kind_residual(int(entry['spell']), entry, float(entry['chance_pct'])))
    if not 0 < spec.chance_pct < 100 or spec.control_ms < 1 or spec.attack_ms < 1 or spec.parts < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a chance below 100%, a control and a treatment attack time and '
                         f'at least one part')
    return spec


def melee_speeds(class_file: dict, spell_id: int | None = None) -> list[int]:
    if 'weapon_sets' in class_file and 'weapon_set' not in class_file:
        class_file = for_entry(class_file, spell_id)
    return [int(weapon['speed_ms']) for weapon, slot in equipped_weapons(class_file)
            if slot in MELEE_SLOTS and weapon.get('speed_ms', 0) > 0]


def swing_bound(spec: SwingResetRateSpec, speeds: list[int]) -> int:
    return spec.parts * sum(spec.attack_ms // speed for speed in speeds)


def reset_mark(spec: SwingResetRateSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'


def swing_reset_rate_scenario(class_file: dict, spec: SwingResetRateSpec) -> tuple[dict, list[Expectation]]:
    if 'weapon_sets' in class_file and 'weapon_set' not in class_file:
        class_file = for_entry(class_file, spec.spell)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.chance_pct)
    speeds = melee_speeds(class_file, spec.spell)
    if not speeds:
        raise ValueError(f'{spec.spell} {KIND} needs a melee weapon with a swing speed')
    needed = minimum_trials(spec.chance_pct, spec.residual)
    confidence = f'{spec.residual["confidence"]:g}' if spec.residual else '99%'
    bound = swing_bound(spec, speeds)
    if bound < needed:
        raise ValueError(f'{spec.spell} {KIND} swings at most {bound} times in {spec.parts} pooled parts of '
                         f'{spec.attack_ms} ms (speeds {speeds} ms), fewer than the {needed} landed hits its rate '
                         f'band needs')

    def swings(phase: str, ms: int) -> list[dict]:
        return [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                {'action': 'wait', 'label': f'{phase} swings', 'ms': ms},
                {'action': 'stop_attack', 'actor': CASTER},
                {'action': 'wait', 'label': f'{phase} settle', 'ms': SETTLE_MS}]

    def reads(phase: str) -> list[dict]:
        return [measurement(reset_mark(spec, f'{phase} hits'), CASTER, HIT_METRIC),
                measurement(reset_mark(spec, f'{phase} resets'), CASTER, 'server_packets',
                            opcode=CLEAR_COOLDOWN_OPCODE, row=spec.reset_spell)]

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.reset_spell}]
             + swings('control', spec.control_ms) + reads('control')
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.talent}]
             + swings('treatment', spec.attack_ms) + reads('treatment'))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour swing reset rate',
        'contract': (f'The caster auto-attacks the dummy for {spec.control_ms} ms before {spec.talent} is learned '
                     f'(control: no SMSG_CLEAR_COOLDOWN of {spec.reset_spell}) and for {spec.attack_ms} ms after '
                     f'(weapon speeds {speeds} ms); the clear-cooldown packets of {spec.reset_spell} per landed '
                     f'damaging auto-attack hit of either hand ({HIT_METRIC}: misses, dodges and parries are no '
                     f'trial) must hold {spec.chance_pct:g}% in a Wilson {confidence} interval inside the G-20 band.'
                     + (f' This case is one of {spec.parts} identical pooled parts: the rate is judged on the hits '
                        f'and resets summed over every part (at least {needed} landed hits, so a conformant server '
                        f'fails the Wilson {confidence} interval inside the band with a probability of at most 1%; '
                        f'fewer hits leave it insufficient), and a missing part leaves the claim unmeasured.'
                        if spec.parts > 1 else '')
                     + (f' {RESIDUAL_TARGET} {spec.residual["target"]:g} per pair: Wilson confidence '
                        f'{spec.residual["confidence"]:g} per run instead of 99%, at least {spec.residual["trials"]} '
                        f'landed hits so that a deviation of {spec.residual["min_detectable"] * 100:g} points is '
                        f'outside the band.' if spec.residual else '')),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'server_packets', 'quote': entry.quote, 'chance_pct': spec.chance_pct,
             'minimum_trials': needed, 'swing_bound': bound,
             'reads': {mark: reset_mark(spec, mark) for mark in MARKS}}
    if spec.residual:
        model['residual'] = spec.residual
    expectation = Expectation(reset_mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.talent,
                              None, f'{spec.chance_pct:g}%', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def swing_reset_rate_verdict(base, run, model: dict):
    return cooldown_reset_rate_pooled_verdict(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return swing_reset_rate_scenario(class_file, swing_reset_rate_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'swing_reset_rate')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: swing_reset_rate_verdict}
POOLED_JUDGE = cooldown_reset_rate_pooled_verdict
