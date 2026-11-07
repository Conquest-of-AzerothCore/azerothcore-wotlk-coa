/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CoAPtrCharacterCopy.h"
#include "AccountMgr.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "ObjectMgr.h"
#include "PlayerDump.h"
#include "StringFormat.h"
#include "World.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <cctype>
#include <optional>

using namespace Acore::ChatCommands;

namespace
{
std::atomic<bool> testOverrideActive = false;

struct Settings
{
    bool enabled = false;
    bool requireSourceOffline = true;
    std::string sourceSchema;
    std::string sourceRealm;
    uint32 cooldownSeconds = 0;
};

struct SourceCharacter
{
    uint32 guid = 0;
    std::string name;
    bool online = false;
};

struct CopyRecord
{
    uint32 targetGuid = 0;
    uint32 copiedAt = 0;
};

uint32 Now()
{
    return uint32(GameTime::GetGameTime().count());
}

std::string CurrentSchema()
{
    QueryResult result = CharacterDatabase.Query("SELECT DATABASE()");
    return result ? result->Fetch()[0].Get<std::string>() : std::string();
}

bool IsPlainSchemaName(std::string const& name)
{
    return !name.empty() && std::all_of(name.begin(), name.end(), [](unsigned char c)
    {
        return std::isalnum(c) || c == '_' || c == '$';
    });
}

Settings LoadSettings()
{
    Settings settings;
    settings.sourceRealm = sConfigMgr->GetOption<std::string>("CoA.PtrCopy.SourceRealmName", "Rexxar");
    if (testOverrideActive)
    {
        settings.enabled = true;
        settings.requireSourceOffline = false;
        settings.sourceSchema = CurrentSchema();
        return settings;
    }

    settings.enabled = sConfigMgr->GetOption<bool>("CoA.PtrCopy.Enable", false);
    settings.sourceSchema = sConfigMgr->GetOption<std::string>("CoA.PtrCopy.SourceDatabase", "");
    settings.cooldownSeconds = sConfigMgr->GetOption<uint32>("CoA.PtrCopy.CooldownSeconds", 3600);
    return settings;
}

std::optional<SourceCharacter> FindSource(Settings const& settings, uint32 accountId, std::string name)
{
    CharacterDatabase.EscapeString(name);
    QueryResult result = CharacterDatabase.Query(
        "SELECT guid, name, online FROM `{}`.characters WHERE account = {} AND name = '{}'",
        settings.sourceSchema, accountId, name);
    if (!result)
        return std::nullopt;

    Field* fields = result->Fetch();
    return SourceCharacter{ fields[0].Get<uint32>(), fields[1].Get<std::string>(), fields[2].Get<uint8>() != 0 };
}

std::optional<CopyRecord> FindRecord(uint32 sourceGuid)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT target_guid, copied_at FROM coa_ptr_character_copy WHERE source_guid = {}", sourceGuid);
    if (!result)
        return std::nullopt;

    Field* fields = result->Fetch();
    return CopyRecord{ fields[0].Get<uint32>(), fields[1].Get<uint32>() };
}

std::optional<std::string> LiveCopyName(uint32 targetGuid, uint32 accountId)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT name FROM characters WHERE guid = {} AND account = {}", targetGuid, accountId);
    if (!result)
        return std::nullopt;
    return result->Fetch()[0].Get<std::string>();
}

bool RejectUnavailable(ChatHandler* handler, Settings const& settings)
{
    if (!settings.enabled)
    {
        handler->SendErrorMessage("Character copies are not enabled on this realm.", false);
        return true;
    }

    if (!IsPlainSchemaName(settings.sourceSchema))
    {
        handler->SendErrorMessage("Character copies are not configured on this realm.", false);
        return true;
    }

    return false;
}

std::string CopyFailureText(DumpReturn result)
{
    switch (result)
    {
        case DUMP_TOO_MANY_CHARS:
            return "Your account has no free character slot on this realm.";
        case DUMP_CHARACTER_DELETED:
            return "That character is deleted.";
        default:
            return "The character could not be copied. Nothing was changed.";
    }
}
}

namespace PtrCharacterCopy
{
TestOverride::TestOverride()
{
    testOverrideActive = true;
}

TestOverride::~TestOverride()
{
    testOverrideActive = false;
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
        if (RejectUnavailable(handler, settings))
            return false;

        uint32 const accountId = handler->GetSession()->GetAccountId();
        QueryResult result = CharacterDatabase.Query(
            "SELECT s.name, s.level, t.name FROM `{}`.characters s "
            "LEFT JOIN coa_ptr_character_copy c ON c.source_guid = s.guid "
            "LEFT JOIN characters t ON t.guid = c.target_guid AND t.account = {} "
            "WHERE s.account = {} ORDER BY s.name",
            settings.sourceSchema, accountId, accountId);
        if (!result)
        {
            handler->PSendSysMessage("You have no characters on {}.", settings.sourceRealm);
            return true;
        }

        handler->PSendSysMessage("Your characters on {}:", settings.sourceRealm);
        do
        {
            Field* fields = result->Fetch();
            std::string const copy = fields[2].IsNull()
                ? std::string("not copied")
                : Acore::StringFormat("copied as {}", fields[2].Get<std::string>());
            handler->PSendSysMessage("  {} (level {}): {}", fields[0].Get<std::string>(), fields[1].Get<uint8>(),
                copy);
        } while (result->NextRow());
        handler->SendSysMessage("Copy one with .ptr copy <name>.");
        return true;
    }

    static bool HandleCopy(ChatHandler* handler, std::string name)
    {
        Settings const settings = LoadSettings();
        if (RejectUnavailable(handler, settings))
            return false;

        uint32 const accountId = handler->GetSession()->GetAccountId();
        std::optional<SourceCharacter> source;
        if (normalizePlayerName(name))
            source = FindSource(settings, accountId, name);
        if (!source)
        {
            handler->SendErrorMessage(Acore::StringFormat("Your account has no character named {} on {}.", name,
                settings.sourceRealm), false);
            return false;
        }

        if (settings.requireSourceOffline && source->online)
        {
            handler->SendErrorMessage(Acore::StringFormat("Log {} out of {} before copying it.", source->name,
                settings.sourceRealm), false);
            return false;
        }

        uint32 const now = Now();
        if (std::optional<CopyRecord> record = FindRecord(source->guid))
        {
            if (std::optional<std::string> copyName = LiveCopyName(record->targetGuid, accountId))
            {
                handler->SendErrorMessage(Acore::StringFormat(
                    "{} is already copied here as {}. Delete that character to copy it again.", source->name,
                    *copyName), false);
                return false;
            }

            uint32 const readyAt = record->copiedAt + settings.cooldownSeconds;
            if (now < readyAt)
            {
                handler->SendErrorMessage(Acore::StringFormat("You can copy {} again in {} min.", source->name,
                    (readyAt - now + 59) / 60), false);
                return false;
            }
        }

        if (AccountMgr::GetCharactersCount(accountId) >= sWorld->getIntConfig(CONFIG_CHARACTERS_PER_REALM))
        {
            handler->SendErrorMessage(CopyFailureText(DUMP_TOO_MANY_CHARS), false);
            return false;
        }

        std::string dump;
        DumpReturn result = PlayerDumpWriter(settings.sourceSchema).WriteDumpToString(dump, source->guid);
        PlayerDumpReader::LoadOptions loadOptions;
        loadOptions.DirectCommit = true;
        loadOptions.PlayerMailFromCopy = true;
        PlayerDumpReader reader(loadOptions);
        if (result == DUMP_SUCCESS)
            result = reader.LoadDumpFromString(dump, accountId, source->name, 0);
        if (result != DUMP_SUCCESS)
        {
            handler->SendErrorMessage(CopyFailureText(result), false);
            return false;
        }

        CharacterDatabase.DirectExecute(
            "REPLACE INTO coa_ptr_character_copy (source_guid, account, target_guid, copied_at) "
            "VALUES ({}, {}, {}, {})", source->guid, accountId, reader.GetLoadedGuid(), now);

        handler->PSendSysMessage("{} was copied from {}. Log out to the character screen to play it.",
            source->name, settings.sourceRealm);
        if (reader.GetLoadedName() != source->name)
            handler->SendSysMessage("That name is taken on this realm, so you will choose a new one at login.");
        return true;
    }
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
}
