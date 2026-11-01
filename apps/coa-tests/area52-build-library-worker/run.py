from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[3]
WORKER = ROOT / 'apps/area52-build-library'
sys.path[:0] = [str(WORKER / 'tools'), str(WORKER / 'portable/tools'), str(WORKER / 'portable/tests')]
import portable_dependency

suite = unittest.TestSuite()
for folder in (WORKER / 'tests', WORKER / 'portable/tests'):
    loader = unittest.TestLoader()
    suite.addTests(loader.discover(str(folder)))
raise SystemExit(0 if unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful() else 1)
