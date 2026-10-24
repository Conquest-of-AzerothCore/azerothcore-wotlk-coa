-- #8392: rev_20261004_90_coa_captured_creature_health joins the captured CoA values on `entry` only. Where CoA uses an
-- entry number for another creature, that creature's HealthModifier lands here (e.g. Crystal Handler (1) 4 -> 1000).
-- Put such rows back to the AzerothCore value from data/sql/base/db_world/creature_template.sql and set three single
-- values. Every UPDATE changes a row only while it still holds the value the migration wrote.

-- Difficulty variants (difficulty_entry_1/2/3 targets) whose CoA row is another creature
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 29247 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Naxxramas Cultist (1); CoA row: Flesh Giant Parts
UPDATE `creature_template` SET `HealthModifier` = 2 WHERE `entry` = 29267 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Corpse Scarab (1); CoA row: Shadow Trap
UPDATE `creature_template` SET `HealthModifier` = 20 WHERE `entry` = 29274 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Naxxramas Worshipper (1); CoA row: Grobbulus
UPDATE `creature_template` SET `HealthModifier` = 545 WHERE `entry` = 29278 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Maexxna (1); CoA row: Maexxna Roof Clipper
UPDATE `creature_template` SET `HealthModifier` = 1 WHERE `entry` = 29279 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Maexxna Spiderling (1); CoA row: Egg of Maexxna
UPDATE `creature_template` SET `HealthModifier` = 15 WHERE `entry` = 29388 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Fallout Slime (1); CoA row: Naxxramas Multi Task Dummy
UPDATE `creature_template` SET `HealthModifier` = 150 WHERE `entry` = 29446 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Stalagg (1); CoA row: Thaddius
UPDATE `creature_template` SET `HealthModifier` = 30 WHERE `entry` = 29941 AND `HealthModifier` BETWEEN 169.999 AND 170.001; -- Death Knight Understudy (1); CoA row: The Unholy Blade
UPDATE `creature_template` SET `HealthModifier` = 2 WHERE `entry` = 29987 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Unrelenting Trainee (1); CoA row: Harvester's Way Gate Controller
UPDATE `creature_template` SET `HealthModifier` = 500 WHERE `entry` = 30057 AND `HealthModifier` BETWEEN 1098.499 AND 1098.501; -- Guardian of Icecrown (1); CoA row: The Lich King
UPDATE `creature_template` SET `HealthModifier` = 1 WHERE `entry` = 30183 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Web Wrap (1); CoA row: Maexxna Wall Clipper
UPDATE `creature_template` SET `HealthModifier` = 2 WHERE `entry` = 30264 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Spectral Trainee (1); CoA row: Spirit Portal
UPDATE `creature_template` SET `HealthModifier` = 6 WHERE `entry` = 30424 AND `HealthModifier` BETWEEN 13.7311 AND 13.7313; -- Marauding Geist (1); CoA row: Marauding Leader
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30478 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Mage Hunter Initiate (1); CoA row: Fallen Azure Enforcer
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30516 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Enforcer (1); CoA row: Azure Skyrazor - Landing Dummy
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30517 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Scale-Binder (1); CoA row: Nexus Rift Portal Operator
UPDATE `creature_template` SET `HealthModifier` = 0.102407 WHERE `entry` = 30518 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Skyrazor (1); CoA row: Fallen Azure Skyrazor
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30519 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Crazed Mana-Surge (1); CoA row: Fallen Crazed Mana-Surge
UPDATE `creature_template` SET `HealthModifier` = 0.95 WHERE `entry` = 30520 AND `HealthModifier` BETWEEN 3.1249 AND 3.1251; -- Crazed Mana-Wraith (1); CoA row: Chaotic Mana-Wraith
UPDATE `creature_template` SET `HealthModifier` = 0.102407 WHERE `entry` = 30521 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Crazed Mana-Wyrm (1); CoA row: Fallen Crazed Mana-Wyrm
UPDATE `creature_template` SET `HealthModifier` = 10 WHERE `entry` = 30524 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Crystalline Protector (1); CoA row: Nexus Rift Portal Sender
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30525 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Crystalline Tender (1); CoA row: Nexus Rift Portal Receiver
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30526 AND `HealthModifier` BETWEEN 3.1249 AND 3.1251; -- Crystalline Keeper (1); CoA row: Frayer Seedling
UPDATE `creature_template` SET `HealthModifier` = 0.45 WHERE `entry` = 30528 AND `HealthModifier` BETWEEN 3.1249 AND 3.1251; -- Crystalline Frayer (1); CoA row: Crystalline Seedling
UPDATE `creature_template` SET `HealthModifier` = 1.25 WHERE `entry` = 30782 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- King Haldor (1); CoA row: Rocky Cliffs Spirit
UPDATE `creature_template` SET `HealthModifier` = 1.25 WHERE `entry` = 30783 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- King Haldor Visual (1); CoA row: King Haldor Spirit Dummy
UPDATE `creature_template` SET `HealthModifier` = 1.25 WHERE `entry` = 30784 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- King Ranulf (1); CoA row: Spirit of the Abyss
UPDATE `creature_template` SET `HealthModifier` = 1.25 WHERE `entry` = 30785 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- King Ranulf Visual (1); CoA row: Spirit Burst
UPDATE `creature_template` SET `HealthModifier` = 1.25 WHERE `entry` = 30786 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- King Tor (1); CoA row: Tor's Dragon Boat
UPDATE `creature_template` SET `HealthModifier` = 1.25 WHERE `entry` = 30787 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- King Tor Visual (1); CoA row: Tor's Raiders
UPDATE `creature_template` SET `HealthModifier` = 1 WHERE `entry` = 30804 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Ritual Channeler (1); CoA row: Svala Sorrowgrave
UPDATE `creature_template` SET `HealthModifier` = 2 WHERE `entry` = 30822 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Ymirjar Warrior (1); CoA row: Flame Breath Trigger Right (Skadi)
UPDATE `creature_template` SET `HealthModifier` = 2 WHERE `entry` = 30823 AND `HealthModifier` BETWEEN 3.1249 AND 3.1251; -- Ymirjar Witch Doctor (1); CoA row: Harpoon Launcher
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30901 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Inquisitor (1); CoA row: Oculus Power Core
UPDATE `creature_template` SET `HealthModifier` = 1.5 WHERE `entry` = 30902 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Ley-Whelp (1); CoA row: Massive Azure Beam
UPDATE `creature_template` SET `HealthModifier` = 10.5885 WHERE `entry` = 30903 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Ring Guardian (1); CoA row: Oculus Portal
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30904 AND `HealthModifier` BETWEEN 12.4999 AND 12.5001; -- Azure Spellbinder (1); CoA row: Azure Subjugator
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30905 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Centrifuge Construct (1); CoA row: Oculus Operator
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30906 AND `HealthModifier` BETWEEN 3.1249 AND 3.1251; -- Phantasmal Air (1); CoA row: Arcane Residue
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30907 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Phantasmal Cloudscraper (1); CoA row: Urom Menagery
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30915 AND `HealthModifier` BETWEEN 0.9999 AND 1.0001; -- Ring-Lord Conjurer (1); CoA row: Ring-Lord's Hover Disk
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 30916 AND `HealthModifier` BETWEEN 0.9999 AND 1.0001; -- Ring-Lord Sorceress (1); CoA row: Oculus Hover Disk
UPDATE `creature_template` SET `HealthModifier` = 0.5 WHERE `entry` = 30943 AND `HealthModifier` BETWEEN 3.1249 AND 3.1251; -- Slad'ran Constrictor (1); CoA row: Coil of Serpents
UPDATE `creature_template` SET `HealthModifier` = 0.625 WHERE `entry` = 30965 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Cyclone (1); CoA row: Loken
UPDATE `creature_template` SET `HealthModifier` = 3.37302 WHERE `entry` = 30969 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Molten Golem (1); CoA row: Ball Lightning
UPDATE `creature_template` SET `HealthModifier` = 1.625 WHERE `entry` = 30970 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Slag (1); CoA row: Molten Anvil Golem
UPDATE `creature_template` SET `HealthModifier` = 8 WHERE `entry` = 30973 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Stormforged Lieutenant (1); CoA row: Lightning Charger
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31178 AND `HealthModifier` BETWEEN 6.2499 AND 6.2501; -- Enraging Ghoul (1); CoA row: Captain Falric
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31179 AND `HealthModifier` BETWEEN 6.2499 AND 6.2501; -- Devouring Ghoul (1); CoA row: Captain Marwyn
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31184 AND `HealthModifier` BETWEEN 6.2499 AND 6.2501; -- Dark Necromancer (1); CoA row: Captain Luc Valonforth
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31187 AND `HealthModifier` BETWEEN 6.2499 AND 6.2501; -- Crypt Fiend (1); CoA row: Lady Lylia
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31188 AND `HealthModifier` BETWEEN 6.2499 AND 6.2501; -- Tomb Stalker (1); CoA row: Eris Havenfire
UPDATE `creature_template` SET `HealthModifier` = 10 WHERE `entry` = 31199 AND `HealthModifier` BETWEEN 3.1249 AND 3.1251; -- Patchwork Construct (1); CoA row: Footman John
UPDATE `creature_template` SET `HealthModifier` = 10 WHERE `entry` = 31200 AND `HealthModifier` BETWEEN 3.1249 AND 3.1251; -- Bile Golem (1); CoA row: Footman Wayne
UPDATE `creature_template` SET `HealthModifier` = 1.6 WHERE `entry` = 31201 AND `HealthModifier` BETWEEN 0.9999 AND 1.0001; -- Acolyte (1); CoA row: Melissa Bridenbecker
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31202 AND `HealthModifier` BETWEEN 0.3124 AND 0.3126; -- Infinite Adversary (1); CoA row: Lucas
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31203 AND `HealthModifier` BETWEEN 0.3124 AND 0.3126; -- Infinite Agent (1); CoA row: Captured Citizen
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31206 AND `HealthModifier` BETWEEN 0.3124 AND 0.3126; -- Infinite Hunter (1); CoA row: Converted Cizizen
UPDATE `creature_template` SET `HealthModifier` = 0.75 WHERE `entry` = 31207 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Ghoul Minion (1); CoA row: Mal'Ganis
UPDATE `creature_template` SET `HealthModifier` = 0.06 WHERE `entry` = 31208 AND `HealthModifier` BETWEEN 12.4999 AND 12.5001; -- Risen Zombie (1); CoA row: Infernal
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31210 AND `HealthModifier` BETWEEN 0.3124 AND 0.3126; -- Arthas (1); CoA row: Phillipp
UPDATE `creature_template` SET `HealthModifier` = 31.25 WHERE `entry` = 31211 AND `HealthModifier` BETWEEN 0.3124 AND 0.3126; -- Meathook (1); CoA row: Anja
UPDATE `creature_template` SET `HealthModifier` = 31.25 WHERE `entry` = 31212 AND `HealthModifier` BETWEEN 0.3124 AND 0.3126; -- Salramm the Fleshcrafter (1); CoA row: Kyra
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31340 AND `HealthModifier` BETWEEN 3.1249 AND 3.1251; -- Drakkari Gutripper (1); CoA row: Juvenil Drakkari Gutripper
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31343 AND `HealthModifier` BETWEEN 3.1249 AND 3.1251; -- Drakkari Scytheclaw (1); CoA row: Juvenil Drakkari Scytheclaw
UPDATE `creature_template` SET `HealthModifier` = 4 WHERE `entry` = 31344 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Crystal Handler (1); CoA row: Eye Beam
UPDATE `creature_template` SET `HealthModifier` = 2 WHERE `entry` = 31369 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Crystalline Shardling (1); CoA row: Krystallus
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31371 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Dark Rune Controller (1); CoA row: Marnak
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31372 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Dark Rune Elementalist (1); CoA row: Kaddrak
UPDATE `creature_template` SET `HealthModifier` = 10 WHERE `entry` = 31373 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Dark Rune Giant (1); CoA row: Abedneum
UPDATE `creature_template` SET `HealthModifier` = 10 WHERE `entry` = 31387 AND `HealthModifier` BETWEEN 12.4999 AND 12.5001; -- Unrelenting Construct (1); CoA row: Dark Rune Gate Guardian
UPDATE `creature_template` SET `HealthModifier` = 0.952381 WHERE `entry` = 31480 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Twisted Visage; CoA row: Herald Volazj
UPDATE `creature_template` SET `HealthModifier` = 1 WHERE `entry` = 31485 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Binder (1); CoA row: Cyanigosa
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31486 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Captain (1); CoA row: Arcane Vacuum
UPDATE `creature_template` SET `HealthModifier` = 4 WHERE `entry` = 31505 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Violet Hold Guard (1); CoA row: Violet Hold Mythic Plus
UPDATE `creature_template` SET `HealthModifier` = 25 WHERE `entry` = 31541 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Acolyte of Shadron (1); CoA row: Twilight Portal
UPDATE `creature_template` SET `HealthModifier` = 25 WHERE `entry` = 31543 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Acolyte of Vesperon (1); CoA row: Twilight Portal
UPDATE `creature_template` SET `HealthModifier` = 32 WHERE `entry` = 31560 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Mage-Lord Urom (1); CoA row: Mage-Lord Urom Vehicle
UPDATE `creature_template` SET `HealthModifier` = 0.3125 WHERE `entry` = 31585 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Animated Bones (1); CoA row: Azjol'Nerub Sinkhole
UPDATE `creature_template` SET `HealthModifier` = 0.314386 WHERE `entry` = 31586 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Anub'ar Assassin (1); CoA row: Web Door
UPDATE `creature_template` SET `HealthModifier` = 0.3125 WHERE `entry` = 31587 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Anub'ar Brood Keeper (1); CoA row: Pound Vehicle
UPDATE `creature_template` SET `HealthModifier` = 0.104058 WHERE `entry` = 31647 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Carrion Beetle (1); CoA row: Strange Portal
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31668 AND `HealthModifier` BETWEEN 6.2499 AND 6.2501; -- Dragonflayer Worker (1); CoA row: Proto-Drake Rider
UPDATE `creature_template` SET `HealthModifier` = 0.268394 WHERE `entry` = 31672 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Frost Tomb (1); CoA row: Dark Nucleus
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31675 AND `HealthModifier` BETWEEN 6.2499 AND 6.2501; -- Proto-Drake Handler (1); CoA row: Proto-Drake Rider
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31676 AND `HealthModifier` BETWEEN 12.4999 AND 12.5001; -- Proto-Drake Rider (1); CoA row: Enslaved Proto-Drake
UPDATE `creature_template` SET `HealthModifier` = 1400 WHERE `entry` = 31734 AND `HealthModifier` BETWEEN 2799.999 AND 2800.001; -- Malygos; CoA row: Malygos Loot Dummy
UPDATE `creature_template` SET `HealthModifier` = 3 WHERE `entry` = 32187 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Power Spark (1); CoA row: Malygos Dummy
UPDATE `creature_template` SET `HealthModifier` = 0.7 WHERE `entry` = 32218 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Snake Wrap (1); CoA row: Gundrak Altar Dummy
UPDATE `creature_template` SET `HealthModifier` = 60 WHERE `entry` = 32368 AND `HealthModifier` BETWEEN 129.999 AND 130.001; -- Archavon Warder (1); CoA row: Tempest Warder

-- Attackable creatures whose CoA row is another creature
UPDATE `creature_template` SET `HealthModifier` = 2.5 WHERE `entry` = 16982 AND `HealthModifier` BETWEEN 43.939899 AND 43.940099; -- Plagued Construct; CoA row: Dr. Bones the Breaker
UPDATE `creature_template` SET `HealthModifier` = 6 WHERE `entry` = 23562 AND `HealthModifier` BETWEEN 44.9999 AND 45.0001; -- Unstoppable Abomination; CoA row: Shade of Naxxramas
UPDATE `creature_template` SET `HealthModifier` = 24.5 WHERE `entry` = 25837 AND `HealthModifier` BETWEEN 1098.499 AND 1098.501; -- Shadowsword Commander; CoA row: High Commander Arynyes
UPDATE `creature_template` SET `HealthModifier` = 1 WHERE `entry` = 26829 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Frenzied Worgen; CoA row: Trophy Orb
UPDATE `creature_template` SET `HealthModifier` = 0.8 WHERE `entry` = 31007 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Binder; CoA row: Eye of Moragg
UPDATE `creature_template` SET `HealthModifier` = 0.8 WHERE `entry` = 31008 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Invader; CoA row: Eye of Moragg
UPDATE `creature_template` SET `HealthModifier` = 1 WHERE `entry` = 31009 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Spellbreaker; CoA row: Eye of Moragg
UPDATE `creature_template` SET `HealthModifier` = 1 WHERE `entry` = 31010 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Azure Mage Slayer; CoA row: Eye of Moragg
UPDATE `creature_template` SET `HealthModifier` = 2 WHERE `entry` = 31204 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Sartharion Twilight Egg; CoA row: Twilight Ghost
UPDATE `creature_template` SET `HealthModifier` = 5 WHERE `entry` = 31214 AND `HealthModifier` BETWEEN 999.999 AND 1000.001; -- Sartharion Twilight Whelp; CoA row: Twilight Portal
UPDATE `creature_template` SET `HealthModifier` = 1950 WHERE `entry` = 37037 AND `HealthModifier` BETWEEN 0.9999 AND 1.0001; -- Acanthurus; CoA row: Spawn Book Dummy

-- Single values
UPDATE `creature_template` SET `HealthModifier` = 39.1 WHERE `entry` = 17797 AND `HealthModifier` BETWEEN 2.2999 AND 2.3001; -- Hydromancer Thespia: the bare factor 2.3; the other TBC dungeon bosses in rev_20261004_90 are AzerothCore x 2.3 (17 x 2.3)
UPDATE `creature_template` SET `HealthModifier` = 130 WHERE `entry` = 34015 AND `HealthModifier` BETWEEN 49.9999 AND 50.0001; -- Tempest Warder: rev_20261004_90 has its CoA value 130 under 32368, Archavon Warder (1)
UPDATE `creature_template` SET `HealthModifier` = 1 WHERE `entry` = 11439 AND `HealthModifier` BETWEEN 15.9999 AND 16.0001; -- Illusion of Jandice Barov: rev_20260919_21 gave it the value of Jandice Barov (AzerothCore 1)
