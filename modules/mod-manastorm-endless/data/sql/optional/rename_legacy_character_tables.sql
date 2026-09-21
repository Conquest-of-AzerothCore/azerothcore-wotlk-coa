-- OPTIONAL, run only when migrating an existing character database with legacy tables.
RENAME TABLE
  `character_uw_endless_progress` TO `character_manastorm_progress`,
  `character_uw_endless_unlock` TO `character_manastorm_unlock`,
  `character_uw_endless_pending_unlock` TO `character_manastorm_pending_unlock`;
