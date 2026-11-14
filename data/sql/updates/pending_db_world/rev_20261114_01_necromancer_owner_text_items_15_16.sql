-- Necromancer client texts aligned to the owner's rulings of 2026-11-14: text items 15 (Raising the Kirin Tor
-- refunds 10 Runic Power) and 16 (Wormfood's Rotling damage increases with level) (G-8, owner go relayed by the
-- mentor; text-items.md). Description only; an empty ToolTip keeps the client's.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (560800, 805649);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(560800, 'Upon fully channeling |cFFFFFFFFCrypt Swarm|r, you summon a |cffffffffRotling|r that will run towards the enemy and explode after $807640t2 sec for ${$500585m1+$500585ppl1+$SP*0.335} Plague damage, increased with your level.', ''),
(805649, 'Your |cff90ee90Command|r spells now have a $h% chance to refund 10 Runic Power.', '');
