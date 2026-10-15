/*
 * Account-wide unlocks for the upgrade tiers above the first.
 *
 * A tier opens once any character of the account has seen its raid boss die.
 * The kill is written straight away, so another character of the same account
 * can buy the upgrade the moment the boss falls.
 *
 * Kills made before the table existed are still on record as achievement
 * statistics: every kill-creature criterion counts the boss on each character.
 * The first purchase that finds no row looks there and keeps what it finds.
 */

#include "WorldforgedUpgrades.h"

#include "AchievementMgr.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Map.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"

#include <set>
#include <string>

namespace
{
    void RecordUnlock(uint32 accountId, uint32 creature)
    {
        CharacterDatabase.DirectExecute(
            "INSERT IGNORE INTO worldforged_account_unlock (account, creature) VALUES ({}, {})",
            accountId, creature);
    }

    std::string KillCriteriaOf(uint32 creature)
    {
        std::string ids;
        if (AchievementCriteriaEntryList const* criteria =
                sAchievementMgr->GetAchievementCriteriaByType(ACHIEVEMENT_CRITERIA_TYPE_KILL_CREATURE))
            for (AchievementCriteriaEntry const* entry : *criteria)
                if (entry->kill_creature.creatureID == creature)
                    ids += (ids.empty() ? "" : ",") + std::to_string(entry->ID);
        return ids;
    }

    bool KilledOnRecord(uint32 accountId, uint32 creature)
    {
        std::string const criteria = KillCriteriaOf(creature);
        if (criteria.empty())
            return false;

        return CharacterDatabase.Query(
            "SELECT 1 FROM character_achievement_progress p JOIN characters c ON c.guid = p.guid "
            "WHERE c.account = {} AND p.criteria IN ({}) AND p.counter > 0 LIMIT 1",
            accountId, criteria) != nullptr;
    }
}

namespace Worldforged
{
    bool IsUnlocked(uint32 accountId, uint32 creature)
    {
        if (!creature)
            return true;

        if (CharacterDatabase.Query(
                "SELECT 1 FROM worldforged_account_unlock WHERE account = {} AND creature = {}",
                accountId, creature))
            return true;

        if (!KilledOnRecord(accountId, creature))
            return false;

        RecordUnlock(accountId, creature);
        return true;
    }
}

class worldforged_unlock_kill : public UnitScript
{
public:
    worldforged_unlock_kill() : UnitScript("worldforged_unlock_kill", true, {UNITHOOK_ON_UNIT_DEATH}) { }

    void OnUnitDeath(Unit* unit, Unit*) override
    {
        Creature* dead = unit->ToCreature();
        if (!dead || !dead->GetMap()->IsDungeon() || !Worldforged::IsUnlockCreature(dead->GetEntry()))
            return;

        std::set<uint32> accounts;
        for (MapReference const& reference : dead->GetMap()->GetPlayers())
            if (Player* player = reference.GetSource())
                accounts.insert(player->GetSession()->GetAccountId());

        for (uint32 accountId : accounts)
            RecordUnlock(accountId, dead->GetEntry());
    }
};

void AddWorldforgedUnlockScripts()
{
    new worldforged_unlock_kill();
}
