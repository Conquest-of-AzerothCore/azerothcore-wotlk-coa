from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, missing_measurement
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset

KIND = 'energize_range'
ORDER = 12


ENERGIZE_RANGE_POLL_MS = 250
ENERGIZE_RANGE_RUNIC_POWER = 6


@dataclass(frozen=True)
class EnergizeRangeSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    energize_spell: int
    low: int
    high: int
    casts: int
    minimum_events: int
    polls_per_cast: int
    target_auras: tuple[tuple[int, int], ...] = ()
    caster_auras: tuple[tuple[int, int], ...] = ()
    label_suffix: str = ''


def energize_range_label(spec: EnergizeRangeSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA}' + (f' {spec.label_suffix}' if spec.label_suffix else '')


def energize_range_scenario(class_file: dict, spec: EnergizeRangeSpec) -> tuple[dict, list[Expectation]]:
    if not 0 < spec.low < spec.high or spec.casts < 1 or spec.polls_per_cast < 1 or spec.minimum_events < 1:
        raise ValueError(f'{spec.spell} energize_range needs 0 < low < high, casts, polls and a minimum event count')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'energize_range', spec.quote, float(spec.low))
    fields = {'spell': spec.energize_spell}
    marks = []

    def reads(mark: str) -> list[dict]:
        total, count = f'{energize_range_label(spec)} {mark} total', f'{energize_range_label(spec)} {mark} count'
        marks.append([total, count])
        return [measurement(total, CASTER, 'spell_energize_total', **fields),
                measurement(count, CASTER, 'spell_energize_count', **fields)]

    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell}] + reads('start')
    for cast in range(1, spec.casts + 1):
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                  for spell, stacks in spec.caster_auras]
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks, 'target': TARGET,
                   'caster': CASTER} for spell, stacks in spec.target_auras]
        steps += [{'action': 'set_power', 'actor': CASTER, 'power': ENERGIZE_RANGE_RUNIC_POWER, 'value': 0},
                  {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell},
                  {'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': TARGET}]
        for poll in range(1, spec.polls_per_cast + 1):
            steps += [{'action': 'wait', 'label': f'cast {cast} poll', 'ms': ENERGIZE_RANGE_POLL_MS}]
            steps += reads(f'{cast} {poll}')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour energize range'
                + (f' {spec.label_suffix}' if spec.label_suffix else ''),
        'contract': (f'{spec.casts} casts of {spec.cast_spell} at the dummy (fixtures {list(spec.caster_auras)} on the '
                     f'caster and {list(spec.target_auras)} on the dummy before each cast, Runic Power set to 0); the '
                     f'cumulative {spec.energize_spell} energize total and count are read every '
                     f'{ENERGIZE_RANGE_POLL_MS} ms; an interval holding exactly one energize event gives that event\'s '
                     f'amount. At least {spec.minimum_events} single events must be read, every amount must lie in '
                     f'{spec.low}..{spec.high}, and both ends must be seen.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'energize_range', 'metric': 'spell_energize_total', 'quote': entry.quote, 'marks': marks,
             'low': spec.low, 'high': spec.high, 'minimum_events': spec.minimum_events}
    expectation = Expectation(energize_range_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.energize_spell,
                              None, f'{spec.low}..{spec.high}', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def energize_range_spec(entry: dict) -> EnergizeRangeSpec:
    pairs = lambda raw: tuple((int(spell), int(stacks)) for spell, stacks in raw)
    return EnergizeRangeSpec(entry['spell'], entry['name'], entry['quote'], int(entry['cast_spell']),
                             int(entry['energize_spell']), int(entry['low']), int(entry['high']), int(entry['casts']),
                             int(entry['minimum_events']), int(entry.get('polls_per_cast', 14)),
                             pairs(entry.get('target_auras', ())), pairs(entry.get('caster_auras', ())),
                             entry.get('label_suffix', ''))


def behaviour_energize_range_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    readings = []
    for total_label, count_label in model['marks']:
        total, count = run.values.get(total_label), run.values.get(count_label)
        if total is None or count is None:
            return replace(base, explanation=missing_measurement(run, total_label if total is None else count_label))
        readings.append((total, count))
    amounts = [later[0] - earlier[0] for earlier, later in zip(readings, readings[1:]) if later[1] - earlier[1] == 1]
    low, high, needed = float(model['low']), float(model['high']), int(model['minimum_events'])
    if not amounts:
        return replace(base, status='unmeasured', explanation='no interval held exactly one energize event')
    lowest, highest = min(amounts), max(amounts)
    outside = [amount for amount in amounts if not low <= amount <= high]
    detail = {'events': len(amounts), 'min': lowest, 'max': highest}
    text = (f'{len(amounts)} single energize events (intervals holding exactly one), amounts {lowest:g} to '
            f'{highest:g} against the roll {low:g}..{high:g}')
    if outside:
        return replace(base, status='alert', measured=lowest, expected=low, low=low, high=high, detail=detail,
                       explanation=f'{text}; {len(outside)} outside the roll')
    if len(amounts) < needed:
        return replace(base, status='unmeasured', measured=lowest, expected=low, low=low, high=high, detail=detail,
                       explanation=f'{text}; at least {needed} single events are needed')
    status = 'ok' if lowest == low and highest == high else 'alert'
    return replace(base, status=status, measured=lowest, expected=low, low=low, high=high, detail=detail,
                   explanation=f'{text}; both ends must be seen in {needed} or more events: '
                               + ('both seen' if status == 'ok' else 'an end was not reached'))


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return energize_range_scenario(class_file, energize_range_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta"
            + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')]


JUDGES = {BEHAVIOUR_METRIC_DELTA: behaviour_energize_range_verdict}
