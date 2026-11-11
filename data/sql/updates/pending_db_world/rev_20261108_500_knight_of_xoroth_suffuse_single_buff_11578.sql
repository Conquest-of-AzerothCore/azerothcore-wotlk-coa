-- #11578 Suffuse applied two buffs
--
-- 801063 is only the cast that triggers the heal-over-time 801064; the aura script that made 801063 carry
-- Speed Demon's movement speed is gone, so its registration goes with it.
DELETE FROM `spell_script_names` WHERE `spell_id` = 801063 AND `ScriptName` = 'aura_ascension_xoroth_lifecycle';
