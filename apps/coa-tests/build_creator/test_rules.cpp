#include "../../../src/server/coa/AscensionBuildCreatorRules.h"
#include <cassert>
#include <cstring>
#include <stdexcept>

namespace
{
using namespace AscensionBuildCreator;

struct Buffer
{
    std::vector<std::uint8_t> bytes;
    std::size_t read = 0;

    template <class T>
    Buffer& Put(T value)
    {
        std::uint8_t raw[sizeof(T)];
        std::memcpy(raw, &value, sizeof(T));
        bytes.insert(bytes.end(), raw, raw + sizeof(T));
        return *this;
    }

    Buffer& operator<<(std::uint8_t value) { return Put(value); }
    Buffer& operator<<(std::uint32_t value) { return Put(value); }
    Buffer& operator<<(std::uint64_t value) { return Put(value); }

    Buffer& operator<<(std::string const& value)
    {
        bytes.insert(bytes.end(), value.begin(), value.end());
        bytes.push_back(0);
        return *this;
    }

    template <class T>
    Buffer& Get(T& value)
    {
        if (read + sizeof(T) > bytes.size())
            throw std::out_of_range("read past the end");
        std::memcpy(&value, bytes.data() + read, sizeof(T));
        read += sizeof(T);
        return *this;
    }

    Buffer& operator>>(std::uint8_t& value) { return Get(value); }
    Buffer& operator>>(std::uint32_t& value) { return Get(value); }
    Buffer& operator>>(std::uint64_t& value) { return Get(value); }

    Buffer& operator>>(std::string& value)
    {
        value.clear();
        while (true)
        {
            if (read >= bytes.size())
                throw std::out_of_range("unterminated string");
            char const c = char(bytes[read++]);
            if (!c)
                return *this;
            value.push_back(c);
        }
    }

    std::uint32_t U32At(std::size_t offset) const
    {
        std::uint32_t value = 0;
        std::memcpy(&value, bytes.data() + offset, sizeof(value));
        return value;
    }
};

constexpr std::uint32_t HERO = 10;
constexpr std::uint32_t KNOWN = 48266;
constexpr std::uint32_t KNOWN_RANK_2 = 48267;
constexpr std::uint32_t KNOWN_ENCHANT = 118239;

bool Known(std::uint32_t spell)
{
    return spell == KNOWN || spell == KNOWN_RANK_2 || spell == KNOWN_ENCHANT;
}

Build Valid()
{
    Build build;
    build.Name = "Frost Witch";
    build.Icon = "spell_frost_frostbolt02";
    build.Description = "Freeze, then shatter.";
    build.Category = 2;
    build.Roles = 8;
    build.PrimaryStat = 3;
    build.Difficulty = 1;
    build.Spells = { { KNOWN, 4, 1, 0, 0, 0, 0, "" }, { KNOWN_RANK_2, 20, 0, 0, 0, 0, 0, "rank 2" } };
    build.Enchants = { { KNOWN_ENCHANT, 1, 1, 0, "" } };
    build.Weapons = { { 10, "" } };
    build.Armor = { { 1, "" } };
    return build;
}

Publisher Player(bool gm = false)
{
    Publisher publisher;
    publisher.Account = 7;
    publisher.Class = HERO;
    publisher.Gm = gm;
    publisher.MaxLevel = 60;
    return publisher;
}

std::uint32_t Check(Build const& build, bool gm = false)
{
    return ValidateContent(build, Player(gm), Known);
}

void WireLayout()
{
    Build build = Valid();
    build.Id = "fb4530c3-4899-46f1-9363-5e013c52dc53";
    build.Class = HERO;
    build.Author = "Idum";
    build.Upvotes = 16;
    build.Created = 1784819677;
    build.Updated = 1788024596;
    Buffer out;
    WriteBuild(out, build);

    std::size_t offset = 37 + 1 + 1 + 1;
    assert(out.U32At(offset) == HERO);
    offset += 4 + 5 + build.Name.size() + 1 + 1 + build.Description.size() + 1 + build.Icon.size() + 1;
    assert(out.U32At(offset) == 16);
    offset += 4 + 8 + 8;
    assert(out.U32At(offset) == 2 && out.U32At(offset + 4) == 8 && out.U32At(offset + 8) == 3);
    offset += 12;
    assert(out.U32At(offset) == 2 && out.U32At(offset + 4) == KNOWN && out.U32At(offset + 8) == 4);
    assert(out.bytes[offset + 12] == 1 && out.bytes[offset + 13] == 0);
    offset += 4 + (4 + 4 + 4 + 4 + 1) + (4 + 4 + 4 + 4 + 7);
    assert(out.U32At(offset) == 1 && out.U32At(offset + 4) == KNOWN_ENCHANT && out.U32At(offset + 8) == 1);
    offset += 4 + 4 + 4 + 4 + 4 + 1;
    assert(out.U32At(offset) == 1 && out.U32At(offset + 4) == 10);
    offset += 4 + 4 + 1;
    assert(out.U32At(offset) == 1 && out.U32At(offset + 4) == 1);
    offset += 4 + 4 + 1;
    assert(out.bytes[offset] == 0 && out.U32At(offset + 1) == 0 && out.U32At(offset + 5) == 1);
    assert(out.bytes.size() == offset + 9);

    std::optional<Build> const back = ReadBuild(out);
    assert(back && out.read == out.bytes.size());
    assert(back->Id == build.Id && back->Author == "Idum" && back->Class == HERO && back->Upvotes == 16);
    assert(back->Created == build.Created && back->Updated == build.Updated && back->Spells.size() == 2);
    assert(back->Spells[1].Comment == "rank 2" && back->Spells[0].Core == 1 && back->Enchants[0].Stacks == 1);
    assert(back->Weapons[0].Type == 10 && back->Armor[0].Type == 1 && back->Difficulty == 1);

    Buffer flood;
    for (int i = 0; i < 4; ++i)
        flood << std::string();
    flood << HERO;
    for (int i = 0; i < 5; ++i)
        flood << std::string();
    flood << std::uint32_t(0) << std::uint64_t(0) << std::uint64_t(0) << std::uint32_t(1) << std::uint32_t(8)
          << std::uint32_t(0) << std::uint32_t(MAX_SPELLS + 1);
    assert(!ReadBuild(flood));
}

void Content()
{
    assert(Check(Valid()) == PUBLISH_OK);

    auto with = [](auto change)
    {
        Build build = Valid();
        change(build);
        return Check(build);
    };
    assert(with([](Build& b) { b.Category = 0; }) == PUBLISH_BAD_CATEGORY);
    assert(with([](Build& b) { b.Category = 9; }) == PUBLISH_BAD_CATEGORY);
    assert(with([](Build& b) { b.Category = 12; }) == PUBLISH_BAD_CATEGORY);
    assert(with([](Build& b) { b.Category = 8; }) == PUBLISH_BAD_CATEGORY);
    Build draft = Valid();
    draft.Category = 10;
    assert(Check(draft, true) == PUBLISH_OK && Check(draft) == PUBLISH_BAD_CATEGORY);
    assert(with([](Build& b) { b.Category = 1; }) == PUBLISH_OK);
    assert(with([](Build& b) { b.Category = 7; }) == PUBLISH_OK);

    assert(with([](Build& b) { b.Spells.clear(); }) == PUBLISH_NO_SPELLS);
    assert(with([](Build& b) { b.Weapons.clear(); }) == PUBLISH_NO_WEAPON_TYPES);
    assert(with([](Build& b) { b.Armor.clear(); }) == PUBLISH_NO_ARMOR_TYPES);
    assert(with([](Build& b) { b.Name.clear(); }) == PUBLISH_NO_NAME);
    assert(with([](Build& b) { b.Name = "Build Name"; }) == PUBLISH_DEFAULT_NAME);
    assert(with([](Build& b) { b.Name.assign(MAX_TEXT + 1, 'a'); }) == PUBLISH_NAME_TOO_LONG);
    assert(with([](Build& b) { b.Name.assign(MAX_TEXT, 'a'); }) == PUBLISH_OK);
    assert(with([](Build& b) { b.Icon.clear(); }) == PUBLISH_NO_ICON);
    assert(with([](Build& b) { b.Icon = "inv_misc_questionmark"; }) == PUBLISH_DEFAULT_ICON);
    assert(with([](Build& b) { b.Icon.assign(MAX_TEXT + 1, 'a'); }) == PUBLISH_ICON_TOO_LONG);
    assert(with([](Build& b) { b.Description.clear(); }) == PUBLISH_NO_DESCRIPTION);
    assert(with([](Build& b) { b.Description = "There is no description yet."; }) == PUBLISH_DEFAULT_DESCRIPTION);
    assert(with([](Build& b) { b.Description.assign(MAX_DESCRIPTION + 1, 'a'); }) == PUBLISH_DESCRIPTION_TOO_LONG);
    assert(with([](Build& b) { b.Description.assign(MAX_DESCRIPTION, 'a'); }) == PUBLISH_OK);

    assert(with([](Build& b) { b.Subtext.assign(MAX_TEXT + 1, 'a'); }) == PUBLISH_UNKNOWN);
    assert(with([](Build& b) { b.PveId.assign(ID_LENGTH + 1, 'a'); }) == PUBLISH_UNKNOWN);
    assert(with([](Build& b) { b.Roles = 3; }) == PUBLISH_UNKNOWN);
    assert(with([](Build& b) { b.Roles = 15; }) == PUBLISH_OK);
    assert(with([](Build& b) { b.PrimaryStat = 5; }) == PUBLISH_UNKNOWN);
    assert(with([](Build& b) { b.Difficulty = 5; }) == PUBLISH_UNKNOWN);

    assert(with([](Build& b) { b.Spells[0].SpellId = 1; }) == PUBLISH_UNKNOWN);
    assert(with([](Build& b) { b.Spells[1].SpellId = KNOWN; }) == PUBLISH_UNKNOWN);
    assert(with([](Build& b) { b.Spells[0].Level = 0; }) == PUBLISH_LEVEL_INAPPROPRIATE_SPELL);
    assert(with([](Build& b) { b.Spells[0].Level = 61; }) == PUBLISH_LEVEL_INAPPROPRIATE_SPELL);
    assert(with([](Build& b) { b.Spells[0].Level = 60; }) == PUBLISH_OK);
    assert(with([](Build& b) { b.Spells[0].Comment.assign(MAX_TEXT + 1, 'a'); }) == PUBLISH_SPELL_COMMENT_TOO_LONG);
    assert(with([](Build& b) { b.Spells[0].Optimal = 1; }) == PUBLISH_MULTIPLE_ABILITY_TYPES);
    assert(with([](Build& b) { b.Enchants[0].EnchantId = 2; }) == PUBLISH_UNKNOWN);
    assert(with([](Build& b) { b.Enchants[0].Comment.assign(MAX_TEXT + 1, 'a'); }) ==
        PUBLISH_RANDOM_ENCHANT_COMMENT_TOO_LONG);
    assert(with([](Build& b) { b.Weapons[0].Type = WEAPON_TYPES; }) == PUBLISH_UNKNOWN);
    assert(with([](Build& b) { b.Weapons.push_back(b.Weapons[0]); }) == PUBLISH_UNKNOWN);
    assert(with([](Build& b) { b.Weapons[0].Comment.assign(MAX_TEXT + 1, 'a'); }) ==
        PUBLISH_WEAPON_TYPE_COMMENT_TOO_LONG);
    assert(with([](Build& b) { b.Armor[0].Type = ARMOR_TYPES; }) == PUBLISH_UNKNOWN);
    assert(with([](Build& b) { b.Armor[0].Comment.assign(MAX_TEXT + 1, 'a'); }) ==
        PUBLISH_ARMOR_TYPE_COMMENT_TOO_LONG);

    assert(std::string(PUBLISH_RESULTS[PUBLISH_MULTIPLE_ABILITY_TYPES]) == "PUBLISH_BUILD_MULTIPLE_ABILITY_TYPES");
    assert(std::string(PUBLISH_RESULTS[PUBLISH_CLASS_MISMATCH]) == "PUBLISH_BUILD_CLASS_MISMATCH");
    assert(std::string(PUBLISH_RESULTS[PUBLISH_BAD_CATEGORY]) == "PUBLISH_BUILD_BAD_CATEGORY");
}

void Ownership()
{
    Build stored = Valid();
    stored.Class = HERO;
    stored.OwnerAccount = 7;
    assert(ValidateEdit(nullptr, Player()) == PUBLISH_NOT_FOUND);
    assert(ValidateEdit(&stored, Player()) == PUBLISH_OK);
    Publisher stranger = Player();
    stranger.Account = 8;
    assert(ValidateEdit(&stored, stranger) == PUBLISH_NO_PERMISSION);
    stranger.Gm = true;
    assert(ValidateEdit(&stored, stranger) == PUBLISH_OK);
    Publisher warrior = Player();
    warrior.Class = 1;
    assert(ValidateEdit(&stored, warrior) == PUBLISH_CLASS_MISMATCH);

    assert(Delete(nullptr, 7, false) == DELETE_NOT_FOUND);
    assert(Delete(&stored, 7, false) == DELETE_OK);
    assert(Delete(&stored, 8, false) == DELETE_NO_PERMISSION);
    assert(Delete(&stored, 8, true) == DELETE_OK);
    stored.OwnerAccount = 0;
    assert(Delete(&stored, 7, false) == DELETE_NO_PERMISSION);

    assert(Rate(false, false, true) == RATE_NOT_FOUND);
    assert(Rate(true, false, true) == RATE_OK && Rate(true, true, true) == RATE_ALREADY_UPVOTED);
    assert(Rate(true, true, false) == RATE_OK && Rate(true, false, false) == RATE_NOT_UPVOTED);
    assert(std::string(RATE_RESULTS[RATE_ALREADY_UPVOTED]) == "RATE_BUILD_ALREADY_UPVOTED");
    assert(std::string(DELETE_RESULTS[DELETE_NO_PERMISSION]) == "DELETE_BUILD_NO_PERMISSION");

    Build kept;
    kept.Id = "kept";
    kept.Class = HERO;
    kept.OwnerAccount = 7;
    kept.Author = "Idum";
    kept.Upvotes = 5;
    kept.Created = 100;
    Build submitted = Valid();
    submitted.Id = "other";
    submitted.Class = 1;
    submitted.Author = "Someone";
    submitted.Upvotes = 999;
    submitted.Created = 1;
    submitted.NeedsRepairs = 1;
    submitted.Flags = FEATURED_FLAG;
    Publish(kept, submitted, Player(), 200);
    assert(kept.Id == "kept" && kept.Class == HERO && kept.OwnerAccount == 7 && kept.Author == "Idum");
    assert(kept.Upvotes == 5 && kept.Created == 100 && kept.Updated == 200 && kept.NeedsRepairs == 0);
    assert(kept.Flags == 0 && kept.Name == submitted.Name && kept.Spells.size() == 2 && kept.Category == 2);
    Publish(kept, submitted, Player(true), 300);
    assert(kept.Flags == FEATURED_FLAG && kept.Updated == 300);
}

void Categories()
{
    assert(CategoryIndex("None") == 0u && CategoryIndex("Leveling") == 1u && CategoryIndex("Level60PvE") == 2u);
    assert(CategoryIndex("BuildDraftEndGamePvP") == 11u && !CategoryIndex("History") && !CategoryIndex(""));
    Build build = Valid();
    assert(InCategory(build, 0) && InCategory(build, 2) && !InCategory(build, 1));
}

void Paging()
{
    std::vector<std::pair<std::size_t, std::size_t>> pages = Pages({}, 100);
    assert(pages.size() == 1 && pages[0].first == 0 && pages[0].second == 0);
    pages = Pages({ 40, 40, 40, 150, 10 }, 100);
    assert(pages.size() == 4);
    assert(pages[0] == std::make_pair(std::size_t(0), std::size_t(2)));
    assert(pages[1] == std::make_pair(std::size_t(2), std::size_t(3)));
    assert(pages[2] == std::make_pair(std::size_t(3), std::size_t(4)));
    assert(pages[3] == std::make_pair(std::size_t(4), std::size_t(5)));
    pages = Pages({ 150 }, 100);
    assert(pages.size() == 1 && pages[0].second == 1);
}

void Ids()
{
    std::string const id = FormatId({ 0x01234567, 0x89ABCDEF, 0xFEDCBA98, 0x76543210 });
    assert(id.size() == ID_LENGTH);
    assert(id == "01234567-89ab-4def-bedc-ba9876543210");
    assert(FormatId({ 0, 0, 0, 0 }) == "00000000-0000-4000-8000-000000000000");
}

void Activation()
{
    Build build = Valid();
    build.Id = "guide";
    build.Class = HERO;
    assert(Activate(nullptr, HERO, "") == ACTIVATE_NOT_FOUND);
    assert(Activate(&build, HERO, "") == ACTIVATE_OK);
    assert(Activate(&build, HERO, "other") == ACTIVATE_OK);
    assert(Activate(&build, HERO, "guide") == ACTIVATE_ALREADY_ACTIVE);
    assert(Activate(&build, 1, "") == ACTIVATE_CLASS_MISMATCH);
    build.NeedsRepairs = 1;
    assert(Activate(&build, HERO, "") == ACTIVATE_NEEDS_REPAIRS);
    build.NeedsRepairs = 0;
    for (std::uint32_t category : { CATEGORY_BUILD_DRAFT, CATEGORY_BUILD_DRAFT_END_GAME_PVE,
        CATEGORY_BUILD_DRAFT_END_GAME_PVP })
    {
        build.Category = category;
        assert(Activate(&build, HERO, "") == ACTIVATE_NOT_DRAFTED);
    }
    assert(std::string(ACTIVATE_RESULTS[ACTIVATE_OK]) == "ACTIVATE_BUILD_OK");
    assert(std::string(ACTIVATE_RESULTS[ACTIVATE_CLASS_MISMATCH]) == "ACTIVATE_BUILD_NOT_WARCRAFT_REBORN");
    assert(std::string(ACTIVATE_RESULTS[ACTIVATE_NOT_DRAFTED]) == "ACTIVATE_BUILD_DRAFTED_BUILD_NOT_FOUND");

    assert(Deactivate(true, "guide", "guide") == DEACTIVATE_OK);
    assert(Deactivate(false, "guide", "guide") == DEACTIVATE_OK);
    assert(Deactivate(true, "guide", "other") == DEACTIVATE_NOT_ACTIVE);
    assert(Deactivate(true, "guide", "") == DEACTIVATE_NOT_ACTIVE);
    assert(Deactivate(false, "guide", "") == DEACTIVATE_NOT_FOUND);
    assert(Deactivate(true, "", "") == DEACTIVATE_NOT_ACTIVE);
    assert(std::string(DEACTIVATE_RESULTS[DEACTIVATE_NOT_ACTIVE]) == "DEACTIVATE_BUILD_NOT_ACTIVE");

    Buffer out;
    WriteActiveBuild(out, ActiveBuild{ "guide", { 1, 0 } });
    assert(out.bytes == (std::vector<std::uint8_t>{ 'g', 'u', 'i', 'd', 'e', 0, 1, 0 }));
    Buffer empty;
    WriteActiveBuild(empty, ActiveBuild{});
    assert(empty.bytes == (std::vector<std::uint8_t>{ 0, 0, 0 }));
    assert(ActiveBuilds{}.size() == SPECIALIZATIONS);
}

void ActivationProgressFlags()
{
    Build build = Valid();
    assert(ActivationProgress(nullptr) == 0);
    build.Flags = 0;
    build.Category = CATEGORY_LEVELING;
    assert(ActivationProgress(&build) == 0);
    build.Flags = FEATURED_FLAG;
    assert(ActivationProgress(&build) == ACTIVATION_FEATURED);
    for (std::uint32_t category = CATEGORY_LEVELING + 1; category <= CATEGORY_LEVEL_70_PVPVE; ++category)
    {
        build.Category = category;
        assert(ActivationProgress(&build) == (ACTIVATION_FEATURED | ACTIVATION_END_GAME));
    }
    build.Flags = 0;
    assert(ActivationProgress(&build) == ACTIVATION_END_GAME);
    for (std::uint32_t category : { CATEGORY_NONE, CATEGORY_BUILD_DRAFT, CATEGORY_ARCHIVED,
        CATEGORY_BUILD_DRAFT_END_GAME_PVE, CATEGORY_BUILD_DRAFT_END_GAME_PVP })
    {
        build.Category = category;
        assert(ActivationProgress(&build) == 0);
    }
}
}

int main()
{
    WireLayout();
    Content();
    Ownership();
    Categories();
    Paging();
    Ids();
    Activation();
    ActivationProgressFlags();
}
