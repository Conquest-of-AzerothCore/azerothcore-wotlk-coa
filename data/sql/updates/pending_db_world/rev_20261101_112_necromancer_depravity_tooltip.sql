-- Depravity 638403: ProcChance 50 renders "$h" as 50, so the client text read "an 50% chance" (#10530)
DELETE FROM `coa_client_spell_description` WHERE `ID` = 638403;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(638403, 'Increases the melee haste of your Undead minions by $s1% and gives their critical melee auto attacks a $h% chance to trigger |cFFFFFFFFBone Club|r, dealing $s2% of the damage dealt as Shadow Damage.', '');
