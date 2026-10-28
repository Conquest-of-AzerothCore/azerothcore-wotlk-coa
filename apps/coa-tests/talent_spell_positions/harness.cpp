#include <cstdint>
#include <cstring>
#include <fstream>
#include <iostream>
#include <iterator>
#include <map>
#include <vector>

using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;

constexpr uint32 MAX_TALENT_RANK = 5;
constexpr uint32 FIRST_RANK_FIELD = 4;

// ACTUAL_TALENT_SPELL_POS

int main(int argc, char** argv)
{
    if (argc != 2)
        return 2;

    std::ifstream file(argv[1], std::ios::binary);
    std::vector<char> raw((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
    if (raw.size() < 20 || std::memcmp(raw.data(), "WDBC", 4) != 0)
    {
        std::cerr << "FAIL: Talent.dbc unreadable\n";
        return 1;
    }

    uint32 header[4];
    std::memcpy(header, raw.data() + 4, sizeof(header));
    uint32 const records = header[0];
    uint32 const recordSize = header[2];

    std::map<uint32, TalentSpellPos> positions;
    std::map<uint32, uint32> owners;
    uint32 wideTalents = 0;
    for (uint32 record = 0; record < records; ++record)
    {
        char const* row = raw.data() + 20 + std::size_t(record) * recordSize;
        uint32 talentId;
        std::memcpy(&talentId, row, sizeof(talentId));
        if (talentId > 0xFFFF)
            ++wideTalents;
        for (uint32 rank = 0; rank < MAX_TALENT_RANK; ++rank)
        {
            uint32 spellId;
            std::memcpy(&spellId, row + (FIRST_RANK_FIELD + rank) * 4, sizeof(spellId));
            if (!spellId)
                continue;
            positions[spellId] = TalentSpellPos(talentId, uint8(rank));
            owners[spellId] = talentId;
        }
    }

    uint32 failures = 0;
    for (auto const& [spellId, talentId] : owners)
    {
        if (positions[spellId].talent_id != talentId)
        {
            if (++failures <= 5)
                std::cerr << "FAIL: rank spell " << spellId << " maps to talent " << positions[spellId].talent_id
                          << ", not " << talentId << "\n";
        }
    }

    if (!wideTalents)
    {
        std::cerr << "FAIL: Talent.dbc has no talent id above 65535\n";
        return 1;
    }
    if (failures)
    {
        std::cerr << "FAIL: " << failures << " of " << owners.size() << " talent rank spells lose their talent\n";
        return 1;
    }
    std::cout << "PASS: " << owners.size() << " talent rank spells keep their talent, " << wideTalents
              << " talents above 65535\n";
    return 0;
}
