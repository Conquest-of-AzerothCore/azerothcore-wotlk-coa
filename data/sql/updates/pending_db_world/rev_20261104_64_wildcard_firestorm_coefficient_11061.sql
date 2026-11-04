-- Wildcard Firestorm 280575 and ranks 280635-280638: each rank's tooltip prices its tornado hit
-- (280578, 280671-280674) at base + per-level + $spfi*.4. The tornado casts those hits for the caster
-- (AscensionSummonedEffects Tick rows), so the 0.4 fire spell power term is the direct coefficient.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (280578, 280671, 280672, 280673, 280674);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(280578, 0.4, 0, 0, 0, 'Wildcard Firestorm Rank 1'),
(280671, 0.4, 0, 0, 0, 'Wildcard Firestorm Rank 2'),
(280672, 0.4, 0, 0, 0, 'Wildcard Firestorm Rank 3'),
(280673, 0.4, 0, 0, 0, 'Wildcard Firestorm Rank 4'),
(280674, 0.4, 0, 0, 0, 'Wildcard Firestorm Rank 5');
