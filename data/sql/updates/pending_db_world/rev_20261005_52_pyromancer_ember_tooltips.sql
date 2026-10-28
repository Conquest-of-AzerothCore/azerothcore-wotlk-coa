-- Explode, Flames of Neltharion, Echo of Nozdormu, Ignis Ultimatus, Roaring
-- Pyre, Phoenix Dive and Firestorm consume an Ember on every cast, exactly
-- like Blaze: AscensionCustomResourceData.h ResourceCostRules lists them with
-- ResourceConsumption::Fixed on the Ember resource aura 807533, so the cast
-- removes one stack. Their client descriptions carry no cost line, while
-- Blaze's does, so players spend a resource the tooltip never names (#6530).
-- The server already streams coa_client_spell_description rows to the client
-- (SMSG_PATCH_SPELL), so publish every rank's own DBC text with the same
-- '$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r' prefix Blaze uses in
-- the client DBC. Every rank of each chain is listed, including the ones above
-- the reporter's level; 802174 is the rank 520937 swaps Explode for.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (800792, 502057, 502058, 502059, 502060, 502061, 502062, 502063, 570750, 801915, 535509, 535510, 535511, 535512, 572618, 572619, 572620, 572621, 572622, 572623, 802174, 803407, 803408, 803409, 803410, 578307, 578308, 578309, 567589, 567590, 680369, 704278, 706854, 802791);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(800792,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nBlast an enemy, dealing ${$m1+0+$spfi*1.13} Fire damage$?s520884[, increased by 15% for each of your Pyromancer periodic effects on the target][].'),
(502057,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nBlast an enemy, dealing ${$m1+0+$spfi*1.13} Fire damage$?s520884[, increased by 15% for each of your Pyromancer periodic effects on the target][].'),
(502058,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nBlast an enemy, dealing ${$m1+0+$spfi*1.13} Fire damage$?s520884[, increased by 15% for each of your Pyromancer periodic effects on the target][].'),
(502059,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nBlast an enemy, dealing ${$m1+0+$spfi*1.13} Fire damage$?s520884[, increased by 15% for each of your Pyromancer periodic effects on the target][].'),
(502060,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nBlast an enemy, dealing ${$m1+0+$spfi*1.13} Fire damage$?s520884[, increased by 15% for each of your Pyromancer periodic effects on the target][].'),
(502061,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nBlast an enemy, dealing ${$m1+0+$spfi*1.13} Fire damage$?s520884[, increased by 15% for each of your Pyromancer periodic effects on the target][].'),
(502062,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nBlast an enemy, dealing ${$m1+0+$spfi*1.13} Fire damage$?s520884[, increased by 15% for each of your Pyromancer periodic effects on the target][].'),
(502063,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nBlast an enemy, dealing ${$m1+0+$spfi*1.13} Fire damage$?s520884[, increased by 15% for each of your Pyromancer periodic effects on the target][].'),
(570750,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nBlast an enemy, dealing ${$m1+0+$spfi*1.13} Fire damage$?s520884[, increased by 15% for each of your Pyromancer periodic effects on the target][].'),
(801915,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(535509,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(535510,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(535511,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(535512,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(572618,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(572619,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(572620,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(572621,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(572622,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(572623,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nUnleash draconic flames, dealing ${$m1+0+$spfi*0.48} Fire damage to an enemy and up to ${$x1-1} additional nearby enemies.'),
(802174,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nObliterate an enemy, dealing ${$m1+0+$SP*1.05} Chromatic Damage and reducing all spell and ability cooldowns by $802804s1%.'),
(803407,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nObliterate an enemy, dealing ${$m1+0+$SP*1.05} Chromatic Damage and reducing all spell and ability cooldowns by $802804s1%.'),
(803408,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nObliterate an enemy, dealing ${$m1+0+$SP*1.05} Chromatic Damage and reducing all spell and ability cooldowns by $802804s1%.'),
(803409,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nObliterate an enemy, dealing ${$m1+0+$SP*1.05} Chromatic Damage and reducing all spell and ability cooldowns by $802804s1%.'),
(803410,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nObliterate an enemy, dealing ${$m1+0+$SP*1.05} Chromatic Damage and reducing all spell and ability cooldowns by $802804s1%.'),
(578307,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nObliterate an enemy, dealing ${$m1+0+$SP*1.05} Chromatic Damage and reducing all spell and ability cooldowns by $802804s1%.'),
(578308,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nObliterate an enemy, dealing ${$m1+0+$SP*1.05} Chromatic Damage and reducing all spell and ability cooldowns by $802804s1%.'),
(578309,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nObliterate an enemy, dealing ${$m1+0+$SP*1.05} Chromatic Damage and reducing all spell and ability cooldowns by $802804s1%.'),
(567589,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nObliterate an enemy, dealing ${$m1+0+$SP*1.05} Chromatic Damage and reducing all spell and ability cooldowns by $802804s1%.'),
(567590,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nObliterate an enemy, dealing ${$m1+0+$SP*1.05} Chromatic Damage and reducing all spell and ability cooldowns by $802804s1%.'),
(680369,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nChannel for $d, gathering a surge of fiery power before unleashing it in a $680370a1 yd line, dealing ${$680371m1+$680371ppl1+$spfi*1.0} Fire damage to enemies while also healing allies for ${$680370m1+$680370ppl1+$bh*2.0}.\r\n\r\nIgnores invulnerabilities, immunities, and resistances.\r\n\r\nConsumes |cffffffffFlamecasting|r stacks to increase this spell\'s damage and healing by $680382s1% per stack.'),
(704278,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nConjure a |cffffffffRoaring Pyre|r at the target location for $d. \r\n\r\nAllies within $704279a1 yds of the bonfire are healed for ${$704279m1+$704279ppl1+$bh*0.1+$SPI*.3}, scaling with your Spirit and healing spell power, every $704279t1 sec and their Spirit is increased by $704279s3%.'),
(706854,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nCommand your |cffffffffPhoenix|r to swoop to the target ally, shielding up to $706855x1 allies in its path with fire and absorbing ${$706855m1*$<scalingbp>+$BH*0.3+$SPI*0.5} damage for $706855d, scaling with your healing spell power and Spirit.'),
(802791,'$?a807533[|cffff7f7f][|cffff3232]Consumes 1 Ember|r\r\nCreate a fiery tornado at a location for $d.\r\n\r\nEnemies who enter its radius suffer ${$803704m1+$803704ppl1+$spfi*.4} Fire damage and are knocked back slightly.');
