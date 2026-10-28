/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBarbarian.h"
#include "AscensionBarbarianCompletion.h"
#include "Item.h"
#include "Player.h"
#include "Random.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include <vector>

namespace
{
constexpr uint32 HEADHUNTER = 92082;
constexpr uint32 HEADHUNTER_EFFECTS = 706432;
constexpr uint32 FILL_LEVEL = 92083;
constexpr uint32 FILL_LEVEL_EFFECTS = 500061;
constexpr uint32 TANKARD = 805813;
constexpr uint32 BODY_BUILDER = 706481;
constexpr uint32 BODY_BUILDER_SIZE = 706508;
constexpr uint32 SPEAR_THROWER = 574321;

constexpr uint32 BRUTAL_SWING_FIRST_HIGHER_RANK = 500996;
constexpr uint32 BRUTAL_SWING_LAST_RANK = 501002;
constexpr uint32 DECAPITATE_FIRST_HIGHER_RANK = 806905;
constexpr uint32 DECAPITATE_LAST_RANK = 806908;

constexpr uint32 ONE_HANDED_WEAPON_SUBCLASS_MASK = (1 << ITEM_SUBCLASS_WEAPON_AXE) |
    (1 << ITEM_SUBCLASS_WEAPON_MACE) | (1 << ITEM_SUBCLASS_WEAPON_SWORD) |
    (1 << ITEM_SUBCLASS_WEAPON_FIST) | (1 << ITEM_SUBCLASS_WEAPON_DAGGER) |
    (1 << ITEM_SUBCLASS_WEAPON_SPEAR);
constexpr uint32 TWO_HANDED_WEAPON_SUBCLASS_MASK = (1 << ITEM_SUBCLASS_WEAPON_AXE2) |
    (1 << ITEM_SUBCLASS_WEAPON_MACE2) | (1 << ITEM_SUBCLASS_WEAPON_POLEARM) |
    (1 << ITEM_SUBCLASS_WEAPON_SWORD2) | (1 << ITEM_SUBCLASS_WEAPON_STAFF);

bool IsHigherRankOfMixedWeaponChain(uint32 spellId)
{
    return (spellId >= BRUTAL_SWING_FIRST_HIGHER_RANK && spellId <= BRUTAL_SWING_LAST_RANK) ||
        (spellId >= DECAPITATE_FIRST_HIGHER_RANK && spellId <= DECAPITATE_LAST_RANK);
}

void ClearContradictingWeaponSlotRequirement(SpellInfo* info)
{
    if (!info || info->EquippedItemClass != ITEM_CLASS_WEAPON || !info->EquippedItemInventoryTypeMask ||
        !IsHigherRankOfMixedWeaponChain(info->Id))
        return;

    uint32 const subclassMask = uint32(info->EquippedItemSubClassMask);
    if (!(subclassMask & ONE_HANDED_WEAPON_SUBCLASS_MASK) || !(subclassMask & TWO_HANDED_WEAPON_SUBCLASS_MASK))
    {
        LOG_ERROR("coa", "Skipped unexpected Barbarian weapon requirement record {}", info->Id);
        return;
    }

    LOG_INFO("coa", "Cleared the equipment slot requirement of Barbarian rank {} that its own weapon "
        "subclasses contradict", info->Id);
    info->EquippedItemInventoryTypeMask = 0;
}
}

void ApplyAscensionBarbarianSpellChanges(SpellInfo* info)
{
    AscensionBarbarian::ApplyContracts(info);
    if (info && info->Id == BODY_BUILDER_SIZE && info->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_MOD_SCALE &&
        info->Effects[EFFECT_1].BasePoints == 6 && info->Effects[EFFECT_1].DieSides == 1)
        info->Effects[EFFECT_1].BasePoints = 4;
    ClearContradictingWeaponSlotRequirement(info);
}

void HandleAscensionBarbarianAura(Player* player, uint32 spellId, bool apply)
{
    if (!player || player->getClass() != CLASS_BARBARIAN)
        return;

    uint32 helper = 0;
    switch (spellId)
    {
        case HEADHUNTER:
            helper = HEADHUNTER_EFFECTS;
            break;
        case FILL_LEVEL:
            helper = FILL_LEVEL_EFFECTS;
            if (!apply)
            {
                player->RemoveAurasDueToSpell(TANKARD);
                player->RemoveAurasDueToSpell(AscensionBarbarian::SPELL_FULL_TANKARD);
                player->RemoveAurasDueToSpell(AscensionBarbarian::SPELL_EMPTY_TANKARD);
            }
            break;
        case BODY_BUILDER:
            helper = BODY_BUILDER_SIZE;
            break;
        default:
            return;
    }

    if (apply)
    {
        if (!player->HasAura(helper))
            player->AddAura(helper, player);
    }
    else
        player->RemoveAurasDueToSpell(helper);
}

void HandleAscensionBarbarianAttackPower(Player* player, float& modifier, bool ranged)
{
    if (!player || player->getClass() != CLASS_BARBARIAN || ranged ||
        player->GetStat(STAT_STRENGTH) < player->GetStat(STAT_AGILITY))
        return;

    if (AuraEffect const* effect = player->GetAuraEffect(BODY_BUILDER, EFFECT_0))
        modifier -= CalculatePct(player->GetStat(STAT_STRENGTH), effect->GetAmount());
}

void HandleAscensionBarbarianCast(Spell* spell)
{
    if (!spell || spell->IsTriggered())
        return;
    Player* player = spell->GetCaster()->ToPlayer();
    if (!player || player->getClass() != CLASS_BARBARIAN)
        return;

    SpellInfo const* info = spell->GetSpellInfo();
    bool preserveTankard = player->HasAura(705218) && info->SpellFamilyName == 18 &&
        (info->Id == 805780 || info->Id == 573064 || info->Id == 573224 || info->Id == 573225);
    if (AuraEffect const* tankard = player->GetAuraEffect(TANKARD, EFFECT_0))
    {
        SpellInfo const* resource = tankard->GetSpellInfo();
        if (!preserveTankard && resource->SpellFamilyName == info->SpellFamilyName &&
            (resource->Effects[EFFECT_0].SpellClassMask & info->SpellFamilyFlags))
        {
            player->RemoveAurasDueToSpell(TANKARD);
            player->AddAura(AscensionBarbarian::SPELL_EMPTY_TANKARD, player);
        }
    }

    if (info->SpellFamilyName != 18 || !(info->SpellFamilyFlags[1] & 0x00040000) ||
        !player->HasAura(SPEAR_THROWER))
        return;

    float chance = 30.0f;
    player->ApplySpellMod(SPEAR_THROWER, SPELLMOD_CHANCE_OF_SUCCESS, chance, spell);
    if (!roll_chance_f(chance))
        return;

    std::vector<uint32> reset;
    for (auto const& [spellId, cooldown] : player->GetSpellCooldownMap())
    {
        (void)cooldown;
        uint32 root = sSpellMgr->GetFirstSpellInChain(spellId);
        if (root == 804137 || root == 500984 || root == 560881 || root == 804139)
            reset.push_back(spellId);
    }
    for (uint32 spellId : reset)
    {
        player->RemoveSpellCooldown(spellId, true);
        if (SpellInfo const* spear = sSpellMgr->GetSpellInfo(spellId))
            if (uint32 category = spear->GetCategory())
                player->RemoveCategoryCooldown(category);
    }
}
