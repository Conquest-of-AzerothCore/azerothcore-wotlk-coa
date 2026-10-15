// mod-coa-challenges (review split): core display/broadcast helpers.
// Mechanical split of review-CoAChallenges.cpp; no logic changes.
#include "CoA.Challenges.Review.h"

namespace CoAChallenges
{

/*
 * mod-coa-challenges: challenge-system bridge.
 *
 * Round 1: SMSG_COA_CONFIG (0x58D) flag batch so the game client's
 *   C_Config map is populated (tabs gated on these flags).
 * Round 2: full Activate/Deactivate round-trip + persistence.
 *
 * Wire formats recovered from Extensions.dll:
 *   SMSG 0x58D: u32 n_int,  n_int   x {str,u32},
 *               u32 n_bool, n_bool  x {str,u8},
 *               u32 n_float,n_float x {str,float},
 *               u32 n_rate, n_rate  x {str,float}, then integer-list and
 *               float-list maps (empty counts when unused); str = u32 len + bytes.
 *   This REPLACES all six maps; the CoA collector includes every registered producer.
 *   CMSG 0x592: u32 challengeID, u32 level.            (confirmed live: 188,1)
 *   SMSG 0x593 (CHALLENGE_START_RESPONSE): u32 id, u32 level, u32 code,
 *               u32, u32, u8 + {u32 len, bytes} response string.
 *               code==0 inserts into the client's active cache, fires the
 *               event with "%u%u%s", UI plays the activate sound.
 *               (confirmed live: button -> DEACTIVATE, IsChallengeActive true)
 *   CMSG 0x594: u32 challengeID.
 *   SMSG 0x595 (CHALLENGE_STOP_RESPONSE): same shape as 0x593.
 *   SMSG 0x596 (CHALLENGE_ACTIVE_LIST_CHANGED): u32 n, n x 26-byte entries
 *               {u32 0, u32 id, u32 level, u32 1, u32 0, u32 0, u16 0}.
 *   SMSG 0x5A3 (CHALLENGE_FAILURE_ADDED): ONE failure record; fires with
 *               (challengeID, level) taken from record+0x18/+0x1C.
 *   SMSG 0x5A2 (CHALLENGE_FAILURE_LIST_CHANGED): u32 n + n x failure record
 *               (clears the client list first; n=0 still fires the event).
 *   Failure record (stride 0xEF, reader 0x13F230), wire order:
 *     str, u32 id, u32 level, u32 x5, u8, u8, u32, u8, u32, u32,
 *     float x3, str x6, u32 x4.  (str = u32 len + bytes.)
 */

    // Display name for a challenge (from the world DB, which carries the client
    // export's names). Falls back to the numeric id.
    std::string ChallengeName(uint32 challengeID)
    {
        std::string name = DefField<std::string>(challengeID, &ChallengeDef::name,
            "CoAChallenges.Name." + std::to_string(challengeID), "");
        if (name.empty())
            name = std::to_string(challengeID);
        return name;
    }

    std::string ChallengeIcon(uint32 challengeID)
    {
        return DefField<std::string>(challengeID, &ChallengeDef::icon,
            "CoAChallenges.Icon." + std::to_string(challengeID), "");
    }

    uint32 ChallengeLevelCount(uint32 challengeID)
    {
        return DefField<uint32>(challengeID, &ChallengeDef::levelCount,
            "CoAChallenges.LevelCount." + std::to_string(challengeID), 1);
    }

    // "[Name]" or "[Name (Level N)]" when the challenge has multiple levels,
    // wrapped in a |Htrial:<id>|h link so the client shows the challenge
    // tooltip on hover (confirmed in-client 2026-09-13).
    std::string ChallengeBracket(uint32 challengeID, uint32 level)
    {
        std::string text = (ChallengeLevelCount(challengeID) > 1)
            ? Acore::StringFormat("{} (Level {})", ChallengeName(challengeID), level)
            : ChallengeName(challengeID);
        return Acore::StringFormat("|Htrial:{}|h[{}]|h", challengeID, text);
    }

    // Inline icon tag, 16x16, rendered by the client in chat.
    std::string IconTagFor(std::string icon)
    {
        if (icon.empty())
            return "";
        if (icon.find("Interface\\Icons\\") == std::string::npos)
            icon = "Interface\\Icons\\" + icon;
        return "|T" + icon + ":16:16|t ";
    }

    std::string ChallengeIconTag(uint32 challengeID)
    {
        return IconTagFor(ChallengeIcon(challengeID));
    }

    // Gray [HH:MM] prefix on every announcement, matching the live client's
    // chat timestamp.
    std::string ChatTimestamp()
    {
        return Acore::StringFormat("|cffB2B2B2[{}]|r ",
            Acore::Time::TimeToTimestampStr(GetEpochTime(), "%H:%M"));
    }

    // Class id -> client class token (from the client's
    // CLASS_ENUM_TO_CLASS_FILE + Enum.lua). Used for the class color and the
    // classicon_<token> texture.
    char const* ClassToken(uint8 cls)
    {
        switch (cls)
        {
            case 1:  return "WARRIOR";
            case 2:  return "PALADIN";
            case 3:  return "HUNTER";
            case 4:  return "ROGUE";
            case 5:  return "PRIEST";
            case 6:  return "DEATHKNIGHT";
            case 7:  return "SHAMAN";
            case 8:  return "MAGE";
            case 9:  return "WARLOCK";
            case 10: return "HERO";
            case 11: return "DRUID";
            case 12: return "BARBARIAN";
            case 13: return "WITCHDOCTOR";
            case 14: return "DEMONHUNTER";
            case 15: return "WITCHHUNTER";
            case 16: return "STORMBRINGER";
            case 17: return "FLESHWARDEN";
            case 18: return "GUARDIAN";
            case 19: return "MONK";
            case 20: return "SONOFARUGAL";
            case 21: return "RANGER";
            case 22: return "CHRONOMANCER";
            case 23: return "NECROMANCER";
            case 24: return "PYROMANCER";
            case 25: return "CULTIST";
            case 26: return "STARCALLER";
            case 27: return "SUNCLERIC";
            case 28: return "TINKER";
            case 29: return "PROPHET";
            case 30: return "REAPER";
            case 31: return "WILDWALKER";
            case 32: return "SPIRITMAGE";
            default: return "";
        }
    }

    // Class color by client token, dumped from the live client's
    // RAID_CLASS_COLORS via /coachatdump classcolors (2026-09-13).
    char const* ClassColorForToken(std::string const& token)
    {
        if (token == "WARRIOR")      return "|cffC79C6E";
        if (token == "PALADIN")      return "|cffF58CBA";
        if (token == "HUNTER")       return "|cffABD473";
        if (token == "ROGUE")        return "|cffFFF569";
        if (token == "PRIEST")       return "|cffFFFFFF";
        if (token == "DEATHKNIGHT")  return "|cffC41F3B";
        if (token == "SHAMAN")       return "|cff0070DE";
        if (token == "MAGE")         return "|cff69CCF0";
        if (token == "WARLOCK")      return "|cff9482C9";
        if (token == "DRUID")        return "|cffFF7D0A";
        if (token == "HERO")         return "|cffFFD624";
        if (token == "BARBARIAN")    return "|cff8A3303";
        if (token == "WITCHDOCTOR")  return "|cffF500FF";
        if (token == "DEMONHUNTER")  return "|cff75FA00";
        if (token == "WITCHHUNTER")  return "|cff5433CF";
        if (token == "STORMBRINGER") return "|cff007DED";
        if (token == "FLESHWARDEN")  return "|cffFC0005";
        if (token == "GUARDIAN")     return "|cff9C9482";
        if (token == "MONK")         return "|cffFFFAB3";
        if (token == "SONOFARUGAL")  return "|cffA30000";
        if (token == "RANGER")       return "|cffBFF06B";
        if (token == "PROPHET")      return "|cff6BA600";
        if (token == "CHRONOMANCER") return "|cffFFED4A";
        if (token == "NECROMANCER")  return "|cff45DB9C";
        if (token == "PYROMANCER")   return "|cffFF6112";
        if (token == "CULTIST")      return "|cff9C45F2";
        if (token == "STARCALLER")   return "|cff8FFFFF";
        if (token == "SUNCLERIC")    return "|cffFFB340";
        if (token == "TINKER")       return "|cffD9D9D9";
        if (token == "REAPER")       return "|cff0A876B";
        if (token == "WILDWALKER")   return "|cffE38C59";
        if (token == "SPIRITMAGE")   return "|cff40C7EB";
        return PLAYER_COLOR;
    }

    // Player name with the class icon, the class color, the class name and a
    // clickable inspect link.
    // `klass` = 0 when the class is unknown (offline character): the link still
    // works, just without the class icon/color.
    std::string PlayerNameLink(std::string const& name, uint8 klass)
    {
        std::string token = ClassToken(klass);
        std::string icon;
        if (!token.empty())
        {
            std::string lower = token;
            std::transform(lower.begin(), lower.end(), lower.begin(),
                [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
            icon = "|TInterface\\Icons\\classicon_" + lower + ":16:16|t ";
        }
        std::string link = icon + Acore::StringFormat("|Hplayer:{}|h{}{}|h|r",
            name, ClassColorForToken(token), name);
        if (ChrClassesEntry const* cEntry = sChrClassesStore.LookupEntry(klass))
        {
            if (cEntry->name[0] && *cEntry->name[0])
                link += Acore::StringFormat(" |cffB2B2B2({})|r", cEntry->name[0]);
        }
        return link;
    }

    std::string PlayerNameLink(Player* player)
    {
        return PlayerNameLink(player->GetName(), player->getClass());
    }

    // Realm-wide completion announcement (config-gated).
    // Live format: <icon>[<TrialName>] <Player> has completed their Trial!
    // GM test harness: suppresses the realm-wide announcement broadcasts while
    // a test intentionally drives paths that fail/complete challenges.
    std::atomic<bool> g_testQuiet{ false };
    void Test_SetQuiet(bool quiet) { g_testQuiet = quiet; }

    void AnnounceCompletion(Player* player, uint32 challengeID, uint32 level)
    {
        if (g_testQuiet)
            return;
        if (!sConfigMgr->GetOption<bool>("CoAChallenges.AnnounceCompletion", true))
            return;
        std::string msg = ChatTimestamp() + ChallengeIconTag(challengeID);
        msg += Acore::StringFormat("{}{}|r {} has completed their Trial!",
            TRIAL_COLOR, ChallengeBracket(challengeID, level), PlayerNameLink(player));
        // ChatHandler(nullptr).SendWorldText dereferences a null m_session, so
        // build the system chat packet and broadcast it through the session
        // manager (same path the core uses for world announcements).
        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_SYSTEM, LANG_UNIVERSAL, nullptr, nullptr, msg);
        sWorldSessionMgr->SendGlobalMessage(&data);
    }

    std::mutex PendingFailMutex;
    std::unordered_map<uint32, PendingFail> PendingFailBroadcast; // guid -> pending failure

    std::mutex LastKillerMutex;
    std::unordered_map<uint32, PendingKiller> LastKiller; // guid -> killer of last death

    std::mutex PendingSyncMutex;
    std::unordered_map<uint32, PendingSync> PendingSyncByGuid; // guid -> outstanding group sync
    // Set while a group sync answer (CMSG 0x59C) is being applied, so the
    // re-activation/deactivation does not bounce a fresh 0x59B back to the
    // group (would ping-pong between members).
    std::atomic<bool> g_suppressSyncBroadcast{ false };

    // Record the death cause for a player. Mechanic deaths call this right
    // before applying the lethal damage, so FailChallenge (which runs later on
    // OnPlayerJustDied) reads the correct label.
    void SetDeathCause(Player* player, KillerKind kind, uint32 entry, std::string const& name)
    {
        if (!player)
            return;
        std::lock_guard<std::mutex> lock(LastKillerMutex);
        LastKiller[player->GetGUID().GetCounter()] = PendingKiller{ kind, entry, name };
    }

    // Test helper: label recorded for the player's last death (mechanic causes
    // like "Fell Asleep"/"Starved"); empty when none/unknown. Used by the E2E
    // harness to assert the broadcast cause.
    std::string Test_LastKillerLabel(Player* player)
    {
        if (!player)
            return {};
        std::lock_guard<std::mutex> lock(LastKillerMutex);
        auto it = LastKiller.find(player->GetGUID().GetCounter());
        return it == LastKiller.end() ? std::string() : it->second.name;
    }

    // Test helper: does a cast of `spellId` get blocked by the player's rules
    // (drives the real OnSpellCheckCast dispatcher)? `triggered` models a
    // buff/proc re-trigger (TRIGGERED_FULL_MASK) rather than the player's own cast.
    bool Test_SpellCheckCastBlocked(Player* player, uint32 spellId, bool triggered)
    {
        if (!player)
            return false;
        SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
        if (!info)
            return false;
        Spell spell(player, info, triggered ? TRIGGERED_FULL_MASK : TRIGGERED_NONE);
        return spell.CheckCast(true) != SPELL_CAST_OK;
    }

    // Live format: <icon>[<TrialName>] <Player> (Level N) has been killed by <killer>.
    //   creature/player killer -> red, bracketed, clickable (3D model / inspect)
    //   special cause (Falling/Suicide/Unknown) -> red, plain, no brackets
    // The creature link is |Hcreature:<entry>|h: the client's handler calls
    // DressUpCreature -> SetDisplayInfo, which Model.lua overrides to
    // Creature:CreateFromID(entry) + SetCreature(entry).
    void AnnounceFailure(std::string const& name, uint32 level, PendingFail const& fail, uint8 klass)
    {
        if (g_testQuiet)
            return;
        if (!sConfigMgr->GetOption<bool>("CoAChallenges.AnnounceFailure", true))
            return;
        // Mechanic deaths (starved, missed objective, fell asleep) are NOT
        // announced by the official server; gated by a config.
        if (fail.killerKind == KillerKind::Mechanic
            && !sConfigMgr->GetOption<bool>("CoAChallenges.AnnounceMechanicFailures", true))
            return;
        // The official only announces from level 10 up.
        uint32 minLevel = sConfigMgr->GetOption<uint32>("CoAChallenges.AnnounceFailureMinLevel", 10);
        if (level < minLevel)
        {
            LOG_INFO("module.coa_challenges", "Failure broadcast suppressed for {} (level {} < {})",
                name, level, minLevel);
            return;
        }

        std::string msg = ChatTimestamp();
        if (!fail.displayName.empty())
            msg += IconTagFor(fail.displayIcon);
        else
            msg += ChallengeIconTag(fail.challengeID);

        std::string bracket = !fail.displayName.empty()
            ? Acore::StringFormat("{}[{}]|r", TRIAL_COLOR, fail.displayName)
            : Acore::StringFormat("{}{}|r", TRIAL_COLOR, ChallengeBracket(fail.challengeID, fail.level));

        // A rule failure (e.g. FAILABLE_NO_KILL_BEASTS) is not a death: the
        // player failed the trial by slaying a forbidden creature.
        bool const slaying = (fail.killerKind == KillerKind::Rule);
        msg += Acore::StringFormat("{} {} (Level {}) {} ",
            bracket, PlayerNameLink(name, klass), level,
            slaying ? "has failed the challenge by slaying" : "has been killed by");

        if (fail.killerKind == KillerKind::Creature || fail.killerKind == KillerKind::Rule)
            msg += Acore::StringFormat("{}|Hcreature:{}|h[{}]|h|r.",
                KILLER_COLOR, fail.killerEntry, fail.killerName);
        else if (fail.killerKind == KillerKind::Player)
            msg += Acore::StringFormat("{}|Hplayer:{}|h[{}]|h|r.",
                KILLER_COLOR, fail.killerName, fail.killerName);
        else if (fail.killerKind == KillerKind::Mechanic)
        {
            // Link the cause to the challenge's aura so hovering explains it.
            std::string label = fail.killerName.empty() ? "Unknown" : fail.killerName;
            std::string aura = sConfigMgr->GetOption<std::string>(
                "CoAChallenges.Spell." + std::to_string(fail.challengeID), "");
            if (!aura.empty())
                msg += Acore::StringFormat("{}|Hspell:{}|h{}|h|r.", KILLER_COLOR, aura, label);
            else
                msg += Acore::StringFormat("{}{}|r.", KILLER_COLOR, label);
        }
        else
            msg += Acore::StringFormat("{}{}|r.",
                KILLER_COLOR, fail.killerName.empty() ? "Unknown" : fail.killerName);

        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_SYSTEM, LANG_UNIVERSAL, nullptr, nullptr, msg);
        sWorldSessionMgr->SendGlobalMessage(&data);
        LOG_INFO("module.coa_challenges", "Failure broadcast for {} (challenge {}): {}",
            name, fail.challengeID, msg);
    }

    // Called each world tick: broadcast and clear pending failures (by now the
    // killer, if the player was killed by a creature/player, has been captured).
    void FlushFailureBroadcasts()
    {
        std::vector<std::pair<ObjectGuid, PendingFail>> sends;
        {
            std::lock_guard<std::mutex> lock(PendingFailMutex);
            for (auto it = PendingFailBroadcast.begin(); it != PendingFailBroadcast.end();)
            {
                sends.emplace_back(ObjectGuid::Create<HighGuid::Player>(it->first), it->second);
                it = PendingFailBroadcast.erase(it);
            }
        }
        for (auto& [guid, fail] : sends)
        {
            if (Player* p = ObjectAccessor::FindPlayer(guid))
            {
                AnnounceFailure(p->GetName(), p->GetLevel(), fail, p->getClass());
                continue;
            }
            // Offline SharedFate partner: announce from the character cache.
            std::string name;
            if (!sCharacterCache->GetCharacterNameByGuid(guid, name) || name.empty())
                continue;
            AnnounceFailure(name, sCharacterCache->GetCharacterLevelByGuid(guid), fail, 0);
        }
    }

    // GM test harness: drop pending failure broadcasts without announcing them,
    // so the next world tick does not leak a realm-wide banner after a test
    // that intentionally failed a challenge (the announce is deferred).
    void Test_ClearPendingFailures()
    {
        std::lock_guard<std::mutex> lock(PendingFailMutex);
        PendingFailBroadcast.clear();
    }

    void AppendConfigString(WorldPacket& data, std::string const& key)
    {
        data << uint32(key.size());
        if (!key.empty())
            data.append(reinterpret_cast<uint8 const*>(key.data()), key.size());
    }

    std::string HexDump(WorldPacket const& packet)
    {
        std::string out;
        out.reserve(packet.size() * 3);
        char buf[4];
        for (uint32 i = 0; i < packet.size(); ++i)
        {
            snprintf(buf, sizeof(buf), "%02X ", packet.read<uint8>(i));
            out += buf;
        }
        return out;
    }
} // namespace CoAChallenges
