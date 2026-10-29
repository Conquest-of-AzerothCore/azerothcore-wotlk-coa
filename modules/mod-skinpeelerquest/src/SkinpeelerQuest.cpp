#include "AllCreatureScript.h"
#include "AllSpellScript.h"
#include "ApexScaling.h"
#include "AscensionClientSpellPatches.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "DBCStores.h"
#include "Item.h"
#include "ItemScript.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerScript.h"
#include "Random.h"
#include "ServerScript.h"
#include "Nytharos.h"
#include "Vaelthara.h"
#include "Spell.h"
#include "TemporarySummon.h"
#include "Timer.h"
#include "UnitScript.h"
#include "World.h"
#include "WorldScript.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <unordered_map>
#include <vector>

namespace
{
    constexpr uint32 APEX_STORMSFANG_ENTRY = 9916222;
    constexpr uint32 APEX_SPIRIT_WOLF_ENTRY = 9916211;
    constexpr uint32 APEX_THUNDER_POUNCE = 1004112;
    constexpr uint32 APEX_POUNCE_IMPACT = 1004116;
    constexpr uint32 APEX_STORMCALL = 1004117;
    constexpr uint32 APEX_LIGHTNING_CALL = 1004118;
    constexpr uint32 APEX_THUNDERCLAP = 100377;
    constexpr uint32 APEX_RAKE = 100331;
    constexpr uint32 APEX_EAT_NO_SHEATHE_EMOTE = 122;
    constexpr float APEX_WOLF_SEPARATION_RADIUS = 2.5f;

    constexpr uint32 APEX_POUNCE_FIRST_DELAY_MS = 10000;
    constexpr uint32 APEX_POUNCE_RETRY_MS = 5000;
    constexpr uint32 APEX_STORMCALL_FIRST_DELAY_MS = 30000;
    constexpr uint32 APEX_STORMCALL_RETRY_MS = 5000;
    constexpr uint32 APEX_STORM_HOWL_FIRST_DELAY_MS = 20000;
    constexpr uint32 APEX_STORM_HOWL_RETRY_MS = 5000;
    constexpr uint32 APEX_STORM_HOWL_DURATION_MS = 25000;
    constexpr uint32 APEX_SPIRIT_WOLF_RETRY_MS = 5000;
    constexpr uint32 APEX_POUNCE_MIN_DELAY_MS = 350;
    constexpr uint32 APEX_POUNCE_MAX_DELAY_MS = 1500;
    constexpr float APEX_POUNCE_RADIUS = 30.0f;
    constexpr float APEX_STORM_HOWL_RADIUS = 40.0f;
    constexpr float APEX_STORMCALL_RADIUS = 50.0f;

    constexpr uint32 APEX_HUNT_ALLIANCE = 17839;
    constexpr uint32 APEX_HUNT_HORDE = 17844;
    // ids used before the quest moved onto client-tracked ids; honoured so a log
    // entry accepted under them keeps tracking until it is re-accepted
    constexpr std::array<uint32, 4> APEX_HUNT_QUEST_IDS = {17839, 17844, 9916201, 9916211};
    constexpr uint32 APEX_PELT_STORMFANG = 1009302;
    constexpr uint32 APEX_PELT_OWLCAT = 1009303;
    constexpr uint32 APEX_PELT_TIDE = 1009304;

    constexpr std::array<uint32, 10> APEX_CLIENT_SPELLS = {
        100331, 1004111, 1004112, 1004113, 1004114,
        1004115, 1004116, 1004117, 1004118, 1004120};

    // Item.dbc rows are only streamed for ids registered here. Without this the
    // client never learns the item, so the bag draws a question mark.
    constexpr std::array<uint32, 4> APEX_CLIENT_ITEMS = {
        APEX_PELT_STORMFANG, APEX_PELT_OWLCAT, APEX_PELT_TIDE};

    // Stormfang has no CreatureAI of its own: its brain is the creature update below.
    // The probe therefore lives in a map the unit script can feed from the damage hook.
    std::unordered_map<uint32, ApexScaling::Probe> g_stormfangProbes;

    std::vector<Player*> NearbyPlayers(Creature* creature, float radius,
        Player* excluded = nullptr)
    {
        std::vector<Player*> players;
        Map::PlayerList const& list = creature->GetMap()->GetPlayers();
        for (Map::PlayerList::const_iterator itr = list.begin();
             itr != list.end(); ++itr)
        {
            Player* player = itr->GetSource();
            if (!player || !player->IsAlive() || player == excluded ||
                !player->InSamePhase(creature) ||
                !player->IsHostileTo(creature) ||
                !creature->IsWithinDistInMap(player, radius))
                continue;
            players.push_back(player);
        }
        return players;
    }

    void Shuffle(std::vector<Player*>& players)
    {
        // The core RNG is already seeded and shared; constructing a generator
        // per call re-seeded from the clock, so two picks in the same
        // millisecond produced the same order.
        for (std::size_t i = players.size(); i > 1; --i)
            std::swap(players[i - 1], players[urand(0, uint32(i) - 1)]);
    }

    Player* SelectNonTankTarget(Creature* creature, Player* tank,
        float radius, ObjectGuid excluded = ObjectGuid::Empty)
    {
        if (!tank)
            return nullptr;

        std::vector<Player*> players = NearbyPlayers(creature, radius, tank);
        if (players.size() > 1)
            players.erase(std::remove_if(players.begin(), players.end(),
                [excluded](Player* player)
                {
                    return excluded && player->GetGUID() == excluded;
                }), players.end());
        if (players.empty())
            return nullptr;
        Shuffle(players);
        return players.front();
    }

    void SummonSpiritWolf(Creature* summoner, Player* target, float angleOffset)
    {
        if (!summoner || !target)
            return;

        float angle = summoner->GetOrientation() + angleOffset;
        float x = summoner->GetPositionX() + 5.0f * std::cos(angle);
        float y = summoner->GetPositionY() + 5.0f * std::sin(angle);

        if (TempSummon* wolf = summoner->SummonCreature(
                APEX_SPIRIT_WOLF_ENTRY, x, y, summoner->GetPositionZ(),
                target->GetOrientation(), TEMPSUMMON_TIMED_DESPAWN,
                APEX_STORM_HOWL_DURATION_MS))
        {
            wolf->SetFaction(summoner->GetFaction());
            wolf->GetThreatMgr().AddThreat(target, 100.0f);
            wolf->AI()->AttackStart(target);
        }
    }

    void SummonStormHowlWolves(Creature* creature)
    {
        Unit* victim = creature->GetVictim();
        Player* tank = victim ? victim->ToPlayer() : nullptr;
        std::vector<Player*> nonTanks = NearbyPlayers(creature, APEX_STORM_HOWL_RADIUS, tank);
        Shuffle(nonTanks);

        Player* first = nullptr;
        Player* second = nullptr;
        if (nonTanks.size() >= 2)
        {
            first = nonTanks[0];
            second = nonTanks[1];
        }
        else if (nonTanks.size() == 1)
        {
            first = nonTanks[0];
            second = nonTanks[0];
        }
        else if (tank)
        {
            first = tank;
            second = tank;
        }

        if (!first || !second)
            return;

        SummonSpiritWolf(creature, first, 0.0f);
        SummonSpiritWolf(creature, second, 3.14159265f);
    }

    void StartStormcall(Creature* caster)
    {
        if (!caster)
            return;

        for (uint32 delay : {0u, 1000u, 2000u, 3000u, 4000u, 5000u, 6000u})
        {
            caster->m_Events.AddEventAtOffset([caster]()
            {
                if (!caster || !caster->IsAlive())
                    return;

                std::vector<Player*> players =
                    NearbyPlayers(caster, APEX_STORMCALL_RADIUS);
                for (Player* player : players)
                {
                    if (!player->IsAlive())
                        continue;

                    caster->CastSpell(player, APEX_LIGHTNING_CALL, true);
                }

                ApexScaling::ApplyAoe(caster, players,
                    {ApexScaling::ABILITY_PCT, 1, 0}, ApexScaling::ABILITY_BUDGET,
                    ApexScaling::ABILITY_CAP_PCT, ApexScaling::CARRIER_NATURE);
            }, Milliseconds(delay));
        }

        caster->SetControlled(true, UNIT_STATE_ROOT);
        caster->SetEmoteState(Emote(APEX_EAT_NO_SHEATHE_EMOTE));
        caster->HandleEmoteCommand(APEX_EAT_NO_SHEATHE_EMOTE);

        caster->m_Events.AddEventAtOffset([caster]()
        {
            if (caster)
            {
                caster->SetControlled(false, UNIT_STATE_ROOT);
                caster->ClearEmoteState();
                caster->HandleEmoteCommand(0);
            }
        }, 7000ms);
    }

    void KeepWolfSeparation(Creature* wolf)
    {
        Unit* victim = wolf->GetVictim();
        if (!wolf->IsInCombat() || !victim)
            return;

        // Keyed by GUID because every summon gets a fresh one. Entries are
        // pruned on a slow beat: without it the map grows for the whole uptime,
        // since a wolf despawns instead of reusing its key.
        static std::unordered_map<uint32, uint32> nextMove;
        static uint32 nextPrune = 0;
        uint32 const key = wolf->GetGUID().GetCounter();
        uint32 const now = getMSTime();

        if (now >= nextPrune)
        {
            nextPrune = now + 30000;
            for (auto itr = nextMove.begin(); itr != nextMove.end();)
                itr = (now > itr->second + 30000) ? nextMove.erase(itr) : std::next(itr);
        }

        auto cooldown = nextMove.find(key);
        if (cooldown != nextMove.end() && now < cooldown->second)
            return;

        std::list<Creature*> wolves;
        wolf->GetCreatureListWithEntryInGrid(wolves, APEX_SPIRIT_WOLF_ENTRY, 8.0f);
        for (Creature* other : wolves)
        {
            if (other == wolf || !other->IsAlive() || !wolf->InSamePhase(other) ||
                other->GetVictim() != victim)
                continue;

            float const distance = wolf->GetExactDist2d(
                other->GetPositionX(), other->GetPositionY());
            if (distance >= APEX_WOLF_SEPARATION_RADIUS ||
                wolf->GetGUID().GetCounter() > other->GetGUID().GetCounter())
                continue;

            wolf->GetMotionMaster()->MoveChase(
                victim, 0.0f, static_cast<float>(M_PI) * 0.5f);
            nextMove[key] = now + 1000;
            break;
        }
    }

    class SkinpeelerStormfangSpellScript : public AllSpellScript
    {
    public:
        SkinpeelerStormfangSpellScript()
            : AllSpellScript("SkinpeelerStormfangSpellScript",
                  {ALLSPELLHOOK_ON_CAST})
        {
        }

        void OnSpellCast(Spell* spell, Unit*,
            SpellInfo const*, bool) override
        {
            if (!spell || !spell->GetCaster() ||
                spell->GetCaster()->GetEntry() != APEX_STORMSFANG_ENTRY)
                return;

            if (spell->m_spellInfo->Id == APEX_THUNDER_POUNCE)
            {
                Unit* caster = spell->GetCaster();
                Unit* target = spell->m_targets.GetUnitTarget();
                if (!caster || !target)
                    return;

                ObjectGuid targetGuid = target->GetGUID();
                uint32 delayMs = static_cast<uint32>(
                    caster->GetExactDist2d(target) * 1000.0f / 24.0f) + 150u;
                if (delayMs < APEX_POUNCE_MIN_DELAY_MS)
                    delayMs = APEX_POUNCE_MIN_DELAY_MS;
                if (delayMs > APEX_POUNCE_MAX_DELAY_MS)
                    delayMs = APEX_POUNCE_MAX_DELAY_MS;

                caster->m_Events.AddEventAtOffset([caster, targetGuid]()
                {
                    if (!caster || !caster->IsAlive())
                        return;

                    if (Unit* landingTarget =
                            ObjectAccessor::GetUnit(*caster, targetGuid))
                    {
                        caster->PlayDirectSound(36559);
                        caster->CastSpell(landingTarget, APEX_POUNCE_IMPACT, true);
                        if (Creature* boss = caster->ToCreature())
                            ApexScaling::ApplyHit(boss, landingTarget,
                                {ApexScaling::HEAVY_PCT, 1, 0}, ApexScaling::CARRIER_PHYSICAL);
                    }
                }, Milliseconds(delayMs));
            }
        }
    };

    class SkinpeelerStormfangCreatureScript : public AllCreatureScript
    {
    public:
        SkinpeelerStormfangCreatureScript()
            : AllCreatureScript("SkinpeelerStormfangCreatureScript")
        {
        }

        void OnCreatureAddWorld(Creature* creature) override
        {
            if (creature && creature->GetEntry() == APEX_STORMSFANG_ENTRY)
                creature->SetReactState(REACT_DEFENSIVE);
        }

        void OnAllCreatureUpdate(Creature* creature, uint32) override
        {
            if (!creature || creature->GetEntry() != APEX_STORMSFANG_ENTRY)
            {
                if (creature && creature->GetEntry() == APEX_SPIRIT_WOLF_ENTRY)
                    KeepWolfSeparation(creature);
                return;
            }

            if (creature->GetReactState() == REACT_AGGRESSIVE && !creature->IsInCombat())
                creature->SetReactState(REACT_DEFENSIVE);

            static std::unordered_map<uint32, uint32> nextPounce;
            static std::unordered_map<uint32, uint32> nextStormcall;
            static std::unordered_map<uint32, uint32> nextStormHowl;
            static std::unordered_map<uint32, uint32> nextMeleeSound;
            static std::unordered_map<uint32, uint32> nextThunderclap;
            static std::unordered_map<uint32, uint32> nextRake;
            static std::unordered_map<uint32, ObjectGuid> lastPounce;
            uint32 const key = creature->GetGUID().GetCounter();
            uint32 const now = getMSTime();

            if (!creature->IsAlive())
            {
                nextPounce.erase(key);
                nextStormcall.erase(key);
                nextStormHowl.erase(key);
                nextMeleeSound.erase(key);
                nextThunderclap.erase(key);
                nextRake.erase(key);
                lastPounce.erase(key);
                g_stormfangProbes.erase(key);
                return;
            }

            // Same pool blueprint as the other apex bosses: a deliberately large
            // starting pool, a fifteen second measurement, then the real size.
            ApexScaling::Probe& probe = g_stormfangProbes[key];
            if (!creature->IsInCombat())
            {
                if (probe.Base && !ApexScaling::StillEngaged(creature))
                {
                    ApexScaling::RestoreHealth(creature, probe.Base);
                    probe = ApexScaling::Probe();
                }
            }
            else
            {
                if (!probe.Base)
                {
                    ApexScaling::ResetProbe(probe, creature);
                    ApexScaling::ScaleHealth(creature, probe.Base, 0.0f);
                }

                ApexScaling::ResolveProbe(probe, creature);
            }

            if (!creature->IsInCombat())
            {
                nextPounce[key] = now + APEX_POUNCE_FIRST_DELAY_MS;
                nextStormcall[key] = now + APEX_STORMCALL_FIRST_DELAY_MS;
                nextStormHowl[key] = now + APEX_STORM_HOWL_FIRST_DELAY_MS;
                nextMeleeSound[key] = now;
                nextThunderclap[key] = now + 3000;
                nextRake[key] = now + 8000;
                lastPounce.erase(key);
                return;
            }

            float const healthPct = creature->GetHealthPct();
            bool const stormcallActive = creature->HasAura(APEX_STORMCALL);

            auto clap = nextThunderclap.find(key);
            if (clap == nextThunderclap.end())
            {
                nextThunderclap.emplace(key, now + 3000);
            }
            else if (now >= clap->second)
            {
                Unit* victim = creature->GetVictim();
                if (!stormcallActive && victim &&
                    creature->CastSpell(victim, APEX_THUNDERCLAP, true) == SPELL_CAST_OK)
                {
                    ApexScaling::ApplyAoe(creature, NearbyPlayers(creature, 10.0f),
                        {ApexScaling::ABILITY_PCT, 1, 0}, ApexScaling::ABILITY_BUDGET,
                        ApexScaling::ABILITY_CAP_PCT, ApexScaling::CARRIER_PHYSICAL);
                    clap->second = now + 12000;
                }
                else
                    clap->second = now + 1000;
            }

            auto rake = nextRake.find(key);
            if (rake == nextRake.end())
            {
                nextRake.emplace(key, now + 8000);
            }
            else if (now >= rake->second)
            {
                Unit* victim = creature->GetVictim();
                if (!stormcallActive && victim &&
                    creature->CastSpell(victim, APEX_RAKE, true) == SPELL_CAST_OK)
                {
                    ApexScaling::ApplyHit(creature, victim,
                        {ApexScaling::ABILITY_PCT, 1, 0}, ApexScaling::CARRIER_PHYSICAL);
                    rake->second = now + 8000;
                }
                else
                    rake->second = now + 1000;
            }

            auto pounce = nextPounce.find(key);
            if (pounce == nextPounce.end())
            {
                nextPounce.emplace(key, now + APEX_POUNCE_FIRST_DELAY_MS);
            }
            else if (now >= pounce->second)
            {
                if (stormcallActive)
                {
                    pounce->second = now + 1000;
                }
                else
                {
                    Unit* victim = creature->GetVictim();
                    Player* tank = victim ? victim->ToPlayer() : nullptr;
                    ObjectGuid previous = lastPounce.count(key)
                        ? lastPounce[key] : ObjectGuid::Empty;
                    Player* target = SelectNonTankTarget(
                        creature, tank, APEX_POUNCE_RADIUS, previous);
                    if (target)
                    {
                        creature->CastSpell(target, APEX_THUNDER_POUNCE, true);
                        lastPounce[key] = target->GetGUID();
                        uint32 interval = healthPct < 40.0f ? 12000 :
                            (healthPct < 70.0f ? 14000 : 16000);
                        pounce->second = now + interval;
                    }
                    else
                    {
                        pounce->second = now + APEX_POUNCE_RETRY_MS;
                    }
                }
            }

            auto howl = nextStormHowl.find(key);
            if (howl == nextStormHowl.end())
            {
                nextStormHowl.emplace(key, now + APEX_STORM_HOWL_FIRST_DELAY_MS);
            }
            else if (now >= howl->second)
            {
                if (stormcallActive)
                {
                    howl->second = now + 1000;
                }
                else if (creature->GetVictim() ||
                         !NearbyPlayers(creature, APEX_STORM_HOWL_RADIUS).empty())
                {
                    SummonStormHowlWolves(creature);
                    uint32 interval = healthPct < 40.0f ? 35000 : 45000;
                    howl->second = now + interval;
                }
                else
                {
                    howl->second = now + APEX_STORM_HOWL_RETRY_MS;
                }
            }

            auto call = nextStormcall.find(key);
            if (call == nextStormcall.end())
            {
                nextStormcall.emplace(key, now + APEX_STORMCALL_FIRST_DELAY_MS);
            }
            else if (now >= call->second)
            {
                if (!NearbyPlayers(creature, APEX_STORMCALL_RADIUS).empty() &&
                    !creature->IsNonMeleeSpellCast(false))
                {
                    SpellCastResult result = creature->CastSpell(creature, APEX_STORMCALL, true);
                    if (result != SPELL_CAST_OK)
                    {
                        LOG_WARN("coa", "Stormfang Stormcall cast failed {}", uint32(result));
                        call->second = now + APEX_STORMCALL_RETRY_MS;
                        return;
                    }

                    StartStormcall(creature);
                    uint32 interval = healthPct < 40.0f ? 40000 :
                        (healthPct < 70.0f ? 50000 : 60000);
                    call->second = now + interval;
                }
                else
                {
                    call->second = now + APEX_STORMCALL_RETRY_MS;
                }
            }

            auto meleeSound = nextMeleeSound.find(key);
            if (meleeSound == nextMeleeSound.end())
                nextMeleeSound.emplace(key, now);
            else if (now >= meleeSound->second &&
                     creature->GetVictim() &&
                     !creature->HasAura(APEX_STORMCALL))
            {
                creature->PlayDirectSound(4069);
                meleeSound->second = now + 2000;
            }
        }
    };

    // SMSG_UPDATE_QUEST_ICON (0x65C): u64 guid, u32 kind, u32 state. Kind 4 is the
    // legendary marker set: state 2 talktomeorange_new.m2, state 5
    // talktome_new_questionlegendary_grey.m2, state 10 talktome_new_questionlegendary.m2.
    constexpr uint16 SMSG_UPDATE_QUEST_ICON = 0x65C;
    constexpr uint32 APEX_ICON_KIND = 4;
    constexpr uint32 APEX_ICON_AVAILABLE = 2;
    constexpr uint32 APEX_ICON_IN_PROGRESS = 5;
    constexpr uint32 APEX_ICON_COMPLETE = 10;
    constexpr uint32 APEX_ICON_NONE = 1;

    // SMSG_SUPER_TRACKER_SET_POSITION (0x740): i32 map, f32 x, y, z. C_SuperTrack keeps
    // this as state, so it is set when the target changes, not resent.
    constexpr uint16 SMSG_SUPER_TRACKER_SET_POSITION = 0x740;

    struct ApexHuntTarget
    {
        uint32 Item;
        int32 Map;
        float X;
        float Y;
        float Z;
    };

    constexpr std::array<ApexHuntTarget, 3> APEX_HUNT_TARGETS = {{
        {1009304, 1, 2269.03f, -6608.37f, 125.192f},   // Nytharos, Ruins of Eldarath
        {1009302, 0, 146.714f, -4587.26f, 119.685f},   // Stormfang, Hinterlands
        {1009303, 1, -3908.87f, 1946.0f, 81.0109f}}};  // Vaelthara, Feralas

    // Where the waypoint points once every hide is held.
    struct ApexTurnIn
    {
        uint32 QuestId;
        int32 Map;
        float X;
        float Y;
        float Z;
    };

    constexpr std::array<ApexTurnIn, 2> APEX_TURN_INS = {{
        {17839, 0, -9168.72f, 768.735f, 154.275f},    // Torvald, Stormwind
        {17844, 1, 2003.64f, -4645.85f, 25.9132f}}};  // Zul'khar, Orgrimmar

    struct ApexIconNpc
    {
        uint32 Entry;
        uint32 SpawnId;
        uint32 QuestId;
    };

    constexpr std::array<ApexIconNpc, 2> APEX_ICON_NPCS = {{
        {9916113, 9999266, 17839},
        {9916114, 9999265, 17844}}};

    // Rebuilt markers follow every quest packet the client processes, so the override
    // is re-applied on the update after one of those, not on a timer.
    std::unordered_set<uint32> g_apexIconDirty;

    class SkinpeelerIconTriggerScript : public ServerScript
    {
    public:
        SkinpeelerIconTriggerScript() : ServerScript("SkinpeelerIconTriggerScript",
            {SERVERHOOK_CAN_PACKET_SEND}) { }

        bool CanPacketSend(WorldSession* session, WorldPacket const& packet) override
        {
            switch (packet.GetOpcode())
            {
                case SMSG_QUESTGIVER_STATUS:
                case SMSG_QUESTGIVER_STATUS_MULTIPLE:
                case SMSG_QUESTGIVER_QUEST_LIST:
                case SMSG_QUESTGIVER_QUEST_DETAILS:
                case SMSG_QUESTGIVER_REQUEST_ITEMS:
                case SMSG_QUESTGIVER_OFFER_REWARD:
                case SMSG_QUESTGIVER_QUEST_COMPLETE:
                case SMSG_QUEST_QUERY_RESPONSE:
                case SMSG_QUESTUPDATE_COMPLETE:
                    if (session && session->GetPlayer())
                        g_apexIconDirty.insert(session->GetPlayer()->GetGUID().GetCounter());
                    break;
                default:
                    break;
            }
            return true;
        }
    };

    class SkinpeelerTrackScript : public PlayerScript
    {
    public:
        SkinpeelerTrackScript() : PlayerScript("SkinpeelerTrackScript", {PLAYERHOOK_ON_UPDATE}) { }

        void OnPlayerUpdate(Player* player, uint32 p_time) override
        {
            if (!player || !player->IsInWorld())
                return;

            uint32 const guid = player->GetGUID().GetCounter();
            bool const dirty = g_apexIconDirty.count(guid) != 0;

            uint32& timer = _timers[guid];
            timer += p_time;

            // A quest packet was just sent, so the client has already rebuilt with the
            // native model. Run now instead of waiting for the next second.
            if (!dirty && timer < 1000)
                return;

            timer = 0;

            for (ApexIconNpc const& npc : APEX_ICON_NPCS)
            {
                uint32& sent = _lastState[player->GetGUID().GetCounter() * 8 + npc.Entry % 8];
                uint32& seen = _lastSeen[player->GetGUID().GetCounter() * 8 + npc.Entry % 8];
                QuestStatus const status = player->GetQuestStatus(npc.QuestId);
                uint32 state = APEX_ICON_NONE;

                if (status == QUEST_STATUS_INCOMPLETE)
                    state = APEX_ICON_IN_PROGRESS;
                else if (status == QUEST_STATUS_COMPLETE)
                    state = APEX_ICON_COMPLETE;
                else if (status == QUEST_STATUS_NONE &&
                         !player->GetQuestRewardStatus(npc.QuestId) &&
                         player->GetLevel() >= 58)
                    state = APEX_ICON_AVAILABLE;

                // 0x65C applies one rebuild and then clears its path, so it is sent only
                // when the quest state changes or the NPC comes back into view. Sending it
                // on a timer would fight the client's own rebuild.
                Creature* creature = player->FindNearestCreature(npc.Entry, 200.0f, true);
                if (!creature)
                {
                    seen = 0;
                    continue;
                }

                bool const firstSight = (seen == 0);
                bool const dirty = g_apexIconDirty.count(player->GetGUID().GetCounter()) != 0;
                if (!firstSight && !dirty && sent == state)
                    continue;

                WorldPacket packet(SMSG_UPDATE_QUEST_ICON, 16);
                packet << creature->GetGUID() << APEX_ICON_KIND << state;
                player->GetSession()->SendPacket(&packet);

                LOG_INFO("coa", "APEX ICON: {} -> kind {} state {}", player->GetName(),
                    APEX_ICON_KIND, state);

                sent = state;
                seen = 1;
            }

            g_apexIconDirty.erase(player->GetGUID().GetCounter());

        }

    private:
        std::unordered_map<uint32, uint32> _timers;
        std::unordered_map<uint32, uint32> _lastState;
        std::unordered_map<uint32, uint32> _lastSeen;
    };

    class SkinpeelerStormfangUnitScript : public UnitScript
    {
    public:
        SkinpeelerStormfangUnitScript() : UnitScript("SkinpeelerStormfangUnitScript", true,
            {UNITHOOK_ON_DAMAGE, UNITHOOK_MODIFY_MELEE_DAMAGE,
             UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK}) { }

        // Every source counts here: melee, ranged, spells, DoTs, pets and procs all
        // arrive as damage on the boss, which is what the pool is sized from.
        void OnDamage(Unit* /*attacker*/, Unit* victim, uint32& damage) override
        {
            if (!victim || !victim->IsCreature() || victim->GetEntry() != APEX_STORMSFANG_ENTRY)
                return;

            auto itr = g_stormfangProbes.find(victim->GetGUID().GetCounter());
            if (itr != g_stormfangProbes.end())
                ApexScaling::ObserveProbe(itr->second, damage);
        }

        void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
        {
            if (!attacker || !target || !damage || !attacker->IsCreature())
                return;

            // Percentage autos, same as the other apex bosses: armour, block, dodge
            // and defensive cooldowns still filter the hit.
            if (attacker->GetEntry() == APEX_STORMSFANG_ENTRY)
            {
                damage = std::max<uint32>(1,
                    uint32(float(target->GetMaxHealth()) * ApexScaling::AUTO_PCT));
                return;
            }

            // His spirit wolves are part of the same fight, so their bites scale with
            // the victim's pool too instead of being a flat number nobody can balance.
            if (attacker->GetEntry() == APEX_SPIRIT_WOLF_ENTRY)
            {
                damage = std::max<uint32>(1,
                    uint32(float(target->GetMaxHealth()) * ApexScaling::WOLF_PCT));
            }
        }

        // His own spells carry the flavour, the debuff and the visual. Their flat
        // damage is removed here and re-applied as a share of the victim's pool at
        // the cast site, so armour and resistances still filter the real hit.
        void ModifySpellDamageTaken(Unit* /*target*/, Unit* attacker, int32& damage,
            SpellInfo const* spellInfo) override
        {
            if (!attacker || !spellInfo || !attacker->IsCreature() ||
                attacker->GetEntry() != APEX_STORMSFANG_ENTRY)
                return;

            if (IsDamagingSpell(spellInfo->Id))
                damage = 0;
        }

        void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage,
            SpellInfo const* /*spellInfo*/) override
        {
            if (!target || !attacker || !attacker->IsCreature() ||
                attacker->GetEntry() != APEX_STORMSFANG_ENTRY)
                return;

            damage = std::max<uint32>(1,
                uint32(float(target->GetMaxHealth()) * ApexScaling::PERIODIC_PCT));
        }

    private:
        static bool IsDamagingSpell(uint32 spellId)
        {
            return spellId == APEX_THUNDERCLAP || spellId == APEX_RAKE ||
                spellId == APEX_POUNCE_IMPACT || spellId == APEX_LIGHTNING_CALL;
        }
    };
}

void Addmod_skinpeelerquestScripts()
{
    for (uint32 spellId : APEX_CLIENT_SPELLS)
        Ascension::ClientSpellPatches::Instance().Register(spellId);

    for (uint32 itemId : APEX_CLIENT_ITEMS)
        Ascension::ClientItemPatches::Instance().Register(itemId);

    new SkinpeelerStormfangSpellScript();
    new SkinpeelerStormfangCreatureScript();
    new SkinpeelerStormfangUnitScript();
    new SkinpeelerTrackScript();
    new SkinpeelerIconTriggerScript();
    AddVaeltharaScripts();
    AddNytharosScripts();
}
