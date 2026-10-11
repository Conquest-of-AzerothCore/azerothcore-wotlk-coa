#include "ADVERTISING_HEADER"
#include "RULES_HEADER"
#include "TaskScheduler.h"
#include <algorithm>
#include <memory>
#include <set>
#include <sstream>
#include <stdexcept>
#include <vector>

namespace
{
using uint8 = uint8_t;
using int32 = int32_t;
using uint64 = uint64_t;
using namespace CoALottery;
namespace Acore
{
    template<typename... Args> std::string StringFormat(std::string text, Args const&... args)
    {
        std::array<std::string, sizeof...(Args)> values{([&] {std::ostringstream out; out << args; return out.str();}())...};
        size_t position = 0;
        for (auto const& value : values)
        {
            position = text.find("{}", position);
            if (position == std::string::npos) throw std::runtime_error("format mismatch");
            text.replace(position, 2, value);
            position += value.size();
        }
        return text;
    }
}

constexpr uint32 REACT_PASSIVE = 0, CHAT_MSG_MONSTER_YELL = 14, LANG_UNIVERSAL = 0, TEXT_RANGE_ZONE = 2;
using LocaleConstant = uint32;
struct ObjectGuid
{
    uint32 value = 0;
    bool IsEmpty() const {return value == 0;}
    void Clear() {value = 0;}
    bool operator==(ObjectGuid const&) const = default;
};
struct Position {float x, y, z, o;};
struct GameObject
{
    bool active = false, despawned = false, removed = false;
    void setActive(bool value) {active = value;}
    void DespawnOrUnsummon() {despawned = true;}
    void AddObjectToRemoveList() {removed = true;}
};
std::vector<std::pair<uint32, Position>> bursts;
std::vector<std::unique_ptr<GameObject>> burstObjects;
struct Creature
{
    ObjectGuid guid;
    bool alive = true, removed = false, active = false;
    float scale = 1.0f;
    float GetPositionX() const {return GallywixX;}
    float GetPositionY() const {return GallywixY;}
    float GetPositionZ() const {return GallywixZ;}
    GameObject* SummonGameObject(uint32 entry, float x, float y, float z, float o,
        float, float, float, float, uint32)
    {
        bursts.push_back({entry, {x, y, z, o}});
        burstObjects.push_back(std::make_unique<GameObject>());
        return burstObjects.back().get();
    }
    void SetObjectScale(float value) {scale = value;}
    virtual ~Creature() = default;
    bool IsAlive() const {return alive;}
    void DespawnOrUnsummon() {removed = true;}
    ObjectGuid GetGUID() const {return guid;}
    uint32 GetZoneId() const {return 1519;}
    void setActive(bool value) {active = value;}
    void SetReactState(uint32) {}
    void SetLootRewardDisabled(bool) {}
    void SetReputationRewardDisabled(bool) {}
};
struct TempSummon : Creature {};
struct Session {bool bot = false; bool IsBot() const {return bot;}};
struct Player
{
    std::string name;
    uint32 zone = 1519;
    float distance = 20;
    bool gm = false, visible = true, inWorld = true;
    Session session;
    uint32 received = 0;
    bool IsInWorld() const {return inWorld;}
    bool IsGameMaster() const {return gm;}
    bool isGMVisible() const {return visible;}
    Session* GetSession() {return &session;}
    uint32 GetZoneId() const {return zone;}
    bool IsWithinDistInMap(Creature*, float radius) const {return distance <= radius;}
    std::string GetName() const {return name;}
};
struct PlayerRef {Player* player; Player* GetSource() const {return player;}};
struct Map
{
    std::unique_ptr<TempSummon> creature;
    std::unique_ptr<TempSummon> goldilocks;
    Position goldilocksPosition{};
    uint32 goldilocksSpawned = 0;
    std::vector<PlayerRef> players;
    Position position{};
    uint32 spawned = 0, loaded = 0;
    Creature* GetCreature(ObjectGuid guid)
    {
        if (creature && !creature->removed && creature->guid == guid) return creature.get();
        return goldilocks && !goldilocks->removed && goldilocks->guid == guid ? goldilocks.get() : nullptr;
    }
    void LoadGrid(float x, float y)
    {
        if ((x != GallywixX || y != GallywixY) && (x != GoldilocksX || y != GoldilocksY) &&
            (x != OrgrimmarLotteryLocation.gallywixX || y != OrgrimmarLotteryLocation.gallywixY) &&
            (x != OrgrimmarLotteryLocation.goldilocksX || y != OrgrimmarLotteryLocation.goldilocksY)) throw std::runtime_error("wrong spawn grid");
        ++loaded;
    }
    TempSummon* SummonCreature(uint32 entry, Position pos)
    {
        if (entry == GoldilocksEntry)
        {
            ++goldilocksSpawned;
            goldilocks = std::make_unique<TempSummon>();
            goldilocks->guid.value = 10000 + goldilocksSpawned;
            goldilocksPosition = pos;
            return goldilocks.get();
        }
        if (entry != GallywixEntry) throw std::runtime_error("wrong NPC entry");
        ++spawned;
        creature = std::make_unique<TempSummon>();
        creature->guid.value = spawned;
        position = pos;
        return creature.get();
    }
    auto const& GetPlayers() const {return players;}
} mockMap, mockHordeMap;
struct MapMgr
{
    Map* FindMap(uint32 id, uint32 instance) {return instance != 0 ? nullptr : id == 0 ? &mockMap : id == 1 ? &mockHordeMap : nullptr;}
    Map* CreateBaseMap(uint32 id) {return id == 0 ? &mockMap : id == 1 ? &mockHordeMap : nullptr;}
} mapMgr;
auto* sMapMgr = &mapMgr;
struct ObjectMgr {bool available = true; bool GetCreatureTemplate(uint32) const {return available;}
    bool GetGameObjectTemplate(uint32) const {return available;}} objectMgr;
auto* sObjectMgr = &objectMgr;
struct WorldPacket {std::string message; ObjectGuid sender; uint32 type = 0;};
struct ChatHandler
{
    static size_t BuildChatPacket(WorldPacket& packet, uint32 type, uint32 language, Creature* creature,
        void*, std::string const& message, uint32, char const*, LocaleConstant)
    {
        if (language != LANG_UNIVERSAL) throw std::runtime_error("wrong language");
        packet.message = message;
        packet.sender = creature->GetGUID();
        packet.type = type;
        return 0;
    }
};
struct TextMgr
{
    std::vector<WorldPacket> yells;
    template<class Builder> void SendChatPacket(Creature* source, Builder const& builder, uint32 type, void*, uint32 range)
    {
        if (range != TEXT_RANGE_ZONE || type != CHAT_MSG_MONSTER_YELL) throw std::runtime_error("not a zone yell");
        WorldPacket packet;
        builder(&packet, 0);
        yells.push_back(packet);
        for (auto const& ref : mockMap.players)
            if (ref.player->zone == source->GetZoneId()) ++ref.player->received;
    }
} textMgr;
auto* sCreatureTextMgr = &textMgr;
struct Settings
{
    bool enabled = true, spawnGallywix = true, spawnGoldilocks = true, advertise = true;
    uint32 advertisementInterval = 1800, advertisementPlayerRadius = 60;
} settings;
struct Round {uint64 ends = 9999999, id = 1; uint32 pot = 10000000, duration = 604800;} round;
bool ready = true;
uint64 now = 1000;
uint64 Now() {return now;}
ADVERTISER_CLASS
void Require(bool value) {if (!value) throw std::runtime_error("lottery advertising assertion failed");}
void Run()
{
    Require(!AdvertisementLines.empty());
    Require(AdvertisementTime(6 * 86400 + 123) == "6 days");
    Require(AdvertisementTime(86401) == "1 day");
    Require(AdvertisementTime(86400) == "24 hours");
    Require(AdvertisementTime(7200) == "2 hours");
    Require(AdvertisementTime(3601) == "1 hour");
    Require(AdvertisementTime(3600) == "60 minutes");
    Require(AdvertisementTime(120) == "2 minutes");
    Require(AdvertisementTime(59) == "1 minute");
    Require(AdvertisementTime(0) == "0 minutes");
    Require(GoldilocksScale(100, 100) == 0.5f);
    Require(GoldilocksScale(100, 50) == 1.0f);
    Require(GoldilocksScale(100, 0) == 1.5f);
    Require(GoldilocksScale(100, 1000) == 0.5f);
    Require(GoldilocksScale(0, 0) == 0.5f);
    for (uint32 i = 0; i < AdvertisementLines.size(); ++i)
    {
        auto message = BuildAdvertisement(i, 12345678, 90061, "Alice");
        Require(message.find('{') == std::string::npos && message.find('}') == std::string::npos);
    }
    Require(BuildAdvertisement(0, 12345678, 90061, "Alice").find("1234 gold") != std::string::npos);
    Require(BuildAdvertisement(2, 0, 90061, "Alice").find("1 day") != std::string::npos);
    Require(BuildAdvertisement(1, 0, 0, "").find("You there") != std::string::npos);
    Player alice{"Alice"}, distant{"Distant"}, outsider{"Outsider"}, gm{"HiddenGM"}, bot{"Bot"};
    distant.distance = 500;
    outsider.zone = 12;
    gm.gm = true;
    gm.visible = false;
    bot.session.bot = true;
    mockMap.players = {{&alice}, {&distant}, {&outsider}, {&gm}, {&bot}};
    LotteryAdvertiser advertiser;
    advertiser.Configure();
    Require(mockMap.spawned == 1 && mockMap.creature->active);
    Require(mockMap.goldilocksSpawned == 1 && mockMap.goldilocks->active);
    Require(mockMap.goldilocksPosition.x == GoldilocksX && mockMap.goldilocksPosition.y == GoldilocksY &&
        mockMap.goldilocksPosition.z == GoldilocksZ && mockMap.goldilocks->scale == 0.5f);
    Require(mockMap.position.x == GallywixX && mockMap.position.y == GallywixY && mockMap.position.z == GallywixZ);
    advertiser.SyncSpawn();
    Require(mockMap.spawned == 1);
    advertiser.Update(1799999);
    Require(textMgr.yells.empty());
    advertiser.Update(1);
    Require(textMgr.yells.size() == 1 && textMgr.yells.front().sender == mockMap.creature->guid);
    Require(alice.received == 1 && distant.received == 1 && outsider.received == 0);
    for (uint32 i = 1; i < AdvertisementLines.size(); ++i) advertiser.Update(1800000);
    std::set<std::string> cycle;
    for (auto const& packet : textMgr.yells)
    {
        Require(packet.type == CHAT_MSG_MONSTER_YELL);
        cycle.insert(packet.message);
        Require(packet.message.find("HiddenGM") == std::string::npos);
        Require(packet.message.find("Distant,") == std::string::npos);
        Require(packet.message.find("Bot,") == std::string::npos);
        Require(packet.message.find("Outsider,") == std::string::npos);
    }
    Require(cycle.size() == AdvertisementLines.size());
    auto last = textMgr.yells.back().message;
    advertiser.Update(1800000);
    Require(textMgr.yells.back().message != last);
    auto count = textMgr.yells.size();
    settings.advertise = false;
    advertiser.Configure();
    advertiser.Update(1800000);
    Require(textMgr.yells.size() == count && !mockMap.creature->removed);
    settings.advertise = true;
    settings.enabled = false;
    advertiser.Configure();
    Require(mockMap.creature->removed);
    advertiser.Update(1800000);
    Require(textMgr.yells.size() == count);
    settings.enabled = true;
    ready = false;
    advertiser.Configure();
    Require(mockMap.spawned == 1);
    ready = true;
    advertiser.SyncSpawn();
    Require(mockMap.spawned == 2);
    mockMap.creature->alive = false;
    advertiser.Update(30000);
    Require(mockMap.spawned == 3 && mockMap.creature->alive);
    now = round.ends;
    advertiser.Update(1800000);
    Require(textMgr.yells.size() == count);
    settings.spawnGallywix = false;
    advertiser.Configure();
    Require(mockMap.creature->removed);
    settings.spawnGallywix = true;
    now = 1000;
    round.pot = 12345678;
    mockMap.players.clear();
    advertiser.Configure();
    count = textMgr.yells.size();
    advertiser.Update(1799999);
    Require(textMgr.yells.size() == count);
    for (uint32 i = 0; i < AdvertisementLines.size(); ++i) advertiser.Update(i == 0 ? 1 : 1800000);
    bool sawFallback = false, sawFreshPot = false;
    for (size_t i = count; i < textMgr.yells.size(); ++i)
    {
        sawFallback |= textMgr.yells[i].message.find("You there") != std::string::npos;
        sawFreshPot |= textMgr.yells[i].message.find("1234 gold") != std::string::npos;
    }
    Require(sawFallback && sawFreshPot);
    round.duration = 100;
    round.ends = now + 100;
    ++round.id;
    advertiser.Update(1);
    Require(mockMap.goldilocks->scale == 0.5f);
    now += 50;
    advertiser.Update(1);
    Require(mockMap.goldilocks->scale == 0.5f);
    settings.advertise = false;
    advertiser.Update(1800000);
    Require(mockMap.goldilocks->scale == 1.0f);
    count = textMgr.yells.size();
    advertiser.AnnounceResult("Alice", 12345678, false);
    Require(textMgr.yells.size() == count + 1 && textMgr.yells.back().message.find("Alice") != std::string::npos);
    Require(textMgr.yells.back().message.find("1234 gold") != std::string::npos && bursts.size() == 5);
    for (auto const& burst : bursts) Require(burst.second.z >= GallywixZ + 6.0f);
    for (auto const& object : burstObjects) Require(object->active && object->despawned && object->removed);
    advertiser.AnnounceResult("Trade Prince Gallywix", 10000000, true);
    Require(textMgr.yells.back().message.find("destroyed") != std::string::npos && bursts.size() == 10);
    count = textMgr.yells.size();
    Require(!advertiser.Advertise() && textMgr.yells.size() == count);
    Require(advertiser.Advertise(true) && textMgr.yells.size() == count + 1);
    now = round.ends;
    advertiser.UpdateGoldilocksScale();
    Require(mockMap.goldilocks->scale == 1.5f);
    ++round.id;
    round.ends = now + 100;
    advertiser.Update(1);
    Require(mockMap.goldilocks->scale == 0.5f);
    round.ends += 100;
    advertiser.Update(1);
    Require(mockMap.goldilocks->scale == 0.5f);
    round.ends = now + 25;
    mockMap.goldilocks->alive = false;
    advertiser.SyncSpawn();
    Require(mockMap.goldilocks->alive && mockMap.goldilocks->scale == 1.25f);
    settings.spawnGallywix = false;
    advertiser.Configure();
    Require(mockMap.creature->removed && !mockMap.goldilocks->removed);
    settings.enabled = false;
    advertiser.Configure();
    Require(mockMap.goldilocks->removed);
    settings.enabled = true;
    settings.spawnGoldilocks = false;
    advertiser.Configure();
    Require(mockMap.goldilocks->removed);
    gm.visible = true;
    mockMap.players = {{&gm}};
    settings.spawnGallywix = true;
    LotteryAdvertiser gmAdvertiser;
    gmAdvertiser.Configure();
    count = textMgr.yells.size();
    for (uint32 i = 0; i < AdvertisementLines.size(); ++i) Require(gmAdvertiser.Advertise(true));
    bool namedVisibleGM = false;
    for (size_t i = count; i < textMgr.yells.size(); ++i)
        namedVisibleGM |= textMgr.yells[i].message.find("HiddenGM") != std::string::npos;
    Require(namedVisibleGM);
    settings.spawnGoldilocks = settings.spawnGallywix = true;
    LotteryCities cities;
    cities.Configure();
    Require(mockHordeMap.creature && mockHordeMap.goldilocks);
    Require(mockHordeMap.position.x == 1621.1122f && mockHordeMap.position.y == -4419.4966f &&
        mockHordeMap.position.z == 14.876221f && mockHordeMap.position.o == 4.71238898f);
    Require(mockHordeMap.goldilocksPosition.x == 1623.0135f && mockHordeMap.goldilocksPosition.y == -4417.805f &&
        mockHordeMap.goldilocksPosition.z == 14.7874975f && mockHordeMap.goldilocksPosition.o == 4.71238898f);
    settings.enabled = false;
    cities.Configure();
    Require(mockHordeMap.creature->removed && mockHordeMap.goldilocks->removed);
}
}
int main() {Run();}
