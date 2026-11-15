-- Daybreak rank 6 (572035) required 503625 at the Sun Cleric trainer, a second "Rank 6" record that is neither in
-- SpellRank.dbc's Daybreak ladder nor a SkillLineAbility row of the class, so the trainer showed rank 6 needing
-- rank 6 (#12438). SpellRank.dbc and spell_ranks (rev_20261026_06) put 572035 directly after rank 5 (503624).
UPDATE `trainer_spell` SET `ReqAbility1` = 503624 WHERE `TrainerId` = 900027 AND `SpellId` = 572035;
