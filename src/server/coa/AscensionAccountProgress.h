#ifndef ASCENSION_ACCOUNT_PROGRESS_H
#define ASCENSION_ACCOUNT_PROGRESS_H

#include "DatabaseEnv.h"
#include "Player.h"
#include "PlayerSettings.h"
#include "WorldSession.h"

#include <string>

namespace AscensionAccountProgress
{
    inline bool HasLevelOrPrestige(Player const* player, uint8 requiredLevel)
    {
        if (!player)
            return false;

        if (player->GetLevel() >= requiredLevel)
            return true;

        constexpr char prestigeSource[] = "core.coa_prestige";
        if (PlayerSettingVector const* settings = player->FindPlayerSettings(prestigeSource);
            settings && !settings->empty() && settings->front().value > 0)
            return true;

        WorldSession const* session = player->GetSession();
        if (!session)
            return false;

        CharacterDatabasePreparedStatement* stmt =
            CharacterDatabase.GetPreparedStatement(CHAR_SEL_ACCOUNT_LEVEL_OR_PRESTIGE);
        stmt->SetData(0, std::string(prestigeSource));
        stmt->SetData(1, session->GetAccountId());
        stmt->SetData(2, player->GetGUID().GetCounter());
        PreparedQueryResult result = CharacterDatabase.Query(stmt);
        if (!result)
            return false;

        do
        {
            Field* fields = result->Fetch();
            if (fields[0].Get<uint8>() >= requiredLevel)
                return true;

            PlayerSettingVector const settings =
                PlayerSettingsStore::ParseSettingsData(fields[1].Get<std::string>());
            if (!settings.empty() && settings.front().value > 0)
                return true;
        } while (result->NextRow());

        return false;
    }
}

#endif
