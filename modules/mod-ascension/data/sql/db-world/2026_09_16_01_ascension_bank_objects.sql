-- The objects the Personal Bank / Celestial Personal Bank / Realm Bank items summon.
--
-- CoA's own client carries these as gameobject type 34 (the type the client opens
-- a bank frame for), captured as "Personal Belongings" (475001 alliance / 475002
-- horde), "Celestial Personal Belongings" (80782) and "Realm Belongings" (80159
-- alliance / 80160 horde). Their display ids are chests, not guild vaults:
--   138006 world\generic\alliance\chest\alliancechest_01.mdx
--   138007 world\generic\horde\chest\hordechest_01.mdx
--   8691   world\expansion02\doodads\ulduar\ul_chest_cosmic.mdx   (Celestial)
-- They are not in this world database, so the module ships them; the summon spell
-- script picks the faction pair, and answers the activate that follows.

-- REPLACE, not INSERT: a template that is already there is rewritten instead of duplicated, so
-- applying this twice leaves the same five rows.
REPLACE INTO `gameobject_template`
    (`entry`, `type`, `displayId`, `name`, `size`, `Data0`) VALUES
(475001, 34, 138006, 'Personal Belongings',          1,   0),
(475002, 34, 138007, 'Personal Belongings',          1,   0),
(80782,  34, 8691,   'Celestial Personal Belongings', 0.7, 0),
(80159,  34, 138006, 'Realm Belongings',             1,   0),
(80160,  34, 138007, 'Realm Belongings',             1,   0);
