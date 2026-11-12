-- Morgwena's Hushed Ones (175119): a freed Hushed Ealdir kept its Frenzy and stood where it was for a minute. On the
-- realm it runs off at once (fppvzzEmIX8 20:53-20:57: the green-ringed Ealdir leaves the fight within four seconds).
-- It now drops Frenzy, turns passive and runs for Baile Escada along the server's own path over the hill, without
-- being forced on in a straight line where that path ends, and despawns on arrival or after 25 s.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164356 AND `source_type` = 0 AND `id` BETWEEN 2 AND 12;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164356, 0, 2, 3, 2, 0, 100, 0, 0, 15, 0, 0, 0, 0, 33, 164356, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hushed Ealdir - At 15% health - Credit freed to loot recipient and group'),
(164356, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 365384, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hushed Ealdir - Linked - Remove Morgwenas Curse'),
(164356, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 28, 365143, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hushed Ealdir - Linked - Remove Frenzy'),
(164356, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 2, 35, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hushed Ealdir - Linked - Mask shatters, turn friendly'),
(164356, 0, 6, 7, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 27, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hushed Ealdir - Linked - Stop combat'),
(164356, 0, 7, 8, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hushed Ealdir - Linked - Set passive'),
(164356, 0, 8, 9, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 100, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hushed Ealdir - Linked - Restore health'),
(164356, 0, 9, 10, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 59, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hushed Ealdir - Linked - Run'),
(164356, 0, 10, 11, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 69, 1, 0, 0, 0, 0, 1, 8, 0, 0, 0, 0, -7800, 972, 180.53, 0, 'Hushed Ealdir - Linked - Flee down the hill to Baile Escada'),
(164356, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 25000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hushed Ealdir - Linked - Despawn after 25 s'),
(164356, 0, 12, 0, 34, 0, 100, 0, 8, 1, 0, 0, 0, 0, 41, 500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Hushed Ealdir - On reaching Baile Escada - Despawn');

-- Dark Moss (2310433) is 8KUL_HangingMoss_A01, which hangs 30 yd below its origin: at the realm size 0.8 and 4 yd over
-- the den floor it stood as a mound taller than a player. The realm shows strands coming down from the cave roof
-- (fppvzzEmIX8 19:36-19:56). An object can only be collected within 5 yd of its origin, so each moss is two objects,
-- as the realm does for its worldforged pickups: a plain strand at 0.25 hung from the roof of Bzb_Mushroomden, and the
-- collectable Dark Moss as an invisible cube under a yard wide on the strand's lower end, never over 4.3 yd up.
-- Collecting the cube takes the strand away with it, and both return after a minute.
UPDATE `gameobject_template` SET `displayId` = 980926, `size` = 3, `AIName` = 'SmartGameObjectAI' WHERE `entry` = 2310433;
UPDATE `gameobject` SET `position_z` = 267.84, `spawntimesecs` = 60 WHERE `guid` = 9980027 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 267.73, `spawntimesecs` = 60 WHERE `guid` = 9980028 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 267.11, `spawntimesecs` = 60 WHERE `guid` = 9980029 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 265.81, `spawntimesecs` = 60 WHERE `guid` = 9980030 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 266.68, `spawntimesecs` = 60 WHERE `guid` = 9980031 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 265.85, `spawntimesecs` = 60 WHERE `guid` = 9980032 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 263.99, `spawntimesecs` = 60 WHERE `guid` = 9980033 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 264.21, `spawntimesecs` = 60 WHERE `guid` = 9980034 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 266.62, `spawntimesecs` = 60 WHERE `guid` = 9980035 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 264.01, `spawntimesecs` = 60 WHERE `guid` = 9980036 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 265.75, `spawntimesecs` = 60 WHERE `guid` = 9980037 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 265.89, `spawntimesecs` = 60 WHERE `guid` = 9980038 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 264.64, `spawntimesecs` = 60 WHERE `guid` = 9980039 AND `id` = 2310433;
UPDATE `gameobject` SET `position_z` = 266.36, `spawntimesecs` = 60 WHERE `guid` = 9980040 AND `id` = 2310433;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data8`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(2399011, 5, 300556, 'Hanging Moss', '', '', '', 0.25, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`);
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9993016 AND 9993029;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9993016, 2399011, 0, 0, 0, 1, 1, -7683, 962.5, 275.76, 2.235, 0, 0, 0.899008, 0.437931, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980027'),
(9993017, 2399011, 0, 0, 0, 1, 1, -7685, 960.8, 274.21, 2.058, 0, 0, 0.856784, 0.515676, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980028'),
(9993018, 2399011, 0, 0, 0, 1, 1, -7685.5, 979.5, 273.82, 3.844, 0, 0, 0.938959, -0.344028, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980029'),
(9993019, 2399011, 0, 0, 0, 1, 1, -7689, 961, 272.29, 1.798, 0, 0, 0.782705, 0.622393, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980030'),
(9993020, 2399011, 0, 0, 0, 1, 1, -7692, 966.5, 275.67, 1.571, 0, 0, 0.707179, 0.707035, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980031'),
(9993021, 2399011, 0, 0, 0, 1, 1, -7696, 976.5, 272.33, 5.725, 0, 0, 0.275484, -0.961306, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980032'),
(9993022, 2399011, 0, 0, 0, 1, 1, -7697, 981, 270.47, 5.333, 0, 0, 0.457421, -0.889250, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980033'),
(9993023, 2399011, 0, 0, 0, 1, 1, -7703, 979, 270.69, 1.713, 0, 0, 0.755554, 0.655086, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980034'),
(9993024, 2399011, 0, 0, 0, 1, 1, -7705, 995, 273.10, 4.823, 0, 0, 0.666939, -0.745113, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980035'),
(9993025, 2399011, 0, 0, 0, 1, 1, -7700.5, 983, 270.49, 2.433, 0, 0, 0.937891, 0.346930, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980036'),
(9993026, 2399011, 0, 0, 0, 1, 1, -7708.5, 981.5, 272.23, 0.785, 0, 0, 0.382499, 0.923956, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980037'),
(9993027, 2399011, 0, 0, 0, 1, 1, -7688, 970.5, 277.21, 2.423, 0, 0, 0.936144, 0.351616, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980038'),
(9993028, 2399011, 0, 0, 0, 1, 1, -7703.5, 983.5, 271.12, 1.768, 0, 0, 0.773281, 0.634063, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980039'),
(9993029, 2399011, 0, 0, 0, 1, 1, -7681, 969, 272.84, 2.715, 0, 0, 0.977338, 0.211683, 60, 100, 1, 'Pale Reach: hanging moss over Dark Moss 9980040');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2310433 AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2310433, 1, 0, 0, 70, 0, 100, 0, 3, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 20, 2399011, 14, 0, 0, 0, 0, 0, 0, 'Dark Moss - On collected - Take the hanging moss away for 60 s');

-- Great Stag Blessing (175120): on the realm the Bone Amulet at the totem is laid down over a 2 s "Picking up" bar, a
-- green orb then burns over the stag effigy and a green beam joins the amulet to it for some seconds (fppvzzEmIX8
-- 22:12-22:20). The amulet takes the quick-open lock the realm's collectables use; two hidden helpers draw the scene:
-- one at the amulet channels the realm's Blessing Neck 365375 at one in front of the effigy's skull. That spell aims at
-- a gameobject in Spell.dbc, which no script here can cast, so the server's copy aims at a unit; the client still
-- draws its own channel visual.
UPDATE `gameobject_template` SET `castBarCaption` = 'Picking up', `Data0` = 57, `Data10` = 0 WHERE `entry` = 2300693;
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`,
`unit_class`, `unit_flags`, `type`, `flags_extra`, `AIName`, `MovementType`) VALUES
(165635, '[TG] great_stag_blessing_beam', 1, 1, 35, 0, 1, 1, 1, 33554432, 10, 130, 'SmartAI', 0),
(165636, '[TG] great_stag_blessing_orb', 1, 1, 35, 0, 1, 1, 1, 33554432, 10, 130, '', 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`),
`type` = VALUES(`type`), `flags_extra` = VALUES(`flags_extra`), `AIName` = VALUES(`AIName`);
DELETE FROM `spell_dbc` WHERE `ID` = 365375;
INSERT INTO `spell_dbc` (`ID`, `AttributesEx`, `AttributesEx2`, `CastingTimeIndex`, `InterruptFlags`, `ProcChance`, `DurationIndex`, `RangeIndex`,
`EquippedItemClass`, `Effect_1`, `EffectBasePoints_1`, `ImplicitTargetA_1`, `EffectAura_1`, `SpellVisualID_1`, `SpellIconID`, `Name_Lang_enUS`,
`Name_Lang_Mask`, `NameSubtext_Lang_Mask`, `Description_Lang_Mask`, `AuraDescription_Lang_Mask`, `EffectChainAmplitude_1`,
`EffectChainAmplitude_2`, `EffectChainAmplitude_3`, `SchoolMask`) VALUES
(365375, 4, 4, 1, 47, 101, 1, 7, -1, 6, 1, 25, 4, 278469, 26913, 'Blessing Neck', 16712190, 16712190, 16712190, 16712190, 1, 1, 1, 1);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (165635, 165636);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(165635, 0, 11686, 0.1, 1, 0),
(165636, 0, 11686, 1, 1, 0);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (165635, 165636);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`) VALUES
(165635, 1, 0, 1, 1, 0, 0, 0),
(165636, 1, 0, 1, 1, 0, 0, 0);
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2300693 AND `source_type` = 1 AND `id` IN (2, 3);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (165635, 165636) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300693, 1, 2, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 165636, 3, 8000, 0, 0, 0, 1, 0, 0, 0, 0, 1.0, -1.0, 4.2, 0, 'Bone Amulet - On use - Summon the orb at the effigy''s skull for 8 s'),
(2300693, 1, 3, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 12, 165635, 3, 8000, 0, 0, 0, 1, 0, 0, 0, 0, -0.6, 0.6, -1.3, 0, 'Bone Amulet - On use - Summon the beam source at the amulet for 8 s'),
(165635, 0, 0, 0, 1, 0, 100, 1, 700, 700, 0, 0, 0, 0, 11, 365375, 0, 0, 0, 0, 0, 19, 165636, 20, 0, 0, 0, 0, 0, 0, '[TG] great_stag_blessing_beam - After 0.7 s - Channel Blessing Neck at the orb');

-- Morgwena's Curse (365384) on the Hushed Ealdir has no icon in Spell.dbc (SpellIconID 1, drawn as a gear). The spell
-- patch stream sends the client this copy of the row with the Drust mask icon instead.
DELETE FROM `spell_dbc` WHERE `ID` = 365384;
INSERT INTO `spell_dbc` (`ID`, `DispelType`, `AttributesEx6`, `CastingTimeIndex`, `AuraInterruptFlags`, `ProcChance`, `DurationIndex`, `RangeIndex`,
`EquippedItemClass`, `Effect_1`, `EffectDieSides_1`, `EffectBasePoints_1`, `ImplicitTargetA_1`, `EffectAura_1`, `EffectAuraPeriod_1`,
`SpellVisualID_1`, `SpellIconID`, `Name_Lang_enUS`, `Name_Lang_Mask`, `NameSubtext_Lang_Mask`, `Description_Lang_enUS`, `Description_Lang_Mask`,
`AuraDescription_Lang_enUS`, `AuraDescription_Lang_Mask`, `EffectChainAmplitude_1`, `EffectChainAmplitude_2`, `EffectChainAmplitude_3`, `SchoolMask`) VALUES
(365384, 1, 41943040, 1, 4718592, 101, 21, 1, -1, 6, 1, -1, 1, 226, 1000, 364280, 26385, 'Morgwena''s Curse', 16712190, 16712190,
'Bound to Morgwena''s Will', 16712190, 'Bound to Morgwena''s Will', 16712190, 1, 1, 1, 1);
DELETE FROM `coa_client_spell_description` WHERE `ID` = 365384;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(365384, 'Bound to Morgwena''s Will', 'Bound to Morgwena''s Will');
