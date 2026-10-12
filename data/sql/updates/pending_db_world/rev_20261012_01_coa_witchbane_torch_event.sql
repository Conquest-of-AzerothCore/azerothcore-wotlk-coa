-- Witchbane Torch (item 33113, spell 42521 "Light Witchbane Torch") sends event 15453 in the client Spell.dbc, but
-- the script that respawns the torch gameobject at the Swamplight Manor dock (guid 5448) was stored under event
-- 15452. Nothing ran on use, so 'Swamp Eye' Jarl never summoned Zelfrax and "Cleansing Witch Hill" (11183) could
-- not be completed (#7360). Move the script to the event id the spell actually sends.
UPDATE `event_scripts` SET `id` = 15453 WHERE `id` = 15452;
