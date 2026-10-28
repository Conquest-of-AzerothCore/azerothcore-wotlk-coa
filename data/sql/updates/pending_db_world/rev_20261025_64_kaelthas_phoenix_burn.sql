-- COA-6781: Kael'thas's Phoenix lost 7% health per second and died in about 15 s. CoA's Burn 36720 already deals
-- 2% of its health every second (effect 1), and spell_kaelthas_burn added another 5% on every effect 0 tick, which
-- CoA ticks every second instead of every 2 s. Drop the script so only the CoA burn remains (about 50 s).
DELETE FROM `spell_script_names` WHERE `spell_id` = 36720 AND `ScriptName` = 'spell_kaelthas_burn';
