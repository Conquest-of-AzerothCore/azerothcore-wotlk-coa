from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset

KIND = 'minion_crit_gate'
ORDER = 31

GATED_SHARE = 0.5
GATE_RATIO_LOW = 0.4
GATE_RATIO_HIGH = 0.75
MINIMUM_CRITS = 6
MOMENTS = ('before', 'after')


@dataclass(frozen=True)
class MinionCritGateSpec:
    spell: int
    name: str
    quote: str
    learn: tuple[int, ...]
    raises: tuple[tuple[int, int, int], ...]
    crit_aura: tuple[int, int]
    observe_spell: int
    observe_power: int
    cut_ms: int
    windows: int
    window_ms: int
    label_suffix: str = 'once_per_sec'


def minion_crit_gate_spec(entry: dict) -> MinionCritGateSpec:
    spec = MinionCritGateSpec(int(entry['spell']), entry['name'], entry['quote'],
                              tuple(int(spell) for spell in entry.get('learn', [])),
                              tuple((int(spell), int(creature), int(settle)) for spell, creature, settle
                                    in entry['raises']),
                              (int(entry['crit_aura'][0]), int(entry['crit_aura'][1])), int(entry['observe_spell']),
                              int(entry['observe_power']), int(entry['cut_ms']), int(entry['windows']),
                              int(entry['window_ms']), entry.get('label_suffix', 'once_per_sec'))
    if len({creature for _, creature, _ in spec.raises}) != 2 or len(spec.raises) != 2:
        raise ValueError(f'{spec.spell} minion_crit_gate raises two minions of distinct entries')
    if spec.cut_ms <= 0 or spec.windows < 1 or not 2000 <= spec.window_ms <= 8000:
        raise ValueError(f'{spec.spell} minion_crit_gate needs a cut, a window and windows of 2000 to 8000 ms '
                         f'(the crit aura is refreshed each window)')
    return spec


def gate_label(spec: MinionCritGateSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def forced_crit_steps(spec: MinionCritGateSpec) -> list[dict]:
    aura, amount = spec.crit_aura
    return [step for _, creature, _ in spec.raises
            for owned in ({'action': 'set_aura', 'actor': CASTER, 'owned_entry': creature, 'spell': aura},)
            for step in ({**owned, 'stacks': 0}, {**owned, 'stacks': 1, 'amount': amount})]


def minion_crit_gate_scenario(class_file: dict, spec: MinionCritGateSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, GATED_SHARE)
    creatures = [creature for _, creature, _ in spec.raises]
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((*spec.learn, *(spell for spell, _, _ in spec.raises), spec.observe_spell,
                                            spec.spell))])
    for spell, creature, settle in spec.raises:
        steps += hit_ratio_cast(records, spell, CASTER, CASTER)
        steps.append({'action': 'wait', 'label': 'raise settle', 'ms': settle})
        steps.append({'action': 'assert', 'label': f'SETUP: the {creature} minion is raised', 'actor': CASTER,
                      'metric': 'owned_creature_count', 'entry': creature, 'equals': 1})
    steps.append({'action': 'attack', 'actor': CASTER, 'target': TARGET})
    windows = []
    for index in range(spec.windows):
        reads = {moment: [gate_label(spec, f'{index} {moment} {read}')
                          for read in ('time', 'cooldown', *(f'crits {creature}' for creature in creatures))]
                 for moment in MOMENTS}
        steps += forced_crit_steps(spec)
        steps += hit_ratio_cast(records, spec.observe_spell, CASTER, CASTER, spec.observe_power)[:-1]
        for moment in MOMENTS:
            time, cooldown, *crits = reads[moment]
            steps += [measurement(time, CASTER, 'game_time_ms'),
                      measurement(cooldown, CASTER, 'cooldown_ms', spell=spec.observe_spell)]
            steps += [measurement(label, CASTER, 'pet_melee_crits', entry=creature)
                      for label, creature in zip(crits, creatures)]
            if moment == 'before':
                steps.append({'action': 'wait', 'label': 'crit window', 'ms': spec.window_ms})
        windows.append(reads)
    steps.append({'action': 'stop_attack', 'actor': CASTER})
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour minion crit gate',
        'contract': (f'With {spec.spell} learned, creatures {creatures[0]} and {creatures[1]} are raised and attack '
                     f'the dummy with the caster; aura {spec.crit_aura[0]} at amount {spec.crit_aura[1]} makes both '
                     f'crit. In each of {spec.windows} windows {spec.observe_spell} is cast, then its cooldown, the '
                     f'game time and each minion\'s melee crits are read before and after {spec.window_ms} ms. The '
                     f'cooldown removed beyond the elapsed time, in units of {spec.cut_ms} ms, counts the accepted '
                     f'crits; against all crits they stand near {GATED_SHARE:g} (two minions swinging together, one '
                     f'cut per second), between {GATE_RATIO_LOW:g} and {GATE_RATIO_HIGH:g}; 1.0 is an ungated cut.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'pet_melee_crits', 'quote': entry.quote, 'windows': windows, 'cut_ms': spec.cut_ms,
             'expected': GATED_SHARE}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.spell, None, f'{GATED_SHARE:g}', prose_rule(entry.quote, spec.spell),
                              model)
    return timed(scenario, waited_ms(steps)), [expectation]


def minion_crit_gate_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for window in model['windows'] for row in window.values() for label in row]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    removed_ms, crits = 0.0, 0.0
    for window in model['windows']:
        before, after = ([run.values[label] for label in window[moment]] for moment in MOMENTS)
        if after[1] <= 0:
            return replace(base, status='unmeasured',
                           explanation='the observed cooldown ran out inside a window: the cuts are not all counted')
        removed_ms += (before[1] - after[1]) - (after[0] - before[0])
        crits += sum(after[2:]) - sum(before[2:])
    if crits < MINIMUM_CRITS:
        return replace(base, status='unmeasured', explanation=f'{crits:g} minion crits, under {MINIMUM_CRITS}')
    accepted = removed_ms / model['cut_ms']
    ratio = accepted / crits
    status = 'ok' if GATE_RATIO_LOW <= ratio <= GATE_RATIO_HIGH else 'alert'
    return replace(base, status=status, measured=ratio, expected=float(model['expected']), low=GATE_RATIO_LOW,
                   high=GATE_RATIO_HIGH,
                   explanation=f'{removed_ms:g} ms removed beyond the elapsed time ({accepted:.2f} cuts) for '
                               f'{crits:g} minion crits: {ratio:.3f} of the crits cut, against {GATE_RATIO_LOW:g} '
                               f'to {GATE_RATIO_HIGH:g}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return minion_crit_gate_scenario(class_file, minion_crit_gate_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'once_per_sec')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: minion_crit_gate_verdict}
