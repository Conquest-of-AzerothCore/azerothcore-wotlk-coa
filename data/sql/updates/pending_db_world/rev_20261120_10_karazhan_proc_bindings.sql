-- Reuse each base effect's proc conditions and rate for its existing heroic, mythic and ascended spells.
CREATE TEMPORARY TABLE `_coa_karazhan_proc_sources` (
    `base` INT NOT NULL,
    `variant` INT PRIMARY KEY
) ENGINE=InnoDB;

DELETE FROM `_coa_karazhan_proc_sources`;
INSERT INTO `_coa_karazhan_proc_sources` VALUES
(29601, 229601),
(34584, 234584),
(34586, 234586),
(34598, 234598),
(37657, 237657),
(38332, 238332),
(29601, 329601),
(34586, 334587),
(37657, 337657),
(38332, 338332),
(29601, 429601),
(34586, 434586),
(37657, 437657),
(38332, 438332),
(34584, 1334584),
(34598, 1334598);

START TRANSACTION;

DELETE FROM `spell_proc` WHERE `SpellId` IN (
    229601, 234584, 234586, 234598, 237657, 238332, 329601, 334587, 337657, 338332, 429601, 434586, 437657, 438332,
    1334584, 1334598);
INSERT INTO `spell_proc` (
    `SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
    `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
    `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT `mapping`.`variant`, `source`.`SchoolMask`, `source`.`SpellFamilyName`, `source`.`SpellFamilyMask0`,
    `source`.`SpellFamilyMask1`, `source`.`SpellFamilyMask2`, `source`.`ProcFlags`, `source`.`SpellTypeMask`,
    `source`.`SpellPhaseMask`, `source`.`HitMask`, `source`.`AttributesMask`, `source`.`DisableEffectsMask`,
    `source`.`ProcsPerMinute`, `source`.`Chance`, `source`.`Cooldown`, `source`.`Charges`
FROM `_coa_karazhan_proc_sources` AS `mapping`
JOIN `spell_proc` AS `source` ON `source`.`SpellId` = `mapping`.`base`;

DELETE FROM `spell_script_names`
WHERE `spell_id` IN (229601, 329601, 429601, 237657, 337657, 437657)
    AND `ScriptName` IN ('spell_item_pendant_of_the_violet_eye', 'spell_item_lightning_capacitor',
        'spell_item_lightning_capacitor_heroic', 'spell_item_lightning_capacitor_mythic',
        'spell_item_lightning_capacitor_ascended');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(229601, 'spell_item_pendant_of_the_violet_eye'),
(329601, 'spell_item_pendant_of_the_violet_eye'),
(429601, 'spell_item_pendant_of_the_violet_eye'),
(237657, 'spell_item_lightning_capacitor_mythic'),
(337657, 'spell_item_lightning_capacitor_heroic'),
(437657, 'spell_item_lightning_capacitor_ascended');

DELETE FROM `spell_script_names`
WHERE `spell_id` IN (38332, 238332, 338332, 438332) AND `ScriptName` = 'spell_karazhan_ribbon_of_sacrifice';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(38332, 'spell_karazhan_ribbon_of_sacrifice'),
(238332, 'spell_karazhan_ribbon_of_sacrifice'),
(338332, 'spell_karazhan_ribbon_of_sacrifice'),
(438332, 'spell_karazhan_ribbon_of_sacrifice');

COMMIT;

DROP TEMPORARY TABLE `_coa_karazhan_proc_sources`;
