-- Molten Core trash and their adds get the same knockback/pull immunity flag the core already
-- honors for a curated set of raid creatures (Spell::EffectKnockBack, now also
-- Spell::EffectPullTowards). Lucifron and Magmadar are bosses (isWorldBoss()/IsDungeonBoss()) and
-- are already protected by that core rule; only their non-boss adds need the flag here.
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11658; -- Molten Giant
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 111658; -- Molten Giant (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 211658; -- Molten Giant (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 311658; -- Molten Giant (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11659; -- Molten Destroyer
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 111659; -- Molten Destroyer (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 211659; -- Molten Destroyer (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 311659; -- Molten Destroyer (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11661; -- Flamewaker
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11662; -- Flamewaker Priest
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11663; -- Flamewaker Healer
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11664; -- Flamewaker Elite
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11665; -- Lava Annihilator
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 111665; -- Lava Annihilator (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 211665; -- Lava Annihilator (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 311665; -- Lava Annihilator (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11666; -- Firewalker
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 111666; -- Firewalker (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 211666; -- Firewalker (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 311666; -- Firewalker (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11667; -- Flameguard
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 111667; -- Flameguard (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 211667; -- Flameguard (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 311667; -- Flameguard (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11668; -- Firelord
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 111668; -- Firelord (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 211668; -- Firelord (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 311668; -- Firelord (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11669; -- Flame Imp
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 111669; -- Flame Imp (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 211669; -- Flame Imp (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 311669; -- Flame Imp (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11671; -- Core Hound
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11672; -- Core Rager
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 11673; -- Ancient Core Hound
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 111673; -- Ancient Core Hound (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 211673; -- Ancient Core Hound (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 311673; -- Ancient Core Hound (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 12076; -- Lava Elemental
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 112076; -- Lava Elemental (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 212076; -- Lava Elemental (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 312076; -- Lava Elemental (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 12099; -- Firesworn
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 12100; -- Lava Reaver
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 112100; -- Lava Reaver (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 212100; -- Lava Reaver (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 312100; -- Lava Reaver (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 12101; -- Lava Surger
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 112101; -- Lava Surger (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 212101; -- Lava Surger (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 312101; -- Lava Surger (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 12119; -- Flamewaker Protector
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 12143; -- Son of Flame
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 12268; -- Shadow of Lucifron
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 112268; -- Shadow of Lucifron (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 212268; -- Shadow of Lucifron (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 312268; -- Shadow of Lucifron (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 80642; -- Magmadar's Right Head
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 180642; -- Magmadar's Right Head (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 280642; -- Magmadar's Right Head (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 380642; -- Magmadar's Right Head (Ascended)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 80643; -- Magmadar's Left Head
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 180643; -- Magmadar's Left Head (Heroic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 280643; -- Magmadar's Left Head (Mythic)
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` = 380643; -- Magmadar's Left Head (Ascended)
