#include "RULES_HEADER"
#include <array>
#include <map>
#include <memory>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <vector>
#define LOG_INFO(...)
#define LOG_ERROR(...)
namespace
{
using uint32 = uint32_t;
using uint64 = uint64_t;
using namespace CoALottery;
enum class HighGuid {Player};
struct ObjectGuid {ObjectGuid(HighGuid, uint32) {}};
struct Cache
{
    bool present = true;
    uint32 GetCharacterAccountIdByGuid(ObjectGuid) const {return present ? 42 : 0;}
} cache;
auto* sCharacterCache = &cache;
struct Field
{
    bool null = false;
    uint32 number = 0;
    std::string text;
    bool IsNull() const {return null;}
    template<class T> T Get() const
    {
        if (null) throw std::runtime_error("read null field");
        if constexpr (std::is_same_v<T, std::string>) return text;
        else return T(number);
    }
};
struct Result
{
    std::vector<std::array<Field, 2>> rows;
    size_t index = 0;
    Field* Fetch() {return rows.at(index).data();}
    bool NextRow() {return ++index < rows.size();}
};
enum {CHAR_SEL_LOTTERY_ENTRIES, CHAR_SEL_LOTTERY_WINNER_IDENTITY, CHAR_UPD_LOTTERY_END};
struct Statement
{
    uint32 id;
    template<class T> void SetData(uint32, T) {}
};
struct Transaction {void Append(Statement*) {}};
struct Database
{
    std::array<Statement, 3> statements{{{0}, {1}, {2}}};
    std::shared_ptr<Result> eligible, identity;
    Statement* GetPreparedStatement(uint32 id) {return &statements.at(id);}
    std::shared_ptr<Result> Query(Statement* stmt)
    {return stmt->id == CHAR_SEL_LOTTERY_ENTRIES ? eligible : identity;}
    std::shared_ptr<Transaction> BeginTransaction() {return std::make_shared<Transaction>();}
} CharacterDatabase;
struct Round
{
    uint64 id = 1, ends = 900;
    bool paused = false;
    uint32 pot = 0;
    uint32 totalTickets = 1, fakeTickets = 0, duration = 100;
    std::map<uint32, uint32> entries{{10, 1}};
} round;
struct Settings {bool enabled = true;} settings;
bool ready = true;
uint64 nextDrawAttempt = 0, mockNow = 1000;
uint32 attempts = 0, houseDraws = 0, commits = 0;
uint64 Now() {return mockNow;}
uint32 urand(uint32 low, uint32) {return low;}
bool Commit(std::shared_ptr<Transaction>) {++commits; return true;}
DRAW_PREFIX
void Require(bool value) {if (!value) throw std::runtime_error("deleted recipient assertion failed");}
void Reset()
{
    round = Round{};
    attempts = houseDraws = commits = 0;
    nextDrawAttempt = 0;
    cache.present = true;
    CharacterDatabase.eligible = std::make_shared<Result>();
    CharacterDatabase.eligible->rows.push_back({Field{false, 10, ""}, Field{false, 1, ""}});
    CharacterDatabase.identity.reset();
}
void Run()
{
    Reset();
    Require(!DrawIfDue() && attempts == 0 && commits == 0);
    Reset();
    CharacterDatabase.identity = std::make_shared<Result>();
    CharacterDatabase.identity->rows.push_back({Field{false, 0, "Alice"}, Field{false, 42, ""}});
    cache.present = false;
    Require(!DrawIfDue() && attempts == 0 && commits == 0);
    Reset();
    CharacterDatabase.eligible->rows = {{Field{true, 0, ""}, Field{true, 0, ""}}};
    Require(DrawIfDue() && attempts == 0 && commits == 1 && round.ends == mockNow + round.duration);
    Reset();
    CharacterDatabase.eligible->rows = {{Field{true, 0, ""}, Field{true, 0, ""}}};
    round.fakeTickets = 100;
    Require(DrawIfDue() && houseDraws == 1 && attempts == 1);
    Reset();
    CharacterDatabase.eligible.reset();
    Require(!DrawIfDue() && attempts == 0 && commits == 0);
    Reset();
    CharacterDatabase.identity = std::make_shared<Result>();
    CharacterDatabase.identity->rows.push_back({Field{false, 0, "Alice"}, Field{false, 42, ""}});
    Require(DrawIfDue() && attempts == 1 && houseDraws == 0);
}
}
int main() {Run();}
