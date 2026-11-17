from dataclasses import fields
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from behaviours import KINDS, MetricDeltaSpec, behaviour_kinds
from kinds import kind_modules
from metric_delta_options import option_modules
from passives import BEHAVIOUR_LABELS

PACKAGE = Path(__file__).resolve().parent


class KindRegistryTests(unittest.TestCase):
    def test_every_kind_module_imports_and_names_its_kind_and_scenario(self):
        modules = kind_modules()
        self.assertTrue(modules)
        for module in modules:
            with self.subTest(module=module.__name__):
                self.assertEqual(module.__name__, f'kinds.{module.KIND}')
                self.assertIsInstance(module.ORDER, int)
                self.assertTrue(callable(module.scenario))

    def test_a_discovered_kind_is_neither_a_builtin_kind_nor_a_builtin_label(self):
        names = [module.KIND for module in kind_modules()]
        self.assertEqual(sorted(set(names) & set(KINDS)), [])
        self.assertEqual(sorted(set(names) & set(BEHAVIOUR_LABELS)), [])
        self.assertEqual(behaviour_kinds(), KINDS + tuple(names))

    def test_every_kind_module_has_its_own_test_file(self):
        for module in kind_modules():
            with self.subTest(kind=module.KIND):
                self.assertTrue((PACKAGE / 'kinds' / f'test_{module.KIND}.py').is_file())


class MetricDeltaOptionRegistryTests(unittest.TestCase):
    def test_every_option_module_names_its_entry_field_and_parses_it(self):
        modules = option_modules()
        self.assertTrue(modules)
        for module in modules:
            with self.subTest(module=module.__name__):
                self.assertEqual(module.__name__, f'metric_delta_options.{module.NAME}')
                self.assertIsInstance(module.ORDER, int)
                self.assertTrue(callable(module.parse))
                self.assertTrue((PACKAGE / 'metric_delta_options' / f'test_{module.NAME}.py').is_file())

    def test_an_option_field_is_not_also_a_spec_field(self):
        names = {field.name for field in fields(MetricDeltaSpec)}
        self.assertEqual(sorted(module.NAME for module in option_modules() if module.NAME in names), [])


def load_tests(loader, tests, pattern):
    for package in ('kinds', 'metric_delta_options'):
        tests.addTests(loader.discover(str(PACKAGE / package), pattern='test_*.py', top_level_dir=str(PACKAGE)))
    return tests


if __name__ == '__main__':
    unittest.main()
