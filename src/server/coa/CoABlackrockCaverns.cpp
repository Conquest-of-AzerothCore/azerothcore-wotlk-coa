/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAOtherSideDamage.h"
#include "CellImpl.h"
#include "Containers.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Creature.h"
#include "InstanceMapScript.h"
#include "InstanceScript.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectMgr.h"
#include "ObjectAccessor.h"
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
#include "TemporarySummon.h"
#include <algorithm>
#include <array>
#include <set>
#include <cmath>
#include <unordered_map>
#include <vector>

namespace
{
enum BrcData : uint32
{
    MAP_BLACKROCK_CAVERNS = 645,

    DATA_ROMOGG = 0,
    DATA_CORLA = 1,
    DATA_KARSH = 2,
    DATA_BEAUTY = 3,
    DATA_OBSIDIUS = 4,
    ENCOUNTER_COUNT = 5,
    DATA_RAZ = 5,

    PERSISTENT_RAZ_STAGE = 0,
    PERSISTENT_OBSIDIUS_FREED = 1,
    PERSISTENT_COUNT = 2,

    RAZ_CAGED = 0,
    RAZ_FREED = 1,
    RAZ_CORLA = 2,
    RAZ_OBSIDIUS = 3,

    NPC_ROMOGG = 39665,
    NPC_FIRE_ZONE = 15214,
    NPC_FIRE_ZONE_RING = 5011006,
    NPC_FIRE_ZONE_FILL = 5011007,
    NPC_RAZ = 39670,
    NPC_CORLA = 39679,
    NPC_KARSH = 39698,
    NPC_BEAUTY = 39700,
    NPC_OBSIDIUS = 39705,
    NPC_INVISIBLE_STALKER = 39842,
    NPC_TWILIGHT_TORTURER = 39978,
    NPC_TWILIGHT_SADIST = 39980,
    NPC_CRAZED_MAGE = 39982,
    NPC_MAD_PRISONER = 39985,
    NPC_EVOLVED_ZEALOT = 39987,
    NPC_TWILIGHT_ZEALOT = 39990,
    NPC_TWILIGHT_FLAME_CALLER = 39708,
    NPC_CONFLAGRATION = 39994,
    NPC_QUICKSILVER = 40004,
    NPC_TWILIGHT_ELEMENT_WARDEN = 40017,
    NPC_CHANNEL_TARGET = 40343,
    NPC_LUCKY = 40008,
    NPC_SPOT = 40011,
    NPC_RUNTY = 40015,
    NPC_CHAINS_OF_WOE = 40447,
    NPC_SHADOW_OF_OBSIDIUS = 40817,
    NPC_KNEELING_ZEALOT = 50284,
    NPC_ANGERED_EARTH = 50376,
    NPC_NETHER_BEAM = 5011005,

    SPELL_FIERCE_BLOW = 975011,
    SPELL_QUAKE = 5011000,
    SPELL_CALL_FOR_HELP = 5011001,
    SPELL_SKULLCRACKER = 5011002,
    SPELL_SKULLCRACKER_MYTHIC = 5011003,
    SPELL_WOUNDING_STRIKE = 5011008,
    SPELL_CHAINS_OF_WOE = 5011009,
    SPELL_CHAINS_OF_WOE_ROOT = 5011010,
    SPELL_CHAINS_OF_WOE_VISUAL = 5011012,
    SPELL_LAVA_POOL = 5011153,
    SPELL_BERSERKER_CHARGE = 76030,
    SPELL_MAGMA_SPIT = 76031,
    SPELL_FLAMEBREAK = 76032,
    SPELL_DARK_COMMAND = 75823,
    SPELL_FEAR = 12096,
    SPELL_TRANSFORMATION_SCALE = 5011095,
    DISPLAY_KARSH_MOLTEN = 36675,
    SPELL_FIRE_CHANNELING = 5011013,
    SPELL_FIRE_BEAM = 5011067,
    SPELL_COOLED = 5011114,
    SPELL_INCINERATE_VISUAL = 43971,
    SPELL_FURIOUS_RAGE = 5011123,
    SPELL_INFLICT_PAIN = 5011030,
    SPELL_AURA_OF_ARCANE_HASTE = 5011052,
    SPELL_ENRAGE = 5011025,
    SPELL_AURA_OF_ACCELERATION = 5011065,
    SPELL_NETHER_BEAM = 5011068,
    SPELL_EVOLUTION_STACK = 5011069,
    SPELL_TWILIGHT_EVOLUTION = 5011070,
    SPELL_KNEELING = 5011071,
    SPELL_EVOLUTION_EVOLVED = 5011072,
    SPELL_CORLA_EVOLUTION = 75610,
    SPELL_DRAIN_ESSENCE = 75645,
    SPELL_BERSERK = 5011079,
    SPELL_TERRIFYING_ROAR = 5011083,
    SPELL_LITTLE_BIG_FLAME_BREATH = 5011085,
    SPELL_STONE_BLOW = 5011088,
    SPELL_THUNDERCLAP = 5011089,
    SPELL_SHADOWY_CORRUPTION = 5011090,
    SPELL_TWITCHY = 5011091,
    SPELL_TRANSFORMATION_UNATTACKABLE = 5011096,
    SPELL_TRANSFORMATION_STUN = 5011097,
    SPELL_QUICKSILVER_ARMOR = 5011100,
    SPELL_SUPERHEATED_ARMOR = 5011102,
    SPELL_HEAT_WAVE = 5011103,
    SPELL_CLEAVE = 5011104,
    SPELL_HIGH_SECURITY_SHADOW_PRISON = 5011121,
    SPELL_FURIOUS_SWIPE = 5011122,
    SPELL_CREPUSCULAR_VEIL = 5011188,
    SPELL_SHADOW_OF_OBSIDIUS = 5011189,
    SPELL_STOP_HEART = 82393,
    SPELL_TWILIGHT_CORRUPTION = 21068,
    SPELL_SHADOW_TETHER = 992765,
    SPELL_FIRE_ZONE_RING = 993011,
    SPELL_FIRE_ZONE_FILL = 256947,
    SPELL_LOBBED_FIREBALL = 29473,

    SAY_ROMOGG_AGGRO = 0,
    SAY_ROMOGG_SLAY = 1,
    SAY_ROMOGG_CHAINS = 2,
    SAY_ROMOGG_DEATH = 3,
    EMOTE_ROMOGG_CALL_FOR_HELP = 4,
    EMOTE_ROMOGG_SKULLCRACKER = 5,

    SAY_RAZ_SMASH = 0,
    SAY_RAZ_TIRED = 1,

    SAY_CORLA_AGGRO = 0,
    SAY_CORLA_SLAY = 1,
    SAY_CORLA_EVOLUTION = 2,
    SAY_CORLA_DEATH = 3,
    EMOTE_CORLA_ZEALOT_EVOLVED = 4,

    SAY_KARSH_AGGRO = 0,
    SAY_KARSH_SLAY = 1,
    SAY_KARSH_SUPERHEATED = 2,
    SAY_KARSH_DEATH = 3,
    EMOTE_KARSH_SUPERHEATED = 4,

    SAY_OBSIDIUS_AGGRO = 0,
    SAY_OBSIDIUS_SLAY = 1,
    SAY_OBSIDIUS_TRANSFORMATION = 2,
    SAY_OBSIDIUS_DEATH = 3,
    EMOTE_OBSIDIUS_TRANSFORMATION = 4,

    SOUND_BEAUTY_AGGRO = 18559,
    SOUND_BEAUTY_DEATH = 18563,

    ACTION_RAZ_BREAK_OUT = 1,
    ACTION_OBSIDIUS_FREE = 2,
    ACTION_ZEALOT_EVOLVE = 3,
    ACTION_BEAM_START = 4,
    ACTION_LAVA_SPOUT = 5,

    DISPLAY_MOLTEN_QUICKSILVER = 33011,
    POINT_RAZ_OBSIDIUS_JUMP = 100,
    POINT_RAZ_LEDGE_JUMP = 101,
};

ObjectData const CreatureData[] =
{
    { NPC_ROMOGG, DATA_ROMOGG },
    { NPC_CORLA, DATA_CORLA },
    { NPC_KARSH, DATA_KARSH },
    { NPC_BEAUTY, DATA_BEAUTY },
    { NPC_OBSIDIUS, DATA_OBSIDIUS },
    { NPC_RAZ, DATA_RAZ },
    { 0, 0 }
};

Position const RazCagePos = { 249.2639f, 949.1614f, 191.7866f, 3.141593f };
Position const RazCorlaPos = { 411.7285f, 816.6429f, 103.4983f, 3.153806f };
Position const RazLedgePos = { 406.1927f, 906.0121f, 163.4926f, 4.310963f };
Position const RazObsidiusPos = { 308.9653f, 635.8195f, 64.79769f, 4.555309f };
Position const RazBridgePos = { 400.9f, 821.1f, 106.5f };
Position const ObsidiusPos = { 331.7f, 554.5f, 66.1f };
Position const RazObsidiusStandPos = { 330.5491f, 559.3794f, 66.00645f, 4.945502f };

std::array<Position, 12> const RazPathRomogg =
{ {
    { 208.311f, 946.102f, 191.0072f }, { 216.6545f, 913.2952f, 190.9795f }, { 230.5486f, 910.7917f, 191.057f },
    { 242.2326f, 905.5382f, 190.97f }, { 255.8333f, 910.5886f, 191.0629f }, { 268.3038f, 918.5191f, 190.9722f },
    { 288.9861f, 949.3038f, 190.8299f }, { 314.5087f, 949.7239f, 191.1788f }, { 345.4254f, 948.5174f, 190.9669f },
    { 375.7309f, 949.0417f, 192.2794f }, { 398.0313f, 945.6302f, 193.3367f }, { 470.9601f, 905.092f, 165.8345f }
} };
std::array<Position, 3> const RazPathCorla =
{ {
    { 380.6f, 817.2f, 104.4f }, { 356.0f, 820.0f, 105.0f }, { 340.754f, 817.0031f, 103.4613f }
} };

std::array<Position, 3> const CorlaZealotPos =
{ {
    { 585.0278f, 982.8993f, 155.4369f, 1.500983f },
    { 561.9618f, 983.0191f, 155.4369f, 1.553343f },
    { 573.4844f, 978.5851f, 155.4369f, 1.570796f }
} };

Position const LavaFountainPos = { 237.2951f, 784.7761f, 95.99241f };

Position const LuckyPos = { 116.337f, 567.625f, 76.4501f, 3.49996f };
Position const SpotPos = { 124.778f, 577.594f, 76.425f, 6.00992f };
Position const RuntyPos = { 84.4645f, 612.958f, 76.8778f, 0.0431063f };

std::array<Position, 3> const ShadowOfObsidiusPos =
{ {
    { 331.6267f, 563.5573f, 66.08982f, 3.141593f },
    { 332.2361f, 544.75f, 66.08982f, 3.141593f },
    { 324.6545f, 554.1979f, 66.10867f, 3.141593f }
} };

struct Damage2
{
    uint32 normal60, mythic;
};

std::unordered_map<uint32, Damage2> const Damages =
{
    { 5011028, { 439, 665 } },
    { 5011064, { 262, 312 } },
    { 5011055, { 59, 76 } },
    { 5011085, { 125, 208 } },
    { 5011063, { 5, 13 } },
    { 5011089, { 100, 133 } },
    { 5011153, { 150, 240 } },
};

Damage2 const MagmaSpitDamage = { 450, 720 };
Damage2 const BerserkerChargeDamage = { 400, 650 };
Damage2 const FlamebreakDamage = { 350, 560 };
Damage2 const DarkCommandDamage = { 800, 1280 };
Damage2 const TwilightCorruptionTick = { 240, 400 };
Damage2 const BurningMetalPerStack = { 60, 96 };
Damage2 const LavaSpoutDamage = { 900, 1450 };
constexpr float LavaGrateRadius = 10.0f;
constexpr float ShadowSpeedRate = 0.3f;
constexpr float FireZoneRadius = 4.0f;
constexpr uint32 FireZoneEveryMs = 2000;
constexpr float FireZoneJitter = 0.5f;
constexpr float FireZoneSpread = 3.0f;
constexpr uint32 FireZoneMs = 2500;
constexpr uint32 FireZoneCallers = 2;
constexpr float RazDamageBonus = 1.3f;

constexpr float HeatWavePerStack = 57.6f;
constexpr float HeatWaveBaseStacks = 2.33f;

bool IsHeroicOrMythic(Map const* map)
{
    return map->GetDifficulty() == DUNGEON_DIFFICULTY_HEROIC || map->GetDifficulty() == DUNGEON_DIFFICULTY_EPIC;
}

float Logged(Unit const* attacker, Unit const* target, float normal60, float mythic, SpellInfo const* spell)
{
    switch (attacker->GetMap()->GetDifficulty())
    {
        case DUNGEON_DIFFICULTY_EPIC:
            return mythic;
        case DUNGEON_DIFFICULTY_HEROIC:
            return mythic / 1.3f;
        default:
            return CoAOtherSide::Unscaled(attacker, target, normal60, spell);
    }
}

int32 Rolled(Unit const* attacker, Unit const* target, float normal60, float mythic, SpellInfo const* spell)
{
    return std::max(1, int32(Logged(attacker, target, normal60, mythic, spell) * frand(0.9f, 1.1f)));
}

void DealDamage(
    Unit* caster, Unit* target, uint32 spellId, uint32 value, SpellSchoolMask school = SPELL_SCHOOL_MASK_NONE)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    if (!info || !value)
        return;
    SpellNonMeleeDamage damage(caster, target, info, school != SPELL_SCHOOL_MASK_NONE ? school : info->GetSchoolMask());
    caster->CalculateSpellDamageTaken(&damage, int32(value), info);
    Unit::DealDamageMods(target, damage.damage, &damage.absorb);
    caster->DealSpellDamage(&damage, true);
    caster->SendSpellNonMeleeDamageLog(&damage);
}

std::vector<Player*> PlayersNear(WorldObject const* center, float range)
{
    std::vector<Player*> out;
    for (auto const& ref : center->GetMap()->GetPlayers())
        if (Player* player = ref.GetSource())
            if (player->IsAlive() && !player->IsGameMaster() && center->GetExactDist(player) <= range)
                out.push_back(player);
    return out;
}

class instance_coa_blackrock_caverns : public InstanceMapScript
{
public:
    instance_coa_blackrock_caverns() : InstanceMapScript("instance_coa_blackrock_caverns", MAP_BLACKROCK_CAVERNS) { }

    struct instance_coa_blackrock_caverns_InstanceMapScript : public InstanceScript
    {
        explicit instance_coa_blackrock_caverns_InstanceMapScript(Map* map) : InstanceScript(map) { }

        void Initialize() override
        {
            SetHeaders("BRC");
            SetBossNumber(ENCOUNTER_COUNT);
            SetPersistentDataCount(PERSISTENT_COUNT);
            LoadObjectData(CreatureData, nullptr);
            scheduler.Schedule(1s, [this](TaskContext context)
            {
                AdvanceRaz();
                context.Repeat();
            });
        }

        bool SetBossState(uint32 type, EncounterState state) override
        {
            if (!InstanceScript::SetBossState(type, state))
                return false;
            if (type == DATA_ROMOGG && state == DONE && GetPersistentData(PERSISTENT_RAZ_STAGE) == RAZ_CAGED)
            {
                StorePersistentData(PERSISTENT_RAZ_STAGE, RAZ_FREED);
                if (Creature* raz = GetCreature(DATA_RAZ))
                    raz->AI()->DoAction(ACTION_RAZ_BREAK_OUT);
            }
            return true;
        }

        void AdvanceRaz()
        {
            if (instance->GetPlayers().IsEmpty())
                return;

            uint32 const stage = GetPersistentData(PERSISTENT_RAZ_STAGE);
            if (stage == RAZ_CAGED && !_cageSummoned)
            {
                _cageSummoned = true;
                if (GetBossState(DATA_ROMOGG) == DONE)
                    StorePersistentData(PERSISTENT_RAZ_STAGE, RAZ_FREED);
                else
                    instance->SummonCreature(NPC_RAZ, RazCagePos);
                return;
            }
            if (stage <= RAZ_FREED && GetBossState(DATA_CORLA) == DONE &&
                (PlayerNear(RazCorlaPos, 35.0f) || PlayerNear(RazBridgePos, 45.0f)))
            {
                StorePersistentData(PERSISTENT_RAZ_STAGE, RAZ_CORLA);
                instance->SummonCreature(NPC_RAZ, RazLedgePos);
                return;
            }
            if (stage <= RAZ_CORLA && GetBossState(DATA_KARSH) == DONE &&
                (PlayerNear(RazObsidiusPos, 60.0f) || PlayerNear(ObsidiusPos, 70.0f)))
            {
                StorePersistentData(PERSISTENT_RAZ_STAGE, RAZ_OBSIDIUS);
                instance->SummonCreature(NPC_RAZ, RazObsidiusPos);
                ArmObsidiusRelease();
                return;
            }
            if (stage == RAZ_OBSIDIUS && !_freeArmed && !GetPersistentData(PERSISTENT_OBSIDIUS_FREED))
                ArmObsidiusRelease();
        }

        void ArmObsidiusRelease()
        {
            _freeArmed = true;
            scheduler.Schedule(120s, [this](TaskContext context)
            {
                if (GetPersistentData(PERSISTENT_OBSIDIUS_FREED))
                    return;
                Creature* obsidius = GetCreature(DATA_OBSIDIUS);
                if (!obsidius || instance->GetPlayers().IsEmpty())
                {
                    context.Repeat(1s);
                    return;
                }
                obsidius->AI()->DoAction(ACTION_OBSIDIUS_FREE);
            });
        }

        bool PlayerNear(Position const& pos, float range) const
        {
            for (auto const& ref : instance->GetPlayers())
                if (Player* player = ref.GetSource())
                    if (player->IsAlive() && !player->IsGameMaster() && player->GetExactDist(&pos) <= range)
                        return true;
            return false;
        }

    private:
        bool _freeArmed = false;
        bool _cageSummoned = false;
    };

    InstanceScript* GetInstanceScript(InstanceMap* map) const override
    {
        return new instance_coa_blackrock_caverns_InstanceMapScript(map);
    }
};

struct boss_coa_brc_romogg : public BossAI
{
    explicit boss_coa_brc_romogg(Creature* creature) : BossAI(creature, DATA_ROMOGG) { }

    enum Events : uint32
    {
        EVENT_WOUNDING_STRIKE = 1,
        EVENT_QUAKE,
        EVENT_CHAINS,
        EVENT_SKULLCRACKER,
        EVENT_CHAINS_CHECK,
        EVENT_FIERCE_BLOW,
    };

    void Reset() override
    {
        _Reset();
        me->SetReactState(REACT_AGGRESSIVE);
        _chains.Clear();
    }

    void JustEngagedWith(Unit* who) override
    {
        BossAI::JustEngagedWith(who);
        Talk(SAY_ROMOGG_AGGRO);
        Talk(EMOTE_ROMOGG_CALL_FOR_HELP);
        DoCastSelf(SPELL_CALL_FOR_HELP);
        me->CallForHelp(35.0f, who);
        events.ScheduleEvent(EVENT_WOUNDING_STRIKE, 6s);
        events.ScheduleEvent(EVENT_QUAKE, 11s);
        events.ScheduleEvent(EVENT_CHAINS, 27s);
        events.ScheduleEvent(EVENT_FIERCE_BLOW, 8500ms);
    }

    void KilledUnit(Unit* victim) override
    {
        if (victim->IsPlayer())
            Talk(SAY_ROMOGG_SLAY);
    }

    void JustDied(Unit* killer) override
    {
        BossAI::JustDied(killer);
        Talk(SAY_ROMOGG_DEATH);
    }

    void JustSummoned(Creature* summon) override
    {
        BossAI::JustSummoned(summon);
        if (summon->GetEntry() == NPC_CHAINS_OF_WOE)
            _chains = summon->GetGUID();
        else if (summon->GetEntry() == NPC_ANGERED_EARTH)
        {
            summon->SetCorpseDelay(5);
            summon->AI()->DoZoneInCombat();
        }
    }

    void OnSpellCast(SpellInfo const* spell) override
    {
        BossAI::OnSpellCast(spell);
        switch (spell->Id)
        {
            case SPELL_QUAKE:
                for (Player* player : PlayersNear(me, 80.0f))
                {
                    Position pos = player->GetNearPosition(3.0f, frand(0.0f, 2.0f * float(M_PI)));
                    me->SummonCreature(NPC_ANGERED_EARTH, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 5000);
                }
                break;
            case SPELL_SKULLCRACKER:
            case SPELL_SKULLCRACKER_MYTHIC:
            {
                for (Player* player : PlayersNear(me, 200.0f))
                    if (player->HasAura(SPELL_CHAINS_OF_WOE_ROOT))
                        DealDamage(me, player, spell->Id, player->GetMaxHealth() * 10, SPELL_SCHOOL_MASK_NORMAL);
                me->SetReactState(REACT_AGGRESSIVE);
                break;
            }
            default:
                break;
        }
    }

    void OnSpellFailed(SpellInfo const* spell) override
    {
        if (spell->Id == SPELL_SKULLCRACKER || spell->Id == SPELL_SKULLCRACKER_MYTHIC)
            me->SetReactState(REACT_AGGRESSIVE);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        events.Update(diff);
        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_WOUNDING_STRIKE:
                    DoCastVictim(SPELL_WOUNDING_STRIKE);
                    events.Repeat(15s);
                    break;
                case EVENT_QUAKE:
                    DoCastSelf(SPELL_QUAKE);
                    events.Repeat(17s);
                    break;
                case EVENT_CHAINS:
                    Talk(SAY_ROMOGG_CHAINS);
                    me->AttackStop();
                    me->SetReactState(REACT_PASSIVE);
                    DoCastSelf(SPELL_CHAINS_OF_WOE);
                    events.ScheduleEvent(EVENT_CHAINS_CHECK, 3500ms);
                    events.ScheduleEvent(EVENT_SKULLCRACKER, 4s);
                    events.Repeat(32s);
                    break;
                case EVENT_CHAINS_CHECK:
                    if (!ObjectAccessor::GetCreature(*me, _chains))
                        me->SummonCreature(NPC_CHAINS_OF_WOE, me->GetNearPosition(4.0f, 0.0f),
                            TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT, 20000);
                    break;
                case EVENT_SKULLCRACKER:
                    Talk(EMOTE_ROMOGG_SKULLCRACKER);
                    if (DoCastSelf(me->GetMap()->GetDifficulty() == DUNGEON_DIFFICULTY_EPIC
                                       ? SPELL_SKULLCRACKER_MYTHIC
                                       : SPELL_SKULLCRACKER) != SPELL_CAST_OK)
                        me->SetReactState(REACT_AGGRESSIVE);
                    break;
                case EVENT_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    events.Repeat(10s);
                    break;
                default:
                    break;
            }
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
        }

        if (me->GetReactState() != REACT_PASSIVE)
            DoMeleeAttackIfReady();
    }

private:
    ObjectGuid _chains;
};

struct npc_coa_brc_chains_of_woe : public ScriptedAI
{
    explicit npc_coa_brc_chains_of_woe(Creature* creature) : ScriptedAI(creature) { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        me->SetReactState(REACT_PASSIVE);
        me->SetControlled(true, UNIT_STATE_ROOT);
        if (Unit* romogg = summoner ? summoner->ToUnit() : nullptr)
        {
            me->SetMaxHealth(std::max<uint32>(1, uint32(romogg->GetMaxHealth() * 0.0555f)));
            me->SetFullHealth();
        }
        DoCastSelf(SPELL_CHAINS_OF_WOE_VISUAL, true);
        WorldObject* center = summoner ? summoner : me;
        for (Player* player : PlayersNear(center, 60.0f))
        {
            Position pos = me->GetNearPosition(frand(1.5f, 3.0f), frand(0.0f, 2.0f * float(M_PI)));
            player->NearTeleportTo(
                pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), player->GetOrientation());
        }
        DoCastSelf(SPELL_CHAINS_OF_WOE_ROOT, true);
    }

    void AttackStart(Unit* ) override { }
    void UpdateAI(uint32 ) override { }
};

struct npc_coa_brc_raz : public ScriptedAI
{
    explicit npc_coa_brc_raz(Creature* creature) : ScriptedAI(creature), _instance(creature->GetInstanceScript()) { }

    enum Events : uint32
    {
        EVENT_SMASH = 1,
        EVENT_ACTIVATE,
        EVENT_JUMP_OBSIDIUS,
        EVENT_DIE,
        EVENT_SWIPE,
        EVENT_FIERCE_BLOW,
        EVENT_RAGE,
        EVENT_LEAP_LEDGE,
        EVENT_DRIVE,
    };

    void IsSummonedBy(WorldObject* ) override
    {
        Init();
    }

    void DoAction(int32 action) override
    {
        if (action != ACTION_RAZ_BREAK_OUT)
            return;
        Init();
        me->RemoveAurasDueToSpell(SPELL_HIGH_SECURITY_SHADOW_PRISON);
        me->SetDisableGravity(false);
        me->SetHover(false);
        me->SetImmuneToAll(false);
        me->SetReactState(REACT_AGGRESSIVE);
        me->GetMotionMaster()->MoveJump(RazPathRomogg[0], 20.0f, 10.0f);
        _point = 1;
        _events.ScheduleEvent(EVENT_SMASH, 3s);
        _events.ScheduleEvent(EVENT_ACTIVATE, 4s);
    }

    void JustEngagedWith(Unit* ) override
    {
        _walking = false;
        _events.ScheduleEvent(EVENT_SWIPE, 1s);
        _events.ScheduleEvent(EVENT_FIERCE_BLOW, 15s);
    }

    void EnterEvadeMode(EvadeReason ) override
    {
        me->CombatStop(true);
        me->GetThreatMgr().ClearAllThreat();
        _walking = false;
        _events.CancelEvent(EVENT_SWIPE);
        _events.CancelEvent(EVENT_FIERCE_BLOW);
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type == EFFECT_MOTION_TYPE && id == POINT_RAZ_LEDGE_JUMP)
        {
            DoCastSelf(SPELL_QUAKE, true);
            _events.ScheduleEvent(EVENT_ACTIVATE, 1s);
            return;
        }
        if (type == EFFECT_MOTION_TYPE && id == POINT_RAZ_OBSIDIUS_JUMP)
        {
            me->SetReactState(REACT_AGGRESSIVE);
            _point = 0;
            _walking = false;
            _active = true;
            return;
        }
        if ((type != POINT_MOTION_TYPE && type != EFFECT_MOTION_TYPE) || id != _point + 1)
            return;
        ++_point;
        _walking = false;
    }

    void SpellHit(Unit* , SpellInfo const* spell) override
    {
        if (spell->Id == SPELL_STOP_HEART)
            _events.ScheduleEvent(EVENT_DIE, 1s);
    }

    void DamageDealt(Unit* victim, uint32& damage, DamageEffectType , SpellSchoolMask ) override
    {
        if (victim && !victim->IsPlayer())
            damage = uint32(damage * RazDamageBonus);
    }

    void UpdateAI(uint32 diff) override
    {
        Init();
        _events.Update(diff);
        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_SMASH:
                    Talk(SAY_RAZ_SMASH);
                    break;
                case EVENT_ACTIVATE:
                    _active = true;
                    break;
                case EVENT_JUMP_OBSIDIUS:
                    Talk(SAY_RAZ_SMASH);
                    if (_instance && _instance->GetCreature(DATA_OBSIDIUS))
                    {
                        _path = { RazObsidiusStandPos };
                        _atObsidius = true;
                        me->GetMotionMaster()->MoveJump(RazObsidiusStandPos, 18.0f, 30.0f, POINT_RAZ_OBSIDIUS_JUMP);
                    }
                    else
                        _events.ScheduleEvent(EVENT_DIE, 4s);
                    break;
                case EVENT_RAGE:
                    DoCastSelf(SPELL_FURIOUS_RAGE, true);
                    _events.Repeat(25s);
                    break;
                case EVENT_LEAP_LEDGE:
                    Talk(SAY_RAZ_SMASH);
                    me->GetMotionMaster()->MoveJump(RazCorlaPos, 35.0f, 12.0f, POINT_RAZ_LEDGE_JUMP);
                    break;
                case EVENT_DIE:
                    Talk(SAY_RAZ_TIRED);
                    me->KillSelf();
                    me->DespawnOrUnsummon(9s);
                    return;
                case EVENT_SWIPE:
                    if (me->GetVictim())
                        DoCastVictim(SPELL_FURIOUS_SWIPE);
                    _events.Repeat(1200ms);
                    break;
                case EVENT_FIERCE_BLOW:
                    if (me->GetVictim())
                        DoCastVictim(SPELL_FIERCE_BLOW);
                    _events.Repeat(18s);
                    break;
                case EVENT_DRIVE:
                    if (!me->IsInCombat())
                        Drive();
                    _events.Repeat(500ms);
                    break;
                default:
                    break;
            }
        }

        if (me->IsInCombat() && UpdateVictim())
            DoMeleeAttackIfReady();
    }

private:
    void Drive()
    {
        if (!_active || !me->IsAlive())
            return;

        if (Unit* target = me->SelectNearestTarget(_atObsidius ? 40.0f : 25.0f))
            if (me->IsWithinLOSInMap(target))
            {
                _walking = false;
                AttackStart(target);
                return;
            }

        if (_point >= _path.size())
        {
            _active = false;
            if (_atObsidius)
                StandAtObsidius();
            else
                me->DespawnOrUnsummon(3s);
            return;
        }
        if (_walking)
            return;
        _walking = true;
        if (_jumps.count(_point))
            me->GetMotionMaster()->MoveJump(_path[_point], 30.0f, 15.0f, _point + 1);
        else
            me->GetMotionMaster()->MovePoint(_point + 1, _path[_point]);
    }

    void StandAtObsidius()
    {
        me->SetReactState(REACT_PASSIVE);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
        DoCastSelf(SPELL_FURIOUS_RAGE, true);
        _events.ScheduleEvent(EVENT_RAGE, 25s);
        if (Creature* obsidius = _instance ? _instance->GetCreature(DATA_OBSIDIUS) : nullptr)
        {
            me->SetFacingToObject(obsidius);
            obsidius->AI()->DoAction(ACTION_OBSIDIUS_FREE);
        }
    }

    void Init()
    {
        if (_initialized)
            return;
        _initialized = true;
        _events.ScheduleEvent(EVENT_DRIVE, 500ms);
        me->SetWalk(false);
        me->SetReactState(REACT_AGGRESSIVE);
        uint32 const stage = _instance ? _instance->GetPersistentData(PERSISTENT_RAZ_STAGE) : RAZ_CAGED;
        if (stage == RAZ_CAGED || stage == RAZ_FREED)
        {
            me->SetReactState(REACT_PASSIVE);
            me->SetImmuneToAll(true);
            me->SetDisableGravity(true);
            me->SetHover(true);
            DoCastSelf(SPELL_HIGH_SECURITY_SHADOW_PRISON, true);
            _path.assign(RazPathRomogg.begin(), RazPathRomogg.end());
            _jumps = { RazPathRomogg.size() - 1 };
        }
        else if (stage == RAZ_CORLA)
        {
            _path.assign(RazPathCorla.begin(), RazPathCorla.end());
            _jumps.clear();
            _events.ScheduleEvent(EVENT_LEAP_LEDGE, 1500ms);
        }
        else
        {
            me->SetReactState(REACT_PASSIVE);
            _events.ScheduleEvent(EVENT_JUMP_OBSIDIUS, 2s);
        }
    }

    InstanceScript* _instance;
    EventMap _events;
    std::vector<Position> _path;
    std::set<size_t> _jumps;
    uint32 _point = 0;
    bool _initialized = false;
    bool _active = false;
    bool _walking = false;
    bool _atObsidius = false;
};

struct boss_coa_brc_corla : public BossAI
{
    explicit boss_coa_brc_corla(Creature* creature) : BossAI(creature, DATA_CORLA) { }

    enum Events : uint32
    {
        EVENT_EVOLUTION_OOC = 1,
        EVENT_DRAIN_ESSENCE,
        EVENT_FIERCE_BLOW,
        EVENT_DARK_COMMAND,
        EVENT_VALIDATE,
    };

    void Reset() override
    {
        _Reset();
        _zealots.clear();
        _ooc.Reset();
        _ooc.ScheduleEvent(EVENT_EVOLUTION_OOC, 2s);
        _ooc.ScheduleEvent(EVENT_DRAIN_ESSENCE, 5s);
        _ooc.ScheduleEvent(EVENT_VALIDATE, 5s);
        _spawnPending = true;
        _darkTarget.Clear();
    }

    void ValidateZealots()
    {
        if (instance->GetBossState(DATA_CORLA) == DONE)
            return;
        uint8 const count = IsHeroicOrMythic(me->GetMap()) ? 3 : 2;
        uint8 kneeling = 0, beams = 0;
        bool stray = false;
        for (ObjectGuid const& guid : summons)
            if (Creature* summon = ObjectAccessor::GetCreature(*me, guid))
            {
                if (summon->GetEntry() == NPC_KNEELING_ZEALOT && summon->IsAlive() && summon->HasAura(SPELL_KNEELING))
                    ++kneeling;
                else if (summon->GetEntry() == NPC_NETHER_BEAM)
                    ++beams;
                else
                    stray = true;
            }
        if (kneeling == count && beams == count && !stray)
            return;
        instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_EVOLUTION_STACK);
        instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_TWILIGHT_EVOLUTION);
        summons.DespawnAll();
        _zealots.clear();
        SpawnZealots();
    }

    void OnSpellCast(SpellInfo const* spell) override
    {
        BossAI::OnSpellCast(spell);
        if (spell->Id == SPELL_DARK_COMMAND)
            DarkCommandHit();
    }

    void OnSpellFailed(SpellInfo const* spell) override
    {
        if (spell->Id == SPELL_DARK_COMMAND)
            _darkTarget.Clear();
    }

    void DarkCommandHit()
    {
        if (Unit* target = ObjectAccessor::GetUnit(*me, _darkTarget))
            if (target->IsAlive())
            {
                if (Aura* fear = me->AddAura(SPELL_FEAR, target))
                    fear->SetDuration(3000);
                DealDamage(me, target, SPELL_DARK_COMMAND,
                    uint32(Rolled(
                        me, target, float(DarkCommandDamage.normal60), float(DarkCommandDamage.mythic), nullptr)),
                    SPELL_SCHOOL_MASK_SHADOW);
            }
        _darkTarget.Clear();
    }

    void SpawnZealots()
    {
        _spawnPending = false;
        uint8 const count = IsHeroicOrMythic(me->GetMap()) ? 3 : 2;
        for (uint8 i = 0; i < count; ++i)
        {
            Creature* zealot = me->SummonCreature(NPC_KNEELING_ZEALOT, CorlaZealotPos[i], TEMPSUMMON_MANUAL_DESPAWN);
            if (!zealot)
                continue;
            _zealots.push_back(zealot->GetGUID());
            Position beamPos = me->GetPosition();
            beamPos.m_positionZ += 2.0f;
            if (Creature* beam = me->SummonCreature(NPC_NETHER_BEAM, beamPos, TEMPSUMMON_MANUAL_DESPAWN))
                beam->AI()->SetGUID(zealot->GetGUID(), 0);
        }
    }

    void JustEngagedWith(Unit* who) override
    {
        BossAI::JustEngagedWith(who);
        Talk(SAY_CORLA_AGGRO);
        me->CastStop();
        DoCastSelf(SPELL_AURA_OF_ACCELERATION, true);
        events.ScheduleEvent(EVENT_FIERCE_BLOW, 10s);
        events.ScheduleEvent(EVENT_DARK_COMMAND, 10s);
        for (ObjectGuid const& guid : summons)
            if (Creature* summon = ObjectAccessor::GetCreature(*me, guid))
                if (summon->GetEntry() == NPC_NETHER_BEAM)
                    summon->AI()->DoAction(ACTION_BEAM_START);
    }

    void KilledUnit(Unit* victim) override
    {
        if (victim->IsPlayer())
            Talk(SAY_CORLA_SLAY);
    }

    void JustDied(Unit* killer) override
    {
        BossAI::JustDied(killer);
        Talk(SAY_CORLA_DEATH);
        instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_EVOLUTION_STACK);
        instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_TWILIGHT_EVOLUTION);
    }

    void EnterEvadeMode(EvadeReason why) override
    {
        instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_EVOLUTION_STACK);
        instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_TWILIGHT_EVOLUTION);
        me->InterruptNonMeleeSpells(true);
        summons.DespawnAll();
        _zealots.clear();
        BossAI::EnterEvadeMode(why);
    }

    void UpdateAI(uint32 diff) override
    {
        if (_spawnPending)
            SpawnZealots();
        if (!me->IsInCombat())
        {
            if (me->IsInEvadeMode() || me->GetMotionMaster()->GetCurrentMovementGeneratorType() == HOME_MOTION_TYPE)
                return;
            _ooc.Update(diff);
            while (uint32 eventId = _ooc.ExecuteEvent())
            {
                if (eventId == EVENT_EVOLUTION_OOC)
                {
                    if (!_zealots.empty())
                        if (Creature* zealot = ObjectAccessor::GetCreature(
                                *me, Acore::Containers::SelectRandomContainerElement(_zealots)))
                        {
                            me->CastStop();
                            DoCast(zealot, SPELL_CORLA_EVOLUTION);
                        }
                    _ooc.Repeat(16s);
                }
                else if (eventId == EVENT_VALIDATE)
                {
                    ValidateZealots();
                    _ooc.Repeat(3s);
                }
                else if (eventId == EVENT_DRAIN_ESSENCE)
                {
                    if (!me->HasUnitState(UNIT_STATE_CASTING))
                        if (Creature* stalker = me->FindNearestCreature(NPC_INVISIBLE_STALKER, 100.0f))
                            DoCast(stalker, SPELL_DRAIN_ESSENCE);
                    _ooc.Repeat(16s);
                }
            }
            return;
        }

        if (!UpdateVictim())
            return;

        events.Update(diff);
        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
        {
            if (eventId == EVENT_FIERCE_BLOW)
            {
                DoCastVictim(SPELL_FIERCE_BLOW);
                events.Repeat(8s);
            }
            else if (eventId == EVENT_DARK_COMMAND)
            {
                Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true, false);
                if (!target)
                    target = me->GetVictim();
                if (target)
                {
                    _darkTarget = target->GetGUID();
                    if (me->CastSpell(target, SPELL_DARK_COMMAND, false) != SPELL_CAST_OK)
                        _darkTarget.Clear();
                }
                events.Repeat(15s);
            }
        }

        DoMeleeAttackIfReady();
    }

private:
    EventMap _ooc;
    std::vector<ObjectGuid> _zealots;
    ObjectGuid _darkTarget;
    bool _spawnPending = false;
};

struct npc_coa_brc_corla_zealot : public ScriptedAI
{
    explicit npc_coa_brc_corla_zealot(Creature* creature)
        : ScriptedAI(creature), _instance(creature->GetInstanceScript())
    {
    }

    enum Events : uint32
    {
        EVENT_FIERCE_BLOW = 1,
    };

    void IsSummonedBy(WorldObject* ) override
    {
        me->SetReactState(REACT_PASSIVE);
        DoCastSelf(SPELL_KNEELING, true);
    }

    void EnterEvadeMode(EvadeReason why) override
    {
        if (_evolved)
            ScriptedAI::EnterEvadeMode(why);
    }

    void JustEngagedWith(Unit* ) override
    {
        if (Creature* corla = _instance ? _instance->GetCreature(DATA_CORLA) : nullptr)
            if (!corla->IsInCombat())
                corla->AI()->DoZoneInCombat();
    }

    void DoAction(int32 action) override
    {
        if (action != ACTION_ZEALOT_EVOLVE || _evolved)
            return;
        _evolved = true;
        me->RemoveAllAuras();
        me->UpdateEntry(NPC_EVOLVED_ZEALOT);
        DoCastSelf(SPELL_EVOLUTION_EVOLVED, true);
        me->SetReactState(REACT_AGGRESSIVE);
        DoZoneInCombat();
        if (Creature* corla = _instance ? _instance->GetCreature(DATA_CORLA) : nullptr)
        {
            corla->AI()->Talk(SAY_CORLA_EVOLUTION);
            corla->AI()->Talk(EMOTE_CORLA_ZEALOT_EVOLVED);
        }
        _events.Reset();
        _events.ScheduleEvent(EVENT_FIERCE_BLOW, 7s);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!_evolved || !UpdateVictim())
            return;
        _events.Update(diff);
        if (_events.ExecuteEvent() == EVENT_FIERCE_BLOW)
        {
            DoCastVictim(SPELL_FIERCE_BLOW);
            _events.ScheduleEvent(EVENT_FIERCE_BLOW, 9s);
        }
        DoMeleeAttackIfReady();
    }

private:
    InstanceScript* _instance;
    EventMap _events;
    bool _evolved = false;
};

struct npc_coa_brc_nether_beam : public ScriptedAI
{
    explicit npc_coa_brc_nether_beam(Creature* creature)
        : ScriptedAI(creature), _instance(creature->GetInstanceScript())
    {
    }

    void SetGUID(ObjectGuid const& guid, int32 ) override
    {
        _zealot = guid;
    }

    void DoAction(int32 action) override
    {
        if (action == ACTION_BEAM_START && !_active)
        {
            _active = true;
            _events.ScheduleEvent(EVENT_PULSE, 250ms);
        }
    }

    void AttackStart(Unit* ) override { }

    void UpdateAI(uint32 diff) override
    {
        _events.Update(diff);
        if (_events.ExecuteEvent() != EVENT_PULSE)
            return;
        _events.ScheduleEvent(EVENT_PULSE, 250ms);
        Pulse();
    }

private:
    enum Events : uint32
    {
        EVENT_PULSE = 1,
    };

    void Pulse()
    {
        Creature* zealot = ObjectAccessor::GetCreature(*me, _zealot);
        Creature* corla = _instance ? _instance->GetCreature(DATA_CORLA) : nullptr;
        if (!zealot || !zealot->IsAlive() || zealot->GetEntry() != NPC_KNEELING_ZEALOT || !corla ||
            !corla->IsInCombat())
        {
            Stop();
            return;
        }

        Unit* target = zealot;
        float best = me->GetExactDist2d(zealot);
        for (Player* player : PlayersNear(me, best + 2.0f))
        {
            float const dist = me->GetExactDist2d(player);
            if (dist >= best)
                continue;
            float const off = me->GetRelativeAngle(player) - me->GetRelativeAngle(zealot);
            if (std::fabs(dist * std::sin(off)) <= 1.5f && std::cos(off) > 0.0f)
            {
                best = dist;
                target = player;
            }
        }

        if (target->GetGUID() != _current)
        {
            ClearBeam();
            _current = target->GetGUID();
            me->CastSpell(target, SPELL_NETHER_BEAM, true);
        }

        uint8 const stacks = IsHeroicOrMythic(me->GetMap()) ? 2 : 1;
        for (uint8 i = 0; i < stacks; ++i)
            me->CastSpell(target, SPELL_EVOLUTION_STACK, true);

        Aura* aura = target->GetAura(SPELL_EVOLUTION_STACK);
        if (!aura || aura->GetStackAmount() < 100)
            return;
        aura->Remove();
        if (target == zealot)
        {
            Stop();
            zealot->AI()->DoAction(ACTION_ZEALOT_EVOLVE);
        }
        else
        {
            corla->AI()->Talk(SAY_CORLA_EVOLUTION);
            corla->CastSpell(target, SPELL_TWILIGHT_EVOLUTION, true);
        }
    }

    void ClearBeam()
    {
        me->CastStop();
        if (Unit* old = ObjectAccessor::GetUnit(*me, _current))
            old->RemoveAurasDueToSpell(SPELL_NETHER_BEAM, me->GetGUID());
        _current.Clear();
    }

    void Stop()
    {
        ClearBeam();
        _active = false;
        _events.Reset();
        me->DespawnOrUnsummon();
    }

    InstanceScript* _instance;
    EventMap _events;
    ObjectGuid _zealot;
    ObjectGuid _current;
    bool _active = false;
};

struct boss_coa_brc_karsh : public BossAI
{
    explicit boss_coa_brc_karsh(Creature* creature) : BossAI(creature, DATA_KARSH) { }

    enum Events : uint32
    {
        EVENT_CLEAVE = 1,
        EVENT_FIERCE_BLOW,
        EVENT_HEAT,
    };

    void Reset() override
    {
        _Reset();
        me->RemoveAurasDueToSpell(SPELL_SUPERHEATED_ARMOR);
        DoCastSelf(SPELL_QUICKSILVER_ARMOR, true);
    }

    void JustEngagedWith(Unit* who) override
    {
        BossAI::JustEngagedWith(who);
        Talk(SAY_KARSH_AGGRO);
        events.ScheduleEvent(EVENT_CLEAVE, 10s);
        events.ScheduleEvent(EVENT_FIERCE_BLOW, 12800ms);
        events.ScheduleEvent(EVENT_HEAT, 1s);
    }

    void KilledUnit(Unit* victim) override
    {
        if (victim->IsPlayer())
            Talk(SAY_KARSH_SLAY);
    }

    void JustDied(Unit* killer) override
    {
        BossAI::JustDied(killer);
        Talk(SAY_KARSH_DEATH);
    }

    void DoAction(int32 action) override
    {
        if (action != ACTION_LAVA_SPOUT || !me->IsInCombat())
            return;
        for (Player* player : PlayersNear(me, 100.0f))
            if (player->GetExactDist2d(LavaFountainPos.GetPositionX(), LavaFountainPos.GetPositionY()) <= LavaGrateRadius)
                DealDamage(me, player, SPELL_SUPERHEATED_ARMOR,
                    uint32(Rolled(me, player, float(LavaSpoutDamage.normal60), float(LavaSpoutDamage.mythic),
                        sSpellMgr->GetSpellInfo(SPELL_SUPERHEATED_ARMOR))),
                    SPELL_SCHOOL_MASK_FIRE);
        for (uint8 i = 0; i < 8; ++i)
        {
            float const angle = float(i) * float(M_PI) / 4.0f;
            Position spout = LavaFountainPos;
            spout.RelocateOffset({ std::cos(angle) * 6.0f, std::sin(angle) * 6.0f, 0.0f });
            if (Creature* fill = me->SummonCreature(NPC_FIRE_ZONE_FILL, spout, TEMPSUMMON_TIMED_DESPAWN, 2000))
                if (Aura* aura = fill->AddAura(SPELL_FIRE_ZONE_FILL, fill))
                {
                    aura->SetMaxDuration(2000);
                    aura->SetDuration(2000);
                }
        }
    }

    void DamageDealt(Unit* victim, uint32& damage, DamageEffectType type, SpellSchoolMask ) override
    {
        if (type != DIRECT_DAMAGE || !damage || !victim || !victim->IsPlayer())
            return;
        Aura const* armor = me->GetAura(SPELL_SUPERHEATED_ARMOR);
        if (!armor)
            return;
        SpellInfo const* info = armor->GetSpellInfo();
        float const stacks = float(armor->GetStackAmount());
        DealDamage(me, victim, SPELL_SUPERHEATED_ARMOR,
            uint32(Rolled(me, victim, BurningMetalPerStack.normal60 * stacks, BurningMetalPerStack.mythic * stacks, info)),
            SPELL_SCHOOL_MASK_FIRE);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        events.Update(diff);

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_HEAT:
                    HeatCheck();
                    events.Repeat(1s);
                    break;
                case EVENT_CLEAVE:
                    if (me->HasUnitState(UNIT_STATE_CASTING))
                        events.Repeat(500ms);
                    else
                    {
                        DoCastVictim(SPELL_CLEAVE);
                        events.Repeat(8s);
                    }
                    break;
                case EVENT_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    events.Repeat(9400ms);
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }

private:
    void HeatCheck()
    {
        if (me->GetExactDist2d(LavaFountainPos.GetPositionX(), LavaFountainPos.GetPositionY()) < 5.0f)
        {
            Aura* armor = me->GetAura(SPELL_SUPERHEATED_ARMOR);
            bool const first = !armor;
            me->RemoveAurasDueToSpell(SPELL_QUICKSILVER_ARMOR);
            if (armor)
                armor->ModStackAmount(1);
            else
                me->CastSpell(me, SPELL_SUPERHEATED_ARMOR, true);
            if (first)
            {
                Talk(SAY_KARSH_SUPERHEATED);
                Talk(EMOTE_KARSH_SUPERHEATED);
            }
            me->CastSpell(me, SPELL_HEAT_WAVE, true);
        }
        else if (!me->HasAura(SPELL_SUPERHEATED_ARMOR) && !me->HasAura(SPELL_QUICKSILVER_ARMOR))
            me->CastSpell(me, SPELL_QUICKSILVER_ARMOR, true);
    }
};

struct boss_coa_brc_beauty : public BossAI
{
    explicit boss_coa_brc_beauty(Creature* creature) : BossAI(creature, DATA_BEAUTY) { }

    enum Events : uint32
    {
        EVENT_ROAR = 1,
        EVENT_FIERCE_BLOW,
        EVENT_MAGMA_SPIT,
        EVENT_CHARGE,
        EVENT_FLAMEBREAK,
    };

    static constexpr uint32 POINT_CHARGE = 1;

    void Reset() override
    {
        _Reset();
        _spawnPending = true;
        _chargeTarget.Clear();
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != POINT_MOTION_TYPE || id != POINT_CHARGE)
            return;
        if (Unit* target = ObjectAccessor::GetUnit(*me, _chargeTarget))
            if (target->IsAlive() && me->IsWithinMeleeRange(target, 3.0f))
            {
                DealDamage(me, target, SPELL_BERSERKER_CHARGE,
                    uint32(Rolled(me, target, float(BerserkerChargeDamage.normal60),
                        float(BerserkerChargeDamage.mythic), nullptr)),
                    SPELL_SCHOOL_MASK_NORMAL);
                target->KnockbackFrom(me->GetPositionX(), me->GetPositionY(), 12.0f, 6.0f);
            }
        _chargeTarget.Clear();
    }

    void SpawnPups()
    {
        _spawnPending = false;
        if (Creature* lucky = me->SummonCreature(NPC_LUCKY, LuckyPos, TEMPSUMMON_MANUAL_DESPAWN))
            lucky->GetMotionMaster()->MoveRandom(5.0f);
        if (Creature* spot = me->SummonCreature(NPC_SPOT, SpotPos, TEMPSUMMON_MANUAL_DESPAWN))
            spot->GetMotionMaster()->MoveRandom(5.0f);
        me->SummonCreature(NPC_RUNTY, RuntyPos, TEMPSUMMON_MANUAL_DESPAWN);
    }

    void JustEngagedWith(Unit* who) override
    {
        BossAI::JustEngagedWith(who);
        me->PlayDirectSound(SOUND_BEAUTY_AGGRO);
        events.ScheduleEvent(EVENT_ROAR, 17s);
        events.ScheduleEvent(EVENT_FIERCE_BLOW, 4600ms);
        events.ScheduleEvent(EVENT_MAGMA_SPIT, 10s);
        events.ScheduleEvent(EVENT_CHARGE, 15s);
        events.ScheduleEvent(EVENT_FLAMEBREAK, 21s);
        for (ObjectGuid const& guid : summons)
            if (Creature* pup = ObjectAccessor::GetCreature(*me, guid))
                if (pup->IsAlive() && !pup->IsInCombat())
                    pup->AI()->DoZoneInCombat();
    }

    void SummonedCreatureDies(Creature* summon, Unit* killer) override
    {
        BossAI::SummonedCreatureDies(summon, killer);
        if (summon->GetEntry() == NPC_RUNTY && me->IsAlive())
            DoCastSelf(SPELL_BERSERK, true);
    }

    void JustDied(Unit* killer) override
    {
        BossAI::JustDied(killer);
        me->PlayDirectSound(SOUND_BEAUTY_DEATH);
    }

private:
    bool _spawnPending = false;
    ObjectGuid _chargeTarget;

public:

    void UpdateAI(uint32 diff) override
    {
        if (_spawnPending)
            SpawnPups();
        if (!UpdateVictim())
            return;

        events.Update(diff);
        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_ROAR:
                    DoCastAOE(SPELL_TERRIFYING_ROAR);
                    events.Repeat(16500ms);
                    break;
                case EVENT_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    events.Repeat(8100ms);
                    break;
                case EVENT_MAGMA_SPIT:
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                    {
                        me->CastSpell(target, SPELL_MAGMA_SPIT, true);
                        DealDamage(me, target, SPELL_MAGMA_SPIT,
                            uint32(Rolled(
                                me, target, float(MagmaSpitDamage.normal60), float(MagmaSpitDamage.mythic), nullptr)),
                            SPELL_SCHOOL_MASK_FIRE);
                    }
                    events.Repeat(7s, 9s);
                    break;
                case EVENT_CHARGE:
                    if (Unit* target = SelectTarget(SelectTargetMethod::MaxDistance, 0, 100.0f, true))
                    {
                        _chargeTarget = target->GetGUID();
                        me->CastSpell(target, SPELL_BERSERKER_CHARGE, true);
                        me->GetMotionMaster()->MoveCharge(target->GetPositionX(), target->GetPositionY(),
                            target->GetPositionZ(), 42.0f, POINT_CHARGE);
                    }
                    events.Repeat(15s, 21s);
                    break;
                case EVENT_FLAMEBREAK:
                    me->CastSpell(me, SPELL_FLAMEBREAK, true);
                    for (Player* player : PlayersNear(me, 10.0f))
                    {
                        DealDamage(me, player, SPELL_FLAMEBREAK,
                            uint32(Rolled(
                                me, player, float(FlamebreakDamage.normal60), float(FlamebreakDamage.mythic), nullptr)),
                            SPELL_SCHOOL_MASK_FIRE);
                        player->KnockbackFrom(me->GetPositionX(), me->GetPositionY(), 10.0f, 7.0f);
                    }
                    events.Repeat(15s, 21s);
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

struct npc_coa_brc_beauty_pup : public ScriptedAI
{
    explicit npc_coa_brc_beauty_pup(Creature* creature) : ScriptedAI(creature), _instance(creature->GetInstanceScript())
    {
    }

    enum Events : uint32
    {
        EVENT_FLAME_BREATH = 1,
        EVENT_FIERCE_BLOW,
        EVENT_LAVA_DROOL,
    };

    void Reset() override
    {
        _events.Reset();
    }

    void JustEngagedWith(Unit* ) override
    {
        if (Creature* beauty = _instance ? _instance->GetCreature(DATA_BEAUTY) : nullptr)
            if (beauty->IsAlive() && !beauty->IsInCombat())
                beauty->AI()->DoZoneInCombat();
        _events.ScheduleEvent(EVENT_LAVA_DROOL, 5500ms, 6500ms);
        _events.ScheduleEvent(EVENT_FLAME_BREATH, 5s, 8s);
        _events.ScheduleEvent(EVENT_FIERCE_BLOW, 12s);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        _events.Update(diff);
        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_FLAME_BREATH:
                    DoCastVictim(SPELL_LITTLE_BIG_FLAME_BREATH);
                    _events.Repeat(11s, 13s);
                    break;
                case EVENT_LAVA_DROOL:
                    DoCastSelf(SPELL_LAVA_POOL, true);
                    _events.Repeat(12s, 13s);
                    break;
                case EVENT_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    _events.Repeat(12s);
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }

private:
    InstanceScript* _instance;
    EventMap _events;
};

struct boss_coa_brc_obsidius : public BossAI
{
    explicit boss_coa_brc_obsidius(Creature* creature) : BossAI(creature, DATA_OBSIDIUS) { }

    enum Events : uint32
    {
        EVENT_STONE_BLOW = 1,
        EVENT_THUNDERCLAP,
        EVENT_FIERCE_BLOW,
        EVENT_SWAP,
        EVENT_REAPPEAR,
        EVENT_TWILIGHT_CORRUPTION,
    };

    void Reset() override
    {
        _Reset();
        _transformations = 0;
        _spawnPending = true;
        me->SetVisible(true);
    }

    void SpawnShadows()
    {
        _spawnPending = false;
        bool const freed = instance->GetPersistentData(PERSISTENT_OBSIDIUS_FREED) != 0;
        SetBound(me, !freed);
        uint8 const count = IsHeroicOrMythic(me->GetMap()) ? 3 : 2;
        for (uint8 i = 0; i < count; ++i)
            if (Creature* shadow =
                    me->SummonCreature(NPC_SHADOW_OF_OBSIDIUS, ShadowOfObsidiusPos[i], TEMPSUMMON_MANUAL_DESPAWN))
                SetBound(shadow, !freed);
    }

    void DoAction(int32 action) override
    {
        if (action != ACTION_OBSIDIUS_FREE || instance->GetPersistentData(PERSISTENT_OBSIDIUS_FREED))
            return;
        instance->StorePersistentData(PERSISTENT_OBSIDIUS_FREED, 1);
        SetBound(me, false);
        for (ObjectGuid const& guid : summons)
            if (Creature* shadow = ObjectAccessor::GetCreature(*me, guid))
                SetBound(shadow, false);
    }

    void JustEngagedWith(Unit* who) override
    {
        BossAI::JustEngagedWith(who);
        Talk(SAY_OBSIDIUS_AGGRO);
        if (Creature* raz = instance->GetCreature(DATA_RAZ))
            if (raz->IsAlive())
                DoCast(raz, SPELL_STOP_HEART, true);
        events.ScheduleEvent(EVENT_STONE_BLOW, 7s);
        events.ScheduleEvent(EVENT_TWILIGHT_CORRUPTION, 12s);
        events.ScheduleEvent(EVENT_FIERCE_BLOW, 5300ms);
        if (IsHeroicOrMythic(me->GetMap()))
            events.ScheduleEvent(EVENT_THUNDERCLAP, 8s);
        for (ObjectGuid const& guid : summons)
            if (Creature* shadow = ObjectAccessor::GetCreature(*me, guid))
                shadow->AI()->DoZoneInCombat();
    }

    void KilledUnit(Unit* victim) override
    {
        if (victim->IsPlayer())
            Talk(SAY_OBSIDIUS_SLAY);
    }

    void JustDied(Unit* killer) override
    {
        Reappear();
        BossAI::JustDied(killer);
        Talk(SAY_OBSIDIUS_DEATH);
        instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_TWILIGHT_CORRUPTION);
    }

    void EnterEvadeMode(EvadeReason why) override
    {
        instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_TWILIGHT_CORRUPTION);
        BossAI::EnterEvadeMode(why);
    }

    void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask mask) override
    {
        BossAI::DamageTaken(attacker, damage, type, mask);
        if (damage >= me->GetHealth())
            return;
        if ((_transformations == 0 && me->HealthBelowPctDamaged(69, damage)) ||
            (_transformations == 1 && me->HealthBelowPctDamaged(34, damage)))
        {
            ++_transformations;
            Transform();
        }
    }

    void UpdateAI(uint32 diff) override
    {
        if (_spawnPending)
            SpawnShadows();
        if (!UpdateVictim())
            return;

        events.Update(diff);
        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_STONE_BLOW:
                    DoCastVictim(SPELL_STONE_BLOW);
                    if (IsHeroicOrMythic(me->GetMap()))
                        events.Repeat(13s);
                    else
                        events.Repeat(17s);
                    break;
                case EVENT_THUNDERCLAP:
                    DoCastAOE(SPELL_THUNDERCLAP);
                    events.Repeat(23s);
                    break;
                case EVENT_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    events.Repeat(9600ms);
                    break;
                case EVENT_SWAP:
                    Swap();
                    break;
                case EVENT_TWILIGHT_CORRUPTION:
                    if (Unit* target =
                            SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true, true, -SPELL_TWILIGHT_CORRUPTION))
                        if (Aura* aura = me->AddAura(SPELL_TWILIGHT_CORRUPTION, target))
                        {
                            aura->SetMaxDuration(12000);
                            aura->SetDuration(12000);
                            if (AuraEffect* effect = aura->GetEffect(EFFECT_0))
                                effect->ChangeAmount(Rolled(me, target, float(TwilightCorruptionTick.normal60),
                                    float(TwilightCorruptionTick.mythic), nullptr));
                        }
                    events.Repeat(12s);
                    break;
                case EVENT_REAPPEAR:
                    Reappear();
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }

private:
    void Reappear()
    {
        me->SetVisible(true);
        if (Creature* shadow = ObjectAccessor::GetCreature(*me, _hiddenShadow))
            shadow->SetVisible(true);
        _hiddenShadow.Clear();
    }

    static void SetBound(Creature* creature, bool bound)
    {
        creature->SetImmuneToAll(bound);
        if (bound)
            creature->CastSpell(creature, SPELL_SHADOWY_CORRUPTION, true);
        else
            creature->RemoveAurasDueToSpell(SPELL_SHADOWY_CORRUPTION);
    }

    void Transform()
    {
        Talk(SAY_OBSIDIUS_TRANSFORMATION);
        Talk(EMOTE_OBSIDIUS_TRANSFORMATION);
        std::vector<Creature*> shadows;
        for (ObjectGuid const& guid : summons)
            if (Creature* shadow = ObjectAccessor::GetCreature(*me, guid))
                if (shadow->IsAlive() && shadow->GetEntry() == NPC_SHADOW_OF_OBSIDIUS)
                    shadows.push_back(shadow);
        if (shadows.empty())
            return;
        Creature* shadow = Acore::Containers::SelectRandomContainerElement(shadows);
        _swapShadow = shadow->GetGUID();
        me->CastSpell(shadow, SPELL_TRANSFORMATION_SCALE, true);
        me->CastSpell(shadow, SPELL_TRANSFORMATION_UNATTACKABLE, true);
        events.ScheduleEvent(EVENT_SWAP, 2s);
    }

    void Swap()
    {
        Creature* shadow = ObjectAccessor::GetCreature(*me, _swapShadow);
        _swapShadow.Clear();
        if (!shadow || !shadow->IsAlive())
            return;
        Position const mine = me->GetPosition();
        Position const theirs = shadow->GetPosition();
        Unit* bossVictim = me->GetVictim();
        Unit* shadowVictim = shadow->GetVictim();
        me->SetVisible(false);
        shadow->SetVisible(false);
        me->NearTeleportTo(
            theirs.GetPositionX(), theirs.GetPositionY(), theirs.GetPositionZ(), theirs.GetOrientation());
        shadow->NearTeleportTo(mine.GetPositionX(), mine.GetPositionY(), mine.GetPositionZ(), mine.GetOrientation());
        me->CastSpell(shadow, SPELL_TRANSFORMATION_STUN, true);
        DoResetThreatList();
        shadow->GetThreatMgr().ResetAllThreat();
        if (shadowVictim && shadowVictim->IsAlive())
            me->AddThreat(shadowVictim, 100000.0f);
        if (bossVictim && bossVictim->IsAlive())
            shadow->AddThreat(bossVictim, 100000.0f);
        _hiddenShadow = shadow->GetGUID();
        events.ScheduleEvent(EVENT_REAPPEAR, 400ms);
    }

    ObjectGuid _swapShadow;
    ObjectGuid _hiddenShadow;

    uint8 _transformations = 0;
    bool _spawnPending = false;
};

struct npc_coa_brc_shadow_of_obsidius : public ScriptedAI
{
    explicit npc_coa_brc_shadow_of_obsidius(Creature* creature) : ScriptedAI(creature) { }

    enum Events : uint32
    {
        EVENT_FIERCE_BLOW = 1,
    };

    void Reset() override
    {
        _events.Reset();
        _events.ScheduleEvent(EVENT_FIERCE_BLOW, 8s);
        me->SetSpeedRate(MOVE_WALK, ShadowSpeedRate);
        me->SetSpeedRate(MOVE_RUN, ShadowSpeedRate);
        DoCastSelf(SPELL_SHADOW_OF_OBSIDIUS, true);
        DoCastSelf(SPELL_CREPUSCULAR_VEIL, true);
        DoCastSelf(SPELL_TWITCHY, true);
    }

    void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType , SpellSchoolMask ) override
    {
        damage = 0;
        if (attacker && attacker != me->GetVictim() && me->IsValidAttackTarget(attacker))
        {
            me->GetThreatMgr().ResetAllThreat();
            me->AddThreat(attacker, 100000.0f);
        }
    }

    void JustEngagedWith(Unit* who) override
    {
        if (Creature* obsidius = Obsidius())
            if (obsidius->IsAlive() && !obsidius->IsInCombat())
                obsidius->AI()->AttackStart(who);
    }

    void JustDied(Unit* ) override
    {
        SetTether(ObjectGuid::Empty);
    }

    void UpdateAI(uint32 diff) override
    {
        Creature* obsidius = Obsidius();
        SetTether(obsidius && obsidius->IsAlive() ? obsidius->GetGUID() : ObjectGuid::Empty);
        if (!UpdateVictim())
            return;
        _events.Update(diff);
        if (_events.ExecuteEvent() == EVENT_FIERCE_BLOW)
        {
            DoCastVictim(SPELL_FIERCE_BLOW);
            _events.ScheduleEvent(EVENT_FIERCE_BLOW, 12s);
        }
        DoMeleeAttackIfReady();
    }

private:
    Creature* Obsidius() const
    {
        InstanceScript* instance = me->GetInstanceScript();
        return instance ? instance->GetCreature(DATA_OBSIDIUS) : nullptr;
    }

    void SetTether(ObjectGuid const& target)
    {
        if (me->GetGuidValue(UNIT_FIELD_CHANNEL_OBJECT) == target)
            return;
        me->SetGuidValue(UNIT_FIELD_CHANNEL_OBJECT, target);
        me->SetUInt32Value(UNIT_CHANNEL_SPELL, target ? uint32(SPELL_SHADOW_TETHER) : 0);
    }

    EventMap _events;
};

struct npc_coa_brc_quicksilver : public ScriptedAI
{
    explicit npc_coa_brc_quicksilver(Creature* creature) : ScriptedAI(creature) { }

    enum Events : uint32
    {
        EVENT_MELT = 1,
        EVENT_STOP,
        EVENT_COOL,
    };

    void Reset() override
    {
        _events.Reset();
        _molten = false;
        me->SetReactState(REACT_PASSIVE);
    }

    void AttackStart(Unit* ) override { }

    void MoveInLineOfSight(Unit* ) override { }

    uint32 GetData(uint32 ) const override
    {
        return _molten ? 1 : 0;
    }

    void SetGUID(ObjectGuid const& guid, int32 ) override
    {
        if (_molten)
            return;
        Unit* source = ObjectAccessor::GetUnit(*me, guid);
        if (!source)
            return;
        _molten = true;
        _source = guid;
        _events.ScheduleEvent(EVENT_MELT, Milliseconds(uint32(me->GetExactDist(source) / 11.0f * 1000.0f) + 100));
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type == POINT_MOTION_TYPE && id == 1)
        {
            DoCastSelf(SPELL_COOLED, true);
            _molten = false;
        }
    }

    void UpdateAI(uint32 diff) override
    {
        _events.Update(diff);
        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_MELT:
                    me->RemoveAurasDueToSpell(SPELL_COOLED);
                    me->SetDisplayId(DISPLAY_MOLTEN_QUICKSILVER);
                    if (Unit* source = ObjectAccessor::GetUnit(*me, _source))
                        me->GetMotionMaster()->MoveFleeing(source, 1000);
                    _events.ScheduleEvent(EVENT_STOP, 1s);
                    _events.ScheduleEvent(EVENT_COOL, 5s);
                    break;
                case EVENT_STOP:
                    me->GetMotionMaster()->Clear();
                    me->GetMotionMaster()->MoveIdle();
                    break;
                case EVENT_COOL:
                    me->DeMorph();
                    me->SetWalk(true);
                    me->GetMotionMaster()->MovePoint(1, me->GetHomePosition());
                    break;
                default:
                    break;
            }
        }
    }

private:
    EventMap _events;
    ObjectGuid _source;
    bool _molten = false;
};

std::unordered_map<uint32, uint32> const QuestBangs =
{
    { 49526, 28737 },
    { 49529, 28738 },
    { 49530, 28740 },
    { 49531, 28741 },
};

struct npc_coa_brc_quest_bang : public ScriptedAI
{
    explicit npc_coa_brc_quest_bang(Creature* creature) : ScriptedAI(creature) { }

    void AttackStart(Unit* ) override { }

    void Reset() override
    {
        scheduler.CancelAll();
        scheduler.Schedule(1s, [this](TaskContext context)
        {
            OfferQuest();
            context.Repeat();
        });
    }

    void UpdateAI(uint32 diff) override
    {
        scheduler.Update(diff);
    }

private:
    void OfferQuest()
    {
        auto itr = QuestBangs.find(me->GetEntry());
        Quest const* quest = itr != QuestBangs.end() ? sObjectMgr->GetQuestTemplate(itr->second) : nullptr;
        if (!quest)
            return;
        for (Player* player : PlayersNear(me, 25.0f))
        {
            if (!player->CanTakeQuest(quest, false) || !player->CanAddQuest(quest, false))
                continue;
            player->AddQuestAndCheckCompletion(quest, nullptr);
            player->PlayerTalkClass->SendQuestGiverQuestDetails(quest, player->GetGUID(), true);
        }
    }
};

enum class Aim : uint8
{
    Victim,
    Self,
    Random,
};

struct Ability
{
    uint32 spell;
    uint32 firstMs;
    uint32 repeatMs;
    Aim aim;
};

Ability const FierceBlow = { SPELL_FIERCE_BLOW, 9000, 9000, Aim::Victim };

std::unordered_map<uint32, std::vector<Ability>> const Abilities = {
    { NPC_TWILIGHT_FLAME_CALLER, { FierceBlow } },
    { NPC_TWILIGHT_TORTURER,
        { { 5011032, 7600, 16000, Aim::Random }, { 5011033, 14800, 14300, Aim::Victim }, FierceBlow } },
    { NPC_TWILIGHT_SADIST, { { 5011028, 1900, 6000, Aim::Victim }, { 5011027, 3500, 5300, Aim::Victim }, FierceBlow } },
    { NPC_CRAZED_MAGE, { { 54792, 3000, 13000, Aim::Self }, FierceBlow } },
    { NPC_MAD_PRISONER, { { 5011023, 6700, 13200, Aim::Victim }, { 5011024, 7400, 13800, Aim::Victim }, FierceBlow } },
    { NPC_EVOLVED_ZEALOT, { FierceBlow } },
    { NPC_TWILIGHT_ZEALOT, { { 5011050, 7400, 14000, Aim::Random }, { 5011045, 11900, 7400, Aim::Victim },
                               { 5011047, 17000, 15000, Aim::Victim }, FierceBlow } },
    { 39994, { FierceBlow } },
    { 40017, { { 5011059, 9700, 8000, Aim::Victim }, FierceBlow } },
    { 40019, { { 5011055, 2600, 14300, Aim::Random }, FierceBlow } },
    { 40021, { FierceBlow } },
    { 40023, { { 5011063, 3100, 9000, Aim::Victim }, { 5011064, 7200, 7800, Aim::Random }, FierceBlow } },
    { 40084, { { 5011054, 3900, 8300, Aim::Victim }, FierceBlow } },
    { NPC_ANGERED_EARTH, { FierceBlow } },
};

struct npc_coa_brc_trash : public ScriptedAI
{
    explicit npc_coa_brc_trash(Creature* creature) : ScriptedAI(creature) { }

    enum IdleEvents : uint32
    {
        EVENT_IDLE_ACTION = 1,
        EVENT_FIRE_ZONE,
    };

    enum Groups : uint32
    {
        GROUP_HEAT = 1,
    };

    void Reset() override
    {
        _enraged = false;
        _abilities.Reset();
        _idle.Reset();
        _idle.ScheduleEvent(EVENT_IDLE_ACTION, Milliseconds(urand(4000, 12000)));
        if (me->GetEntry() == NPC_TWILIGHT_FLAME_CALLER)
            _idle.ScheduleEvent(EVENT_FIRE_ZONE, Milliseconds(urand(500, 2000)));
        scheduler.CancelGroup(GROUP_HEAT);
        if (me->GetEntry() == NPC_CONFLAGRATION)
            scheduler.Schedule(Milliseconds(urand(2000, 5000)), GROUP_HEAT, [this](TaskContext context)
            {
                Heat();
                context.Repeat(5s);
            });
        auto itr = Abilities.find(me->GetEntry());
        _kit = itr != Abilities.end() ? &itr->second : nullptr;
        if (!_kit)
            return;
        for (uint32 i = 0; i < _kit->size(); ++i)
            _abilities.ScheduleEvent(i + 1, Milliseconds((*_kit)[i].firstMs + urand(0, 1500)));
    }

    void JustEngagedWith(Unit* ) override
    {
        me->InterruptNonMeleeSpells(false);
        if (me->GetEntry() == NPC_TWILIGHT_ZEALOT)
            DoCastSelf(SPELL_AURA_OF_ARCANE_HASTE, true);
    }

    void DamageTaken(Unit* , uint32& damage, DamageEffectType , SpellSchoolMask ) override
    {
        if (!_enraged && me->GetEntry() == NPC_MAD_PRISONER && me->HealthBelowPctDamaged(50, damage))
        {
            _enraged = true;
            DoCastSelf(SPELL_ENRAGE, true);
        }
    }

    void UpdateAI(uint32 diff) override
    {
        scheduler.Update(diff);

        if (!me->IsInCombat())
        {
            _idle.Update(diff);
            while (uint32 eventId = _idle.ExecuteEvent())
            {
                if (eventId == EVENT_FIRE_ZONE)
                    SpawnFireZone();
                else
                    IdleAction();
            }
            return;
        }

        if (!UpdateVictim())
            return;

        _abilities.Update(diff);

        if (_kit && !me->HasUnitState(UNIT_STATE_CASTING))
        {
            while (uint32 eventId = _abilities.ExecuteEvent())
            {
                Ability const& ability = (*_kit)[eventId - 1];
                UseAbility(ability);
                _abilities.ScheduleEvent(eventId, Milliseconds(ability.repeatMs));
                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }
        }

        if (!me->HasUnitState(UNIT_STATE_CASTING))
            DoMeleeAttackIfReady();
    }

private:
    void UseAbility(Ability const& ability)
    {
        switch (ability.aim)
        {
            case Aim::Victim:
                DoCastVictim(ability.spell);
                break;
            case Aim::Self:
                DoCastSelf(ability.spell);
                break;
            case Aim::Random:
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 40.0f, true))
                    DoCast(target, ability.spell);
                break;
        }
    }

    void Heat()
    {
        std::list<Creature*> pools;
        me->GetCreatureListWithEntryInGrid(pools, NPC_QUICKSILVER, 20.0f);
        std::vector<Creature*> cooled;
        for (Creature* pool : pools)
            if (pool->IsAlive() && pool->AI() && !pool->AI()->GetData(0))
                cooled.push_back(pool);
        Acore::Containers::RandomShuffle(cooled);
        cooled.resize(std::min<size_t>(cooled.size(), urand(3, 4)));
        for (Creature* pool : cooled)
        {
            me->CastSpell(pool, SPELL_INCINERATE_VISUAL, true);
            pool->AI()->SetGUID(me->GetGUID(), 0);
        }
    }

    void SpawnFireZone()
    {
        uint32 const every = FireZoneEveryMs * FireZoneCallers;
        _idle.ScheduleEvent(EVENT_FIRE_ZONE,
            Milliseconds(urand(uint32(every * (1.0f - FireZoneJitter)), uint32(every * (1.0f + FireZoneJitter)))));
        std::list<Creature*> spots;
        me->GetCreatureListWithEntryInGrid(spots, NPC_FIRE_ZONE, 45.0f);
        spots.remove_if([](Creature* spot) { return spot->IsSummon(); });
        if (spots.empty())
            return;
        Creature* spot = Acore::Containers::SelectRandomContainerElement(spots);
        Position pos = spot->GetPosition();
        spot->MovePositionToFirstCollision(pos, frand(0.0f, FireZoneSpread), frand(0.0f, 2.0f * float(M_PI)));
        Creature* marker = me->SummonCreature(NPC_FIRE_ZONE_RING, pos, TEMPSUMMON_TIMED_DESPAWN, FireZoneMs + 500);
        if (!marker)
            return;
        ShowZone(marker, SPELL_FIRE_ZONE_RING);
        if (Creature* fill = me->SummonCreature(NPC_FIRE_ZONE_FILL, pos, TEMPSUMMON_TIMED_DESPAWN, FireZoneMs + 500))
            ShowZone(fill, SPELL_FIRE_ZONE_FILL);
        uint32 const travelMs = std::min(FireZoneMs, uint32(me->GetExactDist(marker) / 40.0f * 1000.0f));
        ObjectGuid const markerGuid = marker->GetGUID();
        scheduler.Schedule(Milliseconds(FireZoneMs - travelMs), [this, markerGuid](TaskContext )
        {
            if (Creature* target = ObjectAccessor::GetCreature(*me, markerGuid))
                me->CastSpell(target, SPELL_LOBBED_FIREBALL, true);
        });
        scheduler.Schedule(Milliseconds(FireZoneMs), [this, pos](TaskContext )
        {
            BurnFireZone(pos);
        });
    }

    void BurnFireZone(Position const& pos)
    {
        uint32 const pct = me->GetMap()->GetDifficulty() == DUNGEON_DIFFICULTY_EPIC
                               ? 30
                               : (IsHeroicOrMythic(me->GetMap()) ? 20 : 15);
        for (Player* player : PlayersNear(me, 200.0f))
            if (player->GetExactDist2d(pos.GetPositionX(), pos.GetPositionY()) <= FireZoneRadius &&
                std::fabs(player->GetPositionZ() - pos.GetPositionZ()) < 6.0f)
                DealDamage(
                    me, player, SPELL_LOBBED_FIREBALL, player->GetMaxHealth() * pct / 100, SPELL_SCHOOL_MASK_FIRE);
    }

    static void ShowZone(Creature* marker, uint32 spellId)
    {
        if (Aura* aura = marker->AddAura(spellId, marker))
        {
            aura->SetMaxDuration(FireZoneMs);
            aura->SetDuration(FireZoneMs);
        }
    }

    Creature* FindChannelTarget() const
    {
        std::list<Creature*> targets;
        me->GetCreatureListWithEntryInGrid(targets, NPC_CHANNEL_TARGET, 50.0f);
        targets.sort(Acore::ObjectDistanceOrderPred(me));
        for (Creature* target : targets)
            if (me->IsWithinLOSInMap(target))
                return target;
        return nullptr;
    }

    void IdleAction()
    {
        Milliseconds next = Milliseconds(urand(25000, 32000));
        if (!me->HasUnitState(UNIT_STATE_CASTING) && !me->isMoving())
        {
            switch (me->GetEntry())
            {
                case NPC_TWILIGHT_TORTURER:
                case NPC_TWILIGHT_SADIST:
                {
                    Creature* prisoner = me->FindNearestCreature(NPC_MAD_PRISONER, 15.0f);
                    if (!prisoner)
                        prisoner = me->FindNearestCreature(NPC_CRAZED_MAGE, 15.0f);
                    if (prisoner)
                        DoCast(prisoner, SPELL_INFLICT_PAIN);
                    break;
                }
                case NPC_TWILIGHT_FLAME_CALLER:
                    next = 12s;
                    if (!me->HasAura(SPELL_FIRE_CHANNELING))
                        DoCastSelf(SPELL_FIRE_CHANNELING, true);
                    break;
                case NPC_TWILIGHT_ELEMENT_WARDEN:
                    next = 12s;
                    if (Creature* target = FindChannelTarget())
                        DoCast(target, SPELL_FIRE_BEAM);
                    break;
                default:
                    break;
            }
        }
        _idle.ScheduleEvent(EVENT_IDLE_ACTION, next);
    }

    std::vector<Ability> const* _kit = nullptr;
    EventMap _abilities;
    EventMap _idle;
    bool _enraged = false;
};

class spell_coa_brc_damage : public SpellScript
{
    PrepareSpellScript(spell_coa_brc_damage);

    void HandleHit()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target || !GetHitDamage())
            return;
        uint32 const id = GetSpellInfo()->Id;
        if (id == SPELL_HEAT_WAVE)
        {
            Aura const* armor = caster->GetAura(SPELL_SUPERHEATED_ARMOR);
            float const value = HeatWavePerStack * ((armor ? armor->GetStackAmount() : 1) + HeatWaveBaseStacks);
            float const heat = caster->GetMap()->GetDifficulty() == REGULAR_DIFFICULTY
                ? CoAOtherSide::Unscaled(caster, target, value, GetSpellInfo()) : value;
            SetHitDamage(std::max(1, int32(heat * frand(0.95f, 1.05f))));
            return;
        }
        auto itr = Damages.find(id);
        if (itr == Damages.end())
            return;
        SetHitDamage(Rolled(caster, target, float(itr->second.normal60), float(itr->second.mythic), GetSpellInfo()));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_brc_damage::HandleHit);
    }
};

class spell_coa_brc_damage_aura : public AuraScript
{
    PrepareAuraScript(spell_coa_brc_damage_aura);

    void CalcTick(AuraEffect const* , int32& amount, bool& )
    {
        auto itr = Damages.find(GetSpellInfo()->Id);
        if (itr == Damages.end())
            return;
        Unit* owner = GetAura()->GetType() == UNIT_AURA_TYPE ? GetUnitOwner() : nullptr;
        if (Unit* caster = GetCaster())
            amount = Rolled(caster, owner, float(itr->second.normal60), float(itr->second.mythic), GetSpellInfo());
    }

    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(spell_coa_brc_damage_aura::CalcTick, EFFECT_ALL, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class spell_coa_brc_furious_swipe : public SpellScript
{
    PrepareSpellScript(spell_coa_brc_furious_swipe);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        targets.clear();
        std::list<Unit*> units;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(caster, caster, 10.0f);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(caster, units, check);
        Cell::VisitObjects(caster, searcher, 10.0f);
        for (Unit* unit : units)
            if (!unit->IsPlayer() && caster->HasInArc(float(M_PI) * 2.0f / 3.0f, unit) &&
                caster->IsValidAttackTarget(unit))
                targets.push_back(unit);
        if (Unit* victim = caster->GetVictim())
            if (std::find(targets.begin(), targets.end(), victim) == targets.end())
                targets.push_back(victim);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(
            spell_coa_brc_furious_swipe::FilterTargets, EFFECT_ALL, TARGET_UNIT_CONE_ENEMY_24);
    }
};

class spell_coa_brc_twilight_corruption : public AuraScript
{
    PrepareAuraScript(spell_coa_brc_twilight_corruption);

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        Unit* caster = GetCaster();
        if (!caster || caster->GetEntry() % 100000 != NPC_OBSIDIUS)
            return;
        if (AuraEffect* effect = GetAura()->GetEffect(EFFECT_0))
            if (aurEff->GetTickNumber() > 1)
                effect->SetAmount(
                    effect->GetAmount() / int32(aurEff->GetTickNumber() - 1) * int32(aurEff->GetTickNumber()));
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(
            spell_coa_brc_twilight_corruption::HandlePeriodic, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class spell_coa_brc_superheated : public AuraScript
{
    PrepareAuraScript(spell_coa_brc_superheated);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        PreventDefaultAction();
        GetTarget()->SetDisplayId(DISPLAY_KARSH_MOLTEN);
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        PreventDefaultAction();
        GetTarget()->RestoreDisplayId();
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
            if (Creature* karsh = GetTarget()->ToCreature())
                if (karsh->AI())
                    karsh->AI()->DoAction(ACTION_LAVA_SPOUT);
    }

    bool CheckProc(ProcEventInfo& )
    {
        return false;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_coa_brc_superheated::CheckProc);
        OnEffectApply += AuraEffectApplyFn(
            spell_coa_brc_superheated::HandleApply, EFFECT_2, SPELL_AURA_TRANSFORM, AURA_EFFECT_HANDLE_REAL);
        OnEffectRemove += AuraEffectRemoveFn(
            spell_coa_brc_superheated::HandleRemove, EFFECT_2, SPELL_AURA_TRANSFORM, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_CoABlackrockCaverns()
{
    new instance_coa_blackrock_caverns();
    RegisterCreatureAI(boss_coa_brc_romogg);
    RegisterCreatureAI(npc_coa_brc_chains_of_woe);
    RegisterCreatureAI(npc_coa_brc_raz);
    RegisterCreatureAI(boss_coa_brc_corla);
    RegisterCreatureAI(npc_coa_brc_corla_zealot);
    RegisterCreatureAI(npc_coa_brc_nether_beam);
    RegisterCreatureAI(boss_coa_brc_karsh);
    RegisterCreatureAI(boss_coa_brc_beauty);
    RegisterCreatureAI(npc_coa_brc_beauty_pup);
    RegisterCreatureAI(boss_coa_brc_obsidius);
    RegisterCreatureAI(npc_coa_brc_shadow_of_obsidius);
    RegisterCreatureAI(npc_coa_brc_trash);
    RegisterCreatureAI(npc_coa_brc_quest_bang);
    RegisterSpellAndAuraScriptPair(spell_coa_brc_damage, spell_coa_brc_damage_aura);
    RegisterSpellScript(spell_coa_brc_superheated);
    RegisterCreatureAI(npc_coa_brc_quicksilver);
    RegisterSpellScript(spell_coa_brc_twilight_corruption);
    RegisterSpellScript(spell_coa_brc_furious_swipe);
}
