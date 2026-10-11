// mod-coa-challenges (review split): CoA.Challenges.Lifecycle.cpp
// Mechanical split of review-CoAChallenges.cpp; no logic changes.
#include "CoA.Challenges.Review.h"

#include <atomic>
#include <mutex>
#include <optional>
#include <unordered_map>

namespace CoAChallenges
{

    bool HasFailure(uint32 guid, uint32 challengeID)
    {
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT 1 FROM coa_challenge_failure WHERE guid = {} AND challengeId = {} LIMIT 1",
                guid, challengeID))
            return true;
        return false;
    }

    // Any failure at all for the character (used by BlockAllAfterFailure).
    bool HasAnyFailure(uint32 guid)
    {
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT 1 FROM coa_challenge_failure WHERE guid = {} LIMIT 1", guid))
            return true;
        return false;
    }

    // True when the character can never activate another challenge anyway (a
    // recorded failure under BlockAllAfterFailure), so recording a condition
    // flag would be pointless.
    bool ActivationPermanentlyBlocked(uint32 guid)
    {
        return sConfigMgr->GetOption<bool>("CoAChallenges.BlockAllAfterFailure", true)
            && HasAnyFailure(guid);
    }

    bool HasCompletion(uint32 guid, uint32 challengeID)
    {
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT 1 FROM coa_challenge_completion WHERE guid = {} AND challengeId = {} LIMIT 1",
                guid, challengeID))
            return true;
        return false;
    }

    bool HasCompletionLevel(uint32 guid, uint32 challengeID, uint32 level)
    {
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT 1 FROM coa_challenge_completion WHERE guid = {} AND challengeId = {} AND level = {} LIMIT 1",
                guid, challengeID, level))
            return true;
        return false;
    }

    bool HasAccountCompletionLevel(uint32 account, uint32 challengeID, uint32 level)
    {
        auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_COA_ACCOUNT_CHALLENGE_COMPLETION);
        statement->SetData(0, account);
        statement->SetData(1, challengeID);
        statement->SetData(2, level);
        return CharacterDatabase.Query(statement) != nullptr;
    }

    // Death update (SMSG 0x5A6): same 26-byte active-entry layout as 0x596,
    // with the deaths-used counter incremented. Handler 0x1369D0 overwrites
    // the active record, then derives (remaining, total) from the record +
    // the client's local WITHOUT_DEATH requirement and fires
    // CHALLENGE_DEATH_UPDATE(challengeID, remaining, total).
    // Counter = u32 at wire[10] (entry+0x16); level kept at wire[8..9].
    void SendDeathUpdate(Player* player, uint32 challengeID, uint32 level, uint32 deaths)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        uint32 levelWord = (level & 0xFFFF) | ((deaths & 0xFFFF) << 16);
        WorldPacket data(SMSG_COA_CHALLENGE_DEATH_UPDATE, 32);
        data << uint32(0);
        data << uint32(challengeID);
        data << levelWord;
        data << uint32(0);
        data << uint32(0);
        data << uint32(0);
        data << uint16(0);

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x5A6 DEATH_UPDATE to {}: challengeID={} level={} deaths={}",
            player->GetName(), challengeID, level, deaths);
    }

    bool IsSharedFate(uint32 challengeID)
    {
        return DefField<bool>(challengeID, &ChallengeDef::sharedFate,
            "CoAChallenges.SharedFate." + std::to_string(challengeID), false);
    }

    // Mutual-exclusion group (client definitions). 0 = none. Two active
    // challenges with the same non-zero group cannot coexist.
    uint32 ExclusiveGroup(uint32 challengeID)
    {
        return DefField<uint32>(challengeID, &ChallengeDef::exclusiveGroup,
            "CoAChallenges.ExclusiveGroup." + std::to_string(challengeID), 0);
    }

    // A trial (client IsTrial=true) is exclusive with everything: you cannot
    // hold two trials, nor a trial together with a challenge. Challenges
    // (IsTrial=false) may stack (subject to ExclusiveGroup).
    bool IsTrialChallenge(uint32 challengeID)
    {
        return DefField<bool>(challengeID, &ChallengeDef::isTrial,
            "CoAChallenges.IsTrial." + std::to_string(challengeID), false);
    }

    bool IsPrestigeChallenge(uint32 challengeID)
    {
        return DefField<bool>(challengeID, &ChallengeDef::isPrestige,
            "CoAChallenges.IsPrestige." + std::to_string(challengeID), false);
    }

    // The client treats a player as "prestiged" iff they have COA_PRESTIGE_AURA
    // (C_Player:IsPrestiged() = HasAura(9930831), C_Player.lua:59). Prestige
    // challenges are gated on it.
    bool IsPrestiged(Player* player)
    {
        return player && player->HasAura(COA_PRESTIGE_AURA);
    }

    uint32 RequiredGameMode(uint32 challengeID)
    {
        return DefField<uint32>(challengeID, &ChallengeDef::requiredGameMode,
            "CoAChallenges.RequiredGameMode." + std::to_string(challengeID), 0);
    }

    // Game modes are NOT player-toggleable (AppendClientConfig locks the UI): the
    // bitmask is derived from the active challenges' RequiredGameMode. So a
    // trial that "is" a game mode (e.g. 61 -> Nightmare 0x100) turns the mode
    // on while active and off when it stops/fails/completes.
    void RecomputeRequiredGameModes(Player* player)
    {
        if (!player)
            return;
        RecomputeRequiredGameModes(player, LoadActiveChallengeRows(player->GetGUID().GetCounter()));
    }

    void RecomputeRequiredGameModes(Player* player, std::vector<ActiveChallengeRow> const& rows)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();

        uint32 mask = RealmGameModeMask();
        for (ActiveChallengeRow const& row : rows)
            mask |= RequiredGameMode(row.challengeId);

        // Preserve genuinely player-toggled modes (testing flag): without this a
        // login/activate recompute would silently clear them.
        if (sConfigMgr->GetOption<bool>("CoAChallenges.GameModes.PlayerToggle", false))
            mask |= PlayerToggleMaskFor(guid);

        uint32 oldMask = CachedGameModeMask(guid);
        if (oldMask == mask)
            return;

        // Persist/cache the NEW mask first: RemoveChallengeSpell (called from
        // ApplyGameModeSpells) consults CachedGameModeMask to know which mode
        // auras are still live, so it must already reflect the removal.
        SaveGameModeMask(guid, mask);
        ApplyGameModeSpells(player, oldMask, mask);
        SendGameModeState(player, mask);
        LOG_INFO("module.coa_challenges", "Required game modes recomputed for {}: mask=0x{:X}",
            player->GetName(), mask);
    }

    // Full per-character CoA wipe for the GM `.coa reset`: strips challenge
    // auras/meters, clears EVERY coa_* row (challenge/objective/completion/
    // failure/condition/gamemode/mode-lives/survival/fatigue + the character's
    // custom trials and anything referencing them), drops the in-memory caches
    // and re-pushes the empty state to the client (active/failure/completed
    // lists + gamemode mask). Level, money and inventory are NOT touched here.
    void ResetCoaCharacterState(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();

        // Strip challenge auras (+ hunger/fatigue meters) before dropping rows.
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT challengeId FROM coa_character_challenge WHERE guid = {}", guid))
        {
            do { RemoveChallengeSpell(player, r->Fetch()[0].Get<uint32>()); } while (r->NextRow());
        }
        RemoveMeterAuras(player);

        // Bring the character back if dead, and drop resurrection sickness
        // (15007) left by a spirit-healer revive.
        if (!player->IsAlive())
        {
            player->ResurrectPlayer(1.0f, false);
            player->SpawnCorpseBones();
        }
        player->RemoveAurasDueToSpell(15007);

        // Gamemode: remove the base auras + mode-lives counter, then the mask.
        // Cache the empty mask first so RemoveChallengeSpell (inside
        // ApplyGameModeSpells) does not treat the mode base auras as still live.
        uint32 oldMask = LoadGameModeMask(guid);
        SaveGameModeMask(guid, 0);
        ApplyGameModeSpells(player, oldMask, 0);
        ClearGameModeMaskCache(guid);

        // In-memory caches.
        Test_ClearHungerCache(guid);
        UntrackFatigue(player);
        UntrackSpellbind(player);
        UntrackInvertedBreath(player);
        UntrackLootedItems(guid);

        // Snapshot the completed (challenge, level) pairs so the client's
        // leaderboard cache for them can be refreshed after the delete.
        std::vector<std::pair<uint32, uint32>> completions;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT challengeId, level FROM coa_challenge_completion WHERE guid = {}", guid))
        {
            do
            {
                Field* f = r->Fetch();
                completions.emplace_back(f[0].Get<uint32>(), f[1].Get<uint32>());
            } while (r->NextRow());
        }
        // Same for custom-trial completions (no "completion removed" opcode, so
        // the trial leaderboard cache must be re-pushed as well).
        std::vector<std::string> trialCompletions;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT DISTINCT trialId FROM coa_custom_trial_completion WHERE guid = {}", guid))
        {
            do { trialCompletions.push_back(r->Fetch()[0].Get<std::string>()); } while (r->NextRow());
        }

        // Custom trials owned by this character: collect the ids first so the
        // realm-wide rows referencing them (entries/votes/completions/active)
        // can be dropped too, then remove the trials themselves.
        std::vector<std::string> ownedTrials;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT trialId FROM coa_custom_trial WHERE guid = {}", guid))
        {
            do { ownedTrials.push_back(r->Fetch()[0].Get<std::string>()); } while (r->NextRow());
        }

        // DB rows.
        CharacterDatabase.DirectExecute("DELETE FROM coa_character_challenge WHERE guid = {}", guid);
        ClearCharChallengeCache(guid);
        RefreshLevelScalingTracking(player);
        CharacterDatabase.DirectExecute("DELETE FROM coa_character_objective WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_challenge_completion WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_challenge_failure WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_character_condition WHERE guid = {}", guid);
        ResetConditionFlags(guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_character_gamemode WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_character_gamemode_lives WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_character_survival WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_character_fatigue WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_character_looted_item WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_custom_trial WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_custom_trial_entry WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_custom_trial_vote WHERE guid = {}", guid);
        CharacterDatabase.DirectExecute("DELETE FROM coa_custom_trial_completion WHERE guid = {}", guid);
        for (std::string trialId : ownedTrials)
        {
            CharacterDatabase.EscapeString(trialId);
            CharacterDatabase.DirectExecute("DELETE FROM coa_custom_trial_entry WHERE trialId = '{}'", trialId);
            CharacterDatabase.DirectExecute("DELETE FROM coa_custom_trial_vote WHERE trialId = '{}'", trialId);
            CharacterDatabase.DirectExecute("DELETE FROM coa_custom_trial_completion WHERE trialId = '{}'", trialId);
            CharacterDatabase.DirectExecute("DELETE FROM coa_custom_trial_active WHERE trialId = '{}'", trialId);
        }

        // Re-push the cleared state to the client.
        SendActiveList(player);
        SendCriteriaState(player);
        SendFailureList(player);
        SendCompletedList(player);
        SendGameModeState(player, 0);
        SetActiveCustomTrial(player, "");   // clear the client's active custom trial
        SendTrialList(player);              // and drop the character's custom trials

        // Refresh the client's leaderboard cache for the challenges this player
        // had a record on (there is no "completion removed" opcode).
        for (auto const& [cid, lvl] : completions)
            SendCompletionList(player, cid, lvl);
        for (std::string const& t : trialCompletions)
            SendTrialCompletions(player, t);

        LOG_INFO("module.coa_challenges", "Reset all CoA state for {}", player->GetName());
    }

    uint32 RequiredGameEvent(uint32 challengeID)
    {
        return DefField<uint32>(challengeID, &ChallengeDef::requiredGameEvent,
            "CoAChallenges.RequiredGameEvent." + std::to_string(challengeID), 0);
    }

    bool NoRewards(uint32 challengeID)
    {
        return DefField<bool>(challengeID, &ChallengeDef::noRewards,
            "CoAChallenges.NoRewards." + std::to_string(challengeID), false);
    }

    bool ChallengeExists(uint32 challengeID)
    {
        return !DefField<std::string>(challengeID, &ChallengeDef::name,
            "CoAChallenges.Name." + std::to_string(challengeID), "").empty();
    }

    // Conflict check for activation. Returns the Enum.ChallengeResponse code
    // (0 none; 5 EXCLUSIVE_GROUP_ACTIVE; 13 PARTICIPATING_IN_TRIAL;
    // 14 PARTICIPATING_IN_CHALLENGE) and sets conflictId to the blocking
    // active challenge.
    uint32 ConflictingExclusiveChallenge(uint32 guid, uint32 challengeID, uint32& conflictId)
    {
        conflictId = 0;
        uint32 group = ExclusiveGroup(challengeID);
        bool newIsTrial = IsTrialChallenge(challengeID);
        for (uint32 cid : ActiveChallenges(guid))
        {
            if (cid == challengeID)
                continue;
            bool activeIsTrial = IsTrialChallenge(cid);
            if (newIsTrial && !activeIsTrial)
            {
                conflictId = cid;
                return 14; // activating a trial while in a challenge
            }
            if (!newIsTrial && activeIsTrial)
            {
                conflictId = cid;
                return 13; // activating a challenge while in a trial
            }
            // Trial vs trial: exclusive regardless of ExclusiveGroup, so two
            // definitions with group 0 cannot run at the same time.
            if (newIsTrial && activeIsTrial)
            {
                conflictId = cid;
                return 13;
            }
            if (group && ExclusiveGroup(cid) == group)
            {
                conflictId = cid;
                return 5; // same exclusive group (trials)
            }
        }
        return 0;
    }

    // "Dead forever": failing a permadeath challenge blocks resurrection.
    // EXPLICIT only (CoAChallenges.NoResurrect.<id>) — hardcore/1-life is NOT
    // permadeath by default: dying just fails the challenge.
    bool IsPermaDeath(uint32 challengeID)
    {
        return DefField<bool>(challengeID, &ChallengeDef::noResurrect,
            "CoAChallenges.NoResurrect." + std::to_string(challengeID), false);
    }

    bool HasPermaDeathFailure(Player* player)
    {
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult r = CharacterDatabase.Query(
            "SELECT challengeId FROM coa_challenge_failure WHERE guid = {}", guid);
        if (!r)
            return false;
        do
        {
            if (IsPermaDeath(r->Fetch()[0].Get<uint32>()))
                return true;
        } while (r->NextRow());
        return false;
    }

    // ---- Challenge activation (shared by StartChallenge and ActivateTrial) --
    // Validates one challenge against the client's activation rules. Returns the
    // Enum.ChallengeResponse code (0 = OK, 1..14 = reason). Sends a chat hint
    // for every rejection so the player always sees WHY activation failed.
    uint32 ValidateChallenge(Player* player, uint32 challengeID, uint32 level)
    {
        uint32 guid = player->GetGUID().GetCounter();

        if (!ChallengeExists(challengeID))                       // 1 NOT_FOUND
        {
            ChatHandler(player->GetSession()).PSendSysMessage("Challenge {} was not found.", challengeID);
            return 1;
        }
        if (sConfigMgr->GetOption<bool>("CoAChallenges.EnforceNoRewards", false)
            && NoRewards(challengeID))                           // 2 NO_REWARDS
        {
            ChatHandler(player->GetSession()).PSendSysMessage("{} has no rewards.", ChallengeName(challengeID));
            return 2;
        }
        // 3 WRONG_GAME_MODE is intentionally not enforced here: game modes are
        // trial-driven. A trial whose RequiredGameMode is set provides that mode
        // itself (RecomputeRequiredGameModes turns the bit on while it is
        // active), so requiring it beforehand would block its own activation.
        if (ActiveChallenges(guid).count(challengeID))           // 4 ALREADY_ACTIVE
        {
            ChatHandler(player->GetSession()).PSendSysMessage("{} is already active.", ChallengeName(challengeID));
            return 4;
        }
        {
            uint32 conflictId = 0;
            uint32 conflictCode = ConflictingExclusiveChallenge(guid, challengeID, conflictId);
            if (conflictCode)                                    // 5/13/14 EXCLUSIVE/TRIAL/CHALLENGE
            {
                ChatHandler(player->GetSession()).PSendSysMessage(
                    "You already have an active challenge that conflicts ({}).", conflictId);
                return conflictCode;
            }
        }
        if (uint32 eventId = RequiredGameEvent(challengeID))     // 6 GAME_EVENT_NOT_ACTIVE
        {
            if (!sGameEventMgr->IsActiveEvent(eventId))
            {
                ChatHandler(player->GetSession()).PSendSysMessage(
                    "{} requires a game event that is not active.", ChallengeName(challengeID));
                return 6;
            }
        }
        if (std::string reason = CheckActivationConditions(player, challengeID); !reason.empty())
        {                                                        // 8 CONDITIONS_NOT_MET
            ChatHandler(player->GetSession()).PSendSysMessage(
                "Cannot start {}: {}", ChallengeName(challengeID), reason);
            return 8;
        }
        // NO_GROUP (solo-only, e.g. Ironman): cannot start while grouped.
        if (player->GetGroup())
        {
            std::string const rules = ChallengeRules(challengeID);
            if (CoAParse::ListContains(rules, "CHALLENGE_RULES_TYPE_NO_GROUP"))
            {
                ChatHandler(player->GetSession()).PSendSysMessage(
                    "You must leave your group before starting {}.", ChallengeName(challengeID));
                return 12; // RULE_BROKEN
            }
        }
        // HIGH_RISK_ONLY (High Roller / Ironman - High-Risk): the character must
        // be in the High Risk ruleset (aura applied by CoA).
        if (CoAParse::ListContains(ChallengeRules(challengeID), "CHALLENGE_RULES_TYPE_HIGH_RISK_ONLY")
            && HighRiskActivationBlocked(player))
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "{} requires you to be in High Risk.", ChallengeName(challengeID));
            return 12; // RULE_BROKEN
        }
        // Multi-level challenges are difficulty picks, not a ladder: any level can be
        // entered straight away (Adventure Mode at level 30 without ever completing
        // level 1, as on Ascension). Levels are not shortcuts either - rewards are paid
        // per completed (challenge, level) row, so entering high only buys a harder fight.
        if (IsPrestigeChallenge(challengeID) && !IsPrestiged(player))  // 11 NOT_PRESTIGE
        {
            ChatHandler(player->GetSession()).PSendSysMessage("{} requires prestige.", ChallengeName(challengeID));
            return 11;
        }
        if (sConfigMgr->GetOption<bool>("CoAChallenges.BlockAllAfterFailure", true)
            && HasAnyFailure(guid))                              // 12 RULE_BROKEN
        {
            LOG_INFO("module.coa_challenges", "Blocked activation of {} for {}: character already failed a challenge",
                challengeID, player->GetName());
            ChatHandler(player->GetSession()).PSendSysMessage(
                "You have already failed a challenge and cannot start another.");
            return 12;
        }
        if (sConfigMgr->GetOption<bool>("CoAChallenges.BlockFailedReactivate", true)
            && HasFailure(guid, challengeID))                    // 12 RULE_BROKEN
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "You have already failed {} and cannot retake it.", ChallengeName(challengeID));
            return 12;
        }
        // Level-scoped: a multi-level challenge must stay activatable at level N
        // once level N-1 is completed (any-level HasCompletion would lock out
        // every level past the first).
        if (sConfigMgr->GetOption<bool>("CoAChallenges.BlockCompletedReactivate", true)
            && HasCompletionLevel(guid, challengeID, level))
        {
            LOG_INFO("module.coa_challenges", "Blocked reactivation of completed challenge {} for {}",
                challengeID, player->GetName());
            ChatHandler(player->GetSession()).PSendSysMessage(
                "You have already completed this trial ({}).", ChallengeName(challengeID));
            return 12;
        }
        return 0;
    }

    // On activation, drop group members who don't share the activator's
    // challenge set (CoAChallenges.RequireSameChallengeToGroup). Solo/NO_GROUP
    // challenges are blocked before reaching here, so this covers same-challenge
    // group trials (Boss Blitz, Duo/Trio...).
    void EnforceGroupOnActivation(Player* player)
    {
        if (!sConfigMgr->GetOption<bool>("CoAChallenges.RequireSameChallengeToGroup", true))
            return;
        // When group sync is enabled, members are invited via SMSG 0x59B and
        // opt into the set (CMSG 0x59C) instead of being kicked immediately.
        if (sConfigMgr->GetOption<bool>("CoAChallenges.SyncChallengesWithGroup", true))
            return;
        Group* group = player->GetGroup();
        if (!group)
            return;

        std::set<uint32> const mine = ActiveChallenges(player->GetGUID().GetCounter());
        std::vector<ObjectGuid> kick;
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
        {
            if (slot.guid == player->GetGUID())
                continue;
            if (ActiveChallenges(slot.guid.GetCounter()) != mine)
                kick.push_back(slot.guid);
        }
        for (ObjectGuid const& g : kick)
        {
            Player* member = ObjectAccessor::FindPlayer(g);
            if (!member)
                continue;
            ChatHandler(member->GetSession()).PSendSysMessage(
                "You have been removed from the group: it now requires the same challenge set.");
            member->RemoveFromGroup();
        }
    }

    // Persist + apply aura/hunger for one challenge (no validation).
    void DoActivateChallenge(Player* player, uint32 challengeID, uint32 level)
    {
        uint32 guid = player->GetGUID().GetCounter();
        // Direct (synchronous): the active-list/criteria re-push below reads the
        // row right after, and activation is rare enough that blocking is fine.
        CharacterDatabase.DirectExecute(
            "REPLACE INTO coa_character_challenge (guid, challengeId, level, deaths, hunger, thirst, startTime) "
            "VALUES ({}, {}, {}, 0, 0, 0, UNIX_TIMESTAMP())",
            guid, challengeID, level);
        ClearCharChallengeCache(guid);
        ApplyChallengeSpell(player, challengeID, level);
        TrackHunger(player, challengeID);
        TrackFatigue(player, challengeID);
        TrackSpellbind(player, challengeID);
        TrackInvertedBreath(player, challengeID);
        RefreshRegenTracking(player);
        RefreshHighRiskTracking(player);
        RefreshLevelScalingTracking(player);
        RefreshLootedTracking(player);
        RecomputeRequiredGameModes(player);
        EnforceGroupOnActivation(player);

        // Static party-size gates (DUO/TRIO): the size was enforced by the
        // GROUP_SIZE condition in ValidateChallenge, so record them as met now
        // (they show up as done criteria and count for completion).
        for (Objective const& o : GetObjectives(challengeID))
        {
            if (o.type == "CHALLENGE_REQUIREMENT_TYPE_DUO"
                || o.type == "CHALLENGE_REQUIREMENT_TYPE_TRIO")
                SetObjectiveDone(guid, challengeID, o.key);
        }

        // Push the active set + the criteria cache for every activation path
        // (CMSG 0x592, trial activate, `.coa e2e`): the per-objective banner
        // (0x59A) needs the 0x599 list to have seeded the criterion first.
        SendActiveList(player);
        SendCriteriaState(player);

        // Invite the rest of the group to sync this challenge set (SMSG 0x59B).
        BroadcastChallengeSync(player, challengeID, level, false);
    }

    // Validate + activate a single challenge. Returns 0 on success.
    uint32 ActivateChallenge(Player* player, uint32 challengeID, uint32 level)
    {
        uint32 code = ValidateChallenge(player, challengeID, level);
        if (code)
            return code;
        DoActivateChallenge(player, challengeID, level);
        return 0;
    }

    // Remove one challenge from the active set (no response packets).
    void DeactivateChallenge(Player* player, uint32 challengeID)
    {
        uint32 guid = player->GetGUID().GetCounter();
        CharacterDatabase.DirectExecute(
            "DELETE FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
            guid, challengeID);
        ClearCharChallengeCache(guid);
        RemoveChallengeSpell(player, challengeID);
        RemoveMeterAuras(player);
        RemoveHungerChallenge(player, challengeID);
        ClearFatigue(player);
        UntrackSpellbind(player);
        // Rebuild for any OTHER active challenge that still carries a spellbind
        // rule (non-exclusive challenges can coexist: removing one must not
        // silently kill another's roulette).
        RefreshSpellbindTracking(player);
        UntrackInvertedBreath(player);
        RefreshRegenTracking(player);
        RefreshHighRiskTracking(player);
        RefreshLevelScalingTracking(player);
        RefreshLootedTracking(player);
        RecomputeRequiredGameModes(player);

        // Keep the client's active + criteria caches consistent (all
        // deactivation paths: CMSG 0x594, trial deactivate).
        SendActiveList(player);
        SendCriteriaState(player);

        // Tell the rest of the group to drop it too (SMSG 0x59B remove).
        BroadcastChallengeSync(player, challengeID, 0, true);
    }

    // ---- Rules (CHALLENGE_RULES_TYPE_*) ----------------------------------
    // Per-challenge rules live in the world DB (coa_challenge_definition.rules)
    // as a semicolon-separated list, read through ChallengeRules(). A rule
    // applies if ANY active challenge of the player lists it. Enforcement is
    // server-side (client UI is cosmetic).

    bool RuleListContains(std::string const& list, std::string const& rule)
    {
        return CoAParse::ListContains(list, rule);
    }

    // In-memory mirror of coa_character_challenge, for the same reason the game mode mask has one:
    // PlayerHasRule is called from the combat hooks and must not reach the database.
    std::mutex CharChallengeMutex;
    std::unordered_map<uint32, std::vector<std::pair<uint32, uint32>>> CharChallengeCache;
    // Bumped under CharChallengeMutex on every invalidation. A load that started before the bump
    // must not publish its now-stale snapshot (time-of-check to time-of-use): without it, a Clear
    // issued while the entry is still absent is a no-op and the late insert would resurrect an
    // invalidated row set. A single monotonic counter (not a per-guid map) keeps no per-character
    // state alive; the only cost is that a clear on any character also invalidates other in-flight
    // loads, which merely forces an extra reload on the cold path. Scope is in-process and covers
    // writes made through this module, not direct SQL/external writes.
    static uint64 CharChallengeGeneration = 0;

    std::vector<std::pair<uint32, uint32>> LoadCharChallenges(uint32 guid)
    {
        std::vector<std::pair<uint32, uint32>> active;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT challengeId, level FROM coa_character_challenge WHERE guid = {}", guid))
        {
            do
            {
                Field* f = r->Fetch();
                active.emplace_back(f[0].Get<uint32>(), f[1].Get<uint32>());
            } while (r->NextRow());
        }
        return active;
    }

    // Every column the login state needs, read in one query. PushLoginState hands the same rows to
    // each consumer and seeds the cache with them, instead of querying the table once per consumer.
    std::vector<ActiveChallengeRow> LoadActiveChallengeRows(uint32 guid)
    {
        std::vector<ActiveChallengeRow> rows;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT challengeId, level, hunger, thirst FROM coa_character_challenge WHERE guid = {}", guid))
        {
            do
            {
                Field* f = r->Fetch();
                rows.push_back({ f[0].Get<uint32>(), f[1].Get<uint32>(), f[2].Get<int32>(), f[3].Get<int32>() });
            } while (r->NextRow());
        }
        return rows;
    }

    // Test seam (`.coa cachetoctou`, see CoAChallengeTests.cpp). The hook runs on the calling
    // thread between the DB load and the cache publish, so a test can inject an invalidation
    // exactly in the TOCTOU window. Both are inert in production (empty hook, override -1).
    std::function<void(uint32)> CharChallengeLoadHookForTest;
    std::mutex CharChallengeHookMutex;
    static std::atomic<int> CacheGuardOverrideForTest{-1};

    void Test_SetCacheGuard(int value) { CacheGuardOverrideForTest = value; }
    void Test_SetCharChallengeLoadHook(std::function<void(uint32)> hook)
    {
        std::lock_guard<std::mutex> lock(CharChallengeHookMutex);
        CharChallengeLoadHookForTest = std::move(hook);
    }

    // Always on in production. Only the `.coa cachetoctou` regression test overrides it, so the
    // pre-fix behavior (a blind publish that keeps the stale snapshot) can be exercised too.
    bool CacheGenerationGuardEnabled()
    {
        return CacheGuardOverrideForTest.load() != 0;
    }

    // The character's active challenges, kept in memory the way the game mode mask already is.
    // PlayerHasRule runs from the combat hooks - every hit, every heal, every melee roll - and
    // asking the database there put a synchronous query on the map threads: measured at 18 000
    // SELECT a second on a realm with a thousand characters fighting, against an empty table.
    //
    // A copy is returned on purpose. A reference would point inside a map that another map
    // thread can rehash under the caller, which is the failure #4021 had to fix elsewhere.
    std::vector<std::pair<uint32, uint32>> CachedCharChallenges(uint32 guid)
    {
        for (;;)
        {
            uint64 generation = 0;
            bool guard = false;
            {
                std::lock_guard<std::mutex> lock(CharChallengeMutex);
                auto it = CharChallengeCache.find(guid);
                if (it != CharChallengeCache.end())
                    return it->second;
                guard = CacheGenerationGuardEnabled();
                if (guard)
                    generation = CharChallengeGeneration;
            }

            std::vector<std::pair<uint32, uint32>> active = LoadCharChallenges(guid);
            {
                // Copy the hook under its own mutex (the setter can run on the GM command thread
                // while a map thread is here). Invoke it after unlocking so its Clear* call, which
                // takes CharChallengeMutex, cannot deadlock.
                std::function<void(uint32)> hook;
                {
                    std::lock_guard<std::mutex> lock(CharChallengeHookMutex);
                    hook = CharChallengeLoadHookForTest;
                }
                if (hook)
                    hook(guid);
            }

            std::lock_guard<std::mutex> lock(CharChallengeMutex);
            // The row set changed while we were loading: the snapshot is stale, reload.
            if (guard && CharChallengeGeneration != generation)
                continue;
            CharChallengeCache[guid] = active;
            return active;
        }
    }

    // Read before loading rows for SeedCharChallengeCache, so an invalidation in between is detected.
    uint64 CharChallengeCacheGeneration()
    {
        std::lock_guard<std::mutex> lock(CharChallengeMutex);
        return CharChallengeGeneration;
    }

    // Publishes rows the caller loaded after reading CharChallengeCacheGeneration: never over an
    // existing entry, and not at all once the generation has moved on.
    void SeedCharChallengeCache(uint32 guid, uint64 generation, std::vector<ActiveChallengeRow> const& rows)
    {
        std::vector<std::pair<uint32, uint32>> active;
        active.reserve(rows.size());
        for (ActiveChallengeRow const& row : rows)
            active.emplace_back(row.challengeId, row.level);

        std::lock_guard<std::mutex> lock(CharChallengeMutex);
        if (CharChallengeGeneration != generation)
            return;
        CharChallengeCache.try_emplace(guid, std::move(active));
    }

    // Rows read while the character loads (Player::LoadFromDB), kept for PushLoginState in the same
    // login together with the cache generation they were read under. Any invalidation since then
    // means a module write may have changed them, and PushLoginState reads the table again.
    std::mutex LoginChallengeRowsMutex;
    std::unordered_map<uint32, std::pair<uint64, std::vector<ActiveChallengeRow>>> LoginChallengeRows;

    void PreloadLoginChallengeRows(uint32 guid)
    {
        uint64 const generation = CharChallengeCacheGeneration();
        std::vector<ActiveChallengeRow> rows = LoadActiveChallengeRows(guid);
        SeedCharChallengeCache(guid, generation, rows);
        std::lock_guard<std::mutex> lock(LoginChallengeRowsMutex);
        LoginChallengeRows[guid] = { generation, std::move(rows) };
    }

    std::vector<ActiveChallengeRow> TakeLoginChallengeRows(uint32 guid)
    {
        std::optional<std::pair<uint64, std::vector<ActiveChallengeRow>>> preloaded;
        {
            std::lock_guard<std::mutex> lock(LoginChallengeRowsMutex);
            if (auto node = LoginChallengeRows.extract(guid))
                preloaded = std::move(node.mapped());
        }

        uint64 const generation = CharChallengeCacheGeneration();
        if (preloaded && preloaded->first == generation)
            return std::move(preloaded->second);

        std::vector<ActiveChallengeRow> rows = LoadActiveChallengeRows(guid);
        SeedCharChallengeCache(guid, generation, rows);
        return rows;
    }

    void ForgetLoginChallengeRows(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(LoginChallengeRowsMutex);
        LoginChallengeRows.erase(guid);
    }

    // Called wherever the module adds or removes a row of coa_character_challenge, and at logout.
    void ClearCharChallengeCache(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(CharChallengeMutex);
        CharChallengeCache.erase(guid);
        ++CharChallengeGeneration;
    }

    // CoAChallenges.Enable is read when the configuration loads, not on every call: the combat hooks
    // reach it on every hit, and each read of a setting the realm's configuration does not define
    // logs a warning - millions of lines an hour on a realm shipped without mod-coa-challenges.conf.
    std::atomic<bool> ChallengesEnabledSetting{true};

    void LoadChallengesEnabled()
    {
        ChallengesEnabledSetting = sConfigMgr->GetOption<bool>("CoAChallenges.Enable", true);
    }

    bool ChallengesEnabled()
    {
        return ChallengesEnabledSetting.load(std::memory_order_relaxed);
    }

    // Implicit global activation gate (#4205 family): OUTSIDE_INTERACTION.
    // Default on; lets an operator disable the whole gate without a rebuild.
    bool OutsideInteractionGateEnabled()
    {
        return sConfigMgr->GetOption<bool>("CoAChallenges.OutsideInteractionGate", true);
    }

    bool PlayerHasRule(Player* player, char const* rule)
    {
        // The combat hooks read the rules through here, and they are registered whatever the
        // setting says: without this an operator who turns the module off still pays for it.
        if (!player || !ChallengesEnabled())
            return false;
        uint32 guid = player->GetGUID().GetCounter();

        for (auto const& [cid, unusedLevel] : CachedCharChallenges(guid))
        {
            std::string rules = ChallengeRules(cid);
            if (RuleListContains(rules, rule))
                return true;
        }

        // Game mode scope: a mode that is on without a trial applies its base
        // challenge's rules too (bit -> base, e.g. 0x100 -> 61 Nightmare).
        uint32 mask = CachedGameModeMask(guid);
        for (auto const& [bit, base] : GameModeBaseSnapshot())
        {
            if (!(mask & bit))
                continue;
            std::string rules = ChallengeRules(base);
            if (RuleListContains(rules, rule))
                return true;
        }
        return false;
    }

    // Active challenge carrying `rule` (0 if none), with its level in `level`.
    // Used by FAILABLE_* rules that must fail the specific trial.
    uint32 ActiveChallengeWithRule(Player* player, char const* rule, uint32& level)
    {
        level = 0;
        if (!player)
            return 0;
        uint32 guid = player->GetGUID().GetCounter();
        for (auto const& [cid, challengeLevel] : CachedCharChallenges(guid))
        {
            std::string rules = ChallengeRules(cid);
            if (RuleListContains(rules, rule))
            {
                level = challengeLevel;
                return cid;
            }
        }
        return 0;
    }

    std::set<uint32> ActiveChallenges(uint32 guid)
    {
        std::set<uint32> out;
        for (auto const& [cid, unusedLevel] : CachedCharChallenges(guid))
            out.insert(cid);
        return out;
    }

    // True while the player holds a trial. Activation conditions act only up to
    // the trial being activated; interactions during the trial must not taint
    // the next activation (rules cover the "during" window instead).
    bool HasActiveTrial(uint32 guid)
    {
        for (auto const& [cid, unusedLevel] : CachedCharChallenges(guid))
            if (IsTrialChallenge(cid))
                return true;
        return false;
    }

    // ---- Activation conditions -------------------------------------------
    // Per-challenge conditions are generated into CoAChallenges.Conditions.<id>
    // as "TYPE:V1/V2/V3;...". A condition is false by default and becomes
    // "broken" (blocking activation) when the player violates it. Loot/level
    // flags persist per character; group/inventory are checked live.

    // Condition flags are cached per character and written through. The
    // INSERT is asynchronous, so reading the table back could miss a flag an
    // earlier hook just set (loot, then start a trial before the queue drains);
    // the cache is the authority once a character's rows have been loaded.
    namespace
    {
        std::mutex ConditionFlagMutex;
        std::unordered_map<uint32, std::set<std::string>> ConditionFlagCache;

        // Caller holds ConditionFlagMutex.
        std::set<std::string>& LoadedConditionFlags(uint32 guid)
        {
            auto [itr, inserted] = ConditionFlagCache.try_emplace(guid);
            if (inserted)
                if (QueryResult r = CharacterDatabase.Query(
                        "SELECT flag FROM coa_character_condition WHERE guid = {}", guid))
                {
                    do { itr->second.insert(r->Fetch()[0].Get<std::string>()); } while (r->NextRow());
                }
            return itr->second;
        }
    }

    void SetConditionFlag(uint32 guid, char const* flag)
    {
        std::string eflag = flag ? flag : "";
        {
            std::lock_guard<std::mutex> lock(ConditionFlagMutex);
            if (!LoadedConditionFlags(guid).insert(eflag).second)
                return;
        }
        CharacterDatabase.EscapeString(eflag);
        CharacterDatabase.Execute(
            "INSERT IGNORE INTO coa_character_condition (guid, flag) VALUES ({}, '{}')",
            guid, eflag);
    }

    void ClearConditionFlag(uint32 guid, std::string const& flag)
    {
        {
            std::lock_guard<std::mutex> lock(ConditionFlagMutex);
            LoadedConditionFlags(guid).erase(flag);
        }
        std::string eflag = flag;
        CharacterDatabase.EscapeString(eflag);
        CharacterDatabase.Execute(
            "DELETE FROM coa_character_condition WHERE guid = {} AND flag = '{}'", guid, eflag);
    }

    // The character's rows were deleted: it has no flags from now on.
    void ResetConditionFlags(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(ConditionFlagMutex);
        ConditionFlagCache[guid].clear();
    }

    // The character itself was deleted: drop its entry.
    void ForgetConditionFlags(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(ConditionFlagMutex);
        ConditionFlagCache.erase(guid);
    }

    bool HasConditionFlag(uint32 guid, char const* flag)
    {
        std::lock_guard<std::mutex> lock(ConditionFlagMutex);
        return LoadedConditionFlags(guid).count(flag ? flag : "") != 0;
    }

    // Every condition flag for a character.
    std::set<std::string> ConditionFlags(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(ConditionFlagMutex);
        return LoadedConditionFlags(guid);
    }

    // Human label for an OUTSIDE_INTERACTION facet flag (nullptr = not one).
    // OUTSIDE_INTERACTION is the legacy aggregate flag (kept for old rows).
    char const* OutsideFacetLabel(std::string const& flag)
    {
        if (flag == "OUTSIDE_MAIL")        return "taken items or money from the mailbox";
        if (flag == "OUTSIDE_TRADE")       return "traded with another player";
        if (flag == "OUTSIDE_AH")          return "used the auction house";
        if (flag == "OUTSIDE_VENDOR")      return "used a vendor";
        if (flag == "OUTSIDE_GUILD_BANK")  return "withdrawn from the guild bank";
        if (flag == "OUTSIDE_BANK")        return "withdrawn from your bank";
        if (flag == "OUTSIDE_REALM_BANK")  return "withdrawn from your realm bank";
        if (flag == "OUTSIDE_INTERACTION") return "interacted with the outside world";
        return nullptr;
    }

    // Every facet OUTSIDE_INTERACTION aggregates (the trailing entry is the
    // legacy aggregate flag, kept for rows written before the per-facet split).
    std::vector<char const*> AllOutsideFacets()
    {
        return { "OUTSIDE_MAIL", "OUTSIDE_TRADE", "OUTSIDE_AH", "OUTSIDE_VENDOR",
                 "OUTSIDE_GUILD_BANK", "OUTSIDE_BANK", "OUTSIDE_REALM_BANK",
                 "OUTSIDE_INTERACTION" };
    }

    // Facet flags a given condition type checks (empty = not an outside type).
    // The per-service types are aliases over the same persistent flags the
    // aggregate uses, so declaring one of them must not fail closed.
    std::vector<char const*> OutsideFacetsForType(std::string const& type)
    {
        if (type == "CHALLENGE_CONDITIONS_TYPE_OUTSIDE_INTERACTION")
            return AllOutsideFacets();
        if (type == "CHALLENGE_CONDITIONS_TYPE_TAKE_MAIL_MONEY_OR_ITEM")
            return { "OUTSIDE_MAIL" };
        if (type == "CHALLENGE_CONDITIONS_TYPE_AUCTIONHOUSE_INTERACTION")
            return { "OUTSIDE_AH" };
        if (type == "CHALLENGE_CONDITIONS_TYPE_ACCEPT_TRADE")
            return { "OUTSIDE_TRADE" };
        if (type == "CHALLENGE_CONDITIONS_TYPE_VENDOR_INTERACTION")
            return { "OUTSIDE_VENDOR" };
        if (type == "CHALLENGE_CONDITIONS_TYPE_WITHDRAW_GUILD_BANK_MONEY_OR_ITEM")
            return { "OUTSIDE_GUILD_BANK" };
        if (type == "CHALLENGE_CONDITIONS_TYPE_WITHDRAW_BANK_MONEY_OR_ITEM")
            return { "OUTSIDE_BANK" };
        if (type == "CHALLENGE_CONDITIONS_TYPE_WITHDRAW_REALM_BANK_MONEY_OR_ITEM")
            return { "OUTSIDE_REALM_BANK" };
        return {};
    }

    // Broken when any of `allowed` facet flags is present; `message` names
    // exactly what the character did before the trial.
    bool OutsideInteractionBroken(std::set<std::string> const& flags,
        std::vector<char const*> const& allowed, std::string& message)
    {
        std::string list;
        for (char const* f : allowed)
        {
            if (!flags.count(f))
                continue;
            char const* label = OutsideFacetLabel(f);
            if (!label)
                continue;
            if (!list.empty())
                list += ", ";
            list += label;
        }
        if (list.empty())
            return false;
        message = "You have already " + list + " before starting this trial.";
        return true;
    }

    uint32 FreeInventorySlots(Player* player)
    {
        if (!player)
            return 0;
        uint32 free = 0;
        for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
            if (!player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                ++free;
        // Equipped bags count too: "has a free inventory slot" is not backpack-only.
        for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
            if (Bag* bag = player->GetBagByPos(bagSlot))
                free += bag->GetFreeSlots();
        return free;
    }

    // Number of primary professions the character has. Secondary skills
    // (Cooking/Fishing/First Aid/Riding) are not counted.
    uint32 PrimaryProfessionCount(Player* player)
    {
        static uint32 const kPrimaryProfessions[] = {
            SKILL_ALCHEMY, SKILL_BLACKSMITHING, SKILL_ENCHANTING, SKILL_ENGINEERING,
            SKILL_HERBALISM, SKILL_INSCRIPTION, SKILL_JEWELCRAFTING, SKILL_LEATHERWORKING,
            SKILL_MINING, SKILL_SKINNING, SKILL_TAILORING,
        };
        uint32 count = 0;
        for (uint32 skill : kPrimaryProfessions)
            if (player->HasSkill(skill))
                ++count;
        return count;
    }

    // `conds` is normally the challenge's own condition list; the test harness
    // passes a synthetic string with injectOutside=false to exercise one type
    // without depending on a definition that declares it.
    std::vector<ConditionState> EvaluateConditionsFor(Player* player, uint32 challengeID,
        std::string const& conds, bool injectOutside)
    {
        std::vector<ConditionState> out;
        uint32 guid = player->GetGUID().GetCounter();
        bool hasOutside = false;
        size_t start = 0;
        while (!conds.empty() && start <= conds.size())
        {
            size_t end = conds.find(';', start);
            if (end == std::string::npos)
                end = conds.size();
            std::string entry = conds.substr(start, end - start);
            size_t colon = entry.find(':');
            std::string type = (colon == std::string::npos) ? entry : entry.substr(0, colon);
            uint32 v1 = 0;
            if (colon != std::string::npos)
            {
                std::string v = entry.substr(colon + 1);
                size_t slash = v.find('/');
                if (slash != std::string::npos)
                    v = v.substr(0, slash);
                try { v1 = (uint32)std::stoul(v); } catch (...) { v1 = 0; }
            }

            ConditionState s;
            if (type == "CHALLENGE_CONDITIONS_TYPE_GROUP_SIZE")
            {
                uint32 g = player->GetGroup() ? player->GetGroup()->GetMembersCount() : 1;
                s.label = "GROUP_SIZE";
                if (v1 == 0)
                {
                    // "Your group must have 0 members" -> must be solo.
                    s.broken = (player->GetGroup() != nullptr);
                    s.detail = s.broken
                        ? "requires solo, current group of " + std::to_string(g)
                        : "solo";
                    s.message = "This trial must be started solo (you are in a group of "
                        + std::to_string(g) + ").";
                }
                else
                {
                    s.broken = (g != v1);
                    s.detail = "requires " + std::to_string(v1) + ", current " + std::to_string(g);
                    s.message = "This trial requires a group of " + std::to_string(v1)
                        + " (you have " + std::to_string(g) + ").";
                }
            }
            else if (type == "CHALLENGE_CONDITIONS_TYPE_HAVE_FREE_INVENTORY_SLOTS")
            {
                uint32 f = FreeInventorySlots(player);
                s.label = "HAVE_FREE_INVENTORY_SLOTS";
                s.broken = (f < v1);
                s.detail = "requires " + std::to_string(v1) + ", current " + std::to_string(f);
                s.message = "You need at least " + std::to_string(v1)
                    + " free inventory slots (you have " + std::to_string(f) + ").";
            }
            else if (type == "CHALLENGE_CONDITIONS_TYPE_HAVE_TWO_PRIMARY_PROFESSIONS")
            {
                // Normal form is "Cannot Have Two Primary Professions": broken
                // when the character already has two or more.
                uint32 const n = PrimaryProfessionCount(player);
                s.label = "HAVE_TWO_PRIMARY_PROFESSIONS";
                s.broken = (n >= 2);
                s.detail = "primary professions: " + std::to_string(n);
                s.message = "You cannot have two primary professions (you have "
                    + std::to_string(n) + ").";
            }
            else if (type == "CHALLENGE_CONDITIONS_TYPE_LOOT_INTERACTION")
            {
                // Loot history gates a one-shot run, not a difficulty ladder. A
                // multi-level challenge is entered at whichever level the player picks
                // (Adventure Mode 1-100), and the mode itself is built on dungeon loot,
                // so a lifetime "has looted" flag would lock out every level of it for a
                // player who has ever opened a corpse. The condition stays live for
                // single-level challenges, where "start clean" is the point of it.
                bool const ladder = ChallengeLevelCount(challengeID) > 1;
                bool looted = !ladder && HasConditionFlag(guid, "LOOTED");
                s.label = "LOOT_INTERACTION";
                s.broken = looted;
                s.detail = ladder ? "not required for a multi-level challenge"
                                  : (looted ? "LOOTED" : "clean");
                s.message = "You have already looted something; this trial must be started before any loot interaction.";
            }
            else if (type == "CHALLENGE_CONDITIONS_TYPE_LEVEL_UP")
            {
                // Client tooltip: "Cannot have gained experience" -> the player
                // must not have gained any level (still level 1).
                bool leveled = player->GetLevel() > 1;
                s.label = "LEVEL_UP";
                s.broken = leveled;
                s.detail = "requires level 1, current " + std::to_string(player->GetLevel());
                s.message = "You have already gained experience; this trial must be started at level 1.";
            }
            else if (type == "CHALLENGE_CONDITIONS_TYPE_CANNOT_HAVE_GAINED_EXPERIENCE")
            {
                // Legacy alias (not a real client enum); same meaning as LEVEL_UP.
                bool leveled = player->GetLevel() > 1;
                s.label = "CANNOT_HAVE_GAINED_EXPERIENCE";
                s.broken = leveled;
                s.detail = "requires level 1, current " + std::to_string(player->GetLevel());
                s.message = "You have already gained experience; this trial must be started at level 1.";
            }
            else if (auto facets = OutsideFacetsForType(type); !facets.empty())
            {
                // OUTSIDE_INTERACTION and its per-service aliases (mail, trade,
                // auction house, vendor, guild bank) share the same persistent
                // facet flags; declaring one of them must not fail closed.
                std::string message;
                bool const outside = OutsideInteractionBroken(ConditionFlags(guid), facets, message);
                s.label = type.substr(std::string("CHALLENGE_CONDITIONS_TYPE_").size());
                s.broken = outside;
                s.detail = outside ? "INTERACTED" : "clean";
                if (outside)
                    s.message = message;
                if (type == "CHALLENGE_CONDITIONS_TYPE_OUTSIDE_INTERACTION")
                    hasOutside = true;
            }
            else
            {
                // Unknown condition type: fail closed. An unhandled gate must not
                // silently allow activation.
                s.label = type;
                s.broken = true;
                s.detail = "unhandled condition type";
                s.message = "This trial has an unsupported activation requirement and cannot be started.";
                LOG_WARN("module.coa_challenges",
                    "Unhandled activation condition type '{}' (challenge {}) -> blocked",
                    type, challengeID);
            }

            out.push_back(s);
            if (end == conds.size())
                break;
            start = end + 1;
        }

        // OUTSIDE_INTERACTION is the one always-implicit gate (#4205 family):
        // the client surfaces it via a dedicated activation reason code and no
        // trial declares it per-trial, so inject it for every non-prestige
        // trial. The other interaction types are facets of this single flag.
        if (injectOutside && !hasOutside && OutsideInteractionGateEnabled()
            && IsTrialChallenge(challengeID) && !IsPrestigeChallenge(challengeID))
        {
            std::string message;
            bool const outside = OutsideInteractionBroken(ConditionFlags(guid), AllOutsideFacets(), message);
            ConditionState s;
            s.label = "OUTSIDE_INTERACTION";
            s.broken = outside;
            s.detail = outside ? "INTERACTED" : "clean";
            if (outside)
                s.message = message;
            out.push_back(s);
        }
        return out;
    }

    std::vector<ConditionState> EvaluateConditions(Player* player, uint32 challengeID)
    {
        return EvaluateConditionsFor(player, challengeID, ChallengeConditions(challengeID), true);
    }

    // Empty return = OK; otherwise a human-readable reason.
    std::string CheckActivationConditions(Player* player, uint32 challengeID)
    {
        for (ConditionState const& s : EvaluateConditions(player, challengeID))
            if (s.broken)
                return s.message.empty() ? (s.label + " (" + s.detail + ")") : s.message;
        return "";
    }

    // "Pristine": nothing has happened since the challenge was activated — no
    // objective progress, no deaths, and every activation condition still
    // holds. Deactivating while pristine is a free cancel (lets a fresh
    // character undo a wrong pick); otherwise a challenge with lives is failed.
    bool IsPristine(Player* player, uint32 challengeID)
    {
        uint32 guid = player->GetGUID().GetCounter();
        // Party-size gates (DUO/TRIO) are recorded as met at activation; they
        // are not progress, so they must not clear "pristine".
        for (Objective const& o : GetObjectives(challengeID))
        {
            if (o.type == "CHALLENGE_REQUIREMENT_TYPE_DUO"
                || o.type == "CHALLENGE_REQUIREMENT_TYPE_TRIO")
                continue;
            if (IsObjectiveDone(guid, challengeID, o.key))
                return false;
        }
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT deaths FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                guid, challengeID))
        {
            if (r->Fetch()[0].Get<uint32>() > 0)
                return false;
        }
        return CheckActivationConditions(player, challengeID).empty();
    }

    // ---- Objectives (Requirements[] level-restricted) --------------------
    // Generated into CoAChallenges.Objectives.<id> as "TYPE:V1/V2/V3;...".
    // V1 = target (creature/item/quest id, or money amount); V2 = the level the
    // objective must be completed BEFORE. COMPLETE_WITHOUT_DEATH is the Lives
    // mechanic; DUO/TRIO are tracked as party-size gates and marked done right
    // after a successful activation (see DoActivateChallenge).
    // EARN_MONEY_BEFORE_LEVEL is validated AT the level-up against the gold the
    // player is carrying at that instant (hoard mechanic): reaching the level
    // without the amount kills the player.

    std::mutex ObjectiveCacheMutex;
    std::unordered_map<uint32, std::vector<Objective>> ObjectiveCache;

    // Returned by value: LoadChallengeDefinitions can clear ObjectiveCache on
    // .coa challenges reload, which would dangle a returned reference.
    std::vector<Objective> GetObjectives(uint32 challengeID)
    {
        std::lock_guard<std::mutex> lock(ObjectiveCacheMutex);
        auto it = ObjectiveCache.find(challengeID);
        if (it != ObjectiveCache.end())
            return it->second;

        std::string objs = DefField<std::string>(challengeID, &ChallengeDef::objectives, "", "");
        return ObjectiveCache.emplace(challengeID, CoAParse::ParseEntries(objs)).first->second;
    }

    void SetObjectiveDone(uint32 guid, uint32 challengeID, std::string const& key)
    {
        std::string ekey = key;
        CharacterDatabase.EscapeString(ekey);
        // Direct (synchronous): the completion check reads right after, and
        // objective completion is rare enough that blocking is fine.
        CharacterDatabase.DirectExecute(
            "INSERT IGNORE INTO coa_character_objective (guid, challengeId, objective) VALUES ({}, {}, '{}')",
            guid, challengeID, ekey);
    }

    bool IsObjectiveDone(uint32 guid, uint32 challengeID, std::string const& key)
    {
        std::string ekey = key;
        CharacterDatabase.EscapeString(ekey);
        return (bool)CharacterDatabase.Query(
            "SELECT 1 FROM coa_character_objective WHERE guid = {} AND challengeId = {} AND objective = '{}' LIMIT 1",
            guid, challengeID, ekey);
    }

    bool IsTrackedObjective(std::string const& type)
    {
        return CoAParse::IsTrackedObjective(type);
    }

    // All tracked objectives done? (challenges with no tracked objectives
    // never auto-complete here).
    bool ObjectivesAllDone(uint32 guid, uint32 challengeID)
    {
        bool any = false;
        for (Objective const& o : GetObjectives(challengeID))
        {
            if (!IsTrackedObjective(o.type))
                continue;
            any = true;
            if (!IsObjectiveDone(guid, challengeID, o.key))
                return false;
        }
        return any;
    }

    // All tracked objectives done, treating "no tracked objectives" as met
    // (challenges whose only requirement is "N Lives" reach this at the cap).
    bool RequirementsMet(uint32 guid, uint32 challengeID)
    {
        for (Objective const& o : GetObjectives(challengeID))
            if (IsTrackedObjective(o.type) && !IsObjectiveDone(guid, challengeID, o.key))
                return false;
        return true;
    }

    // Reaching the level cap completes every active challenge whose
    // requirements are met. Challenges with no tracked objective (e.g. the
    // "1 Life" Hardcore trials) only complete here.
    void CompleteAtLevelCap(Player* player)
    {
        if (!sConfigMgr->GetOption<bool>("CoAChallenges.CompleteAtLevelCap", true))
            return;
        uint32 cap = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
        if (!cap || player->GetLevel() < cap)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        for (uint32 cid : ActiveChallenges(guid))
        {
            if (RequirementsMet(guid, cid))
                CompleteChallenge(player, cid);
        }
    }

    // Quest color (client UIParent.lua GetQuestDifficultyColor):
    //   diff = questLevel - playerLevel
    //   >= 5 red, >= 3 orange, >= -2 yellow, >= -greenRange green, else gray.
    // Returns 0 gray, 1 green, 2 yellow, 3 orange, 4 red.
    int QuestColor(uint32 questLevel, uint32 playerLevel)
    {
        int diff = int(questLevel) - int(playerLevel);
        if (diff >= 5) return 4;
        if (diff >= 3) return 3;
        if (diff >= -2) return 2;
        if (-diff <= 5) return 1;
        return 0;
    }

    // A quest with no objectives: nothing to kill, collect, explore, pay or
    // earn reputation for (talk-to and delivery quests).
    bool IsQuestWithoutObjectives(Quest const* quest)
    {
        return !quest->GetReqItemsCount() && !quest->GetReqCreatureOrGOcount() && !quest->GetPlayersSlain()
            && !quest->HasSpecialFlag(QUEST_SPECIAL_FLAGS_EXPLORATION_OR_EVENT)
            && !quest->GetRepObjectiveFaction() && !quest->GetRepObjectiveFaction2()
            && quest->GetRewOrReqMoney() >= 0;
    }

    // NO_LEVEL_PAST_REQUIREMENTS: the lowest level ABOVE the player's current
    // one that still has an unmet tracked objective in an active challenge
    // carrying the rule, or 0 if none. XP must be capped one point short of it,
    // because a single huge gain (e.g. a big XP rate) can cross several levels
    // at once and skip the gate.
    uint32 NextGatedLevel(Player* player)
    {
        uint32 guid = player->GetGUID().GetCounter();
        uint32 curLevel = player->GetLevel();
        uint32 gate = 0;
        for (uint32 cid : ActiveChallenges(guid))
        {
            std::string rules = ChallengeRules(cid);
            if (!RuleListContains(rules, "CHALLENGE_RULES_TYPE_NO_LEVEL_PAST_REQUIREMENTS"))
                continue;
            for (Objective const& o : GetObjectives(cid))
            {
                if (!IsTrackedObjective(o.type))
                    continue;
                if (!o.v2 || o.v2 <= curLevel)
                    continue;
                if (IsObjectiveDone(guid, cid, o.key))
                    continue;
                if (!gate || o.v2 < gate)
                    gate = o.v2;
            }
        }
        return gate;
    }

    // Completion: bookkeeping + remove active + CHALLENGE_COMPLETED (0x598).
    void CompleteChallenge(Player* player, uint32 challengeID)
    {
        uint32 guid = player->GetGUID().GetCounter();
        uint32 level = 1;
        uint32 startTime = 0;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT level, startTime FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                guid, challengeID))
        {
            Field* f = r->Fetch();
            level = f[0].Get<uint32>();
            startTime = f[1].Get<uint32>();
        }
        else
        {
            // Never record a bogus level-1/0-duration completion with rewards for
            // a challenge that is not actually active.
            LOG_WARN("module.coa_challenges",
                "CompleteChallenge ignored: challenge {} is not active for {}",
                challengeID, player->GetName());
            return;
        }

        // Rewards marked IsFirstCompletion are only given the first time this
        // level is completed (relevant only when re-completion is allowed).
        bool const firstCompletion = !HasCompletionLevel(guid, challengeID, level);
        uint32 const account = player->GetSession()->GetAccountId();
        bool const firstItemReward = firstCompletion && (!IsTrialChallenge(challengeID)
            || !HasAccountCompletionLevel(account, challengeID, level));

        // Rewards are handed out while the challenge is still recorded as active, and the
        // completion row that marks it done is written straight after. Granting last meant a
        // failed grant (or a realm drop in between) consumed the challenge and paid nothing,
        // with no way to retry; granting first at worst leaves the challenge complete with the
        // reward already paid, which the row written below then records.
        GrantChallengeRewards(player, challengeID, level, firstItemReward, firstCompletion);

        CharacterDatabaseTransaction completion = CharacterDatabase.BeginTransaction();
        completion->Append(
            "INSERT IGNORE INTO coa_challenge_completion (guid, challengeId, level, completeTime, startTime) "
            "VALUES ({}, {}, {}, UNIX_TIMESTAMP(), {})", guid, challengeID, level, startTime);
        auto* accountCompletion = CharacterDatabase.GetPreparedStatement(CHAR_INS_COA_ACCOUNT_CHALLENGE_COMPLETION);
        accountCompletion->SetData(0, account);
        accountCompletion->SetData(1, challengeID);
        accountCompletion->SetData(2, level);
        accountCompletion->SetData(3, startTime);
        completion->Append(accountCompletion);
        completion->Append(
            "DELETE FROM coa_character_challenge WHERE guid = {} AND challengeId = {}", guid, challengeID);
        CharacterDatabase.DirectCommitTransaction(completion);
        ClearCharChallengeCache(guid);
        RemoveChallengeSpell(player, challengeID);
        RemoveMeterAuras(player);
        RemoveHungerChallenge(player, challengeID);
        ClearFatigue(player);
        UntrackSpellbind(player);
        // Rebuild for any OTHER active challenge that still carries a spellbind
        // rule (see DeactivateChallenge).
        RefreshSpellbindTracking(player);
        UntrackInvertedBreath(player);
        RefreshRegenTracking(player);
        RefreshHighRiskTracking(player);
        RefreshLevelScalingTracking(player);
        RefreshLootedTracking(player);
        RecomputeRequiredGameModes(player);

        // 0x598 adds the trial to the client's completed cache but does NOT
        // remove it from the active cache, so the UI would keep showing
        // "deactivate". Re-push the active list (now without this trial).
        SendActiveList(player);
        SendCriteriaState(player);

        if (WorldSession* session = player->GetSession())
        {
            // CHALLENGE_COMPLETED record (28 bytes). Handler 0x137F60 hashes
            // the u32 at offset 4 (challengeID) and fires
            // CHALLENGE_COMPLETED(challengeID, level) from the u32 at offset 8
            // (format "%u%u"). Offsets 0/12..27 are unused; zero them.
            WorldPacket data(SMSG_COA_CHALLENGE_COMPLETED, 28);
            data << uint32(0);
            data << uint32(challengeID);
            data << uint32(level);
            data << uint32(0);
            data << uint32(0);
            data << uint32(0);
            data << uint32(0);
            session->SendPacket(&data);
        }
        LOG_INFO("module.coa_challenges", "Challenge {} ({}) completed by {} (level {})",
            challengeID, ChallengeName(challengeID), player->GetName(), level);

        AnnounceCompletion(player, challengeID, level);
        if (sConfigMgr->GetOption<bool>("CoAChallenges.SendCompletionAdded", true))
            SendCompletionAdded(player, challengeID, level);

        // Completing the last bundled challenge finishes the active custom trial
        // (record the trial completion + broadcast 0x5CB; no-op otherwise).
        TryCompleteCustomTrial(player, challengeID);
    }

    // Level of an active challenge (1 when not active / on a query miss).
    uint32 ActiveChallengeLevel(uint32 guid, uint32 challengeID)
    {
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT level FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                guid, challengeID))
            return r->Fetch()[0].Get<uint32>();
        return 1;
    }

    // Mark matching objectives done for an event value (creature/item/quest/
    // money). Only counts when the objective's level has not been reached yet.
    void MarkObjectives(Player* player, char const* type, uint32 eventValue)
    {
        uint32 guid = player->GetGUID().GetCounter();
        for (uint32 cid : ActiveChallenges(guid))
        {
            bool marked = false;
            uint32 level = 0;
            for (Objective const& o : GetObjectives(cid))
            {
                if (o.type != type || o.v1 != eventValue)
                    continue;
                if (o.v2 && player->GetLevel() >= o.v2)
                    continue;
                if (!IsObjectiveDone(guid, cid, o.key))
                {
                    SetObjectiveDone(guid, cid, o.key);
                    LOG_INFO("module.coa_challenges", "{} completed objective {} (challenge {})",
                        player->GetName(), o.key, cid);
                    // Per-objective banner (SMSG 0x59A): the 0 -> nonzero
                    // progress transition makes the client fire
                    // CHALLENGE_CRITERIA_COMPLETED. Requires the 0x599 list to
                    // have seeded this criterion first (sent on activation).
                    if (!level)
                        level = ActiveChallengeLevel(guid, cid);
                    SendCriteriaUpdatedForObjective(player, cid, level, o, true);
                    marked = true;
                }
            }
            if (marked && ObjectivesAllDone(guid, cid))
                CompleteChallenge(player, cid);
        }
    }

    // Short labels for the failure broadcast when a level-restricted objective
    // is missed (the player is killed for it).
    std::string ObjectiveFailLabel(std::string const& type)
    {
        if (type == "CHALLENGE_REQUIREMENT_TYPE_EARN_MONEY_BEFORE_LEVEL")     return "Greedy";
        if (type == "CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL")  return "Hunt Failed";
        if (type == "CHALLENGE_REQUIREMENT_TYPE_LOOT_ITEM_BEFORE_LEVEL")      return "Loot Failed";
        if (type == "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_QUEST_BEFORE_LEVEL") return "Quest Failed";
        if (type == "CHALLENGE_REQUIREMENT_TYPE_DUO")  return "Duo Broken";
        if (type == "CHALLENGE_REQUIREMENT_TYPE_TRIO") return "Trio Broken";
        return "Failed Objective";
    }

    // On level up: every tracked objective whose V2 level has been reached is
    // validated. Money objectives pass only if the player is CARRYING the
    // required amount right now; anything still unmet kills the player (which
    // fails the challenge). Passed money milestones are recorded.
    // Returns false when an unmet level-restricted objective killed the player
    // (so the caller must not run the level-cap completion on a dying char).
    bool CheckObjectiveLevels(Player* player)
    {
        uint32 guid = player->GetGUID().GetCounter();
        for (uint32 cid : ActiveChallenges(guid))
        {
            // Level-gated trials (NO_LEVEL_PAST_REQUIREMENTS) cap XP one level
            // short of every gate, so a normal player can never stand ON a gate
            // level with its objective unmet: the missed-objective death is
            // unreachable and must not fire (e.g. for a GM-forced level-up).
            std::string const rules = ChallengeRules(cid);
            bool const levelGated =
                rules.find("CHALLENGE_RULES_TYPE_NO_LEVEL_PAST_REQUIREMENTS") != std::string::npos;

            bool marked = false;
            uint32 level = 0;
            for (Objective const& o : GetObjectives(cid))
            {
                if (!IsTrackedObjective(o.type))
                    continue;
                if (!o.v2 || player->GetLevel() < o.v2)
                    continue;
                if (IsObjectiveDone(guid, cid, o.key))
                    continue;

                if (o.type == "CHALLENGE_REQUIREMENT_TYPE_EARN_MONEY_BEFORE_LEVEL"
                    && player->GetMoney() >= o.v1)
                {
                    SetObjectiveDone(guid, cid, o.key);
                    LOG_INFO("module.coa_challenges", "{} completed objective {} (challenge {}) at level {}",
                        player->GetName(), o.key, cid, player->GetLevel());
                    if (!level)
                        level = ActiveChallengeLevel(guid, cid);
                    SendCriteriaUpdatedForObjective(player, cid, level, o, true);
                    marked = true;
                    continue;
                }

                if (levelGated)
                    continue;

                LOG_INFO("module.coa_challenges", "{} missed objective {} (challenge {}) at level {}",
                    player->GetName(), o.key, cid, player->GetLevel());
                SetDeathCause(player, KillerKind::Mechanic, 0, ObjectiveFailLabel(o.type));
                player->EnvironmentalDamage(DAMAGE_EXHAUSTED, player->GetMaxHealth());
                return false;
            }

            if (marked && ObjectivesAllDone(guid, cid))
                CompleteChallenge(player, cid);
        }
        return true;
    }

    // If the failing challenge belongs to the character's active custom trial,
    // the whole trial is over: tear down every remaining bundled challenge and
    // clear the client's active-trial state (SMSG 0x5B1 empty).
    void EndActiveCustomTrialFor(Player* player, uint32 challengeID)
    {
        uint32 guid = player->GetGUID().GetCounter();
        std::string trialID = GetActiveCustomTrial(guid);
        if (trialID.empty())
            return;
        uint32 ownerGuid = TrialOwnerGuid(trialID);
        if (!ownerGuid)
        {
            SetActiveCustomTrial(player, "");
            return;
        }

        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);
        std::vector<uint32> bundled;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT challengeId FROM coa_custom_trial_entry WHERE guid = {} AND trialId = '{}'",
                ownerGuid, eTrialId))
            do { bundled.push_back(r->Fetch()[0].Get<uint32>()); } while (r->NextRow());

        if (std::find(bundled.begin(), bundled.end(), challengeID) == bundled.end())
            return;   // the failed challenge is not part of the active trial

        std::set<uint32> actives = ActiveChallenges(guid);
        for (uint32 cid : bundled)
            if (cid != challengeID && actives.count(cid))
                DeactivateChallenge(player, cid);

        SetActiveCustomTrial(player, "");
        SendActiveList(player);
        SendCriteriaState(player);
        LOG_INFO("module.coa_challenges", "Custom trial {} ended for {} (challenge {} failed)",
            trialID, player->GetName(), challengeID);
    }

    // Full fail sequence: bookkeeping + client updates + aura removal.
    // killerSource: guid whose death carries the killer for the broadcast
    // (defaults to the failing player; shared fate passes the member who died).
    void FailChallenge(Player* player, uint32 challengeID, uint32 level, uint32 deaths,
        ObjectGuid const& killerSource, KillerKind causeKind, uint32 causeEntry, std::string causeName)
    {
        uint32 guid = player->GetGUID().GetCounter();
        // Capture the active custom-trial identity (if any) BEFORE any teardown,
        // so the failure announcement is attributed to the trial.
        std::string trialDisplayName, trialDisplayIcon;
        ActiveTrialDisplayFor(player, challengeID, trialDisplayName, trialDisplayIcon);
        // INSERT IGNORE + synchronous: the PK (guid, challengeId) makes a repeat
        // fail a no-op, and a sync write means HasFailure/HasPermaDeathFailure
        // (read in the same tick) and the client re-push see the row immediately.
        CharacterDatabase.DirectExecute(
            "INSERT IGNORE INTO coa_challenge_failure (guid, challengeId, level, deaths, failTime) "
            "VALUES ({}, {}, {}, {}, UNIX_TIMESTAMP())",
            guid, challengeID, level, deaths);
        // Synchronous delete so the active-list re-push below reflects it.
        CharacterDatabase.DirectExecute(
            "DELETE FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
            guid, challengeID);
        ClearCharChallengeCache(guid);
        RemoveChallengeSpell(player, challengeID);
        RemoveMeterAuras(player);
        RemoveHungerChallenge(player, challengeID);
        ClearFatigue(player);
        UntrackSpellbind(player);
        // Rebuild for any OTHER active challenge that still carries a spellbind
        // rule (see DeactivateChallenge).
        RefreshSpellbindTracking(player);
        UntrackInvertedBreath(player);
        RefreshRegenTracking(player);
        RefreshHighRiskTracking(player);
        RefreshLevelScalingTracking(player);
        RefreshLootedTracking(player);
        RecomputeRequiredGameModes(player);

        SendFailureAdded(player, challengeID, level);
        // Remove it from the client's active cache (otherwise the UI keeps
        // showing "Deactivate" for a challenge the server already dropped).
        SendActiveList(player);
        SendCriteriaState(player);
        SendChallengeResponse(player, SMSG_COA_CHALLENGE_STOP_RESPONSE,
            challengeID, level, 0, "CHALLENGE_STOP_OK");

        // A failed challenge that is part of an active custom trial ends the
        // whole trial (drop the other bundled challenges + clear active-trial).
        EndActiveCustomTrialFor(player, challengeID);

        LOG_INFO("module.coa_challenges", "Challenge {} ({}) failed for {} (deaths={})",
            challengeID, ChallengeName(challengeID), player->GetName(), deaths);

        // Queue the realm-wide failure announcement (flushed next world tick,
        // after OnPlayerKilledByCreature / OnPlayerPVPKill may have filled in
        // the killer).
        {
            PendingFail pending;
            pending.challengeID = challengeID;
            pending.level = level;
            pending.displayName = trialDisplayName;
            pending.displayIcon = trialDisplayIcon;
            if (causeKind != KillerKind::Unknown)
            {
                // Rule failure (e.g. slaying a forbidden beast): name the cause
                // directly; the player did not die, so there is no LastKiller.
                pending.killerKind = causeKind;
                pending.killerEntry = causeEntry;
                pending.killerName = causeName;
            }
            else
            {
                uint32 sourceGuid = (killerSource.IsEmpty() ? player->GetGUID() : killerSource).GetCounter();
                std::lock_guard<std::mutex> lock(LastKillerMutex);
                auto it = LastKiller.find(sourceGuid);
                if (it != LastKiller.end())
                {
                    pending.killerKind = it->second.kind;
                    pending.killerEntry = it->second.entry;
                    pending.killerName = it->second.name;
                }
            }
            std::lock_guard<std::mutex> lock(PendingFailMutex);
            PendingFailBroadcast[guid] = pending;
        }
    }

    // Fail a character that is offline (a SharedFate partner): only the DB rows
    // matter. Auras/meters/packets are moot for a character not in the world
    // (login strips orphan challenge auras), but the failure lock and the active
    // row must be written, or the partner would keep playing the trial.
    void FailChallengeOffline(uint32 guid, uint32 challengeID, uint32 level, uint32 deaths,
        ObjectGuid const& killerSource)
    {
        CharacterDatabase.DirectExecute(
            "INSERT IGNORE INTO coa_challenge_failure (guid, challengeId, level, deaths, failTime) "
            "VALUES ({}, {}, {}, {}, UNIX_TIMESTAMP())",
            guid, challengeID, level, deaths);
        CharacterDatabase.DirectExecute(
            "DELETE FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
            guid, challengeID);
        ClearCharChallengeCache(guid);
        LOG_INFO("module.coa_challenges", "Challenge {} ({}) failed for offline character {} (deaths={})",
            challengeID, ChallengeName(challengeID), guid, deaths);

        // Queue the realm announcement too, so an offline SharedFate partner is
        // announced like the online ones (the flush resolves name/level from the
        // character cache).
        PendingFail pending;
        pending.challengeID = challengeID;
        pending.level = level;
        {
            uint32 sourceGuid = (killerSource.IsEmpty()
                ? ObjectGuid::Create<HighGuid::Player>(guid) : killerSource).GetCounter();
            std::lock_guard<std::mutex> lock(LastKillerMutex);
            auto it = LastKiller.find(sourceGuid);
            if (it != LastKiller.end())
            {
                pending.killerKind = it->second.kind;
                pending.killerEntry = it->second.entry;
                pending.killerName = it->second.name;
            }
        }
        std::lock_guard<std::mutex> lock(PendingFailMutex);
        PendingFailBroadcast[guid] = pending;
    }

    // Shared fate (Duo/Trio/Vitality): one holder's death fails EVERY holder
    // in the party, including the dead player. Returns failed challenge IDs.
    void FailSharedFate(Player* dead, uint32 challengeID)
    {
        Group* group = dead->GetGroup();
        if (!group)
        {
            // Solo holder: fails alone (party of one shares fate with itself).
            if (QueryResult r = CharacterDatabase.Query(
                    "SELECT level, deaths FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                    dead->GetGUID().GetCounter(), challengeID))
            {
                Field* f = r->Fetch();
                FailChallenge(dead, challengeID, f[0].Get<uint32>(), f[1].Get<uint32>() + 1,
                    dead->GetGUID());
            }
            return;
        }

        for (Group::MemberSlotList::const_iterator itr = group->GetMemberSlots().begin();
             itr != group->GetMemberSlots().end(); ++itr)
        {
            uint32 mguid = itr->guid.GetCounter();
            QueryResult r = CharacterDatabase.Query(
                "SELECT level, deaths FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                mguid, challengeID);
            if (!r)
                continue;
            Field* f = r->Fetch();
            uint32 deaths = f[1].Get<uint32>() + (itr->guid == dead->GetGUID() ? 1 : 0);
            Player* member = ObjectAccessor::FindPlayer(itr->guid);
            if (!member)
            {
                // Offline partner: fail it in the DB too, or it would keep the
                // trial on relogin.
                FailChallengeOffline(mguid, challengeID, f[0].Get<uint32>(), deaths, dead->GetGUID());
                continue;
            }
            if (member == dead)
                CharacterDatabase.Execute(
                    "UPDATE coa_character_challenge SET deaths = {} WHERE guid = {} AND challengeId = {}",
                    deaths, mguid, challengeID);
            FailChallenge(member, challengeID, f[0].Get<uint32>(), deaths, dead->GetGUID());
        }
    }

    // Leaving/disbanding a group fails SharedFate (Duo/Trio) challenges: the
    // leaver fails, and by shared fate so do the remaining holders. `extra` is
    // the member already removed from `group` (nullptr for a disband).
    void FailSharedFateHolders(Group* group, ObjectGuid extraGuid)
    {
        if (!ChallengesEnabled())
            return;

        // Keyed by guid (not Player*) so offline partners are failed too.
        std::vector<std::pair<ObjectGuid, uint32>> targets;
        auto collect = [&targets](ObjectGuid guid)
        {
            if (guid.IsEmpty())
                return;
            if (QueryResult r = CharacterDatabase.Query(
                    "SELECT challengeId FROM coa_character_challenge WHERE guid = {}",
                    guid.GetCounter()))
            {
                do
                {
                    uint32 cid = r->Fetch()[0].Get<uint32>();
                    if (IsSharedFate(cid))
                        targets.emplace_back(guid, cid);
                } while (r->NextRow());
            }
        };

        if (group)
            for (Group::MemberSlotList::const_iterator itr = group->GetMemberSlots().begin();
                 itr != group->GetMemberSlots().end(); ++itr)
                collect(itr->guid);
        if (!extraGuid.IsEmpty())
            collect(extraGuid);

        for (auto const& [guid, cid] : targets)
        {
            if (QueryResult r = CharacterDatabase.Query(
                    "SELECT level, deaths FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                    guid.GetCounter(), cid))
            {
                Field* f = r->Fetch();
                if (Player* member = ObjectAccessor::FindPlayer(guid))
                    FailChallenge(member, cid, f[0].Get<uint32>(), f[1].Get<uint32>());
                else
                    FailChallengeOffline(guid.GetCounter(), cid, f[0].Get<uint32>(), f[1].Get<uint32>(),
                        ObjectGuid::Empty);
            }
        }
    }

    // GM test hook: exercise the group-leave failure path for a solo player
    // (group == nullptr still fails the leaver's SharedFate challenge).
    void Test_FailSharedFateOnLeave(Player* player)
    {
        FailSharedFateHolders(nullptr, player->GetGUID());
    }

    void HandlePlayerDeath(Player* player)
    {
        if (!ChallengesEnabled())
            return;
        if (!sConfigMgr->GetOption<bool>("CoAChallenges.RespondToDeath", true))
            return;

        uint32 guid = player->GetGUID().GetCounter();
        std::set<uint32> actives = ActiveChallenges(guid);

        if (QueryResult result = CharacterDatabase.Query(
                "SELECT challengeId, level, deaths FROM coa_character_challenge WHERE guid = {}", guid))
        {
            do
            {
                Field* f = result->Fetch();
                uint32 challengeID = f[0].Get<uint32>();
                uint32 level = f[1].Get<uint32>();

                // Shared fate overrides lives counting: one death fails all.
                if (IsSharedFate(challengeID))
                {
                    FailSharedFate(player, challengeID);
                    continue;
                }

                // Total lives come from the client definition (WITHOUT_DEATH
                // MiscValue1; see CoAExport). Absent = deaths don't affect it.
                uint32 lives = LivesTotal(challengeID);
                if (!lives)
                    continue;

                uint32 deaths = f[2].Get<uint32>() + 1;

                // Synchronous: the completion/fail decision below must not race
                // the death counter write (see also SaveModeDeaths).
                CharacterDatabase.DirectExecute(
                    "UPDATE coa_character_challenge SET deaths = {} WHERE guid = {} AND challengeId = {}",
                    deaths, guid, challengeID);

                SendDeathUpdate(player, challengeID, level, deaths);

                if (deaths >= lives)
                    FailChallenge(player, challengeID, level, deaths);
            } while (result->NextRow());
        }

        // Game mode scope: a mode on WITHOUT its base challenge loses lives too
        // (same counter aura; persisted in coa_character_gamemode_lives).
        uint32 mask = CachedGameModeMask(guid);
        for (auto const& [bit, base] : GameModeBaseSnapshot())
        {
            if (!(mask & bit) || actives.count(base))
                continue;
            uint32 lives = LivesTotal(base);
            if (!lives)
                continue;

            uint32 deaths = LoadModeDeaths(guid, bit) + 1;
            SaveModeDeaths(guid, bit, deaths);
            LOG_INFO("module.coa_challenges", "Mode 0x{:X} death {} / {} for {}",
                bit, deaths, lives, player->GetName());

            if (deaths >= lives)
            {
                mask &= ~bit;
                SaveGameModeMask(guid, mask);
                // The mode failed on its own: forget the player's toggle so a
                // later recompute does not re-enable the dead mode.
                ClearPlayerToggleBit(guid, bit);
                RemoveChallengeSpell(player, base);
                if (bit == GAMEMODE_SURVIVALIST)
                    RemoveHungerChallenge(player, SURVIVALIST_HUNGER_ID);
                SendGameModeState(player, mask);
                ChatHandler(player->GetSession()).PSendSysMessage(
                    "Your {} challenge has failed.", GameModeNameForBit(bit));
            }
        }
    }
} // namespace CoAChallenges
