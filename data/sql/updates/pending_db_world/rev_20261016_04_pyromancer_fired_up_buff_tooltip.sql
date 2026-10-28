-- Fired Up! (704823) buff tooltip: the client's own ToolTip text ("Ember
-- spenders are instant and have a chance to refund their cost.") names neither
-- the refund chance nor the 30% critical strike chance the aura grants, while
-- the spellbook Description already states both. Publish a buff-voiced ToolTip
-- with the same facts (40% refund from ProcChance, fixed 30% from Effect[2]),
-- leaving the duration to the client's own "N seconds remaining" line. The
-- Description row is republished unchanged. AscensionCompat streams the ToolTip
-- over the DBC one as SMSG_PATCH_SPELL at login.
DELETE FROM `coa_client_spell_description` WHERE `ID` = 704823;
INSERT INTO `coa_client_spell_description` (`ID`,`Description`,`ToolTip`) VALUES
(704823,'Your |cffff7f7fEmber|r spenders are now instant and have a $h% chance to refund their cost and increases your chance to critically strike by 30% for $d.','|cffff7f7fEmber|r spenders are instant and have a 40% chance to refund their cost and increase your chance to critically strike by 30%.');
