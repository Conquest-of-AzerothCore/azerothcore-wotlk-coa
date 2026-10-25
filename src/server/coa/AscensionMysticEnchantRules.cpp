/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionMysticEnchantRules.h"
#include "ClientDBC.h"
#include "DBCStores.h"
#include "Log.h"
#include <algorithm>
#include <cmath>
#include <string_view>
#include <unordered_map>

namespace AscensionMysticEnchant
{
std::array<char const*, QUALITY_MAX + 1> const QUALITY_NAMES = { "RE_QUALITY_POOR", "RE_QUALITY_NORMAL",
    "RE_QUALITY_UNCOMMON", "RE_QUALITY_RARE", "RE_QUALITY_EPIC", "RE_QUALITY_LEGENDARY", "RE_QUALITY_ARTIFACT",
    "RE_QUALITY_HEIRLOOM", "RE_QUALITY_MAX" };

std::array<char const*, APPLY_RESULT_COUNT> const APPLY_RESULTS = { "RE_APPLY_OK", "RE_APPLY_UNKNOWN",
    "RE_APPLY_BAD_ITEM", "RE_APPLY_NOT_MYSTIC_SCROLL", "RE_APPLY_BAD_SLOT", "RE_APPLY_DUPLICATE_BAG_SLOT_PAIR",
    "RE_APPLY_STACK_LIMIT", "RE_APPLY_UNCOMMON_LIMIT", "RE_APPLY_RARE_LIMIT", "RE_APPLY_EPIC_LIMIT",
    "RE_APPLY_LEGENDARY_LIMIT", "RE_APPLY_ARTIFACT_LIMIT", "RE_APPLY_UNHANDLED_LIMIT", "RE_APPLY_BAD_ENCHANTMENT",
    "RE_APPLY_BUILD_DRAFT", "RE_APPLY_NOT_WHILE_CASTING", "RE_APPLY_NO_MONEY", "RE_APPLY_BAD_CLASS",
    "RE_APPLY_BAD_REALM", "RE_APPLY_DISABLED_IN_WILDCARD", "RE_APPLY_RARE_WORLDFORGED_LIMIT",
    "RE_APPLY_REQUIRED_AE_INVESTMENT", "RE_APPLY_REQUIRED_TE_INVESTMENT", "RE_APPLY_TOO_LOW_LEVEL",
    "RE_APPLY_DUPLICATE_SLOT", "RE_APPLY_NO_MYSTIC_ALTAR" };

std::array<char const*, DESTROY_RESULT_COUNT> const DESTROY_RESULTS = { "RE_DESTROY_OK", "RE_DESTROY_UNKNOWN",
    "RE_DESTROY_BAD_SLOT", "RE_DESTROY_NO_ENCHANT_APPLIED", "RE_DESTROY_NOT_WHILE_CASTING", "RE_DESTROY_BAD_CLASS",
    "RE_DESTROY_BUILD_DRAFT" };

std::array<char const*, PURCHASE_RESULT_COUNT> const PURCHASE_RESULTS = { "RE_PURCHASE_OK", "RE_PURCHASE_UNKNOWN",
    "RE_PURCHASE_ITEM_NOT_FOUND", "RE_PURCHASE_NOT_ENOUGH_MONEY", "RE_PURCHASE_NOT_ENOUGH_SPACE",
    "RE_PURCHASE_NO_MYSTIC_ALTAR", "RE_PURCHASE_NOT_WHILE_CASTING", "RE_PURCHASE_BAD_CLASS" };

std::array<char const*, INSPECT_RESULT_COUNT> const INSPECT_RESULTS = { "RE_INSPECT_OK", "RE_INSPECT_UNKNOWN",
    "RE_INSPECT_PLAYER_NOT_FOUND", "RE_INSPECT_PLAYER_NOT_IN_MAP", "RE_INSPECT_BAD_CLASS" };

std::array<char const*, PRESET_SAVE_RESULT_COUNT> const PRESET_SAVE_RESULTS = { "RE_PRESET_SAVE_OK",
    "RE_PRESET_SAVE_UNKNOWN", "RE_PRESET_SAVE_BUILD_DRAFT", "RE_PRESET_SAVE_BAD_CLASS" };

std::array<char const*, PRESET_SET_ACTIVE_RESULT_COUNT> const PRESET_SET_ACTIVE_RESULTS = {
    "RE_PRESET_SET_ACTIVE_OK", "RE_PRESET_SET_ACTIVE_UNKNOWN", "RE_PRESET_SET_ACTIVE_BUILD_DRAFT",
    "RE_PRESET_SET_ACTIVE_NOT_WHILE_CASTING", "RE_PRESET_SET_ACTIVE_BAD_CLASS" };

std::array<char const*, PRESET_UNLOCK_RESULT_COUNT> const PRESET_UNLOCK_RESULTS = { "RE_PRESET_UNLOCK_OK",
    "RE_PRESET_UNLOCK_UNKNOWN", "RE_PRESET_UNLOCK_MAX_VALUE_REACHED", "RE_PRESET_UNLOCK_NO_MONEY",
    "RE_PRESET_UNLOCK_BUILD_DRAFT", "RE_PRESET_UNLOCK_NOT_WHILE_CASTING", "RE_PRESET_UNLOCK_BAD_CLASS" };

std::array<char const*, REFORGE_RESULT_COUNT> const REFORGE_RESULTS = { "RE_REFORGE_OK", "RE_REFORGE_UNKNOWN",
    "RE_REFORGE_BAD_ITEM", "RE_REFORGE_NOT_MYSTIC_SCROLL", "RE_REFORGE_WORLDFORGED_SCROLL", "RE_REFORGE_BAD_SLOT",
    "RE_REFORGE_BUILD_DRAFT", "RE_REFORGE_NO_MONEY", "RE_REFORGE_NOT_IN_BATTLEGROUNDS", "RE_REFORGE_NO_MYSTIC_ALTAR",
    "RE_REFORGE_NOT_WHILE_CASTING", "RE_REFORGE_BAD_CLASS", "RE_REFORGE_DISABLED_IN_WILDCARD" };

std::array<char const*, COLLECTION_REFORGE_RESULT_COUNT> const COLLECTION_REFORGE_RESULTS = {
    "RE_COLLECTION_REFORGE_OK", "RE_COLLECTION_REFORGE_UNKNOWN", "RE_COLLECTION_REFORGE_BAD_ITEM",
    "RE_COLLECTION_REFORGE_NOT_MYSTIC_SCROLL", "RE_COLLECTION_REFORGE_WORLDFORGED_SCROLL",
    "RE_COLLECTION_REFORGE_WORLDFORGED_ENCHANT", "RE_COLLECTION_REFORGE_BAD_SLOT",
    "RE_COLLECTION_REFORGE_BUILD_DRAFT", "RE_COLLECTION_REFORGE_BAD_CLASS", "RE_COLLECTION_REFORGE_ALREADY_APPLIED",
    "RE_COLLECTION_REFORGE_BAD_ENCHANTMENT", "RE_COLLECTION_REFORGE_NOT_KNOWN_ENCHANTMENT",
    "RE_COLLECTION_REFORGE_NO_MONEY", "RE_COLLECTION_REFORGE_NOT_IN_BATTLEGROUNDS", "RE_COLLECTION_REFORGE_DISABLED",
    "RE_COLLECTION_REFORGE_STACK_LIMIT", "RE_COLLECTION_REFORGE_UNCOMMON_LIMIT", "RE_COLLECTION_REFORGE_RARE_LIMIT",
    "RE_COLLECTION_REFORGE_EPIC_LIMIT", "RE_COLLECTION_REFORGE_LEGENDARY_LIMIT",
    "RE_COLLECTION_REFORGE_ARTIFACT_LIMIT", "RE_COLLECTION_REFORGE_UNHANDLED_LIMIT",
    "RE_COLLECTION_REFORGE_NO_MYSTIC_ALTAR", "RE_COLLECTION_REFORGE_NOT_WHILE_CASTING",
    "RE_COLLECTION_REFORGE_BAD_REALM", "RE_COLLECTION_REFORGE_DISABLED_IN_WILDCARD",
    "RE_COLLECTION_REFORGE_RARE_WORLDFORGED_LIMIT", "RE_COLLECTION_REFORGE_REQUIRED_AE_INVESTMENT",
    "RE_COLLECTION_REFORGE_REQUIRED_TE_INVESTMENT", "RE_COLLECTION_REFORGE_TOO_LOW_LEVEL" };

std::array<char const*, DISENCHANT_RESULT_COUNT> const DISENCHANT_RESULTS = { "RE_DISENCHANT_OK",
    "RE_DISENCHANT_UNKNOWN", "RE_DISENCHANT_BAD_ITEM", "RE_DISENCHANT_NOT_MYSTIC_SCROLL", "RE_DISENCHANT_BAD_SLOT",
    "RE_DISENCHANT_BUILD_DRAFT", "RE_DISENCHANT_NO_ENCHANTMENT", "RE_DISENCHANT_BAD_ENCHANTMENT",
    "RE_DISENCHANT_ALREADY_KNOWN_ENCHANTMENT", "RE_DISENCHANT_NO_MONEY", "RE_DISENCHANT_NOT_IN_BATTLEGROUNDS",
    "RE_DISENCHANT_DISABLED", "RE_DISENCHANT_NO_MYSTIC_ALTAR", "RE_DISENCHANT_NOT_WHILE_CASTING",
    "RE_DISENCHANT_BAD_REALM", "RE_DISENCHANT_DISABLED_IN_WILDCARD" };

std::array<char const*, EXTRACT_PURCHASE_RESULT_COUNT> const EXTRACT_PURCHASE_RESULTS = {
    "RE_PURCHASE_MYSTIC_EXTRACT_OK", "RE_PURCHASE_MYSTIC_EXTRACT_UNKNOWN", "RE_PURCHASE_MYSTIC_EXTRACT_NO_TOKENS",
    "RE_PURCHASE_MYSTIC_EXTRACT_ALREADY_OBTAINED" };

namespace
{
enum EnchantField : std::uint32_t
{
    FIELD_ID             = 0,
    FIELD_SPELL          = 1,
    FIELD_WEIGHT         = 2,
    FIELD_QUALITY        = 3,
    FIELD_REBORN_QUALITY = 4,
    FIELD_REQUIRED_LEVEL = 5,
    FIELD_ITEM           = 6,
    FIELD_WORLDFORGED    = 7,
    FIELD_REALMS         = 8,
    FIELD_CLASS_MASK     = 13,
    FIELD_CLASS_TYPES    = 19,
    FIELD_TABS           = 22,
    FIELD_REQUIRED_AE    = 25,
    FIELD_REQUIRED_TE    = 28,
    FIELD_COUNT          = 31
};

std::uint32_t QualityIndex(std::string_view name)
{
    auto const itr = std::find(QUALITY_NAMES.begin(), QUALITY_NAMES.end(), name);
    if (itr != QUALITY_NAMES.end())
        return std::uint32_t(itr - QUALITY_NAMES.begin());
    LOG_ERROR("coa", "Mystic enchant quality {} is not one the client knows", name);
    return QUALITY_POOR;
}

Enchant ReadEnchant(ClientDBC::Record const& record)
{
    Enchant enchant;
    enchant.Id = record.GetUInt32(FIELD_ID);
    enchant.Spell = record.GetUInt32(FIELD_SPELL);
    enchant.Weight = record.GetFloat(FIELD_WEIGHT);
    enchant.Quality = QualityIndex(record.GetString(FIELD_QUALITY));
    enchant.RebornQuality = QualityIndex(record.GetString(FIELD_REBORN_QUALITY));
    enchant.RequiredLevel = record.GetUInt32(FIELD_REQUIRED_LEVEL);
    enchant.Item = record.GetUInt32(FIELD_ITEM);
    enchant.Worldforged = record.GetUInt32(FIELD_WORLDFORGED) != 0;
    for (std::size_t index = 0; index < REALM_COUNT; ++index)
        enchant.Realms[index] = record.GetUInt32(FIELD_REALMS + index) != 0;
    enchant.ClassMask = record.GetUInt32(FIELD_CLASS_MASK) |
        (std::uint64_t(record.GetUInt32(FIELD_CLASS_MASK + 1)) << 32);
    for (std::size_t index = 0; index < REQUIREMENT_COUNT; ++index)
    {
        enchant.ClassTypes[index] = record.GetUInt32(FIELD_CLASS_TYPES + index);
        enchant.Tabs[index] = record.GetUInt32(FIELD_TABS + index);
        enchant.RequiredAE[index] = record.GetUInt32(FIELD_REQUIRED_AE + index);
        enchant.RequiredTE[index] = record.GetUInt32(FIELD_REQUIRED_TE + index);
    }
    return enchant;
}

std::unordered_map<std::uint32_t, std::uint32_t> Projected(Catalog const& catalog, Character const& character,
    Slots const& slots, std::vector<StagedApply> const& staged, std::uint32_t slot, std::uint32_t spell)
{
    bool const fusion = character.Fusion();
    std::unordered_map<std::uint32_t, std::uint32_t> projected;
    for (std::uint32_t index = 0; index < SLOT_COUNT; ++index)
        projected[index] = SlotAt(slots, index, fusion);
    for (StagedApply const& entry : staged)
        if (Enchant const* enchant = entry.ItemFound ? catalog.FindItem(entry.ItemEntry) : nullptr)
            projected[entry.Slot] = enchant->Spell;
    if (spell)
        projected[slot] = spell;
    return projected;
}

std::uint32_t QualityLimit(std::uint32_t quality)
{
    switch (quality)
    {
        case QUALITY_UNCOMMON: return APPLY_UNCOMMON_LIMIT;
        case QUALITY_RARE: return APPLY_RARE_LIMIT;
        case QUALITY_EPIC: return APPLY_EPIC_LIMIT;
        case QUALITY_LEGENDARY: return APPLY_LEGENDARY_LIMIT;
        case QUALITY_ARTIFACT: return APPLY_ARTIFACT_LIMIT;
        default: return APPLY_UNHANDLED_LIMIT;
    }
}

void CheckEnchant(Catalog const& catalog, Character const& character, Slots const& slots,
    std::vector<StagedApply> const& staged, std::uint32_t slot, std::uint32_t spell, std::vector<std::uint32_t>& errors)
{
    Enchant const* enchant = catalog.FindSpell(spell);
    if (!enchant)
    {
        errors.push_back(APPLY_BAD_ENCHANTMENT);
        return;
    }
    std::unordered_map<std::uint32_t, std::uint32_t> const projected =
        Projected(catalog, character, slots, staged, slot, spell);
    std::uint32_t const quality = QualityOf(*enchant, character.Class);
    std::uint32_t sameSpell = 0;
    std::uint32_t sameQuality = 0;
    std::uint32_t rareWorldforged = 0;
    for (auto const& [index, held] : projected)
    {
        sameSpell += held == spell;
        if (Enchant const* other = catalog.FindSpell(held))
        {
            sameQuality += QualityOf(*other, character.Class) == quality;
            rareWorldforged += QualityOf(*other, character.Class) == QUALITY_RARE && other->Worldforged;
        }
    }
    std::uint32_t const stackLimit = character.StackLimit ? character.StackLimit(spell) : 0;
    if (stackLimit < sameSpell)
        errors.push_back(APPLY_STACK_LIMIT);
    if (QualityCap(character, quality) < sameQuality)
        errors.push_back(QualityLimit(quality));
    if (quality == QUALITY_RARE && enchant->Worldforged && rareWorldforged > RARE_WORLDFORGED_LIMIT)
        errors.push_back(APPLY_RARE_WORLDFORGED_LIMIT);
    if (!InvestmentMet(character, *enchant, false))
        errors.push_back(APPLY_REQUIRED_AE_INVESTMENT);
    if (!InvestmentMet(character, *enchant, true))
        errors.push_back(APPLY_REQUIRED_TE_INVESTMENT);
    if (character.Level < enchant->RequiredLevel)
        errors.push_back(APPLY_TOO_LOW_LEVEL);
    if (!ClassAllowed(*enchant, character.Class))
        errors.push_back(APPLY_BAD_CLASS);
    if (!RealmAllows(*enchant, character.RealmGates))
        errors.push_back(APPLY_BAD_REALM);
    else if (character.Wildcard())
        errors.push_back(APPLY_DISABLED_IN_WILDCARD);
}

void AddOnce(std::vector<std::uint32_t>& all, std::uint32_t error)
{
    if (std::find(all.begin(), all.end(), error) == all.end())
        all.push_back(error);
}

std::uint32_t UnlockedInOrder(Character const& character, std::uint32_t maximum, std::string const& prefix)
{
    for (std::uint32_t unlocked = 0;;)
    {
        std::int32_t const needed = character.Config ?
            character.Config->Int(prefix + std::to_string(unlocked + 1), 0) : 0;
        if (character.Level < std::uint32_t(needed))
            return unlocked;
        if (maximum <= ++unlocked)
            return maximum;
    }
}

std::uint32_t UnlockedAny(Character const& character, std::uint32_t cap, std::uint32_t count, std::string const& prefix)
{
    std::uint32_t unlocked = 0;
    for (std::uint32_t index = 1; index <= count; ++index)
        if (std::uint32_t(character.Config ? character.Config->Int(prefix + std::to_string(index), 0) : 0) <=
            character.Level)
            ++unlocked;
    return std::min(cap, unlocked);
}

std::int32_t Configured(Character const& character, std::string const& name, std::int32_t fallback)
{
    return character.Config ? character.Config->Int(name, fallback) : fallback;
}
}

Enchant const* Catalog::FindSpell(std::uint32_t spell) const
{
    auto const itr = BySpell.find(spell);
    return itr == BySpell.end() ? nullptr : &Rows[itr->second];
}

Enchant const* Catalog::FindItem(std::uint32_t item) const
{
    auto const itr = ByItem.find(item);
    return itr == ByItem.end() ? nullptr : &Rows[itr->second];
}

namespace
{
std::unordered_map<std::uint32_t, std::uint32_t> TaughtSpells()
{
    constexpr std::uint32_t SPELL_DESCRIPTION = 170;
    std::unordered_map<std::uint32_t, std::uint32_t> taught;
    ClientDBC spells;
    if (!spells.Load(GetClientDBCPath("Spell.dbc"), SPELL_DESCRIPTION + 1))
        return taught;
    for (std::uint32_t index = 0; index < spells.GetRecordCount(); ++index)
    {
        ClientDBC::Record const record = spells.GetRecord(index);
        std::string_view const description = record.GetString(SPELL_DESCRIPTION);
        std::size_t const teaches = description.starts_with("Teaches you") ? 0 : description.find("\nTeaches you");
        if (teaches == std::string_view::npos)
            continue;
        std::size_t const token = description.find("@s:", teaches);
        if (token == std::string_view::npos)
            continue;
        std::uint32_t spell = 0;
        for (std::size_t at = token + 3; at < description.size() && description[at] >= '0' && description[at] <= '9'; ++at)
            spell = spell * 10 + std::uint32_t(description[at] - '0');
        if (spell)
            taught[record.GetUInt32(0)] = spell;
    }
    return taught;
}
}

bool LoadCatalog(Catalog& catalog)
{
    ClientDBC file;
    if (!file.Load(GetClientDBCPath("MysticEnchant.dbc"), FIELD_COUNT))
        return false;
    std::unordered_map<std::uint32_t, std::uint32_t> const taught = TaughtSpells();

    Catalog loaded;
    for (std::uint32_t index = 0; index < file.GetRecordCount(); ++index)
    {
        loaded.Rows.push_back(ReadEnchant(file.GetRecord(index)));
        if (auto const itr = taught.find(loaded.Rows.back().Spell); itr != taught.end())
            loaded.Rows.back().Taught = itr->second;
        loaded.BySpell[loaded.Rows.back().Spell] = loaded.Rows.size() - 1;
        loaded.ByItem[loaded.Rows.back().Item] = loaded.Rows.size() - 1;
    }
    LOG_INFO("coa", "Loaded {} mystic enchants", loaded.Rows.size());
    catalog = std::move(loaded);
    return !catalog.Rows.empty();
}

std::int32_t ClientConfig::Int(std::string const& name, std::int32_t fallback) const
{
    auto const itr = Integers.find(name);
    return itr == Integers.end() ? fallback : itr->second;
}

bool ClientConfig::Bool(std::string const& name, bool fallback) const
{
    auto const itr = Booleans.find(name);
    return itr == Booleans.end() ? fallback : itr->second;
}

bool Character::Fusion() const
{
    return Config && Config->Bool("CONFIG_CLASS_FUSION_ENABLED", false) && Class == HERO_CLASS &&
        (GameModes & FUSION_EXCLUDED_MODES) == 0;
}

bool IsStockClass(std::uint32_t classId)
{
    return (classId >= 1 && classId <= 9) || classId == 11;
}

bool IsConquestOfAzerothClass(std::uint32_t classId)
{
    return classId >= 12 && classId <= 32;
}

std::uint32_t QualityOf(Enchant const& enchant, std::uint32_t classId)
{
    return IsStockClass(classId) ? enchant.RebornQuality : enchant.Quality;
}

bool ClassAllowed(Enchant const& enchant, std::uint32_t classId)
{
    std::uint32_t const bit = classId - 1;
    return bit < 64 && ((enchant.ClassMask >> bit) & 1) != 0;
}

bool RealmAllows(Enchant const& enchant, std::array<bool, REALM_COUNT> const& gates)
{
    for (std::size_t index = 0; index < REALM_COUNT; ++index)
        if (enchant.Realms[index] && gates[index])
            return true;
    return false;
}

bool SlotValid(std::uint32_t slot, bool fusion)
{
    return slot < SLOT_COUNT && (!fusion || slot - 1 < 15);
}

std::uint32_t SlotAt(Slots const& slots, std::uint32_t slot, bool fusion)
{
    return SlotValid(slot, fusion) ? slots[slot] : 0;
}

std::uint32_t QualityCap(Character const& character, std::uint32_t quality)
{
    if (character.Fusion())
    {
        switch (quality)
        {
            case QUALITY_UNCOMMON:
                return UnlockedAny(character, Configured(character, "CONFIG_MAX_UNCOMMON_RANDOM_ENCHANTS", 6), 6,
                    "CONFIG_UNCOMMON_RANDOM_ENCHANT_UNLOCK_LEVEL_");
            case QUALITY_RARE:
                return UnlockedAny(character, Configured(character, "CONFIG_MAX_RARE_RANDOM_ENCHANTS", 5), 5,
                    "CONFIG_RARE_RANDOM_ENCHANT_UNLOCK_LEVEL_");
            case QUALITY_EPIC:
                return UnlockedAny(character, Configured(character, "CONFIG_MAX_EPIC_RANDOM_ENCHANTS", 4), 4,
                    "CONFIG_EPIC_RANDOM_ENCHANT_UNLOCK_LEVEL_");
            default:
                return 0;
        }
    }

    bool const reborn = IsStockClass(character.Class);
    std::string const unlockSuffix = reborn ? "_RANDOM_ENCHANT_REBORN_UNLOCK_LEVEL_" : "_RANDOM_ENCHANT_UNLOCK_LEVEL_";
    std::string const maximumSuffix = reborn ? "_RANDOM_ENCHANTS_REBORN" : "_RANDOM_ENCHANTS";
    std::int32_t maximum = 0;
    std::string tier;
    switch (quality)
    {
        case QUALITY_UNCOMMON:
            return SLOT_COUNT;
        case QUALITY_RARE:
            tier = "RARE";
            maximum = Configured(character, "CONFIG_MAX_RARE" + maximumSuffix, SLOT_COUNT);
            break;
        case QUALITY_EPIC:
            tier = "EPIC";
            maximum = Configured(character, "CONFIG_MAX_EPIC" + maximumSuffix, reborn ? 5 : 3);
            break;
        case QUALITY_LEGENDARY:
            tier = "LEGENDARY";
            maximum = Configured(character, "CONFIG_MAX_LEGENDARY" + maximumSuffix, 1);
            break;
        case QUALITY_ARTIFACT:
            tier = "ARTIFACT";
            maximum = Configured(character, "CONFIG_MAX_ARTIFACT" + maximumSuffix, 1);
            break;
        default:
            return 0;
    }
    return maximum ? UnlockedInOrder(character, std::uint32_t(maximum), "CONFIG_" + tier + unlockSuffix) : 0;
}

bool InvestmentMet(Character const& character, Enchant const& enchant, bool talent)
{
    std::array<std::uint32_t, REQUIREMENT_COUNT> const& required = talent ? enchant.RequiredTE : enchant.RequiredAE;
    if (std::all_of(required.begin(), required.end(), [](std::uint32_t need) { return need == 0; }))
        return true;
    for (std::size_t index = 0; index < REQUIREMENT_COUNT; ++index)
    {
        if (!required[index])
            continue;
        std::uint32_t const invested = character.Invested ?
            character.Invested(enchant.ClassTypes[index], enchant.Tabs[index], talent) : 0;
        if (required[index] <= invested)
            return true;
    }
    return false;
}

std::vector<std::uint32_t> CheckApplySlot(Catalog const& catalog, Character const& character, Slots const& slots,
    std::vector<StagedApply> const& staged, StagedApply const& entry)
{
    std::vector<std::uint32_t> errors;
    if (!SlotValid(entry.Slot, character.Fusion()))
        errors.push_back(APPLY_BAD_SLOT);
    if (!entry.ItemFound)
        errors.push_back(APPLY_BAD_ITEM);
    else if (Enchant const* scroll = catalog.FindItem(entry.ItemEntry))
        CheckEnchant(catalog, character, slots, staged, entry.Slot, scroll->Spell, errors);
    else
        errors.push_back(APPLY_NOT_MYSTIC_SCROLL);
    if (character.Draft)
        errors.push_back(APPLY_BUILD_DRAFT);
    if (character.Casting)
        errors.push_back(APPLY_NOT_WHILE_CASTING);
    if (character.Wildcard())
        errors.push_back(APPLY_DISABLED_IN_WILDCARD);
    for (StagedApply const& other : staged)
        if (other.ItemKey == entry.ItemKey && other.Slot != entry.Slot)
        {
            errors.push_back(APPLY_DUPLICATE_BAG_SLOT_PAIR);
            break;
        }
    return errors;
}

std::uint32_t CheckSaveApply(Catalog const& catalog, Character const& character, Slots const& slots,
    std::vector<StagedApply> const& staged)
{
    if (staged.empty())
        return APPLY_UNKNOWN;
    std::vector<std::uint32_t> all;
    std::vector<std::uint32_t> seen;
    bool const fusion = character.Fusion();
    for (StagedApply const& entry : staged)
    {
        if (fusion)
        {
            if (std::find(seen.begin(), seen.end(), entry.Slot) != seen.end())
                AddOnce(all, APPLY_DUPLICATE_SLOT);
            seen.push_back(entry.Slot);
        }
        for (std::uint32_t error : CheckApplySlot(catalog, character, slots, staged, entry))
            AddOnce(all, error);
    }
    return all.empty() ? APPLY_OK : all.front();
}

std::uint32_t CheckDestroy(Character const& character, Slots const& slots, std::uint32_t slot)
{
    bool const valid = SlotValid(slot, character.Fusion());
    if (!valid)
        return DESTROY_BAD_SLOT;
    if (!slots[slot])
        return DESTROY_NO_ENCHANT_APPLIED;
    if (character.Casting)
        return DESTROY_NOT_WHILE_CASTING;
    if (IsConquestOfAzerothClass(character.Class))
        return DESTROY_BAD_CLASS;
    if (character.Draft)
        return DESTROY_BUILD_DRAFT;
    return DESTROY_OK;
}

std::uint32_t CheckPurchaseScroll(Character const& character, bool scrollKnown, std::uint32_t price)
{
    if (!scrollKnown)
        return PURCHASE_ITEM_NOT_FOUND;
    if (character.Money < price)
        return PURCHASE_NOT_ENOUGH_MONEY;
    if (!character.BagSpace)
        return PURCHASE_NOT_ENOUGH_SPACE;
    if (!character.AltarNearby)
        return PURCHASE_NO_MYSTIC_ALTAR;
    if (character.Casting)
        return PURCHASE_NOT_WHILE_CASTING;
    if (IsConquestOfAzerothClass(character.Class))
        return PURCHASE_BAD_CLASS;
    return PURCHASE_OK;
}

std::uint32_t CheckInspect(bool found, bool sameMap, std::uint32_t targetClass)
{
    if (!found)
        return INSPECT_PLAYER_NOT_FOUND;
    if (!sameMap)
        return INSPECT_PLAYER_NOT_IN_MAP;
    if (IsConquestOfAzerothClass(targetClass))
        return INSPECT_BAD_CLASS;
    return INSPECT_OK;
}

std::uint32_t CheckPresetSave(Character const& character)
{
    if (character.Draft)
        return PRESET_SAVE_BUILD_DRAFT;
    if (IsConquestOfAzerothClass(character.Class))
        return PRESET_SAVE_BAD_CLASS;
    return PRESET_SAVE_OK;
}

std::uint32_t CheckPresetActivate(Character const& character, std::uint32_t preset, std::uint32_t presetCount)
{
    if (character.Draft)
        return PRESET_SET_ACTIVE_BUILD_DRAFT;
    if (character.Casting)
        return PRESET_SET_ACTIVE_NOT_WHILE_CASTING;
    if (IsConquestOfAzerothClass(character.Class))
        return PRESET_SET_ACTIVE_BAD_CLASS;
    if (preset >= presetCount)
        return PRESET_SET_ACTIVE_UNKNOWN;
    return PRESET_SET_ACTIVE_OK;
}

std::uint32_t CheckPresetUnlock(Character const& character, std::uint32_t presetCount)
{
    if (presetCount >= MAX_PRESETS)
        return PRESET_UNLOCK_MAX_VALUE_REACHED;
    if (!character.UnlockTokens)
        return PRESET_UNLOCK_NO_MONEY;
    if (character.Draft)
        return PRESET_UNLOCK_BUILD_DRAFT;
    if (character.Casting)
        return PRESET_UNLOCK_NOT_WHILE_CASTING;
    if (IsConquestOfAzerothClass(character.Class))
        return PRESET_UNLOCK_BAD_CLASS;
    return PRESET_UNLOCK_OK;
}

namespace
{
std::uint32_t SaturatingAdd(std::uint32_t left, std::uint32_t right)
{
    return right > ~left ? NO_TOKEN_PRICE : left + right;
}

bool Priced(std::uint32_t cost)
{
    return cost != 0 && cost != NO_TOKEN_PRICE;
}

std::uint32_t CollectionReforgeLimit(std::uint32_t quality)
{
    switch (quality)
    {
        case QUALITY_UNCOMMON: return COLLECTION_REFORGE_UNCOMMON_LIMIT;
        case QUALITY_RARE: return COLLECTION_REFORGE_RARE_LIMIT;
        case QUALITY_EPIC: return COLLECTION_REFORGE_EPIC_LIMIT;
        case QUALITY_LEGENDARY: return COLLECTION_REFORGE_LEGENDARY_LIMIT;
        case QUALITY_ARTIFACT: return COLLECTION_REFORGE_ARTIFACT_LIMIT;
        default: return COLLECTION_REFORGE_UNHANDLED_LIMIT;
    }
}

void CheckReforgeTarget(Catalog const& catalog, Character const& character, std::uint32_t current, std::uint32_t spell,
    std::vector<std::uint32_t>& errors)
{
    if (current == spell)
        errors.push_back(COLLECTION_REFORGE_ALREADY_APPLIED);
    if (Enchant const* target = catalog.FindSpell(spell))
    {
        if (!character.Knows(target->Spell))
            errors.push_back(COLLECTION_REFORGE_NOT_KNOWN_ENCHANTMENT);
        if (!RealmAllows(*target, character.RealmGates))
            errors.push_back(COLLECTION_REFORGE_BAD_REALM);
        else if (character.Wildcard())
            errors.push_back(COLLECTION_REFORGE_DISABLED_IN_WILDCARD);
    }
    else
        errors.push_back(COLLECTION_REFORGE_BAD_ENCHANTMENT);
    if (!character.AltarNearby)
        errors.push_back(COLLECTION_REFORGE_NO_MYSTIC_ALTAR);
    if (character.Casting)
        errors.push_back(COLLECTION_REFORGE_NOT_WHILE_CASTING);
}

std::vector<std::uint32_t> CheckCollectionReforgeSlot(Catalog const& catalog, Character const& character,
    Slots const& slots, std::vector<StagedReforge> const& staged, StagedReforge const& entry)
{
    std::vector<std::uint32_t> errors;
    bool const fusion = character.Fusion();
    if (!SlotValid(entry.Slot, fusion))
        errors.push_back(COLLECTION_REFORGE_BAD_SLOT);
    if (character.Draft)
        errors.push_back(COLLECTION_REFORGE_BUILD_DRAFT);
    CheckReforgeTarget(catalog, character, SlotAt(slots, entry.Slot, fusion), entry.Spell, errors);
    Enchant const* target = catalog.FindSpell(entry.Spell);
    if (!target)
        return errors;

    std::vector<Enchant const*> targets;
    for (StagedReforge const& other : staged)
        if (Enchant const* enchant = catalog.FindSpell(other.Spell))
            targets.push_back(enchant);
    if (!CollectionReforgeCharge(character, targets, true).Affordable)
        errors.push_back(COLLECTION_REFORGE_NO_MONEY);
    if (!ClassAllowed(*target, character.Class))
        errors.push_back(COLLECTION_REFORGE_BAD_CLASS);
    if (!character.Knows(target->Spell))
        errors.push_back(COLLECTION_REFORGE_NOT_KNOWN_ENCHANTMENT);

    std::unordered_map<std::uint32_t, std::uint32_t> projected;
    for (std::uint32_t index = 0; index < SLOT_COUNT; ++index)
        projected[index] = SlotAt(slots, index, fusion);
    for (StagedReforge const& other : staged)
        projected[other.Slot] = other.Spell;
    projected[entry.Slot] = entry.Spell;

    std::uint32_t const quality = QualityOf(*target, character.Class);
    std::uint32_t sameSpell = 0;
    std::uint32_t sameQuality = 0;
    std::uint32_t rareWorldforged = 0;
    for (auto const& [index, held] : projected)
    {
        sameSpell += held == target->Spell;
        if (Enchant const* other = catalog.FindSpell(held))
        {
            sameQuality += QualityOf(*other, character.Class) == quality;
            rareWorldforged += QualityOf(*other, character.Class) == QUALITY_RARE && other->Worldforged;
        }
    }
    std::uint32_t const stackLimit = character.StackLimit ? character.StackLimit(target->Spell) : 0;
    if (stackLimit < sameSpell)
        errors.push_back(COLLECTION_REFORGE_STACK_LIMIT);
    if (QualityCap(character, quality) < sameQuality)
        errors.push_back(CollectionReforgeLimit(quality));
    if (quality == QUALITY_RARE && target->Worldforged && rareWorldforged > RARE_WORLDFORGED_LIMIT)
        errors.push_back(COLLECTION_REFORGE_RARE_WORLDFORGED_LIMIT);
    if (!InvestmentMet(character, *target, false))
        errors.push_back(COLLECTION_REFORGE_REQUIRED_AE_INVESTMENT);
    if (!InvestmentMet(character, *target, true))
        errors.push_back(COLLECTION_REFORGE_REQUIRED_TE_INVESTMENT);
    if (character.Level < target->RequiredLevel)
        errors.push_back(COLLECTION_REFORGE_TOO_LOW_LEVEL);
    return errors;
}

std::string QualityTier(std::uint32_t quality)
{
    static std::array<char const*, QUALITY_MAX> const TIERS = { "", "", "UNCOMMON", "RARE", "EPIC", "LEGENDARY",
        "ARTIFACT", "" };
    return TIERS[quality];
}

bool GuideFits(Catalog const& catalog, Character const& character, Slots const& slots, std::uint32_t spell)
{
    Enchant const* enchant = catalog.FindSpell(spell);
    if (!enchant || !character.Knows(spell) || !RealmAllows(*enchant, character.RealmGates) || character.Wildcard() ||
        !ClassAllowed(*enchant, character.Class) || character.Level < enchant->RequiredLevel ||
        !InvestmentMet(character, *enchant, false) || !InvestmentMet(character, *enchant, true))
        return false;
    std::uint32_t const quality = QualityOf(*enchant, character.Class);
    std::uint32_t sameSpell = 1;
    std::uint32_t sameQuality = 1;
    std::uint32_t rareWorldforged = quality == QUALITY_RARE && enchant->Worldforged;
    for (std::uint32_t held : slots)
    {
        sameSpell += held == spell;
        if (Enchant const* other = held ? catalog.FindSpell(held) : nullptr)
        {
            sameQuality += QualityOf(*other, character.Class) == quality;
            rareWorldforged += QualityOf(*other, character.Class) == QUALITY_RARE && other->Worldforged;
        }
    }
    std::uint32_t const stackLimit = character.StackLimit ? character.StackLimit(spell) : 0;
    return sameSpell <= stackLimit && sameQuality <= QualityCap(character, quality) &&
        !(quality == QUALITY_RARE && enchant->Worldforged && rareWorldforged > RARE_WORLDFORGED_LIMIT);
}
}

Slots GuideSlots(Catalog const& catalog, Character const& character, Slots const& current,
    std::vector<GuideEnchant> const& guide)
{
    bool const fusion = character.Fusion();
    std::vector<std::uint32_t> open;
    for (std::uint32_t slot = 0; slot < SLOT_COUNT; ++slot)
        if (SlotValid(slot, fusion))
            open.push_back(slot);
    Slots slots{};
    std::size_t next = 0;
    auto place = [&](std::uint32_t spell)
    {
        if (next >= open.size() || !GuideFits(catalog, character, slots, spell))
            return false;
        slots[open[next++]] = spell;
        return true;
    };
    for (GuideEnchant const& enchant : guide)
        if (enchant.Level <= character.Level)
            for (std::uint32_t stack = 0; stack < enchant.Stacks && place(enchant.Spell); ++stack)
                ;
    for (std::uint32_t slot : open)
        if (current[slot])
            place(current[slot]);
    return slots;
}

std::vector<std::uint32_t> GuideLessons(Catalog const& catalog, Character const& character,
    std::vector<GuideEnchant> const& guide)
{
    std::vector<std::uint32_t> lessons;
    if (character.Wildcard())
        return lessons;
    for (GuideEnchant const& entry : guide)
    {
        Enchant const* enchant = catalog.FindSpell(entry.Spell);
        if (enchant && entry.Level <= character.Level && !character.Knows(entry.Spell) &&
            RealmAllows(*enchant, character.RealmGates) && ClassAllowed(*enchant, character.Class) &&
            std::find(lessons.begin(), lessons.end(), entry.Spell) == lessons.end())
            lessons.push_back(entry.Spell);
    }
    return lessons;
}

bool Character::Knows(std::uint32_t spell) const
{
    return Known && std::find(Known->begin(), Known->end(), spell) != Known->end();
}

bool ValidSpecializationLink(std::uint32_t specialization, bool linked, std::uint32_t preset,
    std::uint32_t presetCount)
{
    return specialization < SPECIALIZATION_COUNT && (!linked || (preset >= 1 && preset <= presetCount));
}

std::uint32_t CollectionReforgeCost(Character const& character, Enchant const& enchant, bool money, bool slot)
{
    static std::array<std::int32_t, QUALITY_MAX> const MONEY = { 0, 0, 300000, 600000, 1000000, 2500000, 2500000, 0 };
    static std::array<std::int32_t, QUALITY_MAX> const TOKENS = { 0, 0, 1200, 2400, 4000, 10000, 10000, 0 };
    std::uint32_t const quality = QualityOf(enchant, character.Class);
    if (quality < QUALITY_UNCOMMON || quality > QUALITY_ARTIFACT)
        return quality;
    std::string const tier = QualityTier(quality);
    if (!slot)
        return money ? std::uint32_t(Configured(character,
            "CONFIG_MYSTIC_ENCHANT_COLLECTION_REFORGE_ITEM_" + tier + "_MONEY_COST", MONEY[quality])) : NO_TOKEN_PRICE;
    if (money)
        return std::uint32_t(Configured(character, "CONFIG_MYSTIC_ENCHANT_COLLECTION_REFORGE_" + tier + "_MONEY_COST",
            MONEY[quality]));
    return std::uint32_t(Configured(character, "CONFIG_MYSTIC_ENCHANT_COLLECTION_REFORGE_" + tier + "_TOKEN_COST",
        TOKENS[quality]));
}

std::uint32_t ExtractCost(Character const& character, Enchant const& enchant)
{
    static std::array<std::int32_t, QUALITY_MAX> const TOKENS = { 0, 0, 2500, 5000, 10000, 20000, 20000, 0 };
    std::uint32_t const quality = QualityOf(enchant, character.Class);
    if (quality < QUALITY_UNCOMMON || quality > QUALITY_ARTIFACT)
        return quality;
    return std::uint32_t(Configured(character, "CONFIG_MYSTIC_ENCHANT_EXTRACT_" + QualityTier(quality) + "_TOKEN_COST",
        TOKENS[quality]));
}

std::uint32_t ReforgeCost(Character const& character, bool money)
{
    if (money)
        return std::uint32_t(Configured(character, "CONFIG_MYSTIC_ENCHANT_REFORGE_MONEY_COST", 25000));
    return std::uint32_t(Configured(character, "CONFIG_MYSTIC_ENCHANT_REFORGE_TOKEN_COST", 250));
}

std::uint32_t ExtractPurchaseCost(std::uint32_t altarLevel)
{
    return std::min<std::uint32_t>(altarLevel * 200 + 1000, 5000);
}

Charge CollectionReforgeCharge(Character const& character, std::vector<Enchant const*> const& targets, bool slot)
{
    Charge charge;
    for (Enchant const* target : targets)
    {
        std::uint32_t const runes = CollectionReforgeCost(character, *target, false, slot);
        std::uint32_t const money = CollectionReforgeCost(character, *target, true, slot);
        if (Priced(runes) && SaturatingAdd(charge.Runes, runes) <= character.Runes)
        {
            charge.Runes = SaturatingAdd(charge.Runes, runes);
            continue;
        }
        if (!Priced(money) || character.Money < SaturatingAdd(money, charge.Money))
        {
            charge.Affordable = false;
            return charge;
        }
        charge.Money = SaturatingAdd(money, charge.Money);
    }
    return charge;
}

Charge ReforgeCharge(Character const& character)
{
    std::uint32_t const runes = ReforgeCost(character, false);
    if (runes && runes <= character.Runes)
        return { true, 0, runes };
    std::uint32_t const money = ReforgeCost(character, true);
    if (money && money <= character.Money)
        return { true, money, 0 };
    return { false, 0, 0 };
}

std::uint32_t CheckReforgeItem(Catalog const& catalog, Character const& character, ScrollItem const& scroll)
{
    if (!scroll.Found)
        return REFORGE_BAD_ITEM;
    if (scroll.Entry != UNTARNISHED_MYSTIC_SCROLL)
    {
        Enchant const* enchant = catalog.FindItem(scroll.Entry);
        if (!enchant)
            return REFORGE_NOT_MYSTIC_SCROLL;
        if (enchant->Worldforged)
            return REFORGE_WORLDFORGED_SCROLL;
    }
    if (!ReforgeCharge(character).Affordable)
        return REFORGE_NO_MONEY;
    if (!character.AltarNearby)
        return REFORGE_NO_MYSTIC_ALTAR;
    if (character.Casting)
        return REFORGE_NOT_WHILE_CASTING;
    if (IsConquestOfAzerothClass(character.Class))
        return REFORGE_BAD_CLASS;
    if (character.Wildcard())
        return REFORGE_DISABLED_IN_WILDCARD;
    return REFORGE_OK;
}

std::uint32_t CheckCollectionReforgeItem(Catalog const& catalog, Character const& character, ScrollItem const& scroll,
    std::uint32_t spell)
{
    std::vector<std::uint32_t> errors;
    std::uint32_t current = 0;
    if (!scroll.Found)
        errors.push_back(COLLECTION_REFORGE_BAD_ITEM);
    else if (scroll.Entry != UNTARNISHED_MYSTIC_SCROLL)
    {
        if (Enchant const* held = catalog.FindItem(scroll.Entry))
        {
            if (held->Worldforged)
                errors.push_back(COLLECTION_REFORGE_WORLDFORGED_SCROLL);
            current = held->Spell;
        }
        else
            errors.push_back(COLLECTION_REFORGE_NOT_MYSTIC_SCROLL);
    }
    CheckReforgeTarget(catalog, character, current, spell, errors);
    if (Enchant const* target = catalog.FindSpell(spell))
    {
        if (!CollectionReforgeCharge(character, { target }, false).Affordable)
            errors.push_back(COLLECTION_REFORGE_NO_MONEY);
        if (target->Worldforged)
            errors.push_back(COLLECTION_REFORGE_WORLDFORGED_ENCHANT);
    }
    return errors.empty() ? COLLECTION_REFORGE_OK : errors.front();
}

std::uint32_t CheckSaveCollectionReforge(Catalog const& catalog, Character const& character, Slots const& slots,
    std::vector<StagedReforge> const& staged)
{
    if (staged.empty())
        return COLLECTION_REFORGE_UNKNOWN;
    std::vector<std::uint32_t> all;
    for (StagedReforge const& entry : staged)
        for (std::uint32_t error : CheckCollectionReforgeSlot(catalog, character, slots, staged, entry))
            AddOnce(all, error);
    return all.empty() ? COLLECTION_REFORGE_OK : all.front();
}

std::uint32_t CheckDisenchant(Catalog const& catalog, Character const& character, std::uint32_t spell)
{
    Enchant const* enchant = spell ? catalog.FindSpell(spell) : nullptr;
    if (!enchant)
        return DISENCHANT_BAD_ENCHANTMENT;
    if (!RealmAllows(*enchant, character.RealmGates))
        return DISENCHANT_BAD_REALM;
    if (character.Wildcard())
        return DISENCHANT_DISABLED_IN_WILDCARD;
    if (character.Knows(spell))
        return DISENCHANT_ALREADY_KNOWN_ENCHANTMENT;
    if (!character.AltarNearby)
        return DISENCHANT_NO_MYSTIC_ALTAR;
    if (character.Casting)
        return DISENCHANT_NOT_WHILE_CASTING;
    std::uint32_t const cost = ExtractCost(character, *enchant);
    if (!Priced(cost) || character.Extracts < cost)
        return DISENCHANT_NO_MONEY;
    return DISENCHANT_OK;
}

std::uint32_t CheckDisenchantItem(Catalog const& catalog, Character const& character, ScrollItem const& scroll)
{
    if (!scroll.Found)
        return DISENCHANT_BAD_ITEM;
    Enchant const* enchant = catalog.FindItem(scroll.Entry);
    if (!enchant)
        return DISENCHANT_NOT_MYSTIC_SCROLL;
    return CheckDisenchant(catalog, character, enchant->Spell);
}

std::uint32_t CheckDisenchantSlot(Catalog const& catalog, Character const& character, Slots const& slots,
    std::uint32_t slot)
{
    if (!SlotValid(slot, character.Fusion()))
        return DISENCHANT_BAD_SLOT;
    if (character.Draft)
        return DISENCHANT_BUILD_DRAFT;
    return CheckDisenchant(catalog, character, slots[slot]);
}

std::uint32_t CheckExtractPurchase(Character const& character, std::uint32_t altarLevel)
{
    if (character.Extracts)
        return EXTRACT_PURCHASE_ALREADY_OBTAINED;
    if (character.Runes < ExtractPurchaseCost(altarLevel))
        return EXTRACT_PURCHASE_NO_TOKENS;
    return EXTRACT_PURCHASE_OK;
}

std::uint32_t ExtractsBoughtWithSave(Character const& character, std::uint32_t altarLevel, bool requested)
{
    return requested && CheckExtractPurchase(character, altarLevel) == EXTRACT_PURCHASE_OK ? 1 : 0;
}

std::vector<Enchant const*> ReforgePool(Catalog const& catalog, Character const& character,
    std::function<bool(std::uint32_t item)> const& itemExists)
{
    std::vector<Enchant const*> pool;
    for (Enchant const& enchant : catalog.Rows)
        if (enchant.Item && enchant.Weight > 0.0f && !enchant.Worldforged && ClassAllowed(enchant, character.Class) &&
            RealmAllows(enchant, character.RealmGates) && (!itemExists || itemExists(enchant.Item)))
            pool.push_back(&enchant);
    return pool;
}

Enchant const* Roll(std::vector<Enchant const*> const& pool, double unit)
{
    double total = 0.0;
    for (Enchant const* enchant : pool)
        total += enchant->Weight;
    double target = std::clamp(unit, 0.0, 1.0) * total;
    for (Enchant const* enchant : pool)
    {
        target -= enchant->Weight;
        if (target < 0.0)
            return enchant;
    }
    return pool.empty() ? nullptr : pool.back();
}

std::vector<Enchant const*> RevealPool(Catalog const& catalog, Character const& character,
    std::function<bool(std::uint32_t item)> const& itemExists)
{
    if (!IsStockClass(character.Class))
        return ReforgePool(catalog, character, itemExists);
    std::vector<Enchant const*> pool;
    for (Enchant const& enchant : catalog.Rows)
        if (enchant.Item && enchant.Weight > 0.0f && !enchant.Worldforged && (enchant.ClassMask & STOCK_CLASS_MASK) &&
            RealmAllows(enchant, character.RealmGates) && (!itemExists || itemExists(enchant.Item)))
            pool.push_back(&enchant);
    return pool;
}

Enchant const* RollReveal(Catalog const& catalog, Character const& character,
    std::function<bool(std::uint32_t item)> const& itemExists, std::function<bool(Enchant const&)> const& favored,
    double qualityUnit, double favoredUnit, double pickUnit)
{
    std::array<double, QUALITY_MAX> weights{};
    double total = 0.0;
    for (Enchant const* enchant : ReforgePool(catalog, character, itemExists))
    {
        std::uint32_t const quality = QualityOf(*enchant, character.Class);
        if (quality < QUALITY_MAX)
        {
            weights[quality] += enchant->Weight;
            total += enchant->Weight;
        }
    }
    if (total <= 0.0)
        return nullptr;

    std::uint32_t quality = QUALITY_MAX;
    double target = std::clamp(qualityUnit, 0.0, 1.0) * total;
    for (std::uint32_t index = 0; index < QUALITY_MAX && quality == QUALITY_MAX; ++index)
    {
        target -= weights[index];
        if (weights[index] > 0.0 && target < 0.0)
            quality = index;
    }
    if (quality == QUALITY_MAX)
        for (std::uint32_t index = QUALITY_MAX; index > 0 && quality == QUALITY_MAX; --index)
            if (weights[index - 1] > 0.0)
                quality = index - 1;

    std::vector<Enchant const*> chosen;
    std::vector<Enchant const*> others;
    for (Enchant const* enchant : RevealPool(catalog, character, itemExists))
        if (QualityOf(*enchant, character.Class) == quality)
            (favored && favored(*enchant) ? chosen : others).push_back(enchant);
    if (favoredUnit >= REVEAL_FAVORED_CHANCE)
        std::swap(chosen, others);
    return Roll(chosen.empty() ? others : chosen, pickUnit);
}

std::uint64_t LevelProgress(std::uint32_t level)
{
    if (level == 0)
        return 1;
    if (level > 249)
        return std::uint32_t(level * 0x1001 - 0x72038);
    double const value = double(level);
    return std::uint64_t(std::floor(value * 7.5 * value + double(std::int32_t(level * 354))));
}

std::uint64_t ReforgeProgressGain(Enchant const& enchant, double multiplier)
{
    std::uint64_t gain = 0;
    switch (enchant.Quality)
    {
        case QUALITY_UNCOMMON: gain = 60; break;
        case QUALITY_RARE: gain = 80; break;
        case QUALITY_EPIC: gain = 100; break;
        case QUALITY_LEGENDARY:
        case QUALITY_ARTIFACT: gain = 200; break;
        default: break;
    }
    return std::uint64_t(float(std::int64_t(gain)) * float(multiplier));
}

std::uint32_t AddProgress(Progress& progress, std::uint64_t gain)
{
    if (!gain)
        return 0;
    progress.Points += gain;
    std::uint32_t const before = progress.Level;
    while (LevelProgress(progress.Level) <= progress.Points)
        ++progress.Level;
    return progress.Level - before;
}
}
