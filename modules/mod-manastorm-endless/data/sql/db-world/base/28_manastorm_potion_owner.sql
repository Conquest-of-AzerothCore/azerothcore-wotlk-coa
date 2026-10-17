-- Execute against the world database after deploying the matching module SRC.
-- Spell 254440 has one owner: the SQL-driven Manastorm shared backend.
-- The donor Potion script is not registered by the transport-only donor loader.
-- Keep unrelated spell bindings intact; this migration is repeatable.
-- SRC suppresses Effect 183 at launch so 762608 cannot start a second reserve.
-- The existing backend starts with 3 charges and restores one every 10000 ms.
-- It applies 254462 once after consuming a charge and preserves charges across floors.
-- 992090 is a reference charge-system spell, not another item spell to bind.

DELETE FROM `spell_script_names` WHERE `spell_id` = 254440 AND `ScriptName` = 'spell_ascension_manastorm_potion';
DELETE FROM `spell_script_names` WHERE `spell_id` = 254440 AND `ScriptName` = 'spell_manastorm_baseline_tool';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES (254440, 'spell_manastorm_baseline_tool');
