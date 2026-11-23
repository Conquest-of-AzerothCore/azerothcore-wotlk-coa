from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
playerClass = "PROPHET"
function UnitClass(unit) return "Class", playerClass, 0 end
spells = {
 [803183] = { "Beetle Form", "Interface\\Icons\\INV_Misc_AhnQirajTrinket_01" },
 [800841] = { "Spider Form", "Interface\\Icons\\Ability_Hunter_Pet_Spider" },
 [520307] = { "Venomwing Form", "Interface\\Icons\\Ability_Hunter_Pet_WindSerpent" },
 [803212] = { "Sea Serpent Form", "Interface\\Icons\\Ability_Hunter_Pet_Turtle" },
 [805141] = { "Wasp Form", "Interface\\Icons\\Ability_Hunter_Pet_Wasp" },
 [804980] = { "Weaver Form", "Interface\\Icons\\Spell_Nature_Web" },
 [800912] = { "Vizier Form", "Interface\\Icons\\Spell_Nature_Rejuvenation" },
}
function GetSpellInfo(id)
 local spell = spells[id]
 if spell then return spell[1], "", spell[2] end
end
categories = {
 [1] = { "Head", "INV_Helmet_01" },
 [17] = { "Bear Form", "Ability_Racial_BearForm" },
 [18] = { "Cat Form", "Ability_Druid_CatForm" },
 [19] = { "Travel Form", "Ability_Druid_TravelForm" },
 [20] = { "Aquatic Form", "Ability_Druid_AquaticForm" },
 [21] = { "Flight Form", "Ability_Druid_FlightForm" },
 [22] = { "Moonkin Form", "Spell_Nature_ForceOfNature" },
 [23] = { "Tree of Life", "Ability_Druid_TreeofLife" },
}
C_AppearanceCollection = {
 GetCategoryInfo = function(id)
  local category = categories[id]
  return category[1], category[2], "APPEARANCE_TYPE_INCARNATION"
 end,
}
function Info(id)
 local name, icon, kind = C_AppearanceCollection.GetCategoryInfo(id)
 return name .. "|" .. icon .. "|" .. kind
end
'''


class VenomancerIncarnationNamesTest(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        source = ROOT / 'client/Interface/FrameXML/CoAVenomancerIncarnationNames.lua'
        self.lua.execute(source.read_text(encoding='utf-8') if source.exists() else '')

    def info(self, category):
        return self.lua.eval(f'Info({category})')

    def test_venomancer_sees_each_venomancer_form(self):
        expected = {
            17: 'Beetle Form|INV_Misc_AhnQirajTrinket_01',
            18: 'Spider Form|Ability_Hunter_Pet_Spider',
            19: 'Venomwing Form|Ability_Hunter_Pet_WindSerpent',
            20: 'Sea Serpent Form|Ability_Hunter_Pet_Turtle',
            21: 'Wasp Form|Ability_Hunter_Pet_Wasp',
            22: 'Weaver Form|Spell_Nature_Web',
            23: 'Vizier Form|Spell_Nature_Rejuvenation',
        }
        for category, shown in expected.items():
            self.assertEqual(self.info(category), f'{shown}|APPEARANCE_TYPE_INCARNATION')

    def test_druid_keeps_the_druid_forms(self):
        self.lua.execute('playerClass = "DRUID"')
        self.assertEqual(self.info(18), 'Cat Form|Ability_Druid_CatForm|APPEARANCE_TYPE_INCARNATION')
        self.assertEqual(self.info(20), 'Aquatic Form|Ability_Druid_AquaticForm|APPEARANCE_TYPE_INCARNATION')

    def test_venomancer_other_categories_are_unchanged(self):
        self.assertEqual(self.info(1), 'Head|INV_Helmet_01|APPEARANCE_TYPE_INCARNATION')

    def test_unknown_spell_keeps_the_category(self):
        self.lua.execute('spells[800841] = nil')
        self.assertEqual(self.info(18), 'Cat Form|Ability_Druid_CatForm|APPEARANCE_TYPE_INCARNATION')


if __name__ == '__main__':
    unittest.main()
