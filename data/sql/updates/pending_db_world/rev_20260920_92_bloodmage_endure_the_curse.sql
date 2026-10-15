-- Endure the Curse (681190): "Reduce all damage taken by $s2% for $d. While active, taking damage that would
-- reduce your health below 10% will instantly heal you for $681189s1% of your maximum health. Can only occur
-- once." Effect 1 (aura 87 SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN, MiscValue 127, amount -30) is native, but
-- effect 0 is a SPELL_AURA_SCHOOL_ABSORB over the same all-school mask whose Spell.dbc amount is 0
-- (BasePoints -1, DieSides 1). With no script on the spell, Unit::CalcAbsorbResist absorbs nothing, then
-- subtracts that nothing from the effect and removes the whole aura, effect 1 included, on the first point of
-- damage of any school (Unit.cpp:2515-2523). 681189 (SPELL_EFFECT_HEAL_PCT, 30% of maximum health) is a real
-- Spell.dbc record that no source file, module or SQL row referenced, so the lethal-damage clause did not
-- exist either. Both halves are handled by aura_ascension_endure_the_curse; the spell has no proc flags and
-- needs none, because the script hooks the absorb effect directly. No `spell_proc` row is added.
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 681190 AND `ScriptName` = 'aura_ascension_endure_the_curse';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(681190, 'aura_ascension_endure_the_curse');
COMMIT;
