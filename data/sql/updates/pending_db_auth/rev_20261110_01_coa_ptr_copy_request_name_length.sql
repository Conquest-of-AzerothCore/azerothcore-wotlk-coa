-- Character names are up to 25 letters (MAX_PLAYER_NAME, optional second names), and a copy whose name is taken on
-- the target gets the original name plus its GUID in hex. A copy name over 12 letters failed the completing UPDATE
-- under strict SQL mode, so the request stayed pending and the target loaded it again on every poll.
ALTER TABLE `coa_ptr_copy_request`
    MODIFY `source_name` VARCHAR(25) NOT NULL,
    MODIFY `copy_name` VARCHAR(25) NOT NULL DEFAULT '';
