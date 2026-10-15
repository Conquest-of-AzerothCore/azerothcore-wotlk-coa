/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "EventMap.h"
#include "Map.h"
#include "MotionMaster.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <limits>
#include <map>
#include <mutex>
#include <set>

namespace
{
enum PetalkeeperSpells : uint32
{
    SPELL_PETALKEEPER = 520925,
    SPELL_RED_FLOWER = 521222,
    SPELL_PETALS = 521220,
    SPELL_RED_DREAM = 521451,
    SPELL_RED_DREAM_HEAL = 521643,
    SPELL_ENDURANCE_OF_THE_RANGER = 560809,
    SPELL_ENDURANCE_OF_THE_RANGER_HEAL = 560808
};

enum PetalkeeperEntries : uint32
{
    NPC_RED_FLOWER = 454240,
    EVENT_RED_FLOWER_OWNER_CHECK = 1
};

std::mutex petalMutex;
std::map<ObjectGuid, std::set<ObjectGuid>> redFlowers;

void RememberRedFlower(ObjectGuid owner, ObjectGuid flower)
{
    std::lock_guard<std::mutex> lock(petalMutex);
    redFlowers[owner].insert(flower);
}

void ForgetRedFlower(ObjectGuid owner, ObjectGuid flower)
{
    std::lock_guard<std::mutex> lock(petalMutex);
    auto itr = redFlowers.find(owner);
    if (itr != redFlowers.end())
    {
        itr->second.erase(flower);
        if (itr->second.empty())
            redFlowers.erase(itr);
    }
}

std::set<ObjectGuid> RedFlowerGuids(ObjectGuid owner)
{
    std::lock_guard<std::mutex> lock(petalMutex);
    auto itr = redFlowers.find(owner);
    return itr == redFlowers.end() ? std::set<ObjectGuid>{} : itr->second;
}

Player* RedFlowerOwner(Creature* flower)
{
    if (!flower || flower->GetEntry() != NPC_RED_FLOWER || !flower->IsAlive() || !flower->IsInWorld())
        return nullptr;
    Player* owner = flower->GetCharmerOrOwnerPlayerOrPlayerItself();
    return owner && owner->getClass() == CLASS_RANGER && owner->GetGUID() == flower->GetOwnerGUID() &&
        owner->IsAlive() && owner->IsInWorld() && owner->HasAura(SPELL_PETALKEEPER) &&
        owner->GetMap() == flower->GetMap() && owner->InSamePhase(flower) ? owner : nullptr;
}

struct npc_ascension_ranger_red_flower : ScriptedAI
{
    explicit npc_ascension_ranger_red_flower(Creature* creature) : ScriptedAI(creature) { }
    ObjectGuid ownerGuid;
    EventMap events;

    ~npc_ascension_ranger_red_flower() override { ForgetRedFlower(ownerGuid, me->GetGUID()); }
    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void EnterEvadeMode(EvadeReason) override { }

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = summoner ? summoner->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_RANGER || !player->HasAura(SPELL_PETALKEEPER))
        {
            me->DespawnOrUnsummon();
            return;
        }
        ownerGuid = player->GetGUID();
        me->SetOwnerGUID(ownerGuid);
        me->SetFaction(player->GetFaction());
        me->SetLevel(player->GetLevel());
        me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
        me->SetReactState(REACT_PASSIVE);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
        RememberRedFlower(ownerGuid, me->GetGUID());
        events.ScheduleEvent(EVENT_RED_FLOWER_OWNER_CHECK, Milliseconds(500));
    }

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);
        if (events.ExecuteEvent() != EVENT_RED_FLOWER_OWNER_CHECK)
            return;
        if (!RedFlowerOwner(me))
        {
            ForgetRedFlower(ownerGuid, me->GetGUID());
            me->DespawnOrUnsummon();
            return;
        }
        events.ScheduleEvent(EVENT_RED_FLOWER_OWNER_CHECK, Milliseconds(500));
    }
};

class spell_ascension_ranger_red_flower : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_red_flower);

    bool Load() override { return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_RANGER; }

    void Summon(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        WorldLocation const* destination = GetHitDest();
        int32 duration = GetSpellInfo()->GetDuration();
        player->ApplySpellMod(SPELL_RED_FLOWER, SPELLMOD_DURATION, duration);
        if (!destination || duration <= 0 || !player->HasAura(SPELL_PETALKEEPER))
            return;
        if (TempSummon* flower = player->SummonCreature(NPC_RED_FLOWER, *destination,
            TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, uint32(duration)))
            flower->SetUInt32Value(UNIT_CREATED_BY_SPELL, SPELL_RED_FLOWER);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_ranger_red_flower::Summon, EFFECT_0, SPELL_EFFECT_SUMMON);
    }
};

class aura_ascension_ranger_petalkeeper : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_petalkeeper);

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        return owner->IsPlayer() && owner->getClass() == CLASS_RANGER && owner->IsAlive() && owner->IsInWorld() &&
            event.GetActor() == owner && victim && victim != owner && !owner->IsFriendlyTo(victim) &&
            (event.GetHitMask() & PROC_HIT_CRITICAL) && event.GetDamageInfo() && event.GetDamageInfo()->GetDamage();
    }

    void AddPetals(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        Player* owner = GetTarget()->ToPlayer();
        for (ObjectGuid guid : RedFlowerGuids(owner->GetGUID()))
            if (Creature* flower = owner->GetMap()->GetCreature(guid); RedFlowerOwner(flower) == owner)
                owner->CastSpell(flower, SPELL_PETALS, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_ranger_petalkeeper::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_ranger_petalkeeper::AddPetals, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class ranger_petalkeeper_casts : public AllSpellScript
{
public:
    ranger_petalkeeper_casts() : AllSpellScript("ranger_petalkeeper_casts", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_RANGER || info->SpellFamilyName != 27 || spell->IsTriggered() ||
            !player->IsAlive() || !player->IsInWorld() || !player->HasAura(SPELL_PETALKEEPER))
            return;
        if (info->SpellFamilyFlags[2] & 8192)
            player->CastSpell(player, SPELL_RED_FLOWER, true);
        if (info->SpellFamilyFlags[2] & 1)
            for (ObjectGuid guid : RedFlowerGuids(player->GetGUID()))
            {
                Creature* flower = player->GetMap()->GetCreature(guid);
                if (RedFlowerOwner(flower) != player)
                    continue;
                Aura const* petals = flower->GetAura(SPELL_PETALS, player->GetGUID());
                if (!petals || uint32(petals->GetStackAmount()) < petals->GetSpellInfo()->CalcMaxAuraStacks(player))
                    continue;
                ForgetRedFlower(player->GetGUID(), guid);
                flower->CastSpell(flower, SPELL_RED_DREAM, true);
                flower->DespawnOrUnsummon();
            }
    }
};

class aura_ascension_ranger_red_dream : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_red_dream);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_RED_DREAM_HEAL}); }

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* recipient = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* victim = event.GetActionTarget();
        return recipient->IsAlive() && event.GetActor() == recipient && victim && victim != recipient &&
            !recipient->IsFriendlyTo(victim) && damage && damage->GetDamage() &&
            (damage->GetDamageType() == DIRECT_DAMAGE || damage->GetDamageType() == SPELL_DIRECT_DAMAGE);
    }

    void Heal(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (amount && double(float(amount)) <= double(std::numeric_limits<int32>::max()))
            GetTarget()->CastCustomSpell(SPELL_RED_DREAM_HEAL, SPELLVALUE_BASE_POINT0,
                int32(amount), GetTarget(), true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_ranger_red_dream::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_ranger_red_dream::Heal, EFFECT_0, AuraType(354));
    }
};

class aura_ascension_ranger_endurance : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_endurance);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_ENDURANCE_OF_THE_RANGER_HEAL}); }

    void Heal(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        if (owner && owner->IsAlive())
            owner->CastSpell(owner, SPELL_ENDURANCE_OF_THE_RANGER_HEAL, true, nullptr, effect);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(aura_ascension_ranger_endurance::Heal, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
}

void AddSC_AscensionRangerPetalkeeper()
{
    RegisterCreatureAI(npc_ascension_ranger_red_flower);
    RegisterSpellScript(spell_ascension_ranger_red_flower);
    RegisterSpellScript(aura_ascension_ranger_petalkeeper);
    RegisterSpellScript(aura_ascension_ranger_red_dream);
    RegisterSpellScript(aura_ascension_ranger_endurance);
    new ranger_petalkeeper_casts();
}
