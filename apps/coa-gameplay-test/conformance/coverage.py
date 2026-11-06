from dataclasses import dataclass
from pathlib import Path
import re

from compare import STATUSES, Verdict, read_verdicts
from hits import NEVER_CAST, UNMODELLED
from passives import PASSIVE_DELTA
from procs import PROC_CHECK
from triggers import TRIGGER_CHECK

COVERAGE_FILE = 'coverage.md'
JUDGED = frozenset({'ok', 'alert'})
CHARACTER_CHECKS = frozenset({'known_aura'})
BEHAVIOUR_CHECKS = frozenset({PASSIVE_DELTA, PROC_CHECK, TRIGGER_CHECK})
HIT_CHECK = 'hit_mean'
SPELL_KINDS = ('value', 'hit', 'passive')
PASSIVE_KIND = 'passive'
PLACEHOLDER_RULE = UNMODELLED + NEVER_CAST
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


@dataclass(frozen=True)
class SpellSets:
    spells: frozenset[int]
    passives: frozenset[int]
    judged: frozenset[int]
    behaviour: frozenset[int]
    hit: frozenset[int]
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
    return SpellSets(frozenset(spells), frozenset(passives), frozenset(judged), frozenset(behaviour),
                     frozenset(hit & (spells - passives)), len(placeholders))


def coverage(header: dict, verdicts: list[Verdict]) -> Coverage:
    sets = spell_sets(header, verdicts)
    counted = [verdict for verdict in verdicts if not is_placeholder(verdict)]
    statuses = {status: sum(verdict.status == status for verdict in counted) for status in STATUSES}
    return Coverage(statuses, len(sets.judged), len(sets.spells), len(sets.behaviour), len(sets.passives),
                    len(sets.hit), len(sets.spells - sets.passives))


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
             after.actives)]
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


def write_coverage(before_dir: Path, after_dir: Path, out_dir: Path) -> Path:
    before_header, before = read_verdicts(before_dir)
    after_header, after = read_verdicts(after_dir)
    if before_header['class_id'] != after_header['class_id']:
        raise ValueError(f'class {before_header["class_id"]} before, class {after_header["class_id"]} after')
    headers = (before_header, after_header)
    results = (coverage(before_header, before), coverage(after_header, after))
    sets = (spell_sets(before_header, before), spell_sets(after_header, after))
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / COVERAGE_FILE
    path.write_text('\n'.join(coverage_lines(Path(before_dir), Path(after_dir), headers, results, sets)),
                    encoding='utf-8')
    return path
