-- High-Risk (PvP) 84421's spellbook text states a literal 15% experience bonus, but the High-Risk aura it
-- applies, 1004019, grants SPELL_AURA_MOD_XP_PCT with EffectBasePoints 19 + 1 = 20% and its own text reads $s1%.
-- Stream the unchanged DBC text with the number read from the aura's first effect (#9333).
DELETE FROM `coa_client_spell_description` WHERE `ID` = 84421;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(84421, 'Any death while in the open world with High-Risk Mode active will cause you to drop equipped gear, or Fel Com gold if your gear is insured, and items from your bag.\r\n\r\nEnables High-Risk Open World PvP and grants $1004019s1% increased experience for killing Creatures or Players in the Open World. You cannot use flying mounts in High-Risk.\r\n\nAllows you to loot new crafting materials, Bloodforged PvP gear, and Marks of War from the open world, and allows you to interact with Hidden Caches and Beast Nests.\r\n\r\nCan only be cast while in a rested area!', NULL);
