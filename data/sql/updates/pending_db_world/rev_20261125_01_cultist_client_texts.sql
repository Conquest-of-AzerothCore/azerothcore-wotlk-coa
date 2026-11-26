-- Cultist (class 25) client tooltip corrections approved by owner ruling O-18 (2026-11-25, "go global";
-- Cultist ADRs 0020, 0033, 0035): Dark Matter 806382 (Q-cu-15), Horrific Revelation 704473 (Q-cu-20, embedded
-- in 524877 and 704476), Embrace the Void 300307 (Q-cu-21), Psychic Suppression 800432 (Q-cu-22), Madness
-- 804369 (Q-cu-25, embedded in 500719, 500767 and 500732), Darkwither 800446 and 502213-502220 (Q-cu-26, all 9
-- ranks), Malignant Armor 680569 (Q-cu-4), Void Strength 805121 (Q-cu-9, embedded in 806943), Twisted Seal
-- 525065 ToolTip (Q-cu-16, Description kept verbatim), and Mind Rot 300300 (Q-cu-3).
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (
    806382, 704473, 300307, 800432, 804369,
    800446, 502213, 502214, 502215, 502216, 502217, 502218, 502219, 502220,
    680569, 805121, 525065, 300300
);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(806382, 'Channeling |cffffffffSatiate|r now heals all allies within $807219a1 yds for ${$807219m1+$807219ppl1+$bh*.2} every $807124T2 sec for $804275d.', NULL),
(704473, 'Heals a friendly target for ${$m1+0+$SP*0.678496} and increases their critical strike chance by $s2%, stacking $u times, for $d.', NULL),
(300307, 'Reaching 60 |cffcfa6ffInsanity|r increases your Magic damage dealt by $573285s1% for $573285d.', NULL),
(800432, 'Stun an enemy, dealing ${$m1+0+$sps*.55+$AP*.1} Shadow damage every $t1 sec for $802789d. \r\n\r\nThe target takes $803746s1% more damage from all sources while you are channeling this spell.', NULL),
(804369, 'Your |cffffffffGaze of C''thun|r or |cFFFFFFFFObliteration Beam|r causes $s1% increased damage, stacks up to $u times.', NULL),
(800446, '|cffcfa6ffGenerates 10 Insanity|r\r\nWither an enemy, dealing $o1 Shadow damage over $d. Each instance of damage reduces their periodic healing taken by $706913s1%, stacking up to $?s301317[7][$706913u] times.', NULL),
(502213, '|cffcfa6ffGenerates 10 Insanity|r\r\nWither an enemy, dealing $o1 Shadow damage over $d. Each instance of damage reduces their periodic healing taken by $706913s1%, stacking up to $?s301317[7][$706913u] times.', NULL),
(502214, '|cffcfa6ffGenerates 10 Insanity|r\r\nWither an enemy, dealing $o1 Shadow damage over $d. Each instance of damage reduces their periodic healing taken by $706913s1%, stacking up to $?s301317[7][$706913u] times.', NULL),
(502215, '|cffcfa6ffGenerates 10 Insanity|r\r\nWither an enemy, dealing $o1 Shadow damage over $d. Each instance of damage reduces their periodic healing taken by $706913s1%, stacking up to $?s301317[7][$706913u] times.', NULL),
(502216, '|cffcfa6ffGenerates 10 Insanity|r\r\nWither an enemy, dealing $o1 Shadow damage over $d. Each instance of damage reduces their periodic healing taken by $706913s1%, stacking up to $?s301317[7][$706913u] times.', NULL),
(502217, '|cffcfa6ffGenerates 10 Insanity|r\r\nWither an enemy, dealing $o1 Shadow damage over $d. Each instance of damage reduces their periodic healing taken by $706913s1%, stacking up to $?s301317[7][$706913u] times.', NULL),
(502218, '|cffcfa6ffGenerates 10 Insanity|r\r\nWither an enemy, dealing $o1 Shadow damage over $d. Each instance of damage reduces their periodic healing taken by $706913s1%, stacking up to $?s301317[7][$706913u] times.', NULL),
(502219, '|cffcfa6ffGenerates 10 Insanity|r\r\nWither an enemy, dealing $o1 Shadow damage over $d. Each instance of damage reduces their periodic healing taken by $706913s1%, stacking up to $?s301317[7][$706913u] times.', NULL),
(502220, '|cffcfa6ffGenerates 10 Insanity|r\r\nWither an enemy, dealing $o1 Shadow damage over $d. Each instance of damage reduces their periodic healing taken by $706913s1%, stacking up to $?s301317[7][$706913u] times.', NULL),
(680569, 'Increases your attack power by 2 for every 100 armor value you have.', NULL),
(805121, '|cFF66DDFFLevel 40 Passive|r\r\nIncreases your Shadow spell damage by $s3% of your Strength and your spell hit rating by $s1% of your Strength.', NULL),
(525065, 'Create a warped sigil that bends hostile force away from you, deflecting all spells and abilities for $d, but making you unable to attack or cast spells.\r\n\r\nCasters whose magic is deflected are silenced for $525066d.', 'Deflecting spells and abilities. Enemies who get deflected are also silenced for $525066d.'),
(300300, 'Periodic or channeled damage dealt now has a $h% chance to afflict your target with |cffffffffMind Rot|r.@s:560714:0@', NULL);
