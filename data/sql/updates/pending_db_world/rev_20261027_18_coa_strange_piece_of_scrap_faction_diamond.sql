-- A Strange Piece of Scrap (176000) is turned in to Fizzlebolt Gearwhistle at the Rebel Camp (Alliance) or Grizzik
-- Scrapsnatch at Grom'gol Base Camp (Horde). The client tracks the nearest turn-in node, so Horde players in northern
-- Stranglethorn were sent to the Alliance camp. coa_client_quest_super_track gains AllowableRaces (0 = every race):
-- the core sends each player only the nodes allowed for their race.
SELECT IF(
    NOT EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS`
        WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'coa_client_quest_super_track'
            AND `COLUMN_NAME` = 'AllowableRaces'),
    "ALTER TABLE `coa_client_quest_super_track` ADD COLUMN `AllowableRaces` INT UNSIGNED NOT NULL DEFAULT 0 "
        "COMMENT 'race mask allowed to see this node, 0 every race' AFTER `SuperTrackID`",
    'DO 0') INTO @coa_client_quest_super_track_races;
PREPARE `coa_client_quest_super_track_races` FROM @coa_client_quest_super_track_races;
EXECUTE `coa_client_quest_super_track_races`;
DEALLOCATE PREPARE `coa_client_quest_super_track_races`;

UPDATE `coa_client_quest_super_track` SET `AllowableRaces` = 1101
    WHERE `ID` = 33400 AND `ObjectiveIndex` = -1 AND `SuperTrackID` = 20900;
UPDATE `coa_client_quest_super_track` SET `AllowableRaces` = 690
    WHERE `ID` = 33400 AND `ObjectiveIndex` = -1 AND `SuperTrackID` = 20901;
