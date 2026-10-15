-- Issue #495: Life Tap (706788) heals the Reaper for a share of Spectral Warden's damage.
-- The clause needs the summoned guardian (creature_template 100481, added by
-- rev_1790318561486156723.sql) bound to a script so its DamageDealt hook can apply the heal.
UPDATE `creature_template` SET `ScriptName` = 'npc_ascension_reaper_spectral_warden' WHERE `entry` = 100481;
