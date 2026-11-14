from datetime import datetime, timezone
import json
from pathlib import Path
import tempfile
import unittest

import conformance
from cost import CostError, cost_totals, parse_time, role_of

FIXTURE = Path(__file__).parent / 'fixtures' / 'cost'
SINCE = datetime(2026, 1, 2, tzinfo=timezone.utc)


class RoleTest(unittest.TestCase):
    def test_independent_reviewer_prompt_wins_over_integrator_description(self):
        self.assertEqual(role_of('Integrator of pair 3', 'You are an independent reviewer'), 'read-only')

    def test_integrator_description(self):
        self.assertEqual(role_of('Merge origin/main', 'x'), 'integrator')
        self.assertEqual(role_of('Run the pair', 'x'), 'integrator')

    def test_read_only_prompt_or_description(self):
        self.assertEqual(role_of('Build it', 'This task is read-only'), 'read-only')
        self.assertEqual(role_of('Sweep the ledger', 'x'), 'read-only')

    def test_fix_description(self):
        self.assertEqual(role_of('Resize the pooled entries', 'x'), 'fix')

    def test_everything_else_is_author(self):
        self.assertEqual(role_of('Build the new kind', 'x'), 'author')
        self.assertEqual(role_of('', ''), 'author')

    def test_only_the_head_of_the_prompt_is_read(self):
        self.assertEqual(role_of('Build it', 'x' * 1600 + 'independent reviewer'), 'author')


class TotalsTest(unittest.TestCase):
    def setUp(self):
        self.totals = cost_totals(FIXTURE, SINCE)

    def test_author(self):
        self.assertEqual(self.totals['roles']['author'],
                         {'agents': 1, 'input': 560, 'cache_read': 500, 'output': 50, 'agent_minutes': 30.0})

    def test_a_repeated_message_id_counts_its_last_usage_once(self):
        self.assertEqual(self.totals['roles']['integrator'],
                         {'agents': 1, 'input': 152, 'cache_read': 150, 'output': 15, 'agent_minutes': 20.0})

    def test_read_only_skips_synthetic_messages(self):
        self.assertEqual(self.totals['roles']['read-only'],
                         {'agents': 2, 'input': 64, 'cache_read': 47, 'output': 12, 'agent_minutes': 9.5})

    def test_fix(self):
        self.assertEqual(self.totals['roles']['fix'],
                         {'agents': 1, 'input': 74, 'cache_read': 60, 'output': 8, 'agent_minutes': 4.0})

    def test_main_session_counts_messages_in_the_window_only(self):
        self.assertEqual(self.totals['roles']['main'],
                         {'agents': 0, 'input': 1110, 'cache_read': 1000, 'output': 50, 'agent_minutes': 0.0})

    def test_agent_total_excludes_main_and_agents_before_the_window(self):
        self.assertEqual(self.totals['agents_total'],
                         {'agents': 5, 'input': 850, 'cache_read': 757, 'output': 85, 'agent_minutes': 63.5})

    def test_until_drops_later_agents(self):
        until = datetime(2026, 1, 2, 12, 30, tzinfo=timezone.utc)
        bounded = cost_totals(FIXTURE, SINCE, until)
        self.assertEqual(bounded['agents_total']['agents'], 2)
        self.assertEqual(bounded['roles']['read-only']['agents'], 0)

    def test_until_clips_an_agent_running_past_it(self):
        until = datetime(2026, 1, 2, 11, 15, tzinfo=timezone.utc)
        bounded = cost_totals(FIXTURE, SINCE, until)
        self.assertEqual(bounded['roles']['author']['agent_minutes'], 15.0)
        self.assertEqual(bounded['roles']['author']['output'], 20)

    def test_a_missing_directory_is_an_error(self):
        with self.assertRaises(CostError):
            cost_totals(FIXTURE / 'absent', SINCE)

    def test_naive_times_are_utc(self):
        self.assertEqual(parse_time('2026-01-02T00:00:00'), SINCE)


class CommandTest(unittest.TestCase):
    def run_cost(self, *arguments):
        return conformance.main(['cost', *arguments])

    def test_transcripts_has_no_default(self):
        with self.assertRaises(SystemExit):
            self.run_cost('--since', '2026-01-02', '--out', 'x.json')

    def test_output_holds_aggregates_only(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / 'cost.json'
            self.assertEqual(self.run_cost('--transcripts', str(FIXTURE), '--since', '2026-01-02T00:00:00Z',
                                           '--out', str(out)), 0)
            text = out.read_text(encoding='utf-8')
            document = json.loads(text)
        self.assertEqual(sorted(document), ['agents_total', 'roles', 'window'])
        for forbidden in ('/home', 'someone', 'secret', 'Implement', 'Merge', 'author1', 'session-main', 'agent-',
                          'Resize', 'independent reviewer'):
            self.assertNotIn(forbidden, text)

    def test_bad_time_exits_with_two(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(self.run_cost('--transcripts', str(FIXTURE), '--since', 'not-a-time',
                                           '--out', str(Path(directory) / 'c.json')), 2)


if __name__ == '__main__':
    unittest.main()
