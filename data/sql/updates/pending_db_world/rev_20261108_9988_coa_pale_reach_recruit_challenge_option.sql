-- The Andraste Recruits' challenge option (gossip 100705) showed "(Quest)" as plain text; every other Pale Reach
-- quest option colours it blue, as the realm does.
UPDATE `gossip_menu_option` SET `OptionText` = '|cFF0000FF(Quest)|rI''ve come to help with your training. Prepare for combat!'
    WHERE `MenuID` = 100705 AND `OptionID` = 0;
