// mod-coa-challenges (review split): CoA.Challenges.GameModes.cpp
// Mechanical split of review-CoAChallenges.cpp; no logic changes.
#include "CoA.Challenges.Review.h"

namespace CoAChallenges
{

    GameModeDef const* FindGameMode(std::string const& name)
    {
        for (GameModeDef const& m : GameModes)
            if (name == m.name)
                return &m;
        return nullptr;
    }

    char const* GameModeNameForBit(uint32 bit)
    {
        for (GameModeDef const& m : GameModes)
            if (m.bit == bit)
                return m.name;
        return "game mode";
    }

    bool GameModesEnabled()
    {
        return sConfigMgr->GetOption<bool>("CoAChallenges.GameModes.Enable", true);
    }

    // Modes every character on this realm plays, from CoAChallenges.GameModes.Realm (e.g. WildCard on a
    // Wildcard realm). The recompute ORs them in, so no trial, toggle or relog drops them.
    uint32 RealmGameModeMask()
    {
        uint32 mask = 0;
        for (std::string name : CoAParse::Split(
                 sConfigMgr->GetOption<std::string>("CoAChallenges.GameModes.Realm", ""), ','))
        {
            name.erase(0, name.find_first_not_of(" \t\r\n"));
            name.erase(name.find_last_not_of(" \t\r\n") + 1);
            if (GameModeDef const* mode = FindGameMode(name))
                mask |= mode->bit;
        }
        return mask;
    }

    // Whether a mode row should be hidden on the client (CONFIG_*_HIDDEN). The
    // default hides the modes the server does not run yet (no base challenge and
    // no special handler); override with a comma-separated wire-name list.
    bool GameModeHidden(char const* name)
    {
        if (!name)
            return false;
        std::string const list = sConfigMgr->GetOption<std::string>(
            "CoAChallenges.GameModes.Hidden",
            "Draft,Resolute,WildCard,Felforged,BuildDraft,Crusader");
        size_t pos = 0;
        while (pos <= list.size())
        {
            size_t const comma = list.find(',', pos);
            std::string token = list.substr(pos,
                comma == std::string::npos ? std::string::npos : comma - pos);
            size_t const b = token.find_first_not_of(" \t\r\n");
            size_t const e = token.find_last_not_of(" \t\r\n");
            if (b != std::string::npos && token.substr(b, e - b + 1) == name)
                return true;
            if (comma == std::string::npos)
                break;
            pos = comma + 1;
        }
        return false;
    }

    // Game mode -> base challenge: the trial that "is" the mode, derived from
    // RequiredGameMode.<id> (e.g. 61 -> Nightmare 0x100, 50 -> Ironman 0x2). The
    // mode reuses that trial's generated Spell/Rules/Lives, so a mode turned on
    // globally behaves like its trial without a coa_character_challenge row.
    std::unordered_map<uint32, uint32> GameModeBase;   // bit -> challengeId
    // Guards GameModeBase: LoadChallengeDefinitions -> BuildGameModeBaseMap can
    // run on a map thread (.coa challenges reload) while other maps are ticking.
    static std::mutex GameModeBaseMutex;

    void BuildGameModeBaseMap()
    {
        // Build into a local map under DefMutex, then swap under the base lock so
        // readers never observe a half-cleared/rehashed map.
        std::unordered_map<uint32, uint32> fresh;
        {
            std::lock_guard<std::mutex> lock(DefMutex);
            for (auto const& [cid, d] : DefCache)
                if (d.requiredGameMode && fresh.find(d.requiredGameMode) == fresh.end())
                    fresh[d.requiredGameMode] = cid;
        }
        size_t entries = 0;
        {
            std::lock_guard<std::mutex> lock(GameModeBaseMutex);
            GameModeBase.swap(fresh);
            entries = GameModeBase.size();
        }
        LOG_INFO("module.coa_challenges", "Game mode -> base challenge map: {} entries",
            entries);
    }

    uint32 GameModeBaseForBit(uint32 bit)
    {
        std::lock_guard<std::mutex> lock(GameModeBaseMutex);
        auto it = GameModeBase.find(bit);
        return it == GameModeBase.end() ? 0 : it->second;
    }

    // Snapshot for callers that need to iterate (never iterate the live map).
    std::unordered_map<uint32, uint32> GameModeBaseSnapshot()
    {
        std::lock_guard<std::mutex> lock(GameModeBaseMutex);
        return GameModeBase;
    }

    // In-memory mirror of coa_character_gamemode, so PlayerHasRule (called very
    // often) can OR the mode's rules without a DB query each call.
    std::mutex GameModeMaskMutex;
    std::unordered_map<uint32, uint32> GameModeMaskCache;
    // TOCTOU guard, same scheme as CharChallengeGeneration (CoA.Challenges.Lifecycle.cpp): a single
    // monotonic counter bumped under GameModeMaskMutex on every invalidation (save or clear), so an
    // in-flight load that started before the bump does not publish a stale mask.
    static uint64 GameModeMaskGeneration = 0;

    // Test seam (`.coa cachetoctou`): runs between the DB load and the cache publish.
    std::function<void(uint32)> GameModeLoadHookForTest;
    std::mutex GameModeHookMutex;
    void Test_SetGameModeLoadHook(std::function<void(uint32)> hook)
    {
        std::lock_guard<std::mutex> lock(GameModeHookMutex);
        GameModeLoadHookForTest = std::move(hook);
    }
    // Bits the player enabled from the Gamemodes tab (only while
    // GameModes.PlayerToggle is on). RecomputeRequiredGameModes ORs these in so a
    // trial-driven recompute does not silently clear a player-toggled mode.
    // Guarded by GameModeMaskMutex.
    static std::unordered_map<uint32, uint32> PlayerToggleMask;

    uint32 PlayerToggleMaskFor(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(GameModeMaskMutex);
        auto it = PlayerToggleMask.find(guid);
        return it == PlayerToggleMask.end() ? 0 : it->second;
    }

    void ClearPlayerToggleBit(uint32 guid, uint32 bit)
    {
        std::lock_guard<std::mutex> lock(GameModeMaskMutex);
        auto it = PlayerToggleMask.find(guid);
        if (it != PlayerToggleMask.end())
            it->second &= ~bit;
    }

    uint32 LoadGameModeMask(uint32 guid)
    {
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT gameMode FROM coa_character_gamemode WHERE guid = {}", guid))
            return r->Fetch()[0].Get<uint32>();
        return 0;
    }

    uint32 CachedGameModeMask(uint32 guid)
    {
        for (;;)
        {
            uint64 generation = 0;
            bool guard = false;
            {
                std::lock_guard<std::mutex> lock(GameModeMaskMutex);
                auto it = GameModeMaskCache.find(guid);
                if (it != GameModeMaskCache.end())
                    return it->second;
                guard = CacheGenerationGuardEnabled();
                if (guard)
                    generation = GameModeMaskGeneration;
            }

            uint32 mask = LoadGameModeMask(guid);
            {
                // Copy the hook under its own mutex; invoke after unlocking so its Clear* call,
                // which takes GameModeMaskMutex, cannot deadlock.
                std::function<void(uint32)> hook;
                {
                    std::lock_guard<std::mutex> lock(GameModeHookMutex);
                    hook = GameModeLoadHookForTest;
                }
                if (hook)
                    hook(guid);
            }

            std::lock_guard<std::mutex> lock(GameModeMaskMutex);
            // The stored mask changed while we were loading: the snapshot is stale, reload.
            if (guard && GameModeMaskGeneration != generation)
                continue;
            GameModeMaskCache[guid] = mask;
            return mask;
        }
    }

    void ClearGameModeMaskCache(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(GameModeMaskMutex);
        GameModeMaskCache.erase(guid);
        PlayerToggleMask.erase(guid);
        ++GameModeMaskGeneration;
    }

    // Apply/remove the base challenge's aura for the bits that changed. The
    // trial path also applies it (idempotent); this covers mode-on-without-trial
    // and keeps the aura in sync with the mask.
    void ApplyGameModeSpells(Player* player, uint32 oldMask, uint32 newMask)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        for (auto const& [bit, base] : GameModeBaseSnapshot())
        {
            bool was = (oldMask & bit) != 0;
            bool now = (newMask & bit) != 0;
            if (now && !was)
            {
                ApplyChallengeSpell(player, base);
                // Lives only apply when the base trial is NOT the source (a
                // trial tracks its own lives); otherwise the mode would double.
                if (!ActiveChallenges(guid).count(base))
                    TrackModeLives(player, bit);
            }
            else if (was && !now)
            {
                RemoveChallengeSpell(player, base);
                UntrackModeLives(player, bit);
            }

            // Survivalist runs the hunger/thirst system globally, independent of
            // whether the base challenge row is active. Handled here (not only in
            // ApplyGameModeToggle) so a trial-driven recompute that clears the bit
            // also stops hunger instead of leaving it running forever.
            if (bit == GAMEMODE_SURVIVALIST)
            {
                if (now && !was)
                    TrackSurvivalist(player);
                else if (was && !now)
                    RemoveHungerChallenge(player, SURVIVALIST_HUNGER_ID);
            }
        }
    }

    void SaveGameModeMask(uint32 guid, uint32 mask)
    {
        CharacterDatabase.Execute(
            "REPLACE INTO coa_character_gamemode (guid, gameMode) VALUES ({}, {})", guid, mask);
        std::lock_guard<std::mutex> lock(GameModeMaskMutex);
        GameModeMaskCache[guid] = mask;
        // Drop any in-flight load: it read the pre-write mask and must not overwrite this one.
        ++GameModeMaskGeneration;
    }

    // NOTE: pass the mask explicitly after a toggle — SaveGameModeMask uses the
    // async CharacterDatabase.Execute, so re-querying here would race the write
    // and push a stale value (the classic async-DB gotcha).
    void SendGameModeState(Player* player, uint32 mask)
    {
        WorldSession* session = player ? player->GetSession() : nullptr;
        if (!session)
            return;

        WorldPacket data(SMSG_COA_GAME_MODE_STATE, 4);
        data << uint32(mask);
        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x90B GAME_MODE_STATE to {}: mask=0x{:X}",
            player->GetName(), mask);
    }

    void SendGameModeToggleResult(Player* player, std::string const& response)
    {
        WorldSession* session = player ? player->GetSession() : nullptr;
        if (!session)
            return;

        WorldPacket data(SMSG_COA_GAME_MODE_TOGGLE_RESULT, response.size() + 4);
        data << uint32(response.size());
        if (!response.empty())
            data.append(reinterpret_cast<uint8 const*>(response.data()), response.size());
        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x5A5 GAME_MODE_TOGGLE_RESULT to {}: {}",
            player->GetName(), response);
    }

    void ApplyGameModeToggle(Player* player, GameModeDef const* mode, bool enable);

    void HandleToggleGameMode(Player* player, WorldPacket const& packet)
    {
        if (!player)
            return;

        // Modes are trial-driven; the client rows are locked (CONFIG_*_ENABLE=0)
        // so this normally never fires. Ignore player attempts unless enabled.
        if (!sConfigMgr->GetOption<bool>("CoAChallenges.GameModes.PlayerToggle", false))
        {
            LOG_INFO("module.coa_challenges",
                "CMSG 0x5A4 TOGGLE_GAME_MODE from {} ignored (player toggling disabled)",
                player->GetName());
            return;
        }

        // u32 len, len bytes modeName, u8 enable
        if (packet.size() < 5)
        {
            LOG_WARN("module.coa_challenges", "CMSG 0x5A4 TOGGLE_GAME_MODE: short payload ({} bytes)",
                packet.size());
            return;
        }

        uint32 len = packet.read<uint32>(0);
        if (len > packet.size() - 5)
        {
            LOG_WARN("module.coa_challenges", "CMSG 0x5A4 TOGGLE_GAME_MODE: bad name length {} (payload {} bytes)",
                len, packet.size());
            return;
        }

        std::string name(reinterpret_cast<char const*>(packet.contents() + 4), len);
        uint8 enable = packet.read<uint8>(4 + len);

        GameModeDef const* mode = FindGameMode(name);
        if (!mode)
        {
            LOG_INFO("module.coa_challenges", "CMSG 0x5A4 TOGGLE_GAME_MODE from {}: unknown mode '{}'",
                player->GetName(), name);
            SendGameModeToggleResult(player, "GAME_MODE_NOT_ALLOWED");
            return;
        }

        ApplyGameModeToggle(player, mode, enable != 0);
    }

    // Shared by the CMSG handler and the `.coa gamemode` GM command.
    void ApplyGameModeToggle(Player* player, GameModeDef const* mode, bool enable)
    {
        if (!player || !mode)
            return;

        uint32 guid = player->GetGUID().GetCounter();
        uint32 mask = CachedGameModeMask(guid);
        uint32 oldMask = mask;
        bool active = (mask & mode->bit) != 0;

        if (!GameModesEnabled())
        {
            SendGameModeToggleResult(player, std::string(mode->response) + "_DISABLED");
            return;
        }

        if (enable == active)
        {
            SendGameModeToggleResult(player, std::string(mode->response)
                + (enable ? "_ALREADY_ACTIVE" : "_ALREADY_INACTIVE"));
            SendGameModeState(player, mask);
            return;
        }

        if (enable)
            mask |= mode->bit;
        else
            mask &= ~mode->bit;
        // Remember the player's own choice so RecomputeRequiredGameModes (login,
        // activate/stop) does not clear it.
        {
            std::lock_guard<std::mutex> lock(GameModeMaskMutex);
            uint32& toggled = PlayerToggleMask[guid];
            if (enable)
                toggled |= mode->bit;
            else
                toggled &= ~mode->bit;
        }
        // Save/cache the new mask before applying: RemoveChallengeSpell reads
        // CachedGameModeMask to decide which mode auras are still live.
        SaveGameModeMask(guid, mask);
        ApplyGameModeSpells(player, oldMask, mask);

        LOG_INFO("module.coa_challenges", "Game mode {} {} for {} -> mask=0x{:X}",
            mode->name, enable ? "on" : "off", player->GetName(), mask);

        SendGameModeToggleResult(player, std::string(mode->response) + "_OK");
        SendGameModeState(player, mask);
    }

    uint32 LoadModeDeaths(uint32 guid, uint32 bit)
    {
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT deaths FROM coa_character_gamemode_lives WHERE guid = {} AND gameMode = {}",
                guid, bit))
            return r->Fetch()[0].Get<uint32>();
        return 0;
    }

    // Synchronous: the next death reads this with LoadModeDeaths, so an async
    // write could be missed and undercount the deaths (mode never fails).
    void SaveModeDeaths(uint32 guid, uint32 bit, uint32 deaths)
    {
        CharacterDatabase.DirectExecute(
            "REPLACE INTO coa_character_gamemode_lives (guid, gameMode, deaths) VALUES ({}, {}, {})",
            guid, bit, deaths);
    }

    void ClearModeDeaths(uint32 guid, uint32 bit)
    {
        CharacterDatabase.DirectExecute(
            "DELETE FROM coa_character_gamemode_lives WHERE guid = {} AND gameMode = {}", guid, bit);
    }

    // Mode entered (bit on, base not an active challenge): fresh lives + aura.
    void TrackModeLives(Player* player, uint32 bit)
    {
        if (!player)
            return;
        uint32 base = GameModeBaseForBit(bit);
        uint32 lives = base ? LivesTotal(base) : 0;
        if (!lives)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        ClearModeDeaths(guid, bit);
        LOG_INFO("module.coa_challenges", "Mode 0x{:X} lives started for {} ({} lives)",
            bit, player->GetName(), lives);
    }

    void UntrackModeLives(Player* player, uint32 bit)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        ClearModeDeaths(guid, bit);
    }

    // Re-apply a mode's base aura + lives counter after relog/resurrect WITHOUT
    // resetting the death count (unlike a fresh enable).
    void ReapplyGameModeBehavior(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        uint32 mask = CachedGameModeMask(guid);
        for (auto const& [bit, base] : GameModeBaseSnapshot())
        {
            if (!(mask & bit))
                continue;
            ApplyChallengeSpell(player, base);
        }
    }
} // namespace CoAChallenges
