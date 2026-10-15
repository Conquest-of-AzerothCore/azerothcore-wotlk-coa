-- Gahz'rilla (7273) is unit_class 1, so it has no mana, and its Ascension kit row 9000 casts Icicle (11131, 135 mana):
-- every cast failed with NO_POWER. The kit cast is now triggered, which skips the cost; its 10-12 s timer still sets
-- the pace, and the creature keeps its warrior health, armour and damage.
UPDATE `smart_scripts` SET `action_param2` = 2
    WHERE `entryorguid` = 7273 AND `source_type` = 0 AND `id` = 9000 AND `action_type` = 11 AND `action_param1` = 11131;

-- Jammal'an the Prophet (5710) was raised from level 50 to 54 (rev_20260923_65). Healing Wave (12492) and Flamestrike
-- (12468) scale their cost with creature level and now cost 835 + 1207 = 2042 against a 2041 mana pool, so Flamestrike
-- never went out. ManaModifier 2 gives 4082 mana, room for both again as at level 50.
UPDATE `creature_template` SET `ManaModifier` = 2 WHERE `entry` = 5710;
