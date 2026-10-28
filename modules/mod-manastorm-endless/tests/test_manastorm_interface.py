from pathlib import Path
import importlib.util
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
OVERLAY = ROOT / "modules/mod-manastorm-endless/client/overlay/Interface"
NS = {"ui": "http://www.blizzard.com/wow/ui/"}


class ManastormInterfaceIntegration(unittest.TestCase):
    def test_reward_anchor_is_exposed_on_queue(self):
        tree = ET.parse(OVERLAY / "AddOns/Ascension_Manastorm/ManastormQueue.xml")
        dividers = tree.findall(".//ui:Texture[@parentKey='RewardDiv']", NS)
        self.assertEqual(len(dividers), 1)
        self.assertEqual(dividers[0].get("name"), "$parentRewardDiv")
        frames = tree.findall(".//ui:Frame[@name='ManastormQueueFrame']", NS)
        self.assertEqual(len(frames), 1)
        self.assertIn(dividers[0], list(frames[0].iter()))

    def test_queue_uses_native_levels_without_missing_helper(self):
        queue = (OVERLAY / "AddOns/Ascension_Manastorm/ManastormQueue.lua").read_text()
        self.assertNotIn("AscensionLocalManastormFilterLevels", queue)
        self.assertIn("C_Manastorm.GetEnterableLevels()", queue)
        self.assertIn("C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)", queue)

    def test_package_contains_all_four_canonical_client_files(self):
        path = ROOT / "modules/mod-manastorm-endless/client/build_keybind_patch.py"
        spec = importlib.util.spec_from_file_location("manastorm_client_package", path)
        package = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(package)
        ui = (OVERLAY / "FrameXML/UIParent.lua").read_bytes()
        members = package.overlay_members(ui)
        expected = {
            "Interface/FrameXML/UIParent.lua",
            "Interface/AddOns/Ascension_Manastorm/ManastormQueue.xml",
            "Interface/AddOns/Ascension_Manastorm/ManastormQueue.lua",
            "Interface/AddOns/Ascension_Manastorm/ManastormLoadoutFlyout.lua",
        }
        paths = [name.decode("ascii").replace(chr(92), "/") for name, _ in members]
        self.assertEqual(len(paths), 4)
        self.assertEqual(set(paths), expected)
        for name, data in members:
            relative = name.decode("ascii").replace(chr(92), "/").removeprefix("Interface/")
            self.assertEqual(data, (OVERLAY / relative).read_bytes())
        queue = dict(members)[package.QUEUE_LUA_MEMBER].decode("utf-8-sig")
        self.assertNotIn("ASCENSION_LOCAL_MANASTORM_CAP", queue)
        self.assertNotIn("AscensionLocalManastormFilterLevels", queue)

    def test_trusted_addon_is_also_sent_to_client(self):
        source = (ROOT / "src/server/coa/AscensionCompat.cpp").read_text()
        secure = source.split("secureAscensionAddons = {", 1)[1].split("};", 1)[0]
        sent = source.split("ascensionAddons = {", 1)[1].split("};", 1)[0]
        name = '"Ascension_Manastorm"'
        self.assertEqual(secure.count(name), 1)
        self.assertEqual(sent.count(name), 1)
        self.assertIn('name.starts_with("Blizzard_") || secureAscensionAddons.contains(name)', source)


if __name__ == "__main__":
    unittest.main()
