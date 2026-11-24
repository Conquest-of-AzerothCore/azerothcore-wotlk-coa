-- Dummy-effect systems, area "Healing" (src/server/coa/AscensionDummySystemHealing.cpp): Cloudburst Totem's release,
-- Pack Enhancement's Commands, Tree of Wrath, Radiant Flames, Dominant Word: Shield, Adorned by Light, Beacon of Divinity,
-- Holy Ground, Guardians of the Grove / Roots of the Forest, Power of the Elements, Elemental Lord, Divine Guidance and
-- Grasp of Darkness's Tentacle empowerment.

DELETE FROM `spell_script_names` WHERE `ScriptName` IN (
    'spell_dummysystem_healing_cloudburst_release', 'spell_dummysystem_healing_cloudburst_store',
    'spell_dummysystem_healing_pack_enhancement', 'spell_dummysystem_healing_pack_feral_spirit',
    'spell_dummysystem_healing_tree_of_wrath', 'spell_dummysystem_healing_tree_of_wrath_passive',
    'spell_dummysystem_healing_living_lightning_rod', 'spell_dummysystem_healing_flames_of_the_apostate',
    'spell_dummysystem_healing_dominant_word_shield', 'spell_dummysystem_healing_dominant_rapture',
    'spell_dummysystem_healing_adorned_by_light', 'spell_dummysystem_healing_beacon_of_divinity',
    'spell_dummysystem_healing_beacon_of_divinity_heal', 'spell_dummysystem_healing_holy_ground',
    'spell_dummysystem_healing_force_of_nature', 'spell_dummysystem_healing_power_of_the_elements',
    'spell_dummysystem_healing_elemental_lord', 'spell_dummysystem_healing_elemental_blast',
    'spell_dummysystem_healing_divine_guidance', 'spell_dummysystem_healing_grasp_channel',
    'spell_dummysystem_healing_grasp_tick');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Cloudburst Totem - Release recalls the totem; the store buff also keeps direct heals cast on others
(760008, 'spell_dummysystem_healing_cloudburst_release'),
(2110008, 'spell_dummysystem_healing_cloudburst_release'),
(760010, 'spell_dummysystem_healing_cloudburst_store'),
(2110010, 'spell_dummysystem_healing_cloudburst_store'),
-- Pack Enhancement (talent 277190, enchant 984626, ability set 1578906); Feral Spirit consumes the Commands
(277190, 'spell_dummysystem_healing_pack_enhancement'),
(984626, 'spell_dummysystem_healing_pack_enhancement'),
(1578906, 'spell_dummysystem_healing_pack_enhancement'),
(51533, 'spell_dummysystem_healing_pack_feral_spirit'),
(901607, 'spell_dummysystem_healing_pack_feral_spirit'),
(1151533, 'spell_dummysystem_healing_pack_feral_spirit'),
-- Tree of Wrath: Living Lightning grant, the form's passive, Living Lightning's strike on the Lightning Rod target
(86438, 'spell_dummysystem_healing_tree_of_wrath'),
(86436, 'spell_dummysystem_healing_tree_of_wrath_passive'),
(86449, 'spell_dummysystem_healing_living_lightning_rod'),
(86450, 'spell_dummysystem_healing_living_lightning_rod'),
(86451, 'spell_dummysystem_healing_living_lightning_rod'),
(86453, 'spell_dummysystem_healing_living_lightning_rod'),
(86455, 'spell_dummysystem_healing_living_lightning_rod'),
(86456, 'spell_dummysystem_healing_living_lightning_rod'),
(86457, 'spell_dummysystem_healing_living_lightning_rod'),
(86458, 'spell_dummysystem_healing_living_lightning_rod'),
-- Radiant Flames (Cauterizing Flames): Flames of the Apostate is spent by the Holy Fire that radiates
(997000, 'spell_dummysystem_healing_flames_of_the_apostate'),
-- Dominant Word: Shield (enchant 81472, ability set 1567670) and its Rapture bonus
(81472, 'spell_dummysystem_healing_dominant_word_shield'),
(1567670, 'spell_dummysystem_healing_dominant_word_shield'),
(47755, 'spell_dummysystem_healing_dominant_rapture'),
-- Adorned by Light, Beacon of Divinity
(991030, 'spell_dummysystem_healing_adorned_by_light'),
(986084, 'spell_dummysystem_healing_beacon_of_divinity'),
(986085, 'spell_dummysystem_healing_beacon_of_divinity_heal'),
-- Holy Ground (enchant 81315, talent 281788, ability set 1580965)
(81315, 'spell_dummysystem_healing_holy_ground'),
(281788, 'spell_dummysystem_healing_holy_ground'),
(1580965, 'spell_dummysystem_healing_holy_ground'),
-- Guardians of the Grove / Roots of the Forest: the treants Force of Nature summons
(33831, 'spell_dummysystem_healing_force_of_nature'),
(1133831, 'spell_dummysystem_healing_force_of_nature'),
(1233831, 'spell_dummysystem_healing_force_of_nature'),
-- Power of the Elements (ranks 1-5)
(423785, 'spell_dummysystem_healing_power_of_the_elements'),
(423822, 'spell_dummysystem_healing_power_of_the_elements'),
(423823, 'spell_dummysystem_healing_power_of_the_elements'),
(423824, 'spell_dummysystem_healing_power_of_the_elements'),
(423825, 'spell_dummysystem_healing_power_of_the_elements'),
-- Elemental Lord (enchant 990200): critical Elemental Blast / Lava Burst; Elemental Blast loses its empowerments
(990200, 'spell_dummysystem_healing_elemental_lord'),
(954807, 'spell_dummysystem_healing_elemental_blast'),
(954891, 'spell_dummysystem_healing_elemental_blast'),
(954892, 'spell_dummysystem_healing_elemental_blast'),
(954893, 'spell_dummysystem_healing_elemental_blast'),
(954894, 'spell_dummysystem_healing_elemental_blast'),
(954895, 'spell_dummysystem_healing_elemental_blast'),
(992934, 'spell_dummysystem_healing_elemental_blast'),
-- Divine Guidance
(272885, 'spell_dummysystem_healing_divine_guidance'),
-- Grasp of Darkness: the channels (and WCR's Darkness Gathering) hold Forbidden Power per Tentacle; the ticks read it
(272954, 'spell_dummysystem_healing_grasp_channel'),
(272971, 'spell_dummysystem_healing_grasp_channel'),
(272972, 'spell_dummysystem_healing_grasp_channel'),
(272973, 'spell_dummysystem_healing_grasp_channel'),
(272974, 'spell_dummysystem_healing_grasp_channel'),
(272975, 'spell_dummysystem_healing_grasp_channel'),
(272976, 'spell_dummysystem_healing_grasp_channel'),
(986248, 'spell_dummysystem_healing_grasp_channel'),
(1571356, 'spell_dummysystem_healing_grasp_channel'),
(272958, 'spell_dummysystem_healing_grasp_tick'),
(272965, 'spell_dummysystem_healing_grasp_tick'),
(272966, 'spell_dummysystem_healing_grasp_tick'),
(272967, 'spell_dummysystem_healing_grasp_tick'),
(272968, 'spell_dummysystem_healing_grasp_tick'),
(272969, 'spell_dummysystem_healing_grasp_tick'),
(272970, 'spell_dummysystem_healing_grasp_tick'),
(986251, 'spell_dummysystem_healing_grasp_tick'),
(1571357, 'spell_dummysystem_healing_grasp_tick');

-- 277190 and 272883 carried a catch-all row (every hit procced): Commands from any damage, Divine Guidance from any spell
DELETE FROM `spell_proc` WHERE `SpellId` IN (760010, 2110010, 277190, 984626, 1578906, 86436, 997000, 81472, 1567670,
    991030, 986084, 990200, 272883, 272885);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Cloudburst store buffs: the shaman's heals, direct and periodic (the script keeps what the shared store misses)
(760010, 0, 0, 0x0, 0x0, 0x0, 0x44400, 0x2, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(2110010, 0, 0, 0x0, 0x0, 0x0, 0x44400, 0x2, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Pack Enhancement: Flametongue Attack (flags[0] 0x200000), Windfury Attack (0x800000), Frostbrand Attack (0x1000000),
-- whatever damage class they carry (melee, magic or none)
(277190, 0, 11, 0x1A00000, 0x0, 0x0, 0x11010, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(984626, 0, 11, 0x1A00000, 0x0, 0x0, 0x11010, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(1578906, 0, 11, 0x1A00000, 0x0, 0x0, 0x11010, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Tree of Wrath passive: Nature spells landing (the script keeps Lightning Bolt damage and critical direct heals)
(86436, 8, 0, 0x0, 0x0, 0x0, 0x14000, 0x3, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Flames of the Apostate: Holy Fire's direct hit (flags[0] 0x100000) radiates Radiant Flames
(997000, 0, 6, 0x100000, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Dominant Word: Shield: Power Word: Shield (flags[0] 0x1) landing on an ally
(81472, 0, 6, 0x1, 0x0, 0x0, 0x4000, 0x4, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(1567670, 0, 6, 0x1, 0x0, 0x0, 0x4000, 0x4, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Adorned by Light: direct heals and Holy Shock damage (Holy Shock's heal / damage are triggered by its dummy)
(991030, 0, 0, 0x0, 0x0, 0x0, 0x14000, 0x3, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Beacon of Divinity: direct heals
(986084, 0, 0, 0x0, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Elemental Lord: critical Lava Burst (flags[1] 0x1000) or Elemental Blast (flags[2] 0x20000000)
(990200, 0, 11, 0x0, 0x1000, 0x20000000, 0x10000, 0x1, 0x2, 0x2, 0x0, 0, 0, 100, 0, 0),
-- Divine Guidance talent: Penance's damage bolt (flags[1] 0x8000); the buff: Penance's healing bolt (flags[1] 0x10000)
(272883, 0, 6, 0x0, 0x8000, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(272885, 0, 6, 0x0, 0x10000, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0);
