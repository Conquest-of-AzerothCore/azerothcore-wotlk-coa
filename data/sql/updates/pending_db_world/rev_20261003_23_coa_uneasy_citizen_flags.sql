-- CoA: 1660018 'Those Who Fell' - the Unremarkable Stone reported 'Invalid Target'.
--
-- Uneasy Citizen (161791) carried unit_flags 768 = UNIT_FLAG_IMMUNE_TO_PC (0x100) |
-- UNIT_FLAG_IMMUNE_TO_NPC (0x200). The quest is completed by casting 256708
-- 'Distilling Spiritual Unrest' (the Unremarkable Stone, item 559158) at a Citizen; the
-- SmartAI row on 161791 hands out item 559155 'Spiritual Unrest' on that spellhit:
--   (161791, 0, 0, 1, 8, 0, 100, 0, 256708, 0, 0, 0, 0, 0, 56, 9, 1, 0, 0, 0, 0, 7, 0, ...)
-- The conditions row already scopes the spell to 161791 only.
--
-- Spell target validation rejects a player-cast spell on a unit carrying IMMUNE_TO_PC
-- (Unit::_IsValidAssistTarget), so the stone could never land - the reported 'Invalid Target'
-- on every Citizen, with no way to finish the quest.
--
-- Fix: keep UNIT_FLAG_IMMUNE_TO_NPC (512) so the civilian stays out of NPC combat, drop only
-- the player immunity. The cast is then a valid assist target and the SmartAI credit fires.
--
-- Idempotent: plain UPDATE to a fixed value.

UPDATE `creature_template` SET `unit_flags` = 512 WHERE `entry` = 161791;
