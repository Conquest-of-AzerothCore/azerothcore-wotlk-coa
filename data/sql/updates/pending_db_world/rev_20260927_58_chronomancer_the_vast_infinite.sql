-- The Vast Infinite (706083): "All party and raid members become one, equally sharing 25% of all damage dealt to
-- them for $d, up to a maximum of 100% of their total health. At the end of the duration, all affected allies are
-- healed equal to the total damage shared split evenly amongst all allies."
-- Effect 0 is aura 69 with EffectBasePoints 25 and EffectMiscValueB 100, which Unit::CalcAbsorbResist read as a
-- flat 25-point shield. The client carries the two payloads the tooltip needs: 707600 "The Vast Infinite
-- [Damage]" ("Share damage.", SPELL_EFFECT_SCHOOL_DAMAGE) and 707601 "The Vast Infinite [Heal]" ("Share heal.",
-- SPELL_EFFECT_HEAL), both resolved-value helpers (SPELL_ATTR3_IGNORE_CASTER_MODIFIERS). Nothing cast them.
-- spell_ascension_the_vast_infinite absorbs 25% of each hit up to 100% of the holder's maximum health, splits the
-- absorbed amount evenly across every group member holding the same caster's aura through 707600, and at expiry
-- heals each holder through 707601 for the shared damage it took.
DELETE FROM `spell_script_names` WHERE `spell_id` = 706083 AND `ScriptName` = 'spell_ascension_the_vast_infinite';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(706083, 'spell_ascension_the_vast_infinite');
