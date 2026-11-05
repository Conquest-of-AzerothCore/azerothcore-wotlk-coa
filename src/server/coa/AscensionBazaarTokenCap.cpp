/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionBazaarTokenCap.h"
#include "CharacterCache.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Player.h"
#include "StringFormat.h"
#include "WorldSession.h"
#include <algorithm>
#include <limits>
#include <mutex>
#include <unordered_map>

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 CAPPED_REMINDER_INTERVAL_SECONDS = 300;

struct Window
{
    uint32 start = 0;
    uint32 earned = 0;
    uint32 lastNotice = 0;
};

std::mutex capLock;
std::unordered_map<uint32, Window> windows;

uint32 Now()
{
    return uint32(GameTime::GetGameTime().count());
}

uint32 WindowSeconds()
{
    return std::max<uint32>(1, sConfigMgr->GetOption<uint32>("CoA.BazaarTokens.HourlyCap.WindowSeconds", 3600));
}

Window& WindowRef(uint32 accountId)
{
    auto itr = windows.find(accountId);
    if (itr != windows.end())
        return itr->second;

    Window window;
    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_BAZAAR_TOKEN_HOURLY_CAP);
    stmt->SetData(0, accountId);
    if (PreparedQueryResult result = CharacterDatabase.Query(stmt))
    {
        window.start = (*result)[0].Get<uint32>();
        window.earned = (*result)[1].Get<uint32>();
    }

    return windows.emplace(accountId, window).first->second;
}

void Write(CharacterDatabaseStatements statement, uint32 accountId, Window const& window)
{
    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(statement);
    stmt->SetData(0, accountId);
    stmt->SetData(1, window.start);
    stmt->SetData(2, window.earned);
    CharacterDatabase.Execute(stmt);
}

void SaveIfNewer(uint32 accountId, Window const& window)
{
    Write(CHAR_INS_BAZAAR_TOKEN_HOURLY_CAP_IF_NEWER, accountId, window);
}

void Overwrite(uint32 accountId, Window const& window)
{
    Write(CHAR_REP_BAZAAR_TOKEN_HOURLY_CAP, accountId, window);
}

bool Expired(Window const& window, uint32 now)
{
    return !window.start || now >= window.start + WindowSeconds();
}

uint32 MinutesLeft(Window const& window, uint32 now)
{
    uint32 const end = window.start + WindowSeconds();
    return end > now ? (end - now + 59) / 60 : 0;
}
}

uint32 AscensionBazaarTokenCap::GetCap()
{
    return sConfigMgr->GetOption<uint32>("CoA.BazaarTokens.HourlyCap.Amount", 0);
}

uint32 AscensionBazaarTokenCap::Claim(Player* player, uint32 count)
{
    uint32 const cap = GetCap();
    if (!player || !player->GetSession() || !count || !cap)
        return count;

    uint32 const accountId = player->GetSession()->GetAccountId();
    uint32 const now = Now();
    uint32 allowed = 0;
    uint32 minutesLeft = 0;
    bool notify = false;
    {
        std::lock_guard<std::mutex> guard(capLock);
        Window& window = WindowRef(accountId);
        if (Expired(window, now))
            window = Window{ now, 0, 0 };

        allowed = window.earned < cap ? std::min(count, cap - window.earned) : 0;
        if (allowed)
        {
            window.earned += allowed;
            SaveIfNewer(accountId, window);
        }

        if (window.earned >= cap && (allowed || now >= window.lastNotice + CAPPED_REMINDER_INTERVAL_SECONDS))
        {
            window.lastNotice = now;
            minutesLeft = MinutesLeft(window, now);
            notify = true;
        }
    }

    if (notify)
        ChatHandler(player->GetSession()).PSendSysMessage(
            "You have reached the limit of {} Bazaar Tokens per hour. You can earn Bazaar Tokens again in {} min.",
            cap, std::max<uint32>(1, minutesLeft));

    return allowed;
}

uint32 AscensionBazaarTokenCap::LimitReward(Player* player, uint32 itemId, uint32 count)
{
    return itemId == TOKEN_ITEM ? Claim(player, count) : count;
}

std::string AscensionBazaarTokenCap::Describe(uint32 accountId)
{
    uint32 const cap = GetCap();
    if (!cap)
        return "Bazaar Tokens have no hourly limit.";

    uint32 const now = Now();
    std::lock_guard<std::mutex> guard(capLock);
    Window const& window = WindowRef(accountId);
    if (Expired(window, now))
        return Acore::StringFormat("Bazaar Tokens this hour: 0 of {}. The hour starts with the next token earned.", cap);

    return Acore::StringFormat("Bazaar Tokens this hour: {} of {}. The hour ends in {} min.",
        std::min(window.earned, cap), cap, std::max<uint32>(1, MinutesLeft(window, now)));
}

void AscensionBazaarTokenCap::Set(uint32 accountId, uint32 earned, uint32 secondsAgo)
{
    uint32 const now = Now();
    std::lock_guard<std::mutex> guard(capLock);
    Window& window = WindowRef(accountId);
    window = Window{ now - std::min(secondsAgo, now), earned, 0 };
    Overwrite(accountId, window);
}

class AscensionBazaarTokenCapCommands final : public CommandScript
{
public:
    AscensionBazaarTokenCapCommands() : CommandScript("AscensionBazaarTokenCapCommands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable capTable =
        {
            { "", HandleStatus, SEC_PLAYER, Console::No },
            { "set", HandleSet, SEC_GAMEMASTER, Console::Yes },
            { "reset", HandleReset, SEC_GAMEMASTER, Console::Yes },
        };
        static ChatCommandTable commandTable =
        {
            { "tokencap", capTable },
        };
        return commandTable;
    }

    static bool HandleStatus(ChatHandler* handler)
    {
        handler->SendSysMessage(AscensionBazaarTokenCap::Describe(handler->GetSession()->GetAccountId()));
        return true;
    }

    static bool HandleSet(ChatHandler* handler, Optional<PlayerIdentifier> target, uint32 earned,
        Optional<uint32> minutesAgo)
    {
        return Change(handler, target, earned, minutesAgo.value_or(0) * 60);
    }

    static bool HandleReset(ChatHandler* handler, Optional<PlayerIdentifier> target)
    {
        return Change(handler, target, 0, std::numeric_limits<uint32>::max());
    }

private:
    static bool Change(ChatHandler* handler, Optional<PlayerIdentifier> target, uint32 earned, uint32 secondsAgo)
    {
        if (!target)
            target = PlayerIdentifier::FromTargetOrSelf(handler);
        if (!target)
        {
            handler->SendErrorMessage(LANG_PLAYER_NOT_FOUND);
            return false;
        }

        uint32 const accountId = target->IsConnected()
            ? target->GetConnectedPlayer()->GetSession()->GetAccountId()
            : sCharacterCache->GetCharacterAccountIdByGuid(target->GetGUID());
        if (!accountId)
        {
            handler->SendErrorMessage(LANG_PLAYER_NOT_FOUND);
            return false;
        }

        AscensionBazaarTokenCap::Set(accountId, earned, secondsAgo);
        handler->PSendSysMessage("{} (account {}): {}", target->GetName(), accountId,
            AscensionBazaarTokenCap::Describe(accountId));
        return true;
    }
};

void AddSC_AscensionBazaarTokenCap()
{
    new AscensionBazaarTokenCapCommands();
}
