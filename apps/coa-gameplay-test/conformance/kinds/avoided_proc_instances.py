from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Verdict, describe_failures, failure_reasons, missing_measurement
from hits import timed
import proc_avoided
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset, fixture_health_step

KIND = 'avoided_proc_instances'
ORDER = 53
INSTANCES, GAIN = 'instances', 'gain_per_instance'
ARMS = ('control', 'treatment')
DODGE, PARRY = 100, 0
GAIN_TOLERANCE = 0.0
TICK_MS = 100
FIELDS = {'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'gain_quote', 'proc_aura', 'cast_spell',
          'hit_spells', 'stack_aura', 'instances', 'power', 'power_value', 'striker_entry', 'strikers', 'striker_auras',
          'swing_ms', 'proc_windows', 'casts', 'cast_gap_ms', 'observe_source'}


@dataclass(frozen=True)
class AvoidedProcInstancesSpec:
    spell: int
    name: str
    quote: str
    gain_quote: str
    proc_aura: int
    cast_spell: int
    hit_spells: tuple[int, ...]
    stack_aura: int
    instances: int
    power: int
    power_value: int
    striker_entry: int
    strikers: int
    striker_auras: tuple[int, ...]
    swing_ms: int
    proc_windows: int
    casts: int
    cast_gap_ms: int
    label_suffix: str


def avoided_proc_instances_spec(entry: dict) -> AvoidedProcInstancesSpec:
    if set(entry) - FIELDS:
        raise ValueError(f'{entry["spell"]} {KIND} has unknown fields {sorted(set(entry) - FIELDS)}')
    spec = AvoidedProcInstancesSpec(
        int(entry['spell']), entry['name'], entry['quote'], entry['gain_quote'], int(entry['proc_aura']),
        int(entry['cast_spell']), tuple(int(spell) for spell in entry['hit_spells']), int(entry['stack_aura']),
        int(entry['instances']), int(entry['power']), int(entry['power_value']), int(entry['striker_entry']),
        int(entry['strikers']), tuple(int(spell) for spell in entry.get('striker_auras', ())), int(entry['swing_ms']),
        int(entry['proc_windows']), int(entry['casts']), int(entry['cast_gap_ms']), entry.get('label_suffix', KIND))
    if f'{spec.instances} instances' not in spec.quote:
        raise ValueError(f'{spec.spell} {KIND} quote {spec.quote!r} does not state {spec.instances} instances')
    if not spec.hit_spells or spec.instances < 2 or spec.proc_windows < 1 or spec.cast_gap_ms <= 0:
        raise ValueError(f'{spec.spell} {KIND} needs hit spells, at least 2 instances, proc windows and a cast gap')
    if spec.casts * len(spec.hit_spells) < spec.instances + len(spec.hit_spells):
        raise ValueError(f'{spec.spell} {KIND} {spec.casts} casts of {len(spec.hit_spells)} hits cannot pass '
                         f'{spec.instances} instances by a whole cast')
    proc_avoided.checked_trigger(avoided_entry(spec))
    return spec


def avoided_entry(spec: AvoidedProcInstancesSpec) -> dict:
    return {'aura': spec.spell, 'trigger': {'action': proc_avoided.AVOIDED, 'striker_entry': spec.striker_entry,
                                            'swing_ms': spec.swing_ms, 'dodge': DODGE, 'parry': PARRY,
                                            'strikers': spec.strikers, 'striker_auras': list(spec.striker_auras)}}


def mark(spec: AvoidedProcInstancesSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def cast_labels(spec: AvoidedProcInstancesSpec, arm: str, cast: int) -> dict[str, str]:
    return {read: mark(spec, f'{arm} {read} {cast}') for read in ('stacks', 'aura', 'time', 'value')} | {
        f'hits {spell}': mark(spec, f'{arm} hits {spell} {cast}') for spell in spec.hit_spells}


def cast_steps(spec: AvoidedProcInstancesSpec, arm: str) -> list[dict]:
    target = proc_avoided.striker_ids(avoided_entry(spec))[0]
    steps = []
    for cast in range(1, spec.casts + 1):
        labels = cast_labels(spec, arm, cast)
        steps += [fixture_health_step(CASTER, 100),
                  {'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0},
                  {'action': 'set_aura', 'actor': CASTER, 'spell': spec.stack_aura, 'stacks': 0},
                  {'action': 'set_power', 'actor': CASTER, 'power': spec.power, 'value': spec.power_value},
                  {'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': target},
                  {'action': 'wait', 'ms': spec.cast_gap_ms},
                  measurement(labels['stacks'], CASTER, 'aura_stacks', spell=spec.stack_aura),
                  measurement(labels['aura'], CASTER, 'aura', spell=spec.proc_aura),
                  measurement(labels['value'], CASTER, 'aura_script_value', spell=spec.proc_aura,
                              key=spec.proc_aura),
                  measurement(labels['time'], CASTER, 'game_time_ms')]
        steps += [measurement(labels[f'hits {spell}'], CASTER, 'spell_damage_count', spell=spell, target=target)
                  for spell in spec.hit_spells]
    return steps


def start_labels(spec: AvoidedProcInstancesSpec) -> dict[str, str]:
    return {read: mark(spec, f'start {read}') for read in ('aura', 'applies', 'remaining', 'time', 'value')}


def start_steps(spec: AvoidedProcInstancesSpec) -> list[dict]:
    labels, aura = start_labels(spec), {'spell': spec.proc_aura}
    return [measurement(labels['aura'], CASTER, 'aura', **aura),
            measurement(labels['applies'], CASTER, 'aura_apply_count', **aura),
            measurement(labels['remaining'], CASTER, 'aura_duration_ms', **aura),
            measurement(labels['value'], CASTER, 'aura_script_value', **aura, key=spec.proc_aura),
            measurement(labels['time'], CASTER, 'game_time_ms')]


def rule_text(spec: AvoidedProcInstancesSpec) -> str:
    return (f'{spec.proc_aura} is obtained by the real route ({spec.spell} learned, dodged swings until it '
            f'procs); then {spec.casts} casts of {spec.cast_spell} at a striker, with {spec.stack_aura} set to 0 and '
            f'the swings no longer avoided before each cast. The control arm makes the same casts before the learn: its '
            f'{spec.stack_aura} stacks per cast are the own gain g and {spec.proc_aura} never appears. Treatment extra '
            f'per cast = stacks - g. Gain per instance = the extra over the {spec.hit_spells} hits of the casts after '
            f'which {spec.proc_aura} is still held (every hit of such a cast was a counted instance), expected 1. '
            f'Instances = the summed extra / the measured gain, expected {spec.instances}; {spec.proc_aura} must be '
            f'held after a cast exactly while the counted instances are below that count. aura_script_value '
            f'{spec.proc_aura} is read as a readback only, never judged')


def avoided_proc_instances_scenario(class_file: dict, spec: AvoidedProcInstancesSpec
                                    ) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.instances))
    gain_entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.gain_quote, 1.0)
    avoided = avoided_entry(spec)
    steps = (base_steps(class_file) + proc_avoided.engage_steps(avoided) + cast_steps(spec, 'control')
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + proc_avoided.attempt_steps(avoided, spec.proc_windows, spec.swing_ms)
             + start_steps(spec) + cast_steps(spec, 'treatment')
             + [measurement(mark(spec, 'end applies'), CASTER, 'aura_apply_count', spell=spec.proc_aura)])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour avoided proc instances',
        'contract': (f'{spec.strikers} aggressive stationary strikers {spec.striker_entry} swing at the caster. '
                     f'{rule_text(spec)}. The run is void on a missing read, a refused cast, {spec.proc_aura} absent '
                     f'when the casts start, a new application of {spec.proc_aura} during the casts, {spec.proc_aura} '
                     f'gone by its duration rather than by instances, a control gain that differs between casts, or '
                     f'no held cast to measure the gain on.'),
        'players': [player_fixture(class_file)],
        'creatures': proc_avoided.striker_fixtures(class_file, avoided),
        'steps': steps}
    reads = {arm: [cast_labels(spec, arm, cast) for cast in range(1, spec.casts + 1)] for arm in ARMS}
    base_model = {'kind': KIND, 'metric': 'aura_stacks', 'instances': spec.instances, 'hit_spells': spec.hit_spells,
                  'reads': reads, 'start': start_labels(spec), 'end_applies': mark(spec, 'end applies'),
                  'rule': rule_text(spec)}
    expectations = [
        Expectation(mark(spec, INSTANCES), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.proc_aura, None,
                    str(spec.instances), prose_rule(entry.quote, spec.spell),
                    {**base_model, 'read': INSTANCES, 'quote': entry.quote, 'expected': float(spec.instances)}),
        Expectation(mark(spec, GAIN), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.proc_aura, None, '1',
                    prose_rule(gain_entry.quote, spec.spell),
                    {**base_model, 'read': GAIN, 'quote': gain_entry.quote, 'expected': 1.0})]
    return timed(scenario, waited_ms(steps)), expectations


def void(base: Verdict, why: str) -> Verdict:
    return replace(base, status='unmeasured', explanation=f'void: {why}')


def cast_rows(model: dict, values: dict, arm: str, hits_before: float = 0.0) -> list[dict]:
    rows = []
    for labels in model['reads'][arm]:
        hits = sum(values[labels[f'hits {spell}']] for spell in model['hit_spells'])
        rows.append({'stacks': values[labels['stacks']], 'aura': bool(values[labels['aura']]),
                     'time': values[labels['time']], 'hits': hits - hits_before, 'total_hits': hits})
        hits_before = hits
    return rows


def avoided_proc_instances_verdict(base: Verdict, run, model: dict) -> Verdict:
    labels = ([label for arm in model['reads'].values() for row in arm for label in row.values()]
              + list(model['start'].values()) + [model['end_applies']])
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    refused = '; '.join(f'{spell}: {describe_failures(reasons)}' for spell, reasons
                        in ((spell, failure_reasons(run, spell)) for spell in run.cast_failures) if reasons)
    if refused:
        return void(base, f'refused casts {refused}')
    values, start = run.values, {name: run.values[label] for name, label in model['start'].items()}
    control = cast_rows(model, values, 'control')
    treatment = cast_rows(model, values, 'treatment', control[-1]['total_hits'] if control else 0.0)
    if any(row['aura'] for row in control):
        return replace(base, measured=1.0, expected=0.0, explanation='the proc aura is held before the passive is '
                                                                     'learned')
    gains = {row['stacks'] for row in control}
    if len(gains) != 1:
        return void(base, f'the control gain per cast is not constant: {sorted(gains)}')
    own = gains.pop()
    if not start['aura']:
        return void(base, 'the proc aura is not held when the casts start (no proc in the dodge windows)')
    if values[model['end_applies']] != start['applies']:
        return void(base, 'the proc aura was applied again during the casts')
    extra = [row['stacks'] - own for row in treatment]
    held = [index for index, row in enumerate(treatment) if row['aura']]
    hits = sum(treatment[index]['hits'] for index in held)
    if not held or not hits:
        return void(base, 'no cast after which the proc aura is still held, so no gain per instance is measured')
    gain = sum(extra[index] for index in held) / hits
    notes = (f'own gain {own:g} per cast, extra per cast {[round(value, 3) for value in extra]}, held after casts '
             f'{[index + 1 for index in held]}, gain per instance {gain:g}, readback {start["value"]:g} at the start')
    if model['read'] == GAIN:
        status = 'ok' if abs(gain - 1.0) <= GAIN_TOLERANCE else 'alert'
        return replace(base, status=status, measured=gain, expected=1.0, low=1.0, high=1.0, explanation=notes)
    if gain <= 0:
        return void(base, f'no gain per instance to count instances with ({notes})')
    counted, cumulative = sum(extra) / gain, 0.0
    for index, row in enumerate(treatment):
        cumulative += extra[index] / gain
        if not row['aura'] and cumulative < model['instances'] - 1e-9 \
                and row['time'] - start['time'] >= start['remaining'] - TICK_MS:
            return void(base, f'the proc aura expired by its duration after cast {index + 1} ({notes})')
        if row['aura'] != (cumulative < model['instances'] - 1e-9):
            return replace(base, status='alert', measured=counted, expected=float(model['instances']),
                           explanation=f'after cast {index + 1} the aura is {"held" if row["aura"] else "gone"} at '
                                       f'{cumulative:g} counted instances ({notes})')
    status = 'ok' if counted == model['instances'] else 'alert'
    return replace(base, status=status, measured=counted, expected=float(model['instances']),
                   low=float(model['instances']), high=float(model['instances']),
                   explanation=f'{counted:g} instances counted ({notes})')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return avoided_proc_instances_scenario(class_file, avoided_proc_instances_spec(entry))


def label(entry: dict) -> list[str]:
    suffix = entry.get('label_suffix', KIND)
    return [f"{entry['spell']} behaviour_metric_delta {suffix} {read}" for read in (INSTANCES, GAIN)]


JUDGES = {BEHAVIOUR_METRIC_DELTA: avoided_proc_instances_verdict}
