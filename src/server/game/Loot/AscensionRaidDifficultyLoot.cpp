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
constexpr uint32 NaxxramasMap = 533;
constexpr std::array<uint32, 28> NaxxramasBossLoot = {
    15928, 15931, 15932, 15936, 15952, 15953, 15954, 15956, 15989, 15990, 16011, 16028, 16060, 16061,
    29249, 29268, 29278, 29324, 29373, 29417, 29448, 29615, 29701, 29718, 29940, 29955, 29991, 30061
};
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

constexpr uint32 NaxxramasTokens[][MAX_RAID_DIFFICULTY] = {
    { 22353, 102278, 1402278, 222353 },
    { 22354, 102286, 1402286, 222354 },
    { 22349, 102264, 1402264, 222349 },
    { 22355, 102262, 1402262, 222355 },
    { 22357, 102268, 1402268, 222357 },
    { 22356, 102300, 1402300, 222356 },
    { 22352, 102284, 1402284, 222352 },
    { 22358, 102290, 1402290, 222358 },
    { 1510496, 1810496, 2810496, 1710496 },
};

uint32 NaxxramasTokenVariant(uint32 item, std::size_t difficulty)
{
    for (auto const& variants : NaxxramasTokens)
        if (variants[0] == item)
            return variants[difficulty];
    return item;
}

bool IsNaxxramasEncounterLoot(LootStore const& store, uint32 lootId)
{
    if (&store == &LootTemplates_Gameobject)
        return lootId == 25192 || lootId == 25193;

    return &store == &LootTemplates_Creature &&
        std::binary_search(NaxxramasBossLoot.begin(), NaxxramasBossLoot.end(), lootId);
}

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
    if (!source)
        return;

    bool const karazhan = source->GetMapId() == KarazhanMap && IsKarazhanEncounterLoot(store, lootId);
    bool const naxxramas = source->GetMapId() == NaxxramasMap && IsNaxxramasEncounterLoot(store, lootId);
    if (!karazhan && !naxxramas)
        return;

    Map const* map = source->FindMap();
    if (!map || map->IsScriptedPrivateInstance())
        return;

    size_t const difficulty = map->GetSpawnMode();
    if (difficulty >= ItemOffsets.size())
        return;

    for (LootItem& item : loot.items)
    {
        if (item.needs_quest)
            continue;

        uint32 difficultyItem = item.itemid;
        if (naxxramas)
            difficultyItem = NaxxramasTokenVariant(item.itemid, difficulty);
        else if (std::binary_search(KarazhanTieredDrops.begin(), KarazhanTieredDrops.end(), item.itemid))
            difficultyItem = RedeemableToken(item.itemid) + ItemOffsets[difficulty];
        if (difficultyItem == item.itemid)
            continue;
        if (!sObjectMgr->GetItemTemplate(difficultyItem))
        {
            LOG_ERROR("coa", "Missing raid loot variant {} for item {} on map {} mode {}",
                difficultyItem, item.itemid, source->GetMapId(), difficulty);
            continue;
        }

        item.itemid = difficultyItem;
        item.randomSuffix = GenerateEnchSuffixFactor(difficultyItem);
        item.randomPropertyId = Item::GenerateItemRandomPropertyId(difficultyItem);
    }
}
