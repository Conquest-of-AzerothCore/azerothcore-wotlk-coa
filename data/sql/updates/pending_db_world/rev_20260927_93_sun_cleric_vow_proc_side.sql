-- Sun Cleric Vows proc once per heal or hit, including one the Sun Cleric aims at itself.
-- The rows shipped by rev_20260909_13 used ProcFlags 1048575 (every done and taken flag), so a self-targeted
-- event ran each Vow twice: once in the actor pass and once in the action-target pass.
-- Vows of Radiance, Dawn, Grace, the Eclipse and the Valkyr act on what the Sun Cleric does (done flags, 349524);
-- Vow of Light acts on what the Sun Cleric receives (taken flags, 699048).
DELETE FROM `spell_proc` WHERE `SpellId` IN (803489, 803491, 803719, 807435, 807547, 807749);
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`, `Charges`) VALUES
(803489, 349524, 7, 2, 32767, 2, 100, 0),
(803491, 349524, 7, 2, 32767, 2, 100, 0),
(803719, 349524, 7, 2, 32767, 2, 100, 0),
(807435, 349524, 7, 2, 32767, 2, 100, 0),
(807547, 699048, 7, 2, 32767, 2, 100, 0),
(807749, 349524, 7, 2, 32767, 2, 100, 0);
