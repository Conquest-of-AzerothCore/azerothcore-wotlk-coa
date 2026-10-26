-- Conquest of Azeroth Class Bundle tokens: right-click opens the Class Bundle store again.
-- item_coa_class_bundle_token opens the store from ItemScript::OnUse, but both tokens had no use spell and no
-- openable flag, so the client never sent a use. They now carry the instant self-cast Dummy Spell 93461 on use,
-- as the other scripted caches (item_coa_elite_warchest, item_coa_bag_of_bags, item_coa_dungeon_spoils) do.
UPDATE `item_template` SET `spellid_1` = 93461, `spelltrigger_1` = 0, `spellcharges_1` = 0, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1
WHERE `entry` IN (2499003, 2499004);
