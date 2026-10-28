-- Counterattack! (4021): Regthar Deathgate (3389) starts the Kolkar assault only in event phase 1. His actionlist 338900
-- ended the assault in phase 4 and went back to phase 1 only after 2 hours, so a player who came after someone else's
-- assault found no enemies and could not start one, neither by accepting the quest nor through his gossip. The assault
-- now returns him to phase 1 when it ends, 20 s after Warlord Krom'zar arrives.
UPDATE `smart_scripts` SET `action_param1` = 1, `comment` = 'Regthar Deathgate - On Script - Set Event Phase 1'
WHERE `entryorguid` = 338900 AND `source_type` = 9 AND `id` = 26;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 338900 AND `source_type` = 9 AND `id` = 27;
