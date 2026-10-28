-- COA-7158: the Counterattack! creatures (Warlord Krom'zar 9456, Horde Defender 9457, Horde Axe Thrower 9458,
-- Kolkar Stormseer 9523, Kolkar Invader 9524) are only ever summoned by Regthar Deathgate's actionlist 338900, so
-- their SMART_EVENT_RESPAWN (11) rows never ran: Krom'zar did not yell or wander, the Stormseers had no caster
-- template and the Axe Thrower no turret template. Run them on SMART_EVENT_JUST_SUMMONED (54).
UPDATE `smart_scripts` SET `event_type` = 54, `comment` = REPLACE(`comment`, 'On Respawn', 'On Just Summoned')
WHERE `entryorguid` IN (9456, 9457, 9458, 9523, 9524) AND `source_type` = 0 AND `event_type` = 11;
