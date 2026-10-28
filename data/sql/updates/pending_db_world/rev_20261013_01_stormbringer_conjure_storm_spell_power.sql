-- Conjure Storm (800227, 501415-501420): ${$m1+0+$spn*.2} initial Nature damage and
-- ${($d*1000/$T2)*($m2+0+$spn*.15)} over the duration. No ranks had spell_bonus_data and
-- their EffectBonusMultiplier is 0, so neither part gained anything from spell power.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (800227, 501415, 501416, 501417, 501418, 501419, 501420);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(800227, 0.2, 0.15, 0, 0, 'Stormbringer Conjure Storm - SP'),
(501415, 0.2, 0.15, 0, 0, 'Stormbringer Conjure Storm - SP'),
(501416, 0.2, 0.15, 0, 0, 'Stormbringer Conjure Storm - SP'),
(501417, 0.2, 0.15, 0, 0, 'Stormbringer Conjure Storm - SP'),
(501418, 0.2, 0.15, 0, 0, 'Stormbringer Conjure Storm - SP'),
(501419, 0.2, 0.15, 0, 0, 'Stormbringer Conjure Storm - SP'),
(501420, 0.2, 0.15, 0, 0, 'Stormbringer Conjure Storm - SP');
