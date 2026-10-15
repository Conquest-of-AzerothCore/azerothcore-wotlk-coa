-- Runemaster Firebrand (Weapon Engraving: Fire 653210): "When this effect expires, it explodes, dealing
-- ${$m1+$AP*.075+$spfi*.2} Fire damage per stack." Its effect 0 is that explosion: a periodic Fire tick of $m1 per
-- stack whose amplitude equals the duration, so it ticks once as the aura expires; Explosive Runes 521219 moves the
-- tick with the duration, and Devastating Flames, Forbidden Engraving and Melting Runes all target 653210 (family 38
-- mask1 0x10). aura_ascension_runemaster_firebrand (#161) cast the orphaned Fire Engraving damage 653212 once per stack
-- on the same expiry, a second detonation. Its binding is removed and the tick carries the tooltip's coefficients.
DELETE FROM `spell_script_names` WHERE `spell_id` = 653210 AND `ScriptName` = 'aura_ascension_runemaster_firebrand';

DELETE FROM `spell_bonus_data` WHERE `entry` = 653210;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(653210, 0, 0.2, 0, 0.075, 'CoA Fire Engraving - Firebrand detonation per stack');
