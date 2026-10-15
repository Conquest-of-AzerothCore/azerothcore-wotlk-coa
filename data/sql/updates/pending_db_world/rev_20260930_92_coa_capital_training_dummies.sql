-- Capital training grounds: CoA's level 60 Training Dummy only
-- CoA client creature caches name 32666 "Training Dummy" (captured 2026-07-03 to 2026-09-10); the level 70, 80
--   and 83 dummies never appear in any Ascension capture, so their capital spawns become 32666 in place
UPDATE `creature_template` SET `name` = 'Training Dummy' WHERE `entry` = 32666;
UPDATE `creature` SET `id` = 32666 WHERE `id` IN (31144, 31146, 32667) AND `guid` IN
(42154, 42155, 42156, 42157, 48316, 48317, 48318, 48319, 48320, 48321, 48322, 48323, 48324, 48325, 48326, 48338,
48339, 48340, 48341, 48342, 88215, 88216, 88223, 88224, 201235, 201236, 201237, 201239, 201241, 201242, 202721,
202722, 202723, 202730, 202731, 202962, 202963, 202964, 202965, 202966, 202967, 202968, 204942, 204943, 204944,
204947, 204948);
