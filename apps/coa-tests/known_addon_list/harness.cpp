#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <string>
#include <string_view>
#include <unordered_set>
#include <vector>

using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;

constexpr uint16 SMSG_ASCENSION_SECURE_ADDONS = 0x094E;

struct WorldPacket
{
    WorldPacket(uint16 opcode, std::size_t) : opcode(opcode) { }

    WorldPacket& operator<<(uint8 value)
    {
        bytes.push_back(value);
        return *this;
    }

    WorldPacket& operator<<(uint32 value)
    {
        for (int i = 0; i < 4; ++i)
            bytes.push_back(uint8(value >> (i * 8)));
        return *this;
    }

    WorldPacket& operator<<(std::string const& value)
    {
        bytes.insert(bytes.end(), value.begin(), value.end());
        bytes.push_back(0);
        return *this;
    }

    WorldPacket& operator<<(char const* value) { return *this << std::string(value); }

    uint16 opcode;
    std::vector<uint8> bytes;
};

struct WorldSession
{
    std::vector<std::string> const& GetClientAddonNames() const { return clientAddons; }
    void SendPacket(WorldPacket const* packet) { sent.push_back(*packet); }

    std::vector<std::string> clientAddons;
    std::vector<WorldPacket> sent;
};

// ACTUAL_SEND

struct Entry
{
    std::string name;
    uint8 secure;
};

std::vector<Entry> Parse(WorldPacket const& packet)
{
    std::vector<uint8> const& b = packet.bytes;
    std::size_t at = 0;
    uint32 count = uint32(b.at(0)) | uint32(b.at(1)) << 8 | uint32(b.at(2)) << 16 | uint32(b.at(3)) << 24;
    at = 4;
    std::vector<Entry> entries;
    for (uint32 i = 0; i < count; ++i)
    {
        std::string name;
        while (b.at(at))
            name.push_back(char(b.at(at++)));
        ++at;
        entries.push_back({ name, b.at(at++) });
    }
    if (at != b.size())
    {
        std::cerr << "trailing bytes after the last entry\n";
        std::exit(1);
    }
    return entries;
}

void Expect(bool condition, char const* what)
{
    if (!condition)
    {
        std::cerr << "FAIL: " << what << "\n";
        std::exit(1);
    }
}

Entry const* Find(std::vector<Entry> const& entries, std::string const& name)
{
    auto it = std::find_if(entries.begin(), entries.end(), [&](Entry const& e) { return e.name == name; });
    return it == entries.end() ? nullptr : &*it;
}

int main()
{
    WorldSession session;
    session.clientAddons = { "Blizzard_TrainerUI", "Blizzard_RaidUI", "!BugGrabber", "Ascension_HelpUI" };
    SendSecureAddonList(&session);

    Expect(session.sent.size() == 1, "one packet sent");
    Expect(session.sent[0].opcode == SMSG_ASCENSION_SECURE_ADDONS, "sent as SMSG 0x94E");

    std::vector<Entry> const entries = Parse(session.sent[0]);

    for (std::string const& name : session.clientAddons)
        Expect(Find(entries, name) != nullptr, "every addon the client reported is echoed back");

    Expect(Find(entries, "Blizzard_TrainerUI")->secure == 1, "Blizzard addons are secure");
    Expect(Find(entries, "!BugGrabber")->secure == 0, "third-party addons are not secure");

    for (char const* name : { "AscensionUI", "Ascension_Collections", "Ascension_CompactRaidFrames",
                              "Ascension_EnchantCollection", "Ascension_HelpUI", "Ascension_InspectUI",
                              "Ascension_MythicPlus", "Ascension_SeasonCollection", "Ascension_TicketUI",
                              "Ascension_UIDevelopmentTools", "Ascension_WildCard" })
    {
        Entry const* entry = Find(entries, name);
        Expect(entry != nullptr, "Ascension's own addons are listed even when the client did not report them");
        Expect(entry->secure == 1, "Ascension addons that need protected calls are secure");
    }

    for (char const* name : { "AscensionResources", "Ascension_AddonPanel", "Ascension_AppearanceUI",
                              "Ascension_BuildCreator", "Ascension_ChallengesUI", "Ascension_CharacterAdvancement",
                              "Ascension_CharacterAdvancementSeason9", "Ascension_CoATalents",
                              "Ascension_Draft", "Ascension_ForcedPrimaryStat",
                              "Ascension_Manastorm", "Ascension_NamePlates", "Ascension_NewPlayerExperience",
                              "Ascension_PTRFeedback", "Ascension_PathToAscension", "Ascension_Poll",
                              "Ascension_RandomModeShared", "Ascension_SkillCards", "Ascension_TalentUI",
                              "Ascension_VanityCollection", "Ascension_Warmode", "Ascension_WarmodeLegacy" })
    {
        Entry const* entry = Find(entries, name);
        Expect(entry != nullptr, "Ascension's own addons are listed even when the client did not report them");
        Expect(entry->secure == 0, "Ascension addons that need no protected calls are known but not secure");
    }

    Expect(entries.size() == session.clientAddons.size() - 1 + 33, "every Ascension addon is listed exactly once");

    Expect(std::count_if(entries.begin(), entries.end(),
                         [](Entry const& e) { return e.name == "Ascension_HelpUI"; }) == 1,
           "an addon the client already reported is not listed twice");

    std::cout << "PASS: SMSG 0x94E echoes " << entries.size() << " addons, Blizzard and 11 Ascension addons secure\n";
    return 0;
}
