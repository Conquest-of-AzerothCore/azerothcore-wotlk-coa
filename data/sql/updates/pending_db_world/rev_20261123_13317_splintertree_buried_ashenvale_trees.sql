-- Splintertree Post: two Ashenvale Trees from the woodcutting import were buried 2.3 and 28.2 yd in the cliff and could
-- not be reached; no gathered source places a tree there.
DELETE FROM `gameobject` WHERE `guid` IN (8000677, 8000708) AND `id` = 244630;
