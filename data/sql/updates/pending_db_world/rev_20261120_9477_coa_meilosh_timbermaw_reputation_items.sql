-- Meilosh <Timbermaw Hold Quartermaster> (11557) sold the Timbermaw Hold reputation rewards on live Conquest of
-- Azeroth and only sold Ancient Stick here (#9477). The BisBeard item list in the db.exil.es export (2026-09-13)
-- labels 15 of these items "Timbermaw Hold - Honored/Revered/Exalted"; the five others (856017, 856018, 856022,
-- 856026, 856029) and Formula: Enchant Cloak - Lesser Spell Penetration 46520 require Timbermaw Hold in the captured
-- WDB itemcache. No captured vendor list names their seller; the owner confirmed Meilosh. Ranks and prices are the
-- existing item_template values. Defender of the Timbermaw 21326 stays the reward of The Root of All Evil 8481.
DELETE FROM `npc_vendor` WHERE `entry` = 11557 AND `ExtendedCost` = 0 AND `item` IN (
    46520, 856009, 856010, 856011, 856012, 856013, 856014, 856017,
    856018, 856022, 856026, 856029, 1519801, 1519802, 1519803, 1519890,
    1519891, 1519892, 1519893, 1519894, 1519895
);

INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(11557, 0, 46520, 0, 0, 0),
(11557, 0, 856009, 0, 0, 0),
(11557, 0, 856010, 0, 0, 0),
(11557, 0, 856011, 0, 0, 0),
(11557, 0, 856012, 0, 0, 0),
(11557, 0, 856013, 0, 0, 0),
(11557, 0, 856014, 0, 0, 0),
(11557, 0, 856017, 0, 0, 0),
(11557, 0, 856018, 0, 0, 0),
(11557, 0, 856022, 0, 0, 0),
(11557, 0, 856026, 0, 0, 0),
(11557, 0, 856029, 0, 0, 0),
(11557, 0, 1519801, 0, 0, 0),
(11557, 0, 1519802, 0, 0, 0),
(11557, 0, 1519803, 0, 0, 0),
(11557, 0, 1519890, 0, 0, 0),
(11557, 0, 1519891, 0, 0, 0),
(11557, 0, 1519892, 0, 0, 0),
(11557, 0, 1519893, 0, 0, 0),
(11557, 0, 1519894, 0, 0, 0),
(11557, 0, 1519895, 0, 0, 0);
