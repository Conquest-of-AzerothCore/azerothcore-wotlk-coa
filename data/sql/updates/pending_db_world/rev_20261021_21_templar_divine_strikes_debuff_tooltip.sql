-- Issue #8362: Divine Strikes' enemy debuff (803372) read its percentage from slot $w1, the unused
-- dummy effect, so it showed 0%. The Argent Blade damage bonus is effect 2, which is slot $w2.
-- Its own description was a stale copy of Scourgebane's damage text; it now states the talent's effect.

DELETE FROM `coa_client_spell_description` WHERE `ID` = 803372;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(803372, 'Damage dealt by Scourgebane now increases the damage of Argent Blade by $s2% for $d, stacking $u times.', 'Damage taken from the Crusader''s Argent Blade is increased by ${$w2}%. Stacks $u times.');
