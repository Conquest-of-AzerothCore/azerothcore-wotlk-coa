from pathlib import Path
import tempfile
import unittest

from records import (REQUIRED_ENTRY_FIELDS, convert_records, extract_batch_records, extract_batch_residuals,
                     key_of, load_records, load_residuals, number_text, numeric_leaves, record_schema,
                     traceability_errors, validate_record, write_record_schema)

SHEET = {
    'spell_id': 705268,
    'tooltip': {'description': 'Doubles the healing done to you', 'cleaned': 'Doubles the healing done to you'},
    'effects': [{'effect': 0, 'family': 'P1', 'points': 100.0}],
}


def literal_token_record(value=100, sourced_value='100'):
    return {
        'spell_id': 705268,
        'entry_kind': 'literal_tokens',
        'entry': {'spell': 705268, 'effect': 0, 'quote': 'Doubles the healing done to you', 'value': value},
        'sources': [{'token_or_field': 'quote', 'sheet_section': 'tooltip.cleaned',
                    'value': sourced_value, 'citation': 'tooltip.cleaned'}],
        'reader': 'reader-01',
        'confidence': 'high',
        'rationale': 'the tooltip states the clause verbatim',
    }


class RecordValidationTests(unittest.TestCase):
    def test_valid_record_has_no_errors(self):
        self.assertEqual(validate_record(literal_token_record()), [])

    def test_missing_entry_field_is_rejected(self):
        record = literal_token_record()
        del record['entry']['value']
        errors = validate_record(record)
        self.assertTrue(any('value' in error for error in errors))

    def test_unknown_entry_kind_is_rejected(self):
        record = literal_token_record()
        record['entry_kind'] = 'not_a_kind'
        errors = validate_record(record)
        self.assertTrue(errors)

    def test_bad_confidence_is_rejected(self):
        record = literal_token_record()
        record['confidence'] = 'maybe'
        errors = validate_record(record)
        self.assertTrue(any('confidence' in error for error in errors))

    def test_empty_sources_is_rejected(self):
        record = literal_token_record()
        record['sources'] = []
        errors = validate_record(record)
        self.assertTrue(any('sources' in error for error in errors))

    def test_key_of_reads_the_kind_specific_fields(self):
        self.assertEqual(key_of('literal_tokens', {'spell': 705268, 'effect': 0}), (705268, 0))
        self.assertEqual(key_of('procs', {'aura': 92111}), (92111,))

    def test_every_entry_kind_has_required_fields_listed(self):
        for kind, fields in REQUIRED_ENTRY_FIELDS.items():
            self.assertTrue(fields, f'{kind} has no required fields')


class TraceabilityTests(unittest.TestCase):
    def test_cited_number_matching_the_sheet_passes(self):
        record = literal_token_record(value=100, sourced_value='100')
        self.assertEqual(traceability_errors(record, SHEET), [])

    def test_number_absent_from_sources_is_rejected(self):
        record = literal_token_record(value=100, sourced_value='100')
        record['entry']['value'] = 999
        errors = traceability_errors(record, SHEET)
        self.assertTrue(any('999' in error for error in errors))

    def test_citation_value_absent_from_the_sheet_is_rejected(self):
        record = literal_token_record(value=100, sourced_value='100')
        record['sources'][0]['value'] = '12345'
        record['entry']['value'] = 12345
        errors = traceability_errors(record, SHEET)
        self.assertTrue(any('does not appear verbatim' in error for error in errors))

    def test_list_valued_source_does_not_crash(self):
        record = literal_token_record(value=100, sourced_value='100')
        record['sources'][0]['value'] = [705268, 100]
        self.assertEqual(traceability_errors(record, SHEET), [])

    def test_list_valued_source_with_an_element_outside_the_sheet_is_rejected(self):
        record = literal_token_record(value=100, sourced_value='100')
        record['sources'][0]['value'] = [705268, 999999]
        errors = traceability_errors(record, SHEET)
        self.assertTrue(any('does not appear verbatim' in error for error in errors))

    def test_numeric_leaves_walks_nested_structures(self):
        leaves = list(numeric_leaves({'a': 1, 'b': [2, {'c': 3.5}], 'd': 'text', 'e': True}))
        self.assertEqual(leaves, [1, 2, 3.5])

    def test_number_text_normalizes_integral_floats(self):
        self.assertEqual(number_text(100), '100')
        self.assertEqual(number_text(100.0), '100')
        self.assertEqual(number_text(0.5), '0.5')


class ConversionTests(unittest.TestCase):
    def test_convert_records_groups_entries_by_kind(self):
        records = [literal_token_record(), literal_token_record(value=50, sourced_value='50')]
        converted = convert_records(records)
        self.assertEqual(list(converted), ['literal_tokens'])
        self.assertEqual(len(converted['literal_tokens']), 2)

    def test_load_records_reads_every_json_file_in_a_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            import json
            (Path(directory) / '705268.json').write_text(json.dumps(literal_token_record()), encoding='utf-8')
            (Path(directory) / 'not-a-record.json').write_text(json.dumps({'other': 1}), encoding='utf-8')
            records = load_records(directory)
            self.assertEqual(len(records), 1)

    def test_extract_batch_records_from_dict_wrapped_batch(self):
        residual = {'class': 'templar', 'spell_id': 1, 'tooltip': 't', 'data_says': 'd', 'candidate_a': 'a',
                    'candidate_b': 'b', 'why_undecidable': 'u', 'answer': None, 'answered_by': None,
                    'answered_at': None}
        batch = {'reader': 'a', 'class': 'templar', 'group': 1,
                'records': [literal_token_record(), literal_token_record(value=50, sourced_value='50')],
                'residuals': [residual]}
        self.assertEqual(len(extract_batch_records(batch)), 2)
        self.assertEqual(extract_batch_residuals(batch), [residual])

    def test_extract_batch_records_from_bare_list_with_inline_residuals(self):
        residual = {'class': 'templar', 'spell_id': 1, 'tooltip': 't', 'data_says': 'd', 'candidate_a': 'a',
                    'candidate_b': 'b', 'why_undecidable': 'u', 'answer': None, 'answered_by': None,
                    'answered_at': None}
        batch = [literal_token_record(), residual]
        self.assertEqual(len(extract_batch_records(batch)), 1)
        self.assertEqual(extract_batch_residuals(batch), [residual])

    def test_extract_batch_records_from_bare_list_with_wrapped_residual_kind(self):
        wrapped_residual = {'spell_id': 1, 'entry_kind': 'residual', 'reader': 'b', 'class': 'templar',
                            'residual': {'class': 'templar', 'spell_id': 1, 'tooltip': 't', 'data_says': 'd',
                                        'candidate_a': 'a', 'candidate_b': 'b', 'why_undecidable': 'u',
                                        'answer': None, 'answered_by': None, 'answered_at': None}}
        batch = [literal_token_record(), wrapped_residual]
        self.assertEqual(len(extract_batch_records(batch)), 1)
        self.assertEqual(extract_batch_residuals(batch), [wrapped_residual['residual']])

    def test_load_records_flattens_a_directory_of_batch_files_without_hand_flattening(self):
        with tempfile.TemporaryDirectory() as directory:
            import json
            batch = {'reader': 'a', 'class': 'templar', 'group': 1,
                    'records': [literal_token_record(), literal_token_record(value=50, sourced_value='50')],
                    'residuals': []}
            (Path(directory) / 'group-1.json').write_text(json.dumps(batch), encoding='utf-8')
            records = load_records(directory)
            self.assertEqual(len(records), 2)
            self.assertEqual(load_residuals(directory), [])


class SchemaExportTests(unittest.TestCase):
    def test_record_schema_lists_every_entry_kind(self):
        schema = record_schema()
        self.assertEqual(set(schema['properties']['entry_kind']['enum']), set(REQUIRED_ENTRY_FIELDS))

    def test_write_record_schema_writes_valid_json(self):
        with tempfile.TemporaryDirectory() as directory:
            import json
            path = write_record_schema(Path(directory) / 'record.schema.json')
            json.loads(path.read_text(encoding='utf-8'))


if __name__ == '__main__':
    unittest.main()
