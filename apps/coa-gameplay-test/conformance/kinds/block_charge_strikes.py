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
    shield: int
    strike_spell: int
    cast_power: int
    label_suffix: str


def block_charge_spec(entry: dict) -> BlockChargeSpec:
    return BlockChargeSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['aura']),
                           int(entry.get('effect', 0)), int(entry['shield']), int(entry['strike_spell']),
                           int(entry['cast_power']), entry.get('label_suffix', KIND))


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

    def strikes(arm: str) -> list[dict]:
        steps = []
        for index in range(1, expected[arm] + EXTRA_STRIKES + 1):
            steps += [{'action': 'set_health', 'actor': CASTER, 'value': STRIKE_HEALTH,
                       'maximum': STRIKE_MAX_HEALTH},
                      {'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
                      {'action': 'wait', 'label': f'{arm} strike {index}', 'ms': STRIKE_WAIT_MS},
                      measurement(mark(spec, f'{arm} {index} aura'), CASTER, 'aura', spell=spec.aura),
                      measurement(mark(spec, f'{arm} {index} blocked'), CASTER, 'spell_damage_count',
                                  spell=spec.strike_spell, caster=STRIKER, target=CASTER, blocked=True)]
        return steps

    def arm(name: str) -> list[dict]:
        return ([{'action': 'set_combat_avoidance', 'label': f'{name} forced blocks', 'actor': CASTER,
                  'dodge': 0, 'parry': 0, 'block': 100},
                 {'action': 'set_power', 'actor': CASTER, 'power': aura.power_type, 'value': spec.cast_power},
                 {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.aura},
                 {'action': 'cast', 'actor': CASTER, 'spell': spec.aura, 'target': CASTER},
                 {'action': 'wait', 'label': f'{name} aura cast', 'ms': GCD_WAIT_MS},
                 measurement(mark(spec, f'{name} 0 aura'), CASTER, 'aura', spell=spec.aura),
                 measurement(mark(spec, f'{name} 0 blocked'), CASTER, 'spell_damage_count', spell=spec.strike_spell,
                             caster=STRIKER, target=CASTER, blocked=True)]
                + strikes(name)
                + [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura}])

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (BLOCK_SPELL, spec.aura)]
             + [{'action': 'add_item', 'actor': CASTER, 'item': spec.shield},
                {'action': 'equip', 'actor': CASTER, 'item': spec.shield, 'slot': OFF_HAND_SLOT}]
             + arm(ARMS[0])
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + arm(ARMS[1]))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour block charge strikes',
        'contract': (f'Shield {spec.shield} equipped, block forced to 100% with dodge and parry at 0 (harness '
                     f'set_combat_avoidance block, owner ruling O-20). Each arm casts {spec.aura}, then a passive '
                     f'striker casts {spec.strike_spell} at the caster one strike at a time, and the aura and the '
                     f'blocked strike count are read after each strike: {spec.aura} must last {expected[ARMS[0]]} '
                     f'blocks before {spec.spell} is learned and {expected[ARMS[1]]} after (ProcCharges plus '
                     f'{spec.spell} Effect[{spec.effect}]). Every strike must be a blocked hit or the run is '
                     f'unmeasured.'),
        'players': [player_fixture(class_file)],
        'creatures': [striker_creature(class_file, MetricDeltaStrike(spec.strike_spell, STRIKE_HEALTH,
                                                                     STRIKE_MAX_HEALTH))],
        'steps': steps}
    reads = {name: [{'aura': mark(spec, f'{name} {index} aura'), 'blocked': mark(spec, f'{name} {index} blocked')}
                    for index in range(expected[name] + EXTRA_STRIKES + 1)] for name in ARMS}
    model = {'kind': KIND, 'metric': 'aura', 'quote': entry.quote, 'expected': expected, 'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura, None,
                              str(expected[ARMS[1]] - expected[ARMS[0]]), prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def block_charge_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [label for name in ARMS for read in model['reads'][name] for label in read.values()]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    lasted, notes = {}, []
    for name in ARMS:
        reads = model['reads'][name]
        blocked = [run.values[read['blocked']] for read in reads]
        auras = [run.values[read['aura']] for read in reads]
        notes.append(f'{name}: aura {auras}, blocked {blocked}')
        if auras[0] != 1 or any(after - before != 1 for before, after in zip(blocked, blocked[1:])):
            return replace(base, status='unmeasured',
                           explanation=f'{name} needs the aura at the start and one blocked hit per strike: '
                                       f'{"; ".join(notes)}')
        gone = next((index for index, value in enumerate(auras) if value == 0), None)
        if gone is None or any(auras[gone:]):
            return replace(base, status='alert', explanation=f'{name}: the aura did not end on a block: '
                                                             f'{"; ".join(notes)}')
        lasted[name] = gone
    expected = model['expected']
    ok = all(lasted[name] == expected[name] for name in ARMS)
    return replace(base, status='ok' if ok else 'alert', measured=float(lasted[ARMS[1]] - lasted[ARMS[0]]),
                   expected=float(expected[ARMS[1]] - expected[ARMS[0]]), detail=lasted,
                   explanation=f'blocks lasted {lasted} against {expected}: {"; ".join(notes)}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return block_charge_scenario(class_file, block_charge_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: block_charge_verdict}
