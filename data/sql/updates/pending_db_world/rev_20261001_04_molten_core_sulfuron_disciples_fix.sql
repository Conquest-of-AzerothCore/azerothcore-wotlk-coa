-- Follow-up to rev_20260930_96: Sulfuron's four disciples as static spawns, knockback/pull
-- immunity and a corrected CC-immunity set (see diag-G2.md item 5).
--
-- 1. Three of Sulfuron's four static Flamewaker Priest spawns (creature.sql guids 56678/56679/
--    56681/56682, all entry 11662, around x594-613/y-1177..-1179) become the named disciples
--    directly, so the room shows four distinct names/abilities from the moment it loads instead
--    of a mid-fight swap driven by coa_boss_summon (now removed for entry 12098 by rev_96's own
--    second correction). Guid 56678 stays Corvus the Nimble (11662), untouched.
UPDATE `creature` SET `id` = 92031 WHERE `guid` = 56679;
UPDATE `creature` SET `id` = 92032 WHERE `guid` = 56681;
UPDATE `creature` SET `id` = 92033 WHERE `guid` = 56682;

-- 2. Knockback/pull immunity, matching the flag already given to every other MC trash/add family
--    in rev_20260930_93; Corvus (11662 and its difficulty variants) never received it either.
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x40000000 WHERE `entry` IN (11662, 111662, 211662, 311662, 92031, 92032, 92033);

-- 3. CC immunity: the corpus shows Corvus (CreatureImmunitiesId -254, the shared "stunned no
--    silence allowed" boss-add mask minus two mechanics -- see below) IMMUNE to every stun
--    attempt logged against it, while Hammer of the Law's Silence lands on all four adds
--    including Corvus. The disciples (CreatureImmunitiesId 0) currently have no CC immunity at
--    all -- an inconsistency within the same pull. 9920254 reproduces -254's own mask
--    (CHARM|DISORIENTED|DISARM|DISTRACT|FEAR|ROOT|SLEEP|SNARE|STUN|FREEZE|KNOCKOUT|SHACKLE|
--    HORROR|DAZE|SAPPED = 1225817278) with SILENCE removed (corpus: it lands) and POLYMORPH/
--    BANISH removed (per the task's own "could only be sheeped/banished by certain classes" --
--    i.e. possible, not blanket-immune); -254 itself is a shared curated set used by other
--    creatures and is not edited in place, per the SQL guidelines. All four adds now share this
--    new set instead of Corvus's own -254 / the disciples' previous 0.
DELETE FROM `creature_immunities` WHERE `ID` = 9920254;
INSERT INTO `creature_immunities` (`ID`, `SchoolMask`, `DispelTypeMask`, `MechanicsMask`, `Effects`, `Auras`, `ImmuneAoE`, `ImmuneChain`, `Comment`) VALUES
(9920254, 0, 0, 1225817278, '', '', 0, 0, 'mech=0x49107CBE (-254''s own mask minus SILENCE/POLYMORPH/BANISH): Sulfuron''s four disciples (Corvus the Nimble + Cull/Proxima/Ebon), corpus-evidenced silence landing, poly/banish left possible');
UPDATE `creature_template` SET `CreatureImmunitiesId` = 9920254 WHERE `entry` IN (11662, 111662, 211662, 311662, 92031, 92032, 92033);
