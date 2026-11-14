from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, GCD_WAIT_MS, TARGET, dataset, facts_of

KIND = 'corpse_per_raise'
ORDER = 24

CORPSE_STEP_OVERHEAD_MS = 9
CORPSE_MINIMUM_RAISES = 2
ARMS = ('control', 'treatment')


@dataclass(frozen=True)
class CorpsePerRaiseSpec:
    spell: int
    name: str
    quote: str
    raise_spell: int
    corpse_entry: int
    death_ms: int
    control_window_ms: int
    window_ms: int
    cast_power: int | None = None
    poll_ms: int = 100
    label_suffix: str = 'corpse_per_raise'


def corpse_per_raise_spec(entry: dict) -> CorpsePerRaiseSpec:
    spec = CorpsePerRaiseSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['raise_spell']),
                              int(entry['corpse_entry']), int(entry['death_ms']), int(entry['control_window_ms']),
                              int(entry['window_ms']),
                              int(entry['cast_power']) if entry.get('cast_power') is not None else None,
                              int(entry.get('poll_ms', 100)), entry.get('label_suffix', 'corpse_per_raise'))
    if spec.poll_ms < 25 or spec.death_ms <= 0 or spec.window_ms <= spec.death_ms or spec.control_window_ms < 0:
        raise ValueError(f'{spec.spell} corpse_per_raise polls at least every 25 ms over a window longer than the '
                         f'time a raised creature takes to die')
    return spec


def corpse_label(spec: CorpsePerRaiseSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def corpse_per_raise_scenario(class_file: dict, spec: CorpsePerRaiseSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    facts = facts_of(records, spec.spell)
    reads = {}

    def arm(name: str, window_ms: int) -> list[dict]:
        power = spec.cast_power if spec.cast_power is not None else facts.mana_cost
        steps = [{'action': 'wait', 'label': f'{name} before the cast', 'ms': GCD_WAIT_MS},
                 {'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power},
                 {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell},
                 {'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': TARGET}]
        rows, elapsed = [], 0
        while elapsed <= window_ms:
            index = len(rows)
            row = [corpse_label(spec, f'{name} {index} {read}') for read in ('time', 'raises', 'corpses')]
            steps += [measurement(row[0], CASTER, 'game_time_ms'),
                      measurement(row[1], CASTER, 'spell_cast_count', spell=spec.raise_spell),
                      measurement(row[2], CASTER, 'nearby_creature_count', entry=spec.corpse_entry, dead=True),
                      {'action': 'wait', 'label': f'{name} poll', 'ms': spec.poll_ms}]
            rows.append(row)
            elapsed += spec.poll_ms + CORPSE_STEP_OVERHEAD_MS
        reads[name] = rows
        return steps

    steps = (base_steps(class_file) + arm(ARMS[0], spec.control_window_ms)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + arm(ARMS[1], spec.window_ms))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour corpse per raise',
        'contract': (f'{spec.spell} cast at the dummy before it is learned (control: refused) and after it; every '
                     f'{spec.poll_ms} ms the game time, the caster\'s {spec.raise_spell} casts and the dead '
                     f'{spec.corpse_entry} creatures in its phase within 60 yd are read. Every raise must leave one '
                     f'corpse: the corpses that appear over the window equal the raises cast up to {spec.death_ms} ms '
                     f'before its end, at least {CORPSE_MINIMUM_RAISES}.'),
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'nearby_creature_count', 'quote': entry.quote, 'reads': reads,
             'death_ms': spec.death_ms}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.raise_spell, None, '1', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def corpse_counts(rows: list[tuple[float, float, float]], death_ms: float) -> tuple[float, float]:
    settled = [row for row in rows if row[0] <= rows[-1][0] - death_ms]
    raises = (settled[-1][1] - rows[0][1]) if settled else 0.0
    corpses = sum(max(0.0, later[2] - earlier[2]) for earlier, later in zip(rows, rows[1:]))
    return raises, corpses


def corpse_per_raise_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for rows in model['reads'].values() for row in rows for label in row]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    rows = {name: [tuple(run.values[label] for label in row) for row in model['reads'][name]] for name in ARMS}
    death_ms = float(model['death_ms'])
    control = rows['control']
    if control[-1][1] != control[0][1] or any(row[2] for row in control):
        return replace(base, status='alert', explanation='the control arm raised or left corpses without the cast')
    raises, corpses = corpse_counts(rows['treatment'], death_ms)
    if raises < CORPSE_MINIMUM_RAISES:
        return replace(base, status='unmeasured', measured=raises,
                       explanation=f'{raises:g} raises settled inside the window, fewer than {CORPSE_MINIMUM_RAISES}')
    latest_raises = rows['treatment'][-1][1] - rows['treatment'][0][1]
    status = 'ok' if raises <= corpses <= latest_raises else 'alert'
    return replace(base, status=status, measured=corpses / raises, expected=1.0, low=1.0, high=latest_raises / raises,
                   explanation=f'{corpses:g} corpses appeared for {raises:g} settled raises ({latest_raises:g} in '
                               f'all); every raise must leave one corpse; control: none')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return corpse_per_raise_scenario(class_file, corpse_per_raise_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'corpse_per_raise')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: corpse_per_raise_verdict}
METRIC_EVIDENCE = {'nearby_creature_count': 'event'}
