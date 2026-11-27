-- Heroic and Mythic boss leashes reported as too tight (#13835, #13836, #13847, #13849).
-- Rethilgore (3914) reset as soon as he was kited out of his cell; his room polygon is replaced by the 50-yard circle
-- most bosses use. Baron Silverlaine (3887) and Razorclaw the Butcher (3886) could be pulled into each other's room
-- on Ascension (report #13836); their spawns are 82 yards apart, so both get a 90-yard circle and Silverlaine's room
-- polygon goes. Stomper Kreeg (14322) and Captain Kromcrush (14325) had 30 yards, so a fear, a charge or kiting the
-- Bladestorm reset them; they get 50 yards.
DELETE FROM `coa_boss_leash_point` WHERE `entry` IN (3887, 3914);
DELETE FROM `coa_boss_leash` WHERE `entry` IN (3886, 3887, 3914, 14322, 14325);
INSERT INTO `coa_boss_leash` (`entry`, `radius`, `target`) VALUES
(3886, 90, 0),
(3887, 90, 0),
(3914, 50, 0),
(14322, 50, 0),
(14325, 50, 0);
