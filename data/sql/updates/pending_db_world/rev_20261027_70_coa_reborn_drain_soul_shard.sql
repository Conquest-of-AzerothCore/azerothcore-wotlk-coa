-- Reborn Drain Soul (1101120 and its ranks) has no per-tick Soul Shard chance: its effect layout reverses
-- the stock chain's (channel death item at EFFECT_0, periodic damage at EFFECT_1), so the stock
-- spell_warl_drain_soul script never binds to it. Bind the new Reborn-layout script instead (#8858).
DELETE FROM `spell_script_names` WHERE `spell_id` IN (1101120, 1108288, 1108289, 1111675, 1127217, 1147855)
    AND `ScriptName` = 'spell_warl_drain_soul_reborn';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1101120, 'spell_warl_drain_soul_reborn'),
(1108288, 'spell_warl_drain_soul_reborn'),
(1108289, 'spell_warl_drain_soul_reborn'),
(1111675, 'spell_warl_drain_soul_reborn'),
(1127217, 'spell_warl_drain_soul_reborn'),
(1147855, 'spell_warl_drain_soul_reborn');
