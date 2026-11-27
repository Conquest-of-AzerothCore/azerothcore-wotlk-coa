from dataclasses import dataclass, replace
from pathlib import Path
import struct

from behaviours import (BEHAVIOUR_CAST_COMBAT, CAST_COMBAT_RESURRECT_RESPONSE_OPCODE, CAST_COMBAT_RESURRECT_SETTLE_MS,
                        CAST_COMBAT_SETTLE_MS, CAST_GATE_WAIT_MS, RESURRECT_EFFECTS, behaviour_entry, prose_rule,
                        required_aura_steps, waited_ms)
from hits import base_mana_steps, creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import ALLY, CAST_MARGIN_MS, TARGET, Expectation, dataset, facts_of

KIND = 'peaceful_resurrect'
ORDER = 47

EFFECT_RESURRECT = 18
EFFECT_RESURRECT_NEW = 113
MIN_COA_CLASS = 12
MAX_COA_CLASS = 32
NOT_IN_COMBAT_ONLY_PEACEFUL = 0x10000000
SPELL_FAILED_AFFECTING_COMBAT = 1
NO_CAST_FAILURE = 0
READINGS = ('alive_unoffered', 'combat_peaceful', 'cast_failure_peaceful', 'alive_peaceful', 'health_peaceful',
            'mana_peaceful', 'combat_fighting', 'cast_failure_fighting', 'alive_fighting')
PERCENT_READINGS = ('max_health_peaceful', 'max_power_peaceful')
CLAIM_READINGS = {'health': ('alive_unoffered', 'cast_failure_peaceful', 'alive_peaceful', 'health_peaceful'),
                  'mana': ('alive_unoffered', 'cast_failure_peaceful', 'alive_peaceful', 'mana_peaceful'),
                  'refusal': ('combat_peaceful', 'cast_failure_peaceful', 'alive_peaceful', 'combat_fighting',
                              'alive_fighting', 'cast_failure_fighting')}
PERCENT_MAX_READING = {'health': ('health_peaceful', 'max_health_peaceful'),
                       'mana': ('mana_peaceful', 'max_power_peaceful')}
PRECONDITIONS = {'combat_peaceful': 0, 'combat_fighting': 1}


@dataclass(frozen=True)
class PeacefulResurrectSpec:
    spell: int
    name: str
    quote: str
    claims: tuple[tuple[str, str], ...]
    label_suffix: str
    combat_cast: int | None = None
    ally_class: int | None = None
    clamp_percent: bool = False


def peaceful_resurrect_spec(entry: dict) -> PeacefulResurrectSpec:
    claims = tuple((raw['claim'], raw.get('quote', entry['quote'])) for raw in entry['claims'])
    ally_class = entry.get('ally_class')
    if ally_class is not None and (type(ally_class) is not int or not MIN_COA_CLASS <= ally_class <= MAX_COA_CLASS):
        raise ValueError(f'{entry["spell"]} {KIND} ally_class must be a CoA class ({MIN_COA_CLASS}..{MAX_COA_CLASS}), '
                         f'not {ally_class!r}')
    clamp_percent = entry.get('clamp_percent', False)
    if type(clamp_percent) is not bool:
        raise ValueError(f'{entry["spell"]} {KIND} clamp_percent must be bool, not {clamp_percent!r}')
    spec = PeacefulResurrectSpec(entry['spell'], entry['name'], entry['quote'], claims,
                                 entry.get('label_suffix', 'peaceful'), entry.get('combat_cast'), ally_class,
                                 clamp_percent)
    names = [claim for claim, _ in spec.claims]
    if not names or len(set(names)) != len(names) or not set(names) <= set(CLAIM_READINGS):
        raise ValueError(f'{spec.spell} {KIND} needs distinct claims from {sorted(CLAIM_READINGS)}')
    return spec


def claim_label(spell: int, label_suffix: str, claim: str) -> str:
    return f'{spell} {BEHAVIOUR_CAST_COMBAT} {label_suffix} {claim}'


def resurrect_effect(records: Records, spell: int) -> tuple[int, int, int]:
    effect = next((index for index in range(3)
                   if records.field('Spell', spell, f'Effect[{index}]') in RESURRECT_EFFECTS), None)
    if effect is None:
        raise ValueError(f'{spell} {KIND} needs a SPELL_EFFECT_RESURRECT effect')
    effect_id = int(records.field('Spell', spell, f'Effect[{effect}]'))
    points = (int(records.field('Spell', spell, f'EffectBasePoints[{effect}]'))
              + int(records.field('Spell', spell, f'EffectDieSides[{effect}]') or 0))
    return effect_id, points, int(records.field('Spell', spell, f'EffectMiscValue[{effect}]'))


def resurrect_amounts(records: Records, spell: int) -> tuple[int, int]:
    _, health, mana = resurrect_effect(records, spell)
    return health, mana


def float32(value: float) -> float:
    return struct.unpack('<f', struct.pack('<f', value))[0]


def pct_expected(maximum: float, percent: int) -> int:
    return int(float32(float32(float32(maximum) * float32(float(percent))) / float32(100.0)))


def reading_label(spec: PeacefulResurrectSpec, reading: str) -> str:
    return f'{spec.spell} {KIND} {spec.label_suffix} {reading}'


def accept(label: str) -> list[dict]:
    return [{'action': 'client_packet', 'label': label, 'actor': ALLY, 'opcode': CAST_COMBAT_RESURRECT_RESPONSE_OPCODE,
             'fields': [{'actor_guid': CASTER}, {'u8': 1}], 'consumed': False},
            {'action': 'wait', 'ms': CAST_COMBAT_RESURRECT_SETTLE_MS}]


def peaceful_resurrect_scenario(class_file: dict, spec: PeacefulResurrectSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    for _, quote in spec.claims:
        behaviour_entry(records, spec.spell, spec.name, KIND, quote, float(SPELL_FAILED_AFFECTING_COMBAT))
    if not int(records.field('Spell', spec.spell, 'Attributes')) & NOT_IN_COMBAT_ONLY_PEACEFUL:
        raise ValueError(f'{spec.spell} {KIND} needs SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL')
    facts = facts_of(records, spec.spell)
    effect_id, health, mana = resurrect_effect(records, spec.spell)
    is_percent = effect_id == EFFECT_RESURRECT
    all_readings = READINGS + (PERCENT_READINGS if is_percent else ())
    label = {reading: reading_label(spec, reading) for reading in all_readings}

    def attempt() -> list[dict]:
        power = base_mana_steps(class_file, facts)
        if not power and facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            power = [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost}]
        return (power + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
                + [{**step, 'actor': CASTER} for step in required_aura_steps(facts)]
                + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': ALLY}])

    def engage() -> list[dict]:
        if spec.combat_cast is None:
            return [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                    {'action': 'wait', 'ms': CAST_COMBAT_SETTLE_MS}]
        engage_facts = facts_of(records, spec.combat_cast)
        recovery = int(records.field('Spell', spec.combat_cast, 'StartRecoveryTime') or 0)
        return (base_mana_steps(class_file, engage_facts)
                + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.combat_cast}]
                + [{**step, 'actor': CASTER} for step in required_aura_steps(engage_facts)]
                + [{'action': 'cast', 'actor': CASTER, 'spell': spec.combat_cast, 'target': TARGET},
                   {'action': 'wait', 'ms': max(CAST_COMBAT_SETTLE_MS,
                                                engage_facts.cast_time_ms + recovery + CAST_MARGIN_MS)}])

    learned = [spec.spell] + ([spec.combat_cast] if spec.combat_cast is not None else [])
    max_reads = ([measurement(label['max_health_peaceful'], ALLY, 'max_health'),
                  measurement(label['max_power_peaceful'], ALLY, 'max_power', power=0)]
                 if is_percent else [])
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned]
             + [{'action': 'die', 'actor': ALLY}]
             + accept('accept with no resurrection offered')
             + [measurement(label['alive_unoffered'], ALLY, 'alive'),
                measurement(label['combat_peaceful'], CASTER, 'combat')]
             + attempt()
             + [{'action': 'wait', 'ms': facts.cast_time_ms + CAST_GATE_WAIT_MS},
                measurement(label['cast_failure_peaceful'], CASTER, 'cast_failure', spell=spec.spell)]
             + accept('accept the resurrection out of combat')
             + [measurement(label['alive_peaceful'], ALLY, 'alive'),
                measurement(label['health_peaceful'], ALLY, 'health'),
                measurement(label['mana_peaceful'], ALLY, 'power', power=0)]
             + max_reads
             + [{'action': 'die', 'actor': ALLY}]
             + engage()
             + [measurement(label['combat_fighting'], CASTER, 'combat')]
             + attempt()
             + [{'action': 'wait', 'ms': CAST_GATE_WAIT_MS},
                measurement(label['cast_failure_fighting'], CASTER, 'cast_failure', spell=spec.spell),
                {'action': 'stop_attack', 'actor': CASTER}]
             + accept('accept after the refused cast in combat')
             + [measurement(label['alive_fighting'], ALLY, 'alive')])
    clamp_note = 'clamped to 100%' if spec.clamp_percent else 'unclamped'
    amount_text = (f'{health}% of max_health and {health}% of max_power ({clamp_note})' if is_percent
                   else f'{health} health and {mana} mana')
    ally = {**player_fixture(class_file), 'id': ALLY, 'allow_regeneration': False}
    if spec.ally_class is not None:
        ally['class'] = spec.ally_class
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour peaceful resurrect',
        'contract': (f'Out-of-combat and in-combat arms of {spec.spell} at a dead ally (SPELL_EFFECT_RESURRECT, '
                     f'SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL). The dead ally first sends the resurrection response '
                     f'with no offer (it stays dead). Out of combat (combat 0) the cast completes (cast_failure '
                     f'{NO_CAST_FAILURE} after its {facts.cast_time_ms} ms cast), the ally accepts and is alive with '
                     f'{amount_text} (regeneration off). The ally dies again, the caster '
                     + (f'casts {spec.combat_cast} at the dummy and waits past its global cooldown'
                        if spec.combat_cast is not None else 'attacks the dummy')
                     + f' (combat 1), and the same cast is refused with '
                     f'{SPELL_FAILED_AFFECTING_COMBAT} (SPELL_FAILED_AFFECTING_COMBAT); the ally\'s response finds no '
                     f'offer and it stays dead.'),
        'players': [player_fixture(class_file), ally],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    expected = {'alive_unoffered': 0, 'combat_peaceful': 0, 'cast_failure_peaceful': NO_CAST_FAILURE,
                'alive_peaceful': 1, 'health_peaceful': health, 'mana_peaceful': mana, 'combat_fighting': 1,
                'cast_failure_fighting': SPELL_FAILED_AFFECTING_COMBAT, 'alive_fighting': 0}
    expectations = []
    for claim, quote in spec.claims:
        if is_percent and claim in PERCENT_MAX_READING:
            value_reading, max_reading = PERCENT_MAX_READING[claim]
            fixed_readings = {reading: [label[reading], expected[reading]]
                              for reading in CLAIM_READINGS[claim][:-1]}
            percent_check = {'reading': value_reading, 'label': label[value_reading],
                             'max_label': label[max_reading], 'percent': health}
            if spec.clamp_percent:
                percent_check['clamp_percent'] = True
            model = {'kind': KIND, 'quote': quote, 'claim': claim, 'readings': fixed_readings,
                     'percent_check': percent_check}
            displayed = f'{health}%'
        else:
            model = {'kind': KIND, 'quote': quote, 'claim': claim,
                     'readings': {reading: [label[reading], expected[reading]] for reading in CLAIM_READINGS[claim]}}
            displayed = str(expected[CLAIM_READINGS[claim][-1]])
        expectations.append(Expectation(claim_label(spec.spell, spec.label_suffix, claim), BEHAVIOUR_CAST_COMBAT,
                                        spec.spell, spec.spell, None, displayed, prose_rule(quote, spec.spell), model))
    return timed(scenario, waited_ms(steps)), expectations


def peaceful_resurrect_verdict(base, run, model: dict):
    from compare import missing_measurement
    readings = model['readings']
    percent_check = model.get('percent_check')
    required_labels = [label for label, _ in readings.values()]
    if percent_check is not None:
        required_labels += [percent_check['label'], percent_check['max_label']]
    missing = next((label for label in required_labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    wrong = {reading: run.values[label] for reading, (label, expected) in readings.items()
             if abs(float(run.values[label]) - float(expected)) > 1e-9}
    unmet = sorted(reading for reading in wrong if reading in PRECONDITIONS)
    if unmet:
        read = ', '.join(f'{reading} {float(run.values[readings[reading][0]]):g} (needs {PRECONDITIONS[reading]})'
                         for reading in unmet)
        return replace(base, status='unmeasured', explanation=f'{read}: the arm did not reach its combat state, so '
                                                              f'the claim is not read')
    if percent_check is not None:
        maximum = float(run.values[percent_check['max_label']])
        percent = int(percent_check['percent'])
        measured = float(run.values[percent_check['label']])
        if maximum <= 0:
            return replace(base, status='unmeasured', measured=measured,
                           explanation=f'{percent_check["reading"]} cannot judge {percent}% against max {maximum:g}')
        expected_value = float(pct_expected(maximum, percent))
        if percent_check.get('clamp_percent'):
            expected_value = min(maximum, expected_value)
        if abs(measured - expected_value) > 1e-9:
            wrong[percent_check['reading']] = measured
        status = 'ok' if not wrong else 'alert'
        parts = [f'{reading} {float(run.values[label]):g} (expected {expected:g})'
                 for reading, (label, expected) in readings.items()]
        parts.append(f'{percent_check["reading"]} {measured:g} (expected {expected_value:g} = {percent}% of '
                     f'{maximum:g})')
        return replace(base, status=status, measured=measured, expected=expected_value, low=expected_value,
                       high=expected_value,
                       explanation=f'{", ".join(parts)}; every reading is compared exactly'
                                   + (f'; wrong: {sorted(wrong)}' if wrong else ''))
    final_label, final_expected = list(readings.values())[-1]
    measured = float(run.values[final_label])
    status = 'ok' if not wrong else 'alert'
    read = ', '.join(f'{reading} {float(run.values[label]):g} (expected {expected:g})'
                     for reading, (label, expected) in readings.items())
    return replace(base, status=status, measured=measured, expected=float(final_expected), low=float(final_expected),
                   high=float(final_expected),
                   explanation=f'{read}; every reading is compared exactly' + (f'; wrong: {sorted(wrong)}'
                                                                              if wrong else ''))


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return peaceful_resurrect_scenario(class_file, peaceful_resurrect_spec(entry))


def label(entry: dict) -> list[str]:
    return [claim_label(entry['spell'], entry.get('label_suffix', 'peaceful'), raw['claim']) for raw in entry['claims']]


JUDGES = {BEHAVIOUR_CAST_COMBAT: peaceful_resurrect_verdict}
