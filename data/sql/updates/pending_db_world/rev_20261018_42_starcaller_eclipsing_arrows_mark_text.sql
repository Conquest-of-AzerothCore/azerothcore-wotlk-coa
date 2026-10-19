-- Eclipsing Arrows mark (#7524): the 574154 mark the talent applies
-- carries an empty client description, so the buff shows no text and
-- its application cannot be verified in game. Publish the mark wording
-- through coa_client_spell_description, which the server streams to the
-- client (SMSG_PATCH_SPELL); DELETE+INSERT stays idempotent. The engine
-- path (heal with the talent aura marks the ally) is covered by
-- starcaller-eclipsing-arrows-mark-7524. Confirm in game: heal an ally
-- with the talent learned and read the mark tooltip.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (574154);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(574154,'Marked for |cffffffffEclipsing Arrows|r. |cffffffffHuntress Shot|r heals you.');
