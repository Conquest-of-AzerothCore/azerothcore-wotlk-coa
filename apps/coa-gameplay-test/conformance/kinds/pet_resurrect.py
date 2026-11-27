from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, OWN_CAST_CONTRAST, STRIKER, behaviour_entry, prose_rule, waited_ms
from compare import CONTRAST, Run, Verdict, missing_measurement
from hits import MAX_SCENARIO_MS, base_mana_steps, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import CAST_MARGIN_MS, DUMMY_ENTRY, Expectation, dataset, facts_of, pay_power_steps, required_aura_steps

KIND = 'pet_resurrect'
ORDER = 67
METRIC = 'pet_health'
DEFAULT_KILL_SPELL = 53273
DEFAULT_SUMMON_WAIT_MS = 2000
DEFAULT_KILL_WAIT_MS = 1500
DEFAULT_WAIT_MS = 1500
CASTER_SURVIVE_HEALTH = 100000
STRIKER_HEALTH = 1000000
STRIKER_DISTANCE = 3
MIN_WAIT_MS = 100
FIELDS = frozenset({'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'summon_spell', 'pet_entry',
                    'kill_spell', 'summon_wait_ms', 'kill_wait_ms', 'wait_ms', 'observe_source'})


@dataclass(frozen=True)
class PetResurrectSpec:
    spell: int
    name: str
    quote: str
    summon_spell: int
    pet_entry: int
    kill_spell: int = DEFAULT_KILL_SPELL
    summon_wait_ms: int = DEFAULT_SUMMON_WAIT_MS
    kill_wait_ms: int = DEFAULT_KILL_WAIT_MS
    wait_ms: int = DEFAULT_WAIT_MS
    label_suffix: str = KIND


def positive_int(value, field_name: str, spell: int) -> int:
    if type(value) is not int or value < 1:
        raise ValueError(f'{spell} {KIND} {field_name} must be a positive int, not {value!r}')
    return value


def pet_resurrect_spec(entry: dict) -> PetResurrectSpec:
    unknown = set(entry) - FIELDS
    if unknown:
        raise ValueError(f'{entry.get("spell")} {KIND} unknown fields {sorted(unknown)}')
    spell = positive_int(entry['spell'], 'spell', int(entry['spell']) if isinstance(entry.get('spell'), int) else 0)
    summon_spell = positive_int(entry['summon_spell'], 'summon_spell', spell)
    pet_entry = positive_int(entry['pet_entry'], 'pet_entry', spell)
    kill_spell = positive_int(entry.get('kill_spell', DEFAULT_KILL_SPELL), 'kill_spell', spell)
    waits = {}
    for field_name, default in (('summon_wait_ms', DEFAULT_SUMMON_WAIT_MS),
                                ('kill_wait_ms', DEFAULT_KILL_WAIT_MS),
                                ('wait_ms', DEFAULT_WAIT_MS)):
        value = entry.get(field_name, default)
        if type(value) is not int or value < MIN_WAIT_MS:
            raise ValueError(f'{spell} {KIND} {field_name} must be an int >= {MIN_WAIT_MS}, not {value!r}')
        waits[field_name] = value
    return PetResurrectSpec(spell, entry['name'], entry['quote'], summon_spell, pet_entry, kill_spell,
                            waits['summon_wait_ms'], waits['kill_wait_ms'], waits['wait_ms'],
                            entry.get('label_suffix', KIND))


def mark(spec: PetResurrectSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def cast_power_steps(class_file: dict, facts) -> list[dict]:
    power = base_mana_steps(class_file, facts)
    if not power and facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        return pay_power_steps(facts.power_type, facts.mana_cost)
    return power


def pet_resurrect_scenario(class_file: dict, spec: PetResurrectSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    summon_facts = facts_of(records, spec.summon_spell)
    facts = facts_of(records, spec.spell)
    reads = {
        'entry_summoned': mark(spec, 'entry summoned'),
        'health_summoned': mark(spec, 'health summoned'),
        'entry_dead': mark(spec, 'entry dead'),
        'health_dead': mark(spec, 'health dead'),
        'health_control': mark(spec, 'health control'),
        'cast_failure': mark(spec, 'cast failure'),
        'entry_after': mark(spec, 'entry after'),
        'health_after': mark(spec, 'health after'),
    }
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.summon_spell},
                {'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + cast_power_steps(class_file, summon_facts)
             + required_aura_steps(summon_facts)
             + [{'action': 'cast', 'actor': CASTER, 'spell': spec.summon_spell},
                {'action': 'wait', 'label': f'{KIND} summon settle',
                 'ms': summon_facts.cast_time_ms + spec.summon_wait_ms},
                measurement(reads['entry_summoned'], CASTER, 'pet_entry'),
                measurement(reads['health_summoned'], CASTER, METRIC),
                {'action': 'set_health', 'actor': CASTER, 'value': CASTER_SURVIVE_HEALTH,
                 'maximum': CASTER_SURVIVE_HEALTH},
                {'action': 'set_health', 'actor': CASTER, 'pet': True, 'value': 1},
                {'action': 'cast', 'actor': STRIKER, 'spell': spec.kill_spell},
                {'action': 'wait', 'label': f'{KIND} kill settle', 'ms': spec.kill_wait_ms},
                measurement(reads['entry_dead'], CASTER, 'pet_entry'),
                measurement(reads['health_dead'], CASTER, METRIC),
                {'action': 'wait', 'label': f'{KIND} dead control wait', 'ms': spec.wait_ms},
                measurement(reads['health_control'], CASTER, METRIC)]
             + cast_power_steps(class_file, facts)
             + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
             + required_aura_steps(facts)
             + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell},
                {'action': 'wait', 'label': f'{KIND} resurrect settle',
                 'ms': facts.cast_time_ms + spec.wait_ms + CAST_MARGIN_MS},
                measurement(reads['cast_failure'], CASTER, 'cast_failure', spell=spec.spell),
                measurement(reads['entry_after'], CASTER, 'pet_entry'),
                measurement(reads['health_after'], CASTER, METRIC)])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour pet resurrect',
        'contract': (f'Summons pet {spec.pet_entry} via {spec.summon_spell}, lowers its health to 1 and kills it '
                     f'with striker spell {spec.kill_spell} (verifying pet_entry == {spec.pet_entry} and '
                     f'pet_health == 0 before and after a {spec.wait_ms} ms no-cast control wait). Casting '
                     f'{spec.spell} must succeed (cast_failure == 0) and restore pet_health >= 1 on pet '
                     f'{spec.pet_entry}.'),
        'players': [player_fixture(class_file)],
        'creatures': [{'id': STRIKER, 'owner': CASTER, 'entry': DUMMY_ENTRY, 'level': class_file['level'],
                       'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE}],
        'steps': steps}
    model = {'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'spell': spec.spell,
             'summon_spell': spec.summon_spell, 'pet_entry': spec.pet_entry, 'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.spell, None, '1',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_SCENARIO_MS), [expectation]


def pet_resurrect_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    val = run.values
    order = ('entry_summoned', 'health_summoned', 'entry_dead', 'health_dead', 'health_control',
             'cast_failure', 'entry_after', 'health_after')
    missing = next((reads[key] for key in order if val.get(reads[key]) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    expected_pet = float(model['pet_entry'])
    got = {key: float(val[reads[key]]) for key in order}
    detail = {'metric': METRIC, CONTRAST: OWN_CAST_CONTRAST, **got}
    if (got['entry_summoned'] != expected_pet or got['health_summoned'] <= 0
            or got['entry_dead'] != expected_pet or got['health_dead'] != 0 or got['health_control'] != 0):
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'pet {expected_pet:g} did not reach a stable dead state before resurrect: {got}')
    if got['cast_failure'] != 0:
        return replace(base, status='alert', measured=got['health_after'], expected=1.0, detail=detail,
                       explanation=f'resurrect cast {model["spell"]} failed with cast_failure={got["cast_failure"]:g}')
    if got['entry_after'] != expected_pet or got['health_after'] < 1:
        return replace(base, status='alert', measured=got['health_after'], expected=1.0, detail=detail,
                       explanation=f'after {model["spell"]}, pet_entry={got["entry_after"]:g} (expected '
                                   f'{expected_pet:g}) and {METRIC}={got["health_after"]:g} (expected >= 1)')
    return replace(base, status='ok', measured=got['health_after'], expected=1.0, low=1.0, high=got['health_after'],
                   detail=detail,
                   explanation=f'pet {expected_pet:g} stayed dead ({METRIC} 0 -> 0 control) and returned alive '
                               f'({METRIC}={got["health_after"]:g}) after casting {model["spell"]}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return pet_resurrect_scenario(class_file, pet_resurrect_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: pet_resurrect_verdict}
