-- Portable Call Boards (#4186, #7504, #9088, #9419): the item spells 995213/995214/995215
-- (Hero's/Warchief's/Outlaw's Portable Call Board, items 1913515/1913516/1913517) use
-- SPELL_EFFECT_TRANS_DOOR to summon gameobject 412000/412001/422000. None of those three entries
-- had a gameobject_template row, so Spell::EffectTransmitted logged "not exist and not created"
-- and returned without spawning anything, even though the client's placement cursor appeared.
-- `native_ascension_callboard` (modules/mod-hero-call-board) already treats these three entries as
-- call boards and needs no further script change. Values mirror the permanent boards' own
-- Data1/Data3/Data8 and the realm's recorded displayId/size for the portable versions.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data1`, `Data2`, `Data3`, `Data8`,
`ScriptName`)
VALUES
(412000, 2, 138002, 'Hero''s Call Board', 0.32, 2378, 0, 12399, 1, 'native_ascension_callboard'),
(412001, 2, 138005, 'Warchief''s Command Board', 0.32, 2378, 0, 12399, 1, 'native_ascension_callboard'),
(422000, 2, 3053, 'Outlaw''s Contract Board', 0.5, 7009, 1, 30148, 1, 'native_ascension_callboard')
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
`size` = VALUES(`size`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`),
`Data8` = VALUES(`Data8`), `ScriptName` = VALUES(`ScriptName`);
