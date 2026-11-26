-- The Greatest Race of Hunters (quest 7503) and the book that starts it (item 18361) are open to Witch Doctors,
-- whose Shadowhunting specialization fights like a Hunter. The item keeps the Hunter-family classes (Witch Hunter,
-- Ranger, Tinker) the loader used to add: an explicit custom class bit turns that expansion off.
UPDATE `item_template` SET `AllowableClass` = 135287300 WHERE `entry` = 18361;
UPDATE `quest_template_addon` SET `AllowableClasses` = 4100 WHERE `ID` = 7503;
