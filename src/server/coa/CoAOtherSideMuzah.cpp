/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "Creature.h"
#include "CoAOtherSideDamage.h"
#include "GameObject.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
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
#include <algorithm>
#include <cmath>
#include <list>
#include <vector>

namespace
{
enum MuzahTexts : uint8
{
    SAY_AGGRO = 0,
    SAY_90 = 1,
    SAY_40 = 2,
    SAY_10 = 3,
    SAY_DEATH = 4,
};

enum MuzahData : uint32
{
    NPC_MUZAH = 162711,
    NPC_GLAIVE = 162744,
    NPC_SWIRL = 162779,
    NPC_BAT_A = 162777,
    NPC_BAT_B = 162778,
    GO_GATE_ENTRANCE = 2300587,
    GO_GATE_EXIT = 2300588,

    SPELL_WHIRLING_GLAIVES = 256887,
    SPELL_GLAIVE_VISUAL = 256886,
    SPELL_RIPPED_BY_THE_GLAIVES = 256888,
    SPELL_RIPPED_BY_THE_GLAIVES_HC = 257036,
    SPELL_RIPPED_BY_THE_GLAIVES_MYTHIC = 257037,
    SPELL_COBRA_SHOT = 256929,
    SPELL_COBRA_SHOT_HC = 257030,
    SPELL_COBRA_SHOT_MYTHIC = 257031,
    SPELL_ENTANGLING_WEB_HC = 257039,
    SPELL_ENTANGLING_WEB_MYTHIC = 257040,
    SPELL_BLOOD_EXPLOSION_HC = 257042,
    SPELL_BLOOD_EXPLOSION_MYTHIC = 257043,
    SPELL_MUZAHS_TARGET = 256964,
    SPELL_ENTANGLING_WEB = 256834,
    SPELL_GROUND_SWIRL = 256852,
    SPELL_BAT_FLY_DOWN = 256896,
    SPELL_BLOOD_EXPLOSION = 256903,
    SPELL_SUMMON_BATS = 256904,
    SPELL_FIERCE_BLOW = 975011,
    SPELL_GLAIVE_STRIKE = 257029,

    DATA_BATS = 1,

    POINT_JUMP = 1,
    POINT_GLAIVE_LAND = 1,
    POINT_GLAIVE_ROAM = 2,
    DATA_GLAIVE_ROAMS = 1,

    EVENT_GLAIVES_LAND = 1,
    EVENT_LEAP,
    EVENT_COBRA_TANK_1,
    EVENT_COBRA_TANK_2,
    EVENT_COBRA_RANDOM,
    EVENT_COBRA_RANDOM_EXTRA,
    EVENT_SERIES_END,
    EVENT_SWIRLS,
    EVENT_BATS_RETURN,
    EVENT_WEB,
    EVENT_WEB_TICK,
    EVENT_FIERCE_BLOW,
    EVENT_LANDED,
    EVENT_GLAIVE_STRIKE,
    EVENT_GLAIVE_STRIKE_SECOND,
};

Position const ArenaCenter = { 100.9f, -123.9f, 224.976f, 0.0f };
constexpr float ArenaRadius = 17.0f;
constexpr float ArenaSearch = 120.0f;
constexpr float WallGap = 3.0f;
constexpr uint32 GlaiveCastMs = 2000;
constexpr uint32 CobraCastMs = 2000;
constexpr uint32 CobraGapMs = 2500;
constexpr uint32 SwirlLifeMs = 2500;
constexpr uint32 BatFallMs = 1800;
constexpr uint32 WebCocoonMs = 4000;

constexpr float JumpSpeed = 30.0f;
constexpr uint32 StrikerLifeMs = 4000;
constexpr float StrikeWidth = 3.0f;

constexpr float BatCrashRadius = 3.0f;

using CoAOtherSide::Damage3;
using CoAOtherSide::Logged;
using CoAOtherSide::Rolled;
using CoAOtherSide::Unscaled;
constexpr Damage3 GlaiveHit = { 151, 394 };
constexpr Damage3 GlaiveBleedPerStack = { 40, 110 };
constexpr Damage3 CobraPrimary = { 200, 850 };
constexpr Damage3 CobraSplash = { 137, 330 };
constexpr Damage3 BatCrash = { 380, 950 };
constexpr Damage3 GlaiveStrike = { 100, 250 };
constexpr float PctWebHitNormal = 20.0f;
constexpr float PctWebHitHeroic = 30.0f;
constexpr float PctWebHitMythic = 45.0f;
constexpr float WebTickShare = 0.1f;

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

float WebHitPct(WorldObject const* source)
{
    return float(ByDifficulty(source, uint32(PctWebHitNormal), uint32(PctWebHitHeroic), uint32(PctWebHitMythic)));
}

uint32 WebSpell(WorldObject const* source)
{
    return ByDifficulty(source, SPELL_ENTANGLING_WEB, SPELL_ENTANGLING_WEB_HC, SPELL_ENTANGLING_WEB_MYTHIC);
}

void DealSpellValue(Unit* attacker, Unit* target, uint32 spellId, int32 value)
{
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
    if (!spellInfo || !target->IsAlive() || value <= 0 || target->IsImmunedToDamage(attacker, spellInfo))
        return;
    uint32 amount = attacker->SpellDamageBonusDone(target, spellInfo, uint32(value), SPELL_DIRECT_DAMAGE, EFFECT_0);
    amount = target->SpellDamageBonusTaken(attacker, spellInfo, amount, SPELL_DIRECT_DAMAGE);
    SpellNonMeleeDamage damage(attacker, target, spellInfo, spellInfo->GetSchoolMask());
    attacker->CalculateSpellDamageTaken(&damage, int32(amount), spellInfo);
    Unit::DealDamageMods(target, damage.damage, &damage.absorb);
    attacker->SendSpellNonMeleeDamageLog(&damage);
    attacker->DealSpellDamage(&damage, false);
}

Position GroundAt(WorldObject const* source, float x, float y)
{
    float const z = source->GetMap()->GetHeight(source->GetPhaseMask(), x, y, ArenaCenter.GetPositionZ() + 5.0f);
    return { x, y, z > INVALID_HEIGHT ? z : ArenaCenter.GetPositionZ(), 0.0f };
}

Position RandomArenaPoint(WorldObject const* source, float maxRadius = ArenaRadius)
{
    float const angle = frand(0.0f, 2.0f * float(M_PI));
    float const dist = maxRadius * std::sqrt(frand(0.05f, 1.0f));
    return GroundAt(source, ArenaCenter.GetPositionX() + dist * std::cos(angle), ArenaCenter.GetPositionY() + dist * std::sin(angle));
}

struct boss_coa_muzah : public ScriptedAI
{
    explicit boss_coa_muzah(Creature* creature) : ScriptedAI(creature), _summons(creature) { }

    void Reset() override
    {
        _events.Reset();
        _summons.DespawnAll();
        _falling.clear();
        _cobraTargets.clear();
        _swirlsStarted = false;
        _callingBats = false;
        _inSeries = false;
        me->SetCombatMovement(true);
        me->SetControlled(false, UNIT_STATE_ROOT);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_INTERRUPT, true);
        me->ApplySpellImmune(0, IMMUNITY_EFFECT, SPELL_EFFECT_INTERRUPT_CAST, true);
        SetGates(GO_STATE_ACTIVE);
        RespawnBats(0);
    }

    void JustEngagedWith(Unit* ) override
    {
        SetGates(GO_STATE_READY);
        RespawnBats(1);
        _nextSay = SAY_90;
        Talk(SAY_AGGRO);
        DoCastSelf(SPELL_WHIRLING_GLAIVES);
        _events.ScheduleEvent(EVENT_GLAIVES_LAND, Milliseconds(GlaiveCastMs + 100));
        _events.ScheduleEvent(EVENT_LEAP, Milliseconds(GlaiveCastMs + 5000));
        _events.ScheduleEvent(EVENT_WEB, 20s);
        _events.ScheduleEvent(EVENT_WEB_TICK, 1s);
        _events.ScheduleEvent(EVENT_FIERCE_BLOW, 10s, 15s);
        _events.ScheduleEvent(EVENT_GLAIVE_STRIKE, 15s);
    }

    void DamageTaken(Unit* , uint32& damage, DamageEffectType , SpellSchoolMask ) override
    {
        static uint32 const thresholds[] = { 90, 40, 10 };
        if (_nextSay >= SAY_90 && _nextSay <= SAY_10 && me->HealthBelowPctDamaged(thresholds[_nextSay - SAY_90], damage))
            Talk(_nextSay++);
    }

    void JustDied(Unit* ) override
    {
        Talk(SAY_DEATH);
        _summons.DespawnAll();
        SetGates(GO_STATE_ACTIVE);
        for (bool visible : { true, false })
            for (Creature* bat : CirclingBats(visible))
                bat->DespawnOrUnsummon(0ms, Seconds(WEEK));
    }

    void JustSummoned(Creature* summon) override
    {
        _summons.Summon(summon);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        UpdateFallingBats(diff);
        _events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_GLAIVES_LAND:
                    ThrowGlaives();
                    break;
                case EVENT_LEAP:
                    if (_inSeries)
                    {
                        _events.Repeat(1s);
                        break;
                    }
                    Leap();
                    _events.Repeat(25s);
                    break;
                case EVENT_LANDED:
                    me->SetControlled(true, UNIT_STATE_ROOT);
                    _events.ScheduleEvent(EVENT_COBRA_TANK_1, 200ms);
                    if (!_swirlsStarted)
                    {
                        _swirlsStarted = true;
                        CrashBats(urand(4, 6));
                        _events.ScheduleEvent(EVENT_SWIRLS, 10s);
                    }
                    break;
                case EVENT_GLAIVE_STRIKE:
                    if (me->GetMap()->GetDifficulty() != DUNGEON_DIFFICULTY_EPIC)
                        break;
                    SendStrikers();
                    _events.ScheduleEvent(EVENT_GLAIVE_STRIKE_SECOND, 3s);
                    _events.Repeat(20s);
                    break;
                case EVENT_GLAIVE_STRIKE_SECOND:
                    SendStrikers();
                    break;
                case EVENT_COBRA_TANK_1:
                case EVENT_COBRA_TANK_2:
                    if (Unit* tank = me->GetVictim())
                        Shoot(tank, false);
                    _events.ScheduleEvent(eventId == EVENT_COBRA_TANK_1 ? EVENT_COBRA_TANK_2 : EVENT_COBRA_RANDOM, Milliseconds(CobraGapMs));
                    break;
                case EVENT_COBRA_RANDOM:
                {
                    std::list<Unit*> targets;
                    SelectTargetList(targets, 3, SelectTargetMethod::Random, 0, 100.0f, true);
                    _cobraTargets.clear();
                    for (Unit* target : targets)
                        _cobraTargets.push_back(target->GetGUID());
                    if (!targets.empty())
                        Shoot(targets.front(), false);
                    for (Unit* target : targets)
                        target->CastSpell(target, SPELL_MUZAHS_TARGET, true);
                    _events.ScheduleEvent(EVENT_COBRA_RANDOM_EXTRA, Milliseconds(CobraCastMs));
                    _events.ScheduleEvent(EVENT_SERIES_END, Milliseconds(CobraCastMs + 600));
                    break;
                }
                case EVENT_COBRA_RANDOM_EXTRA:
                    for (size_t i = 1; i < _cobraTargets.size(); ++i)
                        if (Unit* target = ObjectAccessor::GetUnit(*me, _cobraTargets[i]))
                            me->CastSpell(target, ByDifficulty(me, SPELL_COBRA_SHOT, SPELL_COBRA_SHOT_HC, SPELL_COBRA_SHOT_MYTHIC), true);
                    break;
                case EVENT_SERIES_END:
                    EndSeries();
                    break;
                case EVENT_SWIRLS:
                    if (CountLivingBats() == 0)
                    {
                        if (!_callingBats)
                        {
                            _callingBats = true;
                            me->StopMoving();
                            me->SetControlled(true, UNIT_STATE_ROOT);
                            DoCastSelf(SPELL_SUMMON_BATS);
                            LOG_DEBUG("module", "Muzah: all bats down, calling new ones");
                            _events.ScheduleEvent(EVENT_BATS_RETURN, 5100ms);
                        }
                    }
                    else
                        CrashBats(urand(4, 5));
                    _events.Repeat(10s);
                    break;
                case EVENT_BATS_RETURN:
                    _callingBats = false;
                    if (!_inSeries)
                        me->SetControlled(false, UNIT_STATE_ROOT);
                    RespawnBats(1);
                    break;
                case EVENT_WEB:
                    if (_inSeries)
                    {
                        _events.Repeat(1s);
                        break;
                    }
                    DoCastSelf(WebSpell(me));
                    _events.Repeat(20s);
                    break;
                case EVENT_WEB_TICK:
                    TickWebs();
                    _events.Repeat(1s);
                    break;
                case EVENT_FIERCE_BLOW:
                    if (!_inSeries)
                        DoCastVictim(SPELL_FIERCE_BLOW);
                    _events.Repeat(20s, 30s);
                    break;
                default:
                    break;
            }
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
        }

        if (!_inSeries)
            DoMeleeAttackIfReady();
    }

    void SpellHitTarget(Unit* target, SpellInfo const* spellInfo) override
    {
        if (spellInfo->Id != WebSpell(me) || !target->IsPlayer())
            return;
        if (Aura* web = target->GetAura(spellInfo->Id, me->GetGUID()))
        {
            web->SetMaxDuration(WebCocoonMs);
            web->SetDuration(WebCocoonMs);
        }
    }

private:
    void SetGates(GOState state)
    {
        for (uint32 entry : { GO_GATE_ENTRANCE, GO_GATE_EXIT })
            if (GameObject* gate = me->FindNearestGameObject(entry, ArenaSearch))
                gate->SetGoState(state);
    }

    std::vector<Creature*> CirclingBats(bool visible) const
    {
        std::list<Creature*> bats;
        me->GetCreatureListWithEntryInGrid(bats, std::vector<uint32>{ NPC_BAT_A, NPC_BAT_B }, ArenaSearch);
        std::vector<Creature*> result;
        for (Creature* bat : bats)
            if (!bat->IsSummon() && bat->IsAlive() && bat->IsVisible() == visible)
                result.push_back(bat);
        return result;
    }

    void RespawnBats(uint32 data)
    {
        for (Creature* bat : CirclingBats(false))
            bat->SetVisible(true);
        for (Creature* bat : CirclingBats(true))
            if (bat->IsAIEnabled)
                bat->AI()->SetData(DATA_BATS, data);
    }

    uint32 CountLivingBats() const
    {
        return uint32(CirclingBats(true).size());
    }

    void ThrowGlaives()
    {
        std::vector<Position> landings;
        for (uint32 entry : { GO_GATE_ENTRANCE, GO_GATE_EXIT })
        {
            GameObject* gate = me->FindNearestGameObject(entry, ArenaSearch);
            for (float side : { -2.0f, 2.0f })
            {
                if (!gate)
                {
                    landings.push_back(RandomArenaPoint(me));
                    continue;
                }
                float const inward = gate->GetAngle(&ArenaCenter);
                float const x = gate->GetPositionX() + 2.5f * std::cos(inward) + side * std::cos(inward + float(M_PI) / 2.0f);
                float const y = gate->GetPositionY() + 2.5f * std::sin(inward) + side * std::sin(inward + float(M_PI) / 2.0f);
                landings.push_back(GroundAt(me, x, y));
            }
        }
        std::list<Unit*> players;
        SelectTargetList(players, 2, SelectTargetMethod::Random, 0, 100.0f, true);
        auto player = players.begin();
        for (uint32 i = 0; i < 2; ++i)
            landings.push_back(player != players.end() ? (*player++)->GetPosition() : RandomArenaPoint(me));

        for (size_t i = 0; i < landings.size(); ++i)
        {
            Creature* glaive = me->SummonCreature(NPC_GLAIVE, me->GetPosition(), TEMPSUMMON_MANUAL_DESPAWN);
            if (!glaive)
                continue;
            glaive->AI()->SetData(DATA_GLAIVE_ROAMS, i >= 4 ? 1 : 0);
            glaive->GetMotionMaster()->MovePoint(POINT_GLAIVE_LAND, landings[i], FORCED_MOVEMENT_NONE, 18.0f, false);
        }
    }

    void Leap()
    {
        float const angle = frand(0.0f, 2.0f * float(M_PI));
        float const reachOut = 80.0f;
        Position wall = me->GetFirstCollisionPosition(ArenaCenter.GetPositionX(), ArenaCenter.GetPositionY(), ArenaCenter.GetPositionZ() + 2.0f,
            ArenaCenter.GetPositionX() + reachOut * std::cos(angle), ArenaCenter.GetPositionY() + reachOut * std::sin(angle));
        float const reach = std::max(0.0f, ArenaCenter.GetExactDist2d(&wall) - WallGap);
        Position const spot = GroundAt(me, ArenaCenter.GetPositionX() + reach * std::cos(angle), ArenaCenter.GetPositionY() + reach * std::sin(angle));
        _inSeries = true;
        me->SetCombatMovement(false);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveJump(spot.GetPositionX(), spot.GetPositionY(), spot.GetPositionZ(), JumpSpeed, 12.0f, POINT_JUMP);
        _events.ScheduleEvent(EVENT_LANDED, Milliseconds(uint32(me->GetExactDist2d(&spot) / JumpSpeed * 1000.0f) + 400));
    }

    void SendStrikers()
    {
        std::list<Unit*> players;
        SelectTargetList(players, 2, SelectTargetMethod::Random, 0, 100.0f, true);
        for (Unit* player : players)
        {
            float const angle = frand(0.0f, 2.0f * float(M_PI));
            Position wall = me->GetFirstCollisionPosition(ArenaCenter.GetPositionX(), ArenaCenter.GetPositionY(), ArenaCenter.GetPositionZ() + 2.0f,
                ArenaCenter.GetPositionX() + 80.0f * std::cos(angle), ArenaCenter.GetPositionY() + 80.0f * std::sin(angle));
            float const reach = std::max(0.0f, ArenaCenter.GetExactDist2d(&wall) - WallGap);
            Position spot = GroundAt(me, ArenaCenter.GetPositionX() + reach * std::cos(angle), ArenaCenter.GetPositionY() + reach * std::sin(angle));
            spot.SetOrientation(spot.GetAngle(player));
            if (Creature* striker = me->SummonCreature(NPC_SWIRL, spot, TEMPSUMMON_TIMED_DESPAWN, StrikerLifeMs))
            {
                striker->SetReactState(REACT_PASSIVE);
                striker->SetFacingTo(spot.GetOrientation());
                striker->CastSpell(static_cast<Unit*>(nullptr), SPELL_GLAIVE_STRIKE, false);
            }
        }
    }

    void Shoot(Unit* target, bool triggered)
    {
        me->SetFacingToObject(target);
        target->CastSpell(target, SPELL_MUZAHS_TARGET, true);
        me->CastSpell(target, ByDifficulty(me, SPELL_COBRA_SHOT, SPELL_COBRA_SHOT_HC, SPELL_COBRA_SHOT_MYTHIC), triggered);
    }

    void EndSeries()
    {
        _inSeries = false;
        me->SetControlled(false, UNIT_STATE_ROOT);
        std::list<Unit*> marked;
        SelectTargetList(marked, 40, SelectTargetMethod::Random, 0, 150.0f, true);
        for (Unit* target : marked)
            target->RemoveAurasDueToSpell(SPELL_MUZAHS_TARGET);
        me->SetCombatMovement(true);
        if (Unit* victim = me->GetVictim())
            me->GetMotionMaster()->MoveChase(victim);
    }

    void CrashBats(uint32 count)
    {
        std::vector<Creature*> living = CirclingBats(true);
        Acore::Containers::RandomShuffle(living);
        LOG_DEBUG("module", "Muzah: {} bats circling, crashing {}", living.size(), std::min<size_t>(count, living.size()));
        if (living.size() > count)
            living.resize(count);

        std::list<Unit*> players;
        SelectTargetList(players, 40, SelectTargetMethod::Random, 0, 100.0f, true);
        std::vector<Position> spots;
        for (Unit* player : players)
            spots.push_back(player->GetPosition());
        size_t next = 0;

        for (Creature* bat : living)
        {
            Position swirl = RandomArenaPoint(me);
            if (!spots.empty())
            {
                Position const& around = spots[next++ % spots.size()];
                float const angle = frand(0.0f, 2.0f * float(M_PI));
                float const dist = next <= spots.size() ? frand(0.0f, 1.5f) : frand(2.0f, 5.0f);
                swirl = GroundAt(me, around.GetPositionX() + dist * std::cos(angle), around.GetPositionY() + dist * std::sin(angle));
            }
            if (Creature* marker = me->SummonCreature(NPC_SWIRL, swirl, TEMPSUMMON_TIMED_DESPAWN, SwirlLifeMs))
            {
                marker->SetReactState(REACT_PASSIVE);
                marker->CastSpell(marker, SPELL_GROUND_SWIRL, true);
            }
            Creature* faller = me->SummonCreature(bat->GetEntry(), bat->GetPosition(), TEMPSUMMON_MANUAL_DESPAWN);
            LOG_DEBUG("module", "Muzah: bat {} falls into a swirl at ({:.1f}, {:.1f}), stand-in {}", bat->GetSpawnId(),
                swirl.GetPositionX(), swirl.GetPositionY(), faller ? "summoned" : "missing");
            bat->SetVisible(false);
            if (!faller)
                continue;
            faller->SetReactState(REACT_PASSIVE);
            faller->SetCanFly(true);
            faller->SetDisableGravity(true);
            faller->CastSpell(faller, SPELL_BAT_FLY_DOWN, true);
            float const speed = std::max(8.0f, faller->GetExactDist(&swirl) / (BatFallMs / 1000.0f));
            faller->GetMotionMaster()->MovePoint(1, swirl, FORCED_MOVEMENT_NONE, speed, false);
            _falling.push_back({ faller->GetGUID(), BatFallMs, swirl });
        }
    }

    void UpdateFallingBats(uint32 diff)
    {
        for (auto itr = _falling.begin(); itr != _falling.end();)
        {
            if (itr->timer > diff)
            {
                itr->timer -= diff;
                ++itr;
                continue;
            }
            CrashDamage(itr->swirl);
            if (Creature* bat = ObjectAccessor::GetCreature(*me, itr->bat))
            {
                bat->RemoveAurasDueToSpell(SPELL_BAT_FLY_DOWN);
                bat->CastSpell(bat, SPELL_BLOOD_EXPLOSION, true);
                bat->SetDisableGravity(false);
                bat->SetCanFly(false);
                bat->SetCorpseDelay(3600);
                bat->KillSelf();
            }
            itr = _falling.erase(itr);
        }
    }

    void CrashDamage(Position const& swirl)
    {
        uint32 const spellId = ByDifficulty(me, SPELL_BLOOD_EXPLOSION, SPELL_BLOOD_EXPLOSION_HC, SPELL_BLOOD_EXPLOSION_MYTHIC);
        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
        if (!spellInfo)
            return;
        std::list<Unit*> players;
        SelectTargetList(players, 40, SelectTargetMethod::Random, 0, 150.0f, true);
        for (Unit* player : players)
            if (player->GetExactDist2d(&swirl) <= BatCrashRadius)
                DealSpellValue(me, player, spellId, Rolled(me, player, BatCrash));
    }

    void TickWebs()
    {
        uint32 const spellId = WebSpell(me);
        float const pct = WebHitPct(me) * WebTickShare;
        std::list<Unit*> players;
        SelectTargetList(players, 40, SelectTargetMethod::Random, 0, 150.0f, true);
        for (Unit* player : players)
            if (player->HasAura(spellId, me->GetGUID()))
                DealSpellValue(me, player, spellId, int32(Unscaled(me, player, float(player->CountPctFromMaxHealth(pct)))));
    }

    struct FallingBat
    {
        ObjectGuid bat;
        uint32 timer;
        Position swirl;
    };

    EventMap _events;
    SummonList _summons;
    std::vector<FallingBat> _falling;
    std::vector<ObjectGuid> _cobraTargets;
    bool _inSeries = false;
    bool _swirlsStarted = false;
    uint8 _nextSay = SAY_90;
    bool _callingBats = false;
};

struct npc_coa_muzah_glaive : public ScriptedAI
{
    explicit npc_coa_muzah_glaive(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
        me->CastSpell(me, SPELL_GLAIVE_VISUAL, true);
        _pulse = 700;
        _roamDelay = 0;
    }

    void AttackStart(Unit* ) override { }
    void MoveInLineOfSight(Unit* ) override { }
    void EnterEvadeMode(EvadeReason ) override { }

    void SetData(uint32 type, uint32 value) override
    {
        if (type == DATA_GLAIVE_ROAMS)
            _roams = value != 0;
    }

    void MovementInform(uint32 type, uint32 ) override
    {
        if (type == POINT_MOTION_TYPE && _roams)
            _roamDelay = urand(300, 1200);
    }

    void UpdateAI(uint32 diff) override
    {
        if (_pulse <= diff)
        {
            _pulse = 700;
            me->CastSpell(me, ByDifficulty(me, SPELL_RIPPED_BY_THE_GLAIVES, SPELL_RIPPED_BY_THE_GLAIVES_HC, SPELL_RIPPED_BY_THE_GLAIVES_MYTHIC), true);
        }
        else
            _pulse -= diff;

        if (_roamDelay)
        {
            if (_roamDelay <= diff)
            {
                _roamDelay = 0;
                Roam();
            }
            else
                _roamDelay -= diff;
        }
    }

private:
    void Roam()
    {
        float const angle = frand(0.0f, 2.0f * float(M_PI));
        float const step = frand(5.0f, 10.0f);
        float x = me->GetPositionX() + step * std::cos(angle);
        float y = me->GetPositionY() + step * std::sin(angle);
        float const dx = x - ArenaCenter.GetPositionX();
        float const dy = y - ArenaCenter.GetPositionY();
        float const dist = std::sqrt(dx * dx + dy * dy);
        if (dist > ArenaRadius)
        {
            x = ArenaCenter.GetPositionX() + dx / dist * ArenaRadius;
            y = ArenaCenter.GetPositionY() + dy / dist * ArenaRadius;
        }
        me->GetMotionMaster()->MovePoint(POINT_GLAIVE_ROAM, GroundAt(me, x, y), FORCED_MOVEMENT_NONE, 4.0f, false);
    }

    uint32 _pulse = 700;
    uint32 _roamDelay = 0;
    bool _roams = false;
};

class spell_coa_muzah_ripped_by_the_glaives : public SpellScript
{
    PrepareSpellScript(spell_coa_muzah_ripped_by_the_glaives);

    void RememberStacks(SpellMissInfo )
    {
        _stacks = 0;
        if (Unit* target = GetHitUnit())
            if (Aura* bleed = target->GetAura(GetSpellInfo()->Id, GetCaster()->GetGUID()))
                _stacks = bleed->GetStackAmount();
    }

    void HandleHit()
    {
        SetHitDamage(Rolled(GetCaster(), GetHitUnit(), GlaiveHit));
    }

    void AddStack()
    {
        Unit* target = GetHitUnit();
        if (!target || !_stacks)
            return;
        if (Aura* bleed = target->GetAura(GetSpellInfo()->Id, GetCaster()->GetGUID()))
            bleed->SetStackAmount(uint8(std::min<uint32>(_stacks + 1, 99)));
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_coa_muzah_ripped_by_the_glaives::RememberStacks);
        OnHit += SpellHitFn(spell_coa_muzah_ripped_by_the_glaives::HandleHit);
        AfterHit += SpellHitFn(spell_coa_muzah_ripped_by_the_glaives::AddStack);
    }

    uint8 _stacks = 0;
};

class spell_coa_muzah_ripped_by_the_glaives_aura : public AuraScript
{
    PrepareAuraScript(spell_coa_muzah_ripped_by_the_glaives_aura);

    void CalcBleed(AuraEffect const* , int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        if (Unit* owner = GetUnitOwner())
            amount = int32(Logged(GetCaster() ? GetCaster() : owner, owner, GlaiveBleedPerStack));
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_coa_muzah_ripped_by_the_glaives_aura::CalcBleed, EFFECT_1, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class spell_coa_muzah_cobra_shot : public SpellScript
{
    PrepareSpellScript(spell_coa_muzah_cobra_shot);

    void FilterSplash(std::list<WorldObject*>& targets)
    {
        if (GetSpell()->IsTriggered())
        {
            targets.clear();
            return;
        }
        if (Unit* primary = GetExplTargetUnit())
            targets.remove(primary);
    }

    void HandleHit()
    {
        if (Unit* target = GetHitUnit())
            SetHitDamage(Rolled(GetCaster(), target, target == GetExplTargetUnit() ? CobraPrimary : CobraSplash));
    }

    void RemoveDot()
    {
        if (Unit* target = GetHitUnit())
            target->RemoveAurasDueToSpell(GetSpellInfo()->Id, GetCaster()->GetGUID());
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_muzah_cobra_shot::FilterSplash, EFFECT_1, TARGET_UNIT_SRC_AREA_ENEMY);
        OnHit += SpellHitFn(spell_coa_muzah_cobra_shot::HandleHit);
        AfterHit += SpellHitFn(spell_coa_muzah_cobra_shot::RemoveDot);
    }
};

class spell_coa_muzah_glaive_strike : public SpellScript
{
    PrepareSpellScript(spell_coa_muzah_glaive_strike);

    void FilterLine(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        targets.remove_if([caster](WorldObject* target) { return !caster->HasInLine(target, target->GetCombatReach(), StrikeWidth); });
    }

    void HandleHit()
    {
        SetHitDamage(Rolled(GetCaster(), GetHitUnit(), GlaiveStrike));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_muzah_glaive_strike::HandleHit);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_muzah_glaive_strike::FilterLine, EFFECT_0, TARGET_UNIT_CONE_ENEMY_24);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_muzah_glaive_strike::FilterLine, EFFECT_1, TARGET_UNIT_CONE_ENEMY_24);
    }
};

class spell_coa_muzah_entangling_web : public SpellScript
{
    PrepareSpellScript(spell_coa_muzah_entangling_web);

    void HandleHit()
    {
        if (Unit* target = GetHitUnit())
            SetHitDamage(int32(Unscaled(GetCaster(), target, float(target->CountPctFromMaxHealth(WebHitPct(target))))));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_muzah_entangling_web::HandleHit);
    }
};
}

void AddSC_CoAOtherSideMuzah()
{
    RegisterCreatureAI(boss_coa_muzah);
    RegisterCreatureAI(npc_coa_muzah_glaive);
    RegisterSpellAndAuraScriptPair(spell_coa_muzah_ripped_by_the_glaives, spell_coa_muzah_ripped_by_the_glaives_aura);
    RegisterSpellScript(spell_coa_muzah_cobra_shot);
    RegisterSpellScript(spell_coa_muzah_glaive_strike);
    RegisterSpellScript(spell_coa_muzah_entangling_web);
}
