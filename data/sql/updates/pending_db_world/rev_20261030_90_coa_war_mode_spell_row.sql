-- 1004119 is the War Mode aura. The apex "Frenzy" row added for the Stormfang reused that id and replaced
-- War Mode's SpellInfo, so selecting War Mode failed. No script or creature uses the Frenzy row.
DELETE FROM `spell_dbc` WHERE `ID` = 1004119;
