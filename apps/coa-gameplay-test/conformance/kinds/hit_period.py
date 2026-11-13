from dataclasses import dataclass
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from bonus import bonus_band
from cast_period import cast_period_label
from hits import creature_fixture, timed
from kinds.aura_window import AURA_WINDOW_STEP_OVERHEAD_MS
from kinds.pulse_targets import PULSE_TARGETS_METRIC
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset, facts_of

KIND = 'hit_period'
ORDER = 11


@dataclass(frozen=True)
class HitPeriodSpec:
    spell: int
    name: str
    quote: str
    trigger_spell: int
    hit_spell: int
    expected_ms: int
    window: tuple[int, int]
    fixtures: tuple[tuple[int, str], ...] = ()
    poll_ms: int = 1
    label_suffix: str = 'hit_period'


def hit_period_spec(entry: dict) -> HitPeriodSpec:
    spec = HitPeriodSpec(entry['spell'], entry['name'], entry['quote'], int(entry['trigger_spell']),
                         int(entry['hit_spell']), int(entry['expected_ms']),
                         tuple(int(value) for value in entry['window']),
                         tuple((int(spell), str(on)) for spell, on in entry.get('fixtures', ())),
                         int(entry.get('poll_ms', 1)), entry.get('label_suffix', 'hit_period'))
    low, high = spec.window
    if not 0 <= low < high or high - low < 2 * spec.expected_ms:
        raise ValueError(f'{spec.spell} hit_period polls a window of at least two periods after the cast')
    return spec


def hit_period_scenario(class_file: dict, spec: HitPeriodSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'hit_period', spec.quote, float(spec.expected_ms))
    facts = facts_of(records, spec.trigger_spell)
    fixtures = [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': 1,
                 **({'target': on, 'caster': CASTER} if on != CASTER else {})} for spell, on in spec.fixtures]
    control = cast_period_label(spec, 'control')
    start = cast_period_label(spec, 'start')
    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}] + fixtures
             + [measurement(control, CASTER, PULSE_TARGETS_METRIC, spell=spec.hit_spell, target=TARGET),
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell}]
             + ([{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost}]
                if facts.mana_cost > 0 else [])
             + [measurement(start, CASTER, 'game_time_ms'),
                {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET}])
    low, high = spec.window
    gap = max(1, low - AURA_WINDOW_STEP_OVERHEAD_MS)
    steps.append({'action': 'wait', 'label': 'to the window', 'ms': gap})
    elapsed, reads = gap + AURA_WINDOW_STEP_OVERHEAD_MS, []
    while elapsed <= high:
        index = len(reads)
        row = [cast_period_label(spec, f'{index} time'), cast_period_label(spec, f'{index} hits')]
        steps += [measurement(row[0], CASTER, 'game_time_ms'),
                  measurement(row[1], CASTER, PULSE_TARGETS_METRIC, spell=spec.hit_spell, target=TARGET),
                  {'action': 'wait', 'label': 'hit period poll', 'ms': spec.poll_ms}]
        reads.append(row)
        elapsed += spec.poll_ms + AURA_WINDOW_STEP_OVERHEAD_MS
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour hit period',
        'contract': (f'{spec.trigger_spell} cast at the dummy (fixtures {list(spec.fixtures)}); the game time and the '
                     f'{spec.hit_spell} hits on the dummy are read every {spec.poll_ms} ms of wait over {spec.window} '
                     f'ms of game time after the cast; (last stamped hit - first stamped hit) / (hits - 1) must lie '
                     f'inside {spec.expected_ms} ms +- the G-19 band; no hit before the cast.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'cast_period', 'metric': PULSE_TARGETS_METRIC, 'quote': entry.quote,
             'expected_ms': spec.expected_ms, 'band_ms': bonus_band(float(spec.expected_ms)), 'reads': reads,
             'control_label': control, 'start_label': start}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.hit_spell, None, str(spec.expected_ms),
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return hit_period_scenario(class_file, hit_period_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta "
            f"{entry.get('label_suffix', 'hit_period')}"]
