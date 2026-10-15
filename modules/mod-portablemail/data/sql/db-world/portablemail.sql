-- mod-portablemail - the world objects CoA's portable gadgets summon.
--
-- Each gadget item casts a spell whose first effect is SPELL_EFFECT_TRANS_DOOR, and that effect
-- spawns the gameobject named in its MiscValue after looking it up in `gameobject_template`
-- (Spell::EffectTransmitted, src/server/game/Spells/SpellEffects.cpp). The world database held
-- none of these objects, so every cast logged
--
--     Gameobject (Entry: 1903511) not exist and not created at spell (ID: 985210) cast
--
-- and did nothing: the item was consumed, no object appeared. This file restores the rows.
--
-- WHERE THE VALUES COME FROM  (this is realm data, not a reconstruction)
-- The client caches the server's own answer to the gameobject query, so `gameobjectcache.wdb`
-- holds the row the realm actually served - type, model, name, size and Data0..Data23. These
-- values were read out of those caches with the datamine's WGOB reader, and every copy that
-- carried a row agreed with every other copy:
--
--     1903511 Gnomish Portable Post Tube      98 caches
--     1903512 Portable Mystic Altar          164 caches
--     1903520 Demonic Portable Transpolyporter 124 caches
--     1903510 Gnomish Portable Transpolyporter  22 caches
--
-- The mapping between the cache record and this table was validated against the rows we hold in
-- both places (type/displayId/name/size and Data0/Data1 matched exactly), so Data0..Data23 here
-- are the realm's own data fields in the same order the server reads them.
--
-- REPLACE, one statement per row: re-applying this file always reproduces exactly the rows
-- below, and it never touches an entry it does not name.
--
-- The second half of the file is a spell override rather than an object row; it is described
-- where it appears at the bottom.

REPLACE INTO `gameobject_template`
(`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`,
 `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`,
 `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`,
 `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`,
 `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
-- Gnomish Portable Post Tube - the mailbox item 1903512 (spell 985210) creates. Type 19 mailbox;
-- model World\Custom\7dl_dalaran_postofficepipe01.mdx (GameObjectDisplayInfo 12003).
(1903511, 19, 12003, 'Gnomish Portable Post Tube', '', '', '', 0.75,
 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 '', '', 12340),

-- Gnomish Portable Transpolyporter - item 1903510 (spell 979611). Type 22 spellcaster, Data0 is
-- the spell the device casts when used (979612, the teleport), model World\Goober\G_GoblinTeleporter.mdx.
(1903510, 22, 2047, 'Gnomish Portable Transpolyporter', '', '', '', 1,
 979612, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 '', '', 12340),

-- Portable Mystic Altar - items 1903513 and 1903514 (spells 985211 / 985212). Type 4 binder;
-- model World\Custom\7nb_nightborn_cage01.mdx. Data1 carries the realm's own value.
(1903512, 4, 12004, 'Portable Mystic Altar', '', '', '', 0.5,
 0, 45004, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 '', '', 12340),

-- Demonic Portable Transpolyporter - item 1903515 "Fel-Infused Gateway" (spell 979411). Type 22
-- spellcaster, Data0 is the spell it casts (979612), model 7fx_orderhallportal_deadscarrift.mdx.
(1903520, 22, 138000, 'Demonic Portable Transpolyporter', '', '', '', 1,
 979612, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 '', '', 12340);

-- ---------------------------------------------------------------------------
-- Fel Gateway (item 1903515 -> spell 979411 -> object 1903520 above)
--
-- The Fel-Infused Gateway's own text, which is what the player reads on the tooltip, ends
-- "Demonic Transpolyporter combusts after 30 seconds." (Spell.dbc 979411, Description_Lang).
-- Its DurationIndex was 25, i.e. 180,000 ms in SpellDuration.dbc, so the gateway stood for
-- three minutes while the text promised 30 seconds.
--
-- That text lives in the client's copy of Spell.dbc and is drawn client-side, so the server
-- cannot rewrite it; the lifetime is ours to set, so the lifetime is what moves. The row below
-- is the game's own row for 979411 with DurationIndex 25 (180 s) changed to 9 (30 s) and
-- nothing else touched - every other value is copied out of Spell.dbc.
--
-- `spell_dbc` replaces a whole DBC row (DBCDatabaseLoader::Load reads SELECT *), so all 234
-- columns must be present; a partial row would zero every field it leaves out.
REPLACE INTO `spell_dbc` VALUES
(979411, 0, 0, 0, 268500992, 131072, 0, 0, 65536, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 192, 0, 0, 15, 128, 0, 0, 101, 0, 0, 0, 1, 9, 0, 0, 0, 0, 0, 12, 0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 50, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0, 87, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0, 1903520, 0, 0, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 945, 0, 4462, 0, 0, 'Fel Gateway', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0.0, 0.0, 0.0, 0, 0);
