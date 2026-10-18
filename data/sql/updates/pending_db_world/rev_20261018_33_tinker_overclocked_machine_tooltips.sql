-- Tinker Overclocked Machine (#8090): Hardwired Haymaker (806781) and
-- Overclocked Smash (806782) show no description in the talent's SHIFT
-- "more information" section.
--
-- Root cause: the Mechanics talent Overclocked Machine (806757) embeds both
-- effects via @ext:@s:806781:0@@s:806782:0@:ext@, which the client renders
-- from its own Spell.dbc copy. Neither spell has a streamed override (no
-- spell_dbc row, no coa_client_spell_description row, not registered for
-- client patching), and the client copy carries no text for them, so the
-- SHIFT section renders icon+name with an empty body. The same embed is
-- also referenced by the adjacent Clockwork-Guardians text, which this fixes
-- too. The 806778/806780 auras intentionally keep their DBC text (no
-- player-facing surface references them).
--
-- Fix: publish the authored DBC wording through coa_client_spell_description,
-- which the server streams to the client (SMSG_PATCH_SPELL); DELETE+INSERT
-- stays idempotent. Confirm in game: open the Mechanics tree on a Tinker that
-- can choose Overclocked Machine, hover it, hold SHIFT — both the Hardwired
-- Haymaker and the Overclocked Smash sections must show their description.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (806781,806782);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(806781,'Unleash a devastating haymaker that deals ${$m1+0+$RAP*.15} Fire Damage.'),
(806782,'Smash the ground with overwhelming power, dealing ${$m1+0} Arcane Damage to $i enemies in a $a1 yd radius.');
