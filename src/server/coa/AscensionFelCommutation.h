#ifndef COA_ASCENSION_FEL_COMMUTATION_H
#define COA_ASCENSION_FEL_COMMUTATION_H

#include "Define.h"
#include <vector>

class Item;
class Player;

namespace FelCommutation
{
constexpr uint16 ToggleOpcode = 0x073B;
constexpr uint16 ResultOpcode = 0x073C;
constexpr uint16 UpdateOpcode = 0x073D;
constexpr uint16 WindowOpcode = 0x0906;
constexpr uint16 PatchGlobalStringsOpcode = 0x0676;
constexpr uint32 PortalEntry = 8000053;
constexpr uint32 GreedyDemonEntry = 75120;
constexpr uint32 CreditEntry = 13514;
constexpr char Setting[] = "core.coa_fel_commutation";

[[nodiscard]] bool Enabled();
[[nodiscard]] bool Active(Player const* player);
[[nodiscard]] uint32 Shield(Player* player, std::vector<Item*> const& insurable, std::vector<Item*>& losses);
void ReportLoss(Player* player, uint32 insuranceFee, uint32 droppedGold);
}

#endif
