-- A Humble Duty (254053) is finished by using six of the seventeen Gravestones
-- (254677) and the single Invincible's Gravestone (254678) at the Chapel of
-- Final Grace. A grave's credit comes from GameObject::Use ->
-- Player::KillCreditGO, which counts the objective up once per call and keeps no
-- record of which object gave it, so one stone could be clicked over and over
-- and the whole quest solved standing still. The seventeen spawns are there for
-- a reason; each stone has to be worth one credit.
--
-- Data3 (autoCloseTime) is the per-object cooldown the core already honours:
-- GameObject::Use hands out the credit, then sets GO_FLAG_IN_USE and starts the
-- timer, and every later use returns at the top of the goober case before any
-- credit is given. When the timer runs out the update clears the flag and the
-- stone is clickable again, so the six credits still come from six different
-- stones without anyone waiting.
--
-- Data5 (consumable) drops to 0 at the same time. The object was never activated
-- before, so that flag did nothing; now that it is, consumable 1 would send the
-- grave down the despawn path on its first use and empty the graveyard out for
-- its 60 second spawn. A cooldown should not cost the graveyard.
UPDATE `gameobject_template`
SET `Data3` = 30000, `Data5` = 0
WHERE `entry` IN (254677, 254678);
