#ifndef COA_ECONOMY_LOG_H
#define COA_ECONOMY_LOG_H

#include "DatabaseEnvFwd.h"
#include "Define.h"

#include <optional>
#include <string_view>

class Item;
class Player;

enum class CoAEconomyEvent : uint8
{
    VanityStoreBuy = 1,
    VanityCollect = 2,
    VendorBuy = 3,
    VendorSell = 4,
    VendorBuyback = 5,
    BazaarRotationBuy = 6,
    HeirloomTokenBuy = 7,
    CacheOpen = 8,
    AhList = 9,
    AhCancel = 10,
    AhBid = 11,
    AhBuyout = 12,
    AhSold = 13,
    AhExpired = 14,
    Trade = 15,
    MailSend = 16,
    MailTake = 17,
    SystemMail = 18,
    TokensEarned = 19,
    TokensSpent = 20,
    ItemDestroy = 21,
    HighRiskDrop = 22,
    HighRiskClaim = 23,
    Reward = 24,
    StoreBuy = 25
};

enum class CoATokenSource : uint32
{
    Kill = 1,
    Quest = 2,
    DungeonBoss = 3,
    RaidBoss = 4,
    Cache = 5,
    Exchange = 6,
    Other = 7
};

enum class CoAGrantSource : uint32
{
    CrowsCache = 1,
    Arena = 2,
    MythicPlus = 3,
    Manastorm = 4,
    DungeonBoss = 5,
    VoidPortal = 6,
    CallBoard = 7,
    Wildcard = 8,
    ToolDispenser = 9,
    WildcardStore = 10,
    ClassBundleStore = 11
};

struct CoAEconomyRow
{
    CoAEconomyEvent event = CoAEconomyEvent::ItemDestroy;
    uint32 time = 0;
    uint32 itemEntry = 0;
    uint32 itemGuid = 0;
    uint32 itemCount = 0;
    int64 gold = 0;
    int32 tokens = 0;
    uint32 costItem = 0;
    uint32 costCount = 0;
    uint32 otherAccount = 0;
    uint32 otherGuid = 0;
    uint32 source = 0;
};

namespace CoAEconomyLog
{
    bool Enabled();
    bool SetEnabled(bool enabled);
    std::optional<CoAEconomyEvent> EventByName(std::string_view name);
    void Queue(Player* player, CoAEconomyRow const& row);
    void Write(CharacterDatabaseTransaction trans, uint32 account, uint32 guid, uint16 map, uint16 zone,
        CoAEconomyRow const& row);
    void FlushQueue(Player* player, CharacterDatabaseTransaction trans);
    void AddTokensEarned(Player* player, int32 tokens, CoATokenSource source);
    void CacheItem(Player* player, uint32 cacheEntry, Item const* item, uint32 count);
    CoAEconomyRow Tag(CoAEconomyEvent event, uint32 source, uint32 costItem = 0, uint32 costCount = 0, int64 gold = 0);
    CoAEconomyRow Tag(CoAEconomyEvent event, CoAGrantSource source, uint32 costItem = 0, uint32 costCount = 0,
        int64 gold = 0);
    CoAEconomyRow NextRow(CoAEconomyRow& tag);
    void Gained(Player* player, CoAEconomyRow const& tag, Item const* item, uint32 count);
    void GainedGold(Player* player, CoAEconomyRow const& tag, uint32 copper);
    void GainedInto(CharacterDatabaseTransaction trans, uint32 guid, CoAEconomyRow const& tag, Item const* item,
        uint32 count);
    void Cleanup(uint32 now, bool wait);
    uint32 QueuedRows(Player const* player);

    class GainScope
    {
    public:
        GainScope(Player* player, CoAEconomyRow const& tag);
        ~GainScope();
        GainScope(GainScope const&) = delete;
        GainScope& operator=(GainScope const&) = delete;

        static CoAEconomyRow* Find(uint32 guid);

    private:
        uint32 _guid;
        CoAEconomyRow _tag;
        GainScope* _outer;
    };
}

void AddSC_CoAEconomyLog();

#endif
