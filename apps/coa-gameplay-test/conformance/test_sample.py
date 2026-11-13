import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from conformance import main
from sample import (SampleError, bucket_quotas, chunk_split, draw, largest_remainder, load_buckets, parse_minimums,
                    sample_document, spell_key, spell_order)


def clauses_of(bucket, spells, per_spell=1):
    return [{'spell': spell, 'bucket': bucket, 'clause': f'{bucket} {spell} {index}'}
            for spell in spells for index in range(per_spell)]


class OrderTest(unittest.TestCase):
    def test_spells_are_ordered_by_sha256_of_seed_and_id(self):
        spells = [301310, 92111, 524739, 705291]
        expected = sorted(spells, key=lambda spell: hashlib.sha256(f'batch1|{spell}'.encode()).hexdigest())
        self.assertEqual(spell_order('batch1', spells + spells), expected)
        self.assertEqual(spell_key('batch1', 92111), hashlib.sha256(b'batch1|92111').hexdigest())

    def test_another_seed_gives_another_order(self):
        spells = list(range(1, 30))
        self.assertNotEqual(spell_order('batch1', spells), spell_order('batch2', spells))


class QuotaTest(unittest.TestCase):
    def test_quotas_are_proportional_and_sum_to_the_total(self):
        self.assertEqual(largest_remainder({'U': 166, 'D': 139}, 36), {'U': 20, 'D': 16})
        self.assertEqual(sum(largest_remainder({'U': 7, 'D': 5, 'A': 3}, 10).values()), 10)

    def test_a_minimum_raises_a_small_bucket_and_the_rest_share_the_remainder(self):
        self.assertEqual(bucket_quotas({'U': 166, 'D': 139, 'A': 10}, 40, {'A': 4}), {'U': 20, 'D': 16, 'A': 4})

    def test_a_minimum_above_the_bucket_size_takes_the_whole_bucket(self):
        self.assertEqual(bucket_quotas({'U': 50, 'A': 2}, 10, {'A': 4})['A'], 2)

    def test_a_minimum_for_an_absent_bucket_is_refused(self):
        with self.assertRaisesRegex(SampleError, 'hold no clause'):
            bucket_quotas({'U': 5}, 3, {'A': 1})

    def test_minimums_parse(self):
        self.assertEqual(parse_minimums(['A=4', 'D=1']), {'A': 4, 'D': 1})
        with self.assertRaisesRegex(SampleError, 'BUCKET=COUNT'):
            parse_minimums(['A4'])


class DrawTest(unittest.TestCase):
    def test_whole_spells_are_drawn_until_the_quota_is_reached(self):
        clauses = clauses_of('U', range(1, 21), per_spell=3) + clauses_of('A', range(100, 104))
        drawn, sizes, quotas = draw(clauses, 'seed', 10, ['U', 'A'], {'A': 2})
        self.assertEqual(quotas, {'U': 8, 'A': 2})
        u_draws = [item for item in drawn if item.bucket == 'U']
        self.assertEqual([item.spell for item in u_draws],
                         spell_order('seed', range(1, 21))[:3])
        self.assertTrue(all(len(item.clauses) == 3 for item in u_draws))
        self.assertEqual(sum(len(item.clauses) for item in u_draws), 9)
        self.assertEqual([item.spell for item in drawn if item.bucket == 'A'], spell_order('seed', range(100, 104))[:2])

    def test_a_spell_brings_only_its_clauses_of_that_bucket(self):
        clauses = clauses_of('U', [7]) + clauses_of('D', [7], per_spell=2) + clauses_of('D', [8])
        drawn, _, _ = draw(clauses, 'seed', 3, ['U', 'D'], {})
        by_bucket = {(item.bucket, item.spell): len(item.clauses) for item in drawn}
        self.assertEqual(by_bucket.get(('U', 7)), 1)
        self.assertNotIn('U', {clause['bucket'] for item in drawn if item.bucket == 'D' for clause in item.clauses})

    def test_other_buckets_are_never_drawn(self):
        clauses = clauses_of('U', range(5)) + clauses_of('out_of_scope', range(5, 10))
        drawn, sizes, _ = draw(clauses, 'seed', 4, ['U'], {})
        self.assertEqual(sizes, {'U': 5})
        self.assertEqual({item.bucket for item in drawn}, {'U'})


class ChunkTest(unittest.TestCase):
    def test_chunk_one_interleaves_whole_spells_until_it_holds_the_size(self):
        clauses = clauses_of('U', range(1, 11), per_spell=2) + clauses_of('D', range(20, 30)) + \
            clauses_of('A', range(40, 44))
        drawn, _, _ = draw(clauses, 'seed', 20, ['U', 'D', 'A'], {'A': 4})
        first, second = chunk_split(drawn, ['U', 'D', 'A'], 6)
        queues = {bucket: [item.spell for item in drawn if item.bucket == bucket] for bucket in 'UDA'}
        self.assertEqual(first, [queues['U'][0], queues['D'][0], queues['A'][0], queues['U'][1]])
        self.assertEqual(set(first) | set(second), {item.spell for item in drawn})
        self.assertFalse(set(first) & set(second))

    def test_a_spell_drawn_in_two_buckets_stays_in_one_chunk(self):
        clauses = clauses_of('U', [5, 6]) + clauses_of('D', [5, 9])
        drawn, _, _ = draw(clauses, 'seed', 4, ['U', 'D'], {})
        first, second = chunk_split(drawn, ['U', 'D'], 1)
        self.assertEqual(len(first), 1)
        self.assertEqual(first.count(5) + second.count(5), 1)

    def test_the_document_records_draw_order_and_chunks(self):
        clauses = clauses_of('U', range(1, 9)) + clauses_of('A', range(50, 55))
        document = sample_document(clauses, 'seed', 6, ['U', 'A'], {'A': 2}, 3)
        self.assertEqual([row['order'] for row in document['draws']], list(range(1, len(document['draws']) + 1)))
        self.assertEqual(document['drawn_clauses'], {'U': 4, 'A': 2})
        self.assertEqual(document['chunks']['1']['clauses'] + document['chunks']['2']['clauses'], 6)
        self.assertEqual({row['chunk'] for row in document['draws']}, {1, 2})


class CommandTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix='conformance-sample-'))
        self.addCleanup(shutil.rmtree, self.root)

    def test_sample_command_writes_the_same_file_twice(self):
        buckets = self.root / 'buckets.json'
        buckets.write_text(json.dumps({'clauses': clauses_of('U', range(1, 30)) + clauses_of('A', range(60, 66))}),
                           encoding='utf-8')
        outputs = []
        for name in ('one.json', 'two.json'):
            arguments = ['sample', '--buckets', str(buckets), '--seed', 'batch1', '--total', '12', '--bucket', 'U',
                         '--bucket', 'A', '--minimum', 'A=4', '--first-chunk', '5', '--out', str(self.root / name)]
            self.assertEqual(main(arguments), 0)
            outputs.append((self.root / name).read_text(encoding='utf-8'))
        self.assertEqual(outputs[0], outputs[1])
        self.assertEqual(json.loads(outputs[0])['quotas'], {'U': 8, 'A': 4})

    def test_a_malformed_bucket_file_is_refused(self):
        buckets = self.root / 'buckets.json'
        buckets.write_text(json.dumps([{'spell': 'x', 'bucket': 'U'}]), encoding='utf-8')
        with self.assertRaisesRegex(SampleError, 'integer spell'):
            load_buckets(buckets)


if __name__ == '__main__':
    unittest.main()
