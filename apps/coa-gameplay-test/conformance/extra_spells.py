from collections import Counter
from pathlib import Path
import re

from classes import (CHARACTER_LEVEL, PROGRESSION_HEADER, class_spells, dataset, progression_chains,
                     rows_by_identity)
from streamed import SQL_DIRECTORIES, rows as sql_rows, statements as sql_statements, streamed_field
from tooltip import DESCRIPTION, PASSIVE_ATTRIBUTE, SPELL_MARKUP, Records, expansion_refusal

REPOSITORY = Path(__file__).resolve().parents[3]
CUSTOM_CLASS_HEADER = Path('src/server/coa/AscensionCustomClassData.h')
LIVE_BASELINE_HEADER = Path('src/server/coa/AscensionLiveBaselineData.h')
TAUGHT_ABILITY_HEADER = Path('src/server/coa/AscensionTaughtAbilityData.h')
COMPAT_SOURCE = Path('src/server/coa/AscensionCompat.cpp')
BASE_TRAINER_SQL = Path('data/sql/base/db_world/trainer_spell.sql')
UPDATES_ROOT = Path('data/sql')

TRAINER_CLASS_MIN = 900012
TRAINER_CLASS_MAX = 900032
TRAINER_CLASS_OFFSET = 900000
TRAINER_SPELL_COLUMNS = ('TrainerId', 'SpellId', 'MoneyCost', 'ReqSkillLine', 'ReqSkillRank',
                         'ReqAbility1', 'ReqAbility2', 'ReqAbility3', 'ReqLevel', 'VerifiedBuild')
CAST_EVENTS = frozenset({'SPELL_CAST_SUCCESS', 'SPELL_CAST_START'})
WHITESPACE = re.compile(r'\s+')
LINE_THREE_INTS = re.compile(r'\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}')
LINE_FIVE_INTS = re.compile(r'\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}')
LINE_TWO_INTS = re.compile(r'\{\s*(\d+)\s*,\s*(\d+)\s*\}')
TRAINER_DELETE = re.compile(r'(?is)^DELETE\s+FROM\s+`?trainer_spell`?(?:\s+WHERE\s+(.*))?$')
TRAINER_INSERT = re.compile(r'(?is)^(?:INSERT\s+(?:IGNORE\s+)?INTO|REPLACE\s+INTO)\s+`?trainer_spell`?'
                            r'\s*(?:\(([^)]*)\)\s*)?VALUES\b(.*)$')
SPELL_FIELDS = ['SpellName[enUS]', 'Rank[enUS]', 'Description[enUS]', 'Attributes']
TOOLTIP_PREVIEW_CHARS = 180

STOCK_GENERIC_SPELLS = frozenset({
    75, 81, 107, 196, 197, 198, 199, 200, 201, 202, 227, 264, 266, 674, 750, 1180, 2567, 2764,
    3018, 3124, 3127, 5009, 5011, 5019, 6603, 8613, 8737, 9077, 9078, 9116, 15590, 28875,
    33379, 33388, 33391, 34090, 34091, 54197,
})


class ExtraSpellsError(ValueError):
    pass


def log_events(path: Path | None) -> tuple[Counter, Counter]:
    casts, others = Counter(), Counter()
    if path and Path(path).exists():
        for line in Path(path).read_text(encoding='utf-8').splitlines():
            if not line.strip():
                continue
            event, spell, count = line.rsplit(',', 2)
            (casts if event in CAST_EVENTS else others)[int(spell)] += int(count)
    return casts, others


def array_block(path: Path, name: str) -> str:
    if not path.is_file():
        return ''
    text = path.read_text(encoding='utf-8', errors='replace')
    match = re.search(rf'\b{re.escape(name)}\s*=\s*(.*?)\}};', text, re.S)
    return match.group(1) if match else ''


def class_spells_table(root: Path = REPOSITORY) -> dict[int, dict[int, int]]:
    block = array_block(Path(root) / CUSTOM_CLASS_HEADER, 'ClassSpells')
    found: dict[int, dict[int, int]] = {}
    for class_text, level_text, spell_text in LINE_THREE_INTS.findall(block):
        class_id, level, spell_id = int(class_text), int(level_text), int(spell_text)
        per_class = found.setdefault(class_id, {})
        per_class[spell_id] = min(per_class.get(spell_id, level), level)
    return found


def live_baseline_spells(root: Path = REPOSITORY) -> dict[int, set[int]]:
    block = array_block(Path(root) / LIVE_BASELINE_HEADER, 'Spells')
    found: dict[int, set[int]] = {}
    for class_text, race_text, spell_text in LINE_THREE_INTS.findall(block):
        if int(race_text) == 0:
            found.setdefault(int(class_text), set()).add(int(spell_text))
    return found


def taught_abilities(root: Path = REPOSITORY) -> dict[int, dict[int, tuple[int, int]]]:
    block = array_block(Path(root) / TAUGHT_ABILITY_HEADER, 'TaughtAbilities')
    found: dict[int, dict[int, tuple[int, int]]] = {}
    for class_text, _, level_text, parent_text, spell_text in LINE_FIVE_INTS.findall(block):
        class_id, level, parent_id, spell_id = int(class_text), int(level_text), int(parent_text), int(spell_text)
        per_class = found.setdefault(class_id, {})
        if spell_id not in per_class or level < per_class[spell_id][0]:
            per_class[spell_id] = (level, parent_id)
    return found


def felsworn_rifts(root: Path = REPOSITORY) -> dict[int, int]:
    block = array_block(Path(root) / COMPAT_SOURCE, 'FelswornHordeCapitalRifts')
    found: dict[int, int] = {}
    for spell_text, level_text in LINE_TWO_INTS.findall(block):
        spell_id, level = int(spell_text), int(level_text)
        found[spell_id] = min(found.get(spell_id, level), level)
    return found


def sql_column_ids(text: str, column: str) -> set[int] | None:
    match = re.search(rf'`?{column}`?\s*(?:=\s*(\d+)|IN\s*\(([^)]*)\))', text, re.I)
    if not match:
        return None
    return {int(value) for value in re.findall(r'\d+', match.group(1) or match.group(2))}


def apply_trainer_delete(active: dict[tuple[int, int], int], where_clause: str | None) -> None:
    if where_clause is None:
        active.clear()
        return
    for group in re.split(r'\bOR\b', where_clause, flags=re.I):
        trainers = sql_column_ids(group, 'TrainerId')
        spells = sql_column_ids(group, 'SpellId')
        if trainers is None and spells is None:
            continue
        for key in list(active):
            trainer_id, spell_id = key
            if (trainers is None or trainer_id in trainers) and (spells is None or spell_id in spells):
                del active[key]


def apply_trainer_insert(active: dict[tuple[int, int], int], columns_text: str | None, values_text: str) -> None:
    columns = [col.strip(' `\r\n\t') for col in columns_text.split(',')] if columns_text else list(TRAINER_SPELL_COLUMNS)
    for row in sql_rows(values_text):
        if len(row) != len(columns):
            continue
        fields = dict(zip(columns, row))
        try:
            trainer_id = int(fields['TrainerId'])
            spell_id = int(fields['SpellId'])
            req_level = int(fields.get('ReqLevel') or 0)
        except (KeyError, TypeError, ValueError):
            continue
        if TRAINER_CLASS_MIN <= trainer_id <= TRAINER_CLASS_MAX:
            active[(trainer_id, spell_id)] = req_level


def trainer_spells(root: Path = REPOSITORY) -> dict[int, dict[int, int]]:
    root = Path(root)
    files = [root / BASE_TRAINER_SQL]
    for directory in SQL_DIRECTORIES:
        folder = root / UPDATES_ROOT / 'updates' / directory
        if folder.is_dir():
            files += sorted(folder.glob('*.sql'), key=lambda path: path.name)
    active: dict[tuple[int, int], int] = {}
    for path in files:
        if not path.is_file():
            continue
        text = path.read_text(encoding='utf-8', errors='replace')
        if 'trainer_spell' not in text.lower():
            continue
        for statement in sql_statements(text):
            if 'trainer_spell' not in statement.lower():
                continue
            deleted = TRAINER_DELETE.match(statement)
            if deleted:
                apply_trainer_delete(active, deleted.group(1))
                continue
            inserted = TRAINER_INSERT.match(statement)
            if inserted:
                apply_trainer_insert(active, inserted.group(1), inserted.group(2))
    by_class: dict[int, dict[int, int]] = {}
    for (trainer_id, spell_id), req_level in active.items():
        class_id = trainer_id - TRAINER_CLASS_OFFSET
        per_class = by_class.setdefault(class_id, {})
        per_class[spell_id] = min(per_class.get(spell_id, req_level), req_level)
    return by_class


def server_candidates(root: Path, class_id: int, level: int = CHARACTER_LEVEL) -> dict[int, list[str]]:
    sources: dict[int, set[str]] = {}
    for spell_id, req_level in class_spells_table(root).get(class_id, {}).items():
        if req_level <= level:
            sources.setdefault(spell_id, set()).add(f'ClassSpells(L{req_level})')
    for spell_id in live_baseline_spells(root).get(class_id, ()):
        sources.setdefault(spell_id, set()).add('LiveBaseline')
    for spell_id, (req_level, parent_id) in taught_abilities(root).get(class_id, {}).items():
        if req_level <= level:
            sources.setdefault(spell_id, set()).add(f'TaughtAbilities(L{req_level}, parent={parent_id})')
    if class_id == 14:
        for spell_id, req_level in felsworn_rifts(root).items():
            if req_level <= level:
                sources.setdefault(spell_id, set()).add(f'FelswornRifts(L{req_level})')
    for spell_id, req_level in trainer_spells(root).get(class_id, {}).items():
        if req_level <= level:
            sources.setdefault(spell_id, set()).add(f'trainer_spell(L{req_level})')
    return {spell_id: sorted(tags) for spell_id, tags in sorted(sources.items())}


def validate_excluded_extra_spells(entries, advancement_ids: set[int], extra_ids: set[int]) -> dict[int, dict]:
    if not isinstance(entries, list):
        raise ExtraSpellsError('excluded_extra_spells must be a list')
    by_id: dict[int, dict] = {}
    for item in entries:
        if not isinstance(item, dict):
            raise ExtraSpellsError('each excluded_extra_spells entry must be an object')
        spell = item.get('spell')
        name = item.get('name')
        reason = item.get('reason')
        if isinstance(spell, bool) or not isinstance(spell, int) or spell <= 0:
            raise ExtraSpellsError(f'excluded_extra_spells entry has invalid spell id {spell!r}')
        if not isinstance(name, str) or not name.strip():
            raise ExtraSpellsError(f'excluded_extra_spells {spell} needs a non-empty name')
        if not isinstance(reason, str) or not reason.strip():
            raise ExtraSpellsError(f'excluded_extra_spells {spell} needs a non-empty reason')
        if spell in by_id:
            raise ExtraSpellsError(f'excluded_extra_spells lists {spell} more than once')
        if spell in advancement_ids:
            raise ExtraSpellsError(f'excluded_extra_spells {spell} is already a CharacterAdvancement class spell')
        if spell in extra_ids:
            raise ExtraSpellsError(f'excluded_extra_spells {spell} is already in extra_spells')
        by_id[spell] = item
    return by_id


def spell_description(records: Records, spell_id: int, updates: Path) -> str:
    if updates.is_dir():
        streamed = streamed_field(spell_id, DESCRIPTION, updates)
        if streamed is not None:
            return streamed
    return (records.dbc_field('Spell', spell_id, DESCRIPTION) or '') if records.has_spell(spell_id) else ''


def walk_pulled_spells(records: Records, spell_id: int, expanding: tuple[int, ...], updates: Path, found: set[int]) -> None:
    description = spell_description(records, spell_id, updates)
    chain = expanding + (spell_id,)
    for markup in SPELL_MARKUP.finditer(description):
        if expansion_refusal(records, markup, chain) is not None:
            continue
        pulled = int(markup.group('spell'))
        found.add(pulled)
        walk_pulled_spells(records, pulled, chain, updates, found)


def pulled_spells(records: Records, covered_list: list, updates: Path) -> set[int]:
    found: set[int] = set()
    for spell in covered_list:
        walk_pulled_spells(records, spell.max_rank, (), updates, found)
    return found


def resolve_progression_header(source_root: Path, progression_header: Path | None) -> Path:
    if progression_header is not None:
        return Path(progression_header)
    candidate = Path(source_root) / 'src/server/coa/AscensionSpellProgressionData.h'
    return candidate if candidate.is_file() else PROGRESSION_HEADER


def compact_tooltip(text: str) -> str:
    cleaned = WHITESPACE.sub(' ', text or '').strip()
    if len(cleaned) <= TOOLTIP_PREVIEW_CHARS:
        return cleaned
    return cleaned[:TOOLTIP_PREVIEW_CHARS - 3].rstrip() + '...'


def audit_extra_spells(class_file: dict, dbc_dir: Path, source_root: Path = REPOSITORY,
                       progression_header: Path | None = None, log_events_path: Path | None = None) -> dict:
    class_id = int(class_file['class_id'])
    level = int(class_file.get('level', CHARACTER_LEVEL))
    source_root = Path(source_root)
    dbc_dir = Path(dbc_dir)
    header = resolve_progression_header(source_root, progression_header)
    dbc = dataset(dbc_dir)
    records = Records(dbc)
    ca_list = class_spells(dbc_dir, class_id, header, level)
    advancement_ids = {spell.spell_id for spell in ca_list}
    extra_ids = [entry['spell'] for entry in class_file.get('extra_spells', [])]
    excluded_by_id = validate_excluded_extra_spells(class_file.get('excluded_extra_spells', []),
                                                    advancement_ids, set(extra_ids))
    covered_list = class_spells(dbc_dir, class_id, header, level, extra_spells=extra_ids)
    covered_base = {spell.spell_id for spell in covered_list}
    covered_ranks = {rank for spell in covered_list for rank in spell.ranks}
    chains = progression_chains(dbc, header, class_id)
    rank_to_first = {first: first for first in chains} | {
        rank: first for first, chain in chains.items() for rank, _ in chain}
    updates = source_root / UPDATES_ROOT / 'updates'
    pulled_ids = pulled_spells(records, covered_list, updates)

    raw_candidates = server_candidates(source_root, class_id, level)
    collapsed: dict[int, set[str]] = {}
    for spell_id, srcs in raw_candidates.items():
        base = rank_to_first.get(spell_id, spell_id)
        collapsed.setdefault(base, set()).update(srcs)

    covered_name_sources = sorted({spell.max_rank for spell in covered_list} | pulled_ids)
    candidate_ranks: dict[int, tuple[int, ...]] = {}
    for base in collapsed:
        chain = chains.get(base, [])
        all_ranks = (base,) + tuple(rank for rank, _ in chain)
        candidate_ranks[base] = all_ranks
    needed_ids = set(covered_name_sources) | {rank for ranks in candidate_ranks.values() for rank in ranks}
    spell_rows = rows_by_identity(dbc, 'Spell', needed_ids, SPELL_FIELDS)

    covered_names: dict[str, list[int]] = {}
    for spell_id in covered_name_sources:
        row = spell_rows.get(spell_id)
        if row and row['SpellName[enUS]']:
            covered_names.setdefault(row['SpellName[enUS]'], []).append(spell_id)
    for name in covered_names:
        covered_names[name] = sorted(set(covered_names[name]))

    casts, others = log_events(log_events_path)
    covered_candidates = 0
    excluded, stock_generic, unchained_ranks, unaccounted = [], [], [], []
    for base, srcs_set in sorted(collapsed.items()):
        if base in covered_base or base in covered_ranks or base in pulled_ids:
            covered_candidates += 1
            continue
        if base not in spell_rows:
            continue
        srcs = sorted(srcs_set)
        row = spell_rows[base]
        name = row['SpellName[enUS]'] or ''
        if base in excluded_by_id:
            excluded.append({'spell': base, 'name': name, 'reason': excluded_by_id[base]['reason'], 'sources': srcs})
            continue
        if base in STOCK_GENERIC_SPELLS:
            stock_generic.append({'spell': base, 'name': name, 'sources': srcs})
            continue
        all_ranks = candidate_ranks[base]
        log_cast_count = sum(casts[rank] for rank in all_ranks)
        log_other_count = sum(others[rank] for rank in all_ranks)
        if name and name in covered_names:
            unchained_ranks.append({
                'spell': base, 'name': name, 'rank': row['Rank[enUS]'] or '',
                'covered_as': covered_names[name], 'sources': srcs,
                'log_casts': log_cast_count, 'log_other_events': log_other_count})
            continue
        reached = [base] + [rank for rank, required_level in chains.get(base, []) if required_level <= level]
        max_rank = reached[-1]
        max_row = spell_rows.get(max_rank, row)
        unaccounted.append({
            'spell': base, 'max_rank': max_rank, 'ranks': len(all_ranks), 'name': name,
            'passive': bool(row['Attributes'] & PASSIVE_ATTRIBUTE), 'sources': srcs,
            'tooltip': compact_tooltip(max_row['Description[enUS]'] or ''),
            'log_casts': log_cast_count, 'log_other_events': log_other_count})

    return {
        'class_id': class_id,
        'name': class_file.get('name', ''),
        'level': level,
        'counts': {
            'advancement': len(ca_list),
            'extra_spells': len(extra_ids),
            'covered_candidates': covered_candidates,
            'excluded': len(excluded),
            'stock_generic': len(stock_generic),
            'unchained_ranks': len(unchained_ranks),
            'unaccounted': len(unaccounted),
        },
        'unaccounted': unaccounted,
        'unchained_ranks': unchained_ranks,
        'excluded': excluded,
        'stock_generic': stock_generic,
    }


def audit_extra_lines(report: dict) -> list[str]:
    counts = report['counts']
    lines = [
        f"class {report['class_id']} ({report['name']}, L{report['level']}): "
        f"advancement={counts['advancement']} extra={counts['extra_spells']} "
        f"excluded={counts['excluded']} stock={counts['stock_generic']} "
        f"unchained={counts['unchained_ranks']} unaccounted={counts['unaccounted']}"
    ]
    for entry in report['unaccounted']:
        lines.append(
            f"UNACCOUNTED\t{entry['spell']}\tmax={entry['max_rank']} ({entry['ranks']}r)\t"
            f"{'P' if entry['passive'] else 'A'}\t{entry['name']}\t"
            f"logs={entry['log_casts']}c/{entry['log_other_events']}e\t{', '.join(entry['sources'])}")
    for entry in report['unchained_ranks']:
        lines.append(
            f"UNCHAINED_RANK\t{entry['spell']}\t{entry['name']} ({entry['rank']})\t"
            f"covered_as={entry['covered_as']}\t"
            f"logs={entry['log_casts']}c/{entry['log_other_events']}e\t{', '.join(entry['sources'])}")
    return lines
