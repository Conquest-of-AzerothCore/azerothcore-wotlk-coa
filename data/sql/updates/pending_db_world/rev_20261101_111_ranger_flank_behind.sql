-- Ranger Flank "an enemy from behind" fails with SPELL_FAILED_NOT_BEHIND in front of its target, like Backstab (#10589)
DELETE FROM `spell_custom_attr` WHERE `spell_id` IN (582530, 582531, 804940, 805082, 805083, 805084, 805085, 805086,
    805087, 805088);
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES
(582530, 131072),
(582531, 131072),
(804940, 131072),
(805082, 131072),
(805083, 131072),
(805084, 131072),
(805085, 131072),
(805086, 131072),
(805087, 131072),
(805088, 131072);
