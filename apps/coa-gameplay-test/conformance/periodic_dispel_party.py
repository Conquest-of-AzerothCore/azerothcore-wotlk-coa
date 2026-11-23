from dataclasses import dataclass
from pathlib import Path

from behaviours import (BEHAVIOUR_CAST_CONDITION, PARTY_ALLY_FAR_MARGIN_YD, PARTY_ALLY_NEAR_DISTANCE_YD,
                        behaviour_entry, cast_gate_power_step, party_ally_fixture, party_ally_id,
                        periodic_dispel_label, prose_rule, relocate_steps, waited_ms)
from hits import timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset, facts_of, required_aura_steps

PARTY_PULSE_FIELD = 'party_pulse'
PARTY_PULSE_KEYS = {'radius_spell', 'pulses', 'far_margin', 'near_distance', 'near_limit', 'note'}
SPELL_EFFECT_DISPEL_MECHANIC = 108
PARTY_PULSE_MINIMUM_PULSES = 2
PARTY_PULSE_TIME_RULE_SHARE = 0.1
EFFECT_SLOTS = range(3)
UNLIMITED_DURATION = -1


@dataclass(frozen=True)
class PartyPulseSpec:
    spell: int
    name: str
    quote: str
    debuffs: tuple[int, ...]
    period_ms: int
    margin_ms: int
    radius_spell: int
    pulses: int
    power: int | None = None
    near_distance: float = PARTY_ALLY_NEAR_DISTANCE_YD
    far_margin: float = PARTY_ALLY_FAR_MARGIN_YD
    near_limit: float | None = None
    note: str = ''


def party_pulse_spec(entry: dict) -> PartyPulseSpec:
    pulse = entry[PARTY_PULSE_FIELD]
    if not isinstance(pulse, dict) or set(pulse) - PARTY_PULSE_KEYS or 'radius_spell' not in pulse:
        raise ValueError(f'{entry["spell"]} periodic_dispel party_pulse needs {{"radius_spell": id, "pulses": n}} '
                         f'and the optional far_margin, near_distance, near_limit and note, here {pulse!r}')
    if 'margin_ms' not in entry:
        raise ValueError(f'{entry["spell"]} periodic_dispel party_pulse needs its own margin_ms')
    return PartyPulseSpec(entry['spell'], entry['name'], entry['quote'], tuple(int(d) for d in entry['debuffs']),
                          int(entry['period_ms']), int(entry['margin_ms']), int(pulse['radius_spell']),
                          int(pulse.get('pulses', PARTY_PULSE_MINIMUM_PULSES)), entry.get('power'),
                          float(pulse.get('near_distance', PARTY_ALLY_NEAR_DISTANCE_YD)),
                          float(pulse.get('far_margin', PARTY_ALLY_FAR_MARGIN_YD)),
                          None if pulse.get('near_limit') is None else float(pulse['near_limit']),
                          str(pulse.get('note', '')))


def dispelled_mechanics(records: Records, spell: int) -> set[int]:
    return {int(records.field('Spell', spell, f'EffectMiscValue[{slot}]')) for slot in EFFECT_SLOTS
            if records.field('Spell', spell, f'Effect[{slot}]') == SPELL_EFFECT_DISPEL_MECHANIC}


def debuff_mechanics(records: Records, spell: int) -> set[int]:
    return ({int(records.field('Spell', spell, 'Mechanic'))}
            | {int(records.field('Spell', spell, f'EffectMechanic[{slot}]')) for slot in EFFECT_SLOTS}) - {0}


def debuff_duration_ms(records: Records, spell: int) -> int:
    return int(records.field('SpellDuration', records.field('Spell', spell, 'DurationIndex'), 'Duration'))


def period_bracket(spec: PartyPulseSpec) -> tuple[int, int]:
    return spec.period_ms - 2 * spec.margin_ms, spec.period_ms + spec.margin_ms


def window_ms(spec: PartyPulseSpec) -> int:
    return spec.pulses * spec.period_ms + spec.margin_ms


def party_pulse_validate(records: Records, spec: PartyPulseSpec) -> float:
    dispelled = dispelled_mechanics(records, spec.radius_spell)
    if not dispelled:
        raise ValueError(f'{spec.spell} party_pulse radius spell {spec.radius_spell} has no '
                         f'SPELL_EFFECT_DISPEL_MECHANIC effect')
    covered: set[int] = set()
    for debuff in spec.debuffs:
        mechanics = debuff_mechanics(records, debuff) & dispelled
        if not mechanics:
            raise ValueError(f'{spec.spell} party_pulse debuff {debuff} carries none of the dispelled mechanics '
                             f'{sorted(dispelled)}')
        duration = debuff_duration_ms(records, debuff)
        if duration != UNLIMITED_DURATION and duration < window_ms(spec):
            raise ValueError(f'{spec.spell} party_pulse debuff {debuff} lasts {duration} ms, less than the '
                             f'{window_ms(spec)} ms window')
        covered |= mechanics
    if covered != dispelled:
        raise ValueError(f'{spec.spell} party_pulse debuffs leave mechanics {sorted(dispelled - covered)} untested')
    if spec.pulses < PARTY_PULSE_MINIMUM_PULSES:
        raise ValueError(f'{spec.spell} party_pulse needs at least {PARTY_PULSE_MINIMUM_PULSES} pulses after the '
                         f'first, here {spec.pulses}')
    radius = records.radius(spec.radius_spell, 0)
    near_bound = radius if spec.near_limit is None else spec.near_limit
    if (spec.near_limit is not None and spec.near_limit < radius) or not 0 < spec.near_distance < near_bound \
            or spec.far_margin <= 0 or radius + spec.far_margin <= near_bound:
        raise ValueError(f'{spec.spell} party_pulse places the near member inside the {near_bound:g} yd bound and the '
                         f'far '
                         f'one beyond it, here near_distance {spec.near_distance:g}, far_margin '
                         f'{spec.far_margin:g} and near_limit {spec.near_limit}')
    low, high = period_bracket(spec)
    share = PARTY_PULSE_TIME_RULE_SHARE * spec.period_ms
    if not (low > spec.period_ms - share and high < spec.period_ms + share):
        raise ValueError(f'{spec.spell} party_pulse margin {spec.margin_ms} ms brackets the period in {low}..{high} '
                         f'ms, which does not exclude {spec.period_ms - share:g} and {spec.period_ms + share:g} ms')
    return radius


def party_pulse_moments(spec: PartyPulseSpec) -> list[tuple[str, int, int, bool]]:
    count = len(spec.debuffs)
    moments = [('after_0', spec.margin_ms, 0, True)]
    for pulse in range(1, spec.pulses + 1):
        moments += [(f'before_{pulse}', pulse * spec.period_ms - spec.margin_ms, count, False),
                     (f'after_{pulse}', pulse * spec.period_ms + spec.margin_ms, 0, pulse < spec.pulses)]
    return moments


def party_pulse_scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    spec = party_pulse_spec(entry)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    radius = party_pulse_validate(records, spec)
    behaviour = behaviour_entry(records, spec.spell, spec.name, 'periodic_dispel', spec.quote, 0.0)
    facts = facts_of(records, spec.spell)
    near, far = party_ally_id(0), party_ally_id(1)
    far_distance = radius + spec.far_margin
    count = len(spec.debuffs)

    def place(ally: str, stacks: int = 1) -> list[dict]:
        return [{'action': 'set_aura', 'actor': ally, 'spell': debuff, 'stacks': stacks} for debuff in spec.debuffs]

    def read(ally: str, moment: str) -> list[dict]:
        return [measurement(periodic_dispel_label(spec.spell, moment, debuff), ally, 'aura', spell=debuff)
                for debuff in spec.debuffs]

    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + relocate_steps(near, spec.near_distance) + [{'action': 'group', 'actor': CASTER, 'target': near}]
             + relocate_steps(far, far_distance) + [{'action': 'group', 'actor': CASTER, 'target': far}]
             + place(near) + place(far)
             + [{'action': 'wait', 'label': 'control without the spell wait', 'ms': window_ms(spec)}]
             + read(near, 'control') + read(far, 'far_control')
             + place(near, 0) + place(far, 0) + place(near) + place(far)
             + ([{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.power}]
                if spec.power is not None else cast_gate_power_step(facts))
             + required_aura_steps(facts)
             + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': CASTER}])
    elapsed = 0
    moments = party_pulse_moments(spec)
    for moment, at_ms, _, reapply in moments:
        steps += [{'action': 'wait', 'label': f'{moment} wait', 'ms': at_ms - elapsed}] + read(near, moment)
        steps += place(near) if reapply else []
        elapsed = at_ms
    steps += read(far, f'far_{moments[-1][0]}')
    rule = prose_rule(behaviour.quote, spec.spell)
    low, high = period_bracket(spec)
    model = {'kind': 'periodic_dispel', 'mode': PARTY_PULSE_FIELD, 'period_ms': spec.period_ms,
             'radius_yd': radius, 'period_bracket_ms': [low, high], 'quote': behaviour.quote}
    judged = ([('control', count), ('far_control', count)] + [(moment, present) for moment, _, present, _ in moments]
              + [(f'far_{moments[-1][0]}', count)])
    expectations = [Expectation(periodic_dispel_label(spec.spell, moment), BEHAVIOUR_CAST_CONDITION, spec.spell,
                                spec.spell, None, str(present), rule,
                                {**model, 'sum_labels': [periodic_dispel_label(spec.spell, moment, debuff)
                                                         for debuff in spec.debuffs]})
                    for moment, present in judged]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour periodic dispel party pulse',
        'contract': f'A party member {spec.near_distance:g} yd away and a party member {far_distance:g} yd '
                    f'away (beyond the {radius:g} yd radius of {spec.radius_spell}) carry {list(spec.debuffs)}, which '
                    f'stay on both for {window_ms(spec)} ms without {spec.spell}. With it cast at the caster, the '
                    f'near member has none left {spec.margin_ms} ms after the cast; the debuffs are set again after '
                    f'each pulse, all present {spec.margin_ms} ms before and none left {spec.margin_ms} ms after each '
                    f'of {spec.pulses} periods of {spec.period_ms} ms, so every pulse removes all of them and the '
                    f'period lies in {low}..{high} ms; the far member keeps all of them to the end, proving the '
                    f'"{spec.quote}" clause.' + (f' {spec.note}' if spec.note else ''),
        'players': [player_fixture(class_file), party_ally_fixture(0, class_file), party_ally_fixture(1, class_file)],
        'steps': steps}
    return timed(scenario, waited_ms(steps)), expectations
