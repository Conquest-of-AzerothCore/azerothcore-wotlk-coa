-- Bloodmage (class 20) conformance core grants, raid-buff exclusivity groups, and missing spell_bonus_data rows:
-- - Native Parry (3127) for Bloodmage (classmask 524288, trainer 900020) per owner ruling Q-bm-5 (Bloodmage ADR 0004).
-- - Raid buff non-stacking groups: Fleshbending (582766) in spell_group 2000181 (raid crit) and
--   Blood-Cursed Weapons (685029) in spell_group 2000182 (raid haste) (Bloodmage ADR 0009).
-- - Missing spell_bonus_data coefficients verified against server Spell.dbc tooltips (Bloodmage ADR 0009).

DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 0 AND `classmask` = 524288 AND `Spell` = 3127;
INSERT INTO `playercreateinfo_spell_custom` (`racemask`, `classmask`, `Spell`, `Note`) VALUES
(0, 524288, 3127, 'Bloodmage: Parry');

DELETE FROM `trainer_spell` WHERE `TrainerId` = 900020 AND `SpellId` = 3127;
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`) VALUES
(900020, 3127, 2, 0, 0, 0, 0, 0, 1);

DELETE FROM `spell_group` WHERE `id` = 2000181 AND `spell_id` = 582766;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES (2000181, 582766);

DELETE FROM `spell_group` WHERE `id` = 2000182 AND `spell_id` = 685029;
INSERT INTO `spell_group` (`id`, `spell_id`) VALUES (2000182, 685029);

DELETE FROM `spell_bonus_data`
    WHERE `entry` IN (704119, 504291, 504101, 680744, 524180, 704120, 681082, 681310,
        520315, 802313, 572116, 536277, 800775, 803392, 800786, 520312, 800772);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(704119, 0.07, 0, 0, 0, 'Bloodmage - Blood Rituals healing power scaling'),
(504291, 0, 0.05, 0, 0.01, 'Bloodmage - Mortal Wounds bleed spell power and attack power scaling'),
(504101, 0, 0.01, 0, 0, 'Bloodmage - Excess Blood periodic healing power scaling'),
(680744, 0, 0.2, 0, 0, 'Bloodmage - Agonizing Pain periodic shadow spell power scaling'),
(524180, 0.1, 0, 0, 0, 'Bloodmage - Darkfallen Lament healing power scaling'),
(704120, 0, 0.193333, 0, 0, 'Bloodmage - Malediction periodic shadow spell power scaling'),
(681082, 0, 0.33, 0, 0, 'Bloodmage - Arterial Bind periodic healing power scaling'),
(681310, 0.33, 0, 0.125, 0, 'Bloodmage - Bloodgale spell power and attack power scaling'),
(520315, 0.3, 0, 0, 0, 'Bloodmage - Heartbreak ally healing power scaling'),
(802313, 0.035, 0, 0, 0, 'Bloodmage - Bloodthorns shadow spell power scaling'),
(572116, 0.035, 0, 0, 0, 'Bloodmage - Greater Bloodthorns shadow spell power scaling'),
(536277, 0, 0, 0.1, 0, 'Bloodmage - Shadow Strength attack power scaling'),
(800775, 0.35, 0, 0, 0, 'Bloodmage - Sanguine Rupture direct shadow spell power scaling'),
(803392, 0.15, 0, 0.1, 0, 'Bloodmage - Hematoma spell power and attack power scaling'),
(800786, 0, 0.2, 0, 0, 'Bloodmage - Sacrificial Rite periodic healing power scaling'),
(520312, 0.7525, 0, 0, 0, 'Bloodmage - Life''s Essence (Blood Feast) healing power scaling'),
(800772, 0, 0.2, 0, 0, 'Bloodmage - Taldaram''s Torment periodic shadow spell power scaling');
