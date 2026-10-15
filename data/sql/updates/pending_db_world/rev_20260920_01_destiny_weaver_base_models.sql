-- Destiny Weaver: the model each one is drawn with, pointed at the client's own player display.
--
-- The Weavers are mirror units. What they look like arrives in the 68-byte SMSG_MIRRORIMAGE_DATA
-- body, which is answered from `creature_display_preset` (rev_20260919_04 / rev_20260920_00).
-- The unit itself is still created from its `creature_template_model` row first, and the client
-- has to be able to build that model before the appearance packet has anything to apply to.
--
-- Every Weaver was created on one of the invented display ids 449292-449299, which exist in no
-- client. This realm ships them two ways - the mod-destiny-weaver module streams five of the
-- eight (0x0975/0x0976) at login, and a local patch archive carries all eight - so on any other
-- client, including a fresh build of this one, those units have no model at all: a nameplate
-- with nothing under it. 449294, 449295 and 449298 are not even streamed (six of the sixteen
-- Weavers stand on them).
--
-- The captured traffic settles what the model should be. In the 2026-09-01 capture the server
-- answered SMSG_MIRRORIMAGE_DATA for entry 449347 with display 49, and across all 216 captured
-- rows the display is the plain character display for the unit's race and gender - the
-- CreatureDisplayInfo row whose CreatureModelData points at Character\<Race>\<Gender>\ and whose
-- ExtendedDisplayInfoID is 0. Those ids are stock 3.3.5 in every client, so the unit always has
-- a model, and the appearance packet then dresses it.
--
-- One row per race; both Weavers of a race share it.

UPDATE `creature_template_model` SET `CreatureDisplayID` = 51 WHERE `CreatureID` IN (449346, 449356);     -- orc, male
UPDATE `creature_template_model` SET `CreatureDisplayID` = 1478 WHERE `CreatureID` IN (449340, 449350);   -- troll, male
UPDATE `creature_template_model` SET `CreatureDisplayID` = 53 WHERE `CreatureID` IN (449342, 449352);     -- dwarf, male
UPDATE `creature_template_model` SET `CreatureDisplayID` = 56 WHERE `CreatureID` IN (449345, 449355);     -- night elf, female
UPDATE `creature_template_model` SET `CreatureDisplayID` = 57 WHERE `CreatureID` IN (449343, 449353);     -- undead, male
UPDATE `creature_template_model` SET `CreatureDisplayID` = 49 WHERE `CreatureID` IN (449347, 449357);     -- human, male
UPDATE `creature_template_model` SET `CreatureDisplayID` = 15475 WHERE `CreatureID` IN (449341, 449351);  -- blood elf, female
UPDATE `creature_template_model` SET `CreatureDisplayID` = 16125 WHERE `CreatureID` IN (449344, 449354);  -- draenei, male
