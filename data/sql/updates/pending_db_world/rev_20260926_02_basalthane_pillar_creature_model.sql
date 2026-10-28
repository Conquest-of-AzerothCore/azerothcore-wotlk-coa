-- Switch the 3 pillar creatures (10186/10187/10188) from Ascension's real
-- pillar model (200003) to the same Mantid Spike model already added for
-- the gameobject displayId (9500100, see rev_20260925_33).
--
-- Creatures resolve models through a different DBC chain than gameobjects
-- (CreatureModelData.dbc -> CreatureDisplayInfo.dbc -> creature_template_model),
-- so the gameobject's GameObjectDisplayInfo.dbc row from rev_20260925_33 can't
-- be reused directly. Added new rows to both, same id 9500100 for both (id
-- namespaces are per-table, no collision), directly to
-- Build/install/dbc/CreatureModelData.dbc and CreatureDisplayInfo.dbc
-- (server-side files, backed up as *.dbc.bak first) -- same technique as the
-- gameobject one: no MPQ repack, no copying the .m2 anywhere, it already
-- exists in the client (patch-M) and the DBC ModelName just points straight
-- at its real path (world\expansion04\doodads\mantid\mantid_spike_organic.m2).
--
-- CreatureModelData: Scale 1.0, CollisionWidth 1.5, CollisionHeight 6.0,
-- MountHeight 0, geobox -1.5,-1.5,0 to 1.5,1.5,6 (placeholder bounds,
-- matches the gameobject's -- tune in-game if it looks wrong).
-- CreatureDisplayInfo: ModelId 9500100, scale 1.0, alpha 255 (opaque), no
-- texture variants (this is a unique static prop model, not a reskinnable
-- generic one).

UPDATE `creature_template_model` SET `CreatureDisplayID` = 9500100
WHERE `CreatureID` IN (10186, 10187, 10188);
