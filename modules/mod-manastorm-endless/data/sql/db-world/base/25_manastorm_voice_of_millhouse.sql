-- Voice of Millhouse Manastorm
--
-- Recovered shutdown-era Season-10 creaturecache.wdb evidence:
--   entry 80911
--   name  "Voice of Millhouse Manastorm"
--   display 10045
--   rank 0
--   client HealthModifier 0.009625
--   client ManaModifier 1.0
--   movementId 0
--
-- The cache does not expose every server-side creature_template column.
-- Therefore this file is deliberately a FALLBACK only. INSERT IGNORE
-- preserves any more complete original/imported server row already present.
--
-- Runtime behavior (non-attackable, non-selectable, passive, private
-- per-listener emitter, timed despawn) is owned by
-- ManastormVoiceOfMillhouse.cpp rather than guessed into database fields.

INSERT IGNORE INTO `creature_template`
(
    `entry`,
    `name`,
    `subname`,
    `minlevel`,
    `maxlevel`,
    `exp`,
    `faction`,
    `speed_walk`,
    `speed_run`,
    `speed_swim`,
    `speed_flight`,
    `detection_range`,
    `rank`,
    `dmgschool`,
    `DamageModifier`,
    `BaseAttackTime`,
    `RangeAttackTime`,
    `BaseVariance`,
    `RangeVariance`,
    `unit_class`,
    `unit_flags`,
    `type`,
    `AIName`,
    `MovementType`,
    `HoverHeight`,
    `HealthModifier`,
    `ManaModifier`,
    `ArmorModifier`,
    `ExperienceModifier`,
    `RegenHealth`,
    `CreatureImmunitiesId`,
    `flags_extra`,
    `ScriptName`,
    `VerifiedBuild`
)
VALUES
(
    80911,
    'Voice of Millhouse Manastorm',
    '',
    1,
    1,
    0,
    35,
    1,
    1,
    1,
    1,
    0,
    0,
    0,
    1,
    2000,
    2000,
    1,
    1,
    1,
    0,
    8,
    'NullCreatureAI',
    0,
    1,
    0.009625,
    1,
    1,
    1,
    0,
    0,
    0,
    '',
    0
);

INSERT IGNORE INTO `creature_template_model`
(
    `CreatureID`,
    `Idx`,
    `CreatureDisplayID`,
    `DisplayScale`,
    `Probability`,
    `VerifiedBuild`
)
VALUES
(
    80911,
    0,
    10045,
    1,
    1,
    0
);
