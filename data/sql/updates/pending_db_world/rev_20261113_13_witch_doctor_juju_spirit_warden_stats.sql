-- Juju Injection (503608 rank 1, 503609 rank 2) raised Agility and Intellect, which leaves the Spirit specialization
-- Brewing with nothing to multiply, and the Spirit Warden Idol buff (503775) raised Spirit only, which leaves the
-- Agility specialization Shadowhunting with nothing to multiply. The core now adds Spirit to Juju Injection and
-- Agility to the buff, with the same percent (AscensionWitchDoctorCompletion.cpp). The client keeps the old effects
-- and texts in Spell.dbc, so the talent descriptions and the buff's aura text are rewritten here. Spirit Warden
-- itself (503774) only carries the talent text, which names the buff's percent through $503775s1.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (503608, 503609, 503774, 503775);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(503608, 'Increases your Agility, Intellect and Spirit by $s1%.', NULL),
(503609, 'Increases your Agility, Intellect and Spirit by $s1%.', NULL),
(503774, 'Summoning an |cFFFFFFFFIdol|r now increases your Spirit and Agility by $503775s1% for $503775d.', NULL),
(503775, '', 'Spirit and Agility increased by ${$w1}%.');
