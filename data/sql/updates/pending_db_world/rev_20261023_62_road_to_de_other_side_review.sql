-- Road to De Other Side (map 937): fixes from the review of #8671. rev_20261023_60 and _61 were renamed so a fresh
-- database creates the dungeon before #8715 changes it.

-- The last 38 spawns (Hissers, Vol'zeen, part of the trash, the Hirsutta trolls and the Bodies of Offering) were Normal only,
-- so the Chimeric Embryo never appeared on Heroic and Mythic.
UPDATE `creature` SET `spawnMask` = 7 WHERE `map` = 937 AND `guid` BETWEEN 9370500 AND 9370537;

-- Two Interstitial Wanderers carried the Pale Reach paths of the old guids 9999222/9999223.
UPDATE `creature_addon` SET `path_id` = 0 WHERE `guid` IN (9370302, 9370303) AND `path_id` IN (9921108, 9921109);

-- Heroic and Mythic cast the SpellDifficulty.dbc variants, which need the same scripts.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (256496, 257026, 257027, 257048, 257049, 257069, 257070, 257072, 257073, 257078, 257079,
    257081, 257082, 257117, 257118, 257123, 257124, 257132, 257133, 257162, 257163, 257204, 257205);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(256496, 'spell_coa_drakmath_necrotic_emerge'),
(257048, 'spell_coa_drakmath_death_beam'),
(257049, 'spell_coa_drakmath_death_beam'),
(257072, 'spell_coa_volzeen_colossal_smash'),
(257073, 'spell_coa_volzeen_colossal_smash'),
(257078, 'spell_coa_embryo_runover'),
(257079, 'spell_coa_embryo_runover'),
(257081, 'spell_coa_embryo_runover'),
(257082, 'spell_coa_embryo_runover'),
(257162, 'spell_coa_embryo_spike_hit'),
(257163, 'spell_coa_embryo_spike_hit'),
(257117, 'spell_coa_other_side_trash_damage'),
(257118, 'spell_coa_other_side_trash_damage'),
(257123, 'spell_coa_other_side_trash_damage'),
(257124, 'spell_coa_other_side_trash_damage'),
(257132, 'spell_coa_other_side_trash_damage'),
(257133, 'spell_coa_other_side_trash_damage'),
(257026, 'spell_coa_other_side_trash_damage'),
(257027, 'spell_coa_other_side_trash_damage'),
(257069, 'spell_coa_other_side_trash_damage'),
(257070, 'spell_coa_other_side_trash_damage'),
(257204, 'spell_coa_other_side_trash_damage'),
(257205, 'spell_coa_other_side_trash_damage');

-- The trash spell cap exemption is keyed by the spell id that is cast, so the Heroic and Mythic variants need their own rows.
DELETE FROM `coa_dungeon_spell_damage` WHERE `spell_id` IN (257026, 257027, 257069, 257070, 257117, 257118, 257123, 257124, 257132, 257133, 257204, 257205);
INSERT INTO `coa_dungeon_spell_damage` (`spell_id`, `multiplier`, `comment`) VALUES
(257117, 1, 'Road to De Other Side: Decaying Hemorrhage (Heroic), values from the logs, no trash cap'),
(257118, 1, 'Road to De Other Side: Decaying Hemorrhage (Mythic), values from the logs, no trash cap'),
(257123, 1, 'Road to De Other Side: Bite (Heroic), values from the logs, no trash cap'),
(257124, 1, 'Road to De Other Side: Bite (Mythic), values from the logs, no trash cap'),
(257132, 1, 'Road to De Other Side: Sting (Heroic), values from the logs, no trash cap'),
(257133, 1, 'Road to De Other Side: Sting (Mythic), values from the logs, no trash cap'),
(257026, 1, 'Road to De Other Side: Rend Flesh (Heroic), values from the logs, no trash cap'),
(257027, 1, 'Road to De Other Side: Rend Flesh (Mythic), values from the logs, no trash cap'),
(257069, 1, 'Road to De Other Side: Shield Bash (Heroic), values from the logs, no trash cap'),
(257070, 1, 'Road to De Other Side: Shield Bash (Mythic), values from the logs, no trash cap'),
(257204, 1, 'Road to De Other Side: Toxic Expulsion (Heroic), values from the logs, no trash cap'),
(257205, 1, 'Road to De Other Side: Toxic Expulsion (Mythic), values from the logs, no trash cap');

-- Back into the Dungeon Finder (rev_20260922_01 and rev_20260924_01 had taken it out).
DELETE FROM `disables` WHERE `sourceType` = 8 AND `entry` = 937;

-- The bosses scale with the player on Normal; DestinyWeaver leaves boss mobs (type_flags 4) at their authored level.
UPDATE `creature_template` SET `type_flags` = `type_flags` & ~4 WHERE `entry` IN (162711, 162715, 162716);
