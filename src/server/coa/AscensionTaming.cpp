/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionTamingData.h"
#include "AscensionWildcard.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "SpellMgr.h"
#include <algorithm>
#include <array>
#include <unordered_map>

namespace AscensionTaming
{
namespace
{
bool IsKind(uint32 creatureEntry, uint32 kind)
{
    CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(creatureEntry);
    return creature && creature->type == kind;
}

uint32 FamilyPetStatsEntry(uint32 family)
{
    static std::unordered_map<uint32, uint32> const entries = []
    {
        std::unordered_map<uint32, uint32> lowest;
        for (auto const& [entry, creature] : *sObjectMgr->GetCreatureTemplates())
            if (creature.family && sObjectMgr->GetPetLevelInfo(entry, 1))
                if (uint32& found = lowest[creature.family]; !found || entry < found)
                    found = entry;
        return lowest;
    }();
    auto const found = entries.find(family);
    return found == entries.end() ? 0 : found->second;
}

uint32 TamedPetBaseMana(CreatureTemplate const* creature, uint8 level)
{
    if (uint32 const entry = FamilyPetStatsEntry(creature->family))
        if (uint32 const mana = sObjectMgr->GetPetLevelInfo(entry, level)->mana)
            return mana;
    if (uint32 const mana = sObjectMgr->GetCreatureBaseStats(level, creature->unit_class)->BaseMana)
        return mana;
    return sObjectMgr->GetCreatureBaseStats(level, CLASS_PALADIN)->BaseMana;
}

Powers TamedPetPowerType(uint32 family)
{
    static std::unordered_map<uint32, Powers> const types = []
    {
        std::unordered_map<uint32, Powers> kits;
        for (CreatureFamilyEntry const* entry : sCreatureFamilyStore)
        {
            PetLevelupSpellSet const* spells = sSpellMgr->GetPetLevelupSpellList(entry->ID);
            if (!spells)
                continue;
            bool energy = false, mana = false;
            for (auto const& [level, spellId] : *spells)
                if (SpellInfo const* spell = sSpellMgr->GetSpellInfo(spellId);
                    spell && (spell->ManaCost || spell->ManaCostPercentage))
                {
                    energy |= spell->PowerType == POWER_ENERGY;
                    mana |= spell->PowerType == POWER_MANA;
                }
            if (energy || mana)
                kits[entry->ID] = energy ? POWER_ENERGY : POWER_MANA;
        }
        return kits;
    }();
    auto const found = types.find(family);
    return found == types.end() ? POWER_FOCUS : found->second;
}

bool IsHunterPetOfKind(PetStable::PetInfo const& pet, uint32 kind)
{
    return pet.Type == HUNTER_PET && IsKind(pet.CreatureId, kind);
}

void MoveToSlot(Player* player, uint32 petNumber, PetSaveMode slot)
{
    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_UPD_CHAR_PET_SLOT_BY_ID);
    stmt->SetData(0, uint8(slot));
    stmt->SetData(1, player->GetGUID().GetCounter());
    stmt->SetData(2, petNumber);
    CharacterDatabase.Execute(stmt);
}

std::optional<std::size_t> FreeStableSlot(PetStable const& stable)
{
    for (std::size_t slot = 0; slot < stable.MaxStabledPets && slot < stable.StabledPets.size(); ++slot)
        if (!stable.StabledPets[slot])
            return slot;
    return std::nullopt;
}

void StableUnslottedHunterPets(Player* player, PetStable& stable)
{
    for (auto pet = stable.UnslottedPets.begin(); pet != stable.UnslottedPets.end();)
    {
        std::optional<std::size_t> const slot = pet->Type == HUNTER_PET ? FreeStableSlot(stable) : std::nullopt;
        if (!slot)
        {
            ++pet;
            continue;
        }
        MoveToSlot(player, pet->PetNumber, PetSaveMode(PET_SAVE_FIRST_STABLE_SLOT + *slot));
        stable.StabledPets[*slot] = std::move(*pet);
        pet = stable.UnslottedPets.erase(pet);
    }
}

bool HasUnslottedHunterPet(PetStable const& stable)
{
    for (PetStable::PetInfo const& pet : stable.UnslottedPets)
        if (pet.Type == HUNTER_PET)
            return true;
    return false;
}

bool CanLoad(Player* player, PetStable::PetInfo const& pet)
{
    if (!pet.Health)
    {
        player->SendTameFailure(PET_TAME_DEAD);
        return false;
    }
    CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(pet.CreatureId);
    if (!creature || !creature->IsTameable(player->CanTameExoticPets()))
    {
        player->SendTameFailure(creature && creature->IsTameable(true) ? PET_TAME_CANT_CONTROL_EXOTIC
                                                                         : PET_TAME_NOPET_AVAILABLE);
        return false;
    }
    return true;
}

struct Plan
{
    std::optional<std::size_t> WantedSlot;
    std::optional<std::size_t> WantedUnslotted;
    std::optional<std::size_t> ParkSlot;

    bool HasWanted() const { return WantedSlot || WantedUnslotted; }
};

SpellCastResult MakePlan(Player* player, PetStable const& stable, Pet const* out, uint32 kind, Plan& plan)
{
    for (std::size_t slot = 0; slot < stable.StabledPets.size() && !plan.HasWanted(); ++slot)
        if (stable.StabledPets[slot] && IsHunterPetOfKind(*stable.StabledPets[slot], kind))
            plan.WantedSlot = slot;
    for (std::size_t index = 0; index < stable.UnslottedPets.size() && !plan.HasWanted(); ++index)
        if (IsHunterPetOfKind(stable.UnslottedPets[index], kind))
            plan.WantedUnslotted = index;

    if (plan.WantedSlot && !CanLoad(player, *stable.StabledPets[*plan.WantedSlot]))
        return SPELL_FAILED_DONT_REPORT;
    if (plan.WantedUnslotted && !CanLoad(player, stable.UnslottedPets[*plan.WantedUnslotted]))
        return SPELL_FAILED_DONT_REPORT;

    if (out ? out->getPetType() != HUNTER_PET : !stable.CurrentPet || stable.CurrentPet->Type != HUNTER_PET)
        return SPELL_CAST_OK;

    if (out ? !out->IsAlive() : !stable.CurrentPet->Health)
    {
        player->SendTameFailure(PET_TAME_DEAD);
        return SPELL_FAILED_DONT_REPORT;
    }
    plan.ParkSlot = plan.WantedSlot ? plan.WantedSlot : FreeStableSlot(stable);
    if (!plan.ParkSlot)
    {
        player->SendTameFailure(PET_TAME_TOO_MANY);
        return SPELL_FAILED_DONT_REPORT;
    }
    return SPELL_CAST_OK;
}

void ParkCurrent(Player* player, PetStable& stable, Pet* out, std::optional<std::size_t> slot)
{
    if (!slot)
    {
        if (out)
            player->RemovePet(out, PET_SAVE_NOT_IN_SLOT);
        else if (stable.CurrentPet)
        {
            MoveToSlot(player, stable.CurrentPet->PetNumber, PET_SAVE_NOT_IN_SLOT);
            stable.UnslottedPets.push_back(std::move(*stable.CurrentPet));
            stable.CurrentPet.reset();
        }
        return;
    }

    PetSaveMode const mode = PetSaveMode(PET_SAVE_FIRST_STABLE_SLOT + *slot);
    if (out)
        player->RemovePet(out, mode);
    else
        MoveToSlot(player, stable.CurrentPet->PetNumber, mode);
    std::swap(stable.StabledPets[*slot], stable.CurrentPet);
}

void Swap(Player* player, PetStable& stable, Pet* out, Plan const& plan)
{
    PetStable::PetInfo wanted;
    if (plan.WantedSlot)
    {
        wanted = std::move(*stable.StabledPets[*plan.WantedSlot]);
        stable.StabledPets[*plan.WantedSlot].reset();
    }
    else
    {
        wanted = std::move(stable.UnslottedPets[*plan.WantedUnslotted]);
        stable.UnslottedPets.erase(stable.UnslottedPets.begin() + *plan.WantedUnslotted);
    }

    ParkCurrent(player, stable, out, plan.ParkSlot);
    MoveToSlot(player, wanted.PetNumber, PET_SAVE_AS_CURRENT);
    stable.CurrentPet = std::move(wanted);
}

bool GrantStarter(Player* player, FamilyCall const& call)
{
    if (player->GetPetGUID())
        return false;
    Pet* pet = player->CreateTamedPetFrom(call.Starter, call.SpellId);
    if (!pet)
    {
        PetStable const* stable = player->GetPetStable();
        LOG_ERROR("coa", "Starter pet {} for {} of {} could not be created: current {} unslotted {}", call.Starter,
            call.SpellId, player->GetName(), stable && stable->CurrentPet ? stable->CurrentPet->CreatureId : 0,
            stable ? stable->UnslottedPets.size() : 0);
        return false;
    }

    uint8 const level = player->GetLevel();
    pet->SetUInt32Value(UNIT_FIELD_LEVEL, level > 1 ? level - 1 : level);
    pet->GetMap()->AddToMap(pet->ToCreature(), true);
    pet->SetUInt32Value(UNIT_FIELD_LEVEL, level);
    player->SetMinion(pet, true);
    pet->InitTalentForLevel();
    pet->SavePetToDB(PET_SAVE_AS_CURRENT);
    player->PetSpellInitialize();
    LOG_INFO("coa", "Granted {} the starter pet {} for spell {}", player->GetName(), call.Starter, call.SpellId);
    return true;
}
}

class spell_ascension_family_call : public SpellScript
{
    PrepareSpellScript(spell_ascension_family_call);

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        FamilyCall const* call = FindFamilyCall(GetSpellInfo()->Id);
        if (!player || !call || !AscensionWildcard::IsClasslessHero(player))
            return SPELL_CAST_OK;

        if (player->GetCharmGUID())
            return SPELL_CAST_OK;

        PetStable& stable = player->GetOrInitPetStable();
        Pet* out = player->GetPet();
        if (out ? out->getPetType() == HUNTER_PET && IsKind(out->GetEntry(), call->Kind)
                : stable.CurrentPet && IsHunterPetOfKind(*stable.CurrentPet, call->Kind))
            return SPELL_CAST_OK;

        StableUnslottedHunterPets(player, stable);

        Plan plan;
        if (SpellCastResult const result = MakePlan(player, stable, out, call->Kind, plan); result != SPELL_CAST_OK)
            return result;

        if (plan.HasWanted())
        {
            Swap(player, stable, out, plan);
            return SPELL_CAST_OK;
        }

        if (call->Kind == KIND_BEAST || !call->Starter || !sObjectMgr->GetCreatureTemplate(call->Starter))
        {
            player->SendTameFailure(PET_TAME_NOPET_AVAILABLE);
            return SPELL_FAILED_DONT_REPORT;
        }
        if (HasUnslottedHunterPet(stable))
        {
            player->SendTameFailure(PET_TAME_TOO_MANY);
            return SPELL_FAILED_DONT_REPORT;
        }

        ParkCurrent(player, stable, out, plan.ParkSlot);
        GrantStarter(player, *call);
        return SPELL_FAILED_DONT_REPORT;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_family_call::CheckCast);
    }
};

class AscensionTamingPlayer final : public PlayerScript
{
public:
    AscensionTamingPlayer() : PlayerScript("AscensionTamingPlayer", { PLAYERHOOK_ON_FORGOT_SPELL }) { }

    void OnPlayerForgotSpell(Player* player, uint32 spellId) override
    {
        FamilyCall const* call = FindFamilyCall(spellId);
        if (!call || !AscensionWildcard::IsClasslessHero(player))
            return;
        if (Pet* out = player->GetPet(); out && out->getPetType() == HUNTER_PET && IsKind(out->GetEntry(), call->Kind))
            player->RemovePet(out, PET_SAVE_AS_CURRENT);
    }
};

class AscensionTamingPet final : public PetScript
{
public:
    AscensionTamingPet() : PetScript("AscensionTamingPet", { PETHOOK_ON_INIT_STATS_FOR_LEVEL }) { }

    void OnInitStatsForLevel(Guardian* guardian, uint8 petlevel) override
    {
        CreatureTemplate const* creature = guardian->GetCreatureTemplate();
        if (!guardian->IsHunterPet() || creature->type == CREATURE_TYPE_BEAST)
            return;
        uint32 const mana = TamedPetBaseMana(creature, petlevel);
        guardian->SetCreateMana(mana);
        guardian->SetStatFlatModifier(UNIT_MOD_MANA, BASE_VALUE, float(mana));

        Powers const power = TamedPetPowerType(creature->family);
        guardian->setPowerType(power);
        if (power == POWER_ENERGY)
            guardian->SetPower(POWER_ENERGY, guardian->GetMaxPower(POWER_ENERGY));
    }
};

enum PetKitSpells : uint32
{
    SPELL_TAIL_SWEEP            = 891013,
    SPELL_TREANT_REJUVENATION   = 93717,
    SPELL_TREANT_RENEW          = 93726,
    SPELL_RESPLENDENT_LIGHT     = 414260
};

constexpr std::array<uint32, 4> SOOTHING_KISS = { 6360, 7813, 11784, 11785 };
constexpr uint32 DURATION_UNTIL_CANCELLED = 21;

class AscensionTamingSpellData final : public GlobalScript
{
public:
    AscensionTamingSpellData() : GlobalScript("AscensionTamingSpellData", { GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR }) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == SPELL_TAIL_SWEEP)
            info->AttributesEx3 &= ~SPELL_ATTR3_ONLY_ON_PLAYER;
        else if (std::find(SOOTHING_KISS.begin(), SOOTHING_KISS.end(), info->Id) != SOOTHING_KISS.end() &&
            !info->DurationEntry)
            info->DurationEntry = sSpellDurationStore.LookupEntry(DURATION_UNTIL_CANCELLED);
        else if (info->Id == SPELL_TREANT_REJUVENATION || info->Id == SPELL_TREANT_RENEW)
        {
            SpellInfo const* sibling = sSpellMgr->GetSpellInfo(SPELL_RESPLENDENT_LIGHT);
            for (SpellEffectInfo& effect : info->Effects)
                if (sibling && effect.TargetA.GetTarget() == TARGET_UNIT_DEST_AREA_ALLY && !effect.RadiusEntry)
                    effect.RadiusEntry = sibling->Effects[EFFECT_0].RadiusEntry;
        }
    }
};

class spell_ascension_pet_lowest_health_allies : public SpellScript
{
    PrepareSpellScript(spell_ascension_pet_lowest_health_allies);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        targets.sort(Acore::HealthPctOrderPred());
        if (uint32 const limit = GetSpellInfo()->MaxAffectedTargets; targets.size() > limit)
            targets.resize(limit);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_pet_lowest_health_allies::FilterTargets,
            EFFECT_ALL, TARGET_UNIT_DEST_AREA_ALLY);
    }
};
}

void AddAscensionTamingScripts()
{
    RegisterSpellScriptWithArgs(AscensionTaming::spell_ascension_family_call, "spell_ascension_family_call");
    new AscensionTaming::AscensionTamingPlayer();
    new AscensionTaming::AscensionTamingPet();
    new AscensionTaming::AscensionTamingSpellData();
    RegisterSpellScript(AscensionTaming::spell_ascension_pet_lowest_health_allies);
}
