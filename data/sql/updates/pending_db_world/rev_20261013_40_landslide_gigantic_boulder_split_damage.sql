-- Landslide (Maraudon): Gigantic Boulder (2100733 from Hurl Boulder, 2100734 cast directly) is "split between all
-- targets hit", but without SHARE_DAMAGE every player in the 10 yard area took the full damage.
DELETE FROM `spell_custom_attr` WHERE `spell_id` IN (2100733, 2100734);
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES (2100733, 0x00000008), (2100734, 0x00000008);
