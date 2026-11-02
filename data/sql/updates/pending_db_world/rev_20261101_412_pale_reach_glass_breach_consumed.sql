-- Outer Crystal of the Deeprun Tram (175139): one Glass Breach (gameobject 2300699) could be repaired over and over,
-- crediting the quest on every use (#10528). The goober is authored consumable, but with an auto-close time of 0
-- GameObject::Use never marks it in use or activates it, so it never despawns. A one second auto-close marks the
-- breach in use on the first repair, rejects further uses, then lets the consumable despawn and respawn it.
UPDATE `gameobject_template` SET `Data3` = 1000 WHERE `entry` = 2300699;
