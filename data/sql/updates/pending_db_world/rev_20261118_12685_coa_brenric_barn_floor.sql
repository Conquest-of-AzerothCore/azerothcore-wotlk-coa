-- Brenric (Shadewell barn): the live-capture z 334.481 is 0.255 yd under the Barn.wmo floor (334.736 from the
-- server vmap at his X/Y), so he sinks into the floor.
UPDATE `creature` SET `position_z` = 334.736 WHERE `guid` = 9960591 AND `id` = 164151;
