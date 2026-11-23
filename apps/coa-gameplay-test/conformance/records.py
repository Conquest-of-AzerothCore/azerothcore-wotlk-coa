import json
from pathlib import Path

ENTRY_KINDS = ('procs', 'triggers', 'behaviours', 'passive_targets', 'talent_modifiers', 'effect_overrides',
              'unmodelled_effects', 'literal_tokens', 'effect_notes')
REQUIRED_ENTRY_FIELDS = {
    'procs': ('aura', 'chance_token', 'dbc', 'name', 'spell_proc', 'tooltip'),
    'triggers': ('aura', 'name', 'observe_metric', 'observe_source', 'observe_spell', 'per_trigger_text',
                'tooltip', 'trigger_text'),
    'behaviours': ('kind', 'name', 'quote', 'spell'),
    'passive_targets': ('effect', 'spell', 'targets', 'tooltip_words'),
    'talent_modifiers': ('name', 'source', 'source_text', 'talent', 'token', 'tooltip'),
    'effect_overrides': ('citation', 'effect', 'spell'),
    'unmodelled_effects': ('effect', 'reason', 'spell'),
    'literal_tokens': ('effect', 'quote', 'spell', 'value'),
    'effect_notes': ('effect', 'reason', 'spell'),
}
KEY_FIELDS = {
    'procs': ('aura',),
    'triggers': ('aura',),
    'behaviours': ('spell',),
    'passive_targets': ('spell', 'effect'),
    'talent_modifiers': ('talent',),
    'effect_overrides': ('spell', 'effect'),
    'unmodelled_effects': ('spell', 'effect'),
    'literal_tokens': ('spell', 'effect'),
    'effect_notes': ('spell', 'effect'),
}
REQUIRED_RECORD_FIELDS = ('spell_id', 'entry_kind', 'entry', 'sources', 'reader', 'confidence', 'rationale')
REQUIRED_SOURCE_FIELDS = ('token_or_field', 'sheet_section', 'value', 'citation')
CONFIDENCE_LEVELS = ('high', 'low')
RESIDUAL_FIELDS = ('class', 'spell_id', 'tooltip', 'data_says', 'candidate_a', 'candidate_b', 'why_undecidable',
                   'answer', 'answered_by', 'answered_at')


RECORD_FILE_SHAPE_NOTE = (
    'One JSON file per record, entry_kind at the top level. Do not batch several records into one file.'
)
LITERAL_TOKENS_GUIDANCE = (
    "literal_tokens is for a tooltip number with no DBC token or effect behind it at all (the schema's own "
    "edge cases). A number you read but cannot bind to a specific effect index is not a literal_tokens entry: "
    'file it as a residual instead, with the uncertainty stated in why_undecidable.'
)
SOURCE_VALUE_NOTE = (
    "sources[].value is the bare literal the gate string-matches against the sheet: a plain number or a short "
    'id, or a list of such literals for a multi-target claim. Any description, unit or derivation belongs in '
    'citation, never joined into value.'
)
KIND_MERGE_NOTE = (
    'unmodelled_effects and effect_notes share the same required fields (effect, reason, spell) and are scored '
    'as one claim; pick whichever name reads better, the scorer does not distinguish them.'
)


def record_schema() -> dict:
    return {
        '$schema': 'https://json-schema.org/draft/2020-12/schema',
        'title': 'Class conformance reader record',
        'type': 'object',
        'required': list(REQUIRED_RECORD_FIELDS),
        'properties': {
            'spell_id': {'type': 'integer'},
            'entry_kind': {'enum': list(ENTRY_KINDS)},
            'entry': {'type': 'object'},
            'sources': {
                'type': 'array',
                'items': {'type': 'object', 'required': list(REQUIRED_SOURCE_FIELDS)},
                'description': SOURCE_VALUE_NOTE,
            },
            'reader': {'type': 'string'},
            'confidence': {'enum': list(CONFIDENCE_LEVELS)},
            'rationale': {'type': 'string'},
        },
        'entry_required_fields': REQUIRED_ENTRY_FIELDS,
        'residual': {
            'type': 'object',
            'required': list(RESIDUAL_FIELDS),
        },
        'file_shape': RECORD_FILE_SHAPE_NOTE,
        'guidance': {
            'literal_tokens': LITERAL_TOKENS_GUIDANCE,
            'unmodelled_effects': KIND_MERGE_NOTE,
            'effect_notes': KIND_MERGE_NOTE,
        },
    }


def key_of(kind: str, entry: dict):
    return tuple(entry.get(field) for field in KEY_FIELDS[kind])


def validate_record(record: dict) -> list[str]:
    errors = []
    missing = [field for field in REQUIRED_RECORD_FIELDS if field not in record]
    if missing:
        errors.append(f'record is missing {missing}')
        return errors
    kind = record['entry_kind']
    if kind not in ENTRY_KINDS:
        errors.append(f'entry_kind {kind!r} is not one of {ENTRY_KINDS}')
        return errors
    entry = record['entry']
    missing_entry_fields = [field for field in REQUIRED_ENTRY_FIELDS[kind] if field not in entry]
    if missing_entry_fields:
        errors.append(f'entry is missing {missing_entry_fields} required for {kind}')
    if record['confidence'] not in CONFIDENCE_LEVELS:
        errors.append(f'confidence {record["confidence"]!r} is not one of {CONFIDENCE_LEVELS}')
    if not isinstance(record['sources'], list) or not record['sources']:
        errors.append('sources must be a non-empty list')
    else:
        for index, source in enumerate(record['sources']):
            missing_source_fields = [field for field in REQUIRED_SOURCE_FIELDS if field not in source]
            if missing_source_fields:
                errors.append(f'sources[{index}] is missing {missing_source_fields}')
    if None in key_of(kind, entry):
        errors.append(f'entry is missing a {kind} key field {KEY_FIELDS[kind]}')
    return errors


def number_text(value) -> str:
    if isinstance(value, bool):
        raise TypeError('bool is not a traceable number')
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return str(int(value)) if value.is_integer() else str(value)
    raise TypeError(f'{value!r} is not a number')


def numeric_leaves(value):
    if isinstance(value, bool):
        return
    if isinstance(value, (int, float)):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from numeric_leaves(item)
    elif isinstance(value, (list, tuple)):
        for item in value:
            yield from numeric_leaves(item)


def value_tokens(value) -> list[str]:
    if isinstance(value, (list, tuple)):
        return [str(item) for item in value]
    if value is None:
        return []
    return [str(value)]


def traceability_errors(record: dict, sheet: dict) -> list[str]:
    sheet_text = json.dumps(sheet, sort_keys=True)
    sources = record.get('sources', [])
    cited_values: set[str] = set()
    errors = []
    for source in sources:
        value = source.get('value')
        tokens = value_tokens(value)
        if not tokens or any(token not in sheet_text for token in tokens):
            errors.append(f'source citation {value!r} does not appear verbatim in the sheet')
        cited_values.update(tokens)
    kind = record.get('entry_kind')
    entry = record.get('entry', {})
    exempt = set(KEY_FIELDS.get(kind, ()))
    claimed_entry = {field: value for field, value in entry.items() if field not in exempt}
    for leaf in numeric_leaves(claimed_entry):
        text = number_text(leaf)
        if text not in cited_values:
            errors.append(f'entry number {leaf!r} has no matching source value')
    return errors


def convert_records(records: list[dict]) -> dict:
    out: dict = {}
    for record in records:
        out.setdefault(record['entry_kind'], []).append(record['entry'])
    return out


def is_residual_payload(item) -> bool:
    return isinstance(item, dict) and 'entry_kind' not in item and 'candidate_a' in item and 'candidate_b' in item


def extract_batch_records(obj) -> list[dict]:
    if isinstance(obj, dict) and 'entry_kind' in obj:
        return [obj]
    if isinstance(obj, dict) and 'records' in obj:
        return [item for item in obj.get('records', []) if isinstance(item, dict) and 'entry_kind' in item]
    if isinstance(obj, list):
        records = []
        for item in obj:
            if not isinstance(item, dict) or 'entry_kind' not in item:
                continue
            if item['entry_kind'] == 'residual' or is_residual_payload(item):
                continue
            records.append(item)
        return records
    return []


def extract_batch_residuals(obj) -> list[dict]:
    if isinstance(obj, dict) and 'residuals' in obj:
        return [item for item in obj.get('residuals', []) if isinstance(item, dict)]
    if isinstance(obj, list):
        residuals = []
        for item in obj:
            if is_residual_payload(item):
                residuals.append(item)
            elif isinstance(item, dict) and item.get('entry_kind') == 'residual' and isinstance(item.get('residual'), dict):
                residuals.append(item['residual'])
        return residuals
    return []


def load_records(records_dir: Path) -> list[dict]:
    records = []
    for path in sorted(Path(records_dir).glob('*.json')):
        obj = json.loads(path.read_text(encoding='utf-8'))
        records.extend(extract_batch_records(obj))
    return records


def load_residuals(records_dir: Path) -> list[dict]:
    residuals = []
    for path in sorted(Path(records_dir).glob('*.json')):
        obj = json.loads(path.read_text(encoding='utf-8'))
        residuals.extend(extract_batch_residuals(obj))
    return residuals


def write_record_schema(out_path: Path) -> Path:
    out_path = Path(out_path)
    out_path.write_text(json.dumps(record_schema(), indent=2, sort_keys=True) + '\n', encoding='utf-8')
    return out_path
