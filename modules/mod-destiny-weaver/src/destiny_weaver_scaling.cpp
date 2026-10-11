/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

// Open World Scaling, per character.
//
// A creature carries one level, one pool and one set of stats, in one object, handed to every
// client - so the obvious implementation (raise the creature to the player's level) necessarily
// hands that player's scaling to everyone else standing in the same zone. That is not what this
// does, and not what the live service did.
//
// What a client is told is not the object. Every values update is built per recipient
// (`Map::SendObjectUpdates` groups a packet per player, `Unit::PatchValuesUpdate` exists to rewrite
// fields for one target, and the core exposes both as `ShouldTrackValuesUpdatePosByIndex` +
// `OnPatchValuesUpdate`). So the creature keeps its authored level and stats, untouched for
// everyone, and a character who asked for scaling is shown *their* version of it.
//
// That version is built from the same table a creature is built from. `creature_classlevelstats` is
// one row per (level, class) holding health, mana, armor, attack power and weapon damage - exactly
// what `Creature::SelectLevel()` reads and `UpdateAllStats()` writes into the fields the client and
// the fight both use. A view is the row at the viewer's level, so every one of those scales:
//
//   level      the curve's answer for that character (their level - offset), sent to them alone
//   health     the row's health at that level; the bar they see, and the pool their fight is paced by
//   mana       the row's mana, likewise
//   armor      the row's armor, which is what their blows are mitigated by (the core asks this
//              module for it in Unit::CalcArmorReducedDamage - the one place the viewer is not
//              visible from the fields)
//   damage     the row's weapon damage plus the attack power behind it, which is what the creature
//              hits *them* for, and what they hit *it* for
//   skills     the skill values the hit/crit/dodge/parry roll uses, at that level
//
// The pool is shared, which is the one thing a view cannot change: one wolf has one pool of hit
// points and two characters may be hitting it, each shown a pool scaled to their own version. So
// what a character's damage takes out of the real pool is scaled by the same ratio that maps the
// real pool onto the one they are shown (DamageDealtToPool): their bar falls by exactly the number
// their client is told, and the fight lasts what a fight at their version's level lasts. Coming the
// other way, what the creature deals them is scaled to what its version hits for
// (DamageTakenFactor). Both factors are 1 for a character with scaling off, and for a character
// whose version *is* the creature: their fight is then the authored fight, and nobody else's fight
// changes because of it.
#include "destiny_weaver.h"
#include "destiny_weaver_view_damage.h"

#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "Group.h"
#include "LocalLevelScaling.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "StringConvert.h"
#include "Timer.h"
#include "Tokenize.h"
#include "Unit.h"
#include "UpdateData.h"
#include "UpdateFields.h"

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
    /// The realm switches as the module last read them.
    ///
    /// `ViewFor` runs on the hot side of the server - once per creature, per recipient, per values
    /// block, and again inside every damage hook - so it must not ask the config system anything. The
    /// config is read where it changes (startup and `.reload config`) and cached here; a key that is
    /// missing keeps the documented default, which is what the options would have answered anyway.
    std::atomic<bool> g_scalingAvailable{false};

    bool ScalingAvailable()
    {
        return g_scalingAvailable.load(std::memory_order_relaxed);
    }

    /// The offset the view sits below the character, read once per config load. The value lives in
    /// `LocalLevelScaling::CreatureOffset`, which is the core's own copy of it, so the fight paths
    /// read an atomic instead of a config file.
    uint8 ScalingOffset()
    {
        return uint8(std::min<uint32>(sConfigMgr->GetOption<uint32>("DestinyWeaver.Scaling.Offset", 4), 60));
    }

    /// The client flag that marks a unit as scaled for this client (UnitIsLevelScaling): the client then
    /// shows its health as a share rather than as the pool it was told.
    constexpr uint32 UNIT_DYNFLAG_LEVEL_SCALING = 0x100;

    /// The dungeon finder entries whose dungeons scale: the classic five-player dungeons the client's own
    /// scaling list names.
    constexpr char DEFAULT_SCALING_DUNGEONS[] = "1 4 6 8 10 12 14 16 18 20 22 24 26 28 163 164 165 272 273";

    /// Where a view can exist at all: the open-world maps, and the classic dungeons with the band their
    /// creatures are held inside. Built on every config load and at startup, and published whole, so a
    /// reader on any map thread holds one consistent scope for as long as it asks. A scope is never
    /// freed while the server runs: a reload publishes a new one beside it.
    struct ScalingScope
    {
        std::unordered_set<uint32> WorldMaps;
        std::unordered_map<uint32, LocalLevelScaling::LevelBand> DungeonBands;
    };

    std::atomic<ScalingScope const*> g_scope{nullptr};
    std::vector<std::unique_ptr<ScalingScope const>> g_publishedScopes;

    ScalingScope const* Scope()
    {
        return g_scope.load(std::memory_order_acquire);
    }

    std::vector<uint32> ConfigIds(char const* key, char const* fallback)
    {
        std::vector<uint32> ids;
        std::string const value = sConfigMgr->GetOption<std::string>(key, fallback);
        for (std::string_view token : Acore::Tokenize(value, ' ', false))
            if (Optional<uint32> id = Acore::StringTo<uint32>(token))
                ids.push_back(*id);
        return ids;
    }

    /// The bands come from LFGDungeons.dbc. The first config load runs before the store is filled, so
    /// it publishes a scope without dungeons; startup publishes the complete one.
    void PublishScope()
    {
        auto scope = std::make_unique<ScalingScope>();
        for (uint32 mapId : ConfigIds("DestinyWeaver.Scaling.WorldMaps", "0 1"))
            scope->WorldMaps.insert(mapId);

        for (uint32 dungeonId : ConfigIds("DestinyWeaver.Scaling.DungeonIds", DEFAULT_SCALING_DUNGEONS))
        {
            LFGDungeonEntry const* dungeon = sLFGDungeonStore.LookupEntry(dungeonId);
            if (!dungeon)
                continue;

            LocalLevelScaling::LevelBand const band =
                LocalLevelScaling::DungeonBandFromFinder(dungeon->TargetLevelMin, dungeon->MaxLevel);
            auto [itr, inserted] = scope->DungeonBands.try_emplace(dungeon->MapID, band);
            if (!inserted)
                itr->second = LocalLevelScaling::MergeBands(itr->second, band);
        }

        LOG_INFO("module.destiny_weaver", "creature scaling covers {} open-world map(s) and {} dungeon map(s)",
                 scope->WorldMaps.size(), scope->DungeonBands.size());

        g_scope.store(scope.get(), std::memory_order_release);
        g_publishedScopes.push_back(std::move(scope));
    }

    /// The band one scaled dungeon holds its creatures inside, or nullptr outside the scaled dungeons.
    LocalLevelScaling::LevelBand const* DungeonBandFor(Map const* map)
    {
        ScalingScope const* scope = Scope();
        if (!scope || !map)
            return nullptr;

        auto itr = scope->DungeonBands.find(map->GetId());
        return itr != scope->DungeonBands.end() ? &itr->second : nullptr;
    }

    /// One row of `creature_classlevelstats`: everything the core builds a creature of a given level
    /// out of. Rank and template multipliers are deliberately absent - they do not depend on level,
    /// so they cancel out of every ratio here, and the real creature already carries them.
    struct LevelStats
    {
        uint32 Health;
        uint32 Mana;
        uint32 Armor;
        uint32 AttackPower;
        uint32 RangedAttackPower;
        float BaseDamage;
    };

    LevelStats StatsAt(uint8 level, CreatureTemplate const* info)
    {
        CreatureBaseStats const* stats = sObjectMgr->GetCreatureBaseStats(level, info->unit_class);
        return LevelStats{ stats->GenerateHealth(info), stats->GenerateMana(info),
                           uint32(stats->GenerateArmor(info)), stats->AttackPower, stats->RangedAttackPower,
                           stats->GenerateBaseDamage(info) };
    }

    /// What a creature built from this row hits for on average: the middle of its weapon range plus
    /// the attack power behind it, which is what UpdateAttackPowerAndDamage writes into
    /// UNIT_FIELD_MINDAMAGE and UNIT_FIELD_MAXDAMAGE and what Unit::CalculateDamage rolls between.
    double HitFrom(LevelStats const& stats, CreatureTemplate const* info)
    {
        return DestinyWeaver::AverageCreatureMeleeHit(stats.BaseDamage, stats.AttackPower, info->BaseVariance,
                                                      info->BaseAttackTime);
    }

    double SwingFrom(LevelStats const& stats, CreatureTemplate const* info, double weaponFactor)
    {
        return DestinyWeaver::CreatureSwingEnd(stats.BaseDamage, stats.AttackPower, info->BaseVariance, weaponFactor);
    }

    /// One character's version of one creature.
    struct CreatureView
    {
        uint8 Level;
        LevelStats Stats;
        uint32 MaxHealth;           ///< the pool they are shown, and their fight is paced by
        /// A blow's damage -> what the shared real pool actually loses.
        double DamageDealtToPool;
        /// The creature's own blow -> what it is worth in this character's version of the fight.
        double DamageTakenFactor;
        /// The same for the bottom and the top of its melee range.
        double DamageTakenLow;
        double DamageTakenHigh;
    };

    Player* OwningPlayer(Unit* unit)
    {
        return unit ? unit->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    }

    /// Whether a creature may be given a view at all, whoever is looking at it.
    ///
    /// These exclusions are not optional: a creature that belongs to somebody - a pet, a guardian, a
    /// summon, a totem, a charmed unit - must never be re-levelled, and neither must a trigger, a
    /// critter or a non-combat pet, which are scenery with a health bar. A world boss is authored for a
    /// raid at its level, and a creature that serves (any npcflag) or cannot be fought keeps its level
    /// for everyone. Those two are read from the creature's spawn and template rather than from its
    /// live flags, which scripts toggle during events: a client caches the level it was told, so the
    /// view must not appear and vanish with them.
    ///
    /// The maps are the open world the realm lists and the classic dungeons with a band. Raids,
    /// battlegrounds and arenas never scale, and neither does CoA's scripted private content. A dungeon
    /// scales on its regular difficulty only: Heroic and Mythic carry authored level-60 health
    /// (coa_dungeon_health) and Mythic+ scales it; a per-character view would scale it a second time.
    ///
    /// There is no realm switch in front of the list: whether a character scales at all is their own
    /// choice (`ScalingChoiceEnabled`), and the module's switch only decides whether that choice is
    /// consulted.
    bool ViewableCreature(Creature const* creature)
    {
        if (!creature)
            return false;

        Map* map = creature->GetMap();
        ScalingScope const* scope = Scope();
        if (!map || !scope || map->IsScriptedPrivateInstance() || map->IsBattlegroundOrArena() || map->IsRaid())
            return false;

        if (map->IsDungeon())
        {
            if (!map->IsRegularDifficulty() || !scope->DungeonBands.contains(map->GetId()))
                return false;
        }
        else if (!scope->WorldMaps.contains(map->GetId()))
            return false;

        if (creature->IsPet() || creature->IsTotem() || creature->IsGuardian() || creature->IsTrigger() ||
            creature->IsCritter() || creature->isWorldBoss() ||
            creature->GetCreatureType() == CREATURE_TYPE_NON_COMBAT_PET || creature->GetCharmerOrOwner())
            return false;

        CreatureTemplate const* info = creature->GetCreatureTemplate();
        if (!info || !info->unit_class)
            return false;

        uint32 npcFlags = 0;
        uint32 unitFlags = 0;
        uint32 dynamicFlags = 0;
        ObjectMgr::ChooseCreatureFlags(info, npcFlags, unitFlags, dynamicFlags, creature->GetCreatureData());
        return !npcFlags &&
               !(unitFlags & (UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_IMMUNE_TO_PC));
    }

    /// Whether this character's version of this creature is theirs to fight.
    ///
    /// A vendor, a trainer, a quest giver or a friendly guard keeps its authored level. The question
    /// is asked in the one form that does not change while a client is holding the answer, which is
    /// why it is not `Player::IsValidAttackTarget`: that folds in hostility, stealth and invisibility,
    /// immunities and flags, so a creature would appear and vanish as a view depending on whether it
    /// could be seen at that instant - and a client caches the level it was told, so the level it
    /// displays would flap with it. The reaction is faction and faction state: hostile and neutral
    /// creatures scale for a character, friendly ones do not.
    ///
    /// Deliberately not excluded: a game master. A view is only ever one client's, so a GM who turned
    /// scaling on sees the same world a player would.
    bool ViewableBy(Player const* viewer, Creature const* creature)
    {
        return viewer && creature && viewer->GetReactionTo(creature) <= REP_NEUTRAL;
    }

    bool ViewFor(Creature const* creature, Player* viewer, CreatureView& view)
    {
        if (!creature || !viewer || !ScalingAvailable())
            return false;

        // The character's own answer, never a neighbour's: this is what makes scaling a choice.
        if (!LocalLevelScaling::ScalingChoiceEnabled(viewer))
            return false;

        // A challenge rule or an open-world PvP ruleset holds the character to the authored world.
        if (LocalLevelScaling::ScalingBlocksFor(viewer) & LocalLevelScaling::ChallengeBlocksCreatureScaling)
            return false;

        if (!ViewableCreature(creature) || !ViewableBy(viewer, creature))
            return false;

        uint8 const own = creature->GetLevel();
        uint8 level = own;
        Map const* map = creature->GetMap();
        if (map->IsDungeon())
        {
            LocalLevelScaling::LevelBand const* band = DungeonBandFor(map);
            if (!band)
                return false;
            level = LocalLevelScaling::ScaleDungeonCreatureLevelForViewer(viewer->GetLevel(), *band);
        }
        else
        {
            // The viewer's own rule, not the realm's: a level that is told to one client is bounded by
            // nothing, because there is nobody else for a high view to be wrong for.
            uint8 const offset = LocalLevelScaling::CreatureOffset.load(std::memory_order_relaxed);
            level = LocalLevelScaling::ScaleCreatureLevelForViewer(own, viewer->GetLevel(), offset);
        }

        if (level == own)
            return false;               // their version *is* the creature: nothing to virtualise

        CreatureTemplate const* info = creature->GetCreatureTemplate();
        if (!info)
            return false;

        LevelStats const ownStats = StatsAt(own, info);
        uint32 const realMaxHealth = std::max<uint32>(creature->GetMaxHealth(), 1);

        view.Level = level;
        view.Stats = StatsAt(level, info);
        view.MaxHealth = std::max<uint32>(1, uint32(uint64(realMaxHealth) * view.Stats.Health /
                                                    std::max<uint32>(ownStats.Health, 1)));
        view.DamageDealtToPool = double(realMaxHealth) / double(view.MaxHealth);
        view.DamageTakenFactor = DestinyWeaver::ViewDamageTakenFactor(HitFrom(view.Stats, info),
                                                                      HitFrom(ownStats, info));
        view.DamageTakenLow = DestinyWeaver::ViewDamageTakenFactor(SwingFrom(view.Stats, info, 1.0),
                                                                   SwingFrom(ownStats, info, 1.0));
        view.DamageTakenHigh = DestinyWeaver::ViewDamageTakenFactor(
            SwingFrom(view.Stats, info, DestinyWeaver::CREATURE_MAX_WEAPON_DAMAGE_FACTOR),
            SwingFrom(ownStats, info, DestinyWeaver::CREATURE_MAX_WEAPON_DAMAGE_FACTOR));
        return true;
    }

    /// The armor the viewer's version of the creature wears. Installed as the core's resolver: this
    /// is the one fight input that cannot be reached from the viewer's own fields, because the blow
    /// is mitigated against the creature's armor inside Unit::CalcArmorReducedDamage.
    std::optional<uint32> ViewArmorFor(Player const* viewer, Creature const* creature)
    {
        CreatureView view;
        if (!ViewFor(creature, const_cast<Player*>(viewer), view))
            return std::nullopt;

        if (creature->GetPctModifierValue(UNIT_MOD_ARMOR, TOTAL_PCT) <= 0.0f)
            return 0;

        // Replace only the level-derived base; keep the same modifier order as
        // Unit::GetTotalAuraModValue, including armor-reducing effects that reach zero.
        float armor = creature->GetFlatModifierValue(UNIT_MOD_ARMOR, BASE_VALUE) + float(view.Stats.Armor) -
            float(StatsAt(creature->GetLevel(), creature->GetCreatureTemplate()).Armor);
        armor *= creature->GetPctModifierValue(UNIT_MOD_ARMOR, BASE_PCT);
        armor += creature->GetFlatModifierValue(UNIT_MOD_ARMOR, TOTAL_VALUE);
        armor *= creature->GetPctModifierValue(UNIT_MOD_ARMOR, TOTAL_PCT);
        return uint32(std::max(0.0f, armor));
    }

    /// The level the viewer's version of the creature stands at, for the core's own per-target level
    /// query (`Creature::getLevelForTarget`). Everything level-derived that the core rolls - spell
    /// hit and resistance tables, weapon and defence skill, glancing and crushing, detection, aggro
    /// radius, kill experience - is asked for through that one function, so publishing the level here
    /// is what makes all of them follow the viewer instead of the authored creature.
    uint8 ViewLevelForCore(Player const* viewer, Creature const* creature)
    {
        CreatureView view;
        if (!ViewFor(creature, const_cast<Player*>(viewer), view))
            return 0;
        return view.Level;
    }

    uint32 ViewMaxHealthForCore(Player const* viewer, Creature const* creature)
    {
        CreatureView view;
        if (!ViewFor(creature, const_cast<Player*>(viewer), view))
            return 0;
        return view.MaxHealth;
    }

    /// The fields a view rewrites, in one list. The patch looks a position up by index, and a forced
    /// values update is what carries an index to a client at all, so a field added here is both
    /// tracked and re-sendable without a second place to keep in step.
    constexpr uint16 VIEW_FIELDS[] = { UNIT_FIELD_LEVEL, UNIT_FIELD_MAXHEALTH, UNIT_FIELD_HEALTH,
                                       UNIT_FIELD_MAXPOWER1, UNIT_FIELD_POWER1 };

    bool TrackedField(uint16 index)
    {
        for (uint16 field : VIEW_FIELDS)
            if (index == field)
                return true;
        return false;
    }

    /// Asks every client that can see this creature for the fields a view lives in again.
    ///
    /// Marking them changed is all it takes: the next values block for the creature carries exactly
    /// these fields, and `OnPatchValuesUpdate` rewrites them per recipient on the way out - so one
    /// creature broadcast refreshes every viewer each to their own version, and a viewer whose view
    /// has not moved receives its authored values unchanged.
    void ForceViewFields(Creature* creature)
    {
        for (uint16 index : VIEW_FIELDS)
            creature->ForceValuesUpdateAtIndex(index);
        creature->ForceValuesUpdateAtIndex(UNIT_DYNAMIC_FLAGS);
    }

    /// Keeps the scaling flag on every creature a view can exist for. The object's flag is what makes
    /// the field non-zero, so it travels in every create block; each recipient's copy is then set or
    /// cleared in `OnPatchValuesUpdate`. Death and respawn rewrite the dynamic flags, so a living
    /// creature is marked again on its next update.
    void MarkScalable(Creature* creature)
    {
        if (!creature->HasDynamicFlag(UNIT_DYNFLAG_LEVEL_SCALING) && ScalingAvailable() &&
            ViewableCreature(creature))
            creature->SetDynamicFlag(UNIT_DYNFLAG_LEVEL_SCALING);
    }

    /// The flag one recipient is shown: set while they are looking at their own version, cleared for
    /// everyone who sees the authored creature.
    void PatchScalingFlag(ByteBuffer& data, BuildValuesCachePosPointers const& pos, bool viewed)
    {
        if (pos.UnitDynamicFlagsPos < 0)
            return;

        uint32 flags = data.read<uint32>(pos.UnitDynamicFlagsPos);
        flags = viewed ? (flags | UNIT_DYNFLAG_LEVEL_SCALING) : (flags & ~UNIT_DYNFLAG_LEVEL_SCALING);
        data.put(pos.UnitDynamicFlagsPos, flags);
    }

    constexpr char DAMAGE_REMAINDER_KEY[] = "DestinyWeaver.DamageRemainder";

    // The remainder belongs to the shared health pool, not to a particular attacker.
    struct DamageRemainder : DataMap::Base
    {
        double Value = 0.0;
    };

    constexpr char SEEN_FACTION_KEY[] = "DestinyWeaver.SeenFaction";

    struct SeenFaction : DataMap::Base
    {
        uint32 Value = 0;
    };

    /// Whether the creature's faction moved since its last update. A faction change decides whether a
    /// character is looking at their own version at all (`ViewableBy`), but the values block it causes
    /// carries only the faction, so the level and pool the client was told stay the old ones: a
    /// friendly creature that turns hostile keeps its authored level and a full bar. The first look
    /// only records the faction.
    bool FactionChanged(Creature* creature)
    {
        auto* seen = creature->CustomData.GetDefault<SeenFaction>(SEEN_FACTION_KEY);
        uint32 const faction = creature->GetFaction();
        if (seen->Value == faction)
            return false;

        bool const changed = seen->Value != 0;
        seen->Value = faction;
        return changed;
    }

    /// A client whose view stopped being true, until it has been re-sent.
    ///
    /// The *rules* never need this: the choice is read live, so the next question already answers
    /// with the right answer. What does not follow by itself is what a client has already been told -
    /// the level and pool it received for a creature, and the quest data it received for a quest.
    /// Those are caches on the other side of the wire, and only a fresh message replaces them.
    ///
    /// The request is recorded on the thread that saw the change (a group event, a gossip click) and
    /// served on the thread that owns the client: creatures on the creature's own map thread, the
    /// quest log on the character's own map thread. No packet is ever sent across threads.
    struct PendingViewRefresh
    {
        uint32 CreatureUntil;                       ///< this client's creatures are due until here
        bool QuestLogDue;                           ///< its quest log still has to be re-queried
        std::unordered_set<uint64> CreaturesSent;   ///< forced once each, so one episode sends one block per creature
    };

    std::mutex g_viewRefreshLock;
    std::unordered_map<uint64, PendingViewRefresh> g_viewRefresh;
    std::unordered_set<uint64> g_leadersSeen;
    std::atomic<uint32> g_viewRefreshCount{0};

    /// What each client currently believes the group's switch is: 1 on, 0 off. Seeded on login - the
    /// state as of that moment is the baseline - and compared every time a client is marked, so the
    /// centre-screen notification is one message per real change, whoever caused it: joining a group
    /// whose leader's switch differs, the leader flipping it, leadership moving, a leader dropping
    /// out. Nothing per-event has to remember an older value, and no event can double-notify.
    std::unordered_map<uint64, int8> g_toldState;

    /// The last notification each client was spoken, so one event cannot be announced twice. Two
    /// hooks genuinely do describe one event: a member leaving a two-person group fires the removal
    /// *and* the disband, and both hand that member the same default - the same news, twice. The
    /// latch is on the sentence itself, so it only ever suppresses a repeat of the same state; a
    /// change that moves says so whichever way it moves, however quickly.
    struct SpokenState
    {
        uint32 Since = 0;
        int8 Said = -1;   // -1 nothing said yet, 1 enabled, 0 disabled
    };

    std::unordered_map<uint64, SpokenState> g_lastSpoken;

    /// Short on purpose: the duplicates arrive in one call chain, well inside a frame.
    constexpr uint32 SPEAK_REPEAT_WINDOW_MS = 2000;

    void SeedToldState(Player* player)
    {
        if (!player)
            return;

        std::lock_guard<std::mutex> guard(g_viewRefreshLock);
        g_toldState.try_emplace(player->GetGUID().GetRawValue(),
                                DestinyWeaver::LevelScalingEnabled(player) ? 1 : 0);
    }

    /// Records what a client has been told, under the lock that owns the map.
    void RecordToldState(Player* player)
    {
        std::lock_guard<std::mutex> guard(g_viewRefreshLock);
        g_toldState[player->GetGUID().GetRawValue()] =
            DestinyWeaver::LevelScalingEnabled(player) ? 1 : 0;
    }

    /// How long a client keeps pulling the fields it can see. Creatures update on their own stagger,
    /// so one pass would miss whatever happened not to tick; a few seconds catches all of them and
    /// then stops, instead of forcing a values block for every creature forever.
    constexpr uint32 VIEW_REFRESH_WINDOW_MS = 5000;

    /// How far away a creature is worth re-sending for. A client draws creatures well beyond a
    /// creature's own sight range, so the sight range is not the measure of "what it has been told".
    constexpr float VIEW_REFRESH_RANGE = 100.0f;

    void MarkClientDirty(Player* player, bool remindDefault)
    {
        if (!player || !player->IsInWorld() || player->GetSession()->IsBot())
            return;

        // A reminder is owed whatever the state does: it is what the character is left holding.
        bool notify = remindDefault;
        bool effective = false;
        {
            std::lock_guard<std::mutex> guard(g_viewRefreshLock);
            auto [itr, inserted] = g_viewRefresh.try_emplace(player->GetGUID().GetRawValue());
            if (inserted)
                g_viewRefreshCount.fetch_add(1, std::memory_order_relaxed);

            // Every mark starts a fresh episode: the creatures this client has already been re-sent
            // this time round are due again, because the event that just happened moved them again.
            itr->second.CreaturesSent.clear();
            itr->second.CreatureUntil = getMSTime() + VIEW_REFRESH_WINDOW_MS;
            itr->second.QuestLogDue = true;

            // The switch this client is about to be shown, against the one it believes it has.
            // A reminder hands the character their own choice back, so it is their own choice it names
            // - not the effective state, which in the middle of a group hook is still the leader's
            // switch and would make the sentence describe somebody else's setting. Leaving a group and
            // being disbanded both end with the character on their own stored choice, which is exactly
            // what `PersonalLevelScalingChoice` answers.
            effective = remindDefault ? DestinyWeaver::PersonalLevelScalingChoice(player)
                                      : DestinyWeaver::LevelScalingEnabled(player);
            int8& told = g_toldState[player->GetGUID().GetRawValue()];
            int8 const now = effective ? 1 : 0;
            if (told != now)
            {
                told = now;
                notify = true;
            }

            if (notify)
            {
                SpokenState& spoken = g_lastSpoken[player->GetGUID().GetRawValue()];
                uint32 const stamp = getMSTime();
                if (spoken.Said == now && getMSTimeDiff(spoken.Since, stamp) < SPEAK_REPEAT_WINDOW_MS)
                    notify = false;
                else
                {
                    spoken.Since = stamp;
                    spoken.Said = now;
                }
            }
        }

        // Outside the lock: this sends, and nothing else should wait on a packet for it. Which
        // sentence is true depends on what the client is being shown: while a group's switch is in
        // effect the change is the group's, and when there is none - the character left, the group
        // broke up, the leader is gone - it is the Weaver's own line handing them their default. A
        // reminder is about that default, so it is the Weaver's line even while a group is still on
        // the character's screen.
        if (notify)
        {
            if (!remindDefault && DestinyWeaver::GroupScalingApplies(player))
                DestinyWeaver::NotifyGroupScaling(player, effective);
            else
                DestinyWeaver::NotifyPersonalScaling(player, effective);
        }
    }

    /// Claims this creature for one client inside the current episode, so it is re-sent once rather
    /// than once per update for as long as the window lasts.
    bool ClaimCreatureFor(ObjectGuid playerGuid, ObjectGuid creatureGuid)
    {
        std::lock_guard<std::mutex> guard(g_viewRefreshLock);
        auto itr = g_viewRefresh.find(playerGuid.GetRawValue());
        if (itr == g_viewRefresh.end() || itr->second.CreatureUntil <= getMSTime())
            return false;
        return itr->second.CreaturesSent.insert(creatureGuid.GetRawValue()).second;
    }

    /// Forgets a client under the lock, keeping the count that lets the creature pass skip its work.
    void ErasePending(std::unordered_map<uint64, PendingViewRefresh>::iterator itr)
    {
        g_viewRefresh.erase(itr);
        g_viewRefreshCount.fetch_sub(1, std::memory_order_relaxed);
    }

    /// The quest log half of the refresh, consumed on the character's own thread. It is also where an
    /// episode ends: a client that owes nothing and is past its window is forgotten here, so the
    /// registry holds only clients that are actually being refreshed right now - which is what keeps
    /// the creature pass's early-out true the rest of the time.
    bool ConsumeQuestRefresh(Player* player)
    {
        if (!player || !g_viewRefreshCount.load(std::memory_order_relaxed))
            return false;

        std::lock_guard<std::mutex> guard(g_viewRefreshLock);
        auto itr = g_viewRefresh.find(player->GetGUID().GetRawValue());
        if (itr == g_viewRefresh.end())
            return false;

        uint32 const now = getMSTime();
        bool const expired = itr->second.CreatureUntil <= now;

        if (!itr->second.QuestLogDue)
        {
            if (expired)
                ErasePending(itr);
            return false;
        }

        itr->second.QuestLogDue = false;
        if (expired)
            ErasePending(itr);       // the log was the last thing this client was owed
        return true;
    }

    /// Called when a client leaves the world, so a stale entry cannot outlive it.
    void ForgetClient(ObjectGuid guid)
    {
        std::lock_guard<std::mutex> guard(g_viewRefreshLock);
        if (g_viewRefresh.erase(guid.GetRawValue()))
            g_viewRefreshCount.fetch_sub(1, std::memory_order_relaxed);
        g_leadersSeen.erase(guid.GetRawValue());
        g_toldState.erase(guid.GetRawValue());   // a returning character is seeded again on login
        g_lastSpoken.erase(guid.GetRawValue());
    }

    /// True once per leader arrival: logging in, or being handed leadership. A leader's switch decides
    /// the group, so their arrival changes what every member is shown.
    bool MarkLeaderSeen(ObjectGuid guid)
    {
        std::lock_guard<std::mutex> guard(g_viewRefreshLock);
        return g_leadersSeen.insert(guid.GetRawValue()).second;
    }

    void PatchField(ByteBuffer& data, BuildValuesCachePosPointers& pos, uint16 index, uint32 value)
    {
        auto it = pos.other.find(index);
        if (it != pos.other.end())
            data.put(it->second, value);
    }
}

namespace DestinyWeaver
{
uint32 RefreshClient(Player* player, bool remindDefault)
{
    if (!player || !player->IsInWorld())
        return 0;

    MarkClientDirty(player, remindDefault);
    return 1;
}

uint32 RefreshGroup(Group* group, bool remindDefault)
{
    if (!group)
        return 0;

    uint32 marked = 0;
    for (GroupReference* itr = group->GetFirstMember(); itr != nullptr; itr = itr->next())
        if (Player* member = itr->GetSource())
            marked += RefreshClient(member, remindDefault);

    return marked;
}

void RefreshScalingClients(Player* player)
{
    if (!player)
        return;

    // While grouped the leader's switch is the group's, so one character's answer changing is every
    // member's answer changing. Only *what is shown* is marked here - nothing is written to a
    // member's own choice, which is what makes the group an override rather than a change. The
    // group's own list already contains the acting character.
    uint32 const marked = player->GetGroup() ? RefreshGroup(player->GetGroup()) : RefreshClient(player);

    LOG_INFO("module.destiny_weaver",
             "{}'s scaling state changed: re-sending the creature view and quest log of {} client(s)",
             player->GetName(), marked);
}

void NotifyScalingSelf(Player* player, bool enabled)
{
    if (!player)
        return;

    // Marked after the choice is stored, so the state recorded is the one the character is now being
    // shown rather than the one just written: a member of a group is still shown their leader's
    // switch, and the group sentence would then be announcing a change that never happened. Their
    // own line is the Weaver's, either way.
    RecordToldState(player);
    NotifyPersonalScaling(player, enabled);
}
}

/// The per-character half of open-world scaling: what one character is shown of a creature, what
/// their damage does to it, and what it does to them. Every entry point resolves the *viewer* first,
/// so no character can change what another one sees.
class destiny_weaver_view_script : public UnitScript
{
public:
    // Every hook this script overrides has to be listed here: the core dispatches a hook only to the
    // scripts that registered it (`CALL_ENABLED_HOOKS` walks `EnabledHooks[hook]`), so an override
    // that is not listed is dead code and the fight silently keeps the authored numbers.
    // `DealDamage` is the one exception - it is dispatched to every registered unit script.
    destiny_weaver_view_script()
        : UnitScript("destiny_weaver_view_script", true,
                     {UNITHOOK_SHOULD_TRACK_VALUES_UPDATE_POS_BY_INDEX, UNITHOOK_ON_PATCH_VALUES_UPDATE,
                      UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
                      UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK}) { }

    // The fields the view rewrites, so their offsets inside the values block are known when the
    // block is patched for each recipient. Tracked for every update type, not just UPDATETYPE_VALUES:
    // a creature a character has never seen arrives in a *create* block, and that first block is the
    // one that decides the level they will be looking at.
    bool ShouldTrackValuesUpdatePosByIndex(Unit const* unit, uint8 /*updateType*/, uint16 index) override
    {
        return unit && unit->ToCreature() && TrackedField(index);
    }

    void OnPatchValuesUpdate(Unit const* unit, ByteBuffer& data, BuildValuesCachePosPointers& pos,
                             Player* target) override
    {
        Creature const* creature = unit ? unit->ToCreature() : nullptr;
        if (!creature || !target)
            return;

        CreatureView view;
        bool const viewed = ViewFor(creature, target, view);
        PatchScalingFlag(data, pos, viewed);
        if (!viewed)
            return;

        CreatureTemplate const* info = creature->GetCreatureTemplate();
        uint32 const realMaxHealth = std::max<uint32>(creature->GetMaxHealth(), 1);
        uint32 const health = uint32(uint64(creature->GetHealth()) * view.MaxHealth / realMaxHealth);

        PatchField(data, pos, UNIT_FIELD_LEVEL, view.Level);
        PatchField(data, pos, UNIT_FIELD_MAXHEALTH, view.MaxHealth);
        PatchField(data, pos, UNIT_FIELD_HEALTH, health);

        // The mana row scales with the level the same way, so the bar that goes with it does too.
        if (info && creature->GetMaxPower(POWER_MANA))
        {
            LevelStats const ownStats = StatsAt(creature->GetLevel(), info);
            if (ownStats.Mana)
            {
                uint32 const realMaxMana = std::max<uint32>(creature->GetMaxPower(POWER_MANA), 1);
                uint32 const maxMana = std::max<uint32>(1, uint32(uint64(realMaxMana) * view.Stats.Mana / ownStats.Mana));
                uint32 const mana = uint32(uint64(creature->GetPower(POWER_MANA)) * maxMana / realMaxMana);
                PatchField(data, pos, UNIT_FIELD_MAXPOWER1, maxMana);
                PatchField(data, pos, UNIT_FIELD_POWER1, mana);
            }
        }

        // Enough to prove in the log that a view was sent, without one line per creature per client.
        static std::atomic<uint32> logged{0};
        if (logged.fetch_add(1, std::memory_order_relaxed) < 8)
            LOG_INFO("module.destiny_weaver",
                     "{} is shown creature entry {} at level {} (authored {}): pool {}, armor {}, "
                     "damage x{:.2f}",
                     target->GetName(), creature->GetEntry(), uint32(view.Level), uint32(creature->GetLevel()),
                     view.MaxHealth, view.Stats.Armor, view.DamageTakenFactor);
    }

    /// Damage from a character to a creature. This runs after the client has been told the number,
    /// which is exactly why it works: the pool that character is watching is `1 / DamageDealtToPool`
    /// times the real one, so taking that fraction out of the real pool drops their bar by the number
    /// they were shown, and the fight lasts what a fight at their version's level lasts.
    uint32 DealDamage(Unit* attacker, Unit* victim, uint32 damage, DamageEffectType /*damagetype*/,
                      std::optional<uint32>* scriptHealthLeechDamage) override
    {
        Creature* creature = victim ? victim->ToCreature() : nullptr;
        Player* player = OwningPlayer(attacker);
        if (!creature || !player || !damage)
            return damage;

        CreatureView view;
        if (!ViewFor(creature, player, view))
            return damage;

        if (!creature->IsAlive() || creature->IsEvadingAttacks())
            return damage;

        if (scriptHealthLeechDamage)
        {
            uint32 const realMaxHealth = std::max<uint32>(creature->GetMaxHealth(), 1);
            uint32 const viewHealth = uint32(uint64(creature->GetHealth()) * view.MaxHealth / realMaxHealth);
            *scriptHealthLeechDamage = std::min(damage, viewHealth);
        }

        auto* remainder = creature->CustomData.GetDefault<DamageRemainder>(DAMAGE_REMAINDER_KEY);
        double const total = double(damage) * view.DamageDealtToPool + remainder->Value;
        uint32 const whole = uint32(total);
        remainder->Value = total - whole;
        return whole;
    }

    /// Damage from a creature to a character, melee. Runs while the hit is still being calculated, so
    /// the number the client is shown and the health it loses are the same scaled one.
    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        Creature* creature = attacker ? attacker->ToCreature() : nullptr;
        Player* player = OwningPlayer(target);
        if (!creature || !player || !damage)
            return;

        CreatureView view;
        if (!ViewFor(creature, player, view))
            return;

        double const blow = DestinyWeaver::ViewBlow(damage, creature->GetFloatValue(UNIT_FIELD_MINDAMAGE),
                                                    creature->GetFloatValue(UNIT_FIELD_MAXDAMAGE), view.DamageTakenLow,
                                                    view.DamageTakenHigh, view.DamageTakenFactor, rand_norm());
        damage = DestinyWeaver::WholeDamage(blow, rand_norm());
    }

    /// The same for a creature's spells.
    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* /*spellInfo*/) override
    {
        Creature* creature = attacker ? attacker->ToCreature() : nullptr;
        Player* player = OwningPlayer(target);
        if (!creature || !player || damage <= 0)
            return;

        CreatureView view;
        if (ViewFor(creature, player, view))
            damage = std::max<int32>(1, int32(double(damage) * view.DamageTakenFactor));
    }

    /// And for a creature's damage over time, which reaches a character through the same rule. The
    /// same hook also carries periodic *heals*, so a beneficial spell is left alone - a scaled
    /// creature does not heal for the damage its version would deal.
    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        Creature* creature = attacker ? attacker->ToCreature() : nullptr;
        Player* player = OwningPlayer(target);
        if (!creature || !player || !damage || (spellInfo && spellInfo->IsPositive()))
            return;

        CreatureView view;
        if (ViewFor(creature, player, view))
            damage = std::max<uint32>(1, uint32(double(damage) * view.DamageTakenFactor));
    }

    // Hit, crit, dodge, parry and block need no hook here. Every one of them is rolled from the level
    // each side is *relative to the other*, which the core asks for through `getLevelForTarget`,
    // `GetMaxSkillValueForLevel` and `GetUnitMeleeSkill` - and those answer with the view as soon as
    // `ViewLevelForCore` is installed below. Rewriting the roll here a second time would give the same
    // numbers from a second definition, which is exactly how the two drift apart later.
};

/// Serves the refresh requests, on the thread that owns the object being refreshed.
///
/// Creatures: one pass per creature update, which is the cheapest possible place to look - a single
/// atomic read when nothing is pending, and only for a few seconds after a group actually changed.
/// The creature itself is the only thing written to here; the broadcast it triggers is what reaches
/// each viewer, and each viewer's block is patched to its own version on the way out.
class destiny_weaver_view_refresh_script : public AllCreatureScript
{
public:
    destiny_weaver_view_refresh_script()
        : AllCreatureScript("destiny_weaver_view_refresh_script") { }

    void OnCreatureSelectLevel(CreatureTemplate const* /*info*/, Creature* creature) override
    {
        creature->CustomData.Erase(DAMAGE_REMAINDER_KEY);
    }

    void OnCreatureAddWorld(Creature* creature) override
    {
        MarkScalable(creature);
    }

    void OnCreatureRemoveWorld(Creature* creature) override
    {
        creature->CustomData.Erase(DAMAGE_REMAINDER_KEY);
        creature->CustomData.Erase(SEEN_FACTION_KEY);
    }

    void OnAllCreatureUpdate(Creature* creature, uint32 /*diff*/) override
    {
        if (!creature || !creature->IsInWorld())
            return;

        if (!creature->IsAlive() || creature->IsEvadingAttacks())
            creature->CustomData.Erase(DAMAGE_REMAINDER_KEY);

        if (creature->IsAlive())
            MarkScalable(creature);

        if (creature->HasDynamicFlag(UNIT_DYNFLAG_LEVEL_SCALING) && FactionChanged(creature))
            ForceViewFields(creature);

        // Nothing pending: the whole world pays one relaxed atomic read per creature update.
        if (!g_viewRefreshCount.load(std::memory_order_relaxed))
            return;

        for (auto const& reference : creature->GetMap()->GetPlayers())
        {
            Player* player = reference.GetSource();
            if (!player || !player->IsAlive() || !creature->InSamePhase(player))
                continue;

            if (!creature->IsWithinDistInMap(player, VIEW_REFRESH_RANGE))
                continue;

            if (!ClaimCreatureFor(player->GetGUID(), creature->GetGUID()))
                continue;

            ForceViewFields(creature);
            return;
        }
    }
};

/// The client half: the quest log, which may only be written to from the character's own thread, and
/// the leader's arrival, which changes what every member of their group is shown.
class destiny_weaver_view_client_script : public PlayerScript
{
public:
    destiny_weaver_view_client_script()
        : PlayerScript("destiny_weaver_view_client_script",
                       { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT,
                         PLAYERHOOK_ON_LEVEL_CHANGED }) { }

    void OnPlayerLevelChanged(Player* player, uint8 /*oldLevel*/) override
    {
        DestinyWeaver::RefreshClient(player);
    }

    /// The baseline the group notifications are measured against: whatever is true of this character
    /// the moment they enter the world. Nothing is sent here - a character is never told about a
    /// state they are arriving into, only about one that changes while they are playing.
    void OnPlayerLogin(Player* player) override
    {
        SeedToldState(player);
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!player)
            return;

        if (ConsumeQuestRefresh(player))
            player->RefreshQuestLogQueries();

        // A leader arriving - by login, or by being handed the lead - brings their switch with them,
        // and every member's answer changes with it. The lead is also the one character who can be
        // asked about it without a lock, so it is the cheapest place to notice.
        if (Group* group = player->GetGroup())
            if (group->GetLeaderGUID() == player->GetGUID() && MarkLeaderSeen(player->GetGUID()))
                DestinyWeaver::RefreshGroup(group);
    }

    void OnPlayerLogout(Player* player) override
    {
        if (!player)
            return;

        // The switch follows the leader while they are here. Once they are gone every member answers
        // with their own choice again, so their clients have to be told that the world moved.
        if (Group* group = player->GetGroup())
            if (group->GetLeaderGUID() == player->GetGUID())
                DestinyWeaver::RefreshGroup(group);

        ForgetClient(player->GetGUID());
    }
};

/// Installs this module's half of the core's scaling rules: who owns a character's quest-level
/// answer, the offset a scaled creature sits at, the armor a viewer's version of a creature wears,
/// and what a scaled quest pays. The core checks its own realm switches first and only then asks the
/// owner, so a realm that never turns quest scaling on keeps its old behaviour, and a character who
/// never chose follows DestinyWeaver.LevelScaling.Default.
class destiny_weaver_scaling_owner : public WorldScript
{
public:
    destiny_weaver_scaling_owner()
        : WorldScript("destiny_weaver_scaling_owner",
                      { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_SHUTDOWN, WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    /// A challenge started or stopped: the character's creatures and quest log are re-sent, the same
    /// refresh a level-up gets.
    static void RefreshChangedScaling(Player* player)
    {
        DestinyWeaver::RefreshClient(player);
    }

    /// The tuning is this realm's own setting, so it is applied on start and on every config load:
    /// a `.reload config` retunes it without a restart.
    static void ApplyTuning()
    {
        uint8 const offset = ScalingOffset();
        LocalLevelScaling::CreatureOffset.store(offset, std::memory_order_relaxed);
        PublishScope();

        // The switches, cached for the fight paths, and the resolvers installed or removed here rather
        // than only at startup: a `.reload config` that turns the feature on (or off) has to take
        // effect on the next creature, not on the next restart.
        bool const available = sConfigMgr->GetOption<bool>("DestinyWeaver.Enable", true) &&
                               sConfigMgr->GetOption<bool>("DestinyWeaver.LevelScaling", true);
        g_scalingAvailable.store(available, std::memory_order_relaxed);
        LocalLevelScaling::QuestScalingOwner.store(
            available ? &DestinyWeaver::ResolveQuestScaling : nullptr, std::memory_order_relaxed);
        LocalLevelScaling::CreatureViewArmorOwner.store(available ? &ViewArmorFor : nullptr,
                                                        std::memory_order_relaxed);
        LocalLevelScaling::CreatureViewLevelOwner.store(available ? &ViewLevelForCore : nullptr,
                                                        std::memory_order_relaxed);
        LocalLevelScaling::CreatureViewMaxHealthOwner.store(available ? &ViewMaxHealthForCore : nullptr,
                                                            std::memory_order_relaxed);
        LocalLevelScaling::ScalingChangedOwner.store(available ? &RefreshChangedScaling : nullptr,
                                                     std::memory_order_relaxed);

        LOG_INFO("module.destiny_weaver",
                 "open world scaling: creatures per character, level - {} in the open world and the "
                 "character's level inside a dungeon's band, every stat row with it (health, mana, armor, "
                 "damage, skills); quest levels follow each character's choice",
                 offset);
    }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        ApplyTuning();
    }

    void OnStartup() override
    {
        ApplyTuning();   // which is also what installs the resolvers above

        if (!ScalingAvailable())
            return;

        LOG_INFO("module.destiny_weaver",
                 "quest levels follow each character's own scaling choice; a creature's combat level, "
                 "armor and stats follow each character's view of it");
    }

    void OnShutdown() override
    {
        LocalLevelScaling::QuestScalingOwner.store(nullptr);
        LocalLevelScaling::CreatureViewArmorOwner.store(nullptr);
        LocalLevelScaling::CreatureViewLevelOwner.store(nullptr);
        LocalLevelScaling::CreatureViewMaxHealthOwner.store(nullptr);
        LocalLevelScaling::ScalingChangedOwner.store(nullptr);
    }
};

void AddSC_destiny_weaver_scaling()
{
    new destiny_weaver_view_script();
    new destiny_weaver_view_refresh_script();
    new destiny_weaver_view_client_script();
    new destiny_weaver_scaling_owner();
}
