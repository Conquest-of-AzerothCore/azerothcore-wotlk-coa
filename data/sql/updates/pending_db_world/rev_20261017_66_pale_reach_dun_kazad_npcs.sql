-- Dun Kazad as the user set it up in game, on top of this branch's Pale Reach: NPCs both versions have take the user's
-- position, facing, movement, weapons and pose; NPCs only the user placed are added; NPCs only this branch has stay.
-- The user's models, outfits (display presets) and weapons replace these for every Dun Kazad NPC the user dressed.
-- Three Dun Kazad townsfolk the user placed that this branch had no creature for: Ellerdin the fruit seller, Thorek
-- Grayember (walks a patrol) and Erinmumin Flinthelm.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(164411, 0, 0, 0, 0, 0, 'Ellerdin', 'Fruit Seller', NULL, 0, 30, 30, 0, 35, 1, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, '', NULL),
(164640, 0, 0, 0, 0, 0, 'Thorek Grayember', '', NULL, 0, 30, 30, 0, 35, 1, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, '', NULL),
(164952, 0, 0, 0, 0, 0, 'Erinmumin Flinthelm', '', NULL, 0, 30, 30, 0, 35, 1, 1, 1.14286, 1, 1, 20, 0, 0, 1, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, '', NULL) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`);
UPDATE `creature` SET `position_x` = -6443.07, `position_y` = -319.93, `position_z` = 576.763, `orientation` = 5.6, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962261 AND `id` = 164389; -- Ambassador Thargas Anvilmar
UPDATE `creature` SET `position_x` = -6333.09, `position_y` = -453.778, `position_z` = 649.621, `orientation` = 6.27196, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962250 AND `id` = 164453; -- Bilna Stonefist
UPDATE `creature` SET `position_x` = -6343.62, `position_y` = -459.242, `position_z` = 649.518, `orientation` = 6.24682, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962251 AND `id` = 164454; -- Bishop Beorn
UPDATE `creature` SET `position_x` = -6596.49, `position_y` = -277.933, `position_z` = 577.786, `orientation` = 2.0436, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962207 AND `id` = 164421; -- Bishop Degarn
UPDATE `creature` SET `position_x` = -6499, `position_y` = -317.352, `position_z` = 577.626, `orientation` = 1.22362, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963000 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6496.41, `position_y` = -309.104, `position_z` = 577.626, `orientation` = 4.44297, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963001 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6439.04, `position_y` = -312.898, `position_z` = 577.012, `orientation` = 4.70922, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963003 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6448.34, `position_y` = -314.612, `position_z` = 576.989, `orientation` = 5.02181, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963004 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6452.67, `position_y` = -347.767, `position_z` = 576.988, `orientation` = 0.8757, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963005 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6459.69, `position_y` = -335.152, `position_z` = 576.987, `orientation` = 0.156273, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963006 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6688, `position_y` = -46.9597, `position_z` = 562.139, `orientation` = 0.293723, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963007 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6690.01, `position_y` = -82.7765, `position_z` = 570.018, `orientation` = 1.78833, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963008 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6704.97, `position_y` = -73.8135, `position_z` = 568.989, `orientation` = 5.1624, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963009 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6736.39, `position_y` = -100.39, `position_z` = 570.015, `orientation` = 3.72434, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963010 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6634.66, `position_y` = -114.293, `position_z` = 570.544, `orientation` = 3.59944, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963011 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6725.16, `position_y` = -167.669, `position_z` = 569.761, `orientation` = 0.61023, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963012 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6687.66, `position_y` = -185.951, `position_z` = 570.764, `orientation` = 2.57764, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963013 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6680.16, `position_y` = -222.198, `position_z` = 580.327, `orientation` = 1.68307, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963014 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6618.57, `position_y` = -283.58, `position_z` = 577.679, `orientation` = 2.7944, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963015 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6611.76, `position_y` = -263.4, `position_z` = 577.706, `orientation` = 2.89335, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963016 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6590.47, `position_y` = -260.514, `position_z` = 577.81, `orientation` = 5.67132, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963017 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6526.76, `position_y` = -290.55, `position_z` = 577.86, `orientation` = 4.35499, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9963018 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6375.02, `position_y` = -453.346, `position_z` = 649.793, `orientation` = 6.19025, `MovementType` = 2, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9965020 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6466.75, `position_y` = -319.48, `position_z` = 577.639, `orientation` = 2.8936, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9965108 AND `id` = 164403; -- Dun Kazad Guard
UPDATE `creature` SET `position_x` = -6736.2, `position_y` = -69.9411, `position_z` = 567.307, `orientation` = 3.76104, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965002 AND `id` = 164990; -- Dun Kazad Mount
UPDATE `creature` SET `position_x` = -6737.91, `position_y` = -69.4614, `position_z` = 567.457, `orientation` = 3.7367, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965003 AND `id` = 164989; -- Dun Kazad Mount
UPDATE `creature` SET `position_x` = -6738.83, `position_y` = -67.8285, `position_z` = 567.492, `orientation` = 3.89299, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965004 AND `id` = 164989; -- Dun Kazad Mount
UPDATE `creature` SET `position_x` = -6727.56, `position_y` = -64.2934, `position_z` = 567.131, `orientation` = 0.24089, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965005 AND `id` = 164989; -- Dun Kazad Mount
UPDATE `creature` SET `position_x` = -6726.46, `position_y` = -67.974, `position_z` = 566.945, `orientation` = 0.198476, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965006 AND `id` = 164989; -- Dun Kazad Mount
UPDATE `creature` SET `position_x` = -6725.25, `position_y` = -70.6238, `position_z` = 566.738, `orientation` = 0.284083, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965007 AND `id` = 164989; -- Dun Kazad Mount
UPDATE `creature` SET `position_x` = -6724.51, `position_y` = -74.0919, `position_z` = 566.5, `orientation` = 0.272302, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965008 AND `id` = 164989; -- Dun Kazad Mount
UPDATE `creature` SET `position_x` = -6733.47, `position_y` = -73.7971, `position_z` = 567.126, `orientation` = 3.83251, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965009 AND `id` = 164989; -- Dun Kazad Mount
UPDATE `creature` SET `position_x` = -6422.36, `position_y` = -304.815, `position_z` = 575.783, `orientation` = 3.00648, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9963002 AND `id` = 164407; -- Dun Kazad Protector
UPDATE `creature` SET `position_x` = -6549.83, `position_y` = -407.588, `position_z` = 580.863, `orientation` = 0.965355, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965145 AND `id` = 164407; -- Dun Kazad Protector
UPDATE `creature` SET `position_x` = -6493.18, `position_y` = -256.285, `position_z` = 576.914, `orientation` = 5.8357, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9988005 AND `id` = 164414; -- Durakh
UPDATE `creature` SET `position_x` = -6368.28, `position_y` = -418.978, `position_z` = 651.845, `orientation` = 6.12274, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965019 AND `id` = 164085; -- Ealdfrost Fox
UPDATE `creature` SET `position_x` = -6307.08, `position_y` = -478.85, `position_z` = 642.935, `orientation` = 4.45213, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965031 AND `id` = 164085; -- Ealdfrost Fox
UPDATE `creature` SET `position_x` = -6738.66, `position_y` = -416.184, `position_z` = 590.852, `orientation` = 2.39992, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965013 AND `id` = 164424; -- Ealdfrost Goat
UPDATE `creature` SET `position_x` = -6547.04, `position_y` = -488.527, `position_z` = 643.057, `orientation` = 6.21699, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965016 AND `id` = 164424; -- Ealdfrost Goat
UPDATE `creature` SET `position_x` = -6471.97, `position_y` = -442.057, `position_z` = 655.804, `orientation` = 5.82429, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965017 AND `id` = 164424; -- Ealdfrost Goat
UPDATE `creature` SET `position_x` = -6629.6, `position_y` = -147.01, `position_z` = 570.573, `orientation` = 0.9, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962265 AND `id` = 164998; -- Ergrain Tattersail
UPDATE `creature` SET `position_x` = -6598.95, `position_y` = -185.906, `position_z` = 742.086, `orientation` = 4.54945, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962256 AND `id` = 164460; -- Flamekeeper Enril
UPDATE `creature` SET `position_x` = -6533.05, `position_y` = -163.562, `position_z` = 779.862, `orientation` = 3.80175, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965032 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6523.53, `position_y` = -188.663, `position_z` = 785.558, `orientation` = 4.78349, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965033 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6506.28, `position_y` = -219.35, `position_z` = 792.482, `orientation` = 1.83431, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965034 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6524.29, `position_y` = -258.574, `position_z` = 798.36, `orientation` = 4.26119, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965035 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6498.08, `position_y` = -243.492, `position_z` = 792.843, `orientation` = 0.551755, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965036 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6548.28, `position_y` = -246.925, `position_z` = 794.582, `orientation` = 3.14278, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965037 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6539.9, `position_y` = -213.472, `position_z` = 791.214, `orientation` = 3.95489, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965038 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6529.48, `position_y` = -225.669, `position_z` = 792.904, `orientation` = 5.06622, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965039 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6496.62, `position_y` = -198.541, `position_z` = 793.371, `orientation` = 5.27829, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965040 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6432.29, `position_y` = -187.704, `position_z` = 799.616, `orientation` = 3.82215, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965041 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6458.13, `position_y` = -209.852, `position_z` = 786.687, `orientation` = 3.83865, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965042 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6479.26, `position_y` = -141.587, `position_z` = 824.456, `orientation` = 0.0200462, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965044 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6472.97, `position_y` = -230.393, `position_z` = 786.327, `orientation` = 4.08997, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9988016 AND `id` = 164461; -- Frost Elemental
UPDATE `creature` SET `position_x` = -6791.51, `position_y` = -3.64225, `position_z` = 375.663, `orientation` = 4.71662, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965060 AND `id` = 164394; -- Frosty Crab
UPDATE `creature` SET `position_x` = -6439.07, `position_y` = -326.927, `position_z` = 576.763, `orientation` = 2.8439, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 1 WHERE `guid` = 9962206 AND `id` = 164392; -- General Baugwolf
UPDATE `creature` SET `position_x` = -6550.86, `position_y` = -339.627, `position_z` = 580.613, `orientation` = 0.662188, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965146 AND `id` = 164410; -- Ginnad
UPDATE `creature` SET `position_x` = -6476.73, `position_y` = -268.968, `position_z` = 576.801, `orientation` = 1.2935, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9963019 AND `id` = 164405; -- Gryphon Master Stonefeather
UPDATE `creature` SET `position_x` = -6470.96, `position_y` = -225.61, `position_z` = 577.223, `orientation` = 5.17258, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962213 AND `id` = 164404; -- Innkeeper Stonebraid
UPDATE `creature` SET `position_x` = -6538.52, `position_y` = -305.445, `position_z` = 577.856, `orientation` = 0.451002, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9965112 AND `id` = 164417; -- Kardu
UPDATE `creature` SET `position_x` = -6539.86, `position_y` = -327.679, `position_z` = 580.294, `orientation` = 1.19556, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962263 AND `id` = 164638; -- Morik Runaferro
UPDATE `creature` SET `position_x` = -6623.6, `position_y` = -145.008, `position_z` = 570.573, `orientation` = 2.4128, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962209 AND `id` = 164423; -- Norhi Morahondo
UPDATE `creature` SET `position_x` = -6595.6, `position_y` = -275.499, `position_z` = 577.791, `orientation` = 3.73634, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962208 AND `id` = 164422; -- Patriarch Arbilun
UPDATE `creature` SET `position_x` = -6342.58, `position_y` = -449.009, `position_z` = 649.661, `orientation` = 6.24286, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962252 AND `id` = 164455; -- Patriarch Khazemil
UPDATE `creature` SET `position_x` = -6477.05, `position_y` = -238.653, `position_z` = 577.115, `orientation` = 4.6254, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962258 AND `id` = 164976; -- Priestess Yoveatryd
UPDATE `creature` SET `position_x` = -6626.79, `position_y` = -135.399, `position_z` = 570.549, `orientation` = 3.4398, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962240 AND `id` = 165513; -- Smart Tank
UPDATE `creature` SET `position_x` = -6392.26, `position_y` = -450.953, `position_z` = 650.341, `orientation` = 5.82429, `MovementType` = 1, `wander_distance` = 5, `equipment_id` = 0 WHERE `guid` = 9965018 AND `id` = 7560; -- Snowshoe Rabbit
UPDATE `creature` SET `position_x` = -6425.14, `position_y` = -140.982, `position_z` = 842.247, `orientation` = 2.69, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962204 AND `id` = 164462; -- Spirit of Unity
UPDATE `creature` SET `position_x` = -6440.33, `position_y` = -332.424, `position_z` = 576.993, `orientation` = 2.94463, `MovementType` = 0, `wander_distance` = 0, `equipment_id` = 0 WHERE `guid` = 9962260 AND `id` = 164391; -- Thane Azaghal Stonesong
DELETE FROM `creature` WHERE `guid` IN (9963020, 9963021, 9965109, 9965010, 9965113, 9965115, 9965116);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9963020, 164403, 0, 0, 0, 1, 1, 1, -6727.01, -216.335, 568.541, 1.89497, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dun Kazad (placed in game)'),
(9963021, 164403, 0, 0, 0, 1, 1, 1, -6741.16, -210.659, 568.893, 4.6046, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dun Kazad (placed in game)'),
(9965109, 164403, 0, 0, 0, 1, 1, 1, -6469.31, -327.373, 577.639, 3.03968, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dun Kazad Guard (placed in game)'),
(9965010, 164407, 0, 0, 0, 1, 1, 0, -6383.22, -208.321, 579.444, 3.4704, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dun Kazad Protector (placed in game)'),
(9965113, 164411, 0, 0, 0, 1, 1, 0, -6533.36, -336.914, 580.523, 2.5527, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Ellerdin (placed in game)'),
(9965115, 164640, 0, 0, 0, 1, 1, 0, -6639.71, -251.236, 577.487, 6.1224, 300, 0, 0, 1, 0, 2, 0, 0, 0, '', NULL, 0, 'Thorek Grayember (placed in game)'),
(9965116, 164952, 0, 0, 0, 1, 1, 0, -6687.63, -183.039, 570.176, 0.1219, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Erinmumin Flinthelm (placed in game)');
DELETE FROM `creature_addon` WHERE `guid` IN (9962204, 9962206, 9962207, 9962209, 9962213, 9962240, 9962250, 9962251, 9962252, 9962256, 9962258, 9962261, 9962265, 9963000, 9963001, 9963003, 9963004, 9963005, 9963006, 9963007, 9963008, 9963009, 9963010, 9963011, 9963012, 9963013, 9963014, 9963015, 9963016, 9963017, 9963018, 9965020, 9965108, 9963002, 9965145, 9963019, 9965002, 9965003, 9965004, 9965005, 9965006, 9965007, 9965008, 9965009, 9965013, 9965016, 9965017, 9965018, 9965019, 9965031, 9965032, 9965033, 9965034, 9965035, 9965036, 9965037, 9965038, 9965039, 9965040, 9965041, 9965042, 9965044, 9988016, 9965060, 9962263, 9962208, 9962260, 9965112, 9988005, 9965146, 9963020, 9963021, 9965109, 9965010, 9965113, 9965115, 9965116);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9965020, 9921102, 0, 0, 1, 0, 0, ''),
(9962260, 0, 0, 6, 0, 0, 0, NULL),
(9965109, 0, 0, 0, 1, 0, 0, NULL),
(9965115, 9921105, 0, 0, 1, 0, 0, '');
DELETE FROM `waypoint_data` WHERE `id` IN (9921102, 9921105);
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`, `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(9921102, 1, -6375.02, -453.346, 649.793, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 2, -6389.76, -450.649, 650.229, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 3, -6407.99, -445.044, 650.858, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 4, -6440.94, -432.467, 652.34, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 5, -6458.53, -423.442, 653.591, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 6, -6480.79, -426.055, 655.647, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 7, -6499.08, -434.823, 656.63, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 8, -6477.62, -425.141, 655.289, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 9, -6461.33, -422.106, 653.785, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 10, -6431.71, -436.557, 651.696, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 11, -6375.03, -453.142, 649.8, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 12, -6209.12, -317.187, 582.541, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 13, -6209.81, -334.481, 583.465, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 14, -6210.44, -354.358, 591.249, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 15, -6209.22, -333.948, 582.933, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 16, -6209.11, -313.023, 582.797, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 17, -6227.35, -275.31, 588.617, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 18, -6233.9, -267.425, 590.612, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 19, -6243.15, -260.168, 589.213, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 20, -6253.53, -255.466, 588.081, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 21, -6266.33, -248.382, 583.325, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 22, -6255.48, -255.166, 587.608, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921102, 23, -6234.62, -266.583, 590.494, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921105, 1, -6637.96, -251.132, 577.39, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921105, 2, -6628.5, -249.938, 576.873, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921105, 3, -6621.92, -243.253, 576.463, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921105, 4, -6621.13, -235.049, 576.872, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921105, 5, -6628.9, -234.295, 577.969, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921105, 6, -6638.25, -234.848, 580.819, NULL, 0, 0, 0, 0, 0, 100, 0),
(9921105, 7, -6632.92, -249.832, 577.055, NULL, 0, 0, 0, 0, 0, 100, 0);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (164085, 164389, 164391, 164392, 164394, 164403, 164404, 164405, 164407, 164410, 164411, 164414, 164417, 164421, 164422, 164423, 164424, 164453, 164454, 164455, 164460, 164461, 164462, 164638, 164640, 164952, 164976, 164989, 164990, 164998, 165513, 7560);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(7560, 0, 328, 1, 1, 51831),
(164085, 0, 142808, 1, 1, 0),
(164389, 0, 53, 1, 1, 0),
(164391, 0, 53, 1, 1, 0),
(164392, 0, 53, 1, 1, 0),
(164394, 0, 142383, 1, 1, 0),
(164394, 1, 142377, 1, 1, 0),
(164403, 0, 53, 1, 1, 0),
(164404, 0, 53, 1, 1, 0),
(164405, 0, 53, 1, 1, 0),
(164407, 0, 2234, 1, 1, 0),
(164410, 0, 54, 1, 1, 0),
(164411, 0, 15476, 1, 1, 0),
(164414, 0, 1598, 1, 1, 0),
(164417, 0, 53, 1, 1, 0),
(164421, 0, 53, 1, 1, 0),
(164422, 0, 53, 1, 1, 0),
(164423, 0, 1563, 1, 1, 0),
(164424, 0, 40024, 1, 1, 0),
(164424, 1, 66292, 1, 1, 0),
(164424, 2, 40021, 1, 1, 0),
(164424, 3, 40077, 1, 1, 0),
(164453, 0, 54, 1, 1, 0),
(164454, 0, 53, 1, 1, 0),
(164455, 0, 53, 1, 1, 0),
(164460, 0, 53, 1, 1, 0),
(164461, 0, 142179, 1, 1, 0),
(164461, 1, 142180, 1, 1, 0),
(164461, 2, 142181, 1, 1, 0),
(164461, 3, 142185, 1, 1, 0),
(164462, 0, 141468, 1, 1, 0),
(164638, 0, 53, 1, 1, 0),
(164640, 0, 1598, 1, 1, 0),
(164952, 0, 1598, 1, 1, 0),
(164976, 0, 54, 1, 1, 0),
(164989, 0, 141978, 1, 1, 0),
(164989, 1, 141935, 1, 1, 0),
(164989, 2, 141936, 1, 1, 0),
(164989, 3, 141927, 1, 1, 0),
(164990, 0, 141928, 1, 1, 0),
(164990, 1, 141939, 1, 1, 0),
(164990, 2, 141982, 1, 1, 0),
(164990, 3, 141934, 1, 1, 0),
(164998, 0, 54, 1, 1, 0),
(165513, 0, 28650, 1, 1, 0);
DELETE FROM `creature_display_preset` WHERE `entry` IN (164389, 164391, 164392, 164403, 164404, 164405, 164410, 164411, 164417, 164421, 164422, 164423, 164453, 164454, 164455, 164460, 164638, 164976, 164998);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164389, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 0, 2540, 7306, 0, 1236, 6528, 2162, 0, 0, 0, 0),
(164391, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 20681, 24131, 0, 44583, 0, 0, 33791, 0, 0, 0, 0),
(164392, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 43411, 146357, 0, 5954, 0, 56869, 36039, 0, 47135, 0, 93959),
(164403, 53, 3, 0, 1, 0, 0, 0, 0, 0, 0, 12006, 146357, 0, 5954, 0, 56869, 36039, 0, 47135, 0, 93959),
(164404, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 0, 2540, 7306, 0, 1236, 6528, 2162, 0, 0, 0, 0),
(164405, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 0, 2540, 7306, 0, 1236, 6528, 2162, 0, 0, 0, 0),
(164410, 54, 3, 1, 1, 2, 3, 5, 4, 0, 0, 0, 0, 147258, 148641, 3408, 152272, 1246, 0, 156939, 0, 0),
(164411, 15476, 10, 0, 1, 0, 5, 1, 4, 0, 0, 0, 0, 143944, 0, 0, 143945, 142933, 0, 0, 0, 0),
(164417, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 0, 2540, 7306, 0, 1236, 6528, 2162, 0, 0, 0, 0),
(164421, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 20681, 21388, 0, 20678, 0, 0, 33791, 0, 0, 0, 0),
(164422, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 0, 2540, 7306, 0, 1236, 6528, 2162, 0, 0, 0, 0),
(164423, 1563, 7, 0, 1, 3, 1, 6, 5, 2, 0, 0, 0, 147154, 148601, 150215, 1973, 154357, 0, 156855, 0, 0),
(164453, 54, 3, 1, 1, 3, 6, 9, 2, 0, 0, 0, 0, 147258, 148641, 3408, 152272, 1246, 0, 156939, 0, 0),
(164454, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 12276, 12073, 0, 12071, 3306, 0, 4990, 0, 6248, 0, 0),
(164455, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 0, 2540, 7306, 0, 1236, 6528, 2162, 0, 0, 0, 0),
(164460, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 0, 2540, 7306, 0, 1236, 6528, 2162, 0, 0, 0, 0),
(164638, 53, 3, 0, 1, 6, 7, 10, 5, 3, 0, 0, 2540, 7306, 0, 1236, 6528, 2162, 0, 0, 0, 0),
(164976, 54, 3, 1, 1, 3, 6, 9, 2, 0, 0, 0, 0, 147258, 148641, 3408, 152272, 1246, 0, 156939, 0, 0),
(164998, 54, 3, 1, 1, 3, 6, 9, 2, 0, 0, 0, 0, 147258, 148641, 3408, 152272, 1246, 0, 156939, 0, 0);
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (164392, 164403);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164392, 1, 45996, 0, 0, 0),
(164403, 1, 1812, 2445, 0, 0);

-- Thorin, Dagna and Brynna (Snowveil Cemetery) and the four Dun Kazad Fishers wear the user's outfits too.
DELETE FROM `creature_display_preset` WHERE `entry` IN (164456, 164457, 164458, 165506, 165507, 165508, 165509);
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164456, 53, 3, 0, 1, 2, 3, 5, 3, 5, 0, 0, 2540, 7306, 0, 1236, 6528, 2162, 0, 0, 0, 0),
(164457, 54, 3, 1, 1, 1, 2, 4, 6, 0, 0, 0, 0, 147258, 148641, 3408, 152272, 1246, 0, 156939, 0, 0),
(164458, 54, 3, 1, 1, 5, 4, 7, 1, 0, 0, 0, 0, 147258, 148641, 3408, 152272, 1246, 0, 156939, 0, 0),
(165506, 53, 3, 0, 1, 1, 5, 7, 3, 1, 0, 0, 0, 9805, 13429, 0, 9399, 13424, 0, 0, 0, 0),
(165507, 53, 3, 0, 1, 2, 0, 0, 4, 2, 0, 0, 0, 9805, 13429, 0, 9399, 13424, 0, 0, 0, 0),
(165508, 53, 3, 0, 1, 3, 1, 1, 5, 3, 0, 0, 0, 9805, 13429, 0, 9399, 13424, 0, 0, 0, 0),
(165509, 53, 3, 0, 1, 4, 2, 2, 6, 4, 0, 0, 0, 9805, 13429, 0, 9399, 13424, 0, 0, 0, 0);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (164456, 164457, 164458, 165506, 165507, 165508, 165509);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164456, 0, 53, 1, 1, 0),
(164457, 0, 54, 1, 1, 0),
(164458, 0, 54, 1, 1, 0),
(165506, 0, 53, 1, 1, 0),
(165507, 0, 53, 1, 1, 0),
(165508, 0, 53, 1, 1, 0),
(165509, 0, 53, 1, 1, 0);
