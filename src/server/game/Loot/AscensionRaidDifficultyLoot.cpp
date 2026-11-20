#include "AscensionRaidDifficultyLoot.h"
#include "Item.h"
#include "ItemEnchantmentMgr.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "Object.h"
#include "ObjectMgr.h"
#include <algorithm>
#include <array>

namespace
{
constexpr uint32 KarazhanMap = 532;
constexpr std::array<uint32, 13> KarazhanBossLoot = {
    15687, 15688, 15689, 15690, 15691, 16152, 16457, 16524, 17225, 17521, 17533, 17534, 18168
};
constexpr uint32 KarazhanChessLoot = 20712;
constexpr std::array<uint32, 138> KarazhanTieredDrops = {
    28453, 28454, 28477, 28502, 28503, 28504, 28505, 28506, 28507, 28508, 28509, 28510, 28511, 28512,
    28514, 28515, 28516, 28517, 28518, 28519, 28520, 28521, 28522, 28523, 28524, 28525, 28528, 28529,
    28530, 28545, 28565, 28566, 28567, 28568, 28569, 28570, 28572, 28573, 28578, 28579, 28581, 28582,
    28583, 28584, 28585, 28586, 28587, 28588, 28589, 28590, 28591, 28592, 28593, 28594, 28597, 28599,
    28600, 28601, 28602, 28603, 28604, 28606, 28608, 28609, 28610, 28611, 28612, 28621, 28631, 28633,
    28647, 28649, 28652, 28653, 28654, 28655, 28656, 28657, 28658, 28659, 28660, 28661, 28662, 28663,
    28666, 28669, 28670, 28671, 28672, 28673, 28674, 28675, 28726, 28727, 28728, 28729, 28730, 28731,
    28732, 28733, 28734, 28735, 28740, 28741, 28742, 28743, 28744, 28745, 28746, 28747, 28748, 28749,
    28750, 28751, 28752, 28753, 28754, 28755, 28756, 28757, 28762, 28763, 28764, 28765, 28766, 28767,
    28768, 28770, 28771, 28772, 28773, 28785, 29756, 29757, 29758, 29759, 29760, 29761
};
constexpr std::array<uint32, MAX_RAID_DIFFICULTY> ItemOffsets = { 0, 300000, 1300000, 200000 };

uint32 RedeemableToken(uint32 item)
{
    if (item >= 29756 && item <= 29758)
        return 29758;
    if (item >= 29759 && item <= 29761)
        return 29761;
    return item;
}

bool IsKarazhanEncounterLoot(LootStore const& store, uint32 lootId)
{
    if (&store == &LootTemplates_Gameobject)
        return lootId == KarazhanChessLoot;

    return &store == &LootTemplates_Creature &&
        std::binary_search(KarazhanBossLoot.begin(), KarazhanBossLoot.end(), lootId);
}
}

void AscensionRaidDifficultyLoot::Apply(Loot& loot, LootStore const& store, uint32 lootId, WorldObject const* source)
{
    if (!source || source->GetMapId() != KarazhanMap || !IsKarazhanEncounterLoot(store, lootId))
        return;

    Map const* map = source->FindMap();
    if (!map || map->IsScriptedPrivateInstance())
        return;

    size_t const difficulty = map->GetSpawnMode();
    if (difficulty >= ItemOffsets.size())
        return;

    for (LootItem& item : loot.items)
    {
        if (item.needs_quest || !std::binary_search(KarazhanTieredDrops.begin(), KarazhanTieredDrops.end(), item.itemid))
            continue;

        uint32 const difficultyItem = RedeemableToken(item.itemid) + ItemOffsets[difficulty];
        if (difficultyItem == item.itemid)
            continue;
        if (!sObjectMgr->GetItemTemplate(difficultyItem))
        {
            LOG_ERROR("coa", "Missing Karazhan loot variant {} for item {} on mode {}",
                difficultyItem, item.itemid, difficulty);
            continue;
        }

        item.itemid = difficultyItem;
        item.randomSuffix = GenerateEnchSuffixFactor(difficultyItem);
        item.randomPropertyId = Item::GenerateItemRandomPropertyId(difficultyItem);
    }
}
