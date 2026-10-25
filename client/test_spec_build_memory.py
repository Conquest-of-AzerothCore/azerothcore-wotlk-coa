from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
frames = {}
function CreateFrame()
 local f = {events = {}, scripts = {}}
 function f:RegisterEvent(e) self.events[e] = true end
 function f:SetScript(k, v) self.scripts[k] = v end
 frames[#frames + 1] = f
 return f
end

known = {spec = 10, ranks = {[10] = 1, [101] = 3, [102] = 1}}
pending = {spec = 10, ranks = {[10] = 1, [101] = 3, [102] = 1}}
noPending = false
RefreshFromCancel = false
refreshSeenOnCancel = nil

local function copy(ranks)
 local out = {}
 for id, rank in pairs(ranks) do out[id] = rank end
 return out
end

function Ranks(build)
 local ids, out = {}, {}
 for id in pairs(build.ranks) do ids[#ids + 1] = id end
 table.sort(ids)
 for _, id in ipairs(ids) do out[#out + 1] = id .. ":" .. build.ranks[id] end
 return table.concat(out, ",")
end

C_CharacterAdvancement = {
 GetActiveChrSpec = function() return pending.spec end,
 SwitchActiveChrSpec = function(spec)
  if spec == pending.spec then return end
  pending.ranks = {[spec] = 1}
  pending.spec = spec
 end,
 IsPending = function()
  if noPending then error("pending build is not available") end
  return pending.spec ~= known.spec or Ranks(pending) ~= Ranks(known)
 end,
 CancelPendingBuild = function()
  refreshSeenOnCancel = RefreshFromCancel
  pending = {spec = known.spec, ranks = copy(known.ranks)}
 end,
}
'''


class SpecBuildMemoryTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        self.lua.execute((ROOT / 'client/Interface/FrameXML/CoASpecBuildMemory.lua').read_text(encoding='utf-8'))
        self.lua.execute('CoASpecBuildMemory.debug = false')
        self.lua.execute('CoASpecBuildMemory.OnEvent("PLAYER_ENTERING_WORLD")')

    def switch(self, spec):
        self.lua.execute(f'C_CharacterAdvancement.SwitchActiveChrSpec({spec})')

    def pending(self):
        return self.lua.eval('Ranks(pending)')

    def test_returning_to_the_saved_spec_restores_the_saved_build(self):
        self.switch(20)
        self.assertEqual(self.pending(), '20:1')
        self.switch(10)
        self.assertEqual(self.pending(), '10:1,101:3,102:1')
        self.assertFalse(self.lua.eval('C_CharacterAdvancement.IsPending()'))

    def test_the_window_is_told_to_refresh_when_the_build_is_restored(self):
        self.switch(20)
        self.switch(10)
        self.assertTrue(self.lua.eval('refreshSeenOnCancel'))

    def test_a_visit_through_a_third_spec_still_returns_to_the_saved_build(self):
        self.switch(20)
        self.switch(30)
        self.assertEqual(self.pending(), '30:1')
        self.switch(10)
        self.assertEqual(self.pending(), '10:1,101:3,102:1')

    def test_switching_between_two_other_specs_changes_nothing_extra(self):
        self.switch(20)
        self.switch(30)
        self.assertEqual(self.pending(), '30:1')
        self.switch(20)
        self.assertEqual(self.pending(), '20:1')

    def test_a_spec_that_is_not_the_saved_one_is_never_restored(self):
        self.lua.execute('known = {spec = 20, ranks = {[20] = 1, [201] = 2}}; pending = {spec = 20, ranks = {[20] = 1, [201] = 2}}')
        self.switch(10)
        self.assertEqual(self.pending(), '10:1')
        self.switch(30)
        self.assertEqual(self.pending(), '30:1')

    def test_switching_to_the_current_spec_does_not_cancel_anything(self):
        self.lua.execute('pending.ranks[103] = 1')
        self.switch(10)
        self.assertEqual(self.pending(), '10:1,101:3,102:1,103:1')
        self.assertIsNone(self.lua.eval('refreshSeenOnCancel'))

    def test_after_the_server_changes_the_saved_build_the_next_clean_switch_relearns_it(self):
        self.switch(20)
        self.lua.execute('known = {spec = 20, ranks = {[20] = 1, [201] = 2}}; pending = {spec = 20, ranks = {[20] = 1, [201] = 2}}')
        self.lua.execute('CoASpecBuildMemory.OnEvent("ASCENSION_KNOWN_ENTRY_UPDATED")')
        self.switch(10)
        self.switch(20)
        self.assertEqual(self.pending(), '20:1,201:2')

    def test_a_missing_pending_build_never_breaks_the_switch(self):
        self.lua.execute('noPending = true')
        self.switch(20)
        self.assertEqual(self.pending(), '20:1')

    def test_install_needs_the_whole_api_and_is_idempotent(self):
        self.assertFalse(self.lua.eval('CoASpecBuildMemory.Install(C_CharacterAdvancement)'))
        self.assertFalse(self.lua.eval('CoASpecBuildMemory.Install({})'))
        self.assertFalse(self.lua.eval('CoASpecBuildMemory.Install(nil)'))

    def test_the_driver_listens_for_the_events_it_needs(self):
        events = set(self.lua.eval('(function() local e={} for k in pairs(frames[1].events) do e[#e+1]=k end return e end)()').values())
        self.assertEqual(events, {'ADDON_LOADED', 'PLAYER_LOGIN', 'PLAYER_ENTERING_WORLD',
                                  'ASCENSION_KNOWN_ENTRY_UPDATED', 'ASCENSION_KNOWN_ENTRY_REMOVED'})

    def test_install_is_retried_until_the_api_is_complete(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(MOCK)
        lua.execute('full = C_CharacterAdvancement; C_CharacterAdvancement = {}')
        lua.execute((ROOT / 'client/Interface/FrameXML/CoASpecBuildMemory.lua').read_text(encoding='utf-8'))
        lua.execute('CoASpecBuildMemory.debug = false')
        self.assertFalse(lua.eval('CoASpecBuildMemory.Install(C_CharacterAdvancement)'))
        lua.execute('C_CharacterAdvancement = full')
        lua.execute('frames[1].scripts.OnUpdate(frames[1], 2)')
        self.assertIsNone(lua.eval('frames[1].scripts.OnUpdate'))
        lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(20)')
        lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(10)')
        self.assertEqual(lua.eval('Ranks(pending)'), '10:1,101:3,102:1')


if __name__ == '__main__':
    unittest.main()
