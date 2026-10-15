// mod-coa-challenges (review split): CoA.Challenges.Trials.cpp
// Mechanical split of review-CoAChallenges.cpp; no logic changes.
#include "CoA.Challenges.Review.h"

namespace CoAChallenges
{

    bool ReadWireString(WorldPacket const& packet, uint32& off, std::string& out)
    {
        if (off > packet.size() || packet.size() - off < 4)
            return false;
        uint32 len = packet.read<uint32>(off);
        off += 4;
        // Compare in size_t: `off + len` would wrap in uint32 and let a huge len
        // pass the bounds check, turning into an out-of-bounds read.
        if (len > packet.size() - off)
            return false;
        out.assign(reinterpret_cast<char const*>(packet.contents() + off), len);
        off += len;
        return true;
    }

    // Intra-bundle conflict: no two challenges activated together (a custom
    // trial) may share a non-zero ExclusiveGroup. ValidateChallenge only checks
    // each entry against the ALREADY-ACTIVE set, so without this a trial that
    // bundles e.g. 54 (Hardcore) and 176 (Hardcore - Gath'llzogg) would pass and
    // activate both at once.
    static bool BundleHasExclusiveGroupConflict(std::vector<uint32> const& ids,
        uint32& conflictA, uint32& conflictB)
    {
        conflictA = 0;
        conflictB = 0;
        for (size_t i = 0; i < ids.size(); ++i)
        {
            uint32 group = ExclusiveGroup(ids[i]);
            if (!group)
                continue;
            for (size_t j = i + 1; j < ids.size(); ++j)
            {
                if (ExclusiveGroup(ids[j]) == group)
                {
                    conflictA = ids[i];
                    conflictB = ids[j];
                    return true;
                }
            }
        }
        return false;
    }

    void SendTrialResult(Player* player, uint16 opcode, std::string const& trialID, std::string const& response)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        WorldPacket data(opcode, 128);
        AppendConfigString(data, trialID);
        AppendConfigString(data, response);
        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x{:X} trial result to {}: trialID={} response={}",
            opcode, player->GetName(), trialID, response);
    }

    // Generate a unique, URL-ish trial id for a brand-new trial. The client
    // treats trialID as an opaque string key.
    std::string GenerateTrialId(uint32 guid)
    {
        return "trial-" + std::to_string(guid) + "-" +
            std::to_string(uint32(::time(nullptr)));
    }

    // The trial list is browsable by any character now (not just its author),
    // so the creator name is stored on save and resolved from the char cache as
    // a fallback for rows written before the `author` column existed.
    std::string ResolveTrialAuthor(uint32 ownerGuid, std::string const& stored)
    {
        if (!stored.empty())
            return stored;
        std::string name;
        if (sCharacterCache->GetCharacterNameByGuid(
                ObjectGuid::Create<HighGuid::Player>(ownerGuid), name))
            return name;
        return "Unknown";
    }

    // Trials are browsable by any character, but a trial's bundled-challenge
    // rows live under the CREATOR's guid -> resolve the owner from the trialID.
    uint32 TrialOwnerGuid(std::string const& trialID)
    {
        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT guid FROM coa_custom_trial WHERE trialId = '{}'", eTrialId))
            return r->Fetch()[0].Get<uint32>();
        return 0;
    }

    // If the challenge belongs to the character's active custom trial, return
    // the trial's display name/icon (so announcements attribute the failure to
    // the trial, not the bundled challenge).
    bool ActiveTrialDisplayFor(Player* player, uint32 challengeID, std::string& name, std::string& icon)
    {
        name.clear();
        icon.clear();
        std::string trialID = GetActiveCustomTrial(player->GetGUID().GetCounter());
        if (trialID.empty())
            return false;
        uint32 ownerGuid = TrialOwnerGuid(trialID);
        if (!ownerGuid)
            return false;
        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);
        if (!CharacterDatabase.Query(
                "SELECT 1 FROM coa_custom_trial_entry WHERE guid = {} AND trialId = '{}' AND challengeId = {} LIMIT 1",
                ownerGuid, eTrialId, challengeID))
            return false;
        if (QueryResult t = CharacterDatabase.Query(
                "SELECT title, icon FROM coa_custom_trial WHERE trialId = '{}'", eTrialId))
        {
            Field* f = t->Fetch();
            name = f[0].Get<std::string>();
            icon = f[1].Get<std::string>();
            return true;
        }
        return false;
    }

    static void ReadMyVote(uint32 selfGuid, std::string const& trialID, uint8& up, uint8& down)
    {
        up = 0;
        down = 0;
        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT upvote, downvote FROM coa_custom_trial_vote WHERE guid = {} AND trialId = '{}'",
                selfGuid, eTrialId))
        {
            Field* f = r->Fetch();
            up = f[0].Get<uint8>();
            down = f[1].Get<uint8>();
        }
    }

    // The client derives a trial's Score as (#upvoteRecords - #downvoteRecords),
    // so an empty list means "0 points"; each record is 8 bytes on the wire.
    static void AppendVoteList(WorldPacket& data, std::string const& trialID, bool up)
    {
        char const* col = up ? "upvote" : "downvote";
        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);
        QueryResult r = CharacterDatabase.Query(
            std::string("SELECT guid FROM coa_custom_trial_vote WHERE trialId = '") + eTrialId +
            "' AND " + col + " = 1");
        if (!r)
        {
            data << uint32(0);
            return;
        }
        data << uint32(r->GetRowCount());
        do
        {
            data << uint32(r->Fetch()[0].Get<uint32>());
            data << uint32(0);
        } while (r->NextRow());
    }

    // Active-trial state (client mgr+0xC). The client's DeactivateTrial (CMSG
    // 0x5AF) carries NO payload, so the server tracks the active trial and
    // syncs it back with SMSG 0x5B1 (GetActiveTrial/CanDeactivateTrial read it).
    std::string GetActiveCustomTrial(uint32 guid)
    {
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT trialId FROM coa_custom_trial_active WHERE guid = {}", guid))
            return r->Fetch()[0].Get<std::string>();
        return "";
    }

    void SendActiveTrial(Player* player, std::string const& trialID)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;
        WorldPacket data(SMSG_COA_TRIAL_ACTIVE, 32);
        AppendConfigString(data, trialID);
        session->SendPacket(&data);
    }

    void SetActiveCustomTrial(Player* player, std::string const& trialID)
    {
        uint32 guid = player->GetGUID().GetCounter();
        if (trialID.empty())
        {
            CharacterDatabase.DirectExecute(
                "DELETE FROM coa_custom_trial_active WHERE guid = {}", guid);
        }
        else
        {
            std::string eTrialId = trialID;
            CharacterDatabase.EscapeString(eTrialId);
            // Preserve the original activation time if this exact trial is
            // already active; otherwise stamp "now" (never reset a running
            // trial's leaderboard timer).
            uint32 startTime = 0;
            if (QueryResult r = CharacterDatabase.Query(
                    "SELECT startTime FROM coa_custom_trial_active WHERE guid = {} AND trialId = '{}'",
                    guid, eTrialId))
                startTime = r->Fetch()[0].Get<uint32>();
            if (!startTime)
                startTime = uint32(::time(nullptr));
            CharacterDatabase.DirectExecute(
                "REPLACE INTO coa_custom_trial_active (guid, trialId, startTime) VALUES ({}, '{}', {})",
                guid, eTrialId, startTime);
        }
        SendActiveTrial(player, trialID);
    }

    // One custom-trial completion entry (0x88 on the client side; parser
    // 0x10125860 reads 5 strings + 4 u32). The wire order matches the client's
    // GetTrialCompletions field map:
    //   str Challenge (=trialID), str PlayerName, u32 StartLo, u32 StartHi,
    //   u32 CompleteLo, u32 CompleteHi, str PlayerRace, str PlayerGender,
    //   str PlayerClass.
    void AppendTrialCompletionEntry(WorldPacket& data, std::string const& trialID,
        std::string const& name, std::string const& race, std::string const& gender,
        std::string const& klass, uint32 startTime, uint32 completeTime)
    {
        AppendConfigString(data, trialID);
        AppendConfigString(data, name);
        data << startTime << uint32(0);
        data << completeTime << uint32(0);
        AppendConfigString(data, race);
        AppendConfigString(data, gender);
        AppendConfigString(data, klass);
    }

    // SMSG 0x5CA TRIAL_COMPLETION_LIST_CHANGED (answer to CMSG 0x5C9
    // QueryTrialCompletions): str trialID, u32 count, count x completion entry.
    // The first string is the store key (and the per-entry Challenge field), so
    // sending it replaces that trial's cached completion list. Top 50 by
    // duration (completeTime - startTime) ASC, mirroring the challenge board.
    void SendTrialCompletions(Player* player, std::string const& trialID)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);
        QueryResult r = CharacterDatabase.Query(
            "SELECT c.startTime, c.completeTime, ch.name, ch.race, ch.`class`, ch.gender "
            "FROM coa_custom_trial_completion c "
            "INNER JOIN characters ch ON ch.guid = c.guid "
            "WHERE c.trialId = '{}' "
            "ORDER BY (c.completeTime - c.startTime) ASC "
            "LIMIT 50",
            eTrialId);

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

        WorldPacket data(SMSG_COA_TRIAL_QUERY_RESULT, 512);
        AppendConfigString(data, trialID);
        data << uint32(names.size());
        for (size_t i = 0; i < names.size(); ++i)
            AppendTrialCompletionEntry(data, trialID, names[i], races[i], genders[i],
                classes[i], startTimes[i], completeTimes[i]);

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x5CA TRIAL_COMPLETIONS to {}: trialID={} entries={}",
            player->GetName(), trialID, names.size());
    }

    // SMSG 0x5CB TRIAL_COMPLETION_ADDED: one completion entry (no header); the
    // entry's first string is the trial key. Broadcast so open trial
    // leaderboards update live (mirrors 0x5C8 for challenges).
    void SendTrialCompletionAdded(Player* player, std::string const& trialID)
    {
        uint32 guid = player->GetGUID().GetCounter();
        uint32 startTime = 0, completeTime = 0;
        {
            std::string eTrialId = trialID;
            CharacterDatabase.EscapeString(eTrialId);
            if (QueryResult r = CharacterDatabase.Query(
                    "SELECT startTime, completeTime FROM coa_custom_trial_completion "
                    "WHERE guid = {} AND trialId = '{}'",
                    guid, eTrialId))
            {
                Field* f = r->Fetch();
                startTime = f[0].Get<uint32>();
                completeTime = f[1].Get<uint32>();
            }
        }

        std::string race, klass, gender;
        try { race = EnumUtils::ToConstant<Races>(Races(player->getRace())); } catch (...) { race = ""; }
        try { klass = EnumUtils::ToConstant<Classes>(Classes(player->getClass())); } catch (...) { klass = ""; }
        gender = player->getGender() == GENDER_FEMALE ? "GENDER_FEMALE" : "GENDER_MALE";

        WorldPacket data(SMSG_COA_TRIAL_COMPLETION_ADDED, 256);
        AppendTrialCompletionEntry(data, trialID, player->GetName(), race, gender, klass,
            startTime, completeTime);

        sWorldSessionMgr->SendGlobalMessage(&data);
        LOG_INFO("module.coa_challenges", "Broadcast SMSG 0x5CB TRIAL_COMPLETION_ADDED: trialID={} player={}",
            trialID, player->GetName());
    }

    // If the just-completed challenge is part of the character's active custom
    // trial and every bundled challenge is now completed, the trial is done:
    // record the completion (leaderboard), announce it (0x5CB) and clear the
    // client's active-trial state.
    bool TryCompleteCustomTrial(Player* player, uint32 challengeID)
    {
        uint32 guid = player->GetGUID().GetCounter();
        std::string trialID = GetActiveCustomTrial(guid);
        if (trialID.empty())
            return false;
        uint32 ownerGuid = TrialOwnerGuid(trialID);
        if (!ownerGuid)
        {
            SetActiveCustomTrial(player, "");
            return false;
        }
        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);

        std::vector<std::pair<uint32, uint32>> bundled; // (challengeId, level)
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT challengeId, level FROM coa_custom_trial_entry WHERE guid = {} AND trialId = '{}'",
                ownerGuid, eTrialId))
        {
            do
            {
                Field* f = r->Fetch();
                bundled.emplace_back(f[0].Get<uint32>(), f[1].Get<uint32>());
            } while (r->NextRow());
        }

        bool partOfTrial = false;
        for (auto const& [cid, level] : bundled)
            if (cid == challengeID)
                partOfTrial = true;
        if (!partOfTrial)
            return false;   // the completed challenge is not part of this trial

        std::set<uint32> actives = ActiveChallenges(guid);
        for (auto const& [cid, level] : bundled)
        {
            if (actives.count(cid))
                return false;   // the trial still has a running challenge
            // A bundled challenge that is merely gone (cancelled/abandoned without
            // completing) must NOT count as done: require its completion record.
            if (!HasCompletionLevel(guid, cid, level))
                return false;
        }

        uint32 startTime = 0;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT startTime FROM coa_custom_trial_active WHERE guid = {} AND trialId = '{}'",
                guid, eTrialId))
            startTime = r->Fetch()[0].Get<uint32>();
        uint32 completeTime = uint32(::time(nullptr));

        CharacterDatabase.DirectExecute(
            "REPLACE INTO coa_custom_trial_completion (guid, trialId, startTime, completeTime) "
            "VALUES ({}, '{}', {}, {})",
            guid, eTrialId, startTime, completeTime);

        if (sConfigMgr->GetOption<bool>("CoAChallenges.SendTrialCompletionAdded", true))
            SendTrialCompletionAdded(player, trialID);
        SetActiveCustomTrial(player, "");

        LOG_INFO("module.coa_challenges", "Custom trial {} completed by {} (challenge {})",
            trialID, player->GetName(), challengeID);
        return true;
    }

    // Custom-trial list refresh (answer to CMSG 0x5AB QueryTrials and after
    // save/delete).
    //
    // The trial DEFINITIONS (ID, Name, Description, Icon, Author + bundled
    // challenges + vote state) are delivered ONLY by SMSG 0x5AC
    // (TRIAL_QUERY_RESULT). SMSG 0x5CA is TRIAL_COMPLETION_LIST_CHANGED: its
    // client handler (0x123C10) inserts 0x88 completion entries into the
    // completion store (mgr+0x24, read by GetTrialCompletion 0x127220) and
    // fires TRIAL_COMPLETION_LIST_CHANGED. Sending definition-shaped entries
    // through 0x5CA pollutes the completion store, so 0x5CA is used solely by
    // SendTrialCompletions() (answer to CMSG 0x5C9).
    //
    // Evidence (Extensions.dll): handler 0x122D70 (0x5AC) fires
    // TRIAL_QUERY_RESULT; handler 0x123C10 (0x5CA) fires
    // TRIAL_COMPLETION_LIST_CHANGED and touches mgr+0x24.
    void SendTrialList(Player* player)
    {
        // Definitions + entries + votes (0x5AC, fires TRIAL_QUERY_RESULT).
        SendTrialData(player);

        // Keep the client's active-trial state (mgr+0xC) in sync.
        SendActiveTrial(player, GetActiveCustomTrial(player->GetGUID().GetCounter()));
    }

    // SMSG 0x5AC TRIAL_DATA: the trial details that populate the Custom Trials
    // list store. Header: u8 clearFlag, u8 flag2, u32 count. Entry:
    //   str ID, u8 Owned, str Author, str Name, str Description, str Icon,
    //   u32 challengeCount, challengeCount x { u32 ChallengeId, u32 Level, str Desc },
    //   u8 Upvoted, u8 Downvoted,
    //   u32 upvoteCount, upvoteCount x {u32,u32},
    //   u32 downvoteCount, downvoteCount x {u32,u32}.
    // The client computes Score = upvoteCount - downvoteCount.
    void SendTrialData(Player* player)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        uint32 selfGuid = player->GetGUID().GetCounter();
        QueryResult trials = CharacterDatabase.Query(
            "SELECT guid, trialId, title, about, icon, author FROM coa_custom_trial ORDER BY trialId");

        WorldPacket data(SMSG_COA_TRIAL_DATA, 512);
        data << uint8(1);       // clear the store first
        data << uint8(1);       // flag2: fire TRIAL_QUERY_RESULT (auto-refresh list/score)
        if (!trials)
        {
            data << uint32(0);
        }
        else
        {
            data << uint32(trials->GetRowCount());
            do
            {
                Field* f = trials->Fetch();
                uint32 ownerGuid = f[0].Get<uint32>();
                std::string trialID = f[1].Get<std::string>();
                std::string author = ResolveTrialAuthor(ownerGuid, f[5].Get<std::string>());

                std::string eTrialId = trialID;
                CharacterDatabase.EscapeString(eTrialId);

                AppendConfigString(data, trialID);              // ID
                data << uint8(ownerGuid == selfGuid ? 1 : 0);   // Owned
                AppendConfigString(data, author);               // Author
                AppendConfigString(data, f[2].Get<std::string>()); // Name (title)
                AppendConfigString(data, f[3].Get<std::string>()); // Description (about)
                AppendConfigString(data, f[4].Get<std::string>()); // Icon

                std::vector<std::tuple<uint32, uint32, std::string>> entries;
                if (QueryResult e = CharacterDatabase.Query(
                        "SELECT challengeId, level, description FROM coa_custom_trial_entry "
                        "WHERE guid = {} AND trialId = '{}' ORDER BY challengeId, level",
                        ownerGuid, eTrialId))
                {
                    do
                    {
                        Field* ef = e->Fetch();
                        entries.emplace_back(ef[0].Get<uint32>(), ef[1].Get<uint32>(), ef[2].Get<std::string>());
                    } while (e->NextRow());
                }
                data << uint32(entries.size());
                for (auto const& [cid, lvl, desc] : entries)
                {
                    data << uint32(cid);
                    data << uint32(lvl);
                    AppendConfigString(data, desc);
                }

                uint8 up = 0, down = 0;
                ReadMyVote(selfGuid, trialID, up, down);
                data << uint8(up);                  // Upvoted
                data << uint8(down);                // Downvoted
                AppendVoteList(data, trialID, true);   // upvote records
                AppendVoteList(data, trialID, false);  // downvote records
            } while (trials->NextRow());
        }

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x5AC TRIAL_DATA to {}",
            player->GetName());
    }

    // CMSG 0x5A7 SaveTrial.
    void HandleSaveTrial(Player* player, WorldPacket const& packet)
    {
        uint32 off = 0;
        std::string trialID, title, about, icon;
        if (!ReadWireString(packet, off, trialID) || !ReadWireString(packet, off, title)
            || !ReadWireString(packet, off, about) || !ReadWireString(packet, off, icon))
        {
            SendTrialResult(player, SMSG_COA_TRIAL_SAVE_RESULT, "", "SAVE_CHALLENGE_NO_TITLE");
            return;
        }
        if (off + 4 > packet.size())
        {
            SendTrialResult(player, SMSG_COA_TRIAL_SAVE_RESULT, "", "SAVE_CHALLENGE_NO_TITLE");
            return;
        }
        uint32 count = packet.read<uint32>(off);
        off += 4;

        std::vector<std::tuple<uint32, uint32, std::string>> entries;
        for (uint32 i = 0; i < count; ++i)
        {
            if (off + 8 > packet.size())
                break;
            uint32 challengeId = packet.read<uint32>(off); off += 4;
            uint32 level = packet.read<uint32>(off); off += 4;
            std::string desc;
            if (!ReadWireString(packet, off, desc))
                break;
            entries.emplace_back(challengeId, level, desc);
        }

        // Reject entries that could never activate (unknown challenge or level
        // out of range): they would only pollute the browsable trial list.
        for (auto const& [challengeId, level, desc] : entries)
        {
            if (!ChallengeExists(challengeId) || level < 1
                || level > ChallengeLevelCount(challengeId))
            {
                LOG_INFO("module.coa_challenges",
                    "SaveTrial {} by {} rejected: invalid entry challenge {} level {}",
                    trialID, player->GetName(), challengeId, level);
                SendTrialResult(player, SMSG_COA_TRIAL_SAVE_RESULT, trialID,
                    "SAVE_CHALLENGE_CANNOT_EDIT_CHALLENGES");
                return;
            }
        }

        // Validation (mirrors Enum.TrialSaveResponse codes).
        if (title.empty())
        {
            SendTrialResult(player, SMSG_COA_TRIAL_SAVE_RESULT, trialID, "SAVE_CHALLENGE_NO_TITLE");
            return;
        }
        if (entries.empty())
        {
            SendTrialResult(player, SMSG_COA_TRIAL_SAVE_RESULT, trialID, "SAVE_CHALLENGE_NO_CHALLENGES");
            return;
        }

        // Reject a bundle combining mutually exclusive challenges (same non-zero
        // ExclusiveGroup): the client editor can let them through, and the server
        // must never store a trial it would refuse to activate.
        std::vector<uint32> bundleIds;
        bundleIds.reserve(entries.size());
        for (auto const& entry : entries)
            bundleIds.push_back(std::get<0>(entry));
        {
            uint32 conflictA = 0, conflictB = 0;
            if (BundleHasExclusiveGroupConflict(bundleIds, conflictA, conflictB))
            {
                LOG_INFO("module.coa_challenges",
                    "SaveTrial {} by {} rejected: challenges {} and {} share an exclusive group",
                    trialID, player->GetName(), conflictA, conflictB);
                ChatHandler(player->GetSession()).PSendSysMessage(
                    "A trial cannot combine two mutually exclusive challenges ({} and {}).",
                    conflictA, conflictB);
                // No dedicated save-conflict code in Enum.TrialSaveResponse.
                SendTrialResult(player, SMSG_COA_TRIAL_SAVE_RESULT, trialID, "SAVE_CHALLENGE_CANNOT_EDIT_CHALLENGES");
                return;
            }
        }

        uint32 guid = player->GetGUID().GetCounter();
        // Never let a client overwrite or hijack another character's trial by
        // reusing its id: only the current owner may save under an existing id.
        if (!trialID.empty())
        {
            uint32 owner = TrialOwnerGuid(trialID);
            if (owner && owner != guid)
            {
                LOG_INFO("module.coa_challenges",
                    "SaveTrial by {} rejected: trial {} belongs to guid {}",
                    player->GetName(), trialID, owner);
                SendTrialResult(player, SMSG_COA_TRIAL_SAVE_RESULT, trialID,
                    "SAVE_CHALLENGE_CANNOT_EDIT_CHALLENGES");
                return;
            }
        }
        if (trialID.empty())
            trialID = GenerateTrialId(guid);

        // Escape string fields (title/about/icon may contain backslashes and
        // quotes) before embedding them in SQL.
        std::string eTrialId = trialID, eTitle = title, eAbout = about, eIcon = icon, eAuthor = player->GetName();
        CharacterDatabase.EscapeString(eTrialId);
        CharacterDatabase.EscapeString(eTitle);
        CharacterDatabase.EscapeString(eAbout);
        CharacterDatabase.EscapeString(eIcon);
        CharacterDatabase.EscapeString(eAuthor);

        CharacterDatabase.DirectExecute(
            "REPLACE INTO coa_custom_trial (guid, trialId, title, about, icon, author) "
            "VALUES ({}, '{}', '{}', '{}', '{}', '{}')",
            guid, eTrialId, eTitle, eAbout, eIcon, eAuthor);
        CharacterDatabase.DirectExecute(
            "DELETE FROM coa_custom_trial_entry WHERE guid = {} AND trialId = '{}'", guid, eTrialId);
        for (auto const& [challengeId, level, desc] : entries)
        {
            std::string eDesc = desc;
            CharacterDatabase.EscapeString(eDesc);
            CharacterDatabase.DirectExecute(
                "INSERT INTO coa_custom_trial_entry (guid, trialId, challengeId, level, description) "
                "VALUES ({}, '{}', {}, {}, '{}')",
                guid, eTrialId, challengeId, level, eDesc);
        }

        SendTrialResult(player, SMSG_COA_TRIAL_SAVE_RESULT, trialID, "SAVE_CHALLENGE_OK");
        SendTrialList(player);
    }

    // CMSG 0x5A9 DeleteTrial.
    void HandleDeleteTrial(Player* player, WorldPacket const& packet)
    {
        uint32 off = 0;
        std::string trialID;
        if (!ReadWireString(packet, off, trialID) || trialID.empty())
            return;

        uint32 guid = player->GetGUID().GetCounter();
        // Only the owner may delete a trial. Votes and completions are keyed by
        // trialId globally, so without this check any player could wipe another
        // character's votes/completions by deleting their trial id.
        uint32 owner = TrialOwnerGuid(trialID);
        if (!owner || owner != guid)
        {
            LOG_INFO("module.coa_challenges",
                "DeleteTrial ignored for {}: trial {} is not owned by guid {}",
                player->GetName(), trialID, guid);
            return;
        }

        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);
        CharacterDatabase.DirectExecute(
            "DELETE FROM coa_custom_trial WHERE guid = {} AND trialId = '{}'", guid, eTrialId);
        CharacterDatabase.DirectExecute(
            "DELETE FROM coa_custom_trial_entry WHERE guid = {} AND trialId = '{}'", guid, eTrialId);
        CharacterDatabase.DirectExecute(
            "DELETE FROM coa_custom_trial_vote WHERE trialId = '{}'", eTrialId);
        CharacterDatabase.DirectExecute(
            "DELETE FROM coa_custom_trial_completion WHERE trialId = '{}'", eTrialId);

        SendTrialResult(player, SMSG_COA_TRIAL_DELETE_RESULT, trialID, "DELETE_CHALLENGE_OK");
        SendTrialList(player);
    }

    // CMSG 0x5AD ActivateTrial. A custom trial bundles challenges; activating it
    // activates every bundled challenge. Validate all first (no partial
    // activation), then activate each and push the active list.
    void HandleActivateTrial(Player* player, WorldPacket const& packet)
    {
        uint32 off = 0;
        std::string trialID;
        if (!ReadWireString(packet, off, trialID) || trialID.empty())
            return;

        // One custom trial at a time: activating a second would overwrite the
        // tracking row and orphan the first bundle's still-active challenges.
        if (!GetActiveCustomTrial(player->GetGUID().GetCounter()).empty())
        {
            SendTrialResult(player, SMSG_COA_TRIAL_ACTIVATE_RESULT, trialID,
                "ACTIVATE_TRIAL_CANNOT_ACTIVATE_CHALLENGE");
            SendActiveList(player);
            SendCriteriaState(player);
            return;
        }

        uint32 ownerGuid = TrialOwnerGuid(trialID);
        if (!ownerGuid)
        {
            SendTrialResult(player, SMSG_COA_TRIAL_ACTIVATE_RESULT, trialID, "ACTIVATE_TRIAL_NOT_FOUND");
            SendActiveList(player);
            SendCriteriaState(player);
            return;
        }
        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);
        std::vector<std::pair<uint32, uint32>> entries;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT challengeId, level FROM coa_custom_trial_entry WHERE guid = {} AND trialId = '{}'",
                ownerGuid, eTrialId))
        {
            do
            {
                Field* f = r->Fetch();
                entries.emplace_back(f[0].Get<uint32>(), f[1].Get<uint32>());
            } while (r->NextRow());
        }

        // Validate the bundle as a set: ValidateChallenge below only compares
        // each entry against the already-active challenges, never against the
        // other entries, so two bundled challenges of the same exclusive group
        // would otherwise both activate.
        std::vector<uint32> bundleIds;
        bundleIds.reserve(entries.size());
        for (auto const& entry : entries)
            bundleIds.push_back(entry.first);
        {
            uint32 conflictA = 0, conflictB = 0;
            if (BundleHasExclusiveGroupConflict(bundleIds, conflictA, conflictB))
            {
                LOG_INFO("module.coa_challenges",
                    "ActivateTrial {} by {} rejected: challenges {} and {} share an exclusive group",
                    trialID, player->GetName(), conflictA, conflictB);
                ChatHandler(player->GetSession()).PSendSysMessage(
                    "This trial combines two mutually exclusive challenges ({} and {}).",
                    conflictA, conflictB);
                SendTrialResult(player, SMSG_COA_TRIAL_ACTIVATE_RESULT, trialID, "ACTIVATE_TRIAL_CANNOT_ACTIVATE_CHALLENGE");
                // Same reasoning as the single-challenge path: the client
                // toggles optimistically, so restore the server's active set.
                SendActiveList(player);
                SendCriteriaState(player);
                return;
            }
        }

        uint32 code = 0;
        for (auto const& [cid, lvl] : entries)
        {
            code = ValidateChallenge(player, cid, lvl);
            if (code)
                break;
        }

        if (code)
        {
            LOG_INFO("module.coa_challenges", "ActivateTrial {} by {} rejected code={} ({})",
                trialID, player->GetName(), code, ChallengeResponseString(code));
            SendTrialResult(player, SMSG_COA_TRIAL_ACTIVATE_RESULT, trialID, "ACTIVATE_TRIAL_CANNOT_ACTIVATE_CHALLENGE");
            SendActiveList(player);
            SendCriteriaState(player);
            return;
        }

        g_suppressSyncBroadcast = true;
        for (auto const& [cid, lvl] : entries)
            DoActivateChallenge(player, cid, lvl);
        g_suppressSyncBroadcast = false;

        // One group sync for the whole trial (not one per bundled challenge).
        // A trial bundling a party-required challenge (Duo/Trio/GroupSize>=2)
        // is a formation request: a decline reverts the whole activation.
        if (player->GetGroup()
            && sConfigMgr->GetOption<bool>("CoAChallenges.SyncChallengesWithGroup", true))
        {
            uint32 const g = player->GetGUID().GetCounter();
            std::vector<std::pair<uint32, uint32>> wire, rollback;
            for (uint32 cid : ActiveChallenges(g))
                wire.emplace_back(cid, ActiveChallengeLevel(g, cid));
            for (auto const& [cid, lvl] : entries)
                if (ChallengeRequiresParty(cid))
                    rollback.emplace_back(cid, lvl);
            SendChallengeSyncToGroup(player, 60000, false, wire, !rollback.empty(), rollback);
        }

        SendTrialResult(player, SMSG_COA_TRIAL_ACTIVATE_RESULT, trialID, "ACTIVATE_CHALLENGE_OK");
        SetActiveCustomTrial(player, trialID);
        SendActiveList(player);
        SendCriteriaState(player);
    }

    // CMSG 0x5AF DeactivateTrial: NO payload. The server deactivates the
    // character's currently-active custom trial (tracked in
    // coa_custom_trial_active) and clears it on the client (SMSG 0x5B1 empty).
    void HandleDeactivateTrial(Player* player, WorldPacket const& packet)
    {
        uint32 off = 0;
        std::string trialID;
        ReadWireString(packet, off, trialID);   // tolerated: the client sends none
        uint32 guid = player->GetGUID().GetCounter();
        if (trialID.empty())
            trialID = GetActiveCustomTrial(guid);
        if (trialID.empty())
            return;

        uint32 ownerGuid = TrialOwnerGuid(trialID);
        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);
        std::vector<std::pair<uint32, uint32>> removed;
        g_suppressSyncBroadcast = true;
        if (ownerGuid)
        {
            // Mirror the single-challenge STOP path: a challenge with lives is
            // FAILED when abandoned unless still pristine, so a client cannot
            // bypass perma-death/hardcore by bundling it into a custom trial.
            std::set<uint32> actives = ActiveChallenges(guid);
            if (QueryResult r = CharacterDatabase.Query(
                    "SELECT challengeId FROM coa_custom_trial_entry WHERE guid = {} AND trialId = '{}'",
                    ownerGuid, eTrialId))
            {
                do
                {
                    uint32 cid = r->Fetch()[0].Get<uint32>();
                    removed.emplace_back(cid, 0);
                    if (!actives.count(cid))
                        continue;   // already ended by an earlier fail in this loop
                    uint32 lives = LivesTotal(cid);
                    bool freeCancel = sConfigMgr->GetOption<bool>(
                        "CoAChallenges.FreeCancelIfPristine", true)
                        && IsPristine(player, cid);
                    if (lives >= 1 && !freeCancel)
                    {
                        uint32 deaths = 0;
                        if (QueryResult dr = CharacterDatabase.Query(
                                "SELECT deaths FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                                guid, cid))
                            deaths = dr->Fetch()[0].Get<uint32>();
                        NotifyPlayer(player, "You have abandoned {} and failed it.", ChallengeName(cid));
                        FailChallenge(player, cid, ActiveChallengeLevel(guid, cid), deaths);
                    }
                    else
                    {
                        DeactivateChallenge(player, cid);
                    }
                } while (r->NextRow());
            }
        }
        g_suppressSyncBroadcast = false;

        // One removal sync for the whole trial.
        if (!removed.empty() && player->GetGroup()
            && sConfigMgr->GetOption<bool>("CoAChallenges.SyncChallengesWithGroup", true))
            SendChallengeSyncToGroup(player, 60000, true, removed, false, {});

        SetActiveCustomTrial(player, "");
        SendTrialResult(player, SMSG_COA_TRIAL_DEACTIVATE_RESULT, trialID, "DEACTIVATE_CHALLENGE_OK");
        SendActiveList(player);
        SendCriteriaState(player);
    }

    // CMSG 0x5BF RateTrial: str trialID + u8 upvote + u8 downvote. The client
    // sends (up,false) / (false,down) and toggles off with (false,false), so the
    // two flags are mutually exclusive. There is no dedicated result opcode/
    // event on the client: the score is reflected by re-pushing the trial store
    // (0x5AC), which CustomTrialItemMixin:UpdateScore reads via GetTrialInfo.
    void HandleRateTrial(Player* player, WorldPacket const& packet)
    {
        uint32 off = 0;
        std::string trialID;
        if (!ReadWireString(packet, off, trialID) || trialID.empty())
            return;
        if (off + 2 > packet.size())
            return;
        uint8 up = packet.read<uint8>(off); off += 1;
        uint8 down = packet.read<uint8>(off); off += 1;
        if (up && down)
            down = 0;

        std::string eTrialId = trialID;
        CharacterDatabase.EscapeString(eTrialId);
        if (!CharacterDatabase.Query(
                "SELECT 1 FROM coa_custom_trial WHERE trialId = '{}'", eTrialId))
        {
            LOG_INFO("module.coa_challenges", "RateTrial: unknown trial {} from {}",
                trialID, player->GetName());
            return;
        }

        uint32 guid = player->GetGUID().GetCounter();
        // No self-voting: the author could otherwise inflate their own score.
        if (uint32 ownerGuid = TrialOwnerGuid(trialID); ownerGuid && ownerGuid == guid)
        {
            LOG_INFO("module.coa_challenges", "RateTrial ignored: {} tried to vote on own trial {}",
                player->GetName(), trialID);
            return;
        }
        CharacterDatabase.DirectExecute(
            "REPLACE INTO coa_custom_trial_vote (guid, trialId, upvote, downvote) "
            "VALUES ({}, '{}', {}, {})",
            guid, eTrialId, up ? 1 : 0, down ? 1 : 0);

        LOG_INFO("module.coa_challenges", "RateTrial {} by {}: up={} down={}",
            trialID, player->GetName(), up ? 1 : 0, down ? 1 : 0);

        SendTrialData(player);
    }
} // namespace CoAChallenges
