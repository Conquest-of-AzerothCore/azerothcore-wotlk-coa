-- Starfire Barrage's flurry casts the hunter Rapid Fire arrow spell 993772, whose SpellVisual 200233 uses
-- SpellMissileMotion 13 ("Parabola", lifts each arrow by 15% of its flight distance), so the arrows arc.
-- Replace row 200233 (used only by spell 993772) with the same row but MissileMotion 0 (straight line).
-- MissileDestinationAttachment is 1 (chest, as on the other ranged shots) instead of 2 (feet).
-- MissileAttachment stays -1 (default caster attachment), as in the original row.
DELETE FROM `spellvisual_dbc` WHERE `ID` = 200233;
INSERT INTO `spellvisual_dbc`
(`ID`, `PrecastKit`, `CastKit`, `ImpactKit`, `StateKit`, `StateDoneKit`, `ChannelKit`, `HasMissile`, `MissileModel`,
 `MissilePathType`, `MissileDestinationAttachment`, `MissileSound`, `AnimEventSoundID`, `Flags`, `CasterImpactKit`,
 `TargetImpactKit`, `MissileAttachment`, `MissileFollowGroundHeight`, `MissileFollowGroundDropSpeed`,
 `MissileFollowGroundApproach`, `MissileFollowGroundFlags`, `MissileMotion`, `MissileTargetingKit`, `InstantAreaKit`,
 `ImpactAreaKit`, `PersistentAreaKit`, `MissileCastOffsetX`, `MissileCastOffsetY`, `MissileCastOffsetZ`,
 `MissileImpactOffsetX`, `MissileImpactOffsetY`, `MissileImpactOffsetZ`)
VALUES
(200233, 0, 0, 0, 0, 0, 0, 1, 954505,
 0, 1, 57190, 0, 0, 0,
 0, -1, 0, 0,
 0, 0, 0, 0, 0,
 200306, 0, 0, 0, 0,
 0, 0, 0);
