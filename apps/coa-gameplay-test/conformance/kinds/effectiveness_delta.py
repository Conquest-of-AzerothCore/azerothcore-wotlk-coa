from dataclasses import replace

from behaviours import BEHAVIOUR_METRIC_DELTA, metric_delta_scenario, metric_delta_spec
from compare import Run, Verdict, behaviour_metric_delta_verdict
from values import Expectation

KIND = 'effectiveness_delta'
ORDER = 27
EFFECTIVENESS_PREFIX = 'effectiveness_'
READ_METRICS = ('spell_power', 'stat')


def checked_entry(entry: dict) -> dict:
    if entry.get('metric') not in READ_METRICS:
        raise ValueError(f'{entry["spell"]} {KIND} reads {entry.get("metric")!r}, not one of {READ_METRICS}')
    if entry.get('gate_spell') is None or entry.get('gate_timing', 'between') != 'between':
        raise ValueError(f'{entry["spell"]} {KIND} learns its modifier gate_spell between the two casts')
    if not entry.get('cast_in_before', True) or entry.get('setup_only_after') or entry.get('trigger_only_after'):
        raise ValueError(f'{entry["spell"]} {KIND} casts the effect in both phases: without and with the modifier')
    return {**entry, 'kind': 'metric_delta'}


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    built, expectations = metric_delta_scenario(class_file, metric_delta_spec(checked_entry(entry)))
    return built, [replace(expectation, model={**expectation.model, 'kind': KIND, 'read_metric':
                                               expectation.model['metric'],
                                               'metric': EFFECTIVENESS_PREFIX + expectation.model['metric']})
                   for expectation in expectations]


def effectiveness_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return behaviour_metric_delta_verdict(base, run, {**model, 'kind': 'metric_delta', 'metric': model['read_metric']})


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta" + (f" {entry['label_suffix']}" if entry.get('label_suffix')
                                                          else '')]


JUDGES = {BEHAVIOUR_METRIC_DELTA: effectiveness_verdict}
METRIC_EVIDENCE = {EFFECTIVENESS_PREFIX + metric: 'state' for metric in READ_METRICS}
STATE_PROMISES = {EFFECTIVENESS_PREFIX + metric: r'effectiveness' for metric in READ_METRICS}
