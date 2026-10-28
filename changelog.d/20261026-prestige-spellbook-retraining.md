Fix Prestige spell retraining and book rank restoration (#8999, #6013).

Remember successful Book of Ascension training in the existing character rank history and
backfill currently known spells on login. Recorded spells cost no gold to relearn. Summoning
a book restores recorded upgrades for its owner when level and prerequisite requirements
are met, using existing spell notifications. First-time training prices remain unchanged.
Lost purchases absent from both existing history and known spells cannot be reconstructed.
No SQL migration. Native in-game verification remains pending.
