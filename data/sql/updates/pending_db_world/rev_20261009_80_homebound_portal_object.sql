-- #6101: Summon Homebound Portal 93186 (item 97758) is SPELL_EFFECT_TRANS_DOOR with EffectMiscValue 80775, but no
-- gameobject_template row for 80775 exists, so Spell::EffectTransmitted returns without placing anything.
--
-- Source: hertigservices/ascension-data, release exiles-db-export-2026-09-13 (asset
-- coa-public-2026-09-13-tables.tar), table `gameobject`, row id 80775: name "Homebound Portal", type 22
-- (GAMEOBJECT_TYPE_SPELLCASTER), display_id 1026702. The export records no on-use spell for it, so Data0 is the
-- client spell 93187 "Homebound Portal": a dummy effect whose client target is the nearest gameobject. CoA retargets
-- it to an explicit gameobject target at load; go_ascension_homebound_portal casts it at the portal that was clicked
-- and spell_ascension_homebound_portal sends the user to that portal's owner's Hearthstone, as Summon Homebound
-- Portal's description says. Every column is written, so an entry that already exists with other values is replaced
-- as a whole row.
INSERT INTO `gameobject_template` (
    `entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`,
    `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`,
    `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`,
    `VerifiedBuild`
) VALUES
(80775, 22, 1026702, 'Homebound Portal', '', '', '', 1, 93187, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, '', 'go_ascension_homebound_portal', 0)
ON DUPLICATE KEY UPDATE
    `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
    `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`),
    `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`),
    `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`),
    `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`),
    `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`),
    `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`),
    `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`),
    `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`),
    `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`),
    `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1 AND `SourceEntry` = 93187;

DELETE FROM `spell_script_names` WHERE `spell_id` = 93187 AND `ScriptName` = 'spell_ascension_homebound_portal';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(93187, 'spell_ascension_homebound_portal');
