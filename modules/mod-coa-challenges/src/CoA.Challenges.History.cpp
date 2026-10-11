// mod-coa-challenges (review split): CoA.Challenges.History.cpp
// Mechanical split of review-CoAChallenges.cpp; no logic changes.
#include "CoA.Challenges.Review.h"

namespace CoAChallenges
{

    void SendActiveList(Player* player)
    {
        if (!player->GetSession())
            return;
        SendActiveList(player, LoadActiveChallengeRows(player->GetGUID().GetCounter()));
    }

    void SendActiveList(Player* player, std::vector<ActiveChallengeRow> const& rows)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        WorldPacket data(SMSG_COA_CHALLENGE_ACTIVE_LIST, 64);
        data << uint32(rows.size());
        for (ActiveChallengeRow const& row : rows)
        {
            data << uint32(0);
            data << uint32(row.challengeId);
            data << uint32(row.level);
            data << uint32(1);
            data << uint32(0);
            data << uint32(0);
            data << uint16(0);
        }

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x596 ACTIVE_LIST to {}",
            player->GetName());
    }

    // ---- Group challenge sync (SMSG 0x59B / CMSG 0x59C) ------------------
    //
    // Client side (Extensions.dll +0x137DB0, 2026-09-15): 0x59B = u32 timeoutMs,
    // u32 count, count x {u32 challengeID, u32 level}. The pairs go into the
    // "pending" vector (GetPendingChallenges) and CHALLENGE_SYNC_REQUEST is
    // fired with the timeout. UIParent shows CHALLENGES_SYNC while the list is
    // non-empty, else CHALLENGES_SYNC_REMOVE. The answer (sender +0x142F90) is
    // CMSG 0x59C = a single u8 (SendChallengeSyncResponse) with no ids, so the
    // request that is being answered stays here until it is applied.
    //
    // Two kinds of request:
    //   - invitation (plain challenge): decline = the member simply doesn't join.
    //   - formation  (party-required: Duo/Trio/GroupSize>=2): decline reverts the
    //     requester's activation for the whole party, so the group goes back to
    //     its previous set (nobody is kicked, nobody fails).
    bool ChallengeRequiresParty(uint32 challengeID)
    {
        for (Objective const& o : GetObjectives(challengeID))
            if (o.type == "CHALLENGE_REQUIREMENT_TYPE_DUO"
                || o.type == "CHALLENGE_REQUIREMENT_TYPE_TRIO")
                return true;

        std::string const conds = ChallengeConditions(challengeID);
        for (std::string const& tok : CoAParse::Split(conds, ';'))
        {
            size_t c = tok.find(':');
            if (c == std::string::npos)
                continue;
            if (tok.substr(0, c) == "CHALLENGE_CONDITIONS_TYPE_GROUP_SIZE"
                && CoAParse::ToU32(tok.substr(c + 1)) >= 2)
                return true;
        }
        return false;
    }

    void SendSyncRequest(Player* player, uint32 timeoutMs, bool remove,
        std::vector<std::pair<uint32, uint32>> const& pairs, uint32 requesterGuid,
        bool rollbackOnDecline, std::vector<std::pair<uint32, uint32>> const& rollback)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        WorldPacket data(SMSG_COA_CHALLENGE_SYNC_REQUEST, 8 + pairs.size() * 8);
        data << uint32(timeoutMs);
        data << uint32(remove ? 0 : pairs.size());
        if (!remove)
            for (auto const& [id, level] : pairs)
            {
                data << uint32(id);
                data << uint32(level);
            }
        session->SendPacket(&data);

        {
            std::lock_guard<std::mutex> lock(PendingSyncMutex);
            PendingSync& pending = PendingSyncByGuid[player->GetGUID().GetCounter()];
            pending.requesterGuid = requesterGuid;
            pending.remove = remove;
            pending.rollbackOnDecline = rollbackOnDecline;
            pending.pairs = pairs;
            pending.rollback = rollback;
        }

        LOG_INFO("module.coa_challenges", "Sent SMSG 0x59B SYNC_REQUEST to {}: {} {} challenge(s) from {}",
            player->GetName(), remove ? "remove" : "add", pairs.size(), requesterGuid);
    }

    // Send a sync request to the player's OTHER group members. Policy (config
    // CoAChallenges.SyncChallengesWithGroup, on by default): members are
    // invited to opt into the activator's set instead of being kicked by
    // EnforceGroupOnActivation. For a removal request the wire carries 0 pairs
    // (the client then shows CHALLENGES_SYNC_REMOVE); the ids travel only in
    // PendingSyncByGuid.
    void SendChallengeSyncToGroup(Player* actor, uint32 timeoutMs, bool remove,
        std::vector<std::pair<uint32, uint32>> const& pairs, bool rollbackOnDecline,
        std::vector<std::pair<uint32, uint32>> const& rollback)
    {
        Group* group = actor->GetGroup();
        if (!group)
            return;
        uint32 const requester = actor->GetGUID().GetCounter();
        for (Group::MemberSlot const& slot : group->GetMemberSlots())
        {
            if (slot.guid == actor->GetGUID())
                continue;
            if (Player* member = ObjectAccessor::FindPlayer(slot.guid))
                SendSyncRequest(member, timeoutMs, remove, pairs, requester, rollbackOnDecline, rollback);
        }
    }

    void BroadcastChallengeSync(Player* player, uint32 challengeID, uint32 level, bool remove)
    {
        if (!player || g_suppressSyncBroadcast)
            return;
        if (!sConfigMgr->GetOption<bool>("CoAChallenges.SyncChallengesWithGroup", true))
            return;
        if (!player->GetGroup())
            return;

        std::vector<std::pair<uint32, uint32>> pairs;
        if (remove)
        {
            pairs.emplace_back(challengeID, level);
        }
        else
        {
            uint32 guid = player->GetGUID().GetCounter();
            for (uint32 cid : ActiveChallenges(guid))
                pairs.emplace_back(cid, ActiveChallengeLevel(guid, cid));
            if (pairs.empty())
                pairs.emplace_back(challengeID, level);
        }

        bool const rollbackOnDecline = !remove && ChallengeRequiresParty(challengeID);
        std::vector<std::pair<uint32, uint32>> rollback;
        if (rollbackOnDecline)
            rollback.emplace_back(challengeID, level);

        SendChallengeSyncToGroup(player, 60000, remove, pairs, rollbackOnDecline, rollback);
    }

    // CMSG 0x59C: u8 accept. Apply the remembered request (or drop/revert it).
    void HandleSyncResponse(Player* player, WorldPacket const& packet)
    {
        if (!player || packet.size() < 1)
            return;

        bool accept = packet.read<uint8>(0) != 0;
        uint32 guid = player->GetGUID().GetCounter();

        PendingSync pending;
        {
            std::lock_guard<std::mutex> lock(PendingSyncMutex);
            auto it = PendingSyncByGuid.find(guid);
            if (it == PendingSyncByGuid.end())
            {
                LOG_INFO("module.coa_challenges", "CMSG 0x59C SYNC_RESPONSE from {}: no outstanding request",
                    player->GetName());
                return;
            }
            pending = it->second;
            PendingSyncByGuid.erase(it);
        }

        if (accept)
        {
            g_suppressSyncBroadcast = true;
            for (auto const& [id, level] : pending.pairs)
            {
                if (pending.remove)
                    DeactivateChallenge(player, id);
                else
                    ActivateChallenge(player, id, level);
            }
            g_suppressSyncBroadcast = false;

            LOG_INFO("module.coa_challenges", "CMSG 0x59C SYNC_RESPONSE from {}: accepted {} {} challenge(s)",
                player->GetName(), pending.remove ? "remove" : "add", pending.pairs.size());
            return;
        }

        LOG_INFO("module.coa_challenges", "CMSG 0x59C SYNC_RESPONSE from {}: declined", player->GetName());
        if (!pending.rollbackOnDecline || pending.rollback.empty())
            return; // plain invitation: nothing to undo

        // Party-required formation declined: revert the requester's activation
        // everywhere in the party so everyone is back to the previous set.
        auto revert = [&](Player* p)
        {
            if (!p)
                return;
            std::set<uint32> active = ActiveChallenges(p->GetGUID().GetCounter());
            for (auto const& [id, level] : pending.rollback)
                if (active.count(id))
                    DeactivateChallenge(p, id);
        };

        g_suppressSyncBroadcast = true;
        if (pending.requesterGuid)
            revert(ObjectAccessor::FindPlayer(ObjectGuid::Create<HighGuid::Player>(pending.requesterGuid)));
        if (Group* group = player->GetGroup())
            for (Group::MemberSlot const& slot : group->GetMemberSlots())
                revert(ObjectAccessor::FindPlayer(slot.guid));
        revert(player);
        g_suppressSyncBroadcast = false;

        LOG_INFO("module.coa_challenges", "Declined sync reverted {} challenge(s) for requester {}",
            pending.rollback.size(), pending.requesterGuid);
    }

    void PushLoginState(Player* player)
    {
        std::vector<ActiveChallengeRow> const active = TakeLoginChallengeRows(player->GetGUID().GetCounter());

        SendActiveList(player, active);
        SendCriteriaState(player);
        uint32 const guid = player->GetGUID().GetCounter();
        uint32 const maskBefore = CachedGameModeMask(guid);
        RecomputeRequiredGameModes(player, active);
        // The client forgets the mask on the character screen; the recompute only sends it when it changed.
        if (uint32 const mask = CachedGameModeMask(guid); mask && mask == maskBefore)
            SendGameModeState(player, mask);
        ReapplyGameModeBehavior(player);
        if (sConfigMgr->GetOption<bool>("CoAChallenges.SendFailureList", true))
            SendFailureList(player);
        if (sConfigMgr->GetOption<bool>("CoAChallenges.SendCompletedList", true))
            SendCompletedList(player);

        // Load the in-memory counters and push the meter stacks first, then
        // re-apply the challenge aura last so its icon keeps the same slot.
        // (Auras don't reliably survive relog; the DB is the source of truth.)
        RefreshHungerTracking(player, active);
        RefreshFatigueTracking(player, active);
        RefreshSpellbindTracking(player);
        RefreshInvertedBreathTracking(player);
        RefreshRegenTracking(player);
        RefreshHighRiskTracking(player);
        RefreshLevelScalingTracking(player);
        RefreshLootedTracking(player);
        SyncMeterAuras(player);
        ReapplyActiveSpells(player, active);
        // Drop challenge auras with no backing active challenge (self-heal for
        // an orphan left by a row deleted out-of-band).
        StripOrphanChallengeAuras(player);

        // Safety: no hunger active -> no meter icons lingering.
        if (std::none_of(active.begin(), active.end(),
                [](ActiveChallengeRow const& row) { return IsHungerChallenge(row.challengeId); }))
            RemoveMeterAuras(player);

        // A character that logs in already at the cap with an active challenge
        // (or one activated at the cap) completes it here.
        CompleteAtLevelCap(player);
    }

    void AppendFailureString(WorldPacket& data, std::string const& s)
    {
        data << uint32(s.size());
        if (!s.empty())
            data.append(reinterpret_cast<uint8 const*>(s.data()), s.size());
    }

    // One failure record (see header comment for layout). Only id/level
    // carry meaning in v1; strings carry the player name first, rest empty.
    void AppendFailureRecord(WorldPacket& data, std::string const& who, uint32 challengeID, uint32 level)
    {
        AppendFailureString(data, who);
        data << uint32(challengeID);
        data << uint32(level);
        data << uint32(0);
        data << uint32(0);
        data << uint32(0);
        data << uint32(0);
        data << uint32(0);
        data << uint8(0);
        data << uint8(0);
        data << uint32(0);
        data << uint8(0);
        data << uint32(0);
        data << uint32(0);
        data << float(0);
        data << float(0);
        data << float(0);
        for (int i = 0; i < 6; ++i)
            AppendFailureString(data, "");
        data << uint32(0);
        data << uint32(0);
        data << uint32(0);
        data << uint32(0);
    }

    void SendFailureAdded(Player* player, uint32 challengeID, uint32 level)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        WorldPacket data(SMSG_COA_CHALLENGE_FAILURE_ADDED, 128);
        AppendFailureRecord(data, player->GetName(), challengeID, level);
        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x5A3 FAILURE_ADDED to {}: challengeID={} level={}",
            player->GetName(), challengeID, level);
    }

    void SendFailureList(Player* player)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT challengeId, level FROM coa_challenge_failure WHERE guid = {}", guid);

        WorldPacket data(SMSG_COA_CHALLENGE_FAILURE_LIST, 128);
        if (!result)
        {
            data << uint32(0);
        }
        else
        {
            data << uint32(result->GetRowCount());
            do
            {
                Field* f = result->Fetch();
                AppendFailureRecord(data, player->GetName(), f[0].Get<uint32>(), f[1].Get<uint32>());
            } while (result->NextRow());
        }

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x5A2 FAILURE_LIST to {}",
            player->GetName());
    }

    // One leaderboard completion entry (shared by 0x5C7 list and 0x5C8 added).
    // Decoded from Extensions.dll parser 0x13EFD0 / converter 0x13BF30
    // (stride 0x78):
    //   u32 Challenge, u32 Level, str PlayerName, u32 StartLo, u32 StartHi,
    //   u32 CompleteLo, u32 CompleteHi, str Race, str Gender, str Class.
    void AppendCompletionEntry(WorldPacket& data, uint32 challengeID, uint32 level,
        std::string const& name, std::string const& race, std::string const& gender,
        std::string const& klass, uint32 startTime, uint32 completeTime)
    {
        data << uint32(challengeID);
        data << uint32(level);
        AppendConfigString(data, name);
        data << startTime << uint32(0);
        data << completeTime << uint32(0);
        AppendConfigString(data, race);
        AppendConfigString(data, gender);
        AppendConfigString(data, klass);
    }

    // SMSG 0x5C7 CHALLENGE_COMPLETION_LIST_CHANGED (response to CMSG 0x5C6).
    // Client handler 0x1376B0 + parser 0x13EFD0 + converter 0x13BF30 (0x78
    // stride). Layout:
    //   u32 challengeID, u32 level, u32 count, count x entry (0x78).
    // Real leaderboard: top 50 by duration (CompleteTime - StartTime) ASC.
    void SendCompletionList(Player* player, uint32 challengeID, uint32 level)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        QueryResult r = CharacterDatabase.Query(
            "SELECT c.startTime, c.completeTime, ch.name, ch.race, ch.`class`, ch.gender "
            "FROM coa_challenge_completion c "
            "INNER JOIN characters ch ON ch.guid = c.guid "
            "WHERE c.challengeId = {} AND c.level = {} "
            "AND c.completeTime > 0 AND c.completeTime >= c.startTime "
            "ORDER BY (c.completeTime - c.startTime) ASC "
            "LIMIT 50",
            challengeID, level);

        std::vector<std::string> names, races, genders, classes;
        std::vector<uint32> startTimes, completeTimes;
        if (r)
        {
            do
            {
                Field* f = r->Fetch();
                startTimes.push_back(f[0].Get<uint32>());
                completeTimes.push_back(f[1].Get<uint32>());
                names.push_back(f[2].Get<std::string>());
                try { races.push_back(EnumUtils::ToConstant<Races>(Races(f[3].Get<uint8>()))); }
                catch (...) { races.push_back(""); }
                try { classes.push_back(EnumUtils::ToConstant<Classes>(Classes(f[4].Get<uint8>()))); }
                catch (...) { classes.push_back(""); }
                genders.push_back(f[5].Get<uint8>() == GENDER_FEMALE ? "GENDER_FEMALE" : "GENDER_MALE");
            } while (r->NextRow());
        }

        WorldPacket data(SMSG_COA_CHALLENGE_COMPLETION_LIST, 512);
        data << uint32(challengeID);
        data << uint32(level);
        data << uint32(names.size());
        for (size_t i = 0; i < names.size(); ++i)
            AppendCompletionEntry(data, challengeID, level, names[i], races[i], genders[i], classes[i],
                startTimes[i], completeTimes[i]);

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x5C7 COMPLETION_LIST to {}: challengeID={} level={} entries={}",
            player->GetName(), challengeID, level, names.size());
    }

    // SMSG 0x5C8 CHALLENGE_COMPLETION_ADDED: ONE leaderboard entry, broadcast
    // when a challenge is completed so open leaderboards update live. Handler
    // 0x136C40 runs the same 0x78 entry parser (0x13EFD0) as 0x5C7 and fires
    // CHALLENGE_COMPLETION_ADDED(challengeID, level, count) ("%u%u%u").
    void SendCompletionAdded(Player* player, uint32 challengeID, uint32 level)
    {
        uint32 guid = player->GetGUID().GetCounter();
        uint32 startTime = 0, completeTime = 0;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT startTime, completeTime FROM coa_challenge_completion "
                "WHERE guid = {} AND challengeId = {} AND level = {}",
                guid, challengeID, level))
        {
            Field* f = r->Fetch();
            startTime = f[0].Get<uint32>();
            completeTime = f[1].Get<uint32>();
        }

        std::string race, klass, gender;
        try { race = EnumUtils::ToConstant<Races>(Races(player->getRace())); } catch (...) { race = ""; }
        try { klass = EnumUtils::ToConstant<Classes>(Classes(player->getClass())); } catch (...) { klass = ""; }
        gender = player->getGender() == GENDER_FEMALE ? "GENDER_FEMALE" : "GENDER_MALE";

        WorldPacket data(SMSG_COA_CHALLENGE_COMPLETION_ADDED, 256);
        AppendCompletionEntry(data, challengeID, level, player->GetName(), race, gender, klass,
            startTime, completeTime);

        // The GM test harness drives real completions; suppress the realm-wide
        // broadcast then (the leaderboard add is per-player via 0x5C7 anyway).
        if (!g_testQuiet)
            sWorldSessionMgr->SendGlobalMessage(&data);
        LOG_INFO("module.coa_challenges", "Broadcast SMSG 0x5C8 COMPLETION_ADDED: challengeID={} level={} player={}",
            challengeID, level, player->GetName());
    }

    //   u32 count, count x 28-byte entry:
    //     u32 0 (baggage), u32 Id, u32 Level, u32 StartTimeLo, u32 StartTimeHi,
    //     u32 0 (unused), u32 EndTime.   (Id = map key = challengeID.)
    void SendCompletedList(Player* player)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        struct Completion
        {
            uint32 startTime;
            uint32 completeTime;
        };
        std::map<std::pair<uint32, uint32>, Completion> completions;
        auto collect = [&](auto rows, bool shared)
        {
            if (!rows)
                return;
            do
            {
                Field* f = rows->Fetch();
                uint32 const challengeID = f[0].Get<uint32>();
                if (shared && !IsTrialChallenge(challengeID))
                    continue;
                completions[{ challengeID, f[1].Get<uint32>() }] = { f[2].Get<uint32>(), f[3].Get<uint32>() };
            } while (rows->NextRow());
        };
        collect(CharacterDatabase.Query(
            "SELECT challengeId, level, startTime, completeTime FROM coa_challenge_completion WHERE guid = {}",
            player->GetGUID().GetCounter()), false);
        auto* accountCompletions = CharacterDatabase.GetPreparedStatement(CHAR_SEL_COA_ACCOUNT_CHALLENGE_COMPLETIONS);
        accountCompletions->SetData(0, session->GetAccountId());
        collect(CharacterDatabase.Query(accountCompletions), true);

        WorldPacket data(SMSG_COA_CHALLENGE_COMPLETED_LIST, 4 + 28 * completions.size());
        data << uint32(completions.size());
        for (auto const& [key, completion] : completions)
        {
            data << uint32(0);
            data << key.first;
            data << key.second;
            data << completion.startTime;
            data << uint32(0);
            data << uint32(0);
            data << completion.completeTime;
        }

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x597 COMPLETED_LIST to {}",
            player->GetName());
    }

    // ---- Criteria (0x599 list / 0x59A update) -----------------------------
    // Per-objective banner plumbing. Decoded from Extensions.dll handlers
    // 0x136E80 (SMSG 0x599) and 0x137030 (SMSG 0x59A):
    //   entry = 8 x u32 + u8 (0x21 bytes):
    //     +0x00 a            +0x04 b = challengeID (outer map key; hashed
    //                               FNV-1a and fired as the "challengeID" arg)
    //     +0x08 c = level    +0x0c typeIdx (CHALLENGE_REQUIREMENT_TYPE_* order,
    //                               see CoA.Parse::RequirementTypeIndex)
    //     +0x10 e (v1)       +0x14 f (v2)
    //     +0x18 g            +0x1c h
    //     +0x20 done (u8)
    // The client's 0x59A handler fires CHALLENGE_CRITERIA_UPDATED always and,
    // when the criterion's progress (g|h) transitions 0 -> nonzero, also fires
    // CHALLENGE_CRITERIA_COMPLETED -> C_TrackerHeader shows the green
    // "ChallengeCriteriaSuccess" banner. The 0x599 list carries the durable
    // state (g = done) so a relog restores completed objectives; live
    // completions drive the banner through the per-objective 0x59A update
    // (SendCriteriaUpdated). Without the 0x599 list the client has no entry.
    // The type name/formatters shown on the banner come from the client's own
    // reflection table indexed by typeIdx (it has all trial/challenge defs).
    void AppendCriteriaEntry(WorldPacket& data, uint32 a, uint32 b, uint32 c, uint32 typeIdx,
        uint32 e, uint32 f, uint32 g, uint32 h, uint8 done)
    {
        data << a << b << c << typeIdx << e << f << g << h << done;
    }

    // Build the wire fields for one tracked objective. `typeIdx` is the id of
    // the matching 0x5B6 requirement definition (see RequirementIdFor); g
    // doubles as the "progress" marker: 0 = untouched, nonzero = done (triggers
    // the banner on the 0->nonzero transition); done is the durable flag.
    std::array<uint32, 9> BuildCriteriaEntry(uint32 challengeID, uint32 level, uint32 typeIdx,
        Objective const& o, bool done)
    {
        std::array<uint32, 9> e;
        e[0] = 0;                                                  // a (reserved; §25.2)
        e[1] = challengeID;                                        // b (map key)
        e[2] = level;                                              // c
        e[3] = typeIdx;                                            // requirement id
        e[4] = o.v1;                                               // e (target)
        e[5] = o.v2;                                               // f (gate level)
        e[6] = done ? 1u : 0u;                                     // g (progress)
        e[7] = 0u;                                                 // h
        e[8] = done ? 1u : 0u;                                     // done
        return e;
    }

    // Deterministic small id for an active objective, assigned by walking the
    // active set in the same stable order every time (sorted challenge ids,
    // objective parse order). The id keys the client's requirement registry
    // (0x5B6) and is reused as the criteria typeIdx (0x59A/0x599).
    uint32 RequirementIdFor(Player* player, uint32 challengeID, std::string const& key)
    {
        uint32 guid = player->GetGUID().GetCounter();
        uint32 id = 0;
        for (uint32 cid : ActiveChallenges(guid))
        {
            for (Objective const& o : GetObjectives(cid))
            {
                if (!IsTrackedObjective(o.type))
                    continue;
                ++id;
                if (cid == challengeID && o.key == key)
                    return id;
            }
        }
        return 0;
    }

    // SMSG 0x5B6 requirement definition: populates the client's registry entry
    // for `id` (handler RVA 0x139CD0). Layout:
    //   u32 id, u32 v1, u32 v2, u32 v3, u32 reserved,
    //   16 bytes (value1..3 as floats + pad), str typeName.
    // The 0x59A handler indexes this by typeIdx and fires the event with the
    // type name and the three float values.
    void SendRequirementDef(Player* player, uint32 id, std::string const& type,
        uint32 v1, uint32 v2, uint32 v3)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        WorldPacket data(SMSG_COA_CHALLENGE_REQUIREMENT, 64);
        data << uint32(id);
        data << uint32(v1) << uint32(v2) << uint32(v3);
        data << uint32(0);                                   // +0x10 reserved
        data << float(v1) << float(v2) << float(v3) << float(0); // +0x14 block
        data << uint32(type.size());
        data.append(reinterpret_cast<uint8 const*>(type.data()), type.size());

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges",
            "Sent SMSG 0x5B6 REQUIREMENT to {}: id={} type={} v1={} v2={} v3={}",
            player->GetName(), id, type, v1, v2, v3);
    }

    // SMSG 0x599 CHALLENGE_CRITERIA_LIST_CHANGED: u32 count + count x 0x21-byte
    // entries. Fires CHALLENGE_CRITERIA_LIST_CHANGED() (no args); the trailing
    // string in the handler is only used by the 0x59A event. count=0 clears the
    // client's criteria cache.
    void SendCriteriaList(Player* player, std::vector<std::array<uint32, 9>> const& entries)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        WorldPacket data(SMSG_COA_CHALLENGE_CRITERIA_LIST, 128);
        data << uint32(entries.size());
        for (auto const& e : entries)
            AppendCriteriaEntry(data, e[0], e[1], e[2], e[3], e[4], e[5], e[6], e[7], uint8(e[8]));

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x599 CRITERIA_LIST to {}: {} entries",
            player->GetName(), entries.size());
    }

    // SMSG 0x59A CHALLENGE_CRITERIA_UPDATED: ONE 0x21-byte entry; fires
    // CHALLENGE_CRITERIA_UPDATED(b, c, typeName, f1, f2, f3) and (on the
    // 0 -> nonzero progress transition) CHALLENGE_CRITERIA_COMPLETED -> banner.
    void SendCriteriaUpdated(Player* player, std::array<uint32, 9> const& e)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        WorldPacket data(SMSG_COA_CHALLENGE_CRITERIA_UPDATED, 64);
        AppendCriteriaEntry(data, e[0], e[1], e[2], e[3], e[4], e[5], e[6], e[7], uint8(e[8]));

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges",
            "Sent SMSG 0x59A CRITERIA_UPDATED to {}: challengeID={} level={} typeIdx={} done={}",
            player->GetName(), e[1], e[2], e[3], e[8]);
    }

    // Push the full criteria state (all objectives of every active challenge).
    // Sent on login, on activation and after stop/fail/complete (mirrors the
    // active-list push) so the client cache stays consistent; also the seed the
    // 0x59A updates transition from.
    void SendCriteriaState(Player* player)
    {
        if (!sConfigMgr->GetOption<bool>("CoAChallenges.SendCriteria", true))
            return;
        if (!player->GetSession())
            return;

        uint32 guid = player->GetGUID().GetCounter();
        std::vector<std::array<uint32, 9>> entries;
        uint32 id = 0;
        for (uint32 cid : ActiveChallenges(guid))
        {
            uint32 level = ActiveChallengeLevel(guid, cid);
            for (Objective const& o : GetObjectives(cid))
            {
                if (!IsTrackedObjective(o.type))
                    continue;
                ++id;
                // Seed the client's requirement registry *before* the list so
                // the 0x59A handler can resolve typeIdx -> type name.
                SendRequirementDef(player, id, o.type, o.v1, o.v2, o.v3);
                entries.push_back(BuildCriteriaEntry(cid, level, id, o,
                    IsObjectiveDone(guid, cid, o.key)));
            }
        }
        SendCriteriaList(player, entries);
    }

    // One per-objective update (used by MarkObjectives when an objective flips
    // to done). Re-sends the registry definition first so the entry is present
    // even if the criteria list was missed.
    void SendCriteriaUpdatedForObjective(Player* player, uint32 challengeID, uint32 level,
        Objective const& o, bool done)
    {
        uint32 id = RequirementIdFor(player, challengeID, o.key);
        if (!id)
            return;
        SendRequirementDef(player, id, o.type, o.v1, o.v2, o.v3);
        SendCriteriaUpdated(player, BuildCriteriaEntry(challengeID, level, id, o, done));
    }

    // ---- Trial creator (custom trials) ------------------------------------
    // Wire formats decoded from Extensions.dll + live capture (2026-09-13):
    //   CMSG 0x5A7 SaveTrial:  str trialID, str title, str about, str icon,
    //                          u32 count, count x { u32 challengeID, u32 level, str desc }
    //   CMSG 0x5A9 DeleteTrial / 0x5AD ActivateTrial / 0x5AF DeactivateTrial: str trialID
    //   CMSG 0x5AB QueryTrials: empty
    //   SMSG result (0x5A8 save / 0x5AA delete / 0x5AE activate / 0x5B0 deactivate):
    //                          str trialID, str response (Enum string)
    //   SMSG 0x5CA trial list: str removeTrialID, u32 count, count x trial entry
    //                          (entry = str trialID, str title, str about, str icon,
    //                           u32 n, n x { u32 id, u32 level, str desc })
    // Response strings come from Enum.TrialSaveResponse / TrialActivateResponse /
    //   TrialDeactivateResponse — the client resolves the STRING, not a number.
} // namespace CoAChallenges
