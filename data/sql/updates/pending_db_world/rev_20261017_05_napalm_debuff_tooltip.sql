-- Napalm (805315) is the Tinker debuff applied by direct Fire damage. Its client
-- Spell.dbc text says only "Fire Damage taken ... is increased", with no amount
-- and no per-stack statement, while the healing line renders a bare "3%":
--
--   Description: "Fire Damage taken by you is increased and healing received
--     reduced by $803787s1% for $d. Stacks $u times."
--   ToolTip: "Fire Damage taken from the Tinker and healing received reduced
--     by $803787s1%."
--
-- The server behavior (AscensionTinkerContracts tinker_scaling plus the 805315
-- rewrite in the same file) is: Effect 0 keeps its base points (BP 2, so
-- Amount(805315) is 3) and the script adds +3% Fire damage taken per stack up
-- to 10 stacks over 8 s; Effect 1 is rewritten to SPELL_AURA_MOD_HEALING_PCT
-- with -3, a flat -3% healing received at any stack count. The $s variables
-- cannot express the scripted per-stack number (Effect 0 is dummied
-- server-side and $803787s1 belongs to a sibling rank), so the override writes
-- the 3% out with its source cited here and keeps the proven $d (8 s) and $u
-- (10 stacks) variables. `coa_client_spell_description` streams both columns
-- to the client as SMSG_PATCH_SPELL at login.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (805315);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`,`ToolTip`) VALUES
(805315,'Fire Damage taken by you is increased by 3% for each stack of Napalm and healing received reduced by 3% for $d. Stacks $u times.','Fire Damage taken from the Tinker increased by 3% for each stack of Napalm and healing received reduced by 3%.');
