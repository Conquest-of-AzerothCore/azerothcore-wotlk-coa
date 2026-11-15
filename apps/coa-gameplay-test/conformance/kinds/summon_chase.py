from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, FORCED_CHANCE_OP, FORCED_CHANCE_OWNER_AURA, FORCED_CHANCE_PERCENT,
                        behaviour_entry, prose_rule, waited_ms)
from compare import Run, Verdict, missing_measurement
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import DUMMY_DISTANCE, Expectation, TARGET, dataset

KIND = 'summon_chase'
ORDER = 41

DISTANCE = 'owned_creature_distance_2d'
MOMENTS = ('start', 'end')
NOMINAL_MELEE_RANGE_YD = 5.0
ENEMY_MOVE_SHARE = 0.75
MINIMUM_MOVE_YD = 8.0
MAXIMUM_MOVE_YD = 20.0


@dataclass(frozen=True)
class SummonChaseSpec:
    spell: int
    name: str
    quote: str
    talent: int
    trigger_spell: int
    entry: int
    casts: int
    control_casts: int
    cast_gap_ms: int
    move_yd: float
    window_ms: int
    fuse_ms: int
    label_suffix: str = 'run'


def summon_chase_spec(entry: dict) -> SummonChaseSpec:
    spec = SummonChaseSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['talent']),
                           int(entry['trigger_spell']), int(entry['entry']), int(entry['casts']),
                           int(entry['control_casts']), int(entry['cast_gap_ms']), float(entry['move_yd']),
                           int(entry['window_ms']), int(entry['fuse_ms']), entry.get('label_suffix', 'run'))
    if spec.casts < 1 or spec.control_casts < 1 or spec.cast_gap_ms < 100:
        raise ValueError(f'{spec.spell} {KIND} needs control and treatment casts at least 100 ms apart')
    if not MINIMUM_MOVE_YD <= spec.move_yd <= MAXIMUM_MOVE_YD:
        raise ValueError(f'{spec.spell} {KIND} moves the enemy {MINIMUM_MOVE_YD:g} to {MAXIMUM_MOVE_YD:g} yd, beyond '
                         f'the melee reach a summon left behind would still have')
    if spec.casts * spec.cast_gap_ms + spec.window_ms >= spec.fuse_ms:
        raise ValueError(f'{spec.spell} {KIND} reads the summons before their {spec.fuse_ms} ms fuse ends them')
    return spec


def chase_mark(spec: SummonChaseSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'


def summon_chase_scenario(class_file: dict, spec: SummonChaseSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, NOMINAL_MELEE_RANGE_YD)

    def casts(count: int) -> list[dict]:
        return [step for _ in range(count) for step in (
            {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
            {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET},
            {'action': 'wait', 'label': 'cast', 'ms': spec.cast_gap_ms})]

    def reads(moment: str) -> list[dict]:
        return [measurement(chase_mark(spec, f'{moment} summon to enemy'), CASTER, DISTANCE, entry=spec.entry,
                            target=TARGET),
                measurement(chase_mark(spec, f'{moment} summon to caster'), CASTER, DISTANCE, entry=spec.entry,
                            target=CASTER),
                measurement(chase_mark(spec, f'{moment} enemy to caster'), TARGET, 'distance_2d', target=CASTER)]

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell},
                {'action': 'spell_mod_mutant', 'actor': CASTER, 'spell': spec.talent, 'op': FORCED_CHANCE_OP,
                 'percent': FORCED_CHANCE_PERCENT}]
             + casts(spec.control_casts)
             + [measurement(chase_mark(spec, 'control summons'), CASTER, 'owned_creature_count', entry=spec.entry),
                {'action': 'learn', 'actor': CASTER, 'spell': spec.talent}]
             + casts(spec.casts)
             + [{'action': 'unlearn', 'actor': CASTER, 'spell': spec.talent},
                {'action': 'set_aura', 'actor': CASTER, 'spell': FORCED_CHANCE_OWNER_AURA, 'stacks': 0},
                measurement(chase_mark(spec, 'released'), CASTER, 'spell_mod_mutants'),
                measurement(chase_mark(spec, 'summons'), CASTER, 'owned_creature_count', entry=spec.entry)]
             + reads('start')
             + [{'action': 'move_point', 'actor': TARGET, 'dx': spec.move_yd},
                {'action': 'wait', 'label': 'chase window', 'ms': spec.window_ms}]
             + reads('end'))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour summon chase',
        'contract': (f'A forcing fixture raises the roll of {spec.talent} by {FORCED_CHANCE_PERCENT}% until the last '
                     f'treatment cast, then is removed and read gone. Control: {spec.control_casts} casts of '
                     f'{spec.trigger_spell} at a movable dummy {DUMMY_DISTANCE:g} yd out without {spec.talent}: no '
                     f'creature {spec.entry}. Treatment: {spec.casts} casts {spec.cast_gap_ms} ms apart with it '
                     f'learned (then unlearned, so no later summon appears beside the moved dummy); the dummy gets a '
                     f'running point move {spec.move_yd:g} yd away and {spec.window_ms} ms later a creature '
                     f'{spec.entry} must stand within {NOMINAL_MELEE_RANGE_YD:g} yd (NOMINAL_MELEE_RANGE) of it, '
                     f'having moved away from the caster by at least the yards the dummy did less its gap to the '
                     f'dummy at the move and that reach.'),
        'players': [player_fixture(class_file)],
        'creatures': [{**creature_fixture(class_file), 'stationary': False}],
        'steps': steps}
    model = {'kind': KIND, 'metric': DISTANCE, 'quote': entry.quote, 'move_yd': spec.move_yd,
             'expected': NOMINAL_MELEE_RANGE_YD,
             'reads': {mark: chase_mark(spec, mark) for mark in
                       ('control summons', 'summons', 'released',
                        *(f'{moment} {read}' for moment in MOMENTS
                          for read in ('summon to enemy', 'summon to caster', 'enemy to caster')))}}
    expectation = Expectation(chase_mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell,
                              None, f'within {NOMINAL_MELEE_RANGE_YD:g} yd', prose_rule(entry.quote, spec.spell),
                              model)
    return timed(scenario, waited_ms(steps)), [expectation]


def summon_chase_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    missing = next((label for label in reads.values() if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    value = {mark: run.values[label] for mark, label in reads.items()}
    if value['control summons'] != 0:
        return replace(base, status='alert',
                       explanation=f'the control without the talent summoned {value["control summons"]:g}')
    if value['released'] != 0:
        return replace(base, status='alert', explanation=f'{value["released"]:g} forcing modifiers remain')
    if value['summons'] < 1:
        return replace(base, status='unmeasured', explanation='no creature was summoned in the treatment')
    enemy_moved = value['end enemy to caster'] - value['start enemy to caster']
    if enemy_moved < ENEMY_MOVE_SHARE * model['move_yd']:
        return replace(base, status='unmeasured',
                       explanation=f'the enemy moved {enemy_moved:.2f} yd of the {model["move_yd"]:g} ordered: no '
                                   f'run to follow')
    followed = value['end summon to caster'] - value['start summon to caster']
    reach = value['end summon to enemy']
    expected = float(model['expected'])
    floor = enemy_moved - value['start summon to enemy'] - expected
    status = 'ok' if reach <= expected and followed >= floor else 'alert'
    return replace(base, status=status, measured=reach, expected=expected, low=0.0, high=expected,
                   detail={'enemy_moved_yd': enemy_moved, 'summon_followed_yd': followed, 'followed_floor_yd': floor},
                   explanation=f'no summon in the control; {value["summons"]:g} in the treatment, '
                               f'{value["start summon to enemy"]:.2f} yd from the enemy at the move; the enemy ran '
                               f'{enemy_moved:.2f} yd and the summon {followed:.2f} yd after it (at least '
                               f'{floor:.2f}), ending {reach:.2f} yd from it against at most {expected:g}: {status}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return summon_chase_scenario(class_file, summon_chase_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'run')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: summon_chase_verdict}
METRIC_EVIDENCE = {DISTANCE: 'event'}
