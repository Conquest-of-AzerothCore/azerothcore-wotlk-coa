from dataclasses import dataclass
from pathlib import Path

from behaviours import (BEHAVIOUR_CAST_GATE, CAST_GATE_WAIT_MS, NO_CAST_FAILURE, SPELL_FAILED_CASTER_AURASTATE,
                        behaviour_entry, cast_gate_power_step, dummy_placement, hit_ratio_cast, prose_rule,
                        waited_ms)
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import (FORCE_CRIT_RATINGS, FORCED_CRIT_RATING, GCD_WAIT_MS, Expectation, TARGET, armed_for, dataset,
                    facts_of, missile_wait_ms)

KIND = 'caster_aura_gate'
ORDER = 45
AURA_PRESENT = 1
MOMENTS = ('caster_aura_blocked', 'caster_aura_allowed', 'crit_aura', 'crit_allowed')


@dataclass(frozen=True)
class CasterAuraGateSpec:
    spell: int
    name: str
    quote: str
    crit_ability: int | None = None
    force_crit: str | None = None
    earned_learn: tuple[int, ...] = ()
    known_probes: tuple[int, ...] = ()


def caster_aura_gate_spec(entry: dict) -> CasterAuraGateSpec:
    spec = CasterAuraGateSpec(int(entry['spell']), entry['name'], entry['quote'],
                              None if entry.get('crit_ability') is None else int(entry['crit_ability']),
                              entry.get('force_crit'), tuple(int(spell) for spell in entry.get('earned_learn', ())),
                              tuple(int(spell) for spell in entry.get('known_probes', ())))
    if (spec.crit_ability is None) != (spec.force_crit is None):
        raise ValueError(f'{spec.spell} {KIND} earns the aura by a crit_ability with a force_crit, or not at all')
    if spec.force_crit is not None and spec.force_crit not in FORCE_CRIT_RATINGS:
        raise ValueError(f'{spec.spell} {KIND} force_crit {spec.force_crit!r} is not one of '
                         f'{sorted(FORCE_CRIT_RATINGS)}')
    if spec.crit_ability is None and (spec.earned_learn or spec.known_probes):
        raise ValueError(f'{spec.spell} {KIND} learns and probes spells for the earned arm only')
    if spec.crit_ability == spec.spell:
        raise ValueError(f'{spec.spell} {KIND} earns its aura by another ability than the gated spell')
    return spec


def gate_label(spell: int, moment: str) -> str:
    return f'{spell} {BEHAVIOUR_CAST_GATE} {moment}'


def probe_label(spell: int, read: str, stage: str) -> str:
    return f'{spell} {BEHAVIOUR_CAST_GATE} probe {read} {stage}'


def attempt(spell: int, facts, moment: str) -> list[dict]:
    return ([{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}] + cast_gate_power_step(facts)
            + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': TARGET},
               {'action': 'wait', 'ms': CAST_GATE_WAIT_MS},
               measurement(gate_label(spell, moment), CASTER, 'cast_failure', spell=spell)])


def aura_step(aura: int, stacks: int) -> dict:
    return {'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks}


def crit_steps(records: Records, spec: CasterAuraGateSpec, aura: int, distance: float, label: str) -> list[dict]:
    flight = missile_wait_ms(records, spec.crit_ability, distance)
    return ([aura_step(aura, 0)] + hit_ratio_cast(records, spec.crit_ability)
            + ([{'action': 'wait', 'label': f'{spec.crit_ability} hit', 'ms': flight}] if flight else [])
            + [measurement(label, CASTER, 'aura', spell=aura)])


def known_reads(spec: CasterAuraGateSpec, stage: str) -> list[dict]:
    return [measurement(probe_label(spec.spell, f'knows {spell}', stage), CASTER, 'knows_spell', spell=spell)
            for spell in spec.known_probes]


def caster_aura_gate_scenario(class_file: dict, spec: CasterAuraGateSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, NO_CAST_FAILURE)
    facts = facts_of(records, spec.spell)
    aura = facts.caster_aura_spell
    if not aura:
        raise ValueError(f'{spec.spell} has no CasterAuraSpell to gate on')
    class_file = armed_for(class_file, records, spec.spell)
    distance = dummy_placement(records, spec.spell, None, spec.spell)
    learned = (spec.spell,) + (() if spec.crit_ability is None else (spec.crit_ability,))
    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned]
             + known_reads(spec, 'rank_only'))
    if spec.crit_ability is not None:
        steps += crit_steps(records, spec, aura, distance, probe_label(spec.spell, f'aura {aura}', 'rank_only'))
    steps += ([aura_step(aura, 0)] + attempt(spec.spell, facts, MOMENTS[0])
              + [aura_step(aura, 1)] + attempt(spec.spell, facts, MOMENTS[1]))
    expected = {MOMENTS[0]: SPELL_FAILED_CASTER_AURASTATE, MOMENTS[1]: NO_CAST_FAILURE}
    contract = (f'{spec.spell} is attempted at the dummy without its CasterAuraSpell {aura} on the caster and must be '
                f'refused with SPELL_FAILED_CASTER_AURASTATE ({SPELL_FAILED_CASTER_AURASTATE}); with {aura} set '
                f'(harness set_aura, the gate fixture) the same attempt must succeed.')
    if spec.crit_ability is not None:
        steps += ([{'action': 'wait', 'label': f'{spec.spell} cast and global cooldown',
                    'ms': facts.cast_time_ms + GCD_WAIT_MS}]
                  + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in spec.earned_learn]
                  + known_reads(spec, 'earned')
                  + crit_steps(records, spec, aura, distance, gate_label(spec.spell, MOMENTS[2]))
                  + attempt(spec.spell, facts, MOMENTS[3]))
        expected.update({MOMENTS[2]: AURA_PRESENT, MOMENTS[3]: NO_CAST_FAILURE})
        contract += (f' Earned arm: {aura} is removed, {spec.crit_ability} is cast at the dummy with every hit forced '
                     f'to crit ({FORCE_CRIT_RATINGS[spec.force_crit]} {FORCED_CRIT_RATING}), {aura} must then be on '
                     f'the caster and the attempt with no fixture must succeed. The same crit is first made with '
                     f'only {list(learned)} learned and its {aura} read recorded; '
                     f'{list(spec.earned_learn)} are learned before the earned arm; the known spells '
                     f'{list(spec.known_probes)} are read at both stages.')
    player = player_fixture(class_file)
    if spec.force_crit is not None:
        player = {**player, FORCE_CRIT_RATINGS[spec.force_crit]: FORCED_CRIT_RATING}
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour caster aura gate',
        'contract': contract + f' The dummy stands {distance:g} yd from the caster.',
        'players': [player],
        'creatures': [creature_fixture(class_file, distance)],
        'steps': steps}
    model = {'kind': KIND, 'quote': entry.quote, 'aura': aura}
    expectations = [Expectation(gate_label(spec.spell, moment), BEHAVIOUR_CAST_GATE, spec.spell, spec.spell, None,
                                str(value), prose_rule(entry.quote, spec.spell), model)
                    for moment, value in expected.items()]
    return timed(scenario, waited_ms(steps)), expectations


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return caster_aura_gate_scenario(class_file, caster_aura_gate_spec(entry))


def label(entry: dict) -> list[str]:
    moments = MOMENTS if entry.get('crit_ability') is not None else MOMENTS[:2]
    return [gate_label(int(entry['spell']), moment) for moment in moments]
