-- Remove the 32 statless Bloodforged Replica Dungeon Set 2 (T0.5) cosmetic pieces (#11917, #13463)
-- from coa_bloodforged_catalogue. Both the base Replica items (78196-78330) and these Bloodforged
-- twins carry zero primary/secondary stats (only armor, resilience and PvP power).
DELETE FROM `coa_bloodforged_catalogue` WHERE `entry` IN (
    6078196, 6078197, 6078198, 6078200,
    6078212, 6078216, 6078217, 6078219,
    6078230, 6078235, 6078236, 6078237,
    6078248, 6078249, 6078251, 6078252,
    6078262, 6078263, 6078266, 6078269,
    6078278, 6078279, 6078282, 6078284,
    6078310, 6078312, 6078313, 6078314,
    6078326, 6078328, 6078329, 6078330
);
