from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
CompactUnitMixin = {}
function CompactUnitMixin:SetUnit(unit)
 self.unit = unit
 self:SetAttribute("unit", unit)
 self:UpdateAll()
end
function InCombatLockdown() return inCombat end
function NewUnitFrame(disableMouse)
 return {
  disableMouse = disableMouse,
  attributes = {},
  SetAttribute = function(self, name, value)
   if InCombatLockdown() then error("secure SetAttribute blocked") end
   self.attributes[name] = value
  end,
  UpdateAll = function(self) self.updated = true end,
 }
end
'''


class NamePlateCombatTest(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        source = ROOT / 'client/Interface/FrameXML/CoANamePlateCombat.lua'
        self.lua.execute(source.read_text(encoding='utf-8') if source.exists() else '')

    def test_mouse_disabled_nameplate_updates_without_secure_write_in_combat(self):
        self.lua.execute('inCombat = true; frame = NewUnitFrame(true); originalSetAttribute = frame.SetAttribute')
        self.lua.execute('ok, err = pcall(function() CompactUnitMixin.SetUnit(frame, "nameplate1") end)')
        self.assertTrue(self.lua.eval('ok'), self.lua.eval('err'))
        self.assertEqual(self.lua.eval('frame.unit'), 'nameplate1')
        self.assertTrue(self.lua.eval('frame.updated'))
        self.assertTrue(self.lua.eval('frame.SetAttribute == originalSetAttribute'))

    def test_mouse_disabled_nameplate_keeps_secure_attribute_outside_combat(self):
        self.lua.execute('inCombat = false; frame = NewUnitFrame(true)')
        self.lua.execute('CompactUnitMixin.SetUnit(frame, "nameplate2")')
        self.assertEqual(self.lua.eval('frame.attributes.unit'), 'nameplate2')

    def test_set_attribute_is_restored_when_combat_update_fails(self):
        self.lua.execute('inCombat = true; frame = NewUnitFrame(true); originalSetAttribute = frame.SetAttribute')
        self.lua.execute('frame.UpdateAll = function() error("forced update failure") end')
        self.lua.execute('ok, err = pcall(function() CompactUnitMixin.SetUnit(frame, "nameplate1") end)')
        self.assertFalse(self.lua.eval('ok'))
        self.assertIn('forced update failure', self.lua.eval('err'))
        self.assertTrue(self.lua.eval('frame.SetAttribute == originalSetAttribute'))

    def test_clickable_compact_frame_keeps_combat_protection(self):
        self.lua.execute('inCombat = true; frame = NewUnitFrame(false)')
        self.lua.execute('ok, err = pcall(function() CompactUnitMixin.SetUnit(frame, "raid1") end)')
        self.assertFalse(self.lua.eval('ok'))
        self.assertIn('secure SetAttribute blocked', self.lua.eval('err'))


if __name__ == '__main__':
    unittest.main()
