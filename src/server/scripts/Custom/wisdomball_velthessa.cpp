/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Config.h"
#include "Containers.h"
#include "CreatureAI.h"
#include "CreatureScript.h"
#include "CreatureTextMgr.h"
#include "GameObject.h"
#include "GameTime.h"
#include "Map.h"
#include "MotionMaster.h"
#include "MoveSplineInit.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include <array>
#include <cmath>
#include <string>
#include <vector>

namespace
{
constexpr uint32 QUEST_NIGHTMARES_HAND = 9417115;

constexpr uint32 NPC_VELTHESSA    = 9417030;
constexpr uint32 NPC_KHADGAR      = 9417003;
constexpr uint32 NPC_DELWYN       = 9417006;
constexpr uint32 NPC_HAND         = 9417029;
constexpr uint32 NPC_FLAME_PRISON = 9417062;
constexpr uint32 NPC_TORNADO      = 9417063;
constexpr uint32 NPC_FROST_ZONE   = 9417064;
constexpr uint32 NPC_FROZEN_GROUND = 9417066;
constexpr uint32 NPC_NOVA_RING    = 9417067;
constexpr uint32 NPC_RAY_PRECAST  = 9417068;
constexpr uint32 NPC_RAY_BEAM     = 9417069;
constexpr uint32 NPC_ORB_PRECAST  = 9417070;
constexpr uint32 NPC_FROST_ORB    = 9417071;
constexpr uint32 SPAWN_SEAL_FOCUS = 9417122;

constexpr uint32 GO_ICE_WALL_HALF    = 9417226;
constexpr uint32 GO_ICE_WALL_QUARTER = 9417227;
constexpr uint32 GO_ESCAPE_PORTAL    = 9417228;

constexpr uint32 SPELL_FIRE_EXPLOSION  = 42967;
constexpr uint32 SPELL_HOLD_CHANNEL    = 59069;
constexpr uint32 SPELL_CHILLED         = 12484;
constexpr uint32 SPELL_TELEPORT_VISUAL = 41232;
constexpr uint32 SPELL_FROST_NOVA      = 11831;

constexpr uint32 DISPLAY_INVISIBLE = 11686;

constexpr uint32 EMOTE_ONESHOT_APPLAUD_ID     = 21;
constexpr uint32 EMOTE_SPELLEFFECT_HOLD_ID    = 422;
constexpr uint32 EMOTE_SWIM_IDLE_ID           = 437;
constexpr uint32 EMOTE_ONESHOT_OMNI_CAST_ID   = 463;
constexpr uint32 EMOTE_CHANNEL_DIRECTED_ID    = 469;
constexpr uint32 EMOTE_ONESHOT_DECAY_ID       = 993;
constexpr uint32 EMOTE_ONESHOT_ATTACK2HL_ID   = 38;
constexpr uint32 EMOTE_STATE_READY2HL_MOVE_ID = 654;

constexpr uint8 SAY_VELTHESSA_WELL_DONE  = 1;
constexpr uint8 SAY_VELTHESSA_FREE       = 2;
constexpr uint8 SAY_VELTHESSA_MINION     = 3;
constexpr uint8 SAY_VELTHESSA_WALLS      = 4;
constexpr uint8 SAY_HERALD_CLEAVE = 0;
constexpr uint8 SAY_HERALD_GROUND = 1;
constexpr uint8 SAY_HERALD_NOVA   = 2;
constexpr uint8 SAY_KHADGAR_PRISON_FAILS = 4;
constexpr uint8 SAY_KHADGAR_TOO_LATE     = 6;
constexpr uint8 SAY_KHADGAR_HOLD_MINION  = 10;
constexpr uint8 SAY_DELWYN_HOLD_HER      = 5;

uint32 BubbleGapMs(uint32 entry, uint8 group, Player const* player)
{
    std::string text = sCreatureTextMgr->GetLocalizedChatString(entry, 0, group, 0, DEFAULT_LOCALE);
    size_t chars = text.size();
    if (player && text.find("$N") != std::string::npos)
        chars = chars - 2 + player->GetName().size();
    return std::max<uint32>(5000, uint32(150 * chars) + 1000) + 3000;
}

constexpr uint32 MAP_DALARAN_CRATER = 4418;

Position const LandingSpot   = { -11845.18f, -3102.729f, -10.84f, 6.2171354f };
Position const CraterLanding = { 293.71f, 377.26f, -64.09f, 5.50f };

constexpr uint32 DESCENT_START_MS   = 500;
constexpr uint32 DESCENT_MS         = 8000;
constexpr uint32 DESCENT_STEP_MS_DEFAULT = 100;
constexpr float  TRIGGER_RANGE      = 80.0f;
constexpr float  ARENA_RANGE        = 160.0f;
constexpr float  HELPER_RANGE       = 80.0f;
constexpr uint32 PRISON_VANISH_MS   = 800;
constexpr uint32 APPLAUSE_TO_CHANNEL_MS = 5000;
constexpr uint32 CHANNEL_MS         = 3000;
constexpr uint32 WALL_INTERVAL_MS   = 200;
constexpr uint32 WALL_CLOSE_DELAY_MS = 200;
constexpr float  PORTAL_WALK_IN_RANGE = 2.5f;
constexpr uint32 PORTAL_AUTO_TELEPORT_MS = 30000;
Position const KhadgarHoldSpot = { -11831.829f, -3094.241f, -11.36928f, 3.3996124f };
constexpr uint32 KHADGAR_MOVE_POINT = 1;

constexpr uint32 RAY_CHARGE_MS      = 2000;
constexpr uint32 RAY_BEAM_MS        = 2000;
constexpr float  RAY_LENGTH         = 22.0f;
constexpr float  RAY_HALF_WIDTH     = 2.0f;
constexpr float  RAY_DAMAGE_PCT     = 25.0f;
constexpr uint32 GROUND_LIFETIME_MS = 15000;
constexpr uint32 GROUND_ARM_MS      = 1000;
constexpr float  GROUND_REACH       = 5.5f;
constexpr float  GROUND_DAMAGE_PCT  = 4.0f;
constexpr uint32 NOVA_WARN_MS       = 3000;
constexpr float  NOVA_RANGE         = 10.0f;
constexpr int32  NOVA_BP            = 300;
constexpr int32  ROOT_MS            = 2000;
constexpr uint32 ORB_FIRST_MS       = 12000;
constexpr uint32 ORB_EVERY_MS       = 20000;
constexpr uint32 ORB_CHARGE_MS      = 2000;
constexpr float  ORB_SPEED          = 6.0f;
constexpr float  ORB_RANGE          = 85.0f;
constexpr float  ORB_REACH          = 2.5f;
constexpr float  ORB_DAMAGE_PCT     = 20.0f;
constexpr uint32 ORB_LIFETIME_MS    = 15000;
constexpr uint32 RESPAWN_AFTER_RESET_S = 5;

constexpr std::array<float, 4> TORNADO_THRESHOLDS = { 80.0f, 60.0f, 40.0f, 20.0f };
constexpr uint32 TORNADO_LIFETIME_MS = 10000;
constexpr uint64 TORNADO_MIN_GAP_MS  = 15000;
constexpr uint32 TORNADO_TICK_MS     = 1000;
constexpr float  TORNADO_REACH       = 2.5f;
constexpr float  TORNADO_DAMAGE_PCT  = 5.0f;
constexpr float  TORNADO_SPAWN_MIN   = 8.0f;
constexpr float  TORNADO_SPAWN_MAX   = 12.0f;
constexpr uint32 TORNADO_CHASE_CHECK_MS = 1000;

struct WallSpawn
{
    uint32 entry;
    float x, y, z, o, r0, r1, r2, r3;
};

constexpr WallSpawn ICE_WALLS[] =
{
    { GO_ICE_WALL_HALF, -11852.6f, -3111.66f, -11.293f, 0.082664f, 0.0f, 0.0f, 0.04132f, 0.999146f },
    { GO_ICE_WALL_HALF, -11842.7f, -3132.52f, -10.0022f, 0.872017f, 0.0f, 0.0f, 0.422325f, 0.906444f },
    { GO_ICE_WALL_HALF, -11835.8f, -3140.68f, -6.01839f, 0.758135f, 0.0f, 0.0f, 0.370054f, 0.92901f },
    { GO_ICE_WALL_HALF, -11828.2f, -3148.06f, -0.296928f, 1.17832f, 0.0f, 0.0f, 0.555665f, 0.831406f },
    { GO_ICE_WALL_HALF, -11819.3f, -3154.81f, 0.631284f, 0.930919f, 0.0f, 0.0f, 0.448834f, 0.893615f },
    { GO_ICE_WALL_HALF, -11810.8f, -3161.06f, 1.40664f, 0.919138f, 0.0f, 0.0f, 0.443562f, 0.896244f },
    { GO_ICE_WALL_HALF, -11811.3f, -3164.53f, -5.82727f, 0.864124f, 0.0f, 0.0f, 0.418744f, 0.908104f },
    { GO_ICE_WALL_HALF, -11802.3f, -3167.16f, -1.64262f, 1.11156f, 0.0f, 0.0f, 0.527606f, 0.849489f },
    { GO_ICE_WALL_HALF, -11793.4f, -3172.81f, -0.625971f, 1.28042f, 0.0f, 0.0f, 0.597364f, 0.801971f },
    { GO_ICE_WALL_HALF, -11783.5f, -3175.62f, 0.695591f, 1.35896f, 0.0f, 0.0f, 0.628388f, 0.7779f },
    { GO_ICE_WALL_HALF, -11772.7f, -3176.76f, 0.415469f, 1.53175f, 0.0f, 0.0f, 0.693167f, 0.720777f },
    { GO_ICE_WALL_HALF, -11761.4f, -3176.35f, 0.431189f, 1.71632f, 0.0f, 0.0f, 0.756639f, 0.653833f },
    { GO_ICE_WALL_HALF, -11749.9f, -3173.74f, 0.433639f, 1.87732f, 0.0f, 0.0f, 0.806768f, 0.590869f },
    { GO_ICE_WALL_HALF, -11739.9f, -3169.17f, 0.471141f, 2.0776f, 0.0f, 0.0f, 0.861796f, 0.507255f },
    { GO_ICE_WALL_HALF, -11730.0f, -3162.43f, 0.502243f, 2.18755f, 0.0f, 0.0f, 0.888367f, 0.459133f },
    { GO_ICE_WALL_HALF, -11721.0f, -3153.39f, 0.548672f, 2.46637f, 0.0f, 0.0f, 0.943549f, 0.331234f },
    { GO_ICE_WALL_HALF, -11713.1f, -3144.93f, -3.20475f, 2.5292f, 0.0f, 0.0f, 0.953487f, 0.301433f },
    { GO_ICE_WALL_HALF, -11706.4f, -3133.79f, -5.70649f, 2.863f, 0.0f, 0.0f, 0.990314f, 0.138848f },
    { GO_ICE_WALL_HALF, -11705.0f, -3126.26f, -10.4508f, 3.0672f, 0.0f, 0.0f, 0.999308f, 0.037186f },
    { GO_ICE_WALL_HALF, -11703.9f, -3115.25f, -11.4711f, 3.18109f, 0.0f, 0.0f, 0.999805f, -0.019745f },
    { GO_ICE_WALL_HALF, -11704.3f, -3104.58f, -7.63701f, 3.18109f, 0.0f, 0.0f, 0.999805f, -0.019745f },
    { GO_ICE_WALL_QUARTER, -11703.9f, -3094.35f, -11.4425f, 3.46775f, 0.0f, 0.0f, 0.986732f, -0.162355f },
    { GO_ICE_WALL_HALF, -11704.4f, -3094.16f, -8.10941f, 3.41278f, 0.0f, 0.0f, 0.990821f, -0.135178f },
    { GO_ICE_WALL_HALF, -11708.7f, -3084.99f, -4.38137f, 3.73479f, 0.0f, 0.0f, 0.956336f, -0.29227f },
    { GO_ICE_WALL_HALF, -11715.0f, -3076.15f, -3.69226f, 3.82119f, 0.0f, 0.0f, 0.942822f, -0.333295f },
    { GO_ICE_WALL_HALF, -11722.5f, -3067.43f, -6.75012f, 3.97827f, 0.0f, 0.0f, 0.913766f, -0.406241f },
    { GO_ICE_WALL_QUARTER, -11723.7f, -3064.48f, -10.5911f, 3.93898f, 0.0f, 0.0f, 0.921569f, -0.388215f },
    { GO_ICE_WALL_HALF, -11730.4f, -3060.51f, -6.75108f, 4.06073f, 0.0f, 0.0f, 0.896244f, -0.443561f },
    { GO_ICE_WALL_HALF, -11739.6f, -3053.98f, -4.30196f, 4.2178f, 0.0f, 0.0f, 0.858681f, -0.51251f },
    { GO_ICE_WALL_HALF, -11749.9f, -3049.63f, -4.59793f, 4.40629f, 0.0f, 0.0f, 0.806641f, -0.591042f },
    { GO_ICE_WALL_HALF, -11761.4f, -3047.2f, -4.65777f, 4.59478f, 0.0f, 0.0f, 0.747442f, -0.664327f },
    { GO_ICE_WALL_HALF, -11772.9f, -3046.4f, -4.75455f, 4.8461f, 0.0f, 0.0f, 0.658288f, -0.752766f },
    { GO_ICE_WALL_HALF, -11784.3f, -3047.94f, -4.82656f, 4.97176f, 0.0f, 0.0f, 0.609723f, -0.792615f },
    { GO_ICE_WALL_HALF, -11796.1f, -3052.05f, -4.89982f, 5.11313f, 0.0f, 0.0f, 0.552221f, -0.833697f },
    { GO_ICE_WALL_HALF, -11806.8f, -3056.44f, -5.00706f, 5.2113f, 0.0f, 0.0f, 0.51065f, -0.859788f },
    { GO_ICE_WALL_HALF, -11815.9f, -3061.72f, -6.87358f, 5.34089f, 0.0f, 0.0f, 0.453908f, -0.891048f },
    { GO_ICE_WALL_HALF, -11824.7f, -3068.37f, -9.47345f, 5.4587f, 0.0f, 0.0f, 0.400663f, -0.916225f },
    { GO_ICE_WALL_HALF, -11833.0f, -3075.24f, -11.3387f, 5.32519f, 0.0f, 0.0f, 0.460891f, -0.887457f },
    { GO_ICE_WALL_HALF, -11842.5f, -3079.8f, -11.2429f, 5.15633f, 0.0f, 0.0f, 0.534087f, -0.845429f },
    { GO_ICE_WALL_HALF, -11852.2f, -3086.19f, -11.3934f, 0.018485f, 0.0f, 0.0f, 0.009242f, 0.999957f },
    { GO_ICE_WALL_HALF, -11852.0f, -3098.9f, -11.0271f, 0.018485f, 0.0f, 0.0f, 0.009242f, 0.999957f },
};

enum class VelthessaState : uint8
{
    Imprisoned,
    Prelude,
    Bursting,
    Descending,
    HandFight,
    Escaping,
    Done
};

void FrostHit(Creature* source, Player* target, float pct, bool chill)
{
    SpellInfo const* chillInfo = sSpellMgr->GetSpellInfo(SPELL_CHILLED);
    uint32 const damage = uint32(target->GetMaxHealth() * pct / 100.0f);
    SpellNonMeleeDamage log(source, target, chillInfo, SPELL_SCHOOL_MASK_FROST);
    log.damage = damage;
    source->SendSpellNonMeleeDamageLog(&log);
    Unit::DealDamage(source, target, damage, nullptr, SPELL_DIRECT_DAMAGE, SPELL_SCHOOL_MASK_FROST, chillInfo, false);
    if (chill && target->IsAlive())
        source->CastSpell(target, SPELL_CHILLED, true);
}

bool IsArenaPlayer(Creature const* me, Player const* player)
{
    return player && player->IsInWorld() && !player->IsGameMaster() && me->InSamePhase(player) &&
        player->IsWithinDist2d(LandingSpot.GetPositionX(), LandingSpot.GetPositionY(), ARENA_RANGE);
}
}

struct npc_wisdomball_velthessa : public ScriptedAI
{
    explicit npc_wisdomball_velthessa(Creature* creature) : ScriptedAI(creature), _summons(creature) { }

    void Reset() override
    {
        scheduler.CancelAll();
        _summons.DespawnAll();
        _state = VelthessaState::Imprisoned;
        _hand.Clear();
        _frostZone.Clear();
        _questPlayer.Clear();
        _portal.Clear();
        _tornadoesSent = 0;
        _lastTornadoMs = 0;
        _wallsRaised = 0;

        me->SetReactState(REACT_PASSIVE);
        me->SetDisableGravity(true);
        me->SetDisplayId(me->GetNativeDisplayId(), me->GetNativeObjectScale());
        scheduler.Schedule(1s, [this](TaskContext)
        {
            if (Creature* prison = me->FindNearestCreature(NPC_FLAME_PRISON, 15.0f))
                prison->SetDisplayId(prison->GetNativeDisplayId(), prison->GetNativeObjectScale());
        });
        me->SetEmoteState(Emote(EMOTE_SWIM_IDLE_ID));

        scheduler.Schedule(500ms, [this](TaskContext context)
        {
            if (_state != VelthessaState::Imprisoned)
                return;
            if (Player* player = FindTriggeringPlayer())
                StartPrelude(player);
            else
                context.Repeat();
        });
    }

    void JustSummoned(Creature* summon) override
    {
        _summons.Summon(summon);
    }

    void SummonedCreatureDies(Creature* summon, Unit*) override
    {
        if (summon->GetGUID() == _hand && _state == VelthessaState::HandFight)
            StartEscape();
    }

    void SummonedCreatureDespawn(Creature* summon) override
    {
        _summons.Despawn(summon);
        if (summon->GetGUID() == _hand && _state == VelthessaState::HandFight && summon->IsAlive())
            ResetToPrison();
    }

    void EnterEvadeMode(EvadeReason ) override { }

    void UpdateAI(uint32 diff) override
    {
        scheduler.Update(diff);
    }

private:
    Player* FindTriggeringPlayer() const
    {
        for (auto const& ref : me->GetMap()->GetPlayers())
        {
            Player* player = ref.GetSource();
            if (IsArenaPlayer(me, player) && player->IsAlive() && me->IsWithinDist(player, TRIGGER_RANGE) &&
                me->IsWithinLOSInMap(player) && player->GetQuestStatus(QUEST_NIGHTMARES_HAND) == QUEST_STATUS_INCOMPLETE)
                return player;
        }
        return nullptr;
    }

    bool AnyArenaPlayerAlive() const
    {
        for (auto const& ref : me->GetMap()->GetPlayers())
            if (Player* player = ref.GetSource(); IsArenaPlayer(me, player) && player->IsAlive())
                return true;
        return false;
    }

    Creature* Khadgar() const { return me->FindNearestCreature(NPC_KHADGAR, HELPER_RANGE); }
    Creature* Delwyn() const { return me->FindNearestCreature(NPC_DELWYN, HELPER_RANGE); }

    Creature* SealFocus() const
    {
        auto const bounds = me->GetMap()->GetCreatureBySpawnIdStore().equal_range(SPAWN_SEAL_FOCUS);
        return bounds.first != bounds.second ? bounds.first->second : nullptr;
    }

    void HelpersChannel(bool start)
    {
        for (Creature* helper : { Khadgar(), Delwyn() })
        {
            if (!helper)
                continue;
            if (!start)
                helper->InterruptNonMeleeSpells(true);
            else if (Creature* focus = SealFocus())
                helper->CastSpell(focus, SPELL_HOLD_CHANNEL, true);
        }
    }

    void StartPrelude(Player* player)
    {
        _state = VelthessaState::Prelude;
        _questPlayer = player->GetGUID();

        uint32 const gap1 = BubbleGapMs(NPC_KHADGAR, SAY_KHADGAR_PRISON_FAILS, player);
        uint32 const gap2 = BubbleGapMs(NPC_DELWYN, SAY_DELWYN_HOLD_HER, player);

        if (Creature* khadgar = Khadgar())
        {
            khadgar->AI()->Talk(SAY_KHADGAR_PRISON_FAILS);
            khadgar->SetWalk(false);
            khadgar->GetMotionMaster()->MovePoint(KHADGAR_MOVE_POINT, KhadgarHoldSpot.GetPositionX(), KhadgarHoldSpot.GetPositionY(),
                                                  KhadgarHoldSpot.GetPositionZ());
        }
        scheduler.Schedule(250ms, [this](TaskContext context)
        {
            Creature* khadgar = Khadgar();
            if (!khadgar)
                return;
            if (khadgar->GetExactDist2d(KhadgarHoldSpot.GetPositionX(), KhadgarHoldSpot.GetPositionY()) > 1.0f && context.GetRepeatCounter() < 60)
            {
                context.Repeat();
                return;
            }
            khadgar->SetFacingToObject(me);
        });
        ScheduleWipeCheck();

        scheduler.Schedule(Milliseconds(gap1), [this](TaskContext)
        {
            if (Creature* delwyn = Delwyn())
                delwyn->AI()->Talk(SAY_DELWYN_HOLD_HER);
        });
        scheduler.Schedule(Milliseconds(gap1 + gap2), [this](TaskContext) { StartBurst(); });
    }

    void StartBurst()
    {
        _state = VelthessaState::Bursting;

        if (Creature* prison = me->FindNearestCreature(NPC_FLAME_PRISON, 15.0f))
        {
            prison->HandleEmoteCommand(EMOTE_ONESHOT_DECAY_ID);
            ObjectGuid const prisonGuid = prison->GetGUID();
            scheduler.Schedule(Milliseconds(PRISON_VANISH_MS), [this, prisonGuid](TaskContext)
            {
                if (Creature* p = ObjectAccessor::GetCreature(*me, prisonGuid))
                    p->SetDisplayId(DISPLAY_INVISIBLE);
            });
        }
        me->CastSpell(me, SPELL_FIRE_EXPLOSION, true);
        Talk(SAY_VELTHESSA_FREE);
        scheduler.Schedule(250ms, [this](TaskContext context)
        {
            Creature* khadgar = Khadgar();
            if (khadgar && khadgar->GetExactDist2d(KhadgarHoldSpot.GetPositionX(), KhadgarHoldSpot.GetPositionY()) > 1.0f &&
                context.GetRepeatCounter() < 40)
            {
                context.Repeat();
                return;
            }
            if (khadgar)
                khadgar->SetFacingToObject(me);
            if (_state == VelthessaState::Bursting || _state == VelthessaState::Descending || _state == VelthessaState::HandFight)
                HelpersChannel(true);
        });

        scheduler.Schedule(Milliseconds(DESCENT_START_MS), [this](TaskContext) { StartDescent(); });
    }

    void StartDescent()
    {
        _state = VelthessaState::Descending;
        _descentFrom = me->GetPosition();
        _descentStep = 0;
        me->SetEmoteState(Emote(EMOTE_SWIM_IDLE_ID));

        std::string const mode = sConfigMgr->GetOption<std::string>("Wisdomball.Velthessa.DescentMode", "Spline");
        if (mode == "Steps")
        {
            uint32 const stepMs = std::max<uint32>(20, sConfigMgr->GetOption<uint32>("Wisdomball.Velthessa.DescentStepMs", DESCENT_STEP_MS_DEFAULT));
            scheduler.Schedule(Milliseconds(stepMs), [this, stepMs](TaskContext context)
            {
                uint32 const steps = std::max<uint32>(1, DESCENT_MS / stepMs);
                ++_descentStep;
                float const f = float(_descentStep) / float(steps);
                me->NearTeleportTo(_descentFrom.GetPositionX() + (LandingSpot.GetPositionX() - _descentFrom.GetPositionX()) * f,
                                   _descentFrom.GetPositionY() + (LandingSpot.GetPositionY() - _descentFrom.GetPositionY()) * f,
                                   _descentFrom.GetPositionZ() + (LandingSpot.GetPositionZ() - _descentFrom.GetPositionZ()) * f,
                                   LandingSpot.GetOrientation());
                me->SetEmoteState(Emote(EMOTE_SWIM_IDLE_ID));
                if (_descentStep < steps)
                    context.Repeat();
                else
                    Land();
            });
            return;
        }

        Movement::MoveSplineInit init(me);
        init.MoveTo(LandingSpot.GetPositionX(), LandingSpot.GetPositionY(), LandingSpot.GetPositionZ(), false, true);
        init.SetVelocity(std::max(0.1f, me->GetExactDist(&LandingSpot) / (DESCENT_MS / 1000.0f)));
        init.SetFacing(LandingSpot.GetOrientation());
        if (mode == "SplineHover")
            init.SetAnimation(AnimTier::Hover);
        init.Launch();
        scheduler.Schedule(Milliseconds(DESCENT_MS + 200), [this](TaskContext) { Land(); });
    }

    void Land()
    {
        _state = VelthessaState::HandFight;
        me->SetDisableGravity(false);
        me->SetEmoteState(Emote(EMOTE_CHANNEL_DIRECTED_ID));

        Player* player = ObjectAccessor::GetPlayer(*me, _questPlayer);
        Talk(SAY_VELTHESSA_MINION, player);
        scheduler.Schedule(Milliseconds(BubbleGapMs(NPC_VELTHESSA, SAY_VELTHESSA_MINION, player)), [this](TaskContext)
        {
            if (_state != VelthessaState::HandFight)
                return;
            if (Creature* hand = me->SummonCreature(NPC_HAND, LandingSpot.GetPositionX() + 12.0f, LandingSpot.GetPositionY(),
                                                    LandingSpot.GetPositionZ() - 0.63f, LandingSpot.GetOrientation(),
                                                    TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT, 60000))
                _hand = hand->GetGUID();
            if (Creature* khadgar = Khadgar())
                khadgar->AI()->Talk(SAY_KHADGAR_HOLD_MINION, ObjectAccessor::GetPlayer(*me, _questPlayer));
            scheduler.Schedule(Milliseconds(ORB_FIRST_MS), [this](TaskContext context)
            {
                if (_state != VelthessaState::HandFight)
                    return;
                CastFrostOrb();
                context.Repeat(Milliseconds(ORB_EVERY_MS));
            });
        });

        if (Creature* zone = me->SummonCreature(NPC_FROST_ZONE, me->GetPosition(), TEMPSUMMON_MANUAL_DESPAWN))
        {
            _frostZone = zone->GetGUID();
            scheduler.Schedule(500ms, [this](TaskContext)
            {
                if (Creature* z = ObjectAccessor::GetCreature(*me, _frostZone))
                    z->SetEmoteState(Emote(EMOTE_SPELLEFFECT_HOLD_ID));
            });
        }

        scheduler.Schedule(250ms, [this](TaskContext context)
        {
            if (_state != VelthessaState::HandFight)
                return;
            CheckTornado();
            context.Repeat();
        });
    }

    void CheckTornado()
    {
        Creature* hand = ObjectAccessor::GetCreature(*me, _hand);
        if (!hand || !hand->IsAlive() || _tornadoesSent >= TORNADO_THRESHOLDS.size() ||
            hand->GetHealthPct() > TORNADO_THRESHOLDS[_tornadoesSent])
            return;
        if (_lastTornadoMs && GameTime::GetGameTimeMS().count() - _lastTornadoMs < TORNADO_MIN_GAP_MS)
            return;
        _lastTornadoMs = GameTime::GetGameTimeMS().count();

        ++_tornadoesSent;
        std::vector<Player*> targets;
        for (auto const& ref : me->GetMap()->GetPlayers())
            if (Player* player = ref.GetSource(); IsArenaPlayer(me, player) && player->IsAlive())
                targets.push_back(player);
        if (targets.empty())
            return;

        Player* target = Acore::Containers::SelectRandomContainerElement(targets);
        Position spot = target->GetFirstCollisionPosition(frand(TORNADO_SPAWN_MIN, TORNADO_SPAWN_MAX), frand(0.0f, 2.0f * float(M_PI)));
        spot.SetOrientation(spot.GetAngle(target));
        if (Creature* tornado = me->SummonCreature(NPC_TORNADO, spot, TEMPSUMMON_TIMED_DESPAWN, TORNADO_LIFETIME_MS + 2000))
            tornado->AI()->SetGUID(target->GetGUID(), 0);
    }

    void CastFrostOrb()
    {
        std::vector<Player*> targets;
        for (auto const& ref : me->GetMap()->GetPlayers())
            if (Player* player = ref.GetSource(); IsArenaPlayer(me, player) && player->IsAlive())
                targets.push_back(player);
        if (targets.empty())
            return;
        ObjectGuid const target = Acore::Containers::SelectRandomContainerElement(targets)->GetGUID();

        Position hands = me->GetNearPosition(1.5f, 0.0f);
        hands.m_positionZ = me->GetPositionZ() + 3.0f;
        me->SummonCreature(NPC_ORB_PRECAST, hands, TEMPSUMMON_TIMED_DESPAWN, ORB_CHARGE_MS);
        scheduler.Schedule(Milliseconds(ORB_CHARGE_MS), [this, target, hands](TaskContext)
        {
            if (_state != VelthessaState::HandFight)
                return;
            me->HandleEmoteCommand(EMOTE_ONESHOT_OMNI_CAST_ID);
            Player* p = ObjectAccessor::GetPlayer(*me, target);
            if (!p)
                return;
            float const angle = hands.GetAngle(p);
            float const z = p->GetPositionZ() + 1.5f;
            if (Creature* orb = me->SummonCreature(NPC_FROST_ORB, hands.GetPositionX(), hands.GetPositionY(), z, angle,
                                                   TEMPSUMMON_TIMED_DESPAWN, ORB_LIFETIME_MS + 1500))
                orb->GetMotionMaster()->MovePoint(1, hands.GetPositionX() + ORB_RANGE * std::cos(angle),
                                                  hands.GetPositionY() + ORB_RANGE * std::sin(angle), z,
                                                  FORCED_MOVEMENT_NONE, ORB_SPEED, 0.0f, false, true);
        });
    }

    void ScheduleWipeCheck()
    {
        scheduler.Schedule(1s, [this](TaskContext context)
        {
            if (_state == VelthessaState::Escaping || _state == VelthessaState::Done)
                return;
            if (!AnyArenaPlayerAlive())
            {
                ResetToPrison();
                return;
            }
            context.Repeat();
        });
    }

    void ResetToPrison()
    {
        _state = VelthessaState::Done;
        scheduler.CancelAll();
        HelpersChannel(false);
        if (Creature* khadgar = Khadgar())
        {
            Position const home = khadgar->GetHomePosition();
            khadgar->GetMotionMaster()->MovePoint(KHADGAR_MOVE_POINT, home.GetPositionX(), home.GetPositionY(), home.GetPositionZ(),
                                                  FORCED_MOVEMENT_NONE, 0.0f, home.GetAngle(&LandingSpot));
        }
        _summons.DespawnAll();
        if (Creature* prison = me->FindNearestCreature(NPC_FLAME_PRISON, 30.0f))
            prison->DespawnOrUnsummon(0ms, Seconds(RESPAWN_AFTER_RESET_S));
        me->DespawnOrUnsummon(0ms, Seconds(RESPAWN_AFTER_RESET_S));
    }

    void StartEscape()
    {
        _state = VelthessaState::Escaping;
        HelpersChannel(false);
        me->SetEmoteState(EMOTE_ONESHOT_NONE);

        for (ObjectGuid const& guid : _summons)
            if (Creature* summon = ObjectAccessor::GetCreature(*me, guid))
                if (summon->GetEntry() == NPC_FROST_ZONE || summon->GetEntry() == NPC_TORNADO || summon->GetEntry() == NPC_FROST_ORB)
                {
                    summon->HandleEmoteCommand(EMOTE_ONESHOT_DECAY_ID);
                    summon->DespawnOrUnsummon(summon->GetEntry() == NPC_FROST_ZONE ? 850ms : 450ms);
                }

        me->HandleEmoteCommand(EMOTE_ONESHOT_APPLAUD_ID);
        Talk(SAY_VELTHESSA_WELL_DONE);

        scheduler.Schedule(Milliseconds(APPLAUSE_TO_CHANNEL_MS), [this](TaskContext)
        {
            me->SetEmoteState(Emote(EMOTE_CHANNEL_DIRECTED_ID));
        });
        scheduler.Schedule(Milliseconds(APPLAUSE_TO_CHANNEL_MS + CHANNEL_MS), [this](TaskContext)
        {
            me->SetEmoteState(EMOTE_ONESHOT_NONE);
            me->HandleEmoteCommand(EMOTE_ONESHOT_OMNI_CAST_ID);
            Player* player = ObjectAccessor::GetPlayer(*me, _questPlayer);
            Talk(SAY_VELTHESSA_WALLS, player);
            RaiseNextWall();
            uint32 const gap = BubbleGapMs(NPC_VELTHESSA, SAY_VELTHESSA_WALLS, player);
            scheduler.Schedule(Milliseconds(gap), [this](TaskContext)
            {
                if (Creature* khadgar = Khadgar())
                {
                    khadgar->AI()->Talk(SAY_KHADGAR_TOO_LATE);
                    khadgar->CastSpell(khadgar, SPELL_TELEPORT_VISUAL, true);
                    Position spot = khadgar->GetNearPosition(4.0f, 0.0f);
                    if (GameObject* portal = khadgar->SummonGameObject(GO_ESCAPE_PORTAL, spot.GetPositionX(), spot.GetPositionY(),
                                                                        khadgar->GetPositionZ(), khadgar->GetOrientation(), 0.0f, 0.0f, 0.0f, 0.0f, 60))
                    {
                        _portal = portal->GetGUID();
                        scheduler.Schedule(250ms, [this](TaskContext context)
                        {
                            GameObject* portal = ObjectAccessor::GetGameObject(*me, _portal);
                            if (!portal)
                                return;
                            std::vector<Player*> entering;
                            for (auto const& ref : me->GetMap()->GetPlayers())
                                if (Player* player = ref.GetSource(); player && player->IsAlive() && me->InSamePhase(player) &&
                                    portal->GetExactDist2d(player) <= PORTAL_WALK_IN_RANGE &&
                                    std::fabs(portal->GetPositionZ() - player->GetPositionZ()) < 4.0f)
                                    entering.push_back(player);
                            for (Player* player : entering)
                                player->TeleportTo(MAP_DALARAN_CRATER, CraterLanding.GetPositionX(), CraterLanding.GetPositionY(),
                                                   CraterLanding.GetPositionZ(), CraterLanding.GetOrientation());
                            context.Repeat();
                        });
                    }
                    if (Creature* delwyn = Delwyn())
                    {
                        float const side = khadgar->GetOrientation() + float(M_PI) / 2.0f;
                        float const x = spot.GetPositionX() + 3.0f * std::cos(side);
                        float const y = spot.GetPositionY() + 3.0f * std::sin(side);
                        delwyn->SetWalk(false);
                        delwyn->GetMotionMaster()->MovePoint(1, x, y, khadgar->GetPositionZ(), FORCED_MOVEMENT_NONE, 0.0f,
                                                             std::atan2(spot.GetPositionY() - y, spot.GetPositionX() - x));
                    }
                }
            });
            scheduler.Schedule(Milliseconds(gap + PORTAL_AUTO_TELEPORT_MS), [this](TaskContext) { TeleportEveryoneOut(); });
        });
    }

    void RaiseNextWall()
    {
        int const front = int(_wallsRaised);
        int const back = int(std::size(ICE_WALLS)) - 1 - front;
        if (front > back)
            return;
        SpawnWall(ICE_WALLS[front]);
        if (back != front)
            SpawnWall(ICE_WALLS[back]);
        ++_wallsRaised;
        scheduler.Schedule(Milliseconds(WALL_INTERVAL_MS), [this](TaskContext) { RaiseNextWall(); });
    }

    void SpawnWall(WallSpawn const& w)
    {
        if (GameObject* wall = me->SummonGameObject(w.entry, w.x, w.y, w.z, w.o, w.r0, w.r1, w.r2, w.r3, 0))
        {
            wall->SetGoState(GO_STATE_ACTIVE);
            ObjectGuid const wallGuid = wall->GetGUID();
            scheduler.Schedule(Milliseconds(WALL_CLOSE_DELAY_MS), [this, wallGuid](TaskContext)
            {
                if (GameObject* g = ObjectAccessor::GetGameObject(*me, wallGuid))
                    g->SetGoState(GO_STATE_READY);
            });
        }
    }

    void TeleportEveryoneOut()
    {
        for (Creature* helper : { Khadgar(), Delwyn() })
            if (helper)
            {
                helper->CastSpell(helper, SPELL_TELEPORT_VISUAL, true);
                helper->DespawnOrUnsummon(500ms);
            }

        std::vector<Player*> players;
        for (auto const& ref : me->GetMap()->GetPlayers())
            if (Player* player = ref.GetSource(); IsArenaPlayer(me, player))
                players.push_back(player);
        for (Player* player : players)
            player->TeleportTo(MAP_DALARAN_CRATER, CraterLanding.GetPositionX(), CraterLanding.GetPositionY(),
                               CraterLanding.GetPositionZ(), CraterLanding.GetOrientation());

        if (GameObject* portal = ObjectAccessor::GetGameObject(*me, _portal))
            portal->Delete();
        _state = VelthessaState::Done;
    }

    SummonList _summons;
    VelthessaState _state = VelthessaState::Imprisoned;
    ObjectGuid _hand;
    ObjectGuid _frostZone;
    ObjectGuid _questPlayer;
    ObjectGuid _portal;
    uint8 _tornadoesSent = 0;
    uint64 _lastTornadoMs = 0;
    uint32 _wallsRaised = 0;
    Position _descentFrom;
    uint32 _descentStep = 0;
};

struct npc_wisdomball_blistering_tornado : public ScriptedAI
{
    explicit npc_wisdomball_blistering_tornado(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
        scheduler.Schedule(600ms, [this](TaskContext)
        {
            me->SetEmoteState(Emote(EMOTE_SPELLEFFECT_HOLD_ID));
        });
        scheduler.Schedule(Milliseconds(TORNADO_TICK_MS), [this](TaskContext context)
        {
            Hit();
            context.Repeat();
        });
        scheduler.Schedule(Milliseconds(TORNADO_LIFETIME_MS), [this](TaskContext)
        {
            scheduler.CancelAll();
            me->GetMotionMaster()->Clear();
            me->HandleEmoteCommand(EMOTE_ONESHOT_DECAY_ID);
            me->DespawnOrUnsummon(450ms);
        });
    }

    void SetGUID(ObjectGuid const& guid, int32 ) override
    {
        _target = guid;
        me->SetWalk(false);
        scheduler.Schedule(100ms, [this](TaskContext context)
        {
            if (Player* target = ObjectAccessor::GetPlayer(*me, _target); target && target->IsAlive())
                me->GetMotionMaster()->MovePoint(1, target->GetPositionX(), target->GetPositionY(), target->GetPositionZ());
            context.Repeat(Milliseconds(TORNADO_CHASE_CHECK_MS / 2));
        });
    }

    void EnterEvadeMode(EvadeReason ) override { }

    void UpdateAI(uint32 diff) override
    {
        scheduler.Update(diff);
    }

private:
    void Hit()
    {
        Player* target = ObjectAccessor::GetPlayer(*me, _target);
        if (target && target->IsAlive() && me->IsWithinDist(target, TORNADO_REACH))
            FrostHit(me, target, TORNADO_DAMAGE_PCT, true);
    }

    ObjectGuid _target;
};

struct npc_wisdomball_herald : public ScriptedAI
{
    explicit npc_wisdomball_herald(Creature* creature) : ScriptedAI(creature), _summons(creature) { }

    void Reset() override
    {
        scheduler.CancelAll();
        _summons.DespawnAll();
        _busy = false;
        _rotationStarted = false;
        _rotation.clear();
        me->SetControlled(false, UNIT_STATE_ROOT);
        me->SetEmoteState(EMOTE_ONESHOT_NONE);
    }

    void IsSummonedBy(WorldObject*) override
    {
        if (Player* player = me->SelectNearestPlayer(60.0f))
            AttackStart(player);
    }

    void JustSummoned(Creature* summon) override { _summons.Summon(summon); }
    void SummonedCreatureDespawn(Creature* summon) override { _summons.Despawn(summon); }
    void JustDied(Unit*) override { _summons.DespawnAll(); }

    void EnterEvadeMode(EvadeReason why) override
    {
        _summons.DespawnAll();
        ScriptedAI::EnterEvadeMode(why);
    }

    void JustEngagedWith(Unit*) override
    {
        if (_rotationStarted)
            return;
        _rotationStarted = true;
        me->SetEmoteState(Emote(EMOTE_STATE_READY2HL_MOVE_ID));
        scheduler.Schedule(8s, [this](TaskContext context)
        {
            if (_busy || me->HasUnitState(UNIT_STATE_CASTING) || !me->GetVictim())
            {
                context.Repeat(1s);
                return;
            }
            if (_rotation.empty())
            {
                _rotation = { 0, 1, 2 };
                Acore::Containers::RandomShuffle(_rotation);
            }
            uint8 const next = _rotation.back();
            _rotation.pop_back();
            switch (next)
            {
                case 0: GlacialCleave(); break;
                case 1: FrozenGround(); break;
                default: FrostNovaPulse(); break;
            }
            context.Repeat(15s);
        });
    }

    void UpdateAI(uint32 diff) override
    {
        if (!_busy && !UpdateVictim())
            return;
        scheduler.Update(diff);
        if (!_busy && !me->HasUnitState(UNIT_STATE_CASTING))
            Melee2H();
    }

private:
    void GlacialCleave()
    {
        Unit* victim = me->GetVictim();
        _busy = true;
        HoldStill();
        Talk(SAY_HERALD_CLEAVE);
        me->SetFacingToObject(victim);
        me->SetTarget();
        float const o = me->GetOrientation();

        Position charge = me->GetNearPosition(1.5f, 0.0f);
        charge.m_positionZ = me->GetPositionZ() + 2.5f;
        if (Creature* precast = me->SummonCreature(NPC_RAY_PRECAST, charge, TEMPSUMMON_TIMED_DESPAWN, RAY_CHARGE_MS + 800))
        {
            precast->SetFacingTo(o);
            ObjectGuid const precastGuid = precast->GetGUID();
            scheduler.Schedule(Milliseconds(RAY_CHARGE_MS), [this, precastGuid](TaskContext)
            {
                if (Creature* c = ObjectAccessor::GetCreature(*me, precastGuid))
                {
                    c->HandleEmoteCommand(EMOTE_ONESHOT_DECAY_ID);
                    c->DespawnOrUnsummon(600ms);
                }
            });
        }

        scheduler.Schedule(Milliseconds(RAY_CHARGE_MS), [this, o](TaskContext)
        {
            Position origin = me->GetPosition();
            origin.m_positionZ += 1.5f;
            origin.SetOrientation(o);
            if (Creature* beam = me->SummonCreature(NPC_RAY_BEAM, origin, TEMPSUMMON_TIMED_DESPAWN, RAY_BEAM_MS + 1500))
            {
                beam->SetFacingTo(o);
                ObjectGuid const beamGuid = beam->GetGUID();
                scheduler.Schedule(Milliseconds(RAY_BEAM_MS), [this, beamGuid](TaskContext)
                {
                    if (Creature* b = ObjectAccessor::GetCreature(*me, beamGuid))
                    {
                        b->HandleEmoteCommand(EMOTE_ONESHOT_DECAY_ID);
                        b->DespawnOrUnsummon(900ms);
                    }
                });
            }
            float const c = std::cos(o), sn = std::sin(o);
            for (auto const& ref : me->GetMap()->GetPlayers())
            {
                Player* player = ref.GetSource();
                if (!player || !player->IsAlive() || player->IsGameMaster() || !me->InSamePhase(player))
                    continue;
                float const dx = player->GetPositionX() - me->GetPositionX();
                float const dy = player->GetPositionY() - me->GetPositionY();
                float const along = dx * c + dy * sn;
                float const side = -dx * sn + dy * c;
                if (along >= 0.0f && along <= RAY_LENGTH && std::fabs(side) <= RAY_HALF_WIDTH &&
                    std::fabs(player->GetPositionZ() - me->GetPositionZ()) < 8.0f)
                    FrostHit(me, player, RAY_DAMAGE_PCT, true);
            }
        });
        scheduler.Schedule(Milliseconds(RAY_CHARGE_MS + RAY_BEAM_MS), [this](TaskContext) { Resume(); });
    }

    void FrozenGround()
    {
        Player* target = me->GetVictim() ? me->GetVictim()->ToPlayer() : nullptr;
        if (!target)
            return;
        Talk(SAY_HERALD_GROUND, target);
        Position floor = target->GetPosition();
        floor.m_positionZ += 0.3f;
        me->SummonCreature(NPC_FROZEN_GROUND, floor, TEMPSUMMON_TIMED_DESPAWN, GROUND_LIFETIME_MS + 2000);
    }

    void FrostNovaPulse()
    {
        _busy = true;
        HoldStill();
        Talk(SAY_HERALD_NOVA);
        me->SetTarget();
        ObjectGuid ring;
        if (Creature* r = me->SummonCreature(NPC_NOVA_RING, me->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, NOVA_WARN_MS + 2000))
            ring = r->GetGUID();
        scheduler.Schedule(500ms, [this, ring](TaskContext)
        {
            if (Creature* r = ObjectAccessor::GetCreature(*me, ring))
                r->SetEmoteState(Emote(EMOTE_SPELLEFFECT_HOLD_ID));
        });
        scheduler.Schedule(Milliseconds(NOVA_WARN_MS), [this, ring](TaskContext)
        {
            int32 const bp0 = NOVA_BP;
            me->CastCustomSpell(nullptr, SPELL_FROST_NOVA, &bp0, nullptr, nullptr, true);
            for (auto const& ref : me->GetMap()->GetPlayers())
                if (Player* player = ref.GetSource(); player && me->IsWithinDist(player, NOVA_RANGE))
                    if (Aura* root = player->GetAura(SPELL_FROST_NOVA, me->GetGUID()))
                        root->SetDuration(ROOT_MS);
            if (Creature* r = ObjectAccessor::GetCreature(*me, ring))
            {
                r->HandleEmoteCommand(EMOTE_ONESHOT_DECAY_ID);
                r->DespawnOrUnsummon(850ms);
            }
            Resume();
        });
    }

    void Melee2H()
    {
        Unit* victim = me->GetVictim();
        if (!victim || !me->isAttackReady() || !me->IsWithinMeleeRange(victim))
            return;
        me->AttackerStateUpdate(victim);
        me->resetAttackTimer();
        me->HandleEmoteCommand(EMOTE_ONESHOT_ATTACK2HL_ID);
    }

    void HoldStill()
    {
        me->GetMotionMaster()->Clear();
        me->StopMoving();
        me->SetControlled(true, UNIT_STATE_ROOT);
        me->SetEmoteState(EMOTE_ONESHOT_NONE);
    }

    void Resume()
    {
        me->SetControlled(false, UNIT_STATE_ROOT);
        me->SetEmoteState(Emote(EMOTE_STATE_READY2HL_MOVE_ID));
        _busy = false;
        if (Unit* v = me->GetVictim())
        {
            me->SetTarget(v->GetGUID());
            me->GetMotionMaster()->MoveChase(v);
        }
    }

    SummonList _summons;
    bool _busy = false;
    bool _rotationStarted = false;
    std::vector<uint8> _rotation;
};

struct npc_wisdomball_frozen_ground : public ScriptedAI
{
    explicit npc_wisdomball_frozen_ground(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
        scheduler.Schedule(500ms, [this](TaskContext) { me->SetEmoteState(Emote(EMOTE_SPELLEFFECT_HOLD_ID)); });
        scheduler.Schedule(Milliseconds(GROUND_ARM_MS), [this](TaskContext context)
        {
            for (auto const& ref : me->GetMap()->GetPlayers())
                if (Player* player = ref.GetSource(); player && player->IsAlive() && !player->IsGameMaster() &&
                    me->InSamePhase(player) && me->IsWithinDist(player, GROUND_REACH))
                    FrostHit(me, player, GROUND_DAMAGE_PCT, true);
            context.Repeat(1s);
        });
        scheduler.Schedule(Milliseconds(GROUND_LIFETIME_MS), [this](TaskContext)
        {
            scheduler.CancelAll();
            me->HandleEmoteCommand(EMOTE_ONESHOT_DECAY_ID);
            me->DespawnOrUnsummon(850ms);
        });
    }

    void EnterEvadeMode(EvadeReason ) override { }

    void UpdateAI(uint32 diff) override
    {
        scheduler.Update(diff);
    }
};

struct npc_wisdomball_frost_orb : public ScriptedAI
{
    explicit npc_wisdomball_frost_orb(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
        me->SetDisableGravity(true);
        scheduler.Schedule(250ms, [this](TaskContext context)
        {
            for (auto const& ref : me->GetMap()->GetPlayers())
                if (Player* player = ref.GetSource(); player && player->IsAlive() && !player->IsGameMaster() &&
                    me->InSamePhase(player) && me->GetExactDist2d(player) <= ORB_REACH &&
                    std::fabs(player->GetPositionZ() - me->GetPositionZ()) < 4.0f)
                {
                    FrostHit(me, player, ORB_DAMAGE_PCT, false);
                    if (player->IsAlive())
                        if (Aura* root = me->AddAura(SPELL_FROST_NOVA, player))
                            root->SetDuration(ROOT_MS);
                    Burst();
                    return;
                }
            context.Repeat();
        });
        scheduler.Schedule(Milliseconds(ORB_LIFETIME_MS), [this](TaskContext) { Burst(); });
    }

    void EnterEvadeMode(EvadeReason ) override { }

    void UpdateAI(uint32 diff) override
    {
        scheduler.Update(diff);
    }

private:
    void Burst()
    {
        scheduler.CancelAll();
        me->GetMotionMaster()->Clear();
        me->StopMoving();
        me->HandleEmoteCommand(EMOTE_ONESHOT_DECAY_ID);
        me->DespawnOrUnsummon(600ms);
    }
};

void AddSC_wisdomball_velthessa()
{
    RegisterCreatureAI(npc_wisdomball_velthessa);
    RegisterCreatureAI(npc_wisdomball_blistering_tornado);
    RegisterCreatureAI(npc_wisdomball_herald);
    RegisterCreatureAI(npc_wisdomball_frozen_ground);
    RegisterCreatureAI(npc_wisdomball_frost_orb);
}
