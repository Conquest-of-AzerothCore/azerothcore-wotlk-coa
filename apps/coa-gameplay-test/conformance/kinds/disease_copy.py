from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, dummy_fixture, dummy_id, prose_rule, waited_ms
from bonus import bonus_band
from hits import timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, GCD_WAIT_MS, dataset, facts_of

KIND = 'disease_copy'
ORDER = 41
COPY_METRIC = 'disease_copy'
SOURCE, COPY_TARGET, CONTROL_TARGET = dummy_id(1), dummy_id(0), dummy_id(2)
READ_SETTLE_MS = 300


@dataclass(frozen=True)
class DiseaseCopySpec:
    spell: int
    name: str
    quote: str
    disease: int
    infest: int
    duration_ms: int
    power_aura: tuple[int, int, int]
    disease_wait_ms: int = 1600
    copy_wait_ms: int = 4400
    mana: int = 1373
    label_suffix: str = 'copy'


def disease_copy_spec(entry: dict) -> DiseaseCopySpec:
    aura, effect, amount = (int(value) for value in entry['power_aura'])
    spec = DiseaseCopySpec(entry['spell'], entry['name'], entry['quote'], int(entry['disease']), int(entry['infest']),
                           int(entry['duration_ms']), (aura, effect, amount),
                           int(entry.get('disease_wait_ms', 1600)), int(entry.get('copy_wait_ms', 4400)),
                           int(entry.get('mana', 1373)), entry.get('label_suffix', 'copy'))
    if not 0 < spec.disease_wait_ms < spec.duration_ms or not 0 < spec.copy_wait_ms < spec.duration_ms:
        raise ValueError(f'{spec.spell} disease_copy waits inside the {spec.duration_ms} ms disease')
    if not 0 <= effect <= 2 or amount <= 0:
        raise ValueError(f'{spec.spell} disease_copy raises spell power through effect 0 to 2 by a positive amount')
    return spec


def read_label(spec: DiseaseCopySpec, read: str) -> str:
    return f'{spec.spell} {KIND} {spec.label_suffix} {read}'


READS = ('source_amount', 'source_before', 'source_refreshed', 'copy_aura', 'copy_amount', 'copy_duration',
         'source_at_copy', 'control_amount', 'virulency_time', 'infest_time', 'copy_time')


def disease_copy_scenario(class_file: dict, spec: DiseaseCopySpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.duration_ms))
    label = lambda read: read_label(spec, read)
    disease = lambda unit, read, metric: measurement(label(read), unit, metric, spell=spec.disease, caster=CASTER)

    def cast(spell: int, target: str) -> list[dict]:
        return [{'action': 'set_power', 'actor': CASTER, 'power': facts_of(records, spell).power_type,
                 'value': spec.mana},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': target}]

    aura, effect, amount = spec.power_aura
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (spec.disease, spec.spell, spec.infest)]
             + cast(spec.disease, SOURCE) + [{'action': 'wait', 'ms': spec.disease_wait_ms}]
             + [disease(SOURCE, 'source_amount', 'aura_amount'), disease(SOURCE, 'source_before', 'aura_duration_ms'),
                measurement(label('virulency_time'), CASTER, 'game_time_ms')]
             + cast(spec.spell, SOURCE) + [{'action': 'wait', 'ms': READ_SETTLE_MS}]
             + [disease(SOURCE, 'source_refreshed', 'aura_duration_ms'),
                {'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1, 'effect': effect, 'amount': amount},
                {'action': 'wait', 'ms': spec.copy_wait_ms},
                measurement(label('infest_time'), CASTER, 'game_time_ms')]
             + cast(spec.infest, COPY_TARGET) + [{'action': 'wait', 'ms': READ_SETTLE_MS}]
             + [measurement(label('copy_time'), CASTER, 'game_time_ms'),
                disease(COPY_TARGET, 'copy_aura', 'aura'), disease(COPY_TARGET, 'copy_amount', 'aura_amount'),
                disease(COPY_TARGET, 'copy_duration', 'aura_duration_ms'),
                disease(SOURCE, 'source_at_copy', 'aura_duration_ms')]
             + [{'action': 'wait', 'label': 'global cooldown before the control', 'ms': GCD_WAIT_MS}]
             + cast(spec.disease, CONTROL_TARGET) + [{'action': 'wait', 'ms': READ_SETTLE_MS}]
             + [disease(CONTROL_TARGET, 'control_amount', 'aura_amount')])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour disease copy',
        'contract': (f'{spec.disease} is cast at {SOURCE}, then {spec.spell} at {SOURCE} (the refresh and the copy); '
                     f'the caster\'s spell power is raised by aura {aura} (effect {effect} at {amount}), and '
                     f'{spec.copy_wait_ms} ms later {spec.infest} is cast at {COPY_TARGET}. The copy on '
                     f'{COPY_TARGET} must carry the source\'s amount from before the raise and the duration of the '
                     f'copy, {spec.duration_ms} ms, while a fresh {spec.disease} at {CONTROL_TARGET} after the raise '
                     f'carries a larger amount (the control) and the source runs on from the copy.'),
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}],
        'creatures': [dummy_fixture(0, class_file, 3.0), dummy_fixture(1, class_file, 5.0),
                      dummy_fixture(2, class_file, 7.0)],
        'steps': steps}
    model = {'kind': KIND, 'metric': COPY_METRIC, 'quote': entry.quote,
             'reads': {read: label(read) for read in READS}, 'duration_ms': spec.duration_ms}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.disease, None, str(spec.duration_ms),
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def disease_copy_verdict(base, run, model: dict):
    from compare import missing_measurement
    missing = next((label for label in model['reads'].values() if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    read = {name: float(run.values[label]) for name, label in model['reads'].items()}
    duration = float(model['duration_ms'])
    band = bonus_band(duration)
    since_copy = read['copy_time'] - read['infest_time']
    since_refresh = read['copy_time'] - read['virulency_time']
    expected = duration - since_copy
    if read['control_amount'] <= read['source_amount']:
        return replace(base, status='unmeasured',
                       explanation=f'the fresh cast after the raise carries {read["control_amount"]:g}, not more than '
                                   f'the source\'s {read["source_amount"]:g}: the raise did not separate the amounts')
    if abs((duration - since_refresh) - expected) <= band:
        return replace(base, status='unmeasured',
                       explanation=f'{since_refresh - since_copy:g} ms between the copy and the Infest do not separate '
                                   f'a kept duration from a source-following one inside +- {band:g} ms')
    checks = {
        'refreshed': read['source_refreshed'] > read['source_before'] and
        abs(read['source_refreshed'] - duration) <= band,
        'copied': read['copy_aura'] == 1,
        'power kept': read['copy_amount'] == read['source_amount'],
        'duration kept': abs(read['copy_duration'] - expected) <= band,
    }
    failed = [name for name, held in checks.items() if not held]
    return replace(base, status='alert' if failed else 'ok', measured=read['copy_duration'], expected=expected,
                   low=expected - band, high=expected + band,
                   explanation=(f'source {read["source_before"]:g} ms before the refresh, {read["source_refreshed"]:g} '
                                f'after; copy present {read["copy_aura"]:g}, amount {read["copy_amount"]:g} against '
                                f'the source {read["source_amount"]:g} and a fresh cast after the raise '
                                f'{read["control_amount"]:g}; copy duration {read["copy_duration"]:g} ms '
                                f'{since_copy:g} ms after the Infest against {expected:g} +- {band:g} (the source '
                                f'{read["source_at_copy"]:g})' + (f'; failed: {", ".join(failed)}' if failed else '')))


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return disease_copy_scenario(class_file, disease_copy_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'copy')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: disease_copy_verdict}
METRIC_EVIDENCE = {COPY_METRIC: 'event'}
