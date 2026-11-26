#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
#include <limits>
#include <memory>
#include <optional>
#include <sstream>
#include <string>
#include <string_view>
#include <type_traits>
#include <unordered_map>
#include <utility>
#include <vector>

using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
using uint64 = std::uint64_t;

constexpr uint8 BANK_TABS = 6;
constexpr uint8 OWNER_CHARACTER = 0;
constexpr uint8 OWNER_REALM = 1;
constexpr bool SEND_ALL_SLOTS = true;
constexpr uint32 MAX_MONEY_AMOUNT = 0x7FFFFFFF - 1;
constexpr uint8 GUILD_BANK_LOG_DEPOSIT_MONEY = 4;
constexpr uint8 GUILD_BANK_LOG_WITHDRAW_MONEY = 5;
constexpr uint32 EQUIP_ERR_NONE = 0;

struct ObjectGuid
{
    using LowType = uint32;
    uint64 Value = 0;

    LowType GetCounter() const { return LowType(Value); }
    bool operator==(ObjectGuid const&) const = default;
};

struct SpellCastTargets { };

struct Item
{
    uint32 Entry = 0;
    uint32 Count = 1;

    uint32 GetEntry() const { return Entry; }
    uint32 GetCount() const { return Count; }
};

struct WorldSession
{
    uint32 AccountId = 0;
    uint32 GetAccountId() const { return AccountId; }
};

struct MockTransaction
{
    std::vector<std::string> Ops;

    template <typename T>
    static void WriteArg(std::ostringstream& out, T const& value)
    {
        if constexpr (std::is_same_v<std::decay_t<T>, uint8>)
            out << unsigned(value);
        else
            out << value;
    }

    static void FormatInto(std::ostringstream& out, std::string_view fmt)
    {
        out << fmt;
    }

    template <typename First, typename... Rest>
    static void FormatInto(std::ostringstream& out, std::string_view fmt, First const& first, Rest const&... rest)
    {
        std::size_t const pos = fmt.find("{}");
        assert(pos != std::string_view::npos);
        out << fmt.substr(0, pos);
        WriteArg(out, first);
        FormatInto(out, fmt.substr(pos + 2), rest...);
    }

    template <typename... Args>
    void Append(std::string_view sql, Args const&... args)
    {
        std::ostringstream out;
        FormatInto(out, sql, args...);
        Ops.push_back(out.str());
    }
};

using CharacterDatabaseTransaction = std::shared_ptr<MockTransaction>;

struct Field
{
    std::optional<uint8> Value;
    bool IsNull() const { return !Value.has_value(); }
    template <typename T>
    T Get() const
    {
        return T(*Value);
    }
};

struct ResultSet
{
    Field Row;
    Field* Fetch() { return &Row; }
};

using QueryResult = std::shared_ptr<ResultSet>;

struct MockCharacterDatabase
{
    std::vector<std::vector<std::string>> Committed;
    uint32 DirectExecutes = 0;
    std::optional<uint8> QueryMaxTab;

    CharacterDatabaseTransaction BeginTransaction()
    {
        return std::make_shared<MockTransaction>();
    }

    void CommitTransaction(CharacterDatabaseTransaction trans)
    {
        assert(trans != nullptr);
        Committed.push_back(trans->Ops);
    }

    template <typename... Args>
    void Execute(std::string_view, Args const&...)
    {
        ++DirectExecutes;
    }

    template <typename... Args>
    QueryResult Query(std::string_view, Args const&...)
    {
        auto result = std::make_shared<ResultSet>();
        result->Row.Value = QueryMaxTab;
        return result;
    }

    void EscapeString(std::string&) { }
};

MockCharacterDatabase CharacterDatabase;

struct Player
{
    ObjectGuid Guid{ 42 };
    WorldSession Session{ 77 };
    std::string Name = "Tester";
    uint32 Money = 0;
    Item* ActiveVoucher = nullptr;
    uint32 DestroyCalls = 0;

    ObjectGuid GetGUID() const { return Guid; }
    WorldSession* GetSession() { return &Session; }
    WorldSession const* GetSession() const { return &Session; }
    std::string const& GetName() const { return Name; }

    bool HasEnoughMoney(uint32 amount) const { return Money >= amount; }

    bool ModifyMoney(int32 amount)
    {
        if (!amount)
            return true;
        if (amount < 0)
        {
            uint32 const dec = uint32(-amount);
            Money = Money > dec ? Money - dec : 0;
            return true;
        }
        if (Money < uint32(MAX_MONEY_AMOUNT - uint32(amount)))
        {
            Money += uint32(amount);
            return true;
        }
        return false;
    }

    void SaveGoldToDB(CharacterDatabaseTransaction trans)
    {
        trans->Append("SAVE_GOLD {}", Money);
    }

    void DestroyItemCount(Item* item, uint32& count, bool)
    {
        assert(item != nullptr);
        ++DestroyCalls;
        if (item->Count <= count)
        {
            count -= item->Count;
            item->Count = 0;
        }
        else
        {
            item->Count -= count;
            count = 0;
        }
    }

    void SaveInventoryAndGoldToDB(CharacterDatabaseTransaction trans)
    {
        uint32 const voucherCount = ActiveVoucher ? ActiveVoucher->Count : 0;
        trans->Append("SAVE_INVENTORY_AND_GOLD {} {}", voucherCount, Money);
    }

    void SendEquipError(uint32, Item*, Item*) { }
};

struct ChatHandler
{
    explicit ChatHandler(WorldSession*) { }
    template <typename... Args>
    void PSendSysMessage(std::string_view, Args const&...) { }
};

struct ScriptMgrMock
{
    uint32 BankWithdrawHooks = 0;
    void OnPlayerBankWithdraw(Player*, uint8) { ++BankWithdrawHooks; }
};

ScriptMgrMock scriptMgrInstance;
ScriptMgrMock* sScriptMgr = &scriptMgrInstance;

struct WorldPacket
{
    ObjectGuid Banker;
    uint32 Money = 0;
    uint8 Tab = 0;
    std::string Name;
    std::string Icon;
    std::string Text;
};

namespace WorldPackets::Guild
{
struct GuildBankDepositMoney
{
    WorldPacket Pkt;
    ObjectGuid Banker;
    uint32 Money = 0;
    explicit GuildBankDepositMoney(WorldPacket&& p) : Pkt(std::move(p)) { }
    void Read()
    {
        Banker = Pkt.Banker;
        Money = Pkt.Money;
    }
};

struct GuildBankWithdrawMoney
{
    WorldPacket Pkt;
    ObjectGuid Banker;
    uint32 Money = 0;
    explicit GuildBankWithdrawMoney(WorldPacket&& p) : Pkt(std::move(p)) { }
    void Read()
    {
        Banker = Pkt.Banker;
        Money = Pkt.Money;
    }
};

struct GuildBankBuyTab
{
    WorldPacket Pkt;
    ObjectGuid Banker;
    uint8 BankTab = 0;
    explicit GuildBankBuyTab(WorldPacket&& p) : Pkt(std::move(p)) { }
    void Read()
    {
        Banker = Pkt.Banker;
        BankTab = Pkt.Tab;
    }
};

struct GuildBankUpdateTab
{
    WorldPacket Pkt;
    ObjectGuid Banker;
    uint8 BankTab = 0;
    std::string Name;
    std::string Icon;
    explicit GuildBankUpdateTab(WorldPacket&& p) : Pkt(std::move(p)) { }
    void Read()
    {
        Banker = Pkt.Banker;
        BankTab = Pkt.Tab;
        Name = Pkt.Name;
        Icon = Pkt.Icon;
    }
};

struct GuildBankSetTabText
{
    WorldPacket Pkt;
    uint8 Tab = 0;
    std::string TabText;
    explicit GuildBankSetTabText(WorldPacket&& p) : Pkt(std::move(p)) { }
    void Read()
    {
        Tab = Pkt.Tab;
        TabText = Pkt.Text;
    }
};
}

namespace AscensionPersonalBank
{
enum Kind : uint8
{
    PERSONAL = 0,
    REALM = 1
};

bool AccessAllowed = true;
bool CanAccess(Player*, uint8) { return AccessAllowed; }
}

struct ItemScript
{
    explicit ItemScript(char const*) { }
    virtual ~ItemScript() = default;
    virtual bool OnUse(Player*, Item*, SpellCastTargets const&) { return false; }
};

struct OpenBank
{
    uint8 OwnerKind = OWNER_CHARACTER;
    uint64 OwnerId = 0;
    ObjectGuid Vault;
    uint8 Tabs = 1;
    std::array<std::string, BANK_TABS> TabName;
    std::array<std::string, BANK_TABS> TabIcon;
    std::array<std::string, BANK_TABS> TabText;
    uint64 Money = 0;
};

std::unordered_map<ObjectGuid::LowType, OpenBank> openBanks;

uint64 BankOwnerId(Player const* player, uint8 kind)
{
    return kind == AscensionPersonalBank::REALM
               ? uint64(player->GetSession()->GetAccountId())
               : player->GetGUID().GetCounter();
}

uint32 TabPrice(uint8 tab)
{
    return tab < BANK_TABS ? uint32(tab + 1) * 10000 : 0;
}

template <typename T, typename Use>
void WithBankPacket(WorldPacket const& packet, Use&& use)
{
    WorldPacket copy(packet);
    T parsed(std::move(copy));
    parsed.Read();
    use(parsed);
}

void SendTabChanged(Player*, OpenBank const&, uint8) { }
void SendBankData(Player*, OpenBank const&, uint8, bool) { }
void SendTabList(Player*, OpenBank const&, uint8, bool) { }
void SendTabText(Player*, OpenBank const&, uint8) { }
void LogBankEvent(OpenBank const&, uint8, uint8, Player*, uint32, uint16, uint8 = 0) { }

#define LOG_INFO(...) do { } while (false)

// ACTUAL_STORE_MONEY
// ACTUAL_STORE_TAB
// ACTUAL_HANDLE_DEPOSIT_MONEY
// ACTUAL_HANDLE_WITHDRAW_MONEY
// ACTUAL_HANDLE_BUY_TAB
// ACTUAL_HANDLE_UPDATE_TAB
// ACTUAL_HANDLE_SET_TAB_TEXT
// ACTUAL_ADD_TAB_IN_TRANSACTION
// ACTUAL_VOUCHER_SCRIPT

static bool Contains(std::vector<std::string> const& ops, std::string_view needle)
{
    for (std::string const& op : ops)
        if (op.find(needle) != std::string::npos)
            return true;
    return false;
}

int main()
{
    for (uint8 kind : { AscensionPersonalBank::PERSONAL, AscensionPersonalBank::REALM })
    {
        uint8 const ownerKind = kind == AscensionPersonalBank::REALM ? OWNER_REALM : OWNER_CHARACTER;
        Player player;
        player.Guid = { 42 };
        player.Session.AccountId = 77;
        player.Money = 50000;
        uint64 const ownerId = BankOwnerId(&player, kind);

        OpenBank bank;
        bank.OwnerKind = ownerKind;
        bank.OwnerId = ownerId;
        bank.Vault = { 9001 };
        bank.Tabs = 1;
        bank.Money = 1000;

        CharacterDatabase.Committed.clear();
        CharacterDatabase.DirectExecutes = 0;

        WorldPacket dep;
        dep.Banker = bank.Vault;
        dep.Money = 1200;
        HandleDepositMoney(&player, bank, dep);

        assert(CharacterDatabase.DirectExecutes == 0);
        assert(CharacterDatabase.Committed.size() == 1);
        assert(player.Money == 48800);
        assert(bank.Money == 2200);
        assert(Contains(CharacterDatabase.Committed[0], "SAVE_GOLD 48800"));
        assert(Contains(CharacterDatabase.Committed[0],
                        "REPLACE INTO mod_ascension_bank_money (owner_kind, owner_id, money) VALUES (" +
                            std::to_string(ownerKind) + ", " + std::to_string(ownerId) + ", 2200)"));

        CharacterDatabase.Committed.clear();
        scriptMgrInstance.BankWithdrawHooks = 0;

        WorldPacket wd;
        wd.Banker = bank.Vault;
        wd.Money = 700;
        HandleWithdrawMoney(&player, bank, wd);

        assert(CharacterDatabase.DirectExecutes == 0);
        assert(CharacterDatabase.Committed.size() == 1);
        assert(player.Money == 49500);
        assert(bank.Money == 1500);
        assert(scriptMgrInstance.BankWithdrawHooks == 1);
        assert(Contains(CharacterDatabase.Committed[0], "SAVE_GOLD 49500"));
        assert(Contains(CharacterDatabase.Committed[0],
                        "REPLACE INTO mod_ascension_bank_money (owner_kind, owner_id, money) VALUES (" +
                            std::to_string(ownerKind) + ", " + std::to_string(ownerId) + ", 1500)"));

        CharacterDatabase.Committed.clear();
        scriptMgrInstance.BankWithdrawHooks = 0;
        player.Money = MAX_MONEY_AMOUNT - 10;
        WorldPacket wdCap;
        wdCap.Banker = bank.Vault;
        wdCap.Money = 500;
        HandleWithdrawMoney(&player, bank, wdCap);
        assert(CharacterDatabase.Committed.empty());
        assert(CharacterDatabase.DirectExecutes == 0);
        assert(bank.Money == 1500);
        assert(player.Money == MAX_MONEY_AMOUNT - 10);
        assert(scriptMgrInstance.BankWithdrawHooks == 0);

        player.Money = 50000;
        bank.Money = uint64(MAX_MONEY_AMOUNT) + 500;
        WorldPacket wdOverflow;
        wdOverflow.Banker = bank.Vault;
        wdOverflow.Money = MAX_MONEY_AMOUNT + 100;
        HandleWithdrawMoney(&player, bank, wdOverflow);
        assert(CharacterDatabase.Committed.empty());
        assert(bank.Money == uint64(MAX_MONEY_AMOUNT) + 500);
        assert(player.Money == 50000);
        assert(scriptMgrInstance.BankWithdrawHooks == 0);

        CharacterDatabase.Committed.clear();
        WorldPacket buy;
        buy.Banker = bank.Vault;
        buy.Tab = 1;
        HandleBuyTab(&player, bank, buy);

        assert(CharacterDatabase.DirectExecutes == 0);
        assert(CharacterDatabase.Committed.size() == 1);
        assert(player.Money == 30000);
        assert(bank.Tabs == 2);
        assert(Contains(CharacterDatabase.Committed[0], "SAVE_GOLD 30000"));
        assert(Contains(CharacterDatabase.Committed[0],
                        "REPLACE INTO mod_ascension_bank_tab "
                        "(owner_kind, owner_id, tab_index, name, icon, text) VALUES (" +
                            std::to_string(ownerKind) + ", " + std::to_string(ownerId) + ", 1, '', '', '')"));

        CharacterDatabase.Committed.clear();
        WorldPacket upd;
        upd.Banker = bank.Vault;
        upd.Tab = 1;
        upd.Name = "Gear";
        upd.Icon = "INV_Chest";
        HandleUpdateTab(&player, bank, upd);
        assert(CharacterDatabase.DirectExecutes == 0);
        assert(CharacterDatabase.Committed.size() == 1);
        assert(Contains(CharacterDatabase.Committed[0], "REPLACE INTO mod_ascension_bank_tab"));

        CharacterDatabase.Committed.clear();
        WorldPacket txt;
        txt.Tab = 1;
        txt.Text = "Notes";
        HandleSetTabText(&player, bank, txt);
        assert(CharacterDatabase.DirectExecutes == 0);
        assert(CharacterDatabase.Committed.size() == 1);
        assert(Contains(CharacterDatabase.Committed[0], "REPLACE INTO mod_ascension_bank_tab"));

        item_ascension_bank_tab_voucher script;
        SpellCastTargets targets;
        Item voucher;
        voucher.Entry = kind == AscensionPersonalBank::REALM ? 1180485 : 110002;
        voucher.Count = 2;
        player.ActiveVoucher = &voucher;
        player.DestroyCalls = 0;

        openBanks.clear();
        CharacterDatabase.QueryMaxTab = 1;
        CharacterDatabase.Committed.clear();
        assert(script.OnUse(&player, &voucher, targets));
        assert(CharacterDatabase.DirectExecutes == 0);
        assert(CharacterDatabase.Committed.size() == 1);
        assert(player.DestroyCalls == 1);
        assert(voucher.Count == 1);
        assert(Contains(CharacterDatabase.Committed[0], "SAVE_INVENTORY_AND_GOLD 1 30000"));
        assert(Contains(CharacterDatabase.Committed[0],
                        "REPLACE INTO mod_ascension_bank_tab "
                        "(owner_kind, owner_id, tab_index, name, icon, text) VALUES (" +
                            std::to_string(ownerKind) + ", " + std::to_string(ownerId) + ", 2, '', '', '')"));

        openBanks[player.GetGUID().GetCounter()] = bank;
        openBanks[player.GetGUID().GetCounter()].Tabs = 3;
        CharacterDatabase.Committed.clear();
        player.DestroyCalls = 0;
        assert(script.OnUse(&player, &voucher, targets));
        assert(CharacterDatabase.DirectExecutes == 0);
        assert(CharacterDatabase.Committed.size() == 1);
        assert(player.DestroyCalls == 1);
        assert(voucher.Count == 0);
        assert(openBanks[player.GetGUID().GetCounter()].Tabs == 4);
        assert(Contains(CharacterDatabase.Committed[0], "SAVE_INVENTORY_AND_GOLD 0 30000"));
        assert(Contains(CharacterDatabase.Committed[0],
                        "REPLACE INTO mod_ascension_bank_tab "
                        "(owner_kind, owner_id, tab_index, name, icon, text) VALUES (" +
                            std::to_string(ownerKind) + ", " + std::to_string(ownerId) + ", 3, '', '', '')"));

        voucher.Count = 1;
        openBanks[player.GetGUID().GetCounter()].Tabs = BANK_TABS;
        CharacterDatabase.Committed.clear();
        player.DestroyCalls = 0;
        assert(script.OnUse(&player, &voucher, targets));
        assert(CharacterDatabase.DirectExecutes == 0);
        assert(CharacterDatabase.Committed.empty());
        assert(player.DestroyCalls == 0);
        assert(voucher.Count == 1);
    }

    return 0;
}
