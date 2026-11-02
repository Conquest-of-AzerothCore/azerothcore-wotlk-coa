from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
UNLOCALIZED_CLASS_NAMES = { Rogue = "ROGUE" }
SpellbookSideTabMixin = {}
function SpellbookSideTabMixin:SetInfo(id, name, texture)
 self:SetID(id)
 if texture ~= "Interface\\Icons\\Ability_Kick" then
  self.Class = UNLOCALIZED_CLASS_NAMES[name]
 end
end
function MakeTab()
 return {
  SetID = function(self, id) self.id = id end,
 }
end
'''


class SpellbookHighlightTest(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        self.lua.execute('''
AscensionSpellbookFrame = { SideBar = { Tab1 = MakeTab(), Tab2 = MakeTab() } }
for _, tab in pairs(AscensionSpellbookFrame.SideBar) do
 tab.SetInfo = SpellbookSideTabMixin.SetInfo
end
''')
        source = ROOT / 'client/Interface/FrameXML/CoASpellbookHighlight.lua'
        self.lua.execute(source.read_text(encoding='utf-8') if source.exists() else '')

    def test_custom_class_tab_is_marked_as_class(self):
        self.lua.execute('tab = AscensionSpellbookFrame.SideBar.Tab2; tab:SetInfo(2, "Rot", "rot-icon")')
        self.assertTrue(self.lua.eval('tab.Class ~= nil'))

    def test_general_tab_is_unchanged(self):
        self.lua.execute('tab = AscensionSpellbookFrame.SideBar.Tab1; tab:SetInfo(1, "General", "Interface\\Icons\\Ability_Kick")')
        self.assertIsNone(self.lua.eval('tab.Class'))

    def test_stock_class_value_is_preserved(self):
        self.lua.execute('tab = AscensionSpellbookFrame.SideBar.Tab2; tab:SetInfo(2, "Rogue", "rogue-icon")')
        self.assertEqual(self.lua.eval('tab.Class'), 'ROGUE')


if __name__ == '__main__':
    unittest.main()
