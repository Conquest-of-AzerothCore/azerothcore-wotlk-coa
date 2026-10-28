-- Napalm (805315), third wording pass: restore live per-stack numbers.
--
-- rev_20261017_05/06 replaced the DBC variables with hardcoded "3%" text, which
-- froze the tooltip: the client renders $s variables in aura tooltips against
-- live stacks (the pre-fix text grew as marks stacked). The DBC text referenced
-- the helper 803787 for the healing number because 805315's own Effect 1
-- (base points -1) renders 0; 803787's first effect (base points -4) is the slot
-- that renders the 3. By the same rule ($s1 = first effect value, base points
-- + 1), 805315's own Effect 0 (base points 2, the +3% Fire taken per stack the
-- scaling script reads as Amount(805315)) renders its 3 through $805315s1, so
-- the previously missing Fire amount is added the same dynamic way instead of
-- hardcoded. Healing keeps the original $803787s1 reference; $d (8 s) and $u
-- (10 stacks) are unchanged. Supersedes _05/_06 wording; DELETE+INSERT stays
-- idempotent. Confirm in game: hover the debuff at 1 vs 3+ stacks, both numbers
-- must grow per stack.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (805315);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`,`ToolTip`) VALUES
(805315,'Fire Damage taken by you is increased by $805315s1% for each stack of Napalm and healing received reduced by $803787s1% for $d. Stacks $u times.','Fire Damage taken from the Tinker increased by $805315s1% for each stack of Napalm and healing received reduced by $803787s1%.');
