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
    VanityCollect,
    VendorBuy,
    VendorSell,
    VendorBuyback,
    BazaarRotationBuy,
    HeirloomTokenBuy,
    CacheOpen,
    AhList,
    AhCancel,
    AhBid,
    AhBuyout,
    AhSold,
    AhExpired,
    Trade,
    MailSend,
    MailTake,
    SystemMail,
    TokensEarned,
    TokensSpent,
    ItemDestroy,
    HighRiskDrop,
    HighRiskClaim,
    Reward,
    StoreBuy
};

enum class CoATokenSource : uint32
{
    Kill = 1,
    Quest,
    DungeonBoss,
    RaidBoss,
    Cache,
    Exchange,
    Other
};

enum class CoAGrantSource : uint32
{
    CrowsCache = 1,
    Arena,
    MythicPlus,
    Manastorm,
    DungeonBoss,
    VoidPortal,
    CallBoard,
    Wildcard,
    ToolDispenser,
    WildcardStore,
    ClassBundleStore
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
