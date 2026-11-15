/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CoAPtrCharacterCopy.h"
#include "AccountMgr.h"
#include "AsyncCallbackProcessor.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerDump.h"
#include "QueryCallback.h"
#include "Realm.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "World.h"
#include "WorldSession.h"
#include <atomic>
#include <mutex>
#include <optional>
#include <unordered_map>

using namespace Acore::ChatCommands;

namespace
{
enum class RequestState : uint8
{
    Pending = 0,
    Copied = 1,
    Failed = 2,
    Loading = 3,
};

constexpr uint32 PollIntervalMs = 5000;
constexpr uint32 SaveTimeoutSeconds = 60;

std::atomic<bool> testOverrideActive = false;
std::atomic<PtrCharacterCopy::Interruption> testInterruption = PtrCharacterCopy::Interruption::None;
std::mutex savingLock;
std::unordered_map<uint32, uint32> savingSince;

struct Settings
{
    uint32 targetRealm = 0;
    bool receive = false;
    uint32 cooldownSeconds = 0;
};

struct SourceCharacter
{
    uint32 guid = 0;
    std::string name;
};

struct PendingCopy
{
    uint32 id = 0;
    uint32 account = 0;
    uint32 sourceRealm = 0;
    uint32 sourceGuid = 0;
    std::string sourceName;
    std::string dump;
};

struct InterruptedLoad
{
    uint32 id = 0;
    uint32 account = 0;
    uint32 copyGuid = 0;
    std::string sourceName;
};

uint32 Now()
{
    return uint32(GameTime::GetGameTime().count());
}

Settings LoadSettings()
{
    if (testOverrideActive)
        return Settings{ realm.Id.Realm, true, 0 };

    return Settings{
        sConfigMgr->GetOption<uint32>("CoA.PtrCopy.TargetRealmID", 0),
        sConfigMgr->GetOption<bool>("CoA.PtrCopy.Receive", false),
        sConfigMgr->GetOption<uint32>("CoA.PtrCopy.CooldownSeconds", 3600) };
}

std::string RealmName(uint32 realmId)
{
    if (QueryResult result = LoginDatabase.Query("SELECT name FROM realmlist WHERE id = {}", realmId))
        return result->Fetch()[0].Get<std::string>();
    return Acore::StringFormat("realm {}", realmId);
}

bool RejectNotSource(ChatHandler* handler, Settings const& settings)
{
    if (settings.targetRealm)
        return false;

    handler->SendErrorMessage(settings.receive
        ? "Copies to this realm start on the character's own realm: log in there and use .ptr copy <name>."
        : "Character copies are not enabled on this realm.", false);
    return true;
}

std::optional<SourceCharacter> FindOwnCharacter(uint32 accountId, std::string name)
{
    CharacterDatabase.EscapeString(name);
    QueryResult result = CharacterDatabase.Query(
        "SELECT guid, name FROM characters WHERE account = {} AND name = '{}'", accountId, name);
    if (!result)
        return std::nullopt;

    Field* fields = result->Fetch();
    return SourceCharacter{ fields[0].Get<uint32>(), fields[1].Get<std::string>() };
}

std::optional<std::string> QueueRefusal(Settings const& settings, SourceCharacter const& source,
    std::string const& targetName)
{
    uint32 const thisRealm = realm.Id.Realm;
    if (LoginDatabase.Query("SELECT 1 FROM coa_ptr_copy_request WHERE source_realm = {} AND source_guid = {} "
        "AND state IN ({}, {})", thisRealm, source.guid, uint8(RequestState::Pending), uint8(RequestState::Loading)))
        return Acore::StringFormat("A copy of {} is already on its way to {}.", source.name, targetName);

    QueryResult lastCopy = LoginDatabase.Query("SELECT MAX(requested_at) FROM coa_ptr_copy_request "
        "WHERE source_realm = {} AND source_guid = {} AND target_realm = {} AND state = {}", thisRealm, source.guid,
        settings.targetRealm, uint8(RequestState::Copied));
    if (!lastCopy || lastCopy->Fetch()[0].IsNull())
        return std::nullopt;

    uint32 const readyAt = lastCopy->Fetch()[0].Get<uint32>() + settings.cooldownSeconds;
    uint32 const now = Now();
    if (now < readyAt)
        return Acore::StringFormat("You can copy {} again in {} min.", source.name, (readyAt - now + 59) / 60);
    return std::nullopt;
}

std::string DumpFailureText(DumpReturn result)
{
    switch (result)
    {
        case DUMP_TOO_MANY_CHARS:
            return "your account has no free character slot there.";
        case DUMP_CHARACTER_DELETED:
            return "the character is deleted.";
        default:
            return "the copy could not be loaded. Nothing was changed there.";
    }
}

bool BeginSaving(uint32 sourceGuid)
{
    std::lock_guard<std::mutex> lock(savingLock);
    uint32 const now = Now();
    auto const [entry, inserted] = savingSince.try_emplace(sourceGuid, now);
    if (!inserted && now - entry->second < SaveTimeoutSeconds)
        return false;
    entry->second = now;
    return true;
}

void FinishSaving(uint32 sourceGuid)
{
    std::lock_guard<std::mutex> lock(savingLock);
    savingSince.erase(sourceGuid);
}

bool QueueCopy(ChatHandler& chat, uint32 accountId, uint32 targetRealm, SourceCharacter const& source,
    std::string const& targetName)
{
    std::string dump;
    DumpReturn const result = PlayerDumpWriter().WriteDumpToString(dump, source.guid);
    if (result != DUMP_SUCCESS)
    {
        chat.SendErrorMessage(Acore::StringFormat("{} cannot be copied: {}", source.name,
            result == DUMP_CHARACTER_DELETED ? "the character is deleted." : "the character could not be read."),
            false);
        return false;
    }

    std::string name = source.name;
    LoginDatabase.EscapeString(name);
    LoginDatabase.EscapeString(dump);
    LoginDatabase.DirectExecute("INSERT INTO coa_ptr_copy_request (account, source_realm, source_guid, source_name, "
        "target_realm, dump, requested_at, state) VALUES ({}, {}, {}, '{}', {}, '{}', {}, {})", accountId,
        realm.Id.Realm, source.guid, name, targetRealm, dump, Now(), uint8(RequestState::Pending));
    chat.PSendSysMessage("{} is on its way to {}. You will be told here when the copy is ready.", source.name,
        targetName);
    return true;
}

std::optional<std::string> LiveCopyName(PendingCopy const& copy)
{
    QueryResult copies = LoginDatabase.Query("SELECT copy_guid FROM coa_ptr_copy_request WHERE target_realm = {} "
        "AND source_realm = {} AND source_guid = {} AND account = {} AND state = {}", realm.Id.Realm,
        copy.sourceRealm, copy.sourceGuid, copy.account, uint8(RequestState::Copied));
    if (!copies)
        return std::nullopt;

    do
    {
        if (QueryResult live = CharacterDatabase.Query("SELECT name FROM characters WHERE guid = {} AND account = {}",
            copies->Fetch()[0].Get<uint32>(), copy.account))
            return live->Fetch()[0].Get<std::string>();
    } while (copies->NextRow());
    return std::nullopt;
}

void Complete(uint32 id, RequestState state, std::string result, uint32 copyGuid = 0, std::string copyName = {})
{
    LoginDatabase.EscapeString(result);
    LoginDatabase.EscapeString(copyName);
    LoginDatabase.DirectExecute("UPDATE coa_ptr_copy_request SET state = {}, result = '{}', copy_guid = {}, "
        "copy_name = '{}', completed_at = {}, dump = NULL WHERE id = {}", uint8(state), result, copyGuid, copyName,
        Now(), id);
}

bool Claim(uint32 id, uint32 copyGuid)
{
    LoginDatabase.DirectExecute("UPDATE coa_ptr_copy_request SET state = {}, copy_guid = {} "
        "WHERE id = {} AND state = {}", uint8(RequestState::Loading), copyGuid, id, uint8(RequestState::Pending));
    return LoginDatabase.Query("SELECT 1 FROM coa_ptr_copy_request WHERE id = {} AND state = {} AND copy_guid = {}",
        id, uint8(RequestState::Loading), copyGuid) != nullptr;
}

bool TakeTestInterruption(PtrCharacterCopy::Interruption point)
{
    PtrCharacterCopy::Interruption expected = point;
    return testInterruption.compare_exchange_strong(expected, PtrCharacterCopy::Interruption::None);
}

void RecoverInterruptedLoad(InterruptedLoad const& load)
{
    if (QueryResult copy = CharacterDatabase.Query("SELECT name FROM characters WHERE guid = {} AND account = {}",
        load.copyGuid, load.account))
    {
        std::string const copyName = copy->Fetch()[0].Get<std::string>();
        LOG_WARN("misc", "PTR copy request {} of {} was interrupted after {} (guid {}) was created; reporting it",
            load.id, load.sourceName, copyName, load.copyGuid);
        Complete(load.id, RequestState::Copied, {}, load.copyGuid, copyName);
        return;
    }

    LOG_WARN("misc", "PTR copy request {} of {} was interrupted before its character was created", load.id,
        load.sourceName);
    Complete(load.id, RequestState::Failed,
        "the realm stopped before the copy was loaded. Nothing was changed there, so you can copy it again.");
}

void LoadCopy(PendingCopy const& copy)
{
    uint32 const copyGuid = sObjectMgr->GetGenerator<HighGuid::Player>().GetNextAfterMaxUsed();
    if (!Claim(copy.id, copyGuid))
    {
        LOG_ERROR("misc", "PTR copy request {} of {} (realm {}, guid {}) could not be claimed and is not loaded",
            copy.id, copy.sourceName, copy.sourceRealm, copy.sourceGuid);
        return;
    }

    if (TakeTestInterruption(PtrCharacterCopy::Interruption::BeforeLoad))
        return;

    if (std::optional<std::string> liveName = LiveCopyName(copy))
    {
        Complete(copy.id, RequestState::Failed, Acore::StringFormat(
            "it is already there as {}. Delete that character there to copy it again.", *liveName));
        return;
    }

    if (AccountMgr::GetCharactersCount(copy.account) >= sWorld->getIntConfig(CONFIG_CHARACTERS_PER_REALM))
    {
        Complete(copy.id, RequestState::Failed, DumpFailureText(DUMP_TOO_MANY_CHARS));
        return;
    }

    PlayerDumpReader::LoadOptions loadOptions;
    loadOptions.DirectCommit = true;
    loadOptions.PlayerMailFromCopy = true;
    PlayerDumpReader reader(loadOptions);
    DumpReturn const result = reader.LoadDumpFromString(copy.dump, copy.account, copy.sourceName, 0);
    if (result != DUMP_SUCCESS)
    {
        LOG_ERROR("misc", "PTR copy request {} of {} (realm {}, guid {}) failed to load: {}", copy.id,
            copy.sourceName, copy.sourceRealm, copy.sourceGuid, uint32(result));
        Complete(copy.id, RequestState::Failed, DumpFailureText(result));
        return;
    }

    if (TakeTestInterruption(PtrCharacterCopy::Interruption::AfterLoad))
        return;

    Complete(copy.id, RequestState::Copied, {}, reader.GetLoadedGuid(), reader.GetLoadedName());
}

std::string NextCopyRequestQuery()
{
    return Acore::StringFormat("SELECT id, account, source_realm, source_guid, source_name, dump, state, copy_guid "
        "FROM coa_ptr_copy_request WHERE target_realm = {} AND state IN ({}, {}) ORDER BY state, id LIMIT 1",
        realm.Id.Realm, uint8(RequestState::Pending), uint8(RequestState::Loading));
}

void ProcessNextCopyRequest(QueryResult request)
{
    if (!request)
        return;

    Field* fields = request->Fetch();
    if (RequestState(fields[6].Get<uint8>()) == RequestState::Loading)
    {
        RecoverInterruptedLoad(InterruptedLoad{ fields[0].Get<uint32>(), fields[1].Get<uint32>(),
            fields[7].Get<uint32>(), fields[4].Get<std::string>() });
        return;
    }

    LoadCopy(PendingCopy{ fields[0].Get<uint32>(), fields[1].Get<uint32>(), fields[2].Get<uint32>(),
        fields[3].Get<uint32>(), fields[4].Get<std::string>(), fields[5].Get<std::string>() });
}

std::string FinishedCopiesQuery()
{
    return Acore::StringFormat("SELECT id, account, source_name, target_realm, state, result, copy_name "
        "FROM coa_ptr_copy_request WHERE source_realm = {} AND notified = 0 AND state IN ({}, {})", realm.Id.Realm,
        uint8(RequestState::Copied), uint8(RequestState::Failed));
}

std::unordered_map<uint32, Player*> OnlinePlayersByAccount()
{
    std::unordered_map<uint32, Player*> players;
    for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
        if (player->IsInWorld())
            players.emplace(player->GetSession()->GetAccountId(), player);
    return players;
}

void NotifyFinishedCopies(QueryResult finished)
{
    if (!finished)
        return;

    std::unordered_map<uint32, Player*> const online = OnlinePlayersByAccount();
    do
    {
        Field* fields = finished->Fetch();
        auto const player = online.find(fields[1].Get<uint32>());
        if (player == online.end())
            continue;

        std::string const sourceName = fields[2].Get<std::string>();
        std::string const targetName = RealmName(fields[3].Get<uint32>());
        ChatHandler chat(player->second->GetSession());
        if (RequestState(fields[4].Get<uint8>()) == RequestState::Copied)
        {
            chat.PSendSysMessage("{} was copied to {}. Log in there to play it.", sourceName, targetName);
            if (fields[6].Get<std::string>() != sourceName)
                chat.PSendSysMessage("That name is taken on {}, so you will choose a new one at login.", targetName);
        }
        else
            chat.PSendSysMessage("{} was not copied to {}: {}", sourceName, targetName, fields[5].Get<std::string>());

        LoginDatabase.DirectExecute("UPDATE coa_ptr_copy_request SET notified = 1 WHERE id = {}",
            fields[0].Get<uint32>());
    } while (finished->NextRow());
}
}

namespace PtrCharacterCopy
{
TestOverride::TestOverride(Interruption firstLoadInterruption)
{
    testInterruption = firstLoadInterruption;
    testOverrideActive = true;
}

TestOverride::~TestOverride()
{
    testOverrideActive = false;
    testInterruption = Interruption::None;
}
}

class CoAPtrCharacterCopyCommands final : public CommandScript
{
public:
    CoAPtrCharacterCopyCommands() : CommandScript("CoAPtrCharacterCopyCommands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable ptrTable =
        {
            { "list", HandleList, SEC_PLAYER, Console::No },
            { "copy", HandleCopy, SEC_PLAYER, Console::No },
        };
        static ChatCommandTable commandTable =
        {
            { "ptr", ptrTable },
        };
        return commandTable;
    }

    static bool HandleList(ChatHandler* handler)
    {
        Settings const settings = LoadSettings();
        if (RejectNotSource(handler, settings))
            return false;

        uint32 const accountId = handler->GetSession()->GetAccountId();
        QueryResult characters = CharacterDatabase.Query(
            "SELECT guid, name, level FROM characters WHERE account = {} ORDER BY name", accountId);
        if (!characters)
        {
            handler->SendSysMessage("You have no characters on this realm.");
            return true;
        }

        std::unordered_map<uint32, std::string> statusByGuid;
        if (QueryResult requests = LoginDatabase.Query("SELECT source_guid, state, copy_name FROM coa_ptr_copy_request "
            "WHERE account = {} AND source_realm = {} AND target_realm = {} ORDER BY id", accountId, realm.Id.Realm,
            settings.targetRealm))
        {
            do
            {
                Field* fields = requests->Fetch();
                switch (RequestState(fields[1].Get<uint8>()))
                {
                    case RequestState::Pending:
                    case RequestState::Loading:
                        statusByGuid[fields[0].Get<uint32>()] = "copy on its way";
                        break;
                    case RequestState::Copied:
                        statusByGuid[fields[0].Get<uint32>()] = Acore::StringFormat("copied as {}",
                            fields[2].Get<std::string>());
                        break;
                    default:
                        statusByGuid[fields[0].Get<uint32>()] = "last copy failed";
                        break;
                }
            } while (requests->NextRow());
        }

        handler->PSendSysMessage("Your characters, for copying to {}:", RealmName(settings.targetRealm));
        do
        {
            Field* fields = characters->Fetch();
            auto const status = statusByGuid.find(fields[0].Get<uint32>());
            handler->PSendSysMessage("  {} (level {}): {}", fields[1].Get<std::string>(), fields[2].Get<uint8>(),
                status == statusByGuid.end() ? std::string("not copied") : status->second);
        } while (characters->NextRow());
        handler->SendSysMessage("Copy one with .ptr copy <name>.");
        return true;
    }

    static bool HandleCopy(ChatHandler* handler, Tail typedName)
    {
        Settings const settings = LoadSettings();
        if (RejectNotSource(handler, settings))
            return false;

        std::string name(typedName);
        name.erase(name.find_last_not_of(' ') + 1);
        WorldSession* session = handler->GetSession();
        uint32 const accountId = session->GetAccountId();
        std::optional<SourceCharacter> source;
        if (normalizePlayerName(name))
            source = FindOwnCharacter(accountId, name);
        if (!source)
        {
            handler->SendErrorMessage(Acore::StringFormat("Your account has no character named {} on this realm.",
                name), false);
            return false;
        }

        std::string const targetName = RealmName(settings.targetRealm);
        if (std::optional<std::string> refusal = QueueRefusal(settings, *source, targetName))
        {
            handler->SendErrorMessage(*refusal, false);
            return false;
        }

        Player* player = session->GetPlayer();
        if (!player || player->GetGUID().GetCounter() != source->guid)
            return QueueCopy(*handler, accountId, settings.targetRealm, *source, targetName);

        if (!BeginSaving(source->guid))
        {
            handler->SendErrorMessage(Acore::StringFormat("A copy of {} is already on its way to {}.", source->name,
                targetName), false);
            return false;
        }

        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        player->SaveToDB(trans, false, false);
        session->AddTransactionCallback(CharacterDatabase.AsyncCommitTransaction(trans)).AfterComplete(
            [session, accountId, targetRealm = settings.targetRealm, source = *source, targetName](bool saved)
            {
                FinishSaving(source.guid);
                ChatHandler chat(session);
                if (saved)
                    QueueCopy(chat, accountId, targetRealm, source, targetName);
                else
                    chat.SendErrorMessage(Acore::StringFormat("{} could not be saved, so it was not copied.",
                        source.name), false);
            });
        handler->PSendSysMessage("Saving {} for the copy to {}.", source->name, targetName);
        return true;
    }
};

class CoAPtrCharacterCopyWorld final : public WorldScript
{
public:
    CoAPtrCharacterCopyWorld() : WorldScript("CoAPtrCharacterCopyWorld", { WORLDHOOK_ON_UPDATE }) { }

    void OnUpdate(uint32 diff) override
    {
        _queries.ProcessReadyCallbacks();
        _sinceLastPoll += diff;
        if (_sinceLastPoll < PollIntervalMs)
            return;
        _sinceLastPoll = 0;

        Settings const settings = LoadSettings();
        if (settings.receive && !_loadingCopy)
        {
            _loadingCopy = true;
            _queries.AddCallback(LoginDatabase.AsyncQuery(NextCopyRequestQuery()).WithCallback(
                [this](QueryResult request)
                {
                    ProcessNextCopyRequest(std::move(request));
                    _loadingCopy = false;
                }));
        }
        if (settings.targetRealm && !_notifying)
        {
            _notifying = true;
            _queries.AddCallback(LoginDatabase.AsyncQuery(FinishedCopiesQuery()).WithCallback(
                [this](QueryResult finished)
                {
                    NotifyFinishedCopies(std::move(finished));
                    _notifying = false;
                }));
        }
    }

private:
    QueryCallbackProcessor _queries;
    uint32 _sinceLastPoll = 0;
    bool _loadingCopy = false;
    bool _notifying = false;
};

void AddSC_CoAPtrCharacterCopy()
{
    for (char const* table : {
        "character_appearance", "character_appearance_outfit", "character_appearance_settings",
        "character_ascension_state", "character_brew_of_the_month", "character_callboard_contract",
        "character_manastorm_completed_depth", "character_manastorm_completion_reward_state",
        "character_manastorm_pending_currency", "character_manastorm_pending_experience",
        "character_manastorm_pending_unlock", "character_manastorm_progress", "character_manastorm_reward_state",
        "character_manastorm_stage_receipt", "character_manastorm_unlock", "character_manastorm_weekly_cache",
        "character_settings", "character_worldforged_loot",
        "ascension_manastorm_bonus", "ascension_manastorm_clear", "ascension_manastorm_loadout",
        "ascension_manastorm_xp", "manastorm_weekly_cache_lockout", "coa_build_creator_active",
        "coa_challenge_completion", "coa_challenge_failure", "coa_character_challenge", "coa_character_condition",
        "coa_character_fatigue", "coa_character_gamemode", "coa_character_gamemode_lives",
        "coa_character_objective", "coa_character_survival", "coa_custom_trial", "coa_custom_trial_active",
        "coa_custom_trial_completion", "coa_custom_trial_entry", "coa_custom_trial_vote", "coa_mystic_enchant",
        "coa_mystic_enchant_known", "coa_mystic_enchant_slot", "coa_mythic_best", "coa_mythic_weekly",
        "mod_craftsmans_codex" })
        PlayerDump::RegisterCharacterTable(table);

    constexpr char const* characterBankOwner = "owner_kind = 0";
    for (char const* table : { "mod_ascension_bank_tab", "mod_ascension_bank_money" })
        PlayerDump::RegisterOwnedTable(table, "owner_id", characterBankOwner);
    PlayerDump::RegisterOwnedTable("mod_ascension_bank_item", "owner_id", characterBankOwner, { "item_guid" });

    PlayerDump::RegisterItemTable("character_item_scaling", "item_guid");
    PlayerDump::RegisterItemTable("coa_mc_fire_lord_cache_tier", "ItemGuid");
    PlayerDump::RegisterItemTable("ascension_manastorm_cache", "item", "guid");
    PlayerDump::RegisterItemTable("coa_character_looted_item", "itemGuid", "guid");

    new CoAPtrCharacterCopyCommands();
    new CoAPtrCharacterCopyWorld();
}
