-- ----------------------------------------------------------------------------
-- Worldforged pickups: revert ADT snaps that overwrote authored heights (#4984)
-- ----------------------------------------------------------------------------
-- 2026_10_06_65 snapped 286 open-world pickups to the stock map height. 52 of those pins already
-- carried a post-wipe in-game / zone-final / realm-authored Z (or had no provenance at all), so the
-- snap replaced a deliberate placement. This file restores them; XY, orientation and entry are
-- untouched, and 2026_10_06_65 / _66 are left as shipped.
--
-- Gate rule for any future height pass: skip a guid when
--   `Comment` LIKE '%in-game placement%'
-- OR the guid appears in any *_authored* / *_final* / realm-pin SQL dated on or after 2026-09-24
-- with a matching Z.
--
START TRANSACTION;

-- Authored / in-game / zone-final heights (44)
UPDATE `gameobject` SET `position_z` = 162.550308 WHERE `guid` = 6940492;
UPDATE `gameobject` SET `position_z` = 70.870033 WHERE `guid` = 6940334;
UPDATE `gameobject` SET `position_z` = 64.162811 WHERE `guid` = 6960027;
UPDATE `gameobject` SET `position_z` = 77.7749 WHERE `guid` = 6942549;
UPDATE `gameobject` SET `position_z` = 33.416107 WHERE `guid` = 6940717;
UPDATE `gameobject` SET `position_z` = 22.8818 WHERE `guid` = 6940852;
UPDATE `gameobject` SET `position_z` = 150.051987 WHERE `guid` = 6940544;
UPDATE `gameobject` SET `position_z` = 43.7252 WHERE `guid` = 6960040;
UPDATE `gameobject` SET `position_z` = 64.870598 WHERE `guid` = 6941368;
UPDATE `gameobject` SET `position_z` = 53.941833 WHERE `guid` = 6941336;
UPDATE `gameobject` SET `position_z` = 42.1638 WHERE `guid` = 6960039;
UPDATE `gameobject` SET `position_z` = 119.078 WHERE `guid` = 6940022;
UPDATE `gameobject` SET `position_z` = 49.4158 WHERE `guid` = 6941016;
UPDATE `gameobject` SET `position_z` = 38.5402 WHERE `guid` = 6960207;
UPDATE `gameobject` SET `position_z` = -0.028435 WHERE `guid` = 6940546;
UPDATE `gameobject` SET `position_z` = 66.520905 WHERE `guid` = 6940333;
UPDATE `gameobject` SET `position_z` = 113.439 WHERE `guid` = 6940062;
UPDATE `gameobject` SET `position_z` = 57.942394 WHERE `guid` = 6941149;
UPDATE `gameobject` SET `position_z` = 37.31303 WHERE `guid` = 6960038;
UPDATE `gameobject` SET `position_z` = 2.46281 WHERE `guid` = 6960206;
UPDATE `gameobject` SET `position_z` = 22.910549 WHERE `guid` = 6960025;
UPDATE `gameobject` SET `position_z` = 44.185085 WHERE `guid` = 6940595;
UPDATE `gameobject` SET `position_z` = 73.996201 WHERE `guid` = 6941165;
UPDATE `gameobject` SET `position_z` = 43.017685 WHERE `guid` = 6960029;
UPDATE `gameobject` SET `position_z` = 127.179 WHERE `guid` = 6940215;
UPDATE `gameobject` SET `position_z` = 42.453659 WHERE `guid` = 6940439;
UPDATE `gameobject` SET `position_z` = 66.57901 WHERE `guid` = 6942546;
UPDATE `gameobject` SET `position_z` = 61.855438 WHERE `guid` = 6942550;
UPDATE `gameobject` SET `position_z` = 55.903893 WHERE `guid` = 6940179;
UPDATE `gameobject` SET `position_z` = 41.402954 WHERE `guid` = 6940349;
UPDATE `gameobject` SET `position_z` = 62.598858 WHERE `guid` = 6960022;
UPDATE `gameobject` SET `position_z` = 95.966103 WHERE `guid` = 6940105;
UPDATE `gameobject` SET `position_z` = 30.635445 WHERE `guid` = 6940807;
UPDATE `gameobject` SET `position_z` = 75.099808 WHERE `guid` = 6940869;
UPDATE `gameobject` SET `position_z` = 49.430202 WHERE `guid` = 6960018;
UPDATE `gameobject` SET `position_z` = 52.133617 WHERE `guid` = 6941212;
UPDATE `gameobject` SET `position_z` = 74.134285 WHERE `guid` = 6940502;
UPDATE `gameobject` SET `position_z` = 33.891888 WHERE `guid` = 6940903;
UPDATE `gameobject` SET `position_z` = 67.721489 WHERE `guid` = 6940291;
UPDATE `gameobject` SET `position_z` = 92.889923 WHERE `guid` = 6940032;
UPDATE `gameobject` SET `position_z` = 38.630177 WHERE `guid` = 6960005;
UPDATE `gameobject` SET `position_z` = 34.372692 WHERE `guid` = 6940342;
UPDATE `gameobject` SET `position_z` = 33.1411 WHERE `guid` = 6940734;
UPDATE `gameobject` SET `position_z` = 31.777443 WHERE `guid` = 6940811;

-- Provenance-less rows: back to the pre-65 live Z (8)
UPDATE `gameobject` SET `position_z` = 146.345 WHERE `guid` = 6941461;
UPDATE `gameobject` SET `position_z` = 1346.1 WHERE `guid` = 6941716;
UPDATE `gameobject` SET `position_z` = 185.658 WHERE `guid` = 6940240;
UPDATE `gameobject` SET `position_z` = 186.363 WHERE `guid` = 6940183;
UPDATE `gameobject` SET `position_z` = 139.078 WHERE `guid` = 6942093;
UPDATE `gameobject` SET `position_z` = 70.928 WHERE `guid` = 6941148;
UPDATE `gameobject` SET `position_z` = 66.081 WHERE `guid` = 6940244;
UPDATE `gameobject` SET `position_z` = 111.425 WHERE `guid` = 6940974;

COMMIT;
