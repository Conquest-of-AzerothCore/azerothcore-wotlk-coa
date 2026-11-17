from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from bonus import bonus_band
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, GCD_WAIT_MS, TARGET, dataset, facts_of

KIND = 'last_application_expiry'
ORDER = 22

LAST_APPLICATION_STEP_OVERHEAD_MS = 9
ARMS = ('control', 'treatment')


@dataclass(frozen=True)
class LastApplicationSpec:
    spell: int
    name: str
    quote: str
    gate_spell: int
    trigger_spell: int
    aura: int
    expected_ms: int
    control_window_ms: int
    window_ms: int
    trigger_power: int | None = None
    poll_ms: int = 50
    label_suffix: str = 'last_application_expiry'


def last_application_spec(entry: dict) -> LastApplicationSpec:
    spec = LastApplicationSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['gate_spell']),
                               int(entry['trigger_spell']), int(entry['aura']), int(entry['expected_ms']),
                               int(entry['control_window_ms']), int(entry['window_ms']),
                               int(entry['trigger_power']) if entry.get('trigger_power') is not None else None,
                               int(entry.get('poll_ms', 50)), entry.get('label_suffix', 'last_application_expiry'))
    if spec.poll_ms < 10 or spec.expected_ms <= 0 or spec.window_ms <= spec.expected_ms + bonus_band(spec.expected_ms):
        raise ValueError(f'{spec.spell} last_application_expiry polls at least every 10 ms over a window longer than '
                         f'the stated duration and its band')
    if spec.control_window_ms < spec.poll_ms:
        raise ValueError(f'{spec.spell} last_application_expiry needs a control window of at least one poll')
    return spec


def last_application_label(spec: LastApplicationSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def last_application_scenario(class_file: dict, spec: LastApplicationSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.expected_ms))
    facts = facts_of(records, spec.trigger_spell)
    reads = {}

    def arm(name: str, window_ms: int) -> list[dict]:
        power = spec.trigger_power if spec.trigger_power is not None else facts.mana_cost
        steps = [{'action': 'wait', 'label': f'{name} before the cast', 'ms': GCD_WAIT_MS},
                 {'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power},
                 {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
                 {'action': 'select', 'actor': CASTER, 'target': TARGET},
                 {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET}]
        rows, elapsed = [], 0
        while elapsed <= window_ms:
            index = len(rows)
            row = [last_application_label(spec, f'{name} {index} {read}') for read in ('time', 'applied', 'aura')]
            steps += [measurement(row[0], CASTER, 'game_time_ms'),
                      measurement(row[1], TARGET, 'aura_apply_count', spell=spec.aura),
                      measurement(row[2], TARGET, 'aura', spell=spec.aura),
                      {'action': 'wait', 'label': f'{name} poll', 'ms': spec.poll_ms}]
            rows.append(row)
            elapsed += spec.poll_ms + LAST_APPLICATION_STEP_OVERHEAD_MS
        reads[name] = rows
        return steps

    steps = (base_steps(class_file) + arm(ARMS[0], spec.control_window_ms)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.gate_spell, spec.trigger_spell))]
             + arm(ARMS[1], spec.window_ms))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour last application expiry',
        'contract': (f'{spec.trigger_spell} cast at the dummy before {spec.gate_spell} is learned (control: refused, '
                     f'no {spec.aura}) and after it; every {spec.poll_ms} ms the game time, the dummy\'s '
                     f'{spec.aura} application count (every new aura and every refresh) and its presence are read. '
                     f'The last application lies between the two reads where the count last rises; from there the '
                     f'aura must be gone after {spec.expected_ms} ms, the stamped bracket inside the G-19 band.'),
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'aura_apply_count', 'quote': entry.quote, 'reads': reads,
             'expected': spec.expected_ms}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.aura, None, str(spec.expected_ms), prose_rule(entry.quote, spec.spell),
                              model)
    return timed(scenario, waited_ms(steps)), [expectation]


def last_application_bracket(rows: list[tuple[float, float, float]]) -> tuple[float, float] | str:
    rises = [index for index in range(1, len(rows)) if rows[index][1] > rows[index - 1][1]]
    if not rises:
        return 'no application is seen after the cast'
    last = rises[-1]
    if not rows[last][2]:
        return 'the aura is absent at the read of its last application'
    gone = next((index for index in range(last + 1, len(rows)) if not rows[index][2]), None)
    if gone is None:
        return f'the aura is still on {rows[-1][0] - rows[last][0]:g} ms after its last application'
    return rows[gone - 1][0] - rows[last][0], rows[gone][0] - rows[last - 1][0]


def last_application_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for rows in model['reads'].values() for row in rows for label in row]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    rows = {name: [tuple(run.values[label] for label in row) for row in model['reads'][name]] for name in ARMS}
    expected = float(model['expected'])
    band = bonus_band(expected)
    control = rows['control']
    if control[-1][1] != control[0][1] or any(present for _, _, present in control):
        return replace(base, status='alert', explanation='the control arm applied the aura without the gate')
    bracket = last_application_bracket(rows['treatment'])
    if isinstance(bracket, str):
        held = rows['treatment'][-1][0] - rows['treatment'][0][0]
        status = 'alert' if bracket.startswith('the aura is still on') and held > expected + band else 'unmeasured'
        return replace(base, status=status, explanation=f'treatment: {bracket}')
    low, high = bracket
    applications = rows['treatment'][-1][1] - rows['treatment'][0][1]
    if expected - band <= low and high <= expected + band:
        status = 'ok'
    elif high < expected - band or low > expected + band:
        status = 'alert'
    else:
        status = 'unmeasured'
    return replace(base, status=status, measured=(low + high) / 2, expected=expected, low=expected - band,
                   high=expected + band,
                   explanation=f'{applications:g} applications; the aura lasted between {low:g} and {high:g} ms after '
                               f'the last one against {expected:g} +- {band:g} (stamped game time); control: none')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return last_application_scenario(class_file, last_application_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'last_application_expiry')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: last_application_verdict}
