#ifndef COA_ASCENSION_BUILD_CREATOR_RULES_H
#define COA_ASCENSION_BUILD_CREATOR_RULES_H

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <optional>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

namespace AscensionBuildCreator
{
constexpr std::array<char const*, 13> CATEGORIES = { "None", "Leveling", "Level60PvE", "Level60PvP", "Level60PvPvE",
    "Level70PvE", "Level70PvP", "Level70PvPvE", "BuildDraft", "Archived", "BuildDraftEndGamePvE",
    "BuildDraftEndGamePvP", "Broken" };

constexpr std::array<char const*, 39> PUBLISH_RESULTS = { "PUBLISH_BUILD_OK", "PUBLISH_BUILD_UNKNOWN",
    "PUBLISH_BUILD_LOW_LEVEL", "PUBLISH_BUILD_NO_SPELLS", "PUBLISH_BUILD_NO_WEAPON_TYPES",
    "PUBLISH_BUILD_NO_ARMOR_TYPES", "PUBLISH_BUILD_NO_NAME", "PUBLISH_BUILD_DEFAULT_NAME",
    "PUBLISH_BUILD_NAME_TOO_LONG", "PUBLISH_BUILD_NO_ICON", "PUBLISH_BUILD_DEFAULT_ICON",
    "PUBLISH_BUILD_ICON_TOO_LONG", "PUBLISH_BUILD_NO_DESCRIPTION", "PUBLISH_BUILD_DEFAULT_DESCRIPTION",
    "PUBLISH_BUILD_DESCRIPTION_TOO_LONG", "PUBLISH_BUILD_LEVEL_INAPPROPRIATE_SPELL", "PUBLISH_BUILD_ALREADY_EXISTS",
    "PUBLISH_BUILD_UNCOMMON_QUALITY_RESTRICTIONS", "PUBLISH_BUILD_RARE_QUALITY_RESTRICTIONS",
    "PUBLISH_BUILD_EPIC_QUALITY_RESTRICTIONS", "PUBLISH_BUILD_LEGENDARY_QUALITY_RESTRICTIONS",
    "PUBLISH_BUILD_BAD_CATEGORY", "PUBLISH_BUILD_NOT_ENOUGH_AE_INVESTMENT", "PUBLISH_BUILD_NOT_ENOUGH_TE_INVESTMENT",
    "PUBLISH_BUILD_SPELL_COMMENT_TOO_LONG", "PUBLISH_BUILD_RANDOM_ENCHANT_COMMENT_TOO_LONG",
    "PUBLISH_BUILD_WEAPON_TYPE_COMMENT_TOO_LONG", "PUBLISH_BUILD_ARMOR_TYPE_COMMENT_TOO_LONG",
    "PUBLISH_BUILD_NAME_PROFANITY", "PUBLISH_BUILD_DESCRIPTION_PROFANITY", "PUBLISH_BUILD_SPELL_COMMENT_PROFANITY",
    "PUBLISH_BUILD_RANDOM_ENCHANT_COMMENT_PROFANITY", "PUBLISH_BUILD_WEAPON_TYPE_COMMENT_PROFANITY",
    "PUBLISH_BUILD_ARMOR_TYPE_COMMENT_PROFANITY", "PUBLISH_BUILD_MULTIPLE_ABILITY_TYPES",
    "PUBLISH_BUILD_NOT_TRAVERSIBLE", "PUBLISH_BUILD_NOT_FOUND", "PUBLISH_BUILD_NO_PERMISSION",
    "PUBLISH_BUILD_CLASS_MISMATCH" };

constexpr std::array<char const*, 5> RATE_RESULTS = { "RATE_BUILD_OK", "RATE_BUILD_UNKNOWN",
    "RATE_BUILD_ALREADY_UPVOTED", "RATE_BUILD_NOT_UPVOTED", "RATE_BUILD_NOT_FOUND" };

constexpr std::array<char const*, 4> DELETE_RESULTS = { "DELETE_BUILD_OK", "DELETE_BUILD_UNKNOWN",
    "DELETE_BUILD_NOT_FOUND", "DELETE_BUILD_NO_PERMISSION" };

constexpr std::array<char const*, 7> ACTIVATE_RESULTS = { "ACTIVATE_BUILD_OK", "ACTIVATE_BUILD_FAILED",
    "ACTIVATE_BUILD_NOT_FOUND", "ACTIVATE_BUILD_NEEDS_REPAIRS", "ACTIVATE_BUILD_ALREADY_ACTIVE",
    "ACTIVATE_BUILD_NOT_WARCRAFT_REBORN", "ACTIVATE_BUILD_DRAFTED_BUILD_NOT_FOUND" };

constexpr std::array<char const*, 4> DEACTIVATE_RESULTS = { "DEACTIVATE_BUILD_OK", "DEACTIVATE_BUILD_FAILED",
    "DEACTIVATE_BUILD_NOT_FOUND", "DEACTIVATE_BUILD_NOT_ACTIVE" };

enum Category : std::uint32_t
{
    CATEGORY_NONE = 0,
    CATEGORY_LEVELING = 1,
    CATEGORY_LEVEL_70_PVPVE = 7,
    CATEGORY_BUILD_DRAFT = 8,
    CATEGORY_ARCHIVED = 9,
    CATEGORY_BUILD_DRAFT_END_GAME_PVE = 10,
    CATEGORY_BUILD_DRAFT_END_GAME_PVP = 11
};

enum PublishResult : std::uint32_t
{
    PUBLISH_OK = 0,
    PUBLISH_UNKNOWN = 1,
    PUBLISH_NO_SPELLS = 3,
    PUBLISH_NO_WEAPON_TYPES = 4,
    PUBLISH_NO_ARMOR_TYPES = 5,
    PUBLISH_NO_NAME = 6,
    PUBLISH_DEFAULT_NAME = 7,
    PUBLISH_NAME_TOO_LONG = 8,
    PUBLISH_NO_ICON = 9,
    PUBLISH_DEFAULT_ICON = 10,
    PUBLISH_ICON_TOO_LONG = 11,
    PUBLISH_NO_DESCRIPTION = 12,
    PUBLISH_DEFAULT_DESCRIPTION = 13,
    PUBLISH_DESCRIPTION_TOO_LONG = 14,
    PUBLISH_LEVEL_INAPPROPRIATE_SPELL = 15,
    PUBLISH_BAD_CATEGORY = 21,
    PUBLISH_SPELL_COMMENT_TOO_LONG = 24,
    PUBLISH_RANDOM_ENCHANT_COMMENT_TOO_LONG = 25,
    PUBLISH_WEAPON_TYPE_COMMENT_TOO_LONG = 26,
    PUBLISH_ARMOR_TYPE_COMMENT_TOO_LONG = 27,
    PUBLISH_MULTIPLE_ABILITY_TYPES = 34,
    PUBLISH_NOT_FOUND = 36,
    PUBLISH_NO_PERMISSION = 37,
    PUBLISH_CLASS_MISMATCH = 38
};

enum RateResult : std::uint32_t
{
    RATE_OK = 0,
    RATE_ALREADY_UPVOTED = 2,
    RATE_NOT_UPVOTED = 3,
    RATE_NOT_FOUND = 4
};

enum DeleteResult : std::uint32_t
{
    DELETE_OK = 0,
    DELETE_NOT_FOUND = 2,
    DELETE_NO_PERMISSION = 3
};

enum ActivateResult : std::uint32_t
{
    ACTIVATE_OK = 0,
    ACTIVATE_FAILED = 1,
    ACTIVATE_NOT_FOUND = 2,
    ACTIVATE_NEEDS_REPAIRS = 3,
    ACTIVATE_ALREADY_ACTIVE = 4,
    ACTIVATE_CLASS_MISMATCH = 5,
    ACTIVATE_NOT_DRAFTED = 6
};

enum DeactivateResult : std::uint32_t
{
    DEACTIVATE_OK = 0,
    DEACTIVATE_FAILED = 1,
    DEACTIVATE_NOT_FOUND = 2,
    DEACTIVATE_NOT_ACTIVE = 3
};

constexpr std::size_t MAX_TEXT = 0x80;
constexpr std::size_t MAX_DESCRIPTION = 0x4000;
constexpr std::size_t ID_LENGTH = 36;
constexpr std::uint32_t MAX_SPELLS = 512;
constexpr std::uint32_t MAX_ENCHANTS = 64;
constexpr std::uint32_t WEAPON_TYPES = 21;
constexpr std::uint32_t ARMOR_TYPES = 11;
constexpr std::uint32_t PRIMARY_STATS = 5;
constexpr std::uint32_t DIFFICULTIES = 5;
constexpr std::array<std::uint32_t, 6> ROLE_VALUES = { 0, 1, 2, 4, 8, 15 };
constexpr std::uint32_t FEATURED_FLAG = 1;
constexpr std::size_t PAGE_BYTES = 0x6000;
constexpr std::size_t SPECIALIZATIONS = 20;
constexpr std::string_view DEFAULT_NAME = "Build Name";
constexpr std::string_view DEFAULT_ICON = "inv_misc_questionmark";
constexpr std::string_view DEFAULT_DESCRIPTION = "There is no description yet.";

struct Spell
{
    std::uint32_t SpellId = 0;
    std::uint32_t Level = 0;
    std::uint8_t Core = 0;
    std::uint8_t Optimal = 0;
    std::uint8_t Empowering = 0;
    std::uint8_t Synergistic = 0;
    std::uint32_t Flags = 0;
    std::string Comment;
};

struct Enchant
{
    std::uint32_t EnchantId = 0;
    std::uint32_t Stacks = 0;
    std::uint32_t Level = 0;
    std::uint32_t Flags = 0;
    std::string Comment;
};

struct ItemType
{
    std::uint32_t Type = 0;
    std::string Comment;
};

struct Build
{
    std::string Id;
    std::string LevelingId;
    std::string PveId;
    std::string PvpId;
    std::uint32_t Class = 0;
    std::string Author;
    std::string Name;
    std::string Subtext;
    std::string Description;
    std::string Icon;
    std::uint32_t Upvotes = 0;
    std::uint64_t Created = 0;
    std::uint64_t Updated = 0;
    std::uint32_t Category = 0;
    std::uint32_t Roles = 8;
    std::uint32_t PrimaryStat = 0;
    std::vector<Spell> Spells;
    std::vector<Enchant> Enchants;
    std::vector<ItemType> Weapons;
    std::vector<ItemType> Armor;
    std::uint8_t NeedsRepairs = 0;
    std::uint32_t Flags = 0;
    std::uint32_t Difficulty = 0;
    std::uint32_t OwnerAccount = 0;
};

struct Publisher
{
    std::uint32_t Account = 0;
    std::uint32_t Class = 0;
    bool Gm = false;
    std::uint32_t MaxLevel = 0;
};

template <class Out>
void WriteBuild(Out& out, Build const& build)
{
    out << build.Id << build.LevelingId << build.PveId << build.PvpId << build.Class << build.Author << build.Name
        << build.Subtext << build.Description << build.Icon << build.Upvotes << build.Created << build.Updated
        << build.Category << build.Roles << build.PrimaryStat;
    out << std::uint32_t(build.Spells.size());
    for (Spell const& spell : build.Spells)
        out << spell.SpellId << spell.Level << spell.Core << spell.Optimal << spell.Empowering << spell.Synergistic
            << spell.Flags << spell.Comment;
    out << std::uint32_t(build.Enchants.size());
    for (Enchant const& enchant : build.Enchants)
        out << enchant.EnchantId << enchant.Stacks << enchant.Level << enchant.Flags << enchant.Comment;
    for (std::vector<ItemType> const* types : { &build.Weapons, &build.Armor })
    {
        out << std::uint32_t(types->size());
        for (ItemType const& type : *types)
            out << type.Type << type.Comment;
    }
    out << build.NeedsRepairs << build.Flags << build.Difficulty;
}

template <class In>
std::optional<Build> ReadBuild(In& in)
{
    Build build;
    in >> build.Id >> build.LevelingId >> build.PveId >> build.PvpId >> build.Class >> build.Author >> build.Name
        >> build.Subtext >> build.Description >> build.Icon >> build.Upvotes >> build.Created >> build.Updated
        >> build.Category >> build.Roles >> build.PrimaryStat;
    std::uint32_t count = 0;
    in >> count;
    if (count > MAX_SPELLS)
        return std::nullopt;
    build.Spells.resize(count);
    for (Spell& spell : build.Spells)
        in >> spell.SpellId >> spell.Level >> spell.Core >> spell.Optimal >> spell.Empowering >> spell.Synergistic
            >> spell.Flags >> spell.Comment;
    in >> count;
    if (count > MAX_ENCHANTS)
        return std::nullopt;
    build.Enchants.resize(count);
    for (Enchant& enchant : build.Enchants)
        in >> enchant.EnchantId >> enchant.Stacks >> enchant.Level >> enchant.Flags >> enchant.Comment;
    for (auto [types, limit] : { std::pair{ &build.Weapons, WEAPON_TYPES }, std::pair{ &build.Armor, ARMOR_TYPES } })
    {
        in >> count;
        if (count > limit)
            return std::nullopt;
        types->resize(count);
        for (ItemType& type : *types)
            in >> type.Type >> type.Comment;
    }
    in >> build.NeedsRepairs >> build.Flags >> build.Difficulty;
    return build;
}

inline std::optional<std::uint32_t> CategoryIndex(std::string_view name)
{
    for (std::uint32_t index = 0; index < CATEGORIES.size(); ++index)
        if (name == CATEGORIES[index])
            return index;
    return std::nullopt;
}

inline bool InCategory(Build const& build, std::uint32_t category)
{
    return category == CATEGORY_NONE || build.Category == category;
}

inline bool PublishableCategory(std::uint32_t category, bool gm)
{
    if (category >= CATEGORY_LEVELING && category <= CATEGORY_LEVEL_70_PVPVE)
        return true;
    return gm && (category == CATEGORY_BUILD_DRAFT || category == CATEGORY_BUILD_DRAFT_END_GAME_PVE ||
        category == CATEGORY_BUILD_DRAFT_END_GAME_PVP);
}

constexpr std::uint32_t ACTIVATION_FEATURED = 1;
constexpr std::uint32_t ACTIVATION_END_GAME = 2;

inline std::uint32_t ActivationProgress(Build const* build)
{
    if (!build)
        return 0;
    std::uint32_t progress = 0;
    if (build->Flags & FEATURED_FLAG)
        progress |= ACTIVATION_FEATURED;
    if (build->Category > CATEGORY_LEVELING && build->Category <= CATEGORY_LEVEL_70_PVPVE)
        progress |= ACTIVATION_END_GAME;
    return progress;
}

template <class KnownSpell>
std::uint32_t ValidateContent(Build const& build, Publisher const& publisher, KnownSpell const& knownSpell)
{
    if (!PublishableCategory(build.Category, publisher.Gm))
        return PUBLISH_BAD_CATEGORY;
    if (build.Spells.empty())
        return PUBLISH_NO_SPELLS;
    if (build.Weapons.empty())
        return PUBLISH_NO_WEAPON_TYPES;
    if (build.Armor.empty())
        return PUBLISH_NO_ARMOR_TYPES;
    if (build.Name.empty())
        return PUBLISH_NO_NAME;
    if (build.Name == DEFAULT_NAME)
        return PUBLISH_DEFAULT_NAME;
    if (build.Name.size() > MAX_TEXT)
        return PUBLISH_NAME_TOO_LONG;
    if (build.Icon.empty())
        return PUBLISH_NO_ICON;
    if (build.Icon == DEFAULT_ICON)
        return PUBLISH_DEFAULT_ICON;
    if (build.Icon.size() > MAX_TEXT)
        return PUBLISH_ICON_TOO_LONG;
    if (build.Description.empty())
        return PUBLISH_NO_DESCRIPTION;
    if (build.Description == DEFAULT_DESCRIPTION)
        return PUBLISH_DEFAULT_DESCRIPTION;
    if (build.Description.size() > MAX_DESCRIPTION)
        return PUBLISH_DESCRIPTION_TOO_LONG;
    if (build.Subtext.size() > MAX_TEXT || build.LevelingId.size() > ID_LENGTH || build.PveId.size() > ID_LENGTH ||
        build.PvpId.size() > ID_LENGTH)
        return PUBLISH_UNKNOWN;
    if (std::find(ROLE_VALUES.begin(), ROLE_VALUES.end(), build.Roles) == ROLE_VALUES.end() ||
        build.PrimaryStat >= PRIMARY_STATS || build.Difficulty >= DIFFICULTIES)
        return PUBLISH_UNKNOWN;

    std::vector<std::uint32_t> spells;
    for (Spell const& spell : build.Spells)
    {
        if (!knownSpell(spell.SpellId))
            return PUBLISH_UNKNOWN;
        if (!spell.Level || spell.Level > publisher.MaxLevel)
            return PUBLISH_LEVEL_INAPPROPRIATE_SPELL;
        if (spell.Comment.size() > MAX_TEXT)
            return PUBLISH_SPELL_COMMENT_TOO_LONG;
        if ((spell.Core != 0) + (spell.Optimal != 0) + (spell.Empowering != 0) + (spell.Synergistic != 0) > 1)
            return PUBLISH_MULTIPLE_ABILITY_TYPES;
        spells.push_back(spell.SpellId);
    }
    std::sort(spells.begin(), spells.end());
    if (std::adjacent_find(spells.begin(), spells.end()) != spells.end())
        return PUBLISH_UNKNOWN;

    for (Enchant const& enchant : build.Enchants)
    {
        if (!knownSpell(enchant.EnchantId))
            return PUBLISH_UNKNOWN;
        if (enchant.Comment.size() > MAX_TEXT)
            return PUBLISH_RANDOM_ENCHANT_COMMENT_TOO_LONG;
    }

    for (auto [types, limit, tooLong] : { std::tuple{ &build.Weapons, WEAPON_TYPES,
        PUBLISH_WEAPON_TYPE_COMMENT_TOO_LONG }, std::tuple{ &build.Armor, ARMOR_TYPES,
        PUBLISH_ARMOR_TYPE_COMMENT_TOO_LONG } })
    {
        std::vector<std::uint32_t> seen;
        for (ItemType const& type : *types)
        {
            if (type.Type >= limit || std::find(seen.begin(), seen.end(), type.Type) != seen.end())
                return PUBLISH_UNKNOWN;
            if (type.Comment.size() > MAX_TEXT)
                return tooLong;
            seen.push_back(type.Type);
        }
    }
    return PUBLISH_OK;
}

inline std::uint32_t ValidateEdit(Build const* existing, Publisher const& publisher)
{
    if (!existing)
        return PUBLISH_NOT_FOUND;
    if (existing->OwnerAccount != publisher.Account && !publisher.Gm)
        return PUBLISH_NO_PERMISSION;
    if (existing->Class != publisher.Class)
        return PUBLISH_CLASS_MISMATCH;
    return PUBLISH_OK;
}

inline std::uint32_t Rate(bool exists, bool upvoted, bool up)
{
    if (!exists)
        return RATE_NOT_FOUND;
    if (up && upvoted)
        return RATE_ALREADY_UPVOTED;
    if (!up && !upvoted)
        return RATE_NOT_UPVOTED;
    return RATE_OK;
}

inline std::uint32_t Delete(Build const* existing, std::uint32_t account, bool gm)
{
    if (!existing)
        return DELETE_NOT_FOUND;
    if (existing->OwnerAccount != account && !gm)
        return DELETE_NO_PERMISSION;
    return DELETE_OK;
}

inline bool DraftCategory(std::uint32_t category)
{
    return category == CATEGORY_BUILD_DRAFT || category == CATEGORY_BUILD_DRAFT_END_GAME_PVE ||
        category == CATEGORY_BUILD_DRAFT_END_GAME_PVP;
}

struct ActiveBuild
{
    std::string Id;
    std::array<std::uint8_t, 2> Flags = {};
};

using ActiveBuilds = std::array<ActiveBuild, SPECIALIZATIONS>;

inline std::uint32_t Activate(Build const* build, std::uint32_t playerClass, std::string const& active)
{
    if (!build)
        return ACTIVATE_NOT_FOUND;
    if (build->NeedsRepairs)
        return ACTIVATE_NEEDS_REPAIRS;
    if (DraftCategory(build->Category))
        return ACTIVATE_NOT_DRAFTED;
    if (build->Class != playerClass)
        return ACTIVATE_CLASS_MISMATCH;
    if (active == build->Id)
        return ACTIVATE_ALREADY_ACTIVE;
    return ACTIVATE_OK;
}

inline std::uint32_t Deactivate(bool exists, std::string const& id, std::string const& active)
{
    if (!active.empty() && active == id)
        return DEACTIVATE_OK;
    return exists ? DEACTIVATE_NOT_ACTIVE : DEACTIVATE_NOT_FOUND;
}

template <class Buffer>
void WriteActiveBuild(Buffer& out, ActiveBuild const& active)
{
    out << active.Id << active.Flags[0] << active.Flags[1];
}

inline void Publish(Build& stored, Build const& submitted, Publisher const& publisher, std::uint64_t now)
{
    stored.LevelingId = submitted.LevelingId;
    stored.PveId = submitted.PveId;
    stored.PvpId = submitted.PvpId;
    stored.Name = submitted.Name;
    stored.Subtext = submitted.Subtext;
    stored.Description = submitted.Description;
    stored.Icon = submitted.Icon;
    stored.Category = submitted.Category;
    stored.Roles = submitted.Roles;
    stored.PrimaryStat = submitted.PrimaryStat;
    stored.Spells = submitted.Spells;
    stored.Enchants = submitted.Enchants;
    stored.Weapons = submitted.Weapons;
    stored.Armor = submitted.Armor;
    stored.Difficulty = submitted.Difficulty;
    if (publisher.Gm)
        stored.Flags = submitted.Flags;
    stored.Updated = now;
}

inline std::vector<std::pair<std::size_t, std::size_t>> Pages(std::vector<std::size_t> const& sizes,
    std::size_t budget)
{
    std::vector<std::pair<std::size_t, std::size_t>> pages;
    std::size_t first = 0;
    std::size_t bytes = 0;
    for (std::size_t index = 0; index < sizes.size(); ++index)
    {
        if (index > first && bytes + sizes[index] > budget)
        {
            pages.emplace_back(first, index);
            first = index;
            bytes = 0;
        }
        bytes += sizes[index];
    }
    pages.emplace_back(first, sizes.size());
    return pages;
}

inline std::string FormatId(std::array<std::uint32_t, 4> words)
{
    words[1] = (words[1] & 0xFFFF0FFF) | 0x00004000;
    words[2] = (words[2] & 0x3FFFFFFF) | 0x80000000;
    char text[ID_LENGTH + 1] = {};
    std::snprintf(text, sizeof(text), "%08x-%04x-%04x-%04x-%04x%08x", words[0], words[1] >> 16, words[1] & 0xFFFF,
        words[2] >> 16, words[2] & 0xFFFF, words[3]);
    return text;
}
}

#endif
