-- Wildcard Guardian of Ancient Kings 277875 (#10606) names its cooldown helpers in the tooltip ($277877s1) but
-- nothing cast them. 277876 resets Divine Storm (family mask), Hammer of the Righteous 53595 and Holy Shock 20473;
-- 277877 reduces their cooldowns by 50% and now lasts as long as the Guardian aura.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 277875 AND `spell_effect` IN (277876, 277877);
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(277875, 277876, 0, 'Wildcard Guardian of Ancient Kings - cooldown reset'),
(277875, 277877, 2, 'Wildcard Guardian of Ancient Kings - cooldown reduction');
