/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "EventMap.h"
#include "Map.h"
#include "MotionMaster.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <map>
#include <mutex>

namespace
{
enum WindGateSpells : uint32
{
    SPELL_WIND_GATE = 504401,
    SPELL_EVACUATE = 504643,
    SPELL_EVACUATE_PULL = 504644
};

enum WindGateEntries : uint32
{
    NPC_WIND_GATE = 617478,
    EVENT_GATE_OWNER_CHECK = 1
};

std::mutex gateMutex;
std::map<ObjectGuid, ObjectGuid> windGates;

ObjectGuid GateGuid(ObjectGuid owner)
{
    std::lock_guard<std::mutex> lock(gateMutex);
    auto itr = windGates.find(owner);
    return itr == windGates.end() ? ObjectGuid::Empty : itr->second;
}

void ForgetGate(ObjectGuid owner, ObjectGuid gate)
{
    std::lock_guard<std::mutex> lock(gateMutex);
    auto itr = windGates.find(owner);
    if (itr != windGates.end() && itr->second == gate)
        windGates.erase(itr);
}

Creature* GetWindGate(Player* player)
{
    if (!player || !player->IsInWorld())
        return nullptr;
    ObjectGuid guid = GateGuid(player->GetGUID());
    Creature* gate = guid ? player->GetMap()->GetCreature(guid) : nullptr;
    return gate && gate->GetEntry() == NPC_WIND_GATE && gate->GetOwnerGUID() == player->GetGUID() ? gate : nullptr;
}

void RemoveWindGate(Player* player)
{
    Creature* gate = GetWindGate(player);
    ForgetGate(player->GetGUID(), GateGuid(player->GetGUID()));
    if (gate)
        gate->DespawnOrUnsummon();
}

void SyncEvacuate(Player* player)
{
    if (player->getClass() != CLASS_STORMBRINGER)
        return;
    if (!player->HasActiveSpell(SPELL_WIND_GATE))
    {
        RemoveWindGate(player);
        player->removeSpell(SPELL_EVACUATE, SPEC_MASK_ALL, true);
    }
    else if (player->GetSpellMap().find(SPELL_EVACUATE) == player->GetSpellMap().end())
        player->learnSpell(SPELL_EVACUATE, true);
}

bool CanEvacuate(Player* player, Unit* target)
{
    if (!player || player->getClass() != CLASS_STORMBRINGER || !player->IsAlive() ||
        !player->HasActiveSpell(SPELL_WIND_GATE) || !target || !target->IsAlive() || !target->IsInWorld() ||
        target->IsInFlight() || target->GetVehicle() || target->GetTransport())
        return false;
    if (Player* ally = target->ToPlayer())
        if (ally->IsBeingTeleported())
            return false;
    Creature* gate = GetWindGate(player);
    SpellInfo const* helper = sSpellMgr->GetSpellInfo(SPELL_EVACUATE_PULL);
    return gate && helper && gate->IsAlive() && gate->IsInWorld() && gate->GetMap() == target->GetMap() &&
        player->InSamePhase(gate) && gate->InSamePhase(target) && player->IsValidAssistTarget(target) &&
        player->IsInRaidWith(target) && gate->IsWithinLOSInMap(target) &&
        gate->IsWithinDistInMap(target, helper->GetMaxRange(true, gate));
}

struct npc_ascension_stormbringer_gate : ScriptedAI
{
    explicit npc_ascension_stormbringer_gate(Creature* creature) : ScriptedAI(creature) { }
    ObjectGuid ownerGuid;
    EventMap events;

    ~npc_ascension_stormbringer_gate() override { ForgetGate(ownerGuid, me->GetGUID()); }
    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* owner = summoner ? summoner->ToPlayer() : nullptr;
        if (!owner || owner->getClass() != CLASS_STORMBRINGER || !owner->HasActiveSpell(SPELL_WIND_GATE))
        {
            me->DespawnOrUnsummon();
            return;
        }
        ownerGuid = owner->GetGUID();
        me->SetOwnerGUID(ownerGuid);
        me->SetFaction(owner->GetFaction());
        me->SetLevel(owner->GetLevel());
        me->SetReactState(REACT_PASSIVE);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
        events.ScheduleEvent(EVENT_GATE_OWNER_CHECK, Milliseconds(500));
    }

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);
        if (events.ExecuteEvent() != EVENT_GATE_OWNER_CHECK)
            return;
        Player* owner = me->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (!owner || !owner->IsAlive() || !owner->IsInWorld() || owner->GetMap() != me->GetMap() ||
            !owner->InSamePhase(me) || !owner->HasActiveSpell(SPELL_WIND_GATE) ||
            GateGuid(ownerGuid) != me->GetGUID())
        {
            ForgetGate(ownerGuid, me->GetGUID());
            me->DespawnOrUnsummon();
            return;
        }
        events.ScheduleEvent(EVENT_GATE_OWNER_CHECK, Milliseconds(500));
    }
};

class spell_ascension_wind_gate : public SpellScript
{
    PrepareSpellScript(spell_ascension_wind_gate);

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == CLASS_STORMBRINGER;
    }

    void Summon(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        WorldLocation const* destination = GetHitDest();
        int32 duration = GetSpellInfo()->GetDuration();
        player->ApplySpellMod(SPELL_WIND_GATE, SPELLMOD_DURATION, duration);
        if (!destination || duration <= 0 || !player->HasActiveSpell(SPELL_WIND_GATE))
            return;
        TempSummon* gate = player->SummonCreature(NPC_WIND_GATE, *destination,
            TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, uint32(duration));
        if (!gate)
            return;
        RemoveWindGate(player);
        gate->SetUInt32Value(UNIT_CREATED_BY_SPELL, SPELL_WIND_GATE);
        {
            std::lock_guard<std::mutex> lock(gateMutex);
            windGates[player->GetGUID()] = gate->GetGUID();
        }
        SyncEvacuate(player);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_wind_gate::Summon, EFFECT_0, SPELL_EFFECT_SUMMON);
    }
};

class spell_ascension_wind_gate_evacuate : public SpellScript
{
    PrepareSpellScript(spell_ascension_wind_gate_evacuate);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_EVACUATE_PULL}); }

    SpellCastResult CheckPull()
    {
        return CanEvacuate(GetCaster()->ToPlayer(), GetExplTargetUnit())
            ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }

    void Pull(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        if (CanEvacuate(player, target))
            GetWindGate(player)->CastSpell(target, SPELL_EVACUATE_PULL, true);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_wind_gate_evacuate::CheckPull);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_wind_gate_evacuate::Pull,
            EFFECT_0, SPELL_EFFECT_SCRIPT_EFFECT);
    }
};

class stormbringer_gate_lifecycle : public PlayerScript
{
public:
    stormbringer_gate_lifecycle() : PlayerScript("stormbringer_gate_lifecycle",
        {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_MAP_CHANGED,
            PLAYERHOOK_ON_LEARN_SPELL, PLAYERHOOK_ON_FORGOT_SPELL}) { }

    void OnPlayerLogin(Player* player) override { SyncEvacuate(player); }
    void OnPlayerLogout(Player* player) override { RemoveWindGate(player); }
    void OnPlayerMapChanged(Player* player) override { RemoveWindGate(player); }

    void OnPlayerLearnSpell(Player* player, uint32 spell) override
    {
        if (spell == SPELL_WIND_GATE)
            SyncEvacuate(player);
    }

    void OnPlayerForgotSpell(Player* player, uint32 spell) override
    {
        if (spell == SPELL_WIND_GATE)
            SyncEvacuate(player);
    }
};

class stormbringer_gate_metadata : public GlobalScript
{
public:
    stormbringer_gate_metadata() : GlobalScript("stormbringer_gate_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 22)
            return;
        if (info->Id == SPELL_WIND_GATE)
            info->Effects[EFFECT_1].Effect = 0;
    }
};
}

void AddSC_AscensionStormbringerWindGate()
{
    RegisterCreatureAI(npc_ascension_stormbringer_gate);
    RegisterSpellScript(spell_ascension_wind_gate);
    RegisterSpellScript(spell_ascension_wind_gate_evacuate);
    new stormbringer_gate_lifecycle();
    new stormbringer_gate_metadata();
}
