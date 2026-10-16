-- Landslide channels Landslide (21808, spell mechanic Stun) on himself. Ascension's combat logs show that self-hit
-- as IMMUNE, so the channel ends at once: no Theradrim Shardlings and a stun of under 0.1 s on the group (#7004).
-- His template profile -229 lacks Stun, so here he channeled for 8 s, stunning the group and summoning Shardlings.
DELETE FROM `creature_immunities` WHERE `ID` = 12203;
INSERT INTO `creature_immunities` (`ID`, `SchoolMask`, `DispelTypeMask`, `MechanicsMask`, `Effects`, `Auras`,
`ImmuneAoE`, `ImmuneChain`, `Comment`)
SELECT 12203, `SchoolMask`, `DispelTypeMask`, `MechanicsMask` | 4096, `Effects`, `Auras`, `ImmuneAoE`, `ImmuneChain`,
'Landslide - Existing template immunities plus Stun'
FROM `creature_immunities` WHERE `ID` = -229;
UPDATE `creature_template` SET `CreatureImmunitiesId` = 12203 WHERE `entry` IN (12203, 112203, 212203);
