-- Napalm (805315), second wording pass. rev_20261017_05 corrected the debuff text
-- to "increased by 3% for each stack of Napalm", but the tooltip still does not
-- show what the values are across the stack ladder. No tooltip variable resolves
-- a live stack count ($a1 is effect radius; $u is only the cap; the $s values of
-- the server-repurposed effects do not render the scripted number), so the
-- reachable maximum is written out: +3% Fire damage taken per stack (Effect 0
-- base points 2, read by the scaling script as Amount(805315)) reaches +30% at
-- the 10-stack cap, while healing received stays a flat -3% (Effect 1 rewritten
-- to SPELL_AURA_MOD_HEALING_PCT -3, unscaled by stacks). $d (8 s) and $u
-- (10 stacks) are kept as proven variables. Supersedes the wording of _05; the
-- DELETE+INSERT stays idempotent.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (805315);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`,`ToolTip`) VALUES
(805315,'Fire Damage taken by you is increased by 3% for each stack of Napalm, up to 30% at 10 stacks, and healing received reduced by 3% for $d. Stacks $u times.','Fire Damage taken from the Tinker increased by 3% for each stack of Napalm, up to 30% at 10 stacks, and healing received reduced by 3%.');
