-- Native Manastorm segment identity and physical server execution may differ.
--
-- map_id remains the original Manastorm.dbc identity used by native Mode 2.
-- runtime_map_id is an opt-in physical server map override.
-- 0 means "execute on map_id", preserving all existing behavior.
--
-- This is intentionally data-neutral: no segment override is guessed here.
-- Author an override only after the physical source area has been verified.

ALTER TABLE `manastorm_segment`
    ADD COLUMN IF NOT EXISTS `runtime_map_id`
        INT UNSIGNED NOT NULL DEFAULT 0
        AFTER `map_id`;
