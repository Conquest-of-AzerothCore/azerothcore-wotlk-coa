-- Manastorm utility tomes: execute against the world database.
-- Requires the seven existing item_template rows from the Ascension item dump.
-- Existing learning tomes confirm 55884 on use + learned spell in slot 2 (trigger 6).
-- Target spells and minimum learning levels are from the supplied Spell.dbc.
-- These are base utilities: no previous rank, skill, race or class prerequisite.
-- Call of the Elements only summons configured, known totems; it does not grant totems.
-- Moonglade uses the existing spell_target_position entry for spell 18960.
-- This migration is repeatable and changes only the seven listed item templates.
--
-- 1500126: Eye of Kilrogg -> 126 (minimum level 22).
-- 1500128: Mind Soothe -> 453 (minimum level 20).
-- 1500134: Levitate -> 1706 (minimum level 18).
-- 1500135: Safe Fall -> 1860 (minimum level 30).
-- 1500136: Mind Vision -> 2096 (minimum level 22).
-- 1500141: Teleport: Moonglade -> 18960 (minimum level 10).
-- 1500153: Call of the Elements -> 66842 (minimum level 14).

UPDATE `item_template` SET `spellid_1` = 55884,
    `spelltrigger_1` = 0,
    `spellcharges_1` = -1,
    `spellppmRate_1` = 0,
    `spellcooldown_1` = 0,
    `spellcategory_1` = 303,
    `spellcategorycooldown_1` = 0,
    `spellid_2` = CASE `entry`
        WHEN 1500126 THEN 126
        WHEN 1500128 THEN 453
        WHEN 1500134 THEN 1706
        WHEN 1500135 THEN 1860
        WHEN 1500136 THEN 2096
        WHEN 1500141 THEN 18960
        WHEN 1500153 THEN 66842
        END,
    `spelltrigger_2` = 6,
    `spellcharges_2` = -1,
    `spellppmRate_2` = 0,
    `spellcooldown_2` = 0,
    `spellcategory_2` = 0,
    `spellcategorycooldown_2` = 0,
    `RequiredLevel` = CASE `entry`
        WHEN 1500126 THEN 22
        WHEN 1500128 THEN 20
        WHEN 1500134 THEN 18
        WHEN 1500135 THEN 30
        WHEN 1500136 THEN 22
        WHEN 1500141 THEN 10
        WHEN 1500153 THEN 14
        END,
    `requiredspell` = 0,
    `RequiredSkill` = 0,
    `RequiredSkillRank` = 0,
    `AllowableClass` = -1,
    `AllowableRace` = -1
WHERE `entry` IN (1500126, 1500128, 1500134, 1500135, 1500136, 1500141, 1500153);
