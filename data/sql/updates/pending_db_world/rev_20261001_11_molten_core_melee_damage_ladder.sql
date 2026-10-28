-- Molten Core melee damage ladder (H1, user decision): creature_template.DamageModifier was
-- identical across Normal/Heroic/Mythic/Ascended for every MC creature (bosses and trash), so
-- melee swing damage never scaled with difficulty even though health (x1/1.44/1.88/2.32,
-- client-cache-confirmed) and boss spell "Damage Info" damage (e.g. Lucifron Shadow Bolt
-- 800/1600/2400/3200, a x1/2/3/4 ladder) already do. Direct corpus evidence for a dedicated melee
-- ratio is noisy and non-monotonic (best-covered creature, Ancient Core Hound, measured
-- 1:1.25:1.11:1.73 Normal:Heroic:Mythic:Ascended on tank-proxy swings; the cross-creature
-- Normal->Ascended median across 5 creatures with usable samples is only 1.13x, with no creature
-- reaching either the health or the spell ladder) -- see
-- .agents/plans/mc-restoration/research-H1-H2.md. No single measured ratio is defensible as "the"
-- melee ladder. This applies the already-evidenced, already-used health ladder (x1/1.44/1.88/2.32)
-- to DamageModifier instead, for internal consistency with the rest of this fork's difficulty
-- scaling, rather than inventing a separate unmeasured melee-specific constant; flagged as
-- designed, not itself a melee measurement. Normal's own DamageModifier is left unchanged -- the
-- corpus check against our own server log (Molten Giant swings, median 498, n=71) found Normal's
-- absolute output already in a plausible range next to comparable corpus trash. Entries with only
-- one creature_template row (Sacrificial Chains 92030, Sulfuron's three named disciples
-- 92031-92033 -- replace-nearest-live-creature summons with no difficulty variants) and the
-- Magmadar head creatures (80642/80643, DamageModifier=0, immune to all damage, never melee) are
-- out of scope -- there is nothing for a per-difficulty ladder to apply to.
UPDATE `creature_template` SET `DamageModifier` = 18.72 WHERE `entry` = 111502;
UPDATE `creature_template` SET `DamageModifier` = 24.44 WHERE `entry` = 211502;
UPDATE `creature_template` SET `DamageModifier` = 30.16 WHERE `entry` = 311502;
UPDATE `creature_template` SET `DamageModifier` = 21.6 WHERE `entry` = 111658;
UPDATE `creature_template` SET `DamageModifier` = 28.2 WHERE `entry` = 211658;
UPDATE `creature_template` SET `DamageModifier` = 34.8 WHERE `entry` = 311658;
UPDATE `creature_template` SET `DamageModifier` = 23.04 WHERE `entry` = 111659;
UPDATE `creature_template` SET `DamageModifier` = 30.08 WHERE `entry` = 211659;
UPDATE `creature_template` SET `DamageModifier` = 37.12 WHERE `entry` = 311659;
UPDATE `creature_template` SET `DamageModifier` = 18.72 WHERE `entry` = 111661;
UPDATE `creature_template` SET `DamageModifier` = 24.44 WHERE `entry` = 211661;
UPDATE `creature_template` SET `DamageModifier` = 30.16 WHERE `entry` = 311661;
UPDATE `creature_template` SET `DamageModifier` = 15.84 WHERE `entry` = 111662;
UPDATE `creature_template` SET `DamageModifier` = 20.68 WHERE `entry` = 211662;
UPDATE `creature_template` SET `DamageModifier` = 25.52 WHERE `entry` = 311662;
UPDATE `creature_template` SET `DamageModifier` = 17.28 WHERE `entry` = 111663;
UPDATE `creature_template` SET `DamageModifier` = 22.56 WHERE `entry` = 211663;
UPDATE `creature_template` SET `DamageModifier` = 27.84 WHERE `entry` = 311663;
UPDATE `creature_template` SET `DamageModifier` = 20.16 WHERE `entry` = 111664;
UPDATE `creature_template` SET `DamageModifier` = 26.32 WHERE `entry` = 211664;
UPDATE `creature_template` SET `DamageModifier` = 32.48 WHERE `entry` = 311664;
UPDATE `creature_template` SET `DamageModifier` = 25.92 WHERE `entry` = 111665;
UPDATE `creature_template` SET `DamageModifier` = 33.84 WHERE `entry` = 211665;
UPDATE `creature_template` SET `DamageModifier` = 41.76 WHERE `entry` = 311665;
UPDATE `creature_template` SET `DamageModifier` = 14.4 WHERE `entry` = 111666;
UPDATE `creature_template` SET `DamageModifier` = 18.8 WHERE `entry` = 211666;
UPDATE `creature_template` SET `DamageModifier` = 23.2 WHERE `entry` = 311666;
UPDATE `creature_template` SET `DamageModifier` = 14.4 WHERE `entry` = 111667;
UPDATE `creature_template` SET `DamageModifier` = 18.8 WHERE `entry` = 211667;
UPDATE `creature_template` SET `DamageModifier` = 23.2 WHERE `entry` = 311667;
UPDATE `creature_template` SET `DamageModifier` = 17.28 WHERE `entry` = 111668;
UPDATE `creature_template` SET `DamageModifier` = 22.56 WHERE `entry` = 211668;
UPDATE `creature_template` SET `DamageModifier` = 27.84 WHERE `entry` = 311668;
UPDATE `creature_template` SET `DamageModifier` = 10.8 WHERE `entry` = 111669;
UPDATE `creature_template` SET `DamageModifier` = 14.1 WHERE `entry` = 211669;
UPDATE `creature_template` SET `DamageModifier` = 17.4 WHERE `entry` = 311669;
UPDATE `creature_template` SET `DamageModifier` = 14.4 WHERE `entry` = 111671;
UPDATE `creature_template` SET `DamageModifier` = 18.8 WHERE `entry` = 211671;
UPDATE `creature_template` SET `DamageModifier` = 23.2 WHERE `entry` = 311671;
UPDATE `creature_template` SET `DamageModifier` = 20.16 WHERE `entry` = 111672;
UPDATE `creature_template` SET `DamageModifier` = 26.32 WHERE `entry` = 211672;
UPDATE `creature_template` SET `DamageModifier` = 32.48 WHERE `entry` = 311672;
UPDATE `creature_template` SET `DamageModifier` = 23.04 WHERE `entry` = 111673;
UPDATE `creature_template` SET `DamageModifier` = 30.08 WHERE `entry` = 211673;
UPDATE `creature_template` SET `DamageModifier` = 37.12 WHERE `entry` = 311673;
UPDATE `creature_template` SET `DamageModifier` = 24.48 WHERE `entry` = 111982;
UPDATE `creature_template` SET `DamageModifier` = 31.96 WHERE `entry` = 211982;
UPDATE `creature_template` SET `DamageModifier` = 39.44 WHERE `entry` = 311982;
UPDATE `creature_template` SET `DamageModifier` = 28.8 WHERE `entry` = 111988;
UPDATE `creature_template` SET `DamageModifier` = 37.6 WHERE `entry` = 211988;
UPDATE `creature_template` SET `DamageModifier` = 46.4 WHERE `entry` = 311988;
UPDATE `creature_template` SET `DamageModifier` = 20.16 WHERE `entry` = 112018;
UPDATE `creature_template` SET `DamageModifier` = 26.32 WHERE `entry` = 212018;
UPDATE `creature_template` SET `DamageModifier` = 32.48 WHERE `entry` = 312018;
UPDATE `creature_template` SET `DamageModifier` = 20.16 WHERE `entry` = 112056;
UPDATE `creature_template` SET `DamageModifier` = 26.32 WHERE `entry` = 212056;
UPDATE `creature_template` SET `DamageModifier` = 32.48 WHERE `entry` = 312056;
UPDATE `creature_template` SET `DamageModifier` = 25.92 WHERE `entry` = 112057;
UPDATE `creature_template` SET `DamageModifier` = 33.84 WHERE `entry` = 212057;
UPDATE `creature_template` SET `DamageModifier` = 41.76 WHERE `entry` = 312057;
UPDATE `creature_template` SET `DamageModifier` = 17.28 WHERE `entry` = 112076;
UPDATE `creature_template` SET `DamageModifier` = 22.56 WHERE `entry` = 212076;
UPDATE `creature_template` SET `DamageModifier` = 27.84 WHERE `entry` = 312076;
UPDATE `creature_template` SET `DamageModifier` = 23.04 WHERE `entry` = 112098;
UPDATE `creature_template` SET `DamageModifier` = 30.08 WHERE `entry` = 212098;
UPDATE `creature_template` SET `DamageModifier` = 37.12 WHERE `entry` = 312098;
UPDATE `creature_template` SET `DamageModifier` = 20.16 WHERE `entry` = 112099;
UPDATE `creature_template` SET `DamageModifier` = 26.32 WHERE `entry` = 212099;
UPDATE `creature_template` SET `DamageModifier` = 32.48 WHERE `entry` = 312099;
UPDATE `creature_template` SET `DamageModifier` = 23.04 WHERE `entry` = 112100;
UPDATE `creature_template` SET `DamageModifier` = 30.08 WHERE `entry` = 212100;
UPDATE `creature_template` SET `DamageModifier` = 37.12 WHERE `entry` = 312100;
UPDATE `creature_template` SET `DamageModifier` = 18.72 WHERE `entry` = 112101;
UPDATE `creature_template` SET `DamageModifier` = 24.44 WHERE `entry` = 212101;
UPDATE `creature_template` SET `DamageModifier` = 30.16 WHERE `entry` = 312101;
UPDATE `creature_template` SET `DamageModifier` = 23.04 WHERE `entry` = 112118;
UPDATE `creature_template` SET `DamageModifier` = 30.08 WHERE `entry` = 212118;
UPDATE `creature_template` SET `DamageModifier` = 37.12 WHERE `entry` = 312118;
UPDATE `creature_template` SET `DamageModifier` = 18.72 WHERE `entry` = 112119;
UPDATE `creature_template` SET `DamageModifier` = 24.44 WHERE `entry` = 212119;
UPDATE `creature_template` SET `DamageModifier` = 30.16 WHERE `entry` = 312119;
UPDATE `creature_template` SET `DamageModifier` = 17.28 WHERE `entry` = 112143;
UPDATE `creature_template` SET `DamageModifier` = 22.56 WHERE `entry` = 212143;
UPDATE `creature_template` SET `DamageModifier` = 27.84 WHERE `entry` = 312143;
UPDATE `creature_template` SET `DamageModifier` = 23.04 WHERE `entry` = 112259;
UPDATE `creature_template` SET `DamageModifier` = 30.08 WHERE `entry` = 212259;
UPDATE `creature_template` SET `DamageModifier` = 37.12 WHERE `entry` = 312259;
UPDATE `creature_template` SET `DamageModifier` = 23.04 WHERE `entry` = 112264;
UPDATE `creature_template` SET `DamageModifier` = 30.08 WHERE `entry` = 212264;
UPDATE `creature_template` SET `DamageModifier` = 37.12 WHERE `entry` = 312264;
UPDATE `creature_template` SET `DamageModifier` = 18.72 WHERE `entry` = 112268;
UPDATE `creature_template` SET `DamageModifier` = 24.44 WHERE `entry` = 212268;
UPDATE `creature_template` SET `DamageModifier` = 30.16 WHERE `entry` = 312268;
UPDATE `creature_template` SET `DamageModifier` = 17.28 WHERE `entry` = 192026;
UPDATE `creature_template` SET `DamageModifier` = 22.56 WHERE `entry` = 292026;
UPDATE `creature_template` SET `DamageModifier` = 27.84 WHERE `entry` = 392026;
UPDATE `creature_template` SET `DamageModifier` = 17.28 WHERE `entry` = 192027;
UPDATE `creature_template` SET `DamageModifier` = 22.56 WHERE `entry` = 292027;
UPDATE `creature_template` SET `DamageModifier` = 27.84 WHERE `entry` = 392027;
UPDATE `creature_template` SET `DamageModifier` = 17.28 WHERE `entry` = 192028;
UPDATE `creature_template` SET `DamageModifier` = 22.56 WHERE `entry` = 292028;
UPDATE `creature_template` SET `DamageModifier` = 27.84 WHERE `entry` = 392028;
