/*
 * Custom script for the Basalthane encounter (Onyxia's Lair, entry 10189-10192).
 *
 * Annihilation Strike (spell 2108206) is a pure SPELL_EFFECT_DUMMY on Ascension's
 * client/server - it carries no native damage or aura effect in our Spell.dbc
 * (StackAmount = 0, no EffectApplyAura). Ascension's own server implements the
 * cleave damage and the stacking -25% Fire resistance / -25% armor debuff with
 * custom server-side logic that doesn't exist on this fork, so it's reimplemented
 * here by hand:
 *
 *  - On hit: deal 40% weapon damage (Fire school) to the target and to any other
 *    enemies within melee-cleave range of it.
 *  - Track a per-target stack count (not a native WoW aura - the spell has no
 *    aura effect to attach one to) and apply the -25%/stack Fire resistance and
 *    armor reduction directly via the unit's stat modifiers.
 *  - Stacks refresh their 30s expiry on every hit and are cleared either when
 *    they expire (checked on player update) or on logout, so nothing lingers on
 *    a player after the pull ends.
 *
 * Tanks are expected to taunt Basalthane off whoever is holding 2-3 stacks,
 * since at that point Fire damage taken is drastically increased.
 */

#include "AllCreatureScript.h"
#include "Containers.h"
#include "Creature.h"
#include "DataMap.h"
#include "GameObject.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridTerrainData.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "ThreatManager.h"
#include "Unit.h"

#include <algorithm>
#include <cmath>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
    constexpr uint32 SPELL_ANNIHILATION_STRIKE = 2108206;
    // The stacking debuff (-25% Fire resistance, -25% armor per stack) is a real native
    // aura (Effect type Apply Aura, not Dummy) - just cast it and let the game show the
    // icon and manage stacking/duration itself instead of hand-rolling it.
    constexpr uint32 SPELL_ANNIHILATION_DEBUFF = 2108211;
    // The real hit: native "Weapon % Damage 40, radius 10yd" per difficulty - the
    // engine handles the cleave itself, no manual damage calc or nearby-unit loop needed.
    constexpr uint32 SPELL_ANNIHILATION_HIT_D0 = 2108207;
    constexpr uint32 SPELL_ANNIHILATION_HIT_D1 = 2108208;
    constexpr uint32 SPELL_ANNIHILATION_HIT_D2 = 2108209;
    constexpr uint32 SPELL_ANNIHILATION_HIT_D3 = 2108210;
    // Annihilation Strike's own cast scheduling, moved from SmartAI to C++ (2026-10-02,
    // same reasoning as Eruption/Inferno Trail) - this is the only way Cracked Armor's
    // real "extends Annihilation Strike/Eruption cooldowns by 20s" interaction (found via
    // WeakAuras decode, never implemented until now) can actually nudge the timer: native
    // SmartScript::GetEvents() only exposes a const reference, there's no public API to
    // adjust a running SmartAI timer from outside. CONFIRMED range from real kill logs,
    // same value for both the opener and every repeat (smart_scripts id=21's own
    // event_param1-4, all four were 18000/24000/18000/24000 - no separate opener timing).
    constexpr uint32 ANNIHILATION_CAST_MIN_MS = 18000;
    constexpr uint32 ANNIHILATION_CAST_MAX_MS = 24000;
    // From WeakAuras decode: Cracked Armor's proc, besides the self-debuff, also pushes
    // Annihilation Strike's and Eruption's next cast back by 20s each time it applies.
    constexpr uint32 CRACKED_ARMOR_COOLDOWN_EXTEND_MS = 20000;

    // Inferno Trail (2108217) and Eruption (2108227) are, like Annihilation Strike,
    // pure SPELL_EFFECT_DUMMY with no native damage/aura in our Spell.dbc - reimplemented here.
    constexpr uint32 SPELL_INFERNO_TRAIL = 2108217;
    constexpr uint32 SPELL_INFERNO_TRAIL_PRE = 2108218; // "Inferno Trail - Hidden - Pre", real cast-start telegraph
    // Real native stacking DoT, per difficulty - just delegate to it
    constexpr uint32 SPELL_FLASH_BURN_D0 = 2108201;
    constexpr uint32 SPELL_FLASH_BURN_D1 = 2108202;
    constexpr uint32 SPELL_FLASH_BURN_D2 = 2108203;
    constexpr uint32 SPELL_FLASH_BURN_D3 = 2108204;
    // A cone, not a straight line (confirmed against a real kill recording - it fans
    // out wider the further it travels, not a constant-width strip).
    constexpr float INFERNO_TRAIL_LINE_LENGTH = 100.0f; // "Unlimited Range" per the tooltip - keeps going until it leaves the room
    // Forward spacing must be bigger than the same-row gap below - rows should not
    // overlap each other (that's what was stacking hundreds of swirls on top of one
    // another), only swirls within the same row should overlap a little.
    constexpr float INFERNO_TRAIL_VISUAL_STEP = 3.5f; // forward spacing between rows (was 1.0 - rows were overlapping each other)
    constexpr int INFERNO_TRAIL_CONE_START_SWIRLS = 2; // starts as 2 overlapping swirls right at the boss
    constexpr float INFERNO_TRAIL_GROWTH_STEP_DIST = 5.0f; // +1 swirl in the row every 5 yards traveled
    constexpr float INFERNO_TRAIL_SWIRL_OVERLAP_GAP = 1.8f; // gap between adjacent swirls in a row - small so they overlap
    // Cone stops widening past this distance (both the visual and the hitbox use it,
    // so the danger zone never grows wider than what the raid can actually see).
    constexpr float INFERNO_TRAIL_WIDTH_CAP_DIST = 40.0f;
    // Hit detection now checks "am I standing inside one of the actual swirls" rather
    // than a smooth mathematical cone - the two had drifted out of sync once the
    // visual became a discrete grid of rows/swirls, so players standing under a
    // visible swirl but off the cone's exact centerline weren't getting hit. Matches
    // the real native hit spell's own "radius 3yd" per difficulty.
    constexpr float INFERNO_TRAIL_HIT_RADIUS = 3.0f;
    // Real native "School Damage, radius 3yd" per difficulty - casting a chain of these
    // along the line both deals the damage and (since each one carries its own real
    // spell visual) renders the actual chain-of-swirls trail, instead of one cast-start marker.
    constexpr uint32 SPELL_INFERNO_TRAIL_HIT_D0 = 2108219;
    constexpr uint32 SPELL_INFERNO_TRAIL_HIT_D1 = 2108220;
    constexpr uint32 SPELL_INFERNO_TRAIL_HIT_D2 = 2108221;
    constexpr uint32 SPELL_INFERNO_TRAIL_HIT_D3 = 2108222;
    constexpr uint32 SPELL_CRACKED_ARMOR = 2108234;
    // Real native area-aura-enemy (Fire), confirmed via a raw Spell.dbc parse 2026-10-02:
    // Effect 1 is SPELL_EFFECT_APPLY_AREA_AURA_ENEMY (-50% healing done, radius 500yd -
    // effectively room-wide) + Effect 3 is a self-only SPELL_AURA_DUMMY marker on the
    // caster - both implicit-targeted TARGET_UNIT_CASTER, so (unlike Heat Splash/the
    // Annihilation hit) this one's correctly centered already with a plain self-cast, no
    // WORLD_TRIGGER relocation needed. DurationIndex -1 = permanent/infinite, confirmed
    // from a real kill log (applied, never expired on its own, only gone because the boss
    // died) - needs explicit removal in ClearAllBasalthaneDebuffs like Flash Burn.
    // CONFIRMED (2026-10-02, user's own combat-log dig): only triggers when the SEARING
    // pillar specifically shatters (not Crumbling/Volatile) - see the pillar-type branch
    // in spell_basalthane_annihilation_strike::HandleDummy.
    constexpr uint32 SPELL_BLISTERING_TRAUMA = 2108236;

    constexpr uint32 SPELL_ERUPTION = 2108227;
    constexpr uint32 SPELL_ERUPTION_PRE = 2108239; // "Eruption - Hidden - Pre", real cast-start telegraph
    // Real native periodic-damage area aura, per difficulty
    constexpr uint32 SPELL_MAGMA_POOL_D0 = 2108230;
    constexpr uint32 SPELL_MAGMA_POOL_D1 = 2108231;
    constexpr uint32 SPELL_MAGMA_POOL_D2 = 2108232;
    constexpr uint32 SPELL_MAGMA_POOL_D3 = 2108233;
    // The actual explosion: real native School Damage + Knockback + a stacking
    // "+100% Fire damage taken" debuff, found separately from the 2108xxx family
    // (D0-D3, one spell id per difficulty).
    constexpr uint32 SPELL_ERUPTION_EXPLOSION_D0 = 2105077;
    constexpr uint32 SPELL_ERUPTION_EXPLOSION_D1 = 2105078;
    constexpr uint32 SPELL_ERUPTION_EXPLOSION_D2 = 2105079;
    constexpr uint32 SPELL_ERUPTION_EXPLOSION_D3 = 2105080;
    // Heat Splash: real native School Damage (Fire), per difficulty - confirmed via a
    // raw Spell.dbc parse (ImplicitTargetA/B = TARGET_UNIT_TARGET_ENEMY + DEST_AREA_ENEMY,
    // corrected 2026-10-02 - see CastHeatSplashAt and AnnihilationHitSpellFor's comments
    // for the enum mix-up this fixes), so it's just a direct cast onto whichever unit
    // Eruption hit - no trigger relocation needed. Part of the Eruption impact, alongside
    // the explosion and Magma Pool.
    constexpr uint32 SPELL_HEAT_SPLASH_D0 = 2108251;
    constexpr uint32 SPELL_HEAT_SPLASH_D1 = 2108252;
    constexpr uint32 SPELL_HEAT_SPLASH_D2 = 2108253;
    constexpr uint32 SPELL_HEAT_SPLASH_D3 = 2108254;
    constexpr float ERUPTION_BURST_RADIUS = 6.0f; // GUESS: still used for who "counts as hit" for the split damage
    // Magma Pool's own Spell.dbc duration is 168 hours - a failsafe cap, not the real
    // lifetime. Normal/Heroic (10189/10190): expires on its own after 20s. Mythic/Ascended
    // (10191/10192): stays down permanently until the pull ends (see the cleanup below).
    constexpr int32 MAGMA_POOL_DURATION_TIMED_MS = 20000; // GUESS
    constexpr uint32 ENTRY_BASALTHANE_NORMAL = 10189;
    constexpr uint32 ENTRY_BASALTHANE_HEROIC = 10190;
    constexpr uint32 ENTRY_BASALTHANE_MYTHIC = 10191;
    constexpr uint32 ENTRY_BASALTHANE_ASCENDED = 10192;

    // Pillar mechanic (corrected): it's not the ooze - when Basalthane lands
    // Annihilation Strike while standing near a pillar, it shatters - Igneous Impact
    // (2108212, real native School Damage AoE) goes off, and Basalthane gets "caught in
    // the blast" (2108216, real stun) as a bonus damage window.
    //
    // Pillars are the real Ascension pillar creatures (2026-09-25, entries 10186/10187/
    // 10188 - "Volatile"/"Crumbling"/"Searing Pillar", found via client cache lookup),
    // not the earlier placeholder gameobject (entry 68371/9500100, since replaced by
    // creature spawns 9500001-9500003 - see rev_20260925_35). "Shattering" a pillar now
    // means killing the creature outright (KillSelf(), no combat/damage math needed -
    // they're UNIT_FLAG_NON_ATTACKABLE so nothing else can touch them) rather than
    // phase-hiding a gameobject.
    constexpr uint32 ENTRY_PILLAR_1 = 10186; // Volatile Pillar
    constexpr uint32 ENTRY_PILLAR_2 = 10187; // Crumbling Pillar
    constexpr uint32 ENTRY_PILLAR_3 = 10188; // Searing Pillar
    constexpr uint32 PILLAR_ENTRIES[] = { ENTRY_PILLAR_1, ENTRY_PILLAR_2, ENTRY_PILLAR_3 };
    // CONFIRMED 2026-10-02 (user's own in-game knowledge, later refined after they asked
    // someone who ran this encounter on real Ascension): each pillar does something
    // different when it shatters, beyond the shared Igneous Impact/Caught in the Blast/
    // Cracked Armor/Flash Burn-clear package every pillar gets:
    //  - Searing shattering -> Blistering Trauma (see SPELL_BLISTERING_TRAUMA above)
    //  - Crumbling shattering -> 6 Molten Blood oozes total, in waves every 5s, each
    //    wave randomly 1 or 2 oozes - when a wave is 2, they go to DIFFERENT points
    //    (never both at once on the same spot), drawn from the 2 farthest-from-boss
    //    points (pool size 2, matching the max wave size of 2).
    //  - Volatile shattering -> 30 Molten Blood oozes total, in waves every 5s, each
    //    wave randomly 2 or 3 oozes, drawn from the 3 farthest-from-boss points (pool
    //    size 3, matching the max wave size of 3 - same "pool size == max wave size,
    //    no point repeats within a wave" rule as Crumbling, just with bigger numbers).
    // This is fully ADDITIVE to - not a replacement for - the independent periodic
    // spawner (MOLTEN_BLOOD_SPAWN_INTERVAL_MIN/MAX_MS below): both run at the same time,
    // confirmed by the user explicitly ("den normale spawn timer kører stadig i
    // baggrunden, de er independant").
    // NOTE: only one pillar's blob-wave state is tracked at a time (BasalthaneState has
    // a single pillarBlobs* set, not per-pillar-type) - if a second pillar shatters
    // while an earlier one's wave sequence is still running, the new one overwrites the
    // old one's remaining count. Pillars don't respawn mid-fight so this can only happen
    // with 2-3 overlapping bursts in the same pull; accepted as a rare edge case rather
    // than adding a second parallel wave tracker for it.
    constexpr int PILLAR_BLOB_TOTAL_CRUMBLING = 6;
    constexpr int PILLAR_BLOB_TOTAL_VOLATILE = 30;
    // Retuned 2026-10-02 (user corrected after double-checking with someone who ran this
    // on real Ascension): both intervals are 5s, and Volatile's wave size is random 2-3
    // (not a fixed 3) - its pool stays at 3 farthest points, same no-repeats-within-a-
    // wave rule, just the actual spawn count per wave varies now like Crumbling's does.
    constexpr uint32 PILLAR_BLOB_INTERVAL_CRUMBLING_MS = 5000;
    constexpr uint32 PILLAR_BLOB_INTERVAL_VOLATILE_MS = 5000;
    constexpr int PILLAR_BLOB_WAVE_MIN_CRUMBLING = 1;
    constexpr int PILLAR_BLOB_WAVE_MAX_CRUMBLING = 2;
    constexpr int PILLAR_BLOB_WAVE_MIN_VOLATILE = 2;
    constexpr int PILLAR_BLOB_WAVE_MAX_VOLATILE = 3;
    constexpr uint32 ENTRY_MOLTEN_BLOOD_OOZE = 310189; // reverted after diagnostic test 2026-09-24 confirmed entry 68 worked normally (spawned, stayed visible, despawned after the expected ~90s timer) - the bug is specific to 310189's own config, not the spawn mechanism/room/grid. Prime suspect: its model (DisplayID 60375, creature_model_info BoundingRadius 0.5/CombatReach 1.5) may be broken/invisible on this custom client.
    // CONFIRMED 2026-10-02 (user's own combat-log dig, cross-referencing per-pull ooze
    // death-damage totals against known per-difficulty boss total-HP figures): the ooze
    // ALSO flexes per-player like Basalthane himself, not a fixed HP per difficulty.
    // Mythic/Ascended are 25-man-locked (always x25), matching Basalthane's own
    // coa_boss_flex convention for those two difficulties - Normal/Heroic flex
    // dynamically with the instance's actual headcount (clamped 10-25).
    // Deliberately NOT routed through the shared coa_boss_flex table: that table keys
    // off `entry % 100000` (AC's own classic-raid "+100000/+200000/+300000 per
    // difficulty" convention), and 310189 == 10189 + 300000 - a numeric coincidence that
    // made the module think this ooze IS a difficulty-variant of Basalthane and apply
    // HIS per-player HP to it. Scaling the ooze's HP directly here avoids the collision
    // entirely instead of special-casing the shared module for one unlucky entry number.
    constexpr uint32 MOLTEN_BLOOD_HP_PER_PLAYER_NORMAL = 6050;
    constexpr uint32 MOLTEN_BLOOD_HP_PER_PLAYER_HEROIC = 8540;
    constexpr uint32 MOLTEN_BLOOD_HP_PER_PLAYER_MYTHIC = 13150;
    constexpr uint32 MOLTEN_BLOOD_HP_PER_PLAYER_ASCENDED = 19900;
    constexpr uint32 MOLTEN_BLOOD_FLEX_MIN_PLAYERS = 10;
    constexpr uint32 MOLTEN_BLOOD_FLEX_MAX_PLAYERS = 25;
    // CONFIRMED 2026-10-02 (user's own in-game tooltip check, two screenshots):
    //  - Pyroclastic Splash (2108241-44, real native School Damage, radius 3yd): "the
    //    Molten Blood inflicts ... Fire damage to nearby enemies", Procs from Molten
    //    Blood (2108240, the ooze's own periodic debuff). Deliberately NOT applying
    //    2108240 itself: its DBC data (EffectAuraPeriod 1000ms, EffectTriggerSpell
    //    hardcoded to 2108241) fires its own native periodic trigger the instant it's
    //    applied, always the D0/Normal Splash regardless of actual difficulty - an
    //    earlier version of this file self-cast it anyway "just for the icon," which an
    //    external review caught as a real double-proc bug (Normal got it twice;
    //    Heroic+ got a correct tick plus an extra wrong-strength Normal one). Splash
    //    damage is driven entirely by the manual per-difficulty timer in
    //    allcreaturescript_basalthane_ooze_pyroclastic below instead - no native trigger
    //    involved at all, so no icon, but also no way for the two to double up again.
    //  - Pyroclastic Explosion (2108245-48, radius 100yd/room-wide): "The Molten Blood
    //    merges with Basalthane in a violent explosion", Cast by NPCs: Molten Blood -
    //    fires when the ooze actually reaches/touches the boss (not the old 4yd
    //    "become aggressive" proximity - real contact range). The ooze is consumed
    //    (dies) in the same moment; Basalthane gains a Molten Blood stack (2108237)
    //    from the merge instead of the old continuous "stack while ooze within 10yd"
    //    mechanic, which this replaces entirely.
    // The ooze is attackable by players from spawn (already hostile faction, no
    // NON_ATTACKABLE flag) - the old SmartAI "become aggressive at 4yd"/"stop following"
    // rows are obsolete under this design and were removed from smart_scripts.
    constexpr uint32 SPELL_MOLTEN_BLOOD_SELF_BUFF = 2108237;
    constexpr uint32 SPELL_PYROCLASTIC_SPLASH_D0 = 2108241;
    constexpr uint32 SPELL_PYROCLASTIC_SPLASH_D1 = 2108242;
    constexpr uint32 SPELL_PYROCLASTIC_SPLASH_D2 = 2108243;
    constexpr uint32 SPELL_PYROCLASTIC_SPLASH_D3 = 2108244;
    constexpr uint32 SPELL_PYROCLASTIC_EXPLOSION_D0 = 2108245;
    constexpr uint32 SPELL_PYROCLASTIC_EXPLOSION_D1 = 2108246;
    constexpr uint32 SPELL_PYROCLASTIC_EXPLOSION_D2 = 2108247;
    constexpr uint32 SPELL_PYROCLASTIC_EXPLOSION_D3 = 2108248;
    constexpr uint32 MOLTEN_BLOOD_SPLASH_TICK_MS = 1000;
    constexpr float MOLTEN_BLOOD_MERGE_RANGE = 1.5f; // real contact, not the old 4yd proximity
    constexpr float ANNIHILATION_PILLAR_RANGE = 6.0f; // GUESS
    constexpr uint32 SPELL_IGNEOUS_IMPACT = 2108212;
    constexpr uint32 SPELL_CAUGHT_IN_THE_BLAST = 2108216;
    // CONFIRMED 2026-10-02 (user's own in-game tooltip check): Basalthane also gets
    // dazed (generic stock spell, not Basalthane-specific - same ID used all over
    // vanilla WoW) when a pillar shatters, alongside the stun - -50% movement speed,
    // 4s, dispelled by mount.
    constexpr uint32 SPELL_DAZED = 1604;
    // CONFIRMED from real kill combat logs: Cracked Armor lasts ~20.0s each time it's
    // applied (self-debuff on Basalthane from a pillar stun, not a tank debuff).
    constexpr uint32 CRACKED_ARMOR_DURATION_SECONDS = 20;

    // Shattered pillars are killed outright (see ShatterPillar) and force-respawned
    // with Creature::Respawn(true) the instant a wipe/kill/evade happens, rather than
    // waiting on their own respawntimesecs. Confirmed 2026-09-23 (back when this was
    // still gameobject phase-hiding): pillars only come back on wipe/kill/evade - no
    // mid-fight respawn. Don't re-add one without the user asking for it again.

    // Cracked Armor is self-applied to Basalthane by the pillar-stun (see
    // spell_basalthane_annihilation_strike::HandleDummy), not a tank debuff - tracked
    // here and force-removed after CRACKED_ARMOR_DURATION_SECONDS since we can't trust
    // this custom spell's own DBC duration field (same pattern as Magma Pool's bogus
    // 168h cap elsewhere in this file).

    // CONFIRMED from real kill logs (cross-checked across 2 separate kills): raid-wide
    // Flash Burn stacks reapply on a clean, fixed 15.0s cycle the whole fight - this is
    // NOT explained by Inferno Trail hits (its own cast cadence is irregular, 13-34s,
    // and doesn't line up with this). Independent periodic mechanic, first tick 15s
    // after the opener.
    constexpr uint32 FLASH_BURN_RAIDWIDE_TICK_MS = 15000;

    // Inferno Trail is scheduled from C++ (not SmartAI, unlike Fierce Blow/Annihilation
    // Strike/Eruption) so it can give those two real priority: CONFIRMED cadence from
    // real kill logs is a clean 14s cycle that sometimes stretches to 28s when it loses
    // out to one of them - implemented here as an honest "is the boss already mid-cast
    // on something (only Annihilation Strike/Eruption ever share this cast slot) right
    // when Inferno Trail is due? If so, skip this cycle entirely" check, rather than the
    // earlier randomized-interval approximation (removed 2026-09-24, user asked for the
    // real thing instead).
    constexpr uint32 INFERNO_TRAIL_CAST_INTERVAL_MS = 14000;

    // Eruption moved from native SmartAI to C++ (2026-09-30) so its target can
    // exclude both the tank AND the off-tank - SmartAI's target_type=6
    // (SMART_TARGET_HOSTILE_RANDOM_NOT_TOP) only excludes the single top-threat
    // unit, there's no native option to exclude a second, separately-tracked
    // off-tank too. Timing unchanged from the old smart_scripts rows: first
    // cast at 39s (WeakAuras data), then 70-80s random on Normal/Heroic/Mythic,
    // fixed 50s on Ascended (user wants a faster pace there).
    constexpr uint32 ERUPTION_INITIAL_CAST_MS = 39000;
    constexpr uint32 ERUPTION_REPEAT_MIN_MS = 70000;
    constexpr uint32 ERUPTION_REPEAT_MAX_MS = 80000;
    constexpr uint32 ERUPTION_ASCENDED_REPEAT_MS = 50000;

    // Molten Blood ooze spawning - moved from SmartAI to C++ (2026-09-24) because the
    // boss gets dragged around this room (not tanked in the middle), so "spawn at one of
    // the 3 points farthest from the boss" has to be computed against his CURRENT
    // position every time, which a static SmartAI random-point target can't do. All 10
    // points below were walked and .gps'd by the user around the room's usable area
    // after a vmap/mmap re-extraction; every spawn picks among the 3 currently farthest
    // from Basalthane, not a fixed subset. Z values are used as-is (no ground-height
    // requery), same anti-bad-Z precaution as everywhere else in this room - see the
    // room-bug notes in memory for why that matters here.
    // CONFIRMED from real kill logs (2026-09-24): counting distinct Molten Blood GUIDs
    // per 60s bucket across two separate kills showed a roughly steady ~5-6 new oozes
    // per minute for the whole fight (not accelerating) - averages to ~10-12s between
    // spawns (193s/17 oozes = 11.4s avg in one kill, 307s/23 oozes = 13.3s avg in
    // another). Replaces the old 45s GUESS, which was far too slow. Randomized range
    // instead of a fixed value to reflect the real data's natural clustering (some
    // spawns landed within ~1-2s of each other, others 20-30s apart).
    constexpr uint32 MOLTEN_BLOOD_SPAWN_INTERVAL_MIN_MS = 8000;
    constexpr uint32 MOLTEN_BLOOD_SPAWN_INTERVAL_MAX_MS = 16000;
    constexpr uint32 MOLTEN_BLOOD_DESPAWN_MS = 90000; // matches the old SmartAI config (action_param3)
    struct MoltenBloodSpawnPoint { float x, y, z; };
    constexpr MoltenBloodSpawnPoint MOLTEN_BLOOD_SPAWN_POINTS[] = {
        { -240.27287f,  35.508114f, -78.784676f },
        { -263.4401f,   12.799386f, -78.87359f  },
        { -271.89877f, -19.737661f, -77.90959f  },
        { -237.37097f, -58.87336f,  -78.87458f  },
        { -211.72928f, -63.637604f, -78.51081f  },
        { -186.05104f, -46.86159f,  -78.688255f },
        { -175.00475f, -26.678469f, -78.85377f  },
        { -171.39236f,  -9.649658f, -78.56807f  },
        { -178.40074f,   9.963768f, -78.81197f  },
        { -195.8838f,   29.746857f, -78.93467f  },
    };

    // All per-pull Basalthane state lives here, attached directly to the boss's own
    // Creature object via AC's CustomData/DataMap mechanism, instead of in file-level
    // globals keyed by ObjectGuid. Creature GUIDs are only unique within a single map,
    // so two simultaneous Onyxia's Lair instances could have two Basalthane creatures
    // sharing the same GUID - with the old global-map approach, that meant instance B's
    // idle cleanup could erase/reset instance A's actively-fighting state (and, under
    // MapUpdate.Threads > 1, was an outright unsynchronized data race). CustomData is
    // physically attached to the specific Creature C++ object, so two different
    // instances' Basalthane creatures - distinct objects regardless of GUID - always
    // get their own, fully isolated copy automatically. Fixes the "encounter state is
    // global and collides across instances" review finding without having to replace
    // SmartAI (which still drives Fierce Blow/Berserk/melee/threat for this boss).
    struct BasalthaneState : DataMap::Base
    {
        bool flashBurnOpenerApplied = false;
        uint32 flashBurnNextTick = 0;
        // CORRECTED 2026-10-02 (user's own in-game knowledge): Smoldering Vengeance is
        // NOT a pull opener - it's assigned entirely on pillar shatter, to whoever has
        // current aggro (the tank) at that exact moment, and switches holder at the next
        // shatter if aggro has changed by then. Nobody has it before the first pillar
        // breaks. Tracks the current holder so the aura can be stripped from them when
        // it moves to someone else (CastSpell alone would leave both players with it).
        ObjectGuid smolderingVengeanceHolder;
        uint32 infernoTrailNextCast = 0;
        uint32 eruptionNextCast = 0;
        uint32 annihilationNextCast = 0;
        uint32 moltenBloodNextSpawn = 0;
        // Pillar-triggered blob burst (Crumbling/Volatile shattering) - independent of
        // moltenBloodNextSpawn above, see PILLAR_BLOB_* comment. 0 remaining = idle.
        // pool/interval/wave-size are copied in from the PILLAR_BLOB_* constants for
        // whichever pillar type triggered the active burst (see the NOTE on only one
        // burst being tracked at a time).
        int pillarBlobsRemaining = 0;
        uint32 pillarBlobNextSpawn = 0;
        uint32 pillarBlobIntervalMs = 0;
        size_t pillarBlobPoolSize = 0;
        int pillarBlobWaveMin = 0;
        int pillarBlobWaveMax = 0;
        uint32 crackedArmorUntil = 0; // 0 = not currently active
        bool hasInfernoTrailDirection = false;
        float infernoTrailDirX = 0.0f;
        float infernoTrailDirY = 0.0f;
        std::unordered_set<ObjectGuid::LowType> hiddenPillars;
        Spell* lastGenericSpell = nullptr;
    };

    constexpr char BASALTHANE_STATE_KEY[] = "custom.basalthane.state";

    BasalthaneState& StateFor(Creature* boss)
    {
        return *boss->CustomData.GetDefault<BasalthaneState>(BASALTHANE_STATE_KEY);
    }

    // This custom room straddles a map grid boundary (some of the 10 points sit in
    // a different grid than Basalthane's own). CONFIRMED 2026-09-24: an ooze spawned
    // in a grid that isn't currently loaded still exists and functions server-side
    // (it kept granting Molten Blood stacks to the boss - visible as stacks climbing
    // on him) but is invisible to players, which read as "despawns instantly" until
    // the boss buff gave it away. Only consider points whose grid is actually loaded
    // right now, so we never place one somewhere players can't see it.
    //
    // pointCount: how many of the farthest-from-boss candidates to return - 3 for the
    // regular periodic spawner, 2 or 3 for a pillar-triggered blob wave depending on
    // pillar type (see PILLAR_BLOB_* comment above).
    std::vector<MoltenBloodSpawnPoint const*> FarthestLoadedMoltenBloodPoints(Creature* boss, size_t pointCount)
    {
        float bx = boss->GetPositionX();
        float by = boss->GetPositionY();

        std::vector<MoltenBloodSpawnPoint const*> byDistance;
        for (auto const& pt : MOLTEN_BLOOD_SPAWN_POINTS)
            if (boss->GetMap()->IsGridLoaded(pt.x, pt.y))
                byDistance.push_back(&pt);

        std::sort(byDistance.begin(), byDistance.end(), [bx, by](MoltenBloodSpawnPoint const* a, MoltenBloodSpawnPoint const* b)
        {
            float da = (a->x - bx) * (a->x - bx) + (a->y - by) * (a->y - by);
            float db = (b->x - bx) * (b->x - bx) + (b->y - by) * (b->y - by);
            return da > db;
        });

        if (byDistance.size() > pointCount)
            byDistance.resize(pointCount);
        return byDistance;
    }

    // FOUND 2026-09-24 - the real root cause of the "despawns after ~90s, no death,
    // everywhere/every-config" mystery: TEMPSUMMON_TIMED_OR_CORPSE_DESPAWN's timer
    // (see TempSummon::Update in TemporarySummon.cpp) only counts down while the
    // summon is OUT of combat - it resets to full lifetime whenever IsInCombat() is
    // true. Since this ooze is deliberately passive and never enters combat, that
    // timer just counted down from the moment it spawned and unsummoned it ~90s
    // later no matter where it was, what model it had, or whether it could move -
    // explaining every single symptom chased over several failed diagnostics
    // (terrain, grid, gravity, Swim, SmartAI react state). TEMPSUMMON_TIMED_DESPAWN
    // counts down unconditionally regardless of combat state, and death still
    // unsummons instantly regardless of summon type (handled earlier in
    // TempSummon::Update, before the type-specific switch). This is the actual fix -
    // the SetDisableGravity/IsGridLoaded workarounds above are left in as harmless
    // extra safety nets, not because they were wrong, just not the real cause.
    uint32 GetDifficultyEntry(Unit* caster); // defined below, forward-declared for ApplyMoltenBloodFlexHealth

    uint32 MoltenBloodHpPerPlayerFor(uint32 difficultyEntry)
    {
        switch (difficultyEntry)
        {
            case ENTRY_BASALTHANE_HEROIC:   return MOLTEN_BLOOD_HP_PER_PLAYER_HEROIC;
            case ENTRY_BASALTHANE_MYTHIC:   return MOLTEN_BLOOD_HP_PER_PLAYER_MYTHIC;
            case ENTRY_BASALTHANE_ASCENDED: return MOLTEN_BLOOD_HP_PER_PLAYER_ASCENDED;
            default:                        return MOLTEN_BLOOD_HP_PER_PLAYER_NORMAL;
        }
    }

    uint32 PyroclasticSplashSpellFor(uint32 difficultyEntry)
    {
        switch (difficultyEntry)
        {
            case ENTRY_BASALTHANE_HEROIC:   return SPELL_PYROCLASTIC_SPLASH_D1;
            case ENTRY_BASALTHANE_MYTHIC:   return SPELL_PYROCLASTIC_SPLASH_D2;
            case ENTRY_BASALTHANE_ASCENDED: return SPELL_PYROCLASTIC_SPLASH_D3;
            default:                        return SPELL_PYROCLASTIC_SPLASH_D0;
        }
    }

    uint32 PyroclasticExplosionSpellFor(uint32 difficultyEntry)
    {
        switch (difficultyEntry)
        {
            case ENTRY_BASALTHANE_HEROIC:   return SPELL_PYROCLASTIC_EXPLOSION_D1;
            case ENTRY_BASALTHANE_MYTHIC:   return SPELL_PYROCLASTIC_EXPLOSION_D2;
            case ENTRY_BASALTHANE_ASCENDED: return SPELL_PYROCLASTIC_EXPLOSION_D3;
            default:                        return SPELL_PYROCLASTIC_EXPLOSION_D0;
        }
    }

    // Same per-player headcount rule as mod-coa-raid-difficulty's own CountPlayers:
    // every non-GM player in the map, clamped 10-25.
    uint32 CountFlexPlayers(Map* map)
    {
        uint32 count = 0;
        map->DoForAllPlayers([&count](Player* player)
        {
            if (!player->IsGameMaster())
                ++count;
        });
        return std::clamp(count, MOLTEN_BLOOD_FLEX_MIN_PLAYERS, MOLTEN_BLOOD_FLEX_MAX_PLAYERS);
    }

    void ApplyMoltenBloodFlexHealth(Creature* boss, Creature* ooze)
    {
        uint32 difficultyEntry = GetDifficultyEntry(boss);
        bool locked25 = (difficultyEntry == ENTRY_BASALTHANE_MYTHIC || difficultyEntry == ENTRY_BASALTHANE_ASCENDED);
        uint32 players = locked25 ? MOLTEN_BLOOD_FLEX_MAX_PLAYERS : CountFlexPlayers(boss->GetMap());
        uint32 health = MoltenBloodHpPerPlayerFor(difficultyEntry) * players;

        ooze->SetCreateHealth(health);
        ooze->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
        ooze->UpdateMaxHealth();
        ooze->SetHealth(health);
    }

    void SpawnMoltenBloodOozeAt(Creature* boss, MoltenBloodSpawnPoint const* pt)
    {
        if (Creature* ooze = boss->SummonCreature(ENTRY_MOLTEN_BLOOD_OOZE, pt->x, pt->y, pt->z, 0.0f, TEMPSUMMON_TIMED_DESPAWN, MOLTEN_BLOOD_DESPAWN_MS))
        {
            ooze->SetDisableGravity(true);
            ApplyMoltenBloodFlexHealth(boss, ooze);
            // CORRECTED 2026-10-02 (external review caught a real bug): this used to
            // also self-cast SPELL_MOLTEN_BLOOD_DEBUFF (2108240) here purely for its
            // visible icon, but that spell's own DBC data has a real periodic trigger
            // baked in (EffectAuraPeriod 1000ms, EffectTriggerSpell hardcoded to the
            // D0/Normal Pyroclastic Splash) - applying it ALSO independently fires the
            // native trigger every second, on top of the manual per-difficulty tick in
            // allcreaturescript_basalthane_ooze_pyroclastic below. Normal got duplicate
            // ticks; Heroic/Mythic/Ascended got an extra wrong-strength Normal tick on
            // top of the correct one. The icon was cosmetic only and isn't needed for
            // the real damage (the manual timer fully handles that), so removed
            // entirely rather than fighting the native trigger with an AuraScript.
        }
    }

    // Periodic spawner: one ooze, randomly at any of the 3 farthest-from-boss points.
    void SpawnMoltenBloodAtFarthestPoints(Creature* boss, size_t pointCount)
    {
        auto pool = FarthestLoadedMoltenBloodPoints(boss, pointCount);
        if (pool.empty())
            return;
        SpawnMoltenBloodOozeAt(boss, Acore::Containers::SelectRandomContainerElement(pool));
    }

    // Pillar-triggered blob wave: spawns `waveCount` oozes (clamped to the candidate
    // pool, which should already equal waveCount at the caller - see PILLAR_BLOB_*
    // comment), each at a DIFFERENT point drawn from the pool - sampling without
    // replacement (pick a random remaining point, spawn, remove it from the pool) so a
    // multi-ooze wave never doubles up two oozes on the same spot.
    void SpawnMoltenBloodBlobWave(Creature* boss, size_t poolSize, int waveCount)
    {
        auto pool = FarthestLoadedMoltenBloodPoints(boss, poolSize);
        size_t toSpawn = std::min<size_t>(size_t(std::max(waveCount, 0)), pool.size());
        for (size_t i = 0; i < toSpawn; ++i)
        {
            size_t idx = urand(0, uint32(pool.size() - 1));
            SpawnMoltenBloodOozeAt(boss, pool[idx]);
            pool.erase(pool.begin() + idx);
        }
    }

    // Picks the current off-tank: the second-highest-threat PLAYER on the boss's threat
    // list (index 0 is the current tank/victim). Returns nullptr if there aren't two
    // distinct player tanks on the list yet (e.g. right at the very start of the pull).
    Player* FindOffTank(Creature* boss)
    {
        Player* found = nullptr;
        for (auto const& ref : boss->GetThreatMgr().GetSortedThreatList())
        {
            Unit* target = ref->GetVictim();
            if (!target || !target->IsPlayer())
                continue;

            if (!found)
            {
                found = target->ToPlayer();
                continue;
            }

            if (target != found)
                return target->ToPlayer();
        }
        return nullptr;
    }

    // Finds the nearest still-alive pillar within range - FindNearestCreature's
    // alive-only default means an already-shattered (dead) pillar is skipped
    // automatically, no need to cross-check hiddenPillars here.
    Creature* FindNearestPillar(Unit* caster, float range)
    {
        Creature* nearest = nullptr;
        float nearestDist = range;
        for (uint32 entry : PILLAR_ENTRIES)
        {
            if (Creature* candidate = caster->FindNearestCreature(entry, range))
            {
                float const dist = caster->GetDistance(candidate);
                if (!nearest || dist < nearestDist)
                {
                    nearest = candidate;
                    nearestDist = dist;
                }
            }
        }
        return nearest;
    }

    // CONFIRMED from real kill logs (2026-10-02): Igneous Impact's damage, Flash Burn
    // being stripped from the whole raid, and Cracked Armor landing on Basalthane all
    // happen in the exact same tick, every time a pillar shatters - not just on
    // wipe/kill/evade (ClearAllBasalthaneDebuffs' own Flash Burn removal). A fresh
    // reapplication (raid-wide opener/15s tick, or Inferno Trail hits) still stacks it
    // right back up afterward - this only wipes what's already there at the moment
    // the pillar breaks.
    void ClearFlashBurnFromRaid(Creature* boss)
    {
        for (auto const& itr : boss->GetMap()->GetPlayers())
        {
            if (Player* player = itr.GetSource())
            {
                player->RemoveAurasDueToSpell(SPELL_FLASH_BURN_D0);
                player->RemoveAurasDueToSpell(SPELL_FLASH_BURN_D1);
                player->RemoveAurasDueToSpell(SPELL_FLASH_BURN_D2);
                player->RemoveAurasDueToSpell(SPELL_FLASH_BURN_D3);
            }
        }
    }

    // CORRECTED 2026-10-02, twice (external review): first pass used KillSelf() +
    // SetCorpseRemoveTime(0) + SetRespawnTime(), which fixed the lingering-corpse
    // complaint but broke restoration outright - this server runs dynamic respawn mode
    // (Respawn.ForceCompatibilityMode = 0, confirmed in worldserver.conf), where
    // Creature::RemoveCorpse() doesn't just hide a dead creature, it DESTROYS the object
    // and removes it from the map entirely; a fresh one only gets created later by
    // Map::ProcessCreatureRespawn() when something actually triggers a respawn.
    // RestorePillar() resolving the stored ObjectGuid via ObjectAccessor::GetCreature()
    // would find nothing once the object is gone, so Respawn(true) silently never fired
    // - a real regression the reviewer traced before it was ever tested live. Fixed for
    // real this time: track the pillar's spawn ID (stable across the object being
    // destroyed/recreated) instead of its live ObjectGuid, and restore via
    // Map::ProcessCreatureRespawn() - the same spawn-ID-based respawn machinery AC's own
    // respawn timer uses, called directly instead of waiting for the timer.
    void ShatterPillar(Creature* boss, Creature* pillar)
    {
        StateFor(boss).hiddenPillars.insert(pillar->GetSpawnId());
        pillar->KillSelf();
        pillar->SetCorpseRemoveTime(0);
    }

    void RestorePillar(Map* map, ObjectGuid::LowType spawnId)
    {
        map->ProcessCreatureRespawn(spawnId);
    }

    // Restores every currently-shattered pillar immediately (wipe/kill/evade)
    void RestoreAllPillars(Creature* boss)
    {
        BasalthaneState& state = StateFor(boss);
        for (ObjectGuid::LowType spawnId : state.hiddenPillars)
            RestorePillar(boss->GetMap(), spawnId);
        state.hiddenPillars.clear();
    }

    // Both real per-difficulty values pulled directly from Spell.dbc (Ascension's own
    // hidden D0-D3 helper spells for these two abilities), not guesses:
    //   Inferno Trail direct hit: 2108219-2108222 (D0-D3), EffectBasePoints 206/277/349/410
    //   Eruption base damage:     2108223-2108226 (D0-D3), EffectBasePoints 30000/40000/68000/80000
    uint32 GetDifficultyEntry(Unit* caster)
    {
        if (Creature* creature = caster->ToCreature())
            if (CreatureTemplate const* cinfo = creature->GetCreatureTemplate())
                return cinfo->Entry;
        return ENTRY_BASALTHANE_NORMAL;
    }

    uint32 InfernoTrailHitSpellFor(Unit* caster)
    {
        switch (GetDifficultyEntry(caster))
        {
            case ENTRY_BASALTHANE_HEROIC:   return SPELL_INFERNO_TRAIL_HIT_D1;
            case ENTRY_BASALTHANE_MYTHIC:   return SPELL_INFERNO_TRAIL_HIT_D2;
            case ENTRY_BASALTHANE_ASCENDED: return SPELL_INFERNO_TRAIL_HIT_D3;
            default:                        return SPELL_INFERNO_TRAIL_HIT_D0;
        }
    }

    // Flat damage values, real per-difficulty numbers from Spell.dbc - used for the
    // manual 2D damage dealing (see spell_basalthane_inferno_trail::HandleDummy).
    uint32 InfernoTrailDamageFor(Unit* caster)
    {
        switch (GetDifficultyEntry(caster))
        {
            case ENTRY_BASALTHANE_HEROIC:   return 277;
            case ENTRY_BASALTHANE_MYTHIC:   return 349;
            case ENTRY_BASALTHANE_ASCENDED: return 410;
            default:                        return 206;
        }
    }

    uint32 EruptionBaseDamageFor(Unit* caster)
    {
        switch (GetDifficultyEntry(caster))
        {
            case ENTRY_BASALTHANE_HEROIC:   return 40000;
            case ENTRY_BASALTHANE_MYTHIC:   return 68000;
            case ENTRY_BASALTHANE_ASCENDED: return 80000;
            default:                        return 30000;
        }
    }

    uint32 MagmaPoolSpellFor(Unit* caster)
    {
        switch (GetDifficultyEntry(caster))
        {
            case ENTRY_BASALTHANE_HEROIC:   return SPELL_MAGMA_POOL_D1;
            case ENTRY_BASALTHANE_MYTHIC:   return SPELL_MAGMA_POOL_D2;
            case ENTRY_BASALTHANE_ASCENDED: return SPELL_MAGMA_POOL_D3;
            default:                        return SPELL_MAGMA_POOL_D0;
        }
    }

    uint32 FlashBurnSpellFor(Unit* caster)
    {
        switch (GetDifficultyEntry(caster))
        {
            case ENTRY_BASALTHANE_HEROIC:   return SPELL_FLASH_BURN_D1;
            case ENTRY_BASALTHANE_MYTHIC:   return SPELL_FLASH_BURN_D2;
            case ENTRY_BASALTHANE_ASCENDED: return SPELL_FLASH_BURN_D3;
            default:                        return SPELL_FLASH_BURN_D0;
        }
    }

    // CONFIRMED from real kill combat logs 2026-09-24: Smoldering Vengeance is applied
    // by Basalthane himself to a single player - the off-tank - at pull, NOT by killing
    // or standing near the Molten Blood ooze (an earlier design, now removed - ooze
    // deaths in the logs checked had no correlation with when the buff was applied).
    // While it's up, the player ticks Fire damage to nearby enemies every 3s via a
    // separate, difficulty-scaled spell (2108256/57/58 - no D0 variant, Normal doesn't tick).
    constexpr uint32 SPELL_SMOLDERING_VENGEANCE = 2108235;
    constexpr uint32 SPELL_SMOLDERING_VENGEANCE_TICK_D1 = 2108256;
    constexpr uint32 SPELL_SMOLDERING_VENGEANCE_TICK_D2 = 2108257;
    constexpr uint32 SPELL_SMOLDERING_VENGEANCE_TICK_D3 = 2108258;
    constexpr uint32 SMOLDERING_VENGEANCE_TICK_MS = 3000;

    uint32 SmolderingVengeanceTickSpellFor(uint32 difficultyEntry)
    {
        switch (difficultyEntry)
        {
            case ENTRY_BASALTHANE_HEROIC:   return SPELL_SMOLDERING_VENGEANCE_TICK_D1;
            case ENTRY_BASALTHANE_MYTHIC:   return SPELL_SMOLDERING_VENGEANCE_TICK_D2;
            case ENTRY_BASALTHANE_ASCENDED: return SPELL_SMOLDERING_VENGEANCE_TICK_D3;
            default:                        return 0; // Normal doesn't tick
        }
    }

    uint32 AnnihilationHitSpellFor(Unit* caster)
    {
        switch (GetDifficultyEntry(caster))
        {
            case ENTRY_BASALTHANE_HEROIC:   return SPELL_ANNIHILATION_HIT_D1;
            case ENTRY_BASALTHANE_MYTHIC:   return SPELL_ANNIHILATION_HIT_D2;
            case ENTRY_BASALTHANE_ASCENDED: return SPELL_ANNIHILATION_HIT_D3;
            default:                        return SPELL_ANNIHILATION_HIT_D0;
        }
    }

    uint32 EruptionExplosionSpellFor(Unit* caster)
    {
        switch (GetDifficultyEntry(caster))
        {
            case ENTRY_BASALTHANE_HEROIC:   return SPELL_ERUPTION_EXPLOSION_D1;
            case ENTRY_BASALTHANE_MYTHIC:   return SPELL_ERUPTION_EXPLOSION_D2;
            case ENTRY_BASALTHANE_ASCENDED: return SPELL_ERUPTION_EXPLOSION_D3;
            default:                        return SPELL_ERUPTION_EXPLOSION_D0;
        }
    }

    uint32 HeatSplashSpellFor(Unit* caster)
    {
        switch (GetDifficultyEntry(caster))
        {
            case ENTRY_BASALTHANE_HEROIC:   return SPELL_HEAT_SPLASH_D1;
            case ENTRY_BASALTHANE_MYTHIC:   return SPELL_HEAT_SPLASH_D2;
            case ENTRY_BASALTHANE_ASCENDED: return SPELL_HEAT_SPLASH_D3;
            default:                        return SPELL_HEAT_SPLASH_D0;
        }
    }

    // forcedDurationMs >= 0 always overrides to that exact duration (used for the early
    // cast-start telegraph). Left at -1, it falls back to the real per-difficulty rule.
    void CastMagmaPoolAt(Unit* caster, float x, float y, float z, int32 forcedDurationMs = -1)
    {
        SpellInfo const* magmaPool = sSpellMgr->GetSpellInfo(MagmaPoolSpellFor(caster));
        if (!magmaPool)
            return;

        SpellCastTargets targets;
        targets.SetDst(x, y, z, 0.0f);

        if (forcedDurationMs >= 0)
        {
            CustomSpellValues values;
            values.AddSpellMod(SPELLVALUE_AURA_DURATION, forcedDurationMs);
            caster->CastSpell(targets, magmaPool, &values, TRIGGERED_FULL_MASK);
            return;
        }

        bool permanent = false;
        if (Creature* creature = caster->ToCreature())
            if (CreatureTemplate const* cinfo = creature->GetCreatureTemplate())
                permanent = (cinfo->Entry == ENTRY_BASALTHANE_MYTHIC || cinfo->Entry == ENTRY_BASALTHANE_ASCENDED);

        if (permanent)
        {
            caster->CastSpell(targets, magmaPool, nullptr, TRIGGERED_FULL_MASK);
        }
        else
        {
            CustomSpellValues values;
            values.AddSpellMod(SPELLVALUE_AURA_DURATION, MAGMA_POOL_DURATION_TIMED_MS);
            caster->CastSpell(targets, magmaPool, &values, TRIGGERED_FULL_MASK);
        }
    }

    // Ground height varies across the cone's width on this uneven lava floor - using a
    // flat Z for every point made the side casts land in mid-air/underground relative
    // to where players actually stand, so the side hits never registered. Query the
    // real ground height per point instead, falling back to the caster's Z if the
    // query fails (matches the known vmap gaps in this room).
    float ResolveGroundZ(WorldObject* context, float x, float y, float fallbackZ)
    {
        float z = context->GetMap()->GetHeight(x, y, fallbackZ + 5.0f, true);
        return (z > INVALID_HEIGHT) ? z : fallbackZ;
    }

    // Damage is dealt manually (see spell_basalthane_inferno_trail::HandleDummy) - this
    // cast is visual-only, its School Damage effect gets stripped by
    // spell_basalthane_inferno_trail_hit_visual_only (same trick as
    // spell_basalthane_eruption_explosion suppressing Knockback below). Restores the
    // per-swirl explosion look without reintroducing double damage.
    void CastInfernoTrailHitAt(Unit* caster, float x, float y, float z)
    {
        SpellInfo const* hit = sSpellMgr->GetSpellInfo(InfernoTrailHitSpellFor(caster));
        if (!hit)
            return;

        SpellCastTargets targets;
        targets.SetDst(x, y, z, 0.0f);
        caster->CastSpell(targets, hit, nullptr, TRIGGERED_FULL_MASK);
    }

    // Single source of truth for every point along the trail - used to draw the
    // telegraph, to check who's standing in a swirl when it hits, and to play the
    // per-swirl explosion visual, so all three can never drift out of sync again.
    template <typename Callback>
    void ForEachInfernoTrailSwirl(float originX, float originY, float dirX, float dirY, Callback&& cb)
    {
        float perpX = -dirY;
        float perpY = dirX;
        for (float dist = INFERNO_TRAIL_VISUAL_STEP; dist <= INFERNO_TRAIL_LINE_LENGTH; dist += INFERNO_TRAIL_VISUAL_STEP)
        {
            float cappedDist = std::min(dist, INFERNO_TRAIL_WIDTH_CAP_DIST);
            int swirlCount = INFERNO_TRAIL_CONE_START_SWIRLS + int(cappedDist / INFERNO_TRAIL_GROWTH_STEP_DIST);
            float rowHalfWidth = (swirlCount - 1) * INFERNO_TRAIL_SWIRL_OVERLAP_GAP / 2.0f;
            for (int i = 0; i < swirlCount; ++i)
            {
                float offset = -rowHalfWidth + i * INFERNO_TRAIL_SWIRL_OVERLAP_GAP;
                float px = originX + dirX * dist + perpX * offset;
                float py = originY + dirY * dist + perpY * offset;
                cb(px, py);
            }
        }
    }

    // The actual "swirl" visual lives on 2108218 ("Pre"), not on the small hit spells -
    // repeat it at every point along the line to get the chain-of-swirls look instead
    // of a single marker at the boss. Purely cosmetic, no damage/aura of its own.
    void CastInfernoTrailSwirlAt(Unit* caster, float x, float y, float z)
    {
        SpellInfo const* swirl = sSpellMgr->GetSpellInfo(SPELL_INFERNO_TRAIL_PRE);
        if (!swirl)
            return;

        SpellCastTargets targets;
        targets.SetDst(x, y, z, 0.0f);
        caster->CastSpell(targets, swirl, nullptr, TRIGGERED_FULL_MASK);
    }

    // The real explosion: native School Damage + Knockback + stacking "+100% Fire
    // damage taken" debuff, centered on the impact point (not on Basalthane).
    //
    // The hit spells (2105077-80) are TARGET_SRC_CASTER + SRC_AREA_* in the DBC -
    // that implicit target always centers the area on whoever CASTS it, so SetDst
    // alone can't relocate it (SetDst only matters for TARGET_DEST_* implicit
    // targets). Summons a short-lived invisible WORLD_TRIGGER at the impact point
    // and casts from there instead, so the area genuinely originates at (x,y,z).
    void CastEruptionExplosionAt(Unit* caster, float x, float y, float z)
    {
        uint32 spellId = EruptionExplosionSpellFor(caster);
        if (!sSpellMgr->GetSpellInfo(spellId))
            return;

        if (Creature* trigger = caster->SummonCreature(WORLD_TRIGGER, x, y, z, 0.0f, TEMPSUMMON_TIMED_DESPAWN, 1000))
        {
            trigger->SetFaction(caster->GetFaction());
            trigger->CastSpell(trigger, spellId, true);
        }
    }

    // CORRECTED 2026-10-02 (same bug as CastAnnihilationHitAt, same root cause): Heat
    // Splash is TARGET_UNIT_TARGET_ENEMY (6) + TARGET_UNIT_DEST_AREA_ENEMY (16) in the
    // DBC, not TARGET_SRC_CASTER + SRC_AREA_ENEMY - an earlier same-day pass misread
    // AC's Targets enum (see AnnihilationHitSpellFor's comment for the full mix-up).
    // Needs a real explicit enemy unit target, which the old same-faction
    // WORLD_TRIGGER-casting-on-itself could never satisfy (SpellInfo::CheckExplicitTarget
    // would fail) - a plain direct cast onto the same unit Eruption hit is both correct
    // per the DBC and simpler, no trigger needed.
    void CastHeatSplashAt(Unit* caster, Unit* target)
    {
        uint32 spellId = HeatSplashSpellFor(caster);
        if (!sSpellMgr->GetSpellInfo(spellId))
            return;

        caster->CastSpell(target, spellId, true);
    }

    // Builds a real SpellNonMeleeDamage, runs it through the normal mitigation
    // pipeline (resistance, absorbs) and the combat log, instead of a raw
    // Unit::DealDamage that bypasses both. Needed for this encounter's own
    // debuffs to actually apply to this damage - Annihilation Strike's -25% Fire
    // resistance and Eruption's own +100% Fire damage taken stack are both real
    // auras that only affect damage that goes through this pipeline.
    // CORRECTED 2026-10-02 (external review): CalculateSpellDamageTaken handles armor,
    // resilience, absorbs and resistance, but a native spell effect also runs
    // SpellDamageBonusTaken() separately before that step - without it,
    // SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN auras (Eruption's own Fire-vulnerability
    // stack included) never apply to this manual damage path.
    void DealMitigatedFireDamage(Unit* caster, Unit* target, uint32 dmg, SpellInfo const* spellInfo)
    {
        dmg = target->SpellDamageBonusTaken(caster, spellInfo, dmg, SPELL_DIRECT_DAMAGE);
        SpellNonMeleeDamage damageInfo(caster, target, spellInfo, spellInfo->SchoolMask);
        caster->CalculateSpellDamageTaken(&damageInfo, int32(dmg), spellInfo);
        Unit::DealDamageMods(target, damageInfo.damage, &damageInfo.absorb);
        caster->DealSpellDamage(&damageInfo, false);
        caster->SendSpellNonMeleeDamageLog(&damageInfo);
    }

    // CONFIRMED 2026-10-02 (user's own in-game knowledge): Smoldering Vengeance goes to
    // whoever has current aggro (the tank) the instant a pillar shatters, and stays with
    // them until the next shatter reassigns it - possibly to the same player again, if
    // they still have aggro then. Explicitly strips it from the previous holder before
    // handing it to the new one (CastSpell alone would leave both players holding it).
    void AssignSmolderingVengeance(Creature* boss)
    {
        Unit* tank = boss->GetVictim();
        Player* tankPlayer = tank ? tank->ToPlayer() : nullptr;
        if (!tankPlayer)
            return;

        BasalthaneState& state = StateFor(boss);
        if (state.smolderingVengeanceHolder == tankPlayer->GetGUID())
            return;

        if (Player* oldHolder = ObjectAccessor::GetPlayer(*boss, state.smolderingVengeanceHolder))
            oldHolder->RemoveAurasDueToSpell(SPELL_SMOLDERING_VENGEANCE);

        tankPlayer->CastSpell(tankPlayer, SPELL_SMOLDERING_VENGEANCE, true);
        state.smolderingVengeanceHolder = tankPlayer->GetGUID();
    }

}

class spell_basalthane_annihilation_strike : public SpellScript
{
    PrepareSpellScript(spell_basalthane_annihilation_strike);

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        // CORRECTED 2026-10-02 (external review caught a real bug): the hit (2108207-10)
        // is TARGET_UNIT_TARGET_ENEMY (6) + TARGET_UNIT_DEST_AREA_ENEMY (16) in the DBC -
        // an earlier same-day pass misread AC's own Targets enum (6 was wrongly read as
        // TARGET_SRC_CASTER, which is actually 22; 16 was wrongly read as SRC_AREA_ENEMY,
        // which is actually 15) and "fixed" this into a WORLD_TRIGGER relocation that was
        // both unnecessary and broken: TARGET_UNIT_TARGET_ENEMY requires a real explicit
        // enemy unit target, which a same-faction trigger casting on itself fails
        // (SpellInfo::CheckExplicitTarget), and SPELL_EFFECT_WEAPON_PERCENT_DAMAGE reads
        // weapon damage from the caster (m_caster->CalculateDamage()), so even if
        // targeting somehow passed, a WORLD_TRIGGER has no weapon to read from. This
        // plain direct cast was already correct - DEST_AREA_ENEMY around the explicit
        // target's own position is tank-centered natively, no relocation needed.
        caster->CastSpell(target, AnnihilationHitSpellFor(caster), true);

        // Real native stacking debuff - the game handles the icon, stacking and duration
        caster->CastSpell(target, SPELL_ANNIHILATION_DEBUFF, true);

        // Pillar mechanic: if Basalthane is standing near a pillar when he lands
        // Annihilation Strike, it shatters - Igneous Impact goes off (real native
        // room-wide AoE), he gets caught in the blast (stunned), and Cracked Armor
        // goes on HIMSELF (not the tank) as the bonus-damage vulnerability window.
        if (Creature* pillar = FindNearestPillar(caster, ANNIHILATION_PILLAR_RANGE))
        {
            caster->CastSpell(caster, SPELL_IGNEOUS_IMPACT, true);
            caster->CastSpell(caster, SPELL_CAUGHT_IN_THE_BLAST, true);
            caster->CastSpell(caster, SPELL_DAZED, true);
            caster->CastSpell(caster, SPELL_CRACKED_ARMOR, true);
            if (Creature* boss = caster->ToCreature())
            {
                BasalthaneState& state = StateFor(boss);
                state.crackedArmorUntil = uint32(GameTime::GetGameTimeMS().count()) + CRACKED_ARMOR_DURATION_SECONDS * 1000;
                ShatterPillar(boss, pillar);
                ClearFlashBurnFromRaid(boss);
                AssignSmolderingVengeance(boss);

                // Real interaction (WeakAuras decode): Cracked Armor also pushes back
                // Annihilation Strike's and Eruption's next cast by 20s each - only if
                // they're already scheduled (both always are once the boss is in combat,
                // which is the only way to land this pillar hit in the first place).
                if (state.annihilationNextCast != 0)
                    state.annihilationNextCast += CRACKED_ARMOR_COOLDOWN_EXTEND_MS;
                if (state.eruptionNextCast != 0)
                    state.eruptionNextCast += CRACKED_ARMOR_COOLDOWN_EXTEND_MS;

                // Per-pillar-type bonus effect, on top of the shared package above
                // (CONFIRMED 2026-10-02, see the PILLAR_BLOB_*/SPELL_BLISTERING_TRAUMA
                // comments for the source).
                switch (pillar->GetEntry())
                {
                    case ENTRY_PILLAR_3: // Searing
                        caster->CastSpell(caster, SPELL_BLISTERING_TRAUMA, true);
                        break;
                    case ENTRY_PILLAR_2: // Crumbling
                        state.pillarBlobsRemaining = PILLAR_BLOB_TOTAL_CRUMBLING;
                        state.pillarBlobIntervalMs = PILLAR_BLOB_INTERVAL_CRUMBLING_MS;
                        state.pillarBlobPoolSize = 2;
                        state.pillarBlobWaveMin = PILLAR_BLOB_WAVE_MIN_CRUMBLING;
                        state.pillarBlobWaveMax = PILLAR_BLOB_WAVE_MAX_CRUMBLING;
                        state.pillarBlobNextSpawn = uint32(GameTime::GetGameTimeMS().count());
                        break;
                    case ENTRY_PILLAR_1: // Volatile
                        state.pillarBlobsRemaining = PILLAR_BLOB_TOTAL_VOLATILE;
                        state.pillarBlobIntervalMs = PILLAR_BLOB_INTERVAL_VOLATILE_MS;
                        state.pillarBlobPoolSize = 3;
                        state.pillarBlobWaveMin = PILLAR_BLOB_WAVE_MIN_VOLATILE;
                        state.pillarBlobWaveMax = PILLAR_BLOB_WAVE_MAX_VOLATILE;
                        state.pillarBlobNextSpawn = uint32(GameTime::GetGameTimeMS().count());
                        break;
                    default:
                        break;
                }
            }
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_basalthane_annihilation_strike::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_basalthane_inferno_trail : public SpellScript
{
    PrepareSpellScript(spell_basalthane_inferno_trail);

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        // Aim direction was captured at cast start (OnAllCreatureUpdate); fall back to
        // the resolved target's current position if it's missing for some reason.
        float dirX = 0.0f, dirY = 0.0f;
        Creature* casterCreature = caster->ToCreature();
        if (casterCreature && StateFor(casterCreature).hasInfernoTrailDirection)
        {
            BasalthaneState const& state = StateFor(casterCreature);
            dirX = state.infernoTrailDirX;
            dirY = state.infernoTrailDirY;
        }
        else
        {
            float dx = target->GetPositionX() - caster->GetPositionX();
            float dy = target->GetPositionY() - caster->GetPositionY();
            float len = std::sqrt(dx * dx + dy * dy);
            if (len > 0.1f)
            {
                dirX = dx / len;
                dirY = dy / len;
            }
        }

        // The swirl-chain telegraph was already shown for the whole cast (cast-start,
        // see OnAllCreatureUpdate). Damage and Flash Burn are dealt manually here, purely
        // in 2D against the actual swirl positions - the native hit-spell's Z-sensitive
        // AoE target selection was missing players due to this room's known vmap gaps.
        // Hit detection walks the same swirl list the telegraph drew (ForEachInfernoTrailSwirl)
        // and checks "is this player within INFERNO_TRAIL_HIT_RADIUS of any swirl", instead
        // of a smooth mathematical cone that could disagree with what's actually on screen.
        float originX = caster->GetPositionX();
        float originY = caster->GetPositionY();
        float originZ = caster->GetPositionZ();
        uint32 dmg = InfernoTrailDamageFor(caster);
        constexpr float hitRadiusSq = INFERNO_TRAIL_HIT_RADIUS * INFERNO_TRAIL_HIT_RADIUS;

        std::vector<Player*> hitPlayers;
        for (auto const& mapItr : caster->GetMap()->GetPlayers())
        {
            Player* player = mapItr.GetSource();
            if (player && player->IsAlive() && caster->IsValidAttackTarget(player))
                hitPlayers.push_back(player);
        }

        // Adjacent swirls in a row deliberately overlap - collect every swirl position
        // first so a player standing in that overlap is only damaged/debuffed once,
        // while the explosion visual still plays at every swirl regardless.
        std::vector<std::pair<float, float>> swirlPositions;
        ForEachInfernoTrailSwirl(originX, originY, dirX, dirY, [&](float px, float py)
        {
            swirlPositions.emplace_back(px, py);
            CastInfernoTrailHitAt(caster, px, py, ResolveGroundZ(caster, px, py, originZ));
        });

        for (Player* player : hitPlayers)
        {
            bool hit = false;
            for (auto const& pos : swirlPositions)
            {
                float dx = player->GetPositionX() - pos.first;
                float dy = player->GetPositionY() - pos.second;
                if (dx * dx + dy * dy <= hitRadiusSq)
                {
                    hit = true;
                    break;
                }
            }
            if (!hit)
                continue;

            if (dmg)
                DealMitigatedFireDamage(caster, player, dmg, GetSpellInfo());
            // Flash Burn (2108201-04) is TARGET_SRC_CASTER + TARGET_UNIT_SRC_AREA_ENEMY
            // (200yd around the caster) in the DBC, so CastSpell(player, ...) would
            // actually hit every player within 200yd regardless of the `player` arg,
            // stacking it on the whole raid instead of just whoever got hit by the
            // trail. AddAura bypasses the spell's own implicit targeting and applies
            // (and stacks) it directly on just this player.
            player->AddAura(FlashBurnSpellFor(caster), player);
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_basalthane_inferno_trail::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_basalthane_eruption : public SpellScript
{
    PrepareSpellScript(spell_basalthane_eruption);

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        std::list<Unit*> nearby;
        Acore::AnyUnitInObjectRangeCheck check(target, ERUPTION_BURST_RADIUS);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> searcher(target, nearby, check);
        Cell::VisitObjects(target, searcher, ERUPTION_BURST_RADIUS);

        std::vector<Unit*> hit;
        hit.push_back(target);
        for (Unit* other : nearby)
            if (other != target && other->IsPlayer() && caster->IsValidAttackTarget(other))
                hit.push_back(other);

        uint32 perTarget = EruptionBaseDamageFor(caster) / uint32(hit.size());

        for (Unit* u : hit)
            DealMitigatedFireDamage(caster, u, perTarget, GetSpellInfo());

        // The real explosion: native School Damage + Knockback + stacking Fire-vulnerability debuff
        CastEruptionExplosionAt(caster, target->GetPositionX(), target->GetPositionY(), target->GetPositionZ());

        // Heat Splash: a second, separate instant School Damage hit at the same impact
        // point (not part of the explosion/magma pool DBC data - a distinct spell).
        CastHeatSplashAt(caster, target);

        // Magma Pool is a real native area aura - cast it at the impact point to leave the ground hazard
        CastMagmaPoolAt(caster, target->GetPositionX(), target->GetPositionY(), target->GetPositionZ());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_basalthane_eruption::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// The real explosion (2105077-80) has a native Knockback effect, but it doesn't
// actually happen on the real server (confirmed against a real kill recording) -
// suppress it here while leaving the damage and debuff effects untouched.
class spell_basalthane_eruption_explosion : public SpellScript
{
    PrepareSpellScript(spell_basalthane_eruption_explosion);

    void PreventKnockback(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_basalthane_eruption_explosion::PreventKnockback, EFFECT_1, SPELL_EFFECT_KNOCK_BACK);
    }
};

// The real Inferno Trail hit spells (2108219-22) carry the actual explosion visual,
// but their School Damage effect is suppressed here - damage is already dealt
// manually in spell_basalthane_inferno_trail::HandleDummy (see CastInfernoTrailHitAt),
// so casting the real spell unmodified would double it. Same trick as
// spell_basalthane_eruption_explosion above, just stripping the other effect type.
class spell_basalthane_inferno_trail_hit_visual_only : public SpellScript
{
    PrepareSpellScript(spell_basalthane_inferno_trail_hit_visual_only);

    void PreventDamage(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_basalthane_inferno_trail_hit_visual_only::PreventDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

// CORRECTED 2026-10-02 (external review caught a real bug): the tick timer used to live
// in a std::unordered_map shared across EVERY player, as a member of this single
// globally-registered PlayerScript. Map::Update calls Player::Update on map worker
// threads, so with MapUpdate.Threads > 1, two different players' OnPlayerUpdate calls
// could concurrently insert/rehash the SAME shared map from different threads -
// undefined behavior, same class of bug BasalthaneState's move to CustomData already
// fixed for the boss. Moved onto each player's own CustomData instead - no shared
// container, so no cross-thread access to the same memory is possible at all.
class playerscript_basalthane_annihilation_cleanup : public PlayerScript
{
public:
    playerscript_basalthane_annihilation_cleanup()
        : PlayerScript("playerscript_basalthane_annihilation_cleanup", { PLAYERHOOK_ON_UPDATE })
    {
    }

    void OnPlayerUpdate(Player* player, uint32 /*p_time*/) override
    {
        if (player->HasAura(SPELL_SMOLDERING_VENGEANCE))
            TickSmolderingVengeance(player);
    }

private:
    struct SmolderingVengeanceTimerState : DataMap::Base
    {
        uint32 nextTick = 0;
    };

    static constexpr char STATE_KEY[] = "custom.basalthane.smoldering_vengeance_timer";

    void TickSmolderingVengeance(Player* player)
    {
        SmolderingVengeanceTimerState& state = *player->CustomData.GetDefault<SmolderingVengeanceTimerState>(STATE_KEY);

        uint32 now = uint32(GameTime::GetGameTimeMS().count());
        if (now < state.nextTick)
            return;

        state.nextTick = now + SMOLDERING_VENGEANCE_TICK_MS;

        Creature* boss = player->FindNearestCreature(ENTRY_BASALTHANE_NORMAL, 200.0f);
        uint32 tickSpell = SmolderingVengeanceTickSpellFor(boss ? GetDifficultyEntry(boss) : ENTRY_BASALTHANE_NORMAL);
        if (tickSpell)
            player->CastSpell(player, tickSpell, true);
    }
};

namespace
{
    void ClearAllBasalthaneDebuffs(Creature* boss)
    {
        // Everything here is a real native aura - just strip it from the raid
        for (auto const& itr : boss->GetMap()->GetPlayers())
        {
            if (Player* player = itr.GetSource())
            {
                player->RemoveAurasDueToSpell(SPELL_ANNIHILATION_DEBUFF);
                player->RemoveAurasDueToSpell(SPELL_FLASH_BURN_D0);
                player->RemoveAurasDueToSpell(SPELL_FLASH_BURN_D1);
                player->RemoveAurasDueToSpell(SPELL_FLASH_BURN_D2);
                player->RemoveAurasDueToSpell(SPELL_FLASH_BURN_D3);
                player->RemoveAurasDueToSpell(SPELL_SMOLDERING_VENGEANCE);
                player->RemoveAurasDueToSpell(SPELL_BLISTERING_TRAUMA);
            }
        }

        boss->RemoveDynObject(SPELL_MAGMA_POOL_D0);
        boss->RemoveDynObject(SPELL_MAGMA_POOL_D1);
        boss->RemoveDynObject(SPELL_MAGMA_POOL_D2);
        boss->RemoveDynObject(SPELL_MAGMA_POOL_D3);

        BasalthaneState& state = StateFor(boss);
        state.hasInfernoTrailDirection = false;

        // Cracked Armor is self-applied to the boss, not players - strip it here too.
        boss->RemoveAurasDueToSpell(SPELL_CRACKED_ARMOR);
        state.crackedArmorUntil = 0;

        // Blistering Trauma's self-only dummy marker effect (Effect 3) lands on the
        // boss too, alongside the raid-wide healing-done debuff stripped above.
        boss->RemoveAurasDueToSpell(SPELL_BLISTERING_TRAUMA);

        // Pillars only come back on wipe/evade, NOT on a kill - a dead Basalthane keeps
        // his shattered pillars shattered (confirmed 2026-09-23). Debuffs above still
        // get stripped from players either way, this is just the pillar-restore part.
        if (boss->IsAlive())
            RestoreAllPillars(boss);
    }
}

// Cast-start detection (SmartAI's own script hooks only fire after the cast bar
// finishes, so this polls instead): captures Inferno Trail's aim direction the instant
// it starts casting, fires an early ground telegraph when Eruption starts casting, and
// sweeps up every lingering debuff once the pull is over (kill, wipe, or Basalthane
// evading) - Mythic/Ascended Magma Pools don't expire on their own, and the hand-tracked
// Annihilation Strike stacks have no native aura duration to fall back on either. Pillars
// specifically are excluded from the kill case, see ClearAllBasalthaneDebuffs.
class allcreaturescript_basalthane_cleanup : public AllCreatureScript
{
public:
    allcreaturescript_basalthane_cleanup() : AllCreatureScript("allcreaturescript_basalthane_cleanup") { }

    void OnAllCreatureUpdate(Creature* creature, uint32 /*diff*/) override
    {
        if (creature->GetEntry() != ENTRY_BASALTHANE_NORMAL)
            return;

        BasalthaneState& state = StateFor(creature);

        if (!creature->IsInCombat())
        {
            ClearAllBasalthaneDebuffs(creature);
            state.flashBurnOpenerApplied = false;
            state.flashBurnNextTick = 0;
            state.smolderingVengeanceHolder = ObjectGuid::Empty;
            state.infernoTrailNextCast = 0;
            state.eruptionNextCast = 0;
            state.annihilationNextCast = 0;
            state.moltenBloodNextSpawn = 0;
            state.pillarBlobsRemaining = 0;
            state.pillarBlobNextSpawn = 0;
            return;
        }

        // Molten Blood ooze spawning (see MOLTEN_BLOOD_SPAWN_INTERVAL_MS comment) - picks
        // among the 3 points currently farthest from Basalthane every time, since he
        // moves around the room and isn't tanked in the middle.
        {
            uint32& nextMolten = state.moltenBloodNextSpawn;
            if (nextMolten == 0)
                nextMolten = uint32(GameTime::GetGameTimeMS().count()) + urand(MOLTEN_BLOOD_SPAWN_INTERVAL_MIN_MS, MOLTEN_BLOOD_SPAWN_INTERVAL_MAX_MS);
            else if (uint32(GameTime::GetGameTimeMS().count()) >= nextMolten)
            {
                SpawnMoltenBloodAtFarthestPoints(creature, 3);
                nextMolten = uint32(GameTime::GetGameTimeMS().count()) + urand(MOLTEN_BLOOD_SPAWN_INTERVAL_MIN_MS, MOLTEN_BLOOD_SPAWN_INTERVAL_MAX_MS);
            }
        }

        // Pillar-triggered blob burst (Crumbling/Volatile shattering, see
        // PILLAR_BLOB_* comment) - fully independent of the periodic spawner above,
        // both can be mid-cycle at the same time. One wave of (random 1-2 for Crumbling,
        // fixed 3 for Volatile) oozes every state.pillarBlobIntervalMs, drawn from
        // state.pillarBlobPoolSize farthest points with no repeats within a wave, until
        // pillarBlobsRemaining hits 0.
        if (state.pillarBlobsRemaining > 0 && uint32(GameTime::GetGameTimeMS().count()) >= state.pillarBlobNextSpawn)
        {
            int waveCount = (state.pillarBlobWaveMin >= state.pillarBlobWaveMax)
                ? state.pillarBlobWaveMin
                : irand(state.pillarBlobWaveMin, state.pillarBlobWaveMax);
            waveCount = std::min(waveCount, state.pillarBlobsRemaining);
            SpawnMoltenBloodBlobWave(creature, state.pillarBlobPoolSize, waveCount);
            state.pillarBlobsRemaining -= waveCount;
            state.pillarBlobNextSpawn = uint32(GameTime::GetGameTimeMS().count()) + state.pillarBlobIntervalMs;
        }

        // Inferno Trail scheduling (see INFERNO_TRAIL_CAST_INTERVAL_MS comment) - real
        // priority: Annihilation Strike and Eruption are still SmartAI-timed and cast
        // straight onto CURRENT_GENERIC_SPELL like Inferno Trail does, so "is the boss
        // already mid-cast on anything" is an honest proxy for "is one of the two
        // higher-priority casts happening right now" (nothing else shares that slot).
        {
            uint32& nextInferno = state.infernoTrailNextCast;
            if (nextInferno == 0)
                nextInferno = uint32(GameTime::GetGameTimeMS().count()) + INFERNO_TRAIL_CAST_INTERVAL_MS;
            else if (uint32(GameTime::GetGameTimeMS().count()) >= nextInferno)
            {
                if (creature->GetCurrentSpell(CURRENT_GENERIC_SPELL))
                {
                    // Annihilation Strike or Eruption is casting right now - skip this
                    // cycle entirely (matches the ~28s gaps seen in real kill logs).
                    nextInferno = uint32(GameTime::GetGameTimeMS().count()) + INFERNO_TRAIL_CAST_INTERVAL_MS;
                }
                else
                {
                    // Never the tank OR the off-tank - Inferno Trail goes at a random
                    // DPS or healer. Picks from the boss's own threat list (actually
                    // engaged, alive players only) rather than every player on the
                    // map - the old map-wide pool could pick dead players, GMs, or
                    // people still at the entrance, all of which fail a non-triggered
                    // cast silently while this cycle's cast gets skipped anyway.
                    Unit* tank = creature->GetVictim();
                    Player* offTank = FindOffTank(creature);
                    std::vector<Player*> players;
                    for (auto const& ref : creature->GetThreatMgr().GetSortedThreatList())
                    {
                        Unit* target = ref->GetVictim();
                        if (!target || !target->IsPlayer())
                            continue;
                        Player* player = target->ToPlayer();
                        if (player != tank && player != offTank && player->IsAlive() && !player->IsGameMaster())
                            players.push_back(player);
                    }

                    // CORRECTED 2026-10-02 (external review): the threat-list pool
                    // already excludes dead players/GMs, but not range or line of
                    // sight - a player who moved out of cast range or behind an
                    // obstruction still fails the cast silently. Check the real
                    // SpellCastResult: only burn the full cycle on an actual
                    // successful cast; a failure (no valid target reachable right
                    // now) retries shortly instead of being treated the same as a
                    // genuine cast, same reasoning CastSpell's result already exists
                    // for elsewhere in this encounter.
                    if (!players.empty())
                    {
                        SpellCastResult result = creature->CastSpell(Acore::Containers::SelectRandomContainerElement(players), SPELL_INFERNO_TRAIL, false);
                        nextInferno = uint32(GameTime::GetGameTimeMS().count()) +
                            (result == SPELL_CAST_OK ? INFERNO_TRAIL_CAST_INTERVAL_MS : 1000);
                    }
                    else
                    {
                        nextInferno = uint32(GameTime::GetGameTimeMS().count()) + INFERNO_TRAIL_CAST_INTERVAL_MS;
                    }
                }
            }
        }

        // Eruption scheduling (see ERUPTION_INITIAL_CAST_MS comment).
        {
            uint32& nextEruption = state.eruptionNextCast;
            if (nextEruption == 0)
                nextEruption = uint32(GameTime::GetGameTimeMS().count()) + ERUPTION_INITIAL_CAST_MS;
            else if (uint32(GameTime::GetGameTimeMS().count()) >= nextEruption)
            {
                if (creature->GetCurrentSpell(CURRENT_GENERIC_SPELL))
                {
                    // Something else (Annihilation Strike or Inferno Trail) is already
                    // mid-cast - retry shortly rather than waiting a full cycle.
                    nextEruption = uint32(GameTime::GetGameTimeMS().count()) + 1000;
                }
                else
                {
                    Unit* tank = creature->GetVictim();
                    Player* offTank = FindOffTank(creature);
                    std::vector<Player*> players;
                    for (auto const& ref : creature->GetThreatMgr().GetSortedThreatList())
                    {
                        Unit* target = ref->GetVictim();
                        if (!target || !target->IsPlayer())
                            continue;
                        Player* player = target->ToPlayer();
                        if (player != tank && player != offTank && player->IsAlive() && !player->IsGameMaster())
                            players.push_back(player);
                    }

                    if (!players.empty())
                        creature->CastSpell(Acore::Containers::SelectRandomContainerElement(players), SPELL_ERUPTION, false);

                    bool const ascended = GetDifficultyEntry(creature) == ENTRY_BASALTHANE_ASCENDED;
                    nextEruption = uint32(GameTime::GetGameTimeMS().count()) +
                        (ascended ? ERUPTION_ASCENDED_REPEAT_MS : urand(ERUPTION_REPEAT_MIN_MS, ERUPTION_REPEAT_MAX_MS));
                }
            }
        }

        // Annihilation Strike scheduling (see ANNIHILATION_CAST_MIN_MS comment) - moved
        // off SmartAI so Cracked Armor can actually nudge the timer. Cast straight onto
        // CURRENT_GENERIC_SPELL like Eruption/Inferno Trail, so the same "boss already
        // mid-cast" check applies both ways (this skip here, and the other two treating
        // Annihilation Strike as a reason to skip their own cycle).
        {
            uint32& nextAnnihilation = state.annihilationNextCast;
            if (nextAnnihilation == 0)
                nextAnnihilation = uint32(GameTime::GetGameTimeMS().count()) + urand(ANNIHILATION_CAST_MIN_MS, ANNIHILATION_CAST_MAX_MS);
            else if (uint32(GameTime::GetGameTimeMS().count()) >= nextAnnihilation)
            {
                if (creature->GetCurrentSpell(CURRENT_GENERIC_SPELL))
                {
                    nextAnnihilation = uint32(GameTime::GetGameTimeMS().count()) + 1000;
                }
                else
                {
                    if (Unit* tank = creature->GetVictim())
                        creature->CastSpell(tank, SPELL_ANNIHILATION_STRIKE, false);

                    nextAnnihilation = uint32(GameTime::GetGameTimeMS().count()) + urand(ANNIHILATION_CAST_MIN_MS, ANNIHILATION_CAST_MAX_MS);
                }
            }
        }

        // Opening Flash Burn: applied raid-wide the moment the pull starts, matching
        // real kill logs where every raid member got it at the same instant Basalthane
        // entered combat. Inferno Trail's own Flash Burn application (further down in
        // this file) is untouched - this is a separate mechanism.
        // Flash Burn (2108201-04) is TARGET_SRC_CASTER + TARGET_UNIT_SRC_AREA_ENEMY,
        // 200yd around the caster - a SINGLE cast already hits every raid member in
        // range, so this must never be looped per-player (that would stack it N times
        // per pass instead of once).
        uint32 nowMs = uint32(GameTime::GetGameTimeMS().count());
        if (!state.flashBurnOpenerApplied)
        {
            state.flashBurnOpenerApplied = true;
            creature->CastSpell(creature, FlashBurnSpellFor(creature), true);
            state.flashBurnNextTick = nowMs + FLASH_BURN_RAIDWIDE_TICK_MS;
        }

        // Periodic raid-wide Flash Burn refresh (see FLASH_BURN_RAIDWIDE_TICK_MS comment) -
        // stacks onto whatever's already there for players still afflicted from the opener.
        if (nowMs >= state.flashBurnNextTick)
        {
            creature->CastSpell(creature, FlashBurnSpellFor(creature), true);
            state.flashBurnNextTick = nowMs + FLASH_BURN_RAIDWIDE_TICK_MS;
        }

        // Force-expire Cracked Armor after CRACKED_ARMOR_DURATION_SECONDS - see the
        // comment on crackedArmorUntil for why this isn't left to the spell's own duration.
        if (state.crackedArmorUntil != 0 && uint32(GameTime::GetGameTimeMS().count()) >= state.crackedArmorUntil)
        {
            creature->RemoveAurasDueToSpell(SPELL_CRACKED_ARMOR);
            state.crackedArmorUntil = 0;
        }

        Spell* current = creature->GetCurrentSpell(CURRENT_GENERIC_SPELL);
        Spell*& last = state.lastGenericSpell;
        if (current == last)
            return;

        last = current;
        if (!current)
            return;

        Unit* aimTarget = current->m_targets.GetUnitTarget();
        if (!aimTarget)
            return;

        uint32 spellId = current->GetSpellInfo()->Id;
        if (spellId == SPELL_INFERNO_TRAIL)
        {
            float dx = aimTarget->GetPositionX() - creature->GetPositionX();
            float dy = aimTarget->GetPositionY() - creature->GetPositionY();
            float len = std::sqrt(dx * dx + dy * dy);
            float dirX = 0.0f, dirY = 0.0f;
            if (len > 0.1f)
            {
                dirX = dx / len;
                dirY = dy / len;
                state.hasInfernoTrailDirection = true;
                state.infernoTrailDirX = dirX;
                state.infernoTrailDirY = dirY;
            }

            // Show the full swirl-chain telegraph for the whole 2.5s cast, not just at
            // resolution - the raid needs to see it while there's still time to dodge.
            // A real cone: each row starts as 2 overlapping swirls right at the boss,
            // gaining one more swirl every INFERNO_TRAIL_GROWTH_STEP_DIST yards, spaced
            // INFERNO_TRAIL_SWIRL_OVERLAP_GAP apart so neighbors in the same row still
            // overlap - keeps the cone reading as one connected shape instead of gapping
            // out as it grows wider.
            float originX = creature->GetPositionX();
            float originY = creature->GetPositionY();
            float z = creature->GetPositionZ();
            ForEachInfernoTrailSwirl(originX, originY, dirX, dirY, [&](float px, float py)
            {
                CastInfernoTrailSwirlAt(creature, px, py, ResolveGroundZ(creature, px, py, z));
            });
        }
        else if (spellId == SPELL_ERUPTION)
        {
            creature->CastSpell(aimTarget, SPELL_ERUPTION_PRE, true);
        }
    }

};

// Manually drives the ooze toward Basalthane in pure 2D, bypassing native MoveFollow.
// CONFIRMED 2026-09-24: MoveFollow + CREATURE_FLAG_EXTRA_IGNORE_PATHFINDING on this
// room's uneven/broken mesh makes the ooze launch into the air mid-walk - the same
// class of problem Inferno Trail's damage check was rewritten to avoid. This never
// calls GetHeight/pathfinding at all - it uses Basalthane's own live Z (already a
// valid position, since he functions fine in this room) as the ooze's target Z, and
// just relocates it a short step closer every tick. Stops at OOZE_FOLLOW_STOP_DIST,
// matching the original "hold at 3yd" design (rows 2/3 on the ooze's own SmartAI still
// handle the "become aggressive within 4yd" part independently via their own distance
// checks, untouched by this).
constexpr float OOZE_FOLLOW_STOP_DIST = 3.0f;
constexpr float OOZE_FOLLOW_SPEED = 2.5f; // yd/s, roughly a normal walk speed

constexpr uint32 OOZE_FOLLOW_TICK_MS = 200; // throttle - see comment below
constexpr char OOZE_MOVEMENT_STATE_KEY[] = "custom.basalthane.ooze_movement";

class allcreaturescript_basalthane_ooze_movement : public AllCreatureScript
{
public:
    allcreaturescript_basalthane_ooze_movement() : AllCreatureScript("allcreaturescript_basalthane_ooze_movement") { }

    void OnAllCreatureUpdate(Creature* creature, uint32 /*diff*/) override
    {
        if (creature->GetEntry() != ENTRY_MOLTEN_BLOOD_OOZE || !creature->IsAlive())
            return;

        // Attached directly to this ooze's own Creature object (CustomData/DataMap),
        // same reasoning as BasalthaneState above - per-instance by construction,
        // no GUID-collision risk across simultaneous raid instances.
        OozeMovementState& moveState = *creature->CustomData.GetDefault<OozeMovementState>(OOZE_MOVEMENT_STATE_KEY);

        // Throttled to every OOZE_FOLLOW_TICK_MS instead of every world tick -
        // NearTeleportTo is a real teleport call (grid/visibility recalculation each
        // time), not a smooth-movement API, so calling it dozens of times a second was
        // likely spamming teleports hard enough to cause a visibility/network glitch or
        // trip some anti-spam safety net that made the ooze disappear within seconds.
        uint32 now = uint32(GameTime::GetGameTimeMS().count());
        if (now < moveState.nextMove)
            return;
        moveState.nextMove = now + OOZE_FOLLOW_TICK_MS;

        Creature* boss = creature->FindNearestCreature(ENTRY_BASALTHANE_NORMAL, 200.0f);
        if (!boss)
            return;

        // Z is interpolated from a REMEMBERED spawn position/distance, never fed back
        // from the ooze's own live Z - feeding live Z into itself each tick (previous
        // version) let it drift ("flyver op i luften") if NearTeleportTo's own internal
        // position handling nudges Z at all between calls. This way Z is a pure function
        // of progress-along-the-path, immune to any such per-tick drift.
        if (moveState.initialDist == 0.0f)
        {
            float sdx = boss->GetPositionX() - creature->GetPositionX();
            float sdy = boss->GetPositionY() - creature->GetPositionY();
            moveState.z = creature->GetPositionZ();
            moveState.initialDist = std::sqrt(sdx * sdx + sdy * sdy);
            if (moveState.initialDist <= 0.0f)
                moveState.initialDist = 0.01f; // avoid div-by-zero if spawned exactly on the boss
        }

        float dx = boss->GetPositionX() - creature->GetPositionX();
        float dy = boss->GetPositionY() - creature->GetPositionY();
        float dist = std::sqrt(dx * dx + dy * dy);
        if (dist <= OOZE_FOLLOW_STOP_DIST)
            return;

        float step = OOZE_FOLLOW_SPEED * (float(OOZE_FOLLOW_TICK_MS) / 1000.0f);
        float remaining = dist - OOZE_FOLLOW_STOP_DIST;
        if (step > remaining)
            step = remaining;

        float nx = creature->GetPositionX() + (dx / dist) * step;
        float ny = creature->GetPositionY() + (dy / dist) * step;
        float facing = std::atan2(dy, dx);

        float progress = std::clamp(1.0f - (dist - step) / moveState.initialDist, 0.0f, 1.0f);
        float nz = moveState.z + (boss->GetPositionZ() - moveState.z) * progress;

        creature->NearTeleportTo(nx, ny, nz, facing);
    }

private:
    struct OozeMovementState : DataMap::Base
    {
        uint32 nextMove = 0;
        float z = 0.0f;
        float initialDist = 0.0f;
    };
};

// CONFIRMED 2026-10-02 (user's own in-game tooltip check) - see the SPELL_MOLTEN_BLOOD_*/
// SPELL_PYROCLASTIC_* comment above for the full mechanic. Two things every tick:
//  1. Real contact with the boss (MOLTEN_BLOOD_MERGE_RANGE) - merge: Pyroclastic
//     Explosion from the ooze's own position (room-wide), Basalthane gains a Molten
//     Blood stack, the ooze dies. Replaces the old smart_scripts "become aggressive at
//     4yd" rows and the old "gain stack while within 10yd" row entirely.
//  2. Otherwise, a periodic Pyroclastic Splash tick from the ooze's own position (see
//     SPELL_MOLTEN_BLOOD_SELF_BUFF's comment above for why this is driven manually
//     instead of relying on 2108240's own native periodic trigger).
constexpr char OOZE_PYROCLASTIC_STATE_KEY[] = "custom.basalthane.ooze_pyroclastic";

class allcreaturescript_basalthane_ooze_pyroclastic : public AllCreatureScript
{
public:
    allcreaturescript_basalthane_ooze_pyroclastic() : AllCreatureScript("allcreaturescript_basalthane_ooze_pyroclastic") { }

    void OnAllCreatureUpdate(Creature* creature, uint32 /*diff*/) override
    {
        if (creature->GetEntry() != ENTRY_MOLTEN_BLOOD_OOZE || !creature->IsAlive())
            return;

        Creature* boss = creature->FindNearestCreature(ENTRY_BASALTHANE_NORMAL, 200.0f);
        if (!boss)
            return;

        uint32 difficultyEntry = GetDifficultyEntry(boss);

        if (creature->GetDistance(boss) <= MOLTEN_BLOOD_MERGE_RANGE)
        {
            creature->CastSpell(creature, PyroclasticExplosionSpellFor(difficultyEntry), true);
            boss->CastSpell(boss, SPELL_MOLTEN_BLOOD_SELF_BUFF, true);
            creature->KillSelf();
            return;
        }

        PyroclasticSplashState& state = *creature->CustomData.GetDefault<PyroclasticSplashState>(OOZE_PYROCLASTIC_STATE_KEY);
        uint32 now = uint32(GameTime::GetGameTimeMS().count());
        if (now < state.nextSplashTick)
            return;
        state.nextSplashTick = now + MOLTEN_BLOOD_SPLASH_TICK_MS;

        if (SpellInfo const* splash = sSpellMgr->GetSpellInfo(PyroclasticSplashSpellFor(difficultyEntry)))
        {
            SpellCastTargets targets;
            targets.SetDst(creature->GetPositionX(), creature->GetPositionY(), creature->GetPositionZ(), 0.0f);
            creature->CastSpell(targets, splash, nullptr, TRIGGERED_FULL_MASK);
        }
    }

private:
    struct PyroclasticSplashState : DataMap::Base
    {
        uint32 nextSplashTick = 0;
    };
};

void AddSC_spell_basalthane()
{
    RegisterSpellScript(spell_basalthane_annihilation_strike);
    RegisterSpellScript(spell_basalthane_inferno_trail);
    RegisterSpellScript(spell_basalthane_eruption);
    RegisterSpellScript(spell_basalthane_eruption_explosion);
    RegisterSpellScript(spell_basalthane_inferno_trail_hit_visual_only);
    new playerscript_basalthane_annihilation_cleanup();
    new allcreaturescript_basalthane_cleanup();
    new allcreaturescript_basalthane_ooze_pyroclastic();
    // Custom manual movement disabled again 2026-09-30 (second time same day) -
    // even with the room's terrain fixed by fresh vmaps/mmaps, the NearTeleportTo-
    // every-200ms approach itself visibly lags. Back to native SmartAI MoveFollow
    // (smart_scripts id=1, entryorguid=310189, source_type=0, event_chance=100)
    // for smooth movement, with the ooze's speed_walk/speed_run reduced 60%
    // (1 -> 0.4, 1.14286 -> 0.457144) to counteract native follow's catch-up/
    // acceleration behavior instead of avoiding native follow altogether.
    // new allcreaturescript_basalthane_ooze_movement();
}
