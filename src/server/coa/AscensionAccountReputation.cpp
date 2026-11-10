/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionAccountReputationPolicy.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "Player.h"
#include "ReputationMgr.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

namespace
{
uint32 RaceMask(uint8 race) { return uint32(1) << (race - 1); }
uint32 ClassMask(uint8 playerClass) { return uint32(1) << (playerClass - 1); }

std::vector<AccountReputation::SiblingStanding> LoadSiblingStandings(Player* player)
{
    std::vector<AccountReputation::SiblingStanding> siblings;

    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_ACCOUNT_REPUTATIONS);
    stmt->SetData(0, player->GetSession()->GetAccountId());
    stmt->SetData(1, player->GetGUID().GetCounter());
    PreparedQueryResult result = CharacterDatabase.Query(stmt);
    if (!result)
        return siblings;

    TeamId const ownTeam = player->GetTeamId(true);
    uint32 const ownRaceMask = player->getRaceMask();
    uint32 const ownClassMask = player->getClassMask();

    do
    {
        Field* fields = result->Fetch();
        uint8 const race = fields[0].Get<uint8>();
        uint8 const playerClass = fields[1].Get<uint8>();
        FactionEntry const* faction = sFactionStore.LookupEntry(fields[2].Get<uint16>());
        if (!race || !playerClass || !faction || !faction->CanHaveReputation())
            continue;

        int32 const siblingBase = ReputationMgr::GetBaseReputation(faction, RaceMask(race), ClassMask(playerClass));
        int32 const ownBase = ReputationMgr::GetBaseReputation(faction, ownRaceMask, ownClassMask);
        bool const shared = AccountReputation::IsShared(Player::TeamIdForRace(race) == ownTeam, siblingBase, ownBase,
            ReputationMgr::GetDefaultStateFlags(faction, ownRaceMask, ownClassMask));

        int32 const earned = fields[3].Get<int32>();
        siblings.push_back({ faction->ID, siblingBase + earned, shared && AccountReputation::HasEarned(earned) });
    } while (result->NextRow());

    return siblings;
}

void RaiseToAccountStandings(Player* player)
{
    if (!player->GetSession())
        return;

    ReputationMgr& reputations = player->GetReputationMgr();
    std::map<uint32, int32> const raises = AccountReputation::StandingsToRaise(LoadSiblingStandings(player),
        [&reputations](uint32 faction) { return reputations.GetReputation(faction); });
    if (raises.empty())
        return;

    for (auto const& [faction, standing] : raises)
        reputations.SetOneFactionReputation(sFactionStore.LookupEntry(faction), float(standing), false);

    reputations.SendStates();
}

class AscensionAccountReputation : public PlayerScript
{
public:
    AscensionAccountReputation() : PlayerScript("AscensionAccountReputation", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override { RaiseToAccountStandings(player); }
};
}

void AddSC_AscensionAccountReputation()
{
    new AscensionAccountReputation();
}
