-- Death by Laughter (1660034): the player channels Corrupting Totem for 10 s at a totem; a completed channel alters it.
UPDATE `gameobject_template` SET `Data10` = 256716 WHERE `entry` IN (2300527, 2300533, 2300534);

DELETE FROM `spell_script_names` WHERE `spell_id` = 256716 AND `ScriptName` = 'spell_coa_corrupting_totem';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(256716, 'spell_coa_corrupting_totem');

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2300527, 2300533, 2300534) AND `source_type` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300527, 1, 0, 1, 8, 0, 100, 0, 256716, 0, 0, 0, 0, 0, 33, 161849, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Aquiline Totem - On Corrupting Totem Channelled - Quest Credit Totems altered'),
(2300527, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161850, 4, 60000, 1, 0, 0, 8, 0, 0, 0, 0, -3547.5, -1207, 205.527, 4, 'Aquiline Totem - Linked - Summon its guardian spirit to attack the invoker'),
(2300527, 1, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Aquiline Totem - Linked - Fade for 60 seconds'),
(2300533, 1, 0, 1, 8, 0, 100, 0, 256716, 0, 0, 0, 0, 0, 33, 161849, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Owlish Totem - On Corrupting Totem Channelled - Quest Credit Totems altered'),
(2300533, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161851, 4, 60000, 1, 0, 0, 8, 0, 0, 0, 0, -3582.5, -1121, 205.775, 3.8, 'Owlish Totem - Linked - Summon its guardian spirit to attack the invoker'),
(2300533, 1, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Owlish Totem - Linked - Fade for 60 seconds'),
(2300534, 1, 0, 1, 8, 0, 100, 0, 256716, 0, 0, 0, 0, 0, 33, 161849, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Taurine Totem - On Corrupting Totem Channelled - Quest Credit Totems altered'),
(2300534, 1, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 12, 161852, 4, 60000, 1, 0, 0, 8, 0, 0, 0, 0, -3500.5, -1204, 212.906, 5.5, 'Taurine Totem - Linked - Summon its guardian spirit to attack the invoker'),
(2300534, 1, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Taurine Totem - Linked - Fade for 60 seconds');

-- Corrupting Totem 256716 as in Spell.dbc except ChannelInterruptFlags: Drain Life's 31756 plus taking damage (31758),
-- so moving, casting, attacking, using something or being hit cancels the channel without altering the totem, instead
-- of a hit pushing it back to an early finish. The row also reaches the client, which cancels it too.
DELETE FROM `spell_dbc` WHERE `ID` = 256716;
INSERT INTO `spell_dbc` (`ID`, `Category`, `DispelType`, `Mechanic`, `Attributes`, `AttributesEx`, `AttributesEx2`,
    `AttributesEx3`, `AttributesEx4`, `AttributesEx5`, `AttributesEx6`, `AttributesEx7`, `ShapeshiftMask`, `unk_320_2`,
    `ShapeshiftExclude`, `unk_320_3`, `Targets`, `TargetCreatureType`, `RequiresSpellFocus`, `FacingCasterFlags`,
    `CasterAuraState`, `TargetAuraState`, `ExcludeCasterAuraState`, `ExcludeTargetAuraState`, `CasterAuraSpell`,
    `TargetAuraSpell`, `ExcludeCasterAuraSpell`, `ExcludeTargetAuraSpell`, `CastingTimeIndex`, `RecoveryTime`,
    `CategoryRecoveryTime`, `InterruptFlags`, `AuraInterruptFlags`, `ChannelInterruptFlags`, `ProcTypeMask`,
    `ProcChance`, `ProcCharges`, `MaxLevel`, `BaseLevel`, `SpellLevel`, `DurationIndex`, `PowerType`, `ManaCost`,
    `ManaCostPerLevel`, `ManaPerSecond`, `ManaPerSecondPerLevel`, `RangeIndex`, `Speed`, `ModalNextSpell`,
    `CumulativeAura`, `Totem_1`, `Totem_2`, `Reagent_1`, `Reagent_2`, `Reagent_3`, `Reagent_4`, `Reagent_5`,
    `Reagent_6`, `Reagent_7`, `Reagent_8`, `ReagentCount_1`, `ReagentCount_2`, `ReagentCount_3`, `ReagentCount_4`,
    `ReagentCount_5`, `ReagentCount_6`, `ReagentCount_7`, `ReagentCount_8`, `EquippedItemClass`, `EquippedItemSubclass`,
    `EquippedItemInvTypes`, `Effect_1`, `Effect_2`, `Effect_3`, `EffectDieSides_1`, `EffectDieSides_2`,
    `EffectDieSides_3`, `EffectRealPointsPerLevel_1`, `EffectRealPointsPerLevel_2`, `EffectRealPointsPerLevel_3`,
    `EffectBasePoints_1`, `EffectBasePoints_2`, `EffectBasePoints_3`, `EffectMechanic_1`, `EffectMechanic_2`,
    `EffectMechanic_3`, `ImplicitTargetA_1`, `ImplicitTargetA_2`, `ImplicitTargetA_3`, `ImplicitTargetB_1`,
    `ImplicitTargetB_2`, `ImplicitTargetB_3`, `EffectRadiusIndex_1`, `EffectRadiusIndex_2`, `EffectRadiusIndex_3`,
    `EffectAura_1`, `EffectAura_2`, `EffectAura_3`, `EffectAuraPeriod_1`, `EffectAuraPeriod_2`, `EffectAuraPeriod_3`,
    `EffectMultipleValue_1`, `EffectMultipleValue_2`, `EffectMultipleValue_3`, `EffectChainTargets_1`,
    `EffectChainTargets_2`, `EffectChainTargets_3`, `EffectItemType_1`, `EffectItemType_2`, `EffectItemType_3`,
    `EffectMiscValue_1`, `EffectMiscValue_2`, `EffectMiscValue_3`, `EffectMiscValueB_1`, `EffectMiscValueB_2`,
    `EffectMiscValueB_3`, `EffectTriggerSpell_1`, `EffectTriggerSpell_2`, `EffectTriggerSpell_3`,
    `EffectPointsPerCombo_1`, `EffectPointsPerCombo_2`, `EffectPointsPerCombo_3`, `EffectSpellClassMaskA_1`,
    `EffectSpellClassMaskA_2`, `EffectSpellClassMaskA_3`, `EffectSpellClassMaskB_1`, `EffectSpellClassMaskB_2`,
    `EffectSpellClassMaskB_3`, `EffectSpellClassMaskC_1`, `EffectSpellClassMaskC_2`, `EffectSpellClassMaskC_3`,
    `SpellVisualID_1`, `SpellVisualID_2`, `SpellIconID`, `ActiveIconID`, `SpellPriority`, `Name_Lang_enUS`,
    `Name_Lang_enGB`, `Name_Lang_koKR`, `Name_Lang_frFR`, `Name_Lang_deDE`, `Name_Lang_enCN`, `Name_Lang_zhCN`,
    `Name_Lang_enTW`, `Name_Lang_zhTW`, `Name_Lang_esES`, `Name_Lang_esMX`, `Name_Lang_ruRU`, `Name_Lang_ptPT`,
    `Name_Lang_ptBR`, `Name_Lang_itIT`, `Name_Lang_Unk`, `Name_Lang_Mask`, `NameSubtext_Lang_enUS`,
    `NameSubtext_Lang_enGB`, `NameSubtext_Lang_koKR`, `NameSubtext_Lang_frFR`, `NameSubtext_Lang_deDE`,
    `NameSubtext_Lang_enCN`, `NameSubtext_Lang_zhCN`, `NameSubtext_Lang_enTW`, `NameSubtext_Lang_zhTW`,
    `NameSubtext_Lang_esES`, `NameSubtext_Lang_esMX`, `NameSubtext_Lang_ruRU`, `NameSubtext_Lang_ptPT`,
    `NameSubtext_Lang_ptBR`, `NameSubtext_Lang_itIT`, `NameSubtext_Lang_Unk`, `NameSubtext_Lang_Mask`,
    `Description_Lang_enUS`, `Description_Lang_enGB`, `Description_Lang_koKR`, `Description_Lang_frFR`,
    `Description_Lang_deDE`, `Description_Lang_enCN`, `Description_Lang_zhCN`, `Description_Lang_enTW`,
    `Description_Lang_zhTW`, `Description_Lang_esES`, `Description_Lang_esMX`, `Description_Lang_ruRU`,
    `Description_Lang_ptPT`, `Description_Lang_ptBR`, `Description_Lang_itIT`, `Description_Lang_Unk`,
    `Description_Lang_Mask`, `AuraDescription_Lang_enUS`, `AuraDescription_Lang_enGB`, `AuraDescription_Lang_koKR`,
    `AuraDescription_Lang_frFR`, `AuraDescription_Lang_deDE`, `AuraDescription_Lang_enCN`, `AuraDescription_Lang_zhCN`,
    `AuraDescription_Lang_enTW`, `AuraDescription_Lang_zhTW`, `AuraDescription_Lang_esES`, `AuraDescription_Lang_esMX`,
    `AuraDescription_Lang_ruRU`, `AuraDescription_Lang_ptPT`, `AuraDescription_Lang_ptBR`, `AuraDescription_Lang_itIT`,
    `AuraDescription_Lang_Unk`, `AuraDescription_Lang_Mask`, `ManaCostPct`, `StartRecoveryCategory`,
    `StartRecoveryTime`, `MaxTargetLevel`, `SpellClassSet`, `SpellClassMask_1`, `SpellClassMask_2`, `SpellClassMask_3`,
    `MaxTargets`, `DefenseType`, `PreventionType`, `StanceBarOrder`, `EffectChainAmplitude_1`, `EffectChainAmplitude_2`,
    `EffectChainAmplitude_3`, `MinFactionID`, `MinReputation`, `RequiredAuraVision`, `RequiredTotemCategoryID_1`,
    `RequiredTotemCategoryID_2`, `RequiredAreasID`, `SchoolMask`, `RuneCostID`, `SpellMissileID`, `PowerDisplayID`,
    `EffectBonusMultiplier_1`, `EffectBonusMultiplier_2`, `EffectBonusMultiplier_3`, `SpellDescriptionVariableID`,
    `SpellDifficultyID`) VALUES
(256716, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 47, 0, 31758, 0, 101,
    0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 6, 0, 0,
    0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 25, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 278469, 0, 26913, 0, 0, 'Corrupting Totem', '', '', '', '',
    '', '', '', '', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!',
    'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 16712190, '', '', '', '', '', '', '', '', '',
    'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!',
    'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 16712190, '', '', '', '', '', '', '', '', '', 'UPDATE YOUR CLIENT!',
    'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!',
    'UPDATE YOUR CLIENT!', 16712190, '', '', '', '', '', '', '', '', '', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!',
    'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!', 'UPDATE YOUR CLIENT!',
    16712190, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0);
