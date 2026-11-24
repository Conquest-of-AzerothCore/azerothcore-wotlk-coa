from dataclasses import dataclass, replace
from pathlib import Path
import struct

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from hits import timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset

KIND = 'move_under_aura'
ORDER = 50

MOVED_METRIC = 'move_under_aura_moved'
BLOCKED_METRIC = 'move_under_aura_blocked'
EXPECTS = ('moved', 'blocked')
MSG_MOVE_START_FORWARD = 0x0B5
MSG_MOVE_STOP = 0x0B7
MOVEMENTFLAG_FORWARD = 0x1
MOVE_MAP = 1
MOVE_ORIGIN = (2389.03, -6608.37, 125.192)
TELEPORT_SETTLE_MS = 2000
MOVE_SETTLE_MS = 500
STOP_SETTLE_MS = 300
AURA_SETTLE_MS = 300
POSITION_TOLERANCE_YD = 0.1
PHASES = ('control', 'aura')


@dataclass(frozen=True)
class MoveUnderAuraSpec:
    spell: int
    name: str
    quote: str
    aura: int
    step_yd: float = 2.0
    label_suffix: str = 'move'
    expect: str = 'moved'


def move_under_aura_spec(entry: dict) -> MoveUnderAuraSpec:
    spec = MoveUnderAuraSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry.get('aura', entry['spell'])),
                             float(entry.get('step_yd', 2.0)), entry.get('label_suffix', 'move'),
                             entry.get('expect', 'moved'))
    if spec.expect not in EXPECTS:
        raise ValueError(f'{spec.spell} move_under_aura expects one of {EXPECTS}, not {spec.expect!r}')
    if not 0.5 <= spec.step_yd <= 10:
        raise ValueError(f'{spec.spell} move_under_aura steps 0.5 to 10 yd, not {spec.step_yd:g}')
    return spec


def float_bits(value: float) -> int:
    return struct.unpack('<I', struct.pack('<f', value))[0]


def movement_packet(opcode: int, x: float, flags: int) -> dict:
    _, y, z = MOVE_ORIGIN
    return {'action': 'client_packet', 'label': f'movement {opcode}', 'actor': CASTER, 'opcode': opcode,
            'consumed': False,
            'fields': [{'packed_actor_guid': CASTER}, {'u32': flags}, {'u8': 0}, {'u8': 0}, {'u32': 0},
                       {'u32': float_bits(x)}, {'u32': float_bits(y)}, {'u32': float_bits(z)},
                       {'u32': float_bits(0.0)}, {'u32': 0}]}


def move_label(spec: MoveUnderAuraSpec, phase: str, moment: str, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {phase} {moment} {read}'


def phase_steps(spec: MoveUnderAuraSpec, phase: str, start_x: float) -> list[dict]:
    target_x = start_x + spec.step_yd

    def reads(moment: str) -> list[dict]:
        return [measurement(move_label(spec, phase, moment, 'x'), CASTER, 'position_x'),
                measurement(move_label(spec, phase, moment, 'aura'), CASTER, 'aura', spell=spec.aura)]

    return (reads('start') + [movement_packet(MSG_MOVE_START_FORWARD, target_x, MOVEMENTFLAG_FORWARD),
                              {'action': 'wait', 'label': f'{phase} moving', 'ms': MOVE_SETTLE_MS}]
            + reads('moved') + [movement_packet(MSG_MOVE_STOP, target_x, 0),
                                {'action': 'wait', 'label': f'{phase} stopped', 'ms': STOP_SETTLE_MS}]
            + reads('stopped'))


def move_under_aura_scenario(class_file: dict, spec: MoveUnderAuraSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    x, y, z = MOVE_ORIGIN
    steps = base_steps(class_file) + [
        {'action': 'teleport', 'actor': CASTER, 'map': MOVE_MAP, 'x': x, 'y': y, 'z': z, 'o': 0},
        {'action': 'wait', 'label': 'teleport settle', 'ms': TELEPORT_SETTLE_MS}]
    steps += phase_steps(spec, 'control', x)
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + hit_ratio_cast(records, spec.spell, CASTER,
                                                                                         CASTER)
    steps.append({'action': 'wait', 'label': 'aura settle', 'ms': AURA_SETTLE_MS})
    steps += phase_steps(spec, 'aura', x + spec.step_yd)
    blocked = spec.expect == 'blocked'
    outcome = (f'the position must stay where it was (the attempt is refused) while {spec.aura} is held at the '
               f'start, after the move and after the stop' if blocked else
               f'the position must move by the step and {spec.aura} must stay through the move and the stop')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour move under aura'
                + (' blocked' if blocked else ''),
        'contract': (f'The caster is teleported to map {MOVE_MAP} {MOVE_ORIGIN}. Control: without {spec.aura}, a '
                     f'MSG_MOVE_START_FORWARD packet {spec.step_yd:g} yd along x, then MSG_MOVE_STOP, go to the '
                     f'session\'s movement handler (client_packet, consumed false); the position must move by the '
                     f'step, which proves the packet moves the player. Then {spec.spell} is cast and the same move '
                     f'is sent while {spec.aura} is held: {outcome}. Positions within {POSITION_TOLERANCE_YD:g} yd.'),
        'players': [player_fixture(class_file)],
        'creatures': [],
        'steps': steps}
    model = {'kind': KIND, 'metric': BLOCKED_METRIC if blocked else MOVED_METRIC, 'quote': entry.quote,
             'step_yd': spec.step_yd,
             'reads': {phase: {moment: [move_label(spec, phase, moment, read) for read in ('x', 'aura')]
                               for moment in ('start', 'moved', 'stopped')} for phase in PHASES}}
    if blocked:
        model['expect'] = 'blocked'
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.spell, None, '0' if blocked else f'{spec.step_yd:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def move_under_aura_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for phase in model['reads'].values() for pair in phase.values() for label in pair]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    read = {phase: {moment: [run.values[label] for label in pair] for moment, pair in moments.items()}
            for phase, moments in model['reads'].items()}
    step = float(model['step_yd'])

    def moved(phase: str) -> float:
        return read[phase]['stopped'][0] - read[phase]['start'][0]

    control_moved, aura_moved = moved('control'), moved('aura')
    control_held = abs(control_moved - step) <= POSITION_TOLERANCE_YD and not any(
        aura for _, aura in read['control'].values())
    aura_states = [read['aura'][moment][1] for moment in ('start', 'moved', 'stopped')]
    text = (f'control moved {control_moved:g} yd without the aura, auras {[a for _, a in read["control"].values()]}; '
            f'under the aura moved {aura_moved:g} yd against {step:g}, aura {aura_states} at start, moved, stopped')
    blocked = model.get('expect') == 'blocked'
    expected = 0.0 if blocked else step
    if blocked:
        text = (f'attempt: own forward movement (MSG_MOVE_START_FORWARD then MSG_MOVE_STOP to the movement '
                f'handler); {text}; expected no movement under the aura')
    common = dict(measured=aura_moved, expected=expected, low=expected - POSITION_TOLERANCE_YD,
                  high=expected + POSITION_TOLERANCE_YD)
    if not control_held or not aura_states[0]:
        return replace(base, status='unmeasured', **common,
                       explanation=f'{text}; the control did not move the player by the step, or the aura was not '
                                   f'held before the move, so the arm does not discriminate')
    ok = abs(aura_moved - expected) <= POSITION_TOLERANCE_YD and all(aura_states)
    return replace(base, status='ok' if ok else 'alert', **common, explanation=text)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return move_under_aura_scenario(class_file, move_under_aura_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'move')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: move_under_aura_verdict}
METRIC_EVIDENCE = {MOVED_METRIC: 'event', BLOCKED_METRIC: 'event'}
