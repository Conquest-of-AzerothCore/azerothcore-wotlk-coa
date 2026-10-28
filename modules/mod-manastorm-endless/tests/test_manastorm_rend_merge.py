from pathlib import Path
import ast
import itertools
import re
import unittest

ROOT = Path(__file__).resolve().parents[3]


class RendMergeTests(unittest.TestCase):
    def test_stadium_guard_preserves_custom_and_upstream_protections(self):
        source = (ROOT / "src/server/scripts/EasternKingdoms/BlackrockMountain/BlackrockSpire/boss_rend_blackhand.cpp").read_text()
        body = source.split("if (type == AREATRIGGER && data == AREATRIGGER_BLACKROCK_STADIUM)", 1)[1]
        body = body.split("if (!_gythEvent)", 1)[0]
        self.assertEqual(len(re.findall(r"\breturn\s*;", body)), 1)
        predicate = re.search(r"if \((.*?)\)\s*return;", body, re.S).group(1)
        for original, replacement in (
            ("me->IsSummon()", "summon"),
            ("instance->GetBossState(DATA_WARCHIEF_REND_BLACKHAND)", "rend"),
            ("instance->GetBossState(DATA_GYTH)", "gyth"),
            ("||", " or "),
        ):
            predicate = predicate.replace(original, replacement)
        predicate = " ".join(predicate.split())
        tree = ast.parse(predicate, mode="eval")
        allowed = (ast.Expression, ast.BoolOp, ast.Or, ast.Compare, ast.Eq, ast.Name, ast.Load)
        self.assertTrue(all(isinstance(node, allowed) for node in ast.walk(tree)))
        code = compile(tree, "actual-rend-guard", "eval")
        for summon, rend, gyth in itertools.product((False, True), (0, 1, 3), (0, 1, 3)):
            with self.subTest(summon=summon, rend=rend, gyth=gyth):
                actual = eval(code, {"__builtins__": {}}, {
                    "summon": summon, "rend": rend, "gyth": gyth, "DONE": 3, "IN_PROGRESS": 1,
                })
                self.assertEqual(actual, summon or rend == 3 or gyth == 1)
        self.assertIn("bool _gythEvent = false;", source)
        self.assertIn("uint8 _currentWave = 0;", source)


if __name__ == "__main__":
    unittest.main()
