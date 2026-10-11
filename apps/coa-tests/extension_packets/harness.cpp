#include "AscensionCollectibleSpellData.h"
#include "ItemTemplate.h"
#include "Optional.h"
#include "Tokenize.h"
#include "WorldPacket.h"
#include <algorithm>
#include <array>
#include <bit>
#include <cassert>
#include <ctime>
#include <deque>
#include <iostream>
#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <string_view>
#include <type_traits>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#define ASSERT(condition, ...) assert(condition)

time_t gameTime = 0;

namespace Acore::Time
{
std::tm TimeBreakdown(time_t time = 0);
}

namespace GameTime
{
Seconds GetGameTime()
{
    return Seconds(gameTime);
}
}

Seconds GetEpochTime()
{
    return Seconds(gameTime);
}

#ifdef _WIN32
std::tm* localtime_r(time_t const* time, std::tm* result)
{
    localtime_s(result, time);
    return result;
}
#endif

// ACTUAL_TIME_BREAKDOWN
// ACTUAL_BYTE_BUFFER

namespace
{
int failures = 0;
int checks = 0;
int warnings = 0;

void Check(bool value, char const* name)
{
    ++checks;
    failures += !value;
    std::cout << (value ? "PASS: " : "FAIL: ") << name << '\n';
}

template<class... Arguments>
void LogSink(Arguments&&...)
{
}
}

#define LOG_INFO(...) LogSink(__VA_ARGS__)
#define LOG_WARN(...) (++warnings, LogSink(__VA_ARGS__))
#define LOG_DEBUG(...) LogSink(__VA_ARGS__)

struct Player;

class WorldSession
{
public:
    uint32 AccountId = 1;
    bool Bot = false;
    int LocaleIndex = -1;
    Player* PlayerObject = nullptr;
    std::vector<WorldPacket> Sent;
    std::vector<std::string> Messages;
    std::vector<std::string> ClientAddons;

    uint32 GetAccountId() const { return AccountId; }
    std::vector<std::string> const& GetClientAddonNames() const { return ClientAddons; }
    bool IsBot() const { return Bot; }
    Player* GetPlayer() const { return PlayerObject; }
    int GetSessionDbLocaleIndex() const { return LocaleIndex; }
    void SendPacket(WorldPacket const* packet);
    void HandleItemQuerySingleOpcode(WorldPacket& recvData);
    void SendItemQuerySingleResponse(uint32 item);
};

struct ObjectMgr
{
    std::unordered_map<uint32, ItemTemplate> Items;
    std::unordered_map<uint32, ItemLocale> Locales;

    ItemTemplate const* GetItemTemplate(uint32 entry) const
    {
        auto const itr = Items.find(entry);
        return itr != Items.end() ? &itr->second : nullptr;
    }

    ItemLocale const* GetItemLocale(uint32 entry) const
    {
        auto const itr = Locales.find(entry);
        return itr != Locales.end() ? &itr->second : nullptr;
    }

    // ACTUAL_GET_LOCALE_STRING
} objectMgr;

ObjectMgr* sObjectMgr = &objectMgr;

struct SpellInfo
{
    uint32 RecoveryTime = 1500;
    uint32 CategoryRecoveryTime = 0;

    uint32 GetCategory() const { return 0; }
};

struct SpellMgr
{
    SpellInfo Spell;
    std::unordered_set<uint32> Known = {133, 200001, 200002};

    SpellInfo const* GetSpellInfo(uint32 spellId) const { return Known.contains(spellId) ? &Spell : nullptr; }
} spellMgr;

SpellMgr* sSpellMgr = &spellMgr;

// ACTUAL_ITEM_QUERY

struct Item
{
    uint32 Entry = 0;
};

using ItemPosCountVec = std::vector<uint32>;

enum InventoryResult
{
    EQUIP_ERR_OK = 0,
    EQUIP_ERR_INVENTORY_FULL = 50
};

constexpr uint8 NULL_BAG = 0;
constexpr uint8 NULL_SLOT = 255;

struct ObjectGuid
{
    explicit ObjectGuid(uint64 raw) : Raw(raw) { }
    uint32 GetCounter() const { return Raw; }
    uint64 Raw;
};

struct Player
{
    WorldSession* Session = nullptr;
    uint32 ChargeSnapshots = 0;
    uint32 EchoSnapshots = 0;
    bool BagsFull = false;
    std::deque<Item> Items;
    std::vector<uint32> Stored;
    std::vector<uint32> Learned;
    uint32 EquipErrors = 0;
    uint32 NewItemNotices = 0;

    WorldSession* GetSession() const { return Session; }
    ObjectGuid GetGUID() const { return ObjectGuid(1); }
    std::string GetName() const { return "Tester"; }
    bool IsInWorld() const { return true; }
    void SendDirectMessage(WorldPacket const* packet) { Session->SendPacket(packet); }
    void SendAllSpellChargeStates() { ++ChargeSnapshots; }

    InventoryResult CanStoreNewItem(uint8, uint8, ItemPosCountVec&, uint32, uint32) const
    {
        return BagsFull ? EQUIP_ERR_INVENTORY_FULL : EQUIP_ERR_OK;
    }

    void SendEquipError(InventoryResult, Item*, Item*, uint32) { ++EquipErrors; }

    Item* StoreNewItem(ItemPosCountVec const&, uint32 itemId, bool)
    {
        Stored.push_back(itemId);
        Items.push_back({itemId});
        return &Items.back();
    }

    void SendNewItem(Item*, uint32, bool, bool) { ++NewItemNotices; }
    void learnSpell(uint32 spellId, bool = false) { Learned.push_back(spellId); }
    bool HasSpell(uint32 spellId) const { return std::count(Learned.begin(), Learned.end(), spellId); }
    bool HasItemCount(uint32 itemId) const { return std::count(Stored.begin(), Stored.end(), itemId); }
    void SendInitialSpells() { }
};

// ACTUAL_RECEIVES_CLIENT_REQUESTS
// ACTUAL_PROGRESS_EVENT

struct ScriptMgr
{
    std::vector<std::pair<CoAProgressEvent, uint32>> Progress;

    void OnPlayerCoAProgress(Player*, CoAProgressEvent event, uint32 value) { Progress.emplace_back(event, value); }
};

ScriptMgr scriptMgr;
ScriptMgr* const sScriptMgr = &scriptMgr;

class ChatHandler
{
public:
    explicit ChatHandler(WorldSession* session) : _session(session) { }

    Player* GetPlayer() const { return _session->PlayerObject; }
    void SendSysMessage(std::string_view text) { _session->Messages.emplace_back(text); }

    template<class... Arguments>
    void PSendSysMessage(std::string_view text, Arguments&&...)
    {
        _session->Messages.emplace_back(text);
    }

private:
    WorldSession* _session;
};

void SendAscensionRunemasterEchoesCooldown(Player* player)
{
    ++player->EchoSnapshots;
}

bool IsAscensionCharacterSelectionOpcode(uint16)
{
    return false;
}

bool HandleAscensionCharacterSelectionPacket(WorldSession*, WorldPacket const&)
{
    return false;
}

void SendAscensionCharacterListInfo(WorldSession*)
{
}

bool QueueAscensionManastormPacket(WorldSession*, WorldPacket const&)
{
    return false;
}

std::vector<uint32> answeredCreatures;

bool SendCollectionCreatureQueryResponse(WorldSession*, uint32 entry)
{
    answeredCreatures.push_back(entry);
    return true;
}

std::vector<uint16> DispatchedOpcodes;

namespace AscensionCompatOpcodes
{
bool Dispatch(WorldSession*, WorldPacket const& packet)
{
    DispatchedOpcodes.push_back(packet.GetOpcode());
    return false;
}
}

struct ServerScript
{
    virtual ~ServerScript() = default;
    [[nodiscard]] virtual bool CanPacketReceiveEarly(WorldSession*, WorldPacket const&) { return true; }
    virtual bool CanPacketSend(WorldSession*, WorldPacket const&) { return true; }
};

namespace
{
// ACTUAL_OPCODES
// ACTUAL_QUEUE_LIMIT
// ACTUAL_CONFIG_KEYS

struct CompatConfig
{
    std::string RealmType = "live";
    std::string ClassModel = "coa";
    uint32 GameModeMask = 0;
    bool UnlockAllVanity = true;
    bool LearnedSpellDelivery = true;

    template<class T>
    T GetConfigValue(AscensionCompatConfig key) const
    {
        if constexpr (std::is_same_v<T, std::string>)
            return key == AscensionCompatConfig::REALM_TYPE ? RealmType : ClassModel;
        else if constexpr (std::is_same_v<T, uint32>)
        {
            if (key == AscensionCompatConfig::GAME_MODE_MASK)
                return GameModeMask;
            return key == AscensionCompatConfig::FIRST_EXTENSION_OPCODE ? 0x051F : 0x09D3;
        }
        else if (key == AscensionCompatConfig::UNLOCK_ALL_VANITY)
            return UnlockAllVanity;
        else if (key == AscensionCompatConfig::ALLOW_LEARNED_SPELL_DELIVERY)
            return LearnedSpellDelivery;
        else
            return true;
    }
} ascensionCompatConfig;

constexpr uint32 EXPANSION_CLASSIC = 0;
constexpr uint32 EXPANSION_THE_BURNING_CRUSADE = 1;
constexpr uint32 EXPANSION_WRATH_OF_THE_LICH_KING = 2;

struct RealmHandle
{
    uint32 Realm = 7;
};

struct
{
    RealmHandle Id;
    std::string Name = "Conquest of Azeroth";
} realm;

enum ServerConfigs
{
    CONFIG_MAX_PLAYER_LEVEL
};

struct World
{
    uint32 MaxPlayerLevel = 80;
    std::string GetRealmName() const { return "unset world realm name"; }
    uint32 getIntConfig(ServerConfigs) const { return MaxPlayerLevel; }
} world;

World* sWorld = &world;

struct PlayerCollectionState
{
    std::unordered_set<uint32> OwnedVanityItems;
    uint32 CosmeticTimer = 0;
};

struct VanityInfo
{
    uint32 LearnedSpell = 0;
};

struct AscensionClassService
{
    static AscensionClassService& Instance()
    {
        static AscensionClassService service;
        return service;
    }

    std::vector<uint32> Uploads;
    std::vector<uint32> Resets;

    void QueueKnownEntriesUpload(uint32 accountId, WorldPacket const&) { Uploads.push_back(accountId); }
    void QueueTalentReset(uint32 accountId) { Resets.push_back(accountId); }
    void SendInspectResult(Player*, ObjectGuid) { }
};

class AscensionDisplayPatchService
{
public:
    static AscensionDisplayPatchService& Instance()
    {
        static AscensionDisplayPatchService service;
        return service;
    }

    void SendPatchStream(Player*, bool = false) { }

    std::vector<uint32> ItemRequests;

    void SendItemRowOnDemand(Player*, uint32 entry) { ItemRequests.push_back(entry); }
};

namespace ItemScaling
{
std::vector<uint32> StatQueries;

void HandleStatQuery(WorldSession*, WorldPacket const& packet)
{
    if (packet.size() == sizeof(uint64))
        StatQueries.push_back(packet.read<uint32>(0));
}
}

namespace AscensionFreepick
{
bool MysticAltars = false;
bool RealmOffersMysticAltars() { return MysticAltars; }
}

class AscensionCollectionService
{
public:
    static AscensionCollectionService& Instance()
    {
        static AscensionCollectionService service;
        return service;
    }

    std::vector<uint16> AppearancePackets;

    void HandleApplyAppearances(Player*, WorldPacket& packet) { AppearancePackets.push_back(packet.GetOpcode()); }
    void HandleSaveOutfit(Player*, WorldPacket& packet) { AppearancePackets.push_back(packet.GetOpcode()); }
    void HandleDeleteOutfit(Player*, WorldPacket& packet) { AppearancePackets.push_back(packet.GetOpcode()); }
    void HandleSetAppearanceVisibility(Player*, WorldPacket& packet)
    {
        AppearancePackets.push_back(packet.GetOpcode());
    }
    void ProcessPendingAppearanceAdds(Player*, uint32) { }
    void ProcessPendingCompanionSpells(Player*, uint32) { }
    void ProcessCompanionLoot(Player*, uint32, bool = false) { }
    std::shared_ptr<PlayerCollectionState> GetState(Player*) { return State; }
    void RefreshCosmetics(Player*, PlayerCollectionState&) { }

    // ACTUAL_SEND_REALM_INFO
    // ACTUAL_SEND_GAME_MODE_STATE
    // ACTUAL_SEND_SECURE_ADDON_LIST
    // ACTUAL_QUEUE_CLIENT_PACKET
    // ACTUAL_REJECT_CLIENT_PACKET
    // ACTUAL_TAKE_CLIENT_PACKETS
    // ACTUAL_PENDING_OUTFIT
    // ACTUAL_ON_PLAYER_UPDATE
    // ACTUAL_HANDLE_CLIENT_PACKET
    // ACTUAL_POINT_SPEND
    // ACTUAL_DELIVER_VANITY
    // ACTUAL_WITHHELD_VANITY
    // ACTUAL_BANK_VANITY

    std::shared_ptr<PlayerCollectionState> State;
    std::unordered_map<uint32, VanityInfo> _vanityItems;
    std::mutex _packetMutex;
    std::mutex _outfitMutex;
    std::unordered_set<uint32> _pendingOutfitCommits;
    std::unordered_map<uint32, std::deque<WorldPacket>> _pendingPackets;
    std::mutex _rejectedPacketMutex;
    std::unordered_map<uint32, uint32> _rejectedPackets;
};

bool QueueAscensionDungeonDifficulty(WorldSession*, WorldPacket const&) { return false; }

struct AscensionCompatServerScript : ServerScript
{
    // ACTUAL_CAN_PACKET_RECEIVE_EARLY
    // ACTUAL_CAN_PACKET_SEND
};

struct AscensionCompatCommandScript
{
    // ACTUAL_LOCAL_TIME_COMMAND
};

struct RealmInfo
{
    uint32 Ruleset = 0;
    std::vector<uint8> Flags;
    std::string DataPath;
    std::string Name;
    uint8 AddOnsAllowed = 0;
    bool Complete = false;
};

std::string ReadString(WorldPacket& packet)
{
    std::string value;
    for (char c = char(packet.read<uint8>()); c; c = char(packet.read<uint8>()))
        value += c;
    return value;
}

RealmInfo Decode(WorldPacket packet)
{
    RealmInfo info;
    packet.rpos(0);
    packet.read_skip(sizeof(uint32));
    info.Ruleset = packet.read<uint32>();
    packet.read_skip(3 * sizeof(float) + sizeof(uint32) + 2 * sizeof(float) + sizeof(uint32));
    for (int flag = 0; flag < 8; ++flag)
        info.Flags.push_back(packet.read<uint8>());
    info.DataPath = ReadString(packet);
    info.Name = ReadString(packet);
    info.AddOnsAllowed = packet.read<uint8>();
    info.Complete = packet.rpos() == packet.size();
    return info;
}

RealmInfo SendRealmInfo(std::string const& realmType, std::string const& classModel)
{
    ascensionCompatConfig.RealmType = realmType;
    ascensionCompatConfig.ClassModel = classModel;
    WorldSession session;
    AscensionCollectionService::Instance().SendRealmInfo(&session);
    assert(session.Sent.size() == 1 && session.Sent[0].GetOpcode() == 0x09BC);
    return Decode(session.Sent[0]);
}

void TestRealmInfo()
{
    RealmInfo const live = SendRealmInfo("live", "coa");
    Check(live.Complete, "realm info ends one byte after its two strings");
    Check(live.DataPath.empty(), "realm info names no realm data path, so the client keeps its own archives");
    Check(live.Name == realm.Name && live.Name != sWorld->GetRealmName(),
        "realm info names the realm the auth database lists in the realm-name string");
    Check(live.AddOnsAllowed == 1, "realm info tells the stock client that add-ons are allowed");
    Check(live.Flags == std::vector<uint8>{1, 0, 0, 0, 0, 0, 1, 0}, "live CoA realm flags are unchanged");
    Check(live.Ruleset == EXPANSION_WRATH_OF_THE_LICH_KING, "a level-80 realm keeps the Wrath ruleset");
    world.MaxPlayerLevel = 70;
    Check(SendRealmInfo("seasonal", "coa").Ruleset == EXPANSION_THE_BURNING_CRUSADE,
        "a level-70 realm sends the Burning Crusade ruleset, whose level cap the client shows");
    world.MaxPlayerLevel = 60;
    Check(SendRealmInfo("seasonal", "coa").Ruleset == EXPANSION_CLASSIC,
        "a level-60 realm sends the Classic ruleset, whose level cap the client shows");
    world.MaxPlayerLevel = 80;

    bool allowedEverywhere = true;
    for (char const* realmType : {"live", "seasonal", "league", "ptr", "development"})
        for (char const* classModel : {"coa", "wcr", "classic"})
        {
            RealmInfo const info = SendRealmInfo(realmType, classModel);
            allowedEverywhere &= info.Complete && info.AddOnsAllowed == 1 && info.DataPath.empty() &&
                info.Name == realm.Name;
        }
    Check(allowedEverywhere, "every realm type and class model allows add-ons and names the realm");
}

std::vector<uint32> SentGameModes(uint32 mask)
{
    ascensionCompatConfig.GameModeMask = mask;
    WorldSession session;
    Player player;
    player.Session = &session;
    AscensionCollectionService::Instance().SendGameModeState(&player);
    std::vector<uint32> modes;
    for (WorldPacket packet : session.Sent)
    {
        packet.rpos(0);
        if (packet.GetOpcode() == 0x090B && packet.size() == sizeof(uint32))
            modes.push_back(packet.read<uint32>());
    }
    return modes;
}

void TestGameModeState()
{
    Check(SentGameModes(0) == std::vector<uint32>{0},
        "a realm without custom game modes still tells the client its mode is none");
    Check(SentGameModes(64) == std::vector<uint32>{64}, "a wildcard realm sends the wildcard game-mode bit");
    Check(SentGameModes(64 | 8) == std::vector<uint32>{72}, "combined game modes reach the client as one mask");
    ascensionCompatConfig.GameModeMask = 0;
}

bool Receive(WorldSession& session, WorldPacket const& packet)
{
    return AscensionCompatServerScript().CanPacketReceiveEarly(&session, packet);
}

WorldPacket ExtensionInitialized()
{
    WorldPacket packet(0x0561, 8);
    packet << uint32(0) << uint32(1);
    return packet;
}

bool TrustsHelpUi(WorldPacket packet)
{
    if (packet.GetOpcode() != 0x094E || packet.size() < sizeof(uint32))
        return false;
    packet.rpos(0);
    uint32 const count = packet.read<uint32>();
    bool helpUiSecure = false;
    for (uint32 i = 0; i < count; ++i)
    {
        std::string const name = ReadString(packet);
        uint8 const secure = packet.read<uint8>();
        helpUiSecure |= name == "Ascension_HelpUI" && secure == 1;
    }
    return helpUiSecure && packet.rpos() == packet.size();
}

void TestCharacterEnumeration()
{
    WorldSession session;
    bool const passedOn = Receive(session, WorldPacket(CMSG_CHAR_ENUM, 0));
    Check(passedOn, "character enumeration still reaches the core handler");
    Check(session.Sent.size() == 2 && session.Sent[0].GetOpcode() == 0x09BC && TrustsHelpUi(session.Sent[1]),
        "character enumeration sends realm info followed by the secure HelpUI addon list");
}

WorldPacket ApplyAppearances()
{
    WorldPacket packet(0x0697, 4);
    packet << uint32(0);
    return packet;
}

WorldPacket StoreQuery(uint32 store)
{
    WorldPacket packet(0x06B9, 4);
    packet << store;
    return packet;
}

WorldPacket StorePurchase(uint32 key, uint32 quantity)
{
    WorldPacket packet(0x06BB, 8);
    packet << key << quantity;
    return packet;
}

void TestStorePackets()
{
    AscensionCollectionService& service = AscensionCollectionService::Instance();
    WorldSession session;
    Player player;
    player.Session = &session;
    session.PlayerObject = &player;
    DispatchedOpcodes.clear();

    bool const queryPassedOn = Receive(session, StoreQuery(7));
    bool const purchasePassedOn = Receive(session, StorePurchase(9, 1));
    Check(!queryPassedOn && !purchasePassedOn && session.Sent.empty() && DispatchedOpcodes.empty(),
        "the socket hook queues store queries and purchases without running a store handler");
    service.OnPlayerUpdate(&player, 1);
    Check(DispatchedOpcodes == std::vector<uint16>{0x06B9, 0x06BB} && session.Sent.size() == 1 &&
            session.Sent[0].GetOpcode() == 0x06BA,
        "the player update runs the store handlers in order and answers an unclaimed query with an empty store");

    WorldSession glue;
    DispatchedOpcodes.clear();
    bool const glueQueryPassedOn = Receive(glue, StoreQuery(7));
    bool const gluePurchasePassedOn = Receive(glue, StorePurchase(9, 1));
    service.OnPlayerUpdate(&player, 1);
    Check(!glueQueryPassedOn && !gluePurchasePassedOn && DispatchedOpcodes.empty() && glue.Sent.size() == 1 &&
            glue.Sent[0].GetOpcode() == 0x06BA,
        "before login a store query gets the empty store at once and a purchase is dropped, not queued");
}

void TestItemStatQueryQueue()
{
    AscensionCollectionService& service = AscensionCollectionService::Instance();
    WorldSession session;
    Player player;
    player.Session = &session;
    session.PlayerObject = &player;
    ItemScaling::StatQueries.clear();
    WorldPacket query(0x06FF, 8);
    query << uint32(720) << uint32(58);
    Check(!Receive(session, query) && ItemScaling::StatQueries.empty(),
        "item-stat queries are consumed and queued without executing on the socket thread");
    service.OnPlayerUpdate(&player, 1);
    Check(ItemScaling::StatQueries == std::vector<uint32>{720},
        "the player update forwards the item-stat query to the scaling service");
}

void TestBotAltRequests()
{
    AscensionCollectionService& service = AscensionCollectionService::Instance();
    WorldSession session;
    session.AccountId = 77;
    Player player;
    player.Session = &session;
    session.PlayerObject = &player;
    WorldSession botSession;
    botSession.AccountId = 77;
    botSession.Bot = true;
    Player bot;
    bot.Session = &botSession;
    botSession.PlayerObject = &bot;
    service.AppearancePackets.clear();

    WorldPacket save(0x069E, 16);
    save << std::string("Plate") << uint32(0);
    for (WorldPacket const& packet : {ApplyAppearances(), save, ExtensionInitialized(), StoreQuery(7)})
        Receive(session, packet);
    DispatchedOpcodes.clear();
    service.OnPlayerUpdate(&bot, 1);
    Check(service.AppearancePackets.empty() && DispatchedOpcodes.empty() && !bot.ChargeSnapshots &&
            botSession.Sent.empty(),
        "a bot alt of the same account leaves the player's requests queued");
    service.OnPlayerUpdate(&player, 1);
    Check(service.AppearancePackets == std::vector<uint16>{0x0697, 0x069E} && player.ChargeSnapshots == 1 &&
            DispatchedOpcodes == std::vector<uint16>{0x06B9} && session.Sent.size() == 2 &&
            TrustsHelpUi(session.Sent[0]) && session.Sent[1].GetOpcode() == 0x06BA,
        "the player's next update then handles every request of the account in order");
}

void TestWorldEntryResend()
{
    AscensionCollectionService& service = AscensionCollectionService::Instance();
    WorldSession session;
    Player player;
    player.Session = &session;

    bool const passedOn = Receive(session, ExtensionInitialized());
    Check(!passedOn && session.Sent.empty() && !player.ChargeSnapshots,
        "the socket hook consumes the world-entry notice and answers nothing itself");
    service.OnPlayerUpdate(&player, 1);
    Check(player.ChargeSnapshots == 1 && player.EchoSnapshots == 1,
        "the next world update resends the charge snapshot and the Runemaster echoes");
    Check(session.Sent.size() == 1 && TrustsHelpUi(session.Sent[0]),
        "the next world update trusts HelpUI with the client's count, name and secure-flag layout");

    bool consumed = true;
    for (int worldEntry = 0; worldEntry < 3; ++worldEntry)
    {
        consumed &= !Receive(session, ExtensionInitialized());
        service.OnPlayerUpdate(&player, 1);
    }
    Check(consumed && player.ChargeSnapshots == 4 && player.EchoSnapshots == 4,
        "login, loading screens and reloads each get their own resend");
    Check(session.Sent.size() == 4 && std::all_of(session.Sent.begin(), session.Sent.end(), TrustsHelpUi),
        "every extension initialization restores the secure HelpUI addon list");

    uint32 const charges = player.ChargeSnapshots;
    uint32 const echoes = player.EchoSnapshots;
    std::size_t const addonLists = session.Sent.size();
    WorldPacket poll(0x0745, 0);
    Check(!Receive(session, poll), "other extension notices stay consumed");
    service.OnPlayerUpdate(&player, 1);
    Check(player.ChargeSnapshots == charges && player.EchoSnapshots == echoes && session.Sent.size() == addonLists,
        "other extension notices resend nothing");

    WorldPacket visibility(0x06A3, 2);
    visibility << uint8(1) << uint8(1);
    Receive(session, ApplyAppearances());
    Receive(session, visibility);
    service.OnPlayerUpdate(&player, 1);
    Check(service.AppearancePackets == std::vector<uint16>{0x0697, 0x06A3},
        "appearance packets still reach the world thread in order");

    for (int notice = 0; notice < 200; ++notice)
        Receive(session, ExtensionInitialized());
    Receive(session, ApplyAppearances());
    service.OnPlayerUpdate(&player, 1);
    Check(player.ChargeSnapshots == charges + 1 && player.EchoSnapshots == echoes + 1,
        "notices that arrive before the same world update share one resend");
    Check(session.Sent.size() == addonLists + 1 && TrustsHelpUi(session.Sent.back()),
        "duplicate initialization notices share one secure-addon resend");
    Check(service.AppearancePackets == std::vector<uint16>{0x0697, 0x06A3, 0x0697},
        "repeated notices do not fill the queue and crowd out later packets");

    WorldPacket save(0x069E, 16);
    save << std::string("Plate") << uint32(0);
    WorldPacket remove(0x06A0, 8);
    remove << std::string("Plate");
    bool const outfitsConsumed = !Receive(session, save) && !Receive(session, remove);
    service.OnPlayerUpdate(&player, 1);
    Check(outfitsConsumed && service.AppearancePackets ==
            std::vector<uint16>{0x0697, 0x06A3, 0x0697, 0x069E},
        "a queued outfit save leaves the following delete for a later update");
    Check(service.TakeClientPackets(session.GetAccountId(), true).empty(),
        "a pending outfit commit leaves the next outfit request queued");
    service.OnPlayerUpdate(&player, 1);
    Check(outfitsConsumed && service.AppearancePackets ==
            std::vector<uint16>{0x0697, 0x06A3, 0x0697, 0x069E, 0x06A0},
        "outfit save and delete requests are consumed and handled on the world thread in order");
}

WorldPacket BulkQuery(std::vector<uint32> const& entries, uint32 count, uint16 opcode = 0x061B)
{
    WorldPacket packet(opcode, sizeof(uint32) * (entries.size() + 1));
    packet << count;
    for (uint32 entry : entries)
        packet << entry;
    return packet;
}

WorldPacket BulkQuery(std::vector<uint32> const& entries)
{
    return BulkQuery(entries, uint32(entries.size()));
}

std::vector<uint8> Bytes(WorldPacket const& packet)
{
    std::vector<uint8> bytes(packet.size());
    for (std::size_t index = 0; index < packet.size(); ++index)
        bytes[index] = packet[index];
    return bytes;
}

std::vector<uint8> SingleQueryReply(uint32 entry, int localeIndex)
{
    WorldSession session;
    session.LocaleIndex = localeIndex;
    WorldPacket query(0x0056, 4);
    query << entry;
    session.HandleItemQuerySingleOpcode(query);
    assert(session.Sent.size() == 1 && session.Sent[0].GetOpcode() == SMSG_ITEM_QUERY_SINGLE_RESPONSE);
    return Bytes(session.Sent[0]);
}

std::vector<std::vector<uint8>> BulkReplies(WorldSession& session, Player& player, WorldPacket const& query)
{
    session.Sent.clear();
    bool const passedOn = Receive(session, query);
    bool const answeredOnSocket = !session.Sent.empty();
    AscensionCollectionService::Instance().OnPlayerUpdate(&player, 1);
    std::vector<std::vector<uint8>> replies;
    for (WorldPacket const& packet : session.Sent)
        replies.push_back(packet.GetOpcode() == SMSG_ITEM_QUERY_SINGLE_RESPONSE ? Bytes(packet) : std::vector<uint8>{});
    if (passedOn || answeredOnSocket)
        replies.push_back({});
    return replies;
}

void TestItemQueries()
{
    ItemTemplate& blade = objectMgr.Items[35];
    blade.ItemId = 35;
    blade.Class = 2;
    blade.SubClass = 7;
    blade.SoundOverrideSubclass = -1;
    blade.Name1 = "Test Blade";
    blade.Description = "Sharp";
    blade.Spells[0].SpellId = 133;
    blade.Spells[0].SpellCooldown = -1;
    blade.Spells[0].SpellCategoryCooldown = -1;
    ItemTemplate& cloak = objectMgr.Items[135522];
    cloak.ItemId = 135522;
    cloak.Class = 4;
    cloak.Name1 = "Ascension Appearance 135522";
    objectMgr.Locales[35].Name = {"", "", "Testklinge"};

    WorldSession session;
    Player player;
    player.Session = &session;

    session.PlayerObject = &player;
    auto& itemPatches = AscensionDisplayPatchService::Instance().ItemRequests;
    itemPatches.clear();
    std::vector<std::vector<uint8>> const replies = BulkReplies(session, player, BulkQuery({35, 999999, 135522}));
    std::vector<uint8> const unknown = {0x3F, 0x42, 0x0F, 0x80};
    Check(replies.size() == 3 && replies[0] == SingleQueryReply(35, -1) && replies[1] == unknown &&
        replies[2] == SingleQueryReply(135522, -1),
        "a bulk item query answers each entry in order with the stock single-item response");
    Check(itemPatches == std::vector<uint32>{35, 999999 | 0x80000000u, 135522},
        "bulk responses reach the demand-patch hook in order, including the native unknown-item marker");

    WorldPacket first(SMSG_ITEM_QUERY_SINGLE_RESPONSE, 0);
    if (!replies.empty())
        first.append(replies[0].data(), replies[0].size());
    first.rpos(0);
    bool const stockLayout = first.size() > 16 && first.read<uint32>() == 35 && first.read<uint32>() == 2 &&
        first.read<uint32>() == 7 && first.read<int32>() == -1 && ReadString(first) == "Test Blade";
    Check(stockLayout, "the reply starts with the stock entry, class, subclass, sound and name fields");

    session.LocaleIndex = 2;
    std::vector<std::vector<uint8>> const localized = BulkReplies(session, player, BulkQuery({35}));
    Check(localized.size() == 1 && localized[0] == SingleQueryReply(35, 2) && localized[0] != SingleQueryReply(35, -1),
        "bulk replies use the session locale like single queries");
    session.LocaleIndex = -1;

    std::vector<uint32> full(50);
    for (uint32 index = 0; index < full.size(); ++index)
        full[index] = index % 2 ? 35 : 135522;
    Check(BulkReplies(session, player, BulkQuery(full)).size() == 50,
        "the client's largest batch of 50 entries is answered");

    std::size_t const patchRequestsBeforeMalformed = itemPatches.size();
    bool rejected = true;
    for (WorldPacket const& malformed : {BulkQuery({}), BulkQuery(std::vector<uint32>(51, 35)),
            BulkQuery({35}, 2), BulkQuery({35, 36}, 1), WorldPacket(0x061B, 0)})
        rejected &= BulkReplies(session, player, malformed).empty();
    WorldPacket shortCount(0x061B, 3);
    shortCount << uint8(1) << uint8(0) << uint8(0);
    rejected &= BulkReplies(session, player, shortCount).empty();
    Check(rejected, "empty, oversized, truncated and padded batches are consumed without replies");
    Check(itemPatches.size() == patchRequestsBeforeMalformed,
        "malformed item queries do not reach the demand-patch service");

    AscensionCollectionService& service = AscensionCollectionService::Instance();
    session.Sent.clear();
    for (int batch = 0; batch < 64; ++batch)
        Receive(session, BulkQuery(full));
    std::size_t largestUpdate = 0;
    for (int update = 0; update < 30; ++update)
    {
        std::size_t const before = session.Sent.size();
        service.OnPlayerUpdate(&player, 1);
        largestUpdate = std::max(largestUpdate, session.Sent.size() - before);
    }
    bool inOrder = session.Sent.size() == 64 * full.size();
    for (std::size_t index = 0; inOrder && index < session.Sent.size(); ++index)
        inOrder = session.Sent[index].read<uint32>(0) == full[index % full.size()];
    Check(largestUpdate == 150 && inOrder,
        "a flood of item batches gets at most 150 replies per world update and every reply in order");

    std::size_t const appearances = service.AppearancePackets.size();
    for (int batch = 0; batch < 3; ++batch)
        Receive(session, BulkQuery(full));
    Receive(session, ApplyAppearances());
    service.OnPlayerUpdate(&player, 1);
    bool const waited = service.AppearancePackets.size() == appearances;
    service.OnPlayerUpdate(&player, 1);
    Check(waited && service.AppearancePackets.size() == appearances + 1,
        "packets behind a full update budget keep their place for the next update");

    answeredCreatures.clear();
    bool const creaturesPassedOn = Receive(session, BulkQuery({44472, 1234}, 2, 0x061A));
    bool const malformedPassedOn = Receive(session, BulkQuery({44472}, 2, 0x061A));
    bool const oversizedPassedOn = Receive(session, BulkQuery(std::vector<uint32>(51, 44472), 51, 0x061A));
    bool const answeredEarly = !answeredCreatures.empty();
    service.OnPlayerUpdate(&player, 1);
    Check(!creaturesPassedOn && !malformedPassedOn && !oversizedPassedOn && !answeredEarly &&
        answeredCreatures == std::vector<uint32>{44472, 1234},
        "creature bulk queries are validated early and answered on the next world update");

    answeredCreatures.clear();
    std::vector<uint32> creatures(50);
    for (uint32 index = 0; index < creatures.size(); ++index)
        creatures[index] = 44472 + index;
    for (int batch = 0; batch < 64; ++batch)
        Receive(session, BulkQuery(creatures, 50, 0x061A));
    std::size_t largestCreatureUpdate = 0;
    for (int update = 0; update < 30; ++update)
    {
        std::size_t const before = answeredCreatures.size();
        service.OnPlayerUpdate(&player, 1);
        largestCreatureUpdate = std::max(largestCreatureUpdate, answeredCreatures.size() - before);
    }
    bool creaturesInOrder = answeredCreatures.size() == 64 * creatures.size();
    for (std::size_t index = 0; creaturesInOrder && index < answeredCreatures.size(); ++index)
        creaturesInOrder = answeredCreatures[index] == creatures[index % creatures.size()];
    Check(largestCreatureUpdate == 150 && creaturesInOrder,
        "a flood of creature batches gets at most 150 replies per world update and every reply in order");
}

enum VanityCurrency : uint8
{
    SeasonalPoints = 1,
    DonationPoints = 2,
    BazaarTokens = 3
};

WorldPacket PointSpend(uint8 currency, uint32 itemId)
{
    WorldPacket packet(0x0523, 5);
    packet << currency << itemId;
    return packet;
}

WorldPacket DonationPointsRequest(uint32 itemId)
{
    return PointSpend(DonationPoints, itemId);
}

struct Delivery
{
    std::vector<uint32> Stored;
    std::vector<uint32> Learned;
    std::vector<std::string> Messages;
    uint32 EquipErrors = 0;
    uint32 NewItemNotices = 0;
    std::vector<uint32> Reported;

    bool operator==(Delivery const&) const = default;
};

struct VanitySetup
{
    bool UnlockAll = true;
    bool LearnedSpellDelivery = true;
    bool BagsFull = false;
    bool MysticAltars = false;
};

Delivery Deliver(VanitySetup const& setup, std::vector<WorldPacket> const& requests, uint32 directItem = 0)
{
    ascensionCompatConfig.UnlockAllVanity = setup.UnlockAll;
    ascensionCompatConfig.LearnedSpellDelivery = setup.LearnedSpellDelivery;
    AscensionFreepick::MysticAltars = setup.MysticAltars;
    AscensionCollectionService& service = AscensionCollectionService::Instance();
    scriptMgr.Progress.clear();
    service.State = std::make_shared<PlayerCollectionState>();
    service.State->OwnedVanityItems = {1001, 1003, 1004, 56925, 134985};
    WorldSession session;
    Player player;
    player.Session = &session;
    player.BagsFull = setup.BagsFull;
    session.PlayerObject = &player;
    if (directItem)
        service.DeliverVanityItem(&player, directItem);
    bool consumed = true;
    for (WorldPacket const& request : requests)
        consumed &= !Receive(session, request);
    service.OnPlayerUpdate(&player, 1);
    service.State.reset();
    assert(consumed);
    std::vector<uint32> reported;
    for (auto const& [event, value] : scriptMgr.Progress)
        if (event == CoAProgressEvent::VanityDelivered)
            reported.push_back(value);
    return {player.Stored, player.Learned, session.Messages, player.EquipErrors, player.NewItemNotices, reported};
}

void TestVanityDelivery()
{
    for (uint32 itemId : {1001u, 1002u, 56925u, 110000u, 134985u})
    {
        ItemTemplate& item = objectMgr.Items[itemId];
        item.ItemId = itemId;
        item.Name1 = "Vanity";
    }
    objectMgr.Items[110000].Spells[0].SpellId = 200001;
    objectMgr.Items[134985].Spells[0].SpellId = 200002;
    AscensionCollectionService& service = AscensionCollectionService::Instance();
    for (uint32 itemId : {1001u, 1002u, 1003u, 1004u, 56925u, 110000u, 134985u})
        service._vanityItems[itemId] = {};
    service._vanityItems[1003].LearnedSpell = 133;

    bool matches = true;
    for (bool unlockAll : {true, false})
        for (bool learnedSpells : {true, false})
            for (bool bagsFull : {false, true})
                for (uint32 itemId : {1001u, 1002u, 1003u, 1004u, 56925u, 110000u, 134985u, 424242u})
                {
                    VanitySetup const setup{unlockAll, learnedSpells, bagsFull};
                    matches &= Deliver(setup, {DonationPointsRequest(itemId)}) == Deliver(setup, {}, itemId);
                }
    Check(matches,
        "every Donation Points request (Deliver or web-shop buy) ends exactly like a delivery of the same item");

    Delivery const owned = Deliver({}, {DonationPointsRequest(1001)});
    Delivery const bank = Deliver({}, {DonationPointsRequest(134985)});
    Delivery const spell = Deliver({}, {DonationPointsRequest(1003)});
    Check(owned.Stored == std::vector<uint32>{1001} && owned.NewItemNotices == 1 &&
        bank.Stored == std::vector<uint32>{134985} && bank.Learned == std::vector<uint32>{200002} &&
        spell.Learned == std::vector<uint32>{133},
        "Donation Points requests deliver owned items, banks and learned spells");
    Check(owned.Reported == std::vector<uint32>{1001} && bank.Reported == std::vector<uint32>{134985} &&
        spell.Reported == std::vector<uint32>{1003},
        "each delivered vanity item or spell is reported once as progress");

    constexpr uint32 altar = 2903513;
    objectMgr.Items[altar].ItemId = altar;
    service._vanityItems[altar] = {};
    Delivery const withheld = Deliver({}, {DonationPointsRequest(altar)});
    Check(withheld.Stored.empty() && withheld.Learned.empty() && withheld.Reported.empty() &&
        withheld.Messages == std::vector<std::string>{"Mystic Enchanting altars are not available on this realm."},
        "Mystic altars are withheld when the realm does not offer them");
    Delivery const allowed = Deliver({true, true, false, true}, {DonationPointsRequest(altar)});
    Check(allowed.Stored == std::vector<uint32>{altar} && allowed.Reported == std::vector<uint32>{altar},
        "Mystic altars are delivered when the realm offers them");

    VanitySetup const locked{false, true, false};
    Delivery const refused = Deliver(locked, {DonationPointsRequest(1002), DonationPointsRequest(56925),
        DonationPointsRequest(110000), DonationPointsRequest(424242), DonationPointsRequest(1004)});
    Delivery const full = Deliver({true, true, true}, {DonationPointsRequest(1001)});
    Check(refused.Stored.empty() && refused.Learned.empty() && refused.Messages.size() == 5 &&
        full.Stored.empty() && full.EquipErrors == 1 && refused.Reported.empty() && full.Reported.empty(),
        "locked, sigil, unowned bank, unknown and templateless items and full bags are refused");

    WorldPacket shortRequest(0x0523, 4);
    shortRequest << uint32(1001);
    WorldPacket longRequest = DonationPointsRequest(1001);
    longRequest << uint8(0);
    Delivery const ignored = Deliver({}, {PointSpend(SeasonalPoints, 1001), PointSpend(0, 1001),
        PointSpend(BazaarTokens, 1001), shortRequest, longRequest, WorldPacket(0x0523, 0)});
    Check(ignored == Delivery{},
        "Seasonal Points, Bazaar Tokens, unknown currencies and malformed requests deliver nothing");
}
}

void WorldSession::SendPacket(WorldPacket const* packet)
{
    AscensionCompatServerScript script;
    if (script.CanPacketSend(this, *packet))
        Sent.push_back(*packet);
}

struct ClientClock
{
    bool Sent = false;
    bool Complete = false;
    std::tm Shown{};
    float Speed = 0.0f;
    uint32 Trailer = 1;
    std::size_t Messages = 0;
};

ClientClock LocalTime(Optional<uint8> hour = {}, Optional<uint8> minute = {})
{
    WorldSession session;
    Player player;
    player.Session = &session;
    session.PlayerObject = &player;
    ChatHandler handler(&session);
    AscensionCompatCommandScript::HandleLocalTimeCommand(&handler, hour, minute);

    ClientClock clock;
    clock.Messages = session.Messages.size();
    if (session.Sent.size() != 1 || session.Sent[0].GetOpcode() != SMSG_LOGIN_SETTIMESPEED)
        return clock;

    WorldPacket packet = session.Sent[0];
    packet.rpos(0);
    uint32 const packed = packet.read<uint32>();
    clock.Sent = true;
    clock.Shown.tm_year = int((packed >> 24) & 0x1F) + 100;
    clock.Shown.tm_mon = int((packed >> 20) & 0xF);
    clock.Shown.tm_mday = int((packed >> 14) & 0x3F) + 1;
    clock.Shown.tm_hour = int((packed >> 6) & 0x1F);
    clock.Shown.tm_min = int(packed & 0x3F);
    clock.Speed = packet.read<float>();
    clock.Trailer = packet.read<uint32>();
    clock.Complete = packet.rpos() == packet.size();
    return clock;
}

bool ShowsDay(ClientClock const& clock, std::tm const& day)
{
    return clock.Shown.tm_year == day.tm_year && clock.Shown.tm_mon == day.tm_mon && clock.Shown.tm_mday == day.tm_mday;
}

void TestLocalTime()
{
    std::tm night{};
    night.tm_year = 126;
    night.tm_mon = 8;
    night.tm_mday = 23;
    night.tm_hour = 22;
    night.tm_min = 40;
    night.tm_sec = 15;
    night.tm_isdst = -1;
    gameTime = std::mktime(&night);

    ClientClock const noon = LocalTime(uint8(12), uint8(30));
    Check(noon.Sent && noon.Complete && ShowsDay(noon, night) && noon.Shown.tm_hour == 12 && noon.Shown.tm_min == 30,
        ".localtime 12 30 sends the client 12:30 on the server's current day");
    Check(noon.Speed == 0.01666667f && noon.Trailer == 0,
        ".localtime keeps the login packet's real-time clock speed");

    ClientClock const morning = LocalTime(uint8(6));
    Check(morning.Sent && ShowsDay(morning, night) && morning.Shown.tm_hour == 6 && morning.Shown.tm_min == 0,
        ".localtime 6 starts the hour at minute zero");

    bool everyTime = true;
    for (uint8 hour = 0; hour < 24; ++hour)
        for (uint8 minute : {uint8(0), uint8(59)})
        {
            ClientClock const clock = LocalTime(hour, minute);
            everyTime &= clock.Sent && ShowsDay(clock, night) && clock.Shown.tm_hour == hour &&
                clock.Shown.tm_min == minute;
        }
    Check(everyTime, "every hour from 0 to 23 reaches the client unchanged");

    ClientClock const server = LocalTime();
    Check(server.Sent && server.Complete && ShowsDay(server, night) && server.Shown.tm_hour == 22 &&
        server.Shown.tm_min == 40,
        ".localtime without arguments returns the client to the server clock");

    ClientClock const lateHour = LocalTime(uint8(24));
    ClientClock const lateMinute = LocalTime(uint8(12), uint8(60));
    Check(!lateHour.Sent && !lateMinute.Sent && lateHour.Messages == 1 && lateMinute.Messages == 1,
        "hours past 23 and minutes past 59 are refused without a packet");
}

int WarningsFrom(uint32 accountId, int repeats, std::vector<WorldPacket> const& packets)
{
    WorldSession session;
    session.AccountId = accountId;
    Player player;
    player.Session = &session;
    int const before = warnings;
    for (int repeat = 0; repeat < repeats; ++repeat)
        for (WorldPacket const& packet : packets)
            Receive(session, packet);
    for (int update = 0; update < 4; ++update)
        AscensionCollectionService::Instance().OnPlayerUpdate(&player, 1);
    return warnings - before;
}

void TestRejectedPacketWarnings()
{
    WorldPacket shortRequest(0x0523, 4);
    shortRequest << uint32(1001);
    int const malformedQueries = WarningsFrom(20, 1000, {BulkQuery({35}, 2), BulkQuery({44472}, 2, 0x061A)});
    int const overflow = WarningsFrom(21, 1064, {ApplyAppearances()});
    int const malformedSpends = WarningsFrom(22, 64, {shortRequest});
    Check(malformedQueries == 11, "2000 malformed bulk queries log 11 warnings, at 1, 2, 4 ... 1024 rejections");
    Check(overflow == 10, "1000 packets dropped from a full queue log 10 warnings");
    Check(malformedSpends == 7, "64 malformed point spend requests log 7 warnings");
}

void TestTalentRequests()
{
    AscensionClassService& service = AscensionClassService::Instance();
    WorldSession session;
    WorldPacket upload(0x0727, 4);
    upload << uint32(0);
    WorldPacket reset(CMSG_UNLEARN_TALENTS, 0);
    bool const consumed = !Receive(session, upload) && !Receive(session, reset);
    Check(consumed && service.Uploads == std::vector<uint32>{session.GetAccountId()} &&
        service.Resets == std::vector<uint32>{session.GetAccountId()},
        "the native known-entries upload and talent reset are consumed and queued for the account");
}

void TestCoreHandledRequests()
{
    WorldSession session;
    Check(Receive(session, WorldPacket(CMSG_RESET_DUNGEONS, 0)),
        "the portrait menu's reset all dungeons reaches the core handler");
    Check(Receive(session, WorldPacket(CMSG_PORT_GRAVEYARD, 0)),
        "the ghost frame's return to graveyard reaches the core handler");
    Check(Receive(session, WorldPacket(CMSG_TAXI_REQUEST_EARLY_LANDING, 0)),
        "the flight's early landing request reaches the core handler");
    WorldPacket deletePet(CMSG_STABLE_DELETE_PET, 4);
    deletePet << uint32(1);
    Check(Receive(session, deletePet), "the stable window's delete request reaches the core handler");
    Check(Receive(session, WorldPacket(CMSG_QUERY_INSTANCE_BINDS, 0)),
        "the instance bind query reaches the core handler");
    WorldPacket resetInstance(CMSG_RESET_INSTANCE, 5);
    resetInstance << uint32(36) << uint8(0);
    Check(Receive(session, resetInstance), "the single instance reset reaches the core handler");
    Check(session.Sent.empty(), "the early hook answers none of the requests the core handles");
}

int main()
{
    TestRealmInfo();
    TestGameModeState();
    TestCharacterEnumeration();
    TestWorldEntryResend();
    TestStorePackets();
    TestItemStatQueryQueue();
    TestBotAltRequests();
    TestTalentRequests();
    TestCoreHandledRequests();
    TestItemQueries();
    TestVanityDelivery();
    TestRejectedPacketWarnings();
    TestLocalTime();
    std::cout << checks - failures << '/' << checks << " checks passed\n";
    return failures ? 1 : 0;
}
