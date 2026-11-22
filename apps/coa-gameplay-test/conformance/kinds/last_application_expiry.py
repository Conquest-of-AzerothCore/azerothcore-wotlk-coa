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
    caster: bool = False
    repeat: tuple[int, int] | None = None
    no_refresh: bool = False
    forced_roll: int | None = None
    trigger_target: str = TARGET
    poll_before_cast: bool = False


AURA_HOLDERS = {False: TARGET, True: CASTER}


def last_application_spec(entry: dict) -> LastApplicationSpec:
    spec = LastApplicationSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['gate_spell']),
                               int(entry['trigger_spell']), int(entry['aura']), int(entry['expected_ms']),
                               int(entry['control_window_ms']), int(entry['window_ms']),
                               int(entry['trigger_power']) if entry.get('trigger_power') is not None else None,
                               int(entry.get('poll_ms', 50)), entry.get('label_suffix', 'last_application_expiry'),
                               entry.get('caster', False), repeat_of(entry.get('repeat')),
                               entry.get('no_refresh', False),
                               None if entry.get('forced_roll') is None else int(entry['forced_roll']),
                               entry.get('trigger_target', TARGET), entry.get('poll_before_cast', False))
    if spec.trigger_target not in (TARGET, CASTER):
        raise ValueError(f'{spec.spell} last_application_expiry casts its trigger at {TARGET} or {CASTER}')
    if not all(isinstance(flag, bool) for flag in (spec.caster, spec.no_refresh, spec.poll_before_cast)):
        raise ValueError(f'{spec.spell} last_application_expiry caster, no_refresh and poll_before_cast are true or '
                         f'false')
    if spec.no_refresh and spec.repeat is None:
        raise ValueError(f'{spec.spell} last_application_expiry judges no refresh only over repeated trigger casts')
    if spec.forced_roll is not None and spec.repeat is None:
        raise ValueError(f'{spec.spell} last_application_expiry forces the roll only over repeated trigger casts')
    if spec.repeat is not None and spec.repeat[0] * spec.repeat[1] >= spec.expected_ms:
        raise ValueError(f'{spec.spell} last_application_expiry repeats its trigger past the stated duration')
    if spec.poll_ms < 10 or spec.expected_ms <= 0 or spec.window_ms <= spec.expected_ms + bonus_band(spec.expected_ms):
        raise ValueError(f'{spec.spell} last_application_expiry polls at least every 10 ms over a window longer than '
                         f'the stated duration and its band')
    if spec.control_window_ms < spec.poll_ms:
        raise ValueError(f'{spec.spell} last_application_expiry needs a control window of at least one poll')
    return spec


def repeat_of(raw) -> tuple[int, int] | None:
    if raw is None:
        return None
    if not isinstance(raw, dict) or set(raw) != {'count', 'every_ms'} or not all(
            isinstance(raw[key], int) and not isinstance(raw[key], bool) and raw[key] > 0 for key in raw):
        raise ValueError(f'last_application_expiry repeat is {{"count": casts, "every_ms": ms}}, not {raw!r}')
    return raw['count'], raw['every_ms']


def last_application_label(spec: LastApplicationSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def last_application_scenario(class_file: dict, spec: LastApplicationSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.expected_ms))
    facts = facts_of(records, spec.trigger_spell)
    reads = {}

    def arm(name: str, window_ms: int) -> list[dict]:
        power = spec.trigger_power if spec.trigger_power is not None else facts.mana_cost
        cast = {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': spec.trigger_target}
        steps = [{'action': 'wait', 'label': f'{name} before the cast', 'ms': GCD_WAIT_MS},
                 {'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power},
                 {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
                 {'action': 'select', 'actor': CASTER, 'target': TARGET}]
        rows, elapsed = [], 0
        holder = AURA_HOLDERS[spec.caster]
        reads_of = ('time', 'applied', 'aura', 'stacks') if spec.no_refresh else ('time', 'applied', 'aura')
        recasts = [every * index for count, every in [spec.repeat or (0, 0)] for index in range(1, count)]

        def poll() -> list[dict]:
            row = [last_application_label(spec, f'{name} {len(rows)} {read}') for read in reads_of]
            rows.append(row)
            reads = [measurement(row[0], CASTER, 'game_time_ms'),
                     measurement(row[1], holder, 'aura_apply_count', spell=spec.aura),
                     measurement(row[2], holder, 'aura', spell=spec.aura)]
            return reads + ([measurement(row[3], holder, 'aura_stacks', spell=spec.aura)] if spec.no_refresh else [])

        if spec.no_refresh or spec.poll_before_cast:
            steps += poll()
        steps.append(cast)
        while elapsed <= window_ms:
            while recasts and recasts[0] <= elapsed:
                recasts.pop(0)
                if spec.forced_roll is not None:
                    steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power})
                steps.append(dict(cast))
            steps += poll() + [{'action': 'wait', 'label': f'{name} poll', 'ms': spec.poll_ms}]
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
    if spec.forced_roll is not None:
        from metric_delta_options import forced_roll
        forced_roll.fixtures(class_file, spec, forced_roll.ForcedRoll(spec.forced_roll), scenario)
    if spec.caster:
        scenario['contract'] += ' The aura is read on the caster, not the dummy.'
    if spec.trigger_target == CASTER:
        scenario['contract'] += f' {spec.trigger_spell} is cast at the caster, not the dummy.'
    if spec.repeat is not None:
        scenario['contract'] += (f' {spec.trigger_spell} is cast up to {spec.repeat[0]} times per arm (inside its '
                                 f'poll window), {spec.repeat[1]} ms apart.')
    if spec.poll_before_cast and not spec.no_refresh:
        scenario['contract'] += (' One poll precedes the cast, so an application at the cast itself is seen as a '
                                 'rise from that read.')
    if spec.no_refresh:
        scenario['contract'] += (' Its stack count is read at every poll, and one poll precedes the first cast: no '
                                 'refresh means one counted application while the stacks still rise, the duration '
                                 'timed from that first application.')
    model = {'kind': KIND, 'metric': 'aura_apply_count', 'quote': entry.quote, 'reads': reads,
             'expected': spec.expected_ms}
    if spec.no_refresh:
        model['no_refresh'] = True
    if spec.forced_roll is not None:
        from metric_delta_options import forced_roll
        model['forced_roll'] = {'talent': spec.forced_roll, 'released_label': forced_roll.released_label(spec)}
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


def no_refresh_reading(rows: list[tuple[float, ...]]) -> str:
    applications = rows[-1][1] - rows[0][1]
    stacks = max(row[3] for row in rows)
    if applications > 1:
        return f'alert: {applications:g} counted applications, so a later one refreshed or reapplied the aura'
    if stacks < 2:
        return f'unmeasured: the stacks reached {stacks:g}, so no later application was seen to keep the duration'
    return f'one counted application while the stacks rose to {stacks:g} (no refresh)'


def last_application_verdict(base, run, model: dict):
    verdict = last_application_reading(base, run, model)
    roll = model.get('forced_roll')
    if roll is None:
        return verdict
    released = run.values.get(roll['released_label'])
    fixture = f'forcing fixture: a {roll["talent"]} SPELLMOD_CHANCE_OF_SUCCESS spell modifier mutant'
    if released is None or released != 0:
        return replace(verdict, status='alert', explanation=f'{verdict.explanation}; {fixture}: the modifier is still '
                                                            f'active at the end ({released})')
    return replace(verdict, explanation=f'{verdict.explanation}; {fixture}, released at the end')


def last_application_reading(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for rows in model['reads'].values() for row in rows for label in row]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    rows = {name: [tuple(run.values[label] for label in row) for row in model['reads'][name]] for name in ARMS}
    expected = float(model['expected'])
    band = bonus_band(expected)
    control = rows['control']
    if control[-1][1] != control[0][1] or any(row[2] for row in control):
        return replace(base, status='alert', explanation='the control arm applied the aura without the gate')
    refresh = no_refresh_reading(rows['treatment']) if model.get('no_refresh') else ''
    if refresh.startswith('alert'):
        return replace(base, status='alert', explanation=f'treatment: {refresh[len("alert: "):]}')
    if refresh.startswith('unmeasured'):
        return replace(base, status='unmeasured', explanation=f'treatment: {refresh[len("unmeasured: "):]}')
    bracket = last_application_bracket([row[:3] for row in rows['treatment']])
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
                               f'the last one against {expected:g} +- {band:g} (stamped game time); control: none'
                               + (f'; {refresh}' if refresh else ''))


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return last_application_scenario(class_file, last_application_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'last_application_expiry')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: last_application_verdict}
