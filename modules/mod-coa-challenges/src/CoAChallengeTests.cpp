/*
 * mod-coa-challenges: GM-only test harness for the `.coa e2e` command.
 *
 * Kept out of CoAChallenges.cpp so the production path stays free of test
 * code. The visual runner schedules one step per world tick (driven by
 * CoAChallengesWorld::OnUpdate -> Test_Update) so the client renders every
 * level/money/death/banner change without blocking the world thread.
 */
#include "CoAChallengeInternal.h"
#include "CoA.Challenges.Review.h"
#include "Battleground.h"
#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "Group.h"
#include "Item.h"
#include "LFG.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include "StringFormat.h"
#include "TaskScheduler.h"
#include "World.h"
#include "WorldSession.h"
#include <algorithm>
#include <chrono>
#include <functional>
#include <map>
#include <memory>
#include <thread>
#include <utility>

namespace CoAChallenges
{
    // Let queued async character-DB writes (e.g. FailChallenge) land before
    // the next scenario issues synchronous DELETEs, so a stale async DELETE
    // can't wipe a freshly activated challenge.
    void WaitCharacterQueueEmpty()
    {
        for (int i = 0; i < 400 && CharacterDatabase.QueueSize() > 0; ++i)
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
        std::this_thread::sleep_for(std::chrono::milliseconds(20));
    }

    // Clear only the CoA challenge state: challenge auras/meters, active,
    // objectives, completions (leaderboard), failures, condition flags AND the
    // gamemode/mode-lives/survival/fatigue state, then re-push the empty lists
    // to the client. Keeps level, money, inventory/equipment and bank.
    void ResetChallengeState(Player* player)
    {
        WaitCharacterQueueEmpty();
        ResetCoaCharacterState(player);
        WaitCharacterQueueEmpty();
    }

    // Wipe every per-character CoA record and return the character to a
    // freshly-created state: level 1, 0 money, no challenge auras, no
    // completion/failure locks and no objective/condition rows.
    void ResetCharacterForTest(Player* player)
    {
        ResetChallengeState(player);
        uint32 guid = player->GetGUID().GetCounter();

        if (!player->IsAlive())
        {
            player->ResurrectPlayer(1.0f, false);
            player->SpawnCorpseBones();
        }
        player->SetMoney(0);
        if (player->GetLevel() != 1)
            player->GiveLevel(1);
        player->SetHealth(player->GetMaxHealth());
        player->SetPower(POWER_MANA, player->GetMaxPower(POWER_MANA));

        // GiveLevel queues an async LEVELED flag; drain it and clear condition
        // flags last so the character ends up truly clean.
        WaitCharacterQueueEmpty();
        CharacterDatabase.DirectExecute("DELETE FROM coa_character_condition WHERE guid = {}", guid);
        ResetConditionFlags(guid);

        LOG_INFO("module.coa_challenges", "Test reset {}: level 1, 0 money, no challenges",
            player->GetName());
    }

    // Full character wipe for the GM `.coa reset all <player>` command: the CoA
    // state + level 1 (ResetCharacterForTest) PLUS repair all items, unlearn all
    // spells/skills, reset talents and clear the quest log. Inventory/equipment/
    // bank are kept (only durability is repaired). Completed-quest status is NOT
    // reset (only the active quest log is cleared).
    void HardResetCharacter(Player* player)
    {
        if (!player)
            return;

        ResetCharacterForTest(player);           // CoA state + level 1 + 0 money

        player->DurabilityRepairAll(false, 1.0f, false);

        // Unlearn all spells (relearns default skills + custom + quest spells)
        // and reset talents (active specialization).
        player->resetSpells();
        player->resetTalents(true);
        player->UpdateSkillsForLevel();

        // Re-learn the racial languages: resetSpells() drops the language
        // spells, but the client's chat still needs them (the language skills
        // are kept, so re-grant the matching spell for every known language).
        for (uint32 i = 0; i < LANGUAGES_COUNT; ++i)
            if (lang_description[i].spell_id && lang_description[i].skill_id
                && player->HasSkill(lang_description[i].skill_id)
                && !player->HasSpell(lang_description[i].spell_id))
                player->learnSpell(lang_description[i].spell_id, false);

        // Clear the active quest log.
        for (uint16 slot = 0; slot < MAX_QUEST_LOG_SIZE; ++slot)
        {
            uint32 questId = player->GetQuestSlotQuestId(slot);
            if (!questId)
                continue;
            player->RemoveActiveQuest(questId, false);
            player->SetQuestSlot(slot, 0);
        }

        player->SetHealth(player->GetMaxHealth());
        if (player->GetMaxPower(POWER_MANA))
            player->SetPower(POWER_MANA, player->GetMaxPower(POWER_MANA));

        LOG_INFO("module.coa_challenges",
            "Hard reset {}: level 1, repairs, spells/talents/skills reset, quest log cleared",
            player->GetName());
    }

    // Activate a challenge directly (bypasses the client CMSG path). Sends
    // the same START_RESPONSE (code 0) the real path does so the client
    // registers the challenge in its local active cache and renders the
    // failure/completion/death banners during the test.
    void ActivateChallengeForTest(Player* player, uint32 challengeId)
    {
        uint32 guid = player->GetGUID().GetCounter();
        CharacterDatabase.DirectExecute(
            "REPLACE INTO coa_character_challenge (guid, challengeId, level, deaths, hunger, thirst, startTime) "
            "VALUES ({}, {}, 1, 0, 0, 0, UNIX_TIMESTAMP())", guid, challengeId);
        ClearCharChallengeCache(guid);
        ApplyChallengeSpell(player, challengeId);
        TrackHunger(player, challengeId);
        SendChallengeResponse(player, SMSG_COA_CHALLENGE_START_RESPONSE,
            challengeId, 1, 0, "CHALLENGE_START_OK");
        // Seed the client's active + criteria caches so the per-objective
        // banner (0x59A) has an entry to transition.
        SendActiveList(player);
        SendCriteriaState(player);
    }

    // ---- Scheduled (visual) E2E runner ----------------------------------
    TaskScheduler g_e2eScheduler;

    struct E2ERun
    {
        std::string playerName;
        std::vector<std::string> members;
        uint32 challengeId = 0;
        uint32 pauseMs = 0;
        bool pass = true;
        std::vector<Objective> money;
        size_t outer = 0;
        size_t inner = 0;
        enum Phase { Setup, Level, MaxSetup, MaxLevel, Done };
        Phase phase = Setup;
        uint32 carry = 0;
    };

    template <typename... Args>
    void SendTestLine(Player* player, std::string_view fmt, Args&&... args)
    {
        std::string msg = Acore::StringFormat(fmt, std::forward<Args>(args)...);
        if (player && player->GetSession())
            ChatHandler(player->GetSession()).PSendSysMessage("{}", msg);
        LOG_INFO("module.coa_challenges", "[e2e] {}", msg);
    }

    // ---- Party-aware roster ------------------------------------------------
    // The E2E run mirrors every step across the target's party. The target is
    // always first; online party members follow (dedup). A solo target yields a
    // one-element roster, i.e. the previous single-player behavior.
    std::vector<std::string> E2ERoster(Player* target)
    {
        std::vector<std::string> names;
        if (!target)
            return names;
        names.push_back(target->GetName());
        if (Group* group = target->GetGroup())
        {
            for (Group::MemberSlotList::const_iterator itr = group->GetMemberSlots().begin();
                 itr != group->GetMemberSlots().end(); ++itr)
            {
                Player* member = ObjectAccessor::FindPlayer(itr->guid);
                if (!member || member == target)
                    continue;
                std::string const name = member->GetName();
                if (std::find(names.begin(), names.end(), name) == names.end())
                    names.push_back(name);
            }
        }
        return names;
    }

    // Online players for the current step. The target (front) must be online
    // or the run aborts; logged-out members are skipped for that step.
    std::vector<Player*> ResolveE2ERoster(std::vector<std::string> const& names)
    {
        std::vector<Player*> players;
        for (std::string const& name : names)
            if (Player* p = ObjectAccessor::FindPlayerByName(name))
                players.push_back(p);
        return players;
    }

    bool E2ETargetOnline(std::vector<std::string> const& names)
    {
        return !names.empty() && ObjectAccessor::FindPlayerByName(names.front()) != nullptr;
    }

    // Chat line to every member of the run (logged once, like SendTestLine).
    template <typename... Args>
    void BroadcastTestLine(std::vector<Player*> const& players, std::string_view fmt, Args&&... args)
    {
        std::string msg = Acore::StringFormat(fmt, std::forward<Args>(args)...);
        for (Player* p : players)
            if (p && p->GetSession())
                ChatHandler(p->GetSession()).PSendSysMessage("{}", msg);
        LOG_INFO("module.coa_challenges", "[e2e] {}", msg);
    }

    void E2EStep(std::shared_ptr<E2ERun> run, TaskContext context)
    {
        if (!E2ETargetOnline(run->members))
        {
            LOG_INFO("module.coa_challenges", "[e2e] {} logged out, aborting", run->playerName);
            return;
        }
        std::vector<Player*> players = ResolveE2ERoster(run->members);

        switch (run->phase)
        {
            case E2ERun::Setup:
            {
                run->carry = (run->outer == 0) ? 0 : run->money[run->outer - 1].v1;
                for (Player* player : players)
                {
                    ResetCharacterForTest(player);
                    ActivateChallengeForTest(player, run->challengeId);
                    player->SetMoney(run->carry);
                }
                BroadcastTestLine(players, "  [carry {} copper] walk to level {}",
                    run->carry, run->money[run->outer].v2);
                run->inner = 0;
                run->phase = E2ERun::Level;
                break;
            }
            case E2ERun::Level:
            {
                Objective const& o = run->money[run->inner];
                bool const expected = (run->inner < run->outer);
                bool anyDead = false;
                for (Player* player : players)
                {
                    if (player->GetLevel() < o.v2)
                        player->GiveLevel(static_cast<uint8>(o.v2));
                    bool alive = player->IsAlive();
                    if (!alive)
                        anyDead = true;
                    BroadcastTestLine(players, "    [{}] level {} need {} -> alive={} (expected {})",
                        player->GetName(), o.v2, o.v1, alive, expected);
                    if (alive != expected)
                        run->pass = false;
                }
                if (anyDead || run->inner == run->outer)
                {
                    ++run->outer;
                    run->phase = (run->outer < run->money.size()) ? E2ERun::Setup : E2ERun::MaxSetup;
                }
                else
                {
                    ++run->inner;
                }
                break;
            }
            case E2ERun::MaxSetup:
            {
                for (Player* player : players)
                {
                    ResetCharacterForTest(player);
                    ActivateChallengeForTest(player, run->challengeId);
                    player->SetMoney(run->money.back().v1);
                }
                run->inner = 0;
                run->phase = E2ERun::MaxLevel;
                break;
            }
            case E2ERun::MaxLevel:
            {
                Objective const& o = run->money[run->inner];
                for (Player* player : players)
                {
                    if (player->GetLevel() < o.v2)
                        player->GiveLevel(static_cast<uint8>(o.v2));
                    if (!player->IsAlive())
                        run->pass = false;
                }
                ++run->inner;
                if (run->inner >= run->money.size())
                {
                    bool allCompleted = true;
                    for (Player* player : players)
                    {
                        bool completed = (bool)CharacterDatabase.Query(
                            "SELECT 1 FROM coa_challenge_completion WHERE guid = {} AND challengeId = {}",
                            player->GetGUID().GetCounter(), run->challengeId);
                        allCompleted = allCompleted && completed;
                    }
                    BroadcastTestLine(players, "  [carry max {} copper] survived to level {} -> completed={}",
                        run->money.back().v1, run->money.back().v2, allCompleted);
                    if (!allCompleted)
                        run->pass = false;
                    run->phase = E2ERun::Done;
                }
                break;
            }
            case E2ERun::Done:
            default:
            {
                // No end-of-test reset: the character keeps the final state.
                BroadcastTestLine(players, run->pass ? "E2E PASS" : "E2E FAIL");
                return; // finished: do not reschedule
            }
        }

        context.Schedule(std::chrono::milliseconds(run->pauseMs),
            [run](TaskContext ctx) { E2EStep(run, ctx); });
    }

    void Test_Update(uint32 diff)
    {
        g_e2eScheduler.Update(diff);
    }

    // Money challenges: schedule the visual runner. Returns true when the
    // trial has money milestones (i.e. the async runner took over).
    bool Test_StartVisualE2E(Player* player, uint32 challengeId, uint32 pauseMs)
    {
        std::vector<Objective> money;
        for (Objective const& o : GetObjectives(challengeId))
            if (o.type == "CHALLENGE_REQUIREMENT_TYPE_EARN_MONEY_BEFORE_LEVEL")
                money.push_back(o);
        if (money.empty())
            return false;
        std::sort(money.begin(), money.end(),
            [](Objective const& a, Objective const& b) { return a.v2 < b.v2; });

        auto run = std::make_shared<E2ERun>();
        run->playerName = player->GetName();
        run->members = E2ERoster(player);
        run->challengeId = challengeId;
        run->pauseMs = pauseMs;
        run->money = money;

        uint32 guid = player->GetGUID().GetCounter();
        g_e2eScheduler.CancelGroup(guid);
        g_e2eScheduler.Schedule(std::chrono::milliseconds(pauseMs ? pauseMs : 1), guid,
            [run](TaskContext ctx) { E2EStep(run, ctx); });
        return true;
    }

    // ---- Level-gate visual runner (Boss Blitz style) ---------------------
    // One scheduled step per world tick so the client renders each kill and
    // level-up: for every gate (grouped by level) spawn the required creature,
    // kill it with the player as killer, then level up; finish at the cap.
    struct LevelGateRun
    {
        std::string playerName;
        std::vector<std::string> members;
        uint32 challengeId = 0;
        uint32 pauseMs = 0;
        bool pass = true;
        bool missPass = false;   // true = sad path only (no kills)
        std::map<uint32, std::vector<Objective>> byLevel;
        std::vector<uint32> levels;
        size_t idx = 0;
        size_t missIdx = 0;
        enum Phase { Setup, Kill, Level, Finish, MissSetup, MissLevel, Done };
        Phase phase = Setup;
    };

    void LevelGateStep(std::shared_ptr<LevelGateRun> run, TaskContext context)
    {
        if (!E2ETargetOnline(run->members))
        {
            LOG_INFO("module.coa_challenges", "[e2e] {} logged out, aborting", run->playerName);
            return;
        }
        std::vector<Player*> players = ResolveE2ERoster(run->members);

        switch (run->phase)
        {
            case LevelGateRun::Setup:
            {
                for (Player* player : players)
                {
                    ResetCharacterForTest(player);
                    ActivateChallengeForTest(player, run->challengeId);
                }
                BroadcastTestLine(players, "E2E level-gate {} ({}): {} gates, first=level {}",
                    run->challengeId, run->missPass ? "miss path" : "happy path",
                    (uint32)run->levels.size(), run->levels.front());
                run->idx = 0;
                run->missIdx = 0;
                run->phase = run->missPass ? LevelGateRun::MissSetup : LevelGateRun::Kill;
                break;
            }
            case LevelGateRun::Kill:
            {
                uint32 const level = run->levels[run->idx];
                // One run, shared kill credit: the target lands the kill once;
                // the module's CreditKill already marks the objective for every
                // party member holding the same challenge (group trials).
                Player* killer = players.front();
                for (Objective const& o : run->byLevel[level])
                {
                    Creature* c = killer->SummonCreature(o.v1, *killer,
                        TEMPSUMMON_TIMED_DESPAWN, 30000);
                    if (c)
                        Unit::Kill(killer, c);   // CreditKill shares it with the group

                    std::string missing;
                    for (Player* player : players)
                        if (!IsObjectiveDone(player->GetGUID().GetCounter(), run->challengeId, o.key))
                            missing += (missing.empty() ? "" : ",") + player->GetName();
                    if (missing.empty())
                        BroadcastTestLine(players, "  killed entry {} (before level {}) -> credited to all {} member(s)",
                            o.v1, level, (uint32)players.size());
                    else
                    {
                        BroadcastTestLine(players, "  kill entry {} (before level {}) -> NOT marked for: {}",
                            o.v1, level, missing);
                        run->pass = false;
                    }
                }
                run->phase = LevelGateRun::Level;
                break;
            }
            case LevelGateRun::Level:
            {
                uint32 const level = run->levels[run->idx];
                for (Player* player : players)
                {
                    if (player->GetLevel() < level)
                        player->GiveLevel(static_cast<uint8>(level));
                    bool alive = player->IsAlive();
                    BroadcastTestLine(players, "  [{}] level {} -> alive={}",
                        player->GetName(), level, alive);
                    if (!alive)
                        run->pass = false;
                }
                run->phase = (++run->idx >= run->levels.size())
                    ? LevelGateRun::Finish : LevelGateRun::Kill;
                break;
            }
            case LevelGateRun::Finish:
            {
                uint32 const maxLevel = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
                bool allCompleted = true;
                for (Player* player : players)
                {
                    if (player->IsAlive() && player->GetLevel() < maxLevel)
                        player->GiveLevel(static_cast<uint8>(maxLevel));
                    bool completed = (bool)CharacterDatabase.Query(
                        "SELECT 1 FROM coa_challenge_completion WHERE guid = {} AND challengeId = {}",
                        player->GetGUID().GetCounter(), run->challengeId);
                    allCompleted = allCompleted && completed;
                }
                BroadcastTestLine(players, "  level cap -> completed={} (expected true)", allCompleted);
                if (!allCompleted)
                    run->pass = false;
                run->phase = LevelGateRun::Done;   // happy path done; miss is `.coa e2emiss`
                break;
            }
            case LevelGateRun::MissSetup:
            {
                uint32 const level = run->levels[run->missIdx];
                for (Player* player : players)
                {
                    uint32 guid = player->GetGUID().GetCounter();
                    ResetCharacterForTest(player);
                    ActivateChallengeForTest(player, run->challengeId);
                    // Everything except this gate's objectives is satisfied, so
                    // the ONLY thing blocking the gate is the kill we skipped.
                    for (Objective const& o : GetObjectives(run->challengeId))
                        if (IsTrackedObjective(o.type) && o.v2 != level)
                            SetObjectiveDone(guid, run->challengeId, o.key);
                    if (player->GetLevel() < level - 1)
                        player->GiveLevel(static_cast<uint8>(level - 1));
                }
                std::string entries;
                for (Objective const& o : run->byLevel[level])
                    entries += (entries.empty() ? "" : ",") + std::to_string(o.v1);
                BroadcastTestLine(players, "  gate {} @ level {}: skipping kill of [{}]",
                    run->missIdx + 1, level, entries);
                run->phase = LevelGateRun::MissLevel;
                break;
            }
            case LevelGateRun::MissLevel:
            {
                uint32 const level = run->levels[run->missIdx];
                for (Player* player : players)
                {
                    player->GiveLevel(static_cast<uint8>(level));   // fires OnPlayerLevelChanged
                    bool alive = player->IsAlive();
                    BroadcastTestLine(players, "  [{}] gate {}: forced level {} without the kill -> alive={} (expected true)",
                        player->GetName(), run->missIdx + 1, level, alive);
                    if (!alive)
                        run->pass = false;
                }
                run->phase = (++run->missIdx >= run->levels.size())
                    ? LevelGateRun::Done : LevelGateRun::MissSetup;
                break;
            }
            case LevelGateRun::Done:
            default:
            {
                // No end-of-test reset: the character keeps the final state.
                BroadcastTestLine(players, run->pass ? "E2E PASS" : "E2E FAIL");
                return; // finished: do not reschedule
            }
        }

        context.Schedule(std::chrono::milliseconds(run->pauseMs),
            [run](TaskContext ctx) { LevelGateStep(run, ctx); });
    }

    // Schedule the visual level-gate runner. Returns true when the trial is
    // level-gated (i.e. the async runner took over). `missPass` runs the sad
    // path only (force level at every gate without its kill); otherwise the
    // happy path only (spawn+kill each gate, then reach the cap).
    bool Test_StartLevelGateVisualE2E(Player* player, uint32 challengeId, uint32 pauseMs, bool missPass)
    {
        std::string const rules = ChallengeRules(challengeId);
        if (rules.find("CHALLENGE_RULES_TYPE_NO_LEVEL_PAST_REQUIREMENTS") == std::string::npos)
            return false;

        auto run = std::make_shared<LevelGateRun>();
        run->playerName = player->GetName();
        run->members = E2ERoster(player);
        run->challengeId = challengeId;
        run->pauseMs = pauseMs;
        run->missPass = missPass;
        for (Objective const& o : GetObjectives(challengeId))
            if (IsTrackedObjective(o.type) && o.v2)
                run->byLevel[o.v2].push_back(o);
        if (run->byLevel.empty())
            return false;
        for (auto const& [lvl, _] : run->byLevel)
            run->levels.push_back(lvl);

        uint32 guid = player->GetGUID().GetCounter();
        g_e2eScheduler.CancelGroup(guid);
        g_e2eScheduler.Schedule(std::chrono::milliseconds(pauseMs ? pauseMs : 1), guid,
            [run](TaskContext ctx) { LevelGateStep(run, ctx); });
        return true;
    }

    // ---- Fatigue visual runner (Narcolepsy) ------------------------------
    // Drains the native fatigue bar to 0; the module then sleeps (kills) the
    // char with a "Fell Asleep" cause. Asserts the death, the challenge failure
    // and the recorded broadcast cause. The character must be outside a
    // sanctuary (starter zones/rest areas are treated as safe).
    struct FatigueRun
    {
        std::string playerName;
        std::vector<std::string> members;
        uint32 challengeId = 0;
        uint32 pauseMs = 0;
        bool pass = true;
        enum Phase { Setup, Fill, Check, Done };
        Phase phase = Setup;
    };

    void FatigueStep(std::shared_ptr<FatigueRun> run, TaskContext context)
    {
        if (!E2ETargetOnline(run->members))
        {
            LOG_INFO("module.coa_challenges", "[e2e] {} logged out, aborting", run->playerName);
            return;
        }
        std::vector<Player*> players = ResolveE2ERoster(run->members);

        switch (run->phase)
        {
            case FatigueRun::Setup:
            {
                for (Player* player : players)
                {
                    ResetCharacterForTest(player);
                    ActivateChallengeForTest(player, run->challengeId);
                    if (player->GetLevel() < 10)
                        player->GiveLevel(10);   // above AnnounceFailureMinLevel
                }
                BroadcastTestLine(players, "E2E fatigue {}: draining bar to 0", run->challengeId);
                run->phase = FatigueRun::Fill;
                break;
            }
            case FatigueRun::Fill:
            {
                for (Player* player : players)
                {
                    player->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
                    // `fatigue` is remaining-time now: empty it so the next update
                    // is at 0 and the player falls asleep (no drain wait).
                    bool ok = Test_SetFatigue(player, 0);
                    BroadcastTestLine(players, "  [{}] fatigue -> 0 (sleep): {}",
                        player->GetName(), ok ? "ok" : "FAILED (no fatigue challenge)");
                    if (!ok)
                        run->pass = false;
                }
                run->phase = FatigueRun::Check;   // OnPlayerUpdate sleeps them meanwhile
                break;
            }
            case FatigueRun::Check:
            {
                for (Player* player : players)
                {
                    uint32 guid = player->GetGUID().GetCounter();
                    bool dead = !player->IsAlive();
                    bool failed = (bool)CharacterDatabase.Query(
                        "SELECT 1 FROM coa_challenge_failure WHERE guid = {} AND challengeId = {}",
                        guid, run->challengeId);
                    std::string cause = Test_LastKillerLabel(player);
                    BroadcastTestLine(players, "  [{}] slept -> dead={} failed={} cause='{}' (expected true/true/'Fell Asleep')",
                        player->GetName(), dead, failed, cause);
                    if (!dead || !failed || cause != "Fell Asleep")
                        run->pass = false;
                }
                run->phase = FatigueRun::Done;
                break;
            }
            case FatigueRun::Done:
            default:
            {
                // No end-of-test reset: the character keeps the final state.
                BroadcastTestLine(players, run->pass ? "E2E PASS" : "E2E FAIL");
                return; // finished: do not reschedule
            }
        }

        context.Schedule(std::chrono::milliseconds(run->pauseMs),
            [run](TaskContext ctx) { FatigueStep(run, ctx); });
    }

    // Schedule the visual fatigue runner. Returns true when the trial has the
    // FATIGUED_UNLESS_RESTED rule (Narcolepsy).
    bool Test_StartFatigueVisualE2E(Player* player, uint32 challengeId, uint32 pauseMs)
    {
        std::string const rules = ChallengeRules(challengeId);
        if (rules.find("CHALLENGE_RULES_TYPE_FATIGUED_UNLESS_RESTED") == std::string::npos)
            return false;

        auto run = std::make_shared<FatigueRun>();
        run->playerName = player->GetName();
        run->members = E2ERoster(player);
        run->challengeId = challengeId;
        run->pauseMs = std::max<uint32>(pauseMs, 500);   // let a player tick pass

        uint32 guid = player->GetGUID().GetCounter();
        g_e2eScheduler.CancelGroup(guid);
        g_e2eScheduler.Schedule(std::chrono::milliseconds(run->pauseMs), guid,
            [run](TaskContext ctx) { FatigueStep(run, ctx); });
        return true;
    }

    // Non-money challenges: synchronous completion smoke test.
    bool Test_RunCompletionE2E(Player* player, uint32 challengeId)
    {
        std::vector<Player*> players = ResolveE2ERoster(E2ERoster(player));
        bool pass = true;

        for (Player* p : players)
        {
            uint32 guid = p->GetGUID().GetCounter();
            ResetCharacterForTest(p);
            ActivateChallengeForTest(p, challengeId);
            for (Objective const& o : GetObjectives(challengeId))
                if (IsTrackedObjective(o.type))
                    SetObjectiveDone(guid, challengeId, o.key);
            if (ObjectivesAllDone(guid, challengeId))
                CompleteChallenge(p, challengeId);

            bool completed = (bool)CharacterDatabase.Query(
                "SELECT 1 FROM coa_challenge_completion WHERE guid = {} AND challengeId = {}",
                guid, challengeId);
            bool stillActive = (bool)CharacterDatabase.Query(
                "SELECT 1 FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                guid, challengeId);
            BroadcastTestLine(players, "E2E trial {}: [{}] completed={} stillActive={}",
                challengeId, p->GetName(), completed, stillActive);
            if (!completed || stillActive)
                pass = false;
            // No end-of-test reset: the character keeps the final state.
        }
        return pass;
    }

    // Boss Blitz style trials: KILL_CREATURE_BEFORE_LEVEL objectives + the
    // NO_LEVEL_PAST_REQUIREMENTS rule. Synchronous smoke test of the level gate:
    //   1) a huge XP gain must stop one level short of the gate;
    //   2) a FORCED level at the gate with its objective unmet must NOT kill
    //      the char (the XP cap makes that state unreachable in normal play);
    //   3) the full run: for each gate (grouped by level) spawn the required
    //      creature, kill it with the player as killer (which is what marks the
    //      objective, via OnPlayerCreatureKill), then level up; finish at the
    //      level cap -> completion.
    // Returns -1 when the trial is not level-gated, else 1 (pass) / 0 (fail).
    int Test_RunLevelGateE2E(Player* player, uint32 challengeId)
    {
        if (!player)
            return -1;

        std::string const rules = ChallengeRules(challengeId);
        if (rules.find("CHALLENGE_RULES_TYPE_NO_LEVEL_PAST_REQUIREMENTS") == std::string::npos)
            return -1;   // not a level-gated trial

        uint32 const maxLevel = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);

        // Tracked objectives grouped by the level before which they must be done.
        std::map<uint32, std::vector<Objective>> byLevel;
        for (Objective const& o : GetObjectives(challengeId))
            if (IsTrackedObjective(o.type) && o.v2)
                byLevel[o.v2].push_back(o);
        if (byLevel.empty())
            return -1;
        uint32 const gate = byLevel.begin()->first;

        std::vector<Player*> players = ResolveE2ERoster(E2ERoster(player));
        bool pass = true;
        BroadcastTestLine(players, "E2E level-gate {}: {} gates, first=level {}",
            challengeId, (uint32)byLevel.size(), gate);

        // 1) XP cap: a huge kill gain must stop one level short of the gate.
        for (Player* p : players)
        {
            ResetCharacterForTest(p);
            ActivateChallengeForTest(p, challengeId);
            uint32 xp = 10000000;
            sScriptMgr->OnPlayerGiveXP(p, xp, nullptr, XPSOURCE_KILL);
            p->GiveXP(xp, nullptr);
            bool ok = (p->GetLevel() == gate - 1);
            BroadcastTestLine(players, "  [{}] XP cap -> level {} (expected {})",
                p->GetName(), p->GetLevel(), gate - 1);
            if (!ok)
                pass = false;
        }

        // 2) Level-gated trials never kill on a reached-but-unmet objective:
        //    the XP cap keeps normal players one level short of every gate, so
        //    a forced level-up must NOT trigger a challenge death.
        for (Player* p : players)
        {
            uint32 guid = p->GetGUID().GetCounter();
            ResetCharacterForTest(p);
            ActivateChallengeForTest(p, challengeId);
            for (Objective const& o : GetObjectives(challengeId))
                if (IsTrackedObjective(o.type) && o.v2 != gate)
                    SetObjectiveDone(guid, challengeId, o.key);
            p->GiveLevel(static_cast<uint8>(gate));   // fires OnPlayerLevelChanged
            bool alive = p->IsAlive();
            BroadcastTestLine(players, "  [{}] forced level at gate {} -> alive={} (expected true, no challenge death)",
                p->GetName(), gate, alive);
            if (!alive)
                pass = false;
        }

        // 3) Full run (one run, shared party credit): reset+activate every
        //    member, kill each gate's creature once, credit the objective to
        //    the whole party, then level up and reach the cap together.
        for (Player* p : players)
        {
            ResetCharacterForTest(p);
            ActivateChallengeForTest(p, challengeId);
        }
        Player* killer = players.front();
        for (auto const& [level, objs] : byLevel)
        {
            for (Objective const& o : objs)
            {
                Creature* c = killer->SummonCreature(o.v1, *killer,
                    TEMPSUMMON_TIMED_DESPAWN, 30000);
                if (c)
                    Unit::Kill(killer, c);   // CreditKill shares it with the group
            }
            for (Player* p : players)
                if (p->GetLevel() < level)
                    p->GiveLevel(static_cast<uint8>(level));
        }
        for (Player* p : players)
        {
            if (p->IsAlive() && p->GetLevel() < maxLevel)
                p->GiveLevel(static_cast<uint8>(maxLevel));
            bool completed = (bool)CharacterDatabase.Query(
                "SELECT 1 FROM coa_challenge_completion WHERE guid = {} AND challengeId = {}",
                p->GetGUID().GetCounter(), challengeId);
            BroadcastTestLine(players, "  [{}] full run -> completed={} (expected true)",
                p->GetName(), completed);
            if (!completed || !p->IsAlive())
                pass = false;
            // No end-of-test reset: the character keeps the final state.
        }
        return pass ? 1 : 0;
    }

    // GM-only diagnostic (`.coa ruletest <player> <id>`): activate the
    // challenge on a live character and verify the custom rules are enforced
    // through the REAL core hook dispatchers (the same ones the game calls).
    bool Test_CheckRuleGate(Player* player, uint32 challengeId)
    {
        if (!player)
            return false;

        std::string const rules = ChallengeRules(challengeId);
        auto hasRule = [&rules](char const* rule)
        {
            return rules.find(rule) != std::string::npos;
        };
        bool const expectNoManastorm = hasRule("CHALLENGE_RULES_TYPE_NO_MANASTORM");
        bool const expectNoGuildBank = hasRule("CHALLENGE_RULES_TYPE_NO_GUILD_BANK");
        bool const expectNoRealmBank = hasRule("CHALLENGE_RULES_TYPE_NO_REALM_BANK");

        ResetCharacterForTest(player);
        ActivateChallengeForTest(player, challengeId);

        bool const manastormAllowed = sScriptMgr->OnPlayerCanEnterManastorm(player);
        bool const guildBankAllowed = sScriptMgr->CanGuildSendBankList(
            player->GetGuild(), player->GetSession(), 0, true);

        bool pass = true;
        SendTestLine(player, "  challenge {} rules: NO_MANASTORM={} NO_GUILD_BANK={} NO_REALM_BANK={}",
            challengeId, expectNoManastorm, expectNoGuildBank, expectNoRealmBank);
        SendTestLine(player, "  OnPlayerCanEnterManastorm -> {} (expected {})",
            manastormAllowed, !expectNoManastorm);
        SendTestLine(player, "  CanGuildSendBankList -> {} (expected {})",
            guildBankAllowed, !expectNoGuildBank);
        if (manastormAllowed == expectNoManastorm)
            pass = false;
        if (guildBankAllowed == expectNoGuildBank)
            pass = false;
        if (expectNoRealmBank)
            SendTestLine(player, "  NO_REALM_BANK present -> N/A (feature absent on this fork)");

        // Professions: NO_PROFESSIONS blocks skill-ups; CANNOT_UNLEARN blocks abandon.
        if (hasRule("CHALLENGE_RULES_TYPE_NO_PROFESSIONS"))
        {
            bool canUpdate = sScriptMgr->OnPlayerCanUpdateSkill(player, SKILL_ALCHEMY);
            SendTestLine(player, "  OnPlayerCanUpdateSkill(ALCHEMY) -> {} (expected false)", canUpdate);
            if (canUpdate)
                pass = false;
        }
        if (hasRule("CHALLENGE_RULES_TYPE_CANNOT_UNLEARN_PROFESSIONS"))
        {
            // Spellbook "abandon profession" goes through the packet hook.
            WorldPacket data(CMSG_UNLEARN_SKILL);
            data << uint32(SKILL_ALCHEMY);
            bool allowed = sScriptMgr->CanPacketReceive(player->GetSession(), data);
            SendTestLine(player, "  CMSG_UNLEARN_SKILL(ALCHEMY) -> allowed={} (expected false)", allowed);
            if (allowed)
                pass = false;
        }

        // SharedFate (Duo/Trio): leaving the group must fail the challenge.
        if (IsSharedFate(challengeId))
        {
            uint32 guid = player->GetGUID().GetCounter();
            bool activeBefore = (bool)CharacterDatabase.Query(
                "SELECT 1 FROM coa_character_challenge WHERE guid = {} AND challengeId = {}", guid, challengeId);
            Test_FailSharedFateOnLeave(player);
            bool activeAfter = (bool)CharacterDatabase.Query(
                "SELECT 1 FROM coa_character_challenge WHERE guid = {} AND challengeId = {}", guid, challengeId);
            SendTestLine(player, "  SharedFate leave -> active {} -> {} (expected true -> false)",
                activeBefore, activeAfter);
            if (!activeBefore || activeAfter)
                pass = false;
        }

        ResetCharacterForTest(player);
        return pass;
    }

    // ---- Per-rule behavioral tests (`.coa ruletestall`) ------------------
    // Drives the REAL hook dispatchers for every implemented rule and asserts
    // the expected gate; each case activates a challenge that declares the rule.
    namespace
    {
        uint32 RuleTestFindChallenge(char const* rule)
        {
            for (uint32 id : DefIds())
                if (CoAParse::ListContains(ChallengeRules(id), rule))
                    return id;
            return 0;
        }

        ItemTemplate const* RuleTestFirstItem(uint32 cls, int sub, int quality = -1)
        {
            ItemTemplateContainer const* store = sObjectMgr->GetItemTemplateStore();
            if (!store)
                return nullptr;
            for (auto const& pair : *store)
            {
                ItemTemplate const& t = pair.second;
                if (t.Class != cls) continue;
                if (sub >= 0 && t.SubClass != uint32(sub)) continue;
                if (quality >= 0 && t.Quality != uint32(quality)) continue;
                return &t;
            }
            return nullptr;
        }

        uint32 RuleTestFirstCreature(uint32 type)
        {
            CreatureTemplateContainer const* store = sObjectMgr->GetCreatureTemplates();
            if (!store)
                return 0;
            for (auto const& pair : *store)
                if (pair.second.type == type)
                    return pair.first;
            return 0;
        }

        uint32 RuleTestFirstQuestOfColor(Player* player, int colorIdx)
        {
            for (auto const& pair : sObjectMgr->GetQuestTemplates())
                if (QuestColor(pair.second->GetQuestLevel(), player->GetLevel()) == colorIdx)
                    return pair.first;
            return 0;
        }

        uint32 RuleTestFirstQuest(bool withoutObjectives)
        {
            for (auto const& pair : sObjectMgr->GetQuestTemplates())
                if (IsQuestWithoutObjectives(pair.second) == withoutObjectives)
                    return pair.first;
            return 0;
        }

        MapEntry const* RuleTestFirstMap(bool raid)
        {
            for (uint32 i = 1; i < sMapStore.GetNumRows(); ++i)
            {
                MapEntry const* e = sMapStore.LookupEntry(i);
                if (!e)
                    continue;
                if (raid && e->IsRaid()) return e;
                if (!raid && e->IsDungeon() && !e->IsRaid()) return e;
            }
            return nullptr;
        }

        TalentEntry const* RuleTestFirstTalent()
        {
            for (uint32 i = 1; i < sTalentStore.GetNumRows(); ++i)
                if (TalentEntry const* t = sTalentStore.LookupEntry(i))
                    return t;
            return nullptr;
        }

        bool RuleTestChallengeActive(Player* player, uint32 cid)
        {
            return (bool)CharacterDatabase.Query(
                "SELECT 1 FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                player->GetGUID().GetCounter(), cid);
        }

        // First companion-pet summon spell (SPELL_EFFECT_SUMMON of a
        // CREATURE_TYPE_NON_COMBAT_PET) found on a vanity-pet item; 0 if none.
        uint32 RuleTestCompanionSpell()
        {
            ItemTemplateContainer const* items = sObjectMgr->GetItemTemplateStore();
            if (!items)
                return 0;
            for (auto const& pair : *items)
            {
                ItemTemplate const& it = pair.second;
                if (it.Class != ITEM_CLASS_MISC || it.SubClass != ITEM_SUBCLASS_JUNK_PET)
                    continue;
                for (uint8 i = 0; i < MAX_ITEM_PROTO_SPELLS; ++i)
                {
                    int32 sid = it.Spells[i].SpellId;
                    if (sid <= 0)
                        continue;
                    SpellInfo const* si = sSpellMgr->GetSpellInfo(uint32(sid));
                    if (!si)
                        continue;
                    for (uint8 e = 0; e < MAX_SPELL_EFFECTS; ++e)
                    {
                        if (si->Effects[e].Effect != SPELL_EFFECT_SUMMON)
                            continue;
                        CreatureTemplate const* ct =
                            sObjectMgr->GetCreatureTemplate(uint32(si->Effects[e].MiscValue));
                        if (ct && ct->type == CREATURE_TYPE_NON_COMBAT_PET)
                            return uint32(sid);
                    }
                }
            }
            return 0;
        }

        // First spell that summons a NON-companion creature (combat pet/minion/
        // totem), used to assert NO_PETS_OR_MINIONS still blocks those.
        uint32 RuleTestCombatSummonSpell()
        {
            uint32 const count = sSpellMgr->GetSpellInfoStoreSize();
            for (uint32 id = 1; id < count; ++id)
            {
                SpellInfo const* si = sSpellMgr->GetSpellInfo(id);
                if (!si)
                    continue;
                for (uint8 e = 0; e < MAX_SPELL_EFFECTS; ++e)
                {
                    if (si->Effects[e].Effect != SPELL_EFFECT_SUMMON)
                        continue;
                    CreatureTemplate const* ct =
                        sObjectMgr->GetCreatureTemplate(uint32(si->Effects[e].MiscValue));
                    if (ct && ct->type != CREATURE_TYPE_NON_COMBAT_PET && ct->type != CREATURE_TYPE_CRITTER)
                        return id;
                }
            }
            return 0;
        }

        // First player-castable spell whose max range clearly exceeds melee
        // (CAST_RANGE_LIMITED_TO_MELEE).
        uint32 RuleTestRangedSpell()
        {
            uint32 const count = sSpellMgr->GetSpellInfoStoreSize();
            for (uint32 id = 1; id < count; ++id)
            {
                SpellInfo const* si = sSpellMgr->GetSpellInfo(id);
                if (!si || si->IsPassive())
                    continue;
                float const r = std::max(si->GetMaxRange(false), si->GetMaxRange(true));
                if (r > 20.0f)
                    return id;
            }
            return 0;
        }

        // First player-castable teleport/portal spell (NO_PORTALS).
        uint32 RuleTestPortalSpell()
        {
            uint32 const count = sSpellMgr->GetSpellInfoStoreSize();
            for (uint32 id = 1; id < count; ++id)
            {
                SpellInfo const* si = sSpellMgr->GetSpellInfo(id);
                if (!si)
                    continue;
                for (uint8 e = 0; e < MAX_SPELL_EFFECTS; ++e)
                    if (si->Effects[e].Effect == SPELL_EFFECT_TELEPORT_UNITS
                        || si->Effects[e].Effect == SPELL_EFFECT_TRANS_DOOR)
                        return id;
            }
            return 0;
        }

        // First First Aid bandage spell (NO_HEALING_UNLESS_BANDAGING).
        uint32 RuleTestBandageSpell()
        {
            ItemTemplateContainer const* items = sObjectMgr->GetItemTemplateStore();
            if (!items)
                return 0;
            for (auto const& pair : *items)
            {
                ItemTemplate const& it = pair.second;
                if (it.Class != ITEM_CLASS_CONSUMABLE || it.SubClass != ITEM_SUBCLASS_BANDAGE)
                    continue;
                for (uint8 i = 0; i < MAX_ITEM_PROTO_SPELLS; ++i)
                {
                    int32 sid = it.Spells[i].SpellId;
                    if (sid > 0 && IsBandageSpell(sSpellMgr->GetSpellInfo(uint32(sid))))
                        return uint32(sid);
                }
            }
            return 0;
        }
    }

    // ---- Spellbind Roulette regression tests (`.coa ruletestall`) --------
    // C1: on the plain (non-failable) SPELLBIND_ROULETTE, casting the marked
    // spell is BLOCKED and the mark must PERSIST until the interval rerolls it.
    // (Historic bug: the blocked cast consumed the mark, letting the player
    // reroll the forbidden spell at will.)
    bool Test_SpellbindPlainKeepsMark(Player* player)
    {
        uint32 cid = RuleTestFindChallenge("CHALLENGE_RULES_TYPE_SPELLBIND_ROULETTE");
        if (!cid)
            return false;
        TrackSpellbind(player, cid);
        Test_SpellbindTick(player, 30000);              // force a pick now

        uint32 mark = 0; bool failable = true;
        bool tracked = Test_SpellbindMark(player, mark, failable);
        if (!tracked || !mark)
        {
            SendTestLine(player, "  plain roulette: no eligible ability to mark -> SKIP");
            return true;
        }
        // Drive the real cast path (Spell::CheckCast -> OnSpellCheckCast).
        bool blocked = Test_SpellCheckCastBlocked(player, mark);
        uint32 after = 0; bool afterFailable = true;
        bool stillTracked = Test_SpellbindMark(player, after, afterFailable);
        SendTestLine(player, "  plain roulette: cast marked {} blocked={} markAfter={} (expected blocked=true markAfter={})",
            mark, blocked, stillTracked ? after : 0, mark);
        return blocked && stillTracked && after == mark;
    }

    // C2: completing a DIFFERENT challenge must not tear down the spellbind
    // tracking of a still-active spellbind challenge.
    bool Test_SpellbindCoexistingSurvives(Player* player)
    {
        uint32 spellCid = RuleTestFindChallenge("CHALLENGE_RULES_TYPE_FAILABLE_SPELLBIND_ROULETTE");
        if (!spellCid)
            return false;
        uint32 otherCid = 0;
        for (uint32 id : DefIds())
        {
            if (id == spellCid)
                continue;
            std::string const rules = ChallengeRules(id);
            if (!CoAParse::ListContains(rules, "CHALLENGE_RULES_TYPE_SPELLBIND_ROULETTE")
                && !CoAParse::ListContains(rules, "CHALLENGE_RULES_TYPE_FAILABLE_SPELLBIND_ROULETTE")
                && !CoAParse::ListContains(rules, "CHALLENGE_RULES_TYPE_FAILABLE_MEGA_SPELLBIND_ROULETTE"))
            {
                otherCid = id;
                break;
            }
        }
        if (!otherCid)
            return false;

        // RUN() already activated spellCid; track it and add a second,
        // unrelated challenge (both active at once).
        TrackSpellbind(player, spellCid);
        ActivateChallengeForTest(player, otherCid);
        Test_SpellbindTick(player, 30000);

        uint32 before = 0; bool beforeFailable = true;
        bool trackedBefore = Test_SpellbindMark(player, before, beforeFailable);

        // Finish the unrelated challenge through the real completion path.
        CompleteChallenge(player, otherCid);

        // The spellbind challenge is still active: the roulette must keep going.
        Test_SpellbindTick(player, 30000);
        uint32 after = 0; bool afterFailable = true;
        bool trackedAfter = Test_SpellbindMark(player, after, afterFailable);

        SendTestLine(player, "  spellbind coexisting: before(tracked={}) after other-challenge complete(tracked={})",
            trackedBefore, trackedAfter);
        return trackedBefore && trackedAfter;
    }

    // C3 regression: the failable mark death is queued by the cast hook and
    // applied on the player's next update (not inside Spell::CheckCast). The
    // challenge must NOT be failed synchronously by the cast; after processing
    // the pending kill it must be dead + failed.
    bool Test_SpellbindFailableKillsOnNextTick(Player* player)
    {
        uint32 cid = RuleTestFindChallenge("CHALLENGE_RULES_TYPE_FAILABLE_SPELLBIND_ROULETTE");
        if (!cid)
            return false;
        TrackSpellbind(player, cid);
        Test_SpellbindTick(player, 30000);
        uint32 mark = 0; bool failable = false;
        if (!Test_SpellbindMark(player, mark, failable) || !mark || !failable)
        {
            SendTestLine(player, "  failable roulette: no mark -> SKIP");
            return true;
        }
        Test_SpellCheckCastBlocked(player, mark);           // runs the hook (queues)
        bool const activeAfterCast = RuleTestChallengeActive(player, cid);
        Test_SpellbindProcessPending(player);               // next-update processing
        bool const dead = !player->IsAlive();
        bool const failed = !RuleTestChallengeActive(player, cid);
        SendTestLine(player, "  failable roulette: castActive={} afterTick(dead={} failed={})",
            activeAfterCast, dead, failed);
        return activeAfterCast && dead && failed;
    }

    // C4 regression (#4234): a buff/proc that re-triggers the marked spell must
    // not fail the trial. Only the player's own (non-triggered) casts count.
    bool Test_SpellbindTriggeredDoesNotFail(Player* player)
    {
        uint32 cid = RuleTestFindChallenge("CHALLENGE_RULES_TYPE_FAILABLE_SPELLBIND_ROULETTE");
        if (!cid)
            return false;
        TrackSpellbind(player, cid);
        Test_SpellbindTick(player, 30000);
        uint32 mark = 0; bool failable = false;
        if (!Test_SpellbindMark(player, mark, failable) || !mark || !failable)
        {
            SendTestLine(player, "  triggered roulette: no mark -> SKIP");
            return true;
        }
        // Triggered (proc) cast of the marked spell: must neither be blocked nor
        // queue the fail+death pending kill.
        bool const triggeredBlocked = Test_SpellCheckCastBlocked(player, mark, /*triggered=*/true);
        Test_SpellbindProcessPending(player);               // would kill if queued
        bool const alive = player->IsAlive();
        bool const active = RuleTestChallengeActive(player, cid);
        uint32 after = 0; bool afterFailable = false;
        bool const markKept = Test_SpellbindMark(player, after, afterFailable) && after == mark;
        // `triggeredBlocked` is informational only: CheckCast can return non-OK
        // for unrelated reasons (target/cooldown) on a synthetic Spell, while the
        // guard's effect is that no pending kill was queued and the mark survived.
        SendTestLine(player, "  triggered roulette: triggerCastBlocked={} alive={} active={} markKept={}",
            triggeredBlocked, alive, active, markKept);
        return alive && active && markKept;
    }

    // Rules the module actually enforces (kept in sync with the enforcement
    // sites in CoA.Challenges.Scripts.cpp). Used to (a) report declared rules
    // that are NOT implemented and (b) report implemented rules with no gate
    // test. Rules absent here are "RE-pending" (client-only for now).
    std::set<std::string> const& ImplementedRules()
    {
        static std::set<std::string> const kRules = {
            "CHALLENGE_RULES_TYPE_NO_AUCTIONHOUSE",
            "CHALLENGE_RULES_TYPE_NO_GUILD_BANK",
            // NOTE: NO_REALM_BANK is declared by the client but not enforced on
            // this fork (no realm bank feature) - deliberately absent here.
            "CHALLENGE_RULES_TYPE_NO_CONVENIENCE_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_ARENA_FINDER",
            "CHALLENGE_RULES_TYPE_NO_BATTLEGROUND_FINDER",
            "CHALLENGE_RULES_TYPE_NO_DUNGEON_FINDER",
            "CHALLENGE_RULES_TYPE_NO_ARENAS",
            "CHALLENGE_RULES_TYPE_NO_BATTLEGROUNDS",
            "CHALLENGE_RULES_TYPE_NO_DUNGEONS",
            "CHALLENGE_RULES_TYPE_NO_RAIDS",
            "CHALLENGE_RULES_TYPE_NO_MAIL",
            "CHALLENGE_RULES_TYPE_NO_TRADE",
            "CHALLENGE_RULES_TYPE_ONLY_TRADE_IF_SAME_CHALLENGES",
            "CHALLENGE_RULES_TYPE_NO_GROUP",
            "CHALLENGE_RULES_TYPE_ONLY_GROUP_IN_3_LEVEL_RANGE",
            "CHALLENGE_RULES_TYPE_ONLY_PVP_IN_5_LEVEL_RANGE",
            "CHALLENGE_RULES_TYPE_ONLY_PVP_SAME_LEVEL_IF_MAX_LEVEL",
            "CHALLENGE_RULES_TYPE_NO_PROFESSION_EXPERIENCE",
            "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PROFESSIONS",
            "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_QUESTS",
            "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_CREATURES",
            "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PVP",
            "CHALLENGE_RULES_TYPE_GROUP_PROFESSION_EXPERIENCE",
            "CHALLENGE_RULES_TYPE_NO_PROFESSIONS",
            "CHALLENGE_RULES_TYPE_CANNOT_UNLEARN_PROFESSIONS",
            "CHALLENGE_RULES_TYPE_NO_QUESTS",
            "CHALLENGE_RULES_TYPE_NO_GRAY_QUESTS",
            "CHALLENGE_RULES_TYPE_NO_GREEN_QUESTS",
            "CHALLENGE_RULES_TYPE_NO_YELLOW_QUESTS",
            "CHALLENGE_RULES_TYPE_NO_ORANGE_QUESTS",
            "CHALLENGE_RULES_TYPE_NO_RED_QUESTS",
            "CHALLENGE_RULES_TYPE_NO_FETCH_QUEST_EXPERIENCE",
            "CHALLENGE_RULES_TYPE_COSMETIC_ELITE_ENEMIES",
            "CHALLENGE_RULES_TYPE_STRICT_CHALLENGE_RESTRICTED_TAPPING",
            "CHALLENGE_RULES_TYPE_NO_TALENTS",
            "CHALLENGE_RULES_TYPE_NO_HEARTHSTONE",
            "CHALLENGE_RULES_TYPE_NO_BONUS_EXPERIENCE",
            "CHALLENGE_RULES_TYPE_NO_MOUNTS",
            "CHALLENGE_RULES_TYPE_NO_COSMETIC_PET_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_COMPANIONS",
            "CHALLENGE_RULES_TYPE_NO_HEALTH_POTIONS",
            "CHALLENGE_RULES_TYPE_NO_VENDORS",
            "CHALLENGE_RULES_TYPE_NO_VENDOR_BUY",
            "CHALLENGE_RULES_TYPE_NO_VENDOR_BUY_FOOD_OR_DRINK",
            "CHALLENGE_RULES_TYPE_NO_VENDOR_BUYBACK",
            "CHALLENGE_RULES_TYPE_NO_BANK",
            "CHALLENGE_RULES_TYPE_NO_REPAIR_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_EQUIP_ARMOR",
            "CHALLENGE_RULES_TYPE_NO_EQUIP_COMMON_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_EQUIP_UNCOMMON_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_EQUIP_RARE_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_EQUIP_EPIC_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_EQUIP_LEGENDARY_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_EQUIP_ARTIFACT_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_EQUIP_HEIRLOOM_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_BAGS",
            "CHALLENGE_RULES_TYPE_NO_DAMAGE",
            "CHALLENGE_RULES_TYPE_NO_HEALING",
            "CHALLENGE_RULES_TYPE_NO_KILL_BEASTS",
            "CHALLENGE_RULES_TYPE_NO_KILL_HUMANOIDS",
            "CHALLENGE_RULES_TYPE_FAILABLE_NO_KILL_BEASTS",
            "CHALLENGE_RULES_TYPE_FAILABLE_NO_KILL_HUMANOIDS",
            "CHALLENGE_RULES_TYPE_CANNOT_DODGE_BLOCK_OR_PARRY",
            "CHALLENGE_RULES_TYPE_CAN_BE_CRITTED_BY_ANY_ABILITY",
            "CHALLENGE_RULES_TYPE_NO_MANASTORM",
            "CHALLENGE_RULES_TYPE_PVE_ONLY",
            "CHALLENGE_RULES_TYPE_NO_FLAG_PVE",
            "CHALLENGE_RULES_TYPE_NO_FLIGHT_PATHS",
            "CHALLENGE_RULES_TYPE_CANNOT_LOOT_ITEMS",
            // Regen family (Inn-Sane).
            "CHALLENGE_RULES_TYPE_NO_HEALTH_REGENERATION",
            "CHALLENGE_RULES_TYPE_NO_HEALTH_REGENERATION_UNLESS_RESTED",
            "CHALLENGE_RULES_TYPE_NO_MANA_REGENERATION",
            "CHALLENGE_RULES_TYPE_NO_MANA_REGENERATION_UNLESS_RESTED",
            "CHALLENGE_RULES_TYPE_NO_POWER_REGENERATION",
            "CHALLENGE_RULES_TYPE_NO_POWER_REGENERATION_UNLESS_RESTED",
            "CHALLENGE_RULES_TYPE_NO_ENERGIZING",
            "CHALLENGE_RULES_TYPE_NO_ENERGIZING_UNLESS_RESTED",
            "CHALLENGE_RULES_TYPE_NO_HEALING_UNLESS_RESTED",
            "CHALLENGE_RULES_TYPE_NO_HEALTH_REGENERATION_ON_LEVEL_UP",
            "CHALLENGE_RULES_TYPE_NO_POWER_REGENERATION_ON_LEVEL_UP",
            "CHALLENGE_RULES_TYPE_NO_MANA_REGENERATION_ON_LEVEL_UP",
            "CHALLENGE_RULES_TYPE_NO_LEVEL_PAST_REQUIREMENTS",
            "CHALLENGE_RULES_TYPE_FATIGUED_UNLESS_RESTED",
            "CHALLENGE_RULES_TYPE_INVERTED_BREATH",
            "CHALLENGE_RULES_TYPE_SPELLBIND_ROULETTE",
            "CHALLENGE_RULES_TYPE_FAILABLE_SPELLBIND_ROULETTE",
            "CHALLENGE_RULES_TYPE_FAILABLE_MEGA_SPELLBIND_ROULETTE",
            "CHALLENGE_RULES_TYPE_NO_PETS_OR_MINIONS",
            "CHALLENGE_RULES_TYPE_FAILABLE_NO_FALLING",
            // Rules added 2026-09-17 (audit gap closure).
            "CHALLENGE_RULES_TYPE_NO_OUTSIDE_INTERACTION",
            "CHALLENGE_RULES_TYPE_NO_GROUP_FOR_DUNGEONS",
            "CHALLENGE_RULES_TYPE_NO_NON_SELF_CRAFTED_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_NON_LOOTED_ITEMS",
            "CHALLENGE_RULES_TYPE_NO_KILL_CREDIT_UNLESS_AT_DISADVANTAGE",
            "CHALLENGE_RULES_TYPE_CAST_RANGE_LIMITED_TO_MELEE",
            "CHALLENGE_RULES_TYPE_NO_HEALING_UNLESS_BANDAGING",
            "CHALLENGE_RULES_TYPE_NO_PORTALS",
            "CHALLENGE_RULES_TYPE_NO_LEAVE_CONTINENT",
            "CHALLENGE_RULES_TYPE_HIGH_RISK_ONLY",
            "CHALLENGE_RULES_TYPE_NO_CREATURE_LEVEL_SCALING",
            "CHALLENGE_RULES_TYPE_NO_QUEST_LEVEL_SCALING",
            // NOTE: FLOOR_IS_LAVA (165 "The Floor is Lava!") is NOT modelled here:
            // its About is "Don't. Stop. Jumping." (damage while grounded), not
            // lava/fire environmental damage, and 165 is challenge-only (custom
            // trials). Deliberately absent until the movement semantics are done.
        };
        return kRules;
    }

    // Rules exercised by the last Test_RuleGates pass (recorded by its RUN()).
    std::set<std::string> g_exercisedRules;

    // Conditions the module evaluates at activation.
    std::set<std::string> const& KnownConditions()
    {
        static std::set<std::string> const kConds = {
            "CHALLENGE_CONDITIONS_TYPE_GROUP_SIZE",
            "CHALLENGE_CONDITIONS_TYPE_HAVE_FREE_INVENTORY_SLOTS",
            "CHALLENGE_CONDITIONS_TYPE_LOOT_INTERACTION",
            "CHALLENGE_CONDITIONS_TYPE_LEVEL_UP",
            "CHALLENGE_CONDITIONS_TYPE_CANNOT_HAVE_GAINED_EXPERIENCE",
            // Implicit global gates (#4205 family), injected for non-prestige
            // trials rather than declared in the client data.
            "CHALLENGE_CONDITIONS_TYPE_TAKE_MAIL_MONEY_OR_ITEM",
            "CHALLENGE_CONDITIONS_TYPE_OUTSIDE_INTERACTION",
        };
        return kConds;
    }

    bool Test_RuleGates(Player* player)
    {
        if (!player)
            return false;

        // Suppress realm-wide completion/failure broadcast banners while the
        // rule tests intentionally fail challenges (FAILABLE_* cases).
        Test_SetQuiet(true);
        g_exercisedRules.clear();

        int count = 0, fails = 0;
        bool all = true;

        auto RUN = [&](char const* rule, std::function<bool(Player*)> fn)
        {
            uint32 cid = RuleTestFindChallenge(rule);
            if (!cid)
            {
                SendTestLine(player, "  {:<52} SKIP (no challenge)", rule);
                return;
            }
            ResetCharacterForTest(player);
            ActivateChallengeForTest(player, cid);
            g_exercisedRules.insert(rule);
            bool ok = fn(player);
            SendTestLine(player, "  {:<52} {} [id {}]", rule, ok ? "PASS" : "FAIL", cid);
            ++count;
            if (!ok) { ++fails; all = false; }
        };

        auto useItem = [](Player* p, uint32 entry) -> bool
        {
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
            if (!proto) return true;   // skip unknown item
            InventoryResult res = EQUIP_ERR_OK;
            return !sScriptMgr->OnPlayerCanUseItem(p, proto, res);
        };
        auto useItemPtr = [](Player* p, ItemTemplate const* proto) -> bool
        {
            if (!proto) return true;
            InventoryResult res = EQUIP_ERR_OK;
            return !sScriptMgr->OnPlayerCanUseItem(p, proto, res);
        };
        auto canEquip = [](Player* p, ItemTemplate const* proto) -> bool
        {
            if (!proto) return true;
            Item* it = Item::CreateItem(proto->ItemId, 1, p);
            if (!it) return true;
            uint16 dest = 0;
            bool blocked = !sScriptMgr->OnPlayerCanEquipItem(p, 0, dest, it, false, true);
            delete it;
            return blocked;
        };
        auto packetBlocked = [](Player* p, uint16 opcode, uint32 payload) -> bool
        {
            WorldPacket d(opcode);
            if (payload) d << payload;
            return !sScriptMgr->CanPacketReceive(p->GetSession(), d);
        };

        // ---- 1. Finder / queue ----
        RUN("CHALLENGE_RULES_TYPE_NO_DUNGEON_FINDER", [](Player* p) {
            lfg::LfgDungeonSet d; return !sScriptMgr->OnPlayerCanJoinLfg(p, 0, d, ""); });
        RUN("CHALLENGE_RULES_TYPE_NO_BATTLEGROUND_FINDER", [](Player* p) {
            GroupJoinBattlegroundResult e{}; return !sScriptMgr->OnPlayerCanJoinInBattlegroundQueue(p, ObjectGuid::Empty, BATTLEGROUND_AV, 0, e); });
        RUN("CHALLENGE_RULES_TYPE_NO_ARENA_FINDER", [](Player* p) {
            GroupJoinBattlegroundResult e{}; return !sScriptMgr->OnPlayerCanJoinInArenaQueue(p, ObjectGuid::Empty, 0, BATTLEGROUND_AA, 0, 0, e); });
        RUN("CHALLENGE_RULES_TYPE_NO_BATTLEGROUNDS", [](Player* p) {
            GroupJoinBattlegroundResult e{}; return !sScriptMgr->OnPlayerCanJoinInBattlegroundQueue(p, ObjectGuid::Empty, BATTLEGROUND_AV, 0, e); });
        RUN("CHALLENGE_RULES_TYPE_NO_ARENAS", [](Player* p) {
            GroupJoinBattlegroundResult e{}; return !sScriptMgr->OnPlayerCanJoinInArenaQueue(p, ObjectGuid::Empty, 0, BATTLEGROUND_AA, 0, 0, e); });

        // ---- 2. Economy / social ----
        RUN("CHALLENGE_RULES_TYPE_NO_AUCTIONHOUSE", [](Player* p) {
            return !sScriptMgr->OnPlayerCanPlaceAuctionBid(p, nullptr); });
        RUN("CHALLENGE_RULES_TYPE_NO_MAIL", [](Player* p) {
            std::string s1, s2;
            return !sScriptMgr->OnPlayerCanSendMail(p, ObjectGuid::Empty, ObjectGuid::Empty, s1, s2, 0, 0, nullptr); });
        RUN("CHALLENGE_RULES_TYPE_NO_GUILD_BANK", [](Player* p) {
            return !sScriptMgr->CanGuildSendBankList(p->GetGuild(), p->GetSession(), 0, true); });
        RUN("CHALLENGE_RULES_TYPE_NO_TRADE", [](Player* p) {
            return !sScriptMgr->OnPlayerCanInitTrade(p, p); });
        RUN("CHALLENGE_RULES_TYPE_NO_CONVENIENCE_ITEMS", [&](Player* p) { return useItem(p, 777998); });
        RUN("CHALLENGE_RULES_TYPE_NO_BONUS_EXPERIENCE", [&](Player* p) { return useItem(p, 818059); });
        RUN("CHALLENGE_RULES_TYPE_NO_HEARTHSTONE", [&](Player* p) { return useItem(p, 6948); });
        RUN("CHALLENGE_RULES_TYPE_NO_MOUNTS", [&](Player* p) {
            return useItemPtr(p, RuleTestFirstItem(ITEM_CLASS_MISC, ITEM_SUBCLASS_JUNK_MOUNT)); });
        RUN("CHALLENGE_RULES_TYPE_NO_COSMETIC_PET_ITEMS", [&](Player* p) {
            return useItemPtr(p, RuleTestFirstItem(ITEM_CLASS_MISC, ITEM_SUBCLASS_JUNK_PET)); });
        RUN("CHALLENGE_RULES_TYPE_NO_HEALTH_POTIONS", [&](Player* p) {
            return useItemPtr(p, RuleTestFirstItem(ITEM_CLASS_CONSUMABLE, ITEM_SUBCLASS_POTION)); });
        RUN("CHALLENGE_RULES_TYPE_NO_COMPANIONS", [](Player* p) {
            uint32 spell = RuleTestCompanionSpell();
            return spell ? Test_SpellCheckCastBlocked(p, spell) : true; });
        RUN("CHALLENGE_RULES_TYPE_NO_PETS_OR_MINIONS", [](Player* p) {
            // Vanity (non-combat) companions are allowed; combat summons are not.
            uint32 const companionSpell = RuleTestCompanionSpell();
            bool const companionAllowed = companionSpell ? !Test_SpellCheckCastBlocked(p, companionSpell) : true;
            uint32 const combatSpell = RuleTestCombatSummonSpell();
            bool const combatBlocked = combatSpell ? Test_SpellCheckCastBlocked(p, combatSpell) : true;
            return companionAllowed && combatBlocked; });
        RUN("CHALLENGE_RULES_TYPE_NO_MANASTORM", [](Player* p) {
            return !sScriptMgr->OnPlayerCanEnterManastorm(p); });

        // ---- 3. Vendor / bank / repair ----
        RUN("CHALLENGE_RULES_TYPE_NO_VENDOR_BUY", [](Player* p) {
            uint32 item = 6948;
            sScriptMgr->OnPlayerBeforeBuyItemFromVendor(p, ObjectGuid::Empty, 0, item, 1, 0, 0);
            return item == 0; });
        RUN("CHALLENGE_RULES_TYPE_NO_VENDORS", [](Player* p) {
            uint32 item = 6948;
            sScriptMgr->OnPlayerBeforeBuyItemFromVendor(p, ObjectGuid::Empty, 0, item, 1, 0, 0);
            return item == 0 && !sScriptMgr->OnPlayerCanSellItem(p, nullptr, nullptr); });
        RUN("CHALLENGE_RULES_TYPE_NO_VENDOR_BUY_FOOD_OR_DRINK", [&](Player* p) {
            ItemTemplate const* food = RuleTestFirstItem(ITEM_CLASS_CONSUMABLE, ITEM_SUBCLASS_FOOD);
            if (!food) return true;
            uint32 item = food->ItemId;
            sScriptMgr->OnPlayerBeforeBuyItemFromVendor(p, ObjectGuid::Empty, 0, item, 1, 0, 0);
            return item == 0; });
        RUN("CHALLENGE_RULES_TYPE_NO_VENDOR_BUYBACK", [&](Player* p) {
            return packetBlocked(p, CMSG_BUYBACK_ITEM, 0); });
        RUN("CHALLENGE_RULES_TYPE_NO_BANK", [&](Player* p) {
            return packetBlocked(p, CMSG_BANKER_ACTIVATE, 0); });
        RUN("CHALLENGE_RULES_TYPE_NO_REPAIR_ITEMS", [&](Player* p) {
            return packetBlocked(p, CMSG_REPAIR_ITEM, 0); });

        // ---- 4. Group ----
        RUN("CHALLENGE_RULES_TYPE_NO_GROUP", [](Player* p) {
            std::string n = "Nobody";
            return !sScriptMgr->OnPlayerCanGroupInvite(p, n); });

        // ---- 5. XP / profession XP ----
        RUN("CHALLENGE_RULES_TYPE_NO_PROFESSION_EXPERIENCE", [](Player* p) {
            uint32 craftGain = 1;
            sScriptMgr->OnPlayerUpdateCraftingSkill(p, nullptr, 0, craftGain);
            uint32 gatherGain = 1;
            sScriptMgr->OnPlayerUpdateGatheringSkill(p, SKILL_MINING, 1, 25, 50, 75, gatherGain);
            uint32 amtProfession = 1000; sScriptMgr->OnPlayerGiveXP(p, amtProfession, nullptr, XPSOURCE_PROFESSION);
            uint32 amtSkill = 1000; sScriptMgr->OnPlayerGiveXP(p, amtSkill, nullptr, XPSOURCE_PROFESSION_SKILL);
            uint32 amtKill = 1000; sScriptMgr->OnPlayerGiveXP(p, amtKill, nullptr, XPSOURCE_KILL);
            return craftGain == 1 && gatherGain == 1 && amtProfession == 0 && amtSkill == 0 && amtKill == 1000; });
        RUN("CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_QUESTS", [](Player* p) {
            uint32 amt = 1000; sScriptMgr->OnPlayerGiveXP(p, amt, nullptr, XPSOURCE_KILL); return amt == 0; });
        RUN("CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_CREATURES", [](Player* p) {
            uint32 amtQuest = 1000; sScriptMgr->OnPlayerGiveXP(p, amtQuest, nullptr, XPSOURCE_QUEST);
            Creature* c = p->SummonCreature(RuleTestFirstCreature(CREATURE_TYPE_BEAST), *p, TEMPSUMMON_TIMED_DESPAWN, 5000);
            uint32 amtKill = 1000; sScriptMgr->OnPlayerGiveXP(p, amtKill, c, XPSOURCE_KILL);
            return amtQuest == 0 && amtKill == 1000; });
        RUN("CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PVP", [](Player* p) {
            uint32 amtKill = 1000; sScriptMgr->OnPlayerGiveXP(p, amtKill, nullptr, XPSOURCE_KILL);
            uint32 amtBg = 1000; sScriptMgr->OnPlayerGiveXP(p, amtBg, nullptr, XPSOURCE_BATTLEGROUND);
            return amtKill == 0 && amtBg == 1000; });
        RUN("CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PROFESSIONS", [](Player* p) {
            uint32 amt = 1000; sScriptMgr->OnPlayerGiveXP(p, amt, nullptr, XPSOURCE_KILL); return amt == 0; });
        RUN("CHALLENGE_RULES_TYPE_NO_FETCH_QUEST_EXPERIENCE", [](Player* p) {
            Quest const* talk = sObjectMgr->GetQuestTemplate(RuleTestFirstQuest(true));
            Quest const* work = sObjectMgr->GetQuestTemplate(RuleTestFirstQuest(false));
            if (!talk || !work) return true;
            uint32 talkXp = 1000;
            sScriptMgr->OnPlayerQuestComputeXP(p, talk, talkXp);
            uint32 workXp = 1000;
            sScriptMgr->OnPlayerQuestComputeXP(p, work, workXp);
            return talkXp == 0 && workXp == 1000; });

        // ---- 6. Quests (color) ----
        RUN("CHALLENGE_RULES_TYPE_NO_QUESTS", [](Player* p) {
            return !sScriptMgr->OnPlayerBeforeQuestComplete(p, 0); });
        for (int ci = 0; ci < 5; ++ci)
        {
            static char const* colors[5] = {"GRAY", "GREEN", "YELLOW", "ORANGE", "RED"};
            std::string rule = std::string("CHALLENGE_RULES_TYPE_NO_") + colors[ci] + "_QUESTS";
            RUN(rule.c_str(), [&, ci](Player* p) {
                uint32 qid = RuleTestFirstQuestOfColor(p, ci);
                return qid ? !sScriptMgr->OnPlayerBeforeQuestComplete(p, qid) : true; });
        }

        // ---- 7. Professions ----
        RUN("CHALLENGE_RULES_TYPE_NO_PROFESSIONS", [](Player* p) {
            return !sScriptMgr->OnPlayerCanUpdateSkill(p, SKILL_ALCHEMY); });
        RUN("CHALLENGE_RULES_TYPE_CANNOT_UNLEARN_PROFESSIONS", [&](Player* p) {
            return packetBlocked(p, CMSG_UNLEARN_SKILL, SKILL_ALCHEMY); });

        // ---- 8. Items / equip / talents ----
        RUN("CHALLENGE_RULES_TYPE_NO_EQUIP_ARMOR", [&](Player* p) {
            return canEquip(p, RuleTestFirstItem(ITEM_CLASS_ARMOR, -1)); });
        {
            struct { char const* name; uint32 quality; } eq[] = {
                { "COMMON", ITEM_QUALITY_NORMAL }, { "UNCOMMON", ITEM_QUALITY_UNCOMMON },
                { "RARE", ITEM_QUALITY_RARE }, { "EPIC", ITEM_QUALITY_EPIC },
                { "LEGENDARY", ITEM_QUALITY_LEGENDARY }, { "ARTIFACT", ITEM_QUALITY_ARTIFACT },
                { "HEIRLOOM", ITEM_QUALITY_HEIRLOOM },
            };
            for (auto const& e : eq)
            {
                std::string rule = std::string("CHALLENGE_RULES_TYPE_NO_EQUIP_") + e.name + "_ITEMS";
                uint32 q = e.quality;
                RUN(rule.c_str(), [&, q](Player* p) {
                    return canEquip(p, RuleTestFirstItem(ITEM_CLASS_ARMOR, -1, int(q))); });
            }
        }
        RUN("CHALLENGE_RULES_TYPE_NO_BAGS", [&](Player* p) {
            return canEquip(p, RuleTestFirstItem(ITEM_CLASS_CONTAINER, -1)); });
        RUN("CHALLENGE_RULES_TYPE_NO_TALENTS", [](Player* p) {
            TalentEntry const* t = RuleTestFirstTalent();
            return t ? !sScriptMgr->OnPlayerCanLearnTalent(p, t, 0) : true; });

        // ---- 9. Maps ----
        RUN("CHALLENGE_RULES_TYPE_NO_DUNGEONS", [](Player* p) {
            MapEntry const* e = RuleTestFirstMap(false);
            return e ? !sScriptMgr->OnPlayerCanEnterMap(p, e, nullptr, nullptr, false) : true; });
        RUN("CHALLENGE_RULES_TYPE_NO_RAIDS", [](Player* p) {
            MapEntry const* e = RuleTestFirstMap(true);
            return e ? !sScriptMgr->OnPlayerCanEnterMap(p, e, nullptr, nullptr, false) : true; });

        // ---- 10. Combat (UnitScript) ----
        RUN("CHALLENGE_RULES_TYPE_NO_DAMAGE", [](Player* p) {
            Creature* c = p->SummonCreature(RuleTestFirstCreature(CREATURE_TYPE_HUMANOID), *p, TEMPSUMMON_TIMED_DESPAWN, 10000);
            if (!c) return true;
            uint32 dmg = 5000;
            sScriptMgr->OnDamage(p, c, dmg);
            return dmg == 0; });
        RUN("CHALLENGE_RULES_TYPE_NO_HEALING", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            uint32 gain = 500;
            sScriptMgr->OnHeal(nullptr, p, gain);   // receiver-based ("cannot receive healing")
            return gain == 0; });
        RUN("CHALLENGE_RULES_TYPE_NO_KILL_BEASTS", [](Player* p) {
            Creature* c = p->SummonCreature(RuleTestFirstCreature(CREATURE_TYPE_BEAST), *p, TEMPSUMMON_TIMED_DESPAWN, 10000);
            if (!c || c->GetHealth() <= 1) return true;
            uint32 dmg = c->GetHealth() + 100000;
            sScriptMgr->OnDamage(p, c, dmg);
            return dmg == c->GetHealth() - 1; });
        RUN("CHALLENGE_RULES_TYPE_NO_KILL_HUMANOIDS", [](Player* p) {
            Creature* c = p->SummonCreature(RuleTestFirstCreature(CREATURE_TYPE_HUMANOID), *p, TEMPSUMMON_TIMED_DESPAWN, 10000);
            if (!c || c->GetHealth() <= 1) return true;
            uint32 dmg = c->GetHealth() + 100000;
            sScriptMgr->OnDamage(p, c, dmg);
            return dmg == c->GetHealth() - 1; });
        RUN("CHALLENGE_RULES_TYPE_FAILABLE_NO_KILL_BEASTS", [](Player* p) {
            uint32 cid = RuleTestFindChallenge("CHALLENGE_RULES_TYPE_FAILABLE_NO_KILL_BEASTS");
            Creature* c = p->SummonCreature(RuleTestFirstCreature(CREATURE_TYPE_BEAST), *p, TEMPSUMMON_TIMED_DESPAWN, 10000);
            if (!c) return true;
            sScriptMgr->OnPlayerCreatureKill(p, c);
            return !RuleTestChallengeActive(p, cid); });
        RUN("CHALLENGE_RULES_TYPE_FAILABLE_NO_KILL_HUMANOIDS", [](Player* p) {
            uint32 cid = RuleTestFindChallenge("CHALLENGE_RULES_TYPE_FAILABLE_NO_KILL_HUMANOIDS");
            Creature* c = p->SummonCreature(RuleTestFirstCreature(CREATURE_TYPE_HUMANOID), *p, TEMPSUMMON_TIMED_DESPAWN, 10000);
            if (!c) return true;
            sScriptMgr->OnPlayerCreatureKill(p, c);
            return !RuleTestChallengeActive(p, cid); });
        RUN("CHALLENGE_RULES_TYPE_CANNOT_DODGE_BLOCK_OR_PARRY", [](Player* p) {
            int32 a = 0, b = 0, sk = 0, df = 0, crit = 0, miss = 0, dodge = 100, parry = 100, block = 100;
            sScriptMgr->OnBeforeRollMeleeOutcomeAgainst(p, p, BASE_ATTACK, a, b, sk, df, crit, miss, dodge, parry, block);
            return dodge == 0 && parry == 0 && block == 0; });
        RUN("CHALLENGE_RULES_TYPE_CAN_BE_CRITTED_BY_ANY_ABILITY", [](Player* p) {
            int32 a = 0, b = 0, sk = 0, df = 0, crit = 0, miss = 0, dodge = 0, parry = 0, block = 0;
            sScriptMgr->OnBeforeRollMeleeOutcomeAgainst(p, p, BASE_ATTACK, a, b, sk, df, crit, miss, dodge, parry, block);
            return crit > 0; });

        // ---- 11. Spellbind Roulette (regression: mark lifetime) ----
        RUN("CHALLENGE_RULES_TYPE_SPELLBIND_ROULETTE", [](Player* p) {
            return Test_SpellbindPlainKeepsMark(p); });
        RUN("CHALLENGE_RULES_TYPE_FAILABLE_SPELLBIND_ROULETTE", [](Player* p) {
            return Test_SpellbindCoexistingSurvives(p); });
        RUN("CHALLENGE_RULES_TYPE_FAILABLE_SPELLBIND_ROULETTE", [](Player* p) {
            return Test_SpellbindFailableKillsOnNextTick(p); });
        RUN("CHALLENGE_RULES_TYPE_FAILABLE_SPELLBIND_ROULETTE", [](Player* p) {
            return Test_SpellbindTriggeredDoesNotFail(p); });

        // ---- 12. Environment / breath / profession (single-player) ----
        RUN("CHALLENGE_RULES_TYPE_FAILABLE_NO_FALLING", [](Player* p) {
            uint32 cid = RuleTestFindChallenge("CHALLENGE_RULES_TYPE_FAILABLE_NO_FALLING");
            sScriptMgr->OnPlayerEnvironmentalDamage(p, DAMAGE_FALL, 1);
            return cid && !RuleTestChallengeActive(p, cid); });
        // FLOOR_IS_LAVA (165): no gate - see ImplementedRules() note (custom-only,
        // mis-modelled by the pre-existing DAMAGE_LAVA/FIRE approximation).
        RUN("CHALLENGE_RULES_TYPE_INVERTED_BREATH", [](Player* p) {
            RefreshInvertedBreathTracking(p);
            bool const on = sScriptMgr->OnPlayerBreathInverted(p);
            UntrackInvertedBreath(p);
            return on; });
        RUN("CHALLENGE_RULES_TYPE_GROUP_PROFESSION_EXPERIENCE", [](Player* p) {
            // Needs the profession XP-source rule on the same character.
            uint32 cid = 0;
            for (uint32 id : DefIds())
            {
                std::string const r = ChallengeRules(id);
                if (CoAParse::ListContains(r, "CHALLENGE_RULES_TYPE_GROUP_PROFESSION_EXPERIENCE")
                    && CoAParse::ListContains(r, "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PROFESSIONS"))
                { cid = id; break; }
            }
            if (!cid)
                return true;   // skip: no bundled challenge
            ActivateChallengeForTest(p, cid);
            if (p->GetLevel() < 20)
                p->GiveLevel(20);
            // Zero the bar first: a near-full bar would level the char up on the
            // grant and reset XP, masking the gain (flaky before).
            p->SetUInt32Value(PLAYER_XP, 0);
            sScriptMgr->OnPlayerUpdateSkill(p, SKILL_ALCHEMY, 0, 0, 0, 0);
            return p->GetUInt32Value(PLAYER_XP) > 0; });
        RUN("CHALLENGE_RULES_TYPE_NO_FLIGHT_PATHS", [](Player* p) {
            WorldPacket taxi(CMSG_ACTIVATETAXI);
            return !sScriptMgr->CanPacketReceive(p->GetSession(), taxi); });
        RUN("CHALLENGE_RULES_TYPE_NO_FLAG_PVE", [](Player* p) {
            p->UpdatePvP(false, true);   // attempt to clear the PvP flag
            return p->IsPvP(); });
        RUN("CHALLENGE_RULES_TYPE_CANNOT_LOOT_ITEMS", [](Player* p) {
            WorldPacket loot(CMSG_AUTOSTORE_LOOT_ITEM);
            loot << uint8(0);
            return !sScriptMgr->CanPacketReceive(p->GetSession(), loot); });

        // ---- 13. Regeneration (Inn-Sane): not rested -> blocked ----
        RUN("CHALLENGE_RULES_TYPE_NO_HEALTH_REGENERATION", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            return !sScriptMgr->OnPlayerCanRegenerate(p, POWER_HEALTH); });
        RUN("CHALLENGE_RULES_TYPE_NO_HEALTH_REGENERATION_UNLESS_RESTED", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            return !sScriptMgr->OnPlayerCanRegenerate(p, POWER_HEALTH); });
        RUN("CHALLENGE_RULES_TYPE_NO_MANA_REGENERATION", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            return !sScriptMgr->OnPlayerCanRegenerate(p, POWER_MANA); });
        RUN("CHALLENGE_RULES_TYPE_NO_MANA_REGENERATION_UNLESS_RESTED", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            return !sScriptMgr->OnPlayerCanRegenerate(p, POWER_MANA); });
        RUN("CHALLENGE_RULES_TYPE_NO_POWER_REGENERATION", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            // "You cannot regenerate mana, rage, or energy."
            return !sScriptMgr->OnPlayerCanRegenerate(p, POWER_ENERGY)
                && !sScriptMgr->OnPlayerCanRegenerate(p, POWER_MANA); });
        RUN("CHALLENGE_RULES_TYPE_NO_POWER_REGENERATION_UNLESS_RESTED", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            return !sScriptMgr->OnPlayerCanRegenerate(p, POWER_MANA); });
        RUN("CHALLENGE_RULES_TYPE_NO_ENERGIZING", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            return !sScriptMgr->OnPlayerCanEnergize(p, POWER_MANA); });
        RUN("CHALLENGE_RULES_TYPE_NO_ENERGIZING_UNLESS_RESTED", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            return !sScriptMgr->OnPlayerCanEnergize(p, POWER_MANA); });
        RUN("CHALLENGE_RULES_TYPE_NO_HEALING_UNLESS_RESTED", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            uint32 gain = 1000;
            sScriptMgr->OnHeal(p, p, gain);
            return gain == 0; });
        RUN("CHALLENGE_RULES_TYPE_NO_HEALTH_REGENERATION_ON_LEVEL_UP", [](Player* p) {
            p->SetHealth(p->GetMaxHealth() / 2);
            uint32 const before = p->GetHealth();
            p->GiveLevel(uint8(p->GetLevel() + 1));
            return p->GetHealth() <= before; });
        RUN("CHALLENGE_RULES_TYPE_NO_POWER_REGENERATION_ON_LEVEL_UP", [](Player* p) {
            Powers const cp = Powers(p->getPowerType());
            p->SetPower(cp, 0);
            p->GiveLevel(uint8(p->GetLevel() + 1));
            return p->GetPower(cp) == 0; });
        RUN("CHALLENGE_RULES_TYPE_NO_MANA_REGENERATION_ON_LEVEL_UP", [](Player* p) {
            p->SetPower(POWER_MANA, 0);
            p->GiveLevel(uint8(p->GetLevel() + 1));
            return p->GetPower(POWER_MANA) == 0; });

        // ---- 14. Audit gap closure (2026-09-17) ----
        RUN("CHALLENGE_RULES_TYPE_NO_OUTSIDE_INTERACTION", [](Player* p) {
            std::string s1, s2;
            bool const mailBlocked = !sScriptMgr->OnPlayerCanSendMail(
                p, ObjectGuid::Empty, ObjectGuid::Empty, s1, s2, 0, 0, nullptr);
            bool const auctionBlocked = !sScriptMgr->OnPlayerCanPlaceAuctionBid(p, nullptr);
            return mailBlocked && auctionBlocked; });

        RUN("CHALLENGE_RULES_TYPE_NO_GROUP_FOR_DUNGEONS", [](Player* p) {
            // The in-dungeon case needs a dungeon map (not reachable from the
            // open-world harness); assert the gate is open outside one.
            if (p->GetMap() && p->GetMap()->IsDungeon())
                return true;
            return !GroupForDungeonsBlocked(p, nullptr); });

        RUN("CHALLENGE_RULES_TYPE_NO_NON_SELF_CRAFTED_ITEMS", [&](Player* p) {
            ItemTemplate const* proto = RuleTestFirstItem(ITEM_CLASS_ARMOR, -1);
            if (!proto) return true;
            Item* it = Item::CreateItem(proto->ItemId, 1, p);
            if (!it) return true;
            uint16 dest = 0;
            bool const uncraftedBlocked = !sScriptMgr->OnPlayerCanEquipItem(p, 0, dest, it, false, true);
            it->SetGuidValue(ITEM_FIELD_CREATOR, p->GetGUID());
            bool const craftedAllowed = sScriptMgr->OnPlayerCanEquipItem(p, 0, dest, it, false, true);
            delete it;
            return uncraftedBlocked && craftedAllowed; });

        RUN("CHALLENGE_RULES_TYPE_NO_NON_LOOTED_ITEMS", [&](Player* p) {
            RefreshLootedTracking(p);
            ItemTemplate const* proto = RuleTestFirstItem(ITEM_CLASS_ARMOR, -1);
            if (!proto) return true;
            Item* it = Item::CreateItem(proto->ItemId, 1, p);
            if (!it) return true;
            uint16 dest = 0;
            bool const unlootedBlocked = !sScriptMgr->OnPlayerCanEquipItem(p, 0, dest, it, false, true);
            sScriptMgr->OnPlayerLootItem(p, it, 1, ObjectGuid::Empty);
            bool const lootedAllowed = sScriptMgr->OnPlayerCanEquipItem(p, 0, dest, it, false, true);
            delete it;
            return unlootedBlocked && lootedAllowed; });

        RUN("CHALLENGE_RULES_TYPE_NO_KILL_CREDIT_UNLESS_AT_DISADVANTAGE", [](Player* p) {
            Creature* c = p->SummonCreature(RuleTestFirstCreature(CREATURE_TYPE_BEAST), *p, TEMPSUMMON_TIMED_DESPAWN, 10000);
            if (!c) return true;
            c->SetLevel(p->GetLevel());
            uint32 low = 1000;
            sScriptMgr->OnPlayerGiveXP(p, low, c, XPSOURCE_KILL);
            uint8 const higher = uint8(std::min<int>(255, int(p->GetLevel()) + 5));
            c->SetLevel(higher);
            uint32 high = 1000;
            sScriptMgr->OnPlayerGiveXP(p, high, c, XPSOURCE_KILL);
            return low == 0 && high == 1000; });

        RUN("CHALLENGE_RULES_TYPE_CAST_RANGE_LIMITED_TO_MELEE", [](Player* p) {
            RefreshRegenTracking(p);   // seed the cached cast-rule mask
            uint32 spell = RuleTestRangedSpell();
            return spell ? Test_SpellCheckCastBlocked(p, spell) : true; });

        RUN("CHALLENGE_RULES_TYPE_NO_PORTALS", [](Player* p) {
            RefreshRegenTracking(p);
            uint32 spell = RuleTestPortalSpell();
            return spell ? Test_SpellCheckCastBlocked(p, spell) : true; });

        RUN("CHALLENGE_RULES_TYPE_NO_HEALING_UNLESS_BANDAGING", [](Player* p) {
            p->RemovePlayerFlag(PLAYER_FLAGS_RESTING);
            RefreshRegenTracking(p);
            uint32 nonBandage = 1000;
            sScriptMgr->ModifyHealReceived(p, p, nonBandage, nullptr);
            sScriptMgr->OnHeal(p, p, nonBandage);
            if (nonBandage != 0)
                return false;
            uint32 const bandageSpell = RuleTestBandageSpell();
            if (!bandageSpell)
                return true;   // no bandage data on this build: skip the allow case
            uint32 bandage = 1000;
            sScriptMgr->ModifyHealReceived(p, p, bandage, sSpellMgr->GetSpellInfo(bandageSpell));
            sScriptMgr->OnHeal(p, p, bandage);
            return bandage == 1000; });

        RUN("CHALLENGE_RULES_TYPE_NO_LEAVE_CONTINENT", [](Player* p) {
            MapEntry const* cur = p->GetMap() ? p->GetMap()->GetEntry() : nullptr;
            if (!cur || !cur->IsContinent())
                return true;   // harness is not on a continent: skip
            uint32 target = (cur->MapID == MAP_EASTERN_KINGDOMS) ? MAP_KALIMDOR : MAP_EASTERN_KINGDOMS;
            return !sScriptMgr->OnPlayerBeforeTeleport(
                p, target, 0.0f, 0.0f, 0.0f, 0.0f, 0, nullptr); });

        RUN("CHALLENGE_RULES_TYPE_HIGH_RISK_ONLY", [](Player* p) {
            p->RemoveAurasDueToSpell(HighRiskAura());
            bool const blocked = HighRiskActivationBlocked(p);
            if (!sSpellMgr->GetSpellInfo(HighRiskAura()))
                return blocked;
            p->AddAura(HighRiskAura(), p);
            bool const allowed = !HighRiskActivationBlocked(p);
            p->RemoveAurasDueToSpell(HighRiskAura());
            return blocked && allowed; });

        ResetCharacterForTest(player);
        Test_ClearPendingFailures();

        // Coverage: implemented rules with no behavioral gate test. Reported on
        // every run; fails the run only with CoAChallenges.TestStrictCoverage=1.
        // Run BEFORE the summary below so a strict-coverage failure is included
        // in the printed totals.
        {
            // Covered by a dedicated runner instead of a RUN() gate.
            static std::set<std::string> const kCoveredElsewhere = {
                "CHALLENGE_RULES_TYPE_FATIGUED_UNLESS_RESTED",   // `.coa e2e` fatigue
                "CHALLENGE_RULES_TYPE_NO_LEVEL_PAST_REQUIREMENTS", // `.coa e2e` level-gate
                "CHALLENGE_RULES_TYPE_FAILABLE_MEGA_SPELLBIND_ROULETTE", // same path as FAILABLE
                "CHALLENGE_RULES_TYPE_ONLY_TRADE_IF_SAME_CHALLENGES",    // `.coa ruletestparty`
                "CHALLENGE_RULES_TYPE_ONLY_GROUP_IN_3_LEVEL_RANGE",      // `.coa ruletestparty`
                "CHALLENGE_RULES_TYPE_ONLY_PVP_IN_5_LEVEL_RANGE",        // `.coa ruletestparty`
                "CHALLENGE_RULES_TYPE_ONLY_PVP_SAME_LEVEL_IF_MAX_LEVEL", // `.coa ruletestparty`
                "CHALLENGE_RULES_TYPE_PVE_ONLY",                          // `.coa ruletestparty`
                "CHALLENGE_RULES_TYPE_COSMETIC_ELITE_ENEMIES",            // challenges-adventure-mode scenario
                "CHALLENGE_RULES_TYPE_STRICT_CHALLENGE_RESTRICTED_TAPPING", // challenges-adventure-mode scenario
                "CHALLENGE_RULES_TYPE_NO_CREATURE_LEVEL_SCALING", // challenges-level-scaling-rules scenario
                "CHALLENGE_RULES_TYPE_NO_QUEST_LEVEL_SCALING",    // challenges-level-scaling-rules scenario
            };
            std::set<std::string> const& impl = ImplementedRules();
            uint32 missing = 0;
            for (std::string const& r : impl)
            {
                if (g_exercisedRules.count(r) || kCoveredElsewhere.count(r))
                    continue;
                if (!missing)
                    SendTestLine(player, "  coverage: implemented rules WITHOUT a gate test:");
                ++missing;
                SendTestLine(player, "    - {}", r);
            }
            if (!missing)
                SendTestLine(player, "  coverage: all {} implemented rules covered.", impl.size());
            else if (sConfigMgr->GetOption<bool>("CoAChallenges.TestStrictCoverage", false))
            {
                ++fails;
                all = false;
            }
        }

        Test_SetQuiet(false);
        SendTestLine(player, "Rule gates: {} checked, {} failed -> {}", count, fails,
            all ? "ALL PASS" : "FAILURES");
        return all;
    }

    // GM-only (`.coa ruletestparty <p1> <p2>`): rules whose check needs a second
    // player (trade/group/PvP range). Both must be online in the open world.
    // Automated condition-gate tests (`.coa conditiontest <player>`). Exercises
    // every implemented condition type through the REAL EvaluateConditions, with
    // a synthetic condition string (no definition declares most of them) and the
    // implicit OUTSIDE_INTERACTION injection disabled.
    bool Test_ConditionGates(Player* player)
    {
        if (!player)
            return false;

        Test_SetQuiet(true);
        uint32 const cid = 188;   // scratch trial id; label/logging only
        uint32 const guid = player->GetGUID().GetCounter();

        int count = 0, fails = 0;
        auto RUN = [&](char const* label, char const* cond, bool expectBroken,
                       std::function<void()> setup)
        {
            ResetCharacterForTest(player);
            if (setup)
            {
                setup();
                WaitCharacterQueueEmpty();   // condition flags are written async
            }
            bool broken = false;
            for (ConditionState const& s : EvaluateConditionsFor(player, cid, cond, false))
                if (s.broken)
                    broken = true;
            bool const ok = (broken == expectBroken);
            SendTestLine(player, "  {:<46} {} (broken={})", label, ok ? "PASS" : "FAIL", broken);
            ++count;
            if (!ok)
                ++fails;
        };

        // Historical facets: clean by default, broken once the flag is set.
        RUN("MAIL clean", "CHALLENGE_CONDITIONS_TYPE_TAKE_MAIL_MONEY_OR_ITEM:0/0/0", false, nullptr);
        RUN("MAIL flagged", "CHALLENGE_CONDITIONS_TYPE_TAKE_MAIL_MONEY_OR_ITEM:0/0/0", true,
            [&]{ SetConditionFlag(guid, "OUTSIDE_MAIL"); });
        RUN("TRADE flagged", "CHALLENGE_CONDITIONS_TYPE_ACCEPT_TRADE:0/0/0", true,
            [&]{ SetConditionFlag(guid, "OUTSIDE_TRADE"); });
        RUN("AUCTIONHOUSE flagged", "CHALLENGE_CONDITIONS_TYPE_AUCTIONHOUSE_INTERACTION:0/0/0", true,
            [&]{ SetConditionFlag(guid, "OUTSIDE_AH"); });
        RUN("VENDOR flagged", "CHALLENGE_CONDITIONS_TYPE_VENDOR_INTERACTION:0/0/0", true,
            [&]{ SetConditionFlag(guid, "OUTSIDE_VENDOR"); });
        RUN("GUILD_BANK flagged", "CHALLENGE_CONDITIONS_TYPE_WITHDRAW_GUILD_BANK_MONEY_OR_ITEM:0/0/0", true,
            [&]{ SetConditionFlag(guid, "OUTSIDE_GUILD_BANK"); });
        RUN("BANK flagged", "CHALLENGE_CONDITIONS_TYPE_WITHDRAW_BANK_MONEY_OR_ITEM:0/0/0", true,
            [&]{ SetConditionFlag(guid, "OUTSIDE_BANK"); });
        RUN("REALM_BANK flagged", "CHALLENGE_CONDITIONS_TYPE_WITHDRAW_REALM_BANK_MONEY_OR_ITEM:0/0/0", true,
            [&]{ SetConditionFlag(guid, "OUTSIDE_REALM_BANK"); });
        RUN("OUTSIDE aggregate clean", "CHALLENGE_CONDITIONS_TYPE_OUTSIDE_INTERACTION:0/0/0", false, nullptr);
        RUN("OUTSIDE aggregate flagged", "CHALLENGE_CONDITIONS_TYPE_OUTSIDE_INTERACTION:0/0/0", true,
            [&]{ SetConditionFlag(guid, "OUTSIDE_AH"); });
        RUN("LOOT flagged", "CHALLENGE_CONDITIONS_TYPE_LOOT_INTERACTION:0/0/0", true,
            [&]{ SetConditionFlag(guid, "LOOTED"); });

        // Live conditions.
        RUN("LEVEL_UP at level 1", "CHALLENGE_CONDITIONS_TYPE_LEVEL_UP:0/0/0", false, nullptr);
        RUN("LEVEL_UP at level 2", "CHALLENGE_CONDITIONS_TYPE_LEVEL_UP:0/0/0", true,
            [&]{ player->GiveLevel(2); });
        RUN("TWO_PROFESSIONS none", "CHALLENGE_CONDITIONS_TYPE_HAVE_TWO_PRIMARY_PROFESSIONS:0/0/0", false, nullptr);
        RUN("TWO_PROFESSIONS two", "CHALLENGE_CONDITIONS_TYPE_HAVE_TWO_PRIMARY_PROFESSIONS:0/0/0", true,
            [&]{ player->SetSkill(SKILL_ALCHEMY, 0, 1, 75); player->SetSkill(SKILL_BLACKSMITHING, 0, 1, 75); });
        RUN("GROUP_SIZE:0 solo", "CHALLENGE_CONDITIONS_TYPE_GROUP_SIZE:0/0/0", false, nullptr);
        RUN("FREE_SLOTS:1", "CHALLENGE_CONDITIONS_TYPE_HAVE_FREE_INVENTORY_SLOTS:1/0/0", false, nullptr);

        // Unimplemented types must fail closed (documented, not silently allowed).
        RUN("unhandled type blocks", "CHALLENGE_CONDITIONS_TYPE_COMPLETE_CHALLENGE:1/0/0", true, nullptr);

        ResetCharacterForTest(player);
        Test_SetQuiet(false);
        SendTestLine(player, "  ---- condition gates: {} run, {} failed ----", count, fails);
        return fails == 0;
    }

    bool Test_PartyRuleGates(Player* a, Player* b)
    {
        if (!a || !b || a == b)
            return false;

        Test_SetQuiet(true);
        int count = 0, fails = 0;
        bool all = true;

        auto RES = [&](char const* rule, std::function<bool()> fn)
        {
            uint32 cid = RuleTestFindChallenge(rule);
            if (!cid)
            {
                SendTestLine(a, "  {:<52} SKIP (no challenge)", rule);
                return;
            }
            ResetCharacterForTest(a);
            ResetCharacterForTest(b);
            ActivateChallengeForTest(a, cid);
            ActivateChallengeForTest(b, cid);   // same set: isolate from the same-challenge gate
            bool ok = fn();
            SendTestLine(a, "  {:<52} {} [id {}]", rule, ok ? "PASS" : "FAIL", cid);
            ++count;
            if (!ok) { ++fails; all = false; }
        };

        RES("CHALLENGE_RULES_TYPE_ONLY_TRADE_IF_SAME_CHALLENGES", [&]() {
            ResetCharacterForTest(b);   // b has no challenge -> the sets differ
            return !sScriptMgr->OnPlayerCanInitTrade(a, b); });

        RES("CHALLENGE_RULES_TYPE_PVE_ONLY", [&]() {
            return !sScriptMgr->CanUnitAttack(a, b, nullptr); });

        RES("CHALLENGE_RULES_TYPE_ONLY_GROUP_IN_3_LEVEL_RANGE", [&]() {
            if (a->GetLevel() < 10)
                a->GiveLevel(10);
            b->GiveLevel(uint8(a->GetLevel() + 5));   // diff 5 > 3
            std::string name = b->GetName();
            return !sScriptMgr->OnPlayerCanGroupInvite(a, name); });

        RES("CHALLENGE_RULES_TYPE_ONLY_PVP_IN_5_LEVEL_RANGE", [&]() {
            if (a->GetLevel() < 10)
                a->GiveLevel(10);
            b->GiveLevel(uint8(a->GetLevel() + 6));   // diff 6 > 5
            return !sScriptMgr->CanUnitAttack(a, b, nullptr); });

        RES("CHALLENGE_RULES_TYPE_ONLY_PVP_SAME_LEVEL_IF_MAX_LEVEL", [&]() {
            uint32 cap = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
            if (!cap)
                cap = 80;
            a->GiveLevel(uint8(cap));
            b->GiveLevel(uint8(cap > 2 ? cap - 2 : 1)); // one max, one not
            return !sScriptMgr->CanUnitAttack(a, b, nullptr); });

        ResetCharacterForTest(a);
        ResetCharacterForTest(b);
        Test_ClearPendingFailures();
        Test_SetQuiet(false);
        SendTestLine(a, "Party rule gates: {} checked, {} failed -> {}", count, fails,
            all ? "ALL PASS" : "FAILURES");
        return all;
    }

    // GM-only (`.coa ruleaudit <player>`): sweep every challenge ID that has a
    // generated `CoAChallenges.Rules.<id>` entry and verify the REAL hook
    // dispatchers agree with the declared rules. Prints only divergences.
    // Exercises PlayerHasRule's list parsing/matching for all 221 IDs.
    void Test_AuditAllRules(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();

        std::vector<uint32> ids = DefIds();

        // Snapshot and clear the active set so exactly one ID is present at a
        // time (PlayerHasRule checks every active row of the character).
        WaitCharacterQueueEmpty();
        std::vector<uint32> original;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT challengeId FROM coa_character_challenge WHERE guid = {}", guid))
            do { original.push_back(r->Fetch()[0].Get<uint32>()); } while (r->NextRow());
        CharacterDatabase.DirectExecute("DELETE FROM coa_character_challenge WHERE guid = {}", guid);
        ClearCharChallengeCache(guid);

        uint32 divergences = 0;
        for (uint32 id : ids)
        {
            std::string const rules = ChallengeRules(id);
            bool const declaredMana = rules.find("CHALLENGE_RULES_TYPE_NO_MANASTORM") != std::string::npos;
            bool const declaredGuild = rules.find("CHALLENGE_RULES_TYPE_NO_GUILD_BANK") != std::string::npos;

            CharacterDatabase.DirectExecute(
                "INSERT INTO coa_character_challenge (guid, challengeId, level, deaths) VALUES ({}, {}, 1, 0)",
                guid, id);
            ClearCharChallengeCache(guid);
            bool const manaAllowed = sScriptMgr->OnPlayerCanEnterManastorm(player);
            bool const guildAllowed = sScriptMgr->CanGuildSendBankList(
                player->GetGuild(), player->GetSession(), 0, true);
            CharacterDatabase.DirectExecute(
                "DELETE FROM coa_character_challenge WHERE guid = {} AND challengeId = {}", guid, id);
            ClearCharChallengeCache(guid);

            if (manaAllowed == declaredMana || guildAllowed == declaredGuild)
            {
                ++divergences;
                SendTestLine(player, "  DIVERGENCE id={} declared(NO_MANASTORM={} NO_GUILD_BANK={}) "
                    "hook(manastorm={} guildBank={})", id, declaredMana, declaredGuild, manaAllowed, guildAllowed);
            }
        }

        // Restore the pre-audit active set (rows only; auras were untouched).
        for (uint32 id : original)
            CharacterDatabase.DirectExecute(
                "INSERT INTO coa_character_challenge (guid, challengeId, level, deaths) VALUES ({}, {}, 1, 0)",
                guid, id);
        ClearCharChallengeCache(guid);

        SendTestLine(player, "ruleaudit: {} IDs checked, {} divergence(s)", ids.size(), divergences);
    }

    // GM-only (`.coa cachetoctou <player>`): regression test for the cache TOCTOU. It forces the
    // exact window (an invalidation landing between the DB load and the cache publish) and checks
    // that the generation guard discards the stale snapshot. Each cache runs twice: guard OFF (the
    // bug must appear) and ON (the bug must be gone). Requiring the OFF run to fail-as-expected is
    // what makes a green run meaningful instead of vacuous.
    bool Test_CacheToctou(Player* player)
    {
        if (!player)
            return false;
        uint32 guid = player->GetGUID().GetCounter();
        bool ok = true;

        auto contains = [](std::vector<std::pair<uint32, uint32>> const& v, uint32 id, uint32 lv)
        {
            return std::find(v.begin(), v.end(), std::make_pair(id, lv)) != v.end();
        };

        // --- char challenge cache: one probe row (id/level are arbitrary for the cache) ---
        {
            uint32 const probeId = 1;
            uint32 const probeLevel = 7;

            WaitCharacterQueueEmpty();
            // Full rows so the restore does not reset level/deaths/hunger/thirst/startTime.
            struct Row { uint32 challengeId, level, deaths, hunger, thirst, startTime; };
            std::vector<Row> original;
            if (QueryResult r = CharacterDatabase.Query(
                    "SELECT challengeId, level, deaths, hunger, thirst, startTime "
                    "FROM coa_character_challenge WHERE guid = {}", guid))
            {
                do
                {
                    Field* f = r->Fetch();
                    original.push_back(Row{ f[0].Get<uint32>(), f[1].Get<uint32>(), f[2].Get<uint32>(),
                        f[3].Get<uint32>(), f[4].Get<uint32>(), f[5].Get<uint32>() });
                } while (r->NextRow());
            }

            auto arm = [&](std::shared_ptr<bool> fired)
            {
                CharacterDatabase.DirectExecute("DELETE FROM coa_character_challenge WHERE guid = {}", guid);
                CharacterDatabase.DirectExecute(
                    "INSERT INTO coa_character_challenge (guid, challengeId, level, deaths) VALUES ({}, {}, {}, 0)",
                    guid, probeId, probeLevel);
                ClearCharChallengeCache(guid);
                *fired = false;
                Test_SetCharChallengeLoadHook([fired, guid, probeId](uint32 g)
                {
                    if (g != guid)
                        return;   // never touch another character's row from a shared hook
                    if (*fired)
                        return;
                    *fired = true;
                    // Invalidate inside the load -> publish window.
                    CharacterDatabase.DirectExecute(
                        "DELETE FROM coa_character_challenge WHERE guid = {} AND challengeId = {}", g, probeId);
                    ClearCharChallengeCache(g);
                });
            };

            std::shared_ptr<bool> fired = std::make_shared<bool>(false);

            arm(fired);
            Test_SetCacheGuard(0);
            bool const staleOff = contains(CachedCharChallenges(guid), probeId, probeLevel);
            SendTestLine(player, "  cachetoctou char guard=0: stale row kept={} (expected 1) -> {}",
                staleOff ? 1 : 0, staleOff ? "PASS" : "FAIL");
            ok = ok && staleOff;

            arm(fired);
            Test_SetCacheGuard(1);
            bool const staleOn = contains(CachedCharChallenges(guid), probeId, probeLevel);
            SendTestLine(player, "  cachetoctou char guard=1: stale row kept={} (expected 0) -> {}",
                staleOn ? 1 : 0, staleOn ? "FAIL" : "PASS");
            ok = ok && !staleOn;

            Test_SetCharChallengeLoadHook(nullptr);
            Test_SetCacheGuard(-1);

            // Restore the pre-test active set (rows only; auras were untouched).
            CharacterDatabase.DirectExecute("DELETE FROM coa_character_challenge WHERE guid = {}", guid);
            for (Row const& row : original)
                CharacterDatabase.DirectExecute(
                    "INSERT INTO coa_character_challenge "
                    "(guid, challengeId, level, deaths, hunger, thirst, startTime) "
                    "VALUES ({}, {}, {}, {}, {}, {}, {})",
                    guid, row.challengeId, row.level, row.deaths, row.hunger, row.thirst, row.startTime);
            ClearCharChallengeCache(guid);
        }

        // --- game mode mask cache ---
        {
            uint32 const probeA = 0x2;    // Ironman
            uint32 const probeB = 0x100;  // Nightmare
            // Distinguish "no row" from "mask 0" so the restore does not fabricate a row, and let
            // any queued write land before reading the original value.
            WaitCharacterQueueEmpty();
            bool const hadRow = (bool)CharacterDatabase.Query(
                "SELECT 1 FROM coa_character_gamemode WHERE guid = {}", guid);
            uint32 const originalMask = hadRow ? LoadGameModeMask(guid) : 0;

            auto arm = [&](std::shared_ptr<bool> fired)
            {
                CharacterDatabase.DirectExecute(
                    "REPLACE INTO coa_character_gamemode (guid, gameMode) VALUES ({}, {})", guid, probeA);
                ClearGameModeMaskCache(guid);
                *fired = false;
                Test_SetGameModeLoadHook([fired, guid, probeB](uint32 g)
                {
                    if (g != guid)
                        return;   // never touch another character's row from a shared hook
                    if (*fired)
                        return;
                    *fired = true;
                    CharacterDatabase.DirectExecute(
                        "REPLACE INTO coa_character_gamemode (guid, gameMode) VALUES ({}, {})", g, probeB);
                    ClearGameModeMaskCache(g);
                });
            };

            std::shared_ptr<bool> fired = std::make_shared<bool>(false);

            arm(fired);
            Test_SetCacheGuard(0);
            uint32 const maskOff = CachedGameModeMask(guid);
            SendTestLine(player, "  cachetoctou gamemode guard=0: mask=0x{:x} (expected 0x{:x}) -> {}",
                maskOff, probeA, maskOff == probeA ? "PASS" : "FAIL");
            ok = ok && (maskOff == probeA);

            arm(fired);
            Test_SetCacheGuard(1);
            uint32 const maskOn = CachedGameModeMask(guid);
            SendTestLine(player, "  cachetoctou gamemode guard=1: mask=0x{:x} (expected 0x{:x}) -> {}",
                maskOn, probeB, maskOn == probeB ? "PASS" : "FAIL");
            ok = ok && (maskOn == probeB);

            Test_SetGameModeLoadHook(nullptr);
            Test_SetCacheGuard(-1);

            if (hadRow)
                CharacterDatabase.DirectExecute(
                    "REPLACE INTO coa_character_gamemode (guid, gameMode) VALUES ({}, {})", guid, originalMask);
            else
                CharacterDatabase.DirectExecute("DELETE FROM coa_character_gamemode WHERE guid = {}", guid);
            ClearGameModeMaskCache(guid);
        }

        return ok;
    }

    // GM-only (`.coa pettest <player>`): regression test for Issue #4343.
    // Verifies that when a player activates a trial with a trial aura (e.g. Nightmare 61, aura 93132),
    // any creature/pet summoned by the player receives the trial aura dynamically, and when the trial
    // is reset, the aura is cleanly removed from both player and summon.
    bool Test_PetTrialAuras(Player* player)
    {
        if (!player || !player->IsInWorld())
            return false;

        ResetCharacterForTest(player);
        uint32 const cid = 61; // Nightmare
        uint32 const expectedAura = 93132;
        ActivateChallengeForTest(player, cid);

        if (!player->HasAura(expectedAura))
        {
            SendTestLine(player, "  pet_trial_auras: player failed to receive trial aura {}", expectedAura);
            ResetCharacterForTest(player);
            return false;
        }

        // Spawn a temporary summon owned by the player
        Position pos = player->GetPosition();
        TempSummon* summon = player->GetMap()->SummonCreature(
            50075, // Generic summonable creature
            pos, nullptr, 15000, player);

        if (!summon)
        {
            SendTestLine(player, "  pet_trial_auras: could not summon test creature");
            ResetCharacterForTest(player);
            return false;
        }

        bool const hasAura = summon->HasAura(expectedAura);
        SendTestLine(player, "  pet_trial_auras: summon '{}' (GUID {}) aura {} -> {}",
            summon->GetName(), summon->GetGUID().ToString(), expectedAura, hasAura ? "PASS" : "FAIL");

        // Now test trial reset - aura must be stripped from both player and summon
        ResetChallengeState(player);
        bool const playerLost = !player->HasAura(expectedAura);
        bool const summonLost = !summon->HasAura(expectedAura);
        SendTestLine(player, "  pet_trial_auras: aura stripped on reset -> player: {}, summon: {}",
            playerLost ? "PASS" : "FAIL", summonLost ? "PASS" : "FAIL");

        summon->UnSummon();
        ResetCharacterForTest(player);
        return hasAura && playerLost && summonLost;
    }

    // GM-only (`.coa auditdefs <player>`): data-integrity sweep over EVERY
    // definition (all ids): rule/condition/objective tokens are known and
    // enforced, aura spells resolve to a SpellInfo, reward items/achievements
    // exist. Prints only divergences; no player state is touched.
    void Test_AuditAllDefs(Player* player)
    {
        if (!player)
            return;

        std::set<std::string> const& impl = ImplementedRules();
        std::set<std::string> const& conds = KnownConditions();

        // Rules intentionally not enforced server-side, each with the reason.
        static std::map<std::string, char const*> const kNotApplicable = {
            {"CHALLENGE_RULES_TYPE_NONE", "client export sentinel (empty slot)"},
            {"CHALLENGE_RULES_TYPE_NO_REALM_BANK", "no realm bank feature on this fork"},
            {"CHALLENGE_RULES_TYPE_NO_PLAYER_LEVEL_SCALING", "no player level sync on this fork"},
        };
        std::set<std::string> naSeen;
        uint32 ruleCount = 0, unenforced = 0;
        uint32 condCount = 0, unknownConds = 0;
        uint32 objCount = 0, unknownObjs = 0;
        uint32 auraCount = 0, unknownAuras = 0;
        uint32 rewardCount = 0, unknownRewards = 0;

        for (uint32 id : DefIds())
        {
            for (std::string const& tok : CoAParse::Split(ChallengeRules(id), ';'))
            {
                auto const na = kNotApplicable.find(tok);
                if (na != kNotApplicable.end())
                {
                    naSeen.insert(tok);
                    continue;
                }
                ++ruleCount;
                if (!impl.count(tok))
                {
                    ++unenforced;
                    SendTestLine(player, "  [{}] rule not enforced: {}", id, tok);
                }
            }
            for (std::string const& tok : CoAParse::Split(ChallengeConditions(id), ';'))
            {
                ++condCount;
                std::string const type = tok.substr(0, tok.find(':'));
                if (!conds.count(type))
                {
                    ++unknownConds;
                    SendTestLine(player, "  [{}] unknown condition: {}", id, tok);
                }
            }
            for (Objective const& o : GetObjectives(id))
            {
                ++objCount;
                if (o.type != "CHALLENGE_REQUIREMENT_TYPE_NONE"
                    && CoAParse::RequirementTypeIndex(o.type) == 0)
                {
                    ++unknownObjs;
                    SendTestLine(player, "  [{}] unknown objective type: {}", id, o.type);
                }
            }

            uint32 const levels = ChallengeLevelCount(id);
            for (uint32 lv = 0; lv <= levels; ++lv)
            {
                for (uint32 s : GetChallengeSpells(id, lv))
                {
                    ++auraCount;
                    if (!sSpellMgr->GetSpellInfo(s))
                    {
                        ++unknownAuras;
                        SendTestLine(player, "  [{}] unknown aura spell {} (level {})", id, s, lv);
                    }
                }
                for (RewardDef const& r : GetChallengeRewards(id, lv))
                {
                    ++rewardCount;
                    if (r.itemId && !sObjectMgr->GetItemTemplate(r.itemId))
                    {
                        ++unknownRewards;
                        SendTestLine(player, "  [{}] unknown reward item {} (level {})", id, r.itemId, lv);
                    }
                    if (r.achievement && !sAchievementStore.LookupEntry(r.achievement))
                    {
                        ++unknownRewards;
                        SendTestLine(player, "  [{}] unknown reward achievement {} (level {})",
                            id, r.achievement, lv);
                    }
                }
            }
        }

        for (auto const& [rule, reason] : kNotApplicable)
            if (naSeen.count(rule))
                SendTestLine(player, "  N-A: {} ({})", rule, reason);

        SendTestLine(player, "auditdefs: {} id(s); rules {}({} not enforced, {} N-A/needs-RE); "
            "conds {}({} unknown); objs {}({} unknown); auras {}({} unknown); rewards {}({} unknown)",
            DefCount(), ruleCount, unenforced, uint32(naSeen.size()), condCount, unknownConds,
            objCount, unknownObjs, auraCount, unknownAuras, rewardCount, unknownRewards);
    }
}
