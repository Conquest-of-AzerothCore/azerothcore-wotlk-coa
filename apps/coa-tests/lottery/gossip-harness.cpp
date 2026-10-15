#include "RULES_HEADER"
#include <array>
#include <memory>
#include <mutex>
#include <sstream>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <vector>
namespace
{
using uint8 = uint8_t;
using uint32 = uint32_t;
using namespace CoALottery;
constexpr uint32 DAY = 86400, HOUR = 3600, MINUTE = 60;
constexpr uint32 GOSSIP_ICON_CHAT = 0, GOSSIP_SENDER_MAIN = 1;
constexpr uint32 GallywixMenuId = 0xC0A08054, GallywixRulesAction = 10001, GallywixWinnersAction = 10002;
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
struct Menu
{
    uint32 id = 0;
    uint32 GetMenuId() const {return id;}
    void SetMenuId(uint32 value) {id = value;}
};
struct Talk
{
    Menu menu;
    std::string text;
    std::vector<std::pair<std::string, uint32>> options;
    Menu& GetGossipMenu() {return menu;}
    void SendDynamicGossipMenu(std::string const& value, uint32) {text = value;}
};
struct Player
{
    Talk talk;
    Talk* PlayerTalkClass = &talk;
    void* GetSession() {return nullptr;}
};
struct Creature
{
    uint32 entry;
    uint32 GetEntry() const {return entry;}
    uint32 GetGUID() const {return entry;}
};
void ClearGossipMenuFor(Player* player) {player->talk.options.clear();}
uint32 closedMenus = 0;
void CloseGossipMenuFor(Player*) {++closedMenus;}
void AddGossipItemFor(Player* player, uint32, std::string const& label, uint32, uint32 action)
{player->talk.options.emplace_back(label, action);}
struct ChatHandler
{
    explicit ChatHandler(void*) {}
    void SendSysMessage(char const*) {}
};
struct Field
{
    std::string text;
    uint32 number = 0;
    template<typename T> T Get() const
    {
        if constexpr (std::is_same_v<T, std::string>) return text;
        else return T(number);
    }
};
struct Result
{
    std::vector<std::array<Field, 5>> rows;
    size_t index = 0;
    Field* Fetch() {return rows[index].data();}
    bool NextRow() {return ++index < rows.size();}
};
constexpr uint32 CHAR_SEL_LOTTERY_RECENT_WINNERS = 1;
struct Database
{
    std::shared_ptr<Result> result;
    uint32 GetPreparedStatement(uint32 id) {return id;}
    std::shared_ptr<Result> Query(uint32) {return result;}
} CharacterDatabase;
struct Settings {bool enabled = true; uint32 duration = 604800, contribution = 100, fakeTickets = 100, seed = 0;} settings;
struct Round {bool paused = false; uint32 duration = 604800, contribution = 70, fakeTickets = 25, id = 99, ends = 1000;} round;
bool ready = true;
std::mutex lotteryMutex;
uint32 draws = 0, salesMenus = 0, purchases = 0;
uint32 Now() {return 500;}
[[maybe_unused]] bool DrawIfDue() {++draws; return true;}
void Show(Player* player, Creature*) {++salesMenus; player->talk.menu.id = round.id;}
GALLYWIX_METHOD
struct LotteryNPC
{
    HELLO_METHOD
    SELECT_METHOD
};
void Require(bool value) {if (!value) throw std::runtime_error("Gallywix gossip assertion failed");}
void Run()
{
    Player player;
    Creature gallywix{GallywixEntry}, goldilocks{GoldilocksEntry};
    LotteryNPC script;
    script.OnGossipHello(&player, &gallywix);
    Require(draws == 0 && salesMenus == 0 && player.talk.options.size() == 2);
    Require(player.talk.options[0].first == "What are the rules?");
    Require(player.talk.options[1].first == "Who has won recently?");
    script.OnGossipSelect(&player, &gallywix, GOSSIP_SENDER_MAIN, GallywixRulesAction);
    Require(player.talk.text.find("70 percent") != std::string::npos);
    Require(player.talk.text.find("25 tickets") != std::string::npos);
    Require(player.talk.text.find("mailed to your character") != std::string::npos);
    Require(player.talk.text.find("whole pot is destroyed") != std::string::npos);
    auto previousText = player.talk.text;
    for (uint32 action = 1; action <= 4; ++action)
        script.OnGossipSelect(&player, &gallywix, GOSSIP_SENDER_MAIN, action);
    Require(purchases == 0 && player.talk.text == previousText);
    script.OnGossipSelect(&player, &gallywix, 999, GallywixWinnersAction);
    Require(player.talk.text == previousText);
    script.OnGossipSelect(&player, &gallywix, GOSSIP_SENDER_MAIN, GallywixWinnersAction);
    Require(player.talk.text.find("No recent winners") != std::string::npos);
    CharacterDatabase.result = std::make_shared<Result>();
    CharacterDatabase.result->rows.push_back({Field{"Alice", 0}, Field{"", 10000001}, Field{"", 7}, Field{"", 0}});
    CharacterDatabase.result->rows.push_back({Field{"Trade Prince Gallywix", 0}, Field{"", 123400}, Field{"", 100}, Field{"", 1}});
    script.OnGossipSelect(&player, &gallywix, GOSSIP_SENDER_MAIN, GallywixWinnersAction);
    Require(player.talk.text.find("Alice won 1000g0s1c with 7 purchased tickets") != std::string::npos);
    Require(player.talk.text.find("100 house tickets, 0 purchased tickets") != std::string::npos);
    Require(player.talk.text.find("pot was destroyed") != std::string::npos);
    settings.enabled = false;
    ready = false;
    script.OnGossipHello(&player, &gallywix);
    script.OnGossipSelect(&player, &gallywix, GOSSIP_SENDER_MAIN, GallywixRulesAction);
    Require(player.talk.text.find("100 percent") != std::string::npos);
    Require(player.talk.text.find("isn't taking bets") != std::string::npos);
    settings.enabled = true;
    ready = true;
    script.OnGossipHello(&player, &goldilocks);
    Require(salesMenus == 1 && draws == 0);
    script.OnGossipSelect(&player, &goldilocks, GOSSIP_SENDER_MAIN, GallywixRulesAction);
    Require(purchases == 0);
    script.OnGossipSelect(&player, &goldilocks, GOSSIP_SENDER_MAIN, 1);
    Require(purchases == 1);
    script.OnGossipSelect(&player, &gallywix, GOSSIP_SENDER_MAIN, GallywixRulesAction);
    Require(player.talk.menu.id == round.id);
    round.ends = Now();
    script.OnGossipHello(&player, &goldilocks);
    Require(draws == 0 && salesMenus == 1 && closedMenus == 1);
    script.OnGossipSelect(&player, &goldilocks, GOSSIP_SENDER_MAIN, 1);
    Require(draws == 0 && purchases == 1 && closedMenus == 2);
    round.ends = Now() + 1000;
    ++round.id;
    script.OnGossipSelect(&player, &goldilocks, GOSSIP_SENDER_MAIN, 1);
    Require(draws == 0 && purchases == 1 && salesMenus == 2 && player.talk.menu.id == round.id);
    ready = false;
    script.OnGossipHello(&player, &goldilocks);
    script.OnGossipSelect(&player, &goldilocks, GOSSIP_SENDER_MAIN, 1);
    Require(draws == 0 && purchases == 1 && salesMenus == 2 && closedMenus == 3);
    ready = true;
    round.paused = true;
    script.OnGossipHello(&player, &goldilocks);
    script.OnGossipSelect(&player, &goldilocks, GOSSIP_SENDER_MAIN, 1);
    Require(draws == 0 && purchases == 1 && salesMenus == 2 && closedMenus == 4);
}
}
int main() {Run();}
