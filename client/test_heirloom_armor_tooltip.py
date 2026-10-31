from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
RED_FONT_COLOR = {r = 1, g = 0.125, b = 0.125}
function GetAuctionItemSubClasses() return "Miscellaneous", "Cloth", "Leather", "Mail", "Plate" end
known = {}
function IsSpellKnown(id) return known[id] == true end
function GetSpellInfo() return nil end
skillLines = {}
function GetNumSkillLines() return #skillLines end
function GetSkillLineInfo(index) return skillLines[index][1], skillLines[index][2] end
items = {
 stockade = {7, "Plate"},
 dreadmist = {7, "Cloth"},
 forestGarb = {1, "Leather"},
 heirloomSword = {7, "One-Handed Swords"},
}
function GetItemInfo(link) local item = items[link]; return "name", link, item[1], 1, 1, "Armor", item[2] end

function FontString(text)
 return {text = text, shown = text ~= nil,
  IsShown = function(self) return self.shown end,
  GetText = function(self) return self.text end,
  SetText = function(self, value) self.text = value end,
  SetTextColor = function(self, r, g, b) self.color = {r, g, b} end}
end

function Tooltip(name)
 local tooltip = {name = name, lines = 3, shows = 0}
 function tooltip:GetName() return self.name end
 function tooltip:GetItem() return "name", self.link end
 function tooltip:NumLines() return self.lines end
 function tooltip:Show() self.shows = self.shows + 1 end
 function tooltip:HookScript(event, handler) self.hooks = self.hooks or {}; self.hooks[event] = handler end
 return tooltip
end

GameTooltip = Tooltip("GameTooltip")
ItemRefTooltip = Tooltip("ItemRefTooltip")
ShoppingTooltip1 = Tooltip("ShoppingTooltip1")
ShoppingTooltip2 = Tooltip("ShoppingTooltip2")

function Hover(tooltip, link, rightText)
 tooltip.link = link
 _G[tooltip.name .. "TextRight2"] = FontString(nil)
 _G[tooltip.name .. "TextRight3"] = FontString(rightText)
 tooltip.hooks.OnTooltipSetItem(tooltip)
 local right = _G[tooltip.name .. "TextRight3"]
 return right.text, right.color and right.color[1], right.color and right.color[2]
end
'''


class HeirloomArmorTooltipTest(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        self.lua.execute((ROOT / 'client/Interface/FrameXML/CoAHeirloomArmorTooltip.lua').read_text())

    def hover(self, link, right_text, tooltip='GameTooltip'):
        return self.lua.eval(f'{{Hover({tooltip}, "{link}", "{right_text}")}}')

    def wear(self, *spell_ids):
        for spell_id in spell_ids:
            self.lua.execute(f'known[{spell_id}] = true')

    def test_leather_wearer_sees_plate_heirloom_as_red_plate(self):
        self.wear(9078, 9077)
        result = self.hover('stockade', 'Leather')
        self.assertEqual((result[1], result[2], result[3]), ('Plate', 1, 0.125))

    def test_plate_wearer_sees_plate_heirloom_as_white_plate(self):
        self.wear(9078, 9077, 8737, 750)
        result = self.hover('stockade', 'Plate')
        self.assertEqual((result[1], result[2], result[3]), ('Plate', 1, 1))

    def test_comparison_and_link_tooltips_are_corrected(self):
        self.wear(9078, 9077)
        for tooltip in ('ItemRefTooltip', 'ShoppingTooltip1', 'ShoppingTooltip2'):
            result = self.hover('stockade', 'Leather', tooltip)
            self.assertEqual((result[1], result[2], result[3]), ('Plate', 1, 0.125), tooltip)

    def test_skill_lines_count_when_the_proficiency_spell_is_not_reported(self):
        self.lua.execute('skillLines = {{"Armor Proficiencies", true}, {"Cloth", false}, {"Plate Mail", false}}')
        result = self.hover('stockade', 'Cloth')
        self.assertEqual((result[1], result[2], result[3]), ('Plate', 1, 1))

    def test_wearable_cloth_heirloom_stays_white_cloth(self):
        self.wear(9078)
        result = self.hover('dreadmist', 'Cloth')
        self.assertEqual((result[1], result[2], result[3]), ('Cloth', 1, 1))

    def test_ordinary_armor_and_heirloom_weapons_are_untouched(self):
        self.wear(9078)
        result = self.hover('forestGarb', 'Leather')
        self.assertEqual((result[1], result[2]), ('Leather', None))
        result = self.hover('heirloomSword', 'Sword')
        self.assertEqual((result[1], result[2]), ('Sword', None))


if __name__ == '__main__':
    unittest.main()
