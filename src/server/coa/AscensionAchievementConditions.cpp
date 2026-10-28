/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AchievementCriteriaScript.h"
#include "AchievementMgr.h"
#include "AchievementScript.h"
#include "Player.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

namespace
{
enum GameMode : uint32
{
    GAME_MODE_IRONMAN = 0x002,
    GAME_MODE_SURVIVALIST = 0x004,
    GAME_MODE_DRAFT = 0x008,
    GAME_MODE_RESOLUTE = 0x020,
    GAME_MODE_WILDCARD = 0x040,
    GAME_MODE_FELFORGED = 0x080,
    GAME_MODE_NIGHTMARE = 0x100
};

struct GameModeCriteria
{
    char const* Name;
    uint32 Modes;
};

constexpr GameModeCriteria GAME_MODE_CRITERIA[] = {
    { "achievement_coa_game_mode_ironman", GAME_MODE_IRONMAN },
    { "achievement_coa_game_mode_survivalist", GAME_MODE_SURVIVALIST },
    { "achievement_coa_game_mode_draft", GAME_MODE_DRAFT },
    { "achievement_coa_game_mode_resolute", GAME_MODE_RESOLUTE },
    { "achievement_coa_game_mode_ironman_resolute", GAME_MODE_IRONMAN | GAME_MODE_RESOLUTE },
    { "achievement_coa_game_mode_wildcard", GAME_MODE_WILDCARD },
    { "achievement_coa_game_mode_felforged", GAME_MODE_FELFORGED },
    { "achievement_coa_game_mode_nightmare", GAME_MODE_NIGHTMARE },
    { "achievement_coa_game_mode_ironman_nightmare", GAME_MODE_IRONMAN | GAME_MODE_NIGHTMARE },
    { "achievement_coa_game_mode_survivalist_nightmare", GAME_MODE_SURVIVALIST | GAME_MODE_NIGHTMARE },
    { "achievement_coa_game_mode_resolute_nightmare", GAME_MODE_RESOLUTE | GAME_MODE_NIGHTMARE },
    { "achievement_coa_game_mode_ironman_resolute_nightmare",
        GAME_MODE_IRONMAN | GAME_MODE_RESOLUTE | GAME_MODE_NIGHTMARE }
};

class AchievementGameModeCriteria final : public AchievementCriteriaScript
{
public:
    explicit AchievementGameModeCriteria(GameModeCriteria const& criteria)
        : AchievementCriteriaScript(criteria.Name), _modes(criteria.Modes) { }

    bool OnCheck(Player* player, Unit*, uint32) override
    {
        std::optional<uint32> const mask = sScriptMgr->OnPlayerGetGameModeMask(player);
        return mask && (*mask & _modes) == _modes;
    }

private:
    uint32 _modes;
};

class RealmFirstAchievementPermission final : public PlayerScript
{
public:
    RealmFirstAchievementPermission()
        : PlayerScript("RealmFirstAchievementPermission", { PLAYERHOOK_ON_BEFORE_ACHI_COMPLETE }) { }

    bool OnPlayerBeforeAchievementComplete(Player* player, AchievementEntry const* achievement) override
    {
        if (!(achievement->flags & (ACHIEVEMENT_FLAG_REALM_FIRST_REACH | ACHIEVEMENT_FLAG_REALM_FIRST_KILL)))
            return true;

        WorldSession* session = player->GetSession();
        return !session || !session->HasPermission(rbac::RBAC_PERM_CANNOT_EARN_REALM_FIRST_ACHIEVEMENTS);
    }
};

class LearnSkillLineSpellsCriteriaDataGate final : public AchievementScript
{
public:
    LearnSkillLineSpellsCriteriaDataGate()
        : AchievementScript("LearnSkillLineSpellsCriteriaDataGate", { ACHIEVEMENTHOOK_IS_COMPLETED_CRITERIA }) { }

    bool IsCompletedCriteria(AchievementMgr* mgr, AchievementCriteriaEntry const* achievementCriteria,
        AchievementEntry const*, CriteriaProgress const*) override
    {
        if (achievementCriteria->requiredType != ACHIEVEMENT_CRITERIA_TYPE_LEARN_SKILLLINE_SPELLS)
            return true;

        AchievementCriteriaDataSet const* data = sAchievementMgr->GetCriteriaDataSet(achievementCriteria);
        return !data || data->Meets(mgr->GetPlayer(), nullptr);
    }
};
}

void AddAscensionAchievementConditionScripts()
{
    for (GameModeCriteria const& criteria : GAME_MODE_CRITERIA)
        new AchievementGameModeCriteria(criteria);

    new RealmFirstAchievementPermission();
    new LearnSkillLineSpellsCriteriaDataGate();
}
