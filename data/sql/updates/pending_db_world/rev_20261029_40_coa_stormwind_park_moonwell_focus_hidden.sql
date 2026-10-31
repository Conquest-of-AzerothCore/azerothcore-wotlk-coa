-- Moonwell spell focus 177272 uses the EasterEgg01 placeholder model. Stock hid it under the park moonwell's water;
-- the CoA Stormwind park moonwell basin is dry, so four eggs lay in plain sight. Remove the model and keep the
-- focus for Mooncloth.

UPDATE `gameobject_template` SET `displayId` = 0 WHERE `entry` = 177272;
