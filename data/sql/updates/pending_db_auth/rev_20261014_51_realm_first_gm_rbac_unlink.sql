-- #6533 Permission 9 (cannot earn realm first achievements) is no longer inherited by every GM role through 194.
-- AscensionAchievementConditions refuses realm firsts to holders of 9, so the link would bar every GM account from
-- them; without it GM accounts earn and lock realm firsts like players, and 9 stays available as an explicit grant.
DELETE FROM `rbac_linked_permissions` WHERE `id` = 194 AND `linkedId` = 9;
