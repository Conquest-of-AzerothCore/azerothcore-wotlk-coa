-- Arcane Bionics (541493) is a Tinker buff on a party member: effect 0 reduces spell damage taken by 4% and
-- effect 1 reduces healing taken by 4%. The negative sign on effect 1 makes the positivity heuristic classify
-- the whole aura as a debuff, so the client lists it among harmful auras (issue #5773).
-- Mark every effect positive so it is displayed as a buff.
DELETE FROM `spell_custom_attr` WHERE `spell_id` = 541493;
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES
(541493, 234881024);
