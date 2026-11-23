import math
from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, RELOCATE_STEP_LIMIT_YD, behaviour_entry, prose_rule,
                        required_aura_steps, waited_ms)
from hits import base_mana_steps, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset, facts_of

KIND = 'ally_heal_reach'
ORDER = 46

COUNT_METRIC = 'spell_heal_count'
TOTAL_METRIC = 'spell_heal_total'
EFFECTIVE_METRIC = 'spell_effective_heal_total'
READ_METRICS = {'count': COUNT_METRIC, 'total': TOTAL_METRIC, 'effective': EFFECTIVE_METRIC}
JUDGES_BY_NAME = ('reach', 'offsets', 'per_source', 'share', 'count', 'aura_reach', 'immune_window', 'drain',
                  'health_share')
AURA_JUDGES = ('aura_reach', 'immune_window')
DRAIN_RELATIONS = ('more', 'equal')
AURA_METRIC = 'aura'
POWER_METRIC = 'power'
HEALTH_METRIC = 'health'
OWN_CAST = 'own_cast'
SPREAD_FLOOR = 10
CONTROL, TREATMENT = 'control', 'treatment'
DEFAULT_POLL_MS = 250
MAXIMUM_ALLIES = 7
MAXIMUM_RAID_ALLIES = 24
PARTY_ALLIES = 4


@dataclass(frozen=True)
class ReachAlly:
    id: str
    dx: float
    dy: float
    grouped: bool = True
    health: int | None = None
    maximum: int | None = None
    auras: tuple[tuple[int, int], ...] = ()


@dataclass(frozen=True)
class ReachCast:
    spell: int
    target: str
    watch_ms: int
    refill_power: int | None = None
    poll_ms: int = DEFAULT_POLL_MS
    end_ms: int = 0
    power_reads: bool = False
    gap_ms: int = 0
    probes: tuple[int, ...] = ()


@dataclass(frozen=True)
class ReachCheck:
    name: str
    judge: str
    spell: int
    quote: str
    reference: str | None = None
    minimum: int = 1
    healed: tuple[str, ...] = ()
    unhealed: tuple[str, ...] = ()
    witness_spell: int | None = None
    offsets: tuple[tuple[str, int], ...] = ()
    source: int | None = None
    per_event: int | None = None
    expected: float | None = None
    band: tuple[float, float] = (0.0, 0.0)
    band_reason: str = ''
    aura: int | None = None
    removed: tuple[str, ...] = ()
    kept: tuple[str, ...] = ()
    immune: tuple[str, ...] = ()
    early_ms: int | None = None
    late_ms: int | None = None
    low_cast: int | None = None
    high_cast: int | None = None
    levelled: tuple[str, ...] = ()
    apart: tuple[str, ...] = ()
    tolerance: float = 0.0
    control_allowed: tuple[str, ...] = ()
    relation: str = 'more'


@dataclass(frozen=True)
class AllyHealReachSpec:
    spell: int
    name: str
    quote: str
    allies: tuple[ReachAlly, ...]
    casts: tuple[ReachCast, ...]
    checks: tuple[ReachCheck, ...]
    gate_spell: int | None = None
    learn: tuple[int, ...] = ()
    caster_auras: tuple[tuple[int, int], ...] = ()
    caster_health: tuple[int, int] | None = None
    gate_settle_ms: int = 0


def aura_pairs(raw) -> tuple[tuple[int, int], ...]:
    return tuple((int(spell), int(stacks)) for spell, stacks in raw)


def reach_ally(raw: dict) -> ReachAlly:
    return ReachAlly(raw['id'], float(raw.get('dx', 0.0)), float(raw.get('dy', 0.0)), bool(raw.get('grouped', True)),
                     raw.get('health'), raw.get('maximum'), aura_pairs(raw.get('auras', ())))


def reach_cast(raw: dict) -> ReachCast:
    return ReachCast(int(raw['spell']), raw['target'], int(raw['watch_ms']), raw.get('refill_power'),
                     int(raw.get('poll_ms', DEFAULT_POLL_MS)), int(raw.get('end_ms', 0)),
                     bool(raw.get('power_reads', False)), int(raw.get('gap_ms', 0)),
                     tuple(int(at) for at in raw.get('probes', ())))


def reach_check(raw: dict, quote: str) -> ReachCheck:
    band = raw.get('band', [0.0, 0.0])
    return ReachCheck(raw['name'], raw['judge'], int(raw['spell']), raw.get('quote', quote), raw.get('reference'),
                      int(raw.get('minimum', 1)), tuple(raw.get('healed', ())), tuple(raw.get('unhealed', ())),
                      raw.get('witness_spell'), tuple((ally, int(offset)) for ally, offset in
                                                      raw.get('offsets', {}).items()),
                      raw.get('source'), raw.get('per_event'), raw.get('expected'),
                      (float(band[0]), float(band[1])), raw.get('band_reason', ''), raw.get('aura'),
                      tuple(raw.get('removed', ())), tuple(raw.get('kept', ())), tuple(raw.get('immune', ())),
                      raw.get('early_ms'), raw.get('late_ms'), raw.get('low_cast'), raw.get('high_cast'),
                      tuple(raw.get('levelled', ())), tuple(raw.get('apart', ())), float(raw.get('tolerance', 0.0)),
                      tuple(raw.get('control_allowed', ())), raw.get('relation', 'more'))


def ally_heal_reach_spec(entry: dict) -> AllyHealReachSpec:
    spec = AllyHealReachSpec(entry['spell'], entry['name'], entry['quote'],
                             tuple(reach_ally(raw) for raw in entry['allies']),
                             tuple(reach_cast(raw) for raw in entry['casts']),
                             tuple(reach_check(raw, entry['quote']) for raw in entry['checks']),
                             entry.get('gate_spell'), tuple(int(spell) for spell in entry.get('learn', ())),
                             aura_pairs(entry.get('caster_auras', ())),
                             tuple(entry['caster_health']) if entry.get('caster_health') is not None else None,
                             int(entry.get('gate_settle_ms', 0)))
    validate(spec)
    return spec


def validate(spec: AllyHealReachSpec) -> None:
    ids = [ally.id for ally in spec.allies]
    if not ids or len(ids) > MAXIMUM_RAID_ALLIES or len(set(ids)) != len(ids) or CASTER in ids:
        raise ValueError(f'{spec.spell} {KIND} needs 1 to {MAXIMUM_RAID_ALLIES} allies with distinct ids other than '
                         f'{CASTER!r}')
    for ally in spec.allies:
        if (ally.health is None) != (ally.maximum is None) or (ally.health is not None and
                                                                not 0 < ally.health < ally.maximum):
            raise ValueError(f'{spec.spell} {KIND} ally {ally.id!r} sets health and maximum together, with the '
                             f'health below the maximum')
    if spec.gate_spell is not None and spec.gate_spell in spec.learn:
        raise ValueError(f'{spec.spell} {KIND} learns its gate spell {spec.gate_spell} before the control phase')
    if not spec.casts:
        raise ValueError(f'{spec.spell} {KIND} needs at least one cast')
    for cast in spec.casts:
        if cast.target not in ids and cast.target != CASTER:
            raise ValueError(f'{spec.spell} {KIND} cast {cast.spell} targets {cast.target!r}, not an ally')
        if cast.watch_ms <= 0 or cast.poll_ms < 25 or cast.watch_ms % cast.poll_ms:
            raise ValueError(f'{spec.spell} {KIND} cast {cast.spell} watches a positive whole number of polls of at '
                             f'least 25 ms')
    names = [check.name for check in spec.checks]
    if not names or len(set(names)) != len(names):
        raise ValueError(f'{spec.spell} {KIND} needs checks with distinct names')
    for check in spec.checks:
        known = set(ids)
        if check.judge not in JUDGES_BY_NAME:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} judge {check.judge!r} is not one of '
                             f'{JUDGES_BY_NAME}')
        named = set(check.healed) | set(check.unhealed) | {ally for ally, _ in check.offsets} | set(
            check.control_allowed)
        if check.control_allowed and (check.judge != 'reach' or spec.gate_spell is None):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} allows control heals only on a gated reach')
        if check.reference is not None and check.judge not in AURA_JUDGES:
            named.add(check.reference)
        if not named <= known:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} names unknown allies {sorted(named - known)}')
        if check.judge == 'reach' and (not check.healed or check.reference is None):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs healed allies and a reference ally')
        if check.judge == 'offsets' and (not check.offsets or check.reference is None or check.minimum < 2):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs offsets, a reference ally and a minimum '
                             f'of at least 2')
        if check.judge == 'per_source' and (check.source is None or not check.per_event):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs a source spell and a per_event count')
        if check.judge == 'share' and (check.source is None or check.expected is None or not check.band_reason
                                       or check.band[0] > check.band[1]):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs a source spell, an expected share and a '
                             f'stated band with its reason')
        if check.judge in ('per_source', 'share') and spec.gate_spell is None:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs a gate_spell: its control phase reads '
                             f'the heal without the gate')
        validate_extended_check(spec, check)
    validate_extended_spec(spec)


def aura_units(spec: AllyHealReachSpec) -> tuple[str, ...]:
    return ((CASTER,) if spec.caster_auras else ()) + tuple(ally.id for ally in spec.allies if ally.auras)


def aura_carriers(spec: AllyHealReachSpec) -> list[tuple[str, int]]:
    return ([(CASTER, spell) for spell, _ in spec.caster_auras]
            + [(ally.id, spell) for ally in spec.allies for spell, _ in ally.auras])


def health_units(spec: AllyHealReachSpec) -> tuple[str, ...]:
    units = []
    for check in spec.checks:
        for unit in (*check.levelled, *check.apart):
            if unit not in units:
                units.append(unit)
    return tuple(units)


def validate_extended_spec(spec: AllyHealReachSpec) -> None:
    if spec.caster_health is not None and not 0 < spec.caster_health[0] < spec.caster_health[1]:
        raise ValueError(f'{spec.spell} {KIND} caster_health is [health, maximum] with the health below the maximum')
    if spec.gate_settle_ms < 0 or (spec.gate_settle_ms and spec.gate_spell is None):
        raise ValueError(f'{spec.spell} {KIND} gate_settle_ms is a non-negative wait after a gate learn')
    for cast in spec.casts:
        if cast.gap_ms < 0 or any(at <= 0 or at > cast.watch_ms or at % cast.poll_ms for at in cast.probes):
            raise ValueError(f'{spec.spell} {KIND} cast {cast.spell} probes whole polls inside its watch and waits '
                             f'a non-negative gap')
        if cast.probes and not aura_units(spec):
            raise ValueError(f'{spec.spell} {KIND} cast {cast.spell} probes auras that no unit carries')


def validate_extended_check(spec: AllyHealReachSpec, check: ReachCheck) -> None:
    units = set(aura_units(spec))
    known = {ally.id for ally in spec.allies} | {CASTER}
    if check.judge == 'count' and (check.reference is None or check.expected is None
                                   or float(check.expected) != int(check.expected) or check.expected < 0):
        raise ValueError(f'{spec.spell} {KIND} check {check.name} counts the heals of a reference ally against a '
                         f'whole expected count')
    if check.judge in AURA_JUDGES:
        if check.aura is None or not any(int(check.aura) == spell for _, spell in aura_carriers(spec)):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} reads an aura that no unit carries')
        named = set(check.removed) | set(check.kept) | set(check.immune) | (
            {check.reference} if check.reference is not None else set())
        if not named <= units:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} names units without auras '
                             f'{sorted(named - units)}')
    if check.judge == 'aura_reach' and (check.reference is None or not check.removed and not check.kept):
        raise ValueError(f'{spec.spell} {KIND} check {check.name} needs a reference unit and removed or kept units')
    if check.judge == 'immune_window':
        casts = [cast for cast in spec.casts if check.early_ms in cast.probes and check.late_ms in cast.probes]
        if not check.immune or len(casts) != 1 or check.early_ms >= check.late_ms:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs immune units and an early and a late '
                             f'probe of one cast')
    if check.judge == 'drain':
        readable = [index for index, cast in enumerate(spec.casts) if cast.power_reads]
        if check.low_cast not in readable or check.high_cast not in readable or check.low_cast == check.high_cast:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} compares the power reads of two casts')
        if check.relation not in DRAIN_RELATIONS:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} relation {check.relation!r} is not one of '
                             f'{DRAIN_RELATIONS}')
    if check.judge == 'health_share':
        named = set(check.levelled) | set(check.apart)
        if len(check.levelled) < 2 or not named <= known or check.tolerance <= 0:
            raise ValueError(f'{spec.spell} {KIND} check {check.name} levels two or more known units with a '
                             f'positive tolerance')
        unhealthy = [ally.id for ally in spec.allies if ally.id in named and ally.health is None]
        if unhealthy or (CASTER in named and spec.caster_health is None):
            raise ValueError(f'{spec.spell} {KIND} check {check.name} needs a health fixture on '
                             f'{unhealthy or [CASTER]}')


def phases(spec: AllyHealReachSpec) -> tuple[str, ...]:
    return (CONTROL, TREATMENT) if spec.gate_spell is not None else (TREATMENT,)


def read_spells(spec: AllyHealReachSpec) -> tuple[int, ...]:
    spells = []
    for check in spec.checks:
        for spell in (check.spell, check.source, check.witness_spell):
            if spell is not None and spell not in spells:
                spells.append(int(spell))
    return tuple(spells)


def read_label(spec: AllyHealReachSpec, phase: str, moment: str, ally: str, spell: int, field: str) -> str:
    return f'{spec.spell} {KIND} {phase} {moment} {ally} {spell} {field}'


def position_steps(ally: ReachAlly) -> list[dict]:
    chunks = math.ceil(max(abs(ally.dx), abs(ally.dy)) / RELOCATE_STEP_LIMIT_YD)
    return [{'action': 'relocate', 'actor': ally.id, 'dx': ally.dx / chunks, 'dy': ally.dy / chunks}
            for _ in range(chunks)]


def read_steps(spec: AllyHealReachSpec, phase: str, moment: str) -> list[dict]:
    return [measurement(read_label(spec, phase, moment, ally.id, spell, field), CASTER, metric, spell=spell,
                        target=ally.id)
            for ally in spec.allies for spell in read_spells(spec) for field, metric in READ_METRICS.items()]


def cast_steps(class_file: dict, records: Records, cast: ReachCast, spec: AllyHealReachSpec, phase: str,
               index: int) -> list[dict]:
    facts = facts_of(records, cast.spell)
    steps = base_mana_steps(class_file, facts)
    if not steps and facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        steps = [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost}]
    steps += [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': cast.spell}]
    steps += [{**step, 'actor': CASTER} for step in required_aura_steps(facts)]
    if cast.power_reads:
        steps.append(measurement(power_label(spec, phase, index, 'start'), CASTER, POWER_METRIC,
                                 power=facts.power_type))
    steps.append({'action': 'cast', 'actor': CASTER, 'spell': cast.spell, 'target': cast.target})
    for poll in range(1, cast.watch_ms // cast.poll_ms + 1):
        steps.append({'action': 'wait', 'label': f'{KIND} watch', 'ms': cast.poll_ms})
        if poll * cast.poll_ms in cast.probes:
            steps += aura_fixture_steps(spec, refusable=True) + aura_reads(
                spec, phase, probe_moment(index, poll * cast.poll_ms))
        if cast.refill_power is not None:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                          'value': int(cast.refill_power)})
    if cast.power_reads:
        steps.append(measurement(power_label(spec, phase, index, 'end'), CASTER, POWER_METRIC,
                                 power=facts.power_type))
    if cast.gap_ms:
        steps.append({'action': 'wait', 'label': f'{KIND} gap', 'ms': cast.gap_ms})
    return steps


def health_steps(spec: AllyHealReachSpec) -> list[dict]:
    caster = ([{'action': 'set_health', 'actor': CASTER, 'value': int(spec.caster_health[0]),
                'maximum': int(spec.caster_health[1])}] if spec.caster_health is not None else [])
    return caster + [{'action': 'set_health', 'actor': ally.id, 'value': int(ally.health),
                      'maximum': int(ally.maximum)} for ally in spec.allies if ally.health is not None]


def unit_auras(spec: AllyHealReachSpec, unit: str) -> tuple[tuple[int, int], ...]:
    if unit == CASTER:
        return spec.caster_auras
    return next(ally.auras for ally in spec.allies if ally.id == unit)


def aura_fixture_steps(spec: AllyHealReachSpec, refusable: bool = False) -> list[dict]:
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks,
             **({} if unit == CASTER else {'target': unit}), **({'refusable': True} if refusable else {})}
            for unit in aura_units(spec) for spell, stacks in unit_auras(spec, unit)]


def judged_auras(spec: AllyHealReachSpec) -> tuple[int, ...]:
    return tuple(dict.fromkeys(int(check.aura) for check in spec.checks if check.judge in AURA_JUDGES))


def aura_label(spec: AllyHealReachSpec, phase: str, moment: str, unit: str, aura: int) -> str:
    return f'{spec.spell} {KIND} {phase} {moment} {unit} {aura} aura'


def carries(spec: AllyHealReachSpec, unit: str, aura: int) -> bool:
    return any(spell == aura for spell, _ in unit_auras(spec, unit))


def aura_reads(spec: AllyHealReachSpec, phase: str, moment: str) -> list[dict]:
    return [measurement(aura_label(spec, phase, moment, unit, aura), unit, AURA_METRIC, spell=aura)
            for unit in aura_units(spec) for aura in judged_auras(spec) if carries(spec, unit, aura)]


def probe_moment(index: int, at_ms: int) -> str:
    return f'probe {index} {at_ms}'


def power_label(spec: AllyHealReachSpec, phase: str, index: int, moment: str) -> str:
    return f'{spec.spell} {KIND} {phase} cast {index} power {moment}'


def health_label(spec: AllyHealReachSpec, phase: str, moment: str, unit: str, field: str) -> str:
    return f'{spec.spell} {KIND} {phase} {moment} {unit} {field}'


def health_reads(spec: AllyHealReachSpec, phase: str, moment: str) -> list[dict]:
    return [measurement(health_label(spec, phase, moment, unit, field), unit, field)
            for unit in health_units(spec) for field in ('health', 'max_health')]


def phase_steps(class_file: dict, records: Records, spec: AllyHealReachSpec, phase: str) -> list[dict]:
    steps = (health_steps(spec) + aura_fixture_steps(spec) + read_steps(spec, phase, 'start')
             + health_reads(spec, phase, 'start'))
    for index, cast in enumerate(spec.casts):
        steps += cast_steps(class_file, records, cast, spec, phase, index)
    steps += read_steps(spec, phase, 'end') + aura_reads(spec, phase, 'end') + health_reads(spec, phase, 'end')
    for cast in spec.casts:
        if cast.end_ms:
            steps.append({'action': 'wait', 'label': f'{KIND} end', 'ms': cast.end_ms})
    return steps


def reads_model(spec: AllyHealReachSpec) -> dict:
    return {phase: {ally.id: {str(spell): {field: [read_label(spec, phase, 'start', ally.id, spell, field),
                                                   read_label(spec, phase, 'end', ally.id, spell, field)]
                                           for field in READ_METRICS}
                              for spell in read_spells(spec)}
                    for ally in spec.allies}
            for phase in phases(spec)}


def check_label(spec: AllyHealReachSpec, check: ReachCheck) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {check.name}'


def extended_text(spec: AllyHealReachSpec) -> str:
    parts = []
    carriers = aura_carriers(spec)
    if carriers:
        named = ', '.join(f'{spell} on {unit}' for unit, spell in carriers)
        parts.append(f' Precondition auras set with set_aura at the start of each phase: {named}; the auras '
                     f'{list(judged_auras(spec))} are read on their units at the end of each phase.')
    for index, cast in enumerate(spec.casts):
        if cast.probes:
            parts.append(f' At {list(cast.probes)} ms after cast {index} ({cast.spell}) the same auras are set again '
                         f'with a refusable set_aura (an application the unit refuses, such as one it is immune to, '
                         f'leaves it absent) and read.')
        if cast.power_reads:
            parts.append(f' The caster\'s power is read right before cast {index} ({cast.spell}) and at the end of '
                         f'its watch.')
        if cast.gap_ms:
            parts.append(f' {cast.gap_ms} ms pass after cast {index} before the next step.')
    if health_units(spec):
        parts.append(f' The health and maximum health of {list(health_units(spec))} are read at the start and the '
                     f'end of each phase window.')
    if spec.caster_health is not None:
        parts.append(f' The caster is set to {spec.caster_health[0]} of {spec.caster_health[1]} health at each phase '
                     f'start, regeneration off.')
    if spec.gate_settle_ms:
        parts.append(f' {spec.gate_settle_ms} ms pass after the gate learn before the treatment phase.')
    return ''.join(parts)


def check_metric(check: ReachCheck) -> str:
    if check.judge == 'share':
        return TOTAL_METRIC
    if check.judge in AURA_JUDGES:
        return AURA_METRIC
    if check.judge == 'drain':
        return POWER_METRIC
    if check.judge == 'health_share':
        return HEALTH_METRIC
    return COUNT_METRIC


def aura_model(spec: AllyHealReachSpec, check: ReachCheck) -> dict:
    aura = int(check.aura)
    moments = ['end'] + [probe_moment(index, at) for index, cast in enumerate(spec.casts) for at in cast.probes]
    reads = {phase: {moment: {unit: aura_label(spec, phase, moment, unit, aura)
                              for unit in aura_units(spec) if carries(spec, unit, aura)}
                     for moment in moments}
             for phase in phases(spec)}
    probe_cast = next((index for index, cast in enumerate(spec.casts) if check.early_ms in cast.probes), None)
    return {'aura': aura, 'removed': list(check.removed), 'kept': list(check.kept), 'immune': list(check.immune),
            'early_ms': check.early_ms, 'late_ms': check.late_ms, 'probe_cast': probe_cast, 'aura_reads': reads}


def extended_model(spec: AllyHealReachSpec, check: ReachCheck) -> dict:
    if check.judge in AURA_JUDGES:
        return aura_model(spec, check)
    if check.judge == 'drain':
        reads = {phase: {str(index): [power_label(spec, phase, index, 'start'), power_label(spec, phase, index, 'end')]
                         for index, cast in enumerate(spec.casts) if cast.power_reads}
                 for phase in phases(spec)}
        model = {'low_cast': check.low_cast, 'high_cast': check.high_cast, 'contrast': OWN_CAST, 'power_reads': reads}
        if check.relation != 'more':
            model |= {'relation': check.relation, 'tolerance': check.tolerance}
        return model
    if check.judge == 'health_share':
        reads = {phase: {moment: {unit: {field: health_label(spec, phase, moment, unit, field)
                                         for field in ('health', 'max_health')}
                                  for unit in health_units(spec)}
                         for moment in ('start', 'end')}
                 for phase in phases(spec)}
        return {'levelled': list(check.levelled), 'apart': list(check.apart), 'tolerance': check.tolerance,
                'health_reads': reads}
    return {}


def check_model(spec: AllyHealReachSpec, check: ReachCheck, reads: dict) -> dict:
    return {'kind': KIND, 'metric': check_metric(check), 'quote': check.quote, **extended_model(spec, check),
            **({'control_allowed': list(check.control_allowed)} if check.control_allowed else {}),
            'judge': check.judge, 'spell': check.spell, 'reference': check.reference, 'minimum': check.minimum,
            'healed': list(check.healed), 'unhealed': list(check.unhealed), 'witness_spell': check.witness_spell,
            'offsets': dict(check.offsets), 'source': check.source, 'per_event': check.per_event,
            'expected': check.expected, 'band': list(check.band), 'band_reason': check.band_reason,
            'allies': [ally.id for ally in spec.allies], 'phases': list(phases(spec)), 'reads': reads}


def ally_heal_reach_scenario(class_file: dict, spec: AllyHealReachSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    for check in spec.checks:
        behaviour_entry(records, spec.spell, spec.name, KIND, check.quote, float(check.expected or 0))
    allies = [{**player_fixture(class_file), 'id': ally.id,
               **({'allow_regeneration': False} if ally.health is not None else {})} for ally in spec.allies]
    caster = {**player_fixture(class_file), **({'allow_regeneration': False} if spec.caster_health else {})}
    steps = base_steps(class_file)
    for ally in spec.allies:
        steps += position_steps(ally)
        if ally.grouped:
            steps.append({'action': 'group', 'actor': CASTER, 'target': ally.id})
    for spell in dict.fromkeys([*spec.learn, *(cast.spell for cast in spec.casts)]):
        steps.append({'action': 'learn', 'actor': CASTER, 'spell': spell})
    for phase in phases(spec):
        if phase == TREATMENT and spec.gate_spell is not None:
            steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.gate_spell})
            if spec.gate_settle_ms:
                steps.append({'action': 'wait', 'label': f'{KIND} gate settle', 'ms': spec.gate_settle_ms})
        steps += phase_steps(class_file, records, spec, phase)
    layout = '; '.join(f'{ally.id} at ({ally.dx:g}, {ally.dy:g}) yd'
                       + ('' if ally.grouped else ' ungrouped')
                       + (f', health {ally.health} of {ally.maximum}' if ally.health is not None else '')
                       for ally in spec.allies)
    casts = '; '.join(f'{cast.spell} at {cast.target}, watched {cast.watch_ms} ms'
                      + (f' with the power refilled to {cast.refill_power} every {cast.poll_ms} ms'
                         if cast.refill_power is not None else '')
                      for cast in spec.casts)
    gate = (f' The control phase runs without {spec.gate_spell}; it is learned before the treatment phase.'
            if spec.gate_spell is not None else ' One treatment phase, no gate.')
    scenario = {
        'schema': 1 if len(spec.allies) <= MAXIMUM_ALLIES else 2,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour ally heal reach',
        'contract': (f'Ally players placed from the caster: {layout}. Real casts per phase: {casts}. Every ally\'s '
                     f'heal count, total and effective total of {list(read_spells(spec))} from the caster are read at '
                     f'the start and the end of each phase window, and each check judges the window\'s '
                     f'increments.{gate}{required_aura_text(records, spec)}{raid_text(spec)}'
                     f'{extended_text(spec)}'),
        'players': [caster] + allies,
        'steps': steps}
    reads = reads_model(spec)
    expectations = [Expectation(check_label(spec, check), BEHAVIOUR_METRIC_DELTA, spec.spell, check.spell, None,
                                expected_text(check), prose_rule(check.quote, spec.spell),
                                check_model(spec, check, reads))
                    for check in spec.checks]
    return timed(scenario, waited_ms(steps)), expectations


def required_auras(records: Records, spec: AllyHealReachSpec) -> dict[int, int]:
    found = {}
    for cast in spec.casts:
        aura = facts_of(records, cast.spell).caster_aura_spell
        if aura:
            found.setdefault(cast.spell, int(aura))
    return found


def required_aura_text(records: Records, spec: AllyHealReachSpec) -> str:
    auras = required_auras(records, spec)
    if not auras:
        return ''
    named = ', '.join(f'{aura} before each {spell}' for spell, aura in auras.items())
    return (f' Precondition fixtures: the CasterAuraSpell of a cast is set on the caster with set_aura before that '
            f'cast ({named}), so the cast is not refused for its caster aura; that aura is not the subject of any '
            f'check.')


def raid_text(spec: AllyHealReachSpec) -> str:
    grouped = [ally.id for ally in spec.allies if ally.grouped]
    if len(grouped) <= PARTY_ALLIES:
        return ''
    return (f' {len(grouped)} grouped allies exceed a party: the harness group step converts the full party to a raid '
            f'before it adds {grouped[PARTY_ALLIES]}, which joins another raid subgroup, so a party-only search does '
            f'not see {grouped[PARTY_ALLIES:]}.')


def expected_text(check: ReachCheck) -> str:
    if check.judge == 'count':
        return f'{int(check.expected)}'
    if check.judge == 'aura_reach':
        return f'{len(check.removed)} removed, {len(check.kept)} kept'
    if check.judge == 'immune_window':
        return f'{len(check.immune)} immune'
    if check.judge == 'drain':
        if check.relation == 'equal':
            return f'cast {check.high_cast} equal to cast {check.low_cast}'
        return f'cast {check.high_cast} above cast {check.low_cast}'
    if check.judge == 'health_share':
        return f'{len(check.levelled)} levelled'
    if check.judge == 'reach':
        return str(len(check.healed))
    if check.judge == 'offsets':
        return ', '.join(f'{ally} {offset:+d}' for ally, offset in check.offsets)
    if check.judge == 'per_source':
        return str(check.per_event)
    return f'{check.expected:g}'


def increment(run, model: dict, phase: str, ally: str, spell: int, field: str) -> float | str:
    start, end = model['reads'][phase][ally][str(spell)][field]
    for label in (start, end):
        if run.values.get(label) is None:
            from compare import missing_measurement
            return missing_measurement(run, label)
    return float(run.values[end]) - float(run.values[start])


def increments(run, model: dict, phase: str, spell: int, field: str = 'count') -> dict[str, float] | str:
    found = {}
    for ally in model['allies']:
        value = increment(run, model, phase, ally, spell, field)
        if isinstance(value, str):
            return value
        found[ally] = value
    return found


def control_heals(run, model: dict, spell: int) -> dict[str, float] | str | None:
    if CONTROL not in model['phases']:
        return None
    return increments(run, model, CONTROL, spell)


def listed(counts: dict[str, float]) -> str:
    return ', '.join(f'{ally} {value:g}' for ally, value in counts.items())


def reach_verdict(base, run, model: dict):
    spell, reference = model['spell'], model['reference']
    treatment = increments(run, model, TREATMENT, spell)
    if isinstance(treatment, str):
        return replace(base, explanation=treatment)
    anchor_spell = model['witness_spell'] or spell
    anchor = increments(run, model, TREATMENT, anchor_spell)
    if isinstance(anchor, str):
        return replace(base, explanation=anchor)
    if anchor[reference] < model['minimum']:
        return replace(base, status='unmeasured', measured=anchor[reference],
                       explanation=f'reference {reference} took {anchor[reference]:g} heals of {anchor_spell} in the '
                                   f'treatment window, fewer than {model["minimum"]}: the cast did not run')
    unreached = [ally for ally in model['unhealed'] if model['witness_spell'] and anchor[ally] <= 0]
    if unreached:
        return replace(base, status='unmeasured',
                       explanation=f'{unreached} took no {anchor_spell} heal, so their 0 {spell} heals do not show a '
                                   f'selection: they were not reachable')
    control = control_heals(run, model, spell)
    if isinstance(control, str):
        return replace(base, explanation=control)
    healed = [ally for ally in model['healed'] if treatment[ally] > 0]
    wrong = [ally for ally in model['unhealed'] if treatment[ally] != 0]
    allowed = model.get('control_allowed', [])
    leaked = [ally for ally, value in (control or {}).items() if value != 0 and ally not in allowed]
    status = 'ok' if len(healed) == len(model['healed']) and not wrong and not leaked else 'alert'
    control_text = (f'; control phase without the gate: {listed(control)} (all must be 0'
                    + (f' but {allowed}' if allowed else '') + ')' if control is not None else '')
    unwitnessed = (f'; no witness spell: the 0 of {model["unhealed"]} does not exclude a line of sight or placement '
                   f'fault' if model['unhealed'] and not model['witness_spell'] else '')
    return replace(base, status=status, measured=float(len(healed)), expected=float(len(model['healed'])),
                   low=float(len(model['healed'])), high=float(len(model['healed'])),
                   explanation=f'treatment heals of {spell}: {listed(treatment)}; {model["healed"]} must each take at '
                               f'least one, {model["unhealed"]} none{control_text}; a count is compared '
                               f'exactly{unwitnessed}')


def offsets_verdict(base, run, model: dict):
    spell, reference = model['spell'], model['reference']
    treatment = increments(run, model, TREATMENT, spell)
    if isinstance(treatment, str):
        return replace(base, explanation=treatment)
    anchor = treatment[reference]
    if anchor < model['minimum']:
        return replace(base, status='unmeasured', measured=anchor,
                       explanation=f'reference {reference} took {anchor:g} heals of {spell}, fewer than '
                                   f'{model["minimum"]}: an offset cannot be told from a missing heal')
    wrong = {ally: treatment[ally] - anchor for ally, offset in model['offsets'].items()
             if treatment[ally] - anchor != offset}
    status = 'ok' if not wrong else 'alert'
    return replace(base, status=status, measured=anchor, expected=anchor, low=anchor, high=anchor,
                   explanation=f'treatment heals of {spell}: {listed(treatment)}; against reference {reference} '
                               f'({anchor:g}) each ally must read its offset {model["offsets"]}'
                               + (f'; read offsets {wrong}' if wrong else '') + '; counts are compared exactly')


def per_source_verdict(base, run, model: dict):
    spell, source = model['spell'], model['source']
    treatment = increments(run, model, TREATMENT, spell)
    sources = increments(run, model, TREATMENT, source)
    totals = increments(run, model, TREATMENT, source, 'total')
    effective = increments(run, model, TREATMENT, source, 'effective')
    for value in (treatment, sources, totals, effective):
        if isinstance(value, str):
            return replace(base, explanation=value)
    source_events = sum(sources.values())
    if source_events < model['minimum']:
        return replace(base, status='unmeasured', measured=source_events,
                       explanation=f'{source_events:g} heals of {source}, fewer than {model["minimum"]}')
    if sum(totals.values()) != sum(effective.values()):
        return replace(base, status='unmeasured',
                       explanation=f'{source} overhealed ({sum(totals.values()) - sum(effective.values()):g}): an '
                                   f'overheal can leave no effective healing to share, so the count per heal is not '
                                   f'judged')
    control = control_heals(run, model, spell)
    if isinstance(control, str):
        return replace(base, explanation=control)
    expected = float(model['per_event']) * source_events
    measured = sum(treatment.values())
    leaked = sum((control or {}).values())
    status = 'ok' if measured == expected and leaked == 0 else 'alert'
    return replace(base, status=status, measured=measured, expected=expected, low=expected, high=expected,
                   explanation=f'{measured:g} heals of {spell} ({listed(treatment)}) for {source_events:g} heals of '
                               f'{source}: {model["per_event"]} per heal gives {expected:g}; control phase '
                               f'{leaked:g} (must be 0); a count is compared exactly')


def share_verdict(base, run, model: dict):
    spell, source = model['spell'], model['source']
    reads = {}
    for name, (read_spell, field) in {'count': (spell, 'count'), 'total': (spell, 'total'),
                                      'source_count': (source, 'count'),
                                      'source_effective': (source, 'effective')}.items():
        value = increments(run, model, TREATMENT, read_spell, field)
        if isinstance(value, str):
            return replace(base, explanation=value)
        reads[name] = sum(value.values())
    if reads['count'] < model['minimum'] or reads['source_count'] < model['minimum']:
        return replace(base, status='unmeasured', measured=reads['count'],
                       explanation=f'{reads["count"]:g} heals of {spell} and {reads["source_count"]:g} of {source}, '
                                   f'fewer than {model["minimum"]}')
    control = control_heals(run, model, spell)
    if isinstance(control, str):
        return replace(base, explanation=control)
    mean = reads['total'] / reads['count']
    source_mean = reads['source_effective'] / reads['source_count']
    centre = float(model['expected']) * source_mean
    low, high = centre + model['band'][0], centre + model['band'][1]
    leaked = sum((control or {}).values())
    status = 'ok' if low - 1e-9 <= mean <= high + 1e-9 and leaked == 0 else 'alert'
    return replace(base, status=status, measured=mean, expected=centre, low=low, high=high,
                   explanation=f'mean {spell} heal {mean:g} over {reads["count"]:g} heals against '
                               f'{model["expected"]:g} x the mean effective {source} heal {source_mean:g} '
                               f'({reads["source_count"]:g} heals) = {centre:g}, band [{low:g}, {high:g}] '
                               f'({model["band_reason"]}); control phase {leaked:g} heals of {spell} (must be 0); '
                               f'ratio {mean / source_mean:.4f}')


def count_verdict(base, run, model: dict):
    spell, reference = model['spell'], model['reference']
    treatment = increments(run, model, TREATMENT, spell)
    if isinstance(treatment, str):
        return replace(base, explanation=treatment)
    control = control_heals(run, model, spell)
    if isinstance(control, str):
        return replace(base, explanation=control)
    expected = float(model['expected'])
    measured = treatment[reference]
    leaked = (control or {}).get(reference, 0.0)
    status = 'ok' if measured == expected and leaked == 0 else 'alert'
    control_text = f'; control phase {leaked:g} (must be 0)' if control is not None else ''
    return replace(base, status=status, measured=measured, expected=expected, low=expected, high=expected,
                   explanation=f'{measured:g} heals of {spell} on {reference} in the treatment window '
                               f'(all allies: {listed(treatment)}) against {expected:g}{control_text}; a count is '
                               f'compared exactly')


def aura_state(run, model: dict, phase: str, moment: str, units) -> dict[str, float] | str:
    from compare import missing_measurement
    found = {}
    for unit in units:
        label = model['aura_reads'][phase][moment][unit]
        if run.values.get(label) is None:
            return missing_measurement(run, label)
        found[unit] = float(run.values[label])
    return found


def aura_reach_verdict(base, run, model: dict):
    reference, aura = model['reference'], model['aura']
    units = list(dict.fromkeys([reference, *model['removed'], *model['kept']]))
    treatment = aura_state(run, model, TREATMENT, 'end', units)
    if isinstance(treatment, str):
        return replace(base, explanation=treatment)
    control = aura_state(run, model, CONTROL, 'end', units) if CONTROL in model['phases'] else None
    if isinstance(control, str):
        return replace(base, explanation=control)
    if treatment[reference] != 0 or (control is not None and control[reference] != 0):
        return replace(base, status='unmeasured', measured=treatment[reference],
                       explanation=f'reference {reference} still carries {aura} at the end of a phase (treatment '
                                   f'{treatment[reference]:g}' + (f', control {control[reference]:g}'
                                                                  if control is not None else '')
                                   + '): the cast did not run')
    wrong = ([unit for unit in model['removed'] if treatment[unit] != 0]
             + [unit for unit in model['kept'] if treatment[unit] == 0])
    leaked = [unit for unit in model['removed'] if control is not None and control[unit] == 0]
    removed = sum(1 for unit in model['removed'] if treatment[unit] == 0)
    status = 'ok' if not wrong and not leaked else 'alert'
    control_text = (f'; control phase without the gate: {listed(control)} ({model["removed"]} must still carry it)'
                    if control is not None else '')
    return replace(base, status=status, measured=float(removed), expected=float(len(model['removed'])),
                   low=float(len(model['removed'])), high=float(len(model['removed'])),
                   explanation=f'{aura} at the end of the treatment phase: {listed(treatment)}; {model["removed"]} '
                               f'must have lost it and {model["kept"]} kept it, reference {reference} lost it in '
                               f'every phase{control_text}; presence is compared exactly'
                               + (f'; wrong: {wrong}' if wrong else '')
                               + (f'; removed without the gate: {leaked}' if leaked else ''))


def immune_window_verdict(base, run, model: dict):
    index = model['probe_cast']
    early, late = probe_moment(index, model['early_ms']), probe_moment(index, model['late_ms'])
    units = model['immune']
    reads = {}
    for phase in model['phases']:
        for moment in (early, late):
            value = aura_state(run, model, phase, moment, units)
            if isinstance(value, str):
                return replace(base, explanation=value)
            reads[(phase, moment)] = value
    blocked = [unit for unit in units if reads[(TREATMENT, early)][unit] == 0]
    ended = [unit for unit in units if reads[(TREATMENT, late)][unit] != 0]
    control = reads.get((CONTROL, early))
    opened = [unit for unit in units if control is None or control[unit] != 0]
    status = 'ok' if len(blocked) == len(ended) == len(opened) == len(units) else 'alert'
    control_text = (f'; control phase without the gate at {model["early_ms"]} ms: {listed(control)} (must take '
                    f'it, 1)' if control is not None else '')
    return replace(base, status=status, measured=float(len(blocked)), expected=float(len(units)),
                   low=float(len(units)), high=float(len(units)),
                   explanation=f'{model["aura"]} set again {model["early_ms"]} ms after cast {index}: '
                               f'{listed(reads[(TREATMENT, early)])} (must be refused, 0), and at '
                               f'{model["late_ms"]} ms: {listed(reads[(TREATMENT, late)])} (must take it, 1)'
                               f'{control_text}; presence is compared exactly')


def drain_verdict(base, run, model: dict):
    from compare import missing_measurement
    drains = {}
    for index in (model['low_cast'], model['high_cast']):
        start, end = model['power_reads'][TREATMENT][str(index)]
        for label in (start, end):
            if run.values.get(label) is None:
                return replace(base, explanation=missing_measurement(run, label))
        drains[index] = float(run.values[start]) - float(run.values[end])
    low, high = drains[model['low_cast']], drains[model['high_cast']]
    if low <= 0:
        return replace(base, status='unmeasured', measured=low,
                       explanation=f'cast {model["low_cast"]} spent {low:g} power: the cast did not run')
    if model.get('relation') == 'equal':
        tolerance = float(model['tolerance'])
        status = 'ok' if abs(high - low) <= tolerance else 'alert'
        return replace(base, status=status, measured=high, expected=low, low=low - tolerance, high=low + tolerance,
                       explanation=f'power spent over the watch: cast {model["low_cast"]} {low:g}, cast '
                                   f'{model["high_cast"]} {high:g} (must be equal within {tolerance:g})')
    status = 'ok' if high > low else 'alert'
    return replace(base, status=status, measured=high, expected=low, low=low, high=None,
                   explanation=f'power spent over the watch: cast {model["low_cast"]} {low:g}, cast '
                               f'{model["high_cast"]} {high:g} (must be more, ratio {high / low:.4f})')


def health_pct(run, model: dict, phase: str, moment: str, unit: str) -> float | str:
    from compare import missing_measurement
    labels = model['health_reads'][phase][moment][unit]
    for label in labels.values():
        if run.values.get(label) is None:
            return missing_measurement(run, label)
    maximum = float(run.values[labels['max_health']])
    if maximum <= 0:
        return f'{labels["max_health"]} read {maximum:g}'
    return 100.0 * float(run.values[labels['health']]) / maximum


def health_share_verdict(base, run, model: dict):
    reads = {}
    for moment in ('start', 'end'):
        for unit in (*model['levelled'], *model['apart']):
            value = health_pct(run, model, TREATMENT, moment, unit)
            if isinstance(value, str):
                return replace(base, explanation=value)
            reads[(moment, unit)] = value
    tolerance = float(model['tolerance'])
    start = [reads[('start', unit)] for unit in model['levelled']]
    end = [reads[('end', unit)] for unit in model['levelled']]
    if max(start) - min(start) <= SPREAD_FLOOR * tolerance:
        return replace(base, status='unmeasured', measured=max(start) - min(start),
                       explanation=f'the levelled units start at {[round(value, 3) for value in start]} percent, '
                                   f'too close to tell a share from the fixture')
    spread = max(end) - min(end)
    moved = [unit for unit in model['apart'] if abs(reads[('end', unit)] - reads[('start', unit)]) > tolerance]
    status = 'ok' if spread <= tolerance and not moved else 'alert'
    text = ', '.join(f'{unit} {reads[("start", unit)]:.3f} to {reads[("end", unit)]:.3f}'
                     for unit in (*model['levelled'], *model['apart']))
    return replace(base, status=status, measured=spread, expected=0.0, low=0.0, high=tolerance,
                   explanation=f'health percent from the window start to its end: {text}; {model["levelled"]} '
                               f'must end within {tolerance:g} points of each other, {model["apart"]} unchanged '
                               f'within {tolerance:g}')


VERDICTS = {'reach': reach_verdict, 'offsets': offsets_verdict, 'per_source': per_source_verdict,
            'share': share_verdict, 'count': count_verdict, 'aura_reach': aura_reach_verdict,
            'immune_window': immune_window_verdict, 'drain': drain_verdict, 'health_share': health_share_verdict}


def ally_heal_reach_verdict(base, run, model: dict):
    return VERDICTS[model['judge']](base, run, model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return ally_heal_reach_scenario(class_file, ally_heal_reach_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {check['name']}" for check in entry['checks']]


JUDGES = {BEHAVIOUR_METRIC_DELTA: ally_heal_reach_verdict}
