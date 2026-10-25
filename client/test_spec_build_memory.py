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

pending = {spec = 0, ranks = {}}
importFails = false
local identity = {[10] = 1, [20] = 2}

C_CharacterAdvancement = {
 GetActiveChrSpec = function() return pending.spec end,
 SwitchActiveChrSpec = function(spec)
  pending.ranks = {}
  pending.spec = spec
  pending.ranks[spec] = 1
 end,
 ExportBuild = function(includeREs)
  return pending.spec .. "|" .. Ranks()
 end,
 ImportPendingBuild = function(text)
  if importFails then return false, "CA_LEARN_BAD_ABILITY" end
  local spec, list = text:match("^(%d+)|(.*)$")
  pending.spec = tonumber(spec)
  pending.ranks = {}
  for id, rank in list:gmatch("(%d+):(%d+)") do pending.ranks[tonumber(id)] = tonumber(rank) end
  return true
 end,
 ClearPendingBuild = function() pending.ranks = {}; pending.spec = 0 end,
}

function Build(spec, ranks)
 pending.spec = spec
 pending.ranks = ranks
end

function Ranks()
 local ids, out = {}, {}
 for id in pairs(pending.ranks) do ids[#ids + 1] = id end
 table.sort(ids)
 for _, id in ipairs(ids) do out[#out + 1] = id .. ":" .. pending.ranks[id] end
 return table.concat(out, ",")
end
'''


class SpecBuildMemoryTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        self.lua.execute((ROOT / 'client/Interface/FrameXML/CoASpecBuildMemory.lua').read_text(encoding='utf-8'))
        self.lua.execute('CoASpecBuildMemory.debug = false')
        self.lua.execute('CoASpecBuildMemory.OnEvent("PLAYER_ENTERING_WORLD")')

    def ranks(self):
        return self.lua.eval('Ranks()')

    def test_returning_to_the_original_spec_restores_its_pending_build(self):
        self.lua.execute('Build(10, {[10]=1,[101]=3,[102]=1,[103]=2})')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(20)')
        self.assertEqual(self.ranks(), '20:1')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(10)')
        self.assertEqual(self.ranks(), '10:1,101:3,102:1,103:2')
        self.assertEqual(self.lua.eval('pending.spec'), 10)

    def test_unsaved_edits_made_in_the_inspected_spec_survive_a_second_visit(self):
        self.lua.execute('Build(10, {[10]=1,[101]=1})')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(20)')
        self.lua.execute('pending.ranks[201]=2')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(10)')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(20)')
        self.assertEqual(self.ranks(), '20:1,201:2')

    def test_a_spec_never_left_is_not_restored_from_anything(self):
        self.lua.execute('Build(0, {})')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(20)')
        self.assertEqual(self.ranks(), '20:1')

    def test_clearing_the_pending_build_forgets_the_remembered_builds(self):
        self.lua.execute('Build(10, {[10]=1,[101]=3})')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(20)')
        self.lua.execute('C_CharacterAdvancement.ClearPendingBuild(0)')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(10)')
        self.assertEqual(self.ranks(), '10:1')

    def test_a_server_state_change_forgets_the_remembered_builds(self):
        for event in ('ASCENSION_KNOWN_ENTRY_UPDATED', 'ASCENSION_KNOWN_ENTRY_REMOVED'):
            self.lua.execute('Build(10, {[10]=1,[101]=3})')
            self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(20)')
            self.lua.execute(f'CoASpecBuildMemory.OnEvent("{event}")')
            self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(10)')
            self.assertEqual(self.ranks(), '10:1', event)

    def test_a_refused_import_leaves_the_plain_switch_result(self):
        self.lua.execute('Build(10, {[10]=1,[101]=3})')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(20)')
        self.lua.execute('importFails=true')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(10)')
        self.assertEqual(self.ranks(), '10:1')

    def test_switching_to_the_current_spec_changes_nothing(self):
        self.lua.execute('Build(10, {[10]=1,[101]=3})')
        self.lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(10)')
        self.assertEqual(self.ranks(), '10:1')

    def test_install_is_idempotent_and_needs_the_whole_api(self):
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
        lua.execute('Build(10, {[10]=1,[101]=3})')
        lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(20)')
        lua.execute('C_CharacterAdvancement.SwitchActiveChrSpec(10)')
        self.assertEqual(lua.eval('Ranks()'), '10:1,101:3')


if __name__ == '__main__':
    unittest.main()
