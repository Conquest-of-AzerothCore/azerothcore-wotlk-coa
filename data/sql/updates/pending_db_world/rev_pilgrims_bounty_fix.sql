-- Remove and respawn Pilgrim's Bounty objects at Light's Hope Chapel to fix clipping with Ascension doodads
-- Generated using apps/coa-gameplay-check/find_pilgrims_bounty_objects.py

-- First, remove the existing objects that are clipping
DELETE FROM gameobject WHERE guid IN (
    -- These GUIDs should be replaced with actual values from the script output
    12345, 12346, 12347, 12348, 12349
);

-- Now respawn them in the new location outside the inn building to the right of the entrance
-- Position: approximately 74.9, 54.3 on Sexymap coordinates
-- Converted to gameobject coordinates (adjust as needed)

INSERT INTO gameobject (guid, id, map, spawnMask, phaseMask, position_x, position_y, position_z, orientation, rotation0, rotation1, rotation2, rotation3, spawntimesecs, animprogress, state) VALUES
-- Pilgrim's Bounty Table
(12350, 181385, 0, 1, 1, 2248.50, -5305.80, 83.50, 1.57, 0, 0, 0.707, 0.707, 300, 100, 1),

-- Pilgrim's Bounty Chairs
(12351, 181386, 0, 1, 1, 2247.80, -5306.20, 83.50, 1.57, 0, 0, 0.707, 0.707, 300, 100, 1),
(12352, 181386, 0, 1, 1, 2249.20, -5306.20, 83.50, 1.57, 0, 0, 0.707, 0.707, 300, 100, 1),
(12353, 181386, 0, 1, 1, 2248.50, -5307.00, 83.50, 1.57, 0, 0, 0.707, 0.707, 300, 100, 1),
(12354, 181386, 0, 1, 1, 2248.50, -5304.60, 83.50, 1.57, 0, 0, 0.707, 0.707, 300, 100, 1);

-- Note: The actual gameobject IDs (181385, 181386) and GUIDs should be verified
-- using the find_pilgrims_bounty_objects.py script before applying this SQL.