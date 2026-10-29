-- The Cleansing of Grimepit (175016): using a Trogg Idol (gameobject 2300633) marks it in use until its 2 s
-- auto-close, but its SmartAI despawns it after 1 s, so the flag is never cleared and the idol respawns in use:
-- players see it sparkle but cannot click it, and the server rejects its use, until a world restart.
-- The Ascension client cache has no auto-close for the idol; without one it is never marked in use.
UPDATE `gameobject_template` SET `Data3` = 0 WHERE `entry` = 2300633;
