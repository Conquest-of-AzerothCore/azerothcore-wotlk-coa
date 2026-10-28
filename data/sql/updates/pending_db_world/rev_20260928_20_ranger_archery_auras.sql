-- Hawkeye (800358) is a passive with two effects. Effect 0 is SPELL_EFFECT_APPLY_AREA_AURA_ENEMY carrying
-- SPELL_AURA_PERIODIC_TRIGGER_SPELL (801192, 75% ranged weapon damage, 3 s tick, 30 yd radius). Effect 1 is
-- SPELL_AURA_ADD_FLAT_MODIFIER (aura 107) on SPELLMOD_DURATION, +9999 ms on the class mask of Hunting Shot
-- (801191 and ranks 547202-547208), whose own records have no duration.
-- UnitAura::FillTargetMap (src/server/game/Spells/Auras/SpellAuras.cpp, SPELL_EFFECT_APPLY_AREA_AURA_ENEMY)
-- puts effect 0 on every hostile unit inside the radius, so the periodic trigger fired at anything the
-- Ranger happened to be standing next to, whether or not the target was ever marked by Hunting Shot.
-- The tooltip is "enemies within 30 yds affected by your Hunting Shot", and #4829 / #4928 both report the
-- unfiltered behaviour in play.
-- aura_ascension_ranger_hawkeye answers the area-target question instead of filtering the tick:
-- Aura::CanBeAppliedOn calls Aura::CheckAreaTarget, which runs the AuraScript DoCheckAreaTarget handlers,
-- for every unit in the target map on each 500 ms UpdateTargetMap pass (SpellAuras.cpp,
-- UPDATE_TARGET_MAP_INTERVAL). That map includes the Ranger, who receives effect 1, so the script accepts the
-- owner and refuses an enemy that does not carry the Ranger's own Hunting Shot aura (Unit::GetAuraOfRankedSpell
-- over the 801191 chain). An enemy without the mark is never given effect 0, so it never ticks.
-- Woodland Stalker (705034) needs no script. Its effect 0 is SPELLMOD_EFFECT2 (MiscValue 12), not a critical
-- strike modifier, and its class mask matches only Elude SLS3 (524969), whose effect 1 is
-- SPELL_AURA_ASCENSION_MOD_CRIT_CHANCE at base 0. The client data therefore already limits the +20% to Elude,
-- and rev_20260928_07_ranger_pathfinder_elude.sql applies SLS3 for as long as Elude lasts (#2484).
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_ranger_hawkeye';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(800358, 'aura_ascension_ranger_hawkeye');
