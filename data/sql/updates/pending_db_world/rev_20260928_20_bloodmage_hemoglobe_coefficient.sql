-- Hemoglobe (#1978): the tick 524906 reads $524906m1+$524906ppl1+$bh*0.1125+$SPI*0.45+$STA*0.35, so the
-- bonus-healing term needs direct_bonus 0.1125. SpellLevel 35 / MaxLevel 60 still halve it through
-- Unit::CalculateLevelPenalty unless IgnoreSpellLevelPenalty is set, which
-- ApplyAscensionBloodmageHemoglobeContract now does for this exact record shape.
DELETE FROM `spell_bonus_data` WHERE `entry` = 524906;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(524906, 0.1125, 0, 0, 0, 'Bloodmage - Hemoglobe (Hemopulse tick)');
