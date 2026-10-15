#include <algorithm>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

using uint32 = uint32_t;
enum AccountOpResult { AOR_OK, AOR_NAME_NOT_EXIST, AOR_DB_INTERNAL_ERROR };
constexpr int CHAR_SEL_CHECK_NAME = 0;

struct Storage
{
    bool accountExists = true;
    bool deletionQueued = false;
    bool commitAfterLookup = false;
    bool deleteFails = false;
    bool characterCached = true;
    bool characterRow = true;
    uint32 characterCount = 1;
    uint32 deletions = 0;
} storage;

void Require(bool value, std::string const& message)
{
    if (!value)
        throw std::runtime_error(message);
}

namespace AccountMgr
{
uint32 GetId(std::string const&)
{
    uint32 const id = storage.accountExists ? 17 : 0;
    if (storage.deletionQueued && storage.commitAfterLookup)
        storage.accountExists = false;
    return id;
}

AccountOpResult DeleteAccount(uint32)
{
    ++storage.deletions;
    if (storage.deleteFails)
        return AOR_DB_INTERNAL_ERROR;
    if (!storage.accountExists)
        return AOR_NAME_NOT_EXIST;
    storage.deletionQueued = true;
    return AOR_OK;
}

bool GetName(uint32, std::string&) { return storage.accountExists; }
uint32 GetCharactersCount(uint32) { return storage.characterCount; }
}

struct Field
{
    template<class T> T Get() const { return T(19); }
};
struct Result
{
    Field field;
    Field* Fetch() { return &field; }
};
using QueryResult = std::shared_ptr<Result>;
struct CharacterDatabasePreparedStatement
{
    void SetData(uint32, std::string const&) { }
};
struct Database
{
    CharacterDatabasePreparedStatement statement;
    void EscapeString(std::string&) const { }
    CharacterDatabasePreparedStatement* GetPreparedStatement(int) { return &statement; }
    template<class... Args> QueryResult Query(char const*, Args const&...) const
    {
        return storage.characterRow ? std::make_shared<Result>() : nullptr;
    }
    QueryResult Query(CharacterDatabasePreparedStatement*) const
    {
        return storage.characterRow ? std::make_shared<Result>() : nullptr;
    }
} CharacterDatabase;
struct Player
{
    static void DeleteFromDB(uint32, uint32, bool, bool) { }
};
struct CharacterCache
{
    uint32 GetCharacterGuidByName(std::string const&) const { return storage.characterCached ? 19 : 0; }
} characterCache;
CharacterCache* sCharacterCache = &characterCache;
struct Accounts
{
    std::vector<std::string> accounts{"CASE_ACCOUNT"};
    std::vector<std::string> characters{"CaseCharacter"};
};
struct Outcome { Accounts accounts; };
struct Lane
{
    Outcome outcome;
    std::vector<uint32> deletedAccounts;
};

struct NativeTeardown
{
    // NATIVE_DELETE
    // NATIVE_COMPLETE
};

int main()
{
    Lane lane;
    NativeTeardown::DeleteAccounts(lane);
    assert(storage.deletions == 1 && storage.deletionQueued);
    assert(lane.deletedAccounts == std::vector<uint32>{17});
    assert(!NativeTeardown::TeardownComplete(lane));

    storage.commitAfterLookup = true;
    NativeTeardown::DeleteAccounts(lane);
    assert(!storage.accountExists && storage.deletions == 1);
    assert(lane.deletedAccounts == std::vector<uint32>{17});

    assert(!NativeTeardown::TeardownComplete(lane));
    storage.characterCount = 0;
    assert(!NativeTeardown::TeardownComplete(lane));
    storage.characterCached = false;
    assert(!NativeTeardown::TeardownComplete(lane));
    storage.characterRow = false;
    assert(NativeTeardown::TeardownComplete(lane));
    NativeTeardown::DeleteAccounts(lane);
    assert(storage.deletions == 1);

    storage = {};
    storage.deleteFails = true;
    Lane failed;
    bool threw = false;
    try { NativeTeardown::DeleteAccounts(failed); }
    catch (std::runtime_error const&) { threw = true; }
    assert(threw && failed.deletedAccounts.empty());
    std::cout << "Asynchronous account cleanup is idempotent; pending character state and real errors block release\n";
}
