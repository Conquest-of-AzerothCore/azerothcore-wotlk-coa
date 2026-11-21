from collections import Counter
import json
from pathlib import Path
import re

from class_map import CONDITION, LITERAL, MARKUP, TOKEN, family_masks, token_kind
from compare import CONFORMANT
from tooltip import Unreadable

JUDGED = CONFORMANT | {'alert'}
ID_WORD = r'(?<![\w.]){}(?![\w])'
SPELL_MARKUP = re.compile(r'@s:(\d+):')
TOKEN_SPELL = re.compile(r'\$(\d{3,})')
QUOTED = re.compile(r'"([^"]+)"')
CLASS_SOURCE_GLOB = 'src/server/coa/**/Ascension{}*'
FAMILY_WORDS = range(3)
EVIDENCE_BUCKETS = {'unproven': 'U', 'data': 'D'}
OUT_OF_SCOPE = 'out_of_scope'
ALERT_BUCKET = 'A'


class BucketError(ValueError):
    pass


def tokens_of(text: str) -> list[str]:
    return TOKEN.findall(CONDITION.sub('', MARKUP.sub(' ', text)))


def literals_of(text: str) -> list[str]:
    return LITERAL.findall(TOKEN.sub(' ', CONDITION.sub('', MARKUP.sub(' ', text))))


def clause_token_kind(tokens: list[str], literals: list[str]) -> str:
    kinds = sorted({token_kind(token) for token in tokens})
    if not kinds:
        return 'literal' if literals else 'prose'
    return '+'.join(kinds + (['literal'] if literals else []))


def class_glob(class_name: str) -> str:
    return CLASS_SOURCE_GLOB.format(re.sub(r'\W', '', class_name))


def read_sources(root: Path, paths: list[str] | None = None, pattern: str | None = None) -> dict[str, str]:
    root = Path(root)
    found = [root / path for path in paths] if paths is not None else sorted(root.glob(pattern))
    return {path.relative_to(root).as_posix(): path.read_text(encoding='utf-8') for path in found}


def source_masks(sources: dict[str, str]) -> list[tuple[int, int]]:
    return sorted({mask for text in sources.values() for mask in family_masks(text)})


def id_hits(sources: dict[str, str], spell: int) -> list[str]:
    pattern = re.compile(ID_WORD.format(spell))
    return sorted(f'{path}:{number}' for path, text in sources.items()
                  for number, line in enumerate(text.splitlines(), 1) if pattern.search(line))


def family_hits(records, spell: int, family: int, masks: list[tuple[int, int]]) -> list[str]:
    try:
        if records.field('Spell', spell, 'SpellFamilyName') != family:
            return []
        flags = [records.field('Spell', spell, f'SpellFamilyFlags[{word}]') for word in FAMILY_WORDS]
    except Unreadable:
        return []
    return [f'SpellFamilyFlags[{word}] & {mask}' for word, mask in masks if flags[word] & mask]


def class_family(records, spells: list[int]) -> int:
    families = Counter()
    for spell in spells:
        try:
            families[records.field('Spell', spell, 'SpellFamilyName')] += 1
        except Unreadable:
            continue
    if not families:
        raise BucketError('no class spell has a readable SpellFamilyName')
    return families.most_common(1)[0][0]


def value_scenarios(manifest: dict) -> list[dict]:
    return [entry for entry in manifest.get('scenarios', []) if entry['kind'] == 'value']


def readbacks(manifest: dict) -> dict[tuple[int, str], list[str]]:
    found = {}
    for entry in value_scenarios(manifest):
        for data in entry['expectations']:
            found.setdefault((data['spell_id'], data['displayed']), []).append(data['label'])
            found.setdefault((data['rank_id'], data['displayed']), []).append(data['label'])
    return found


def ranks(manifest: dict) -> dict[int, set[int]]:
    found = {}
    for entry in value_scenarios(manifest):
        found.setdefault(entry['spell_id'], set()).add(entry['rank_id'])
    return found


def spell_names(manifest: dict) -> dict[int, str]:
    return {entry['spell_id']: entry['spell_name'] for entry in manifest.get('scenarios', [])
            if entry.get('spell_name')}


def spell_name(records, names: dict[int, str], spell: int) -> str | None:
    if spell in names:
        return names[spell]
    try:
        return records.field('Spell', spell, 'SpellName[enUS]')
    except Unreadable:
        return None


def uncited_alert_quotes(manifest: dict, class_file: dict, statuses: dict[str, str],
                         cited: set[str]) -> dict[str, set[str]]:
    quotes = {}
    for entry in manifest.get('scenarios', []):
        for data in entry['expectations']:
            if statuses.get(data['label']) == 'alert' and data['label'] not in cited:
                quotes.setdefault(data['label'], set()).update(QUOTED.findall(data['rule']))
    for label in quotes:
        for gate in class_file.get('target_aura_gates', []):
            if label == f"{gate['rank']} hit_mean {gate.get('label_suffix', '')}" and gate.get('quote'):
                quotes[label].add(gate['quote'])
    return quotes


def clause_keys(rows, what: str) -> dict[tuple[int, str], str]:
    found = {}
    for index, row in enumerate(rows):
        if not isinstance(row, dict) or not isinstance(row.get('spell'), int) or not isinstance(row.get('clause'), str):
            raise BucketError(f'{what}[{index}] is not {{"spell": <int>, "clause": <text>, ...}}')
        found[(row['spell'], row['clause'])] = row.get('why', '')
    return found


def token_readbacks(tokens: list[str], spell: int, by_token: dict, statuses: dict[str, str]) -> dict[str, dict]:
    reads = {}
    for token in tokens:
        reads[token] = {label: statuses.get(label) for label in sorted(set(by_token.get((spell, token), [])))}
    return reads


def all_reads_in(reads: dict[str, dict], allowed: frozenset[str]) -> bool:
    return bool(reads) and all(found and all(status in allowed for status in found.values())
                               for found in reads.values())


def bucket_of(evidence: str, alert_source: list[str]) -> str:
    if alert_source:
        return ALERT_BUCKET
    if evidence == 'behaviour':
        return OUT_OF_SCOPE
    return EVIDENCE_BUCKETS[evidence]


def bucket_rows(coverage: dict, manifest: dict, class_file: dict, sources: dict[str, str], family: int, records,
                settled: dict, standing: dict, standing_name: str) -> tuple[list[dict], dict[str, set[str]]]:
    masks = source_masks(sources)
    by_token, rank_ids, names = readbacks(manifest), ranks(manifest), spell_names(manifest)
    statuses = coverage['statuses']
    cited = {label for clause in coverage['clauses'] for label in clause['label_statuses']}
    attached = uncited_alert_quotes(manifest, class_file, statuses, cited)
    rows = []
    for clause in coverage['clauses']:
        spell, text = clause['spell'], clause['clause']
        tokens, literals = tokens_of(text), literals_of(text)
        token_spells = ({int(number) for token in tokens for number in TOKEN_SPELL.findall(token)}
                        | {int(number) for number in SPELL_MARKUP.findall(text)})
        touch = {}
        for identity in sorted({spell} | rank_ids.get(spell, set()) | token_spells):
            hits = {'id': id_hits(sources, identity), 'family': family_hits(records, identity, family, masks)}
            if hits['id'] or hits['family']:
                touch[str(identity)] = hits
        reads = token_readbacks(tokens, spell, by_token, statuses)
        conformant_reads = all_reads_in(reads, CONFORMANT)
        key = (spell, text)
        alert_source = [f'standing alert ({standing_name})'] if key in standing else []
        if clause['alert_labels']:
            alert_source.append(f'alert label {clause["alert_labels"]}')
        alert_source += [f'uncited alert verdict {label} quotes this clause' for label, texts in sorted(attached.items())
                         if text.strip() in {quoted.strip() for quoted in texts}]
        if key in settled:
            alert_source = []
        bucket = bucket_of(clause['evidence'], alert_source)
        rows.append({'index': clause['index'], 'spell': spell, 'spell_name': spell_name(records, names, spell),
                     'clause': text, 'bucket': bucket, 'evidence': clause['evidence'], 'alert_source': alert_source,
                     'script_touch': bool(touch), 'script_touch_hits': touch,
                     'token_kind': clause_token_kind(tokens, literals), 'tokens': tokens, 'literals': literals,
                     'token_readbacks': reads, 'readable_token': all_reads_in(reads, JUDGED),
                     'token_readbacks_conformant': conformant_reads,
                     'declared_claims': len(clause['claim_evidence']) > 1,
                     'zero_agent_data': bucket == 'U' and conformant_reads and not literals
                     and len(clause['claim_evidence']) == 1,
                     'labels': clause['labels'], 'missing_labels': clause['missing_labels'],
                     'label_statuses': clause['label_statuses']})
    return rows, attached


def definition(source_name: str, family: int) -> dict:
    return {
        'U': 'claim clause unproven in the coverage audit, no standing alert',
        'D': 'claim clause data conformant in the coverage audit, no standing alert',
        'A': 'claim clause with a standing alert: a label resolving to an alert verdict in the audit set, an alert '
             'verdict of the audit set cited by no clause whose expectation rule or class-file target_aura_gates '
             'quote gives this clause text, or a listed standing alert; a listed settled alert clears all three',
        OUT_OF_SCOPE: 'behaviour proven in the coverage audit, no standing alert',
        'script_touch': f'the clause spell, its rank ids (value scenarios of the manifest) or a spell its tokens name '
                        f'is matched in {source_name} by id (the number as a whole word) or by family '
                        f'(SpellFamilyName {family} and SpellFamilyFlags intersecting a mask the code tests with '
                        f'Family(), SpellFamilyFlags[w] & m or flag96(...)); a bare SpellFamilyName test is not a '
                        f'family match',
        'token_kind': 'kinds of the $ tokens of the clause text (value, duration, chance, periodic_total, period, '
                      'radius, range, stacks, count, formula, variable), joined by +, plus literal when a number '
                      'stands outside a token; prose when neither',
        'zero_agent_data': 'U clause, no declared claims, no number outside a token, and every $ token has at least '
                           'one value-scenario readback of the clause spell whose displayed text is the token, all '
                           'conformant (ok, tolerated, closed) in the audit set',
        'readable_token': 'every $ token of the clause has a value-scenario readback of the clause spell whose '
                          'displayed text is the token, judged (ok, tolerated, closed or alert) in the audit set'}


def bucket_document(coverage: dict, manifest: dict, class_file: dict, sources: dict[str, str], source_name: str,
                    family: int, records, settled: dict, standing: dict, inputs: dict) -> dict:
    rows, attached = bucket_rows(coverage, manifest, class_file, sources, family, records, settled, standing,
                                 inputs.get('standing_alerts') or 'standing alerts file')
    statuses = coverage['statuses']
    uncited = sorted(label for label, status in statuses.items() if status == 'alert'
                     and not any(label in row['label_statuses'] for row in rows))
    return {'definition': definition(source_name, family),
            'inputs': {**inputs, 'family': family, 'sources': sorted(sources),
                       'settled_alerts': [{'spell': spell, 'clause': text, 'why': why}
                                          for (spell, text), why in settled.items()],
                       'family_masks': [f'SpellFamilyFlags[{word}] & {mask}' for word, mask in source_masks(sources)]},
            'uncited_alert_verdicts': uncited,
            'uncited_alert_quotes': {label: sorted(texts) for label, texts in attached.items()},
            'clauses': rows}


def bucket_counts(rows: list[dict]) -> dict[str, int]:
    return dict(sorted(Counter(row['bucket'] for row in rows).items()))


def read_json(path: Path | None, default):
    return json.loads(Path(path).read_text(encoding='utf-8')) if path else default
