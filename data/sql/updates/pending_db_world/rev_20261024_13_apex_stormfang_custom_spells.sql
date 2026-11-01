-- Apex Bounty: The Stormfang -- custom boss spells and visuals
--
-- These are boss-only custom rows, not native spell reuse:
--   1004101  Stormfang Rake            -> bleed + 50% healing cut + 50% armor shred
--   1004102  Stormfang Chain Lightning  -> chain damage
--   1004103  Stormfang Lightning Bolt  -> damage + 4 s stun
--
-- They use three custom SpellVisual rows (99001-99003). The lightning rows
-- use the existing attack-animation kit 532 and LightningBolt Missile 157,
-- attached at attachment point 7 (mouth). Rake uses the existing Rake impact
-- kit 220. The custom Spell rows and SpellVisual rows are streamed to the
-- client by AscensionCompat (0x92A and 0x92C).

START TRANSACTION;

DELETE FROM `spell_dbc` WHERE `ID` IN (1004101, 1004102, 1004103);
DELETE FROM `spellvisual_dbc` WHERE `ID` IN (99001, 99002, 99003);

INSERT INTO `spell_dbc`
(`ID`,`Attributes`,`CastingTimeIndex`,`MaxLevel`,`BaseLevel`,`SpellLevel`,`DurationIndex`,`RangeIndex`,
 `Effect_1`,`Effect_2`,`Effect_3`,
 `EffectDieSides_1`,`EffectDieSides_2`,`EffectDieSides_3`,
 `EffectBasePoints_1`,`EffectBasePoints_2`,`EffectBasePoints_3`,
 `ImplicitTargetA_1`,`ImplicitTargetA_2`,`ImplicitTargetA_3`,
 `EffectAura_1`,`EffectAura_2`,`EffectAura_3`,
 `EffectAuraPeriod_1`,`EffectAuraPeriod_2`,`EffectAuraPeriod_3`,
 `EffectChainTargets_1`,`EffectChainTargets_2`,`EffectChainTargets_3`,
 `EffectChainAmplitude_1`,`EffectChainAmplitude_2`,`EffectChainAmplitude_3`,
 `SpellVisualID_1`,`SpellIconID`,`SpellPriority`,
 `Name_Lang_enUS`,`Name_Lang_Mask`,`NameSubtext_Lang_enUS`,
 `Description_Lang_enUS`,`Description_Lang_Mask`,
 `AuraDescription_Lang_enUS`,`AuraDescription_Lang_Mask`,
 `SchoolMask`,`SpellMissileID`,`SpellDifficultyID`)
VALUES
-- Rake: 30 s bleed, 50% healing reduction, 50% armor reduction.
(1004101, 65536, 1, 60, 60, 60, 9, 2,
 6, 6, 6,
 1, 0, 0,
 100, -50, -50,
 6, 6, 6,
 3, 118, 101,
 2000, 0, 0,
 0, 0, 0,
 0, 0, 0,
 99001, 494, 0,
 'Stormfang Rake', 0, 'Apex Bounty',
 'Rends the target, causing bleeding, reducing healing received by 50%, and shredding 50% of armor.', 0,
 'Bleeding. Healing reduced by 50%. Armor reduced by 50%.', 0,
 1, 0, 0),
-- Chain Lightning: 3-target chain, instant.
(1004102, 65536, 1, 60, 60, 60, 0, 4,
 2, 0, 0,
 1, 0, 0,
 800, 0, 0,
 6, 0, 0,
 0, 0, 0,
 0, 0, 0,
 3, 0, 0,
 0.6, 0, 0,
 99002, 165, 0,
 'Stormfang Chain Lightning', 0, 'Apex Bounty',
 'Hurls a bolt of lightning that arcs to nearby enemies.', 0,
 'Struck by Stormfang lightning.', 0,
 8, 0, 0),
-- Lightning Bolt: damage plus a 4 s stun.
(1004103, 65536, 1, 60, 60, 60, 35, 4,
 2, 6, 0,
 1, 0, 0,
 600, 0, 0,
 6, 6, 0,
 0, 12, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 99003, 62, 0,
 'Stormfang Lightning Bolt', 0, 'Apex Bounty',
 'Blasts an enemy with lightning and stuns it for 4 sec.', 0,
 'Stunned by Stormfang lightning.', 0,
 8, 0, 0);

INSERT INTO `spellvisual_dbc`
(`ID`,`PrecastKit`,`CastKit`,`ImpactKit`,`StateKit`,`StateDoneKit`,`ChannelKit`,
 `HasMissile`,`MissileModel`,`MissilePathType`,`MissileDestinationAttachment`,`MissileSound`,
 `AnimEventSoundID`,`Flags`,`CasterImpactKit`,`TargetImpactKit`,`MissileAttachment`,
 `MissileFollowGroundHeight`,`MissileFollowGroundDropSpeed`,`MissileFollowGroundApproach`,
 `MissileFollowGroundFlags`,`MissileMotion`,`MissileTargetingKit`,`InstantAreaKit`,
 `ImpactAreaKit`,`PersistentAreaKit`,`MissileCastOffsetX`,`MissileCastOffsetY`,`MissileCastOffsetZ`,
 `MissileImpactOffsetX`,`MissileImpactOffsetY`,`MissileImpactOffsetZ`)
VALUES
-- Rake: attack animation only; existing Rake impact kit.
(99001, 0, 532, 220, 0, 0, 0,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0,
 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 0.0),
-- Chain Lightning: attack animation, missile from attachment 7 (mouth).
(99002, 0, 532, 283, 0, 0, 0,
 1, 157, 0, 1, 3087,
 0, 1, 0, 0, 7,
 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 0.0),
-- Lightning Bolt: attack animation, missile from attachment 7 (mouth).
(99003, 0, 532, 283, 0, 0, 0,
 1, 157, 0, 1, 3087,
 0, 1, 0, 0, 7,
 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0.0, 0.0, 0.0,
 0.0, 0.0, 0.0);

-- Remove the temporary native-aura rows from the previous pass.
DELETE FROM `smart_scripts`
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `id` IN (17, 18, 19, 47, 48, 49, 61, 62, 63);

-- All three boss attacks now use boss-only custom spells.
UPDATE `smart_scripts`
   SET `action_param1` = 1004101,
       `target_type` = 2,
       `target_param1` = 0,
       `target_param2` = 0,
       `comment` = 'Stormfang - Rake (tank; custom)'
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 9904;

UPDATE `smart_scripts`
   SET `action_param1` = 1004102,
       `comment` = 'Stormfang - Chain Lightning (custom)'
 WHERE `entryorguid` IN (9916201, 9916202)
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` IN (421, 59220);

UPDATE `smart_scripts`
   SET `action_param1` = 1004103,
       `comment` = 'Stormfang - Lightning Bolt (custom; 4 s stun)'
 WHERE `entryorguid` = 9916201
   AND `source_type` = 0
   AND `action_type` = 11
   AND `action_param1` = 8246;

COMMIT;
