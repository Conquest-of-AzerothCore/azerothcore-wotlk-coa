/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionBazaarTokenReserve.h"
#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Player.h"
#include "StringFormat.h"
#include "WorldSession.h"
#include <mutex>
#include <string>
#include <unordered_map>

namespace
{
std::mutex reserveLock;
std::unordered_map<uint32, uint32> reserves;
thread_local uint32 spendDepth = 0;

uint32& ReserveRef(uint32 accountId)
{
    auto itr = reserves.find(accountId);
    if (itr != reserves.end())
        return itr->second;

    uint32 reserve = 0;
    if (QueryResult result = CharacterDatabase.Query(
            "SELECT `reserve` FROM `account_bazaar_token_reserve` WHERE `account` = {}", accountId))
        reserve = result->Fetch()[0].Get<uint32>();

    return reserves.emplace(accountId, reserve).first->second;
}

void Store(uint32 accountId, uint32 reserve)
{
    ReserveRef(accountId) = reserve;
    if (reserve)
        CharacterDatabase.Execute("REPLACE INTO `account_bazaar_token_reserve` (`account`, `reserve`) VALUES ({}, {})",
            accountId, reserve);
    else
        CharacterDatabase.Execute("DELETE FROM `account_bazaar_token_reserve` WHERE `account` = {}", accountId);
}

void Lower(uint32 accountId, uint32 count)
{
    if (!accountId || !count)
        return;

    std::lock_guard<std::mutex> guard(reserveLock);
    uint32 const reserve = ReserveRef(accountId);
    if (reserve)
        Store(accountId, reserve > count ? reserve - count : 0);
}

uint32 QueryCount(std::string const& sql)
{
    if (QueryResult result = CharacterDatabase.Query(sql))
        return result->Fetch()[0].Get<uint32>();
    return 0;
}

uint32 CountInventory(std::string const& where)
{
    return QueryCount(Acore::StringFormat(
        "SELECT CAST(COALESCE(SUM(ii.`count`), 0) AS UNSIGNED) FROM `character_inventory` ci "
        "JOIN `item_instance` ii ON ii.`guid` = ci.`item` JOIN `characters` c ON c.`guid` = ci.`guid` "
        "WHERE ii.`itemEntry` = {} AND {}", AscensionBazaarTokenReserve::TOKEN_ITEM, where));
}

uint32 CountMail(std::string const& where)
{
    return QueryCount(Acore::StringFormat(
        "SELECT CAST(COALESCE(SUM(ii.`count`), 0) AS UNSIGNED) FROM `mail` m "
        "JOIN `mail_items` mi ON mi.`mail_id` = m.`id` JOIN `item_instance` ii ON ii.`guid` = mi.`item_guid` "
        "JOIN `characters` c ON c.`guid` = m.`receiver` "
        "WHERE ii.`itemEntry` = {} AND {}", AscensionBazaarTokenReserve::TOKEN_ITEM, where));
}
}

bool AscensionBazaarTokenReserve::IsEnabled()
{
    return sConfigMgr->GetOption<bool>("CoA.BazaarTokens.WarchestRealmBound", true);
}

uint32 AscensionBazaarTokenReserve::GetReserve(uint32 accountId)
{
    std::lock_guard<std::mutex> guard(reserveLock);
    return ReserveRef(accountId);
}

void AscensionBazaarTokenReserve::AddReserve(Player* player, uint32 count)
{
    if (!player || !player->GetSession() || !count || !IsEnabled())
        return;

    uint32 const accountId = player->GetSession()->GetAccountId();
    std::lock_guard<std::mutex> guard(reserveLock);
    Store(accountId, ReserveRef(accountId) + count);
}

void AscensionBazaarTokenReserve::OnSpent(Player* player, uint32 count)
{
    if (player && player->GetSession())
        Lower(player->GetSession()->GetAccountId(), count);
}

void AscensionBazaarTokenReserve::OnCharacterDeleted(uint32 accountId, uint32 lowGuid)
{
    if (!accountId || !GetReserve(accountId))
        return;

    std::string const where = Acore::StringFormat("c.`guid` = {} AND c.`account` = {}", lowGuid, accountId);
    Lower(accountId, CountInventory(where) + CountMail(where));
}

uint32 AscensionBazaarTokenReserve::CountAccountTokens(Player* player)
{
    uint32 const accountId = player->GetSession()->GetAccountId();
    uint32 const lowGuid = player->GetGUID().GetCounter();

    return player->GetItemCount(TOKEN_ITEM, true)
        + CountInventory(Acore::StringFormat("c.`account` = {} AND c.`guid` <> {}", accountId, lowGuid))
        + CountMail(Acore::StringFormat("c.`account` = {}", accountId));
}

bool AscensionBazaarTokenReserve::CanGiveAway(Player* player, uint32 count)
{
    if (!player || !player->GetSession() || !count || !IsEnabled())
        return true;

    uint32 const reserve = GetReserve(player->GetSession()->GetAccountId());
    if (!reserve)
        return true;

    uint32 const held = CountAccountTokens(player);
    return held >= count && held - count >= reserve;
}

void AscensionBazaarTokenReserve::SendRefusal(Player* player)
{
    if (!player || !player->GetSession())
        return;

    uint32 const reserve = GetReserve(player->GetSession()->GetAccountId());
    ChatHandler(player->GetSession()).PSendSysMessage(
        "{} of your Bazaar Tokens came from the Elite Warchest and are Realm Bound: spend them or mail them to your "
        "own characters. Only the tokens above that amount can be given to other players.", reserve);
}

AscensionBazaarTokenReserve::SpendScope::SpendScope(Player* player, uint32 itemEntry)
    : _player(itemEntry == TOKEN_ITEM && player && !spendDepth && IsEnabled() ? player : nullptr),
      _before(_player ? _player->GetItemCount(TOKEN_ITEM, true) : 0)
{
    if (_player)
        ++spendDepth;
}

AscensionBazaarTokenReserve::SpendScope::~SpendScope()
{
    if (!_player)
        return;

    --spendDepth;

    uint32 const after = _player->GetItemCount(TOKEN_ITEM, true);
    if (after < _before)
        OnSpent(_player, _before - after);
}
