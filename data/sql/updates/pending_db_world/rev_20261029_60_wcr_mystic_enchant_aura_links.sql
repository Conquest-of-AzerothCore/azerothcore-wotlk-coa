-- Warcraft Reborn Mystic Enchants whose effect is a helper spell held while an aura is up (coa_mystic_enchant_aura_link):
-- Icy Slaughter's Icy Veins modifiers (Cone of Cold and Deep Freeze: no mana cost, +20% damage) and Controlled
-- Aggression's Shield Slam modifiers (25% of attack power, +3 sec cooldown, Sword and Board doubled), held with the
-- enchant itself.
DELETE FROM `coa_mystic_enchant_aura_link` WHERE `enchant_spell` IN (1180760, 1181300);
INSERT INTO `coa_mystic_enchant_aura_link` (`enchant_spell`, `aura`, `grant_spell`, `comment`) VALUES
(1180760, '1112472 1212472', 1180762, 'Icy Slaughter (enchant 1691163): under Icy Veins, Cone of Cold and Deep Freeze cost no mana and deal 20% more'),
(1181300, '1181300', 1181301, 'Controlled Aggression (enchant 1445118): Shield Slam damage and cooldown'),
(1181300, '1181300', 1181302, 'Controlled Aggression (enchant 1445118): Sword and Board chance doubled');
