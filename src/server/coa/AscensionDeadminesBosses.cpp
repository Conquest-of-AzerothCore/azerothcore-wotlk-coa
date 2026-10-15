/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "MotionMaster.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <list>
#include <numbers>

namespace
{
enum DeadminesSawBladeData : uint32
{
    NPC_SNEEDS_SHREDDER = 642,
    NPC_SNEED = 643,
    NPC_CAPTAIN_GREENSKIN = 647,
    SPELL_BUSTER_CALL_CIRCLE = 2102591,
    SPELL_BUSTER_CALL_CANNONBALL = 2102592,
    BUSTER_CALL_START_DELAY_MAX_MS = 1500,
    BUSTER_CALL_FIRE_DELAY_MS = 4400,
    SPELL_ASCENSION_POISONED_HARPOON = 2102585,
    SPELL_BUZZING_SAW_BLADE = 2102564,
    POINT_SAW_ORBIT = 1,
    SAW_MOVE_INTERVAL_MS = 250,
    SAW_BOSS_LOST_MS = 3000,
    SAW_DIP_DELAY_MIN_MS = 6000,
    SAW_DIP_DELAY_MAX_MS = 10000,
    SAW_DIP_DURATION_MS = 4000
};

constexpr std::array<uint32, 2> SawBosses = { NPC_SNEEDS_SHREDDER, NPC_SNEED };
constexpr float SawBossRange = 80.0f;
constexpr float SawOrbitRadius = 5.0f;
constexpr float SawDipRadius = 2.0f;
constexpr float SawSpeed = 2.2f;
constexpr float SawLaneRadiusStep = 1.2f;
constexpr float SawLaneDipStep = 0.7f;
constexpr uint32 SawLaneCount = 3;
constexpr float SawGoldenAngle = 2.39996f;
constexpr float SawMinSeparation = 2.5f;
constexpr float SawLookaheadSeconds = 0.6f;
constexpr float SawMinStepRadius = 2.0f;
constexpr float BusterCallMinRadius = 3.0f;
constexpr float BusterCallMaxRadius = 16.0f;
constexpr float BusterCallHeight = 25.0f;

struct npc_ascension_buzzing_saw_blade : ScriptedAI
{
    explicit npc_ascension_buzzing_saw_blade(Creature* creature) : ScriptedAI(creature),
        _clockwise(true), _lane(0), _angle(0.0f), _moveTimer(0), _lostTimer(0),
        _dipDelay(urand(SAW_DIP_DELAY_MIN_MS, SAW_DIP_DELAY_MAX_MS)), _dipElapsed(0), _started(false) { }

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject*) override
    {
        Start();
    }

    void UpdateAI(uint32 diff) override
    {
        Start();

        Creature* boss = FindBoss();
        if (!boss)
        {
            _lostTimer += diff;
            if (_lostTimer >= SAW_BOSS_LOST_MS)
                me->DespawnOrUnsummon();
            return;
        }
        _lostTimer = 0;

        AdvanceDip(diff);

        _moveTimer = _moveTimer > diff ? _moveTimer - diff : 0;
        if (_moveTimer)
            return;
        _moveTimer = SAW_MOVE_INTERVAL_MS;
        Orbit(boss);
    }

private:
    void Start()
    {
        if (_started)
            return;
        _started = true;
        std::list<Creature*> saws;
        me->GetCreatureListWithEntryInGrid(saws, me->GetEntry(), SawBossRange);
        _lane = saws.empty() ? 0 : uint32(saws.size() - 1);
        _clockwise = _lane % 2 == 0;
        _angle = SawGoldenAngle * float(_lane);
        me->SetReactState(REACT_PASSIVE);
        me->CastSpell(me, SPELL_BUZZING_SAW_BLADE, true);
    }

    Creature* FindBoss() const
    {
        for (uint32 entry : SawBosses)
            if (Creature* boss = me->FindNearestCreature(entry, SawBossRange, true))
                if (boss->IsInCombat())
                    return boss;
        return nullptr;
    }

    void AdvanceDip(uint32 diff)
    {
        if (_dipElapsed)
        {
            _dipElapsed += diff;
            if (_dipElapsed >= SAW_DIP_DURATION_MS)
            {
                _dipElapsed = 0;
                _dipDelay = urand(SAW_DIP_DELAY_MIN_MS, SAW_DIP_DELAY_MAX_MS);
            }
            return;
        }
        _dipDelay = _dipDelay > diff ? _dipDelay - diff : 0;
        if (!_dipDelay)
            _dipElapsed = 1;
    }

    float CurrentRadius() const
    {
        float const dip = _dipElapsed ? std::sin(std::numbers::pi_v<float> * float(_dipElapsed) / float(SAW_DIP_DURATION_MS)) : 0.0f;
        float const lane = float(_lane % SawLaneCount);
        float const orbit = SawOrbitRadius + SawLaneRadiusStep * lane;
        float const dipRadius = SawDipRadius + SawLaneDipStep * lane;
        return orbit - (orbit - dipRadius) * dip;
    }

    bool TooCloseToOtherSaw(Creature* boss, float angle, float radius) const
    {
        float const x = boss->GetPositionX() + radius * std::cos(angle);
        float const y = boss->GetPositionY() + radius * std::sin(angle);
        std::list<Creature*> saws;
        me->GetCreatureListWithEntryInGrid(saws, me->GetEntry(), SawBossRange);
        for (Creature* saw : saws)
            if (saw != me && saw->IsAlive() && me->GetGUID().GetCounter() > saw->GetGUID().GetCounter() &&
                saw->GetExactDist2d(x, y) < SawMinSeparation)
                return true;
        return false;
    }

    void Orbit(Creature* boss)
    {
        float const radius = std::max(CurrentRadius(), SawMinStepRadius);
        float const direction = _clockwise ? -1.0f : 1.0f;
        float const advance = direction * SawSpeed * float(SAW_MOVE_INTERVAL_MS) / 1000.0f / radius;
        if (!TooCloseToOtherSaw(boss, _angle + advance, radius))
            _angle += advance;
        float const angle = _angle + direction * SawSpeed * SawLookaheadSeconds / radius;
        float const x = boss->GetPositionX() + radius * std::cos(angle);
        float const y = boss->GetPositionY() + radius * std::sin(angle);
        float z = boss->GetPositionZ();
        me->UpdateAllowedPositionZ(x, y, z);
        me->GetMotionMaster()->MovePoint(POINT_SAW_ORBIT, x, y, z, FORCED_MOVEMENT_NONE, SawSpeed, 0.0f, false);
    }

    bool _clockwise;
    uint32 _lane;
    float _angle;
    uint32 _moveTimer;
    uint32 _lostTimer;
    uint32 _dipDelay;
    uint32 _dipElapsed;
    bool _started;
};

struct npc_ascension_buster_call_marker : ScriptedAI
{
    explicit npc_ascension_buster_call_marker(Creature* creature) : ScriptedAI(creature),
        _delay(urand(0, BUSTER_CALL_START_DELAY_MAX_MS)), _elapsed(0), _stage(0), _x(0.0f), _y(0.0f), _z(0.0f) { }

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        float const angle = frand(0.0f, 2.0f * std::numbers::pi_v<float>);
        float const radius = frand(BusterCallMinRadius, BusterCallMaxRadius);
        _x = summoner->GetPositionX() + radius * std::cos(angle);
        _y = summoner->GetPositionY() + radius * std::sin(angle);
        _z = summoner->GetPositionZ();
        me->UpdateGroundPositionZ(_x, _y, _z);
        me->SetDisableGravity(true);
        me->NearTeleportTo(_x, _y, _z + BusterCallHeight, me->GetOrientation());
        _stage = 1;
    }

    void UpdateAI(uint32 diff) override
    {
        if (_stage == 0 || _stage == 3)
            return;

        _elapsed += diff;
        if (_stage == 1 && _elapsed >= _delay)
        {
            me->CastSpell(_x, _y, _z, SPELL_BUSTER_CALL_CIRCLE, true);
            _elapsed = 0;
            _stage = 2;
        }
        else if (_stage == 2 && _elapsed >= BUSTER_CALL_FIRE_DELAY_MS)
        {
            me->CastSpell(_x, _y, _z, SPELL_BUSTER_CALL_CANNONBALL, true);
            _stage = 3;
        }
    }

    uint32 _delay;
    uint32 _elapsed;
    uint8 _stage;
    float _x;
    float _y;
    float _z;
};

class spell_ascension_greenskin_poisoned_harpoon : public SpellScript
{
    PrepareSpellScript(spell_ascension_greenskin_poisoned_harpoon);

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->GetEntry() == NPC_CAPTAIN_GREENSKIN;
    }

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ SPELL_ASCENSION_POISONED_HARPOON });
    }

    void ThrowHarpoon()
    {
        PreventHitAura();
        PreventHitDamage();
        if (Unit* target = GetHitUnit())
            GetCaster()->CastSpell(target, SPELL_ASCENSION_POISONED_HARPOON, true);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_ascension_greenskin_poisoned_harpoon::ThrowHarpoon);
    }
};
}

void AddSC_AscensionDeadminesBosses()
{
    RegisterCreatureAI(npc_ascension_buzzing_saw_blade);
    RegisterSpellScript(spell_ascension_greenskin_poisoned_harpoon);
    RegisterCreatureAI(npc_ascension_buster_call_marker);
}
