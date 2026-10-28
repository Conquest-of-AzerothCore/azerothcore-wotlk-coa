-- Shadewell Murloc Oracle (161717, Shadewell Spring in Northshire): the Oracle had no AI and no mana, so it only
-- meleed. It now fights with the kit of the stock Murloc Minor Oracle (456): Lightning Bolt at its victim and
-- Healing Wave on a hurt ally.
--
-- WHERE EACH VALUE COMES FROM
--   kit  approved by the user for #6324: no source lists the Oracle's own spells (AscensionDB, CoA Tavern,
--     client DBC, addons, the db.exil.es dump and Project Descension were searched), so it borrows the caster kit
--     of 456 Murloc Minor Oracle (data/sql/base/db_world/smart_scripts.sql:4553-4554, creature_template_spell.sql
--     :135-136).
--   unit_class 2, AIName 'SmartAI'  as 456 (data/sql/base/db_world/creature_template.sql:398): the Paladin class
--     gives the Oracle a mana pool, and SmartAI runs the rows below.
--   creature_template_spell  456's rows: index 0 Lightning Bolt 9532, index 1 Healing Wave 332.
--   Lightning Bolt row  456's row 0 unchanged: in combat, first cast at once, then every 3.6-5.1 s, cast flag 64
--     (keep casting instead of chasing), target 2 (the victim). Spell 9532 scales its damage and mana cost to the
--     caster's level (SPELL_ATTR0_SCALES_WITH_CREATURE_LEVEL in Spell.dbc), so the level 20 spell suits a low level
--     Oracle.
--   Healing Wave row  456 heals a friend missing 130 health (event 14), but a level 3-4 Oracle (about 70 health)
--     never misses that much, so the trigger is the health percentage form (event 74) the stock murloc healers use:
--     an ally at or below 40% health within 40 yards, as Murloc Tidecaller 545 and Murloc Minor Tidecaller 548
--     (smart_scripts.sql:4670, 4674). Repeat 30.9-39 s, radius 40, cast flag 1 (interrupt the bolt) and target 7
--     (the hurt ally) are 456's values.
--   Not copied: 456's flee at 15% health (row 2), which is not part of the approved caster kit.
UPDATE `creature_template` SET `unit_class` = 2, `AIName` = 'SmartAI' WHERE `entry` = 161717;

DELETE FROM `creature_template_spell` WHERE `CreatureID` = 161717;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`) VALUES
(161717, 0, 9532, 12340),
(161717, 1, 332, 12340);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 161717 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(161717, 0, 0, 0, 0, 0, 100, 0, 0, 0, 3600, 5100, 0, 0, 11, 9532, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadewell Murloc Oracle - In Combat CMC - Cast \'Lightning Bolt\''),
(161717, 0, 1, 0, 74, 0, 100, 0, 0, 0, 30900, 39000, 40, 40, 11, 332, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadewell Murloc Oracle - On Friendly Between 0-40% Health - Cast \'Healing Wave\'');
