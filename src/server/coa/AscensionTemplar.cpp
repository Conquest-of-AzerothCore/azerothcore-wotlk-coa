/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTemplar.h"
#include "AscensionTemplarData.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
#include <memory>
#include <mutex>
#include <set>
#include <unordered_map>

namespace AscensionTemplar
{
namespace
{
std::unordered_map<ObjectGuid, std::unique_ptr<TemplarState>> states;
std::mutex stateMutex;
constexpr uint32 oaths[] = {804903, 804904, 804922, 804924, 805332};
}
Player* Owner(Unit const* unit)
{
    Player* player = unit ? const_cast<Unit*>(unit)->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_MONK ? player : nullptr;
}
TemplarState& State(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return *states.try_emplace(player->GetGUID(), std::make_unique<TemplarState>()).first->second;
}
bool Named(SpellInfo const* info, uint32 root)
{
    return info && sSpellMgr->GetFirstSpellInChain(info->Id) == sSpellMgr->GetFirstSpellInChain(root);
}
bool Libram(SpellInfo const* info)
{
    return Named(info, 801441) ||
           (info && (info->Id == 801461 || info->Id == 801463 || info->Id == 801466 || info->Id == 805423));
}
bool HasLibram(Player* player)
{
    for (uint32 sid : {801441, 803890, 803891, 803892, 803893, 801461, 801463, 801466, 805423})
        if (player->HasAura(sid))
            return true;
    return false;
}
bool Derived(SpellInfo const* info)
{
    if (!info)
        return false;
    for (uint32 sid : TemplarCopies)
        if (info->Id == sid)
            return true;
    for (uint32 sid : {801450, 801832, 680398, 524619, 804148, 804150, 504809, 803160, 527269, 520544, 706466, 707111,
                       806352, 803237, 807763})
        if (info->Id == sid)
            return true;
    return false;
}
bool Ability(SpellInfo const* info)
{
    return info && info->SpellFamilyName == 25 && !Derived(info) &&
           (info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE) || info->HasEffect(SPELL_EFFECT_WEAPON_PERCENT_DAMAGE) ||
            info->HasEffect(SPELL_EFFECT_HEALTH_LEECH) || Named(info, 804906) || Named(info, 803872));
}
int32 Amount(uint32 spell, uint8 effect, Unit* caster)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    return info ? info->Effects[effect].CalcValue(caster) : 0;
}
void Cast(Unit* caster, Unit* target, uint32 spell)
{
    if (caster && target && target->IsAlive() && caster->IsInWorld())
        caster->CastSpell(target, spell, true);
}
void Copy(Unit* caster, Unit* target, uint32 spell, uint32 amount)
{
    if (caster && target && target->IsAlive() && amount)
        caster->CastCustomSpell(spell, SPELLVALUE_BASE_POINT0, int32(std::min(amount, uint32(INT32_MAX))), target,
                                true);
}
std::list<Unit*> Nearby(Unit* center, float range)
{
    std::list<Unit*> units;
    if (!center || !center->IsInWorld())
        return units;
    Acore::AnyUnitInObjectRangeCheck check(center, range);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center, units, check);
    Cell::VisitObjects(center, search, range);
    units.remove_if([center](Unit* unit) { return !unit->IsAlive() || !center->InSamePhase(unit); });
    units.sort([center](Unit* a, Unit* b) {
        float first = center->GetDistance(a), second = center->GetDistance(b);
        return first == second ? a->GetGUID() < b->GetGUID() : first < second;
    });
    return units;
}
bool Chance(Player* player, uint32 talent, uint32 cooldown)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(talent);
    if (!player->HasAura(talent) || !info || State(player).cooldowns.HasTimeUntilEvent(talent) ||
        !roll_chance_f(float(info->ProcChance)))
        return false;
    if (cooldown)
        State(player).cooldowns.ScheduleEvent(talent, Milliseconds(cooldown));
    return true;
}
void Reduce(Player* player, uint32 root, int32 milliseconds)
{
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
            if (milliseconds == INT32_MAX)
                player->RemoveSpellCooldown(pair.first, true);
            else
                player->ModifySpellCooldown(pair.first, -milliseconds);
}
void ReduceLibrams(Player* player, int32 milliseconds)
{
    for (uint32 sid : {801441, 801461, 801463, 801466, 805423})
        Reduce(player, sid, milliseconds);
}
void Replacement(Player* player, uint32 root, uint32 replacement)
{
    if (replacement && !player->HasActiveSpell(replacement))
        player->learnSpell(replacement, true);
    std::set<uint32> lent;
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
        {
            if (!replacement)
                lent.insert(player->GetTemporarySpellReplacement(pair.first));
            player->SetTemporarySpellReplacement(pair.first, replacement);
        }
    for (uint32 id : lent)
        player->removeSpell(id, SPEC_MASK_ALL, true);
}
void ClearOaths(Player* player)
{
    if (State(player).oath)
        return;
    State(player).oath = true;
    for (uint32 sid : oaths)
        player->RemoveAurasDueToSpell(sid);
    player->RemoveAurasDueToSpell(704576);
    player->RemoveAurasDueToSpell(706426);
    player->RemoveAurasDueToSpell(807764);
    State(player).oath = false;
}
void GrantOath(Player* player, uint32 oath)
{
    Aura* chain = player->GetAura(704576);
    if (chain && chain->GetStackAmount() >= 10)
        return;
    bool first = !chain;
    int32 duration = chain ? chain->GetDuration() : 15000;
    Cast(player, player, oath);
    if (Aura* aura = player->GetAura(oath))
        aura->SetDuration(duration);
    Cast(player, player, 704576);
    if (Aura* aura = player->GetAura(704576))
    {
        aura->SetDuration(first ? aura->GetMaxDuration() : duration);
        if (Aura* granted = first ? player->GetAura(oath) : nullptr)
            granted->SetDuration(aura->GetDuration());
    }
    if (first && State(player).retribution)
    {
        State(player).retribution = false;
        GrantOath(player, 804924);
    }
}
void Delay(Player* player, uint32 amount)
{
    if (!amount)
        return;
    Aura* aura = player->GetAura(803237);
    int32 old = aura && aura->GetEffect(EFFECT_0) ? aura->GetEffect(EFFECT_0)->GetAmount() : 0;
    if (!aura)
    {
        Cast(player, player, 803237);
        aura = player->GetAura(803237);
    }
    if (aura && aura->GetEffect(EFFECT_0))
    {
        aura->GetEffect(EFFECT_0)->ChangeAmount(int32(std::min<uint64>(INT32_MAX, uint64(std::max(0, old)) + amount)));
        aura->SetDuration(aura->GetMaxDuration());
    }
}
void ReduceDebt(Player* player, uint32 percent, bool oneTick)
{
    if (Aura* aura = player->GetAura(803237))
        if (AuraEffect* effect = aura->GetEffect(EFFECT_0))
        {
            uint32 amount = std::max(0, effect->GetAmount());
            uint32 ticks = std::max(1, (aura->GetDuration() + 999) / 1000);
            uint32 reduction = oneTick ? (amount + ticks - 1) / ticks : uint64(amount) * std::min(100u, percent) / 100;
            if (reduction >= amount)
                aura->Remove();
            else
                effect->ChangeAmount(amount - reduction);
        }
}
void Zealotry(Player* player, Unit* target, bool repeat)
{
    if (!target || !player->IsValidAttackTarget(target))
        return;
    Cast(player, target, 801450);
    uint32 sermon = player->HasAura(572554) ? 572554 : player->HasAura(572548) ? 572548 : 0;
    SpellInfo const* info = sermon ? sSpellMgr->GetSpellInfo(sermon) : nullptr;
    if (!repeat && info && roll_chance_i(info->ProcChance))
        Zealotry(player, target, true);
}
uint32 HopeCount(Player* player)
{
    uint32 count = 0;
    for (ObjectGuid guid : State(player).copies)
        if (Creature* unit = ObjectAccessor::GetCreature(*player, guid))
            if (unit->IsAlive() && unit->GetOwnerGUID() == player->GetGUID() && player->InSamePhase(unit) &&
                player->IsWithinDistInMap(unit, 15.0f))
                ++count;
    return count;
}
void SpreadCondemn(Player* player, Unit* target)
{
    Aura* source = nullptr;
    for (auto const& pair : target->GetAppliedAuras())
        if (Aura* aura = pair.second->GetBase();
            Named(aura->GetSpellInfo(), 804906) && aura->GetCasterGUID() == player->GetGUID())
        {
            source = aura;
            break;
        }
    if (!source)
        return;
    for (Unit* enemy : Nearby(target, 10.0f))
    {
        if (enemy == target || !player->IsValidAttackTarget(enemy) || !target->IsWithinLOSInMap(enemy))
            continue;
        bool already = false;
        for (auto const& pair : enemy->GetAppliedAuras())
            if (Aura* aura = pair.second->GetBase();
                Named(aura->GetSpellInfo(), 804906) && aura->GetCasterGUID() == player->GetGUID())
                already = true;
        if (already)
            continue;
        if (Aura* copy = player->AddAura(source->GetId(), enemy))
        {
            copy->SetStackAmount(source->GetStackAmount());
            copy->SetMaxDuration(source->GetMaxDuration());
            copy->SetDuration(source->GetDuration());
            for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                if (AuraEffect* old = source->GetEffect(i))
                    if (AuraEffect* effect = copy->GetEffect(i))
                    {
                        effect->ChangeAmount(old->GetAmount());
                        effect->SetPeriodicTimer(old->GetPeriodicTimer());
                    }
            break;
        }
    }
}
bool DivineSteed(Unit const* unit)
{
    Aura const* aura = unit ? unit->GetAura(527272) : nullptr;
    return aura && unit->IsMounted() && unit->GetMountID() == 14584 && Owner(aura->GetCaster());
}
}

namespace
{
class templar_player : public PlayerScript
{
  public:
    templar_player() : PlayerScript("templar_player", {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT}) {}
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (AscensionTemplar::Owner(player))
        {
            auto& state = AscensionTemplar::State(player);
            state.cooldowns.Update(diff);
            while (state.cooldowns.ExecuteEvent())
            {
            }
            state.copies.erase(std::remove_if(state.copies.begin(), state.copies.end(),
                                              [player](ObjectGuid guid) {
                                                  Creature* unit = ObjectAccessor::GetCreature(*player, guid);
                                                  return !unit || !unit->IsAlive() ||
                                                         unit->GetOwnerGUID() != player->GetGUID();
                                              }),
                               state.copies.end());
            if (!player->IsAlive())
                AscensionTemplar::ClearOaths(player);
            if (player->HasAura(560096) && !player->HasAura(567572))
                AscensionTemplar::Cast(player, player, 567572);
            else if (!player->HasAura(560096) && player->HasAura(567572, player->GetGUID()))
                player->RemoveAurasDueToSpell(567572, player->GetGUID());
        }
    }
    void OnPlayerLogout(Player* player) override
    {
        using namespace AscensionTemplar;
        if (!Owner(player))
            return;
        for (ObjectGuid guid : State(player).copies)
            if (Creature* unit = ObjectAccessor::GetCreature(*player, guid))
                unit->DespawnOrUnsummon();
        std::lock_guard<std::mutex> lock(stateMutex);
        states.erase(player->GetGUID());
    }
};
}
void AddSC_AscensionTemplar()
{
    new templar_player();
}
