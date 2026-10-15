-- Transfusion (705734, #2825): "Swap health percentages with an ally. Increases the lower health percentage
-- of the two to 40%, if below that amount." Spell.dbc gives 705734 RecoveryTime 180000, RangeIndex 4
-- (30 yds), ManaCost 200 and a single effect 77 (SPELL_EFFECT_SCRIPT_EFFECT) with TargetA 57
-- (TARGET_UNIT_TARGET_RAID) and base 39 -> 40, the tooltip's floor percentage.
-- Spell::EffectScriptEffect is a hard-coded switch on SpellFamilyName and spell id with no entry for
-- family 26 / id 705734, and no `spell_script_names` row existed, so casting Transfusion spent the cost and
-- the 180 s cooldown and moved no health on either unit.
-- The empowered half already works and is not touched: AscensionPooledVitality.h maps 705734 to
-- Empowerment::Transfusion and Player.cpp applies -60000 ms to SPELLMOD_COOLDOWN, matching helper 681406
-- ("Transfusion (Empowered)", aura 107 with MiscValue 11 = SPELLMOD_COOLDOWN, base -60001 -> -60000).
-- spell_ascension_bloodmage_transfusion exchanges the two units' health percentages and raises the lower
-- of the pair to the effect's own value (40) when it is below it. Every number comes from the record.
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 705734
    AND `ScriptName` = 'spell_ascension_bloodmage_transfusion';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(705734, 'spell_ascension_bloodmage_transfusion');
COMMIT;
