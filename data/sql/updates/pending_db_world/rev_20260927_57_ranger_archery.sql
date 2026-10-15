-- Ranger Pierced (705033): critical Skullpiercer and Precision Shot hits bleed the enemy through Pierced (782754),
-- whose aura script deals 15% of the hit on application and 35% over the two ticks of its 4 sec duration.
DELETE FROM `spell_script_names` WHERE `spell_id` = 782754 AND `ScriptName` = 'aura_ascension_ranger_pierced_bleed';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(782754, 'aura_ascension_ranger_pierced_bleed');

-- Ranger Brutal Shot (570014): "While Skirmish is active this ability is guaranteed to critically strike."
-- The hidden Skirmish SLS record (803335) carries the +100% critical chance modifier on Brutal Shot's family flag
-- and is kept on the Ranger for exactly as long as Skirmish (802039) is.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 802039 AND `spell_effect` = 803335 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(802039, 803335, 2, 'Ranger Skirmish - Skirmish SLS (Brutal Shot guaranteed critical strike)');
