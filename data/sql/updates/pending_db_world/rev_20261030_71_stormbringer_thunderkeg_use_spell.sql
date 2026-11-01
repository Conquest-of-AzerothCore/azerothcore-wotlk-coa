-- #10281: Conjure Thunderkeg (807849) places Thunderkeg (gameobject 195002, GAMEOBJECT_TYPE_SPELLCASTER), but
-- rev_20260930_93 left Data0 (spell cast on the user) at 0, so using the keg did nothing.
-- The tooltip: "Players in your party or raid may interact with it to receive $807850s1 tankards of
-- Thunderale". 807850 is Conjure Thunderale (CREATE_ITEM 2000150 Weak Thunder Ale, 5). Data2 (partyOnly) = 1
-- matches the party/raid clause. Data1 (charges) stays 0: no source gives a limit.
UPDATE `gameobject_template` SET `Data0` = 807850, `Data2` = 1 WHERE `entry` = 195002;
