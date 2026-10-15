#include "RULES_HEADER"
#include <cstdlib>
#include <iostream>
#include <map>
#include <mutex>
#include <stdexcept>
#include <string>
#include <vector>

using uint8 = uint8_t;
using uint32 = uint32_t;
constexpr uint32 SMSG_NPC_TEXT_UPDATE = 0x180;
constexpr uint8 MAX_GOSSIP_TEXT_OPTIONS = 8;
constexpr uint8 MAX_GOSSIP_TEXT_EMOTES = 3;

class ObjectGuid
{
public:
    uint32 value = 0;
    void Clear() { value = 0; }
    bool IsEmpty() const { return !value; }
    bool operator==(ObjectGuid const&) const = default;
};

struct WorldPacket
{
    uint32 opcode;
    std::vector<uint8> bytes;
    WorldPacket(uint32 op, size_t) : opcode(op) { }
    template <typename T> WorldPacket& operator<<(T value)
    {
        auto* start = reinterpret_cast<uint8*>(&value);
        bytes.insert(bytes.end(), start, start + sizeof(T));
        return *this;
    }
    WorldPacket& operator<<(std::string const& value)
    {
        bytes.insert(bytes.end(), value.begin(), value.end());
        bytes.push_back(0);
        return *this;
    }
};

void Require(bool condition)
{
    if (!condition)
        throw std::runtime_error("lottery assertion failed");
}

struct WorldSession
{
    std::map<uint32, std::string> cache;
    std::vector<uint32> sequence;
    std::vector<uint8> lastPacket;
    void SendPacket(WorldPacket const* packet)
    {
        Require(packet->opcode == SMSG_NPC_TEXT_UPDATE);
        sequence.push_back(packet->opcode);
        lastPacket = packet->bytes;
        uint32 id = uint32(lastPacket[0]) | uint32(lastPacket[1]) << 8 |
            uint32(lastPacket[2]) << 16 | uint32(lastPacket[3]) << 24;
        cache[id] = std::string(reinterpret_cast<char const*>(lastPacket.data() + 8));
    }
};

class PlayerMenu
{
public:
    explicit PlayerMenu(WorldSession* session) : _session(session) { }
    void ClearDynamicGossipText();
    void SendDynamicGossipMenu(std::string const&, ObjectGuid);
    bool SendDynamicGossipText(uint32, ObjectGuid);
    void SendGossipMenu(uint32 id, ObjectGuid)
    {
        _session->sequence.push_back(0x17D);
        observed = _session->cache[id];
        selectedId = id;
    }
    std::string observed;
    uint32 selectedId = 0;
private:
    WorldSession* _session;
    std::mutex _dynamicTextMutex;
    uint32 _dynamicTextId = 0;
    ObjectGuid _dynamicTextGUID;
    std::string _dynamicText;
};

DYNAMIC_METHODS

int main()
{
    using namespace CoALottery;
    std::vector<uint32> prizes;
    Require(ParseBonusItems(" 97393, 98073,97393 ", prizes));
    Require(prizes == std::vector<uint32>({97393, 98073}));
    for (auto invalid : {"0", "-1", "97393,", "97393,,98073", "abc", "4294967296"})
    {
        Require(!ParseBonusItems(invalid, prizes));
        Require(prizes == std::vector<uint32>({97393, 98073}));
    }
    Require(ParseBonusItems("", prizes) && prizes.empty());
    WorldSession first;
    WorldSession second;
    PlayerMenu a(&first);
    PlayerMenu b(&second);
    ObjectGuid npc{80539};
    a.SendDynamicGossipMenu("Your gold tickets: 12", npc);
    b.SendDynamicGossipMenu("Your gold tickets: 3", npc);
    Require(a.observed == "Your gold tickets: 12" && b.observed == "Your gold tickets: 3");
    Require(first.sequence == std::vector<uint32>({0x180, 0x17D}));
    uint32 originalId = a.selectedId;
    a.SendDynamicGossipMenu("Your gold tickets: 13", npc);
    Require(a.selectedId != originalId && a.observed == "Your gold tickets: 13");
    a.SendDynamicGossipMenu("Your gold tickets: 14", npc);
    Require(a.selectedId == originalId && a.observed == "Your gold tickets: 14");
    Require(!a.SendDynamicGossipText(a.selectedId, ObjectGuid{80540}));
    Require(!a.SendDynamicGossipText(a.selectedId + 100, npc));
    Require(a.SendDynamicGossipText(a.selectedId, npc));
    auto const& bytes = first.lastPacket;
    size_t offset = 4;
    for (uint8 i = 0; i < 8; ++i)
    {
        float probability;
        std::copy(bytes.begin() + offset, bytes.begin() + offset + 4,
            reinterpret_cast<uint8*>(&probability));
        Require(probability == (i == 0 ? 1.0f : 0.0f));
        offset += 4;
        for (uint8 stringIndex = 0; stringIndex < 2; ++stringIndex)
        {
            std::string text(reinterpret_cast<char const*>(bytes.data() + offset));
            Require(text == (i == 0 ? "Your gold tickets: 14" : ""));
            offset += text.size() + 1;
        }
        for (uint8 field = 0; field < 28; ++field)
            Require(bytes[offset++] == 0);
    }
    Require(offset == bytes.size());
    a.ClearDynamicGossipText();
    Require(!a.SendDynamicGossipText(a.selectedId, npc));
    Require(b.SendDynamicGossipText(b.selectedId, npc));
    Require(!CanPurchase(TicketCost - 1, 0, 0, 1, 100));
    Require(CanPurchase(TicketCost, 0, 0, 1, 100));
    Require(!CanPurchase(TicketCost, MaximumPot, 0, 1, 100));
    Require(CanPurchase(TicketCost, MaximumPot - TicketCost, 0, 1, 100));
    Require(!CanPurchase(UINT32_MAX, 0, 0, UINT32_MAX, 100));
    Require(!CanPurchase(TicketCost, 0, MaximumTickets, 1, 0));
    Require(Contribution(10, 70) == 700000);
    Require(HouseTickets(0, 100) == 100);
    Require(HouseTickets(0, 0) == 0);
    Require(HouseTickets(MaximumPot, 100) == 0);
    Require(HouseTickets(MaximumPot - TicketCost, UINT32_MAX) == 1);
    Require(HouseTickets(0, UINT32_MAX) == MaximumTickets);
    Require(!CanPurchase(TicketCost, 0, MaximumTickets, 1, 0));
    std::map<uint32, uint32> houseDrawEntries{{10, 2}, {20, 3}};
    std::map<uint32, uint32> frequencies;
    for (uint32 ticket = 0; ticket < 105; ++ticket)
        ++frequencies[SelectDrawWinner(houseDrawEntries, 100, ticket)];
    Require(frequencies[0] == 100 && frequencies[10] == 2 && frequencies[20] == 3);
    Require(SelectDrawWinner(houseDrawEntries, 0, 0) == 10);
    Require(SelectDrawWinner(houseDrawEntries, 100, 99) == 0);
    Require(SelectDrawWinner(houseDrawEntries, 100, 100) == 10);
    Require(SelectDrawWinner(std::map<uint32, uint32>{}, 100, 99) == 0);
    std::map<uint32, uint32> entries = {{10, 1}, {20, 10}, {30, 100}};
    std::map<uint32, uint32> wins;
    for (uint32 ticket = 0; ticket < 111; ++ticket)
        ++wins[SelectWinner(entries, ticket)];
    Require(wins == entries && !SelectWinner(entries, 111));
    std::cout << "Lottery C++ harness passed\n";
}
