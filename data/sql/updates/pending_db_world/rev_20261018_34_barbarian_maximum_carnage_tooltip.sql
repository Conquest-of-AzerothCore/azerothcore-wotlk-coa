-- Barbarian Maximum Carnage (#7603): the talent tooltip reads as a 491
-- damage total while each tick deals that amount, and the aura buff text
-- uses a 0.25 AP coefficient while the server applies 0.3.
--
-- Root cause is text, not mechanics: 560932 deals a single application of
-- 150-153 + 0.3*AP per 1s tick (verified: naked L59, AP 372, ticks
-- 249-251 vs 261.6-264.6 pre-mitigation). The reporter compared the
-- per-tick tooltip number against post-mitigation ticks and read the
-- "over $d" phrasing as a total.
--
-- Fix: publish clarified wording through coa_client_spell_description,
-- which the server streams to the client (SMSG_PATCH_SPELL); DELETE+INSERT
-- stays idempotent. Confirm in game: hover Maximum Carnage, check the
-- per-tick wording and the 0.3 coefficient on the aura tooltip.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (561359, 560933);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(561359,'Casting |cffffffffUnbridled Rage|r now causes you to begin swinging your weapon around you, dealing ${$560932m1+$560932ppl1+$AP*.3} Physical damage to up to $560932i nearby enemies every second for $560933d.'),
(560933,'Begin swinging your weapon around you dealing ${$560932m1+$560932ppl1+$AP*.3} Physical Damage to $560932i nearby enemies every second.');
