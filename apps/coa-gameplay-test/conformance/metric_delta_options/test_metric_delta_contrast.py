import ast
from pathlib import Path
from types import SimpleNamespace
import unittest

from behaviours import CONDITION_CONTRAST, LEARNED_CONTRAST, OWN_CAST_CONTRAST, metric_delta_contrast
from coverage import METRIC_EVIDENCE, STATE, metric_evidence

HERE = Path(__file__).resolve().parent.parent


def own_cast(metric: str, spell: int = 806109) -> SimpleNamespace:
    return SimpleNamespace(spell=spell, metric=metric, setup_only_after=True, setup_casts=(spell,))


class MetricDeltaContrastTests(unittest.TestCase):
    def test_an_own_cast_contrast_follows_the_full_evidence_table_for_every_metric(self):
        for metric, evidence in metric_evidence().items():
            with self.subTest(metric=metric):
                expected = OWN_CAST_CONTRAST if evidence == STATE else CONDITION_CONTRAST
                self.assertEqual(metric_delta_contrast(own_cast(metric)), expected)

    def test_an_option_row_state_metric_is_an_own_cast_contrast(self):
        self.assertNotIn('position_x', METRIC_EVIDENCE)
        self.assertEqual(metric_evidence()['position_x'], STATE)
        self.assertEqual(metric_delta_contrast(own_cast('position_x')), OWN_CAST_CONTRAST)

    def test_a_foreign_setup_cast_or_a_learned_gate_keeps_its_contrast(self):
        foreign = SimpleNamespace(spell=806109, metric='position_x', setup_only_after=True, setup_casts=(806128,))
        learned = SimpleNamespace(spell=806109, metric='position_x', setup_only_after=False, setup_casts=())
        self.assertEqual(metric_delta_contrast(foreign), CONDITION_CONTRAST)
        self.assertEqual(metric_delta_contrast(learned), LEARNED_CONTRAST)

    def test_no_module_reads_the_static_metric_evidence_table_outside_coverage(self):
        readers = []
        for path in sorted(HERE.rglob('*.py')):
            if path.name.startswith('test_') or path.name == 'coverage.py':
                continue
            for node in ast.walk(ast.parse(path.read_text(encoding='utf-8'))):
                if isinstance(node, ast.ImportFrom) and node.module == 'coverage' and \
                        any(alias.name == 'METRIC_EVIDENCE' for alias in node.names):
                    readers.append(str(path.relative_to(HERE)))
                if isinstance(node, ast.Attribute) and node.attr == 'METRIC_EVIDENCE' and \
                        isinstance(node.value, ast.Name) and node.value.id == 'coverage':
                    readers.append(str(path.relative_to(HERE)))
        self.assertEqual(readers, [])


if __name__ == '__main__':
    unittest.main()
