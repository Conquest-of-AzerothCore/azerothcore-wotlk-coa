/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionCharacterSelection.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Player.h"
#include "QueryResult.h"
#include "StringFormat.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <algorithm>
#include <cstdint>
#include <string>
#include <vector>

namespace
{
    constexpr uint16 CMSG_ASCENSION_CHARACTER_ACTIVATE = 0x072E;
    constexpr uint16 CMSG_ASCENSION_CHARACTER_DEACTIVATE = 0x072F;
    constexpr uint16 CMSG_ASCENSION_CHARACTER_SORT_ORDER = 0x0772;
    constexpr uint16 SMSG_ASCENSION_CHARACTER_LIST_INFO = 0x075E;
    constexpr uint16 SMSG_ASCENSION_CHARACTER_ACTIVATE_RESULT = 0x075F;
    constexpr uint16 SMSG_ASCENSION_CHARACTER_DEACTIVATE_RESULT = 0x0760;
    constexpr uint16 SMSG_ASCENSION_CHARACTER_SORT_ORDER = 0x076F;
    constexpr uint16 SMSG_ASCENSION_CHARACTER_SELECTION_MAIL = 0x0770;
    constexpr uint16 SMSG_ASCENSION_CHARACTER_SELECTION_GAME_MODE = 0x0771;

    constexpr uint32 CHARACTER_SELECTION_FACTION_ALLIANCE = 469;
    constexpr uint32 CHARACTER_SELECTION_FACTION_HORDE = 67;
    constexpr uint8 CHARACTER_SELECTION_RULESET_NONE = 0;
    constexpr uint8 CHARACTER_SELECTION_RULESET_HIGH_RISK = 1;

    constexpr uint32 SPELL_ASCENSION_HIGH_RISK = 1004019;

    constexpr char ACTIVATE_CHARACTER_OK[] = "ACTIVATE_CHARACTER_OK";
    constexpr char ACTIVATE_CHARACTER_NOT_FOUND[] = "ACTIVATE_CHARACTER_NOT_FOUND";
    constexpr char ACTIVATE_CHARACTER_NOT_OWNED[] = "ACTIVATE_CHARACTER_NOT_OWNED";
    constexpr char ACTIVATE_CHARACTER_ALREADY_ACTIVE[] = "ACTIVATE_CHARACTER_ALREADY_ACTIVE";
    constexpr char ACTIVATE_CHARACTER_MAX_ACTIVE[] = "ACTIVATE_CHARACTER_MAX_ACTIVE";
    constexpr char ACTIVATE_CHARACTER_ONLINE[] = "ACTIVATE_CHARACTER_ONLINE";
    constexpr char ACTIVATE_CHARACTER_FAILED[] = "ACTIVATE_CHARACTER_FAILED";

    constexpr char DEACTIVATE_CHARACTER_OK[] = "DEACTIVATE_CHARACTER_OK";
    constexpr char DEACTIVATE_CHARACTER_NOT_FOUND[] = "DEACTIVATE_CHARACTER_NOT_FOUND";
    constexpr char DEACTIVATE_CHARACTER_NOT_OWNED[] = "DEACTIVATE_CHARACTER_NOT_OWNED";
    constexpr char DEACTIVATE_CHARACTER_ALREADY_INACTIVE[] = "DEACTIVATE_CHARACTER_ALREADY_INACTIVE";
    constexpr char DEACTIVATE_CHARACTER_ONLINE[] = "DEACTIVATE_CHARACTER_ONLINE";
    constexpr char DEACTIVATE_CHARACTER_FAILED[] = "DEACTIVATE_CHARACTER_FAILED";

    constexpr uint32 CHARACTER_LIST_MAXIMUM = 128;
    constexpr std::size_t SORT_ORDER_PAYLOAD_MAXIMUM = 1023;

    bool CharacterSelectionEnabled()
    {
        return sConfigMgr->GetOption<bool>("CoA.CharacterSelectionEnable", true);
    }

    uint32 CharacterSelectionMaxActive()
    {
        uint32 const maximum = sConfigMgr->GetOption<uint32>(
            "CoA.CharacterSelectionMaxActive", 128);
        return std::clamp(maximum, uint32(1), CHARACTER_LIST_MAXIMUM);
    }

    uint32 CharacterSelectionActiveGameModes()
    {
        return 0;
    }

    uint32 CharacterSelectionEnabledGameModes()
    {
        return 0;
    }

    uint32 CharacterSelectionTeamId(uint8 race)
    {
        switch (Player::TeamIdForRace(race))
        {
            case TEAM_ALLIANCE:
                return CHARACTER_SELECTION_FACTION_ALLIANCE;
            case TEAM_HORDE:
                return CHARACTER_SELECTION_FACTION_HORDE;
            default:
                return 0;
        }
    }

    void SendCharacterSelectionPerCharacter(WorldSession* session, uint32 listIndex, uint8 race,
        bool highRisk, bool hasMail)
    {
        WorldPacket gameMode(SMSG_ASCENSION_CHARACTER_SELECTION_GAME_MODE, 18);
        gameMode << listIndex
                 << CharacterSelectionActiveGameModes()
                 << CharacterSelectionEnabledGameModes()
                 << CharacterSelectionTeamId(race)
                 << uint8(0)
                 << uint8(highRisk ? CHARACTER_SELECTION_RULESET_HIGH_RISK
                                   : CHARACTER_SELECTION_RULESET_NONE);
        session->SendPacket(&gameMode);

        WorldPacket mail(SMSG_ASCENSION_CHARACTER_SELECTION_MAIL, 6);
        mail << listIndex
             << uint8(hasMail ? 1 : 0)
             << uint8(0);
        session->SendPacket(&mail);
    }

    void SendResult(WorldSession* session, uint16 opcode, char const* result)
    {
        WorldPacket packet(opcode, 64);
        packet << result;
        session->SendPacket(&packet);
    }

    std::string BuildCharacterStateQuery(uint32 charGuid)
    {
        return Acore::StringFormat(
            "SELECT `c`.`account`, `c`.`online`, COALESCE(`s`.`active` <> 0, 1), "
            "(SELECT COUNT(*) FROM `characters` AS `c2` "
            "LEFT JOIN `character_ascension_state` AS `s2` ON `s2`.`guid` = `c2`.`guid` "
            "WHERE `c2`.`account` = `c`.`account` AND (`s2`.`active` IS NULL OR `s2`.`active` <> 0)) "
            "FROM `characters` AS `c` "
            "LEFT JOIN `character_ascension_state` AS `s` ON `s`.`guid` = `c`.`guid` "
            "WHERE `c`.`guid` = {}", charGuid);
    }

    void HandleActivateRequest(WorldSession* session, WorldPacket const& packet)
    {
        if (packet.size() < sizeof(uint32))
        {
            SendResult(session, SMSG_ASCENSION_CHARACTER_ACTIVATE_RESULT, ACTIVATE_CHARACTER_FAILED);
            return;
        }

        uint32 const charGuid = packet.read<uint32>(0);
        uint32 const accountId = session->GetAccountId();

        session->QueueQueryCallback(
            CharacterDatabase.AsyncQuery(BuildCharacterStateQuery(charGuid)).WithCallback(
                [session, accountId, charGuid](QueryResult result)
                {
                    if (!result || result->GetRowCount() == 0)
                    {
                        SendResult(session, SMSG_ASCENSION_CHARACTER_ACTIVATE_RESULT, ACTIVATE_CHARACTER_NOT_FOUND);
                        return;
                    }

                    Field* fields = result->Fetch();

                    if (fields[0].Get<uint32>() != accountId)
                    {
                        SendResult(session, SMSG_ASCENSION_CHARACTER_ACTIVATE_RESULT, ACTIVATE_CHARACTER_NOT_OWNED);
                        return;
                    }

                    if (fields[1].Get<uint8>() != 0)
                    {
                        SendResult(session, SMSG_ASCENSION_CHARACTER_ACTIVATE_RESULT, ACTIVATE_CHARACTER_ONLINE);
                        return;
                    }

                    if (fields[2].Get<uint32>() != 0)
                    {
                        SendResult(session, SMSG_ASCENSION_CHARACTER_ACTIVATE_RESULT, ACTIVATE_CHARACTER_ALREADY_ACTIVE);
                        return;
                    }

                    uint64 const activeCount = fields[3].Get<uint64>();
                    if (activeCount >= CharacterSelectionMaxActive())
                    {
                        SendResult(session, SMSG_ASCENSION_CHARACTER_ACTIVATE_RESULT, ACTIVATE_CHARACTER_MAX_ACTIVE);
                        return;
                    }

                    CharacterDatabase.Execute(
                        "INSERT INTO `character_ascension_state` (`guid`, `active`) VALUES ({}, 1) "
                        "ON DUPLICATE KEY UPDATE `active` = 1", charGuid);

                    SendResult(session, SMSG_ASCENSION_CHARACTER_ACTIVATE_RESULT, ACTIVATE_CHARACTER_OK);

                    sWorld->UpdateRealmCharCount(accountId);

                    LOG_INFO("coa",
                        "Activated character {} for account {} ({}/{} active characters)",
                        charGuid, accountId, activeCount + 1, CharacterSelectionMaxActive());
                }));
    }

    void HandleDeactivateRequest(WorldSession* session, WorldPacket const& packet)
    {
        if (packet.size() < sizeof(uint32))
        {
            SendResult(session, SMSG_ASCENSION_CHARACTER_DEACTIVATE_RESULT, DEACTIVATE_CHARACTER_FAILED);
            return;
        }

        uint32 const charGuid = packet.read<uint32>(0);
        uint32 const accountId = session->GetAccountId();

        session->QueueQueryCallback(
            CharacterDatabase.AsyncQuery(BuildCharacterStateQuery(charGuid)).WithCallback(
                [session, accountId, charGuid](QueryResult result)
                {
                    if (!result || result->GetRowCount() == 0)
                    {
                        SendResult(session, SMSG_ASCENSION_CHARACTER_DEACTIVATE_RESULT, DEACTIVATE_CHARACTER_NOT_FOUND);
                        return;
                    }

                    Field* fields = result->Fetch();

                    if (fields[0].Get<uint32>() != accountId)
                    {
                        SendResult(session, SMSG_ASCENSION_CHARACTER_DEACTIVATE_RESULT, DEACTIVATE_CHARACTER_NOT_OWNED);
                        return;
                    }

                    if (fields[1].Get<uint8>() != 0)
                    {
                        SendResult(session, SMSG_ASCENSION_CHARACTER_DEACTIVATE_RESULT, DEACTIVATE_CHARACTER_ONLINE);
                        return;
                    }

                    if (fields[2].Get<uint32>() == 0)
                    {
                        SendResult(session, SMSG_ASCENSION_CHARACTER_DEACTIVATE_RESULT, DEACTIVATE_CHARACTER_ALREADY_INACTIVE);
                        return;
                    }

                    CharacterDatabase.Execute(
                        "INSERT INTO `character_ascension_state` (`guid`, `active`) VALUES ({}, 0) "
                        "ON DUPLICATE KEY UPDATE `active` = 0", charGuid);

                    SendResult(session, SMSG_ASCENSION_CHARACTER_DEACTIVATE_RESULT, DEACTIVATE_CHARACTER_OK);

                    sWorld->UpdateRealmCharCount(accountId);

                    LOG_INFO("coa",
                        "Deactivated character {} for account {}", charGuid, accountId);
                }));
    }

    void HandleSortOrderRequest(WorldSession* session, WorldPacket const& packet)
    {
        WorldPacket readable = packet;
        std::string payload;
        readable >> payload;

        if (payload.empty())
        {
            LOG_DEBUG("coa",
                "Ignored empty character-selection sort order from account {}",
                session->GetAccountId());
            return;
        }

        if (payload.size() > SORT_ORDER_PAYLOAD_MAXIMUM)
        {
            LOG_ERROR("coa",
                "Account {} sent an oversized character-selection sort order ({} bytes); ignored",
                session->GetAccountId(), payload.size());
            return;
        }

        std::string escaped = payload;
        CharacterDatabase.EscapeString(escaped);

        CharacterDatabase.Execute(
            "INSERT INTO `account_ascension_settings` (`account_id`, `sort_order`) VALUES ({}, '{}') "
            "ON DUPLICATE KEY UPDATE `sort_order` = VALUES(`sort_order`)",
            session->GetAccountId(), escaped);

        LOG_DEBUG("coa",
            "Stored character-selection sort order for account {} ({} bytes)",
            session->GetAccountId(), payload.size());
    }

    void HandleCharacterListQuery(WorldSession* session, uint32 maxActive, QueryResult result)
    {
        struct CharacterSelectionExtra
        {
            uint32 index;
            uint8 race;
            bool highRisk;
            bool hasMail;
        };

        std::vector<CharacterSelectionExtra> extras;
        extras.reserve(CHARACTER_LIST_MAXIMUM);

        uint32 total = 0;
        uint32 activeCount = 0;
        uint32 listIndex = 0;
        std::string sortOrder;

        WorldPacket info(SMSG_ASCENSION_CHARACTER_LIST_INFO, 256);
        info << maxActive << uint32(0) << uint32(0) << uint32(0);

        if (result && result->GetRowCount() != 0)
        {
            do
            {
                Field* fields = result->Fetch();

                uint8 const active = fields[8].Get<uint32>() != 0 ? 1 : 0;
                ++total;
                activeCount += active;

                if (total == 1)
                    sortOrder = fields[9].Get<std::string>();

                uint32 const guid = fields[0].Get<uint32>();
                uint8 const race = fields[4].Get<uint8>();

                if (active != 0)
                {
                    extras.push_back({ ++listIndex, race,
                        fields[10].Get<uint64>() != 0, fields[11].Get<uint64>() != 0 });
                }

                info << guid
                     << active
                     << uint8(fields[2].Get<uint8>() != 0 ? 1 : 0)
                     << fields[3].Get<uint8>()
                     << race
                     << fields[5].Get<uint8>()
                     << fields[6].Get<uint8>()
                     << fields[7].Get<uint32>()
                     << fields[1].Get<std::string>();
            } while (result->NextRow());
        }

        info.put<uint32>(4, total);
        info.put<uint32>(8, activeCount);
        info.put<uint32>(12, total - activeCount);

        if (sortOrder.empty())
        {
            for (uint32 i = 1; i <= maxActive; ++i)
            {
                if (i > 1)
                    sortOrder += ' ';
                sortOrder += std::to_string(i);
            }
        }

        WorldPacket order(SMSG_ASCENSION_CHARACTER_SORT_ORDER, sortOrder.size() + 8);
        order << sortOrder;
        session->SendPacket(&order);

        for (CharacterSelectionExtra const& extra : extras)
        {
            SendCharacterSelectionPerCharacter(session, extra.index, extra.race,
                extra.highRisk, extra.hasMail);
        }

        session->SendPacket(&info);

        LOG_DEBUG("coa",
            "Sent Ascension character list for account {}: max={}, total={}, active={}, inactive={}, extras={}, sort order={} bytes",
            session->GetAccountId(), maxActive, total, activeCount, total - activeCount, extras.size(), sortOrder.size());
    }
}

bool IsAscensionCharacterSelectionOpcode(uint16 opcode)
{
    return opcode == CMSG_ASCENSION_CHARACTER_ACTIVATE ||
           opcode == CMSG_ASCENSION_CHARACTER_DEACTIVATE ||
           opcode == CMSG_ASCENSION_CHARACTER_SORT_ORDER;
}

bool HandleAscensionCharacterSelectionPacket(WorldSession* session, WorldPacket const& packet)
{
    if (!session || !CharacterSelectionEnabled())
        return false;

    switch (uint16(packet.GetOpcode()))
    {
        case CMSG_ASCENSION_CHARACTER_ACTIVATE:
            HandleActivateRequest(session, packet);
            return true;
        case CMSG_ASCENSION_CHARACTER_DEACTIVATE:
            HandleDeactivateRequest(session, packet);
            return true;
        case CMSG_ASCENSION_CHARACTER_SORT_ORDER:
            HandleSortOrderRequest(session, packet);
            return true;
        default:
            return false;
    }
}

void SendAscensionCharacterListInfo(WorldSession* session)
{
    if (!session || !CharacterSelectionEnabled())
        return;

    uint32 const accountId = session->GetAccountId();
    uint32 const maxActive = CharacterSelectionMaxActive();

    std::string const query = Acore::StringFormat(
        "SELECT `c`.`guid`, `c`.`name`, `c`.`online`, `c`.`level`, `c`.`race`, `c`.`class`, `c`.`gender`, `c`.`zone`, "
        "COALESCE(`s`.`active` <> 0, 1), "
        "COALESCE((SELECT `a`.`sort_order` FROM `account_ascension_settings` AS `a` "
        "WHERE `a`.`account_id` = {}), ''), "
        "EXISTS(SELECT 1 FROM `character_aura` AS `ha` WHERE `ha`.`guid` = `c`.`guid` AND `ha`.`spell` = {}), "
        "EXISTS(SELECT 1 FROM `mail` AS `m` WHERE `m`.`receiver` = `c`.`guid` "
        "AND (`m`.`checked` & 1) = 0 AND `m`.`deliver_time` <= UNIX_TIMESTAMP()) "
        "FROM `characters` AS `c` "
        "LEFT JOIN `character_ascension_state` AS `s` ON `s`.`guid` = `c`.`guid` "
        "WHERE `c`.`account` = {} AND `c`.`deleteInfos_Name` IS NULL "
        "ORDER BY COALESCE(`s`.`active` <> 0, 1) DESC, COALESCE(`c`.`order`, `c`.`guid`)",
        accountId, SPELL_ASCENSION_HIGH_RISK, accountId);

    session->QueueQueryCallback(
        CharacterDatabase.AsyncQuery(query).WithCallback(
            [session, maxActive](QueryResult result)
            {
                HandleCharacterListQuery(session, maxActive, result);
            }));
}
