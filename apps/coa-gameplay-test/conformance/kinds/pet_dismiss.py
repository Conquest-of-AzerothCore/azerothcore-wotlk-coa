from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, OWN_CAST_CONTRAST, behaviour_entry, prose_rule, waited_ms
from compare import CONTRAST, Run, Verdict, missing_measurement
from hits import MAX_SCENARIO_MS, base_mana_steps, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import CAST_MARGIN_MS, Expectation, dataset, facts_of, pay_power_steps, required_aura_steps

KIND = 'pet_dismiss'
ORDER = 66
METRIC = 'pet_entry'
DEFAULT_SUMMON_WAIT_MS = 2000
DEFAULT_WAIT_MS = 1500
MIN_WAIT_MS = 100
FIELDS = frozenset({'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'summon_spell', 'pet_entry',
                    'summon_wait_ms', 'wait_ms', 'observe_source'})


@dataclass(frozen=True)
class PetDismissSpec:
    spell: int
    name: str
    quote: str
    summon_spell: int
    pet_entry: int
    summon_wait_ms: int = DEFAULT_SUMMON_WAIT_MS
    wait_ms: int = DEFAULT_WAIT_MS
    label_suffix: str = KIND


def positive_int(value, field_name: str, spell: int) -> int:
    if type(value) is not int or value < 1:
        raise ValueError(f'{spell} {KIND} {field_name} must be a positive int, not {value!r}')
    return value


def pet_dismiss_spec(entry: dict) -> PetDismissSpec:
    unknown = set(entry) - FIELDS
    if unknown:
        raise ValueError(f'{entry.get("spell")} {KIND} unknown fields {sorted(unknown)}')
    spell = positive_int(entry['spell'], 'spell', int(entry['spell']) if isinstance(entry.get('spell'), int) else 0)
    summon_spell = positive_int(entry['summon_spell'], 'summon_spell', spell)
    pet_entry = positive_int(entry['pet_entry'], 'pet_entry', spell)
    waits = {}
    for field_name, default in (('summon_wait_ms', DEFAULT_SUMMON_WAIT_MS), ('wait_ms', DEFAULT_WAIT_MS)):
        value = entry.get(field_name, default)
        if type(value) is not int or value < MIN_WAIT_MS:
            raise ValueError(f'{spell} {KIND} {field_name} must be an int >= {MIN_WAIT_MS}, not {value!r}')
        waits[field_name] = value
    return PetDismissSpec(spell, entry['name'], entry['quote'], summon_spell, pet_entry,
                          waits['summon_wait_ms'], waits['wait_ms'], entry.get('label_suffix', KIND))


def mark(spec: PetDismissSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def cast_power_steps(class_file: dict, facts) -> list[dict]:
    power = base_mana_steps(class_file, facts)
    if not power and facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        return pay_power_steps(facts.power_type, facts.mana_cost)
    return power


def pet_dismiss_scenario(class_file: dict, spec: PetDismissSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 0.0)
    summon_facts = facts_of(records, spec.summon_spell)
    facts = facts_of(records, spec.spell)
    reads = {
        'before': mark(spec, 'before'),
        'control': mark(spec, 'control'),
        'cast_failure': mark(spec, 'cast failure'),
        'after': mark(spec, 'after'),
    }
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.summon_spell},
                {'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + cast_power_steps(class_file, summon_facts)
             + required_aura_steps(summon_facts)
             + [{'action': 'cast', 'actor': CASTER, 'spell': spec.summon_spell},
                {'action': 'wait', 'label': f'{KIND} summon settle', 'ms': summon_facts.cast_time_ms + spec.summon_wait_ms},
                measurement(reads['before'], CASTER, METRIC),
                {'action': 'wait', 'label': f'{KIND} no-cast control wait', 'ms': spec.wait_ms},
                measurement(reads['control'], CASTER, METRIC)]
             + cast_power_steps(class_file, facts)
             + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
             + required_aura_steps(facts)
             + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell},
                {'action': 'wait', 'label': f'{KIND} dismiss settle',
                 'ms': facts.cast_time_ms + spec.wait_ms + (CAST_MARGIN_MS if facts.cast_time_ms else 0)},
                measurement(reads['cast_failure'], CASTER, 'cast_failure', spell=spec.spell),
                measurement(reads['after'], CASTER, METRIC)])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour pet dismiss',
        'contract': (f'Summons pet {spec.pet_entry} via {spec.summon_spell} and confirms {METRIC} == {spec.pet_entry} '
                     f'before and after a {spec.wait_ms} ms no-cast control wait. Casting {spec.spell} must succeed '
                     f'(cast_failure == 0) and leave {METRIC} == 0.'),
        'players': [player_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'spell': spec.spell,
             'summon_spell': spec.summon_spell, 'pet_entry': spec.pet_entry, 'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.spell, None, '0',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_SCENARIO_MS), [expectation]


def pet_dismiss_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    val = run.values
    missing = next((reads[key] for key in ('before', 'control', 'cast_failure', 'after')
                    if val.get(reads[key]) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    expected_pet = float(model['pet_entry'])
    before = float(val[reads['before']])
    control = float(val[reads['control']])
    cast_failure = float(val[reads['cast_failure']])
    after = float(val[reads['after']])
    detail = {'metric': METRIC, CONTRAST: OWN_CAST_CONTRAST, 'before': before, 'control': control,
              'cast_failure': cast_failure, 'after': after}
    if before != expected_pet or control != expected_pet:
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'pet {expected_pet:g} was not held before dismiss (before={before:g}, '
                                   f'control={control:g})')
    if cast_failure != 0:
        return replace(base, status='alert', measured=after, expected=0.0, detail=detail,
                       explanation=f'dismiss cast {model["spell"]} failed with cast_failure={cast_failure:g}')
    if after != 0:
        return replace(base, status='alert', measured=after, expected=0.0, detail=detail,
                       explanation=f'{METRIC} read {after:g} after casting {model["spell"]}, expected 0')
    return replace(base, status='ok', measured=0.0, expected=0.0, low=0.0, high=0.0, detail=detail,
                   explanation=f'{METRIC} stayed {expected_pet:g} through the no-cast control and dropped to 0 after '
                               f'casting {model["spell"]}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return pet_dismiss_scenario(class_file, pet_dismiss_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: pet_dismiss_verdict}
