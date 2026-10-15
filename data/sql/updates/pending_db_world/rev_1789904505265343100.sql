--
-- Boulder Dash (#1881): helpers grant immunity and prevent attacks; cleanup follows the parent aura.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 500692 AND `spell_effect` IN (680473, 681302, 500693);
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(500692, 680473, 2, 'Boulder Dash - crowd-control immunity'),
(500692, 681302, 2, 'Boulder Dash - remaining immunity and pacify'),
(500692, 500693, 2, 'Boulder Dash - cast lock and immediate cleanup');
