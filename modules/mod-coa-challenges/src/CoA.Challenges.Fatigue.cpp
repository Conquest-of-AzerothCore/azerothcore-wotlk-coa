// mod-coa-challenges (review split): CoA.Challenges.Fatigue.cpp
// Mechanical split of review-CoAChallenges.cpp; no logic changes.
#include "CoA.Challenges.Review.h"

namespace CoAChallenges
{

    std::mutex FatigueMutex;
    std::unordered_map<uint32, FatigueState> FatigueStates;

    bool IsFatigueChallenge(uint32 challengeID)
    {
        std::string rules = ChallengeRules(challengeID);
        return CoAParse::ListContains(rules, "CHALLENGE_RULES_TYPE_FATIGUED_UNLESS_RESTED");
    }

    uint32 FatigueMax()
    {
        return std::max<uint32>(1, sConfigMgr->GetOption<uint32>("CoAChallenges.FatigueMax", 100));
    }

    uint32 FatigueFillSeconds()
    {
        return std::max<uint32>(1, sConfigMgr->GetOption<uint32>("CoAChallenges.FatigueSecondsToFill", 420));
    }

    void PersistFatigue(uint32 guid, uint32 challengeId, int32 fatigue)
    {
        CharacterDatabase.Execute(
            "REPLACE INTO coa_character_fatigue (guid, challengeId, fatigue) VALUES ({}, {}, {})",
            guid, challengeId, fatigue);
    }

    // StopMirrorTimer is protected in Player, so build the packets directly.
    void StopFatigueBar(Player* player)
    {
        WorldPacket data(SMSG_STOP_MIRROR_TIMER, 4);
        data << uint32(FATIGUE_TIMER);
        player->SendDirectMessage(&data);
    }

    // Mirror-timer bar drains over FatigueSecondsToFill (value/scale are in ms).
    // `fatigue` is the REMAINING amount: it starts at FatigueMax and drops to 0,
    // so the bar starts full and empties (negative scale = drains), matching
    // Ascension ("the same mechanic as out-of-zone exploring").
    void SendFatigueBar(Player* player, int32 fatigue)
    {
        uint32 maxV = FatigueMax();
        uint32 fillMs = FatigueFillSeconds() * 1000;
        // 64-bit: fatigue * fillMs overflows uint32 for large FatigueSecondsToFill.
        uint32 remainingMs = uint32(uint64(std::clamp<int32>(fatigue, 0, (int32)maxV)) * fillMs / maxV);
        WorldPacket data(SMSG_START_MIRROR_TIMER, 21);
        data << uint32(FATIGUE_TIMER);   // timer 0 = FATIGUE (MirrorTimer1)
        data << uint32(remainingMs);     // current value (ms)
        data << uint32(fillMs);          // max value (ms)
        data << int32(-1);               // negative scale -> drains
        data << uint8(0);                // paused
        data << uint32(0);               // spell id
        player->SendDirectMessage(&data);
    }

    void TrackFatigue(Player* player, uint32 challengeID)
    {
        if (!player || !IsFatigueChallenge(challengeID))
            return;
        uint32 guid = player->GetGUID().GetCounter();
        int32 const maxV = (int32)FatigueMax();
        // `fatigue` is the remaining amount; a fresh/stale row starts full.
        int32 fatigue = maxV;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT fatigue FROM coa_character_fatigue WHERE guid = {} AND challengeId = {}",
                guid, challengeID))
        {
            fatigue = r->Fetch()[0].Get<int32>();
            if (fatigue <= 0 || fatigue > maxV)
                fatigue = maxV;
        }
        // Starter zones are sanctuaries (no inn): treated as safe, like a rest area.
        bool resting = player->HasPlayerFlag(PLAYER_FLAGS_RESTING) || player->IsInSanctuary();
        {
            std::lock_guard<std::mutex> lock(FatigueMutex);
            FatigueStates[guid] = FatigueState{ challengeID, fatigue, 0, resting };
        }
        if (resting)
            StopFatigueBar(player);
        else
            SendFatigueBar(player, fatigue);
    }

    // Stop tracking but keep the persisted value (logout).
    void UntrackFatigue(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        {
            std::lock_guard<std::mutex> lock(FatigueMutex);
            FatigueStates.erase(guid);
        }
        StopFatigueBar(player);
    }

    // Challenge ended (stop/fail/complete): drop the counter too, so a later
    // re-activation starts from 0.
    void ClearFatigue(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        {
            std::lock_guard<std::mutex> lock(FatigueMutex);
            FatigueStates.erase(guid);
        }
        CharacterDatabase.Execute("DELETE FROM coa_character_fatigue WHERE guid = {}", guid);
        StopFatigueBar(player);
    }

    // Rebuild the tracking state from the DB (login). Loads persisted fatigue.
    void RefreshFatigueTracking(Player* player)
    {
        if (!player)
            return;
        RefreshFatigueTracking(player, LoadActiveChallengeRows(player->GetGUID().GetCounter()));
    }

    void RefreshFatigueTracking(Player* player, std::vector<ActiveChallengeRow> const& rows)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        uint32 found = 0;
        for (ActiveChallengeRow const& row : rows)
            if (IsFatigueChallenge(row.challengeId))
            {
                found = row.challengeId;
                break;
            }
        if (!found)
        {
            ClearFatigue(player);
            return;
        }
        int32 const maxV = (int32)FatigueMax();
        // `fatigue` is the remaining amount; a fresh/stale row starts full.
        int32 fatigue = maxV;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT fatigue FROM coa_character_fatigue WHERE guid = {} AND challengeId = {}",
                guid, found))
        {
            fatigue = r->Fetch()[0].Get<int32>();
            if (fatigue <= 0 || fatigue > maxV)
                fatigue = maxV;
        }
        // Starter zones are sanctuaries (no inn): treated as safe, like a rest area.
        bool resting = player->HasPlayerFlag(PLAYER_FLAGS_RESTING) || player->IsInSanctuary();
        {
            std::lock_guard<std::mutex> lock(FatigueMutex);
            FatigueStates[guid] = FatigueState{ found, fatigue, 0, resting };
        }
        if (resting)
            StopFatigueBar(player);
        else
            SendFatigueBar(player, fatigue);
    }

    // Test helper: force the player's fatigue counter (0..FatigueMax) so the E2E
    // can reach the sleep threshold without waiting the full fill time.
    bool Test_SetFatigue(Player* player, int32 value)
    {
        if (!player)
            return false;
        RefreshFatigueTracking(player);
        uint32 guid = player->GetGUID().GetCounter();
        int32 fatigue = 0;
        {
            std::lock_guard<std::mutex> lock(FatigueMutex);
            auto it = FatigueStates.find(guid);
            if (it == FatigueStates.end())
                return false;
            it->second.fatigue = std::clamp<int32>(value, 0, (int32)FatigueMax());
            it->second.ms = 0;
            fatigue = it->second.fatigue;
        }
        SendFatigueBar(player, fatigue);
        return true;
    }

    void FatigueUpdate(Player* player, uint32 diff)
    {
        uint32 guid = player->GetGUID().GetCounter();
        uint32 cid;
        {
            std::lock_guard<std::mutex> lock(FatigueMutex);
            auto it = FatigueStates.find(guid);
            if (it == FatigueStates.end())
                return;
            cid = it->second.challengeId;
        }
        if (!player->IsAlive() || !player->IsInWorld())
            return;

        uint32 maxV = FatigueMax();
        uint32 perPointMs = std::max<uint32>(1, FatigueFillSeconds() * 1000 / maxV);
        // Safe area = rested (inn/city) or a starter-zone sanctuary.
        bool const safeNow = player->HasPlayerFlag(PLAYER_FLAGS_RESTING) || player->IsInSanctuary();
        // Grace before the bar returns after LEAVING a safe area, so standing at
        // the inn/rest boundary does not flicker it. Entering a safe area applies
        // immediately (delaying the reset could kill the player at the doorstep).
        // ponytail: per-state timer, no timestamp needed.
        uint32 const graceMs =
            sConfigMgr->GetOption<uint32>("CoAChallenges.Fatigue.SafeGraceSeconds", 1) * 1000;

        int32 fatigue = 0;
        bool rested = safeNow;
        bool changed = false, died = false;
        {
            std::lock_guard<std::mutex> lock(FatigueMutex);
            auto it = FatigueStates.find(guid);
            if (it == FatigueStates.end())
                return;
            FatigueState& s = it->second;
            if (safeNow == s.resting)
                s.graceMs = 0;
            else if (safeNow)
            {
                s.resting = true;
                s.graceMs = 0;
                changed = true;
            }
            else if ((s.graceMs += diff) >= graceMs)
            {
                s.resting = false;
                s.graceMs = 0;
                changed = true;
            }
            rested = s.resting;
            if (rested)
            {
                // Safe area (inn/city/starter sanctuary): the bar is off and the
                // counter resets to full, so leaving the safe area starts a fresh
                // drain (mirrors the original, which cleared the counter on rest).
                if (s.fatigue != (int32)maxV)
                {
                    s.fatigue = (int32)maxV;
                    changed = true;
                }
                s.ms = 0;
            }
            else
            {
                // Drain toward empty; reaching 0 means falling asleep (death).
                s.ms += diff;
                while (s.ms >= perPointMs && s.fatigue > 0)
                {
                    s.ms -= perPointMs;
                    s.fatigue -= 1;
                    changed = true;
                }
                if (s.fatigue <= 0)
                    died = true;
            }
            fatigue = s.fatigue;
        }

        if (died)
        {
            {
                std::lock_guard<std::mutex> lock(FatigueMutex);
                auto it = FatigueStates.find(guid);
                if (it != FatigueStates.end()) { it->second.fatigue = 0; it->second.ms = 0; }
            }
            PersistFatigue(guid, cid, 0);
            StopFatigueBar(player);
            LOG_INFO("module.coa_challenges", "{} fell asleep (fatigue drained, challenge {})",
                player->GetName(), cid);
            SetDeathCause(player, KillerKind::Mechanic, 0, "Fell Asleep");
            player->EnvironmentalDamage(DAMAGE_EXHAUSTED, player->GetMaxHealth());
            return;
        }

        if (!changed)
            return;

        if (rested)
        {
            PersistFatigue(guid, cid, fatigue);
            StopFatigueBar(player);
        }
        else
        {
            PersistFatigue(guid, cid, fatigue);
            SendFatigueBar(player, fatigue);
        }
    }
} // namespace CoAChallenges
