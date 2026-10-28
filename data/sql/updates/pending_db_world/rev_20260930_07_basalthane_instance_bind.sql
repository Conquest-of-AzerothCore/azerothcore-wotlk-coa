-- Basalthane (10189-10192) had no CREATURE_FLAG_EXTRA_INSTANCE_BIND (0x1),
-- so killing him never bound the raid's instance lockout. User confirmed he
-- should have a normal raid lockout on kill.

UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x1
WHERE `entry` IN (10189, 10190, 10191, 10192);
