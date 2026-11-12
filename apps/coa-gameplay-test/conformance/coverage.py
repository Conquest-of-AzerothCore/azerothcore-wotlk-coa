from dataclasses import dataclass, field
import json
from pathlib import Path
import re

from behaviours import (BEHAVIOUR_ABSORB_PIERCE_RATIO, BEHAVIOUR_AGGRO_REDIRECT, BEHAVIOUR_AMOUNT_DELTA,
                        BEHAVIOUR_AURA_GRANT, BEHAVIOUR_CAST_APPLIES_AURA, BEHAVIOUR_CAST_COMBAT,
                        BEHAVIOUR_CAST_CONDITION, BEHAVIOUR_CAST_GATE, BEHAVIOUR_CHARGE_RECHARGE, BEHAVIOUR_COUNT,
                        BEHAVIOUR_CRIT_GUARANTEE, BEHAVIOUR_CRIT_MAGNITUDE, BEHAVIOUR_DURATION,
                        BEHAVIOUR_DURATION_RATIO, BEHAVIOUR_DURATION_REFRESH, BEHAVIOUR_EXCLUSIVITY,
                        BEHAVIOUR_FIXED_COUNT, BEHAVIOUR_GROUP_STACK_CAP, BEHAVIOUR_HEAL_BLOCK, BEHAVIOUR_HIT_RATIO,
                        BEHAVIOUR_IMMUNITY, BEHAVIOUR_INTERNAL_COOLDOWN, BEHAVIOUR_INTERNAL_COOLDOWN_GATE,
                        BEHAVIOUR_METRIC_DELTA, BEHAVIOUR_METRIC_RATIO_DELTA, BEHAVIOUR_MOUNT_GRANT,
                        BEHAVIOUR_OATH_CONSUMPTION, BEHAVIOUR_OATH_CONSUMPTION_REMOVAL, BEHAVIOUR_PARTY_STAT_RATIO,
                        BEHAVIOUR_RATIO, BEHAVIOUR_SINGLE_TARGET, BEHAVIOUR_THREAT_SLOPE, BEHAVIOUR_TRIGGER,
                        BEHAVIOUR_EVENT_DELAY, BEHAVIOUR_PROC_RESET, BEHAVIOUR_TAKEN_HIT,
                        BEHAVIOUR_THREAT_REDIRECT, BEHAVIOUR_DISPEL_COUNT, BEHAVIOUR_TAKEN_OUTCOME,
                        BEHAVIOUR_CRIT_RATE, BEHAVIOUR_AMOUNT_MATCH, BEHAVIOUR_SOURCE_STACK, BEHAVIOUR_FALL_DAMAGE,
                        LEARNED_CONTRAST)
from behaviours import BEHAVIOUR_CHECKS as PROSE_BEHAVIOUR_CHECKS
from compare import (CONFORMANT, CONTRAST, DATA_ONLY, LINKED_VERDICT_REFERENCE, NOT_MEASURED, PASSIVE_METRIC,
                     STATUSES, Verdict, read_verdicts)
from expiry import BEHAVIOUR_EXPIRY
from hits import NEVER_CAST, NO_HIT_EFFECT, UNMODELLED
from passives import PASSIVE_DELTA, POWER_NAMES, RATING_NAMES
from procs import DELTA_CHECK, PROC_CHECK
from profile import DbcSetMismatch, require_server_sha
from streamed import same_figures, streamed_texts
from stack import STACK_DPS, STACK_SOURCE, TALENT_DELTA
from triggers import (COOLDOWN_CHECK, DURATION_CHECK, GATE_ABSENCE_CHECK, MAGNITUDE_CHECK, SELF_TRIGGER_CHECK,
                      TRIGGER_CHECK)
from values import CHECKS as VALUE_CHECKS, GAP_CLOSER_DISTANCE

COVERAGE_FILE = 'coverage.md'
JUDGED = frozenset({'ok', 'tolerated', 'alert'})
CHARACTER_CHECKS = frozenset({'known_aura'})
BEHAVIOUR_CHECKS = frozenset({PASSIVE_DELTA, PROC_CHECK, TRIGGER_CHECK, BEHAVIOUR_EXPIRY, *PROSE_BEHAVIOUR_CHECKS})
HIT_CHECK = 'hit_mean'
SPELL_KINDS = ('value', 'hit', 'passive')
PASSIVE_KIND = 'passive'
PLACEHOLDER_RULE = UNMODELLED + NEVER_CAST
NO_HIT_EFFECT_RULE = UNMODELLED + NO_HIT_EFFECT
KEY_SEPARATORS = re.compile(r'[^a-z0-9]+')


@dataclass(frozen=True)
class Coverage:
    statuses: dict[str, int]
    judged_spells: int
    spells: int
    passives_with_behaviour: int
    passives: int
    actives_with_hit: int
    actives: int
    actives_with_effect: int


@dataclass(frozen=True)
class SpellSets:
    spells: frozenset[int]
    passives: frozenset[int]
    judged: frozenset[int]
    behaviour: frozenset[int]
    hit: frozenset[int]
    hittable: frozenset[int]
    placeholders: int


def is_placeholder(verdict: Verdict) -> bool:
    return verdict.label.endswith(f' {HIT_CHECK}') and verdict.explanation == PLACEHOLDER_RULE


def scenario_kind(class_name: str, scenario: str) -> str | None:
    prefix = KEY_SEPARATORS.sub('-', f'conformance-{class_name}'.lower()).strip('-') + '-'
    if not scenario.startswith(prefix):
        return None
    return scenario[len(prefix):].split('-', 1)[0]


def spell_sets(header: dict, verdicts: list[Verdict]) -> SpellSets:
    placeholders = [verdict for verdict in verdicts if is_placeholder(verdict)]
    own = [verdict for verdict in verdicts if verdict.check not in CHARACTER_CHECKS and not is_placeholder(verdict)]
    kinds = [(scenario_kind(header['class_name'], verdict.scenario), verdict) for verdict in own]
    spells = {verdict.spell_id for kind, verdict in kinds if kind in SPELL_KINDS}
    spells |= {verdict.spell_id for verdict in placeholders}
    passives = {verdict.spell_id for kind, verdict in kinds if kind == PASSIVE_KIND}
    passives |= {verdict.spell_id for verdict in placeholders}
    judged = {verdict.spell_id for verdict in own if verdict.status in JUDGED} & spells
    behaviour = {verdict.spell_id for verdict in own
                 if verdict.status in JUDGED and verdict.check in BEHAVIOUR_CHECKS} & passives
    hit = {verdict.spell_id for verdict in own if verdict.status in JUDGED and verdict.check == HIT_CHECK}
    actives = spells - passives
    hittable = {verdict.spell_id for verdict in own
               if verdict.check == HIT_CHECK and verdict.spell_id in actives
               and not verdict.explanation.startswith(NO_HIT_EFFECT_RULE)}
    return SpellSets(frozenset(spells), frozenset(passives), frozenset(judged), frozenset(behaviour),
                     frozenset(hit & actives), frozenset(hittable), len(placeholders))


def coverage(header: dict, verdicts: list[Verdict]) -> Coverage:
    sets = spell_sets(header, verdicts)
    counted = [verdict for verdict in verdicts if not is_placeholder(verdict)]
    statuses = {status: sum(verdict.status == status for verdict in counted) for status in STATUSES}
    return Coverage(statuses, len(sets.judged), len(sets.spells), len(sets.behaviour), len(sets.passives),
                    len(sets.hit), len(sets.spells - sets.passives), len(sets.hittable))


def share(part: int, whole: int) -> str:
    return f'{part} of {whole} ({part / whole * 100:.1f}%)' if whole else f'{part} of 0'


def signed(value: int) -> str:
    return f'{value:+d}'


def spell_list(spells: frozenset[int]) -> str:
    return ', '.join(map(str, sorted(spells))) or 'None.'


def coverage_lines(before_dir: Path, after_dir: Path, headers: tuple[dict, dict], results: tuple[Coverage, Coverage],
                   sets: tuple[SpellSets, SpellSets]) -> list[str]:
    before, after = results
    rows = [('spells judged', before.judged_spells, before.spells, after.judged_spells, after.spells),
            ('passives with a behaviour check', before.passives_with_behaviour, before.passives,
             after.passives_with_behaviour, after.passives),
            ('actives with a hit model', before.actives_with_hit, before.actives, after.actives_with_hit,
             after.actives),
            ('actives with a hit model (of those with an effect)', before.actives_with_hit,
             before.actives_with_effect, after.actives_with_hit, after.actives_with_effect)]
    lines = [f'# Conformance coverage: {headers[1]["class_name"]} (class {headers[1]["class_id"]})', '',
             f'- Before: `{before_dir}` (manifest `{headers[0].get("manifest", "")}`)',
             f'- After: `{after_dir}` (manifest `{headers[1].get("manifest", "")}`)',
             f'- Left out: {sets[0].placeholders} phase-1 placeholders before and {sets[1].placeholders} after '
             f'(`{HIT_CHECK}` verdicts with the rule `{PLACEHOLDER_RULE}`).',
             '- Class spells: spell ids with a verdict in a value, hit or passive scenario; passives: the spells of a '
             'passive scenario or of a placeholder; actives: the other class spells.',
             f'- Judged: at least one `ok` or `alert` verdict, `{"`, `".join(sorted(CHARACTER_CHECKS))}` left out. '
             f'Behaviour check: a judged `{"`, `".join(sorted(BEHAVIOUR_CHECKS))}` verdict of the passive. Hit model: '
             f'a judged `{HIT_CHECK}` verdict of the active.',
             '', '## Coverage', '', '| | before | after | difference |', '|---|---|---|---|']
    lines += [f'| {name} | {share(part, whole)} | {share(new_part, new_whole)} | {signed(new_part - part)} |'
              for name, part, whole, new_part, new_whole in rows]
    lines += ['', '## Verdicts per status', '', '| | before | after | difference |', '|---|---|---|---|']
    lines += [f'| {status} | {before.statuses[status]} | {after.statuses[status]} | '
              f'{signed(after.statuses[status] - before.statuses[status])} |' for status in STATUSES]
    lines += [f'| total | {sum(before.statuses.values())} | {sum(after.statuses.values())} | '
              f'{signed(sum(after.statuses.values()) - sum(before.statuses.values()))} |']
    lines += ['', '## Spells judged before, not after', '', spell_list(sets[0].judged - sets[1].judged),
              '', '## Spells judged after, not before', '', spell_list(sets[1].judged - sets[0].judged),
              '', '## Class spells on one side only', '',
              f'- Before only: {spell_list(sets[0].spells - sets[1].spells)}',
              f'- After only: {spell_list(sets[1].spells - sets[0].spells)}']
    return lines + ['']


ORDINAL_SUFFIX = re.compile(r' #\d+$')


def load_clauses(path: Path) -> list[dict]:
    return json.loads(Path(path).read_text(encoding='utf-8'))


def resolved_labels(label: str, statuses: dict[str, str]) -> list[str]:
    if label in statuses:
        return [label]
    if ORDINAL_SUFFIX.search(label):
        return []
    prefix = f'{label} #'
    return sorted(candidate for candidate in statuses
                 if candidate.startswith(prefix) and candidate[len(prefix):].isdigit())


DECLARED_CLAIMS = 'claims'
CLAIM_WORDS = 'claim'
MIN_DECLARED_CLAIMS = 2


def clause_claims(clause: dict) -> list[dict]:
    if DECLARED_CLAIMS in clause:
        return [{CLAIM_WORDS: claim[CLAIM_WORDS], 'labels': list(claim.get('labels') or [])}
                for claim in clause[DECLARED_CLAIMS]]
    words = clause.get(CLAIM_WORDS, clause.get('clause', ''))
    return [{CLAIM_WORDS: words, 'labels': list(clause.get('labels') or [])}]


EFFECTIVENESS_OF = 'effectiveness_of'
EFFECTIVENESS_WORDS = re.compile(r'\beffectiveness of\b', re.IGNORECASE)
FORMULA_TOKEN = re.compile(r'\$\{[^}]*\}')
TOOLTIP_TOKEN = re.compile(r'\$(?:/\d+;)?(\d*)([A-Za-z])(\d*)')
UNSTATED_PROPERTY_TOKENS = frozenset('dar')
LITERAL_NUMBER = re.compile(r'\b\d+(?:\.\d+)?\b')


def stated_values(text: str) -> set[str]:
    formulas = set(FORMULA_TOKEN.findall(text))
    rest = FORMULA_TOKEN.sub(' ', text)
    tokens = {f'${spell}{letter.lower()}{index}' for spell, letter, index in TOOLTIP_TOKEN.findall(rest)
              if letter.lower() not in UNSTATED_PROPERTY_TOKENS}
    return formulas | tokens | set(LITERAL_NUMBER.findall(TOOLTIP_TOKEN.sub(' ', rest)))


def states_value(text: str) -> bool:
    return bool(stated_values(text))


def require_effectiveness_subjects(clauses: list[dict]):
    for clause in clauses:
        if EFFECTIVENESS_OF not in clause:
            continue
        where = f"spell {clause.get('spell')}: {clause.get('clause')!r}"
        if clause.get('kind') != 'claim' or DECLARED_CLAIMS in clause:
            raise EvidenceError(f'{where} names an effectiveness subject but is not a claim entry with its own '
                                f'labels')
        named = clause[EFFECTIVENESS_OF]
        if not isinstance(named, int) or isinstance(named, bool):
            raise EvidenceError(f'{where} names the effectiveness subject {named!r}; it is the spell id of the buff '
                                f'the clause names')
        if not EFFECTIVENESS_WORDS.search(clause.get('clause', '')):
            raise EvidenceError(f'{where} names an effectiveness subject but does not increase "the effectiveness '
                                f'of" a buff')


def subject_claims(clause: dict, clauses: list[dict]) -> list[dict]:
    found = clause_claims(clause)
    named = clause.get(EFFECTIVENESS_OF)
    if named is None:
        return found
    entries = [other['clause'] for other in clauses if other.get('spell') == named]
    if len(set().union(*map(stated_values, entries))) != 1:
        return found
    stated = ' '.join(text for text in entries if states_value(text))
    return [{**claim, CLAIM_WORDS: f'{claim[CLAIM_WORDS]} ({stated})'} for claim in found]


def clause_labels(clause: dict) -> list[str]:
    return [label for claim in clause_claims(clause) for label in claim['labels']]


def require_claims(clauses: list[dict]):
    for clause in clauses:
        if DECLARED_CLAIMS not in clause:
            continue
        where = f"spell {clause.get('spell')}: {clause.get('clause')!r}"
        claims = clause[DECLARED_CLAIMS]
        if clause.get('kind') != 'claim':
            raise EvidenceError(f'{where} declares claims but is not a claim entry')
        if clause.get('labels'):
            raise EvidenceError(f'{where} declares claims and also clause labels; the labels belong to its claims')
        if not isinstance(claims, list) or len(claims) < MIN_DECLARED_CLAIMS:
            raise EvidenceError(f'{where} declares {claims!r}; declared claims are a list of at least '
                                f'{MIN_DECLARED_CLAIMS}, otherwise the clause labels are its one claim')
        for claim in claims:
            if not isinstance(claim, dict) or not isinstance(claim.get(CLAIM_WORDS), str) \
                    or not isinstance(claim.get('labels'), list):
                raise EvidenceError(f'{where} declares {claim!r}; a claim is {{"claim": <words>, "labels": [...]}}')


TOOL_GAP = 'tool_gap'
TOOL_GAP_ACCEPTED = 'accepted'
TOOL_GAP_PENDING = 'pending'
MIN_TOOL_GAP_AGENTS = 2


def text_field(value) -> bool:
    return isinstance(value, str) and bool(value.strip())


def require_attempts(clause: dict, field_name: str, what: str):
    where = f"spell {clause.get('spell')}: {clause.get('clause')!r}"
    declared = clause[field_name]
    if clause.get('kind') != 'claim':
        raise EvidenceError(f'{where} declares {what} but is not a claim entry')
    if not isinstance(declared, dict) or not text_field(declared.get('reason')) \
            or not isinstance(declared.get('attempts'), list):
        raise EvidenceError(f'{where} declares {declared!r}; {what} is {{"reason": <text>, "attempts": [...]}}')
    if not declared['attempts']:
        raise EvidenceError(f'{where} declares {what} with no attempt')
    for attempt in declared['attempts']:
        if not isinstance(attempt, dict) or not text_field(attempt.get('agent')) \
                or not text_field(attempt.get('report')):
            raise EvidenceError(f'{where} declares the attempt {attempt!r}; an attempt is '
                                f'{{"agent": <who tried>, "report": <where it is written>}}')
    return where, declared


def attempting_agents(declared: dict) -> set[str]:
    return {attempt['agent'].strip() for attempt in declared['attempts']}


def require_tool_gaps(clauses: list[dict]):
    for clause in clauses:
        if TOOL_GAP not in clause:
            continue
        where, gap = require_attempts(clause, TOOL_GAP, 'a tool gap')
        acceptance = gap.get('owner_acceptance')
        if acceptance is not None and (not isinstance(acceptance, dict) or not text_field(acceptance.get('ruling'))):
            raise EvidenceError(f'{where} declares the owner acceptance {acceptance!r}; it is '
                                f'{{"ruling": <the ruling that accepts the gap>}}')


def tool_gap_state(clause: dict) -> str | None:
    gap = clause.get(TOOL_GAP)
    if gap is None:
        return None
    if gap.get('owner_acceptance') or len(attempting_agents(gap)) >= MIN_TOOL_GAP_AGENTS:
        return TOOL_GAP_ACCEPTED
    return TOOL_GAP_PENDING


NO_BEHAVIOUR_ROUTE = 'no_behaviour_route'
NO_ROUTE_TERMINAL = 'terminal'
NO_ROUTE_PENDING = 'pending'
NO_ROUTE_NOT_DATA = 'not_data'
MIN_NO_ROUTE_AGENTS = 2


def require_no_routes(clauses: list[dict]):
    for clause in clauses:
        if NO_BEHAVIOUR_ROUTE not in clause:
            continue
        where, _ = require_attempts(clause, NO_BEHAVIOUR_ROUTE, 'no behaviour route')
        if TOOL_GAP in clause:
            raise EvidenceError(f'{where} declares both a tool gap and no behaviour route; a tool gap is for an '
                                f'unproven clause, no behaviour route for a data conformant one')


def no_route_state(clause: dict, evidence: str) -> str:
    if evidence != DATA:
        return NO_ROUTE_NOT_DATA
    if len(attempting_agents(clause[NO_BEHAVIOUR_ROUTE])) >= MIN_NO_ROUTE_AGENTS:
        return NO_ROUTE_TERMINAL
    return NO_ROUTE_PENDING


def clause_proven(labels: list[str], statuses: dict[str, str]) -> bool:
    if not labels:
        return False
    for label in labels:
        matches = resolved_labels(label, statuses)
        if not matches or any(statuses.get(match) not in CONFORMANT for match in matches):
            return False
    return True


DATA = 'data'
BEHAVIOUR = 'behaviour'
UNPROVEN = 'unproven'
BY_METRIC = 'metric'
LINKED = 'linked'
EVENT = 'event'
READBACK = 'readback'
STATE = 'state'
EVIDENCE = {
    **{check: DATA for check in VALUE_CHECKS},
    'hit_mean': BEHAVIOUR, 'melee_mean': BEHAVIOUR, 'periodic_total': BEHAVIOUR, 'unmodelled': LINKED,
    PASSIVE_DELTA: BY_METRIC, PROC_CHECK: BEHAVIOUR, DELTA_CHECK: BEHAVIOUR,
    TRIGGER_CHECK: BEHAVIOUR, COOLDOWN_CHECK: DATA, DURATION_CHECK: DATA, MAGNITUDE_CHECK: BEHAVIOUR,
    SELF_TRIGGER_CHECK: BEHAVIOUR, GATE_ABSENCE_CHECK: BEHAVIOUR,
    STACK_DPS: BEHAVIOUR, STACK_SOURCE: BEHAVIOUR, TALENT_DELTA: BEHAVIOUR,
    BEHAVIOUR_COUNT: BEHAVIOUR, BEHAVIOUR_RATIO: BY_METRIC, BEHAVIOUR_DURATION: DATA, BEHAVIOUR_DURATION_RATIO: DATA,
    BEHAVIOUR_TRIGGER: BEHAVIOUR, BEHAVIOUR_METRIC_DELTA: BY_METRIC, BEHAVIOUR_DURATION_REFRESH: DATA,
    BEHAVIOUR_AMOUNT_DELTA: DATA, BEHAVIOUR_CRIT_GUARANTEE: BEHAVIOUR, BEHAVIOUR_AURA_GRANT: BEHAVIOUR,
    BEHAVIOUR_OATH_CONSUMPTION: BY_METRIC, BEHAVIOUR_OATH_CONSUMPTION_REMOVAL: BEHAVIOUR,
    BEHAVIOUR_INTERNAL_COOLDOWN_GATE: BEHAVIOUR, BEHAVIOUR_EXCLUSIVITY: BEHAVIOUR,
    BEHAVIOUR_GROUP_STACK_CAP: BY_METRIC, BEHAVIOUR_SINGLE_TARGET: BEHAVIOUR, BEHAVIOUR_CRIT_MAGNITUDE: BY_METRIC,
    BEHAVIOUR_CHARGE_RECHARGE: BEHAVIOUR, BEHAVIOUR_FIXED_COUNT: BEHAVIOUR, BEHAVIOUR_PARTY_STAT_RATIO: BY_METRIC,
    BEHAVIOUR_CAST_GATE: BEHAVIOUR, BEHAVIOUR_CAST_CONDITION: BEHAVIOUR, BEHAVIOUR_MOUNT_GRANT: BEHAVIOUR,
    BEHAVIOUR_INTERNAL_COOLDOWN: BEHAVIOUR, BEHAVIOUR_CAST_COMBAT: BEHAVIOUR, BEHAVIOUR_AGGRO_REDIRECT: BEHAVIOUR,
    BEHAVIOUR_HEAL_BLOCK: BEHAVIOUR, BEHAVIOUR_CAST_APPLIES_AURA: DATA, BEHAVIOUR_METRIC_RATIO_DELTA: BEHAVIOUR,
    BEHAVIOUR_ABSORB_PIERCE_RATIO: BEHAVIOUR, GAP_CLOSER_DISTANCE: BEHAVIOUR, BEHAVIOUR_HIT_RATIO: BY_METRIC,
    BEHAVIOUR_EXPIRY: BEHAVIOUR, BEHAVIOUR_IMMUNITY: BEHAVIOUR, BEHAVIOUR_THREAT_SLOPE: BEHAVIOUR,
    BEHAVIOUR_EVENT_DELAY: BEHAVIOUR,
    BEHAVIOUR_PROC_RESET: BEHAVIOUR, BEHAVIOUR_TAKEN_HIT: BEHAVIOUR, BEHAVIOUR_THREAT_REDIRECT: BEHAVIOUR,
    BEHAVIOUR_DISPEL_COUNT: BEHAVIOUR, BEHAVIOUR_TAKEN_OUTCOME: BEHAVIOUR, BEHAVIOUR_CRIT_RATE: BEHAVIOUR,
    BEHAVIOUR_AMOUNT_MATCH: BEHAVIOUR, BEHAVIOUR_SOURCE_STACK: BEHAVIOUR, BEHAVIOUR_FALL_DAMAGE: BEHAVIOUR,
}
METRIC_EVIDENCE = {
    **dict.fromkeys(('aura', 'aura_stacks', 'aura_apply_count', 'spell_cast_count', 'spell_damage_count',
                     'spell_damage_total', 'spell_heal_count', 'spell_heal_total',
                     'spell_effective_heal_total', 'spell_energize_count', 'spell_energize_total', 'spell_proc_count',
                     'melee_attack_count', 'melee_damage_count', 'melee_damage_total',
                     'melee_attacks_taken', 'owned_creature_count', 'owned_creature_damage_count',
                     'owned_creature_damage_total', 'owned_creature_heal_count', 'owned_creature_heal_total',
                     'cast_failure', 'timeline_count', 'timeline_first_ms', 'timeline_interval_min_ms',
                     'timeline_interval_max_ms', 'timeline_interval_median_ms', 'event_first_ms',
                     'event_interval_min_ms', 'event_interval_max_ms', 'event_interval_median_ms', 'water_walk',
                     'spell_absorb_total', 'spell_log_count', 'nearby_creature_at_client'),
                    EVENT),
    **dict.fromkeys(('spell_modifier', 'spell_power_cost', 'spell_effect_value', 'spell_max_stacks', 'can_detect',
                     'spell_cast_time_ms', 'spell_duration_ms', 'spell_effect_radius', 'spell_max_range',
                     'aura_amount', 'aura_duration_ms', 'aura_amplitude_ms', 'aura_charges', 'cooldown_ms',
                     'spell_cooldown_packet_ms',
                     'spell_damage_done', 'spell_healing_done', 'spell_healing_taken', 'spell_critical_damage',
                     'spell_done_crit_chance', 'melee_damage_done', 'aoe_damage_taken', 'script_spell_damage_taken',
                     'spell_damage_taken', 'melee_damage_taken',
                     'script_heal_received', 'item_armor_by_subclass', 'spell_effect_immune', 'spell_immune'),
                    READBACK),
    **dict.fromkeys(('stat', 'stat_exact', 'armor', 'combat_rating', 'melee_hit_chance', 'spell_hit_chance',
                     'expertise', 'spell_power', 'attack_power', 'ranged_attack_power', 'max_health', 'max_power',
                     'power', 'run_speed_rate', 'attack_time_ms', 'parry_chance', 'dodge_chance', 'block_chance',
                     'melee_crit_chance', 'melee_crit_chance_refreshed', 'spell_crit_chance', 'weapon_damage_min',
                     'resistance', 'mana_regen', 'moving', 'threat'), STATE),
}
CRIT_WORDS = r'critical strike chance|chance to critically'
RATING_WORDS = '|'.join(['rating', *sorted({re.escape(name) for name in RATING_NAMES.values()})])
POWER_WORDS = '|'.join(sorted(re.escape(name) for name in POWER_NAMES.values()))
STATE_PROMISES = {
    'stat': r'strength|agility|stamina|intellect|spirit', 'stat_exact': r'strength|agility|stamina|intellect|spirit',
    'armor': r'armou?r', 'combat_rating': RATING_WORDS, 'melee_hit_chance': r'hit chance|chance to hit',
    'spell_hit_chance': r'hit chance|chance to hit', 'expertise': r'expertise',
    'spell_power': r'spell power|spell damage',
    'attack_power': r'attack power', 'ranged_attack_power': r'ranged attack power',
    'max_health': r'maximum health', 'max_power': POWER_WORDS,
    'power': r'mana|energy|rage|focus', 'run_speed_rate': r'movement speed|run speed',
    'attack_time_ms': r'haste|attack speed', 'parry_chance': r'parry', 'dodge_chance': r'dodge',
    'block_chance': r'block', 'melee_crit_chance': CRIT_WORDS, 'melee_crit_chance_refreshed': CRIT_WORDS,
    'spell_crit_chance': CRIT_WORDS, 'weapon_damage_min': r'weapon damage', 'resistance': r'resistances?',
    'mana_regen': r'mana regenerat\w*', 'moving': r'flee\w*|moving', 'threat': r'threat',
}
CONTRAST_CHECKS = frozenset({PASSIVE_DELTA, BEHAVIOUR_METRIC_DELTA, BEHAVIOUR_PARTY_STAT_RATIO})
LISTED_OTHER_BUILD = 5


class EvidenceError(ValueError):
    pass


K3 = 'K3'
CONSUMED = 'consumed'
NOT_CONSUMED = 'not_consumed'
CONSUMPTION_FIELDS = frozenset({'label', 'route', 'spell', 'effect', 'build', 'evidence', 'result'})
SHA256 = re.compile(r'[0-9a-f]{64}')


@dataclass(frozen=True)
class Consumption:
    label: str
    route: str
    spell: int
    effect: int
    build: str
    evidence: str
    result: str


def consumption_row(row, where: str) -> Consumption:
    if not isinstance(row, dict) or set(row) != CONSUMPTION_FIELDS:
        raise EvidenceError(f'{where}: a consumption row has exactly the fields {sorted(CONSUMPTION_FIELDS)}')
    if row['route'] != K3:
        raise EvidenceError(f'{where}: route {row["route"]!r} is not {K3}, the only consumption route (ADR 0129)')
    if row['result'] not in (CONSUMED, NOT_CONSUMED):
        raise EvidenceError(f'{where}: result {row["result"]!r} is not {CONSUMED} or {NOT_CONSUMED}')
    if not isinstance(row['build'], str) or not SHA256.fullmatch(row['build']):
        raise EvidenceError(f'{where}: build {row["build"]!r} is not a worldserver binary sha256')
    if not all(isinstance(row[name], str) and row[name] for name in ('label', 'evidence')):
        raise EvidenceError(f'{where}: label and evidence are non-empty strings')
    if not all(isinstance(row[name], int) and not isinstance(row[name], bool) and row[name] >= 0
               for name in ('spell', 'effect')):
        raise EvidenceError(f'{where}: spell and effect are non-negative integers')
    return Consumption(row['label'], row['route'], row['spell'], row['effect'], row['build'], row['evidence'],
                       row['result'])


def load_consumption(path: Path) -> list[Consumption]:
    path = Path(path)
    if not path.is_file():
        return []
    rows = json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(rows, list):
        raise EvidenceError(f'{path} holds {type(rows).__name__}, not a JSON array of consumption rows')
    return [consumption_row(row, f'{path}[{index}]') for index, row in enumerate(rows)]


def consumption_results(rows, build: str | None) -> dict[str, str]:
    results = {}
    for row in rows:
        if build is None or row.build != build:
            continue
        results[row.label] = NOT_CONSUMED if NOT_CONSUMED in (row.result, results.get(row.label)) else CONSUMED
    return results


def acting(verdict: Verdict) -> bool:
    if verdict.status not in CONFORMANT or verdict.status == 'closed' or (verdict.detail or {}).get(DATA_ONLY):
        return False
    kind = EVIDENCE.get(verdict.check)
    return kind == BEHAVIOUR or (kind == BY_METRIC and metric_class(verdict) == EVENT)


@dataclass(frozen=True)
class ClauseCoverage:
    proven: int
    behaviour: int
    total: int
    unproven: list[dict]
    evidence: list[tuple[dict, str]]
    not_measured: list[str]
    claim_evidence: list[list[str]] = field(default_factory=list)
    tool_gaps: list[tuple[dict, str]] = field(default_factory=list)
    promoted: frozenset[str] = frozenset()
    not_consumed: frozenset[str] = frozenset()
    no_routes: list[tuple[dict, str]] = field(default_factory=list)
    project_text: list[dict] = field(default_factory=list)

    @property
    def data(self) -> int:
        return self.proven - self.behaviour

    @property
    def terminal_no_route(self) -> int:
        return sum(state == NO_ROUTE_TERMINAL for _, state in self.no_routes)

    @property
    def open_data(self) -> int:
        return self.data - self.terminal_no_route

    @property
    def accepted_tool_gaps(self) -> int:
        return sum(state == TOOL_GAP_ACCEPTED for _, state in self.tool_gaps)

    @property
    def pending_tool_gaps(self) -> int:
        return sum(state == TOOL_GAP_PENDING for _, state in self.tool_gaps)

    @property
    def resolved(self) -> int:
        return self.proven + self.accepted_tool_gaps


def require_build(verdicts: list[Verdict], build: str | None, where: str):
    if not verdicts:
        return
    if build is None:
        raise EvidenceError(f'{where}: no single build is named for these verdicts (runs of several builds, or a '
                            f'compare that predates per-verdict builds); compare the runs of one build again')
    other = sorted(verdict.label for verdict in verdicts if verdict.build != build)
    if other:
        shown = ', '.join(other[:LISTED_OTHER_BUILD]) + (', ...' if len(other) > LISTED_OTHER_BUILD else '')
        raise EvidenceError(f'{where}: {len(other)} verdicts come from another build than {build}, alerts and proofs '
                            f'alike, and are refused: {shown}')


def require_known_checks(verdicts: list[Verdict]):
    unknown = sorted({verdict.check for verdict in verdicts if verdict.check not in EVIDENCE})
    if unknown:
        raise EvidenceError(f'checks {unknown} have no evidence class in coverage.EVIDENCE')


def metric_class(verdict: Verdict) -> str:
    metric = (verdict.detail or {}).get(PASSIVE_METRIC)
    if metric is None:
        raise EvidenceError(f'{verdict.label}: check {verdict.check} carries no observed metric in its detail')
    if metric not in METRIC_EVIDENCE:
        raise EvidenceError(f'{verdict.label}: metric {metric!r} has no evidence class in coverage.METRIC_EVIDENCE')
    return METRIC_EVIDENCE[metric]


def promised_state(verdict: Verdict, clause: str) -> bool:
    detail = verdict.detail or {}
    if verdict.check not in CONTRAST_CHECKS:
        return False
    if verdict.check == BEHAVIOUR_METRIC_DELTA and detail.get(CONTRAST) != LEARNED_CONTRAST:
        return False
    words = STATE_PROMISES.get(detail[PASSIVE_METRIC])
    return words is not None and re.search(rf'\b(?:{words})\b', clause, re.IGNORECASE) is not None


def verdict_evidence(verdict: Verdict, clause: str, by_label: dict[str, Verdict],
                     seen: frozenset[str] = frozenset(), promoted: frozenset[str] = frozenset()) -> str:
    if verdict.status not in CONFORMANT:
        return UNPROVEN
    kind = EVIDENCE[verdict.check]
    if kind == LINKED:
        referenced = [by_label[label] for label in LINKED_VERDICT_REFERENCE.findall(verdict.explanation)
                      if label in by_label and label not in seen]
        found = {verdict_evidence(other, clause, by_label, seen | {verdict.label}, promoted) for other in referenced}
        return BEHAVIOUR if BEHAVIOUR in found else DATA
    if verdict.status != 'closed' and verdict.label in promoted:
        return BEHAVIOUR
    if verdict.status == 'closed' or kind == DATA or (verdict.detail or {}).get(DATA_ONLY):
        return DATA
    if kind == BEHAVIOUR:
        return BEHAVIOUR
    observed = metric_class(verdict)
    if observed == EVENT or (observed == STATE and promised_state(verdict, clause)):
        return BEHAVIOUR
    return DATA


def claim_evidence(claim: dict, by_label: dict[str, Verdict], statuses: dict[str, str],
                   promoted: frozenset[str] = frozenset()) -> str:
    labels = claim['labels']
    if not clause_proven(labels, statuses):
        return UNPROVEN
    matched = [by_label[match] for label in labels for match in resolved_labels(label, statuses)]
    found = {verdict_evidence(verdict, claim[CLAIM_WORDS], by_label, promoted=promoted) for verdict in matched}
    return BEHAVIOUR if BEHAVIOUR in found else DATA


def claims_evidence(found: list[str]) -> str:
    if UNPROVEN in found:
        return UNPROVEN
    return BEHAVIOUR if all(status == BEHAVIOUR for status in found) else DATA


def clause_evidence(clause: dict, by_label: dict[str, Verdict], statuses: dict[str, str],
                    promoted: frozenset[str] = frozenset()) -> str:
    return claims_evidence([claim_evidence(claim, by_label, statuses, promoted) for claim in clause_claims(clause)])


TEXT_SOURCE = 'text_source'
DBC_CLAUSE = 'dbc_clause'
INDEPENDENT_BASES = frozenset({'owner_ruling', 'live_source'})
TEXT_CORRECTION = 'text_correction'
TEXT_BASES = INDEPENDENT_BASES | {TEXT_CORRECTION, 'align_to_server'}


def require_text_sources(clauses: list[dict], streamed: frozenset[int]):
    for clause in clauses:
        source = clause.get(TEXT_SOURCE)
        where = f"spell {clause.get('spell')}: {clause.get('clause')!r}"
        if clause.get('spell') in streamed and source is None:
            raise EvidenceError(f'{where} is read from a streamed client text and names no {TEXT_SOURCE}')
        if source is not None and source.get('basis') not in TEXT_BASES:
            raise EvidenceError(f'{where} has a {TEXT_SOURCE} basis {source.get("basis")!r}, not one of '
                                f'{sorted(TEXT_BASES)}')


def independent_text(clause: dict) -> bool:
    source = clause.get(TEXT_SOURCE)
    if source is None or source['basis'] in INDEPENDENT_BASES or DBC_CLAUSE not in clause:
        return True
    return source['basis'] == TEXT_CORRECTION and same_figures(clause[DBC_CLAUSE], clause['clause'])


def clause_coverage(clauses: list[dict], verdicts: list[Verdict], build: str | None = None,
                    consumption=(), streamed: frozenset[int] | None = None) -> ClauseCoverage:
    require_build(verdicts, build, 'clause coverage')
    require_known_checks(verdicts)
    require_claims(clauses)
    require_tool_gaps(clauses)
    require_no_routes(clauses)
    require_effectiveness_subjects(clauses)
    require_text_sources(clauses, frozenset(streamed_texts()) if streamed is None else streamed)
    by_label = {verdict.label: verdict for verdict in verdicts}
    statuses = {verdict.label: verdict.status for verdict in verdicts}
    results = consumption_results(consumption, build)
    promoted = frozenset(label for label, result in results.items() if result == CONSUMED)
    not_consumed = frozenset(label for label, result in results.items() if result == NOT_CONSUMED)
    claims = [clause for clause in clauses if clause.get('kind') == 'claim']
    per_claim = [[claim_evidence(claim, by_label, statuses, promoted) for claim in subject_claims(clause, clauses)]
                 for clause in claims]
    project_text = [clause for clause in claims if not independent_text(clause)]
    evidence = [(clause, UNPROVEN if any(clause is other for other in project_text) else claims_evidence(found))
                for clause, found in zip(claims, per_claim)]
    unproven = [clause for clause, status in evidence if status == UNPROVEN]
    behaviour = sum(status == BEHAVIOUR for _, status in evidence)
    not_measured = sorted(verdict.label for verdict in verdicts if verdict.status == NOT_MEASURED)
    tool_gaps = [(clause, tool_gap_state(clause)) for clause in unproven if TOOL_GAP in clause]
    no_routes = [(clause, no_route_state(clause, status)) for clause, status in evidence
                 if NO_BEHAVIOUR_ROUTE in clause]
    return ClauseCoverage(len(claims) - len(unproven), behaviour, len(claims), unproven, evidence, not_measured,
                          per_claim, tool_gaps, promoted & by_label.keys(), not_consumed & by_label.keys(),
                          no_routes, project_text)


def clause_coverage_lines(result: ClauseCoverage) -> list[str]:
    lines = [f'clauses proven: {share(result.proven, result.total)}',
             f'behaviour proven: {share(result.behaviour, result.total)}',
             f'data conformant: {share(result.data, result.total)}',
             f'data conformant, no behaviour route (terminal: a stated reason and attempts by two agents, closed, '
             f'not resolved): {share(result.terminal_no_route, result.total)}',
             f'data conformant, still open: {share(result.open_data, result.total)}',
             f'tool gaps accepted (a second attempt by another agent or an owner acceptance, counted resolved, not '
             f'proven): {result.accepted_tool_gaps}',
             f'tool gaps pending (one agent\'s attempt only, counted unresolved): {result.pending_tool_gaps}',
             f'clauses resolved (proven or accepted tool gap): {share(result.resolved, result.total)}',
             f'not measured (CalcValue read of an effect whose amount a CalcAmount hook sets, counted unproven): '
             f'{len(result.not_measured)}',
             f'readbacks promoted by a K3 consumption row (the acting reading moved under a server mutant): '
             f'{len(result.promoted)}',
             f'readbacks shown not consumed by a K3 row (the acting reading did not move, kept as data): '
             f'{len(result.not_consumed)}', '']
    for title, labels in (('K3 promoted labels:', result.promoted), ('K3 not consumed labels:', result.not_consumed)):
        if labels:
            lines.append(title)
            lines += [f'  {label}' for label in sorted(labels)]
    if result.project_text:
        lines.append('Judged against a project-written text, no independent expectation (counted unproven):')
        lines += [f"  spell {clause.get('spell')}: {clause.get('clause')}" for clause in result.project_text]
    if result.not_measured:
        lines.append('Not measured labels:')
        lines += [f'  {label}' for label in result.not_measured]
    if result.unproven:
        lines.append('Unproven clauses:')
        found = {id(clause): statuses for (clause, _), statuses in zip(result.evidence, result.claim_evidence)}
        for clause in result.unproven:
            if DECLARED_CLAIMS not in clause:
                lines.append(f"  spell {clause.get('spell')}: {clause.get('clause')} "
                            f"(labels {clause.get('labels') or []})")
                continue
            lines.append(f"  spell {clause.get('spell')}: {clause.get('clause')}")
            for claim, status in zip(clause_claims(clause), found.get(id(clause), [])):
                lines.append(f"    claim {claim[CLAIM_WORDS]!r}: {status} (labels {claim['labels']})")
    if result.tool_gaps:
        lines.append('Tool gaps (ADR 0127):')
        for clause, state in result.tool_gaps:
            gap = clause[TOOL_GAP]
            agents = ', '.join(attempt['agent'] for attempt in gap['attempts'])
            accepted = f"; owner acceptance {gap['owner_acceptance']['ruling']}" if gap.get('owner_acceptance') else ''
            lines.append(f"  spell {clause.get('spell')}: {clause.get('clause')}: {state} ({gap['reason']}; attempts "
                         f"by {agents}{accepted})")
    if result.no_routes:
        lines.append('No behaviour route:')
        for clause, state in result.no_routes:
            declared = clause[NO_BEHAVIOUR_ROUTE]
            agents = ', '.join(attempt['agent'] for attempt in declared['attempts'])
            lines.append(f"  spell {clause.get('spell')}: {clause.get('clause')}: {state} ({declared['reason']}; "
                         f"attempts by {agents})")
    return lines


def claim_rows(clause: dict, statuses: list[str], sha: str) -> list[dict]:
    rows = evidence_rows(clause, statuses, sha)
    if NO_BEHAVIOUR_ROUTE in clause:
        state = no_route_state(clause, claims_evidence(statuses))
        rows = [{**row, NO_BEHAVIOUR_ROUTE: clause[NO_BEHAVIOUR_ROUTE], 'no_behaviour_route_state': state}
                for row in rows]
    if TOOL_GAP not in clause:
        return rows
    return [{**row, TOOL_GAP: clause[TOOL_GAP], 'tool_gap_state': tool_gap_state(clause)}
            if row['evidence'] == UNPROVEN else row for row in rows]


def evidence_rows(clause: dict, statuses: list[str], sha: str) -> list[dict]:
    claims = clause_claims(clause)
    status = claims_evidence(statuses)
    if DECLARED_CLAIMS not in clause:
        return [{'spell': clause['spell'], 'clause': clause['clause'], **(
            {CLAIM_WORDS: clause[CLAIM_WORDS]} if CLAIM_WORDS in clause else {}), 'labels': claims[0]['labels'],
            'kind': 'claim', 'evidence': status, 'spell_dbc_sha256': sha}]
    if status != UNPROVEN:
        return [{'spell': clause['spell'], 'clause': clause['clause'],
                 DECLARED_CLAIMS: [{**claim, 'evidence': found} for claim, found in zip(claims, statuses)],
                 'kind': 'claim', 'evidence': status, 'spell_dbc_sha256': sha}]
    return [{'spell': clause['spell'], 'clause': clause['clause'], CLAIM_WORDS: claim[CLAIM_WORDS],
             'labels': claim['labels'], 'kind': 'claim', 'evidence': found, 'spell_dbc_sha256': sha}
            for claim, found in zip(claims, statuses)]


def fragment_entries(result: ClauseCoverage, header: dict) -> list[dict]:
    sha = require_server_sha(header.get('spell_dbc_sha256'), f'verdicts of {header.get("results")}')
    return [row for (clause, _), statuses in zip(result.evidence, result.claim_evidence)
            for row in claim_rows(clause, statuses, sha)]


def write_fragment(path: Path, entries: list[dict]) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(entries, indent=2) + '\n')
    return path


def read_fragment(path: Path) -> list[dict]:
    entries = json.loads(Path(path).read_text(encoding='utf-8'))
    if not isinstance(entries, list):
        raise EvidenceError(f'{path} holds {type(entries).__name__}, not a JSON array of ledger entries')
    for index, entry in enumerate(entries):
        try:
            require_server_sha(entry.get('spell_dbc_sha256'), f'{path}[{index}]')
        except DbcSetMismatch as error:
            raise EvidenceError(str(error)) from error
    return entries


def write_coverage(before_dir: Path, after_dir: Path, out_dir: Path) -> Path:
    before_header, before = read_verdicts(before_dir)
    after_header, after = read_verdicts(after_dir)
    if before_header['class_id'] != after_header['class_id']:
        raise ValueError(f'class {before_header["class_id"]} before, class {after_header["class_id"]} after')
    require_build(before, before_header.get('build'), f'coverage of {before_dir}')
    require_build(after, after_header.get('build'), f'coverage of {after_dir}')
    headers = (before_header, after_header)
    results = (coverage(before_header, before), coverage(after_header, after))
    sets = (spell_sets(before_header, before), spell_sets(after_header, after))
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / COVERAGE_FILE
    path.write_text('\n'.join(coverage_lines(Path(before_dir), Path(after_dir), headers, results, sets)),
                    encoding='utf-8')
    return path
