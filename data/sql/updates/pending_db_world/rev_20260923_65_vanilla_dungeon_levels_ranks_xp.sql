-- Classic+ world data: vanilla 1.12 dungeon creature levels, patch-2.3 de-elites and per-creature kill XP
-- multipliers. Source: vmangos world, final 1.12 rows (patch <= 10). A value changes only where the current
-- world still carries stock AzerothCore data for it, the creature keeps its vanilla ID and name, and its level
-- is 1-63; Naxxramas/Onyxia (WotLK 80+) and creatures with difficulty entries are left alone. Creatures whose
-- Ascension live health (rev_20260919_21) is normal-mob health stay normal, and no HealthModifier from that
-- file is changed.

-- Dungeon entry levels: Shadowfang Keep, Razorfen Kraul and Blackfathom Deeps (vanilla areatrigger levels).
UPDATE `dungeon_access_template` SET `min_level` = 10 WHERE `id` = 1; -- Shadowfang Keep (was 14)
UPDATE `dungeon_access_template` SET `min_level` = 15 WHERE `id` = 5; -- Razorfen Kraul (was 17)
UPDATE `dungeon_access_template` SET `min_level` = 10 WHERE `id` = 6; -- Blackfathom Deeps (was 19)

-- Creatures of the 19 vanilla 5-man dungeons back to their 1.12 levels, which patch 2.3 lowered by 1-7.
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20 WHERE `entry` = 636; -- Defias Blackguard
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 21 WHERE `entry` = 639; -- Edwin VanCleef
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 26 WHERE `entry` = 1663; -- Dextren Ward
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 27 WHERE `entry` = 1666; -- Kam Deepfury
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24 WHERE `entry` = 1706; -- Defias Prisoner
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24 WHERE `entry` = 1707; -- Defias Captive
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 25 WHERE `entry` = 1708; -- Defias Inmate
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 25 WHERE `entry` = 1711; -- Defias Convict
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 26 WHERE `entry` = 1715; -- Defias Insurgent
UPDATE `creature_template` SET `minlevel` = 29, `maxlevel` = 29 WHERE `entry` = 1716; -- Bazil Thredd
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 28 WHERE `entry` = 1717; -- Hamhock
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 26 WHERE `entry` = 1720; -- Bruegal Ironknuckle
UPDATE `creature_template` SET `minlevel` = 16, `maxlevel` = 17 WHERE `entry` = 1725; -- Defias Watchman
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20 WHERE `entry` = 1732; -- Defias Squallshaper
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 25 WHERE `entry` = 2529; -- Son of Arugal
UPDATE `creature_template` SET `minlevel` = 47, `maxlevel` = 47 WHERE `entry` = 2748; -- Archaedas
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 21 WHERE `entry` = 3670; -- Lord Pythas
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 21 WHERE `entry` = 3673; -- Lord Serpentis
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 21 WHERE `entry` = 3674; -- Skum
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20 WHERE `entry` = 3840; -- Druid of the Fang
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20 WHERE `entry` = 3853; -- Shadowfang Moonwalker
UPDATE `creature_template` SET `minlevel` = 20, `maxlevel` = 21 WHERE `entry` = 3854; -- Shadowfang Wolfguard
UPDATE `creature_template` SET `minlevel` = 20, `maxlevel` = 21 WHERE `entry` = 3855; -- Shadowfang Darksoul
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 22 WHERE `entry` = 3857; -- Shadowfang Glutton
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24 WHERE `entry` = 3859; -- Shadowfang Ragetooth
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 25 WHERE `entry` = 3863; -- Lupine Horror
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20 WHERE `entry` = 3864; -- Fel Steed
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 23 WHERE `entry` = 3866; -- Vile Bat
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24 WHERE `entry` = 3868; -- Blood Seeker
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 25 WHERE `entry` = 3872; -- Deathsworn Captain
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24 WHERE `entry` = 3873; -- Tormented Officer
UPDATE `creature_template` SET `minlevel` = 20, `maxlevel` = 21 WHERE `entry` = 3875; -- Haunted Servitor
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 22 WHERE `entry` = 3877; -- Wailing Guardsman
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 22 WHERE `entry` = 3886; -- Razorclaw the Butcher
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 24 WHERE `entry` = 3887; -- Baron Silverlaine
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 25 WHERE `entry` = 3927; -- Wolf Master Nandos
UPDATE `creature_template` SET `minlevel` = 40, `maxlevel` = 40 WHERE `entry` = 3975; -- Herod
UPDATE `creature_template` SET `minlevel` = 42, `maxlevel` = 42 WHERE `entry` = 3976; -- Scarlet Commander Mograine
UPDATE `creature_template` SET `minlevel` = 42, `maxlevel` = 42 WHERE `entry` = 3977; -- High Inquisitor Whitemane
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 25 WHERE `entry` = 4274; -- Fenrus the Devourer
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 26 WHERE `entry` = 4275; -- Archmage Arugal
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 24 WHERE `entry` = 4278; -- Commander Springvale
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 24 WHERE `entry` = 4279; -- Odo the Blindwatcher
UPDATE `creature_template` SET `minlevel` = 35, `maxlevel` = 36 WHERE `entry` = 4286; -- Scarlet Soldier
UPDATE `creature_template` SET `minlevel` = 34, `maxlevel` = 35 WHERE `entry` = 4288; -- Scarlet Beastmaster
UPDATE `creature_template` SET `minlevel` = 36, `maxlevel` = 37 WHERE `entry` = 4289; -- Scarlet Evoker
UPDATE `creature_template` SET `minlevel` = 36, `maxlevel` = 37 WHERE `entry` = 4290; -- Scarlet Guardsman
UPDATE `creature_template` SET `minlevel` = 34, `maxlevel` = 35 WHERE `entry` = 4291; -- Scarlet Diviner
UPDATE `creature_template` SET `minlevel` = 36, `maxlevel` = 37 WHERE `entry` = 4292; -- Scarlet Protector
UPDATE `creature_template` SET `minlevel` = 37, `maxlevel` = 38 WHERE `entry` = 4295; -- Scarlet Myrmidon
UPDATE `creature_template` SET `minlevel` = 35, `maxlevel` = 36 WHERE `entry` = 4297; -- Scarlet Conjuror
UPDATE `creature_template` SET `minlevel` = 37, `maxlevel` = 38 WHERE `entry` = 4298; -- Scarlet Defender
UPDATE `creature_template` SET `minlevel` = 34, `maxlevel` = 36 WHERE `entry` = 4299; -- Scarlet Chaplain
UPDATE `creature_template` SET `minlevel` = 39, `maxlevel` = 40 WHERE `entry` = 4302; -- Scarlet Champion
UPDATE `creature_template` SET `minlevel` = 39, `maxlevel` = 40 WHERE `entry` = 4303; -- Scarlet Abbot
UPDATE `creature_template` SET `minlevel` = 33, `maxlevel` = 34 WHERE `entry` = 4304; -- Scarlet Tracking Hound
UPDATE `creature_template` SET `minlevel` = 31, `maxlevel` = 32 WHERE `entry` = 4308; -- Unfettered Spirit
UPDATE `creature_template` SET `minlevel` = 32, `maxlevel` = 32 WHERE `entry` = 4420; -- Overlord Ramtusk
UPDATE `creature_template` SET `minlevel` = 33, `maxlevel` = 33 WHERE `entry` = 4421; -- Charlga Razorflank
UPDATE `creature_template` SET `minlevel` = 33, `maxlevel` = 33 WHERE `entry` = 4422; -- Agathelos the Raging
UPDATE `creature_template` SET `minlevel` = 30, `maxlevel` = 30 WHERE `entry` = 4424; -- Aggem Thorncurse
UPDATE `creature_template` SET `minlevel` = 32, `maxlevel` = 32 WHERE `entry` = 4425; -- Blind Hunter
UPDATE `creature_template` SET `minlevel` = 31, `maxlevel` = 31 WHERE `entry` = 4427; -- Ward Guardian
UPDATE `creature_template` SET `minlevel` = 30, `maxlevel` = 30 WHERE `entry` = 4428; -- Death Speaker Jargba
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 26 WHERE `entry` = 4436; -- Razorfen Quilguard
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 26 WHERE `entry` = 4437; -- Razorfen Warden
UPDATE `creature_template` SET `minlevel` = 29, `maxlevel` = 30 WHERE `entry` = 4438; -- Razorfen Spearhide
UPDATE `creature_template` SET `minlevel` = 29, `maxlevel` = 29 WHERE `entry` = 4440; -- Razorfen Totemic
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 28 WHERE `entry` = 4442; -- Razorfen Defender
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 28 WHERE `entry` = 4512; -- Rotting Agam'ar
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 26 WHERE `entry` = 4514; -- Raging Agam'ar
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29 WHERE `entry` = 4515; -- Death's Head Acolyte
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 28 WHERE `entry` = 4516; -- Death's Head Adept
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 27 WHERE `entry` = 4517; -- Death's Head Priest
UPDATE `creature_template` SET `minlevel` = 29, `maxlevel` = 30 WHERE `entry` = 4518; -- Death's Head Sage
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29 WHERE `entry` = 4519; -- Death's Head Seer
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 26 WHERE `entry` = 4520; -- Razorfen Geomancer
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29 WHERE `entry` = 4522; -- Razorfen Dustweaver
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 28 WHERE `entry` = 4523; -- Razorfen Groundshaker
UPDATE `creature_template` SET `minlevel` = 30, `maxlevel` = 31 WHERE `entry` = 4525; -- Razorfen Earthbreaker
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 26 WHERE `entry` = 4530; -- Razorfen Handler
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29 WHERE `entry` = 4531; -- Razorfen Beast Trainer
UPDATE `creature_template` SET `minlevel` = 30, `maxlevel` = 31 WHERE `entry` = 4532; -- Razorfen Beastmaster
UPDATE `creature_template` SET `minlevel` = 30, `maxlevel` = 31 WHERE `entry` = 4538; -- Kraul Bat
UPDATE `creature_template` SET `minlevel` = 32, `maxlevel` = 32 WHERE `entry` = 4539; -- Greater Kraul Bat
UPDATE `creature_template` SET `minlevel` = 35, `maxlevel` = 36 WHERE `entry` = 4540; -- Scarlet Monk
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 27 WHERE `entry` = 4541; -- Blood of Agamaggan
UPDATE `creature_template` SET `minlevel` = 34, `maxlevel` = 34 WHERE `entry` = 4543; -- Bloodmage Thalnos
UPDATE `creature_template` SET `minlevel` = 30, `maxlevel` = 31 WHERE `entry` = 4623; -- Quilguard Champion
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24 WHERE `entry` = 4798; -- Fallenroot Shadowstalker
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 25 WHERE `entry` = 4799; -- Fallenroot Hellcaller
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24 WHERE `entry` = 4805; -- Blackfathom Sea Witch
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 23 WHERE `entry` = 4807; -- Blackfathom Myrmidon
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 25 WHERE `entry` = 4809; -- Twilight Acolyte
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 26 WHERE `entry` = 4810; -- Twilight Reaver
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 26 WHERE `entry` = 4811; -- Twilight Aquamancer
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 25 WHERE `entry` = 4812; -- Twilight Loreseeker
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 27 WHERE `entry` = 4813; -- Twilight Shadowmage
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 27 WHERE `entry` = 4814; -- Twilight Elementalist
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 23 WHERE `entry` = 4815; -- Murkshallow Snapclaw
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 23 WHERE `entry` = 4818; -- Blindlight Murloc
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 25 WHERE `entry` = 4819; -- Blindlight Muckdweller
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 25 WHERE `entry` = 4820; -- Blindlight Oracle
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 23 WHERE `entry` = 4821; -- Skittering Crustacean
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24 WHERE `entry` = 4822; -- Snapping Crustacean
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 26 WHERE `entry` = 4823; -- Barbed Crustacean
UPDATE `creature_template` SET `minlevel` = 23, `maxlevel` = 24 WHERE `entry` = 4824; -- Aku'mai Fisher
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 27 WHERE `entry` = 4825; -- Aku'mai Snapjaw
UPDATE `creature_template` SET `minlevel` = 24, `maxlevel` = 25 WHERE `entry` = 4827; -- Deep Pool Threshfin
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 28 WHERE `entry` = 4829; -- Aku'mai
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 26 WHERE `entry` = 4830; -- Old Serra'kis
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 25 WHERE `entry` = 4831; -- Lady Sarevess
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 27 WHERE `entry` = 4832; -- Twilight Lord Kelris
UPDATE `creature_template` SET `minlevel` = 32, `maxlevel` = 32 WHERE `entry` = 4842; -- Earthcaller Halmgar
UPDATE `creature_template` SET `minlevel` = 39, `maxlevel` = 40 WHERE `entry` = 4847; -- Shadowforge Relic Hunter
UPDATE `creature_template` SET `minlevel` = 43, `maxlevel` = 44 WHERE `entry` = 4848; -- Shadowforge Darkcaster
UPDATE `creature_template` SET `minlevel` = 43, `maxlevel` = 44 WHERE `entry` = 4849; -- Shadowforge Archaeologist
UPDATE `creature_template` SET `minlevel` = 38, `maxlevel` = 39 WHERE `entry` = 4850; -- Stonevault Cave Lurker
UPDATE `creature_template` SET `minlevel` = 37, `maxlevel` = 38 WHERE `entry` = 4852; -- Stonevault Oracle
UPDATE `creature_template` SET `minlevel` = 43, `maxlevel` = 44 WHERE `entry` = 4853; -- Stonevault Geomancer
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 45 WHERE `entry` = 4854; -- Grimlok
UPDATE `creature_template` SET `minlevel` = 43, `maxlevel` = 44 WHERE `entry` = 4855; -- Stonevault Brawler
UPDATE `creature_template` SET `minlevel` = 46, `maxlevel` = 46 WHERE `entry` = 4857; -- Stone Keeper
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 44 WHERE `entry` = 4860; -- Stone Steward
UPDATE `creature_template` SET `minlevel` = 38, `maxlevel` = 39 WHERE `entry` = 4861; -- Shrike Bat
UPDATE `creature_template` SET `minlevel` = 39, `maxlevel` = 40 WHERE `entry` = 4863; -- Jadespine Basilisk
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 25 WHERE `entry` = 4887; -- Ghamoo-ra
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20 WHERE `entry` = 5055; -- Deviate Lasher
UPDATE `creature_template` SET `minlevel` = 20, `maxlevel` = 21 WHERE `entry` = 5056; -- Deviate Dreadfang
UPDATE `creature_template` SET `minlevel` = 20, `maxlevel` = 21 WHERE `entry` = 5058; -- Wolfguard Worg
UPDATE `creature_template` SET `minlevel` = 48, `maxlevel` = 49 WHERE `entry` = 5256; -- Atal'ai Warrior
UPDATE `creature_template` SET `minlevel` = 49, `maxlevel` = 50 WHERE `entry` = 5259; -- Atal'ai Witch Doctor
UPDATE `creature_template` SET `minlevel` = 48, `maxlevel` = 49 WHERE `entry` = 5267; -- Unliving Atal'ai
UPDATE `creature_template` SET `minlevel` = 49, `maxlevel` = 50 WHERE `entry` = 5270; -- Atal'ai Corpse Eater
UPDATE `creature_template` SET `minlevel` = 50, `maxlevel` = 51 WHERE `entry` = 5271; -- Atal'ai Deathwalker
UPDATE `creature_template` SET `minlevel` = 50, `maxlevel` = 51 WHERE `entry` = 5273; -- Atal'ai High Priest
UPDATE `creature_template` SET `minlevel` = 50, `maxlevel` = 51 WHERE `entry` = 5277; -- Nightmare Scalebane
UPDATE `creature_template` SET `minlevel` = 50, `maxlevel` = 51 WHERE `entry` = 5280; -- Nightmare Wyrmkin
UPDATE `creature_template` SET `minlevel` = 49, `maxlevel` = 50 WHERE `entry` = 5283; -- Nightmare Wanderer
UPDATE `creature_template` SET `minlevel` = 49, `maxlevel` = 50 WHERE `entry` = 5291; -- Hakkari Frostwing
UPDATE `creature_template` SET `minlevel` = 51, `maxlevel` = 51 WHERE `entry` = 5708; -- Spawn of Hakkar
UPDATE `creature_template` SET `minlevel` = 55, `maxlevel` = 55 WHERE `entry` = 5709; -- Shade of Eranikus
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 54 WHERE `entry` = 5710; -- Jammal'an the Prophet
UPDATE `creature_template` SET `minlevel` = 53, `maxlevel` = 53 WHERE `entry` = 5711; -- Ogom the Wretched
UPDATE `creature_template` SET `minlevel` = 51, `maxlevel` = 51 WHERE `entry` = 5712; -- Zolo
UPDATE `creature_template` SET `minlevel` = 51, `maxlevel` = 51 WHERE `entry` = 5713; -- Gasher
UPDATE `creature_template` SET `minlevel` = 51, `maxlevel` = 51 WHERE `entry` = 5714; -- Loro
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 52 WHERE `entry` = 5715; -- Hukku
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 52 WHERE `entry` = 5716; -- Zul'Lor
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 52 WHERE `entry` = 5717; -- Mijan
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 52 WHERE `entry` = 5719; -- Morphaz
UPDATE `creature_template` SET `minlevel` = 51, `maxlevel` = 51 WHERE `entry` = 5720; -- Weaver
UPDATE `creature_template` SET `minlevel` = 53, `maxlevel` = 53 WHERE `entry` = 5721; -- Dreamscythe
UPDATE `creature_template` SET `minlevel` = 53, `maxlevel` = 53 WHERE `entry` = 5722; -- Hazzas
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20 WHERE `entry` = 5755; -- Deviate Viper
UPDATE `creature_template` SET `minlevel` = 20, `maxlevel` = 21 WHERE `entry` = 5756; -- Deviate Venomwing
UPDATE `creature_template` SET `minlevel` = 19, `maxlevel` = 20 WHERE `entry` = 5761; -- Deviate Shambler
UPDATE `creature_template` SET `minlevel` = 21, `maxlevel` = 21 WHERE `entry` = 5775; -- Verdan the Everliving
UPDATE `creature_template` SET `minlevel` = 20, `maxlevel` = 20 WHERE `entry` = 5912; -- Deviate Faerie Dragon
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29 WHERE `entry` = 6035; -- Razorfen Stalker
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 28 WHERE `entry` = 6168; -- Roogug
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 27 WHERE `entry` = 6206; -- Caverndeep Burrower
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 27 WHERE `entry` = 6207; -- Caverndeep Ambusher
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 28 WHERE `entry` = 6211; -- Caverndeep Reaver
UPDATE `creature_template` SET `minlevel` = 32, `maxlevel` = 33 WHERE `entry` = 6212; -- Dark Iron Agent
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 28 WHERE `entry` = 6218; -- Irradiated Slime
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29 WHERE `entry` = 6219; -- Corrosive Lurker
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29 WHERE `entry` = 6220; -- Irradiated Horror
UPDATE `creature_template` SET `minlevel` = 29, `maxlevel` = 30 WHERE `entry` = 6222; -- Leprous Technician
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29 WHERE `entry` = 6223; -- Leprous Defender
UPDATE `creature_template` SET `minlevel` = 29, `maxlevel` = 30 WHERE `entry` = 6224; -- Leprous Machinesmith
UPDATE `creature_template` SET `minlevel` = 29, `maxlevel` = 30 WHERE `entry` = 6225; -- Mechano-Tank
UPDATE `creature_template` SET `minlevel` = 30, `maxlevel` = 31 WHERE `entry` = 6226; -- Mechano-Flamewalker
UPDATE `creature_template` SET `minlevel` = 31, `maxlevel` = 32 WHERE `entry` = 6227; -- Mechano-Frostwalker
UPDATE `creature_template` SET `minlevel` = 33, `maxlevel` = 33 WHERE `entry` = 6228; -- Dark Iron Ambassador
UPDATE `creature_template` SET `minlevel` = 32, `maxlevel` = 32 WHERE `entry` = 6229; -- Crowd Pummeler 9-60
UPDATE `creature_template` SET `minlevel` = 30, `maxlevel` = 31 WHERE `entry` = 6230; -- Peacekeeper Security Suit
UPDATE `creature_template` SET `minlevel` = 32, `maxlevel` = 33 WHERE `entry` = 6232; -- Arcane Nullifier X-21
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29 WHERE `entry` = 6233; -- Mechanized Sentry
UPDATE `creature_template` SET `minlevel` = 31, `maxlevel` = 32 WHERE `entry` = 6234; -- Mechanized Guardian
UPDATE `creature_template` SET `minlevel` = 32, `maxlevel` = 32 WHERE `entry` = 6235; -- Electrocutioner 6000
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 26 WHERE `entry` = 6243; -- Gelihast
UPDATE `creature_template` SET `minlevel` = 29, `maxlevel` = 30 WHERE `entry` = 6391; -- Holdout Warrior
UPDATE `creature_template` SET `minlevel` = 29, `maxlevel` = 30 WHERE `entry` = 6392; -- Holdout Medic
UPDATE `creature_template` SET `minlevel` = 29, `maxlevel` = 30 WHERE `entry` = 6407; -- Holdout Technician
UPDATE `creature_template` SET `minlevel` = 31, `maxlevel` = 33 WHERE `entry` = 6426; -- Anguished Dead
UPDATE `creature_template` SET `minlevel` = 32, `maxlevel` = 33 WHERE `entry` = 6427; -- Haunting Phantasm
UPDATE `creature_template` SET `minlevel` = 37, `maxlevel` = 37 WHERE `entry` = 6487; -- Arcanist Doan
UPDATE `creature_template` SET `minlevel` = 33, `maxlevel` = 33 WHERE `entry` = 6488; -- Fallen Champion
UPDATE `creature_template` SET `minlevel` = 33, `maxlevel` = 33 WHERE `entry` = 6489; -- Ironspine
UPDATE `creature_template` SET `minlevel` = 33, `maxlevel` = 33 WHERE `entry` = 6490; -- Azshir the Sleepless
UPDATE `creature_template` SET `minlevel` = 41, `maxlevel` = 41 WHERE `entry` = 6906; -- Baelog
UPDATE `creature_template` SET `minlevel` = 40, `maxlevel` = 40 WHERE `entry` = 6907; -- Eric "The Swift"
UPDATE `creature_template` SET `minlevel` = 40, `maxlevel` = 40 WHERE `entry` = 6908; -- Olaf
UPDATE `creature_template` SET `minlevel` = 40, `maxlevel` = 40 WHERE `entry` = 6910; -- Revelosh
UPDATE `creature_template` SET `minlevel` = 42, `maxlevel` = 43 WHERE `entry` = 7011; -- Earthen Rocksmasher
UPDATE `creature_template` SET `minlevel` = 42, `maxlevel` = 43 WHERE `entry` = 7012; -- Earthen Sculptor
UPDATE `creature_template` SET `minlevel` = 39, `maxlevel` = 40 WHERE `entry` = 7022; -- Venomlash Scorpid
UPDATE `creature_template` SET `minlevel` = 42, `maxlevel` = 42 WHERE `entry` = 7023; -- Obsidian Sentinel
UPDATE `creature_template` SET `minlevel` = 40, `maxlevel` = 41 WHERE `entry` = 7030; -- Shadowforge Geologist
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 45 WHERE `entry` = 7076; -- Earthen Guardian
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 45 WHERE `entry` = 7077; -- Earthen Hallshaper
UPDATE `creature_template` SET `minlevel` = 30, `maxlevel` = 30 WHERE `entry` = 7079; -- Viscous Fallout
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 44 WHERE `entry` = 7206; -- Ancient Stone Keeper
UPDATE `creature_template` SET `minlevel` = 40, `maxlevel` = 40 WHERE `entry` = 7228; -- Ironaya
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 46 WHERE `entry` = 7246; -- Sandfury Shadowhunter
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 46 WHERE `entry` = 7247; -- Sandfury Soul Eater
UPDATE `creature_template` SET `minlevel` = 48, `maxlevel` = 48 WHERE `entry` = 7267; -- Chief Ukorz Sandscalp
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 46 WHERE `entry` = 7268; -- Sandfury Guardian
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 46 WHERE `entry` = 7269; -- Scarab
UPDATE `creature_template` SET `minlevel` = 43, `maxlevel` = 44 WHERE `entry` = 7290; -- Shadowforge Sharpshooter
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 45 WHERE `entry` = 7291; -- Galgann Firehammer
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 45 WHERE `entry` = 7309; -- Earthen Custodian
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 45 WHERE `entry` = 7320; -- Stonevault Mauler
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 45 WHERE `entry` = 7321; -- Stonevault Flameweaver
UPDATE `creature_template` SET `minlevel` = 37, `maxlevel` = 37 WHERE `entry` = 7334; -- Battle Boar Horror
UPDATE `creature_template` SET `minlevel` = 35, `maxlevel` = 36 WHERE `entry` = 7335; -- Death's Head Geomancer
UPDATE `creature_template` SET `minlevel` = 36, `maxlevel` = 37 WHERE `entry` = 7337; -- Death's Head Necromancer
UPDATE `creature_template` SET `minlevel` = 37, `maxlevel` = 38 WHERE `entry` = 7341; -- Skeletal Frostweaver
UPDATE `creature_template` SET `minlevel` = 39, `maxlevel` = 40 WHERE `entry` = 7342; -- Skeletal Summoner
UPDATE `creature_template` SET `minlevel` = 37, `maxlevel` = 38 WHERE `entry` = 7344; -- Splinterbone Warrior
UPDATE `creature_template` SET `minlevel` = 39, `maxlevel` = 40 WHERE `entry` = 7345; -- Splinterbone Captain
UPDATE `creature_template` SET `minlevel` = 38, `maxlevel` = 39 WHERE `entry` = 7346; -- Splinterbone Centurion
UPDATE `creature_template` SET `minlevel` = 38, `maxlevel` = 39 WHERE `entry` = 7347; -- Boneflayer Ghoul
UPDATE `creature_template` SET `minlevel` = 37, `maxlevel` = 38 WHERE `entry` = 7348; -- Thorn Eater Ghoul
UPDATE `creature_template` SET `minlevel` = 37, `maxlevel` = 38 WHERE `entry` = 7352; -- Frozen Soul
UPDATE `creature_template` SET `minlevel` = 39, `maxlevel` = 40 WHERE `entry` = 7353; -- Freezing Spirit
UPDATE `creature_template` SET `minlevel` = 40, `maxlevel` = 40 WHERE `entry` = 7354; -- Ragglesnout
UPDATE `creature_template` SET `minlevel` = 39, `maxlevel` = 39 WHERE `entry` = 7357; -- Mordresh Fire Eye
UPDATE `creature_template` SET `minlevel` = 41, `maxlevel` = 41 WHERE `entry` = 7358; -- Amnennar the Coldbringer
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 45 WHERE `entry` = 7396; -- Earthen Stonebreaker
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 45 WHERE `entry` = 7397; -- Earthen Stonecarver
UPDATE `creature_template` SET `minlevel` = 42, `maxlevel` = 43 WHERE `entry` = 7405; -- Deadly Cleft Scorpid
UPDATE `creature_template` SET `minlevel` = 28, `maxlevel` = 29 WHERE `entry` = 7603; -- Leprous Assistant
UPDATE `creature_template` SET `minlevel` = 46, `maxlevel` = 46 WHERE `entry` = 7797; -- Ruuzlu
UPDATE `creature_template` SET `minlevel` = 34, `maxlevel` = 34 WHERE `entry` = 7800; -- Mekgineer Thermaplugg
UPDATE `creature_template` SET `minlevel` = 27, `maxlevel` = 27 WHERE `entry` = 7998; -- Blastmaster Emi Shortfuse
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 47 WHERE `entry` = 8095; -- Sul'lithuz Sandcrawler
UPDATE `creature_template` SET `minlevel` = 47, `maxlevel` = 47 WHERE `entry` = 8120; -- Sul'lithuz Abomination
UPDATE `creature_template` SET `minlevel` = 48, `maxlevel` = 48 WHERE `entry` = 8127; -- Antu'sul
UPDATE `creature_template` SET `minlevel` = 49, `maxlevel` = 50 WHERE `entry` = 8319; -- Nightmare Whelp
UPDATE `creature_template` SET `minlevel` = 47, `maxlevel` = 49 WHERE `entry` = 8384; -- Deep Lurker
UPDATE `creature_template` SET `minlevel` = 40, `maxlevel` = 40 WHERE `entry` = 8567; -- Glutton
UPDATE `creature_template` SET `minlevel` = 50, `maxlevel` = 50 WHERE `entry` = 8580; -- Atal'alarion
UPDATE `creature_template` SET `minlevel` = 51, `maxlevel` = 52 WHERE `entry` = 8892; -- Anvilrage Footman
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 53 WHERE `entry` = 8893; -- Anvilrage Soldier
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 53 WHERE `entry` = 8894; -- Anvilrage Medic
UPDATE `creature_template` SET `minlevel` = 53, `maxlevel` = 54 WHERE `entry` = 8895; -- Anvilrage Officer
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 54 WHERE `entry` = 8896; -- Shadowforge Peasant
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 54 WHERE `entry` = 8897; -- Doomforge Craftsman
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 55 WHERE `entry` = 8898; -- Anvilrage Marshal
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 55 WHERE `entry` = 8899; -- Doomforge Dragoon
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 55 WHERE `entry` = 8900; -- Doomforge Arcanasmith
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 55 WHERE `entry` = 8901; -- Anvilrage Reservist
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 56 WHERE `entry` = 8902; -- Shadowforge Citizen
UPDATE `creature_template` SET `minlevel` = 55, `maxlevel` = 56 WHERE `entry` = 8903; -- Anvilrage Captain
UPDATE `creature_template` SET `minlevel` = 55, `maxlevel` = 56 WHERE `entry` = 8904; -- Shadowforge Senator
UPDATE `creature_template` SET `minlevel` = 53, `maxlevel` = 54 WHERE `entry` = 8905; -- Warbringer Construct
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 55 WHERE `entry` = 8906; -- Ragereaver Golem
UPDATE `creature_template` SET `minlevel` = 55, `maxlevel` = 56 WHERE `entry` = 8907; -- Wrath Hammer Construct
UPDATE `creature_template` SET `minlevel` = 55, `maxlevel` = 56 WHERE `entry` = 8908; -- Molten War Golem
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 54 WHERE `entry` = 8910; -- Blazing Fireguard
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 56 WHERE `entry` = 8911; -- Fireguard Destroyer
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 53 WHERE `entry` = 8913; -- Twilight Emissary
UPDATE `creature_template` SET `minlevel` = 53, `maxlevel` = 54 WHERE `entry` = 8914; -- Twilight Bodyguard
UPDATE `creature_template` SET `minlevel` = 52, `maxlevel` = 54 WHERE `entry` = 8916; -- Arena Spectator
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 56 WHERE `entry` = 8920; -- Weapon Technician
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 55 WHERE `entry` = 8922; -- Bloodhound Mastiff
UPDATE `creature_template` SET `minlevel` = 57, `maxlevel` = 57 WHERE `entry` = 8923; -- Panzor the Invincible
UPDATE `creature_template` SET `minlevel` = 58, `maxlevel` = 58 WHERE `entry` = 8929; -- Princess Moira Bronzebeard
UPDATE `creature_template` SET `minlevel` = 57, `maxlevel` = 57 WHERE `entry` = 8983; -- Golem Lord Argelmach
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 54 WHERE `entry` = 9016; -- Bael'Gar
UPDATE `creature_template` SET `minlevel` = 55, `maxlevel` = 55 WHERE `entry` = 9017; -- Lord Incendius
UPDATE `creature_template` SET `minlevel` = 59, `maxlevel` = 59 WHERE `entry` = 9019; -- Emperor Dagran Thaurissan
UPDATE `creature_template` SET `minlevel` = 57, `maxlevel` = 57 WHERE `entry` = 9033; -- General Angerforge
UPDATE `creature_template` SET `minlevel` = 57, `maxlevel` = 57 WHERE `entry` = 9039; -- Doom'rel
UPDATE `creature_template` SET `minlevel` = 56, `maxlevel` = 56 WHERE `entry` = 9041; -- Warder Stilgiss
UPDATE `creature_template` SET `minlevel` = 55, `maxlevel` = 55 WHERE `entry` = 9042; -- Verek
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 54 WHERE `entry` = 9056; -- Fineous Darkvire
UPDATE `creature_template` SET `minlevel` = 57, `maxlevel` = 57 WHERE `entry` = 9156; -- Ambassador Flamelash
UPDATE `creature_template` SET `minlevel` = 59, `maxlevel` = 59 WHERE `entry` = 9196; -- Highlord Omokk
UPDATE `creature_template` SET `minlevel` = 59, `maxlevel` = 59 WHERE `entry` = 9237; -- War Master Voone
UPDATE `creature_template` SET `minlevel` = 57, `maxlevel` = 58 WHERE `entry` = 9264; -- Firebrand Pyromancer
UPDATE `creature_template` SET `minlevel` = 55, `maxlevel` = 55 WHERE `entry` = 9677; -- Ograbisi
UPDATE `creature_template` SET `minlevel` = 56, `maxlevel` = 56 WHERE `entry` = 9678; -- Shill Dinger
UPDATE `creature_template` SET `minlevel` = 54, `maxlevel` = 54 WHERE `entry` = 9680; -- Crest Killer
UPDATE `creature_template` SET `minlevel` = 53, `maxlevel` = 53 WHERE `entry` = 9681; -- Jaz
UPDATE `creature_template` SET `minlevel` = 57, `maxlevel` = 57 WHERE `entry` = 9938; -- Magmus
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 26 WHERE `entry` = 10000; -- Arugal
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 45 WHERE `entry` = 10120; -- Vault Warder
UPDATE `creature_template` SET `minlevel` = 57, `maxlevel` = 58 WHERE `entry` = 10408; -- Rockwing Gargoyle
UPDATE `creature_template` SET `minlevel` = 13, `maxlevel` = 15 WHERE `entry` = 11321; -- Molten Elemental
UPDATE `creature_template` SET `minlevel` = 47, `maxlevel` = 48 WHERE `entry` = 11784; -- Theradrim Guardian
UPDATE `creature_template` SET `minlevel` = 46, `maxlevel` = 48 WHERE `entry` = 11789; -- Deep Borer
UPDATE `creature_template` SET `minlevel` = 43, `maxlevel` = 44 WHERE `entry` = 11790; -- Putridus Satyr
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 45 WHERE `entry` = 11791; -- Putridus Trickster
UPDATE `creature_template` SET `minlevel` = 42, `maxlevel` = 44 WHERE `entry` = 11792; -- Putridus Shadowstalker
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 46 WHERE `entry` = 11793; -- Celebrian Dryad
UPDATE `creature_template` SET `minlevel` = 51, `maxlevel` = 51 WHERE `entry` = 12201; -- Princess Theradras
UPDATE `creature_template` SET `minlevel` = 50, `maxlevel` = 50 WHERE `entry` = 12203; -- Landslide
UPDATE `creature_template` SET `minlevel` = 48, `maxlevel` = 49 WHERE `entry` = 12206; -- Primordial Behemoth
UPDATE `creature_template` SET `minlevel` = 42, `maxlevel` = 43 WHERE `entry` = 12216; -- Poison Sprite
UPDATE `creature_template` SET `minlevel` = 42, `maxlevel` = 43 WHERE `entry` = 12217; -- Corruptor
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 47 WHERE `entry` = 12218; -- Vile Larva
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 46 WHERE `entry` = 12220; -- Constrictor Vine
UPDATE `creature_template` SET `minlevel` = 46, `maxlevel` = 47 WHERE `entry` = 12221; -- Noxious Slime
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 46 WHERE `entry` = 12222; -- Creeping Sludge
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 46 WHERE `entry` = 12223; -- Cavern Lurker
UPDATE `creature_template` SET `minlevel` = 46, `maxlevel` = 47 WHERE `entry` = 12224; -- Cavern Shambler
UPDATE `creature_template` SET `minlevel` = 49, `maxlevel` = 49 WHERE `entry` = 12225; -- Celebras the Cursed
UPDATE `creature_template` SET `minlevel` = 47, `maxlevel` = 47 WHERE `entry` = 12236; -- Lord Vyletongue
UPDATE `creature_template` SET `minlevel` = 48, `maxlevel` = 48 WHERE `entry` = 12237; -- Meshlok the Harvester
UPDATE `creature_template` SET `minlevel` = 46, `maxlevel` = 46 WHERE `entry` = 12242; -- Spirit of Maraudos
UPDATE `creature_template` SET `minlevel` = 47, `maxlevel` = 47 WHERE `entry` = 12243; -- Spirit of Veng
UPDATE `creature_template` SET `minlevel` = 48, `maxlevel` = 48 WHERE `entry` = 12258; -- Razorlash
UPDATE `creature_template` SET `minlevel` = 26, `maxlevel` = 26 WHERE `entry` = 12902; -- Lorgus Jett
UPDATE `creature_template` SET `minlevel` = 43, `maxlevel` = 44 WHERE `entry` = 13141; -- Deeprot Stomper
UPDATE `creature_template` SET `minlevel` = 44, `maxlevel` = 45 WHERE `entry` = 13142; -- Deeprot Tangler
UPDATE `creature_template` SET `minlevel` = 48, `maxlevel` = 48 WHERE `entry` = 13282; -- Noxxion
UPDATE `creature_template` SET `minlevel` = 46, `maxlevel` = 48 WHERE `entry` = 13323; -- Subterranean Diemetradon
UPDATE `creature_template` SET `minlevel` = 45, `maxlevel` = 47 WHERE `entry` = 13533; -- Spewed Larva
UPDATE `creature_template` SET `minlevel` = 50, `maxlevel` = 50 WHERE `entry` = 13596; -- Rotgrip
UPDATE `creature_template` SET `minlevel` = 46, `maxlevel` = 47 WHERE `entry` = 13599; -- Stolid Snapjaw
UPDATE `creature_template` SET `minlevel` = 50, `maxlevel` = 50 WHERE `entry` = 13601; -- Tinkerer Gizlock
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 25 WHERE `entry` = 14682; -- Sever
UPDATE `creature_template` SET `minlevel` = 40, `maxlevel` = 40 WHERE `entry` = 14686; -- Lady Falther'ess

-- Vanilla elites made normal in patch 2.3: elite again, with the vanilla elite damage (vmangos
-- damage_multiplier at AzerothCore's per-level damage and the vanilla attack speed). Health stays as
-- Ascension recorded it; the two creatures Ascension has no record of get vanilla elite health.
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.75 WHERE `entry` = 314; -- Eliza
UPDATE `creature_template` SET `rank` = 1 WHERE `entry` = 397; -- Morganth
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 436; -- Blackrock Shadowcaster
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 594; -- Defias Henchman
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 619; -- Defias Conjurer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.65 WHERE `entry` = 623; -- Skeletal Miner
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 624; -- Undead Excavator
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.65 WHERE `entry` = 625; -- Undead Dynamiter
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.4 WHERE `entry` = 626; -- Foreman Thistlenettle
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.5 WHERE `entry` = 678; -- Mosh'Ogg Mauler
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.4 WHERE `entry` = 679; -- Mosh'Ogg Shaman
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.5 WHERE `entry` = 680; -- Mosh'Ogg Lord
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.2 WHERE `entry` = 709; -- Mosh'Ogg Warmonger
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.4 WHERE `entry` = 710; -- Mosh'Ogg Spellcrafter
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.9 WHERE `entry` = 728; -- Bhag'thera
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2 WHERE `entry` = 730; -- Tethis
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 871; -- Saltscale Warrior
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 873; -- Saltscale Oracle
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 875; -- Saltscale Tide Lord
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 877; -- Saltscale Forager
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.25 WHERE `entry` = 879; -- Saltscale Hunter
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1051; -- Dark Iron Dwarf
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.711 WHERE `entry` = 1052; -- Dark Iron Saboteur
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1053; -- Dark Iron Tunneler
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1054; -- Dark Iron Demolitionist
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1178; -- Mo'grosh Ogre
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1179; -- Mo'grosh Enforcer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.473 WHERE `entry` = 1180; -- Mo'grosh Brute
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1181; -- Mo'grosh Shaman
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1183; -- Mo'grosh Mystic
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1225; -- Ol' Sooty
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1364; -- Balgaras the Foul
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.702 WHERE `entry` = 1388; -- Vagash
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.5 WHERE `entry` = 1559; -- King Mukla
UPDATE `creature_template` SET `rank` = 1 WHERE `entry` = 1725; -- Defias Watchman
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1726; -- Defias Magician
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.72 WHERE `entry` = 1788; -- Skeletal Warlord
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1827; -- Scarlet Sentinel
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1832; -- Scarlet Magus
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1834; -- Scarlet Paladin
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.651 WHERE `entry` = 1891; -- Pyrewood Watcher
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.001 WHERE `entry` = 1892; -- Moonrage Watcher
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1893; -- Moonrage Sentry
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.6 WHERE `entry` = 1894; -- Pyrewood Sentry
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1895; -- Pyrewood Elder
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 1896; -- Moonrage Elder
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4.4 WHERE `entry` = 1947; -- Thule Ravenclaw
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2 WHERE `entry` = 2091; -- Chieftain Nek'rosh
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 2106; -- Apothecary Berard
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.3 WHERE `entry` = 2257; -- Mug'thol
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.1 WHERE `entry` = 2420; -- Targ
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2 WHERE `entry` = 2421; -- Muckrake
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.9 WHERE `entry` = 2422; -- Glommus
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 2558; -- Witherbark Berserker
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.75 WHERE `entry` = 2569; -- Boulderfist Mauler
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.9 WHERE `entry` = 2570; -- Boulderfist Shaman
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.1 WHERE `entry` = 2571; -- Boulderfist Lord
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 2583; -- Stromgarde Troll Hunter
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.9 WHERE `entry` = 2584; -- Stromgarde Defender
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2 WHERE `entry` = 2585; -- Stromgarde Vindicator
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 2588; -- Syndicate Prowler
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 2590; -- Syndicate Conjuror
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 2591; -- Syndicate Magus
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.65 WHERE `entry` = 2597; -- Lord Falconcrest
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.4 WHERE `entry` = 2599; -- Otto
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.5 WHERE `entry` = 2607; -- Prince Galen Trollbane
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.15 WHERE `entry` = 2611; -- Fozruk
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.8 WHERE `entry` = 2612; -- Lieutenant Valorcall
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.5 WHERE `entry` = 2635; -- Elder Saltwater Crocolisk
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.7 WHERE `entry` = 2641; -- Vilebranch Headhunter
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.8 WHERE `entry` = 2642; -- Vilebranch Shadowcaster
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.81 WHERE `entry` = 2643; -- Vilebranch Berserker
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.91 WHERE `entry` = 2644; -- Vilebranch Hideskinner
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.9 WHERE `entry` = 2645; -- Vilebranch Shadow Hunter
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3 WHERE `entry` = 2646; -- Vilebranch Blood Drinker
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.225 WHERE `entry` = 2647; -- Vilebranch Soul Eater
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.1 WHERE `entry` = 2648; -- Vilebranch Aman'zasi Guard
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.1 WHERE `entry` = 2681; -- Vilebranch Raiding Wolf
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 2738; -- Stromgarde Cavalryman
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.65 WHERE `entry` = 2757; -- Blacklash
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.35 WHERE `entry` = 2759; -- Hematus
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 2773; -- Or'Kalar
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.1 WHERE `entry` = 2780; -- Caretaker Nevlin
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.1 WHERE `entry` = 2781; -- Caretaker Weston
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.1 WHERE `entry` = 2782; -- Caretaker Alaric
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2 WHERE `entry` = 2783; -- Marez Cowl
-- Summoned Guardian
UPDATE `creature_template` SET `rank` = 1, `HealthModifier` = 3, `DamageModifier` = 1.8 WHERE `entry` = 2794;
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2 WHERE `entry` = 2892; -- Stonevault Seer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.8 WHERE `entry` = 2932; -- Magregan Deepshadow
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.6 WHERE `entry` = 3528; -- Pyrewood Armorer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 3529; -- Moonrage Armorer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 3630; -- Deviate Coiler
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 3631; -- Deviate Stinglash
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 3632; -- Deviate Creeper
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 3633; -- Deviate Slayer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 3634; -- Deviate Stalker
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 3638; -- Devouring Ectoplasm
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 3641; -- Deviate Lurker
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 3655; -- Mad Magglish
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.715 WHERE `entry` = 4050; -- Cenarion Caretaker
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4052; -- Cenarion Druid
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4056; -- Mirkfallon Keeper
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4061; -- Mirkfallon Dryad
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4064; -- Blackrock Scout
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4065; -- Blackrock Sentry
UPDATE `creature_template` SET `rank` = 1 WHERE `entry` = 4282; -- Scarlet Magician
UPDATE `creature_template` SET `rank` = 1 WHERE `entry` = 4284; -- Scarlet Augur
UPDATE `creature_template` SET `rank` = 1 WHERE `entry` = 4285; -- Scarlet Disciple
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4409; -- Gatekeeper Kordurus
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.6 WHERE `entry` = 4465; -- Vilebranch Warrior
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.81 WHERE `entry` = 4468; -- Jade Sludge
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.6 WHERE `entry` = 4469; -- Emerald Ooze
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4788; -- Fallenroot Satyr
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4789; -- Fallenroot Rogue
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4802; -- Blackfathom Tide Priestess
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4803; -- Blackfathom Oracle
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.332 WHERE `entry` = 4844; -- Shadowforge Surveyor
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4845; -- Shadowforge Ruffian
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4846; -- Shadowforge Digger
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.85 WHERE `entry` = 4851; -- Stonevault Rockchewer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 4856; -- Stonevault Cave Hunter
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.8 WHERE `entry` = 4872; -- Obsidian Golem
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.6 WHERE `entry` = 5224; -- Murk Slitherer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.65 WHERE `entry` = 5235; -- Fungal Ooze
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.6 WHERE `entry` = 5243; -- Cursed Atal'ai
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.6 WHERE `entry` = 5261; -- Enthralled Atal'ai
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.7 WHERE `entry` = 5263; -- Mummified Atal'ai
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.7 WHERE `entry` = 5269; -- Atal'ai Priest
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.8 WHERE `entry` = 5401; -- Kazkaz the Unholy
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.083 WHERE `entry` = 5402; -- Khan Hratha
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.3 WHERE `entry` = 5645; -- Sandfury Hideskinner
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.4 WHERE `entry` = 5646; -- Sandfury Axe Thrower
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.881 WHERE `entry` = 5647; -- Sandfury Firecaller
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.76 WHERE `entry` = 5833; -- Margol the Rager
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.8 WHERE `entry` = 5860; -- Twilight Dark Shaman
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.91 WHERE `entry` = 5861; -- Twilight Fire Guard
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3 WHERE `entry` = 5862; -- Twilight Geomancer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 6132; -- Razorfen Servitor
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2 WHERE `entry` = 6208; -- Caverndeep Invader
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.298 WHERE `entry` = 6213; -- Irradiated Invader
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 6231; -- Techbot
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.2 WHERE `entry` = 6669; -- The Threshwackonator 4100
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2 WHERE `entry` = 6733; -- Stonevault Basher
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.464 WHERE `entry` = 7040; -- Black Dragonspawn
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.4 WHERE `entry` = 7041; -- Black Wyrmkin
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.862 WHERE `entry` = 7042; -- Flamescale Dragonspawn
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.85 WHERE `entry` = 7043; -- Flamescale Wyrmkin
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.5 WHERE `entry` = 7044; -- Black Drake
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.6 WHERE `entry` = 7045; -- Scalding Drake
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.35 WHERE `entry` = 7046; -- Searscale Drake
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.3 WHERE `entry` = 7053; -- Klaven Mortwake
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.3 WHERE `entry` = 7136; -- Infernal Sentry
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.5 WHERE `entry` = 7728; -- Kirith the Damned
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.176 WHERE `entry` = 7872; -- Death's Head Cultist
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 7873; -- Razorfen Battleguard
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.176 WHERE `entry` = 7874; -- Razorfen Thornweaver
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.81 WHERE `entry` = 7977; -- Gammerita
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4 WHERE `entry` = 7995; -- Vile Priestess Hexx
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.95 WHERE `entry` = 7996; -- Qiaga the Keeper
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.75 WHERE `entry` = 8075; -- Edana Hatetalon
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4.5 WHERE `entry` = 8400; -- Obsidion
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.1 WHERE `entry` = 8419; -- Twilight Idolater
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.81 WHERE `entry` = 8447; -- Clunk
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 8518; -- Rynthariel the Keymaster
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.95 WHERE `entry` = 8636; -- Morta'gya the Keeper
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.4 WHERE `entry` = 9043; -- Scarshield Grunt
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.4 WHERE `entry` = 9044; -- Scarshield Sentry
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.35 WHERE `entry` = 9461; -- Frenzied Black Drake
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.45 WHERE `entry` = 10608; -- Scarlet Priest
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4 WHERE `entry` = 10737; -- Shy-Rotam
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.5 WHERE `entry` = 10738; -- High Chief Winterfall
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.95 WHERE `entry` = 10802; -- Hitah'ya the Keeper
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4 WHERE `entry` = 10806; -- Ursius
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.8 WHERE `entry` = 10807; -- Brumeran
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.711 WHERE `entry` = 10882; -- Arikara
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.4 WHERE `entry` = 11440; -- Gordok Enforcer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.4 WHERE `entry` = 11442; -- Gordok Mauler
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.3 WHERE `entry` = 11443; -- Gordok Ogre-Mage
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.501 WHERE `entry` = 11698; -- Hive'Ashi Stinger
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.601 WHERE `entry` = 11721; -- Hive'Ashi Worker
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.6 WHERE `entry` = 11722; -- Hive'Ashi Defender
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4.15 WHERE `entry` = 11723; -- Hive'Ashi Sandstalker
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.501 WHERE `entry` = 11724; -- Hive'Ashi Swarmer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.6 WHERE `entry` = 11725; -- Hive'Zora Waywatcher
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.5 WHERE `entry` = 11726; -- Hive'Zora Tunneler
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.4 WHERE `entry` = 11728; -- Hive'Zora Reaver
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.4 WHERE `entry` = 11729; -- Hive'Zora Hive Sister
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4.25 WHERE `entry` = 11730; -- Hive'Regal Ambusher
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 5.2 WHERE `entry` = 11731; -- Hive'Regal Burrower
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.5 WHERE `entry` = 11732; -- Hive'Regal Spitfire
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.5 WHERE `entry` = 11733; -- Hive'Regal Slavemaker
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 3.55 WHERE `entry` = 11734; -- Hive'Regal Hive Lord
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.4 WHERE `entry` = 11777; -- Shadowshard Rumbler
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.5 WHERE `entry` = 11778; -- Shadowshard Smasher
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.3 WHERE `entry` = 11781; -- Ambershard Crusher
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.4 WHERE `entry` = 11782; -- Ambershard Destroyer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.2 WHERE `entry` = 11785; -- Ambereye Basilisk
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.35 WHERE `entry` = 11786; -- Ambereye Reaver
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.5 WHERE `entry` = 11787; -- Rock Borer
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.4 WHERE `entry` = 11788; -- Rock Worm
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 6.496 WHERE `entry` = 11896; -- Borelgore
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 5.5 WHERE `entry` = 11897; -- Duskwing
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.5 WHERE `entry` = 11920; -- Goggeroc
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 11921; -- Besseleth
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 5 WHERE `entry` = 12262; -- Ziggurat Protector
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.7 WHERE `entry` = 12579; -- Bloodfury Ripper
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.964 WHERE `entry` = 12865; -- Ambassador Malcin
-- Rogue Black Drake
UPDATE `creature_template` SET `rank` = 1, `HealthModifier` = 3, `DamageModifier` = 1.85 WHERE `entry` = 14388;
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4 WHERE `entry` = 14467; -- Kroshius
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4 WHERE `entry` = 14621; -- Overseer Maltorius
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2 WHERE `entry` = 15209; -- Crimson Templar
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.72 WHERE `entry` = 15211; -- Azure Templar
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2 WHERE `entry` = 15212; -- Hoary Templar
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 2.65 WHERE `entry` = 15215; -- Mistress Natalia Mar'alith
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4.499 WHERE `entry` = 15286; -- Xil'xix
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4.499 WHERE `entry` = 15288; -- Aluntir
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 4.499 WHERE `entry` = 15290; -- Arakis
UPDATE `creature_template` SET `rank` = 1, `DamageModifier` = 1.9 WHERE `entry` = 15307; -- Earthen Templar

-- Kill XP multipliers back to the vanilla per-creature values (vmangos xp_multiplier); the elite bonus
-- itself comes from the core rates.
UPDATE `creature_template` SET `ExperienceModifier` = 0 WHERE `entry` IN (
    1352, 2098, 2442, 2848, 3444, 3663, 4166, 4484, 4953, 5644, 5951, 7208, 8257, 8881, 8887, 8901, 8963, 9600, 9700,
    9701, 9778, 9779, 10016, 10017, 10582, 10685, 10716, 10940, 11776, 12296, 12298, 12383, 13016, 13017, 13160, 13533,
    14361, 14826, 14892, 15065, 15066, 15071, 15072, 16241, 16281, 16285, 16384, 16395, 16433, 16434, 16435, 16436,
    16484, 16490, 16493, 16495, 16786);
UPDATE `creature_template` SET `ExperienceModifier` = 0.1 WHERE `entry` = 12222;
UPDATE `creature_template` SET `ExperienceModifier` = 1 WHERE `entry` IN (
    622, 634, 636, 641, 657, 1706, 1707, 1708, 1711, 1715, 1729, 1731, 1732, 3636, 3637, 3640, 3678, 3840, 3849, 3850,
    3851, 3853, 3854, 3855, 3857, 3859, 3861, 3862, 3863, 3864, 3866, 3868, 3873, 3875, 3877, 3947, 4286, 4287, 4288,
    4289, 4290, 4291, 4292, 4294, 4295, 4296, 4297, 4298, 4299, 4300, 4301, 4302, 4303, 4304, 4306, 4417, 4418, 4425,
    4427, 4435, 4436, 4437, 4438, 4440, 4442, 4508, 4511, 4512, 4514, 4515, 4516, 4517, 4518, 4519, 4520, 4522, 4523,
    4525, 4530, 4531, 4532, 4538, 4539, 4540, 4541, 4623, 4798, 4799, 4805, 4807, 4809, 4810, 4811, 4812, 4813, 4814,
    4815, 4818, 4819, 4820, 4821, 4822, 4823, 4824, 4825, 4827, 4842, 4847, 4848, 4849, 4850, 4852, 4853, 4855, 4857,
    4860, 4861, 4863, 5048, 5056, 5226, 5228, 5256, 5259, 5267, 5270, 5271, 5273, 5277, 5280, 5283, 5291, 5648, 5649,
    5650, 5708, 5755, 5756, 5761, 5912, 6035, 6206, 6211, 6212, 6218, 6219, 6220, 6223, 6225, 6226, 6227, 6228, 6230,
    6232, 6233, 6234, 6329, 6392, 6407, 6426, 6427, 6488, 6489, 6490, 6907, 6908, 7022, 7030, 7246, 7247, 7268, 7274,
    7290, 7320, 7321, 7327, 7328, 7329, 7332, 7335, 7337, 7341, 7342, 7345, 7347, 7348, 7352, 7353, 7604, 7605, 7606,
    7607, 7608, 7998, 8095, 8120, 8130, 8384, 8889, 8890, 8891, 8892, 8893, 8894, 8895, 8898, 8899, 8903, 8905, 8906,
    8907, 8908, 8909, 8910, 8911, 8912, 8913, 8914, 8923, 8982, 9020, 9021, 9022, 9023, 9034, 9035, 9036, 9037, 9038,
    9039, 9040, 9045, 9096, 9097, 9098, 9197, 9198, 9199, 9200, 9201, 9216, 9217, 9218, 9219, 9239, 9240, 9241, 9257,
    9258, 9259, 9260, 9261, 9262, 9263, 9264, 9265, 9266, 9267, 9268, 9269, 9500, 9541, 9554, 9583, 9596, 9677, 9678,
    9679, 9680, 9681, 9692, 9693, 9716, 9717, 9718, 9817, 9818, 9819, 10000, 10043, 10080, 10081, 10082, 10083, 10120,
    10162, 10257, 10263, 10299, 10317, 10318, 10319, 10366, 10371, 10372, 10374, 10376, 10381, 10382, 10384, 10385,
    10398, 10400, 10405, 10406, 10407, 10408, 10409, 10412, 10413, 10414, 10416, 10417, 10418, 10419, 10420, 10421,
    10422, 10423, 10424, 10425, 10426, 10447, 10463, 10464, 10469, 10470, 10471, 10472, 10475, 10476, 10477, 10478,
    10486, 10487, 10488, 10489, 10491, 10495, 10498, 10499, 10500, 10509, 10740, 10762, 10809, 10812, 10814, 10899,
    10917, 11043, 11082, 11257, 11318, 11319, 11320, 11321, 11322, 11323, 11324, 11338, 11339, 11340, 11347, 11348,
    11350, 11351, 11352, 11353, 11356, 11357, 11359, 11361, 11365, 11370, 11371, 11372, 11373, 11374, 11380, 11382,
    11441, 11444, 11445, 11446, 11448, 11450, 11451, 11452, 11453, 11454, 11455, 11456, 11457, 11458, 11459, 11461,
    11462, 11464, 11465, 11467, 11469, 11470, 11471, 11472, 11473, 11475, 11480, 11483, 11484, 11491, 11551, 11582,
    11658, 11659, 11661, 11662, 11665, 11666, 11667, 11668, 11669, 11671, 11672, 11673, 11784, 11790, 11791, 11792,
    11793, 11830, 11831, 11981, 11982, 11983, 11988, 12017, 12056, 12057, 12076, 12098, 12099, 12100, 12101, 12118,
    12119, 12206, 12207, 12219, 12220, 12221, 12223, 12224, 12237, 12242, 12243, 12259, 12264, 12435, 12457, 12458,
    12459, 12460, 12461, 12463, 12464, 12465, 12467, 12468, 12557, 13020, 13021, 13141, 13142, 13196, 13197, 13285,
    13323, 13996, 14020, 14241, 14303, 14308, 14349, 14354, 14358, 14368, 14369, 14371, 14381, 14382, 14383, 14398,
    14399, 14401, 14456, 14507, 14509, 14510, 14517, 14532, 14601, 14682, 14684, 14686, 14690, 14695, 14750, 14821,
    14825, 14834, 14861, 14880, 14882, 14883, 15042, 15043, 15067, 15111, 15229, 15230, 15233, 15235, 15236, 15240,
    15247, 15249, 15250, 15252, 15262, 15263, 15264, 15275, 15276, 15277, 15299, 15311, 15312, 15318, 15319, 15320,
    15323, 15324, 15325, 15327, 15335, 15336, 15338, 15339, 15340, 15341, 15343, 15344, 15348, 15355, 15369, 15370,
    15378, 15379, 15380, 15385, 15386, 15387, 15388, 15389, 15390, 15391, 15392, 15461, 15462, 15502, 15503, 15504,
    15505, 15509, 15510, 15511, 15516, 15543, 15544, 15589, 15727, 15963, 15984);
