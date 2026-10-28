/*
 * mod-coa-challenges: internal declarations shared between the module
 * implementation (CoAChallenges.cpp) and the GM test harness
 * (CoAChallengeTests.cpp). Not a public API.
 */
#ifndef MOD_COA_CHALLENGES_INTERNAL_H
#define MOD_COA_CHALLENGES_INTERNAL_H

#include "CoAChallengeParse.h"
#include "Player.h"
#include <functional>
#include <string>
#include <vector>

namespace CoAChallenges
{
    using Objective = CoAParse::Entry;

    // Helpers implemented in CoAChallenges.cpp.
    // level = 0 means "any/union" (legacy: all levels' auras); >0 selects the
    // per-level aura when the challenge defines one.
    void ApplyChallengeSpell(Player* player, uint32 challengeID, uint32 level = 0);
    void RemoveChallengeSpell(Player* player, uint32 challengeID);
    void RemoveMeterAuras(Player* player);
    void TrackHunger(Player* player, uint32 challengeID);
    void Test_ClearHungerCache(uint32 guid);
    bool Test_SetFatigue(Player* player, int32 value);
    std::string Test_LastKillerLabel(Player* player);
    void UntrackFatigue(Player* player);
    void Test_FailSharedFateOnLeave(Player* player);
    void ResetChallengeState(Player* player);
    void ResetCoaCharacterState(Player* player);
    void ResetCharacterForTest(Player* player);
    void HardResetCharacter(Player* player);
    void SendChallengeResponse(Player* player, uint16 opcode, uint32 challengeID, uint32 level,
        uint32 code, std::string const& okStr);

    std::vector<Objective> GetObjectives(uint32 challengeID);
    bool IsTrackedObjective(std::string const& type);
    void SetObjectiveDone(uint32 guid, uint32 challengeID, std::string const& key);
    bool IsObjectiveDone(uint32 guid, uint32 challengeID, std::string const& key);
    bool ObjectivesAllDone(uint32 guid, uint32 challengeID);
    void CompleteChallenge(Player* player, uint32 challengeID);
    void SendActiveList(Player* player);
    void SendCriteriaState(Player* player);

    // Helpers exposed for the test harness.
    int QuestColor(uint32 questLevel, uint32 playerLevel);
    bool IsQuestWithoutObjectives(Quest const* quest);
    bool Test_SpellCheckCastBlocked(Player* player, uint32 spellId, bool triggered = false);
    void Test_SetQuiet(bool quiet);
    // Spellbind roulette (GM `.coa ruletestall` regression tests).
    bool Test_SpellbindMark(Player* player, uint32& spellId, bool& failable);
    void Test_SpellbindTick(Player* player, uint32 diff);
    void Test_SpellbindProcessPending(Player* player);
    void Test_ClearPendingFailures();

    // Test harness implemented in CoAChallengeTests.cpp.
    void Test_Update(uint32 diff);
    bool Test_StartVisualE2E(Player* player, uint32 challengeId, uint32 pauseMs);
    bool Test_StartLevelGateVisualE2E(Player* player, uint32 challengeId, uint32 pauseMs, bool missPass);
    bool Test_StartFatigueVisualE2E(Player* player, uint32 challengeId, uint32 pauseMs);
    bool Test_RunCompletionE2E(Player* player, uint32 challengeId);
    int Test_RunLevelGateE2E(Player* player, uint32 challengeId);
    bool Test_CheckRuleGate(Player* player, uint32 challengeId);
    bool Test_RuleGates(Player* player);
    bool Test_ConditionGates(Player* player);
    bool Test_PartyRuleGates(Player* a, Player* b);
    void Test_AuditAllRules(Player* player);
    void Test_AuditAllDefs(Player* player);
    bool Test_CacheToctou(Player* player);
    bool Test_PetTrialAuras(Player* player);

    // Cache TOCTOU seam (implemented in Lifecycle.cpp / GameModes.cpp): lets the
    // regression test inject an invalidation between the DB load and the cache
    // publish, and force the generation guard off to exercise the pre-fix path.
    void Test_SetCacheGuard(int value);
    void Test_SetCharChallengeLoadHook(std::function<void(uint32)> hook);
    void Test_SetGameModeLoadHook(std::function<void(uint32)> hook);
}

#endif
