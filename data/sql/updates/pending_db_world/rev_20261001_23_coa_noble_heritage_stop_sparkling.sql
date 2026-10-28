-- A Noble Heritage 1660028: its four valuables kept sparkling after they were looted. A chest whose questId
-- (Data8) is set activates for anyone with that quest incomplete (GameObject::ActivateToQuest), so every object
-- sparkled until the whole quest was done. Each already drops a quest-required item, which alone decides the
-- sparkle per item, so the questId goes.
UPDATE `gameobject_template` SET `Data8` = 0 WHERE `entry` IN (2300528, 2300529, 2300530, 2300531);
