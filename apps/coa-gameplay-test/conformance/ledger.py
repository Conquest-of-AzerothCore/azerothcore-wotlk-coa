from dataclasses import dataclass
import json
from pathlib import Path
import re
import subprocess

from classes import PROGRESSION_HEADER, ClassSpell, class_spells
from coverage import FORMULA_TOKEN, LITERAL_NUMBER, TEXT_BASES, TOOLTIP_TOKEN
from streamed import SQL_DIRECTORIES, SQL_UPDATES, TABLE, StreamedText, streamed_texts
from tooltip import COLOR_CODE, EXTENSION_MARKUP, SPELL_MARKUP, Records, Tooltip, conditional_bounds
from values import Unmodelled, armed_for, dataset, static_conditional_known, structure_stats, value_scenario

REPOSITORY = Path(__file__).resolve().parents[3]
DESCRIPTION = 'Description[enUS]'
TOOLTIP = 'ToolTip[enUS]'
EMPTY_CLAUSE = '(empty tooltip)'
EMPTY_REASON = 'Tooltip field is empty; no sentence exists to carry a gameplay claim.'
LEVEL_LABEL = re.compile(r'Level \d+(?: [A-Z][a-z]+)*')
LEVEL_REASON = 'A level-availability label line, not a gameplay claim.'
ACQUISITION_NOTE = re.compile(r'@ext:\s*(?:Eastern Kingdoms|Kalimdor|Outland|Northrend):.*:ext@', re.DOTALL)
ACQUISITION_REASON = 'A client note listing where the ability is learned; acquisition information, not a mechanic.'
LINE_BREAK = re.compile(r'\r\n|\n|\r|\|n')
SENTENCE_END = '.!?'
SENTENCE_FOLLOWERS = ('$?', '@ext:')
SOFT_CUTS = (', ', ' and ')
FUNCTION_WORDS = frozenset({'a', 'an', 'and', 'at', 'by', 'for', 'from', 'her', 'his', 'in', 'it', 'its', 'of', 'on',
                            'or', 'our', 'the', 'their', 'them', 'to', 'with', 'you', 'your'})
ORDINAL = re.compile(r'^(\d+) .* #(\d+)$')
TOKEN_ENTRY_STARTS = ('$', '@')
PULL_REQUEST = re.compile(r'\((#\d+)\)\s*$')
COMMIT_DIGITS = 10


@dataclass(frozen=True)
class Segment:
    raw: str
    hard_end: bool


@dataclass(frozen=True)
class Ledger:
    entries: list[dict]
    unlabelled: dict[int, str]


def protected_end(text: str, start: int) -> int | None:
    if text.startswith('${', start):
        close = text.find('}', start)
        return len(text) if close < 0 else close + 1
    if text.startswith('$?', start):
        return conditional_bounds(text, start + 2)[4]
    if text[start] == '@':
        markup = SPELL_MARKUP.match(text, start)
        return markup.end() if markup else EXTENSION_MARKUP.match(text, start).end()
    color = COLOR_CODE.match(text, start)
    if color:
        return color.end()
    if text.startswith('|T', start):
        close = text.find('|t', start + 2)
        return len(text) if close < 0 else close + 2
    return None


def sentence_ends(text: str, position: int) -> bool:
    if text[position] not in SENTENCE_END:
        return False
    following = text[position + 1:]
    return (not following or following[0].isspace() or LINE_BREAK.match(following) is not None
            or following.startswith(SENTENCE_FOLLOWERS))


def segments(text: str) -> list[Segment]:
    found, start, position = [], 0, 0
    while position < len(text):
        end = protected_end(text, position)
        if end is not None:
            position = max(end, position + 1)
            continue
        line_break = LINE_BREAK.match(text, position)
        if line_break:
            found.append(Segment(text[start:line_break.end()], True))
            start = position = line_break.end()
            continue
        if sentence_ends(text, position):
            found.append(Segment(text[start:position + 1], True))
            start = position = position + 1
            continue
        soft = next((cut for cut in SOFT_CUTS if text.startswith(cut, position)), None)
        if soft is not None:
            cut = position + 1 if soft == ', ' else position
            found.append(Segment(text[start:cut], False))
            start = cut
            position += len(soft)
            continue
        position += 1
    if start < len(text):
        found.append(Segment(text[start:], True))
    return found


def display(raw: str) -> str:
    return SPELL_MARKUP.sub('', COLOR_CODE.sub('', raw)).strip(' \t\r\n')


def without_line_breaks(text: str) -> str:
    return LINE_BREAK.sub(' ', text).strip()


def carries_value(raw: str) -> bool:
    text = display(raw)
    rest = FORMULA_TOKEN.sub(' ', text)
    return bool(FORMULA_TOKEN.search(text) or TOOLTIP_TOKEN.search(rest)
                or LITERAL_NUMBER.search(TOOLTIP_TOKEN.sub(' ', rest)))


def sentences(text: str) -> list[list[Segment]]:
    found, current = [], []
    for segment in segments(text):
        current.append(segment)
        if segment.hard_end:
            found.append(current)
            current = []
    if current:
        found.append(current)
    return found


def cuts_between(current: str, rest: str) -> bool:
    if not (carries_value(current) and carries_value(rest)):
        return False
    words = display(current).rstrip(' ,').split()
    return bool(words) and words[-1].lower() not in FUNCTION_WORDS


def sentence_clauses(parts: list[Segment]) -> list[str]:
    clauses, current = [], ''
    for index, part in enumerate(parts):
        current += part.raw
        rest = ''.join(later.raw for later in parts[index + 1:])
        if index + 1 < len(parts) and cuts_between(current, rest):
            clauses.append(current)
            current = ''
    return clauses + [current] if current else clauses


def raw_clauses(text: str) -> list[str]:
    found: list[str] = []
    pending = ''
    for sentence in sentences(text):
        for raw in sentence_clauses(sentence):
            if not without_line_breaks(display(raw)):
                if found:
                    found[-1] += raw
                else:
                    pending += raw
                continue
            found.append(pending + raw)
            pending = ''
    if pending:
        if found:
            found[-1] += pending
        else:
            found.append(pending)
    return found


def clause_words(raw: str) -> str:
    text = display(raw)
    while True:
        trimmed = text.removeprefix('|n').removesuffix('|n').strip(' \t\r\n')
        if trimmed == text:
            return text
        text = trimmed


def no_claim_reason(words: str) -> str | None:
    if not words:
        return EMPTY_REASON
    if LEVEL_LABEL.fullmatch(words):
        return LEVEL_REASON
    if ACQUISITION_NOTE.fullmatch(words):
        return ACQUISITION_REASON
    return None


def ordinal_labels(class_file: dict, spell: ClassSpell, rank_id: int) -> dict[int, list[str]]:
    _, expectations, periodic_totals = value_scenario(class_file, spell, rank_id)
    found: dict[int, list[str]] = {}
    for label in [expectation.label for expectation in expectations] + [item['label'] for item in periodic_totals]:
        match = ORDINAL.match(label)
        if match and int(match.group(1)) == rank_id and label not in found.get(int(match.group(2)), []):
            found.setdefault(int(match.group(2)), []).append(label)
    return found


def clause_label_lists(class_file: dict, records: Records, spell: ClassSpell, rank_id: int,
                       raws: list[str]) -> list[list[str]]:
    armed_file = armed_for(class_file, records, rank_id)
    caster = structure_stats(armed_file, static_conditional_known(armed_file, rank_id))
    whole = Tooltip(records, rank_id, caster).read(''.join(raws))
    parts = [Tooltip(records, rank_id, caster).read(raw) for raw in raws]
    if [value.text for part in parts for value in part.values] != [value.text for value in whole.values] \
            or [entry for part in parts for entry in part.unreadable] != whole.unreadable:
        raise ValueError(f'Spell {rank_id}: the clauses read differently from the whole tooltip')
    by_ordinal = ordinal_labels(class_file, spell, rank_id)
    lists, value_ordinal, unreadable_ordinal = [], 0, len(whole.values)
    for part in parts:
        ordinals = list(range(value_ordinal, value_ordinal + len(part.values)))
        ordinals += [unreadable_ordinal + index for index, entry in enumerate(part.unreadable)
                     if entry.startswith(TOKEN_ENTRY_STARTS)]
        value_ordinal += len(part.values)
        unreadable_ordinal += len(part.unreadable)
        lists.append([label for ordinal in ordinals for label in by_ordinal.get(ordinal, [])])
    return lists


def first_commit(path: Path) -> tuple[str | None, str | None]:
    try:
        output = subprocess.run(['git', '-C', str(REPOSITORY), 'log', '--diff-filter=A', f'--abbrev={COMMIT_DIGITS}',
                                 '--format=%h%x00%s', '--', str(path)],
                                capture_output=True, text=True, check=True).stdout.strip().splitlines()
    except (OSError, subprocess.CalledProcessError):
        return None, None
    if not output:
        return None, None
    commit, subject = output[-1].split('\0', 1)
    pull = PULL_REQUEST.search(subject)
    return commit, pull.group(1) if pull else None


def sql_path(name: str, updates: Path) -> Path:
    return next((Path(updates) / directory / name for directory in SQL_DIRECTORIES
                 if (Path(updates) / directory / name).is_file()), Path(updates) / SQL_DIRECTORIES[0] / name)


def differing_fields(records: Records, rank_id: int, row: StreamedText) -> list[str]:
    fields = []
    if row.description != (records.dbc_field('Spell', rank_id, DESCRIPTION) or ''):
        fields.append('Description')
    if row.tooltip is not None and row.tooltip != (records.dbc_field('Spell', rank_id, TOOLTIP) or ''):
        fields.append('ToolTip')
    return fields


def text_source(records: Records, rank_id: int, row: StreamedText, basis: str, updates: Path) -> dict:
    commit, pull = first_commit(sql_path(row.file, updates))
    fields = differing_fields(records, rank_id, row)
    return {'table': TABLE, 'file': row.file, 'commit': commit, 'pr': pull, 'basis': basis, 'ruling': None,
            'spell': rank_id,
            'dbc_differs': differs_text(fields)}


def differs_text(fields: list[str]) -> str:
    if not fields:
        return 'no field differs from Spell.dbc'
    return f'{" and ".join(fields)} {"differs" if len(fields) == 1 else "differ"} from Spell.dbc'


def spell_entries(class_file: dict, records: Records, spell: ClassSpell, text_bases: dict[int, str],
                  updates: Path, unlabelled: dict[int, str]) -> list[dict]:
    rank_id = spell.max_rank
    description = records.field('Spell', rank_id, DESCRIPTION) or ''
    row = streamed_texts(updates).get(rank_id)
    source = None
    dbc_words: list[str] | None = None
    if row is not None:
        if rank_id not in text_bases:
            raise ValueError(f'Spell {rank_id} is read from {TABLE} ({row.file}); give its basis with '
                             f'--text-basis {rank_id}=<{"|".join(sorted(TEXT_BASES))}>')
        source = text_source(records, rank_id, row, text_bases[rank_id], updates)
        dbc_description = records.dbc_field('Spell', rank_id, DESCRIPTION) or ''
        if dbc_description != description:
            dbc_words = [clause_words(raw) for raw in raw_clauses(dbc_description)]
    raws = raw_clauses(description)
    if not raws or not any(clause_words(raw) for raw in raws):
        entries = [{'spell': rank_id, 'clause': EMPTY_CLAUSE, 'labels': [], 'kind': 'no_claim',
                    'reason': EMPTY_REASON}]
    else:
        try:
            labels = clause_label_lists(class_file, records, spell, rank_id, raws)
        except Unmodelled as error:
            unlabelled[rank_id] = error.reason
            labels = [[] for _ in raws]
        entries = []
        for index, (raw, clause_labels) in enumerate(zip(raws, labels)):
            words = clause_words(raw)
            reason = no_claim_reason(words)
            entry = {'spell': rank_id, 'clause': words, 'labels': [] if reason else clause_labels,
                     'kind': 'no_claim' if reason else 'claim'}
            if reason:
                entry['reason'] = reason
            if dbc_words is not None:
                dbc_clause = (dbc_words[index] if len(dbc_words) == len(raws)
                              else ' '.join(dbc_words))
                if dbc_clause != words:
                    entry['dbc_clause'] = dbc_clause
            entries.append(entry)
    if source is not None:
        entries = [{**entry, 'text_source': source} for entry in entries]
    return entries


def ledger(class_file: dict, dbc_dir: Path, text_bases: dict[int, str] | None = None,
           updates: Path = SQL_UPDATES) -> Ledger:
    text_bases = dict(text_bases or {})
    unknown = sorted(basis for basis in text_bases.values() if basis not in TEXT_BASES)
    if unknown:
        raise ValueError(f'Text bases {unknown} are not among {sorted(TEXT_BASES)}')
    class_file = {**class_file, 'dbc_dir': str(dbc_dir)}
    records = Records(dataset(Path(dbc_dir)))
    spells = class_spells(Path(dbc_dir), class_file['class_id'], PROGRESSION_HEADER, class_file['level'],
                          [entry['spell'] for entry in class_file.get('extra_spells', [])])
    unlabelled: dict[int, str] = {}
    entries = [entry for spell in spells
               for entry in spell_entries(class_file, records, spell, text_bases, updates, unlabelled)]
    return Ledger(entries, unlabelled)


def parse_text_bases(items: list[str] | None) -> dict[int, str]:
    bases: dict[int, str] = {}
    for item in items or []:
        spell, separator, basis = item.partition('=')
        if not separator or not spell.strip().isdigit():
            raise ValueError(f'--text-basis {item!r} is not <spell>=<basis>')
        if int(spell) in bases:
            raise ValueError(f'--text-basis names spell {spell} twice')
        bases[int(spell)] = basis.strip()
    return bases


def write_ledger(entries: list[dict], out: Path):
    out = Path(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(entries, indent=2, ensure_ascii=False) + '\n')
