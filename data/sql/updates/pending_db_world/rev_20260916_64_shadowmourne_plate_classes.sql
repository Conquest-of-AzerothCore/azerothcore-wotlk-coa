-- Shadowmourne is gated to Warrior, Paladin and Death Knight, the three plate classes WotLK
-- shipped with. This fork has more, and the Shadowmourne chain and the axe itself never learned
-- about them, so a Knight of Xoroth could not start "The Sacred and the Corrupt" at all.
--
-- The gate is which classes can actually wield the reward. Shadowmourne is a two-handed axe
-- (item class 2, subclass 1), and mod-ascension-compat's ClassProficiencies grants the Two-Handed
-- Axes proficiency (spell 197) to exactly six Ascension classes: Barbarian, Knight of Xoroth,
-- Cultist, Starcaller, Reaper and Runemaster.
--
-- Of those the chain opens to the plate wearers - Knight of Xoroth (17), Cultist (25) and
-- Reaper (30) - plus Barbarian (12), whose Body Builder passive converts Strength to attack power
-- and gives it a real Strength build to spend the axe on.
--
-- Starcaller (26) is deliberately left out despite wearing plate and holding the proficiency, and
-- Runemaster (32) is left out as a leather class. Guardian (18), Sun Cleric (27) and Primalist (31)
-- wear plate but have no two-handed axe proficiency, so the reward would not be equippable.
--
-- 536870947 = 0x20000023 -> Warrior, Paladin, Death Knight, Reaper
-- 553715747 = 0x21010823 -> those, minus nothing, plus Barbarian, Knight of Xoroth, Cultist
UPDATE `quest_template_addon` SET `AllowableClasses` = 553715747
WHERE `ID` IN (24545, 24743, 24547, 24749, 24756, 24757, 24548, 24549, 24748)
  AND `AllowableClasses` = 536870947;

-- The axe, the Frostmourne the Darion exchange hands back for it, and the Shadow's Edge the chain
-- builds it from all have to agree; otherwise the chain completes into an item the character cannot
-- equip, or the exchange returns one.
UPDATE `item_template` SET `AllowableClass` = 553715747 WHERE `entry` IN (49623, 33350);

-- Shadow's Edge shipped as -1501, every class except the seven WotLK ones that cannot wield it,
-- which silently included all twenty-one custom classes. Bring it in line with the chain that
-- awards it.
UPDATE `item_template` SET `AllowableClass` = 553715747 WHERE `entry` = 49888;
