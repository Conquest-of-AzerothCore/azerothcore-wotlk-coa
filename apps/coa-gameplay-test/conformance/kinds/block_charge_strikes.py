from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, STRIKER, MetricDeltaStrike, behaviour_entry, prose_rule,
                        striker_creature, waited_ms)
from compare import Run, Verdict, missing_measurement
from hits import timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import GCD_WAIT_MS, Expectation, dataset, facts_of

KIND = 'block_charge_strikes'
ORDER = 33
ARMS = ('control', 'treatment')
BLOCK_SPELL = 107
OFF_HAND_SLOT = 16
STRIKE_HEALTH = 50000
STRIKE_MAX_HEALTH = 100000
STRIKE_WAIT_MS = 300
EXTRA_STRIKES = 1


@dataclass(frozen=True)
class BlockChargeSpec:
    spell: int
    name: str
    quote: str
    aura: int
    effect: int
    shield: int | None
    strike_spell: int
    cast_power: int
    label_suffix: str
    require_block: bool = True
    striker_untriggered: bool = False
    striker_auras: tuple[int, ...] = ()


def block_charge_spec(entry: dict) -> BlockChargeSpec:
    require_block = entry.get('require_block', True)
    if type(require_block) is not bool:
        raise ValueError(f'{entry["spell"]} {KIND} require_block must be a boolean, not {require_block!r}')
    raw_shield = entry.get('shield')
    if require_block:
        if type(raw_shield) is not int or raw_shield <= 0:
            raise ValueError(f'{entry["spell"]} {KIND} needs a positive shield item id when require_block is true')
        shield = raw_shield
    else:
        if raw_shield is not None:
            raise ValueError(f'{entry["spell"]} {KIND} omits shield when require_block is false')
        shield = None
    striker_untriggered = entry.get('striker_untriggered', False)
    if type(striker_untriggered) is not bool:
        raise ValueError(f'{entry["spell"]} {KIND} striker_untriggered must be a boolean, not {striker_untriggered!r}')
    raw_auras = entry.get('striker_auras', [])
    if not isinstance(raw_auras, list) or not all(type(aura) is int and aura > 0 for aura in raw_auras) \
            or len(set(raw_auras)) != len(raw_auras):
        raise ValueError(f'{entry["spell"]} {KIND} striker_auras must be distinct positive spell ids, '
                         f'not {raw_auras!r}')
    cast_power = entry.get('cast_power', 0 if not require_block else None)
    if type(cast_power) is not int or cast_power < 0:
        raise ValueError(f'{entry["spell"]} {KIND} cast_power must be a non-negative integer, not {cast_power!r}')
    return BlockChargeSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['aura']),
                           int(entry.get('effect', 0)), shield, int(entry['strike_spell']),
                           cast_power, entry.get('label_suffix', KIND), require_block,
                           striker_untriggered, tuple(raw_auras))


def mark(spec: BlockChargeSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def expected_blocks(records: Records, spec: BlockChargeSpec) -> dict[str, int]:
    base = int(records.field('Spell', spec.aura, 'ProcCharges'))
    extra = int(records.single_value(spec.spell, spec.effect))
    if base < 1 or extra < 1:
        raise ValueError(f'{spec.spell} {KIND} needs ProcCharges on {spec.aura} and a positive extra count')
    return {ARMS[0]: base, ARMS[1]: base + extra}


def block_charge_scenario(class_file: dict, spec: BlockChargeSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    expected = expected_blocks(records, spec)
    aura = facts_of(records, spec.aura)
    count_key = 'blocked' if spec.require_block else 'hits'
    count_kwargs = {'blocked': True} if spec.require_block else {}
    cast_extra = {'triggered': False} if spec.striker_untriggered else {}

    def strikes(arm: str) -> list[dict]:
        steps = []
        for index in range(1, expected[arm] + EXTRA_STRIKES + 1):
            steps += [{'action': 'set_health', 'actor': CASTER, 'value': STRIKE_HEALTH,
                       'maximum': STRIKE_MAX_HEALTH},
                      {'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER, **cast_extra},
                      {'action': 'wait', 'label': f'{arm} strike {index}', 'ms': STRIKE_WAIT_MS},
                      measurement(mark(spec, f'{arm} {index} aura'), CASTER, 'aura', spell=spec.aura),
                      measurement(mark(spec, f'{arm} {index} {count_key}'), CASTER, 'spell_damage_count',
                                  spell=spec.strike_spell, caster=STRIKER, target=CASTER, **count_kwargs)]
        return steps

    def arm(name: str) -> list[dict]:
        avoidance = {'action': 'set_combat_avoidance',
                     'label': f'{name} forced blocks' if spec.require_block else f'{name} no avoidance',
                     'actor': CASTER, 'dodge': 0, 'parry': 0, 'block': 100 if spec.require_block else 0}
        power = ([{'action': 'set_power', 'actor': CASTER, 'power': aura.power_type, 'value': spec.cast_power}]
                 if spec.require_block or spec.cast_power > 0 else [])
        return ([avoidance] + power + [
                 {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.aura},
                 {'action': 'cast', 'actor': CASTER, 'spell': spec.aura, 'target': CASTER},
                 {'action': 'wait', 'label': f'{name} aura cast', 'ms': GCD_WAIT_MS},
                 measurement(mark(spec, f'{name} 0 aura'), CASTER, 'aura', spell=spec.aura),
                 measurement(mark(spec, f'{name} 0 {count_key}'), CASTER, 'spell_damage_count',
                             spell=spec.strike_spell, caster=STRIKER, target=CASTER, **count_kwargs)]
                + strikes(name)
                + [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura}])

    setup_spells = (BLOCK_SPELL, spec.aura) if spec.require_block else (spec.aura,)
    shield_steps = ([{'action': 'add_item', 'actor': CASTER, 'item': spec.shield},
                     {'action': 'equip', 'actor': CASTER, 'item': spec.shield, 'slot': OFF_HAND_SLOT}]
                    if spec.require_block else [])
    striker_aura_steps = [{'action': 'set_aura', 'actor': CASTER, 'target': STRIKER, 'caster': STRIKER,
                           'spell': aura_id, 'stacks': 1} for aura_id in spec.striker_auras]
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in setup_spells]
             + shield_steps
             + striker_aura_steps
             + arm(ARMS[0])
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + arm(ARMS[1]))
    if spec.require_block:
        contract = (f'Shield {spec.shield} equipped, block forced to 100% with dodge and parry at 0 (harness '
                    f'set_combat_avoidance block, owner ruling O-20). Each arm casts {spec.aura}, then a passive '
                    f'striker casts {spec.strike_spell} at the caster one strike at a time, and the aura and the '
                    f'blocked strike count are read after each strike: {spec.aura} must last {expected[ARMS[0]]} '
                    f'blocks before {spec.spell} is learned and {expected[ARMS[1]]} after (ProcCharges plus '
                    f'{spec.spell} Effect[{spec.effect}]). Every strike must be a blocked hit or the run is '
                    f'unmeasured.')
    else:
        striker_note = ''
        if spec.striker_untriggered:
            striker_note += ' untriggered'
        if spec.striker_auras:
            striker_note += f' with striker fixture auras {list(spec.striker_auras)}'
        contract = (f'Avoidance forced to 0 (dodge, parry and block 0 via harness set_combat_avoidance). Each arm '
                    f'casts {spec.aura}, then a passive striker casts {spec.strike_spell}{striker_note} at the caster '
                    f'one strike at a time, and the aura and landed strike count are read after each strike: '
                    f'{spec.aura} must last {expected[ARMS[0]]} hits before {spec.spell} is learned and '
                    f'{expected[ARMS[1]]} after (ProcCharges plus {spec.spell} Effect[{spec.effect}]). Every strike '
                    f'must land or the run is unmeasured.')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour block charge strikes',
        'contract': contract,
        'players': [player_fixture(class_file)],
        'creatures': [striker_creature(class_file, MetricDeltaStrike(spec.strike_spell, STRIKE_HEALTH,
                                                                     STRIKE_MAX_HEALTH))],
        'steps': steps}
    reads = {name: [{'aura': mark(spec, f'{name} {index} aura'), count_key: mark(spec, f'{name} {index} {count_key}')}
                    for index in range(expected[name] + EXTRA_STRIKES + 1)] for name in ARMS}
    model = {'kind': KIND, 'metric': 'aura', 'quote': entry.quote, 'expected': expected, 'reads': reads}
    if not spec.require_block:
        model['require_block'] = False
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura, None,
                              str(expected[ARMS[1]] - expected[ARMS[0]]), prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def block_charge_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [label for name in ARMS for read in model['reads'][name] for label in read.values()]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    require_block = model.get('require_block', True)
    count_key = 'blocked' if require_block else 'hits'
    noun = 'block' if require_block else 'hit'
    nouns = 'blocks' if require_block else 'hits'
    hit_desc = 'blocked hit' if require_block else 'landed hit'
    lasted, notes = {}, []
    for name in ARMS:
        reads = model['reads'][name]
        counts = [run.values[read[count_key]] for read in reads]
        auras = [run.values[read['aura']] for read in reads]
        notes.append(f'{name}: aura {auras}, {count_key} {counts}')
        if auras[0] != 1 or any(after - before != 1 for before, after in zip(counts, counts[1:])):
            return replace(base, status='unmeasured',
                           explanation=f'{name} needs the aura at the start and one {hit_desc} per strike: '
                                       f'{"; ".join(notes)}')
        gone = next((index for index, value in enumerate(auras) if value == 0), None)
        if gone is None or any(auras[gone:]):
            return replace(base, status='alert', explanation=f'{name}: the aura did not end on a {noun}: '
                                                             f'{"; ".join(notes)}')
        lasted[name] = gone
    expected = model['expected']
    ok = all(lasted[name] == expected[name] for name in ARMS)
    return replace(base, status='ok' if ok else 'alert', measured=float(lasted[ARMS[1]] - lasted[ARMS[0]]),
                   expected=float(expected[ARMS[1]] - expected[ARMS[0]]), detail=lasted,
                   explanation=f'{nouns} lasted {lasted} against {expected}: {"; ".join(notes)}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return block_charge_scenario(class_file, block_charge_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: block_charge_verdict}
