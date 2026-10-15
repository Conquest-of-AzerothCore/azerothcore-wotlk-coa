#ifndef COA_SPELLBOOK_H
#define COA_SPELLBOOK_H

#include <cstdint>
#include <vector>

class Player;

namespace CoASpellbook
{
    constexpr std::uint16_t SMSG_PATCH_SPELL_CUSTOM_ATTR = 0x05F4;
    constexpr std::uint16_t SMSG_PATCH_SPELL = 0x092A;
    constexpr std::size_t SMSG_PATCH_SPELL_CAST_TIME_INDEX_DWORD = 28;

    struct Provider
    {
        std::uint32_t (*RowCount)(Player*) = nullptr;
        bool (*OffersSpell)(Player*, std::uint32_t) = nullptr;
        bool (*CoversSpell)(Player*, std::uint32_t) = nullptr;
        std::vector<std::uint32_t> (*UpgradeRanksAbove)(Player*, std::uint8_t) = nullptr;
    };

    void SetProvider(Provider provider);
    bool Available();
    double RowCount(Player* player);
    double OffersSpell(Player* player, std::uint32_t spellId);
    double CoversSpell(Player* player, std::uint32_t spellId);
    std::vector<std::uint32_t> UpgradeRanksAbove(Player* player, std::uint8_t level);
}

#endif
