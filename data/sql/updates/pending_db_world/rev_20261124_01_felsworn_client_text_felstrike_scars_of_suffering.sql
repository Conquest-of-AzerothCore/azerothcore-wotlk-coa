-- Felstrike (802678): the DBC text printed only the base points ($m1 = 8 + 1), so the client showed 54 while the server
-- deals 34 per tick (9 + 0.5 x (60 - 10) at level 60), 204 per application (owner O-19). patch-ZG.MPQ Spell.dbc now
-- carries the same Description; the same text is expanded in Malice of Gul'dan (800214, @s:802678).
-- Scars of Suffering debuff (570159): the aura tooltip printed ${$m1+$ppl1+$AGI*0.15} = 68 at Agility 130 while the
-- talent's value alone, 15% of the caster's Agility, is the ruling (owner O-20). patch-ZG.MPQ Spell.dbc now carries
-- the same ToolTip.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (802678, 570159);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(802678, 'Burn an enemy for ${($d*1000/$T1)*($802678m1+$802678ppl1+$SP*.05)} Shadowflame Damage over $d, stacking $u times.', NULL),
(570159, '', 'Attackers have ${$AGI*0.15} increased attack power against this target.');
