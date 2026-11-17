from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import AFTER, BEFORE, BEHAVIOUR_METRIC_DELTA, LEARNED_CONTRAST, behaviour_entry, prose_rule
from compare import Run, Verdict, exact, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset, facts_of

KIND = 'strike_bursts'
ORDER = 2


@dataclass(frozen=True)
class StrikeBurstsSpec:
    spell: int
    name: str
    quote: str
    command: int
    entry: int
    stances: tuple[int, int]
    arms: tuple[tuple[str, int, int, int, int], ...]
    distance: float = 6.0
    power: int = 1000
    summon_wait_ms: int = 3100
    burst_delay_ms: int = 500
    window_ms: int = 25
    stance_wait_ms: int = 3500


def strike_bursts_spec(entry: dict) -> StrikeBurstsSpec:
    arms = tuple((arm['name'], int(arm['health_pct']), int(arm['cycles']), int(arm['low']), int(arm['high']))
                 for arm in entry['arms'])
    return StrikeBurstsSpec(entry['spell'], entry['name'], entry['quote'], entry['command'], entry['entry'],
                            tuple(entry['stances']), arms, float(entry.get('distance', 6.0)),
                            int(entry.get('power', 1000)), int(entry.get('summon_wait_ms', 3100)))


def strike_bursts_label(spec: StrikeBurstsSpec, arm: str, cycle: int, moment: str) -> str:
    return f'{spec.spell} strike_bursts {arm} {cycle} {moment}'


def strike_bursts_scenario(class_file: dict, spec: StrikeBurstsSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'strike_bursts', spec.quote, 0.0)
    pacify, resume = spec.stances
    healths = [health for _, health, _, _, _ in spec.arms]
    if healths != sorted(healths, reverse=True) or any(not 0 < health <= 100 for health in healths):
        raise ValueError(f'{spec.spell} strike_bursts arms lower the target health from arm to arm')
    if any(not 0 < low <= high or cycles < 1 for _, _, cycles, low, high in spec.arms):
        raise ValueError(f'{spec.spell} strike_bursts arms need cycles and a count range')
    read = {'entry': spec.entry}

    def command() -> list[dict]:
        return [{'action': 'set_power', 'actor': CASTER, 'power': facts_of(records, spec.command).power_type,
                 'value': spec.power},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.command},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.command, 'target': TARGET}]

    def stance(spell: int) -> list[dict]:
        return [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': CASTER},
                {'action': 'wait', 'ms': spec.stance_wait_ms}]

    control = f'{spec.spell} strike_bursts absent after'
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in (spec.spell, spec.command, pacify, resume)]
             + command() + [{'action': 'wait', 'ms': spec.burst_delay_ms + spec.window_ms},
                            measurement(control, CASTER, 'owned_creature_damage_count', **read)]
             + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': CASTER},
                {'action': 'wait', 'label': 'raise settle', 'ms': spec.summon_wait_ms}]
             + stance(resume))
    arms = []
    for name, health, cycles, low, high in spec.arms:
        steps.append({'action': 'set_health_pct', 'actor': CASTER, 'target': TARGET, 'pct': health})
        reads = []
        for cycle in range(1, cycles + 1):
            before, after = (strike_bursts_label(spec, name, cycle, moment) for moment in (BEFORE, AFTER))
            steps += command() + [
                {'action': 'wait', 'ms': spec.burst_delay_ms - spec.window_ms},
                measurement(before, CASTER, 'owned_creature_damage_count', **read),
                {'action': 'wait', 'ms': 2 * spec.window_ms},
                measurement(after, CASTER, 'owned_creature_damage_count', **read)] + stance(pacify) + stance(resume)
            reads.append([before, after])
        arms.append({'name': name, 'health_pct': health, 'low': low, 'high': high, 'reads': reads})
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour strike bursts',
        'contract': f'{spec.command} is cast at the dummy ({spec.distance:g} yd) with no minion (no hit), then '
                    f'{spec.spell} raises a creature {spec.entry}; each cycle casts {spec.command} at the dummy and '
                    f'reads the minion\'s hits {spec.window_ms} ms before and after {spec.burst_delay_ms} ms, then '
                    f'casts {pacify} and {resume} so the minion stops between cycles. Arms set the dummy\'s health '
                    f'percent: {[(name, health) for name, health, _, _, _ in spec.arms]}.',
        'players': [player_fixture(class_file)],
        'creatures': [{**creature_fixture(class_file), 'distance': spec.distance}],
        'steps': steps}
    timed(scenario, sum(step['ms'] for step in steps if step['action'] == 'wait'), MAX_ACCELERATED_SCENARIO_MS)
    model = {'kind': 'strike_bursts', 'metric': 'owned_creature_damage_count', 'contrast': LEARNED_CONTRAST,
             'quote': entry.quote}
    expectations = [Expectation(f'{spec.spell} behaviour_metric_delta bursts_absent', BEHAVIOUR_METRIC_DELTA,
                                spec.spell, spec.command, None, '0', prose_rule(entry.quote, spec.spell),
                                {**model, 'mode': 'absent', 'label': control})]
    for arm in arms:
        expectations.append(Expectation(f'{spec.spell} behaviour_metric_delta bursts_{arm["name"]}',
                                        BEHAVIOUR_METRIC_DELTA, spec.spell, spec.command, None,
                                        f'{arm["low"]}..{arm["high"]}', prose_rule(entry.quote, spec.spell),
                                        {**model, 'mode': 'range', **arm}))
    return scenario, expectations


def behaviour_strike_bursts_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    if model['mode'] == 'absent':
        value = run.values.get(model['label'])
        if value is None:
            return replace(base, explanation=missing_measurement(run, model['label']))
        return exact(base, float(value), 0.0, 'the minion hits read after the command with no minion raised')
    counts = []
    for before, after in model['reads']:
        if run.values.get(before) is None or run.values.get(after) is None:
            return replace(base, explanation=missing_measurement(run, before if run.values.get(before) is None
                                                                 else after))
        counts.append(int(round(run.values[after] - run.values[before])))
    low, high = int(model['low']), int(model['high'])
    inside = all(low <= count <= high for count in counts)
    ends = low in counts and high in counts
    status = 'ok' if inside and ends else 'alert'
    seen = {count: counts.count(count) for count in sorted(set(counts))}
    explanation = (f'{len(counts)} commands at {model["health_pct"]}% target health struck {seen} times each '
                   f'(count: commands); every count must lie in {low}..{high} and both {low} and {high} be seen')
    return replace(base, status=status, measured=float(min(counts)), expected=float(low), low=float(low),
                   high=float(high), explanation=explanation)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return strike_bursts_scenario(class_file, strike_bursts_spec(entry))


JUDGES = {BEHAVIOUR_METRIC_DELTA: behaviour_strike_bursts_verdict}
