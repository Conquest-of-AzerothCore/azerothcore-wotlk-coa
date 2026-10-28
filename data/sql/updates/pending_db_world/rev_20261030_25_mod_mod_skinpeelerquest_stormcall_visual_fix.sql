START TRANSACTION;

DELETE FROM `spellvisualkit_dbc` WHERE `f0` = 791;
INSERT INTO `spellvisualkit_dbc`
(`f0`, `f1`, `f2`, `f3`, `f4`, `f5`, `f6`, `f7`, `f8`, `f9`, `f10`,
 `f11`, `f12`, `f13`, `f14`, `f15`, `f16`, `f17`, `f18`, `f19`, `f20`,
 `f21`, `f22`, `f23`, `f24`, `f25`, `f26`, `f27`, `f28`, `f29`, `f30`,
 `f31`, `f32`, `f33`, `f34`, `f35`, `f36`, `f37`)
VALUES
(791, -1, 130, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

UPDATE `spellvisual_dbc`
SET `ChannelKit` = 0
WHERE `ID` = 99028;

UPDATE `smart_scripts`
SET `event_phase_mask` = 0
WHERE `entryorguid` = 9916212 AND `id` IN (20, 40);

COMMIT;
