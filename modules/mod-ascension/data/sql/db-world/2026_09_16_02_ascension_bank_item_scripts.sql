-- Bind the bank vouchers to the item scripts this module registers.
--
-- An item only reaches an ItemScript through `item_template.ScriptName`: the session's
-- use-item handler asks ScriptMgr, which resolves `Item::GetScriptId()` ->
-- `ItemTemplate::ScriptId`, and that is filled from this column at template load. With it
-- empty the voucher cast its spell and nothing else happened - no tab, no message, no
-- consumption - which is exactly what "the new tabs are not there" looked like.
--
--   110002, 134986  Personal Bank Tab Voucher  -> the character's own bank
--   1180485         Realm Bank Tab Voucher     -> the shared realm bank
--   102130, 134984  Ornate Bank Voucher        -> the ordinary bank bag slots, same module
--                                                  script family, same empty column
UPDATE `item_template` SET `ScriptName` = 'item_ascension_bank_tab_voucher'
    WHERE `entry` IN (110002, 134986, 1180485);

UPDATE `item_template` SET `ScriptName` = 'item_ascension_bank_voucher'
    WHERE `entry` IN (102130, 134984);
