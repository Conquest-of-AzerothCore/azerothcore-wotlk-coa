Fix Prestige daily max-level credit being lost while leveling in a raid group (#8048).

Synchronize the level objective against the configured Prestige level on level changes,
login, map changes and Chromie interaction. This also repairs existing missing level ticks.
Keep the separate activity objective and all rewards unchanged. No SQL migration.
Focused native regression and real-header syntax checks passed; in-game acceptance pending.
