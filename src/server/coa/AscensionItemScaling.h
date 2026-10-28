#ifndef COA_ASCENSION_ITEM_SCALING_H
#define COA_ASCENSION_ITEM_SCALING_H

#include <array>
#include <cstdint>
#include <optional>
#include <unordered_set>

class WorldPacket;
class WorldSession;
struct ItemTemplate;

namespace ItemScaling
{
using ClientItemRow = std::array<std::uint32_t, 8>;

std::uint32_t BaseEntry(std::uint32_t entry);
std::optional<ClientItemRow> ClientRow(std::uint32_t entry);
void HandleStatQuery(WorldSession* session, WorldPacket const& packet);
bool LiftableEntry(std::uint32_t entry);
void RebracketDisenchant(ItemTemplate& scaled, ItemTemplate const& base, std::uint32_t itemLevel);
void SetUnliftableEntries(std::unordered_set<std::uint32_t> entries);
}

#endif
