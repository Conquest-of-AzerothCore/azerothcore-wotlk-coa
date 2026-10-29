/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAOtherSideDamage.h"
#include "Containers.h"
#include "Creature.h"
#include "GameObject.h"
#include "GameObjectAI.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "TemporarySummon.h"
#include "Vehicle.h"
#include <array>
#include <cmath>
#include <list>
#include <unordered_map>
#include <vector>

namespace
{
using CoAOtherSide::BaseSpellId;
using CoAOtherSide::Damage3;
using CoAOtherSide::Rolled;

enum VaultsCreatures : uint32
{
    NPC_MERCILESS_ECHO = 162700,
    NPC_ECHO_IMAGE = 162701,
    NPC_CHAIN_ZONE = 162702,
    NPC_DARKANDLE = 162703,
    NPC_DECEIVER = 162704,
    NPC_HOLY_CRYSTAL_SEAL = 162705,
    NPC_CANDLE_FLAME = 162706,
    NPC_CANDLE_ZONE = 162707,
    NPC_VOIDFLARE = 162710,
    NPC_HOLY_CRYSTAL_FIGHT = 162723,
    NPC_SHIELD_ZONE = 162724,
    NPC_TORTURER = 162733,
    NPC_PHANTASMAL_BOUND = 162734,
    NPC_FREED_PRISONER = 162735,
    NPC_WRATHFUL_TORMENT = 162736,
    NPC_KOBOLD = 162737,
    NPC_BRUTE = 162738,
    NPC_SOUND_HELPER = 162745,
    NPC_SHADOW_PROJECTION = 162748,
    NPC_KOBOLD_NORMAL = 162759,
    NPC_CORPOREAL_SHADOW = 162761,
    NPC_KOBOLD_ELITE = 162762,
    NPC_BRUTE_ELITE = 162763,
    NPC_CONFESSOR_KONRAD = 162999,
    NPC_KOBOLD_FLAME = 163813,
    NPC_RP_TORTURER = 162984,
    NPC_RP_TORMENT = 162985,
    NPC_RP_PHANTASM = 162986,
    NPC_TRAP_CONTROLLER = 162978,
};

enum VaultsSpells : uint32
{
    SPELL_FIERCE_BLOW = 975011,
    SPELL_SPECTRAL_DESTRUCTION = 256805,
    SPELL_SPECTRAL_DESTRUCTION_RP = 256937,
    SPELL_RP_SHADOWBOLT = 256936,
    SPELL_VOID_ESCAPE = 256811,
    SPELL_CANDLE_HIT_ZONE = 256815,
    SPELL_CANDLE_FIREBALL_HIT = 256817,
    SPELL_HOLY_RING = 256806,
    SPELL_HOLY_CHANNEL_LOOK = 47540,
    SPELL_COSMETIC_CHAINS = 256843,
    SPELL_GROUND_ZONE = 256852,
    SPELL_QUAKE_ZONE = 256917,
    SPELL_SPECTRAL_STRIKE = 256975,
    SPELL_CHAIN_ZONE = 256803,
    SPELL_SUBJUGATING_CHAINS = 256804,
    SPELL_VISUAL_CANDLE_FLAME = 256812,
    SPELL_CANDLES = 256813,
    SPELL_MORE_FIRE = 256814,
    SPELL_CANDLE_FIREBALL = 256816,
    SPELL_DARKANDLE_FLAME = 256818,
    SPELL_EARTHQUAKE = 256819,
    SPELL_ABYSSAL_DEVOUR = 256820,
    SPELL_SHADOWY_RING_VISUAL = 256822,
    SPELL_SHADOWY_RING = 256823,
    SPELL_VOID_PUNISHMENT = 256831,
    SPELL_ENDLESS_AFFLICTION_BOSS = 256832,
    SPELL_VOID_WRATH = 256844,
    SPELL_GROUND_CRACKS = 255878,
    SPELL_ECHO_GLOW = 256916,
    SPELL_HOLY_SHELTER_ZONE = 256846,
    SPELL_SHADOWY_RINGS = 256825,
    SPELL_SHADOWY_RING_INNER = 256821,
    SPELL_SHADOWY_RING_OUTER = 256824,
    SPELL_VOID_CONSUMPTION = 257219,
    SPELL_SOAK_ERUPTION = 256925,
    SPELL_VOID_WRATH_TICK = 256926,
    SPELL_HOLY_SHELTER = 256847,
    SPELL_VOID_ZONE = 256827,
    SPELL_VOIDFLARE = 256927,
    SPELL_SWORD_STRIKE = 256918,
    SPELL_MANA_BURN = 267007,
    SPELL_SILENCE = 267008,
    SPELL_PSYCHIC_SCREAM = 257166,
    SPELL_MANIFEST = 257167,
    SPELL_ENDLESS_AFFLICTION = 256891,
    SPELL_HAUNTING_WRATH = 257171,
    SPELL_PICKAXE_STRIKE = 257175,
    SPELL_DARK_WAX_EXPLOSION = 256893,
    SPELL_CHARGE_IMPACT = 257186,
    SPELL_KOBOLD_FLAME = 256892,
    SPELL_LASH_OF_THE_VOID = 256895,
    SPELL_SHADOWFURY = 256491,
    SPELL_MIND_BLAST = 256962,
    SPELL_ABYSSAL_CRY = 256963,
};

enum VaultsTexts : uint8
{
    SAY_AGGRO = 0,
    SAY_SPECIAL = 1,
    SAY_KILL = 2,
    SAY_LOW = 3,
    SAY_LOWER = 4,
    SAY_DEATH = 5,
    SAY_RANDOM = 6,
    EMOTE_CRYSTAL = 7,
    SAY_FIRE = 7,
    SAY_QUAKE = 8,
    SAY_STRIKE = 2,
    SAY_DESTRUCTION = 3,
    SAY_UNSEALED = 0,
    SAY_AWAKENED = 1,
    SAY_VOID_WRATH = 2,
    SAY_VOIDFLARE = 6,
    SAY_TRASH_AGGRO = 0,
    SAY_TRASH_DEATH = 1,
};

enum VaultsData : uint32
{
    DISPLAY_INVISIBLE = 11686,
    DISPLAY_SOAK_RING = 132245,
    VAULTS_MAP_ID = 936,
    GO_TOWER_BOSS_DOOR = 2300560,
    GO_TOWER_BOSS_BARRIER = 2300561,
    GO_TOWER_BOSS_BARRIER_2 = 2300576,
    SOUND_CHAIN_BREAK = 126821,
    SOUND_HOLY_EXPLOSION = 16539,
    SOUND_QUAKE = 1485,
    KIT_HOLY_NOVA = 163260,
    KIT_SEAL_ERUPTION = 165022,
    KIT_HOLY_CRACKS = 162721,
    KIT_CRYSTAL_SHATTER = 165068,
    KIT_CRYSTAL_NOVA = 10756,
    KIT_INNER_RING_BURST = 165048,
    KIT_OUTER_RING_BURST = 165049,
    KIT_VOID_ERUPTION = 165190,
    KIT_VOID_WRATH_HIT = 165191,
    KIT_FIRE_EXPLOSION = 165037,
};

constexpr uint32 GateCheckMs = 1000;
constexpr uint32 GateOpenAnimMs = 3000;
constexpr Seconds GateGmOpenTime = 60s;
constexpr Seconds GateGoneTime = 7 * 24h;
constexpr uint8 DoorAnimProgress = 255;
constexpr uint32 RpRespawnDelay = 7 * DAY;
constexpr uint32 CandleZoneLifeMs = 5500;
constexpr uint32 CrystalBreakMs = 3000;
constexpr uint32 RingLifeMs = 6000;
constexpr uint32 SoakLifeMs = 4500;
constexpr uint32 SoakDelayMs = 4000;
constexpr float SoakRadius = 4.2f;
constexpr float SoakKnockSpeed = 2.0f;
constexpr float SoakKnockHeight = 18.0f;
constexpr uint32 ShatterFxMs = 3000;
constexpr uint32 KitDelayMs = 300;

enum VaultsActions : int32
{
    ACTION_CANDLE_IGNITE = 1,
    ACTION_CANDLE_LIT,
    ACTION_VOID_WRATH_END,
};

enum VaultsHelperData : uint32
{
    DATA_PLAY_KIT = 1,
};
constexpr float RoomRange = 60.0f;
constexpr float SealRange = 40.0f;
constexpr float TentacleAggroRange = 25.0f;
constexpr float LashRange = 20.0f;
constexpr uint32 LashRetryMs = 1000;
constexpr TriggerCastFlags RelaxedCast = TriggerCastFlags(TRIGGERED_IGNORE_GCD | TRIGGERED_IGNORE_SHAPESHIFT |
    TRIGGERED_IGNORE_CASTER_AURASTATE | TRIGGERED_IGNORE_SET_FACING | TRIGGERED_IGNORE_CASTER_MOUNTED_OR_ON_VEHICLE |
    TRIGGERED_IGNORE_CASTER_AURAS);

uint8 DifficultyIndex(Map const* map)
{
    switch (map->GetDifficulty())
    {
        case DUNGEON_DIFFICULTY_HEROIC:
            return 1;
        case DUNGEON_DIFFICULTY_EPIC:
            return 2;
        default:
            return 0;
    }
}

template <typename T>
T ByDifficulty(Map const* map, T normal, T heroic, T mythic)
{
    switch (DifficultyIndex(map))
    {
        case 1:
            return heroic;
        case 2:
            return mythic;
        default:
            return normal;
    }
}

std::vector<Player*> PlayersInRange(WorldObject const* center, float range)
{
    std::vector<Player*> players;
    for (auto const& ref : center->GetMap()->GetPlayers())
    {
        Player* player = ref.GetSource();
        if (player && player->IsAlive() && !player->IsGameMaster() && center->GetExactDist(player) <= range)
            players.push_back(player);
    }
    return players;
}

Player* RandomPlayer(WorldObject const* center, float range)
{
    std::vector<Player*> players = PlayersInRange(center, range);
    return players.empty() ? nullptr : Acore::Containers::SelectRandomContainerElement(players);
}

struct SpellDamage
{
    Damage3 hit;
    Damage3 tick;
};

std::unordered_map<uint32, SpellDamage> const Damages =
{
    { SPELL_SPECTRAL_DESTRUCTION, { { 289, 2103 }, { 0, 0 } } },
    { SPELL_SUBJUGATING_CHAINS, { { 200, 989 }, { 0, 0 } } },
    { SPELL_DARKANDLE_FLAME, { { 79, 495 }, { 0, 0 } } },
    { SPELL_EARTHQUAKE, { { 300, 1500 }, { 100, 500 } } },
    { SPELL_ENDLESS_AFFLICTION_BOSS, { { 185, 709 }, { 0, 0 } } },
    { SPELL_VOIDFLARE, { { 170, 842 }, { 0, 0 } } },
    { SPELL_VOID_PUNISHMENT, { { 170, 841 }, { 0, 0 } } },
    { SPELL_ENDLESS_AFFLICTION, { { 142, 1111 }, { 0, 0 } } },
    { SPELL_PICKAXE_STRIKE, { { 59, 197 }, { 0, 0 } } },
    { SPELL_DARK_WAX_EXPLOSION, { { 410, 1600 }, { 0, 0 } } },
    { SPELL_CHARGE_IMPACT, { { 80, 400 }, { 0, 0 } } },
    { SPELL_KOBOLD_FLAME, { { 246, 600 }, { 0, 0 } } },
    { SPELL_LASH_OF_THE_VOID, { { 61, 206 }, { 0, 0 } } },
    { SPELL_SHADOWFURY, { { 89, 357 }, { 0, 0 } } },
    { SPELL_ABYSSAL_CRY, { { 110, 559 }, { 0, 0 } } },
};

Damage3 const InnerRingDamage = { 440, 2182 };
Damage3 const OuterRingDamage = { 370, 1844 };
Damage3 const SoakEruptionDamage = { 210, 1045 };
Damage3 const SoakFailDamage = { 450, 2241 };
Damage3 const VoidWrathTickDamage = { 170, 845 };
Damage3 const CandleFireballDamage = { 250, 1302 };

void DealLogged(Unit* caster, Player* target, uint32 spellId, Damage3 const& value)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    if (!info || target->IsImmunedToDamage(caster, info))
        return;
    uint32 const amount = target->SpellDamageBonusTaken(caster, info, uint32(Rolled(caster, target, value, info)), SPELL_DIRECT_DAMAGE);
    SpellNonMeleeDamage damage(caster, target, info, info->GetSchoolMask());
    caster->CalculateSpellDamageTaken(&damage, int32(amount), info);
    Unit::DealDamageMods(target, damage.damage, &damage.absorb);
    caster->DealSpellDamage(&damage, true);
    caster->SendSpellNonMeleeDamageLog(&damage);
}

void SetEngageable(Creature* me, bool engageable, bool keepCombat = false)
{
    if (engageable)
        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
    else
        me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
    me->SetImmuneToAll(!engageable, keepCombat);
    me->SetReactState(engageable ? REACT_AGGRESSIVE : REACT_PASSIVE);
}

void PlayKitDelayed(Creature* helper, uint32 kit)
{
    if (helper && helper->IsAIEnabled)
        helper->AI()->SetData(DATA_PLAY_KIT, kit);
}

void ShatterEffect(Creature* crystal)
{
    if (Creature* fx = crystal->SummonCreature(NPC_SOUND_HELPER, crystal->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, ShatterFxMs))
    {
        PlayKitDelayed(fx, KIT_CRYSTAL_SHATTER);
        PlayKitDelayed(fx, KIT_CRYSTAL_NOVA);
    }
}

bool AnyPlayerNear(Map const* map, Position const& pos, float range)
{
    for (auto const& ref : map->GetPlayers())
        if (Player* player = ref.GetSource())
            if (player->IsAlive() && player->GetExactDist(&pos) <= range)
                return true;
    return false;
}

bool AnyPlayerNear2d(Map const* map, Position const& pos, float range)
{
    for (auto const& ref : map->GetPlayers())
        if (Player* player = ref.GetSource())
            if (player->IsAlive() && player->GetExactDist2d(&pos) <= range)
                return true;
    return false;
}

void KeepAura(Unit* target, uint32 spellId)
{
    if (Aura* aura = target->AddAura(spellId, target))
    {
        aura->SetMaxDuration(-1);
        aura->SetDuration(-1);
    }
}

std::vector<ObjectGuid::LowType> const& BossSpawns(uint32 entry)
{
    static std::unordered_map<uint32, std::vector<ObjectGuid::LowType>> const spawns = []
    {
        std::unordered_map<uint32, std::vector<ObjectGuid::LowType>> result;
        for (auto const& [spawnId, data] : sObjectMgr->GetAllCreatureData())
            if (data.mapid == VAULTS_MAP_ID && (data.id == NPC_MERCILESS_ECHO || data.id == NPC_DARKANDLE))
                result[data.id].push_back(spawnId);
        return result;
    }();
    static std::vector<ObjectGuid::LowType> const none;
    auto itr = spawns.find(entry);
    return itr != spawns.end() ? itr->second : none;
}

bool BossDefeated(Map* map, uint32 entry)
{
    bool defeated = false;
    for (ObjectGuid::LowType spawnId : BossSpawns(entry))
    {
        auto range = map->GetCreatureBySpawnIdStore().equal_range(spawnId);
        for (auto itr = range.first; itr != range.second; ++itr)
        {
            if (itr->second->IsAlive())
                return false;
            defeated = true;
        }
        if (map->GetCreatureRespawnTime(spawnId) > GameTime::GetGameTime().count())
            defeated = true;
    }
    return defeated;
}

uint32 GateBoss(uint32 gateEntry)
{
    switch (gateEntry)
    {
        case GO_TOWER_BOSS_DOOR:
        case GO_TOWER_BOSS_BARRIER:
        case GO_TOWER_BOSS_BARRIER_2:
            return NPC_MERCILESS_ECHO;
        default:
            return NPC_DARKANDLE;
    }
}

struct go_coa_vaults_jail_door : public GameObjectAI
{
    explicit go_coa_vaults_jail_door(GameObject* go) : GameObjectAI(go) { }

    void Reset() override
    {
        me->SetGoAnimProgress(DoorAnimProgress);
        me->SetGoState(GO_STATE_READY);
    }

    bool GossipHello(Player*, bool) override
    {
        me->SetGoState(me->GetGoState() == GO_STATE_READY ? GO_STATE_ACTIVE : GO_STATE_READY);
        return true;
    }
};

struct go_coa_vaults_boss_gate : public GameObjectAI
{
    explicit go_coa_vaults_boss_gate(GameObject* go) : GameObjectAI(go) { }

    void Reset() override
    {
        me->SetGoAnimProgress(DoorAnimProgress);
        _checkMs = 0;
        _openMs = 0;
    }

    bool GossipHello(Player* player, bool) override
    {
        if (player->IsGameMaster() && !_openMs)
            me->DespawnOrUnsummon(0ms, GateGmOpenTime);
        return true;
    }

    void UpdateAI(uint32 diff) override
    {
        if (_openMs)
        {
            if (_openMs > diff)
            {
                _openMs -= diff;
                return;
            }
            _openMs = 0;
            me->DespawnOrUnsummon(0ms, GateGoneTime);
            return;
        }
        if (_checkMs > diff)
        {
            _checkMs -= diff;
            return;
        }
        _checkMs = GateCheckMs;
        if (BossDefeated(me->GetMap(), GateBoss(me->GetEntry())))
        {
            me->SetGoState(GO_STATE_ACTIVE);
            _openMs = GateOpenAnimMs;
        }
        else if (me->GetGoState() != GO_STATE_READY)
            me->SetGoState(GO_STATE_READY);
    }

private:
    uint32 _checkMs = 0;
    uint32 _openMs = 0;
};

enum EchoEvents : uint32
{
    EVENT_ECHO_STRIKE = 1,
    EVENT_ECHO_DESTRUCTION,
    EVENT_ECHO_CHAINS,
    EVENT_ECHO_FIERCE_BLOW,
    EVENT_ECHO_SECOND_LINE,
};

Position const EchoThreshold = { -6748.0947f, -5797.5986f, 164.72157f, 0.0f };
Position const EchoFightPosition = { -6805.836f, -5805.8115f, 169.43356f, 6.283159f };
constexpr float EchoThresholdRadius = 7.0f;
constexpr float EchoRpRange = 40.0f;
constexpr uint32 EchoRpCastFallbackMs = 6500;
constexpr uint32 EchoRpLoopMs = 4500;
constexpr uint32 EchoEngageDelayMs = 3000;
constexpr uint32 PointEchoFight = 1;
constexpr uint32 EchoDestructionGlowMs = 5500;
constexpr int32 EchoSecondLineChance = 90;

struct boss_coa_vaults_echo : public ScriptedAI
{
    explicit boss_coa_vaults_echo(Creature* creature) : ScriptedAI(creature), _summons(creature) { }

    void Reset() override
    {
        _events.Reset();
        _summons.DespawnAll();
        _glowMs = 0;
        SetEngageable(me, _rpDone && !_walking && !_engageMs);
        if (!_rpDone)
        {
            KeepAura(me, SPELL_ECHO_GLOW);
            _loopMs = 0;
        }
    }

    void JustEngagedWith(Unit*) override
    {
        if (!_rpDone || _walking)
            return;
        Talk(SAY_AGGRO);
        _events.ScheduleEvent(EVENT_ECHO_SECOND_LINE, 6s);
        _events.ScheduleEvent(EVENT_ECHO_CHAINS, 5s);
        _events.ScheduleEvent(EVENT_ECHO_FIERCE_BLOW, 6s);
        _events.ScheduleEvent(EVENT_ECHO_STRIKE, 15s);
        _events.ScheduleEvent(EVENT_ECHO_DESTRUCTION, 25s);
    }

    void JustSummoned(Creature* summon) override { _summons.Summon(summon); }

    void OnSpellCast(SpellInfo const* spell) override
    {
        uint32 const baseId = BaseSpellId(spell->Id);
        if (baseId == SPELL_SPECTRAL_DESTRUCTION_RP && _rpTriggered)
            FinishRp();
        else if (baseId == SPELL_SPECTRAL_DESTRUCTION)
            EndGlow();
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != POINT_MOTION_TYPE || id != PointEchoFight)
            return;
        _walking = false;
        me->SetFacingTo(EchoFightPosition.GetOrientation());
        me->SetHomePosition(EchoFightPosition);
        _engageMs = EchoEngageDelayMs;
    }

    void JustDied(Unit*) override
    {
        Talk(SAY_DEATH);
        _summons.DespawnAll();
    }

    void EnterEvadeMode(EvadeReason why) override
    {
        _summons.DespawnAll();
        ScriptedAI::EnterEvadeMode(why);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!_rpDone)
        {
            UpdateRp(diff);
            return;
        }
        if (_engageMs)
        {
            if (_engageMs > diff)
            {
                _engageMs -= diff;
                return;
            }
            _engageMs = 0;
            SetEngageable(me, true);
        }
        if (!UpdateVictim())
            return;
        if (_glowMs)
        {
            if (_glowMs > diff)
                _glowMs -= diff;
            else
                EndGlow();
        }
        _events.Update(diff);
        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;
        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_ECHO_SECOND_LINE:
                    if (roll_chance_i(EchoSecondLineChance))
                        Talk(SAY_SPECIAL);
                    break;
                case EVENT_ECHO_CHAINS:
                    if (Player* player = RandomPlayer(me, RoomRange))
                        me->SummonCreature(NPC_CHAIN_ZONE, player->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 5000);
                    _events.Repeat(ByDifficulty(me->GetMap(), 10s, 4s, 2s));
                    break;
                case EVENT_ECHO_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    _events.Repeat(9s, 11s);
                    break;
                case EVENT_ECHO_STRIKE:
                    Talk(SAY_STRIKE);
                    SummonImages();
                    DoCastVictim(SPELL_SPECTRAL_STRIKE);
                    _events.Repeat(37s);
                    break;
                case EVENT_ECHO_DESTRUCTION:
                    Talk(SAY_DESTRUCTION);
                    me->AddAura(SPELL_ECHO_GLOW, me);
                    _glowMs = EchoDestructionGlowMs;
                    DoCastAOE(SPELL_SPECTRAL_DESTRUCTION);
                    _events.Repeat(37s);
                    break;
                default:
                    break;
            }
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
        }
        DoMeleeAttackIfReady();
    }

private:
    void UpdateRp(uint32 diff)
    {
        if (_rpCastMs)
        {
            if (_rpCastMs > diff)
                _rpCastMs -= diff;
            else
                FinishRp();
            return;
        }
        if (_loopMs > diff)
            _loopMs -= diff;
        else
        {
            _loopMs = EchoRpLoopMs;
            me->InterruptNonMeleeSpells(false);
            DoCastSelf(SPELL_SPECTRAL_DESTRUCTION_RP);
        }
        if (_rpCheckMs > diff)
        {
            _rpCheckMs -= diff;
            return;
        }
        _rpCheckMs = 500;
        if (!AnyPlayerNear(me->GetMap(), EchoThreshold, EchoThresholdRadius) && !AnyPlayerNear(me->GetMap(), me->GetPosition(), 25.0f))
            return;
        me->InterruptNonMeleeSpells(false);
        _rpTriggered = true;
        DoCastSelf(SPELL_SPECTRAL_DESTRUCTION_RP);
        _rpCastMs = EchoRpCastFallbackMs;
    }

    void FinishRp()
    {
        if (_rpDone)
            return;
        _rpDone = true;
        _rpCastMs = 0;
        me->RemoveAurasDueToSpell(SPELL_ECHO_GLOW);
        std::list<Creature*> mobs;
        me->GetCreatureListWithEntryInGrid(mobs, { NPC_RP_TORTURER, NPC_RP_TORMENT, NPC_RP_PHANTASM }, EchoRpRange);
        for (Creature* mob : mobs)
            if (mob->IsAlive())
                Unit::Kill(me, mob);
        if (me->GetExactDist(&EchoFightPosition) > 1.5f)
        {
            _walking = true;
            me->SetWalk(true);
            me->GetMotionMaster()->MovePoint(PointEchoFight, EchoFightPosition);
            return;
        }
        MovementInform(POINT_MOTION_TYPE, PointEchoFight);
    }

    void EndGlow()
    {
        _glowMs = 0;
        me->RemoveAurasDueToSpell(SPELL_ECHO_GLOW);
    }

    void SummonImages()
    {
        std::vector<Player*> targets;
        for (Player* player : PlayersInRange(me, RoomRange))
            if (player != me->GetVictim())
                targets.push_back(player);
        Acore::Containers::RandomShuffle(targets);
        uint32 const wanted = ByDifficulty<uint32>(me->GetMap(), 1, 2, uint32(targets.size()));
        targets.resize(std::min<size_t>(targets.size(), wanted));
        float const start = frand(0.0f, 2.0f * float(M_PI));
        for (size_t i = 0; i < targets.size(); ++i)
        {
            float const angle = start + 2.0f * float(M_PI) * float(i) / float(targets.size());
            float const dist = frand(8.0f, 15.0f);
            Position const pos(me->GetPositionX() + dist * std::cos(angle), me->GetPositionY() + dist * std::sin(angle),
                me->GetPositionZ(), angle + float(M_PI));
            if (Creature* image = me->SummonCreature(NPC_ECHO_IMAGE, pos, TEMPSUMMON_TIMED_DESPAWN, 5000))
                if (image->IsAIEnabled)
                    image->AI()->SetGUID(targets[i]->GetGUID(), 0);
        }
    }

    SummonList _summons;
    EventMap _events;
    uint32 _rpCheckMs = 0;
    uint32 _rpCastMs = 0;
    uint32 _loopMs = 0;
    uint32 _engageMs = 0;
    uint32 _glowMs = 0;
    bool _rpDone = false;
    bool _rpTriggered = false;
    bool _walking = false;
};

struct npc_coa_vaults_echo_rp : public ScriptedAI
{
    explicit npc_coa_vaults_echo_rp(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
        me->SetRespawnDelay(RpRespawnDelay);
        _actMs = urand(500, 2000);
        _spellMs = urand(3000, 8000);
        if (me->GetEntry() != NPC_RP_PHANTASM)
            me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_READY1H);
    }

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }

    void UpdateAI(uint32 diff) override
    {
        _spellMs = _spellMs > diff ? _spellMs - diff : 0;
        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;
        if (_actMs > diff)
        {
            _actMs -= diff;
            return;
        }
        _actMs = urand(1600, 2400);
        Creature* echo = me->FindNearestCreature(NPC_MERCILESS_ECHO, EchoRpRange);
        if (!echo)
            return;
        me->SetFacingToObject(echo);
        if (me->GetEntry() == NPC_RP_PHANTASM)
        {
            DoCast(echo, SPELL_RP_SHADOWBOLT);
            _actMs = urand(3500, 4500);
            return;
        }
        if (me->GetEntry() == NPC_RP_TORMENT && !_spellMs && !AnyPlayerNear(me->GetMap(), me->GetPosition(), 20.0f))
        {
            DoCastSelf(SPELL_ENDLESS_AFFLICTION);
            _spellMs = 8000;
            return;
        }
        me->HandleEmoteCommand(EMOTE_ONESHOT_ATTACK1H);
    }

private:
    uint32 _actMs = 0;
    uint32 _spellMs = 0;
};

enum DarkandleEvents : uint32
{
    EVENT_DARK_APPEAR = 1,
    EVENT_DARK_CANDLES,
    EVENT_DARK_INTRO_LINE,
    EVENT_DARK_READY,
    EVENT_DARK_MORE_FIRE,
    EVENT_DARK_FIRE_CIRCLES,
    EVENT_DARK_FIRE_LINE,
    EVENT_DARK_EARTHQUAKE,
    EVENT_DARK_QUAKE_END,
    EVENT_DARK_FIERCE_BLOW,
};

Position const DarkandleIntroPoint = { -6508.65f, -5964.25f, 138.21f, 3.15885f };
Position const DarkandleDevourPoint = { -6524.63f, -5965.32f, 138.21f, 0.0219462f };
Position const DarkandleTrigger = { -6492.524f, -5964.035f, 138.21f, 0.0f };
std::array<Position, 9> const DarkandleCandles =
{{
    { -6490.24f, -5970.85f, 160.00f, 0.0f },
    { -6483.72f, -5965.45f, 162.67f, 0.0f },
    { -6491.56f, -5958.88f, 159.70f, 0.0f },
    { -6484.72f, -5960.50f, 158.78f, 0.0f },
    { -6485.09f, -5970.84f, 157.63f, 0.0f },
    { -6495.72f, -5958.32f, 154.66f, 0.0f },
    { -6494.75f, -5972.37f, 154.41f, 0.0f },
    { -6498.02f, -5974.32f, 153.47f, 0.0f },
    { -6497.11f, -5954.66f, 153.26f, 0.0f },
}};
constexpr float DarkandleTriggerRange = 12.0f;
constexpr float DarkandleAttackRange = 100.0f;
constexpr float DarkandleArenaRadius = 20.0f;
constexpr float DarkandleCandleRange = 60.0f;
constexpr uint32 EarthquakeRadiusIndex = 13;
constexpr uint32 EarthquakeMarkerMs = 3000;
constexpr uint32 DarkandleEscapeMs = 3000;
constexpr Milliseconds DarkandleTeleportDelay = 3800ms;
constexpr Milliseconds DarkandleAfterTeleport = 1100ms;
constexpr uint32 DarkandleFireCircles = 10;
constexpr float DarkandleCircleScatter = 3.0f;

struct boss_coa_vaults_darkandle : public ScriptedAI
{
    explicit boss_coa_vaults_darkandle(Creature* creature) : ScriptedAI(creature), _summons(creature) { }

    void Reset() override
    {
        _events.Reset();
        _summons.DespawnAll();
        me->RemoveAllDynObjects();
        _devoured = false;
        _pleaded = false;
        _escapeMs = 0;
        _devourMs = 0;
        if (_introDone)
        {
            SetEngageable(me, true);
            return;
        }
        _introStarted = false;
        me->RestoreDisplayId();
        SetEngageable(me, false);
        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
    }

    void JustEngagedWith(Unit*) override
    {
        if (!_introDone)
            return;
        LightCandles(true);
        _events.ScheduleEvent(EVENT_DARK_MORE_FIRE, 5s);
        _events.ScheduleEvent(EVENT_DARK_EARTHQUAKE, 18500ms);
        _events.ScheduleEvent(EVENT_DARK_FIERCE_BLOW, 9s);
    }

    void JustSummoned(Creature* summon) override
    {
        if (summon->GetEntry() == NPC_CANDLE_FLAME)
            _candles.push_back(summon->GetGUID());
        else
            _summons.Summon(summon);
    }

    void KilledUnit(Unit* victim) override
    {
        if (victim->IsPlayer())
            Talk(SAY_KILL);
    }

    void DamageTaken(Unit*, uint32& damage, DamageEffectType, SpellSchoolMask) override
    {
        if (!_devoured && me->HealthBelowPctDamaged(ByDifficulty<int32>(me->GetMap(), 15, 20, 30), damage))
            StartEscape();
        if (!_pleaded && me->HealthBelowPctDamaged(10, damage))
        {
            _pleaded = true;
            Talk(SAY_LOWER);
        }
    }

    void JustDied(Unit*) override
    {
        Talk(SAY_DEATH);
        _summons.DespawnAll();
        me->RemoveAllDynObjects();
    }

    void EnterEvadeMode(EvadeReason why) override
    {
        _summons.DespawnAll();
        me->RemoveAllDynObjects();
        _escapeMs = 0;
        _devourMs = 0;
        me->SetControlled(false, UNIT_STATE_ROOT);
        ScriptedAI::EnterEvadeMode(why);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!_introDone)
        {
            UpdateIntro(diff);
            return;
        }
        if (_escapeMs)
        {
            if (_escapeMs > diff)
                _escapeMs -= diff;
            else
                EscapeTeleport();
            return;
        }
        if (_devourMs)
        {
            if (_devourMs > diff)
                _devourMs -= diff;
            else
                FinishEscape();
            return;
        }
        if (!UpdateVictim())
            return;
        _events.Update(diff);
        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;
        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_DARK_MORE_FIRE:
                    DoCastSelf(SPELL_MORE_FIRE);
                    _events.ScheduleEvent(EVENT_DARK_FIRE_CIRCLES, 3s);
                    _events.Repeat(20s);
                    break;
                case EVENT_DARK_FIRE_CIRCLES:
                    FireCircles();
                    _events.ScheduleEvent(EVENT_DARK_FIRE_LINE, 4s);
                    break;
                case EVENT_DARK_FIRE_LINE:
                    Talk(SAY_FIRE);
                    break;
                case EVENT_DARK_EARTHQUAKE:
                    Talk(SAY_QUAKE);
                    MarkEarthquake();
                    DoCastAOE(SPELL_EARTHQUAKE);
                    _events.ScheduleEvent(EVENT_DARK_QUAKE_END, 7s);
                    _events.Repeat(20s);
                    break;
                case EVENT_DARK_QUAKE_END:
                    me->RemoveAllDynObjects();
                    break;
                case EVENT_DARK_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    _events.Repeat(6s, 8s);
                    break;
                default:
                    break;
            }
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
        }
        DoMeleeAttackIfReady();
    }

private:
    void UpdateIntro(uint32 diff)
    {
        if (!_introStarted)
        {
            if (AnyPlayerNear2d(me->GetMap(), DarkandleTrigger, DarkandleTriggerRange))
            {
                _introStarted = true;
                DoCastSelf(SPELL_VOID_ESCAPE);
                _events.ScheduleEvent(EVENT_DARK_APPEAR, DarkandleTeleportDelay);
            }
            return;
        }
        _events.Update(diff);
        switch (_events.ExecuteEvent())
        {
            case EVENT_DARK_APPEAR:
                TeleportTo(DarkandleIntroPoint);
                me->SetHomePosition(DarkandleIntroPoint);
                _events.ScheduleEvent(EVENT_DARK_CANDLES, DarkandleAfterTeleport);
                break;
            case EVENT_DARK_CANDLES:
                LightCandles(false);
                DoCastSelf(SPELL_CANDLES);
                _events.ScheduleEvent(EVENT_DARK_INTRO_LINE, 4500ms);
                _events.ScheduleEvent(EVENT_DARK_READY, 6500ms);
                break;
            case EVENT_DARK_INTRO_LINE:
                Talk(SAY_AGGRO);
                break;
            case EVENT_DARK_READY:
                _introDone = true;
                SetEngageable(me, true);
                Talk(SAY_SPECIAL);
                if (Player* player = me->SelectNearestPlayer(DarkandleAttackRange))
                    AttackStart(player);
                break;
            default:
                break;
        }
    }

    void TeleportTo(Position const& pos)
    {
        me->GetMotionMaster()->Clear();
        me->StopMoving();
        me->NearTeleportTo(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), pos.GetOrientation());
    }

    void MarkEarthquake()
    {
        Creature* marker = me->SummonCreature(NPC_SOUND_HELPER, me->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, EarthquakeMarkerMs);
        if (!marker)
            return;
        marker->AddAura(SPELL_QUAKE_ZONE, marker);
    }

    void StartEscape()
    {
        _devoured = true;
        Talk(SAY_LOW);
        me->InterruptNonMeleeSpells(false);
        SetEngageable(me, false, true);
        me->AttackStop();
        me->GetMotionMaster()->Clear();
        me->StopMoving();
        me->SetControlled(true, UNIT_STATE_ROOT);
        DoCastSelf(SPELL_VOID_ESCAPE);
        _escapeMs = DarkandleEscapeMs;
    }

    void EscapeTeleport()
    {
        _escapeMs = 0;
        TeleportTo(DarkandleDevourPoint);
        _devourMs = uint32(DarkandleAfterTeleport.count());
    }

    void FinishEscape()
    {
        _devourMs = 0;
        me->SetControlled(false, UNIT_STATE_ROOT);
        SetEngageable(me, true, true);
        DoCastAOE(SPELL_ABYSSAL_DEVOUR);
    }

    void LightCandles(bool instant)
    {
        _candles.clear();
        std::list<Creature*> placed;
        me->GetCreatureListWithEntryInGrid(placed, NPC_CANDLE_FLAME, DarkandleCandleRange);
        for (Creature* candle : placed)
            if (candle->IsAlive())
                _candles.push_back(candle->GetGUID());
        if (_candles.empty())
            for (Position const& pos : DarkandleCandles)
                me->SummonCreature(NPC_CANDLE_FLAME, pos, TEMPSUMMON_MANUAL_DESPAWN);
        for (ObjectGuid const& guid : _candles)
            if (Creature* candle = ObjectAccessor::GetCreature(*me, guid))
                candle->AI()->DoAction(instant ? ACTION_CANDLE_LIT : ACTION_CANDLE_IGNITE);
    }

    void FireCircles()
    {
        std::vector<Position> spots;
        std::vector<Player*> players = PlayersInRange(me, DarkandleArenaRadius + 15.0f);
        for (std::size_t i = 0; spots.size() < DarkandleFireCircles * 2 / 3 && !players.empty(); ++i)
        {
            Player const* player = players[i % players.size()];
            float const angle = frand(0.0f, 2.0f * float(M_PI));
            float const dist = i < players.size() ? 0.0f : frand(1.0f, DarkandleCircleScatter * 2.0f);
            spots.emplace_back(player->GetPositionX() + dist * std::cos(angle), player->GetPositionY() + dist * std::sin(angle),
                player->GetPositionZ(), 0.0f);
        }
        Position const center = me->GetHomePosition();
        while (spots.size() < DarkandleFireCircles)
        {
            float const angle = frand(0.0f, 2.0f * float(M_PI));
            float const dist = frand(3.0f, DarkandleArenaRadius);
            float const x = center.GetPositionX() + dist * std::cos(angle);
            float const y = center.GetPositionY() + dist * std::sin(angle);
            float z = me->GetMap()->GetHeight(me->GetPhaseMask(), x, y, center.GetPositionZ() + 5.0f);
            if (z <= INVALID_HEIGHT)
                z = center.GetPositionZ();
            spots.emplace_back(x, y, z, 0.0f);
        }
        for (std::size_t i = 0; i < spots.size(); ++i)
        {
            Creature* zone = me->SummonCreature(NPC_CANDLE_ZONE, spots[i], TEMPSUMMON_TIMED_DESPAWN, CandleZoneLifeMs);
            if (zone && !_candles.empty())
                zone->AI()->SetGUID(_candles[i % _candles.size()], int32(i));
        }
    }

    SummonList _summons;
    EventMap _events;
    std::vector<ObjectGuid> _candles;
    uint32 _escapeMs = 0;
    uint32 _devourMs = 0;
    bool _introStarted = false;
    bool _introDone = false;
    bool _devoured = false;
    bool _pleaded = false;
};

enum DeceiverEvents : uint32
{
    EVENT_DEC_VOIDFLARE = 1,
    EVENT_DEC_INNER_RING,
    EVENT_DEC_INNER_BURST,
    EVENT_DEC_OUTER_RING,
    EVENT_DEC_OUTER_BURST,
    EVENT_DEC_SOAK,
    EVENT_DEC_CRYSTAL,
    EVENT_DEC_VOID_WRATH,
    EVENT_DEC_FIERCE_BLOW,
    EVENT_DEC_ERUPTION,
    EVENT_DEC_HOLY_CRACKS,
    EVENT_DEC_SEAL_RING,
    EVENT_DEC_ROAR,
    EVENT_DEC_AWAKE,
};

constexpr std::array<Milliseconds, 4> DeceiverEruptions = { 2s, 6s, 11s, 13s };
constexpr Milliseconds DeceiverHolyCracksAt = 12s;
constexpr Milliseconds DeceiverSealRingAt = 14s;
constexpr Milliseconds DeceiverRoarAt = 15500ms;
constexpr Milliseconds DeceiverAwakeAt = 17s;
constexpr uint32 VoidflareHoldMs = 1000;
constexpr Milliseconds DeceiverCycle = 40s;
constexpr Milliseconds DeceiverRingDelay = 5s;
constexpr uint32 DeceiverVeilRecastMs = 29000;
constexpr float InnerRingRadius = 9.5f;
constexpr float OuterRingRadius = 18.5f;
constexpr float CrystalMinDistance = 6.0f;
constexpr float CrystalMaxDistance = 16.0f;

struct boss_coa_vaults_deceiver : public ScriptedAI
{
    explicit boss_coa_vaults_deceiver(Creature* creature) : ScriptedAI(creature), _summons(creature) { }

    void Reset() override
    {
        _events.Reset();
        _summons.DespawnAll();
        _holyGuid.Clear();
        _shadowGuid.Clear();
        _innerGuid.Clear();
        _outerGuid.Clear();
        _cracksGuid.Clear();
        _flareLock = false;
        _flareHoldMs = 0;
        me->SetCombatMovement(false);
        me->SetControlled(true, UNIT_STATE_ROOT);
        me->RemoveAurasDueToSpell(SPELL_SHADOWY_RING_INNER);
        if (_awakened)
        {
            SetEngageable(me, true);
            return;
        }
        _breaking = false;
        _checkMs = 1000;
        _veilMs = 0;
        SetEngageable(me, false);
    }

    void JustEngagedWith(Unit*) override
    {
        if (!_awakened)
            return;
        _events.ScheduleEvent(EVENT_DEC_VOIDFLARE, 7s);
        _events.ScheduleEvent(EVENT_DEC_INNER_RING, 20s);
        _events.ScheduleEvent(EVENT_DEC_OUTER_RING, 25s);
        _events.ScheduleEvent(EVENT_DEC_SOAK, 30s);
        _events.ScheduleEvent(EVENT_DEC_CRYSTAL, 35s);
        _events.ScheduleEvent(EVENT_DEC_VOID_WRATH, 40s);
        _events.ScheduleEvent(EVENT_DEC_FIERCE_BLOW, 10s);
    }

    void JustSummoned(Creature* summon) override { _summons.Summon(summon); }

    void DoAction(int32 action) override
    {
        if (action != ACTION_VOID_WRATH_END)
            return;
        _summons.DespawnEntry(NPC_SHIELD_ZONE);
        _summons.DespawnEntry(NPC_HOLY_CRYSTAL_FIGHT);
    }

    void JustDied(Unit*) override
    {
        Talk(SAY_DEATH);
        _summons.DespawnAll();
    }

    void EnterEvadeMode(EvadeReason why) override
    {
        _summons.DespawnAll();
        ScriptedAI::EnterEvadeMode(why);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!_awakened)
        {
            UpdateSeal(diff);
            return;
        }
        if (_flareLock)
        {
            _events.Update(diff);
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
            if (_flareHoldMs > diff)
            {
                _flareHoldMs -= diff;
                return;
            }
            _flareLock = false;
            _flareHoldMs = 0;
            diff = 0;
        }
        if (!UpdateVictim())
            return;
        _events.Update(diff);
        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;
        if (Unit* victim = me->GetVictim())
            if (me->GetTarget() != victim->GetGUID())
                me->SetTarget(victim->GetGUID());
        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_DEC_VOIDFLARE:
                    CastVoidflare();
                    _events.Repeat(DeceiverCycle);
                    break;
                case EVENT_DEC_INNER_RING:
                    DoCastSelf(SPELL_SHADOWY_RINGS, true);
                    _innerGuid = ShowRing(SPELL_SHADOWY_RING_INNER);
                    _events.ScheduleEvent(EVENT_DEC_INNER_BURST, DeceiverRingDelay);
                    _events.Repeat(DeceiverCycle);
                    break;
                case EVENT_DEC_INNER_BURST:
                    BurstRing(_innerGuid, 0.0f, InnerRingRadius, SPELL_SHADOWY_RING, InnerRingDamage, KIT_INNER_RING_BURST);
                    break;
                case EVENT_DEC_OUTER_RING:
                    _outerGuid = ShowRing(SPELL_SHADOWY_RING_VISUAL);
                    _events.ScheduleEvent(EVENT_DEC_OUTER_BURST, DeceiverRingDelay);
                    _events.Repeat(DeceiverCycle);
                    break;
                case EVENT_DEC_OUTER_BURST:
                    BurstRing(_outerGuid, InnerRingRadius, OuterRingRadius, SPELL_SHADOWY_RING_OUTER, OuterRingDamage, KIT_OUTER_RING_BURST);
                    break;
                case EVENT_DEC_SOAK:
                    if (Player* player = RandomPlayer(me, RoomRange))
                        me->SummonCreature(NPC_TRAP_CONTROLLER, player->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, SoakLifeMs);
                    _events.Repeat(DeceiverCycle);
                    break;
                case EVENT_DEC_CRYSTAL:
                    SpawnHelpCrystal();
                    _events.Repeat(DeceiverCycle);
                    break;
                case EVENT_DEC_VOID_WRATH:
                    Talk(SAY_VOID_WRATH);
                    DoCastSelf(SPELL_VOID_WRATH);
                    _events.Repeat(DeceiverCycle);
                    break;
                case EVENT_DEC_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    _events.Repeat(10s, 12s);
                    break;
                default:
                    break;
            }
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
        }
        DoMeleeAttackIfReady();
    }

private:
    void UpdateSeal(uint32 diff)
    {
        if (_breaking)
        {
            _events.Update(diff);
            while (uint32 eventId = _events.ExecuteEvent())
                AwakenEvent(eventId);
            return;
        }
        if (_holyGuid.IsEmpty())
            SummonSeal();
        if (_veilMs > diff)
            _veilMs -= diff;
        else
        {
            _veilMs = DeceiverVeilRecastMs;
            DoCastSelf(SPELL_VOID_CONSUMPTION);
        }
        if (_checkMs > diff)
        {
            _checkMs -= diff;
            return;
        }
        _checkMs = 1000;
        std::list<Creature*> crystals;
        me->GetCreatureListWithEntryInGrid(crystals, NPC_HOLY_CRYSTAL_SEAL, SealRange);
        for (Creature* crystal : crystals)
            if (crystal->IsAlive())
                return;
        me->InterruptNonMeleeSpells(false);
        me->PlayDirectSound(SOUND_CHAIN_BREAK);
        Talk(SAY_UNSEALED);
        _breaking = true;
        _events.Reset();
        for (Milliseconds at : DeceiverEruptions)
            _events.ScheduleEvent(EVENT_DEC_ERUPTION, at);
        _events.ScheduleEvent(EVENT_DEC_HOLY_CRACKS, DeceiverHolyCracksAt);
        _events.ScheduleEvent(EVENT_DEC_SEAL_RING, DeceiverSealRingAt);
        _events.ScheduleEvent(EVENT_DEC_ROAR, DeceiverRoarAt);
        _events.ScheduleEvent(EVENT_DEC_AWAKE, DeceiverAwakeAt);
    }

    void SummonSeal()
    {
        Position const center = me->GetHomePosition();
        if (Creature* holy = me->SummonCreature(NPC_SOUND_HELPER, center, TEMPSUMMON_MANUAL_DESPAWN))
        {
            _holyGuid = holy->GetGUID();
            KeepAura(holy, SPELL_HOLY_RING);
        }
        if (Creature* shadow = me->SummonCreature(NPC_SOUND_HELPER, center, TEMPSUMMON_MANUAL_DESPAWN))
        {
            _shadowGuid = shadow->GetGUID();
            KeepAura(shadow, SPELL_VOID_ZONE);
        }
    }

    void AwakenEvent(uint32 eventId)
    {
        switch (eventId)
        {
            case EVENT_DEC_ERUPTION:
                ShowCracks();
                me->SendPlaySpellVisual(KIT_SEAL_ERUPTION);
                me->PlayDirectSound(SOUND_QUAKE);
                break;
            case EVENT_DEC_HOLY_CRACKS:
                me->SendPlaySpellVisual(KIT_HOLY_CRACKS);
                for (ObjectGuid const& guid : { _holyGuid, _shadowGuid })
                    if (Creature* helper = ObjectAccessor::GetCreature(*me, guid))
                        helper->DespawnOrUnsummon();
                break;
            case EVENT_DEC_SEAL_RING:
                KeepAura(me, SPELL_SHADOWY_RING_INNER);
                break;
            case EVENT_DEC_ROAR:
                me->HandleEmoteCommand(EMOTE_ONESHOT_BATTLE_ROAR);
                break;
            case EVENT_DEC_AWAKE:
                me->RemoveAurasDueToSpell(SPELL_SHADOWY_RING_INNER);
                if (Creature* cracks = ObjectAccessor::GetCreature(*me, _cracksGuid))
                    cracks->DespawnOrUnsummon();
                _breaking = false;
                _awakened = true;
                SetEngageable(me, true);
                Talk(SAY_AWAKENED);
                break;
            default:
                break;
        }
    }

    void ShowCracks()
    {
        if (ObjectAccessor::GetCreature(*me, _cracksGuid))
            return;
        if (Creature* cracks = me->SummonCreature(NPC_SOUND_HELPER, me->GetHomePosition(), TEMPSUMMON_MANUAL_DESPAWN))
        {
            _cracksGuid = cracks->GetGUID();
            KeepAura(cracks, SPELL_GROUND_CRACKS);
        }
    }

    void CastVoidflare()
    {
        if (Unit* victim = me->GetVictim())
        {
            float const angle = me->GetAngle(victim);
            me->SetOrientation(angle);
            me->SetFacingTo(angle);
        }
        me->SetTarget(ObjectGuid::Empty);
        Talk(SAY_VOIDFLARE);
        DoCastSelf(SPELL_VOIDFLARE);
        _flareLock = me->HasUnitState(UNIT_STATE_CASTING);
        _flareHoldMs = VoidflareHoldMs;
    }

    ObjectGuid ShowRing(uint32 spellId)
    {
        Creature* ring = me->SummonCreature(NPC_SOUND_HELPER, me->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, RingLifeMs);
        if (!ring)
            return ObjectGuid::Empty;
        KeepAura(ring, spellId);
        return ring->GetGUID();
    }

    void BurstRing(ObjectGuid const& ringGuid, float minRadius, float maxRadius, uint32 spellId, Damage3 const& damage, uint32 kit)
    {
        Creature* ring = ObjectAccessor::GetCreature(*me, ringGuid);
        Unit* center = ring ? static_cast<Unit*>(ring) : me;
        for (Player* player : PlayersInRange(center, maxRadius))
            if (center->GetExactDist2d(player) >= minRadius)
                DealLogged(me, player, spellId, damage);
        if (ring)
        {
            ring->SendPlaySpellVisual(kit);
            ring->DespawnOrUnsummon(500ms);
        }
    }

    void SpawnHelpCrystal()
    {
        Talk(EMOTE_CRYSTAL);
        float const angle = frand(0.0f, 2.0f * float(M_PI));
        float const dist = frand(CrystalMinDistance, CrystalMaxDistance);
        Position const center = me->GetHomePosition();
        float const x = center.GetPositionX() + dist * std::cos(angle);
        float const y = center.GetPositionY() + dist * std::sin(angle);
        float z = me->GetMap()->GetHeight(me->GetPhaseMask(), x, y, center.GetPositionZ() + 5.0f);
        if (z <= INVALID_HEIGHT)
            z = center.GetPositionZ();
        if (Creature* crystal = me->SummonCreature(NPC_HOLY_CRYSTAL_FIGHT, { x, y, z, 0.0f }, TEMPSUMMON_MANUAL_DESPAWN))
        {
            PlayKitDelayed(crystal, KIT_HOLY_NOVA);
            crystal->PlayDirectSound(SOUND_HOLY_EXPLOSION);
        }
    }

    SummonList _summons;
    EventMap _events;
    ObjectGuid _holyGuid;
    ObjectGuid _shadowGuid;
    ObjectGuid _innerGuid;
    ObjectGuid _outerGuid;
    ObjectGuid _cracksGuid;
    uint32 _checkMs = 0;
    uint32 _veilMs = 0;
    uint32 _flareHoldMs = 0;
    bool _awakened = false;
    bool _breaking = false;
    bool _flareLock = false;
};

constexpr uint32 HelperTickMs = 250;
constexpr float ShelterRadius = 6.4f;
constexpr float CandleZoneRadius = 3.0f;
constexpr uint32 CandleShotMs = 3000;
constexpr uint32 CandleImpactMs = 4000;
constexpr uint32 CandleStaggerMs = 150;

struct npc_coa_vaults_helper : public ScriptedAI
{
    explicit npc_coa_vaults_helper(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
        me->SetControlled(true, UNIT_STATE_ROOT);
        _ageMs = 0;
        _tickMs = 0;
        _fired = false;
        _shot = false;
        switch (me->GetEntry())
        {
            case NPC_CHAIN_ZONE:
                DoCastSelf(SPELL_CHAIN_ZONE, true);
                break;
            case NPC_CANDLE_FLAME:
            case NPC_SOUND_HELPER:
                me->SetDisableGravity(true);
                break;
            case NPC_CANDLE_ZONE:
                me->AddAura(SPELL_CANDLE_HIT_ZONE, me);
                break;
            case NPC_VOIDFLARE:
                DoCastSelf(SPELL_VOID_ZONE, true);
                break;
            case NPC_SHIELD_ZONE:
                KeepAura(me, SPELL_HOLY_SHELTER_ZONE);
                break;
            case NPC_TRAP_CONTROLLER:
                me->SetDisplayId(DISPLAY_INVISIBLE);
                _soaked = true;
                break;
            default:
                break;
        }
    }

    void SetData(uint32 id, uint32 value) override
    {
        if (id == DATA_PLAY_KIT)
            _kits.push_back(value);
    }

    void DoAction(int32 action) override
    {
        if (me->GetEntry() != NPC_CANDLE_FLAME || me->HasAura(SPELL_VISUAL_CANDLE_FLAME))
            return;
        if (action == ACTION_CANDLE_IGNITE)
            me->CastSpell(me, SPELL_VISUAL_CANDLE_FLAME, false);
        else if (action == ACTION_CANDLE_LIT && !me->HasUnitState(UNIT_STATE_CASTING))
            me->AddAura(SPELL_VISUAL_CANDLE_FLAME, me);
    }

    void SetGUID(ObjectGuid const& guid, int32 index) override
    {
        _candle = guid;
        _staggerMs = uint32(std::max(index, 0)) * CandleStaggerMs;
    }

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }

    void OnSpellClick(Unit* clicker, bool&) override
    {
        Player* player = clicker ? clicker->ToPlayer() : nullptr;
        if (!player || me->GetEntry() != NPC_HOLY_CRYSTAL_FIGHT || _fired)
            return;
        _fired = true;
        ShatterEffect(me);
        player->KilledMonsterCredit(NPC_HOLY_CRYSTAL_SEAL);
        TempSummon* summon = me->ToTempSummon();
        Creature* boss = summon && summon->GetSummonerUnit() ? summon->GetSummonerUnit()->ToCreature() : nullptr;
        if (boss)
            boss->SummonCreature(NPC_SHIELD_ZONE, me->GetPosition(), TEMPSUMMON_MANUAL_DESPAWN);
        me->DespawnOrUnsummon(100ms);
    }

    void UpdateAI(uint32 diff) override
    {
        _ageMs += diff;
        if (_tickMs > diff)
        {
            _tickMs -= diff;
            return;
        }
        _tickMs = HelperTickMs;
        if (!_kits.empty() && _ageMs >= KitDelayMs)
        {
            for (uint32 kit : _kits)
                me->SendPlaySpellVisual(kit);
            _kits.clear();
        }
        switch (me->GetEntry())
        {
            case NPC_CHAIN_ZONE:
                if (!_fired && _ageMs >= 2500)
                {
                    _fired = true;
                    DoCastSelf(SPELL_SUBJUGATING_CHAINS, true);
                }
                break;
            case NPC_VOIDFLARE:
                if (!_fired && _ageMs >= 2500)
                {
                    _fired = true;
                    DoCastSelf(SPELL_VOIDFLARE, true);
                }
                break;
            case NPC_CANDLE_ZONE:
                UpdateCandleZone();
                break;
            case NPC_ECHO_IMAGE:
                if (!_fired && _ageMs >= 500)
                {
                    _fired = true;
                    Player* player = ObjectAccessor::GetPlayer(*me, _candle);
                    if (!player || !player->IsAlive())
                        player = RandomPlayer(me, RoomRange);
                    if (player)
                    {
                        me->SetFacingToObject(player);
                        DoCast(player, SPELL_SPECTRAL_STRIKE);
                    }
                }
                break;
            case NPC_SHIELD_ZONE:
                for (Player* player : PlayersInRange(me, ShelterRadius))
                    me->AddAura(SPELL_HOLY_SHELTER, player);
                break;
            case NPC_TRAP_CONTROLLER:
                UpdateSoak();
                break;
            default:
                break;
        }
    }

private:
    void UpdateSoak()
    {
        if (_candle.IsEmpty())
        {
            if (Creature* ring = me->SummonCreature(NPC_SOUND_HELPER, me->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, SoakLifeMs))
            {
                ring->SetDisplayId(DISPLAY_SOAK_RING);
                _candle = ring->GetGUID();
            }
        }
        if (_fired)
            return;
        bool const soaked = !PlayersInRange(me, SoakRadius).empty();
        if (soaked != _soaked)
        {
            _soaked = soaked;
            if (soaked)
                me->SetDisplayId(DISPLAY_INVISIBLE);
            else
                me->RestoreDisplayId();
        }
        if (_ageMs < SoakDelayMs)
            return;
        _fired = true;
        if (Creature* ring = ObjectAccessor::GetCreature(*me, _candle))
            ring->DespawnOrUnsummon(500ms);
        ResolveSoak();
    }

    void ResolveSoak()
    {
        std::vector<Player*> soakers = PlayersInRange(me, SoakRadius);
        if (!soakers.empty())
        {
            Player* soaker = soakers.front();
            me->SendPlaySpellVisual(KIT_VOID_ERUPTION);
            DealLogged(me, soaker, SPELL_SOAK_ERUPTION, SoakEruptionDamage);
            soaker->KnockbackFrom(me->GetPositionX(), me->GetPositionY(), SoakKnockSpeed, SoakKnockHeight);
        }
        else
        {
            me->SendPlaySpellVisual(KIT_VOID_WRATH_HIT);
            for (Player* player : PlayersInRange(me, RoomRange))
                DealLogged(me, player, SPELL_VOID_WRATH_TICK, SoakFailDamage);
        }
        me->DespawnOrUnsummon(500ms);
    }

    void UpdateCandleZone()
    {
        if (!_shot && _ageMs >= CandleShotMs + _staggerMs)
        {
            _shot = true;
            if (Creature* candle = ObjectAccessor::GetCreature(*me, _candle))
                candle->CastSpell(me, SPELL_CANDLE_FIREBALL, true);
        }
        if (!_fired && _ageMs >= CandleImpactMs + _staggerMs)
        {
            _fired = true;
            me->RemoveAurasDueToSpell(SPELL_CANDLE_HIT_ZONE);
            me->SendPlaySpellVisual(KIT_FIRE_EXPLOSION);
            for (Player* player : PlayersInRange(me, CandleZoneRadius))
                DealLogged(me, player, SPELL_CANDLE_FIREBALL_HIT, CandleFireballDamage);
        }
    }

    ObjectGuid _candle;
    std::vector<uint32> _kits;
    uint32 _staggerMs = 0;
    uint32 _ageMs = 0;
    uint32 _tickMs = 0;
    bool _fired = false;
    bool _shot = false;
    bool _soaked = false;
};

struct npc_coa_vaults_tentacle_vehicle : public ScriptedAI
{
    explicit npc_coa_vaults_tentacle_vehicle(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
    }

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }

    void UpdateAI(uint32) override
    {
        if (_seated)
            return;
        _seated = true;
        if (Vehicle* vehicle = me->GetVehicleKit())
            vehicle->InstallAllAccessories(false);
    }

private:
    bool _seated = false;
};

struct npc_coa_vaults_holy_crystal : public ScriptedAI
{
    explicit npc_coa_vaults_holy_crystal(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
        me->SetControlled(true, UNIT_STATE_ROOT);
        me->SetRespawnDelay(RpRespawnDelay);
        _chainMs = 1000;
        _breakMs = 0;
        _breaker.Clear();
    }

    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }

    void OnSpellClick(Unit* clicker, bool&) override
    {
        Player* player = clicker ? clicker->ToPlayer() : nullptr;
        if (!player || !me->IsAlive() || !_breaker.IsEmpty())
            return;
        _breaker = player->GetGUID();
        _breakMs = CrystalBreakMs;
        player->SetGuidValue(UNIT_FIELD_CHANNEL_OBJECT, me->GetGUID());
        player->SetUInt32Value(UNIT_CHANNEL_SPELL, SPELL_HOLY_CHANNEL_LOOK);
    }

    void UpdateAI(uint32 diff) override
    {
        if (_breakMs)
        {
            if (_breakMs > diff)
                _breakMs -= diff;
            else
                Shatter();
        }
        if (_chainMs > diff)
        {
            _chainMs -= diff;
            return;
        }
        _chainMs = 2000;
        if (me->GetCurrentSpell(CURRENT_CHANNELED_SPELL))
            return;
        std::list<Creature*> helpers;
        me->GetCreatureListWithEntryInGrid(helpers, NPC_SOUND_HELPER, SealRange);
        for (Creature* helper : helpers)
            if (helper->HasAura(SPELL_HOLY_RING))
            {
                me->CastSpell(helper, SPELL_COSMETIC_CHAINS, true);
                return;
            }
    }

private:
    void Shatter()
    {
        _breakMs = 0;
        Player* player = ObjectAccessor::GetPlayer(*me, _breaker);
        if (player && player->GetUInt32Value(UNIT_CHANNEL_SPELL) == SPELL_HOLY_CHANNEL_LOOK)
        {
            player->SetGuidValue(UNIT_FIELD_CHANNEL_OBJECT, ObjectGuid::Empty);
            player->SetUInt32Value(UNIT_CHANNEL_SPELL, 0);
        }
        me->InterruptNonMeleeSpells(false);
        ShatterEffect(me);
        if (player)
            Unit::Kill(player, me);
        else
            me->KillSelf();
        me->DespawnOrUnsummon(200ms);
    }

    ObjectGuid _breaker;
    uint32 _breakMs = 0;
    uint32 _chainMs = 0;
};

enum class Aim : uint8
{
    Victim,
    Self,
    Random,
    Charge,
    Near,
};

struct Ability
{
    uint32 spell;
    uint32 firstMs;
    uint32 repeatMs;
    Aim aim;
};

Ability const FierceBlow = { SPELL_FIERCE_BLOW, 7000, 9000, Aim::Victim };

std::unordered_map<uint32, std::vector<Ability>> const Abilities =
{
    { NPC_TORTURER, { { SPELL_SWORD_STRIKE, 1000, 6500, Aim::Victim }, FierceBlow } },
    { NPC_PHANTASMAL_BOUND, { { SPELL_MANA_BURN, 2500, 16000, Aim::Random }, { SPELL_SILENCE, 7500, 16000, Aim::Self },
        { SPELL_PSYCHIC_SCREAM, 13000, 16000, Aim::Self }, FierceBlow } },
    { NPC_FREED_PRISONER, { { SPELL_MANIFEST, 4000, 600000, Aim::Self }, FierceBlow } },
    { NPC_WRATHFUL_TORMENT, { { SPELL_ENDLESS_AFFLICTION, 4500, 8000, Aim::Self }, { SPELL_HAUNTING_WRATH, 9500, 8000, Aim::Self }, FierceBlow } },
    { NPC_KOBOLD, { { SPELL_PICKAXE_STRIKE, 4300, 10000, Aim::Self }, FierceBlow } },
    { NPC_KOBOLD_NORMAL, { { SPELL_PICKAXE_STRIKE, 4300, 10000, Aim::Self }, FierceBlow } },
    { NPC_KOBOLD_ELITE, { { SPELL_PICKAXE_STRIKE, 4700, 10000, Aim::Self }, FierceBlow } },
    { NPC_BRUTE, { { SPELL_DARK_WAX_EXPLOSION, 4500, 19500, Aim::Self }, { SPELL_CHARGE_IMPACT, 12500, 19300, Aim::Charge }, FierceBlow } },
    { NPC_BRUTE_ELITE, { { SPELL_DARK_WAX_EXPLOSION, 4500, 19500, Aim::Self }, { SPELL_CHARGE_IMPACT, 9000, 19300, Aim::Charge }, FierceBlow } },
    { NPC_KOBOLD_FLAME, { { SPELL_KOBOLD_FLAME, 200, 2000, Aim::Victim }, FierceBlow } },
    { NPC_SHADOW_PROJECTION, { { SPELL_LASH_OF_THE_VOID, 500, 5000, Aim::Near } } },
    { NPC_CORPOREAL_SHADOW, { { SPELL_SHADOWFURY, 5000, 16500, Aim::Random }, FierceBlow } },
    { NPC_CONFESSOR_KONRAD, { { SPELL_MIND_BLAST, 2000, 13000, Aim::Victim }, { SPELL_ABYSSAL_CRY, 7000, 13000, Aim::Self }, FierceBlow } },
};

struct TalkChance
{
    int32 aggro;
    int32 death;
};

std::unordered_map<uint32, TalkChance> const TrashTalk =
{
    { NPC_PHANTASMAL_BOUND, { 7, 20 } },
    { NPC_WRATHFUL_TORMENT, { 100, 10 } },
    { NPC_KOBOLD, { 7, 10 } },
    { NPC_KOBOLD_NORMAL, { 7, 10 } },
    { NPC_KOBOLD_ELITE, { 7, 10 } },
    { NPC_KOBOLD_FLAME, { 7, 10 } },
    { NPC_BRUTE, { 33, 33 } },
    { NPC_BRUTE_ELITE, { 33, 33 } },
    { NPC_CORPOREAL_SHADOW, { 100, 0 } },
};

struct npc_coa_vaults_trash : public ScriptedAI
{
    explicit npc_coa_vaults_trash(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _timers.clear();
        _scanMs = 0;
        if (me->GetEntry() == NPC_SHADOW_PROJECTION && !me->GetVehicle())
            me->SetControlled(true, UNIT_STATE_ROOT);
        auto itr = Abilities.find(me->GetEntry());
        if (itr == Abilities.end())
            return;
        for (Ability const& ability : itr->second)
            _timers.push_back({ &ability, ability.firstMs + urand(0, 1500) });
    }

    void JustEngagedWith(Unit*) override
    {
        auto itr = TrashTalk.find(me->GetEntry());
        if (itr != TrashTalk.end() && roll_chance_i(itr->second.aggro))
            Talk(SAY_TRASH_AGGRO);
    }

    void JustDied(Unit*) override
    {
        auto itr = TrashTalk.find(me->GetEntry());
        if (itr != TrashTalk.end() && roll_chance_i(itr->second.death))
            Talk(SAY_TRASH_DEATH);
    }

    void AttackStart(Unit* who) override
    {
        if (me->GetEntry() == NPC_SHADOW_PROJECTION)
        {
            AttackStartNoMove(who);
            return;
        }
        ScriptedAI::AttackStart(who);
    }

    void OnSpellCast(SpellInfo const* spell) override
    {
        if (spell->Id != SPELL_MANIFEST || !me->IsAlive())
            return;
        Unit* victim = me->GetVictim();
        if (Creature* phantasm = me->SummonCreature(NPC_PHANTASMAL_BOUND, me->GetPosition(), TEMPSUMMON_CORPSE_TIMED_DESPAWN, 60000))
            if (victim)
                phantasm->AI()->AttackStart(victim);
        Unit::Kill(victim ? victim : me, me);
    }

    void UpdateAI(uint32 diff) override
    {
        if (me->GetEntry() == NPC_SHADOW_PROJECTION && !me->IsInCombat())
            ScanForPlayers(diff);
        if (!UpdateVictim())
            return;
        for (Timer& timer : _timers)
            timer.left = timer.left > diff ? timer.left - diff : 0;
        if (!me->HasUnitState(UNIT_STATE_CASTING))
        {
            for (Timer& timer : _timers)
            {
                if (timer.left)
                    continue;
                Ability const& ability = *timer.ability;
                uint32 next = ability.repeatMs;
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
                    case Aim::Charge:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 30.0f, true))
                        {
                            me->GetMotionMaster()->MoveCharge(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ());
                            _chargeImpactMs = 1200;
                        }
                        break;
                    case Aim::Near:
                        next = LashRetryMs;
                        if (Player* target = RandomPlayer(me, LashRange))
                        {
                            SpellCastResult const result = me->CastSpell(target, ability.spell, RelaxedCast);
                            if (result == SPELL_CAST_OK)
                                next = ability.repeatMs;
                            else
                                LOG_INFO("coa.bossprobe", "castfail map={} entry={} spell={} result={} dist={:.1f}", me->GetMapId(),
                                    me->GetEntry(), ability.spell, uint32(result), me->GetExactDist(target));
                        }
                        break;
                }
                timer.left = next;
                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }
        }
        if (_chargeImpactMs)
        {
            if (_chargeImpactMs > diff)
                _chargeImpactMs -= diff;
            else
            {
                _chargeImpactMs = 0;
                DoCastSelf(SPELL_CHARGE_IMPACT, true);
            }
        }
        if (!me->HasUnitState(UNIT_STATE_CASTING))
            DoMeleeAttackIfReady();
    }

private:
    void ScanForPlayers(uint32 diff)
    {
        if (_scanMs > diff)
        {
            _scanMs -= diff;
            return;
        }
        _scanMs = 1000;
        for (Player* player : PlayersInRange(me, TentacleAggroRange))
        {
            AttackStart(player);
            return;
        }
    }

    struct Timer
    {
        Ability const* ability;
        uint32 left;
    };

    std::vector<Timer> _timers;
    uint32 _chargeImpactMs = 0;
    uint32 _scanMs = 0;
};

class spell_coa_vaults_damage : public SpellScript
{
    PrepareSpellScript(spell_coa_vaults_damage);

    void HandleHit()
    {
        auto itr = Damages.find(BaseSpellId(GetSpellInfo()->Id));
        if (itr == Damages.end() || !itr->second.hit.mythic || !GetHitDamage() || !GetHitUnit())
            return;
        SetHitDamage(Rolled(GetCaster(), GetHitUnit(), itr->second.hit, GetSpellInfo()));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_vaults_damage::HandleHit);
    }
};

class spell_coa_vaults_damage_aura : public AuraScript
{
    PrepareAuraScript(spell_coa_vaults_damage_aura);

    void CalcTick(AuraEffect const*, int32& amount, bool&)
    {
        auto itr = Damages.find(BaseSpellId(GetSpellInfo()->Id));
        if (itr == Damages.end() || !itr->second.tick.mythic)
            return;
        if (GetAura()->GetType() != UNIT_AURA_TYPE)
            return;
        if (Unit* caster = GetCaster())
            amount = Rolled(caster, GetUnitOwner(), itr->second.tick, GetSpellInfo());
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_coa_vaults_damage_aura::CalcTick, EFFECT_ALL, SPELL_AURA_PERIODIC_DAMAGE);
    }
};
class spell_coa_vaults_void_wrath : public AuraScript
{
    PrepareAuraScript(spell_coa_vaults_void_wrath);

    void HandleRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Creature* caster = GetCaster() ? GetCaster()->ToCreature() : nullptr)
            if (caster->IsAIEnabled)
                caster->AI()->DoAction(ACTION_VOID_WRATH_END);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_coa_vaults_void_wrath::HandleRemove, EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_coa_vaults_void_wrath_tick : public SpellScript
{
    PrepareSpellScript(spell_coa_vaults_void_wrath_tick);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        targets.remove_if([](WorldObject* target)
        {
            Unit* unit = target->ToUnit();
            return !unit || unit->HasAura(SPELL_HOLY_SHELTER);
        });
    }

    void HandleHit()
    {
        if (Unit* target = GetHitUnit())
            SetHitDamage(Rolled(GetCaster(), target, VoidWrathTickDamage, GetSpellInfo()));
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_vaults_void_wrath_tick::FilterTargets, EFFECT_0, TARGET_UNIT_SRC_AREA_ENEMY);
        OnHit += SpellHitFn(spell_coa_vaults_void_wrath_tick::HandleHit);
    }
};

class vaults_spell_attributes : public GlobalScript
{
public:
    vaults_spell_attributes() : GlobalScript("vaults_spell_attributes", { GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR }) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info)
            return;
        switch (info->Id)
        {
            case 256895:
            case 257195:
            case 257196:
            case 257197:
                info->AttributesEx2 |= SPELL_ATTR2_IGNORE_LINE_OF_SIGHT;
                break;
            case 256819:
            case 257105:
            case 257106:
            case 257107:
                if (SpellRadiusEntry const* radius = sSpellRadiusStore.LookupEntry(EarthquakeRadiusIndex))
                    for (SpellEffectInfo& effect : info->Effects)
                        if (effect.RadiusEntry)
                            effect.RadiusEntry = radius;
                break;
            default:
                break;
        }
    }
};
}

void AddSC_CoAVaults()
{
    RegisterGameObjectAI(go_coa_vaults_jail_door);
    RegisterGameObjectAI(go_coa_vaults_boss_gate);
    RegisterCreatureAI(npc_coa_vaults_echo_rp);
    RegisterCreatureAI(boss_coa_vaults_echo);
    RegisterCreatureAI(boss_coa_vaults_darkandle);
    RegisterCreatureAI(boss_coa_vaults_deceiver);
    RegisterCreatureAI(npc_coa_vaults_helper);
    RegisterCreatureAI(npc_coa_vaults_holy_crystal);
    RegisterCreatureAI(npc_coa_vaults_tentacle_vehicle);
    RegisterCreatureAI(npc_coa_vaults_trash);
    RegisterSpellAndAuraScriptPair(spell_coa_vaults_damage, spell_coa_vaults_damage_aura);
    RegisterSpellScript(spell_coa_vaults_void_wrath);
    RegisterSpellScript(spell_coa_vaults_void_wrath_tick);
    new vaults_spell_attributes();
}
