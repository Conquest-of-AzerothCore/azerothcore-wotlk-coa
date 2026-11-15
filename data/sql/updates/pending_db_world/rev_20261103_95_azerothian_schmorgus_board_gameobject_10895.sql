-- Azerothian Schmorgus Board (#10895): item 100626 casts 966448, which places gameobject 100626, but the template was
-- missing, so the item was spent and nothing appeared. Values from the CoA client gameobject cache: a spellcaster that
-- casts Refreshment 966449 on 50 party members.
DELETE FROM `gameobject_template` WHERE `entry` = 100626;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`,
    `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`,
    `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`,
    `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(100626, 22, 138012, 'Azerothian Schmorgus Board', 'Interact', '', '', 0.4,
    966449, 50, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0);

-- Eating 10 seconds triggers Well Fed 966452, a dummy that picks the Spell Power 966453 or Attack Power 966454 buff.
DELETE FROM `spell_script_names` WHERE `spell_id` = 966452;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (966452, 'spell_ascension_schmorgus_well_fed');
