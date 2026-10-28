import unittest
from patch_prestige_client import patch


class PrestigeClientTest(unittest.TestCase):
    def test_only_threshold_changes(self):
        source = "PrestigeModeUI.MAX_LEVEL \t= 60 -- prestige any level above 60\r\nsize = 60\r\n"
        self.assertEqual(patch(source), "PrestigeModeUI.MAX_LEVEL \t= GetMaxLevel()\r\nsize = 60\r\n")

    def test_unknown_or_duplicate_sources_fail(self):
        for source in ("", "PrestigeModeUI.MAX_LEVEL = 80", "PrestigeModeUI.MAX_LEVEL = 60\n" * 2):
            with self.assertRaises(ValueError):
                patch(source)


if __name__ == "__main__":
    unittest.main()
