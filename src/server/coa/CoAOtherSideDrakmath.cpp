/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAOtherSideDamage.h"
#include "Creature.h"
#include "Map.h"
#include "MotionMaster.h"
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
#include "WaypointMgr.h"
#include <cmath>
#include <limits>
#include <list>
#include <vector>

namespace
{
enum DrakmathData : uint32
{
    NPC_DRAKMATH = 162715,
    NPC_PILLAR = 162727,
    NPC_ORB = 162728,
    NPC_VOLZEEN = 162988,

    SPELL_ENCHANTED = 256839,
    SPELL_PARASITISM = 256867,
    SPELL_PARASITISM_HC = 257054,
    SPELL_PARASITISM_MYTHIC = 257055,
    SPELL_SUBMERGED = 256850,
    SPELL_PILLAR_VISUAL = 256854,
    SPELL_NECROTIC_EMERGE = 256021,
    SPELL_ORB_VISUAL = 256853,
    SPELL_ORB_CIRCLE = 256865,
    SPELL_NECROTIC_EXPLOSION = 256857,
    SPELL_NECROTIC_EXPLOSION_HC = 257057,
    SPELL_NECROTIC_EXPLOSION_MYTHIC = 257058,
    SPELL_DEATH_BEAM = 256858,
    SPELL_DEATH_BEAM_HIT = 256859,
    SPELL_DEATH_MISSILE = 256863,
    SPELL_DEATH_MISSILE_HIT = 256864,
    SPELL_DEATH_MISSILE_HIT_HC = 257051,
    SPELL_DEATH_MISSILE_HIT_MYTHIC = 257052,
    SPELL_IMPACT_ZONE = 256865,
    SPELL_FIERCE_BLOW = 975011,
    SPELL_COLOSSAL_SMASH = 256959,

    SAY_RISE = 0,
    SAY_AGGRO = 1,
    SAY_PILLARS = 2,
    SAY_DEATH = 3,

    EVENT_PARASITISM = 1,
    EVENT_FIERCE_BLOW,
    EVENT_SINK,
    EVENT_SUBMERGED,
    EVENT_SIDE_PILLARS,
    EVENT_SIDE_PILLARS_FADE,
    EVENT_RISE,
    EVENT_BEAM,
    EVENT_BEAM_WALK,
    EVENT_BEAM_PILLAR,
    EVENT_BEAM_END,
    EVENT_DEATH_MISSILE,
};

constexpr float SidePillarDistance = 10.0f;
constexpr float OrbSpeed = 2.0f;
constexpr float OrbTravel = 25.0f;
constexpr float OrbTouch = 2.0f;
constexpr float BeamLength = 45.0f;
constexpr float BeamConeHalfAngle = 15.0f * float(M_PI) / 180.0f;
constexpr float BeamMinHalfWidth = 2.0f;
constexpr uint32 BeamPillars = 10;
constexpr uint32 BeamChannelMs = 30000;
constexpr uint32 BeamTickMs = 500;
constexpr float LevitateHeight = 3.0f;

constexpr float OrbHover = 1.2f;
constexpr int32 OrbExplosionRadiusMod = 17500;
constexpr uint32 PointCenter = 1;
constexpr uint32 DisplayInvisible = 11686;

constexpr uint32 PathBeam = 1337801;
Position const ArenaCenter = { 290.11f, 150.62f, 248.04f, 0.0f };
Position const BeamWalkerStart = { 273.317f, 156.766f, 248.961f, 0.0f };

using CoAOtherSide::Damage3;
using CoAOtherSide::Rolled;
using CoAOtherSide::Unscaled;
constexpr Damage3 ParasitismHit = { 366, 1118 };
constexpr Damage3 ParasitismTick = { 56, 371 };
constexpr Damage3 NecroticEmerge = { 260, 660 };
constexpr Damage3 NecroticExplosion = { 340, 954 };
constexpr Damage3 DeathMissile = { 250, 750 };
constexpr uint32 MissileMarkMs = 2500;
constexpr float MissileSpeed = 15.0f;

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

bool InBeamCone(Unit const* caster, WorldObject const* walker, Unit const* target)
{
    float const beamAngle = caster->GetAngle(walker);
    float const dist = caster->GetExactDist2d(target);
    float off = Position::NormalizeOrientation(caster->GetAngle(target) - beamAngle);
    if (off > float(M_PI))
        off -= 2.0f * float(M_PI);
    float const along = dist * std::cos(off);
    float const across = std::fabs(dist * std::sin(off));
    float const halfWidth = std::max(BeamMinHalfWidth, along * std::tan(BeamConeHalfAngle));
    return along > 0.0f && along <= BeamLength && across <= halfWidth;
}

struct boss_coa_drakmath : public ScriptedAI
{
    explicit boss_coa_drakmath(Creature* creature) : ScriptedAI(creature), _summons(creature) { }

    void Reset() override
    {
        _events.Reset();
        _summons.DespawnAll();
        _orbs.clear();
        _missiles.clear();
        _timedPillars.clear();
        _sidePillars.clear();
        _phase = Phase::Fight;
        _beaming = false;
        me->RemoveAurasDueToSpell(SPELL_SUBMERGED);
        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
        me->SetControlled(false, UNIT_STATE_ROOT);
        me->SetCombatMovement(true);
        me->SetHover(false);
        me->SetDisableGravity(false);
        me->RestoreDisplayId();
        _beamWalker.Clear();
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_INTERRUPT, true);
        me->ApplySpellImmune(0, IMMUNITY_EFFECT, SPELL_EFFECT_INTERRUPT_CAST, true);
        DoCastSelf(SPELL_ENCHANTED, true);
    }

    void JustEngagedWith(Unit* ) override
    {
        me->RemoveAurasDueToSpell(SPELL_ENCHANTED);
        _home = me->GetHomePosition();
        _center = GroundAt(ArenaCenter.GetPositionX(), ArenaCenter.GetPositionY());
        _center.SetOrientation(_home.GetOrientation());
        _events.ScheduleEvent(EVENT_PARASITISM, 7s);
        _events.ScheduleEvent(EVENT_FIERCE_BLOW, 9s);
        _events.ScheduleEvent(EVENT_SINK, 15s);
        _pillarsSaid = false;
        Talk(SAY_AGGRO);
    }

    void JustSummoned(Creature* summon) override
    {
        _summons.Summon(summon);
    }

    void DamageTaken(Unit* , uint32& damage, DamageEffectType , SpellSchoolMask ) override
    {
        if (_phase == Phase::Sunk)
            damage = 0;
    }

    void JustDied(Unit* ) override
    {
        Talk(SAY_DEATH);
        _summons.DespawnAll();
        _beaming = false;
        me->RemoveAurasDueToSpell(SPELL_SUBMERGED);
        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
        me->SetControlled(false, UNIT_STATE_ROOT);
        me->SetHover(false);
        me->SetDisableGravity(false);
        me->RestoreDisplayId();
    }

    void UpdateAI(uint32 diff) override
    {
        if (_phase == Phase::Fight)
        {
            if (!UpdateVictim())
                return;
        }
        else if (!me->IsInCombat())
        {
            EnterEvadeMode(EVADE_REASON_NO_HOSTILES);
            return;
        }

        UpdateOrbs(diff);
        UpdateMissiles(diff);
        if (_beaming)
            UpdateBeam(diff);
        _events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING) && _phase != Phase::Beam)
            return;

        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_PARASITISM:
                    if (Busy())
                    {
                        _events.Repeat(1s);
                        break;
                    }
                    DoCastSelf(ByDifficulty(me, SPELL_PARASITISM, SPELL_PARASITISM_HC, SPELL_PARASITISM_MYTHIC));
                    _events.Repeat(55s);
                    break;
                case EVENT_FIERCE_BLOW:
                    if (!Busy())
                        DoCastVictim(SPELL_FIERCE_BLOW);
                    _events.Repeat(45s);
                    break;
                case EVENT_SINK:
                    if (me->GetExactDist2d(&_center) > 2.0f && _walkTries++ < 20)
                    {
                        if (me->HasUnitState(UNIT_STATE_CASTING))
                        {
                            _events.Repeat(500ms);
                            break;
                        }
                        _phase = Phase::Walk;
                        me->SetCombatMovement(false);
                        me->SetTarget();
                        me->GetMotionMaster()->Clear();
                        me->GetMotionMaster()->MovePoint(PointCenter, _center);
                        _events.Repeat(500ms);
                        break;
                    }
                    _walkTries = 0;
                    Sink();
                    break;
                case EVENT_SUBMERGED:
                    me->SetDisplayId(DisplayInvisible);
                    _sinkPos = me->GetPosition();
                    if (Creature* pillar = SummonPillar(_sinkPos, 10000, 1.0f))
                        _middlePillar = pillar->GetGUID();
                    _events.ScheduleEvent(EVENT_SIDE_PILLARS, 2s);
                    _events.ScheduleEvent(EVENT_RISE, 10s);
                    break;
                case EVENT_SIDE_PILLARS:
                    _sidePillars.clear();
                    for (float side : { float(M_PI) / 2.0f, -float(M_PI) / 2.0f })
                    {
                        float const angle = _sinkPos.GetOrientation() + side;
                        Position const pos = GroundAt(_sinkPos.GetPositionX() + SidePillarDistance * std::cos(angle),
                            _sinkPos.GetPositionY() + SidePillarDistance * std::sin(angle));
                        if (Creature* pillar = SummonPillar(pos, 4000))
                            _sidePillars.push_back(pillar->GetGUID());
                    }
                    _events.ScheduleEvent(EVENT_SIDE_PILLARS_FADE, 4s);
                    break;
                case EVENT_SIDE_PILLARS_FADE:
                    for (ObjectGuid guid : _sidePillars)
                        if (Creature* pillar = ObjectAccessor::GetCreature(*me, guid))
                            BurstPillar(pillar);
                    _sidePillars.clear();
                    break;
                case EVENT_RISE:
                    Rise();
                    break;
                case EVENT_BEAM:
                    if (Creature* walker = me->SummonCreature(NPC_PILLAR, BeamWalkerStart, TEMPSUMMON_TIMED_DESPAWN, 5000 + BeamChannelMs + 2000))
                    {
                        walker->SetReactState(REACT_PASSIVE);
                        walker->RemoveUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
                        _beamWalker = walker->GetGUID();
                        me->SetTarget(_beamWalker);
                        me->SetFacingToObject(walker);
                        DoCast(walker, SPELL_DEATH_BEAM);
                    }
                    _beaming = true;
                    _beamTick = BeamTickMs;
                    _beamLeft = 5000 + BeamChannelMs;
                    _beamPillars = 0;
                    _events.ScheduleEvent(EVENT_BEAM_WALK, 5s);
                    _events.ScheduleEvent(EVENT_BEAM_PILLAR, 5s);
                    _events.ScheduleEvent(EVENT_BEAM_END, Milliseconds(5000 + BeamChannelMs + 200));
                    _events.ScheduleEvent(EVENT_DEATH_MISSILE, 0ms);
                    break;
                case EVENT_BEAM_WALK:
                    if (Creature* walker = ObjectAccessor::GetCreature(*me, _beamWalker))
                        WalkTheCircle(walker);
                    break;
                case EVENT_BEAM_PILLAR:
                    if (Creature* pillar = SummonPillar(RandomArenaPoint(), 3000))
                        _timedPillars.push_back({ pillar->GetGUID(), 3000 });
                    if (++_beamPillars < BeamPillars)
                        _events.Repeat(3s);
                    break;
                case EVENT_DEATH_MISSILE:
                    MarkDeathMissile();
                    _events.Repeat(1s);
                    break;
                case EVENT_BEAM_END:
                    EndBeam();
                    break;
                default:
                    break;
            }
            if (me->HasUnitState(UNIT_STATE_CASTING) && _phase != Phase::Beam)
                return;
        }

        if (!Busy())
            DoMeleeAttackIfReady();
    }

private:
    bool Busy() const
    {
        return _phase != Phase::Fight;
    }

    Position GroundAt(float x, float y) const
    {
        float const z = me->GetMap()->GetHeight(me->GetPhaseMask(), x, y, _home.GetPositionZ() + 5.0f);
        return { x, y, z > INVALID_HEIGHT ? z : _home.GetPositionZ(), 0.0f };
    }

    Position WallFrom(Position const& from, float angle) const
    {
        return me->GetFirstCollisionPosition(from.GetPositionX(), from.GetPositionY(), from.GetPositionZ() + 2.0f,
            from.GetPositionX() + 40.0f * std::cos(angle), from.GetPositionY() + 40.0f * std::sin(angle));
    }

    Position RandomArenaPoint() const
    {
        float const angle = frand(0.0f, 2.0f * float(M_PI));
        Position const wall = WallFrom(_center, angle);
        float const reach = std::max(2.0f, _center.GetExactDist2d(&wall) - 4.0f);
        float const dist = reach * std::sqrt(frand(0.0f, 1.0f));
        return GroundAt(_center.GetPositionX() + dist * std::cos(angle), _center.GetPositionY() + dist * std::sin(angle));
    }

    Creature* SummonPillar(Position const& pos, uint32 lifeMs, float scale = 0.75f)
    {
        Creature* pillar = me->SummonCreature(NPC_PILLAR, pos, TEMPSUMMON_TIMED_DESPAWN, lifeMs + 500);
        if (pillar)
        {
            pillar->SetReactState(REACT_PASSIVE);
            pillar->SetObjectScale(scale);
            pillar->CastSpell(pillar, SPELL_PILLAR_VISUAL, true);
        }
        return pillar;
    }

    void BurstPillar(Creature* pillar)
    {
        pillar->CastSpell(pillar, SPELL_NECROTIC_EMERGE, true);
        ReleaseOrbs(pillar->GetPosition());
        pillar->DespawnOrUnsummon(200ms);
    }

    void ReleaseOrbs(Position const& from)
    {
        float const start = frand(0.0f, 2.0f * float(M_PI));
        for (uint32 i = 0; i < 3; ++i)
        {
            float const angle = start + float(i) * 2.0f * float(M_PI) / 3.0f;
            Position start = from;
            start.m_positionZ += OrbHover;
            Position const wall = WallFrom(from, angle);
            float const travel = std::min(OrbTravel, std::max(0.5f, from.GetExactDist2d(&wall) - 1.0f));
            Position const to = { from.GetPositionX() + travel * std::cos(angle), from.GetPositionY() + travel * std::sin(angle), start.GetPositionZ(), angle };
            Creature* orb = me->SummonCreature(NPC_ORB, start, TEMPSUMMON_TIMED_DESPAWN, uint32(travel / OrbSpeed * 1000.0f) + 1500);
            if (!orb)
                continue;
            orb->SetReactState(REACT_PASSIVE);
            orb->SetCanFly(true);
            orb->SetDisableGravity(true);
            orb->CastSpell(orb, SPELL_ORB_VISUAL, true);
            orb->GetMotionMaster()->MovePoint(1, to, FORCED_MOVEMENT_NONE, OrbSpeed, false);
            _orbs.push_back(orb->GetGUID());
        }
    }

    void UpdateOrbs(uint32 diff)
    {
        for (auto itr = _timedPillars.begin(); itr != _timedPillars.end();)
        {
            if (itr->second > diff)
            {
                itr->second -= diff;
                ++itr;
                continue;
            }
            if (Creature* pillar = ObjectAccessor::GetCreature(*me, itr->first))
                BurstPillar(pillar);
            itr = _timedPillars.erase(itr);
        }

        _orbCheck += diff;
        if (_orbCheck < 200)
            return;
        _orbCheck = 0;
        std::list<Unit*> players;
        SelectTargetList(players, 40, SelectTargetMethod::Random, 0, 200.0f, true);
        for (auto itr = _orbs.begin(); itr != _orbs.end();)
        {
            Creature* orb = ObjectAccessor::GetCreature(*me, *itr);
            if (!orb || !orb->IsAlive())
            {
                itr = _orbs.erase(itr);
                continue;
            }
            bool touched = false;
            for (Unit* player : players)
                if (player->IsAlive() && orb->GetExactDist2d(player) <= OrbTouch)
                    touched = true;
            if (touched)
            {
                orb->CastCustomSpell(ByDifficulty(me, SPELL_NECROTIC_EXPLOSION, SPELL_NECROTIC_EXPLOSION_HC, SPELL_NECROTIC_EXPLOSION_MYTHIC),
                    SPELLVALUE_RADIUS_MOD, OrbExplosionRadiusMod, nullptr, TRIGGERED_FULL_MASK);
                orb->DespawnOrUnsummon(300ms);
                itr = _orbs.erase(itr);
                continue;
            }
            ++itr;
        }
    }

    void Sink()
    {
        if (me->HasUnitState(UNIT_STATE_CASTING))
        {
            _events.ScheduleEvent(EVENT_SINK, 500ms);
            return;
        }
        _phase = Phase::Sunk;
        if (!_pillarsSaid)
        {
            _pillarsSaid = true;
            Talk(SAY_PILLARS);
        }
        me->SetCombatMovement(false);
        me->SetTarget();
        me->GetMotionMaster()->Clear();
        me->StopMoving();
        me->SetControlled(true, UNIT_STATE_ROOT);
        DoCastSelf(SPELL_SUBMERGED, true);
        me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
        me->AttackStop();
        _events.ScheduleEvent(EVENT_SUBMERGED, 600ms);
    }

    void Rise()
    {
        if (Creature* pillar = ObjectAccessor::GetCreature(*me, _middlePillar))
            BurstPillar(pillar);
        me->RestoreDisplayId();
        me->RemoveAurasDueToSpell(SPELL_SUBMERGED);
        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
        me->SetFloatValue(UNIT_FIELD_HOVERHEIGHT, LevitateHeight);
        me->SetDisableGravity(true);
        me->SetHover(true);
        _phase = Phase::Beam;
        Talk(SAY_RISE);
        _events.ScheduleEvent(EVENT_BEAM, 1s);
    }

    void UpdateBeam(uint32 diff)
    {
        _beamLeft = _beamLeft > diff ? _beamLeft - diff : 0;
        Creature* walker = ObjectAccessor::GetCreature(*me, _beamWalker);
        if (!walker)
            return;
        float const beamAngle = me->GetAngle(walker);
        me->SetOrientation(beamAngle);
    }

    void MarkDeathMissile()
    {
        Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 200.0f, true);
        if (!target)
            return;
        float const angle = frand(0.0f, 2.0f * float(M_PI));
        float const dist = frand(0.0f, 3.0f);
        Position const pos = GroundAt(target->GetPositionX() + dist * std::cos(angle), target->GetPositionY() + dist * std::sin(angle));
        Creature* mark = me->SummonCreature(NPC_PILLAR, pos, TEMPSUMMON_TIMED_DESPAWN, MissileMarkMs + 1500);
        if (!mark)
            return;
        mark->SetReactState(REACT_PASSIVE);
        mark->RemoveUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
        mark->CastSpell(mark, SPELL_IMPACT_ZONE, true);
        uint32 const flightMs = uint32(me->GetExactDist(mark) / MissileSpeed * 1000.0f);
        _missiles.push_back({ mark->GetGUID(), MissileMarkMs, flightMs < MissileMarkMs ? MissileMarkMs - flightMs : 0, false });
    }

    void UpdateMissiles(uint32 diff)
    {
        for (auto itr = _missiles.begin(); itr != _missiles.end();)
        {
            Creature* mark = ObjectAccessor::GetCreature(*me, itr->mark);
            if (!mark)
            {
                itr = _missiles.erase(itr);
                continue;
            }
            itr->launchIn = itr->launchIn > diff ? itr->launchIn - diff : 0;
            if (!itr->launched && !itr->launchIn)
            {
                me->CastSpell(mark, SPELL_DEATH_MISSILE, true);
                itr->launched = true;
            }
            if (itr->landIn > diff)
            {
                itr->landIn -= diff;
                ++itr;
                continue;
            }
            mark->CastSpell(mark->GetPositionX(), mark->GetPositionY(), mark->GetPositionZ(),
                ByDifficulty(me, SPELL_DEATH_MISSILE_HIT, SPELL_DEATH_MISSILE_HIT_HC, SPELL_DEATH_MISSILE_HIT_MYTHIC), true, nullptr, nullptr, me->GetGUID());
            mark->RemoveAurasDueToSpell(SPELL_IMPACT_ZONE);
            mark->DespawnOrUnsummon(500ms);
            itr = _missiles.erase(itr);
        }
    }

    void WalkTheCircle(Creature* walker)
    {
        WaypointPath const* path = sWaypointMgr->GetPath(PathBeam);
        if (!path || path->Nodes.size() < 4)
            return;
        std::vector<WaypointNode> const& nodes = path->Nodes;
        size_t lap = nodes.size();
        for (size_t i = 10; i < nodes.size(); ++i)
        {
            float const dx = nodes[i].X - nodes[0].X, dy = nodes[i].Y - nodes[0].Y;
            if (dx * dx + dy * dy < 2.0f * 2.0f)
            {
                lap = i;
                break;
            }
        }
        size_t nearest = 0;
        float best = std::numeric_limits<float>::max();
        for (size_t i = 0; i < lap; ++i)
        {
            float const d = walker->GetExactDist2dSq(nodes[i].X, nodes[i].Y);
            if (d < best)
            {
                best = d;
                nearest = i;
            }
        }
        Movement::PointsArray points;
        points.emplace_back(walker->GetPositionX(), walker->GetPositionY(), walker->GetPositionZ());
        float length = 0.0f;
        for (size_t step = 0; step <= lap; ++step)
        {
            WaypointNode const& node = nodes[(nearest + step) % lap];
            G3D::Vector3 const next(node.X, node.Y, node.Z);
            length += (next - points.back()).length();
            points.push_back(next);
        }
        Movement::MoveSplineInit init(walker);
        init.MovebyPath(points);
        init.SetVelocity(length / (float(BeamChannelMs) / 1000.0f));
        init.Launch();
    }

    void EndBeam()
    {
        _beaming = false;
        _events.CancelEvent(EVENT_BEAM_PILLAR);
        _events.CancelEvent(EVENT_DEATH_MISSILE);
        me->InterruptNonMeleeSpells(false);
        if (Creature* walker = ObjectAccessor::GetCreature(*me, _beamWalker))
            walker->DespawnOrUnsummon();
        _beamWalker.Clear();
        me->SetHover(false);
        me->SetDisableGravity(false);
        me->SetControlled(false, UNIT_STATE_ROOT);
        me->SetCombatMovement(true);
        _phase = Phase::Fight;
        if (Unit* victim = me->GetVictim())
        {
            me->SetTarget(victim->GetGUID());
            me->GetMotionMaster()->MoveChase(victim);
        }
        _events.ScheduleEvent(EVENT_SINK, 25s);
    }

    enum class Phase : uint8
    {
        Fight,
        Walk,
        Sunk,
        Beam,
    };

    bool _pillarsSaid = false;
    EventMap _events;
    SummonList _summons;
    Position _home;
    Position _sinkPos;
    Position _center;
    uint32 _walkTries = 0;
    ObjectGuid _middlePillar;
    ObjectGuid _beamWalker;
    std::vector<ObjectGuid> _sidePillars;
    std::vector<std::pair<ObjectGuid, uint32>> _timedPillars;
    std::vector<ObjectGuid> _orbs;
    struct PendingMissile
    {
        ObjectGuid mark;
        uint32 landIn;
        uint32 launchIn;
        bool launched;
    };
    std::vector<PendingMissile> _missiles;
    Phase _phase = Phase::Fight;
    uint32 _orbCheck = 0;
    uint32 _beamTick = 0;
    uint32 _beamLeft = 0;
    uint32 _beamPillars = 0;
    bool _beaming = false;
};

class spell_coa_drakmath_spiritual_parasitism : public SpellScript
{
    PrepareSpellScript(spell_coa_drakmath_spiritual_parasitism);

    void HandleHit()
    {
        if (!GetHitDamage())
            return;
        SetHitDamage(Rolled(GetCaster(), GetHitUnit(), ParasitismHit));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_drakmath_spiritual_parasitism::HandleHit);
    }
};

class spell_coa_drakmath_spiritual_parasitism_aura : public AuraScript
{
    PrepareAuraScript(spell_coa_drakmath_spiritual_parasitism_aura);

    void CalcTick(AuraEffect const* , int32& amount, bool& )
    {
        if (Unit* caster = GetCaster())
            amount = Rolled(caster, GetUnitOwner(), ParasitismTick);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_coa_drakmath_spiritual_parasitism_aura::CalcTick, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class spell_coa_drakmath_necrotic_emerge : public SpellScript
{
    PrepareSpellScript(spell_coa_drakmath_necrotic_emerge);

    void HandleHit()
    {
        SetHitDamage(Rolled(GetCaster(), GetHitUnit(), NecroticEmerge));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_drakmath_necrotic_emerge::HandleHit);
    }
};

class spell_coa_drakmath_death_missile : public SpellScript
{
    PrepareSpellScript(spell_coa_drakmath_death_missile);

    void HandleHit()
    {
        Unit* source = GetOriginalCaster() ? GetOriginalCaster() : GetCaster();
        SetHitDamage(Rolled(source, GetHitUnit(), DeathMissile));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_drakmath_death_missile::HandleHit);
    }
};

class spell_coa_drakmath_necrotic_explosion : public SpellScript
{
    PrepareSpellScript(spell_coa_drakmath_necrotic_explosion);

    void HandleHit()
    {
        SetHitDamage(Rolled(GetCaster(), GetHitUnit(), NecroticExplosion));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_drakmath_necrotic_explosion::HandleHit);
    }
};

class spell_coa_volzeen_colossal_smash : public SpellScript
{
    PrepareSpellScript(spell_coa_volzeen_colossal_smash);

    void HandleHit()
    {
        Unit* target = GetHitUnit();
        Unit* caster = GetCaster();
        if (target && caster && caster->GetEntry() == NPC_VOLZEEN)
            SetHitDamage(int32(Unscaled(caster, target, float(target->CountPctFromMaxHealth(12.0f)))));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_volzeen_colossal_smash::HandleHit);
    }
};

class spell_coa_drakmath_death_beam : public SpellScript
{
    PrepareSpellScript(spell_coa_drakmath_death_beam);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        Unit* walker = caster ? ObjectAccessor::GetUnit(*caster, caster->GetTarget()) : nullptr;
        if (!walker || walker == caster)
        {
            targets.clear();
            return;
        }
        targets.remove_if([caster, walker](WorldObject* target)
        {
            Unit* unit = target->ToUnit();
            return !unit || unit == walker || !InBeamCone(caster, walker, unit);
        });
    }

    void HandleHit()
    {
        if (Unit* target = GetHitUnit())
            SetHitDamage(int32(Unscaled(GetCaster(), target, float(target->CountPctFromMaxHealth(float(GetSpellInfo()->Effects[EFFECT_0].CalcValue()))))));
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_drakmath_death_beam::FilterTargets, EFFECT_0, TARGET_UNIT_SRC_AREA_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_drakmath_death_beam::FilterTargets, EFFECT_1, TARGET_UNIT_SRC_AREA_ENEMY);
        OnHit += SpellHitFn(spell_coa_drakmath_death_beam::HandleHit);
    }
};
}

void AddSC_CoAOtherSideDrakmath()
{
    RegisterCreatureAI(boss_coa_drakmath);
    RegisterSpellAndAuraScriptPair(spell_coa_drakmath_spiritual_parasitism, spell_coa_drakmath_spiritual_parasitism_aura);
    RegisterSpellScript(spell_coa_drakmath_necrotic_emerge);
    RegisterSpellScript(spell_coa_drakmath_necrotic_explosion);
    RegisterSpellScript(spell_coa_drakmath_death_missile);
    RegisterSpellScript(spell_coa_volzeen_colossal_smash);
    RegisterSpellScript(spell_coa_drakmath_death_beam);
}
