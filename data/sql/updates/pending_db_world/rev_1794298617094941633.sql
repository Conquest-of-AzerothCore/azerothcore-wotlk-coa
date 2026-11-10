-- Boss Blitz Gold Satchel (500) carries ITEM_FLAG_HAS_LOOT with no loot rows or money loot, so opening it
-- produced an empty loot window and consumed the satchel. Its item script pays the 500 gold instead.
UPDATE `item_template` SET `ScriptName` = 'item_ascension_gold_satchel' WHERE `entry` = 800901;
