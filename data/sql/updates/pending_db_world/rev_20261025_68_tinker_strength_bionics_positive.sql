-- COA-4688: Strength Bionics (510176) is the Tinker's party buff paired with Arcane Bionics (541493, fixed in
-- rev_20260930_92). Its damage-taken effect (aura 14) makes the positivity heuristic classify the whole aura as
-- negative, so the client lists it among the debuffs. Mark every effect positive, as for Arcane Bionics.
DELETE FROM `spell_custom_attr` WHERE `spell_id` = 510176;
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES (510176, 234881024);
