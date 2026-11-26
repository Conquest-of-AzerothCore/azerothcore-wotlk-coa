-- Deadman's Signet (entry 515510, guid 6941618 at Alien Egg quest 4821 POI 2 in Thousand Needles):
-- replace displayId 63516 (JewelCraft_Ring03.mdx, 96.4x86.6x77.8 yd giant ring) with pickup-scale
-- displayId 1015946 (jewelcraft_ring03.m2, 0.61x0.82x1.10 yd) from GameObjectDisplayInfo.dbc.
UPDATE `gameobject_template` SET `displayId` = 1015946 WHERE `entry` = 515510 AND `displayId` = 63516;
