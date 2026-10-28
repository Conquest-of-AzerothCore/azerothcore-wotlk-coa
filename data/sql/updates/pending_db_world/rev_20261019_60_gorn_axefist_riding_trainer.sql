-- CoA: Gorn Axefist (75133) <Riding Trainer> had no trainer flag, gossip menu or trainer, so he only offered
-- 'Path to Ascension: Mount Up!'. Give him the same setup as his Alliance counterpart Hank Dullahan (776785):
-- npcflag 83, gossip menu 9950104 and the Orgrimmar riding trainer list (38, the same rows as Hank's 37).
UPDATE `creature_template` SET `npcflag` = 83, `gossip_menu_id` = 9950104 WHERE `entry` = 75133;

DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 75133;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (75133, 38);
