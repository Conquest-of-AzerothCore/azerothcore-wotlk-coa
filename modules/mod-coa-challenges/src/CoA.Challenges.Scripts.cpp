// mod-coa-challenges (review split): CoA.Challenges.Scripts.cpp
// Mechanical split of review-CoAChallenges.cpp; no logic changes.
#include "CoA.Challenges.Review.h"
#include "RBAC.h"
#include "KillRewarder.h"
#include "Random.h"
#include "AllCreatureScript.h"
#include "AccountScript.h"
#include "LocalLevelScaling.h"

using namespace Acore::ChatCommands;

namespace CoAChallenges
{

    bool UsesCoreProfessionXP(Player* player)
    {
        return player && ActiveChallenges(player->GetGUID().GetCounter()).contains(167);
    }

    // Heal-path helpers (defined below, used by HealBlocked earlier in this TU).
    void AllowBandageHeal(uint32 guid);
    bool ConsumeBandageAllow(uint32 guid);

    // ---- Spellbind Roulette -------------------------------------------------
    // FAILABLE_SPELLBIND_ROULETTE (173/174/175/387/388/389; 30s) and
    // FAILABLE_MEGA_SPELLBIND_ROULETTE (429/430; 3s) periodically mark one of
    // the player's known spells; casting it fails the challenge. Plain
    // SPELLBIND_ROULETTE (193) only blocks the cast. Server-side functional
    // implementation; the client's "Marked for Death" visual needs client RE.
    struct SpellbindMark
    {
        uint32 challengeId = 0;
        uint32 level = 0;
        uint32 spellId = 0;
        std::string name;       // display name; the cast may be a sibling id
        uint32 ms = 0;
        uint32 intervalMs = 30000;
        bool failable = true;
        // PickRandomKnownSpell returned 0 (no markable ability yet). Without
        // this the !spellId check would rescan the whole spell map every tick.
        bool noEligible = false;
    };

    std::mutex SpellbindMutex;
    std::unordered_map<uint32, SpellbindMark> SpellbindState;

    // Mark death queued from the spell CheckCast hook and applied on the
    // player's next update, so no world mutation happens inside Spell::CheckCast.
    struct SpellbindPendingKill
    {
        uint32 challengeId = 0;
        uint32 level = 0;
        uint32 deaths = 0;
        std::string name;
    };
    std::unordered_map<uint32, SpellbindPendingKill> SpellbindPendingKills;

    void SpellbindClear(uint32 guid);
    void SendSpellActivationShow(Player* player, uint32 spellId);
    void SendSpellActivationHide(Player* player, uint32 spellId);

    bool SpellbindActiveFor(Player* player, uint32& challengeId, uint32& level,
        uint32& intervalMs, bool& failable)
    {
        level = 0;
        if (uint32 cid = ActiveChallengeWithRule(player, "CHALLENGE_RULES_TYPE_FAILABLE_MEGA_SPELLBIND_ROULETTE", level))
        { challengeId = cid; intervalMs = 3000; failable = true; return true; }
        if (uint32 cid = ActiveChallengeWithRule(player, "CHALLENGE_RULES_TYPE_FAILABLE_SPELLBIND_ROULETTE", level))
        { challengeId = cid; intervalMs = 30000; failable = true; return true; }
        if (uint32 cid = ActiveChallengeWithRule(player, "CHALLENGE_RULES_TYPE_SPELLBIND_ROULETTE", level))
        { challengeId = cid; intervalMs = 30000; failable = false; return true; }
        return false;
    }

    // Real, markable class ability: the spell maps to a skill line whose
    // category is CLASS and which is not one of Ascension's collections
    // (Mounts/Companions/Vanity, all tagged CLASS). This drops the general junk
    // (Opening/Closing, Auto Attack, Duel, Stuck, Wildcard Mount, mode toggles,
    // ...) which have no CLASS skill line.
    static bool IsMarkableClassAbility(uint32 spellId)
    {
        SkillLineAbilityMapBounds bounds = sSpellMgr->GetSkillLineAbilityMapBounds(spellId);
        for (auto it = bounds.first; it != bounds.second; ++it)
        {
            SkillLineEntry const* sl = sSkillLineStore.LookupEntry(it->second->SkillLine);
            if (!sl || sl->categoryId != SKILL_CATEGORY_CLASS)
                continue;
            std::string const nm = sl->name[0] ? sl->name[0] : "";
            if (nm.find("Mount") != std::string::npos
                || nm.find("Companion") != std::string::npos
                || nm.find("Vanity") != std::string::npos
                || nm.find("Collection") != std::string::npos
                || nm.find("Toy") != std::string::npos
                || nm.find("Pet") != std::string::npos
                || (!nm.empty() && nm[0] == '!'))
                continue;
            return true;
        }
        return false;
    }

    // Markable ability = a usable ability that deals damage, heals, buffs or
    // moves the player. Everything else (resource/utility like "Sanity Tap",
    // auto-attack, open/close/door, mounts, companions, ...) is skipped. Mounts
    // and companion summons are pre-excluded.
    static bool IsMarkableAbility(SpellInfo const* info)
    {
        if (!info || info->IsPassive())
            return false;

        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
        {
            if (info->Effects[i].ApplyAuraName == SPELL_AURA_MOUNTED)
                return false;
            if (info->Effects[i].Effect == SPELL_EFFECT_SUMMON)
            {
                if (CreatureTemplate const* ct = sObjectMgr->GetCreatureTemplate(uint32(info->Effects[i].MiscValue)))
                    if (ct->type == CREATURE_TYPE_NON_COMBAT_PET || ct->type == CREATURE_TYPE_CRITTER)
                        return false;
            }
        }

        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
        {
            switch (info->Effects[i].Effect)
            {
                case SPELL_EFFECT_SCHOOL_DAMAGE:
                case SPELL_EFFECT_WEAPON_DAMAGE:
                case SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL:
                case SPELL_EFFECT_WEAPON_PERCENT_DAMAGE:
                case SPELL_EFFECT_NORMALIZED_WEAPON_DMG:
                case SPELL_EFFECT_HEAL:
                case SPELL_EFFECT_HEAL_MAX_HEALTH:
                case SPELL_EFFECT_CHARGE:
                case SPELL_EFFECT_CHARGE_DEST:
                case SPELL_EFFECT_JUMP:
                case SPELL_EFFECT_JUMP_DEST:
                case SPELL_EFFECT_LEAP:
                case SPELL_EFFECT_LEAP_BACK:
                    return true;
                case SPELL_EFFECT_APPLY_AURA:
                case SPELL_EFFECT_APPLY_AREA_AURA_PARTY:
                case SPELL_EFFECT_APPLY_AREA_AURA_RAID:
                case SPELL_EFFECT_APPLY_AREA_AURA_FRIEND:
                    if (info->IsPositiveEffect(i))
                        return true;    // buff / HoT
                    switch (info->Effects[i].ApplyAuraName)
                    {
                        case SPELL_AURA_PERIODIC_DAMAGE:
                        case SPELL_AURA_PERIODIC_DAMAGE_PERCENT:
                        case SPELL_AURA_PERIODIC_LEECH:
                        case SPELL_AURA_PERIODIC_HEAL:
                        case SPELL_AURA_PERIODIC_HEALTH_FUNNEL:
                        case SPELL_AURA_MOD_INCREASE_SPEED:
                        case SPELL_AURA_MOD_SPEED_ALWAYS:
                            return true;    // DoT / movement
                        default:
                            break;
                    }
                    break;
                default:
                    break;
            }
        }
        return false;
    }

    uint32 PickRandomKnownSpell(Player* player)
    {
        // Deduplicate by display name: Ascension abilities have several internal
        // spell ids with the same name (e.g. "Darkslayer"); keeping the lowest
        // id avoids over-weighting those variants.
        std::map<std::string, uint32> byName;
        for (auto const& itr : player->GetSpellMap())
        {
            PlayerSpell const* ps = itr.second;
            if (!ps || ps->State == PLAYERSPELL_REMOVED || !ps->Active)
                continue;
            SpellInfo const* info = sSpellMgr->GetSpellInfo(itr.first);
            if (!info || !IsMarkableAbility(info))
                continue;
            if (!IsMarkableClassAbility(itr.first))
                continue;
            std::string const nm = info->SpellName[0] ? info->SpellName[0] : std::to_string(itr.first);
            // Auto-repeat abilities ("Auto Attack", "Auto Shot", ...) are not
            // part of the roulette.
            if (nm.rfind("Auto ", 0) == 0)
                continue;
            auto it = byName.find(nm);
            if (it == byName.end() || itr.first < it->second)
                byName[nm] = itr.first;
        }
        std::vector<uint32> ids;
        ids.reserve(byName.size());
        for (auto const& kv : byName)
            ids.push_back(kv.second);
        if (ids.empty())
            return 0;
        std::string list;
        for (uint32 id : ids)
        {
            SpellInfo const* si = sSpellMgr->GetSpellInfo(id);
            list += std::to_string(id);
            list += "(";
            list += (si && si->SpellName[0]) ? si->SpellName[0] : "?";
            list += ") ";
        }
        LOG_INFO("module.coa_challenges", "Spellbind: {} eligible abilities = {}: {}",
            player->GetName(), ids.size(), list);
        return ids[urand(0, uint32(ids.size()) - 1)];
    }

    // Rebuild from the DB (login / activation): adds or removes the tracker.
    void RefreshSpellbindTracking(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        uint32 cid = 0, level = 0, interval = 0;
        bool failable = true;
        if (!SpellbindActiveFor(player, cid, level, interval, failable))
        {
            SpellbindClear(guid);
            return;
        }
        std::lock_guard<std::mutex> lock(SpellbindMutex);
        SpellbindMark& m = SpellbindState[guid];
        m.challengeId = cid; m.level = level; m.intervalMs = interval;
        m.failable = failable; m.ms = 0; m.spellId = 0;
    }

    // Called on activation with the challenge just started.
    void TrackSpellbind(Player* player, uint32 challengeID)
    {
        if (!player)
            return;
        std::string rules = ChallengeRules(challengeID);
        if (!RuleListContains(rules, "CHALLENGE_RULES_TYPE_SPELLBIND_ROULETTE")
            && !RuleListContains(rules, "CHALLENGE_RULES_TYPE_FAILABLE_SPELLBIND_ROULETTE")
            && !RuleListContains(rules, "CHALLENGE_RULES_TYPE_FAILABLE_MEGA_SPELLBIND_ROULETTE"))
            return;
        RefreshSpellbindTracking(player);
    }

    void UntrackSpellbind(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        uint32 spell = 0;
        {
            std::lock_guard<std::mutex> lock(SpellbindMutex);
            auto it = SpellbindState.find(guid);
            if (it != SpellbindState.end())
                spell = it->second.spellId;
        }
        if (spell)
            SendSpellActivationHide(player, spell);
        SpellbindClear(guid);
    }

    void SpellbindUpdate(Player* player, uint32 diff)
    {
        uint32 guid = player->GetGUID().GetCounter();
        uint32 newMark = 0;
        uint32 oldMark = 0;
        {
            std::lock_guard<std::mutex> lock(SpellbindMutex);
            auto it = SpellbindState.find(guid);
            if (it == SpellbindState.end())
                return;
            SpellbindMark& m = it->second;
            m.ms += diff;
            if (m.ms >= m.intervalMs || (!m.spellId && !m.noEligible))
            {
                m.ms = 0;
                oldMark = m.spellId;
                m.spellId = PickRandomKnownSpell(player);
                m.noEligible = (m.spellId == 0);
                SpellInfo const* si = m.spellId ? sSpellMgr->GetSpellInfo(m.spellId) : nullptr;
                m.name = (si && si->SpellName[0]) ? si->SpellName[0] : "";
                newMark = m.spellId;
            }
        }
        if (oldMark && oldMark != newMark)
            SendSpellActivationHide(player, oldMark);
        if (newMark)
        {
            SpellInfo const* markInfo = sSpellMgr->GetSpellInfo(newMark);
            LOG_INFO("module.coa_challenges", "Spellbind: {} marked spell {} ({})",
                player->GetName(), newMark, markInfo ? markInfo->SpellName[0] : "?");
            // The mark itself is always applied; the on-screen warning is
            // silenced while the GM test harness runs (only PASS/FAIL lines).
            if (markInfo && markInfo->SpellName[0] && !g_testQuiet)
            {
                // Ascension rotates these 10 warning phrases; the spell name is
                // a red spell link, shown big on screen + in chat.
                static char const* const kWarnings[] = {
                    "A new spell is bound by the roulette! {} is now a forbidden incantation.",
                    "A dire warning: {} is now ensnared by the curse - cast it at your own peril.",
                    "The curse has moved! {} is now perilous to cast - heed the warning.",
                    "The roulette of fate has chosen its next victim: {}. Cast it not, lest death be your reward.",
                    "The curse has found a new host! {} is now lethal to cast - heed this omen.",
                    "Beware, traveler! The spell {} is now forbidden - cast it not, lest you perish.",
                    "A new spell is bound by fate! Avoid casting {}, or meet your doom.",
                    "The forbidden seal has shifted! {} is now a spell of certain demise.",
                    "The roulette has spun! Casting {} is now a fatal gamble.",
                    "The winds of fate have changed! {} is now deadly to invoke.",
                };
                std::string const link = "|cffff0000|Hspell:" + std::to_string(newMark)
                    + "|h[" + markInfo->SpellName[0] + "]|h|r";
                std::string const msg = Acore::StringFormat(kWarnings[urand(0, 9)], link);
                // Big gold on-screen text + chat line = CHAT_MSG_RAID_BOSS_EMOTE
                // (SendNotification/UIErrorsFrame is small and red).
                WorldPacket data;
                ChatHandler::BuildChatPacket(data, CHAT_MSG_RAID_BOSS_EMOTE, LANG_UNIVERSAL,
                    nullptr, nullptr, msg);
                player->GetSession()->SendPacket(&data);
            }
            SendSpellActivationShow(player, newMark);
        }
    }

    // If `spellId` is the player's current mark, copies it to `out` and returns
    // true. The mark is only cleared when `consume` is true: the plain
    // SPELLBIND_ROULETTE merely blocks the cast, so its mark must persist until
    // the interval rerolls it (otherwise the player could reroll it at will).
    bool SpellbindConsumeMark(uint32 guid, uint32 spellId, SpellbindMark& out, bool consume)
    {
        // A sibling spell id with the same display name counts (Ascension
        // abilities like "Darkslayer" have several internal ids).
        SpellInfo const* castInfo = sSpellMgr->GetSpellInfo(spellId);
        std::string const castName = (castInfo && castInfo->SpellName[0]) ? castInfo->SpellName[0] : "";
        std::lock_guard<std::mutex> lock(SpellbindMutex);
        auto it = SpellbindState.find(guid);
        if (it == SpellbindState.end() || !it->second.spellId)
            return false;
        bool const match = (it->second.spellId == spellId)
            || (!it->second.name.empty() && it->second.name == castName);
        if (!match)
            return false;
        out = it->second;
        if (consume)
        {
            it->second.spellId = 0;
            it->second.ms = 0;
        }
        return true;
    }

    // Clear the current mark (keep the tracker) so the next tick rerolls it.
    void SpellbindClearMark(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(SpellbindMutex);
        auto it = SpellbindState.find(guid);
        if (it != SpellbindState.end())
        {
            it->second.spellId = 0;
            it->second.ms = 0;
        }
    }

    void SpellbindClear(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(SpellbindMutex);
        SpellbindState.erase(guid);
        SpellbindPendingKills.erase(guid);
    }

    void SpellbindQueueKill(uint32 guid, SpellbindPendingKill const& kill)
    {
        std::lock_guard<std::mutex> lock(SpellbindMutex);
        SpellbindPendingKills[guid] = kill;
    }

    // Applies a mark death queued by the cast hook, on the player's own update
    // (map thread). FailChallenge + lethal damage run here, not inside CheckCast.
    void SpellbindProcessPending(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        SpellbindPendingKill kill;
        {
            std::lock_guard<std::mutex> lock(SpellbindMutex);
            auto it = SpellbindPendingKills.find(guid);
            if (it == SpellbindPendingKills.end())
                return;
            kill = it->second;
            SpellbindPendingKills.erase(it);
        }
        // Attribute the death to the mechanic (otherwise the recap/broadcast
        // shows "Unknown"), then fail the challenge and apply the lethal damage.
        SetDeathCause(player, KillerKind::Mechanic, 0, kill.name);
        FailChallenge(player, kill.challengeId, kill.level, kill.deaths);
        player->EnvironmentalDamage(DAMAGE_EXHAUSTED, player->GetMaxHealth());
    }

    // Test-harness accessors (GM `.coa ruletestall`): inspect/advance the
    // in-memory roulette state without exposing SpellbindState via a header.
    bool Test_SpellbindMark(Player* player, uint32& spellId, bool& failable)
    {
        spellId = 0;
        failable = true;
        if (!player)
            return false;
        std::lock_guard<std::mutex> lock(SpellbindMutex);
        auto it = SpellbindState.find(player->GetGUID().GetCounter());
        if (it == SpellbindState.end())
            return false;
        spellId = it->second.spellId;
        failable = it->second.failable;
        return true;
    }

    void Test_SpellbindTick(Player* player, uint32 diff)
    {
        if (player)
            SpellbindUpdate(player, diff);
    }

    void Test_SpellbindProcessPending(Player* player)
    {
        SpellbindProcessPending(player);
    }

    // Spell Activation Overlay: the client paints the "proc glow" on the action
    // button of a spell via SMSG 0x9B1 and clears it via 0x9B2. Used to mark the
    // Spellbind Roulette forbidden spell. The SHOW payload was decoded from the
    // client handler (0x10235A90 -> Lua SPELL_ACTIVATION_SHOW, "%u%s%s%f%u%u%u"):
    //   u32 spellId, str texture, u32 type, float scale, u32 r, u32 g, u32 b
    // Values are conf-tunable so the visual can be iterated without a rebuild.
    void SendSpellActivationShow(Player* player, uint32 spellId)
    {
        WorldSession* session = player ? player->GetSession() : nullptr;
        if (!session || !spellId
            || !sConfigMgr->GetOption<bool>("CoAChallenges.Spellbind.OverlayEnabled", false))
            return;
        std::string const tex = sConfigMgr->GetOption<std::string>(
            "CoAChallenges.Spellbind.OverlayTexture",
            "Textures\\SpellActivationOverlays\\sudden_death");
        WorldPacket data(SMSG_COA_SPELL_ACTIVATION_SHOW, 96);
        data << uint32(spellId);
        // The client string reader is `u32 len` + `len` bytes; write the NUL so
        // the framing matches (WorldPacket<<string writes len+1 but omits it).
        data << uint32(tex.size() + 1);
        data.append(tex.c_str(), tex.size() + 1);
        data << uint32(sConfigMgr->GetOption<uint32>("CoAChallenges.Spellbind.OverlayType", 1));
        data << float(sConfigMgr->GetOption<float>("CoAChallenges.Spellbind.OverlayScale", 1.0f));
        data << uint32(sConfigMgr->GetOption<uint32>("CoAChallenges.Spellbind.OverlayR", 255));
        data << uint32(sConfigMgr->GetOption<uint32>("CoAChallenges.Spellbind.OverlayG", 0));
        data << uint32(sConfigMgr->GetOption<uint32>("CoAChallenges.Spellbind.OverlayB", 0));
        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x9B1 SPELL_ACTIVATION_SHOW to {}: spell={}",
            player->GetName(), spellId);
    }

    void SendSpellActivationHide(Player* player, uint32 spellId)
    {
        WorldSession* session = player ? player->GetSession() : nullptr;
        if (!session || !spellId
            || !sConfigMgr->GetOption<bool>("CoAChallenges.Spellbind.OverlayEnabled", false))
            return;
        WorldPacket data(SMSG_COA_SPELL_ACTIVATION_HIDE, 8);
        data << uint32(spellId);
        data << uint32(0);
        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x9B2 SPELL_ACTIVATION_HIDE to {}: spell={}",
            player->GetName(), spellId);
    }

    // ---- INVERTED_BREATH ----------------------------------------------------
    // Only Breathe Underwater: the core hook inverts the native breath timer
    // (drown on land, recover underwater). The module keeps the set of players
    // whose active challenge carries the rule (in-memory, so the per-tick core
    // hook stays cheap).
    std::mutex BreathMutex;
    std::unordered_set<uint32> InvertedBreathGuids;

    void RefreshInvertedBreathTracking(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        uint32 level = 0;
        bool const has = ActiveChallengeWithRule(player, "CHALLENGE_RULES_TYPE_INVERTED_BREATH", level) != 0;
        std::lock_guard<std::mutex> lock(BreathMutex);
        if (has)
            InvertedBreathGuids.insert(guid);
        else
            InvertedBreathGuids.erase(guid);
    }

    void TrackInvertedBreath(Player* player, uint32 challengeID)
    {
        if (!player)
            return;
        if (!RuleListContains(ChallengeRules(challengeID), "CHALLENGE_RULES_TYPE_INVERTED_BREATH"))
            return;
        std::lock_guard<std::mutex> lock(BreathMutex);
        InvertedBreathGuids.insert(player->GetGUID().GetCounter());
    }

    void UntrackInvertedBreath(Player* player)
    {
        if (!player)
            return;
        std::lock_guard<std::mutex> lock(BreathMutex);
        InvertedBreathGuids.erase(player->GetGUID().GetCounter());
    }

    // ---- Regeneration rules (Inn-Sane family) ------------------------------
    // Per-player bitmask of the active regen/heal/cast rules, so the per-tick
    // core hook (OnPlayerCanRegenerate) and the per-cast spell hook never touch
    // the DB. Refreshed on login/activate/deactivate/complete/fail like the
    // other trackers. "UNLESS_RESTED" variants allow regen inside a rest area.
    std::mutex RegenMutex;
    std::unordered_map<uint32, uint32> RegenRuleMask; // guid -> bitmask

    enum RegenRuleBit : uint32
    {
        REGEN_HEALTH          = 0x01,
        REGEN_HEALTH_RESTED   = 0x02,
        REGEN_MANA            = 0x04,
        REGEN_MANA_RESTED     = 0x08,
        REGEN_POWER           = 0x10,
        REGEN_POWER_RESTED    = 0x20,
        REGEN_ENERGIZE        = 0x40,
        REGEN_ENERGIZE_RESTED = 0x80,
        REGEN_HEAL_RESTED     = 0x100,
        REGEN_NO_HEALING      = 0x200,
        REGEN_HEAL_BANDAGE    = 0x400,
        // Cast-time rules (checked per spell cast, so cached to avoid a DB hit).
        REGEN_CAST_RANGE      = 0x800,
        REGEN_NO_PORTALS      = 0x1000,
    };

    void RefreshRegenTracking(Player* player)
    {
        if (!player)
            return;
        uint32 mask = 0;
        auto add = [&](char const* rule, uint32 bit)
        {
            uint32 level = 0;
            if (ActiveChallengeWithRule(player, rule, level))
                mask |= bit;
        };
        add("CHALLENGE_RULES_TYPE_NO_HEALTH_REGENERATION", REGEN_HEALTH);
        add("CHALLENGE_RULES_TYPE_NO_HEALTH_REGENERATION_UNLESS_RESTED", REGEN_HEALTH_RESTED);
        add("CHALLENGE_RULES_TYPE_NO_MANA_REGENERATION", REGEN_MANA);
        add("CHALLENGE_RULES_TYPE_NO_MANA_REGENERATION_UNLESS_RESTED", REGEN_MANA_RESTED);
        add("CHALLENGE_RULES_TYPE_NO_POWER_REGENERATION", REGEN_POWER);
        add("CHALLENGE_RULES_TYPE_NO_POWER_REGENERATION_UNLESS_RESTED", REGEN_POWER_RESTED);
        add("CHALLENGE_RULES_TYPE_NO_ENERGIZING", REGEN_ENERGIZE);
        add("CHALLENGE_RULES_TYPE_NO_ENERGIZING_UNLESS_RESTED", REGEN_ENERGIZE_RESTED);
        add("CHALLENGE_RULES_TYPE_NO_HEALING_UNLESS_RESTED", REGEN_HEAL_RESTED);
        add("CHALLENGE_RULES_TYPE_NO_HEALING", REGEN_NO_HEALING);
        add("CHALLENGE_RULES_TYPE_NO_HEALING_UNLESS_BANDAGING", REGEN_HEAL_BANDAGE);
        add("CHALLENGE_RULES_TYPE_CAST_RANGE_LIMITED_TO_MELEE", REGEN_CAST_RANGE);
        add("CHALLENGE_RULES_TYPE_NO_PORTALS", REGEN_NO_PORTALS);

        {
            std::lock_guard<std::mutex> lock(RegenMutex);
            uint32 guid = player->GetGUID().GetCounter();
            if (mask)
                RegenRuleMask[guid] = mask;
            else
                RegenRuleMask.erase(guid);
        }
        player->UpdateManaRegen();
    }

    void UntrackRegen(Player* player)
    {
        if (!player)
            return;
        std::lock_guard<std::mutex> lock(RegenMutex);
        RegenRuleMask.erase(player->GetGUID().GetCounter());
    }

    // Called from the core regen tick (Player::Regenerate / RegenerateHealth).
    // Must stay DB-free: only reads the cached mask + the resting flag.
    bool RegenBlocked(Player* player, int32 power)
    {
        if (!player)
            return false;
        uint32 mask;
        {
            std::lock_guard<std::mutex> lock(RegenMutex);
            auto it = RegenRuleMask.find(player->GetGUID().GetCounter());
            if (it == RegenRuleMask.end())
                return false;
            mask = it->second;
        }
        bool const rested = player->HasPlayerFlag(PLAYER_FLAGS_RESTING);
        if (power == POWER_HEALTH)
            return (mask & REGEN_HEALTH) != 0
                || (!rested && (mask & REGEN_HEALTH_RESTED) != 0);
        if (power == POWER_MANA)
            return (mask & (REGEN_MANA | REGEN_POWER)) != 0
                || (!rested && (mask & (REGEN_MANA_RESTED | REGEN_POWER_RESTED)) != 0);
        return (mask & REGEN_POWER) != 0
            || (!rested && (mask & REGEN_POWER_RESTED) != 0);
    }

    // NO_HEALING (always) / NO_HEALING_UNLESS_RESTED (outside rest). The rule is
    // "cannot RECEIVE healing", so it is checked on the RECEIVER, not the healer.
    // Cache-only so it stays cheap in the heal path.
    bool HealBlocked(Player* player)
    {
        if (!player)
            return false;
        uint32 mask;
        {
            std::lock_guard<std::mutex> lock(RegenMutex);
            auto it = RegenRuleMask.find(player->GetGUID().GetCounter());
            if (it == RegenRuleMask.end())
                return false;
            mask = it->second;
        }
        bool const rested = player->HasPlayerFlag(PLAYER_FLAGS_RESTING);
        bool blocked = (mask & REGEN_NO_HEALING) != 0
            || (!rested && (mask & REGEN_HEAL_RESTED) != 0);
        // NO_HEALING_UNLESS_BANDAGING: block everything except a bandage heal,
        // which ModifyHealReceived flags immediately before this runs.
        if (!blocked && (mask & REGEN_HEAL_BANDAGE) != 0)
            blocked = !ConsumeBandageAllow(player->GetGUID().GetCounter());
        return blocked;
    }

    // Cached per-player rule mask lookup (see RegenRuleMask). DB-free, so it is
    // safe in the per-spell-cast hook.
    bool RuleMaskHas(Player* player, uint32 bit)
    {
        if (!player)
            return false;
        std::lock_guard<std::mutex> lock(RegenMutex);
        auto it = RegenRuleMask.find(player->GetGUID().GetCounter());
        return it != RegenRuleMask.end() && (it->second & bit) != 0;
    }

    // NO_ENERGIZING (always) / NO_ENERGIZING_UNLESS_RESTED (outside rest):
    // instant power-restoring effects (potions / spells / talents), distinct from
    // passive regeneration. Called from Unit::EnergizeBySpell.
    bool EnergizeBlocked(Player* player)
    {
        if (!player)
            return false;
        uint32 mask;
        {
            std::lock_guard<std::mutex> lock(RegenMutex);
            auto it = RegenRuleMask.find(player->GetGUID().GetCounter());
            if (it == RegenRuleMask.end())
                return false;
            mask = it->second;
        }
        bool const rested = player->HasPlayerFlag(PLAYER_FLAGS_RESTING);
        return (mask & REGEN_ENERGIZE) != 0
            || (!rested && (mask & REGEN_ENERGIZE_RESTED) != 0);
    }

    // ---- Level-up regen rules ----------------------------------------------
    // The core refills health/powers on level-up. Snapshot before (OnPlayerCan-
    // GiveLevel) and restore after (OnPlayerLevelChanged) for the blocked powers.
    std::mutex LevelUpMutex;
    struct LevelUpSnapshot
    {
        uint32 health = 0;
        uint32 power[5] = {};   // POWER_MANA .. POWER_HAPPINESS
    };
    std::unordered_map<uint32, LevelUpSnapshot> LevelUpSnapshots;

    void SnapshotLevelUp(Player* player)
    {
        if (!player)
            return;
        LevelUpSnapshot s;
        s.health = player->GetHealth();
        for (uint32 p = POWER_MANA; p <= POWER_HAPPINESS; ++p)
            s.power[p] = player->GetPower(Powers(p));
        std::lock_guard<std::mutex> lock(LevelUpMutex);
        LevelUpSnapshots[player->GetGUID().GetCounter()] = s;
    }

    void RestoreLevelUpRegen(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        LevelUpSnapshot s;
        {
            std::lock_guard<std::mutex> lock(LevelUpMutex);
            auto it = LevelUpSnapshots.find(guid);
            if (it == LevelUpSnapshots.end())
                return;
            s = it->second;
            LevelUpSnapshots.erase(it);
        }
        if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_HEALTH_REGENERATION_ON_LEVEL_UP"))
            player->SetHealth(std::min(s.health, player->GetMaxHealth()));
        if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_POWER_REGENERATION_ON_LEVEL_UP"))
            for (uint32 p = POWER_MANA; p <= POWER_HAPPINESS; ++p)
                player->SetPower(Powers(p), std::min(s.power[p], player->GetMaxPower(Powers(p))));
        if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_MANA_REGENERATION_ON_LEVEL_UP"))
            player->SetPower(POWER_MANA, std::min(s.power[POWER_MANA], player->GetMaxPower(POWER_MANA)));
    }

    void UntrackLevelUp(Player* player)
    {
        if (!player)
            return;
        std::lock_guard<std::mutex> lock(LevelUpMutex);
        LevelUpSnapshots.erase(player->GetGUID().GetCounter());
    }

    // ---- HIGH_RISK_ONLY -----------------------------------------------------
    // High Risk is a ruleset aura applied by CoA
    // (SPELL_ASCENSION_HIGH_RISK = 1004019; see AscensionRulesets.cpp). The rule
    // means the challenge may only run while the character carries it. The aura
    // is polled per tick from a cached guid set (refreshed on login/activate/
    // deactivate/complete/fail) so the hot path stays DB-free.
    std::mutex HighRiskMutex;
    std::unordered_set<uint32> HighRiskGuids;

    uint32 HighRiskAura()
    {
        return sConfigMgr->GetOption<uint32>("CoAChallenges.HighRisk.Aura", 1004019);
    }

    void RefreshHighRiskTracking(Player* player)
    {
        if (!player)
            return;
        uint32 level = 0;
        bool const has = ActiveChallengeWithRule(player, "CHALLENGE_RULES_TYPE_HIGH_RISK_ONLY", level) != 0;
        std::lock_guard<std::mutex> lock(HighRiskMutex);
        uint32 guid = player->GetGUID().GetCounter();
        if (has)
            HighRiskGuids.insert(guid);
        else
            HighRiskGuids.erase(guid);
    }

    void UntrackHighRisk(Player* player)
    {
        if (!player)
            return;
        std::lock_guard<std::mutex> lock(HighRiskMutex);
        HighRiskGuids.erase(player->GetGUID().GetCounter());
    }

    bool HighRiskTracked(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(HighRiskMutex);
        return HighRiskGuids.find(guid) != HighRiskGuids.end();
    }

    // ---- NO_CREATURE_LEVEL_SCALING / NO_QUEST_LEVEL_SCALING -----------------
    // The scaling paths ask once per creature per viewer update, so the mask is
    // cached per guid like the High Risk set, with a count for the common case
    // of nobody holding such a challenge. A change re-sends the character's
    // creatures and quest log, which the client otherwise keeps from before.
    std::mutex LevelScalingMutex;
    std::unordered_map<uint32, uint8> LevelScalingMasks;
    std::atomic<uint32> LevelScalingMaskCount{0};

    uint8 LevelScalingBlocks(Player const* player)
    {
        if (!player || !LevelScalingMaskCount.load(std::memory_order_relaxed))
            return 0;
        std::lock_guard<std::mutex> lock(LevelScalingMutex);
        auto const it = LevelScalingMasks.find(player->GetGUID().GetCounter());
        return it == LevelScalingMasks.end() ? 0 : it->second;
    }

    uint8 StoreLevelScalingBlocks(uint32 guid, uint8 blocks)
    {
        std::lock_guard<std::mutex> lock(LevelScalingMutex);
        auto const it = LevelScalingMasks.find(guid);
        uint8 const previous = it == LevelScalingMasks.end() ? 0 : it->second;
        if (it != LevelScalingMasks.end() && !blocks)
        {
            LevelScalingMasks.erase(it);
            LevelScalingMaskCount.fetch_sub(1, std::memory_order_relaxed);
        }
        else if (it != LevelScalingMasks.end())
            it->second = blocks;
        else if (blocks)
        {
            LevelScalingMasks.emplace(guid, blocks);
            LevelScalingMaskCount.fetch_add(1, std::memory_order_relaxed);
        }
        return previous;
    }

    void RefreshLevelScalingTracking(Player* player)
    {
        if (!player)
            return;
        uint8 blocks = 0;
        if (ChallengesEnabled())
        {
            uint32 level = 0;
            if (ActiveChallengeWithRule(player, "CHALLENGE_RULES_TYPE_NO_CREATURE_LEVEL_SCALING", level))
                blocks |= LocalLevelScaling::ChallengeBlocksCreatureScaling;
            if (ActiveChallengeWithRule(player, "CHALLENGE_RULES_TYPE_NO_QUEST_LEVEL_SCALING", level))
                blocks |= LocalLevelScaling::ChallengeBlocksQuestScaling;
        }
        if (StoreLevelScalingBlocks(player->GetGUID().GetCounter(), blocks) == blocks || !player->IsInWorld())
            return;
        if (!LocalLevelScaling::NotifyScalingChanged(player))
            player->RefreshQuestLogQueries();
    }

    void UntrackLevelScaling(Player* player)
    {
        if (player)
            StoreLevelScalingBlocks(player->GetGUID().GetCounter(), 0);
    }

    // HIGH_RISK_ONLY activation gate (shared by ValidateChallenge and tests).
    bool HighRiskActivationBlocked(Player* player)
    {
        return !player || !player->HasAura(HighRiskAura());
    }

    // Called each tick while the rule is active: losing the High Risk aura
    // ("must remain in High Risk at all times") fails the challenge.
    void EnforceHighRisk(Player* player)
    {
        if (!player || !HighRiskTracked(player->GetGUID().GetCounter()))
            return;
        if (player->HasAura(HighRiskAura()))
            return;
        uint32 level = 0;
        uint32 cid = ActiveChallengeWithRule(player, "CHALLENGE_RULES_TYPE_HIGH_RISK_ONLY", level);
        if (!cid)
        {
            UntrackHighRisk(player);
            return;
        }
        uint32 guid = player->GetGUID().GetCounter();
        uint32 deaths = 0;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT deaths FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                guid, cid))
            deaths = r->Fetch()[0].Get<uint32>();
        NotifyPlayer(player, "You left High Risk and failed your challenge.");
        FailChallenge(player, cid, level, deaths);
    }

    // ---- NO_NON_LOOTED_ITEMS ("Scavenger") ---------------------------------
    // Tracks the item-instance GUIDs a character has looted so equipping an
    // item obtained any other way (vendor/trade/quest/mail/craft) can be
    // blocked. Persistent across relogs; the in-memory set is (re)loaded when
    // the rule is active. `INSERT IGNORE` keeps the loot path idempotent.
    std::mutex LootedMutex;
    std::unordered_map<uint32, std::unordered_set<uint32>> LootedItems;

    void UntrackLootedItems(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(LootedMutex);
        LootedItems.erase(guid);
    }

    void LoadLootedItems(uint32 guid)
    {
        std::unordered_set<uint32> items;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT itemGuid FROM coa_character_looted_item WHERE guid = {}", guid))
            do { items.insert(r->Fetch()[0].Get<uint32>()); } while (r->NextRow());
        std::lock_guard<std::mutex> lock(LootedMutex);
        LootedItems[guid] = std::move(items);
    }

    void RefreshLootedTracking(Player* player)
    {
        if (!player)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        uint32 level = 0;
        if (ActiveChallengeWithRule(player, "CHALLENGE_RULES_TYPE_NO_NON_LOOTED_ITEMS", level))
            LoadLootedItems(guid);
        else
            UntrackLootedItems(guid);
    }

    // Records a looted item instance while the rule is being tracked. No DB
    // write happens for characters without the rule (so the loot path stays
    // free of per-loot inserts for the rest of the realm).
    void MarkLootedItem(Player* player, Item* item)
    {
        if (!player || !item)
            return;
        uint32 guid = player->GetGUID().GetCounter();
        uint32 itemGuid = item->GetGUID().GetCounter();
        if (!itemGuid)
            return;
        {
            std::lock_guard<std::mutex> lock(LootedMutex);
            auto it = LootedItems.find(guid);
            if (it == LootedItems.end())
                return;   // not tracking this character
            if (!it->second.insert(itemGuid).second)
                return;   // already known
        }
        CharacterDatabase.Execute(
            "INSERT IGNORE INTO coa_character_looted_item (guid, itemGuid) VALUES ({}, {})",
            guid, itemGuid);
    }

    bool ItemWasLooted(uint32 guid, uint32 itemGuid)
    {
        std::lock_guard<std::mutex> lock(LootedMutex);
        auto it = LootedItems.find(guid);
        return it != LootedItems.end() && it->second.count(itemGuid) != 0;
    }

    // ---- NO_HEALING_UNLESS_BANDAGING ---------------------------------------
    // First Aid bandage heals are the only healing allowed. Bandage spells are
    // identified by their First Aid skill line (the classic Bandage ranks).
    bool IsBandageSpell(SpellInfo const* spellInfo)
    {
        if (!spellInfo)
            return false;
        SkillLineAbilityMapBounds bounds = sSpellMgr->GetSkillLineAbilityMapBounds(spellInfo->Id);
        for (auto it = bounds.first; it != bounds.second; ++it)
            if (it->second->SkillLine == SKILL_FIRST_AID)
                return true;
        return false;
    }

    // Per-player allowance set a bandage heal just before it resolves: the
    // heal hooks lack spell info, so ModifyHealReceived (spell-aware) flags the
    // receiver and HealBlocked consumes it.
    std::mutex BandageAllowMutex;
    std::unordered_set<uint32> BandageAllowGuids;

    void AllowBandageHeal(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(BandageAllowMutex);
        BandageAllowGuids.insert(guid);
    }

    bool ConsumeBandageAllow(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(BandageAllowMutex);
        return BandageAllowGuids.erase(guid) != 0;
    }

    void UntrackBandage(Player* player)
    {
        if (!player)
            return;
        std::lock_guard<std::mutex> lock(BandageAllowMutex);
        BandageAllowGuids.erase(player->GetGUID().GetCounter());
    }

    // ---- NO_OUTSIDE_INTERACTION ("I'm the Main Character") ----------------
    // "Unable to interact with other players": trade, group, mail, bank/AH/
    // vendor, guild bank. Aggregated into the existing per-service handlers.
    bool NoOutsideInteraction(Player* player)
    {
        return PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_OUTSIDE_INTERACTION");
    }

    // ---- OUTSIDE_INTERACTION activation gate (implicit, #4205 family) -----
    // Any outside service interaction (mail/trade/AH/vendor/guild bank) taints
    // the character, so a non-prestige trial can no longer be started. One
    // persistent flag; the in-memory set avoids a DB write per vendor click.
    // ponytail: personal bank has no core hook, so it is not tracked yet.
    std::mutex OutsideMutex;
    std::unordered_set<std::string> OutsideMarked;

    void MarkOutsideInteraction(Player* player, char const* facet)
    {
        if (!player || !facet || !ChallengesEnabled() || !OutsideInteractionGateEnabled() || IsPrestiged(player))
            return;
        uint32 const guid = player->GetGUID().GetCounter();
        if (HasActiveTrial(guid))   // condition gates activation only
            return;
        std::string const key = std::to_string(guid) + ":" + facet;
        {
            std::lock_guard<std::mutex> lock(OutsideMutex);
            if (!OutsideMarked.insert(key).second)
                return;
        }
        // Already permanently blocked (a failure under BlockAllAfterFailure):
        // the flag can never matter, so don't write it. Checked after the dedup
        // so the DB query runs at most once per facet per session.
        if (ActivationPermanentlyBlocked(guid))
            return;
        SetConditionFlag(guid, facet);
    }

    void UntrackOutsideInteraction(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(OutsideMutex);
        std::string const prefix = std::to_string(guid) + ":";
        for (auto it = OutsideMarked.begin(); it != OutsideMarked.end();)
        {
            if (it->compare(0, prefix.size(), prefix) == 0)
                it = OutsideMarked.erase(it);
            else
                ++it;
        }
    }

    // ---- NO_GROUP_FOR_DUNGEONS ("Solitary Struggle") ----------------------
    // You cannot group with other players while inside a dungeon.
    bool GroupForDungeonsBlocked(Player* player, Player* other)
    {
        if (!player || !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_GROUP_FOR_DUNGEONS"))
            return false;
        if (player->GetMap() && player->GetMap()->IsDungeon())
            return true;
        if (other && other->GetMap() && other->GetMap()->IsDungeon())
            return true;
        return false;
    }

    // ---- Mailbox (#4205) ---------------------------------------------------
    // Pre-trial: taking non-store items/currency from the mailbox taints the
    // character so a non-prestige trial cannot be started (facet of
    // OUTSIDE_INTERACTION). During the trial: the NO_MAIL rule forbids both
    // sending and receiving mail. Store items / reward caches are exempt.
    bool IsMailExemptItem(uint32 entry)
    {
        if (!entry)
            return false;
        return CoAParse::ListContains(
            sConfigMgr->GetOption<std::string>("CoAChallenges.MailExemptItems", "1397884;1397885;1397886"),
            std::to_string(entry));
    }

    // NO_MAIL / NO_OUTSIDE_INTERACTION (rules) forbid RECEIVING mail during the
    // trial, mirroring OnPlayerCanSendMail for the sending side. Exempt items
    // (store items / reward caches, same list as MarkMailTaken) are never
    // player-to-player mail, so they stay takeable; itemEntry is 0 for money.
    bool MailTakeForbidden(Player* player, uint32 itemEntry = 0)
    {
        if (player && !IsMailExemptItem(itemEntry)
            && (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_MAIL")
                || NoOutsideInteraction(player)))
        {
            NotifyPlayer(player, "Your challenge forbids receiving mail.");
            return true;
        }
        return false;
    }

    // Mail is a facet of the OUTSIDE_INTERACTION condition: taking a non-exempt
    // item/currency (entry 0 = money) taints the character for the next trial
    // activation. Store items / reward caches are exempt.
    void MarkMailTaken(Player* player, uint32 itemEntry)
    {
        if (!player || !ChallengesEnabled())
            return;
        if (IsMailExemptItem(itemEntry))   // store items / reward caches: exempt
            return;
        if (IsPrestiged(player))           // prestige uses the mailbox normally
            return;
        MarkOutsideInteraction(player, "OUTSIDE_MAIL");
    }

    // ---- Adventure Mode: monster health ---------------------------------------
    // Every tier's main aura reads "Monsters have X% more health". The first
    // Adventure player to hit an untapped monster (or one their group tapped)
    // scales it by their tier until it leaves combat. A flat TOTAL_VALUE
    // modifier survives the aura-driven recalculation of the health multiplier.
    uint32 AdventureModeTier(Player* player)
    {
        if (!player || !ChallengesEnabled())
            return 0;
        for (auto const& [cid, level] : CachedCharChallenges(player->GetGUID().GetCounter()))
            if (cid == 211 || cid == 425)
                return std::max<uint32>(level, 1);
        return 0;
    }

    uint32 AdventureModeExtraHealthPct(uint32 tier)
    {
        if (tier >= 89)
            return 400;
        if (tier >= 69)
            return 285;
        if (tier >= 49)
            return 215;
        if (tier >= 29)
            return 165;
        if (tier >= 9)
            return 125;
        return 100;
    }

    constexpr char const* AdventureHealthKey = "coa_challenges.adventure_health";

    struct AdventureHealth : DataMap::Base
    {
        float extra = 0.0f;
    };

    void ChangeMaxHealthKeepingPct(Creature* creature, float extra, bool apply)
    {
        bool const alive = creature->IsAlive() && creature->GetHealth();
        float const pct = creature->GetHealthPct();
        creature->HandleStatFlatModifier(UNIT_MOD_HEALTH, TOTAL_VALUE, extra, apply);
        if (alive)
            creature->SetHealth(std::max<uint32>(creature->CountPctFromMaxHealth(pct), 1));
    }

    void ScaleAdventureHealth(Player* attacker, Unit* victim)
    {
        Creature* creature = victim->ToCreature();
        if (!creature || creature->IsCharmedOwnedByPlayerOrPlayer() || !creature->IsAlive())
            return;
        if (creature->CustomData.Get<AdventureHealth>(AdventureHealthKey))
            return;
        if (creature->hasLootRecipient() && !creature->isTappedBy(attacker))
            return;
        uint32 const tier = AdventureModeTier(attacker);
        if (!tier)
            return;

        auto* state = new AdventureHealth();
        state->extra = float(CalculatePct(creature->GetMaxHealth(), AdventureModeExtraHealthPct(tier)));
        creature->CustomData.Set(AdventureHealthKey, state);
        ChangeMaxHealthKeepingPct(creature, state->extra, true);
    }

    void RestoreAdventureHealth(Unit* unit)
    {
        Creature* creature = unit ? unit->ToCreature() : nullptr;
        if (!creature)
            return;
        AdventureHealth* state = creature->CustomData.Get<AdventureHealth>(AdventureHealthKey);
        if (!state)
            return;
        ChangeMaxHealthKeepingPct(creature, state->extra, false);
        creature->CustomData.Erase(AdventureHealthKey);
    }

    // ---- STRICT_CHALLENGE_RESTRICTED_TAPPING -----------------------------------
    // A monster's kill rewards (experience, reputation, quest credit and loot)
    // go only to group members in the same restricted challenge as the player
    // who tapped it; players outside such a challenge share only with each
    // other.
    uint32 RestrictedTappingChallenge(ObjectGuid guid)
    {
        for (auto const& [cid, unusedLevel] : CachedCharChallenges(guid.GetCounter()))
            if (RuleListContains(ChallengeRules(cid), "CHALLENGE_RULES_TYPE_STRICT_CHALLENGE_RESTRICTED_TAPPING"))
                return cid;
        return 0;
    }

    bool TappingAllowsRewards(Player const* player, Creature const* creature)
    {
        if (!player || !creature || !ChallengesEnabled())
            return true;
        ObjectGuid const tapper = creature->GetLootRecipientGUID();
        if (!tapper || tapper == player->GetGUID())
            return true;
        return RestrictedTappingChallenge(player->GetGUID()) == RestrictedTappingChallenge(tapper);
    }

    constexpr char const* DeniedKillRewardKey = "coa_challenges.denied_kill_reward";

    struct DeniedKillReward : DataMap::Base
    {
        bool denied = false;
    };

    // ---- COSMETIC_ELITE_ENEMIES ------------------------------------------------
    // Monsters that are not friendly to the player are shown as elite (rares as
    // rare elite). The rank lives in the creature query response, which the
    // client caches, so the responses of visible monsters are re-sent when the
    // rule starts and restored when it ends.
    constexpr uint32 CreatureQueryRankUnknownEntry = 0x80000000;

    bool IsCosmeticEliteEnemy(Player* player, CreatureTemplate const* creature)
    {
        if (creature->type == CREATURE_TYPE_CRITTER || creature->type == CREATURE_TYPE_NON_COMBAT_PET)
            return false;
        FactionTemplateEntry const* own = player->GetFactionTemplateEntry();
        FactionTemplateEntry const* other = sFactionTemplateStore.LookupEntry(creature->faction);
        return own && other && !other->IsFriendlyTo(*own);
    }

    uint32 CosmeticEliteRank(uint32 rank)
    {
        if (rank == CREATURE_ELITE_NORMAL)
            return CREATURE_ELITE_ELITE;
        if (rank == CREATURE_ELITE_RARE)
            return CREATURE_ELITE_RAREELITE;
        return rank;
    }

    std::size_t CreatureQueryRankPos(WorldPacket const& packet)
    {
        std::size_t pos = sizeof(uint32);
        auto skipString = [&packet, &pos]()
        {
            while (pos < packet.size() && packet[pos])
                ++pos;
            ++pos;
        };
        skipString();
        pos += 3;
        skipString();
        skipString();
        pos += 3 * sizeof(uint32);
        return pos + sizeof(uint32) <= packet.size() ? pos : 0;
    }

    bool SendWithCosmeticEliteRank(WorldSession* session, WorldPacket const& packet)
    {
        Player* player = session ? session->GetPlayer() : nullptr;
        if (!player || packet.size() < sizeof(uint32))
            return false;
        uint32 const entry = packet.read<uint32>(0);
        if (entry & CreatureQueryRankUnknownEntry)
            return false;
        CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(entry);
        if (!creature || !IsCosmeticEliteEnemy(player, creature)
            || !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_COSMETIC_ELITE_ENEMIES"))
            return false;
        std::size_t const rankPos = CreatureQueryRankPos(packet);
        if (!rankPos)
            return false;
        uint32 const rank = packet.read<uint32>(rankPos);
        uint32 const shown = CosmeticEliteRank(rank);
        if (shown == rank)
            return false;

        WorldPacket elite(packet);
        elite.put<uint32>(rankPos, shown);
        session->SendPacket(&elite);
        return true;
    }

    constexpr char const* CosmeticEliteKey = "coa_challenges.cosmetic_elite";
    constexpr uint32 CosmeticEliteRefreshMs = 1000;

    struct CosmeticEliteDisplay : DataMap::Base
    {
        std::unordered_set<uint32> entries;
        uint32 timer = 0;
    };

    void ResendCreatureQuery(WorldSession* session, uint32 entry)
    {
        WorldPacket query(CMSG_CREATURE_QUERY, sizeof(uint32) + sizeof(uint64));
        query << uint32(entry) << ObjectGuid::Empty;
        session->HandleCreatureQueryOpcode(query);
    }

    void UpdateCosmeticElite(Player* player, uint32 diff)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;
        CosmeticEliteDisplay* display = player->CustomData.Get<CosmeticEliteDisplay>(CosmeticEliteKey);
        if (display && display->timer > diff)
        {
            display->timer -= diff;
            return;
        }

        if (!PlayerHasRule(player, "CHALLENGE_RULES_TYPE_COSMETIC_ELITE_ENEMIES"))
        {
            if (!display)
                return;
            std::unordered_set<uint32> const shown = std::move(display->entries);
            player->CustomData.Erase(CosmeticEliteKey);
            for (uint32 entry : shown)
                ResendCreatureQuery(session, entry);
            return;
        }

        if (!display)
            display = player->CustomData.GetDefault<CosmeticEliteDisplay>(CosmeticEliteKey);
        display->timer = CosmeticEliteRefreshMs;
        std::vector<uint32> added;
        player->DoForAllVisibleWorldObjects([display, &added](WorldObject* object)
        {
            if (Creature* creature = object->ToCreature())
                if (display->entries.insert(creature->GetEntry()).second)
                    added.push_back(creature->GetEntry());
        });
        for (uint32 entry : added)
            ResendCreatureQuery(session, entry);
    }

    class CoAChallengesPlayer : public PlayerScript
    {
    public:
        CoAChallengesPlayer() : PlayerScript("CoAChallengesPlayer", { PLAYERHOOK_ON_SEND_INITIAL_PACKETS_BEFORE_ADD_TO_MAP, PLAYERHOOK_ON_PLAYER_JUST_DIED, PLAYERHOOK_ON_PLAYER_RESURRECT, PLAYERHOOK_CAN_RESURRECT, PLAYERHOOK_CAN_SEND_MAIL, PLAYERHOOK_CAN_JOIN_LFG, PLAYERHOOK_CAN_JOIN_IN_BATTLEGROUND_QUEUE, PLAYERHOOK_CAN_JOIN_IN_ARENA_QUEUE, PLAYERHOOK_CAN_INIT_TRADE, PLAYERHOOK_CAN_PLACE_AUCTION_BID, PLAYERHOOK_ON_BEFORE_SEND_LOOT, PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_CREATURE_KILL, PLAYERHOOK_ON_CREATURE_KILLED_BY_PET, PLAYERHOOK_ON_PLAYER_KILLED_BY_CREATURE, PLAYERHOOK_ON_PVP_KILL, PLAYERHOOK_ON_LOOT_ITEM, PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST, PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_CAN_GROUP_INVITE, PLAYERHOOK_CAN_GROUP_ACCEPT, PLAYERHOOK_ON_UPDATE_CRAFTING_SKILL, PLAYERHOOK_ON_UPDATE_GATHERING_SKILL, PLAYERHOOK_ON_BEFORE_QUEST_COMPLETE, PLAYERHOOK_ON_QUEST_COMPUTE_EXP, PLAYERHOOK_ON_GIVE_EXP, PLAYERHOOK_ON_GET_MAX_ALLOWED_LEVEL, PLAYERHOOK_ON_HAS_NO_BONUS_EXPERIENCE, PLAYERHOOK_CAN_LEARN_TALENT, PLAYERHOOK_CAN_USE_ITEM, PLAYERHOOK_CAN_ENTER_MAP, PLAYERHOOK_CAN_EQUIP_ITEM, PLAYERHOOK_CAN_ENTER_MANASTORM, PLAYERHOOK_ON_PLAYER_ENVIRONMENTAL_DAMAGE, PLAYERHOOK_ON_PLAYER_BREATH_INVERTED, PLAYERHOOK_ON_BEFORE_BUY_ITEM_FROM_VENDOR, PLAYERHOOK_CAN_SELL_ITEM, PLAYERHOOK_ON_CAN_UPDATE_SKILL, PLAYERHOOK_ON_UPDATE_SKILL, PLAYERHOOK_ON_PLAYER_PVP_FLAG_CHANGE, PLAYERHOOK_ON_CAN_REGENERATE, PLAYERHOOK_ON_CAN_ENERGIZE, PLAYERHOOK_ON_CAN_GIVE_LEVEL, PLAYERHOOK_ON_BEFORE_TELEPORT, PLAYERHOOK_ON_DELETE_FROM_DB, PLAYERHOOK_ON_BANK_WITHDRAW, PLAYERHOOK_ON_REWARD_KILL_REWARDER, PLAYERHOOK_ON_GIVE_REPUTATION, PLAYERHOOK_PASSED_QUEST_KILLED_MONSTER_CREDIT, PLAYERHOOK_ON_LOAD_FROM_DB, PLAYERHOOK_ON_GET_GAME_MODE_MASK }) { }

        bool OnPlayerGetGameModeMask(Player const* player, uint32& mask) override
        {
            mask = CachedGameModeMask(player->GetGUID().GetCounter());
            return true;
        }

        // Player::LoadFromDB, before the inventory load asks PlayerHasRule: one read of the active
        // challenges serves both that cache and PushLoginState later in the same login.
        void OnPlayerLoadFromDB(Player* player) override
        {
            PreloadLoginChallengeRows(player->GetGUID().GetCounter());
        }

        // Runs on BOTH login paths (full + re-login-to-in-world; see
        // CharacterHandler.cpp:901 and :1215). Batch is idempotent.
        void OnPlayerSendInitialPacketsBeforeAddToMap(Player* player, WorldPacket& /*data*/) override
        {
            PushLoginState(player);
        }

        void OnPlayerJustDied(Player* player) override
        {
            HandlePlayerDeath(player);
        }

        // "Dead forever": block resurrection when the player carries a failed
        // permadeath challenge (Player::ResurrectPlayer early-returns on false).
        bool OnPlayerCanResurrect(Player* player) override
        {
            if (!ChallengesEnabled())
                return true;
            return !HasPermaDeathFailure(player);
        }

        // NO_MANASTORM: the Manastorm feature lives in CoA,
        // which calls this hook before starting a run.
        bool OnPlayerCanEnterManastorm(Player* player) override
        {
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_MANASTORM"))
            {
                // player is non-null here: PlayerHasRule(nullptr) is false.
                NotifyPlayer(player, "Your challenge forbids entering the Manastorm.");
                return false;
            }
            return true;
        }

        // INVERTED_BREATH (Only Breathe Underwater): the core asks whether to
        // flip the native breath timer (drown on land, recover underwater).
        bool OnPlayerBreathInverted(Player* player) override
        {
            if (!player)
                return false;
            std::lock_guard<std::mutex> lock(BreathMutex);
            return InvertedBreathGuids.find(player->GetGUID().GetCounter()) != InvertedBreathGuids.end();
        }

        // NO_FLAG_PVE (Bring it On!): the PvP flag can never be turned off.
        void OnPlayerPVPFlagChange(Player* player, bool state) override
        {
            if (player && !state && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_FLAG_PVE"))
                player->UpdatePvP(true, true);   // re-arm; the true call is a no-op here
        }

        // Regen rules (Inn-Sane): suppress natural regeneration per power; the
        // UNLESS_RESTED variants allow it inside a rest area. DB-free (cached).
        bool OnPlayerCanRegenerate(Player* player, int32 power) override
        {
            return !RegenBlocked(player, power);
        }

        // NO_ENERGIZING[_UNLESS_RESTED]: nullify instant energize effects
        // (potions / spells / talents), distinct from passive regen.
        bool OnPlayerCanEnergize(Player* player, int32 /*power*/) override
        {
            return !EnergizeBlocked(player);
        }

        // Level-up regen rules: snapshot before the core refills health/powers.
        bool OnPlayerCanGiveLevel(Player* player, uint8 /*newLevel*/) override
        {
            SnapshotLevelUp(player);
            return true;
        }

        // Failure-broadcast label for an EnviromentalDamage type (the client has
        // no cause of its own: without this the death reads as "Unknown"/"Suicide").
        static char const* EnvironmentalLabel(uint32 type)
        {
            switch (type)
            {
                case DAMAGE_EXHAUSTED:    return "Exhaustion";
                case DAMAGE_DROWNING:     return "Drowning";
                case DAMAGE_FALL:         return "Falling";
                case DAMAGE_LAVA:         return "Lava";
                case DAMAGE_SLIME:        return "Slime";
                case DAMAGE_FIRE:         return "Fire";
                case DAMAGE_FALL_TO_VOID: return "Falling";
                default:                  return "Environment";
            }
        }

        // Fails the first active challenge that carries `rule` (used by the
        // environment rules, where death is not required to fail).
        static void FailForEnvRule(Player* player, char const* rule, uint32 type, char const* message)
        {
            uint32 level = 0;
            uint32 cid = ActiveChallengeWithRule(player, rule, level);
            if (!cid)
                return;
            uint32 guid = player->GetGUID().GetCounter();
            uint32 deaths = 0;
            if (QueryResult r = CharacterDatabase.Query(
                    "SELECT deaths FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                    guid, cid))
                deaths = r->Fetch()[0].Get<uint32>();

            NotifyPlayer(player, "{}", message);
            LOG_INFO("module.coa_challenges",
                "{}: {} took environmental type {}, failing challenge {}",
                rule, player->GetName(), type, cid);
            FailChallenge(player, cid, level, deaths);
        }

        // Environmental damage hook (core: Player::EnvironmentalDamage). Names
        // the cause on a lethal hit (so the failure broadcast reads
        // Falling/Drowning/Lava/Fire/Exhaustion) and fails the environment
        // rules: FAILABLE_NO_FALLING (163) on any fall, FLOOR_IS_LAVA (165) on
        // lava/fire contact.
        bool OnPlayerEnvironmentalDamage(Player* player, uint32 type, uint32 damage) override
        {
            if (!player || !ChallengesEnabled())
                return true;

            // Only a lethal hit names the death; a non-lethal scratch must not
            // tag a later, unrelated death. Do not clobber an explicit Mechanic
            // cause (Starved / Fell Asleep / spellbind / missed objective): those
            // set the label right before applying this lethal hit.
            if (damage >= player->GetHealth())
            {
                std::lock_guard<std::mutex> lock(LastKillerMutex);
                auto it = LastKiller.find(player->GetGUID().GetCounter());
                if (it == LastKiller.end() || it->second.kind != KillerKind::Mechanic)
                    LastKiller[player->GetGUID().GetCounter()] =
                        PendingKiller{ KillerKind::Environment, 0, EnvironmentalLabel(type) };
            }

            // FAILABLE_NO_FALLING (163 "If you fall any distance, you might die").
            // KNOWN LIMITATION: only fires when the fall deals damage - the core
            // calls this hook from Player::EnvironmentalDamage, so a zero-damage
            // "safe" fall does not fail the trial.
            if (type == DAMAGE_FALL || type == DAMAGE_FALL_TO_VOID)
                FailForEnvRule(player, "CHALLENGE_RULES_TYPE_FAILABLE_NO_FALLING", type,
                    "You have fallen and failed your challenge.");

            if (type == DAMAGE_LAVA || type == DAMAGE_FIRE)
                FailForEnvRule(player, "CHALLENGE_RULES_TYPE_FLOOR_IS_LAVA", type,
                    "The floor is lava! Your challenge has failed.");

            return true;
        }

        // ---- Rules enforcement (server-side; client UI is cosmetic) ----
        bool OnPlayerCanSendMail(Player* player, ObjectGuid /*receiverGuid*/, ObjectGuid /*mailbox*/,
            std::string& /*subject*/, std::string& /*body*/, uint32 /*money*/, uint32 /*COD*/, Item* /*item*/) override
        {
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_MAIL")
                || NoOutsideInteraction(player))
            {
                NotifyPlayer(player, "Your challenge forbids using the mailbox.");
                return false;
            }
            return true;
        }

        bool OnPlayerCanJoinLfg(Player* player, uint8 /*roles*/, std::set<uint32>& /*dungeons*/, std::string const& /*comment*/) override
        {
            return !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_DUNGEON_FINDER");
        }

        bool OnPlayerCanJoinInBattlegroundQueue(Player* player, ObjectGuid /*BattlemasterGuid*/, BattlegroundTypeId /*BGTypeID*/, uint8 /*joinAsGroup*/, GroupJoinBattlegroundResult& /*err*/) override
        {
            return !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_BATTLEGROUND_FINDER")
                && !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_BATTLEGROUNDS");
        }

        bool OnPlayerCanJoinInArenaQueue(Player* player, ObjectGuid /*BattlemasterGuid*/, uint8 /*arenaslot*/, BattlegroundTypeId /*BGTypeID*/, uint8 /*joinAsGroup*/, uint8 /*IsRated*/, GroupJoinBattlegroundResult& /*err*/) override
        {
            return !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_ARENA_FINDER")
                && !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_ARENAS");
        }

        bool OnPlayerCanPlaceAuctionBid(Player* player, AuctionEntry* /*auction*/) override
        {
            MarkOutsideInteraction(player, "OUTSIDE_AH");
            return !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_AUCTIONHOUSE")
                && !NoOutsideInteraction(player);
        }

        bool OnPlayerCanInitTrade(Player* player, Player* target) override
        {
            if (!player || !target)
                return true;
            MarkOutsideInteraction(player, "OUTSIDE_TRADE");
            MarkOutsideInteraction(target, "OUTSIDE_TRADE");
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_TRADE")
                || PlayerHasRule(target, "CHALLENGE_RULES_TYPE_NO_TRADE")
                || NoOutsideInteraction(player)
                || NoOutsideInteraction(target))
            {
                NotifyPlayer(player, "Your challenge forbids trading.");
                return false;
            }
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_ONLY_TRADE_IF_SAME_CHALLENGES")
                || PlayerHasRule(target, "CHALLENGE_RULES_TYPE_ONLY_TRADE_IF_SAME_CHALLENGES"))
            {
                if (ActiveChallenges(player->GetGUID().GetCounter())
                    != ActiveChallenges(target->GetGUID().GetCounter()))
                {
                    NotifyPlayer(player,
                        "Trade is restricted: both players must share the same challenge(s).");
                    return false;
                }
            }
            return true;
        }

        // ---- Rules: grouping / professions / quests --------------------------
        bool OnPlayerCanGroupInvite(Player* player, std::string& membername) override
        {
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_GROUP"))
            {
                NotifyPlayer(player, "Your challenge forbids joining a group.");
                return false;
            }

            Player* target = ObjectAccessor::FindPlayerByName(membername);

            if (NoOutsideInteraction(player) || (target && NoOutsideInteraction(target)))
            {
                NotifyPlayer(player, "Your challenge forbids interacting with other players.");
                return false;
            }
            if (GroupForDungeonsBlocked(player, target))
            {
                NotifyPlayer(player, "Your challenge forbids grouping inside a dungeon.");
                return false;
            }

            // Official behavior: you can only group with players in the exact
            // same challenge set (both with none = free grouping). This is a
            // server-side mechanic, not encoded in the client definitions.
            if (sConfigMgr->GetOption<bool>("CoAChallenges.RequireSameChallengeToGroup", true)
                && target
                && ActiveChallenges(player->GetGUID().GetCounter())
                    != ActiveChallenges(target->GetGUID().GetCounter()))
            {
                NotifyPlayer(player,
                    "You can only group with players in the same challenge.");
                return false;
            }

            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_ONLY_GROUP_IN_3_LEVEL_RANGE") && target)
            {
                int diff = int(player->GetLevel()) - int(target->GetLevel());
                if (diff < 0) diff = -diff;
                if (diff > 3)
                {
                    NotifyPlayer(player, "Your challenge only allows grouping within 3 levels.");
                    return false;
                }
            }
            return true;
        }

        bool OnPlayerCanGroupAccept(Player* player, Group* group) override
        {
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_GROUP"))
            {
                NotifyPlayer(player, "Your challenge forbids joining a group.");
                return false;
            }

            Player* leader = group ? ObjectAccessor::FindPlayer(group->GetLeaderGUID()) : nullptr;

            if (NoOutsideInteraction(player) || (leader && NoOutsideInteraction(leader)))
            {
                NotifyPlayer(player, "Your challenge forbids interacting with other players.");
                return false;
            }
            if (GroupForDungeonsBlocked(player, leader))
            {
                NotifyPlayer(player, "Your challenge forbids grouping inside a dungeon.");
                return false;
            }

            // Same-challenge grouping gate (see OnPlayerCanGroupInvite).
            if (sConfigMgr->GetOption<bool>("CoAChallenges.RequireSameChallengeToGroup", true)
                && leader
                && ActiveChallenges(player->GetGUID().GetCounter())
                    != ActiveChallenges(leader->GetGUID().GetCounter()))
            {
                NotifyPlayer(player,
                    "You can only group with players in the same challenge.");
                return false;
            }

            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_ONLY_GROUP_IN_3_LEVEL_RANGE") && leader)
            {
                int diff = int(player->GetLevel()) - int(leader->GetLevel());
                if (diff < 0) diff = -diff;
                if (diff > 3)
                {
                    NotifyPlayer(player, "Your challenge only allows grouping within 3 levels.");
                    return false;
                }
            }
            return true;
        }

        void OnPlayerUpdateCraftingSkill(Player* player, SkillLineAbilityEntry const* skill, uint32 /*current_level*/, uint32& /*gain*/) override
        {
            if (player && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PROFESSIONS")
                && !UsesCoreProfessionXP(player))
            {
                std::lock_guard<std::mutex> lock(CraftRarityMutex);
                CraftRarity[player->GetGUID().GetCounter()] = CraftedItemRarity(skill);
            }
        }

        void OnPlayerUpdateGatheringSkill(Player* player, uint32 /*skill_id*/, uint32 /*current*/, uint32 /*gray*/, uint32 /*green*/, uint32 /*yellow*/, uint32& /*gain*/) override
        {
            if (player && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PROFESSIONS")
                && !UsesCoreProfessionXP(player))
            {
                // Gathering has no crafted item: flat XP, also clears a stale
                // craft entry from a failed skill-up roll.
                std::lock_guard<std::mutex> lock(CraftRarityMutex);
                CraftRarity[player->GetGUID().GetCounter()] = 1;
            }
        }

        // NO_PROFESSIONS: unable to learn or use professions of any kind.
        // Skill-up gate (silent: attempts are frequent); the cast itself is
        // blocked with a message in CoAChallengesSpells::OnSpellCheckCast.
        bool OnPlayerCanUpdateSkill(Player* player, uint32 skillId) override
        {
            return !(player && IsProfessionSkill(skillId)
                && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_PROFESSIONS"));
        }

        // GROUP_PROFESSION_EXPERIENCE (+ its XP source rule): each profession
        // skill-up grants player XP (base core awards none), shared with the
        // whole party holding the profession-XP rule.
        void OnPlayerUpdateSkill(Player* player, uint32 skillId, uint32 /*value*/, uint32 /*max*/, uint32 /*step*/, uint32 /*newValue*/) override
        {
            if (!player || !IsProfessionSkill(skillId))
                return;
            if (!PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PROFESSIONS"))
                return;
            if (UsesCoreProfessionXP(player))
                return;
            uint32 mult = 1;
            {
                std::lock_guard<std::mutex> lock(CraftRarityMutex);
                auto it = CraftRarity.find(player->GetGUID().GetCounter());
                if (it != CraftRarity.end())
                {
                    mult = it->second;
                    CraftRarity.erase(it);
                }
            }
            GrantProfessionXP(player, mult);
            if (!PlayerHasRule(player, "CHALLENGE_RULES_TYPE_GROUP_PROFESSION_EXPERIENCE"))
                return;
            if (Group* group = player->GetGroup())
            {
                for (Group::MemberSlot const& slot : group->GetMemberSlots())
                {
                    if (slot.guid == player->GetGUID())
                        continue;
                    Player* member = ObjectAccessor::FindPlayer(slot.guid);
                    if (!member)
                        continue;
                    if (!PlayerHasRule(member, "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PROFESSIONS"))
                        continue;
                    GrantProfessionXP(member, mult);
                }
            }
        }

        bool OnPlayerBeforeQuestComplete(Player* player, uint32 quest_id) override
        {
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_QUESTS"))
            {
                NotifyPlayer(player, "Your challenge forbids completing quests.");
                return false;
            }
            if (Quest const* quest = sObjectMgr->GetQuestTemplate(quest_id))
            {
                static char const* colors[5] = {"GRAY", "GREEN", "YELLOW", "ORANGE", "RED"};
                int c = QuestColor(quest->GetQuestLevel(), player->GetLevel());
                std::string rule = std::string("CHALLENGE_RULES_TYPE_NO_") + colors[c] + "_QUESTS";
                if (PlayerHasRule(player, rule.c_str()))
                {
                    NotifyPlayer(player, "Your challenge forbids completing this quest.");
                    return false;
                }
            }
            return true;
        }

        // NO_FETCH_QUEST_EXPERIENCE: quests with no objectives (talk-to and
        // delivery quests) grant no experience; other rewards stay.
        void OnPlayerQuestComputeXP(Player* player, Quest const* quest, uint32& xpValue) override
        {
            if (!player || !quest)
                return;
            if (!PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_FETCH_QUEST_EXPERIENCE"))
                return;
            if (IsQuestWithoutObjectives(quest))
                xpValue = 0;
        }

        // ---- Rules: experience source / talents / items ----------------------
        bool OnPlayerHasNoBonusExperience(Player* player) override
        {
            return PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_BONUS_EXPERIENCE");
        }

        void OnPlayerGiveXP(Player* player, uint32& amount, Unit* victim, uint8 xpSource) override
        {
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_QUESTS"))
            {
                if (xpSource != XPSOURCE_QUEST && xpSource != XPSOURCE_QUEST_DF)
                    amount = 0;
            }
            else if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_CREATURES"))
            {
                // XPSOURCE_KILL is shared by creature and player kills; only a
                // creature victim counts.
                if (xpSource != XPSOURCE_KILL || !victim || !victim->IsCreature())
                    amount = 0;
            }
            else if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PVP"))
            {
                // PvP = battlegrounds, or a kill whose victim is a player.
                bool const pvp = (xpSource == XPSOURCE_BATTLEGROUND)
                    || (xpSource == XPSOURCE_KILL && victim && victim->IsPlayer());
                if (!pvp)
                    amount = 0;
            }
            else if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EXPERIENCE_EXCEPT_PROFESSIONS"))
            {
                uint8 const professionSource = UsesCoreProfessionXP(player)
                    ? XPSOURCE_PROFESSION : XPSOURCE_PROFESSION_SKILL;
                if (xpSource != professionSource)
                    amount = 0;
            }

            if ((xpSource == XPSOURCE_PROFESSION || xpSource == XPSOURCE_PROFESSION_SKILL)
                && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_PROFESSION_EXPERIENCE"))
                amount = 0;

            // NO_KILL_CREDIT_UNLESS_AT_DISADVANTAGE ("Punching Up" / Overwhelming
            // Odds): only monsters above the player's level grant kill credit.
            if (amount
                && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_KILL_CREDIT_UNLESS_AT_DISADVANTAGE")
                && xpSource == XPSOURCE_KILL && victim && victim->IsCreature()
                && victim->GetLevel() <= player->GetLevel())
                amount = 0;

            // Prestige experience bonus: while a prestige cycle is in progress
            // the character earns the module's configured experience (the single
            // "Prestige Challenge" aura, 9930831, is the IsPrestiged() marker and
            // carries no mechanical XP effect, so this core applies it). The bonus
            // is flat, not per-cycle, and only below the cap. A challenge carrying
            // NO_BONUS_EXPERIENCE (Prestige - Resolute, Slow and Steady, Resolute
            // Mode) ignores it.
            if (amount && CoAPrestige::IsActive(player)
                && !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_BONUS_EXPERIENCE"))
            {
                amount = uint32(uint64(amount) * CoAPrestige::ExperienceBonusPercent() / 100);
            }

            // Prestige daily bonus: the content the held Prestige daily names earns extra
            // experience while it is played (Open World / Battlegrounds / Dungeons). A
            // challenge carrying NO_BONUS_EXPERIENCE ignores it too.
            if (amount && !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_BONUS_EXPERIENCE"))
                if (uint32 const daily = CoAPrestige::DailyExperienceBonusPercent(player, xpSource))
                    amount = uint32(uint64(amount) * (100 + daily) / 100);

            // NO_LEVEL_PAST_REQUIREMENTS: hold the player one point short of the
            // FIRST unmet objective level ahead. A huge gain (e.g. a big XP
            // rate) can cross several levels at once. When the gain would reach
            // that gate, jump to one point short of the gate level and ZERO the
            // gain: Player::GiveXP early-returns on xp < 1, so the rested pool
            // is NOT spent on experience the player never actually keeps.
            if (amount)
            {
                uint32 gate = NextGatedLevel(player);
                if (gate)
                {
                    uint32 curLevel = player->GetLevel();
                    uint32 curXP = player->GetUInt32Value(PLAYER_XP);
                    uint32 nextLvlXP = player->GetUInt32Value(PLAYER_NEXT_LEVEL_XP);
                    uint64 need = (nextLvlXP > curXP) ? uint64(nextLvlXP - curXP) : 0;
                    for (uint32 lvl = curLevel + 1; lvl < gate; ++lvl)
                        need += sObjectMgr->GetXPForLevel(static_cast<uint8>(lvl));
                    // XP that would actually land: gain + rested/RaF bonus
                    // (GetXPRestBonus returns min(restPool, gain)).
                    uint32 rest = static_cast<uint32>(player->GetRestBonus());
                    uint64 projected = uint64(amount) + std::min<uint64>(rest, amount);
                    uint64 room = (need > 0) ? (need - 1) : 0;
                    if (projected >= room)
                    {
                        uint32 before = amount;
                        uint8 targetLevel = static_cast<uint8>(gate - 1);
                        while (player->GetLevel() < targetLevel)
                            player->GiveLevel(player->GetLevel() + 1);
                        uint32 targetXP = sObjectMgr->GetXPForLevel(targetLevel);
                        player->SetUInt32Value(PLAYER_XP, targetXP > 0 ? targetXP - 1 : 0);
                        amount = 0; // GiveXP early-returns; rested untouched
                        LOG_INFO("module.coa_challenges",
                            "XP gate {}: src={} level {}->{} bar={} (rested kept {}), gain {} discarded",
                            player->GetName(), xpSource, curLevel, targetLevel, targetXP - 1, rest, before);
                    }
                }
            }
        }

        // Hard level-up cap for NO_LEVEL_PAST_REQUIREMENTS. Player::GiveXP
        // enforces it after every XP multiplier (dynamic-xp rate, RaF, rested,
        // favored) and regardless of hook order, so a large gain cannot cross
        // the gate. Complements the projection in OnPlayerGiveXP, which also
        // lands the bar one point short of the next level.
        uint8 OnPlayerGetMaxAllowedLevel(Player* player) override
        {
            uint32 const gate = NextGatedLevel(player);
            return gate ? static_cast<uint8>(gate - 1) : 0;
        }

        bool OnPlayerCanLearnTalent(Player* player, TalentEntry const* /*talent*/, uint32 /*rank*/) override
        {
            return !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_TALENTS");
        }

        bool OnPlayerCanUseItem(Player* player, ItemTemplate const* proto, InventoryResult& /*result*/) override
        {
            if (!proto)
                return true;
            // Hearthstone (6948).
            if (proto->ItemId == 6948 && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_HEARTHSTONE"))
            {
                NotifyPlayer(player, "Your challenge forbids using the hearthstone.");
                return false;
            }
            // Boosting items (Tradesman's Scroll / Scroll of Experience).
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_CONVENIENCE_ITEMS"))
            {
                switch (proto->ItemId)
                {
                    case 777998: case 2200018: case 1008036:
                    case 977065: case 991038:
                        NotifyPlayer(player, "Your challenge forbids using boosting items.");
                        return false;
                    default:
                        break;
                }
            }
            // Bonus experience modifiers (Aura/Potion of Experience, hotspots).
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_BONUS_EXPERIENCE"))
            {
                switch (proto->ItemId)
                {
                    case 818059: case 2200021: case 2818059:
                    case 135060: case 818046: case 3818046: case 8180460:
                    case 696666: case 818050:
                        NotifyPlayer(player, "Your challenge forbids bonus experience items.");
                        return false;
                    default:
                        break;
                }
            }
            // Mounts.
            if (proto->Class == ITEM_CLASS_MISC && proto->SubClass == ITEM_SUBCLASS_JUNK_MOUNT
                && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_MOUNTS"))
            {
                NotifyPlayer(player, "Your challenge forbids using mounts.");
                return false;
            }
            // Cosmetic pets.
            if (proto->Class == ITEM_CLASS_MISC && proto->SubClass == ITEM_SUBCLASS_JUNK_PET
                && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_COSMETIC_PET_ITEMS"))
            {
                NotifyPlayer(player, "Your challenge forbids cosmetic pets.");
                return false;
            }
            // Health potions.
            if (proto->Class == ITEM_CLASS_CONSUMABLE && proto->SubClass == ITEM_SUBCLASS_POTION
                && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_HEALTH_POTIONS"))
            {
                NotifyPlayer(player, "Your challenge forbids using potions.");
                return false;
            }
            return true;
        }

        // NO_VENDOR_BUY_FOOD_OR_DRINK: survival-style challenges may not buy
        // consumables that restore health/mana as food or drink. Potions and
        // bandages keep their own rules; this hook only sees normal vendor
        // purchases, not buyback.
        static bool IsVendorFoodOrDrink(ItemTemplate const* proto)
        {
            if (!proto || proto->Class != ITEM_CLASS_CONSUMABLE)
                return false;
            for (uint8 i = 0; i < MAX_ITEM_PROTO_SPELLS; ++i)
            {
                if (proto->Spells[i].SpellCategory == SPELL_CATEGORY_FOOD
                    || proto->Spells[i].SpellCategory == SPELL_CATEGORY_DRINK)
                    return true;
            }
            return false;
        }

        void OnPlayerBeforeBuyItemFromVendor(Player* player, ObjectGuid vendorguid, uint32 /*vendorslot*/, uint32& item, uint8 /*count*/, uint8 /*bag*/, uint8 /*slot*/) override
        {
            if (!player || item == 0)
                return;
            MarkOutsideInteraction(player, "OUTSIDE_VENDOR");
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item);
            Creature* vendor = player->GetNPCIfCanInteractWith(vendorguid, UNIT_NPC_FLAG_VENDOR);

            // NO_VENDORS / NO_VENDOR_BUY / NO_OUTSIDE_INTERACTION: block vendor purchases.
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_VENDORS")
                || PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_VENDOR_BUY")
                || NoOutsideInteraction(player))
            {
                item = 0;
                player->SendBuyError(BUY_ERR_SELLER_DONT_LIKE_YOU, vendor, proto ? proto->ItemId : 0, 0);
                NotifyPlayer(player, "Your challenge forbids buying from vendors.");
                return;
            }
            // NO_VENDOR_BUY_FOOD_OR_DRINK: block food/drink only.
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_VENDOR_BUY_FOOD_OR_DRINK")
                && IsVendorFoodOrDrink(proto))
            {
                item = 0;
                player->SendBuyError(BUY_ERR_SELLER_DONT_LIKE_YOU, vendor, proto ? proto->ItemId : 0, 0);
                NotifyPlayer(player, "Your challenge forbids buying food or drinks from vendors.");
            }
        }

        // NO_VENDORS: also block selling to a vendor.
        bool OnPlayerCanSellItem(Player* player, Item* /*item*/, Creature* /*creature*/) override
        {
            MarkOutsideInteraction(player, "OUTSIDE_VENDOR");
            if (player && (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_VENDORS")
                || NoOutsideInteraction(player)))
            {
                NotifyPlayer(player, "Your challenge forbids using vendors.");
                return false;
            }
            return true;
        }

        // ---- Rules: dungeons/raids / item quality ---------------------------
        bool OnPlayerCanEnterMap(Player* player, MapEntry const* entry, InstanceTemplate const* /*instance*/, MapDifficulty const* /*mapDiff*/, bool /*loginCheck*/) override
        {
            if (!entry)
                return true;
            if (entry->IsRaid() && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_RAIDS"))
            {
                NotifyPlayer(player, "Your challenge forbids entering raids.");
                return false;
            }
            if (entry->IsDungeon() && !entry->IsRaid() && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_DUNGEONS"))
            {
                NotifyPlayer(player, "Your challenge forbids entering dungeons.");
                return false;
            }
            return true;
        }

        // NO_LEAVE_CONTINENT ("Land Locked"): block teleports (spells/portals/
        // summons) that would move the character to a different continent. The
        // held continent is the one the character is on while the rule is
        // active. KNOWN LIMITATION: non-teleport map changes (boats/zeppelins)
        // don't pass through this hook.
        bool OnPlayerBeforeTeleport(Player* player, uint32 mapid, float /*x*/, float /*y*/, float /*z*/,
            float /*orientation*/, uint32 /*options*/, Unit* /*target*/) override
        {
            if (!player || !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_LEAVE_CONTINENT"))
                return true;
            MapEntry const* dest = sMapStore.LookupEntry(mapid);
            MapEntry const* cur = player->GetMap() ? player->GetMap()->GetEntry() : nullptr;
            if (dest && cur && dest->IsContinent() && cur->IsContinent()
                && dest->MapID != cur->MapID)
            {
                NotifyPlayer(player, "Your challenge forbids leaving the continent.");
                return false;
            }
            return true;
        }

        bool OnPlayerCanEquipItem(Player* player, uint8 /*slot*/, uint16& /*dest*/, Item* pItem, bool /*swap*/, bool /*not_loading*/) override
        {
            if (!pItem)
                return true;
            ItemTemplate const* proto = pItem->GetTemplate();
            if (!proto)
                return true;
            // NO_NON_SELF_CRAFTED_ITEMS (D.I.Y.): only gear the character
            // crafted itself (ITEM_FIELD_CREATOR holds the crafter's guid).
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_NON_SELF_CRAFTED_ITEMS")
                && pItem->GetGuidValue(ITEM_FIELD_CREATOR) != player->GetGUID())
            {
                NotifyPlayer(player, "Your challenge only allows items you crafted yourself.");
                return false;
            }
            // NO_NON_LOOTED_ITEMS (Scavenger): only item instances the character
            // looted itself (tracked in coa_character_looted_item).
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_NON_LOOTED_ITEMS")
                && !ItemWasLooted(player->GetGUID().GetCounter(), pItem->GetGUID().GetCounter()))
            {
                NotifyPlayer(player, "Your challenge only allows items you looted yourself.");
                return false;
            }
            if (proto->Class == ITEM_CLASS_ARMOR && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EQUIP_ARMOR"))
            {
                NotifyPlayer(player, "Your challenge forbids equipping armor.");
                return false;
            }
            if (proto->Class == ITEM_CLASS_CONTAINER && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_BAGS"))
            {
                NotifyPlayer(player, "Your challenge forbids additional bags.");
                return false;
            }
            switch (proto->Quality)
            {
                case ITEM_QUALITY_NORMAL:
                    if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EQUIP_COMMON_ITEMS")) return false;
                    break;
                case ITEM_QUALITY_UNCOMMON:
                    if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EQUIP_UNCOMMON_ITEMS")) return false;
                    break;
                case ITEM_QUALITY_RARE:
                    if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EQUIP_RARE_ITEMS")) return false;
                    break;
                case ITEM_QUALITY_EPIC:
                    if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EQUIP_EPIC_ITEMS")) return false;
                    break;
                case ITEM_QUALITY_LEGENDARY:
                    if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EQUIP_LEGENDARY_ITEMS")) return false;
                    break;
                case ITEM_QUALITY_ARTIFACT:
                    if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EQUIP_ARTIFACT_ITEMS")) return false;
                    break;
                case ITEM_QUALITY_HEIRLOOM:
                    if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_EQUIP_HEIRLOOM_ITEMS")) return false;
                    break;
                default:
                    break;
            }
            return true;
        }

        // ---- Activation-condition tracking (persistent, once broken stays) ----
        void OnPlayerBeforeSendLoot(Player* player, ObjectGuid /*lootGuid*/, Loot* /*loot*/) override
        {
            uint32 const guid = player->GetGUID().GetCounter();
            if (!HasActiveTrial(guid))   // condition gates activation only
                SetConditionFlag(guid, "LOOTED");
        }

        void OnPlayerLevelChanged(Player* player, uint8 /*oldLevel*/) override
        {
            SetConditionFlag(player->GetGUID().GetCounter(), "LEVELED");
            RestoreLevelUpRegen(player);
            if (CheckObjectiveLevels(player))
                CompleteAtLevelCap(player);
        }

        // ---- Objective tracking (level-restricted objectives) ----

        // NO_KILL_CREDIT_UNLESS_AT_DISADVANTAGE: kill credit (objective progress)
        // only counts for monsters above the player's level.
        static bool KillCreditAllowed(Player* player, Creature* killed)
        {
            return !PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_KILL_CREDIT_UNLESS_AT_DISADVANTAGE")
                || (killed && killed->GetLevel() > player->GetLevel());
        }

        // Credit a kill to the killer AND every group member holding the same
        // challenge (group trials like Boss Blitz share objectives; the last
        // hitter is not the only one who progresses).
        static void CreditKill(Player* player, Creature* killed)
        {
            if (!player || !killed)
                return;
            Group* group = player->GetGroup();
            LOG_DEBUG("module.coa_challenges",
                "Kill credit: {} killed creature {} (obj KILL_CREATURE_BEFORE_LEVEL), group={}",
                player->GetName(), killed->GetEntry(), group ? group->GetMembersCount() : 1);
            if (!KillCreditAllowed(player, killed))
            {
                LOG_INFO("module.coa_challenges",
                    "Kill credit suppressed for {} (creature {} level {} not above player level {})",
                    player->GetName(), killed->GetEntry(), killed->GetLevel(), player->GetLevel());
                return;
            }
            MarkObjectives(player, "CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL", killed->GetEntry());
            if (group)
                for (Group::MemberSlot const& slot : group->GetMemberSlots())
                    if (slot.guid != player->GetGUID())
                        if (Player* member = ObjectAccessor::FindPlayer(slot.guid))
                        {
                            if (!KillCreditAllowed(member, killed))
                                continue;
                            LOG_INFO("module.coa_challenges",
                                "Kill credit shared: {} -> member {} (creature {})",
                                player->GetName(), member->GetName(), killed->GetEntry());
                            MarkObjectives(member, "CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL", killed->GetEntry());
                        }
        }

        // FAILABLE_NO_KILL_BEASTS (D.E.H.T.A, 209/423) and
        // FAILABLE_NO_KILL_HUMANOIDS (160): killing the forbidden creature type
        // instantly fails the trial ("lose membership / broken vow").
        static void FailForbiddenKill(Player* player, Creature* killed)
        {
            if (!player || !killed)
                return;
            if (!(killed->GetCreatureType() == CREATURE_TYPE_BEAST || killed->IsCritter()
                || killed->GetCreatureType() == CREATURE_TYPE_HUMANOID))
                return;

            char const* rule = (killed->GetCreatureType() == CREATURE_TYPE_HUMANOID)
                ? "CHALLENGE_RULES_TYPE_FAILABLE_NO_KILL_HUMANOIDS"
                : "CHALLENGE_RULES_TYPE_FAILABLE_NO_KILL_BEASTS";
            uint32 level = 0;
            uint32 cid = ActiveChallengeWithRule(player, rule, level);
            if (!cid)
                return;
            uint32 guid = player->GetGUID().GetCounter();
            uint32 deaths = 0;
            if (QueryResult r = CharacterDatabase.Query(
                    "SELECT deaths FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                    guid, cid))
                deaths = r->Fetch()[0].Get<uint32>();

            NotifyPlayer(player,
                "You have slain a forbidden creature and failed your challenge.");
            LOG_INFO("module.coa_challenges",
                "{}: {} killed creature {} (type {}), failing challenge {}",
                rule, player->GetName(), killed->GetEntry(), uint32(killed->GetCreatureType()), cid);
            FailChallenge(player, cid, level, deaths, ObjectGuid::Empty,
                KillerKind::Rule, killed->GetEntry(), killed->GetName());
        }

        void OnPlayerCreatureKill(Player* player, Creature* killed) override
        {
            CreditKill(player, killed);
            FailForbiddenKill(player, killed);
        }

        // Pet/guardian kills credit the owner (and their group) too.
        void OnPlayerCreatureKilledByPet(Player* petOwner, Creature* killed) override
        {
            CreditKill(petOwner, killed);
            FailForbiddenKill(petOwner, killed);
        }

        // Fires right after OnPlayerJustDied (which already failed the
        // challenge) and carries the killer, so the failure broadcast can name
        // the mob the player died to. Every pending failure whose killerSource
        // is this death (the player, plus shared-fate holders) gets tagged.
        void OnPlayerKilledByCreature(Creature* killer, Player* killed) override
        {
            if (!killer || !killed)
                return;
            Player* owner = killer->GetCharmerOrOwnerPlayerOrPlayerItself();
            PendingKiller k;
            if (owner)
            {
                // Player pet: name the owner, not the pet (live showed
                // "Unknown" for the pet itself).
                k.kind = KillerKind::Player;
                k.name = owner->GetName();
            }
            else
            {
                k.kind = KillerKind::Creature;
                // The client overrides SetDisplayInfo (Model.lua) to call
                // Creature:CreateFromID(id) + SetCreature(id), so this must be
                // the creature ENTRY, not the display id.
                k.entry = killer->GetEntry();
                k.name = killer->GetName();
            }
            std::lock_guard<std::mutex> lock(LastKillerMutex);
            LastKiller[killed->GetGUID().GetCounter()] = k;
        }

        // PvP death: name the player killer (clickable inspect link).
        void OnPlayerPVPKill(Player* killer, Player* killed) override
        {
            if (!killer || !killed)
                return;
            uint32 guid = killed->GetGUID().GetCounter();
            std::lock_guard<std::mutex> lock(LastKillerMutex);
            if (killer == killed)
            {
                // Self-inflicted: EnvironmentalDamage kills the player with
                // themselves as the killer. Keep an explicitly-set cause (e.g.
                // Starved/Greedy) and only fall back to Suicide for a real
                // self-damage with no cause already recorded.
                auto it = LastKiller.find(guid);
                if (it == LastKiller.end() || it->second.kind == KillerKind::Unknown)
                    LastKiller[guid] = PendingKiller{ KillerKind::Self, 0, "Suicide" };
                return;
            }
            PendingKiller k;
            k.kind = KillerKind::Player;
            k.name = killer->GetName();
            LastKiller[guid] = k;
        }

        void OnPlayerLootItem(Player* player, Item* item, uint32 /*count*/, ObjectGuid /*lootguid*/) override
        {
            if (item)
            {
                MarkObjectives(player, "CHALLENGE_REQUIREMENT_TYPE_LOOT_ITEM_BEFORE_LEVEL", item->GetEntry());
                MarkLootedItem(player, item);
            }
        }

        void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
        {
            if (quest)
                MarkObjectives(player, "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_QUEST_BEFORE_LEVEL", quest->GetQuestId());
        }

        void OnPlayerResurrect(Player* player, float /*restore_percent*/, bool& /*applySickness*/) override
        {
            {
                std::lock_guard<std::mutex> lock(LastKillerMutex);
                LastKiller.erase(player->GetGUID().GetCounter());
            }
            ReapplyActiveSpells(player);
        }

        void OnPlayerUpdate(Player* player, uint32 diff) override
        {
            SpellbindProcessPending(player);
            HungerUpdate(player, diff);
            FatigueUpdate(player, diff);
            SpellbindUpdate(player, diff);
            EnforceHighRisk(player);
            UpdateCosmeticElite(player, diff);
        }

        void OnPlayerRewardKillRewarder(Player* player, KillRewarder* rewarder, bool /*isDungeon*/,
            float& rate) override
        {
            bool const denied = !TappingAllowsRewards(player, rewarder->GetVictim()->ToCreature());
            player->CustomData.GetDefault<DeniedKillReward>(DeniedKillRewardKey)->denied = denied;
            if (denied)
                rate = 0.0f;
        }

        void OnPlayerGiveReputation(Player* player, int32 /*factionID*/, float& amount,
            ReputationSource repSource) override
        {
            if (repSource != REPUTATION_SOURCE_KILL)
                return;
            if (DeniedKillReward const* reward = player->CustomData.Get<DeniedKillReward>(DeniedKillRewardKey))
                if (reward->denied)
                    amount = 0.0f;
        }

        bool OnPlayerPassedQuestKilledMonsterCredit(Player* player, Quest const* /*qinfo*/, uint32 /*entry*/,
            uint32 /*real_entry*/, ObjectGuid guid) override
        {
            if (!guid.IsCreatureOrVehicle())
                return true;
            return TappingAllowsRewards(player, ObjectAccessor::GetCreature(*player, guid));
        }

        void OnPlayerLogout(Player* player) override
        {
            UntrackHunger(player);
            UntrackFatigue(player);
            SpellbindClear(player->GetGUID().GetCounter());
            UntrackInvertedBreath(player);
            UntrackRegen(player);
            UntrackLevelUp(player);
            UntrackHighRisk(player);
            UntrackLevelScaling(player);
            UntrackLootedItems(player->GetGUID().GetCounter());
            UntrackBandage(player);
            UntrackOutsideInteraction(player->GetGUID().GetCounter());
            ClearGameModeMaskCache(player->GetGUID().GetCounter());
            ClearCharChallengeCache(player->GetGUID().GetCounter());
            ForgetLoginChallengeRows(player->GetGUID().GetCounter());
            // Not reset elsewhere; a stale craft multiplier / killer label would
            // otherwise survive into the next session.
            {
                std::lock_guard<std::mutex> lock(CraftRarityMutex);
                CraftRarity.erase(player->GetGUID().GetCounter());
            }
            {
                std::lock_guard<std::mutex> lock(LastKillerMutex);
                LastKiller.erase(player->GetGUID().GetCounter());
            }
        }

        // Character deletion: drop every character-scoped coa_* row in the same
        // transaction the core commits for the delete (Player::DeleteFromDB ->
        // OnPlayerDeleteFromDB), so nothing is orphaned. Keep this list in sync
        // with ResetCoaCharacterState.
        void OnPlayerDeleteFromDB(CharacterDatabaseTransaction trans, uint32 guid) override
        {
            static char const* const kCharTables[] = {
                "coa_character_challenge", "coa_character_objective", "coa_challenge_completion",
                "coa_challenge_failure", "coa_character_condition", "coa_character_gamemode",
                "coa_character_gamemode_lives", "coa_character_survival", "coa_character_fatigue",
                "coa_character_looted_item", "coa_custom_trial", "coa_custom_trial_active",
                "coa_custom_trial_entry", "coa_custom_trial_vote", "coa_custom_trial_completion",
            };
            for (char const* table : kCharTables)
                trans->Append("DELETE FROM {} WHERE guid = {}", table, guid);
            ForgetConditionFlags(guid);
        }

        // Personal / realm bank withdrawal (CoA fires this core
        // hook) feeds the OUTSIDE_INTERACTION gate. kind: 0 = personal, 1 = realm.
        void OnPlayerBankWithdraw(Player* player, uint8 kind) override
        {
            MarkOutsideInteraction(player, kind == 1 ? "OUTSIDE_REALM_BANK" : "OUTSIDE_BANK");
        }
    };

    class CoAChallengesWorld : public WorldScript
    {
    public:
        CoAChallengesWorld() : WorldScript("CoAChallengesWorld",
            { WORLDHOOK_ON_UPDATE, WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            LoadChallengesEnabled();
        }

            void OnStartup() override
            {
                EnsureTables();
                LoadChallengeDefinitions();
            }

        void OnUpdate(uint32 diff) override
        {
            Test_Update(diff);
            FlushFailureBroadcasts();
        }
    };

    class CoAChallengesServer : public ServerScript
    {
    public:
        CoAChallengesServer() : ServerScript("CoAChallengesServer",
            { SERVERHOOK_CAN_PACKET_RECEIVE, SERVERHOOK_CAN_PACKET_SEND }) { }

        bool CanPacketSend(WorldSession* session, WorldPacket const& packet) override
        {
            if (packet.GetOpcode() != SMSG_CREATURE_QUERY_RESPONSE)
                return true;
            return !SendWithCosmeticEliteRank(session, packet);
        }

        bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
        {
            uint16 opcode = packet.GetOpcode();

            // CANNOT_UNLEARN_PROFESSIONS: profession choices are permanent.
            // The spellbook "abandon profession" button sends CMSG_UNLEARN_SKILL
            // (u32 skillId); dropping it here keeps the whole rule inside this
            // module, with no core hook.
            if (opcode == CMSG_UNLEARN_SKILL && packet.size() >= 4)
            {
                Player* player = session ? session->GetPlayer() : nullptr;
                uint32 skillId = packet.read<uint32>(0);
                if (player && IsProfessionSkill(skillId)
                    && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_CANNOT_UNLEARN_PROFESSIONS"))
                {
                    NotifyPlayer(player, "Your profession choices are permanent.");
                    LOG_INFO("module.coa_challenges", "CMSG_UNLEARN_SKILL from {}: blocked profession skill {}",
                        player->GetName(), skillId);
                    return false;
                }
                return true;
            }

            Player* player = session ? session->GetPlayer() : nullptr;

            // Mail take (#4205). Handled here (not via a core hook) so the whole
            // rule stays in the module, like the other opcodes below.
            // - NO_MAIL / NO_OUTSIDE_INTERACTION forbid RECEIVING during a trial.
            // - Otherwise taking a non-exempt item/currency taints the character
            //   for the next trial activation (OUTSIDE_INTERACTION facet).
            // Payload: mailbox ObjectGuid (8) then mailId (u32); take-item adds
            // the item low guid (u32).
            if (opcode == CMSG_MAIL_TAKE_ITEM && packet.size() >= 16)
            {
                Item* item = player ? player->GetMItem(packet.read<uint32>(12)) : nullptr;
                uint32 itemEntry = item ? item->GetEntry() : 0;
                if (MailTakeForbidden(player, itemEntry))
                {
                    if (player)
                        player->SendMailResult(packet.read<uint32>(8), MAIL_ITEM_TAKEN, MAIL_ERR_INTERNAL_ERROR);
                    return false;
                }
                if (player)
                    MarkMailTaken(player, itemEntry);
                return true;
            }
            if (opcode == CMSG_MAIL_TAKE_MONEY && packet.size() >= 12)
            {
                if (MailTakeForbidden(player))
                {
                    if (player)
                        player->SendMailResult(packet.read<uint32>(8), MAIL_MONEY_TAKEN, MAIL_ERR_INTERNAL_ERROR);
                    return false;
                }
                MarkMailTaken(player, 0);
                return true;
            }

            // NO_VENDOR_BUYBACK / NO_VENDORS / NO_OUTSIDE_INTERACTION: no vendor buyback.
            if (opcode == CMSG_BUYBACK_ITEM)
            {
                if (player && (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_VENDOR_BUYBACK")
                    || PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_VENDORS")
                    || NoOutsideInteraction(player)))
                {
                    NotifyPlayer(player, "Your challenge forbids vendor buyback.");
                    return false;
                }
                return true;
            }
            // NO_BANK / NO_OUTSIDE_INTERACTION: no personal/guild bank window.
            if (opcode == CMSG_BANKER_ACTIVATE)
            {
                if (player && (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_BANK")
                    || NoOutsideInteraction(player)))
                {
                    NotifyPlayer(player, "Your challenge forbids using banks.");
                    return false;
                }
                return true;
            }
            // NO_REPAIR_ITEMS: no repairing at a vendor.
            if (opcode == CMSG_REPAIR_ITEM)
            {
                if (player && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_REPAIR_ITEMS"))
                {
                    NotifyPlayer(player, "Your challenge forbids repairing items.");
                    return false;
                }
                return true;
            }
            // CANNOT_LOOT_ITEMS (Minimalist, "unable to loot items"): block the
            // item-loot packets. Money (CMSG_LOOT_MONEY) is still allowed.
            if (opcode == CMSG_AUTOSTORE_LOOT_ITEM || opcode == CMSG_AUTOSTORE_BAG_ITEM
                || opcode == CMSG_LOOT_ROLL || opcode == CMSG_LOOT_MASTER_GIVE)
            {
                if (player && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_CANNOT_LOOT_ITEMS"))
                {
                    NotifyPlayer(player, "Your challenge forbids looting items.");
                    return false;
                }
                return true;
            }
            // NO_FLIGHT_PATHS: no taxi/flight routes.
            if (opcode == CMSG_ACTIVATETAXI || opcode == CMSG_ACTIVATETAXIEXPRESS)
            {
                if (player && PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_FLIGHT_PATHS"))
                {
                    NotifyPlayer(player, "Your challenge forbids using flight paths.");
                    return false;
                }
                return true;
            }
            // NO_*_QUESTS (accept side): block taking quests of the forbidden color.
            // Turn-in side is handled in OnPlayerBeforeQuestComplete.
            if (opcode == CMSG_QUESTGIVER_ACCEPT_QUEST && packet.size() >= 12)
            {
                uint32 questId = packet.read<uint32>(8);
                Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
                if (player && quest)
                {
                    static char const* colors[5] = {"GRAY", "GREEN", "YELLOW", "ORANGE", "RED"};
                    // Negative quest level = "use the player's level" sentinel;
                    // it has no real color, so the NO_*_QUESTS rules don't apply.
                    int qLevel = quest->GetQuestLevel();
                    if (qLevel < 0)
                        return true;
                    int c = QuestColor(uint32(qLevel), player->GetLevel());
                    if (c >= 0 && c < 5)
                    {
                        std::string rule = std::string("CHALLENGE_RULES_TYPE_NO_") + colors[c] + "_QUESTS";
                        if (PlayerHasRule(player, rule.c_str()))
                        {
                            NotifyPlayer(player, "Your challenge forbids accepting this quest.");
                            return false;
                        }
                    }
                }
                return true;
            }

            if (opcode >= 0x521 && opcode < NUM_MSG_TYPES)
            {
                Player* player = session ? session->GetPlayer() : nullptr;
                std::string who = player ? player->GetName() : "<none>";

                if (!ChallengesEnabled())
                    return true;

                // Debug level, and no full hex dump: this branch is reached for
                // every packet in the CoA opcode range, handled or not.
                LOG_DEBUG("module.coa_challenges", "CMSG 0x{:X} from {}: size={} bytes",
                    opcode, who, packet.size());

                if (opcode == CMSG_COA_QUERY_FAILURES)
                {
                    if (player)
                    {
                        SendFailureList(player);
                        LOG_INFO("module.coa_challenges", "CMSG 0x5A1 QUERY_FAILURES from {} -> failure list", who);
                    }
                    return false;
                }

                if (opcode == CMSG_COA_QUERY_COMPLETIONS)
                {
                    if (player && packet.size() >= 8)
                    {
                        uint32 challengeID = packet.read<uint32>(0);
                        uint32 level = packet.read<uint32>(4);
                        SendCompletionList(player, challengeID, level);
                        LOG_INFO("module.coa_challenges", "CMSG 0x5C6 QUERY_COMPLETIONS from {}: challengeID={} level={}",
                            who, challengeID, level);
                    }
                    return false;
                }

                if (opcode == CMSG_COA_START_CHALLENGE)
                {
                    if (packet.size() < 8)
                    {
                        LOG_WARN("module.coa_challenges", "CMSG_COA_START_CHALLENGE from {}: short payload ({} bytes)",
                            who, packet.size());
                        return false;
                    }
                    uint32 challengeID = packet.read<uint32>(0);
                    uint32 level = packet.read<uint32>(4);

                    if (player)
                    {
                        uint32 code = ActivateChallenge(player, challengeID, level);
                        if (code == 0)
                        {
                            SendChallengeResponse(player, SMSG_COA_CHALLENGE_START_RESPONSE,
                                challengeID, level, 0, "CHALLENGE_START_OK");
                            SendActiveList(player);
                            SendCriteriaState(player);
                        }
                        else
                        {
                            LOG_INFO("module.coa_challenges",
                                "CMSG_COA_START_CHALLENGE from {}: challengeID={} level={} rejected code={} ({})",
                                who, challengeID, level, code, ChallengeResponseString(code));
                            SendChallengeResponse(player, SMSG_COA_CHALLENGE_START_RESPONSE,
                                challengeID, level, code, ChallengeResponseString(code));
                            // Re-push the authoritative active/criteria state: the
                            // client toggles optimistically, so a rejected start
                            // would otherwise leave the challenge shown as active.
                            SendActiveList(player);
                            SendCriteriaState(player);
                        }
                    }

                    return false;
                }

                if (opcode == CMSG_COA_STOP_CHALLENGE)
                {
                    if (packet.size() < 4)
                    {
                        LOG_WARN("module.coa_challenges", "CMSG_COA_STOP_CHALLENGE from {}: short payload ({} bytes)",
                            who, packet.size());
                        return false;
                    }
                    uint32 challengeID = packet.read<uint32>(0);

                    uint32 level = 0;
                    if (player)
                    {
                        uint32 guid = player->GetGUID().GetCounter();
                        if (QueryResult r = CharacterDatabase.Query(
                                "SELECT level FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                                guid, challengeID))
                            level = r->Fetch()[0].Get<uint32>();

                        // A challenge with lives (hardcore/Nightmare) is FAILED
                        // when abandoned — unless nothing has been done yet
                        // (pristine), in which case it's a free cancel so a
                        // fresh character can undo a wrong pick.
                        uint32 lives = LivesTotal(challengeID);
                        bool freeCancel = sConfigMgr->GetOption<bool>(
                            "CoAChallenges.FreeCancelIfPristine", true)
                            && IsPristine(player, challengeID);

                        if (lives >= 1 && !freeCancel)
                        {
                            uint32 deaths = 0;
                            if (QueryResult dr = CharacterDatabase.Query(
                                    "SELECT deaths FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                                    guid, challengeID))
                                deaths = dr->Fetch()[0].Get<uint32>();
                            NotifyPlayer(player,
                                "You have abandoned {} and failed it.", ChallengeName(challengeID));
                            FailChallenge(player, challengeID, level, deaths);
                            return false;
                        }

                        DeactivateChallenge(player, challengeID);

                        SendChallengeResponse(player, SMSG_COA_CHALLENGE_STOP_RESPONSE,
                            challengeID, level, 0, "CHALLENGE_STOP_OK");
                        SendActiveList(player);
                        SendCriteriaState(player);
                    }

                    return false;
                }

                // ---- Gamemodes ----
                if (opcode == CMSG_COA_TOGGLE_GAME_MODE)
                {
                    if (player)
                        HandleToggleGameMode(player, packet);
                    return false;
                }

                // ---- Trial creator CMSGs ----
                if (opcode == CMSG_COA_QUERY_TRIALS)
                {
                    if (player)
                        SendTrialList(player);
                    return false;
                }

                if (opcode == CMSG_COA_SAVE_TRIAL)
                {
                    if (player)
                        HandleSaveTrial(player, packet);
                    return false;
                }

                if (opcode == CMSG_COA_DELETE_TRIAL)
                {
                    if (player)
                        HandleDeleteTrial(player, packet);
                    return false;
                }

                if (opcode == CMSG_COA_ACTIVATE_TRIAL)
                {
                    if (player)
                        HandleActivateTrial(player, packet);
                    return false;
                }

                if (opcode == CMSG_COA_DEACTIVATE_TRIAL)
                {
                    if (player)
                        HandleDeactivateTrial(player, packet);
                    return false;
                }

                if (opcode == CMSG_COA_RATE_TRIAL)
                {
                    if (player)
                        HandleRateTrial(player, packet);
                    return false;
                }

                if (opcode == CMSG_COA_QUERY_TRIAL_COMPLETIONS)
                {
                    // Custom-trial leaderboard query (CMSG 0x5C9), answered by
                    // SMSG 0x5CA (TRIAL_COMPLETION_LIST_CHANGED) with the real
                    // recorded completions for the requested trial.
                    if (player)
                    {
                        uint32 off = 0;
                        std::string trialID;
                        ReadWireString(packet, off, trialID);
                        SendTrialCompletions(player, trialID);
                    }
                    return false;
                }

                if (opcode == CMSG_COA_SYNC_RESPONSE)
                {
                    if (player)
                        HandleSyncResponse(player, packet);
                    return false;
                }

                return true;
            }

            return true;
        }
    };

    // GM/console tool: clear the "already failed" lock on a challenge so it
    // can be retaken. Mirrors a manual DELETE on coa_challenge_failure but
    // refreshes an online client's failure list immediately (no relog).
    class CoAChallengesCommand : public CommandScript
    {
    public:
        CoAChallengesCommand() : CommandScript("CoAChallengesCommand") { }

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable coaActionsTable =
            {
                { "unlock", HandleCoAUnlockCommand, SEC_ADMINISTRATOR, Console::Yes },
                { "check",  HandleCoACheckCommand,  SEC_ADMINISTRATOR, Console::Yes }
            };
            static ChatCommandTable coaChallengesTable =
            {
                { "reload", HandleCoAReloadCommand, SEC_ADMINISTRATOR, Console::Yes }
            };
            static ChatCommandTable coaCommandTable =
            {
                { "trial",     coaActionsTable },
                { "challenge", coaActionsTable },
                { "challenges", coaChallengesTable },
                { "e2e",       HandleCoAE2ECommand, SEC_ADMINISTRATOR, Console::Yes },
                { "e2emiss",   HandleCoAE2EMissCommand, SEC_ADMINISTRATOR, Console::Yes },
                { "ruletest",  HandleCoARuleTestCommand, SEC_ADMINISTRATOR, Console::Yes },
                { "ruletestall", HandleCoARuleTestAllCommand, SEC_ADMINISTRATOR, Console::Yes },
                { "conditiontest", HandleCoAConditionTestCommand, SEC_ADMINISTRATOR, Console::Yes },
                { "flag",      HandleCoAFlagCommand,       SEC_ADMINISTRATOR, Console::Yes },
                { "ruletestparty", HandleCoARuleTestPartyCommand, SEC_ADMINISTRATOR, Console::Yes },
                { "ruleaudit", HandleCoARuleAuditCommand, SEC_ADMINISTRATOR, Console::Yes },
                { "auditdefs", HandleCoAAuditDefsCommand, SEC_ADMINISTRATOR, Console::Yes },
                { "cachetoctou", HandleCoACacheToctouCommand, SEC_ADMINISTRATOR, Console::Yes },
                { "pettest",   HandleCoAPetTestCommand,   SEC_ADMINISTRATOR, Console::Yes },
                { "gamemode",  HandleCoAGameModeCommand,  SEC_ADMINISTRATOR, Console::Yes },
                { "sync",      HandleCoASyncCommand,       SEC_ADMINISTRATOR, Console::Yes },
                { "fatigue",   HandleCoAFatigueCommand,   SEC_ADMINISTRATOR, Console::Yes },
                { "envtest",   HandleCoAEnvTestCommand,   SEC_ADMINISTRATOR, Console::Yes },
                { "reward",    HandleCoARewardCommand,    SEC_ADMINISTRATOR, Console::Yes },
                { "reset",     HandleCoAResetCommand,     SEC_ADMINISTRATOR, Console::Yes },
        { "prestige",  HandleCoAPrestigeCommand,  SEC_ADMINISTRATOR, Console::Yes }
            };
            static ChatCommandTable commandTable =
            {
                { "coa", coaCommandTable }
            };
            return commandTable;
        }

        // .coa <trial|challenge> unlock <id> [player]
        static bool HandleCoAUnlockCommand(ChatHandler* handler, uint32 challengeId, Optional<PlayerIdentifier> player)
        {
            if (!player)
                player = PlayerIdentifier::FromTargetOrSelf(handler);
            if (!player)
            {
                handler->SendErrorMessage("No player (target someone or run it yourself).");
                return false;
            }

            uint32 guid = player->GetGUID().GetCounter();
            bool had = HasFailure(guid, challengeId);
            // Synchronous: SendFailureList below re-reads the table and must not
            // see the row still present (async DELETE would race it).
            CharacterDatabase.DirectExecute(
                "DELETE FROM coa_challenge_failure WHERE guid = {} AND challengeId = {}",
                guid, challengeId);

            if (had)
            {
                if (Player* online = player->GetConnectedPlayer())
                    SendFailureList(online);
                handler->PSendSysMessage("Unlocked {} from challenge {}.", player->GetName(), challengeId);
            }
            else
            {
                handler->SendErrorMessage("{} had no failure lock on challenge {}.", player->GetName(), challengeId);
            }
            return true;
        }

        // .coa <trial|challenge> check <id> [player]
        static bool HandleCoACheckCommand(ChatHandler* handler, uint32 challengeId, Optional<PlayerIdentifier> player)
        {
            if (!player)
                player = PlayerIdentifier::FromTargetOrSelf(handler);
            Player* p = player ? player->GetConnectedPlayer() : nullptr;
            if (!p)
            {
                handler->SendErrorMessage("Player must be online to check conditions.");
                return false;
            }

            handler->PSendSysMessage("Conditions for challenge {} ({}):", challengeId, p->GetName());

            std::vector<ConditionState> states = EvaluateConditions(p, challengeId);
            if (states.empty())
                handler->PSendSysMessage("  (none)");
            for (ConditionState const& s : states)
            {
                if (s.broken)
                    handler->SendErrorMessage("  {}: BROKEN ({})", s.label, s.detail);
                else
                    handler->PSendSysMessage("  {}: ok ({})", s.label, s.detail);
            }

            std::string reason = CheckActivationConditions(p, challengeId);
            if (reason.empty())
                handler->PSendSysMessage("  => OK (can activate)");
            else
                handler->SendErrorMessage("  => BLOCKED: {}", reason);
            return true;
        }

        // .coa sync <challengeId> [level] [player]
        // GM-only: sends the group CHALLENGES_SYNC popup (SMSG 0x59B) to a
        // player's party members for `challengeId`; accepting it on a member
        // answers CMSG 0x59C and activates the challenge for them.
        static bool HandleCoASyncCommand(ChatHandler* handler, uint32 challengeId,
            Optional<uint32> level, Optional<PlayerIdentifier> player)
        {
            if (!player)
                player = PlayerIdentifier::FromTargetOrSelf(handler);
            Player* p = player ? player->GetConnectedPlayer() : nullptr;
            if (!p)
            {
                handler->SendErrorMessage("Player must be online to send a sync request.");
                return false;
            }
            if (!p->GetGroup())
            {
                handler->SendErrorMessage("{} is not in a group.", p->GetName());
                return false;
            }

            uint32 lvl = level.value_or(ActiveChallengeLevel(p->GetGUID().GetCounter(), challengeId));
            std::vector<std::pair<uint32, uint32>> pairs = { { challengeId, lvl } };
            SendChallengeSyncToGroup(p, 60000, false, pairs, false, {});
            handler->PSendSysMessage("Sent CHALLENGES_SYNC (0x59B) for challenge {} level {} to {}'s party.",
                challengeId, lvl, p->GetName());
            return true;
        }

        // .coa challenges reload
        // GM-only: re-read coa_challenge_definition + coa_challenge_spell into
        // the in-memory cache (and rebuild the game-mode base map), so challenge
        // definitions can be edited/imported without restarting the server.
        static bool HandleCoAReloadCommand(ChatHandler* handler)
        {
            LoadChallengeDefinitions();
            handler->PSendSysMessage("Reloaded {} challenge definition(s) from the database.",
                DefCount());
            return true;
        }

        // .coa gamemode <mode> <on|off> [player]
        // GM-only: toggles a custom game mode for a character and
        // pushes the new state (SMSG 0x90B) + result (SMSG 0x5A5), mirroring
        // what CMSG 0x5A4 does. Useful to validate without the client UI.
        static bool HandleCoAGameModeCommand(ChatHandler* handler, std::string modeName, std::string onOff, Optional<PlayerIdentifier> player)
        {
            if (!player)
                player = PlayerIdentifier::FromTargetOrSelf(handler);
            Player* p = player ? player->GetConnectedPlayer() : nullptr;
            if (!p)
            {
                handler->SendErrorMessage("Player must be online.");
                return false;
            }

            GameModeDef const* mode = FindGameMode(modeName);
            if (!mode)
            {
                handler->SendErrorMessage("Unknown game mode '{}'.", modeName);
                return false;
            }

            bool enable = (onOff == "on" || onOff == "1" || onOff == "true" || onOff == "enable");
            ApplyGameModeToggle(p, mode, enable);
            handler->PSendSysMessage("Game mode {} {} for {}.", modeName,
                enable ? "enabled" : "disabled", p->GetName());
            return true;
        }

        // .coa fatigue <player> [value]
        // GM-only: inspect/set the FATIGUED_UNLESS_RESTED (Narcolepsy) counter
        // (0..FatigueMax) and re-push the native fatigue bar. `value` clamps.
        static bool HandleCoAFatigueCommand(ChatHandler* handler, Optional<PlayerIdentifier> player, Optional<uint32> value)
        {
            if (!player)
                player = PlayerIdentifier::FromTargetOrSelf(handler);
            Player* p = player ? player->GetConnectedPlayer() : nullptr;
            if (!p)
            {
                handler->SendErrorMessage("Player must be online.");
                return false;
            }

            uint32 guid = p->GetGUID().GetCounter();
            RefreshFatigueTracking(p);

            int32 fatigue = 0;
            bool resting = false;
            {
                std::lock_guard<std::mutex> lock(FatigueMutex);
                auto it = FatigueStates.find(guid);
                if (it == FatigueStates.end())
                {
                    handler->SendErrorMessage("{} has no active FATIGUED_UNLESS_RESTED challenge.", p->GetName());
                    return false;
                }
                if (value)
                {
                    it->second.fatigue = std::clamp<int32>((int32)*value, 0, (int32)FatigueMax());
                    it->second.ms = 0;
                }
                fatigue = it->second.fatigue;
                resting = it->second.resting;
            }

            SendFatigueBar(p, fatigue);
            handler->PSendSysMessage("Fatigue[{}] = {}/{} (resting={})",
                p->GetName(), fatigue, FatigueMax(), resting ? "yes" : "no");
            return true;
        }

        // .coa reward <challengeId> [level] [player]
        // GM-only: print the parsed reward entries for a challenge/level and,
        // when a player name is given (or target/self in-game), deliver them
        // (mail/achievement) using the same path as completion.
        static bool HandleCoARewardCommand(ChatHandler* handler, uint32 challengeId, Optional<uint32> level, Optional<std::string> playerName)
        {
            uint32 lvl = level ? *level : 1;
            std::vector<RewardDef> rewards = GetChallengeRewards(challengeId, lvl);
            if (rewards.empty())
            {
                handler->SendErrorMessage("Challenge {} level {} has no reward data.", challengeId, lvl);
                return false;
            }
            handler->PSendSysMessage("Rewards for challenge {} level {} ({} entries):",
                challengeId, lvl, rewards.size());
            for (RewardDef const& r : rewards)
                handler->PSendSysMessage("  item={} x{} ach={} special={} first={}",
                    r.itemId, r.amount, r.achievement, r.isSpecial ? 1 : 0, r.isFirst ? 1 : 0);

            Player* p = playerName ? ObjectAccessor::FindPlayerByName(*playerName) : nullptr;
            if (!p)
            {
                Optional<PlayerIdentifier> target = PlayerIdentifier::FromTargetOrSelf(handler);
                p = target ? target->GetConnectedPlayer() : nullptr;
            }
            if (!p)
            {
                handler->PSendSysMessage("Listed only (no online player; usage: .coa reward <id> [level] [player]).");
                return true;
            }
            GrantChallengeRewards(p, challengeId, lvl, true, true);
            handler->PSendSysMessage("Delivered to {} (check the mailbox / achievements).", p->GetName());
            return true;
        }

        // .coa e2e <player> <trialId> [intervalMs]
        // GM test harness (see CoAChallengeTests.cpp). Resets the character to
        // a freshly-created state and runs the trial's validation scenarios.
        static bool HandleCoAE2ECommand(ChatHandler* handler, std::string playerName, uint32 challengeId, Optional<uint32> stepMs)
        {
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            uint32 pauseMs = stepMs ? *stepMs : sConfigMgr->GetOption<uint32>("CoAChallenges.TestStepMs", 0);

            // Always begin from a clean slate: same full wipe as `.coa reset`
            // (challenge auras, gamemode/mode-lives, per-character tables,
            // client push, leaderboard, resurrect). Custom trials are kept.
            ResetCoaCharacterState(p);
            handler->PSendSysMessage("E2E: reset '{}' before running trial {}.", playerName, challengeId);

            // Money challenges run asynchronously (one step per world tick) so
            // the client renders every change.
            if (Test_StartVisualE2E(p, challengeId, pauseMs))
            {
                handler->PSendSysMessage("E2E trial {} ({}): scheduled, interval {} ms. Watch the client.",
                    challengeId, playerName, pauseMs);
                return true;
            }

            // Level-gated trials (NO_LEVEL_PAST_REQUIREMENTS, e.g. Boss Blitz):
            // synchronous assertions (XP-cap / forced-level must not kill).
            // Run BEFORE the visual runner: both gate on the same precondition,
            // so otherwise this path is unreachable and the regressions untested.
            // Returns -1 when N/A.
            if (int lg = Test_RunLevelGateE2E(p, challengeId); lg >= 0)
            {
                if (lg == 1)
                    handler->PSendSysMessage("E2E PASS");
                else
                    handler->SendErrorMessage("E2E FAIL");
                return true;
            }

            // Level-gated trials (Boss Blitz): asynchronous spawn+kill+levelup
            // (also used by `.coa e2emiss` with missPass=true).
            if (Test_StartLevelGateVisualE2E(p, challengeId, pauseMs, false))
            {
                handler->PSendSysMessage("E2E level-gate {} ({}): scheduled, interval {} ms. Watch the client.",
                    challengeId, playerName, pauseMs);
                return true;
            }

            // Fatigue trials (Narcolepsy): fill the bar -> sleep death.
            if (Test_StartFatigueVisualE2E(p, challengeId, pauseMs))
            {
                handler->PSendSysMessage("E2E fatigue {} ({}): scheduled, interval {} ms. Watch the client.",
                    challengeId, playerName, pauseMs);
                return true;
            }

            // Non-money challenges: synchronous completion smoke test.
            if (Test_RunCompletionE2E(p, challengeId))
                handler->PSendSysMessage("E2E PASS");
            else
                handler->SendErrorMessage("E2E FAIL");
            return true;
        }

        // .coa e2emiss <player> <trialId> [intervalMs]
        // Sad path only (level-gated trials): every gate is force-leveled
        // WITHOUT its kill. Validates the XP-cap invariant that a reached-but-
        // unmet objective must not kill the character.
        static bool HandleCoAE2EMissCommand(ChatHandler* handler, std::string playerName, uint32 challengeId, Optional<uint32> stepMs)
        {
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            uint32 pauseMs = stepMs ? *stepMs : sConfigMgr->GetOption<uint32>("CoAChallenges.TestStepMs", 0);

            ResetCoaCharacterState(p);
            handler->PSendSysMessage("E2E(miss): reset '{}' before running trial {}.", playerName, challengeId);

            if (Test_StartLevelGateVisualE2E(p, challengeId, pauseMs, true))
            {
                handler->PSendSysMessage("E2E miss {} ({}): scheduled, interval {} ms. Watch the client.",
                    challengeId, playerName, pauseMs);
                return true;
            }

            handler->SendErrorMessage("Trial {} is not a level-gated trial (no miss path).", challengeId);
            return false;
        }

        // .coa ruletest <player> <id>
        // GM-only: activates the challenge and checks the custom rules through
        // the real hook dispatchers (NO_GUILD_BANK / NO_MANASTORM / N/A realm).
        static bool HandleCoARuleTestCommand(ChatHandler* handler, std::string playerName, uint32 challengeId)
        {
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            if (Test_CheckRuleGate(p, challengeId))
                handler->PSendSysMessage("RULE TEST PASS (challenge {})", challengeId);
            else
                handler->SendErrorMessage("RULE TEST FAIL (challenge {})", challengeId);
            return true;
        }

        // .coa ruletestall <player>
        // GM-only: runs a behavioral gate test for EVERY implemented rule,
        // driving the real hook dispatchers (see Test_RuleGates).
        static bool HandleCoARuleTestAllCommand(ChatHandler* handler, std::string playerName)
        {
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            if (Test_RuleGates(p))
                handler->PSendSysMessage("RULE GATES PASS");
            else
                handler->SendErrorMessage("RULE GATES FAIL (see per-rule lines above)");
            return true;
        }

        // .coa conditiontest <player>
        // GM-only: exercises every implemented activation condition through the
        // real EvaluateConditions, using a synthetic condition string.
        static bool HandleCoAConditionTestCommand(ChatHandler* handler, std::string playerName)
        {
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            if (Test_ConditionGates(p))
                handler->PSendSysMessage("CONDITION GATES PASS");
            else
                handler->SendErrorMessage("CONDITION GATES FAIL (see per-condition lines above)");
            return true;
        }

        // .coa flag <player> <FLAG> [on|off]
        // GM-only: set/clear a persistent activation-condition flag on a
        // character (e.g. OUTSIDE_BANK) to exercise the activation gate without
        // performing the real action. Then `.coa trial check <id>`.
        static bool HandleCoAFlagCommand(ChatHandler* handler, std::string playerName,
            std::string flag, Optional<bool> on)
        {
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            uint32 const guid = p->GetGUID().GetCounter();
            if (!on || *on)
            {
                SetConditionFlag(guid, flag.c_str());
                handler->PSendSysMessage("Set condition flag '{}' for {}.", flag, p->GetName());
            }
            else
            {
                ClearConditionFlag(guid, flag);
                handler->PSendSysMessage("Cleared condition flag '{}' for {}.", flag, p->GetName());
            }
            return true;
        }

        // .coa ruletestparty <p1> <p2>
        // GM-only: drives the rules whose check needs a second player
        // (trade / group / PvP range). Both must be online.
        static bool HandleCoARuleTestPartyCommand(ChatHandler* handler, std::string p1, std::string p2)
        {
            Player* a = ObjectAccessor::FindPlayerByName(p1);
            Player* b = ObjectAccessor::FindPlayerByName(p2);
            if (!a || !b)
            {
                handler->SendErrorMessage("Both players must be online ('{}' / '{}').", p1, p2);
                return false;
            }
            if (Test_PartyRuleGates(a, b))
                handler->PSendSysMessage("PARTY RULE GATES PASS");
            else
                handler->SendErrorMessage("PARTY RULE GATES FAIL (see lines above)");
            return true;
        }

        // .coa ruleaudit <player>
        // GM-only: sweeps every generated challenge ID and compares the
        // declared rules with the real hook dispatchers; prints divergences.
        static bool HandleCoARuleAuditCommand(ChatHandler* handler, std::string playerName)
        {
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            Test_AuditAllRules(p);
            handler->PSendSysMessage("Rule audit finished for {} (check chat/log for divergences).", playerName);
            return true;
        }

        // .coa auditdefs <player>
        // GM-only: data-integrity sweep over every definition (rules/conditions/
        // objectives known + auras/rewards resolvable); prints divergences.
        static bool HandleCoAAuditDefsCommand(ChatHandler* handler, std::string playerName)
        {
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            Test_AuditAllDefs(p);
            handler->PSendSysMessage("Definition audit finished for {} (check chat/log for divergences).", playerName);
            return true;
        }

        // .coa cachetoctou <player>
        // GM-only: deterministically forces the cache TOCTOU window (an invalidation
        // between the DB load and the cache publish) and checks the generation guard,
        // running each cache with the guard OFF (bug must appear) and ON (bug gone).
        static bool HandleCoACacheToctouCommand(ChatHandler* handler, std::string playerName)
        {
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            if (Test_CacheToctou(p))
                handler->PSendSysMessage("CACHE TOCTOU PASS");
            else
                handler->SendErrorMessage("CACHE TOCTOU FAIL (see lines above)");
            return true;
        }

        // .coa pettest <player>
        // GM-only: regression test for Issue #4343 (trial auras applied to summons).
        static bool HandleCoAPetTestCommand(ChatHandler* handler, std::string playerName)
        {
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            if (Test_PetTrialAuras(p))
                handler->PSendSysMessage("PET TRIAL AURAS PASS");
            else
                handler->SendErrorMessage("PET TRIAL AURAS FAIL (see lines above)");
            return true;
        }

        // .coa reset <player>      -> clears only the challenge/trial state
        //                             (active/failures/completions/objectives/
        //                             conditions + auras/meters)
        // .coa reset all <player>  -> also level 1, 0 money, no auras
        // Keeps inventory/equipment and bank in both modes.
        static bool HandleCoAResetCommand(ChatHandler* handler, std::string first, Optional<std::string> second)
        {
            bool all = false;
            std::string playerName = first;
            if (first == "all")
            {
                if (!second)
                {
                    handler->SendErrorMessage("Usage: .coa reset all <player>");
                    return false;
                }
                all = true;
                playerName = *second;
            }
            Player* p = ObjectAccessor::FindPlayerByName(playerName);
            if (!p)
            {
                handler->SendErrorMessage("Player '{}' is not online.", playerName);
                return false;
            }
            if (all)
            {
                HardResetCharacter(p);
                handler->PSendSysMessage(
                    "Hard reset ALL for {}: level 1, 0 money, no CoA state, repairs, "
                    "spells/talents/skills unlearned, quest log cleared.", playerName);
            }
            else
            {
                ResetChallengeState(p);
                handler->PSendSysMessage("Reset challenge state for {} (level/money/items kept).", playerName);
            }
            return true;
        }

        // .coa prestige [player] [on|off] -> grant/revoke the prestige aura
        // (COA_PRESTIGE_AURA) that gates IsPrestige challenges and drives the
        // client's IsPrestiged()/prestige UI. Toggles when on/off is omitted.
        static bool HandleCoAPrestigeCommand(ChatHandler* handler,
            Optional<PlayerIdentifier> player, Optional<uint32> enable)
        {
            if (!player)
                player = PlayerIdentifier::FromTargetOrSelf(handler);
            Player* p = player ? player->GetConnectedPlayer() : nullptr;
            if (!p)
            {
                handler->SendErrorMessage("Player must be online.");
                return false;
            }

            if (!sSpellMgr->GetSpellInfo(COA_PRESTIGE_AURA))
            {
                handler->SendErrorMessage(
                    "Spell {} (prestige aura) is unknown to the server.", COA_PRESTIGE_AURA);
                return false;
            }

            bool on = enable ? (*enable != 0) : !p->HasAura(COA_PRESTIGE_AURA);
            if (on)
            {
                p->AddAura(COA_PRESTIGE_AURA, p);
                handler->PSendSysMessage("{} is now PRESTIGED (aura {}).", p->GetName(), COA_PRESTIGE_AURA);
            }
            else
            {
                p->RemoveAurasDueToSpell(COA_PRESTIGE_AURA);
                handler->PSendSysMessage("{} is no longer prestiged.", p->GetName());
            }
            return true;
        }

        // .coa envtest <type> [damage] [player]
        // GM-only: applies environmental damage through the real core path so
        // the env hook (death cause + FAILABLE_NO_FALLING / FLOOR_IS_LAVA) can
        // be validated without the client. type = EnviromentalDamage
        // (0 Exhausted, 1 Drowning, 2 Fall, 3 Lava, 4 Slime, 5 Fire, 6 FallToVoid).
        static bool HandleCoAEnvTestCommand(ChatHandler* handler, uint32 type,
            Optional<uint32> damage, Optional<std::string> playerName)
        {
            Player* p = playerName ? ObjectAccessor::FindPlayerByName(*playerName) : nullptr;
            if (!p)
            {
                Optional<PlayerIdentifier> target = PlayerIdentifier::FromTargetOrSelf(handler);
                p = target ? target->GetConnectedPlayer() : nullptr;
            }
            if (!p)
            {
                handler->SendErrorMessage("Player must be online (usage: .coa envtest <type> [damage] [player]).");
                return false;
            }

            uint32 dmg = damage.value_or(p->GetMaxHealth());
            uint32 applied = p->EnvironmentalDamage(static_cast<EnviromentalDamage>(type), dmg);
            handler->PSendSysMessage("Applied environmental type {} ({} raw) to {}: {} applied.",
                type, dmg, p->GetName(), applied);
            return true;
        }
    };
    // MiscScript: block opening the auction house when the player holds a
    // NO_AUCTIONHOUSE challenge (the bid/buyout path is gated separately).
    class CoAChallengesMisc : public MiscScript
    {
    public:
        CoAChallengesMisc() : MiscScript("CoAChallengesMisc", { MISCHOOK_CAN_SEND_AUCTIONHELLO }) { }

        bool CanSendAuctionHello(WorldSession const* session, ObjectGuid /*guid*/, Creature* /*creature*/) override
        {
            Player* player = session ? session->GetPlayer() : nullptr;
            MarkOutsideInteraction(player, "OUTSIDE_AH");
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_AUCTIONHOUSE")
                || NoOutsideInteraction(player))
            {
                if (player)
                    NotifyPlayer(player, "Your challenge forbids using the auction house.");
                return false;
            }
            return true;
        }
    };
    // GuildScript: block the guild bank list for NO_GUILD_BANK challenges.
    // Withholding SMSG_GUILD_BANK_LIST keeps the client from opening/using it.
    class CoAChallengesGuild : public GuildScript
    {
    public:
        CoAChallengesGuild() : GuildScript("CoAChallengesGuild", { GUILDHOOK_CAN_GUILD_SEND_BANK_LIST, GUILDHOOK_ON_ITEM_MOVE, GUILDHOOK_ON_MEMBER_WITDRAW_MONEY }) { }

        bool CanGuildSendBankList(Guild const* /*guild*/, WorldSession* session, uint8 /*tabId*/, bool /*sendAllSlots*/) override
        {
            Player* player = session ? session->GetPlayer() : nullptr;
            if (PlayerHasRule(player, "CHALLENGE_RULES_TYPE_NO_GUILD_BANK")
                || NoOutsideInteraction(player))
            {
                if (player)
                    NotifyPlayer(player, "Your challenge forbids using the guild bank.");
                return false;
            }
            return true;
        }

        // OUTSIDE_INTERACTION gate: withdrawing items/money from the guild bank
        // is an outside interaction.
        void OnItemMove(Guild* /*guild*/, Player* player, Item* /*pItem*/, bool isSrcBank, uint8 /*srcContainer*/,
            uint8 /*srcSlotId*/, bool /*isDestBank*/, uint8 /*destContainer*/, uint8 /*destSlotId*/) override
        {
            if (isSrcBank)
                MarkOutsideInteraction(player, "OUTSIDE_GUILD_BANK");
        }

        void OnMemberWitdrawMoney(Guild* /*guild*/, Player* player, uint32& /*amount*/, bool /*isRepair*/) override
        {
            MarkOutsideInteraction(player, "OUTSIDE_GUILD_BANK");
        }
    };
    // GroupScript: leaving/disbanding a group fails SharedFate (Duo/Trio)
    // challenges — the About says "you cannot leave the group, or you'll
    // instantly fail". The removed member is already out of the group when
    // OnRemoveMember fires, so it is passed explicitly.
    class CoAChallengesGroup : public GroupScript
    {
    public:
        CoAChallengesGroup() : GroupScript("CoAChallengesGroup", { GROUPHOOK_ON_REMOVE_MEMBER, GROUPHOOK_ON_DISBAND }) { }

        void OnRemoveMember(Group* group, ObjectGuid guid, RemoveMethod /*method*/, ObjectGuid /*kicker*/, char const* /*reason*/) override
        {
            if (group && (group->isBGGroup() || group->isBFGroup()))
                return;
            FailSharedFateHolders(group, guid);
        }

        void OnDisband(Group* group) override
        {
            if (group && (group->isBGGroup() || group->isBFGroup()))
                return;
            FailSharedFateHolders(group, ObjectGuid::Empty);
        }
    };

    // True when the spell (or a spell it triggers, up to depth 2) summons/tames
    // a pet or minion. Covers summons hidden behind a trigger, e.g.
    // "Harness Animal Spirit" -> "Tame Beast" (SPELL_EFFECT_TAMECREATURE).
    // `companion` is set when the summoned creature is a non-combat pet/critter
    // (a vanity companion), which the NO_PETS_OR_MINIONS rule must not block.
    static bool SpellIsPetSummon(SpellInfo const* info, int depth, bool& companion)
    {
        if (!info || depth > 2)
            return false;
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
        {
            switch (info->Effects[i].Effect)
            {
                case SPELL_EFFECT_SUMMON:
                case SPELL_EFFECT_SUMMON_PET:
                    if (CreatureTemplate const* ct = sObjectMgr->GetCreatureTemplate(uint32(info->Effects[i].MiscValue)))
                        if (ct->type == CREATURE_TYPE_NON_COMBAT_PET || ct->type == CREATURE_TYPE_CRITTER)
                            companion = true;
                    return true;
                case SPELL_EFFECT_TAMECREATURE:
                case SPELL_EFFECT_CREATE_TAMED_PET:
                    return true;
                default:
                    break;
            }
            if (uint32 trig = info->Effects[i].TriggerSpell)
                if (SpellInfo const* ti = sSpellMgr->GetSpellInfo(trig))
                    if (SpellIsPetSummon(ti, depth + 1, companion))
                        return true;
        }
        return false;
    }

    // NO_PETS_OR_MINIONS (D.E.H.T.A 209/423 + MEGA Spellbind Roulette 429/430):
    // block pet/minion summon spells. The trial's About: "pets of any kind
    // (even demons) would be considered cruel enslavement". Warlock demons and
    // hunter pets use SPELL_EFFECT_SUMMON_PET (56); guardians/minions use
    // SPELL_EFFECT_SUMMON (28). The rule lookup (a DB query) only runs when
    // the spell is summon-, profession- or unlearn-related, so it stays rare.
    class CoAChallengesSpells : public AllSpellScript
    {
    public:
        CoAChallengesSpells() : AllSpellScript("CoAChallengesSpells", { ALLSPELLHOOK_ON_SPELL_CHECK_CAST }) { }

        void OnSpellCheckCast(Spell* spell, bool /*strict*/, SpellCastResult& res) override
        {
            if (!spell)
                return;
            Unit* caster = spell->GetCaster();
            if (!caster || !caster->IsPlayer())
                return;
            SpellInfo const* info = spell->GetSpellInfo();
            if (!info)
                return;

            bool summons = false;
            bool companion = false;
            bool professionSpell = false;
            bool unlearnSpec = false;
            for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            {
                switch (info->Effects[i].Effect)
                {
                    case SPELL_EFFECT_SUMMON_PET:   // 56: hunter/warlock pets, demons
                    case SPELL_EFFECT_SUMMON:       // 28: guardians/minions
                        summons = true;
                        if (CreatureTemplate const* ct = sObjectMgr->GetCreatureTemplate(uint32(info->Effects[i].MiscValue)))
                            if (ct->type == CREATURE_TYPE_NON_COMBAT_PET || ct->type == CREATURE_TYPE_CRITTER)
                                companion = true;
                        break;
                    case SPELL_EFFECT_SKILL_STEP:   // 44: learn a profession rank
                    case SPELL_EFFECT_SKILL:        // 118: learn a skill
                        if (IsProfessionSkill(uint32(info->Effects[i].MiscValue)))
                            professionSpell = true;
                        break;
                    case SPELL_EFFECT_UNLEARN_SPECIALIZATION: // 133: unlearn a profession specialty
                        unlearnSpec = true;
                        break;
                    default:
                        break;
                }
            }
            // Also catch pets/tames hidden behind a triggered spell.
            if (!summons && SpellIsPetSummon(info, 0, companion))
                summons = true;
            if (!professionSpell)
            {
                // Profession ability casts (craft/gather/learn via trainer)
                // belong to a profession skill line.
                SkillLineAbilityMapBounds bounds = sSpellMgr->GetSkillLineAbilityMapBounds(info->Id);
                for (auto it = bounds.first; it != bounds.second && !professionSpell; ++it)
                    if (IsProfessionSkill(it->second->SkillLine))
                        professionSpell = true;
            }

            Player* pl = caster->ToPlayer();

            // Spellbind Roulette: casting the marked spell fails the challenge
            // (FAILABLE variants) or is blocked (plain). Only the player's own
            // (non-triggered) casts count: a buff/proc that re-triggers the
            // marked ability has no separate cast to punish, so it must not
            // consume the mark nor fail the trial.
            if (!spell->IsTriggered() && !spell->GetTriggeredByAuraSpellInfo())
            {
                SpellbindMark mark;
                // Peek only: the mark is consumed in the failable branch (death
                // ends the trial). The plain variant must keep it so the block
                // applies until the interval rerolls it.
                if (SpellbindConsumeMark(pl->GetGUID().GetCounter(), info->Id, mark, /*consume=*/false))
                {
                    if (mark.failable)
                    {
                        // Queue the fail+death for the player's next update: this
                        // is the spell CheckCast hook, and mutating world state
                        // (DB/auras/lethal damage) here is reentrant. Clear the
                        // mark now so a second cast this tick can't re-trigger it.
                        SpellbindClearMark(pl->GetGUID().GetCounter());
                        SpellbindPendingKill pending;
                        pending.challengeId = mark.challengeId;
                        pending.level = mark.level;
                        pending.name = mark.name.empty() ? "Spellbind Roulette" : mark.name;
                        if (QueryResult r = CharacterDatabase.Query(
                                "SELECT deaths FROM coa_character_challenge WHERE guid = {} AND challengeId = {}",
                                pl->GetGUID().GetCounter(), mark.challengeId))
                            pending.deaths = r->Fetch()[0].Get<uint32>();
                        SpellbindQueueKill(pl->GetGUID().GetCounter(), pending);
                        NotifyPlayer(pl, "You cast a spell marked for death and it kills you.");
                        LOG_INFO("module.coa_challenges",
                            "Spellbind: {} cast marked spell {}, queued fail+death (challenge {})",
                            pl->GetName(), info->Id, mark.challengeId);
                    }
                    else
                    {
                        NotifyPlayer(pl, "That spell is forbidden by your challenge.");
                        res = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
                        return;
                    }
                }
            }

            // NO_PORTALS ("Not Thinking with Portals"): no player-cast portals or
            // teleports (mage Teleport/Portal and similar map-changing spells).
            if (RuleMaskHas(pl, REGEN_NO_PORTALS))
            {
                bool portal = false;
                for (uint8 i = 0; i < MAX_SPELL_EFFECTS && !portal; ++i)
                {
                    switch (info->Effects[i].Effect)
                    {
                        case SPELL_EFFECT_TELEPORT_UNITS:
                        case SPELL_EFFECT_TELEPORT_UNITS_FACE_CASTER:
                        case SPELL_EFFECT_TRANS_DOOR:
                            portal = true;
                            break;
                        default:
                            break;
                    }
                }
                if (portal)
                {
                    NotifyPlayer(pl, "Your challenge forbids using portals.");
                    res = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
                    return;
                }
            }

            // CAST_RANGE_LIMITED_TO_MELEE ("Shortsighted"): no cast whose reach
            // exceeds melee range.
            if (RuleMaskHas(pl, REGEN_CAST_RANGE))
            {
                float const maxRange = std::max(info->GetMaxRange(false, pl, spell),
                                                info->GetMaxRange(true, pl, spell));
                if (maxRange > NOMINAL_MELEE_RANGE)
                {
                    NotifyPlayer(pl, "Your challenge limits your cast range to melee.");
                    res = SPELL_FAILED_OUT_OF_RANGE;
                    return;
                }
            }

            // NO_PROFESSIONS: unable to learn or use professions of any kind.
            if (professionSpell && PlayerHasRule(pl, "CHALLENGE_RULES_TYPE_NO_PROFESSIONS"))
            {
                NotifyPlayer(pl, "Your challenge forbids using professions.");
                res = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
                return;
            }
            // CANNOT_UNLEARN_PROFESSIONS: profession choices are permanent
            // (trainer-gossip unlearning; the spellbook path is dropped in CanPacketReceive).
            if (unlearnSpec && PlayerHasRule(pl, "CHALLENGE_RULES_TYPE_CANNOT_UNLEARN_PROFESSIONS"))
            {
                NotifyPlayer(pl, "Your profession choices are permanent.");
                res = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
                return;
            }
            if (!summons)
                return;

            // NO_COMPANIONS: no vanity companion pets (combat minions still allowed).
            if (companion && PlayerHasRule(pl, "CHALLENGE_RULES_TYPE_NO_COMPANIONS"))
            {
                NotifyPlayer(pl, "Your challenge forbids companion pets.");
                res = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
                return;
            }
            // NO_PETS_OR_MINIONS refers to combat pets/summons (incl. totems): the
            // non-combat (vanity) companions are explicitly allowed, as on Ascension.
            if (!companion && PlayerHasRule(pl, "CHALLENGE_RULES_TYPE_NO_PETS_OR_MINIONS"))
            {
                NotifyPlayer(pl, "Your challenge forbids pets and minions.");
                res = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
            }
        }
    };

    // Combat rules enforced through UnitScript (Unit::DealDamage / heal /
    // melee-outcome roll): NO_DAMAGE, NO_KILL_BEASTS/HUMANOIDS, NO_HEALING,
    // CANNOT_DODGE_BLOCK_OR_PARRY, CAN_BE_CRITTED_BY_ANY_ABILITY.
    class CoAChallengesLoot : public GlobalScript
    {
    public:
        CoAChallengesLoot() : GlobalScript("CoAChallengesLoot",
            { GLOBALHOOK_ON_ALLOWED_FOR_PLAYER_LOOT_CHECK, GLOBALHOOK_ON_ALLOWED_TO_LOOT_CONTAINER_CHECK }) { }

        bool OnAllowedForPlayerLootCheck(Player const* player, ObjectGuid source) override
        {
            return !TappingAllowsLoot(player, source);
        }

        bool OnAllowedToLootContainerCheck(Player const* player, ObjectGuid source) override
        {
            return !TappingAllowsLoot(player, source);
        }

    private:
        static bool TappingAllowsLoot(Player const* player, ObjectGuid source)
        {
            if (!player || !source.IsCreatureOrVehicle())
                return true;
            return TappingAllowsRewards(player, ObjectAccessor::GetCreature(*player, source));
        }
    };

    // STRICT_CHALLENGE_RESTRICTED_TAPPING already denies rewards (loot/xp/rep/
    // quest credit) to a player outside the tapper's restricted challenge via
    // TappingAllowsRewards; this refusal is the matching attack-time block, so
    // a mismatched-challenge player cannot fight the mob at all (Ascension
    // parity), throttled per player so repeated validity checks do not spam chat.
    constexpr uint32 TappingNoticeIntervalMs = 3000;
    constexpr char const* TappingNoticeKey = "coa_challenges.tapping_notice";

    struct TappingNotice : DataMap::Base
    {
        uint32 Last = 0;
    };

    // CanUnitAttack (UnitScript / Unit::_IsValidAttackTarget) is evaluated by AI
    // target-validity scans, AoE splash and threat-list revalidation far more
    // often than by an actual attack attempt, so the PVE_ONLY refusal below is
    // throttled per player like mod-scrolls-of-retreat's own refusal notice.
    constexpr uint32 PveOnlyNoticeIntervalMs = 3000;
    constexpr char const* PveOnlyNoticeKey = "coa_challenges.pve_only_notice";

    struct PveOnlyNotice : DataMap::Base
    {
        uint32 Last = 0;
    };

    class CoAChallengesUnit : public UnitScript
    {
    public:
        CoAChallengesUnit() : UnitScript("CoAChallengesUnit", true,
            { UNITHOOK_ON_DAMAGE, UNITHOOK_ON_HEAL, UNITHOOK_MODIFY_HEAL_RECEIVED, UNITHOOK_ON_BEFORE_ROLL_MELEE_OUTCOME_AGAINST, UNITHOOK_CAN_UNIT_ATTACK,
              UNITHOOK_ON_UNIT_EXIT_COMBAT }) { }

        void OnUnitExitCombat(Unit* unit) override
        {
            RestoreAdventureHealth(unit);
        }

        // Open-world PvP range rules (from the client localization):
        //  - ONLY_PVP_IN_5_LEVEL_RANGE: "You can only PvP with players 5 levels
        //    higher or lower than you in the open world."
        //  - ONLY_PVP_SAME_LEVEL_IF_MAX_LEVEL: "You will only be able to PvP with
        //    players at max level if you are also at max level."
        // Gate is Unit::_IsValidAttackTarget (both melee and spells). Pets/
        // guardians are resolved to their owner. Battlegrounds/arenas keep their
        // own rules (only the open world is restricted).
        bool CanUnitAttack(Unit const* attacker, Unit const* target, SpellInfo const* /*spell*/) override
        {
            if (!attacker || !target)
                return true;
            Player* a = attacker->GetCharmerOrOwnerPlayerOrPlayerItself();
            if (!a)
                return true;

            // STRICT_CHALLENGE_RESTRICTED_TAPPING: a mismatched-challenge player
            // cannot attack a mob already tapped for someone else's restricted
            // challenge (creature targets only; TappingAllowsRewards is a no-op
            // for an untapped mob or a same-challenge/no-challenge tapper).
            if (Creature const* creatureTarget = target->ToCreature())
            {
                if (!TappingAllowsRewards(a, creatureTarget))
                {
                    if (a->GetSession())
                    {
                        TappingNotice* notice = a->CustomData.GetDefault<TappingNotice>(TappingNoticeKey);
                        uint32 const now = getMSTime();
                        if (!notice->Last || now - notice->Last >= TappingNoticeIntervalMs)
                        {
                            notice->Last = now;
                            NotifyPlayer(a, "This target is already tapped by another challenge.");
                        }
                    }
                    return false;
                }
            }

            Player* t = target->GetCharmerOrOwnerPlayerOrPlayerItself();
            if (!t || a == t)
                return true;

            // PVE_ONLY (Adventure Mode): cannot fight other players at all.
            // KNOWN LIMITATION: only attack is blocked; flag/BG/arena scope not
            // modelled (the client tooltip is empty; About 211 doesn't mention PvP).
            if (PlayerHasRule(a, "CHALLENGE_RULES_TYPE_PVE_ONLY"))
            {
                if (a->GetSession())
                {
                    PveOnlyNotice* notice = a->CustomData.GetDefault<PveOnlyNotice>(PveOnlyNoticeKey);
                    uint32 const now = getMSTime();
                    if (!notice->Last || now - notice->Last >= PveOnlyNoticeIntervalMs)
                    {
                        notice->Last = now;
                        NotifyPlayer(a, "Your challenge is PvE only: you cannot fight players.");
                    }
                }
                return false;
            }

            if (a->GetMap()->IsBattlegroundOrArena())
                return true;

            bool blocked = false;
            if (PlayerHasRule(a, "CHALLENGE_RULES_TYPE_ONLY_PVP_IN_5_LEVEL_RANGE")
                || PlayerHasRule(t, "CHALLENGE_RULES_TYPE_ONLY_PVP_IN_5_LEVEL_RANGE"))
            {
                int diff = int(a->GetLevel()) - int(t->GetLevel());
                if (diff < 0) diff = -diff;
                if (diff > 5)
                    blocked = true;
            }
            if (!blocked
                && (PlayerHasRule(a, "CHALLENGE_RULES_TYPE_ONLY_PVP_SAME_LEVEL_IF_MAX_LEVEL")
                    || PlayerHasRule(t, "CHALLENGE_RULES_TYPE_ONLY_PVP_SAME_LEVEL_IF_MAX_LEVEL")))
            {
                if (a->IsMaxLevel() != t->IsMaxLevel())
                    blocked = true;
            }
            if (blocked && a->GetSession())
                NotifyPlayer(a,
                    "Your challenge restricts who you may fight in PvP.");
            return !blocked;
        }

        void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
        {
            if (!attacker || !victim || !damage)
                return;
            // Resolve the controlling player: a pet/guardian must not be able to
            // bypass NO_DAMAGE / NO_KILL_* by dealing the damage itself.
            Player* pl = attacker->GetCharmerOrOwnerPlayerOrPlayerItself();
            if (!pl)
                return;

            // NO_DAMAGE: the player deals no damage at all.
            if (PlayerHasRule(pl, "CHALLENGE_RULES_TYPE_NO_DAMAGE"))
            {
                damage = 0;
                return;
            }

            ScaleAdventureHealth(pl, victim);

            // NO_KILL_*: prevent the killing blow against forbidden creature types.
            if (victim->IsCreature() && damage >= victim->GetHealth() && victim->GetHealth() > 1)
            {
                uint32 type = victim->ToCreature()->GetCreatureTemplate()->type;
                if (type == CREATURE_TYPE_BEAST && PlayerHasRule(pl, "CHALLENGE_RULES_TYPE_NO_KILL_BEASTS"))
                    damage = victim->GetHealth() - 1;
                else if (type == CREATURE_TYPE_HUMANOID
                    && PlayerHasRule(pl, "CHALLENGE_RULES_TYPE_NO_KILL_HUMANOIDS"))
                    damage = victim->GetHealth() - 1;
            }
        }

        void OnHeal(Unit* /*healer*/, Unit* receiver, uint32& gain) override
        {
            // NO_HEALING / NO_HEALING_UNLESS_RESTED: "cannot receive healing",
            // so check the RECEIVER (the healer's own rules don't apply here).
            if (receiver && receiver->IsPlayer() && HealBlocked(receiver->ToPlayer()))
                gain = 0;
        }

        // NO_HEALING_UNLESS_BANDAGING: this hook still carries the heal spell,
        // so flag a bandage heal for HealBlocked (which is spell-agnostic). The
        // two core dispatch sites pass (target, healer) and, due to an ordering
        // quirk in Unit::HealBySpell, (healer, target): flag both players.
        void ModifyHealReceived(Unit* target, Unit* healer, uint32& /*heal*/, SpellInfo const* spellInfo) override
        {
            if (!IsBandageSpell(spellInfo))
                return;
            if (target && target->IsPlayer())
                AllowBandageHeal(target->GetGUID().GetCounter());
            if (healer && healer->IsPlayer())
                AllowBandageHeal(healer->GetGUID().GetCounter());
        }

        void OnBeforeRollMeleeOutcomeAgainst(Unit const* /*attacker*/, Unit const* victim,
            WeaponAttackType /*attType*/, int32& /*attackerMaxSkillValueForLevel*/,
            int32& /*victimMaxSkillValueForLevel*/, int32& /*attackerWeaponSkill*/,
            int32& /*victimDefenseSkill*/, int32& crit_chance, int32& /*miss_chance*/,
            int32& dodge_chance, int32& parry_chance, int32& block_chance) override
        {
            if (!victim || !victim->IsPlayer())
                return;
            Player* pl = const_cast<Player*>(victim->ToPlayer());
            if (PlayerHasRule(pl, "CHALLENGE_RULES_TYPE_CANNOT_DODGE_BLOCK_OR_PARRY"))
            {
                dodge_chance = 0;
                parry_chance = 0;
                block_chance = 0;
            }
            if (PlayerHasRule(pl, "CHALLENGE_RULES_TYPE_CAN_BE_CRITTED_BY_ANY_ABILITY"))
                crit_chance = 10000;
        }
    };

    class CoAChallengesAccount : public AccountScript
    {
    public:
        CoAChallengesAccount() : AccountScript("CoAChallengesAccount", { ACCOUNTHOOK_ON_BEFORE_ACCOUNT_DELETE }) { }

        void OnBeforeAccountDelete(uint32 account) override
        {
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_DEL_COA_ACCOUNT_CHALLENGE_COMPLETIONS);
            statement->SetData(0, account);
            CharacterDatabase.DirectExecute(statement);
        }
    };

    class CoAChallengesAllCreature : public AllCreatureScript
    {
    public:
        CoAChallengesAllCreature() : AllCreatureScript("CoAChallengesAllCreature") { }

        void OnCreatureAddWorld(Creature* creature) override
        {
            if (!creature)
                return;

            Player* owner = GetPlayerOwner(creature);
            if (!owner)
                return;

            ApplyActiveChallengeSpellsToCreature(owner, creature);
        }
    };

} // namespace CoAChallenges

void Addmod_coa_challengesScripts()
{
    RegisterAscensionClientConfig(&CoAChallenges::AppendClientConfig);
    LocalLevelScaling::ChallengeBlocksOwner.store(&CoAChallenges::LevelScalingBlocks, std::memory_order_relaxed);
    new CoAChallenges::CoAChallengesPlayer();
    new CoAChallenges::CoAChallengesWorld();
    new CoAChallenges::CoAChallengesServer();
    new CoAChallenges::CoAChallengesUnit();
    new CoAChallenges::CoAChallengesLoot();
    new CoAChallenges::CoAChallengesCommand();
    new CoAChallenges::CoAChallengesMisc();
    new CoAChallenges::CoAChallengesGuild();
    new CoAChallenges::CoAChallengesGroup();
    new CoAChallenges::CoAChallengesSpells();
    new CoAChallenges::CoAChallengesAllCreature();
    new CoAChallenges::CoAChallengesAccount();
}
