from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
MOCK = r'''
SPELLS = {
 Fireball = { harm = true },
 ["Flash Heal"] = { help = true },
 ["Holy Shock"] = { harm = true, help = true },
 Attack = { attack = true },
 ["Arcane Intellect"] = { help = true },
}
function IsHarmfulSpell(name) local s = SPELLS[name]; return s and s.harm and 1 or nil end
function IsHelpfulSpell(name) local s = SPELLS[name]; return s and s.help and 1 or nil end
function IsAttackSpell(name) local s = SPELLS[name]; return s and s.attack and 1 or nil end

-- The chooser runs in the game's restricted environment: only these names exist there.
units, combat = {}, false
local function U(u) return units[u] end
SW, SH = 1365, 768
local Handle = {}
Handle.__index = Handle
function Handle:GetAttribute(k) return self.a[k] end
function Handle:GetFrameRef(k) return self.refs[k] end
function Handle:IsProtected() return true end
function Handle:IsVisible() return true end
function Handle:GetEffectiveScale() return self.eff end
function Handle:GetRect() local r = self.rect; return r.l / self.eff, r.b / self.eff, r.w / self.eff, r.h / self.eff end
function Handle:GetChildList(t) return t end
function NewHandle(a, refs, rect, eff)
 return setmetatable({ a = a, refs = refs or {}, rect = rect, eff = eff or 1 }, Handle)
end
function NewPlate(unit, x, bottom)
 return NewHandle({ unit = unit }, nil, { l = x - 55, b = bottom, w = 110, h = 22 }, 1.2)
end
env = {
 UnitExists = function(u) return U(u) ~= nil end,
 UnitIsDead = function(u) return U(u) and U(u).dead or false end,
 PlayerCanAttack = function(u) return U(u) and U(u).hostile or false end,
 newtable = function() return {} end, tinsert = table.insert, strmatch = string.match,
 format = string.format, tonumber = tonumber, type = type,
}
'''

SETUP = r'''
header = NewHandle({ fb = 1, aim = 1, aimsize = AutoTarget.AIM_SIZE_DEFAULT, aimyw = AutoTarget.AIM_Y_WEIGHT, np = 0 },
 { screen = NewHandle({}, nil, { l = 0, b = 0, w = SW, h = SH }, 0.85), world = NewHandle({}) })
local def = assert(loadstring("return function (self, ...) " .. AutoTarget.CHOOSE_SNIPPET .. "\nend"))
setfenv(def, {})
choose = def()
setfenv(choose, env)
function Pool(list)
 header.a.np = #list
 for i, p in ipairs(list) do header.refs["p" .. i] = p end
end
HOST, DEAD, FRIEND = { hostile = true }, { hostile = true, dead = true }, { hostile = false }
CX, CY = SW / 2, SH / 2
'''


class AutoTargetTest(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        source = ROOT / 'client-addons/AutoTarget/Rule.lua'
        self.lua.execute(source.read_text(encoding='utf-8'))
        self.lua.execute(SETUP)

    def choose(self):
        return self.lua.eval('(choose(header, "centre"))')

    def test_secure_snippets_obey_the_restricted_code_rules(self):
        for name in ('CHOOSE_SNIPPET', 'PICK_SNIPPET', 'WHO_SNIPPET', 'KEY_SNIPPET'):
            self.assertFalse(self.lua.eval(f'AutoTarget.{name}:find("function", 1, true) ~= nil'), name)
            self.assertFalse(self.lua.eval(f'AutoTarget.{name}:find("[{{}}]") ~= nil'), name)

    def test_macro_text_for_each_choice(self):
        macro = 'AutoTarget.MacroFor'
        self.assertEqual(self.lua.eval(f'{macro}("keep", false, true)'), '')
        self.assertEqual(self.lua.eval(f'{macro}("nameplate2", false, false)'),
                         '/target [target=nameplate2,harm,nodead]')
        self.assertEqual(self.lua.eval(f'{macro}("nameplate2", false, true)'),
                         '/target [target=nameplate2,harm,nodead]\n/targetenemy [noharm][dead]')
        self.assertEqual(self.lua.eval(f'{macro}("nearest", true, true)'),
                         '/targetenemy [noharm][dead]\n/startattack [harm,nodead]')
        self.assertEqual(self.lua.eval(f'{macro}("none", true, true)'), '')

    def test_only_harmful_actions_are_picked_for(self):
        harmful = 'AutoTarget.IsHarmfulSpellName'
        self.assertTrue(self.lua.eval(f'{harmful}("Fireball")'))
        self.assertTrue(self.lua.eval(f'{harmful}("Attack")'))
        self.assertFalse(self.lua.eval(f'{harmful}("Flash Heal")'))
        self.assertFalse(self.lua.eval(f'{harmful}("Arcane Intellect")'))
        self.assertFalse(self.lua.eval(f'{harmful}("")'))

    def test_spell_that_heals_and_harms_is_dual(self):
        self.assertTrue(self.lua.eval('AutoTarget.IsDualSpellName("Holy Shock")'))
        self.assertFalse(self.lua.eval('AutoTarget.IsDualSpellName("Fireball")'))
        self.assertEqual(self.lua.eval('AutoTarget.PrefixLine(nil, true)'),
                         '/click [nohelp][dead] AutoTargetPick\n')
        self.assertEqual(self.lua.eval('AutoTarget.PrefixLine()'), '/click AutoTargetPick\n')

    def test_living_enemy_target_is_kept(self):
        self.lua.execute('units.target = HOST; units.nameplate1 = HOST; Pool({ NewPlate("nameplate1", CX, CY) })')
        self.assertEqual(self.choose(), 'keep')

    def test_enemy_under_the_mouse_comes_before_the_plates(self):
        self.lua.execute('units.mouseover = HOST; units.nameplate1 = HOST; Pool({ NewPlate("nameplate1", CX, CY) })')
        self.assertEqual(self.choose(), 'mouseover')

    def test_middle_of_the_screen_wins_over_nearer_at_the_side(self):
        self.lua.execute('''
            units.nameplate1, units.nameplate2 = HOST, HOST
            Pool({ NewPlate("nameplate1", CX + 420, CY - 150), NewPlate("nameplate2", CX + 10, CY + 20) })
        ''')
        self.assertEqual(self.choose(), 'nameplate2')

    def test_dead_and_friendly_plates_are_skipped(self):
        self.lua.execute('''
            units.nameplate1, units.nameplate2, units.nameplate3 = DEAD, FRIEND, HOST
            Pool({ NewPlate("nameplate1", CX, CY), NewPlate("nameplate2", CX + 5, CY),
                   NewPlate("nameplate3", CX + 90, CY + 10) })
        ''')
        self.assertEqual(self.choose(), 'nameplate3')

    def test_nobody_in_the_circle_uses_the_nearest_enemy_option(self):
        self.lua.execute('''
            units.nameplate1 = HOST
            Pool({ NewPlate("nameplate1", 80, 300) })
        ''')
        self.assertEqual(self.choose(), 'nearest')
        self.lua.execute('header.a.fb = 0')
        self.assertEqual(self.choose(), 'none')

    def test_without_nameplate_tokens_only_the_simple_rule_runs(self):
        self.lua.execute('''
            header.a.aim = 0
            units.nameplate1 = HOST
            Pool({ NewPlate("nameplate1", CX, CY) })
        ''')
        self.assertEqual(self.choose(), 'nearest')
