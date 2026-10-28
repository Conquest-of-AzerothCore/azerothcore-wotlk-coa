-- ----------------------------------------------------------------------------
-- Worldforged pickups: third playtest pass on open-world placements (#4984)
-- ----------------------------------------------------------------------------
-- Additive on top of rev_20261006_65 .. _69, which stay as shipped.
-- Confirmed in game: Dropped Shield pose. Jewelry display swap and Scarlet Band / Zul'Kunda ring lay-flat folded from live playtest.
--
-- Display 1074163 is 9mw_domination_legendaryarmor_necklace01.m2, a tall (0.9 yd) legendary-armor showpiece that
-- stands upright whatever the rotation. Display 1010146 is jewelcraft_necklace01.m2: 1.6 x 0.65 x 0.3 yd and
-- flat at identity rotation, already used by Eliza's Pendant and Southmoon Amulet. Sized to 0.35 so the
-- necklace reads as a small pickup rather than a chest-scale model.
--
-- Round-4 live playtest follow-ups folded in below: Deserter 2nd cave move, hatchet lay-flat, Glen Guardian
-- rack+chairs, Zul'Kunda Z + lay-flat rot, Heretical Libram Z, Scarlet Band Z + lay-flat rot + band display.
-- Confirmed ring quat (0, 0.707107, 0, 0.707107); ring Z nudged down a pixel (152.05 / 61.40).
START TRANSACTION;

-- 6941652 Dropped Shield: confirmed. Laid flat face-up on a plank (XY nudged onto the plank, Z from the player's
-- standing height; the ADT reads 116.33 under the deck).
UPDATE `gameobject` SET `position_x` = -312.834, `position_y` = -4020.400, `position_z` = 121.400,
    `orientation` = 2.98032, `rotation0` = 0.056958, `rotation1` = 0.704812, `rotation2` = 0.704812,
    `rotation3` = 0.056958 WHERE `guid` = 6941652;

-- 6942141 Scarlet Blunderbuss: 1331.500 (pending confirm). 1330.9 left the rack half merged; the ADT reads 1331.51.
UPDATE `gameobject` SET `position_z` = 1331.500 WHERE `guid` = 6942141;

-- Deserter's Last Resort (1345038) and Fragment of K'aresh (1345056) switch from the upright Domination necklace
-- to the flat jewelcraft necklace at size 0.35. Affected guids: 6941629, 6941630, 6941751, 6940506.
UPDATE `gameobject_template` SET `displayId` = 1010146, `size` = 0.35 WHERE `entry` IN (1345038, 1345056);

-- 6941629 Deserter's Last Resort: the (0.5, 0.5, 0.5, 0.5) tilt was a workaround for the upright
-- model; with the flat display it is a plain yaw of 0.62188. Z 46.5 is the platform floor (FloorZ 46.48).
UPDATE `gameobject` SET `position_z` = 46.500, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.305954,
    `rotation3` = 0.952046 WHERE `guid` = 6941629;

-- 6941630 Deserter's Last Resort (2nd): lived inside Md_Warmcave_Medium.wmo at (878.8,-4715.3,30.889) where the
-- player falls through (no collision at that XY). Moved beside Copper Vein 76087 on the walkable cave floor.
UPDATE `gameobject` SET `position_x` = 870.500, `position_y` = -4707.500, `position_z` = 31.150,
    `orientation` = 0, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0, `rotation3` = 1
WHERE `guid` = 6941630;

-- 6941751 Fragment of K'aresh: same reason, orientation 0 so identity rotation.
UPDATE `gameobject` SET `position_z` = 57.150, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0, `rotation3` = 1
WHERE `guid` = 6941751;

-- 6940506 Fragment of K'aresh, Swamp of Sorrows: its tilted quaternion was tuned for the upright
-- display, so it follows the swap back to a plain yaw of 0.688079.
UPDATE `gameobject` SET `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.337293, `rotation3` = 0.941400
WHERE `guid` = 6940506;

-- 6940773 Mountaineer Hatchet: 328.408 -> 333.999 (stock anvil floor). Yaw-only left the weapon upright; lay flatter
-- with a 90deg pitch composed onto yaw 2.0831 -> (0.357006, 0.610366, 0.610366, 0.357006).
UPDATE `gameobject` SET `position_z` = 333.999, `rotation0` = 0.357006, `rotation1` = 0.610366,
    `rotation2` = 0.610366, `rotation3` = 0.357006 WHERE `guid` = 6940773;

-- 6940548 Glen Guardian (Eye-Catching Item Rack): raised off the ADT onto the stock floor, then lowered slightly so
-- the rack feet sit clean (13.476 -> 12.900). The three stock Wooden Chairs it overlaps (18693, 18694, 18699) are
-- removed: the loader resets a zero phaseMask to 1, so they cannot be hidden that way.
DELETE FROM `gameobject` WHERE `guid` IN (18693, 18694, 18699);
UPDATE `gameobject` SET `position_z` = 12.900 WHERE `guid` = 6940548;

-- 6941371 Zul'Kunda Blood Ring: was floating at 65.785; player GroundZ/FloorZ 61.408. Z 61.40 sits on the ground
-- (61.50 floated a pixel). Lay flat with quaternion (0, 0.707107, 0, 0.707107) - confirmed in playtest.
UPDATE `gameobject` SET `position_z` = 61.40, `rotation0` = 0, `rotation1` = 0.707107, `rotation2` = 0, `rotation3` = 0.707107 WHERE `guid` = 6941371;

-- 6941820 Heretical Libram: SQL 65 snapped to ADT 65.814 (merged under coffin/floor prop). Raise to the Nether Sister
-- floor band (~68.0); +0.5 above floor so it sits on/beside the coffin rather than inside it.
UPDATE `gameobject` SET `position_z` = 68.500 WHERE `guid` = 6941820;

-- Scarlet Band template (340066): swap upright Domination necklace 1074163 for band display 1070109 at size 0.25.
UPDATE `gameobject_template` SET `displayId` = 1070109, `size` = 0.25 WHERE `entry` = 340066;

-- Zul'Kunda Blood Ring template (95736): shrink pickup size to 0.25.
UPDATE `gameobject_template` SET `size` = 0.25 WHERE `entry` = 95736;

-- 6941010 Scarlet Band: SQL 65 snapped to ADT 146.025 (buried); Scarlet Sentinels at this XY stand at 152.103.
-- Raise to 152.05 (152.15 floated a pixel) and lay flat with quaternion (0, 0.707107, 0, 0.707107) - confirmed.
UPDATE `gameobject` SET `position_z` = 152.05, `rotation0` = 0, `rotation1` = 0.707107, `rotation2` = 0, `rotation3` = 0.707107 WHERE `guid` = 6941010;

COMMIT;
