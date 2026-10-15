--
-- Fury of the Wild (#458): copy the active class-granted Boons to the owned pet at half effectiveness.
-- Reuse the full active records so Hawk haste and Lion sleep resistance are not lost in old pet variants.
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('aura_ascension_primalist_boon', 'aura_ascension_fury_of_the_wild', 'spell_ascension_pet_hawk_heal', 'aura_ascension_lion_boon_periodic');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500935, 'aura_ascension_primalist_boon'),
(500939, 'aura_ascension_primalist_boon'),
(500943, 'aura_ascension_primalist_boon'),
(800137, 'aura_ascension_primalist_boon'),
(504856, 'aura_ascension_primalist_boon'),
(801234, 'aura_ascension_fury_of_the_wild'),
(997800, 'spell_ascension_pet_hawk_heal'),
(505217, 'aura_ascension_lion_boon_periodic');

-- Restore the authored Lion dispel companion for the same lifetime as its resistance aura.
-- The pet uses the copied Pet SLS's six-second interval; the player retains three seconds.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 504856 AND `spell_effect` = 505217 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(504856, 505217, 2, 'Boon of the Lion - periodic fear/charm/sleep dispel');
