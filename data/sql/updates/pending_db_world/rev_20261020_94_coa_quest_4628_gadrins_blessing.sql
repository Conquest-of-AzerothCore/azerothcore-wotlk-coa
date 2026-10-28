-- Issue #4628: Gadrin's Blessing (675910, +100% swim speed for 10 min) is applied in Echo Isles (area 368) while the
-- player has Minshina's Skull (808), Practical Prey (817), A Solvent Spirit (818) or Zalazane (826) in the log.
-- No source names the trigger: the spell exists in client and server Spell.dbc, but no quest, creature or spell
-- applies it. The trigger is inferred from the report and was approved by the maintainer on 2026-10-20.
-- Values: spell 675910 and area 368 (Echo Isles, parent 14 Durotar) come from the server Spell.dbc and
-- AreaTable.dbc; no AreaTable row has 368 as its parent. Quests 808/817/818/826 are the Echo Isles quests in
-- quest_template. quest_start_status 10 = (1 << QUEST_STATUS_COMPLETE) | (1 << QUEST_STATUS_INCOMPLETE): the
-- blessing holds while the quest is in the log; once it is rewarded or abandoned no row fits and the area check
-- removes the aura. quest_end 0 so turning in one quest keeps the blessing while another is still taken.
-- racemask 0 and gender 2 (GENDER_NONE) leave the quests' own race limit (AllowableRaces 690) in charge.
DELETE FROM `spell_area` WHERE `spell` = 675910;
INSERT INTO `spell_area` (`spell`, `area`, `quest_start`, `quest_start_status`, `quest_end`, `quest_end_status`,
    `aura_spell`, `racemask`, `gender`, `autocast`) VALUES
(675910, 368, 808, 10, 0, 11, 0, 0, 2, 1),
(675910, 368, 817, 10, 0, 11, 0, 0, 2, 1),
(675910, 368, 818, 10, 0, 11, 0, 0, 2, 1),
(675910, 368, 826, 10, 0, 11, 0, 0, 2, 1);
