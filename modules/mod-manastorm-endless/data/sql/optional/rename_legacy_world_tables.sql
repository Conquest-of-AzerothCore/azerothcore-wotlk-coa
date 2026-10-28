-- OPTIONAL, run only when migrating an existing database that already contains the legacy tables.
-- This preserves all existing rows; it does not create/copy/guess data.
RENAME TABLE
  `uw_endless_segment` TO `manastorm_segment`,
  `uw_endless_chaotic_link_spawn` TO `manastorm_chaotic_link_spawn`,
  `uw_endless_scaling_curve` TO `manastorm_scaling_curve`,
  `uw_endless_unlock` TO `manastorm_unlock`,
  `uw_endless_unlock_grant` TO `manastorm_unlock_grant`,
  `uw_endless_unlock_message` TO `manastorm_unlock_message`;
