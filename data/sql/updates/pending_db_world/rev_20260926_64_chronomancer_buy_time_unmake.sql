-- Buy Time (520188): "Casting Unmake on a target will remove this effect." The enemy-side stasis is 520186
-- (SPELL_AURA_DAMAGE_IMMUNITY, SPELL_AURA_MOD_STUN, MECHANIC_BANISH). Spell.dbc ships the carrier as 807310,
-- rank "Buy Time Remover" of Unmake: SPELL_EFFECT_REMOVE_AURA on TARGET_UNIT_TARGET_ENEMY with
-- EffectTriggerSpell 520186 and SPELL_ATTR0_NO_IMMUNITIES, but no record, proc or script ever cast it.
-- Casting any Unmake rank now casts 807310 on the Unmake target (SPELL_LINK_CAST).
DELETE FROM `spell_linked_spell`
WHERE `spell_trigger` IN (804418, 503784, 503785, 503786, 503787, 503788, 503789, 503790, 504574, 574344, 574345)
AND `spell_effect` = 807310 AND `type` = 0;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(804418, 807310, 0, 'Unmake rank 1 - remove Buy Time stasis from the target'),
(503784, 807310, 0, 'Unmake rank 2 - remove Buy Time stasis from the target'),
(503785, 807310, 0, 'Unmake rank 3 - remove Buy Time stasis from the target'),
(503786, 807310, 0, 'Unmake rank 4 - remove Buy Time stasis from the target'),
(503787, 807310, 0, 'Unmake rank 5 - remove Buy Time stasis from the target'),
(503788, 807310, 0, 'Unmake rank 6 - remove Buy Time stasis from the target'),
(503789, 807310, 0, 'Unmake rank 7 - remove Buy Time stasis from the target'),
(503790, 807310, 0, 'Unmake rank 8 - remove Buy Time stasis from the target'),
(504574, 807310, 0, 'Unmake rank 9 - remove Buy Time stasis from the target'),
(574344, 807310, 0, 'Unmake rank 10 - remove Buy Time stasis from the target'),
(574345, 807310, 0, 'Unmake rank 11 - remove Buy Time stasis from the target');
