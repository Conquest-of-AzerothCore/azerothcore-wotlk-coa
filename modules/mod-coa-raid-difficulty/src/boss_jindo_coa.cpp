/*
 * Jin'do the Hexxer with Ascension's spells.
 *
 * Kit: Ascension's block 2118500-2118562. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json.
 *
 *   Delusions of Jin'do   first 14s, every 20s    random player: sees the
 *                                                 Other Side, a Shade of Jin'do
 *                                                 hunts them, Shadow damage every
 *                                                 5s that doubles every 10s,
 *                                                 +350% damage against undead
 *   Brain Wash Totems     first 16s, every 60s    three over the pit (five above
 *                                                 Normal), each casts Brainwash
 *                                                 on a player: stunned and
 *                                                 pacified while it stands
 *   Healing Stream Totem  first 21s, every 60s    casts Healing Stream on him:
 *                                                 every second 1% of his missing
 *                                                 health while it stands
 *   Animate Bones         first 23s, every 30s    eight Sacrificed Trolls rise
 *                                                 in the Blood Pit and join the
 *                                                 fight; they Fierce Blow too
 *   Fierce Blow           first 8s, every 8s      on the tank
 *   Friends On the Other Side  +2% damage for every shade alive
 *   Berserk               at 15 minutes           Ascended only (2100213)
 *
 *   Every hit takes one health from a totem: a Brain Wash Totem has 5, the
 *   ward 15 (25 above Normal). The pit is empty before the fight, and he casts
 *   neither Hex nor Banish (tester, live).
 *
 * From stock: the shade's invisibility and random aggro, the totems and the
 * dance when the raid wipes.
 *
 * Decided here, not in the data:
 *   - the totems are the stock creatures, summoned by Ascension's cast bars;
 *     that the brain wash totem casts Brainwash and the ward casts Healing
 *     Stream is read from the spells' names and targets. Both auras last
 *     seven days in the data, so they end when their totem dies or despawns;
 *   - the totems spread over the Bloodfire Pit (tester 2026-11-14, marked on a
 *     screenshot): each stands at a random point of the area its outer trash
 *     pack spots enclose (tester 2026-11-15: random, not fixed spots), on the
 *     floor those spots stand on, out of the water, in his sight and within its
 *     spell's range of him, and at least 20 yards from the others of its wave
 *     where the floor allows. The area and the spacing are estimated; the live
 *     video does not show where the totems stand. Away from the pit they stand
 *     ten yards around him. Mythic and Ascended use the Heroic totem counts and
 *     health;
 *   - he resets once no living player near him is in combat, whatever his
 *     ward, totems or shades still do (testers 2026-11-16: the ward kept him in
 *     the fight after a wipe); the 250 yard reach is estimated;
 *   - a curse is the vision 2118511 and one damage tier, as in the live logs;
 *     the vision itself lets its target see the shades;
 *   - the Shade of Jin'do neither swings nor casts Shadow Shock: in the CoA logs
 *     of 2026-08-02 and 2026-08-24 it only casts Seeking Shadow Bolts (2118556,
 *     4s, interruptible) over and over, while every 4s each player takes a
 *     Seeking Shadow Bolt (2118551 by difficulty) until the shade dies; an
 *     interrupted cast does not stop them.
 */

#include "CreatureScript.h"
#include "GameTime.h"
#include "PassiveAI.h"
#include "PathGenerator.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "TemporarySummon.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"
#include "zg_coa_leash.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <list>
#include <map>
#include <optional>
#include <vector>

using namespace coa_zg;

namespace
{
    enum Say
    {
        SAY_AGGRO = 1
    };

    enum Spells
    {
        SPELL_SUMMON_SHADE_OF_JINDO    = 24308,

        SPELL_SUMMON_BRAIN_WASH        = 2118501,
        SPELL_BRAINWASH                = 2118502,
        SPELL_SUMMON_HEALING_STREAM    = 2118503,
        SPELL_HEALING_STREAM           = 2118504,
        SPELL_HEALING_STREAM_HEAL      = 2118506,
        SPELL_DELUSIONS                = 2118510,
        SPELL_DELUSIONS_VISION         = 2118511,
        SPELL_DELUSIONS_DOT            = 2118512,
        SPELL_FRIENDS_ON_THE_OTHER_SIDE = 2118518,
        SPELL_ANIMATE_BONES            = 2118560,

        SPELL_SHADE_OF_JINDO_PASSIVE   = 24307,
        SPELL_SHADE_OF_JINDO_VISUAL    = 24313,
        SPELL_RANDOM_AGGRO             = 23878,
        SPELL_SEEKING_SHADOW_BOLT      = 2118551,
        SPELL_SEEKING_SHADOW_BOLTS_BAR = 2118556,
    };

    enum Events
    {
        EVENT_DELUSIONS = 1,
        EVENT_BRAIN_WASH,
        EVENT_ANIMATE_BONES,
        EVENT_HEALING_STREAM,
        EVENT_FIERCE_BLOW,
        EVENT_DELUSIONS_GROW,
        EVENT_BERSERK,
    };

    enum Npcs
    {
        NPC_POWERFUL_HEALING_WARD = 14987
    };

    constexpr Milliseconds DELUSIONS_DOUBLING = 10s;
    constexpr float JINDO_RAID_REACH = 250.0f;
    constexpr Milliseconds TOTEM_LIFETIME     = 240s;
    constexpr Milliseconds TROLL_CORPSE_DECAY = 5s;
    constexpr Milliseconds JINDO_FIERCE_BLOW  = 8s;
    constexpr float TOTEM_DISTANCE            = 10.0f;
    constexpr float TOTEM_SPACING             = 20.0f;
    constexpr float TOTEM_SPOT_TAKEN          = 3.0f;
    constexpr uint8 BRAIN_WASH_TOTEMS_NORMAL  = 3;
    constexpr uint8 BRAIN_WASH_TOTEMS_HEROIC  = 5;
    constexpr uint32 BRAIN_WASH_TOTEM_HEALTH  = 5;
    constexpr uint32 HEALING_WARD_HEALTH_NORMAL = 15;
    constexpr uint32 HEALING_WARD_HEALTH_HEROIC = 25;
    constexpr uint8 ANIMATED_TROLLS           = 8;
    constexpr Milliseconds SEEKING_SHADOW_BOLTS = 4s;
    constexpr float SEEKING_SHADOW_BOLTS_RANGE  = 200.0f;
    constexpr float SHADE_SPAWN_MIN             = 15.0f;
    constexpr float SHADE_SPAWN_MAX             = 30.0f;
    constexpr float SHADE_SPOT_CLIMB            = 10.0f;
    constexpr float SHADE_SPOT_ON_GROUND        = 1.5f;
    constexpr uint8 SHADE_SPOT_ATTEMPTS         = 32;

    std::array<Position, 10> const BloodPitTrolls =
    { {
        { -11584.2f, -1252.21f, 77.6299f, 0.959931f },
        { -11582.5f, -1250.32f, 77.6299f, 3.90954f },
        { -11581.5f, -1252.54f, 77.6299f, 2.61799f },
        { -11583.2f, -1254.83f, 77.6299f, 1.67552f },
        { -11586.4f, -1253.92f, 77.6299f, 0.750492f },
        { -11586.6f, -1250.72f, 77.6299f, 6.07375f },
        { -11585.1f, -1248.76f, 77.6299f, 5.23599f },
        { -11582.3f, -1247.86f, 77.6299f, 4.36332f },
        { -11580.2f, -1250.6f, 77.6299f, 3.36848f },
        { -11580.6f, -1254.79f, 77.6299f, 2.28638f },
    } };

    std::array<Position, 6> const BloodfirePitCorners =
    { {
        { -11613.4f, -1278.9f, 79.84f, 0.0f },
        { -11571.1f, -1308.7f, 79.17f, 0.0f },
        { -11537.6f, -1289.9f, 78.85f, 0.0f },
        { -11532.0f, -1270.0f, 79.11f, 0.0f },
        { -11550.1f, -1223.9f, 80.22f, 0.0f },
        { -11601.1f, -1228.4f, 79.11f, 0.0f },
    } };
    constexpr float BLOODFIRE_PIT_FLOOR_LOW   = 76.6f;
    constexpr float BLOODFIRE_PIT_FLOOR_HIGH  = 81.2f;
    constexpr uint8 TOTEM_SPOT_ATTEMPTS       = 64;

    bool InsideBloodfirePit(float x, float y)
    {
        bool left = false;
        bool right = false;
        for (std::size_t i = 0; i < BloodfirePitCorners.size(); ++i)
        {
            Position const& from = BloodfirePitCorners[i];
            Position const& to = BloodfirePitCorners[(i + 1) % BloodfirePitCorners.size()];
            float const side = (to.GetPositionX() - from.GetPositionX()) * (y - from.GetPositionY()) -
                (to.GetPositionY() - from.GetPositionY()) * (x - from.GetPositionX());
            left = left || side > 0.0f;
            right = right || side < 0.0f;
        }
        return !(left && right);
    }

    bool AboveNormal(Unit const* unit)
    {
        return unit->GetMap()->GetSpawnMode() > 0;
    }

    struct boss_jindo_coa : public BossAI
    {
        boss_jindo_coa(Creature* creature) : BossAI(creature, DATA_JINDO)
        {
            SetBoundary(coa_zg::LeashFor(DATA_JINDO));
        }

        void Reset() override
        {
            BossAI::Reset();
            _delusions.clear();
            _shades = 0;
            me->RemoveAurasDueToSpell(SPELL_FRIENDS_ON_THE_OTHER_SIDE);
            ReleaseTotemAuras(true);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(SAY_AGGRO);
            me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NONE);

            events.ScheduleEvent(EVENT_FIERCE_BLOW, JINDO_FIERCE_BLOW);
            events.ScheduleEvent(EVENT_DELUSIONS, 14s);
            events.ScheduleEvent(EVENT_BRAIN_WASH, 16s);
            events.ScheduleEvent(EVENT_HEALING_STREAM, 21s);
            events.ScheduleEvent(EVENT_ANIMATE_BONES, 23s);
            events.ScheduleEvent(EVENT_DELUSIONS_GROW, 1s);
            if (IsAscended(me))
                events.ScheduleEvent(EVENT_BERSERK, ASCENDED_BERSERK_TIMER);
        }

        void JustSummoned(Creature* summon) override
        {
            BossAI::JustSummoned(summon);
            if (summon->GetEntry() == NPC_BRAIN_WASH_TOTEM)
            {
                summon->SetReactState(REACT_PASSIVE);
                if (Unit* target = BrainwashTarget(summon))
                    summon->CastSpell(target, SPELL_BRAINWASH, false);
            }
            else if (summon->GetEntry() == NPC_POWERFUL_HEALING_WARD)
                summon->CastSpell(me, SPELL_HEALING_STREAM, false);
            else if (summon->GetEntry() == NPC_SACRIFICED_TROLL)
                DoZoneInCombat(summon);
        }

        Unit* BrainwashTarget(Creature const* totem)
        {
            uint32 const skipTank = me->GetThreatMgr().GetThreatListSize() > 1 ? 1 : 0;
            float const range = sSpellMgr->AssertSpellInfo(SPELL_BRAINWASH)->GetMaxRange(false);
            auto inReach = [totem, range](Unit const* target)
            {
                return totem->IsWithinDistInMap(target, range) && totem->IsWithinLOSInMap(target);
            };
            DefaultTargetSelector fresh(me, 0.0f, true, true, -int32(SPELL_BRAINWASH));
            if (Unit* target = SelectTarget(SelectTargetMethod::Random, skipTank,
                [&](Unit* unit) { return fresh(unit) && inReach(unit); }))
                return target;
            DefaultTargetSelector any(me, 0.0f, true, true, 0);
            return SelectTarget(SelectTargetMethod::Random, skipTank,
                [&](Unit* unit) { return any(unit) && inReach(unit); });
        }

        bool TotemStandsAt(Position const& spot) const
        {
            for (ObjectGuid const& guid : summons)
                if (Creature const* totem = ObjectAccessor::GetCreature(*me, guid))
                    if (totem->IsAlive() && totem->GetExactDist2d(spot) < TOTEM_SPOT_TAKEN &&
                        (totem->GetEntry() == NPC_BRAIN_WASH_TOTEM || totem->GetEntry() == NPC_POWERFUL_HEALING_WARD))
                        return true;
            return false;
        }

        std::optional<Position> RandomPitSpot(float reach) const
        {
            auto [lowX, highX] = std::minmax_element(BloodfirePitCorners.begin(), BloodfirePitCorners.end(),
                [](Position const& a, Position const& b) { return a.GetPositionX() < b.GetPositionX(); });
            auto [lowY, highY] = std::minmax_element(BloodfirePitCorners.begin(), BloodfirePitCorners.end(),
                [](Position const& a, Position const& b) { return a.GetPositionY() < b.GetPositionY(); });
            float const x = frand(lowX->GetPositionX(), highX->GetPositionX());
            float const y = frand(lowY->GetPositionY(), highY->GetPositionY());
            if (!InsideBloodfirePit(x, y))
                return std::nullopt;

            float const z = me->GetMap()->GetHeight(me->GetPhaseMask(), x, y, BLOODFIRE_PIT_FLOOR_HIGH);
            if (z < BLOODFIRE_PIT_FLOOR_LOW || z > BLOODFIRE_PIT_FLOOR_HIGH)
                return std::nullopt;

            Position const spot(x, y, z, frand(0.0f, 2.0f * float(M_PI)));
            if (me->GetExactDist2d(spot) > reach || !me->IsWithinLOS(x, y, z) ||
                me->GetMap()->IsInWater(me->GetPhaseMask(), x, y, z, DEFAULT_COLLISION_HEIGHT))
                return std::nullopt;
            return spot;
        }

        std::vector<Position> SpreadTotemSpots(uint8 count, float reach) const
        {
            std::vector<Position> picked;
            auto clear = [this, &picked](Position const& spot, float spacing)
            {
                return !TotemStandsAt(spot) && std::none_of(picked.begin(), picked.end(),
                    [&spot, spacing](Position const& other) { return other.GetExactDist2d(spot) < spacing; });
            };
            for (float const spacing : { TOTEM_SPACING, TOTEM_SPOT_TAKEN })
                for (uint8 attempt = 0; attempt < TOTEM_SPOT_ATTEMPTS && picked.size() < count; ++attempt)
                    if (std::optional<Position> spot = RandomPitSpot(reach))
                        if (clear(*spot, spacing))
                            picked.push_back(*spot);
            return picked;
        }

        void SummonSpread(uint32 entry, uint8 count, uint32 reachSpell)
        {
            float const reach = sSpellMgr->AssertSpellInfo(reachSpell)->GetMaxRange(false);
            std::vector<Position> spots = SpreadTotemSpots(count, reach);
            float const step = 2.0f * float(M_PI) / count;
            float const start = frand(0.0f, step);
            for (uint8 i = uint8(spots.size()); i < count; ++i)
                spots.push_back(me->GetNearPosition(TOTEM_DISTANCE, start + step * i));
            for (Position const& spot : spots)
                me->SummonCreature(entry, spot, TEMPSUMMON_TIMED_DESPAWN, TOTEM_LIFETIME.count());
        }

        void AnimateBones()
        {
            std::vector<Position> spots(BloodPitTrolls.begin(), BloodPitTrolls.end());
            Acore::Containers::RandomResize(spots, ANIMATED_TROLLS);
            for (Position const& spot : spots)
                me->SummonCreature(NPC_SACRIFICED_TROLL, spot, TEMPSUMMON_CORPSE_TIMED_DESPAWN, TROLL_CORPSE_DECAY.count());
        }

        // Totems do not report their despawn, so the auras are checked against their caster.
        void ReleaseTotemAuras(bool all)
        {
            auto orphaned = [all](Aura const* aura)
            {
                Unit* totem = aura->GetCaster();
                return all || !totem || !totem->IsAlive();
            };
            me->GetMap()->DoForAllPlayers([&](Player* player)
            {
                if (Aura* aura = player->GetAura(SPELL_BRAINWASH))
                    if (orphaned(aura))
                        player->RemoveAura(aura);
            });
            if (Aura* aura = me->GetAura(SPELL_HEALING_STREAM))
                if (orphaned(aura))
                    me->RemoveAura(aura);
        }

        void JustDied(Unit* killer) override
        {
            BossAI::JustDied(killer);
            ReleaseTotemAuras(true);
            DespawnShades();
        }

        // +2% damage per shade alive.
        void UpdateFriends()
        {
            // The shades are summoned by the cursed players, not by him.
            std::list<Creature*> found;
            me->GetCreatureListWithEntryInGrid(found, NPC_SHADE_OF_JINDO, 200.0f);
            uint8 shades = 0;
            for (Creature* c : found)
                if (c->IsAlive())
                    ++shades;
            if (shades == _shades)
                return;
            _shades = shades;

            me->RemoveAurasDueToSpell(SPELL_FRIENDS_ON_THE_OTHER_SIDE);
            if (!shades)
                return;
            // CastCustomSpell adds the spell's one point of dice on top.
            int32 bonus = Info(me, SPELL_FRIENDS_ON_THE_OTHER_SIDE, 1) * shades - 1;
            me->CastCustomSpell(me, SPELL_FRIENDS_ON_THE_OTHER_SIDE, nullptr, &bonus, nullptr, true);
        }

        bool WalkableFromJindo(float x, float y, float z) const
        {
            dtNavMeshQuery const* navMesh = me->GetMap()->GetMapCollisionData().GetMMapData().GetNavMeshQuery();
            if (!navMesh)
                return true;

            float const spot[VERTEX_SIZE] = { y, z, x };
            float const extents[VERTEX_SIZE] = { SHADE_SPOT_ON_GROUND, SHADE_SPOT_ON_GROUND, SHADE_SPOT_ON_GROUND };
            dtQueryFilter const filter;
            dtPolyRef ground = INVALID_POLYREF;
            if (dtStatusFailed(navMesh->findNearestPoly(spot, extents, &filter, &ground, nullptr)) ||
                ground == INVALID_POLYREF)
                return false;

            PathGenerator path(me);
            path.CalculatePath(x, y, z);
            return path.GetPathType() == PATHFIND_NORMAL;
        }

        Position RandomShadeSpot()
        {
            for (uint8 attempt = 0; attempt < SHADE_SPOT_ATTEMPTS; ++attempt)
            {
                float const angle = frand(0.0f, 2.0f * float(M_PI));
                float const distance =
                    std::sqrt(frand(SHADE_SPAWN_MIN * SHADE_SPAWN_MIN, SHADE_SPAWN_MAX * SHADE_SPAWN_MAX));
                float const x = me->GetPositionX() + distance * std::cos(angle);
                float const y = me->GetPositionY() + distance * std::sin(angle);
                float const z =
                    me->GetMap()->GetHeight(me->GetPhaseMask(), x, y, me->GetPositionZ() + SHADE_SPOT_CLIMB);
                if (std::fabs(z - me->GetPositionZ()) <= SHADE_SPOT_CLIMB && me->IsWithinLOS(x, y, z) &&
                    !me->GetMap()->IsInWater(me->GetPhaseMask(), x, y, z, DEFAULT_COLLISION_HEIGHT) &&
                    WalkableFromJindo(x, y, z))
                    return Position(x, y, z, Position::NormalizeOrientation(angle + float(M_PI)));
            }
            return me->GetFirstCollisionPosition(SHADE_SPAWN_MIN, frand(0.0f, 2.0f * float(M_PI)));
        }

        void SummonShade(Unit* cursed)
        {
            uint32 const lifetime = uint32(sSpellMgr->AssertSpellInfo(SPELL_SUMMON_SHADE_OF_JINDO)->GetDuration());
            if (TempSummon* shade = cursed->SummonCreature(NPC_SHADE_OF_JINDO, RandomShadeSpot(),
                TEMPSUMMON_TIMED_DESPAWN, lifetime))
                _shadeGuids.insert(shade->GetGUID());
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_DELUSIONS:
                    if (Unit* target = ObjectAccessor::GetUnit(*me, _target))
                    {
                        me->AddAura(SPELL_DELUSIONS_VISION, target);
                        me->CastSpell(target, SPELL_DELUSIONS_DOT, true);
                        SummonShade(target);
                        _delusions[target->GetGUID()] = GameTime::GetGameTimeMS();
                    }
                    break;
                case SPELL_SUMMON_BRAIN_WASH:
                    SummonSpread(NPC_BRAIN_WASH_TOTEM,
                        AboveNormal(me) ? BRAIN_WASH_TOTEMS_HEROIC : BRAIN_WASH_TOTEMS_NORMAL, SPELL_BRAINWASH);
                    break;
                case SPELL_SUMMON_HEALING_STREAM:
                    SummonSpread(NPC_POWERFUL_HEALING_WARD, 1, SPELL_HEALING_STREAM);
                    break;
                case SPELL_ANIMATE_BONES:
                    AnimateBones();
                    break;
                default:
                    break;
            }
        }

        // The Delusions damage doubles every 10 seconds on each target.
        void GrowDelusions()
        {
            uint32 const now = GameTime::GetGameTimeMS().count();
            for (auto it = _delusions.begin(); it != _delusions.end();)
            {
                Unit* target = ObjectAccessor::GetUnit(*me, it->first);
                AuraEffect* dot = target ? target->GetAuraEffect(sSpellMgr->GetSpellIdForDifficulty(SPELL_DELUSIONS_DOT, me), EFFECT_0) : nullptr;
                if (!dot)
                {
                    it = _delusions.erase(it);
                    continue;
                }
                uint32 const steps = (now - uint32(it->second.count())) / uint32(DELUSIONS_DOUBLING.count());
                int32 const base = Info(me, SPELL_DELUSIONS_DOT);
                int32 const wanted = base << std::min<uint32>(steps, 5);
                if (dot->GetAmount() != wanted)
                    dot->ChangeAmount(wanted);
                ++it;
            }
        }

        void DespawnShades()
        {
            for (ObjectGuid const& guid : _shadeGuids)
                if (Creature* shade = ObjectAccessor::GetCreature(*me, guid))
                    shade->DespawnOrUnsummon();
            _shadeGuids.clear();
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            if (CreatureAI::_EnterEvadeMode(why))
            {
                DespawnShades();
                Reset();
                me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_DANCE);
                Creature* jindo = me;
                me->m_Events.AddEventAtOffset([jindo]()
                {
                    jindo->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NONE);
                    jindo->GetMotionMaster()->MoveTargetedHome();
                }, 4s);
            }
        }

        bool RaidStillFights()
        {
            return !Players(me, [this](Player* player)
            {
                return player->IsInCombat() && me->IsWithinDistInMap(player, JINDO_RAID_REACH);
            }).empty();
        }

        void UpdateAI(uint32 diff) override
        {
            if (me->IsEngaged() && !RaidStillFights())
            {
                EnterEvadeMode(EVADE_REASON_NO_HOSTILES);
                return;
            }

            if (!UpdateVictim())
                return;

            events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_DELUSIONS:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true, true, -int32(SPELL_DELUSIONS_VISION)))
                        {
                            _target = target->GetGUID();
                            DoCast(target, SPELL_DELUSIONS);
                        }
                        events.ScheduleEvent(EVENT_DELUSIONS, 20s);
                        break;
                    case EVENT_BRAIN_WASH:
                        DoCastSelf(SPELL_SUMMON_BRAIN_WASH);
                        events.ScheduleEvent(EVENT_BRAIN_WASH, 60s);
                        break;
                    case EVENT_ANIMATE_BONES:
                        DoCastSelf(SPELL_ANIMATE_BONES);
                        events.ScheduleEvent(EVENT_ANIMATE_BONES, 30s);
                        break;
                    case EVENT_HEALING_STREAM:
                        DoCastSelf(SPELL_SUMMON_HEALING_STREAM);
                        events.ScheduleEvent(EVENT_HEALING_STREAM, 60s);
                        break;
                    case EVENT_FIERCE_BLOW:
                        DoCastVictim(SPELL_FIERCE_BLOW);
                        events.ScheduleEvent(EVENT_FIERCE_BLOW, JINDO_FIERCE_BLOW);
                        break;
                    case EVENT_DELUSIONS_GROW:
                        GrowDelusions();
                        UpdateFriends();
                        ReleaseTotemAuras(false);
                        events.ScheduleEvent(EVENT_DELUSIONS_GROW, 1s);
                        break;
                    case EVENT_BERSERK:
                        DoCastSelf(SPELL_ASCENDED_BERSERK, true);
                        break;
                    default:
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        ObjectGuid _target;
        std::map<ObjectGuid, Milliseconds> _delusions;
        uint8 _shades = 0;
        GuidSet _shadeGuids;
    };

    struct npc_jindo_coa_totem : public NullCreatureAI
    {
        npc_jindo_coa_totem(Creature* creature) : NullCreatureAI(creature) { }

        void IsSummonedBy(WorldObject* /*summoner*/) override
        {
            uint32 const health = me->GetEntry() == NPC_BRAIN_WASH_TOTEM ? BRAIN_WASH_TOTEM_HEALTH
                : AboveNormal(me) ? HEALING_WARD_HEALTH_HEROIC : HEALING_WARD_HEALTH_NORMAL;
            me->SetMaxHealth(health);
            me->SetHealth(health);
        }

        void DamageTaken(Unit* /*attacker*/, uint32& damage, DamageEffectType /*type*/, SpellSchoolMask /*school*/) override
        {
            if (damage)
                damage = 1;
        }
    };

    struct npc_shade_of_jindo_coa : public ScriptedAI
    {
        npc_shade_of_jindo_coa(Creature* creature) : ScriptedAI(creature) { }

        void IsSummonedBy(WorldObject* /*summoner*/) override
        {
            DoZoneInCombat();
            DoCastSelf(SPELL_SHADE_OF_JINDO_PASSIVE, true);
            DoCastSelf(SPELL_SHADE_OF_JINDO_VISUAL, true);
            DoCastAOE(SPELL_RANDOM_AGGRO, true);
            _scheduler.Schedule(SEEKING_SHADOW_BOLTS, [this](TaskContext volley)
            {
                for (Player* player : PlayersWithin(me, SEEKING_SHADOW_BOLTS_RANGE))
                    me->CastSpell(player, SPELL_SEEKING_SHADOW_BOLT, true);
                volley.Repeat();
            }).Schedule(0ms, [this](TaskContext bar)
            {
                if (!me->HasUnitState(UNIT_STATE_CASTING))
                    if (Unit* target = me->GetVictim() ? me->GetVictim() : SelectTarget(SelectTargetMethod::Random, 0))
                        me->CastSpell(target, SPELL_SEEKING_SHADOW_BOLTS_BAR, TRIGGERED_IGNORE_AURA_INTERRUPT_FLAGS);
                bar.Repeat(500ms);
            }).Schedule(1s, [this](TaskContext aggro)
            {
                DoCastAOE(SPELL_RANDOM_AGGRO, true);
                aggro.Repeat();
            });
        }

        bool CanAlwaysBeDetectable(WorldObject const* seer) override
        {
            Unit const* unit = seer->ToUnit();
            return unit && unit->HasAura(SPELL_DELUSIONS_VISION);
        }

        void UpdateAI(uint32 diff) override
        {
            _scheduler.Update(diff);
        }

    private:
        TaskScheduler _scheduler;
    };

    // Healing Stream: every second its first value in percent of the target's missing health.
    class spell_jindo_coa_healing_stream : public AuraScript
    {
        PrepareAuraScript(spell_jindo_coa_healing_stream);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            return ValidateSpellInfo({ SPELL_HEALING_STREAM_HEAL });
        }

        void HandlePeriodic(AuraEffect const* /*aurEff*/)
        {
            PreventDefaultAction();
            Unit* caster = GetCaster();
            Unit* target = GetTarget();
            if (!caster || target->IsFullHealth())
                return;
            int32 heal = int32(CalculatePct(target->GetMaxHealth() - target->GetHealth(),
                GetSpellInfo()->Effects[EFFECT_0].CalcValue(caster)));
            if (heal > 0)
                caster->CastCustomSpell(target, SPELL_HEALING_STREAM_HEAL, &heal, nullptr, nullptr, true);
        }

        void Register() override
        {
            OnEffectPeriodic += AuraEffectPeriodicFn(spell_jindo_coa_healing_stream::HandlePeriodic, EFFECT_1,
                SPELL_AURA_PERIODIC_TRIGGER_SPELL);
        }
    };

    class spell_jindo_coa_delusions_vision : public AuraScript
    {
        PrepareAuraScript(spell_jindo_coa_delusions_vision);

        void RefreshShadeSight(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            GetTarget()->UpdateObjectVisibility();
        }

        void Register() override
        {
            AfterEffectApply += AuraEffectApplyFn(spell_jindo_coa_delusions_vision::RefreshShadeSight, EFFECT_0,
                SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
            AfterEffectRemove += AuraEffectRemoveFn(spell_jindo_coa_delusions_vision::RefreshShadeSight, EFFECT_0,
                SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        }
    };
}

void AddCoaJindoScripts()
{
    RegisterZulGurubCreatureAI(boss_jindo_coa);
    RegisterZulGurubCreatureAI(npc_jindo_coa_totem);
    RegisterZulGurubCreatureAI(npc_shade_of_jindo_coa);
    RegisterSpellScript(spell_jindo_coa_healing_stream);
    RegisterSpellScript(spell_jindo_coa_delusions_vision);
}
