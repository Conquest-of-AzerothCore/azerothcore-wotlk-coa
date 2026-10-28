-- Shazzrah (12264): Dampen Magic and Mass Counterspell were scheduled at target 2 (self),
-- which is what made every occurrence fail with SPELL_FAILED_TARGET_NOT_PLAYER (122). Both
-- spells' first effect is SPELL_EFFECT_DUMMY with EffectImplicitTargetA = TARGET_UNIT_TARGET_ANY
-- (Spell.dbc), and both carry SPELL_ATTR3_ONLY_ON_PLAYER, so the dummy needs an explicit player
-- target, not Shazzrah himself.
--
-- The mechanic each dummy stands for is unaffected by which player is picked:
--  - Dampen Magic's effect (2105608) is SPELL_EFFECT_APPLY_AURA with
--    EffectImplicitTargetA = TARGET_UNIT_CASTER, so the buff lands on Shazzrah (the caster of
--    2105608, which this AI always is) regardless of who the dummy's cast bar shows - it is a
--    self-buff reducing magic damage taken, cast "at" a player only because the dummy itself
--    needs one. Retargeted to the tank (0), the same way Fire Strike is.
--  - Mass Counterspell's second effect (2105610) is TARGET_SRC_CASTER + TARGET_UNIT_SRC_AREA_ENEMY
--    - an area effect centred on Shazzrah, the identical shape already used successfully by
--    Arcane Instability (2105605/06). Retargeted to 3 (area), matching that row.
DELETE FROM `coa_boss_schedule` WHERE `entry` = 12264 AND `idx` IN (2, 5);
INSERT INTO `coa_boss_schedule`
    (`entry`, `idx`, `spell_d0`, `spell_d1`, `spell_d2`, `spell_d3`, `effect`, `first_ms`, `period_ms`, `hp_pct`, `target`, `comment`)
VALUES
(12264, 2, 2105607, 2105607, 2105607, 2105607, 2105608, 14100, 30200, 0, 0, 'Dampen Magic'),
(12264, 5, 2105609, 2105609, 2105609, 2105609, 2105610, 23600, 34800, 0, 3, 'Mass Counterspell');
