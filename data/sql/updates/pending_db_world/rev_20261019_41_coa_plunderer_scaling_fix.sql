-- CoA 8178 follow-up: revert the static 3/4 -> 5/6 bump (wrong approach) and fix the
-- real cause instead. The Defias Plunderer (161736) carries UNIT_NPC_FLAG_QUESTGIVER,
-- and open-world scaling explicitly skips any creature with NPC flags, so this mob never
-- received its per-character scaled view and everyone saw the authored level. Restore the
-- authored 3-4 and clear the spurious questgiver flag so scaling applies like other mobs.
UPDATE `creature_template` SET `minlevel` = 3, `maxlevel` = 4, `npcflag` = 0 WHERE `entry` = 161736;
