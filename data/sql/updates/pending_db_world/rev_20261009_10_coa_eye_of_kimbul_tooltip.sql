-- Eye of Kimbul (#6979): the debuff names its numbers through the damage-scaled form of the
-- weapon tokens, so the unit frame and the debuff tooltip render a scaled figure instead of
-- the 1% per stack the auras carry.
--
-- The spell is 802707, the debuff the Shadowhunting talent 503714 leaves on enemies. Its
-- client and server Spell.dbc row is effect 0 aura 271 (MOD_DAMAGE_FROM_CASTER, MiscValue
-- 127 = all schools) and effect 1 aura 308 (MOD_CRIT_CHANCE_FOR_CASTER), each with
-- EffectBasePoints 0 / EffectDieSides 1 = 1%, StackAmount 5 and DurationIndex 8 = 15 s.
-- The server applies exactly that: five stacks measure +1% damage from the caster and
-- +5.0% melee, ranged and spell critical chance against the affected target, and nothing
-- against any other enemy (scenarios witchdoctor-eye-kimbul-ranged-auto-crit-6979 and
-- witchdoctor-eye-kimbul-one-percent-stacks-4093). Traced where a Witch Doctor critical
-- chance can come from otherwise: Unit::GetUnitCriticalChance and Unit::SpellTakenCritChance
-- are the only two consumers of aura 308 and both filter on the caster; the guaranteed-crit
-- conditional (ASCENSION_CONDITIONAL_GUARANTEED_CRIT) is bound to the Felsworn and
-- Necromancer contracts only (AscensionFelswornContracts.cpp, AscensionNecromancerContracts.cpp);
-- Juju Spirits 807296 adds its 5%-per-Spirit flat spellmod to Bad Juju alone, and the
-- "Pain" rows 706643/706664 that carry a 100% aura 308 are applied by nothing in the core.
--
-- Description[enUS] (column 170) states the right value: "$s2" is effect 1's 1 and "$u" is 5.
-- ToolTip[enUS] (column 187), the aura text the unit frame and the debuff tooltip show, is
-- the broken half: "The Shadowhunter deals ${$w1}% increased damage to you and has a
-- ${$w2}% increased chance to critically strike you." ${$wN} is the damage-scaled
-- placeholder, so the client runs those two percent auras through its damage scaling and
-- five stacks read as a three-digit figure - the 100% the report quotes, and the same
-- defect class as 680692's old "${$w1}% of healing" aura text
-- (rev_20261007_40_coa_sanguine_essence_bloodmoon_echo.sql) and 706654's unresolvable
-- "${$532612w1}" (rev_20261004_03_bloodmage_bite_wound_tooltip_unitframe.sql).
--
-- The repository cannot edit the client's Spell.dbc, and AscensionCompat already streams
-- `coa_client_spell_description` to the client as SMSG_PATCH_SPELL at login, so the fix
-- publishes the corrections here. The Description is repeated byte for byte from the
-- client's own row so the only change is the aura text; the magnitudes written into it are
-- the DBC's own 1% per stack, and "$u" stays for the stack count. Idempotent: delete of the
-- exact key followed by the insert.

DELETE FROM `coa_client_spell_description` WHERE `ID` = 802707;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(802707,'Increases your damage dealt and critical strike chance against this target by $s2%, stacking $u times.\r\n\r\nWhile affected, enemies cannot stealth or turn invisible.','The Shadowhunter deals 1% increased damage to you per stack and has a 1% increased chance to critically strike you per stack. Stacks $u times. Cannot stealth or turn invisible.');
