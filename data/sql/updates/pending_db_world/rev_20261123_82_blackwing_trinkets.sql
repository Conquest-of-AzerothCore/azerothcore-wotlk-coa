DELETE FROM `spell_script_names` WHERE
    (`spell_id` IN (909584, 909585, 909586, 909587) AND `ScriptName` = 'spell_blackwing_arcane_infusion')
    OR (`spell_id` IN (909588, 909589, 909590, 909591) AND `ScriptName` = 'spell_blackwing_arcane_explosion')
    OR (`spell_id` = 966348 AND `ScriptName` = 'spell_blackwing_rune_of_metamorphosis')
    OR (`spell_id` = 966351 AND `ScriptName` = 'spell_blackwing_owlkin_rune');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(909584, 'spell_blackwing_arcane_infusion'),
(909585, 'spell_blackwing_arcane_infusion'),
(909586, 'spell_blackwing_arcane_infusion'),
(909587, 'spell_blackwing_arcane_infusion'),
(909588, 'spell_blackwing_arcane_explosion'),
(909589, 'spell_blackwing_arcane_explosion'),
(909590, 'spell_blackwing_arcane_explosion'),
(909591, 'spell_blackwing_arcane_explosion'),
(966348, 'spell_blackwing_rune_of_metamorphosis'),
(966351, 'spell_blackwing_owlkin_rune');

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (909584, 909585, 909586, 909587, 966348, 966350, 966351);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`)
SELECT 909584,
    'Your next direct ranged weapon ability that deals damage within 10 seconds causes an Arcane explosion '
    'within 8 yards of the target. Deals ${$909588m1+1*$RAP} Arcane damage (10% to players).',
    'Your next direct ranged weapon ability that deals damage triggers an Arcane explosion.'
UNION ALL SELECT 909585,
    'Your next direct ranged weapon ability that deals damage within 10 seconds causes an Arcane explosion '
    'within 8 yards of the target. Deals ${$909589m1+1.08*$RAP} Arcane damage (10% to players).',
    'Your next direct ranged weapon ability that deals damage triggers an Arcane explosion.'
UNION ALL SELECT 909586,
    'Your next direct ranged weapon ability that deals damage within 10 seconds causes an Arcane explosion '
    'within 8 yards of the target. Deals ${$909590m1+1.16*$RAP} Arcane damage (10% to players).',
    'Your next direct ranged weapon ability that deals damage triggers an Arcane explosion.'
UNION ALL SELECT 909587,
    'Your next direct ranged weapon ability that deals damage within 10 seconds causes an Arcane explosion '
    'within 8 yards of the target. Deals ${$909591m1+1.24*$RAP} Arcane damage (10% to players).',
    'Your next direct ranged weapon ability that deals damage triggers an Arcane explosion.'
UNION ALL SELECT 966348,
    'Gain a temporary buff based on your active specialization: block, dodge and parry rating for tanks, '
    'Spirit for healers, stacking spell power for spell damage dealers, '
    'or melee and ranged haste and hit rating for weapon damage dealers.', NULL
UNION ALL SELECT 966350,
    'Increases melee and ranged haste rating by $s1 and melee and ranged hit rating by $s2 for $d.',
    'Melee and ranged haste rating increased by $s1 and melee and ranged hit rating increased by $s2.'
UNION ALL SELECT 966351,
    'Direct damaging spell hits grant $966352s1 spell power, stacking up to 10 times until this effect ends.',
    'Direct damaging spell hits grant stacking spell power.';
