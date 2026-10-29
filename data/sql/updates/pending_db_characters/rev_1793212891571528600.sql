-- Player tickets: names are up to 25 letters (MAX_PLAYER_NAME, optional second names). A ticket from or
-- answered by a longer name failed to save under strict SQL mode and was lost at the next restart.
ALTER TABLE `ascension_player_ticket`
    MODIFY `creator` VARCHAR(25) NOT NULL,
    MODIFY `assigned_to` VARCHAR(25) NOT NULL DEFAULT '';

ALTER TABLE `ascension_player_ticket_message`
    MODIFY `sender` VARCHAR(25) NOT NULL,
    MODIFY `read_by` VARCHAR(25) NOT NULL DEFAULT '';
