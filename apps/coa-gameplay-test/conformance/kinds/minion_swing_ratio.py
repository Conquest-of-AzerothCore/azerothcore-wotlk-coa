from dataclasses import dataclass
from pathlib import Path

from behaviours import BEHAVIOUR_HIT_RATIO, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset

KIND = 'minion_swing_ratio'
ORDER = 6


MINION_SWING_RATIO_RAISE_WAIT_MS = 3100
MINION_SWING_RATIO_MINIMUM_TRIALS = 2


@dataclass(frozen=True)
class MinionSwingRatioSpec:
    spell: int
    name: str
    quote: str
    raise_spell: int
    command_spell: int
    strike_spell: int
    entry: int
    expected: float
    trials: int = 20
    wait_ms: int = 3000
    command_power: int | None = None
    label_suffix: str = ''
    strike_flat: float = 0.0
    player_spell_power: int | None = None


def minion_swing_ratio_label(spec: MinionSwingRatioSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_HIT_RATIO}' + (f' {spec.label_suffix}' if spec.label_suffix else '')


def minion_swing_ratio_marks(spec: MinionSwingRatioSpec, arm: str, mark) -> tuple[str, str]:
    base = f'{minion_swing_ratio_label(spec)} {arm} {mark}'
    return f'{base} total', f'{base} count'


def minion_swing_ratio_scenario(class_file: dict, spec: MinionSwingRatioSpec) -> tuple[dict, list[Expectation]]:
    if spec.trials < MINION_SWING_RATIO_MINIMUM_TRIALS or spec.expected <= 0 or spec.wait_ms <= 0:
        raise ValueError(f'{spec.spell} minion_swing_ratio needs at least {MINION_SWING_RATIO_MINIMUM_TRIALS} '
                         f'trials, a positive expected ratio and a positive wait')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'minion_swing_ratio', spec.quote, spec.expected)
    strike = {'spell': spec.strike_spell, 'caster_entry': spec.entry, 'target': TARGET, 'critical': False,
              'blocked': False}
    weapon_label = f'{minion_swing_ratio_label(spec)} weapon_damage_min'

    def reads(mark) -> list[dict]:
        swing_total, swing_count = minion_swing_ratio_marks(spec, 'control', mark)
        strike_total, strike_count = minion_swing_ratio_marks(spec, 'treatment', mark)
        return [measurement(swing_total, CASTER, 'pet_melee_plain_damage', entry=spec.entry),
                measurement(swing_count, CASTER, 'pet_melee_plain_count', entry=spec.entry),
                measurement(strike_total, CASTER, 'spell_damage_total', **strike),
                measurement(strike_count, CASTER, 'spell_damage_count', **strike)]

    def command() -> list[dict]:
        return hit_ratio_cast(records, spec.command_spell, CASTER, TARGET, spec.command_power) + [
            {'action': 'wait', 'label': 'command swings', 'ms': spec.wait_ms}]

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (spec.raise_spell,
                                                                                   spec.command_spell)]
             + hit_ratio_cast(records, spec.raise_spell, CASTER, CASTER)
             + [{'action': 'wait', 'label': 'raise', 'ms': MINION_SWING_RATIO_RAISE_WAIT_MS}]
             + command() + [measurement(weapon_label, CASTER, 'owned_creature_weapon_damage_min', entry=spec.entry)]
             + reads('start'))
    for trial in range(1, spec.trials + 1):
        steps += command() + reads(trial)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour minion swing ratio'
                + (f' {spec.label_suffix}' if spec.label_suffix else ''),
        'contract': (f'A real {spec.raise_spell} raises creature {spec.entry}; one {spec.command_spell} at the dummy '
                     f'starts its attack, then {spec.trials} more, {spec.wait_ms} ms apart. After each, the '
                     f'non-critical, unblocked {spec.strike_spell} hits of creature {spec.entry} on the dummy and '
                     f'its plain melee swings (no crit, no glancing) are read; the per-hit mean of the strike over '
                     f'the per-swing mean of the same creature\'s swings is judged against {spec.expected:g} in the '
                     f'band of 5% of that ratio. The creature\'s minimum weapon damage is recorded once, not judged.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    marks = ('start', *range(1, spec.trials + 1))
    model = {'kind': 'hit_ratio', 'reads': {arm: [minion_swing_ratio_marks(spec, arm, mark) for mark in marks]
                                            for arm in ('control', 'treatment')},
             'expected': spec.expected, 'expected_bonus': (spec.expected - 1) * 100, 'trials': spec.trials,
             'trial_limit': spec.trials, 'minimum_hits': max(1, spec.trials // 2), 'metric': 'spell_damage_total',
             'ratio_band': True, 'quote': entry.quote}
    if spec.player_spell_power is not None:
        scenario['players'][0]['spell_power'] = spec.player_spell_power
        scenario['contract'] += f' The caster holds {spec.player_spell_power} spell power (harness fixture).'
    if spec.strike_flat:
        model['treatment_flat'] = spec.strike_flat
        scenario['contract'] += (f' The strike\'s flat part, {spec.strike_flat:g} per hit, is taken off the strike '
                                 f'before the ratio.')
    expectation = Expectation(minion_swing_ratio_label(spec), BEHAVIOUR_HIT_RATIO, spec.spell, spec.strike_spell,
                              None, str(spec.expected), prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def minion_swing_ratio_spec(entry: dict) -> MinionSwingRatioSpec:
    return MinionSwingRatioSpec(entry['spell'], entry['name'], entry['quote'], int(entry['raise_spell']),
                                int(entry['command_spell']), int(entry['strike_spell']), int(entry['entry']),
                                float(entry['expected']), int(entry.get('trials', 20)),
                                int(entry.get('wait_ms', 3000)), entry.get('command_power'),
                                entry.get('label_suffix', ''), float(entry.get('strike_flat', 0.0)),
                                entry.get('player_spell_power'))


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return minion_swing_ratio_scenario(class_file, minion_swing_ratio_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_hit_ratio"
            + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')]
