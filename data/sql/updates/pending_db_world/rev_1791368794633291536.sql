-- Noxxion is Charm-immune in the original Ascension NPC data (db.exil.es/npc/13282).
DELETE FROM `creature_immunities` WHERE `ID` = 13282;
INSERT INTO `creature_immunities` (`ID`, `SchoolMask`, `DispelTypeMask`, `MechanicsMask`, `Effects`, `Auras`,
`ImmuneAoE`, `ImmuneChain`, `Comment`)
SELECT 13282, `SchoolMask`, `DispelTypeMask`, `MechanicsMask` | 2, `Effects`, `Auras`, `ImmuneAoE`, `ImmuneChain`,
'Noxxion - Existing template immunities plus Charm'
FROM `creature_immunities` WHERE `ID` = -66;
UPDATE `creature_template` SET `CreatureImmunitiesId` = 13282 WHERE `entry` IN (13282, 113282, 213282);
