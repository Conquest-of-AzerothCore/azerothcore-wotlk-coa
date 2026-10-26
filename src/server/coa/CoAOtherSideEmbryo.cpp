/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAOtherSideDamage.h"
#include "Creature.h"
#include "GameObject.h"
#include "Map.h"
#include "MotionMaster.h"
#include "MoveSpline.h"
#include "MoveSplineInit.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include <cmath>
#include <list>
#include <vector>

namespace
{
enum EmbryoData : uint32
{
    NPC_CONTROLLER = 162731,
    NPC_POISON_ZONE = 162739,
    NPC_WEB_MARK = 162740,
    NPC_WEB = 162741,
    NPC_SPIDER = 162743,
    NPC_SPIKE = 162973,
    NPC_EGG = 9370010,
    GO_BRIDGE = 2300563,
    GO_BLOOD_POOL = 9370001,
    NPC_BODY_OF_OFFERING = 162972,

    SPELL_SPIKES = 256878,
    SPELL_SPIKES_HC = 257182,
    SPELL_SPIKES_MYTHIC = 257183,
    SPELL_SPIKE_MARK = 256852,
    SPELL_SPIKE_VISUAL = 256922,
    SPELL_SPIKE_HIT = 257161,
    SPELL_POISON_BOLT = 256882,
    SPELL_POISON_BOLT_HC = 257063,
    SPELL_POISON_BOLT_MYTHIC = 257064,
    SPELL_RITUAL = 256872,
    SPELL_RITUAL_HC = 256965,
    SPELL_RITUAL_MYTHIC = 256967,
    SPELL_NOVA = 256873,
    SPELL_CIRCLE = 256875,
    SPELL_SWIRL = 256883,
    SPELL_BLOB = 256874,
    SPELL_WEB_MARK_VISUAL = 256879,
    SPELL_WEB_ACTIVE = 256880,
    SPELL_WEB_SHOT = 257135,
    SPELL_POISON_WAVE = 256877,
    SPELL_FIERCE_BLOW = 975011,

    SOUND_EGG_KICK = 215092,

    SAY_AGGRO = 0,
    SAY_SWIRLS = 1,
    SAY_DEATH = 2,

    POINT_MIDDLE = 1,
    POINT_HOVER = 2,
    POINT_LAND = 3,

    ACTION_SPIKES_FIRE = 1,

    EVENT_SPIKES = 1,
    EVENT_POISON_BOLT,
    EVENT_FIERCE_BLOW,
    EVENT_WEB_LINES,
    EVENT_EGG_PHASE_NOVA,
    EVENT_EGG_PHASE_RITUAL,
    EVENT_EGG_PHASE_SWIRLS,
    EVENT_EGG_PHASE_BLOBS,
    EVENT_EGG_RAIN,
    EVENT_EGG_PHASE_STOP,
    EVENT_EGG_LAST_RAIN,
    EVENT_EGG_HATCH,
    EVENT_SPIDERS_RUN,
    EVENT_LAND,
};

enum class Phase : uint8
{
    Ground,
    Eggs,
    Landed,
};

constexpr uint32 SwirlsAtMs = 7000;
constexpr uint32 BlobsAtMs = 9000;
constexpr uint32 EggsAtMs = 10000;
constexpr uint32 PhaseStopMs = 47000;
constexpr uint32 LastRainMs = 50000;
constexpr uint32 HatchMs = 51000;
constexpr uint32 SpidersRunMs = 52000;
constexpr uint32 LandMs = 53000;
constexpr uint32 RitualChannelMs = 30000;

constexpr float FacingPlatform = 1.16f;
constexpr float HoverHeight = 4.0f;
constexpr float CircleRadius = 10.0f;
constexpr float OrbitRadius = 14.5f;
constexpr float OrbitSpeed = 5.0f;
constexpr uint32 OrbitPoints = 24;
constexpr float EggTouch = 1.3f;
constexpr uint32 SpidersPerEgg = 1;

constexpr float SpikeLineAngle = float(M_PI) / 6.0f;
constexpr float SpikeStart = 3.0f;
constexpr float SpikeStep = 2.5f;
constexpr uint32 SpikeStepMs = 60;
constexpr int32 SpikeRadiusMod = 80000;

constexpr uint32 WebTrackMs = 3000;
constexpr uint32 WebHoldMs = 1000;
constexpr float BlobKnockSpeedXY = 10.0f;
constexpr float BlobKnockSpeedZ = 6.0f;
constexpr float BlobBehind = 4.5f;
constexpr float BlobAhead = 6.5f;
constexpr float BlobSide = 4.5f;
constexpr float WebTouch = 1.5f;
Position const ArenaMiddle = { 304.429f, -206.081f, 341.841f, 0.0f };
constexpr float WebSpeed = 25.0f;

using CoAOtherSide::BaseSpellId;
using CoAOtherSide::Damage3;
using CoAOtherSide::Rolled;
constexpr Damage3 SpikeHit = { 400, 1200 };
constexpr Damage3 PoisonBoltHit = { 300, 1000 };
constexpr Damage3 PoisonBoltTick = { 40, 150 };

uint32 ByDifficulty(WorldObject const* source, uint32 normal, uint32 heroic, uint32 mythic)
{
    switch (source->GetMap()->GetDifficulty())
    {
        case DUNGEON_DIFFICULTY_HEROIC:
            return heroic;
        case DUNGEON_DIFFICULTY_EPIC:
            return mythic;
        default:
            return normal;
    }
}

struct boss_coa_chimeric_embryo : public ScriptedAI
{
    explicit boss_coa_chimeric_embryo(Creature* creature) : ScriptedAI(creature), _summons(creature) { }

    void Reset() override
    {
        _events.Reset();
        _summons.DespawnAll();
        _eggs.clear();
        _spikes.clear();
        _webs.clear();
        _phase = Phase::Ground;
        _eggPhasePending = false;
        me->SetDisableGravity(false);
        me->SetReactState(REACT_AGGRESSIVE);
        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
    }

    void IsSummonedBy(WorldObject* ) override
    {
        me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
        me->SetReactState(REACT_PASSIVE);
        if (Creature* controller = me->FindNearestCreature(NPC_CONTROLLER, 200.0f))
            me->GetMotionMaster()->MovePoint(POINT_MIDDLE, controller->GetPosition());
        else
            _wakeIn = 1000;
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != POINT_MOTION_TYPE && type != EFFECT_MOTION_TYPE)
            return;
        switch (id)
        {
            case POINT_MIDDLE:
            {
                me->SetFacingTo(FacingPlatform);
                Position home = me->GetPosition();
                home.SetOrientation(FacingPlatform);
                me->SetHomePosition(home);
                _wakeIn = 1000;
                break;
            }
            case POINT_HOVER:
                me->SetFacingTo(FacingPlatform);
                break;
            default:
                break;
        }
    }

    void JustEngagedWith(Unit* ) override
    {
        _center = ArenaMiddle;
        ClearRitual();
        ShowBridge(false);
        Talk(SAY_AGGRO);
        _events.ScheduleEvent(EVENT_SPIKES, 5s);
        _events.ScheduleEvent(EVENT_FIERCE_BLOW, 10s);
    }

    void DamageTaken(Unit* , uint32& damage, DamageEffectType , SpellSchoolMask ) override
    {
        if (_phase == Phase::Ground && !_eggPhasePending && me->HealthBelowPctDamaged(50, damage))
            _eggPhasePending = true;
    }

    void EnterEvadeMode(EvadeReason why) override
    {
        ShowBridge(true);
        me->SetDisableGravity(false);
        ScriptedAI::EnterEvadeMode(why);
    }

    void JustDied(Unit* ) override
    {
        Talk(SAY_DEATH);
        ShowBridge(true);
        _summons.DespawnAll();
    }

    void JustSummoned(Creature* summon) override
    {
        _summons.Summon(summon);
    }

    void DoAction(int32 action) override
    {
        if (action == ACTION_SPIKES_FIRE)
            FireSpikes();
    }

    void UpdateAI(uint32 diff) override
    {
        if (_wakeIn)
        {
            if (_wakeIn <= diff)
            {
                _wakeIn = 0;
                me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
                me->SetReactState(REACT_AGGRESSIVE);
            }
            else
                _wakeIn -= diff;
        }

        if (!UpdateVictim())
            return;

        UpdateSpikes(diff);
        UpdateWebs(diff);
        UpdateEggs(diff);
        _events.Update(diff);

        if (_eggPhasePending && !me->HasUnitState(UNIT_STATE_CASTING))
            StartEggPhase();

        if (me->HasUnitState(UNIT_STATE_CASTING) && _phase != Phase::Eggs)
            return;

        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_SPIKES:
                    StartSpikes();
                    _events.Repeat(20s);
                    break;
                case EVENT_POISON_BOLT:
                    DoCastAOE(ByDifficulty(me, SPELL_POISON_BOLT, SPELL_POISON_BOLT_HC, SPELL_POISON_BOLT_MYTHIC));
                    _events.Repeat(10s);
                    break;
                case EVENT_FIERCE_BLOW:
                    if (_phase != Phase::Eggs)
                        DoCastVictim(SPELL_FIERCE_BLOW);
                    _events.Repeat(14s);
                    break;
                case EVENT_WEB_LINES:
                    WebLines();
                    _events.Repeat(10s);
                    break;
                case EVENT_EGG_PHASE_NOVA:
                    DoCastAOE(SPELL_NOVA, true);
                    _events.Repeat(3s);
                    break;
                case EVENT_EGG_PHASE_RITUAL:
                    _events.CancelEvent(EVENT_EGG_PHASE_NOVA);
                    DoCastSelf(ByDifficulty(me, SPELL_RITUAL, SPELL_RITUAL_HC, SPELL_RITUAL_MYTHIC), true);
                    if (!_ritualRecast)
                    {
                        _ritualRecast = true;
                        _events.Repeat(Milliseconds(RitualChannelMs));
                    }
                    break;
                case EVENT_EGG_PHASE_SWIRLS:
                    Talk(SAY_SWIRLS);
                    SpawnSwirls();
                    break;
                case EVENT_EGG_PHASE_BLOBS:
                    for (ObjectGuid const& guid : _swirls)
                        if (Creature* swirl = ObjectAccessor::GetCreature(*me, guid))
                        {
                            swirl->RemoveAurasDueToSpell(SPELL_SWIRL);
                            swirl->CastSpell(swirl, SPELL_BLOB, true);
                        }
                    break;
                case EVENT_EGG_RAIN:
                    RainEggs();
                    _events.Repeat(3s);
                    break;
                case EVENT_EGG_PHASE_STOP:
                    StopEggPhase();
                    break;
                case EVENT_EGG_LAST_RAIN:
                    RainEggs();
                    break;
                case EVENT_EGG_HATCH:
                    HatchEggs();
                    break;
                case EVENT_SPIDERS_RUN:
                    SpidersRun();
                    break;
                case EVENT_LAND:
                    Land();
                    break;
                default:
                    break;
            }
            if (me->HasUnitState(UNIT_STATE_CASTING) && _phase != Phase::Eggs)
                return;
        }

        if (_phase != Phase::Eggs)
            DoMeleeAttackIfReady();
    }

private:
    void ClearRitual()
    {
        std::list<Creature*> bodies;
        me->GetCreatureListWithEntryInGrid(bodies, NPC_BODY_OF_OFFERING, 200.0f);
        for (Creature* body : bodies)
            body->DespawnOrUnsummon();
        std::list<GameObject*> pools;
        me->GetGameObjectListWithEntryInGrid(pools, GO_BLOOD_POOL, 200.0f);
        for (GameObject* pool : pools)
            pool->DespawnOrUnsummon();
    }

    void ShowBridge(bool show)
    {
        std::list<GameObject*> bridges;
        me->GetGameObjectListWithEntryInGrid(bridges, GO_BRIDGE, 200.0f);
        for (GameObject* bridge : bridges)
            bridge->SetPhaseMask(show ? PHASEMASK_NORMAL : 0x40000000, true);
    }

    Position GroundAt(float x, float y) const
    {
        float const z = me->GetMap()->GetHeight(me->GetPhaseMask(), x, y, _center.GetPositionZ() + 10.0f);
        return { x, y, z > INVALID_HEIGHT ? z : _center.GetPositionZ(), 0.0f };
    }

    Position WallFrom(Position const& from, float angle, float reach = 60.0f, float lift = 2.0f) const
    {
        Position const wall = me->GetFirstCollisionPosition(from.GetPositionX(), from.GetPositionY(), from.GetPositionZ() + lift,
            from.GetPositionX() + reach * std::cos(angle), from.GetPositionY() + reach * std::sin(angle));
        float const limit = from.GetExactDist2d(&wall);
        float last = 0.0f;
        for (float dist = 0.5f; dist <= limit; dist += 0.5f)
        {
            float const x = from.GetPositionX() + dist * std::cos(angle);
            float const y = from.GetPositionY() + dist * std::sin(angle);
            float const z = me->GetMap()->GetHeight(me->GetPhaseMask(), x, y, from.GetPositionZ() + 10.0f);
            if (z <= INVALID_HEIGHT || std::fabs(z - from.GetPositionZ()) > 3.0f)
                break;
            last = dist;
        }
        return { from.GetPositionX() + last * std::cos(angle), from.GetPositionY() + last * std::sin(angle), from.GetPositionZ(), 0.0f };
    }

    Creature* Helper(uint32 entry, Position const& pos, uint32 lifeMs)
    {
        Creature* helper = me->SummonCreature(entry, pos, lifeMs ? TEMPSUMMON_TIMED_DESPAWN : TEMPSUMMON_MANUAL_DESPAWN, lifeMs);
        if (helper)
        {
            helper->SetReactState(REACT_PASSIVE);
            helper->RemoveUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
        }
        return helper;
    }

    void StartSpikes()
    {
        uint32 const spell = ByDifficulty(me, SPELL_SPIKES, SPELL_SPIKES_HC, SPELL_SPIKES_MYTHIC);
        me->StopMoving();
        me->SetFacingTo(me->GetOrientation());
        DoCastSelf(spell);
        uint32 const castMs = sSpellMgr->GetSpellInfo(spell) ? sSpellMgr->GetSpellInfo(spell)->CalcCastTime() : 3000;
        Position const from = me->GetPosition();
        _spikes.clear();
        for (int32 line = -1; line <= 1; ++line)
        {
            float const angle = from.GetOrientation() + float(line) * SpikeLineAngle;
            Position const wall = WallFrom(from, angle, 60.0f, 4.0f);
            float const reach = from.GetExactDist2d(&wall) - 0.5f;
            uint32 step = 0;
            for (float dist = SpikeStart; dist <= reach; dist += SpikeStep, ++step)
            {
                Position const pos = GroundAt(from.GetPositionX() + dist * std::cos(angle), from.GetPositionY() + dist * std::sin(angle));
                if (Creature* spike = Helper(NPC_SPIKE, pos, castMs + 4000))
                {
                    spike->CastSpell(spike, SPELL_SPIKE_MARK, true);
                    if (Aura* mark = spike->GetAura(SPELL_SPIKE_MARK))
                    {
                        mark->SetMaxDuration(-1);
                        mark->SetDuration(-1);
                    }
                    _spikes.push_back({ spike->GetGUID(), step * SpikeStepMs, false });
                }
            }
        }
    }

    void FireSpikes()
    {
        for (PendingSpike& spike : _spikes)
            spike.armed = true;
    }

    void UpdateSpikes(uint32 diff)
    {
        for (auto itr = _spikes.begin(); itr != _spikes.end();)
        {
            if (!itr->armed)
            {
                ++itr;
                continue;
            }
            if (itr->delay > diff)
            {
                itr->delay -= diff;
                ++itr;
                continue;
            }
            if (Creature* spike = ObjectAccessor::GetCreature(*me, itr->guid))
            {
                spike->RemoveAurasDueToSpell(SPELL_SPIKE_MARK);
                me->AddAura(SPELL_SPIKE_VISUAL, spike);
                spike->CastCustomSpell(SPELL_SPIKE_HIT, SPELLVALUE_RADIUS_MOD, SpikeRadiusMod, nullptr, TRIGGERED_FULL_MASK,
                    nullptr, nullptr, me->GetGUID());
                spike->DespawnOrUnsummon(2500ms);
            }
            itr = _spikes.erase(itr);
        }
    }

    void WebLines()
    {
        std::list<Unit*> targets;
        SelectTargetList(targets, 2, SelectTargetMethod::Random, 0, 200.0f, true);
        for (Unit* target : targets)
        {
            float const angle = frand(0.0f, 2.0f * float(M_PI));
            Position const wall = WallFrom(_center, angle);
            float const reach = std::max(2.0f, _center.GetExactDist2d(&wall) - 1.0f);
            Position start = GroundAt(_center.GetPositionX() + reach * std::cos(angle), _center.GetPositionY() + reach * std::sin(angle));
            start.SetOrientation(start.GetAngle(target));
            uint32 const lifeMs = WebTrackMs + WebHoldMs + 8000;
            Creature* mark = Helper(NPC_WEB_MARK, start, lifeMs);
            Creature* blade = Helper(NPC_WEB, start, lifeMs);
            if (!mark || !blade)
                continue;
            mark->CastSpell(mark, SPELL_WEB_MARK_VISUAL, true);
            blade->CastSpell(blade, SPELL_WEB_SHOT, true);
            mark->SetTarget(target->GetGUID());
            blade->SetTarget(target->GetGUID());
            _webs.push_back({ mark->GetGUID(), blade->GetGUID(), target->GetGUID(), 0, start.GetOrientation(), false });
        }
    }

    void UpdateWebs(uint32 diff)
    {
        for (auto itr = _webs.begin(); itr != _webs.end();)
        {
            Creature* mark = ObjectAccessor::GetCreature(*me, itr->mark);
            Creature* blade = ObjectAccessor::GetCreature(*me, itr->blade);
            if (!mark || !blade)
            {
                itr = _webs.erase(itr);
                continue;
            }
            itr->elapsed += diff;
            if (itr->elapsed < WebTrackMs)
            {
                if (Unit* target = ObjectAccessor::GetUnit(*me, itr->target); target && target->IsAlive())
                {
                    itr->dir = mark->GetAngle(target);
                    mark->SetOrientation(itr->dir);
                    blade->SetOrientation(itr->dir);
                }
                ++itr;
                continue;
            }
            if (!itr->locked)
            {
                itr->locked = true;
                mark->SetTarget();
                blade->SetTarget();
                mark->SetFacingTo(itr->dir);
                blade->SetFacingTo(itr->dir);
            }
            if (itr->elapsed < WebTrackMs + WebHoldMs)
            {
                ++itr;
                continue;
            }
            float const dx = blade->GetPositionX() - _center.GetPositionX();
            float const dy = blade->GetPositionY() - _center.GetPositionY();
            float const length = std::max(1.0f, -2.0f * (dx * std::cos(itr->dir) + dy * std::sin(itr->dir)));
            Position const to = GroundAt(blade->GetPositionX() + length * std::cos(itr->dir),
                blade->GetPositionY() + length * std::sin(itr->dir));
            LOG_DEBUG("module", "Embryo: web line shoots {:.1f} yards", length);
            blade->CastSpell(blade, SPELL_WEB_ACTIVE, true);
            blade->GetMotionMaster()->MovePoint(1, to, FORCED_MOVEMENT_NONE, WebSpeed, false);
            blade->DespawnOrUnsummon(Milliseconds(uint32(length / WebSpeed * 1000.0f) + 300));
            mark->DespawnOrUnsummon(Milliseconds(uint32(length / WebSpeed * 1000.0f) + 300));
            itr = _webs.erase(itr);
        }
    }

    void StartEggPhase()
    {
        _eggPhasePending = false;
        _phase = Phase::Eggs;
        _ritualRecast = false;
        _events.CancelEvent(EVENT_SPIKES);
        _events.CancelEvent(EVENT_FIERCE_BLOW);
        me->InterruptNonMeleeSpells(false);
        me->AttackStop();
        me->SetReactState(REACT_PASSIVE);
        me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
        me->GetMotionMaster()->Clear();
        me->StopMoving();
        me->SetDisableGravity(true);
        me->GetMotionMaster()->MoveTakeoff(POINT_HOVER, _center.GetPositionX(), _center.GetPositionY(), _center.GetPositionZ() + HoverHeight);

        if (Creature* circle = Helper(NPC_POISON_ZONE, _center, 0))
        {
            circle->CastSpell(circle, SPELL_CIRCLE, true);
            _circle = circle->GetGUID();
        }

        _events.ScheduleEvent(EVENT_EGG_PHASE_NOVA, 0ms);
        _events.ScheduleEvent(EVENT_EGG_PHASE_RITUAL, Milliseconds(SwirlsAtMs));
        _events.ScheduleEvent(EVENT_EGG_PHASE_SWIRLS, Milliseconds(SwirlsAtMs));
        _events.ScheduleEvent(EVENT_EGG_PHASE_BLOBS, Milliseconds(BlobsAtMs));
        _events.ScheduleEvent(EVENT_EGG_RAIN, Milliseconds(EggsAtMs));
        _events.ScheduleEvent(EVENT_EGG_PHASE_STOP, Milliseconds(PhaseStopMs));
        _events.ScheduleEvent(EVENT_EGG_LAST_RAIN, Milliseconds(LastRainMs));
        _events.ScheduleEvent(EVENT_EGG_HATCH, Milliseconds(HatchMs));
        _events.ScheduleEvent(EVENT_SPIDERS_RUN, Milliseconds(SpidersRunMs));
        _events.ScheduleEvent(EVENT_LAND, Milliseconds(LandMs));
    }

    void SpawnSwirls()
    {
        _swirls.clear();
        float const start = frand(0.0f, 2.0f * float(M_PI));
        for (uint32 side = 0; side < 2; ++side)
        {
            float const first = start + float(side) * float(M_PI);
            Position const pos = GroundAt(_center.GetPositionX() + OrbitRadius * std::cos(first), _center.GetPositionY() + OrbitRadius * std::sin(first));
            Creature* swirl = Helper(NPC_POISON_ZONE, pos, 0);
            if (!swirl)
                continue;
            swirl->CastSpell(swirl, SPELL_SWIRL, true);
            Movement::PointsArray points;
            for (uint32 i = 0; i <= OrbitPoints; ++i)
            {
                float const angle = first + 2.0f * float(M_PI) * float(i) / float(OrbitPoints);
                Position const p = GroundAt(_center.GetPositionX() + OrbitRadius * std::cos(angle), _center.GetPositionY() + OrbitRadius * std::sin(angle));
                points.emplace_back(p.GetPositionX(), p.GetPositionY(), p.GetPositionZ() + 0.2f);
            }
            Movement::MoveSplineInit init(swirl);
            init.MovebyPath(points);
            init.SetFly();
            init.SetCyclic();
            init.SetVelocity(OrbitSpeed);
            init.Launch();
            _swirls.push_back(swirl->GetGUID());
        }
    }

    void RainEggs()
    {
        uint32 const count = 3;
        for (uint32 i = 0; i < count; ++i)
        {
            float const angle = frand(0.0f, 2.0f * float(M_PI));
            Position const wall = WallFrom(_center, angle);
            float const outer = std::max(CircleRadius + 2.0f, _center.GetExactDist2d(&wall) - 2.0f);
            float const dist = frand(CircleRadius + 1.5f, outer);
            Position const to = GroundAt(_center.GetPositionX() + dist * std::cos(angle), _center.GetPositionY() + dist * std::sin(angle));
            Creature* egg = Helper(NPC_EGG, me->GetPosition(), 0);
            if (!egg)
                continue;
            egg->GetMotionMaster()->MoveJump(to, 18.0f, 12.0f);
            _eggs.push_back({ egg->GetGUID(), false });
        }
    }

    void UpdateEggs(uint32 diff)
    {
        if (_eggs.empty())
            return;
        _eggCheck += diff;
        if (_eggCheck < 200)
            return;
        _eggCheck = 0;
        std::list<Unit*> players;
        SelectTargetList(players, 40, SelectTargetMethod::Random, 0, 200.0f, true);
        for (auto itr = _eggs.begin(); itr != _eggs.end();)
        {
            Creature* egg = ObjectAccessor::GetCreature(*me, itr->guid);
            if (!egg)
            {
                itr = _eggs.erase(itr);
                continue;
            }
            if (itr->kicked || egg->HasUnitState(UNIT_STATE_JUMPING) || !egg->movespline->Finalized())
            {
                ++itr;
                continue;
            }
            Unit* kicker = nullptr;
            for (Unit* player : players)
                if (player->IsAlive() && egg->GetExactDist2d(player) <= EggTouch)
                {
                    kicker = player;
                    break;
                }
            if (!kicker)
            {
                ++itr;
                continue;
            }
            egg->PlayDistanceSound(SOUND_EGG_KICK);
            float const angle = kicker->GetAngle(egg);
            Position const wall = WallFrom(egg->GetPosition(), angle, 12.0f);
            float const reach = std::max(2.0f, egg->GetExactDist2d(&wall) - 1.0f);
            egg->GetMotionMaster()->MoveJump(GroundAt(egg->GetPositionX() + reach * std::cos(angle), egg->GetPositionY() + reach * std::sin(angle)), 20.0f, 6.0f);
            egg->m_Events.AddEventAtOffset([egg]()
            {
                if (egg->IsAlive())
                    Unit::Kill(egg, egg);
            }, 800ms);
            egg->DespawnOrUnsummon(6s);
            itr = _eggs.erase(itr);
        }
    }

    void StopEggPhase()
    {
        _events.CancelEvent(EVENT_EGG_PHASE_NOVA);
        _events.CancelEvent(EVENT_EGG_PHASE_RITUAL);
        _events.CancelEvent(EVENT_EGG_RAIN);
        me->InterruptNonMeleeSpells(false);
        for (ObjectGuid const& guid : _swirls)
            if (Creature* swirl = ObjectAccessor::GetCreature(*me, guid))
                swirl->DespawnOrUnsummon();
        _swirls.clear();
        if (Creature* circle = ObjectAccessor::GetCreature(*me, _circle))
            circle->DespawnOrUnsummon();
        _circle.Clear();
    }

    void HatchEggs()
    {
        for (EggState const& state : _eggs)
        {
            Creature* egg = ObjectAccessor::GetCreature(*me, state.guid);
            if (!egg)
                continue;
            for (uint32 i = 0; i < SpidersPerEgg; ++i)
            {
                float const angle = frand(0.0f, 2.0f * float(M_PI));
                Position pos = GroundAt(egg->GetPositionX() + 0.8f * std::cos(angle), egg->GetPositionY() + 0.8f * std::sin(angle));
                pos.SetOrientation(angle);
                if (Creature* spider = me->SummonCreature(NPC_SPIDER, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 10000))
                {
                    spider->SetReactState(REACT_PASSIVE);
                    _spiders.push_back(spider->GetGUID());
                }
            }
            egg->DespawnOrUnsummon();
        }
        _eggs.clear();
    }

    void SpidersRun()
    {
        Unit* tank = SelectTarget(SelectTargetMethod::MaxThreat, 0, 200.0f, true);
        for (ObjectGuid const& guid : _spiders)
        {
            Creature* spider = ObjectAccessor::GetCreature(*me, guid);
            if (!spider || !spider->IsAlive())
                continue;
            spider->SetReactState(REACT_AGGRESSIVE);
            spider->SetInCombatWithZone();
            if (tank)
                spider->AI()->AttackStart(tank);
        }
        _spiders.clear();
    }

    void Land()
    {
        _phase = Phase::Landed;
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveLand(POINT_LAND, GroundAt(me->GetPositionX(), me->GetPositionY()));
        me->SetDisableGravity(false);
        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
        me->SetReactState(REACT_AGGRESSIVE);
        if (Unit* victim = SelectTarget(SelectTargetMethod::MaxThreat, 0, 200.0f, true))
            AttackStart(victim);
        _events.ScheduleEvent(EVENT_SPIKES, 5s);
        _events.ScheduleEvent(EVENT_WEB_LINES, 3s);
        _events.ScheduleEvent(EVENT_POISON_BOLT, 8s);
        _events.ScheduleEvent(EVENT_FIERCE_BLOW, 10s);
    }

    struct PendingSpike
    {
        ObjectGuid guid;
        uint32 delay;
        bool armed;
    };
    struct PendingWeb
    {
        ObjectGuid mark;
        ObjectGuid blade;
        ObjectGuid target;
        uint32 elapsed;
        float dir;
        bool locked;
    };
    struct EggState
    {
        ObjectGuid guid;
        bool kicked;
    };

    EventMap _events;
    SummonList _summons;
    Position _center;
    Phase _phase = Phase::Ground;
    std::vector<PendingSpike> _spikes;
    std::vector<PendingWeb> _webs;
    std::vector<EggState> _eggs;
    std::vector<ObjectGuid> _swirls;
    std::vector<ObjectGuid> _spiders;
    ObjectGuid _circle;
    uint32 _wakeIn = 0;
    uint32 _eggCheck = 0;
    bool _eggPhasePending = false;
    bool _ritualRecast = false;
};

class spell_coa_embryo_spikes : public SpellScript
{
    PrepareSpellScript(spell_coa_embryo_spikes);

    void HandleAfterCast()
    {
        if (Creature* caster = GetCaster() ? GetCaster()->ToCreature() : nullptr)
            if (caster->AI())
                caster->AI()->DoAction(ACTION_SPIKES_FIRE);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_coa_embryo_spikes::HandleAfterCast);
    }
};

class spell_coa_embryo_spike_hit : public SpellScript
{
    PrepareSpellScript(spell_coa_embryo_spike_hit);

    void HandleHit()
    {
        Unit* source = GetOriginalCaster() ? GetOriginalCaster() : GetCaster();
        SetHitDamage(Rolled(source, GetHitUnit(), SpikeHit, GetSpellInfo()));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_embryo_spike_hit::HandleHit);
    }
};

class spell_coa_embryo_venomous_ritual : public AuraScript
{
    PrepareAuraScript(spell_coa_embryo_venomous_ritual);

    void CalcPeriod(AuraEffect const* , bool& isPeriodic, int32& amplitude)
    {
        isPeriodic = true;
        if (Unit* caster = GetCaster())
            amplitude = int32(ByDifficulty(caster, 3000, 3000, 2000));
    }

    void Register() override
    {
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(spell_coa_embryo_venomous_ritual::CalcPeriod, EFFECT_1, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

bool OnBlob(Unit const* blob, Unit const* target)
{
    float const dist = blob->GetExactDist2d(target);
    float const off = blob->GetRelativeAngle(target);
    float const along = dist * std::cos(off);
    float const across = dist * std::sin(off);
    float const centre = (BlobAhead - BlobBehind) / 2.0f;
    float const halfAlong = (BlobAhead + BlobBehind) / 2.0f;
    float const a = (along - centre) / halfAlong;
    float const b = across / BlobSide;
    return a * a + b * b <= 1.0f;
}

class spell_coa_embryo_runover : public SpellScript
{
    PrepareSpellScript(spell_coa_embryo_runover);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        targets.clear();
        Unit* caster = GetCaster();
        if (!caster)
            return;
        uint32 const spellId = GetSpellInfo()->Id;
        bool const wave = BaseSpellId(spellId) == SPELL_POISON_WAVE;
        for (auto const& ref : caster->GetMap()->GetPlayers())
            if (Player* player = ref.GetSource(); player && player->IsAlive() && !player->IsGameMaster() && (wave ? OnBlob(caster, player) : caster->GetExactDist2d(player) <= WebTouch)
                && std::fabs(caster->GetPositionZ() - player->GetPositionZ()) < 4.0f && !player->HasAura(spellId))
                targets.push_back(player);
    }

    void HandleKnockBack(SpellEffIndex effIndex)
    {
        if (BaseSpellId(GetSpellInfo()->Id) != SPELL_POISON_WAVE)
            return;
        PreventHitDefaultEffect(effIndex);
        if (Unit* caster = GetCaster())
            if (Unit* target = GetHitUnit())
                target->KnockbackFrom(caster->GetPositionX(), caster->GetPositionY(), BlobKnockSpeedXY, BlobKnockSpeedZ);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_embryo_runover::FilterTargets, EFFECT_0, TARGET_UNIT_SRC_AREA_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_embryo_runover::FilterTargets, EFFECT_1, TARGET_UNIT_SRC_AREA_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_embryo_runover::FilterTargets, EFFECT_2, TARGET_UNIT_SRC_AREA_ENEMY);
        OnEffectHitTarget += SpellEffectFn(spell_coa_embryo_runover::HandleKnockBack, EFFECT_0, SPELL_EFFECT_KNOCK_BACK);
    }
};

class spell_coa_embryo_poison_bolt : public SpellScript
{
    PrepareSpellScript(spell_coa_embryo_poison_bolt);

    void HandleHit()
    {
        if (!GetHitDamage())
            return;
        SetHitDamage(Rolled(GetCaster(), GetHitUnit(), PoisonBoltHit, GetSpellInfo()));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_embryo_poison_bolt::HandleHit);
    }
};

class spell_coa_embryo_poison_bolt_aura : public AuraScript
{
    PrepareAuraScript(spell_coa_embryo_poison_bolt_aura);

    void CalcTick(AuraEffect const* , int32& amount, bool& )
    {
        if (Unit* caster = GetCaster())
            amount = Rolled(caster, GetUnitOwner(), PoisonBoltTick, GetSpellInfo());
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_coa_embryo_poison_bolt_aura::CalcTick, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};
}

void AddSC_CoAOtherSideEmbryo()
{
    RegisterCreatureAI(boss_coa_chimeric_embryo);
    RegisterSpellScript(spell_coa_embryo_spikes);
    RegisterSpellScript(spell_coa_embryo_spike_hit);
    RegisterSpellScript(spell_coa_embryo_runover);
    RegisterSpellScript(spell_coa_embryo_venomous_ritual);
    RegisterSpellAndAuraScriptPair(spell_coa_embryo_poison_bolt, spell_coa_embryo_poison_bolt_aura);
}
