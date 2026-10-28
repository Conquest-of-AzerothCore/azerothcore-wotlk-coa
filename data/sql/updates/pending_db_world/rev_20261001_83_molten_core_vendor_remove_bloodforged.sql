-- The 8 T1/T2 tier-token vendor lists (91000001-91000008, rev_20261001_60) wired every class
-- variant of the 18 classic sets plus each set's "Bloodforged" faction-skin twin, per an earlier
-- "faction versions, both vendors list all" instruction. That instruction was wrong: Major
-- Mattingly and Overlord Runthak must sell only the classic Tier 1/Tier 2 pieces, for every
-- difficulty and every set -- never a Bloodforged variant.
--
-- Bloodforged items share their base set's item_template.ItemSet (e.g. "Bloodforged Dragonstalker's
-- Helm" still carries ItemSet 215, not a distinct 60215/61215 id as the client DBC's own set name
-- would suggest), so ItemSet cannot distinguish them; every Bloodforged row's name starts with the
-- literal "Bloodforged " prefix instead (checked: no vendor row contains "Bloodforged" anywhere in
-- its name without that exact prefix). 320 such rows exist across the 8 lists -- 80 apiece in T1
-- Normal/Heroic and T2 Normal/Heroic (91000001/91000002/91000005/91000006); Mythic/Ascended
-- (91000003/91000004/91000007/91000008) never carried a Bloodforged clone to begin with.
DELETE FROM `npc_vendor` WHERE `entry` BETWEEN 91000001 AND 91000008
    AND `item` IN (SELECT `entry` FROM `item_template` WHERE `name` LIKE 'Bloodforged %');
