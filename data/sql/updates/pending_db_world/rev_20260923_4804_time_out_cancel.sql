DELETE FROM `spell_linked_spell`
WHERE `spell_trigger` IN (-802229, -803896, -803897) AND `spell_effect` = -802228 AND `type` = 0;

INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(-802229, -802228, 0, 'Time Out! rank 1 - remove stasis when the parent aura is removed'),
(-803896, -802228, 0, 'Time Out! rank 2 - remove stasis when the parent aura is removed'),
(-803897, -802228, 0, 'Time Out! rank 3 - remove stasis when the parent aura is removed');
