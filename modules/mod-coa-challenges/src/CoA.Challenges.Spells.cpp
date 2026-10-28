// mod-coa-challenges (review split): CoA.Challenges.Spells.cpp
// Mechanical split of review-CoAChallenges.cpp; no logic changes.
#include "CoA.Challenges.Review.h"
#include "Pet.h"
#include "TemporarySummon.h"

namespace CoAChallenges
{

    char const* ChallengeResponseString(uint32 code)
    {
        switch (code)
        {
            case 0:  return "CHALLENGE_START_OK";
            case 1:  return "CHALLENGE_START_NOT_FOUND";
            case 2:  return "CHALLENGE_START_NO_REWARDS";
            case 3:  return "CHALLENGE_START_WRONG_GAME_MODE";
            case 4:  return "CHALLENGE_START_ALREADY_ACTIVE";
            case 5:  return "CHALLENGE_START_EXCLUSIVE_GROUP_ACTIVE";
            case 6:  return "CHALLENGE_START_GAME_EVENT_NOT_ACTIVE";
            case 7:  return "CHALLENGE_START_DISABLED";
            case 8:  return "CHALLENGE_START_CONDITIONS_NOT_MET";
            case 9:  return "CHALLENGE_START_PREVIOUS_LEVEL_NOT_COMPLETED";
            case 10: return "CHALLENGE_START_OUTSIDE_INTERACTION";
            case 11: return "CHALLENGE_START_NOT_PRESTIGE";
            case 12: return "CHALLENGE_START_RULE_BROKEN";
            case 13: return "CHALLENGE_START_PARTICIPATING_IN_TRIAL";
            case 14: return "CHALLENGE_START_PARTICIPATING_IN_CHALLENGE";
            default: return "CHALLENGE_START_DISABLED";
        }
    }

    void SendChallengeResponse(Player* player, uint16 opcode, uint32 challengeID, uint32 level, uint32 code, std::string const& respStr)
    {
        WorldSession* session = player->GetSession();
        if (!session)
            return;

        WorldPacket data(opcode, 64);
        data << uint32(challengeID);
        data << uint32(level);
        data << uint32(code);
        data << uint32(0);
        data << uint32(0);
        data << uint8(0);
        AppendConfigString(data, respStr);

        session->SendPacket(&data);
        LOG_INFO("module.coa_challenges", "Sent SMSG 0x{:X} to {}: challengeID={} level={} code={}",
            opcode, player->GetName(), challengeID, level, code);
    }

    // Active-list push: u32 n + n x 26-byte entries. Fires
    // CHALLENGE_ACTIVE_LIST_CHANGED (no sound).
    //
    // Layout decoded from Extensions.dll (INSERT 0x12FAB0 + LOOKUP 0x8EFA0 +
    // IsChallengeActive 0x142CD0 + handler 0x138050):
    //   wire[0]  u32: baggage (0x593 path stores player-guid-ish here; unchecked)
    //   wire[4]  u32: CHALLENGE ID — map key (FNV-1a hashed) + node+0x10
    //   wire[8]  u32: LEVEL — node+0x14, returned by IsChallengeActive
    //   wire[12] u32: low byte must be 1 (0x593 path hardcodes node+0x18 = 1)
    //   rest zeroed (matches a live 0x593-tested activation of 188/1).
    // Challenge buff spells, from the live client definitions (CoAExport).
    // Per challenge:  CoAChallenges.Spell.<id>          = union across levels
    // Multi-level:    CoAChallenges.SpellLevels.<id>    = 1
    //                 CoAChallenges.Spell.<id>.<level>  = that level's auras
    // When the SpellLevels marker is set the module uses the level entry (an
    // empty level means "no aura for this level") and never the union; without
    // it (single-level / legacy config) it uses the union.
    // NOTE: manual cancel needs no code guard — challenge auras
    // carry NO_AURA_CANCEL in Spell.dbc (core + client both refuse).
    static std::vector<uint32> ParseSpellList(std::string raw)
    {
        std::vector<uint32> out;
        size_t hash = raw.find('#');
        if (hash != std::string::npos)
            raw = raw.substr(0, hash);
        size_t start = 0;
        while (start < raw.size())
        {
            size_t end = raw.find(';', start);
            if (end == std::string::npos)
                end = raw.size();
            std::string tok = raw.substr(start, end - start);
            size_t b = tok.find_first_not_of(" \t\r\n");
            size_t e = tok.find_last_not_of(" \t\r\n");
            if (b != std::string::npos)
            {
                tok = tok.substr(b, e - b + 1);
                try { out.push_back(uint32(std::stoul(tok))); } catch (...) {}
            }
            start = end + 1;
        }
        return out;
    }

    std::vector<uint32> GetChallengeSpells(uint32 challengeID, uint32 level)
    {
        std::string raw;
        {
            std::lock_guard<std::mutex> lock(DefMutex);
            auto it = DefCache.find(challengeID);
            if (it != DefCache.end())
            {
                auto const& sp = it->second.spells;
                auto unionSp = sp.find(0);
                if (level > 0)
                {
                    auto lv = sp.find(level);
                    if (lv != sp.end())
                        raw = lv->second;                 // per-level (may be empty)
                    else if (unionSp != sp.end())
                        raw = unionSp->second;            // no that level -> union
                }
                else if (unionSp != sp.end())
                {
                    raw = unionSp->second;
                }
            }
        }

        // DB-only: auras come from coa_challenge_spell (no conf fallback).
        return ParseSpellList(raw);
    }

    Player* GetPlayerOwner(Creature* creature)
    {
        if (!creature)
            return nullptr;

        if (Player* owner = creature->GetCharmerOrOwnerPlayerOrPlayerItself())
            return owner;

        if (TempSummon* temp = creature->ToTempSummon())
            if (Unit* summoner = temp->GetSummonerUnit())
                if (Player* player = summoner->ToPlayer())
                    return player;

        if (ObjectGuid createdBy = creature->GetCreatorGUID())
            if (createdBy.IsPlayer())
                return ObjectAccessor::GetPlayer(*creature, createdBy);

        return nullptr;
    }

    std::vector<Creature*> GetPlayerSummons(Player* player)
    {
        std::vector<Creature*> summons;
        if (!player)
            return summons;

        if (Pet* pet = player->GetPet())
            summons.push_back(pet);

        for (Unit* u : player->m_Controlled)
            if (Creature* c = u->ToCreature())
                summons.push_back(c);

        if (ObjectGuid critterGuid = player->GetCritterGUID())
            if (Creature* critter = ObjectAccessor::GetCreature(*player, critterGuid))
                summons.push_back(critter);

        for (uint8 slot = 0; slot < MAX_SUMMON_SLOT; ++slot)
        {
            if (ObjectGuid slotGuid = player->m_SummonSlot[slot])
                if (Creature* s = ObjectAccessor::GetCreature(*player, slotGuid))
                    summons.push_back(s);
        }

        std::sort(summons.begin(), summons.end());
        summons.erase(std::unique(summons.begin(), summons.end()), summons.end());
        return summons;
    }

    void ApplyChallengeSpellToCreature(Creature* creature, uint32 spell)
    {
        if (!creature || !spell)
            return;
        if (!sSpellMgr->GetSpellInfo(spell))
            return;
        if (!creature->HasAura(spell))
        {
            creature->AddAura(spell, creature);
            LOG_INFO("module.coa_challenges", "Applied challenge aura {} to summon {} (owner: {})",
                spell, creature->GetName(), creature->GetOwnerGUID().ToString());
        }
    }

    void ApplyActiveChallengeSpellsToCreature(Player* player, Creature* creature)
    {
        if (!player || !creature)
            return;

        uint32 const guid = player->GetGUID().GetCounter();
        for (ActiveChallengeRow const& row : LoadActiveChallengeRows(guid))
        {
            for (uint32 spell : GetChallengeSpells(row.challengeId, row.level))
                ApplyChallengeSpellToCreature(creature, spell);
        }

        uint32 modeMask = CachedGameModeMask(guid);
        for (auto const& [bit, base] : GameModeBaseSnapshot())
        {
            if (!(modeMask & bit))
                continue;
            for (uint32 spell : GetChallengeSpells(base, 0))
                ApplyChallengeSpellToCreature(creature, spell);
        }
    }

    void ApplyChallengeSpell(Player* player, uint32 challengeID, uint32 level)
    {
        if (!player)
            return;
        std::vector<Creature*> summons = GetPlayerSummons(player);
        for (uint32 spell : GetChallengeSpells(challengeID, level))
        {
            if (!spell)
                continue;
            if (!sSpellMgr->GetSpellInfo(spell))
            {
                LOG_WARN("module.coa_challenges", "Challenge {}: spell {} unknown to core, aura not applied",
                    challengeID, spell);
                continue;
            }
            player->CastSpell(player, spell, true);
            LOG_INFO("module.coa_challenges", "Applied challenge aura {} to {} (challenge {} level {})",
                spell, player->GetName(), challengeID, level);

            for (Creature* summon : summons)
                ApplyChallengeSpellToCreature(summon, spell);
        }
    }

    // Remove every aura the challenge could have applied (union + every
    // per-level entry): the active level isn't always known at removal time.
    void RemoveChallengeSpell(Player* player, uint32 challengeID)
    {
        if (!player)
            return;

        auto collect = [](uint32 id, std::vector<uint32>& out)
        {
            for (uint32 s : GetChallengeSpells(id, 0))
                out.push_back(s);
            for (uint32 lv = 1; lv <= ChallengeLevelCount(id); ++lv)
                for (uint32 s : GetChallengeSpells(id, lv))
                    out.push_back(s);
        };

        std::vector<uint32> spells;
        collect(challengeID, spells);

        // Auras the challenge shares with a still-active challenge or an active
        // game-mode base must survive: otherwise stopping one challenge silently
        // strips an aura another one still needs.
        uint32 guid = player->GetGUID().GetCounter();
        std::set<uint32> keep;
        for (uint32 other : ActiveChallenges(guid))
        {
            if (other == challengeID)
                continue;
            std::vector<uint32> otherSpells;
            collect(other, otherSpells);
            keep.insert(otherSpells.begin(), otherSpells.end());
        }
        uint32 modeMask = CachedGameModeMask(guid);
        for (auto const& [bit, base] : GameModeBaseSnapshot())
        {
            if (!(modeMask & bit))
                continue;
            std::vector<uint32> baseSpells;
            collect(base, baseSpells);
            keep.insert(baseSpells.begin(), baseSpells.end());
        }

        std::sort(spells.begin(), spells.end());
        spells.erase(std::unique(spells.begin(), spells.end()), spells.end());
        std::vector<Creature*> summons = GetPlayerSummons(player);
        for (uint32 spell : spells)
        {
            if (!spell || keep.count(spell))
                continue;
            player->RemoveAurasDueToSpell(spell);
            LOG_INFO("module.coa_challenges", "Removed challenge aura {} from {} (challenge {})",
                spell, player->GetName(), challengeID);

            for (Creature* summon : summons)
                summon->RemoveAurasDueToSpell(spell);
        }
    }

    // Death strips auras; resurrect must restore active challenge auras.
    void ReapplyActiveSpells(Player* player)
    {
        ReapplyActiveSpells(player, LoadActiveChallengeRows(player->GetGUID().GetCounter()));
    }

    void ReapplyActiveSpells(Player* player, std::vector<ActiveChallengeRow> const& rows)
    {
        for (ActiveChallengeRow const& row : rows)
            ApplyChallengeSpell(player, row.challengeId, row.level);
    }

    // Login reconciliation: drop challenge auras that have no backing active
    // challenge (or game-mode base). ReapplyActiveSpells only ADDS auras, so an
    // orphan left by a row deleted out-of-band (old repack build, crash, manual
    // DB surgery, characters->world migration) would otherwise persist forever.
    // Kept: every spell of an active challenge and of the base challenge of
    // every active game mode (those apply without a coa_character_challenge row).
    void StripOrphanChallengeAuras(Player* player)
    {
        if (!player)
            return;

        auto collect = [](uint32 challengeID, std::set<uint32>& out)
        {
            for (uint32 s : GetChallengeSpells(challengeID, 0))
                if (s)
                    out.insert(s);
            for (uint32 lv = 1; lv <= ChallengeLevelCount(challengeID); ++lv)
                for (uint32 s : GetChallengeSpells(challengeID, lv))
                    if (s)
                        out.insert(s);
        };

        std::vector<uint32> const ids = DefIds();
        uint32 guid = player->GetGUID().GetCounter();

        std::set<uint32> keep;
        for (uint32 cid : ActiveChallenges(guid))
            collect(cid, keep);

        uint32 mask = CachedGameModeMask(guid);
        for (uint32 cid : ids)
        {
            uint32 gm = RequiredGameMode(cid);
            if (gm && (mask & gm))
                collect(cid, keep);
        }

        std::set<uint32> allSpells;
        for (uint32 cid : ids)
            collect(cid, allSpells);

        for (uint32 spell : allSpells)
        {
            if (keep.count(spell) || !player->HasAura(spell))
                continue;
            player->RemoveAurasDueToSpell(spell);
            LOG_INFO("module.coa_challenges", "Stripped orphan challenge aura {} from {}",
                spell, player->GetName());
        }
    }

    // Defaults must match conf/mod-coa-challenges.conf.dist (the conf promises
    // that an omitted key falls back to the code default).
    uint32 HungerFoodSpell()
    {
        return sConfigMgr->GetOption<uint32>("CoAChallenges.HungerFoodSpell", 93175);
    }

    uint32 HungerDrinkSpell()
    {
        return sConfigMgr->GetOption<uint32>("CoAChallenges.HungerDrinkSpell", 93176);
    }

    // Meter auras must go away with the challenge (stop/fail) and must
    // never linger without an active hunger challenge (stale relog, etc.).
    void RemoveMeterAuras(Player* player)
    {
        if (!player)
            return;
        player->RemoveAurasDueToSpell(HungerFoodSpell());
        player->RemoveAurasDueToSpell(HungerDrinkSpell());
    }

    void SetMeterAura(Player* player, uint32 spell, int32 value)
    {
        if (!spell)
            return;
        if (value <= 0)
        {
            player->RemoveAurasDueToSpell(spell);
            return;
        }
        if (!sSpellMgr->GetSpellInfo(spell))
        {
            LOG_WARN("module.coa_challenges", "Meter spell {} unknown to core", spell);
            return;
        }
        // Cast first (full visible pipeline, proven by 93181); raw AddAura
        // inside SetAuraStack left some spells invisible client-side.
        if (!player->HasAura(spell))
            player->CastSpell(player, spell, true);
        // Stacks are capped by the client's aura model (255), not by the literal
        // 100: with HungerMax > 100 the meter must keep tracking the real value.
        player->SetAuraStack(spell, player, (uint32)std::min(value, 255));
        // Per-change meter updates are very chatty (one per hunger/thirst tick
        // per player); keep them at DEBUG so they don't flood Server.log.
        if (Aura* aura = player->GetAura(spell))
            LOG_DEBUG("module.coa_challenges", "Meter aura {} on {}: stacks={}",
                spell, player->GetName(), (uint32)aura->GetStackAmount());
        else
            LOG_WARN("module.coa_challenges", "Meter aura {} failed to apply on {}",
                spell, player->GetName());
    }

    // Total lives for a challenge/mode (CoAChallenges.Lives.<id>). Used by the
    // death handling; the lives COUNTER AURA display is deferred (needs a
    // client Spell.dbc edit).
    uint32 LivesTotal(uint32 challengeID)
    {
        return DefField<uint32>(challengeID, &ChallengeDef::lives,
            "CoAChallenges.Lives." + std::to_string(challengeID), 0);
    }

    // Per-mode deaths (mode on without its base challenge). Kept in its own
    // table so coa_character_challenge is untouched.
} // namespace CoAChallenges
