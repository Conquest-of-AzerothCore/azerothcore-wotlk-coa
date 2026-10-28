-- The Ragnaros portal (go_ragnaros_portal_coa, gameobject_template 181623) was visible from the
-- start of the Majordomo fight: it was a static `gameobject` row (guid 9000601) gated only by
-- `GO_FLAG_NOT_SELECTABLE`, a flag that blocks the click/use path but not rendering, so the
-- client always drew the model. It is now spawned by `instance_molten_core.cpp` /
-- `boss_majordomo_executus.cpp` only once `DATA_MAJORDOMO_EXECUTUS` reaches `DONE` (live defeat
-- or already-DONE on instance load), so the static row is removed outright.
DELETE FROM `gameobject` WHERE `guid` = 9000601;

-- The template itself (reused stock "Molten Core Instance Portal") was never clickable: every
-- base-data use of `type = 5` (GAMEOBJECT_TYPE_GENERIC, e.g. this row and the whole "Instance
-- Portal"/"Caverns of Time Portal" family, gameobject_template entries 19527-19531/19503) is pure
-- decoration paired with a separate AreaTrigger that performs the teleport on walk-in - stock
-- content never clicks a type-5 object, and the WoW client offers no interact cursor for one
-- regardless of server-side GameObject::Use()/GossipHello (which did already run - the reported
-- "CMSG_GAMEOBJ_USE works server-side" symptom). Retyped to `type = 10` (GAMEOBJECT_TYPE_GOOBER,
-- the standard click-and-run-a-script object type) with `displayId = 7161` ("Orb of
-- Translocation"), copying gameobject_template 180911/180912/182543/182546 field-for-field (all
-- Data fields 0, no lock/quest/spell gate) - that exact type/displayId pair is confirmed clickable
-- in this fork's own base data as real, live Outland teleporters (gameobject guids 12932/13210 on
-- map 530). `go_ragnaros_portal_coa`'s own GossipHello (boss_majordomo_executus.cpp) is unchanged
-- and already teleports the clicking player; only the template's type/model were wrong.
UPDATE `gameobject_template` SET
    `type` = 10,
    `displayId` = 7161,
    `name` = 'Portal to Ragnaros\' Lair',
    `size` = 1,
    `Data0` = 0, `Data1` = 0, `Data2` = 0, `Data3` = 0, `Data4` = 0, `Data5` = 0, `Data6` = 0,
    `Data7` = 0, `Data8` = 0, `Data9` = 0, `Data10` = 0, `Data11` = 0, `Data12` = 0, `Data13` = 0,
    `Data14` = 0, `Data15` = 0, `Data16` = 0, `Data17` = 0, `Data18` = 0, `Data19` = 0, `Data20` = 0
WHERE `entry` = 181623;
