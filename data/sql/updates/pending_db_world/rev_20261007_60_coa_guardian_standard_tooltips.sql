-- Every Guardian Standard cast tooltip renders the client extension marker literally.
-- Reported from a Standard of Spellwarding tooltip screenshot.
--
-- The marker is the client shift-reveal extension tag (an @ext: block with no tilde
-- inside it), which AscSpellText::Markup erases when Shift is not held. These tooltips
-- nevertheless show it as raw text. This is the same defect the Standard of Recovery fix
-- removed for 500260 in rev_20261006_40_guardian_recovery_cast_tooltip.sql, which is the
-- precedent followed here - publish the own text of the spell with the two markers
-- removed and the sentence kept as plain text, changing nothing else.
--
-- The text below is the Spell.dbc Description[enUS] of each spell, read from the live
-- client (patch-T.MPQ, sha256
-- d3dd607291d2d6793f72c7b13537f94fd7748d40a79a326db6a8b4cb2ed41068) and byte for byte
-- apart from the two markers. The CR LF line breaks of the client are written as the
-- repository escape, which MySQL expands back to the same bytes. Every one of these
-- strings carries exactly one marker pair, so nothing else in them can be affected. The
-- repository cannot edit the client Spell.dbc, and AscensionCompat already streams this
-- table to the client as SMSG_PATCH_SPELL (opcode 2346) at login, so no code change is
-- involved.
--
-- Scope is every learnable Guardian Standard whose own text carries the marker:
-- 500263 Rallying, 500547 Spellwarding, 706805 Might, 800346 Supremacy and the Standard
-- of Valiance rank chain 803931-803938. Deliberately not included:
--   500260 Standard of Recovery - already published without the marker by the fix above.
--   800319 Standard of Valiance rank 1 - its own text never carried the marker, being the
--     only rank with a plain sentence, which is why rank 1 has always looked right.
--   800335 Standard of Valiance - STANDARD_VALIANCE_DAMAGE, the internal spell the field
--     aura 501543 casts. It is absent from spell_ranks, trainer_spell and the class
--     ability list, so no client renders its description.
-- The three Necrolords, Deaths Chosen and Blackhound Warband spells (250021-250023) are
-- another class standards and carry no marker.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (500263, 500547, 706805, 800346, 803931, 803932, 803933, 803934, 803935, 803936, 803937, 803938);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(500263,'Throw down a |cffffffffStandard of Rallying|r for $d, reducing damage taken by $500265s1% and the duration of stun effects on them by $500265s3% on all allies within $500265a1 yds.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(500547,'Throw down a |cffffffffStandard of Spellwarding|r for $d, reducing the spell haste of enemies within $500548a1 yds by $500548s1%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(706805,'Throw down a |cffffffffStandard of Might|r for $d, increasing the base health of allies within $500602a1 yds by $500602s1% and reducing the duration of disarm effects against them by $500602s2%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(800346,'Throw down a |cffffffffStandard of Supremacy|r for $d, increasing the critical damage of Physical attacks by party members within $500299a1 yds by $500299s1%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(803931,'Throw down a |cffffffffStandard of Valiance|r for $d, nearby enemies within the area take ${$501538m3+$501538ppl3+$AP*0.04} Physical damage every $501538T3 sec and their movement speed is slowed by $800629s1%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(803932,'Throw down a |cffffffffStandard of Valiance|r for $d, nearby enemies within the area take ${$501539m3+$501539ppl3+$AP*0.04} Physical damage every $501539T3 sec and their movement speed is slowed by $800629s1%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(803933,'Throw down a |cffffffffStandard of Valiance|r for $d, nearby enemies within the area take ${$501540m3+$501540ppl3+$AP*0.04} Physical damage every $501540T3 sec and their movement speed is slowed by $800629s1%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(803934,'Throw down a |cffffffffStandard of Valiance|r for $d, nearby enemies within the area take ${$501541m3+$501541ppl3+$AP*0.04} Physical damage every $501541T3 sec and their movement speed is slowed by $800629s1%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(803935,'Throw down a |cffffffffStandard of Valiance|r for $d, nearby enemies within the area take ${$501542m3+$501542ppl3+$AP*0.04} Physical damage every $501542T3 sec and their movement speed is slowed by $800629s1%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(803936,'Throw down a |cffffffffStandard of Valiance|r for $d, nearby enemies within the area take ${$501543m3+$501543ppl3+$AP*0.04} Physical damage every $501543T3 sec and their movement speed is slowed by $800629s1%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(803937,'Throw down a |cffffffffStandard of Valiance|r for $d, nearby enemies within the area take ${$501544m3+$501544ppl3+$AP*0.04} Physical damage every $501544T3 sec and their movement speed is slowed by $800629s1%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.'),
(803938,'Throw down a |cffffffffStandard of Valiance|r for $d, nearby enemies within the area take ${$501545m3+$501545ppl3+$AP*0.04} Physical damage every $501545T3 sec and their movement speed is slowed by $800629s1%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.');
