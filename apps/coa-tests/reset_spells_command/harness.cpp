#include <algorithm>
#include <cassert>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

using uint16 = std::uint16_t;
using uint64 = std::uint64_t;
template <class T> using Optional = std::optional<T>;

enum CharacterDatabaseStatements { CHAR_UPD_ADD_AT_LOGIN_FLAG };
enum AtLoginFlags { AT_LOGIN_RESET_SPELLS = 0x02 };
enum TrinityStrings { LANG_RESET_SPELLS, LANG_RESET_SPELLS_ONLINE, LANG_RESET_SPELLS_OFFLINE };

struct ObjectGuid
{
    uint64 counter = 0;
    uint64 GetCounter() const { return counter; }
};

struct Player;

struct WorldSession
{
    Player* player = nullptr;
    Player* GetPlayer() const { return player; }
};

struct Player
{
    WorldSession session;
    int spellResets = 0;
    void resetSpells() { ++spellResets; }
    WorldSession* GetSession() { return &session; }
};

std::vector<TrinityStrings> gmMessages;

struct ChatHandler
{
    WorldSession* session;
    explicit ChatHandler(WorldSession* worldSession) : session(worldSession) { }
    WorldSession* GetSession() const { return session; }
    std::string GetNameLink(Player*) const { return "target"; }
    void SendSysMessage(TrinityStrings) { }
    template <class... Args> void PSendSysMessage(TrinityStrings message, Args&&...) { gmMessages.push_back(message); }
};

struct PlayerIdentifier
{
    ObjectGuid guid;
    std::string name;
    Player* connected = nullptr;
    static Optional<PlayerIdentifier> FromTargetOrSelf(ChatHandler*) { return std::nullopt; }
    Player* GetConnectedPlayer() const { return connected; }
    ObjectGuid GetGUID() const { return guid; }
    std::string const& GetName() const { return name; }
};

struct CharacterDatabasePreparedStatement
{
    std::vector<uint64> values;
    template <class T> void SetData(std::size_t index, T value)
    {
        values.resize(std::max(values.size(), index + 1));
        values[index] = uint64(value);
    }
};

struct CharacterDatabaseStub
{
    CharacterDatabasePreparedStatement prepared;
    std::vector<std::vector<uint64>> executed;
    CharacterDatabasePreparedStatement* GetPreparedStatement(CharacterDatabaseStatements)
    {
        prepared = { };
        return &prepared;
    }
    void Execute(CharacterDatabasePreparedStatement* statement) { executed.push_back(statement->values); }
} CharacterDatabase;

// ACTUAL_RESET_SPELLS

int main()
{
    WorldSession console;
    ChatHandler gm(&console);

    bool const offline = HandleResetSpellsCommand(&gm, PlayerIdentifier{ { 42 }, "Offline", nullptr });
    assert(offline);
    assert(CharacterDatabase.executed == std::vector<std::vector<uint64>>({ { AT_LOGIN_RESET_SPELLS, 42 } }));
    assert(gmMessages == std::vector<TrinityStrings>({ LANG_RESET_SPELLS_OFFLINE }));

    Player online;
    online.session.player = &online;
    CharacterDatabase.executed.clear();
    gmMessages.clear();
    bool const connected = HandleResetSpellsCommand(&gm, PlayerIdentifier{ { 7 }, "Online", &online });
    assert(connected);
    assert(online.spellResets == 1 && CharacterDatabase.executed.empty());
    assert(gmMessages == std::vector<TrinityStrings>({ LANG_RESET_SPELLS_ONLINE }));

    bool const missing = HandleResetSpellsCommand(&gm, std::nullopt);
    assert(!missing);
}
