-- CoA: 1660022 'A Sinister Ritual' - Hirsutta the Witch (161790) cast Drain Life
-- (256798, no mana cost) every 9-12 seconds, an endless full heal the player could never
-- out-damage. The drain now fires once per fight when she first drops to half health,
-- so it stays a threatening heal without making her unkillable.
UPDATE `smart_scripts` SET `event_type` = 2, `event_param1` = 0, `event_param2` = 50, `event_param3` = 0, `event_param4` = 0, `event_flags` = 1 WHERE `entryorguid` = 161790 AND `source_type` = 0 AND `id` = 3;
