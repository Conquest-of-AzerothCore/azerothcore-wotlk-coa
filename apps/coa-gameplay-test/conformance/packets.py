from dataclasses import dataclass
import json
from pathlib import Path
from typing import Iterable, Mapping, Sequence

from behaviours import KINDS
from hits import reference_caster
from tooltip import Readout, Records, Unreadable, read_tooltip
from values import EFFECTS, dataset

CHECK_SECTIONS = ('behaviours', 'procs', 'triggers', 'talent_modifiers', 'target_aura_gates', 'learned_hits',
                  'player_observations', 'player_tooltip_readings')
SPELL_FIELDS = ('spell', 'rank', 'talent', 'gate_spell', 'proc_spell', 'aura', 'aura_spell', 'trial_spell',
                'observe_spell')
EFFECT_FIELDS = ('Effect', 'EffectBasePoints', 'EffectDieSides', 'EffectApplyAuraName', 'EffectMiscValue',
                 'EffectMiscValueB', 'EffectTriggerSpell', 'EffectImplicitTargetA', 'EffectImplicitTargetB',
                 'EffectRadiusIndex', 'EffectAmplitude', 'EffectMechanic', 'EffectChainTarget')
SPELL_LEVEL_FIELDS = ('SpellFamilyName', 'SpellFamilyFlags[0]', 'SpellFamilyFlags[1]', 'SpellFamilyFlags[2]',
                      'DurationIndex', 'StackAmount', 'ProcFlags', 'ProcChance', 'ProcCharges', 'RecoveryTime',
                      'CategoryRecoveryTime', 'Attributes')
CLASS_MAP_FIELDS = ('risk', 'gap', 'custom_mechanics', 'log_casts', 'log_other_events', 'log_linked_events')
CLASS_MAP_HIT_FIELDS = ('code_hits', 'data_hits', 'family_hits', 'core_hits', 'script_only', 'custom_mechanics')
LABEL_SECTIONS = (('trigger_', 'triggers'), ('proc_rate', 'procs'), ('talent_delta', 'talent_modifiers'))
BEHAVIOUR_LABEL = 'behaviour_'


class PacketError(ValueError):
    pass


@dataclass(frozen=True)
class MapMatch:
    fields: dict | None
    how: str


def chunk_spells(sample: Mapping, chunk: str) -> list[int]:
    chunks = sample.get('chunks', {})
    if chunk not in chunks:
        raise PacketError(f'the sample has no chunk {chunk!r} (chunks {sorted(chunks)})')
    return list(chunks[chunk]['spells'])


def chunk_rows(sample: Mapping, chunk: str) -> list[dict]:
    return [clause for draw in sample.get('draws', []) if str(draw.get('chunk')) == chunk
            for clause in draw['clauses']]


def annotated_tooltip(description: str, readout: Readout) -> str:
    parts, position = [], 0
    for value in readout.values:
        found = description.find(value.text, position)
        if found < 0:
            continue
        end = found + len(value.text)
        parts.append(description[position:end] + f'[={value.value:g}]')
        position = end
    return ''.join(parts) + description[position:]


def token_spells(spell_id: int, readout: Readout) -> list[int]:
    return sorted({value.spell_id for value in readout.values if value.spell_id and value.spell_id != spell_id})


def field_text(record: dict, name: str) -> str | None:
    field = next((item for item in record['fields'] if item['name'] == name), None)
    if field is None or field['value'] in (0, None, ''):
        return None
    labels = field.get('labels') or []
    return f'{field["value"]}' + (f' ({", ".join(labels)})' if labels else '')


def spell_record(dbc, spell_id: int) -> dict | None:
    try:
        return dbc.record('Spell', spell_id)
    except ValueError:
        return None


def spell_effects(dbc, spell_id: int) -> dict:
    record = spell_record(dbc, spell_id)
    if record is None:
        raise PacketError(f'spell {spell_id} is not in Spell.dbc')
    spell_level = {name: text for name in SPELL_LEVEL_FIELDS if (text := field_text(record, name)) is not None}
    effects = []
    for effect in EFFECTS:
        if field_text(record, f'Effect[{effect}]') is None:
            continue
        fields = {name: text for name in EFFECT_FIELDS
                  if (text := field_text(record, f'{name}[{effect}]')) is not None}
        effects.append({'effect': effect, **fields})
    return {'spell': spell_id, 'name': record.get('name'), 'fields': spell_level, 'effects': effects}


def triggered_spells(effects: dict) -> list[int]:
    return sorted({int(effect['EffectTriggerSpell'].split()[0]) for effect in effects['effects']
                   if 'EffectTriggerSpell' in effect})


def related_ids(spell_id: int, readout: Readout) -> set[int]:
    return {spell_id, *token_spells(spell_id, readout)}


def names_spell(entry: dict, ids: set[int]) -> bool:
    return any(isinstance(entry.get(name), int) and entry[name] in ids for name in SPELL_FIELDS)


def class_entries(class_file: dict, ids: set[int]) -> list[dict]:
    found = []
    for section, entries in class_file.items():
        if not isinstance(entries, list):
            continue
        for position, entry in enumerate(entries):
            if isinstance(entry, dict) and names_spell(entry, ids):
                found.append({'section': section, 'position': position, 'kind': entry.get('kind'), 'entry': entry})
    return found


def effect_signature(dbc, spell_id: int | None) -> set[tuple[str, str]]:
    if not isinstance(spell_id, int) or spell_record(dbc, spell_id) is None:
        return set()
    return {(effect.get('Effect', ''), effect.get('EffectApplyAuraName', ''))
            for effect in spell_effects(dbc, spell_id)['effects']}


def entry_spell(entry: dict) -> int | None:
    return next((entry[name] for name in SPELL_FIELDS if isinstance(entry.get(name), int)), None)


def label_kinds(labels: Iterable[str]) -> list[tuple[str, str | None]]:
    kinds = []
    for label in labels:
        for word in label.split():
            if word.startswith(BEHAVIOUR_LABEL) and word[len(BEHAVIOUR_LABEL):] in KINDS:
                kinds.append(('behaviours', word[len(BEHAVIOUR_LABEL):]))
            for prefix, section in LABEL_SECTIONS:
                if word.startswith(prefix):
                    kinds.append((section, None))
    return sorted(set(kinds), key=lambda item: (item[0], item[1] or ''))


def nearest_entry(dbc, class_file: dict, spell_id: int, section: str, kind: str | None,
                  exclude: set[int]) -> dict | None:
    own = effect_signature(dbc, spell_id)
    candidates = []
    for position, entry in enumerate(class_file.get(section, [])):
        if not isinstance(entry, dict) or entry.get('kind') != kind:
            continue
        other = entry_spell(entry)
        if other is None or other in exclude:
            continue
        shared = len(own & effect_signature(dbc, other))
        candidates.append((-shared, abs(other - spell_id), position, entry))
    if not candidates:
        return None
    shared, distance, position, entry = min(candidates, key=lambda item: item[:3])
    return {'section': section, 'kind': kind, 'position': position, 'shared_effect_aura_pairs': -shared,
            'id_distance': distance, 'entry': entry}


def map_spells(class_map: Mapping | None, class_id: int) -> list[dict]:
    if class_map is None:
        return []
    return list(class_map.get('classes', {}).get(str(class_id), {}).get('spells', []))


def class_map_match(spells: Sequence[dict], spell_id: int, name: str) -> MapMatch:
    if not spells:
        return MapMatch(None, 'no class map given')
    exact = next((spell for spell in spells if spell.get('spell') == spell_id), None)
    if exact is not None:
        return MapMatch({field: exact.get(field) for field in CLASS_MAP_FIELDS}, f'map spell {spell_id}')
    token = str(spell_id)
    for spell in spells:
        if spell.get('name') != name:
            continue
        if any(token in str(hit).replace(':', ' ').split() for field in CLASS_MAP_HIT_FIELDS
               for hit in spell.get(field) or ()):
            return MapMatch({field: spell.get(field) for field in CLASS_MAP_FIELDS},
                            f'map spell {spell["spell"]} of the same name, whose hits name {spell_id}')
    return MapMatch(None, f'spell {spell_id} is not in the class map')


def ledger_rows(bucket_rows: Sequence[dict], spell_id: int, in_chunk: set[int]) -> list[dict]:
    return [{**row, 'in_chunk': row['index'] in in_chunk} for row in bucket_rows if row.get('spell') == spell_id]


def packet(dbc, class_file: dict, spell_id: int, bucket_rows: Sequence[dict], chunk_indexes: set[int],
           class_map: Mapping | None = None) -> dict:
    records = Records(dbc)
    if not records.has_spell(spell_id):
        raise PacketError(f'spell {spell_id} is not in Spell.dbc')
    name = records.field('Spell', spell_id, 'SpellName[enUS]')
    description = records.field('Spell', spell_id, 'Description[enUS]')
    try:
        readout = read_tooltip(dbc, spell_id, reference_caster(class_file))
    except Unreadable as error:
        readout = Readout([], [str(error)])
    effects = spell_effects(dbc, spell_id)
    named = token_spells(spell_id, readout)
    foreign = sorted(set(named) | set(triggered_spells(effects)))
    rows = ledger_rows(bucket_rows, spell_id, chunk_indexes)
    hits = {}
    for row in rows:
        for hit_id, found in (row.get('script_touch_hits') or {}).items():
            merged = hits.setdefault(hit_id, {'id': set(), 'family': set()})
            for key in ('id', 'family'):
                merged[key].update(found.get(key) or ())
    entries = class_entries(class_file, related_ids(spell_id, readout))
    own_kinds = {(item['section'], item['kind']) for item in entries if item['section'] in CHECK_SECTIONS}
    labels = [label for row in rows for label in row.get('labels', [])]
    kinds = sorted(own_kinds | set(label_kinds(labels)), key=lambda item: (item[0], item[1] or ''))
    exclude = related_ids(spell_id, readout)
    nearest = [found for section, kind in kinds
               if (found := nearest_entry(dbc, class_file, spell_id, section, kind, exclude)) is not None]
    fixtures = [item for item in entries if item['section'] not in CHECK_SECTIONS]
    match = class_map_match(map_spells(class_map, class_file['class_id']), spell_id, name)
    return {
        'spell': spell_id, 'name': name, 'class_id': class_file['class_id'],
        'tooltip': {'description': description, 'annotated': annotated_tooltip(description, readout),
                    'values': [{'text': value.text, 'value': value.value, 'kind': value.kind,
                                'effect': value.effect_index, 'spell': value.spell_id} for value in readout.values],
                    'unreadable': list(readout.unreadable)},
        'effects': [effects] + [spell_effects(dbc, other) for other in foreign if records.has_spell(other)],
        'script_touch_hits': {hit_id: {key: sorted(values) for key, values in found.items()}
                              for hit_id, found in sorted(hits.items())},
        'ledger_rows': rows,
        'class_entries': [item for item in entries if item['section'] in CHECK_SECTIONS],
        'check_kinds': [{'section': section, 'kind': kind} for section, kind in kinds],
        'nearest_entries': nearest,
        'fixtures': fixtures,
        'available_behaviour_kinds': list(KINDS),
        'class_map': {'how': match.how, 'fields': match.fields},
    }


def compact(value) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False)


def render_packet(data: dict) -> str:
    lines = [f'# Packet: {data["name"]} {data["spell"]}', '',
             'Built by `conformance.py packets` from Spell.dbc, the class file, the bucket file and the class map, '
             'with no agent judgement.', '', '## Tooltip', '', f'- Description: {data["tooltip"]["description"]}',
             f'- Tokens resolved with the reference stats: {data["tooltip"]["annotated"]}']
    for value in data['tooltip']['values']:
        lines.append(f'  - `{value["text"]}` = {value["value"]:g} ({value["kind"]}, effect {value["effect"]}, '
                     f'spell {value["spell"]})')
    lines += [f'  - unreadable: {item}' for item in data['tooltip']['unreadable']]
    lines += ['', '## Class map', '', f'- Match: {data["class_map"]["how"]}']
    for name, value in (data['class_map']['fields'] or {}).items():
        lines.append(f'- {name}: {compact(value)}')
    lines += ['', '## Spell.dbc effects', '']
    for spell in data['effects']:
        lines.append(f'- {spell["name"]} {spell["spell"]}: {compact(spell["fields"])}')
        lines += [f'  - effect {effect["effect"]}: '
                  + compact({key: value for key, value in effect.items() if key != 'effect'})
                  for effect in spell['effects']]
    lines += ['', '## Script touch hits', '']
    if not data['script_touch_hits']:
        lines.append('- none')
    for hit_id, found in data['script_touch_hits'].items():
        ids, families = ', '.join(found['id']) or 'none', ', '.join(found['family']) or 'none'
        lines.append(f'- {hit_id}: id {ids}; family {families}')
    lines += ['', '## Ledger rows', '']
    for row in data['ledger_rows']:
        lines.append(f'- clause {row["index"]} ({"this chunk" if row["in_chunk"] else "other"}), bucket '
                     f'{row["bucket"]}, evidence {row.get("evidence")}, token_kind {row.get("token_kind")}, '
                     f'script_touch {row.get("script_touch")}, readable_token {row.get("readable_token")}: '
                     f'{row["clause"]}')
        lines.append(f'  - labels: {compact(row.get("labels", []))}')
        lines.append(f'  - label statuses: {compact(row.get("label_statuses", {}))}')
        if row.get('missing_labels'):
            lines.append(f'  - missing labels: {compact(row["missing_labels"])}')
    lines += ['', '## Existing class-file entries', '']
    if not data['class_entries']:
        lines.append('- none')
    for item in data['class_entries']:
        lines.append(f'- {item["section"]}[{item["position"]}] kind {item["kind"]}: {compact(item["entry"])}')
    lines += ['', '## Nearest entry of the same check kind', '']
    if not data['check_kinds']:
        lines.append('- no existing entry and no label names a check kind')
    named = {(item['section'], item['kind']) for item in data['nearest_entries']}
    for kind in data['check_kinds']:
        if (kind['section'], kind['kind']) not in named:
            lines.append(f'- {kind["section"]} kind {kind["kind"]}: no other entry of that kind')
    for item in data['nearest_entries']:
        lines.append(f'- {item["section"]}[{item["position"]}] kind {item["kind"]} (shared effect and aura pairs '
                     f'{item["shared_effect_aura_pairs"]}, id distance {item["id_distance"]}): '
                     f'{compact(item["entry"])}')
    lines += ['', '## Fixtures', '']
    if not data['fixtures']:
        lines.append('- no class-file fixture names this spell or a spell its tokens name')
    for item in data['fixtures']:
        lines.append(f'- {item["section"]}[{item["position"]}]: {compact(item["entry"])}')
    lines.append(f'- behaviour kinds the generator builds: {", ".join(data["available_behaviour_kinds"])}')
    return '\n'.join(lines) + '\n'


def write_packets(dbc_dir: Path, class_file: dict, sample: Mapping, chunk: str, bucket_rows: Sequence[dict],
                  out_dir: Path, class_map: Mapping | None = None) -> list[Path]:
    dbc = dataset(Path(dbc_dir))
    indexes = {row['index'] for row in chunk_rows(sample, chunk)}
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    written = []
    for spell_id in chunk_spells(sample, chunk):
        path = out_dir / f'{spell_id}.md'
        path.write_text(render_packet(packet(dbc, class_file, spell_id, bucket_rows, indexes, class_map)),
                        encoding='utf-8')
        written.append(path)
    return written
