-- Every learnable Guardian ability that Spell.dbc column 24 (CasterAuraSpell)
-- gates behind a formation, republished with the requirement its tooltip never
-- had (#6742, #6743, #6744, #6745, #6746, #6748).
--
-- 504151 Knight's Calling, 800313 Brace, 500168 Raise Shield and 802283 Bastion
-- carry CasterAuraSpell 800317 (Tower Formation); 806220 Linebreaker and the
-- Advance and Hammer of Kings chains carry 803130 (Line Formation); the Battle
-- Rush, Spear Throw and Net Throw chains carry 803417 (Assault Formation).
-- Core enforces that field in Spell::CheckCasterAuras, so the abilities really
-- are unusable outside their formation - but the client renders no tooltip line
-- for CasterAuraSpell, and Stances/StancesNot are 0 on every spell published
-- here, so nothing told the player. Reporters of six separate issues hit the
-- same wall.
--
-- Four spells carrying the same field are left out because no client renders
-- their description: 707722 Turn The Blade 'Disarm' is cast by the server
-- itself (AscensionGuardianEvents.cpp), and 500746 Advance 'Stun', 803939 Hold
-- the Line 'SLS' and 802309 Net Throw 'Test' are unlearnable helper and test
-- ranks whose text duplicates the real ranks published below. 500746 is also
-- the only spell in the family that carries Stances bits (196608), so leaving
-- it out is what makes the sentence above true of every row here.
--
-- The repository already publishes this shape of requirement: the Runeshroud
-- runes in rev_20261003_00_coa_palm_sigil_runeshroud_tooltip.sql carry
-- '$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r' ahead of their own
-- text, white while the aura is up and red while it is not. Every row below
-- uses that prefix with the formation's own aura id and name, both read out of
-- the client's spell data rather than typed in.
--
-- The description body of each row is the client's own text, byte for byte;
-- only the requirement line is added. The client's Spell.dbc cannot be edited
-- from this repository, and AscensionCompat already streams these rows to the
-- client as SMSG_PATCH_SPELL, so no code change is involved.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (300927, 500168, 500170, 500257, 500463, 501546, 501547, 501548, 503127, 503128, 503129, 503130, 503131, 503132, 503133, 503134, 503344, 503345, 503346, 503347, 503348, 503349, 503350, 503351, 504151, 504693, 572142, 572143, 572144, 572145, 572146, 572147, 572821, 707170, 800313, 802188, 802197, 802198, 802283, 802304, 803132, 803830, 803895, 806220);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(300927,'$?a800317[|cffffffff][|cffff3232]Requires Tower Formation|r\r\nRaise your shield and reflect the next harmful spell cast on you within $d. \r\n\r\nWhile active, being hit by a spell restores $500493s1 Energy.'),
(500168,'$?a800317[|cffffffff][|cffff3232]Requires Tower Formation|r\r\nRaise your shield, increasing your block chance$?s92105[ $s1%][] and block value by $?s92105[$500613s1%][$s1%] for $d.\r\n\r\nWhile active, blocking an attack restores $500493s1 Energy.'),
(500170,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nIncreases movement speed by $s3%, grants immunity to movement-impairing effects, and prevents you from stopping for $d.\r\n\r\nAfter a short delay, you can recast the ability to stomp the ground, dealing ${$m1+0+$AP*0.1} Physical damage to nearby enemies. If not recast, you will stomp at the end of the duration.'),
(500257,'$?a800317[|cffffffff][|cffff3232]Requires Tower Formation|r\r\nRaise your shield in challenge at your target, taunting them for $d.'),
(500463,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nThrow a massive spear at an enemy, dealing ${$m1+0+$AP*0.665} Physical damage, reducing the effectiveness of any healing by $804572s1% for $804572d.'),
(501546,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nCharge an enemy, dealing ${$m2+0+$AP*0.09996} Physical damage and stunning them for $d.'),
(501547,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nCharge an enemy, dealing ${$m2+0+$AP*0.09996} Physical damage and stunning them for $d.'),
(501548,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nCharge an enemy, dealing ${$m2+0+$AP*0.09996} Physical damage and stunning them for $d.'),
(503127,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\n|cff66ccffGrants Motivation|r\r\nSlam the ground, dealing ${$m1+0+$AP*0.4} Physical Damage, scaling with defense rating to nearby enemies$?s572714[ and reducing their casting speed by $572714s1% for $572714d][].\r\n\r\nDeals $803131s2% increased damage to enemies affected by |cffffffffLine Formation|r.'),
(503128,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\n|cff66ccffGrants Motivation|r\r\nSlam the ground, dealing ${$m1+0+$AP*0.4} Physical Damage, scaling with defense rating to nearby enemies$?s572714[ and reducing their casting speed by $572714s1% for $572714d][].\r\n\r\nDeals $803131s2% increased damage to enemies affected by |cffffffffLine Formation|r.'),
(503129,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\n|cff66ccffGrants Motivation|r\r\nSlam the ground, dealing ${$m1+0+$AP*0.4} Physical Damage, scaling with defense rating to nearby enemies$?s572714[ and reducing their casting speed by $572714s1% for $572714d][].\r\n\r\nDeals $803131s2% increased damage to enemies affected by |cffffffffLine Formation|r.'),
(503130,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\n|cff66ccffGrants Motivation|r\r\nSlam the ground, dealing ${$m1+0+$AP*0.4} Physical Damage, scaling with defense rating to nearby enemies$?s572714[ and reducing their casting speed by $572714s1% for $572714d][].\r\n\r\nDeals $803131s2% increased damage to enemies affected by |cffffffffLine Formation|r.'),
(503131,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\n|cff66ccffGrants Motivation|r\r\nSlam the ground, dealing ${$m1+0+$AP*0.4} Physical Damage, scaling with defense rating to nearby enemies$?s572714[ and reducing their casting speed by $572714s1% for $572714d][].\r\n\r\nDeals $803131s2% increased damage to enemies affected by |cffffffffLine Formation|r.'),
(503132,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\n|cff66ccffGrants Motivation|r\r\nSlam the ground, dealing ${$m1+0+$AP*0.4} Physical Damage, scaling with defense rating to nearby enemies$?s572714[ and reducing their casting speed by $572714s1% for $572714d][].\r\n\r\nDeals $803131s2% increased damage to enemies affected by |cffffffffLine Formation|r.'),
(503133,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\n|cff66ccffGrants Motivation|r\r\nSlam the ground, dealing ${$m1+0+$AP*0.4} Physical Damage, scaling with defense rating to nearby enemies$?s572714[ and reducing their casting speed by $572714s1% for $572714d][].\r\n\r\nDeals $803131s2% increased damage to enemies affected by |cffffffffLine Formation|r.'),
(503134,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\n|cff66ccffGrants Motivation|r\r\nSlam the ground, dealing ${$m1+0+$AP*0.4} Physical Damage, scaling with defense rating to nearby enemies$?s572714[ and reducing their casting speed by $572714s1% for $572714d][].\r\n\r\nDeals $803131s2% increased damage to enemies affected by |cffffffffLine Formation|r.'),
(503344,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nIncreases movement speed by $s3%, grants immunity to movement impairing effects, and prevents you from stopping for $d.\r\n\r\nAfter a short delay, you can recast the ability to stomp the ground, dealing ${$m1+0+$AP*0.1} Physical damage to nearby enemies. If not recast, you will stomp at the end of the duration.'),
(503345,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nIncreases movement speed by $s3%, grants immunity to movement impairing effects, and prevents you from stopping for $d.\r\n\r\nAfter a short delay, you can recast the ability to stomp the ground, dealing ${$m1+0+$AP*0.1} Physical damage to nearby enemies. If not recast, you will stomp at the end of the duration.'),
(503346,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nIncreases movement speed by $s3%, grants immunity to movement impairing effects, and prevents you from stopping for $d.\r\n\r\nAfter a short delay, you can recast the ability to stomp the ground, dealing ${$m1+0+$AP*0.1} Physical damage to nearby enemies. If not recast, you will stomp at the end of the duration.'),
(503347,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nIncreases movement speed by $s3%, grants immunity to movement impairing effects, and prevents you from stopping for $d.\r\n\r\nAfter a short delay, you can recast the ability to stomp the ground, dealing ${$m1+0+$AP*0.1} Physical damage to nearby enemies. If not recast, you will stomp at the end of the duration.'),
(503348,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nIncreases movement speed by $s3%, grants immunity to movement impairing effects, and prevents you from stopping for $d.\r\n\r\nAfter a short delay, you can recast the ability to stomp the ground, dealing ${$m1+0+$AP*0.1} Physical damage to nearby enemies. If not recast, you will stomp at the end of the duration.'),
(503349,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nIncreases movement speed by $s3%, grants immunity to movement impairing effects, and prevents you from stopping for $d.\r\n\r\nAfter a short delay, you can recast the ability to stomp the ground, dealing ${$m1+0+$AP*0.1} Physical damage to nearby enemies. If not recast, you will stomp at the end of the duration.'),
(503350,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nIncreases movement speed by $s3%, grants immunity to movement impairing effects, and prevents you from stopping for $d.\r\n\r\nAfter a short delay, you can recast the ability to stomp the ground, dealing ${$m1+0+$AP*0.1} Physical damage to nearby enemies. If not recast, you will stomp at the end of the duration.'),
(503351,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nIncreases movement speed by $s3%, grants immunity to movement impairing effects, and prevents you from stopping for $d.\r\n\r\nAfter a short delay, you can recast the ability to stomp the ground, dealing ${$m1+0+$AP*0.1} Physical damage to nearby enemies. If not recast, you will stomp at the end of the duration.'),
(504151,'$?a800317[|cffffffff][|cffff3232]Requires Tower Formation|r\r\nEmbrace your calling, restoring $s1% of your maximum health and Energy, repeating every $t1 sec for $d.'),
(504693,'$?a800317[|cffffffff][|cffff3232]Requires Tower Formation|r\r\nRemoves and grants immunity to disorient and incapacitation effects for $d, and restores $s2% of your maximum health.'),
(572142,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nThrow a massive spear at an enemy, dealing ${$m1+0+$AP*0.665} Physical damage, reducing the effectiveness of any healing by $804572s1% for $804572d.'),
(572143,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nThrow a massive spear at an enemy, dealing ${$m1+0+$AP*0.665} Physical damage, reducing the effectiveness of any healing by $804572s1% for $804572d.'),
(572144,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nThrow a massive spear at an enemy, dealing ${$m1+0+$AP*0.665} Physical damage, reducing the effectiveness of any healing by $804572s1% for $804572d.'),
(572145,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nThrow a massive spear at an enemy, dealing ${$m1+0+$AP*0.665} Physical damage, reducing the effectiveness of any healing by $804572s1% for $804572d.'),
(572146,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nThrow a massive spear at an enemy, dealing ${$m1+0+$AP*0.665} Physical damage, reducing the effectiveness of any healing by $804572s1% for $804572d.'),
(572147,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nThrow a massive spear at an enemy, dealing ${$m1+0+$AP*0.665} Physical damage, reducing the effectiveness of any healing by $804572s1% for $804572d.'),
(572821,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nPlay a harrowing melody, dealing ${$m2+0+$AP*.42} Magic damage and reducing all healing received by enemies within $a1 yds by $s1% for $d.\r\n\r\nIn addition, your next |cffffffffBallad|r within $572820d is free of cost and deals $572820s2% increased damage.'),
(707170,'$?a800317[|cffffffff][|cffff3232]Requires Tower Formation|r\r\nParry the next attack against you within $d. Successfully parrying an attack in this way will disarm the enemy\'s melee weapons for $707722d.'),
(800313,'$?a800317[|cffffffff][|cffff3232]Requires Tower Formation|r\r\nFortify your defenses, reducing all damage taken by $s1% and gaining immunity to stun effects for $d.'),
(802188,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nYou automatically parry the next attack against you. Lasts for 5 attacks or $d.\r\n\r\nWhen you expend a charge you deal ${$m2+0} damage to attackers and heal for ${$501535m1+$501535ppl1+$AP*1} health.'),
(802197,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nCharge an enemy, dealing ${$m2+0+$AP*0.09996} Physical damage and stunning them for $d.'),
(802198,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nInstantly escape the effects of any root or slow and become immune to movement slowing effects for $d.'),
(802283,'$?a800317[|cffffffff][|cffff3232]Requires Tower Formation|r\r\nRaise your shield and lead your allies within $a1 yds, reducing their damage taken by $s1% for $d.'),
(802304,'$?a803417[|cffffffff][|cffff3232]Requires Assault Formation|r\r\nToss a weighted net at an enemy that roots them for $d. While active, the target cannot dodge attacks.'),
(803132,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\n|cff66ccffGrants Motivation|r\r\nSlam the ground, dealing ${$m1+0+$AP*0.4} Physical Damage, scaling with defense rating to nearby enemies$?s572714[ and reducing their casting speed by $572714s1% for $572714d][].\r\n\r\nDeals $803131s2% increased damage to enemies affected by |cffffffffLine Formation|r.'),
(803830,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nCommand nearby allies to hold the line, making them immune to incapacitate, disorient, knockback, and grip effects for $d.'),
(803895,'$?a800317[|cffffffff][|cffff3232]Requires Tower Formation|r\r\nRush towards an ally, intercepting the next melee attack made against them and causing you to critically block the next attack against you. Lasts $d.'),
(806220,'$?a803130[|cffffffff][|cffff3232]Requires Line Formation|r\r\nSmash an enemy with great force, destroying any damage absorption or damage immunity effects and reducing their armor by $s1% for $d.');
