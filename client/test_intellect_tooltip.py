from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
format = string.format
strfind = string.find
strsub = string.sub
DEFAULT_STAT4_TOOLTIP = "Increases maximum mana by %d.|nIncreases spell critical strike chance by %.2f%%."
function UnitHasMana(unit) return hasMana end
function GetSpellCritChanceFromIntellect(unit) return 1.25 end
function PaperDollFrame_SetStat(frame, statIndex, unit)
 frame.tooltip2 = nil
 if statIndex == 4 and UnitHasMana(unit or "player") then
  frame.tooltip2 = format(DEFAULT_STAT4_TOOLTIP, 100, 1.25)
 end
end
frame = {}
'''


class IntellectTooltipTest(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        source = ROOT / 'client/Interface/FrameXML/CoAIntellectTooltip.lua'
        self.lua.execute(source.read_text(encoding='utf-8') if source.exists() else '')
        self.lua.execute('PaperDollFrame_SetStat(frame, 4)')

    def test_no_mana_player_keeps_spell_crit_explanation(self):
        self.lua.execute('hasMana = false')
        self.lua.execute('PaperDollFrame_SetStat(frame, 4)')
        self.assertEqual(
            self.lua.eval('frame.tooltip2'),
            'Increases spell critical strike chance by 1.25%.')

    def test_mana_player_tooltip_is_unchanged(self):
        self.lua.execute('hasMana = true')
        self.lua.execute('PaperDollFrame_SetStat(frame, 4)')
        self.assertEqual(
            self.lua.eval('frame.tooltip2'),
            'Increases maximum mana by 100.|nIncreases spell critical strike chance by 1.25%.')

    def test_other_stats_are_unchanged(self):
        self.lua.execute('hasMana = false; PaperDollFrame_SetStat(frame, 1)')
        self.assertIsNone(self.lua.eval('frame.tooltip2'))


if __name__ == '__main__':
    unittest.main()
