/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionXoroth.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Pet.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <algorithm>
#include <memory>
#include <mutex>
#include <unordered_map>
namespace AscensionXoroth
{
namespace
{
std::unordered_map<ObjectGuid, std::unique_ptr<XorothState>> states;
std::mutex stateMutex;
}
Player* Owner(Unit const* unit)
{
    Player* player = unit ? const_cast<Unit*>(unit)->ToPlayer() : nullptr;
    return player && player->getClass() == 17 ? player : nullptr;
}
XorothState& State(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return *states.try_emplace(player->GetGUID(), std::make_unique<XorothState>()).first->second;
}
bool Named(SpellInfo const* info, uint32 root)
{
    return info && sSpellMgr->GetFirstSpellInChain(info->Id) == sSpellMgr->GetFirstSpellInChain(root);
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
void Reduce(Player* player, uint32 root, int32 milliseconds)
{
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
            if (milliseconds == INT32_MAX)
                player->RemoveSpellCooldown(pair.first, true);
            else
                player->ModifySpellCooldown(pair.first, -milliseconds);
}
void Replace(Player* player, uint32 root, uint32 replacement)
{
    if (replacement)
        for (auto const& [id, spell] : player->GetSpellMap())
            if (player->HasActiveSpell(id) && Named(sSpellMgr->GetSpellInfo(id), replacement) &&
                sSpellMgr->GetSpellRank(id) > sSpellMgr->GetSpellRank(replacement))
                replacement = id;
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root))
            player->SetTemporarySpellReplacement(pair.first, replacement);
}

bool Spender(SpellInfo const* info)
{
    for (uint32 root : {520292, 524897, 524920, 806965, 801059, 800168, 801063, 802342, 802581, 803334, 803889})
        if (Named(info, root))
            return true;
    return false;
}
bool Sever(SpellInfo const* info)
{
    return Named(info, 500904) || Named(info, 520005);
}
bool Infernal(SpellInfo const* info)
{
    return Named(info, 801016) || Named(info, 804353);
}
bool Derived(SpellInfo const* info)
{
    return info &&
           (info->Id == 680204 || info->Id == 704974 || info->Id == 802608 || info->Id == 802620 || info->Id == 681206);
}
bool Pestilence(uint32 id)
{
    return id == 801053 || id == 802344 || id == 802345 || id == 804786 || id == 801054;
}
bool Mark(SpellInfo const* info)
{
    return info && info->SpellFamilyName == 23 && (info->SpellFamilyFlags[1] & 2147483648u);
}
uint32 Count(Unit const* unit, uint32 id)
{
    Aura const* aura = unit ? unit->GetAura(id) : nullptr;
    return aura ? aura->GetStackAmount() : 0;
}
int32 Amount(uint32 id, uint8 slot, Unit* caster)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    return info ? info->Effects[slot].CalcValue(caster) : 0;
}
uint32 Highest(Player* player, uint32 root)
{
    uint32 id = root;
    for (auto const& pair : player->GetSpellMap())
        if (player->HasSpell(pair.first) && Named(sSpellMgr->GetSpellInfo(pair.first), root) &&
            sSpellMgr->GetSpellInfo(pair.first)->SpellLevel >= sSpellMgr->GetSpellInfo(id)->SpellLevel)
            id = pair.first;
    return id;
}
void Cast(Unit* caster, Unit* target, uint32 id)
{
    if (caster && target && target->IsAlive() && caster->IsInWorld())
        caster->CastSpell(target, id, true);
}
void Copy(Unit* caster, Unit* target, uint32 id, uint32 amount)
{
    if (caster && target && target->IsAlive() && amount)
        caster->CastCustomSpell(id, SPELLVALUE_BASE_POINT0, int32(std::min<uint32>(amount, INT32_MAX)), target, true);
}
void Gain(Player* player, uint32 count)
{
    if (!player || !player->IsAlive() || !count)
        return;
    uint32 previous = Count(player, 500906);
    int32 cap = 6;
    player->ApplySpellMod(500906, SPELLMOD_MAX_AURA_STACKS, cap);
    uint32 maxStacks = uint32(std::max(cap, 0));
    if (Aura* aura = player->AddAura(500906, player))
        aura->SetStackAmount(std::min(maxStacks, previous + count));
    if (player->HasAura(524922))
        player->EnergizeBySpell(player, 524922, 10, POWER_RAGE);
}
bool Chance(Player* player, uint32 id, uint32 cooldown, float bonus)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    if (!player->HasAura(id) || !info || State(player).timers.HasTimeUntilEvent(id) ||
        !roll_chance_f(std::min(100.0f, float(info->ProcChance) + bonus)))
        return false;
    if (cooldown)
        State(player).timers.ScheduleEvent(id, Milliseconds(cooldown));
    return true;
}
void Blood(Player* player)
{
    Cast(player, player, 800999);
    if (Chance(player, 300391))
        Cast(player, player, 804011);
    if (Chance(player, 707631) || Chance(player, 707840))
        Unleash(player, player, .5f);
    Refresh(player);
}
void SetRemainingUses(Aura* aura, uint8 uses)
{
    aura->SetScriptValue(aura->GetId(), uses);
    aura->SetCharges(uses);
    aura->SetUsingCharges(false);
}
void Refresh(Player* player)
{
    auto& state = State(player);
    if (state.refreshing)
        return;
    state.refreshing = true;
    state.imps.erase(std::remove_if(state.imps.begin(), state.imps.end(),
                                    [player](ObjectGuid id) {
                                        Creature* unit = ObjectAccessor::GetCreature(*player, id);
                                        return !unit || !unit->IsAlive() || unit->GetOwnerGUID() != player->GetGUID();
                                    }),
                     state.imps.end());
    uint32 imps = uint32(state.imps.size());
    auto scale = [player](uint32 id, int32 value) {
        if (!value)
        {
            player->RemoveAurasDueToSpell(id);
            return;
        }
        Aura* aura = player->GetAura(id);
        if (!aura)
            aura = player->AddAura(id, player);
        if (aura && aura->GetEffect(EFFECT_0) && aura->GetEffect(EFFECT_0)->GetAmount() != value)
            aura->GetEffect(EFFECT_0)->ChangeAmount(value);
    };
    int32 blockPerImp = player->HasAura(707836)                ? Amount(302546, 1)
                        : player->GetAuraOfRankedSpell(706569) ? Amount(302546)
                                                               : 0;
    scale(302546, int32(imps) * blockPerImp);
    scale(302573, player->HasAura(804340) ? imps * Amount(302573) : 0);
    scale(302574, player->HasAura(804340) ? -int32(imps) * Amount(302574) : 0);
    scale(302592, imps);
    scale(805965, -150 * int32(imps));
    if (AuraEffect* effect = player->GetAuraEffect(573066, EFFECT_0))
        effect->ChangeAmount(Amount(573066) + imps * Amount(805916, 2));
    for (uint32 id : {704195, 704217, 707630})
        player->RemoveAurasDueToSpell(id);
    if (AuraEffect* effect = player->GetAuraEffect(704186, EFFECT_0))
        effect->ChangeAmount(Amount(704186) + 10 * Count(player, 500906));
    if (AuraEffect* effect = player->GetAuraEffect(704953, EFFECT_0))
        effect->ChangeAmount(Count(player, 500906));

    scale(573075, player->HasAura(573035) ? player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_BLOCK) / 2 : 0);
    if (player->HasAura(706502) && !player->HasSpell(504581))
        player->learnSpell(504581, true);
    if (!player->HasAura(706502))
    {
        player->RemoveAurasDueToSpell(712294);
        if (player->HasSpell(504581))
            player->removeSpell(504581, SPEC_MASK_ALL, false);
    }
    Replace(player, 800340, player->HasAura(706502) && player->HasAura(712294) ? 504581 : 0);
    if (player->HasAura(800710) && !player->HasSpell(520005))
        player->learnSpell(520005);
    if (!player->HasAura(800710) && player->HasSpell(520005))
    {
        Replace(player, 500904, 0);
        player->removeSpell(520005, SPEC_MASK_ALL, false);
    }
    for (auto const& replacement : {std::array<uint32, 3>{800710, 500904, 520005},
                                    {570727, 801059, 802581},
                                    {807587, 801059, 520292}})
    {
        uint32 talent = replacement[0];
        if (talent == 570727 && player->HasAura(807587))
            continue;
        if (talent == 807587 && player->HasAura(570727) && !player->HasAura(807587))
            continue;
        Replace(player, replacement[1], player->HasAura(talent) ? replacement[2] : 0);
    }
    bool impTalent = player->HasAura(92101) || player->HasAura(704993);
    if (impTalent && !player->HasSpell(520661))
        player->learnSpell(520661);
    if (!impTalent && player->HasSpell(520661))
        player->removeSpell(520661, SPEC_MASK_ALL, false);
    if (Pet* pet = player->GetPet(); pet && pet->GetEntry() == 510100)
    {
        if (!pet->HasAura(520662))
            Cast(player, pet, 520662);
        if (pet->HasSpell(800444))
        {
            pet->ToggleAutocast(sSpellMgr->GetSpellInfo(800444), false);
            pet->removeSpell(800444, false);
        }
        bool learned = false;
        for (uint32 id : {630930, 630931})
            if (!pet->HasSpell(id))
            {
                pet->learnSpell(id);
                pet->ToggleAutocast(sSpellMgr->GetSpellInfo(id), true);
                learned = true;
            }
        if (learned)
        {
            player->PetSpellInitialize();
        }
    }
    state.refreshing = false;
}
void Unleash(Player* player, Unit* center, float strength, bool pet)
{
    if (!player || !center)
        return;
    uint32 active = 0;
    for (uint32 id : {801053, 802344, 802345, 804786, 801054})
        if (player->HasAura(id))
            active = id;
    if (pet)
    {
        active = center->HasAura(802605)   ? 801053
                 : center->HasAura(802603) ? 802344
                 : center->HasAura(802604) ? 802345
                 : center->HasAura(806962) ? 804786
                                           : active;
    }
    uint32 spell = active == 801053   ? 802857
                   : active == 802344 ? 802856
                   : active == 802345 ? 802855
                   : active == 804786 ? 560817
                   : active == 801054 ? 801055
                                      : 0;
    if (!spell)
        return;
    if (spell == 801055 && player->HasAura(704954))
        strength *= 1 + Amount(704954) / 100.0f;
    float old = State(player).unleash;
    State(player).unleash = strength;
    uint32 n = 0;
    for (Unit* target : Nearby(center, 10.0f))
        if (player->IsValidAttackTarget(target) && center->IsWithinLOSInMap(target))
        {
            Cast(player, target, spell);
            if (++n == 10)
                break;
        }
    if (active == 802345)
    {
        HealInfo heal(player, player, uint32(player->GetMaxHealth() * .05f * strength), sSpellMgr->GetSpellInfo(802855),
                      SPELL_SCHOOL_MASK_FIRE);
        player->HealBySpell(heal);
    }
    State(player).unleash = old;
}
void Spread(Player* player, Unit* target)
{
    std::vector<Aura*> source;
    for (auto const& pair : target->GetAppliedAuras())
    {
        Aura* aura = pair.second->GetBase();
        if (aura->GetCasterGUID() == player->GetGUID() &&
            (Named(aura->GetSpellInfo(), 806965) || aura->GetId() == 803334))
            source.push_back(aura);
    }
    uint32 count = 0;
    for (Unit* enemy : Nearby(target, 10.0f))
    {
        if (enemy == target || !player->IsValidAttackTarget(enemy) || !target->IsWithinLOSInMap(enemy))
            continue;
        bool copied = false;
        for (Aura* old : source)
            if (Aura* aura = player->AddAura(old->GetId(), enemy))
            {
                aura->SetMaxDuration(old->GetMaxDuration());
                aura->SetDuration(old->GetDuration());
                aura->SetScriptValue(802619, 0);
                for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
                    if (AuraEffect* effect = old->GetEffect(i))
                        if (AuraEffect* copy = aura->GetEffect(i))
                        {
                            copy->ChangeAmount(effect->GetAmount());
                            copy->SetPeriodicTimer(effect->GetPeriodicTimer());
                        }
                copied = true;
            }
        if (copied && ++count == 3)
            break;
    }
}
}
namespace
{
class xoroth_player : public PlayerScript
{
  public:
    xoroth_player()
        : PlayerScript("xoroth_player",
                       {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_AFTER_UPDATE_MAX_HEALTH,
                        PLAYERHOOK_ON_BEFORE_GUARDIAN_INIT_STATS_FOR_LEVEL})
    {
    }
    void OnPlayerBeforeGuardianInitStatsForLevel(Player* player, Guardian* guardian, CreatureTemplate const*,
                                                 PetType& type) override
    {
        if (AscensionXoroth::Owner(player) && guardian && guardian->GetEntry() == 510100)
            type = SUMMON_PET;
    }
    void OnPlayerAfterUpdateMaxHealth(Player* player, float& value) override
    {
        if (AscensionXoroth::Owner(player) && player->HasAura(92104))
            value *= 1.0f + AscensionXoroth::Count(player, 800999) * .01f;
    }
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        using namespace AscensionXoroth;
        if (!Owner(player))
            return;
        auto& state = State(player);
        state.timers.Update(diff);
        state.scheduler.Update(diff);
        while (state.timers.ExecuteEvent())
        {
        }
        if (!state.timers.HasTimeUntilEvent(1))
        {
            Refresh(player);
            state.timers.ScheduleEvent(1, 250ms);
        }
    }
    void OnPlayerLogout(Player* player) override
    {
        using namespace AscensionXoroth;
        if (!Owner(player))
            return;
        for (ObjectGuid guid : State(player).imps)
            if (Creature* creature = ObjectAccessor::GetCreature(*player, guid))
                creature->DespawnOrUnsummon();
        std::lock_guard<std::mutex> lock(stateMutex);
        states.erase(player->GetGUID());
    }
};
}
void AddSC_AscensionXoroth()
{
    new xoroth_player();
}
