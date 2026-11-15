-- Huntress Shot (680220 and ranks) and the Starfire Barrage aura 803264 use SpellVisual 1475, whose
-- MissileAttachment is 0 while the other ranged-shot visuals use -1 (default caster attachment), so the arrow
-- left from above the caster's head. Replace row 1475 with the same row but MissileAttachment -1.
DELETE FROM `spellvisual_dbc` WHERE `ID` = 1475;
INSERT INTO `spellvisual_dbc`
(`ID`, `PrecastKit`, `CastKit`, `ImpactKit`, `StateKit`, `StateDoneKit`, `ChannelKit`, `HasMissile`, `MissileModel`,
 `MissilePathType`, `MissileDestinationAttachment`, `MissileSound`, `AnimEventSoundID`, `Flags`, `CasterImpactKit`,
 `TargetImpactKit`, `MissileAttachment`, `MissileFollowGroundHeight`, `MissileFollowGroundDropSpeed`,
 `MissileFollowGroundApproach`, `MissileFollowGroundFlags`, `MissileMotion`, `MissileTargetingKit`, `InstantAreaKit`,
 `ImpactAreaKit`, `PersistentAreaKit`, `MissileCastOffsetX`, `MissileCastOffsetY`, `MissileCastOffsetZ`,
 `MissileImpactOffsetX`, `MissileImpactOffsetY`, `MissileImpactOffsetZ`)
VALUES
(1475, 0, 0, 2277, 0, 0, 0, 1, 239658,
 0, 0, 0, 0, 0, 0,
 0, -1, 0, 0,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0,
 0, 0, 0);
