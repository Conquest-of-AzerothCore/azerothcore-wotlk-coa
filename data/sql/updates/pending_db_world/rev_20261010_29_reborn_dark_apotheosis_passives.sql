-- Warcraft Reborn Dark Apotheosis 1154321 reads "increasing your health by 15%, ... significantly increasing your threat
-- ... damage dealt by you and your pets is reduced by 32%". Those come from its passives 1154322 (threat +260%, damage
-- -32%) and 1154323 (health +15%, Soul Gorge and Unending Resolve modifiers), which nothing applied: only the cloth
-- armor bonus in the form itself worked. The script applies both while transformed.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_reborn_dark_apotheosis';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1154321, 'aura_ascension_reborn_dark_apotheosis');
