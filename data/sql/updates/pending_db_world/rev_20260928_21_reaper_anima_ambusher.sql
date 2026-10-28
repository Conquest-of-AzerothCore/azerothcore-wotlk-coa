-- Anima Ambusher 705424 is aura 354, which has no core handler. Spectre Stride's damage spell 803742 (triggered by
-- every Spectre Stride rank, 801624 and 802422-802428) now applies Anima Ambush 705425: five one-second ticks,
-- each 25% of the Spectre Stride hit, for the tooltip's additional 125% over 5 sec.
DELETE FROM `spell_script_names` WHERE `spell_id` = 803742 AND `ScriptName` = 'spell_ascension_reaper_anima_ambusher';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(803742, 'spell_ascension_reaper_anima_ambusher');
