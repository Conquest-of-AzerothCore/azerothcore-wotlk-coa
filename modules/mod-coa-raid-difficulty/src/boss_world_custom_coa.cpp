/*
 * Ascension's own world bosses: Setis, Korrim Snowgrave and The Will of
 * Soggoth, each in the boss map Ascension built for it (Map.dbc 880, 889, 883).
 *
 * All three are in one log (24.08.2026), each killed twice. The second kill of
 * each hit harder and had more health with the same raid, so the log holds two
 * levels rather than flex: the lower one runs on the 10/25 normal difficulties,
 * the higher one on the heroic ones. Health and a damage factor per level come
 * from coa_world_boss_level; the damage factor is the log's hits over the base
 * values of the spells Ascension cast (the same ids on both kills).
 *
 * Setis (his kit as seven live kills show it; the spells of his new block that
 * no live kill shows are left out)
 *   Plague              every 5.1s    a random player
 *   Fierce Blow         every 8.8s    tank
 *   Shadow Storm        every 13.6s   shadow bolts at everyone 25-45 yards out
 *   War Stomp           every 32s     around him, knocked back
 *   Meteor              every 32s     4s cast at a marked player, fire on the ground
 *   Call Lightning      every 35.1s   marks three spots, one more for every ten
 *                                     players, then a 4s cast strikes them and
 *                                     electrifies the ground for 20s
 *   Frenzy              at 30%
 *   Armageddon          at 3%         15s cast, +150% damage taken while he
 *                                     casts; if it finishes, the raid dies
 * His health is per player in his map (10 to 40), and only the Normal difficulties
 * are open. He drops one of his items for every
 * four players, and every player gets Runes of Ascension, Bazaar Tokens and a
 * Treasures of Azeroth chest.
 * The altar by the Scarab Wall takes players into his map, and the portal he
 * leaves behind takes them back to it.
 *
 * Korrim Snowgrave (a 62.1-second rotation, every step measured)
 *   Frozen Club         passive       hits stack Frostbite
 *   Massive Stomp       0s            2s cast: the tank, then everyone, less
 *                                     further out; icicles fall 5s later
 *   Hail                10s, 30s, 55s 1s cast at a player: a cone of ice shards
 *   Winter's Grasp      20s           a ring of ice spikes grows out from him
 *   Steal Warmth        40s           isolated players gain Chilled to the
 *                                     Bones each second, huddled ones lose it;
 *                                     at 10 stacks, Frozen Solid
 *   Shock Frost         52s           doubles the stacks, then frost damage
 *                                     that grows with them
 *   Fierce Blow         every 9s      tank
 *
 * The Will of Soggoth
 *   Void Beam           every 2s      a random player
 *   Waking Tear         every 22.1s   3s cast: a tear at a player for 20s
 *   Waking Nightmare    every 33.1s   six Psychophages rise around a player
 *   Visions of Ny'alotha every 45s    4s cast: everyone, then after 6s a void
 *                                     explosion under each of them
 *   Fierce Blow         every 7.8s    tank
 *
 * Atal'zul, the Soulreaver, with Zul'rogg (map 890; two kills in the log of
 * 25.08.2026, same spell damage on both, see the level table for health)
 *   Spectral Bolt       every 1.5s    his tank, stacking shadow damage taken
 *   Spectral Volley     every 12s     3s cast, everyone
 *   Land of the Dead    every 61.4s   six seconds: a Damned Wight a second at
 *                                     the raid, a choking cloud every other
 *   Spectral Veil       at 80/60/40/20%  a channel of up to 100s: shadow damage
 *                                     to everyone each second, growing. The four
 *                                     Soul Vessels open: each spawns Restless
 *                                     Spirits that blow up unless killed or
 *                                     interrupted. Breaking one vessel ends the
 *                                     veil, shields the rest and gives the raid
 *                                     Soul Release.
 *   Both start ghostly and untouchable until the four Soul Vessels are
 *   clicked; Zul'rogg then jumps down from the pyramid.
 *   Zul'rogg            Fierce Blow every 7.6s, Titanic Crush every 10.8s,
 *                       Consume Life every 8s; cannot die while Atal'zul lives
 *
 * Trut-K'hahn has no log and no map. His kit is his spell block; every timer
 * is designed: Fierce Blow 8s, Turkey Rush 20s, Feather Storm 30s, Flap Flap
 * Flap and Dive Bomb 40s, Call the Flock 60s.
 */

#include "Chat.h"
#include "Containers.h"
#include "CreatureScript.h"
#include "SpellScriptLoader.h"
#include "SpellScript.h"
#include "GameObjectScript.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "Item.h"
#include "ServerScript.h"
#include "PlayerScript.h"
#include "WorldSession.h"
#include "WorldPacket.h"
#include "Mail.h"
#include "ScriptedGossip.h"
#include "LootMgr.h"
#include "Map.h"
#include "MoveSpline.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include "SetisLoot.h"
#include "zg_coa_common.h"

#include <algorithm>
#include <unordered_set>
#include <mutex>
#include <atomic>
#include <array>
#include <cmath>
#include <map>
#include <unordered_map>
#include <vector>

using namespace coa_zg;

namespace
{
    // ------------------------------------------------------------- the levels
    struct Level
    {
        uint32 health;
        float damage;
    };

    // entry -> difficulty -> level
    std::unordered_map<uint32, std::map<uint8, Level>> g_levels;

    void LoadLevels()
    {
        g_levels.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT entry, difficulty, health, damage_pct FROM coa_world_boss_level"))
        {
            do
            {
                Field* f = result->Fetch();
                g_levels[f[0].Get<uint32>()][f[1].Get<uint8>()] = { f[2].Get<uint32>(), f[3].Get<float>() / 100.0f };
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded levels for {} custom world boss creatures", uint32(g_levels.size()));
    }

    // The level for this creature's difficulty, or the highest one below it.
    Level const* LevelOf(Creature const* me)
    {
        auto it = g_levels.find(me->GetEntry());
        if (it == g_levels.end() || it->second.empty())
            return nullptr;
        uint8 const diff = uint8(me->GetMap()->GetDifficulty());
        auto lv = it->second.upper_bound(diff);
        if (lv == it->second.begin())
            return &lv->second;
        return &std::prev(lv)->second;
    }

    void ApplyLevelHealth(Creature* me)
    {
        Level const* lv = LevelOf(me);
        if (!lv || !lv->health)
            return;
        me->SetCreateHealth(lv->health);
        me->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(lv->health));
        me->UpdateMaxHealth();
        me->SetFullHealth();
    }

    class coa_world_boss_level_loader : public WorldScript
    {
    public:
        coa_world_boss_level_loader() : WorldScript("coa_world_boss_level_loader") { }
        void OnAfterConfigLoad(bool /*reload*/) override { LoadLevels(); }
    };

    constexpr uint32 SPELL_FIERCE_BLOW = 975011;

    // A clock for the rotation and one for pulses, as for Azuregos and Kazzak,
    // plus the level: health on reset, damage on every hit.
    struct custom_world_boss_coa : public ScriptedAI
    {
        explicit custom_world_boss_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            events.Reset();
            _clock.Reset();
            ApplyLevelHealth(me);
            _damage = LevelOf(me) ? LevelOf(me)->damage : 1.0f;
        }

        void JustEngagedWith(Unit* /*who*/) override { Schedule(); }

        virtual void Schedule() = 0;
        virtual void Execute(uint32 eventId) = 0;
        virtual void Tick(uint32 /*tick*/) { }

        void DamageDealt(Unit* victim, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            ScriptedAI::DamageDealt(victim, damage, type, school);
            damage = uint32(damage * _damage);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            _clock.Update(diff);
            while (uint32 tick = _clock.ExecuteEvent())
                Tick(tick);

            events.Update(diff);
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                Execute(eventId);
                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }
            DoMeleeAttackIfReady();
        }

        Unit* RandomPlayer(bool notTank = true)
        {
            if (Unit* u = SelectTarget(SelectTargetMethod::Random, notTank ? 1 : 0, 100.0f, true))
                return u;
            return me->GetVictim();
        }

        void CastAt(Position const& pos, uint32 spell)
        {
            me->CastSpell(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), spell, true);
        }

    protected:
        EventMap events;
        EventMap _clock;
        float _damage = 1.0f;
    };

    // ------------------------------------------------------------------ Setis
    enum SetisSpells
    {
        SPELL_PLAGUE            = 1002115,
        SPELL_SHADOW_STORM      = 1002116,
        SPELL_WAR_STOMP         = 1002213,
        SPELL_FIRE_REFLECT      = 1002118,
        SPELL_FRENZY            = 1002120,
        SPELL_METEOR            = 83360,
        SPELL_METEOR_MARK       = 2119015,
        SPELL_CALL_LIGHTNING    = 2119052,
        SPELL_LIGHTNING_MARK    = 2119053,
        SPELL_LIGHTNING_STRIKE  = 2119054,
        SPELL_ARMAGEDDON        = 2119050,
        SPELL_ARMAGEDDON_BLAST  = 2119051,
    };

    enum SetisEvents
    {
        ES_PLAGUE = 1, ES_FIERCE, ES_STORM, ES_STOMP, ES_METEOR, ES_LIGHTNING
    };

    constexpr float SETIS_MELEE_REACH = 8.0f;
    constexpr uint32 GO_SETIS_EXIT = 64601;
    constexpr uint32 SETIS_MAP = 880;
    constexpr uint32 SETIS_SHRINE_TEXT = 64600;
    constexpr uint32 SETIS_MIN_FLEX = 10;
    constexpr uint32 SETIS_MAX_FLEX = 40;
    constexpr uint32 ITEM_RUNE_OF_ASCENSION = 375250;
    constexpr uint32 ITEM_BAZAAR_TOKEN = 975001;
    constexpr uint32 ITEM_TREASURES_OF_AZEROTH = 1615011;
    constexpr uint32 SETIS_RUNES = 250;
    constexpr uint32 SETIS_TOKENS_MIN = 100;
    constexpr uint32 SETIS_TOKENS_MAX = 150;
    constexpr uint8 SETIS_NORMAL_GROUP = 1;
    constexpr uint8 SETIS_HEROIC_GROUP = 2;
    constexpr uint16 SMSG_COA_CHECKPOINTS_ENABLED = 0x767;
    constexpr uint16 CMSG_COA_RESPAWN_AT_CHECKPOINT = 0x774;
    Position const SetisEntrance = { -8093.0f, 1663.6f, 12.9f, 0.0f };
    Position const SetisShrine = { -7864.724f, 1326.674f, -7.357f, 5.4786f };
    constexpr float SETIS_SHRINE_ARRIVAL = 20.0f;
    Position const SetisExitPortal = { -7970.9f, 1507.22f, 2.61f, 0.0f };

    void GiveOrMail(Player* player, uint32 item, uint32 count)
    {
        ItemPosCountVec dest;
        uint32 noSpace = 0;
        player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, item, count, &noSpace);
        if (count > noSpace)
            if (Item* stored = player->StoreNewItem(dest, item, true))
                player->SendNewItem(stored, count - noSpace, true, false);
        count = noSpace;
        if (!count)
            return;
        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        MailDraft draft("Setis", "Your bags were full, so this part of your reward was sent by mail.");
        if (Item* mailed = Item::CreateItem(item, count, player))
        {
            mailed->SaveToDB(trans);
            draft.AddItem(mailed);
        }
        draft.SendMailTo(trans, MailReceiver(player), MailSender(MAIL_NORMAL, 0, MAIL_STATIONERY_GM));
        CharacterDatabase.CommitTransaction(trans);
    }

    struct boss_setis_coa : public custom_world_boss_coa
    {
        explicit boss_setis_coa(Creature* creature) : custom_world_boss_coa(creature) { }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            _frenzy = _armageddon = false;
            _marks.clear();
            me->SetLootMode(me->GetMap()->IsHeroic() ? LOOT_MODE_HARD_MODE_1 : LOOT_MODE_DEFAULT);
            ApplyFlexHealth();
            // Reflected Firebolts in the log: fire (and arcane) comes back.
            DoCastSelf(SPELL_FIRE_REFLECT, true);
        }

        void JustEngagedWith(Unit* who) override
        {
            ApplyFlexHealth();
            custom_world_boss_coa::JustEngagedWith(who);
        }

        void ApplyFlexHealth()
        {
            Level const* lv = LevelOf(me);
            if (!lv || !lv->health)
                return;
            uint32 const players = std::clamp<uint32>(me->GetMap()->GetPlayersCountExceptGMs(), SETIS_MIN_FLEX,
                SETIS_MAX_FLEX);
            float const pct = me->GetHealthPct();
            uint32 const health = lv->health * players;
            me->SetCreateHealth(health);
            me->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
            me->UpdateMaxHealth();
            me->SetHealth(std::max<uint32>(uint32(me->GetMaxHealth() * pct / 100.0f), 1));
        }

        void Schedule() override
        {
            events.ScheduleEvent(ES_PLAGUE, 3800ms);
            events.ScheduleEvent(ES_FIERCE, 6200ms);
            events.ScheduleEvent(ES_STORM, 12s);
            events.ScheduleEvent(ES_STOMP, 16300ms);
            events.ScheduleEvent(ES_METEOR, 26400ms);
            events.ScheduleEvent(ES_LIGHTNING, 30500ms);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case ES_PLAGUE:
                    if (Unit* t = RandomPlayer())
                        me->CastSpell(t, SPELL_PLAGUE, true);
                    events.Repeat(5100ms);
                    break;
                case ES_FIERCE:    DoCastVictim(SPELL_FIERCE_BLOW);  events.Repeat(8800ms);  break;
                case ES_STORM:     DoCastSelf(SPELL_SHADOW_STORM);   events.Repeat(13600ms); break;
                case ES_STOMP:     DoCastSelf(SPELL_WAR_STOMP);      events.Repeat(32s);     break;
                case ES_METEOR:
                    if (Unit* t = RandomPlayer())
                    {
                        _meteorTarget = t->GetGUID();
                        me->CastSpell(t, SPELL_METEOR_MARK, true);
                        DoCast(t, SPELL_METEOR);
                    }
                    events.Repeat(32s);
                    break;
                case ES_LIGHTNING:
                    MarkLightning();
                    if (Unit* t = RandomPlayer())
                        DoCast(t, SPELL_CALL_LIGHTNING);
                    events.Repeat(35100ms);
                    break;
            }
        }

        void MarkLightning()
        {
            std::vector<Player*> pool = PlayersWithin(me, 100.0f);
            uint32 const marks = std::min<uint32>(3 + uint32(pool.size()) / 10, uint32(pool.size()));
            // Ranged first: whoever stands beyond melee reach; the melee only make up what is left.
            Acore::Containers::RandomShuffle(pool);
            std::stable_partition(pool.begin(), pool.end(), [this](Player* p)
            {
                return !me->IsWithinMeleeRange(p, SETIS_MELEE_REACH);
            });
            pool.resize(marks);
            _marks.clear();
            for (Player* p : pool)
            {
                _marks.push_back(p->GetPosition());
                CastAt(p->GetPosition(), SPELL_LIGHTNING_MARK);
            }
        }

        void JustDied(Unit* killer) override
        {
            custom_world_boss_coa::JustDied(killer);
            uint32 const raid = me->GetMap()->GetPlayersCountExceptGMs();
            if (LootTemplate const* loot = LootTemplates_Creature.GetLootFor(me->GetCreatureTemplate()->lootid))
            {
                uint8 const group = me->GetMap()->IsHeroic() ? SETIS_HEROIC_GROUP : SETIS_NORMAL_GROUP;
                Player const* looter = me->GetLootRecipient();
                for (uint32 i = coa_setis::MinItems; i < coa_setis::LootItems(raid); ++i)
                    loot->Process(me->loot, LootTemplates_Creature, me->GetLootMode(), looter, group);
            }
            me->GetMap()->DoForAllPlayers([](Player* player)
            {
                if (player->IsGameMaster())
                    return;
                GiveOrMail(player, ITEM_RUNE_OF_ASCENSION, SETIS_RUNES);
                GiveOrMail(player, ITEM_BAZAAR_TOKEN, urand(SETIS_TOKENS_MIN, SETIS_TOKENS_MAX));
                GiveOrMail(player, ITEM_TREASURES_OF_AZEROTH, 1);
            });
            if (me->GetMapId() == SETIS_MAP)
                me->SummonGameObject(GO_SETIS_EXIT, SetisExitPortal.GetPositionX(), SetisExitPortal.GetPositionY(),
                    SetisExitPortal.GetPositionZ(), SetisExitPortal.GetOrientation(), 0, 0, 0, 0, 600, true,
                    GO_SUMMON_TIMED_DESPAWN);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_CALL_LIGHTNING)
            {
                for (Position const& mark : _marks)
                    CastAt(mark, SPELL_LIGHTNING_STRIKE);
                _marks.clear();
            }
            else if (spell->Id == SPELL_ARMAGEDDON)
                DoCastAOE(SPELL_ARMAGEDDON_BLAST, true);
            else if (spell->Id == SPELL_METEOR)
                if (Unit* target = ObjectAccessor::GetUnit(*me, _meteorTarget))
                    target->RemoveAurasDueToSpell(SPELL_METEOR_MARK, me->GetGUID());
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            custom_world_boss_coa::DamageTaken(attacker, damage, type, school);
            if (!_frenzy && me->HealthBelowPctDamaged(30, damage))
            {
                _frenzy = true;
                DoCastSelf(SPELL_FRENZY, true);
            }
            if (!_armageddon && me->HealthBelowPctDamaged(3, damage))
            {
                _armageddon = true;
                me->InterruptNonMeleeSpells(false);
                events.Reset();
                DoCastSelf(SPELL_ARMAGEDDON);
            }
        }

    private:
        bool _frenzy = false;
        bool _armageddon = false;
        std::vector<Position> _marks;
        ObjectGuid _meteorTarget;
    };

    class go_setis_altar_coa : public GameObjectScript
    {
    public:
        go_setis_altar_coa() : GameObjectScript("go_setis_altar_coa") { }

        bool OnGossipHello(Player* player, GameObject* go) override
        {
            if (!player->IsAlive())
                return true;
            ClearGossipMenuFor(player);
            AddGossipItemFor(player, GOSSIP_ICON_BATTLE, "Challenge Setis the Gate Warden", GOSSIP_SENDER_MAIN,
                GOSSIP_ACTION_INFO_DEF + 1);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Take your hands off the shrine.", GOSSIP_SENDER_MAIN,
                GOSSIP_ACTION_INFO_DEF + 2);
            SendGossipMenuFor(player, SETIS_SHRINE_TEXT, go->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player* player, GameObject* /*go*/, uint32 /*sender*/, uint32 action) override
        {
            CloseGossipMenuFor(player);
            if (action != GOSSIP_ACTION_INFO_DEF + 1 || !player->IsAlive())
                return true;
            // Only the Normal difficulties are open for now.
            if (player->GetRaidDifficulty() > RAID_DIFFICULTY_25MAN_NORMAL)
            {
                ChatHandler(player->GetSession()).SendNotification("Setis only answers the Normal difficulty.");
                return true;
            }
            player->TeleportTo(SETIS_MAP, SetisEntrance.GetPositionX(), SetisEntrance.GetPositionY(),
                SetisEntrance.GetPositionZ(), SetisEntrance.GetOrientation());
            return true;
        }
    };

    class go_setis_exit_coa : public GameObjectScript
    {
    public:
        explicit go_setis_exit_coa(char const* name) : GameObjectScript(name) { }

        bool OnGossipHello(Player* player, GameObject* /*go*/) override
        {
            if (!player->IsAlive())
                return true;
            // Twenty yards out on the open sand, away from the crystals behind the shrine, facing it.
            float const away = SetisShrine.GetOrientation() - float(M_PI);
            float const x = SetisShrine.GetPositionX() + SETIS_SHRINE_ARRIVAL * std::cos(away);
            float const y = SetisShrine.GetPositionY() + SETIS_SHRINE_ARRIVAL * std::sin(away);
            float z = SetisShrine.GetPositionZ();
            if (Map* silithus = sMapMgr->CreateBaseMap(1))
            {
                float const ground = silithus->GetHeight(x, y, z + 20.0f);
                if (ground > INVALID_HEIGHT)
                    z = ground;
            }
            player->TeleportTo(1, x, y, z + 0.5f, Position::NormalizeOrientation(away + float(M_PI)));
            return true;
        }
    };

    // Ascension's death dialog offers "Last Checkpoint" in a raid whose checkpoints are on (SMSG 0x767, u8);
    // the button sends CMSG 0x774 (u8 1). In Setis' map it carries the body back to the entrance.
    std::mutex g_checkpointLock;
    std::unordered_set<uint32> g_checkpointRequests;
    std::atomic<uint32> g_checkpointCount{0};

    class setis_checkpoint_packets : public ServerScript
    {
    public:
        setis_checkpoint_packets()
            : ServerScript("setis_checkpoint_packets", {SERVERHOOK_CAN_PACKET_RECEIVE_EARLY}) { }

        [[nodiscard]] bool CanPacketReceiveEarly(WorldSession* session, WorldPacket const& packet) override
        {
            if (packet.GetOpcode() != CMSG_COA_RESPAWN_AT_CHECKPOINT)
                return true;
            if (session)
            {
                std::lock_guard lock(g_checkpointLock);
                if (g_checkpointRequests.insert(session->GetAccountId()).second)
                    ++g_checkpointCount;
            }
            return false;
        }
    };

    class setis_checkpoint_players : public PlayerScript
    {
    public:
        setis_checkpoint_players()
            : PlayerScript("setis_checkpoint_players", {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_MAP_CHANGED}) { }

        void OnPlayerMapChanged(Player* player) override
        {
            WorldPacket packet(SMSG_COA_CHECKPOINTS_ENABLED, 1);
            packet << uint8(player->GetMapId() == SETIS_MAP ? 1 : 0);
            player->SendDirectMessage(&packet);
        }

        void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
        {
            if (!g_checkpointCount.load(std::memory_order_relaxed))
                return;
            {
                std::lock_guard lock(g_checkpointLock);
                if (!g_checkpointRequests.erase(player->GetSession()->GetAccountId()))
                    return;
                --g_checkpointCount;
            }
            if (player->GetMapId() != SETIS_MAP || player->IsAlive() || player->HasPlayerFlag(PLAYER_FLAGS_GHOST))
                return;
            player->NearTeleportTo(SetisEntrance.GetPositionX(), SetisEntrance.GetPositionY(),
                SetisEntrance.GetPositionZ(), SetisEntrance.GetOrientation());
        }
    };

    // -------------------------------------------------------- Korrim Snowgrave
    enum SnowgraveSpells
    {
        SPELL_FROZEN_CLUB       = 2119751,
        SPELL_MASSIVE_STOMP     = 2119757,
        SPELL_STOMP_HIT         = 2119758,
        SPELL_STOMP_DAMAGE_INFO = 2119759,
        SPELL_STOMP_DAMAGE      = 2119763,
        SPELL_STOMP_KNOCKBACK   = 2119764,
        SPELL_WATER_SPIKE       = 2119765,
        SPELL_HAIL              = 2119769,
        SPELL_HAIL_SHARD        = 2119773,
        SPELL_HAIL_MISSILE_LEFT = 2119771,
        SPELL_HAIL_MISSILE_RIGHT= 2119772,
        SPELL_STEAL_WARMTH      = 2119777,
        SPELL_CHILLED           = 2119778,
        SPELL_SHOCK_FROST       = 2119779,
        SPELL_SHOCK_FROST_HIT   = 2119780,
        SPELL_FROZEN_SOLID      = 2119784,
        SPELL_WINTERS_GRASP     = 2119787,
        SPELL_ICE_SPIKE_WARNING = 2119789,
        SPELL_ICE_SPIKE         = 2119790,
        SPELL_CAVE_IN_WARNING   = 2119794,
    };

    enum SnowgraveEvents
    {
        EW_STOMP = 1, EW_HAIL, EW_GRASP, EW_WARMTH, EW_SHOCK, EW_FIERCE,
        TW_ICICLE_WARN, TW_ICICLE, TW_HAIL, TW_HAIL_IMPACT, TW_RING, TW_RING_HIT, TW_WARMTH,
    };

    constexpr uint8 CHILL_FROZEN      = 10;
    constexpr uint32 GO_FALLEN_ICICLE = 978098;
    constexpr float HUDDLE_RANGE      = 5.0f;   // close enough to share Body Heat
    constexpr uint8 HAIL_VOLLEYS      = 20;  // one shard every 150 ms through the 3s channel
    constexpr float HAIL_RADIUS       = 5.0f;
    constexpr float RING_THROW_XY     = 8.0f;   // about six yards, onto the next ring
    constexpr float RING_THROW_Z      = 4.0f;
    constexpr uint8 GRASP_RINGS       = 6;
    constexpr uint8 MAX_FALLEN        = 12;  // icicles left on the ground at once; the oldest melts

    struct boss_snowgrave_coa : public custom_world_boss_coa
    {
        explicit boss_snowgrave_coa(Creature* creature) : custom_world_boss_coa(creature) { }

        void ApplyFlex()
        {
            Level const* lv = LevelOf(me);
            if (!lv || !lv->health)
                return;
            uint32 const players = std::clamp<uint32>(me->GetMap()->GetPlayersCountExceptGMs(), 10, 40);
            float const pct = me->GetHealthPct();
            uint32 const health = lv->health * players;
            me->SetCreateHealth(health);
            me->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
            me->UpdateMaxHealth();
            me->SetHealth(std::max<uint32>(uint32(me->GetMaxHealth() * pct / 100.0f), 1));
            me->ResetPlayerDamageReq();
        }

        void JustEngagedWith(Unit* who) override
        {
            ApplyFlex();
            custom_world_boss_coa::JustEngagedWith(who);
        }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            me->SetLootMode(me->GetMap()->IsHeroic() ? LOOT_MODE_HARD_MODE_1 : LOOT_MODE_DEFAULT);
            _hailImpacts.clear();
            ApplyFlex();
            DoCastSelf(SPELL_FROZEN_CLUB, true);
            _stomps = 0;
            ClearIcicles();
        }

        void JustDied(Unit* killer) override
        {
            ClearIcicles();
            custom_world_boss_coa::JustDied(killer);
        }

        void ClearIcicles()
        {
            me->RemoveDynObject(SPELL_WATER_SPIKE);
            me->RemoveDynObject(SPELL_ICE_SPIKE_WARNING);
            me->RemoveDynObject(SPELL_CAVE_IN_WARNING);
            me->GetMap()->DoForAllPlayers([](Player* p) { p->RemoveAurasDueToSpell(SPELL_CHILLED); });
            for (ObjectGuid const& guid : _fallen)
                if (GameObject* icicle = me->GetMap()->GetGameObject(guid))
                    icicle->DespawnOrUnsummon();
            _fallen.clear();
        }

        void Schedule() override
        {
            events.ScheduleEvent(EW_STOMP, 4200ms);
            events.ScheduleEvent(EW_HAIL, 14300ms);
            events.ScheduleEvent(EW_FIERCE, 20300ms);
            events.ScheduleEvent(EW_GRASP, 24300ms);
            events.ScheduleEvent(EW_WARMTH, 44300ms);
            events.ScheduleEvent(EW_SHOCK, 56300ms);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case EW_STOMP:  DoCastVictim(SPELL_MASSIVE_STOMP);  events.Repeat(62100ms); break;
                case EW_GRASP:  DoCastSelf(SPELL_WINTERS_GRASP);    events.Repeat(62100ms); break;
                case EW_WARMTH: DoCastSelf(SPELL_STEAL_WARMTH);     events.Repeat(62100ms); break;
                case EW_SHOCK:  DoCastSelf(SPELL_SHOCK_FROST);      events.Repeat(62100ms); break;
                case EW_FIERCE: DoCastVictim(SPELL_FIERCE_BLOW);    events.Repeat(9s);      break;
                case EW_HAIL:
                    if (Unit* t = RandomPlayer())
                    {
                        _hailTarget = t->GetGUID();
                        DoCast(t, SPELL_HAIL);
                    }
                    // Three hails a rotation: 20.1s, 24.6s and 17.4s apart.
                    events.Repeat(std::array<Milliseconds, 3>{ 20100ms, 24600ms, 17400ms }[_hails++ % 3]);
                    break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            switch (spell->Id)
            {
                case SPELL_MASSIVE_STOMP:
                {
                    if (Unit* tank = me->GetVictim())
                        me->CastSpell(tank, SPELL_STOMP_HIT, true);
                    int32 const base = Info(me, SPELL_STOMP_DAMAGE_INFO);
                    for (Player* p : PlayersWithin(me, 100.0f))
                    {
                        // Less further out: full next to him, a fifth at 40 yards and beyond.
                        float const falloff = std::clamp(1.0f - me->GetDistance(p) / 50.0f, 0.2f, 1.0f);
                        Hit(me, p, SPELL_STOMP_DAMAGE, int32(base * falloff) - 1);
                        me->CastSpell(p, SPELL_STOMP_KNOCKBACK, true);
                    }
                    ++_stomps;
                    _clock.ScheduleEvent(TW_ICICLE_WARN, 1s);
                    break;
                }
                case SPELL_HAIL:
                    _hailVolleys = HAIL_VOLLEYS;
                    _clock.ScheduleEvent(TW_HAIL, 150ms);
                    break;
                case SPELL_WINTERS_GRASP:
                    _ring = _ringHit = 0;
                    _clock.ScheduleEvent(TW_RING, 600ms);
                    break;
                case SPELL_STEAL_WARMTH:
                    _warmthSeconds = 15;
                    _clock.ScheduleEvent(TW_WARMTH, 0ms);
                    break;
                case SPELL_SHOCK_FROST:
                {
                    int32 const base = Info(me, SPELL_SHOCK_FROST_HIT);
                    for (Player* p : PlayersWithin(me, 100.0f))
                    {
                        uint8 stacks = 0;
                        if (Aura* a = p->GetAura(SPELL_CHILLED))
                        {
                            stacks = uint8(std::min<uint32>(a->GetStackAmount() * 2u, CHILL_FROZEN));
                            if (stacks >= CHILL_FROZEN)
                            {
                                p->RemoveAurasDueToSpell(SPELL_CHILLED);
                                me->CastSpell(p, SPELL_FROZEN_SOLID, true);
                            }
                            else
                                a->SetStackAmount(stacks);
                        }
                        Hit(me, p, SPELL_SHOCK_FROST_HIT, int32(base * (1.0f + 0.1f * stacks)) - 1);
                    }
                    break;
                }
            }
        }

        void Tick(uint32 tick) override
        {
            switch (tick)
            {
                case TW_ICICLE_WARN:
                {
                    // Three icicles after the first stomp, three more after each one after.
                    std::vector<Player*> pool = PlayersWithin(me, 100.0f);
                    Acore::Containers::RandomResize(pool, std::min<uint32>(3u * _stomps, 15u));
                    _icicles.clear();
                    for (Player* p : pool)
                    {
                        // On the ground under the player, even one who is in the air when it is picked.
                        Position pos = p->GetPosition();
                        pos.m_positionZ = me->GetMap()->GetHeight(me->GetPhaseMask(), pos.GetPositionX(),
                            pos.GetPositionY(), pos.GetPositionZ() + 2.0f);
                        _icicles.push_back(pos);
                        CastAt(pos, SPELL_CAVE_IN_WARNING);
                    }
                    _clock.ScheduleEvent(TW_ICICLE, 4s);
                    break;
                }
                case TW_ICICLE:
                    // The icicle stays where it fell until the fight ends; the last wave's chilling areas go (each
                    // one lasts ten minutes, and wave after wave of them weighs on every client).
                    me->RemoveDynObject(SPELL_WATER_SPIKE);
                    for (Position const& pos : _icicles)
                    {
                        CastAt(pos, SPELL_WATER_SPIKE);
                        if (GameObject* icicle = me->SummonGameObject(GO_FALLEN_ICICLE, pos.GetPositionX(),
                                pos.GetPositionY(), pos.GetPositionZ(), frand(0.0f, 2 * float(M_PI)), 0, 0, 0, 0, 0))
                            _fallen.push_back(icicle->GetGUID());
                        if (_fallen.size() > MAX_FALLEN)
                        {
                            if (GameObject* oldest = me->GetMap()->GetGameObject(_fallen.front()))
                                oldest->DespawnOrUnsummon();
                            _fallen.erase(_fallen.begin());
                        }
                    }
                    break;
                case TW_HAIL:
                    // Each volley is thrown at where the target stands now: the shards follow them, and land where
                    // they were, so one who keeps moving leaves a trail of them behind.
                    if (Unit* t = ObjectAccessor::GetUnit(*me, _hailTarget))
                    {
                        Position pos = t->GetPosition();
                        pos.m_positionZ = me->GetMap()->GetHeight(me->GetPhaseMask(), pos.GetPositionX(),
                            pos.GetPositionY(), pos.GetPositionZ() + 2.0f);
                        CastAt(pos, _hailVolleys % 2 ? SPELL_HAIL_MISSILE_LEFT : SPELL_HAIL_MISSILE_RIGHT);
                        _hailImpacts.push_back(pos);
                        uint32 const flight = uint32(me->GetExactDist(&pos) / 60.0f * 1000);
                        _clock.ScheduleEvent(TW_HAIL_IMPACT, Milliseconds(flight));
                    }
                    if (--_hailVolleys)
                        _clock.ScheduleEvent(TW_HAIL, 150ms);
                    break;
                case TW_HAIL_IMPACT:
                    if (!_hailImpacts.empty())
                    {
                        Position const pos = _hailImpacts.front();
                        _hailImpacts.erase(_hailImpacts.begin());
                        for (Player* p : PlayersWithin(me, 100.0f))
                            if (p->GetExactDist2d(&pos) < HAIL_RADIUS)
                                me->CastSpell(p, SPELL_HAIL_SHARD, true);
                    }
                    break;
                case TW_RING:
                {
                    // A ring every 1.5s, six yards further out, a spike every twelve yards on it (at most twelve, so a
                    // full raid's clients are not flooded with spike effects).
                    float const radius = 6.0f * (_ring + 1);
                    uint32 const spikes = std::clamp<uint32>(uint32(2 * float(M_PI) * radius / 12.0f), 6, 12);
                    std::vector<Position>& ring = _ringSpikes[_ring % 2];
                    ring.clear();
                    for (uint32 i = 0; i < spikes; ++i)
                    {
                        float const a = 2 * float(M_PI) * i / spikes;
                        Position pos = me->GetPosition();
                        pos.m_positionX += radius * std::cos(a);
                        pos.m_positionY += radius * std::sin(a);
                        pos.m_positionZ = me->GetMap()->GetHeight(me->GetPhaseMask(), pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ() + 5.0f);
                        ring.push_back(pos);
                        CastAt(pos, SPELL_ICE_SPIKE_WARNING);
                    }
                    _clock.ScheduleEvent(TW_RING_HIT, 2500ms);
                    if (++_ring < GRASP_RINGS)
                        _clock.ScheduleEvent(TW_RING, 1500ms);
                    break;
                }
                case TW_RING_HIT:
                {
                    float const radius = 6.0f * (_ringHit + 1);
                    std::vector<Player*> onRing = PlayersWithin(me, radius + 3.0f);
                    std::erase_if(onRing, [&](Player* p) { return me->GetExactDist2d(p) < radius - 3.0f; });
                    // The spikes nobody stands by; those under a player are cast at that player below.
                    for (Position const& pos : _ringSpikes[_ringHit++ % 2])
                        if (std::none_of(onRing.begin(), onRing.end(),
                                [&](Player* p) { return p->GetExactDist2d(&pos) < 6.0f; }))
                            CastAt(pos, SPELL_ICE_SPIKE);
                    // Everyone on the ring is hit and thrown outward onto the next ring, six yards out. No spell
                    // effect per player: a full raid on one ring would flood the clients with spikes.
                    int32 const spike = Info(me, SPELL_ICE_SPIKE);
                    for (Player* p : onRing)
                    {
                        Hit(me, p, SPELL_ICE_SPIKE, spike);
                        p->KnockbackFrom(me->GetPositionX(), me->GetPositionY(), RING_THROW_XY, RING_THROW_Z);
                    }
                    break;
                }
                case TW_WARMTH:
                    // Isolated players gain a stack each second, huddled ones lose one.
                    for (Player* p : PlayersWithin(me, 100.0f))
                    {
                        bool const huddled = !Players(me, [&](Player* x) { return x != p && p->IsWithinDistInMap(x, HUDDLE_RANGE); }).empty();
                        Aura* a = p->GetAura(SPELL_CHILLED);
                        if (huddled)
                        {
                            if (a)
                                a->ModStackAmount(-1);
                            continue;
                        }
                        AddStack(me, p, SPELL_CHILLED, CHILL_FROZEN);
                        a = p->GetAura(SPELL_CHILLED);
                        if (a && a->GetStackAmount() >= CHILL_FROZEN)
                        {
                            p->RemoveAurasDueToSpell(SPELL_CHILLED);
                            me->CastSpell(p, SPELL_FROZEN_SOLID, true);
                        }
                    }
                    if (--_warmthSeconds)
                        _clock.ScheduleEvent(TW_WARMTH, 1s);
                    else
                        for (Player* p : PlayersWithin(me, 100.0f))
                            p->RemoveAurasDueToSpell(SPELL_CHILLED);
                    break;
            }
        }

    private:
        uint32 _stomps = 0;
        uint32 _hails = 0;
        uint8 _hailVolleys = 0;
        uint8 _ring = 0;
        uint8 _ringHit = 0;
        uint8 _warmthSeconds = 0;
        ObjectGuid _hailTarget;
        std::vector<Position> _hailImpacts;
        std::vector<Position> _icicles;
        std::vector<ObjectGuid> _fallen;
        std::vector<Position> _ringSpikes[2];
    };

    // -------------------------------------------------------- Will of Soggoth
    enum SoggothSpells
    {
        SPELL_VOID_BEAM         = 254479,
        SPELL_VISIONS           = 2119310,
        SPELL_VISIONS_MARK      = 2119312,
        SPELL_VISIONS_HIT       = 2119313,
        SPELL_VOID_REND         = 2119314,
        SPELL_WAKING_TEAR       = 2119315,
        SPELL_TEAR_ZONE         = 2119317,
        SPELL_TEAR_HIT          = 2119319,
        SPELL_WAKING_NIGHTMARE  = 2119320,
        NPC_PSYCHOPHAGE         = 454004,
    };

    enum SoggothEvents
    {
        EG_BEAM = 1, EG_TEAR, EG_FIERCE, EG_NIGHTMARE, EG_VISIONS,
        TG_TEAR_SECOND, TG_NIGHTMARE, TG_REND,
    };

    constexpr float TEAR_RADIUS = 5.0f;
    constexpr uint32 TEAR_SECONDS = 20;

    struct boss_soggoth_coa : public custom_world_boss_coa
    {
        explicit boss_soggoth_coa(Creature* creature) : custom_world_boss_coa(creature), _summons(creature) { }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            _summons.DespawnAll();
            _tears.clear();
        }

        void JustDied(Unit* /*killer*/) override { _summons.DespawnAll(); }
        void JustSummoned(Creature* summon) override
        {
            _summons.Summon(summon);
            if (Unit* t = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                summon->AI()->AttackStart(t);
        }

        void Schedule() override
        {
            events.ScheduleEvent(EG_BEAM, 5s);
            events.ScheduleEvent(EG_TEAR, 6s);
            events.ScheduleEvent(EG_FIERCE, 10500ms);
            events.ScheduleEvent(EG_NIGHTMARE, 13200ms);
            events.ScheduleEvent(EG_VISIONS, 22100ms);
            _clock.ScheduleEvent(TG_TEAR_SECOND, 1s);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case EG_BEAM:
                    if (Unit* t = RandomPlayer(false))
                        me->CastSpell(t, SPELL_VOID_BEAM, true);
                    events.Repeat(2s);
                    break;
                case EG_FIERCE:  DoCastVictim(SPELL_FIERCE_BLOW); events.Repeat(7800ms); break;
                case EG_VISIONS: DoCastAOE(SPELL_VISIONS);        events.Repeat(45s);    break;
                case EG_TEAR:
                    if (Unit* t = RandomPlayer())
                    {
                        _tearSpot = t->GetPosition();
                        DoCast(t, SPELL_WAKING_TEAR);
                    }
                    events.Repeat(22100ms);
                    break;
                case EG_NIGHTMARE:
                    if (Unit* t = RandomPlayer())
                    {
                        me->CastSpell(t, SPELL_WAKING_NIGHTMARE, true);
                        _nightmare = t->GetPosition();
                        _phages = 6;
                        _clock.ScheduleEvent(TG_NIGHTMARE, 500ms);
                    }
                    events.Repeat(33100ms);
                    break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_WAKING_TEAR)
            {
                CastAt(_tearSpot, SPELL_TEAR_ZONE);
                _tears.push_back({ _tearSpot, TEAR_SECONDS });
            }
            else if (spell->Id == SPELL_VISIONS)
            {
                for (Player* p : PlayersWithin(me, 200.0f))
                {
                    me->CastSpell(p, SPELL_VISIONS_HIT, true);
                    me->CastSpell(p, SPELL_VISIONS_MARK, true);
                }
                _clock.ScheduleEvent(TG_REND, 6s);
            }
        }

        void Tick(uint32 tick) override
        {
            switch (tick)
            {
                case TG_TEAR_SECOND:
                    for (auto it = _tears.begin(); it != _tears.end();)
                    {
                        for (Player* p : Players(me, [&](Player* x) { return x->IsWithinDist3d(&it->first, TEAR_RADIUS); }))
                            me->CastSpell(p, SPELL_TEAR_HIT, true);
                        it = --it->second ? std::next(it) : _tears.erase(it);
                    }
                    _clock.ScheduleEvent(TG_TEAR_SECOND, 1s);
                    break;
                case TG_NIGHTMARE:
                {
                    Position pos = _nightmare;
                    pos.m_positionX += frand(-6.0f, 6.0f);
                    pos.m_positionY += frand(-6.0f, 6.0f);
                    pos.m_positionZ = me->GetMap()->GetHeight(me->GetPhaseMask(), pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ() + 5.0f);
                    me->SummonCreature(NPC_PSYCHOPHAGE, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 10000);
                    if (--_phages)
                        _clock.ScheduleEvent(TG_NIGHTMARE, 500ms);
                    break;
                }
                case TG_REND:
                    for (Player* p : PlayersWithin(me, 200.0f))
                        if (p->HasAura(SPELL_VISIONS_MARK))
                            me->CastSpell(p, SPELL_VOID_REND, true);
                    break;
            }
        }

    private:
        SummonList _summons;
        Position _tearSpot;
        Position _nightmare;
        uint8 _phages = 0;
        std::vector<std::pair<Position, uint32>> _tears;
    };

    // Psychophages: melee and Fierce Blow, and the level's health and damage.
    struct npc_psychophage_coa : public ScriptedAI
    {
        explicit npc_psychophage_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            ApplyLevelHealth(me);
            _damage = LevelOf(me) ? LevelOf(me)->damage : 1.0f;
            _fierce = 8s;
        }

        void DamageDealt(Unit* victim, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            ScriptedAI::DamageDealt(victim, damage, type, school);
            damage = uint32(damage * _damage);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;
            _fierce -= Milliseconds(diff);
            if (_fierce <= 0ms)
            {
                DoCastVictim(SPELL_FIERCE_BLOW);
                _fierce = 8s;
            }
            DoMeleeAttackIfReady();
        }

    private:
        float _damage = 1.0f;
        Milliseconds _fierce = 8s;
    };

    // --------------------------------------------------------------- Atal'Zul
    enum AtalzulSpells
    {
        SPELL_SPECTRAL_BOLT     = 2119801,
        SPELL_SPECTRAL_BOLT_HIT = 2119802,
        SPELL_LAND_OF_THE_DEAD  = 2119806,
        SPELL_RAISE_DEAD        = 2119807,
        SPELL_CHOKING_CLOUD     = 2119810,
        SPELL_SPECTRAL_VEIL     = 2119816,
        SPELL_VEIL_TRIGGER      = 2119817,
        SPELL_SPECTRAL_BOMB     = 2119819,
        SPELL_SPECTRAL_BOMB_HIT = 2119820,
        SPELL_HAND_OF_SOULREAVER= 2119825,
        SPELL_TITANIC_CRUSH     = 2119826,
        SPELL_TITANIC_CRUSH_HIT = 2119828,
        SPELL_TRAUMA            = 2119830,
        SPELL_ENDLESS_HUNGER    = 2119831,
        SPELL_CONSUME_LIFE      = 2119832,
        SPELL_CONSUME_LIFE_HEAL = 2119836,
        SPELL_CONSUME_LIFE_AP   = 2119837,
        SPELL_SOUL_RELEASE      = 2119839,
        SPELL_SOUL_RELEASE_HIT  = 2119840,
        SPELL_SPECTRAL_VOLLEY   = 2119848,
        SPELL_VEIL_PULSE        = 2119853,
        SPELL_VEIL_POWER        = 2119857,
        SPELL_GHOST             = 22650,
        SPELL_SOUL_BIND         = 2119845,
        SPELL_SOUL_FLAY_BEAM    = 2146711,
        SPELL_SOUL_LINK         = 2119847,

        NPC_ATALZUL             = 67532,
        NPC_ZULROGG             = 67533,
        NPC_DAMNED_WIGHT        = 67534,
        NPC_RESTLESS_SPIRIT     = 67535,
        NPC_SOUL_VESSEL         = 67536,
        NPC_VESSEL_BARRIER      = 67537,
        NPC_VESSEL_ANCHOR       = 67538,
    };

    enum AtalzulEvents { EA_BOLT = 1, EA_VOLLEY, EA_LAND };

    enum VesselState { VESSEL_IDLE, VESSEL_LINKED, VESSEL_SHIELDED, VESSEL_OPEN, VESSEL_BROKEN };

    constexpr uint32 ACTION_VESSEL_BROKEN = 1;
    constexpr uint32 ACTION_VESSEL_LINKED = 2;
    constexpr uint32 ACTION_AWAKEN = 3;
    constexpr uint8 SPIRIT_COUNT = 6;
    constexpr float SPIRIT_HEIGHT = 12.0f;
    constexpr float SPIRIT_SPREAD = 12.0f;
    constexpr uint32 ZUROGG_JUMP = 1;
    Position const ZuroggLanding = { 3368.63f, -4908.01f, 159.4f, 0.0f };
    constexpr float BARRIER_RISE = -0.4f;
    constexpr float ANCHOR_RISE = -0.4f;

    void Beam(Unit* from, Unit* to)
    {
        if (!from->HasUnitState(UNIT_STATE_CASTING))
            from->CastSpell(to, SPELL_SOUL_BIND, true);
    }

    void Dormant(Creature* creature, bool on)
    {
        if (on)
        {
            creature->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            creature->SetReactState(REACT_PASSIVE);
            if (!creature->HasAura(SPELL_GHOST))
                creature->AddAura(SPELL_GHOST, creature);
        }
        else
        {
            creature->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            creature->SetReactState(REACT_AGGRESSIVE);
            creature->RemoveAurasDueToSpell(SPELL_GHOST);
        }
    }

    struct npc_restless_spirit_coa : public ScriptedAI
    {
        explicit npc_restless_spirit_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            ApplyLevelHealth(me);
            me->SetReactState(REACT_PASSIVE);
        }

        void IsSummonedBy(WorldObject* /*summoner*/) override
        {
            me->SetDisableGravity(true);
            me->SetCanFly(true);
            me->SetHover(true);
        }

        bool Sent() const { return _sent; }

        void Send(Position const& goal)
        {
            _sent = true;
            _goal = goal;
            me->SetWalk(false);
            me->GetMotionMaster()->MovePoint(1, _goal, FORCED_MOVEMENT_NONE, 0.f, false);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_SPECTRAL_BOMB)
                return;
            Unit* caster = me->FindNearestCreature(NPC_ATALZUL, 400.0f);
            (caster ? caster : me)->CastSpell(me->GetPositionX(), me->GetPositionY(), me->GetPositionZ(),
                SPELL_SPECTRAL_BOMB_HIT, true);
            me->DespawnOrUnsummon(100ms);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!_sent || me->HasUnitState(UNIT_STATE_CASTING))
                return;
            if (me->GetExactDist(&_goal) > 3.0f)
            {
                if (me->movespline->Finalized())
                    me->GetMotionMaster()->MovePoint(1, _goal, FORCED_MOVEMENT_NONE, 0.f, false);
                return;
            }
            if (!_arrived)
            {
                _arrived = true;
                me->StopMoving();
                me->GetMotionMaster()->Clear();
                _scheduler.Schedule(0s, [this](TaskContext bomb)
                {
                    DoCastSelf(SPELL_SPECTRAL_BOMB);
                    bomb.Repeat(4s);
                });
            }
            _scheduler.Update(diff);
        }

    private:
        Position _goal;
        bool _sent = false;
        bool _arrived = false;
        TaskScheduler _scheduler;
    };

    struct npc_soul_vessel_coa : public ScriptedAI
    {
        explicit npc_soul_vessel_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            ApplyLevelHealth(me);
            me->SetReactState(REACT_PASSIVE);
            me->SetControlled(true, UNIT_STATE_ROOT);
            SetState(VESSEL_IDLE);
        }

        VesselState State() const { return _state; }

        void SetState(VesselState state)
        {
            _state = state;
            me->InterruptNonMeleeSpells(false);
            me->SetVisible(state != VESSEL_BROKEN);
            if (state == VESSEL_OPEN)
                me->RemoveUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
            else
                me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
            if (state == VESSEL_OPEN)
                me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
            else
                me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
            _assaulted = false;
            Keep(_barrier, state == VESSEL_SHIELDED, NPC_VESSEL_BARRIER, BARRIER_RISE);
            Keep(_anchor, state == VESSEL_LINKED || state == VESSEL_OPEN, NPC_VESSEL_ANCHOR, ANCHOR_RISE);
        }

        void Keep(ObjectGuid& guid, bool wanted, uint32 entry, float rise)
        {
            Creature* held = ObjectAccessor::GetCreature(*me, guid);
            if (held && wanted)
                return;
            if (held)
                held->DespawnOrUnsummon();
            guid.Clear();
            if (!wanted)
                return;
            if (TempSummon* made = me->SummonCreature(entry, me->GetPositionX(), me->GetPositionY(),
                me->GetPositionZ() + rise, 0, TEMPSUMMON_MANUAL_DESPAWN))
            {
                made->SetReactState(REACT_PASSIVE);
                guid = made->GetGUID();
            }
        }

        void Link()
        {
            Creature* atal = me->FindNearestCreature(NPC_ATALZUL, 400.0f);
            if (!atal)
                return;
            Creature* anchor = ObjectAccessor::GetCreature(*me, _anchor);
            Beam(anchor ? static_cast<Unit*>(anchor) : static_cast<Unit*>(me), atal);
        }

        void Click()
        {
            if (_state != VESSEL_IDLE)
                return;
            SetState(VESSEL_LINKED);
            if (Creature* atal = me->FindNearestCreature(NPC_ATALZUL, 400.0f))
                atal->AI()->DoAction(ACTION_VESSEL_LINKED);
        }

        void DamageTaken(Unit* /*attacker*/, uint32& damage, DamageEffectType /*type*/,
            SpellSchoolMask /*school*/) override
        {
            if (_state != VESSEL_OPEN)
                return;
            _assaulted = true;
            if (damage < me->GetHealth())
                return;
            damage = 0;
            SetState(VESSEL_BROKEN);
            for (Player* p : Players(me, [&](Player* x) { return me->IsWithinDistInMap(x, 100.0f); }))
            {
                me->CastSpell(p, SPELL_SOUL_RELEASE_HIT, true);
                AddStack(me, p, SPELL_SOUL_RELEASE);
            }
            if (Creature* atal = me->FindNearestCreature(NPC_ATALZUL, 400.0f))
                atal->AI()->DoAction(ACTION_VESSEL_BROKEN);
        }

        void UpdateAI(uint32 diff) override
        {
            if (_state == VESSEL_LINKED)
            {
                Link();
                return;
            }
            if (_state != VESSEL_OPEN)
                return;
            Link();
        }

        bool Assaulted() const { return _state == VESSEL_OPEN && _assaulted; }
        Position Where() const { return me->GetPosition(); }

    private:
        ObjectGuid _barrier;
        bool _assaulted = false;
        ObjectGuid _anchor;
        VesselState _state = VESSEL_IDLE;
    };

    class go_soul_vessel_altar : public GameObjectScript
    {
    public:
        go_soul_vessel_altar() : GameObjectScript("go_atalzul_vessel_coa") { }

        bool OnGossipHello(Player* /*player*/, GameObject* go) override
        {
            if (Creature* vessel = go->FindNearestCreature(NPC_SOUL_VESSEL, 5.0f))
                if (auto* ai = dynamic_cast<npc_soul_vessel_coa*>(vessel->AI()))
                    ai->Click();
            return true;
        }
    };

    struct boss_atalzul_coa : public custom_world_boss_coa
    {
        explicit boss_atalzul_coa(Creature* creature) : custom_world_boss_coa(creature), _summons(creature) { }

        void ApplyFlex()
        {
            Level const* lv = LevelOf(me);
            if (!lv || !lv->health)
                return;
            uint32 const players = std::clamp<uint32>(me->GetMap()->GetPlayersCountExceptGMs(), 10, 40);
            float const pct = me->GetHealthPct();
            uint32 const health = lv->health * players;
            me->SetCreateHealth(health);
            me->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
            me->UpdateMaxHealth();
            me->SetHealth(std::max<uint32>(uint32(me->GetMaxHealth() * pct / 100.0f), 1));
            me->ResetPlayerDamageReq();
        }

        template <typename F>
        void ForVessels(F&& f)
        {
            std::list<Creature*> vessels;
            me->GetCreatureListWithEntryInGrid(vessels, NPC_SOUL_VESSEL, 150.0f);
            for (Creature* v : vessels)
                if (auto* ai = dynamic_cast<npc_soul_vessel_coa*>(v->AI()))
                    f(ai);
        }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            me->SetLootMode(me->GetMap()->IsHeroic() ? LOOT_MODE_HARD_MODE_1 : LOOT_MODE_DEFAULT);
            ApplyFlex();
            _summons.DespawnAll();
            _nextVeil = 80;
            _phase = false;
            _dormant = true;
            me->RemoveAurasDueToSpell(SPELL_VEIL_POWER);
            me->ApplySpellImmune(0, IMMUNITY_EFFECT, SPELL_EFFECT_INTERRUPT_CAST, true);
            me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_INTERRUPT, true);
            ForVessels([](npc_soul_vessel_coa* ai) { ai->SetState(VESSEL_IDLE); });
            if (Creature* rogg = me->FindNearestCreature(NPC_ZULROGG, 400.0f, false))
            {
                if (!rogg->IsAlive())
                    rogg->Respawn(true);
                rogg->RemoveAurasDueToSpell(SPELL_SOUL_LINK);
            }
            Dormant(me, true);
        }

        void JustEngagedWith(Unit* who) override
        {
            ApplyFlex();
            custom_world_boss_coa::JustEngagedWith(who);
            if (Creature* rogg = me->FindNearestCreature(NPC_ZULROGG, 400.0f))
                if (!rogg->IsInCombat())
                    rogg->AI()->AttackStart(who);
        }

        void JustSummoned(Creature* summon) override
        {
            _summons.Summon(summon);
            if (summon->GetEntry() != NPC_DAMNED_WIGHT)
                return;
            summon->SetReactState(REACT_PASSIVE);
            summon->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_SUBMERGED);
            summon->m_Events.AddEventAtOffset([summon]()
            {
                summon->HandleEmoteCommand(EMOTE_ONESHOT_EMERGE);
            }, 1500ms);
            summon->m_Events.AddEventAtOffset([summon]()
            {
                summon->SetUInt32Value(UNIT_NPC_EMOTESTATE, 0);
            }, 2900ms);
            ObjectGuid bossGuid = me->GetGUID();
            summon->m_Events.AddEventAtOffset([summon, bossGuid]()
            {
                if (Creature* boss = ObjectAccessor::GetCreature(*summon, bossGuid))
                    summon->CastSpell(boss, SPELL_SOUL_FLAY_BEAM, true);
            }, 3s);
            summon->m_Events.AddEventAtOffset([summon]()
            {
                summon->InterruptNonMeleeSpells(false);
                summon->SetReactState(REACT_AGGRESSIVE);
                if (Player* target = summon->SelectNearestPlayer(150.0f))
                    summon->AI()->AttackStart(target);
            }, 4s);
        }

        void JustDied(Unit* /*killer*/) override
        {
            _summons.DespawnAll();
            ForVessels([](npc_soul_vessel_coa* ai) { ai->SetState(VESSEL_BROKEN); });
            if (Creature* rogg = me->FindNearestCreature(NPC_ZULROGG, 400.0f))
            {
                rogg->RemoveAurasDueToSpell(SPELL_SOUL_LINK);
                rogg->KillSelf();
                rogg->DespawnOrUnsummon(3s);
            }
        }

        void Schedule() override
        {
            events.ScheduleEvent(EA_BOLT, 700ms);
            events.ScheduleEvent(EA_VOLLEY, 8400ms);
            events.ScheduleEvent(EA_LAND, 11400ms);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case EA_BOLT:   DoCastVictim(SPELL_SPECTRAL_BOLT);  events.Repeat(1500ms);  break;
                case EA_VOLLEY: DoCastVictim(SPELL_SPECTRAL_VOLLEY); events.Repeat(12s);    break;
                case EA_LAND:   DoCastSelf(SPELL_LAND_OF_THE_DEAD); events.Repeat(61400ms); break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_SPECTRAL_BOLT)
                return;
            if (Unit* v = me->GetVictim())
                me->CastSpell(v, SPELL_SPECTRAL_BOLT_HIT, true);
        }

        void SpellHit(Unit* /*caster*/, SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_RAISE_DEAD)
            {
                Unit* t = RandomPlayer(false);
                if (!t)
                    return;
                Position pos = me->GetNearPosition(8.0f + 3.0f * float(_raise % 3), 2.4f * float(_raise));
                me->UpdateGroundPositionZ(pos.m_positionX, pos.m_positionY, pos.m_positionZ);
                me->SummonCreature(NPC_DAMNED_WIGHT, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 10000);
                if (_raise++ % 2 == 0)
                    CastAt(t->GetPosition(), SPELL_CHOKING_CLOUD);
            }
            else if (spell->Id == SPELL_VEIL_TRIGGER)
            {
                DoCastAOE(SPELL_VEIL_PULSE, true);
                AddStack(me, me, SPELL_VEIL_POWER);
            }
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            custom_world_boss_coa::DamageTaken(attacker, damage, type, school);
            if (_nextVeil && !_phase && me->HealthBelowPctDamaged(_nextVeil, damage))
            {
                _nextVeil = _nextVeil > 20 ? _nextVeil - 20 : 0;
                _phase = true;
                me->InterruptNonMeleeSpells(false);
                DoCastSelf(SPELL_SPECTRAL_VEIL);
                ForVessels([](npc_soul_vessel_coa* ai)
                {
                    if (ai->State() == VESSEL_SHIELDED)
                        ai->SetState(VESSEL_OPEN);
                });
                for (uint8 i = 0; i < SPIRIT_COUNT; ++i)
                    HoverSpirit(i);
                _scheduler.CancelAll();
                _scheduler.Schedule(3s, [this](TaskContext pull)
                {
                    PullSpirit();
                    pull.Repeat(2s);
                });
            }
        }

        void DoAction(int32 action) override
        {
            if (action == ACTION_VESSEL_LINKED)
            {
                bool all = true;
                ForVessels([&](npc_soul_vessel_coa* ai) { all = all && ai->State() == VESSEL_LINKED; });
                if (all && _dormant)
                    Awaken();
            }
            else if (action == ACTION_AWAKEN && _dormant)
                Awaken();
            else if (action == ACTION_VESSEL_BROKEN && _phase)
            {
                _phase = false;
                _summons.DespawnEntry(NPC_RESTLESS_SPIRIT);
                me->InterruptNonMeleeSpells(false);
                me->RemoveAurasDueToSpell(SPELL_SPECTRAL_VEIL);
                me->RemoveAurasDueToSpell(SPELL_VEIL_POWER);
                ForVessels([](npc_soul_vessel_coa* ai)
                {
                    if (ai->State() == VESSEL_OPEN)
                        ai->SetState(VESSEL_SHIELDED);
                });
            }
        }

        void Awaken()
        {
            _dormant = false;
            me->InterruptNonMeleeSpells(false);
            Dormant(me, false);
            ForVessels([](npc_soul_vessel_coa* ai) { ai->SetState(VESSEL_SHIELDED); });
            Creature* rogg = me->FindNearestCreature(NPC_ZULROGG, 400.0f);
            if (rogg)
            {
                rogg->AI()->DoAction(ACTION_AWAKEN);
                me->CastSpell(rogg, SPELL_SOUL_LINK, true);
            }
            Player* first = nullptr;
            for (Player* p : Players(me, [](Player*) { return true; }))
                if (!first || (p->HasTankSpec() && !first->HasTankSpec()) ||
                    (p->HasTankSpec() == first->HasTankSpec() && me->GetDistance(p) < me->GetDistance(first)))
                    first = p;
            if (first)
            {
                AttackStart(first);
                if (rogg)
                    rogg->AI()->AttackStart(first);
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!_dormant)
            {
                if (_phase)
                    _scheduler.Update(diff);
                custom_world_boss_coa::UpdateAI(diff);
                return;
            }
            Dormant(me, true);
        }

    private:
        void PullSpirit()
        {
            npc_restless_spirit_coa* spirit = nullptr;
            for (ObjectGuid const& guid : _summons)
                if (Creature* c = ObjectAccessor::GetCreature(*me, guid))
                    if (auto* ai = dynamic_cast<npc_restless_spirit_coa*>(c->AI()); ai && !ai->Sent())
                        spirit = ai;
            if (!spirit)
                return;
            std::vector<Position> goals;
            for (Player* p : Players(me, [&](Player* x) { return me->GetExactDist2d(x) > SPIRIT_SPREAD; }))
                goals.push_back(p->GetPosition());
            ForVessels([&](npc_soul_vessel_coa* ai)
            {
                if (ai->Assaulted())
                    goals.push_back(ai->Where());
            });
            spirit->Send(goals.empty() ? me->GetPosition() : Acore::Containers::SelectRandomContainerElement(goals));
            HoverSpirit(_hovered++);
        }

        void HoverSpirit(uint32 slot)
        {
            float const angle = float(M_PI) * 2.0f * float(slot % SPIRIT_COUNT) / SPIRIT_COUNT;
            me->SummonCreature(NPC_RESTLESS_SPIRIT, me->GetPositionX() + 8.0f * std::cos(angle),
                me->GetPositionY() + 8.0f * std::sin(angle), me->GetPositionZ() + SPIRIT_HEIGHT, angle,
                TEMPSUMMON_TIMED_DESPAWN, 120000);
        }

        SummonList _summons;
        TaskScheduler _scheduler;
        uint32 _hovered = 0;
        uint8 _nextVeil = 80;
        uint32 _raise = 0;
        bool _phase = false;
        bool _dormant = true;
    };

    enum ZulroggEvents { EZ_CRUSH = 1, EZ_FIERCE };

    struct boss_zulrogg_coa : public custom_world_boss_coa
    {
        explicit boss_zulrogg_coa(Creature* creature) : custom_world_boss_coa(creature) { }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            DoCastSelf(SPELL_HAND_OF_SOULREAVER, true);
            DoCastSelf(SPELL_ENDLESS_HUNGER, true);
            Position const& home = me->GetHomePosition();
            if (me->GetExactDist(&home) > 2.0f)
                me->NearTeleportTo(home.GetPositionX(), home.GetPositionY(), home.GetPositionZ(),
                    home.GetOrientation());
            _dormant = true;
            _jumping = false;
            Dormant(me, true);
        }

        void UpdateAI(uint32 diff) override
        {
            if (_dormant)
                Dormant(me, true);
            else if (_jumping)
                _scheduler.Update(diff);
            else
                custom_world_boss_coa::UpdateAI(diff);
        }

        void AttackStart(Unit* who) override
        {
            if (_jumping)
                _target = who->GetGUID();
            else
                custom_world_boss_coa::AttackStart(who);
        }

        void MovementInform(uint32 type, uint32 id) override
        {
            if (_jumping && type == EFFECT_MOTION_TYPE && id == ZUROGG_JUMP)
                Land();
        }

        void Land()
        {
            _jumping = false;
            me->SetReactState(REACT_AGGRESSIVE);
            if (Unit* t = ObjectAccessor::GetUnit(*me, _target))
                AttackStart(t);
        }

        void DoAction(int32 action) override
        {
            if (action != ACTION_AWAKEN)
                return;
            _dormant = false;
            Dormant(me, false);
            me->SetReactState(REACT_PASSIVE);
            me->InterruptNonMeleeSpells(false);
            _jumping = true;
            _scheduler.CancelAll();
            _scheduler.Schedule(4s, [this](TaskContext) { Land(); });
            me->GetMotionMaster()->MoveJump(ZuroggLanding, 25.0f, 15.0f, ZUROGG_JUMP);
        }

        void JustEngagedWith(Unit* who) override
        {
            custom_world_boss_coa::JustEngagedWith(who);
            if (Creature* atal = me->FindNearestCreature(NPC_ATALZUL, 400.0f))
                if (!atal->IsInCombat())
                    atal->AI()->AttackStart(who);
        }

        void Schedule() override
        {
            events.ScheduleEvent(EZ_FIERCE, 5400ms);
            events.ScheduleEvent(EZ_CRUSH, 7200ms);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case EZ_FIERCE: DoCastVictim(SPELL_FIERCE_BLOW);   events.Repeat(7600ms);  break;
                case EZ_CRUSH:  DoCastVictim(SPELL_TITANIC_CRUSH); events.Repeat(10800ms); break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_TITANIC_CRUSH)
                return;
            Unit* target = me->GetVictim();
            if (!target)
                return;
            for (Player* p : Players(me, [&](Player* x) { return target->IsWithinDistInMap(x, 5.0f); }))
                me->CastSpell(p, SPELL_TITANIC_CRUSH_HIT, true);
            me->CastSpell(target, SPELL_TRAUMA, true);
        }

        // Endless Hunger: every Consume Life that lands heals him, or at full
        // health raises his attack power.
        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            if (spell->Id != SPELL_CONSUME_LIFE || !target->IsPlayer())
                return;
            if (me->IsFullHealth())
                DoCastSelf(SPELL_CONSUME_LIFE_AP, true);
            else
                Hit(me, me, SPELL_CONSUME_LIFE_HEAL, Info(me, SPELL_CONSUME_LIFE) - 1);
        }

        // Hand of the Soulreaver: he cannot die while Atal'zul is bound.
        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            custom_world_boss_coa::DamageTaken(attacker, damage, type, school);
            if (damage >= me->GetHealth())
                if (Creature* atal = me->FindNearestCreature(NPC_ATALZUL, 400.0f))
                    if (atal->IsAlive())
                        damage = me->GetHealth() > 1 ? me->GetHealth() - 1 : 0;
        }

    private:
        bool _dormant = true;
        bool _jumping = false;
        TaskScheduler _scheduler;
        ObjectGuid _target;
    };

    // ------------------------------------------------------------ Trut-K'hahn
    enum TrutSpells
    {
        SPELL_FLAP              = 2119901,
        SPELL_DIVE_BOMB_INFO    = 2119902,
        SPELL_DIVE_BOMB         = 2119903,
        SPELL_DIVE_KNOCKBACK    = 2119904,
        SPELL_DIVE_STUN         = 2119905,
        SPELL_FEATHER_STORM     = 2119907,
        SPELL_CALL_THE_FLOCK    = 2119908,
        SPELL_TURKEY_RUSH       = 2119909,
        SPELL_TURKEY_RUSH_PRE   = 2119910,
        SPELL_TURKEY_RUSH_HIT   = 2119911,

        NPC_TRUT_FLOCK          = 9780030,
        NPC_FEATHER_STORM       = 9780031,
    };

    enum TrutEvents { ET_FIERCE = 1, ET_RUSH, ET_FLAP, ET_STORM, ET_FLOCK, TT_DIVE };

    constexpr uint8 FLOCK_SIZE = 5;

    struct boss_trut_khahn_coa : public custom_world_boss_coa
    {
        explicit boss_trut_khahn_coa(Creature* creature) : custom_world_boss_coa(creature), _summons(creature) { }

        void Reset() override
        {
            custom_world_boss_coa::Reset();
            _summons.DespawnAll();
        }

        void JustDied(Unit* /*killer*/) override { _summons.DespawnAll(); }

        void JustSummoned(Creature* summon) override
        {
            _summons.Summon(summon);
            if (summon->GetEntry() == NPC_TRUT_FLOCK)
                if (Unit* t = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                    summon->AI()->AttackStart(t);
        }

        void Schedule() override
        {
            events.ScheduleEvent(ET_FIERCE, 6s);
            events.ScheduleEvent(ET_RUSH, 15s);
            events.ScheduleEvent(ET_STORM, 25s);
            events.ScheduleEvent(ET_FLAP, 40s);
            events.ScheduleEvent(ET_FLOCK, 60s);
        }

        void Execute(uint32 eventId) override
        {
            switch (eventId)
            {
                case ET_FIERCE: DoCastVictim(SPELL_FIERCE_BLOW); events.Repeat(8s); break;
                case ET_RUSH:
                    if (Unit* t = RandomPlayer())
                    {
                        _rushTo = t->GetPosition();
                        CastAt(_rushTo, SPELL_TURKEY_RUSH_PRE);
                        DoCast(t, SPELL_TURKEY_RUSH);
                    }
                    events.Repeat(20s);
                    break;
                case ET_FLAP:
                    if (Unit* t = RandomPlayer(false))
                    {
                        _diveAt = t->GetPosition();
                        DoCastSelf(SPELL_FLAP);
                    }
                    events.Repeat(40s);
                    break;
                case ET_STORM:
                    if (Unit* t = RandomPlayer(false))
                        me->SummonCreature(NPC_FEATHER_STORM, t->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 15000);
                    events.Repeat(30s);
                    break;
                case ET_FLOCK: DoCastSelf(SPELL_CALL_THE_FLOCK); events.Repeat(60s); break;
            }
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            switch (spell->Id)
            {
                case SPELL_TURKEY_RUSH:
                {
                    // Everyone within 4 yards of his path is run over.
                    Position const from = me->GetPosition();
                    float const dx = _rushTo.GetPositionX() - from.GetPositionX();
                    float const dy = _rushTo.GetPositionY() - from.GetPositionY();
                    float const len2 = std::max(1.0f, dx * dx + dy * dy);
                    for (Player* p : PlayersWithin(me, 100.0f))
                    {
                        float const u = std::clamp(((p->GetPositionX() - from.GetPositionX()) * dx + (p->GetPositionY() - from.GetPositionY()) * dy) / len2, 0.0f, 1.0f);
                        float const ex = from.GetPositionX() + u * dx - p->GetPositionX();
                        float const ey = from.GetPositionY() + u * dy - p->GetPositionY();
                        if (ex * ex + ey * ey <= 16.0f)
                            me->CastSpell(p, SPELL_TURKEY_RUSH_HIT, true);
                    }
                    me->GetMotionMaster()->MoveCharge(_rushTo.GetPositionX(), _rushTo.GetPositionY(), _rushTo.GetPositionZ(), 42.0f);
                    break;
                }
                case SPELL_FLAP:
                    me->SetDisableGravity(true);
                    me->GetMotionMaster()->MovePoint(0, _diveAt.GetPositionX(), _diveAt.GetPositionY(), _diveAt.GetPositionZ() + 15.0f, FORCED_MOVEMENT_NONE, 0.f, 0.f, false);
                    _clock.ScheduleEvent(TT_DIVE, 3s);
                    break;
                case SPELL_CALL_THE_FLOCK:
                    for (uint8 i = 0; i < FLOCK_SIZE; ++i)
                    {
                        Position pos = me->GetPosition();
                        me->MovePosition(pos, 12.0f, 2 * float(M_PI) * i / FLOCK_SIZE);
                        me->SummonCreature(NPC_TRUT_FLOCK, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 10000);
                    }
                    break;
            }
        }

        void Tick(uint32 tick) override
        {
            if (tick != TT_DIVE)
                return;
            me->SetDisableGravity(false);
            me->NearTeleportTo(_diveAt.GetPositionX(), _diveAt.GetPositionY(), _diveAt.GetPositionZ(), me->GetOrientation());
            int32 const base = Info(me, SPELL_DIVE_BOMB_INFO);
            for (Player* p : PlayersWithin(me, 100.0f))
            {
                float const d = p->GetExactDist2d(&_diveAt);
                // Hit directly: stunned. Further out: less damage, thrown back.
                Hit(me, p, SPELL_DIVE_BOMB, int32(base * std::clamp(1.0f - d / 40.0f, 0.1f, 1.0f)) - 1);
                me->CastSpell(p, d <= 5.0f ? SPELL_DIVE_STUN : SPELL_DIVE_KNOCKBACK, true);
            }
        }

    private:
        SummonList _summons;
        Position _rushTo;
        Position _diveAt;
    };

    // A feather storm that drifts from player to player for 15 seconds.
    struct npc_feather_storm_coa : public ScriptedAI
    {
        explicit npc_feather_storm_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            me->SetReactState(REACT_PASSIVE);
            _pulse = 1s;
            _move = 0ms;
        }

        void UpdateAI(uint32 diff) override
        {
            _pulse -= Milliseconds(diff);
            _move -= Milliseconds(diff);
            if (_pulse <= 0ms)
            {
                Unit* caster = me;
                if (TempSummon* s = me->ToTempSummon())
                    if (Unit* trut = s->GetSummonerUnit())
                        caster = trut;
                for (Player* p : Players(me, [&](Player* x) { return me->IsWithinDistInMap(x, 8.0f); }))
                    caster->CastSpell(p, SPELL_FEATHER_STORM, true);
                _pulse = 1s;
            }
            if (_move <= 0ms)
            {
                std::vector<Player*> pool = Players(me, [&](Player* x) { return me->IsWithinDistInMap(x, 60.0f); });
                if (!pool.empty())
                {
                    Player* p = Acore::Containers::SelectRandomContainerElement(pool);
                    me->GetMotionMaster()->MovePoint(0, p->GetPosition());
                }
                _move = 5s;
            }
        }

    private:
        Milliseconds _pulse = 1s;
        Milliseconds _move = 0ms;
    };

    // Adds of the Atal'Zul and Trut-K'hahn fights: melee, Fierce Blow, the level.
    struct npc_custom_add_coa : public npc_psychophage_coa
    {
        using npc_psychophage_coa::npc_psychophage_coa;
    };

    template <class AI>
    class custom_script : public CreatureScript
    {
    public:
        explicit custom_script(char const* name) : CreatureScript(name) { }
        CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
    };
}

void AddCoaCustomWorldBossScripts()
{
    new coa_world_boss_level_loader();
    new custom_script<boss_setis_coa>("boss_setis_coa");
    new go_setis_altar_coa();
    new go_setis_exit_coa("go_setis_exit_coa");
    new go_setis_exit_coa("go_setis_leave_coa");
    new setis_checkpoint_packets();
    new setis_checkpoint_players();
    new custom_script<boss_snowgrave_coa>("boss_snowgrave_coa");
    void AddCoaSnowgraveInstanceScripts();
    AddCoaSnowgraveInstanceScripts();
    new custom_script<boss_soggoth_coa>("boss_soggoth_coa");
    new custom_script<npc_psychophage_coa>("npc_psychophage_coa");
    new custom_script<boss_atalzul_coa>("boss_atalzul_coa");
    void AddCoaAtalzulInstanceScripts();
    AddCoaAtalzulInstanceScripts();
    new custom_script<boss_zulrogg_coa>("boss_zulrogg_coa");
    new custom_script<npc_soul_vessel_coa>("npc_soul_vessel_coa");
    new go_soul_vessel_altar();
    new custom_script<npc_restless_spirit_coa>("npc_restless_spirit_coa");
    new custom_script<npc_custom_add_coa>("npc_custom_add_coa");
    new custom_script<boss_trut_khahn_coa>("boss_trut_khahn_coa");
    new custom_script<npc_feather_storm_coa>("npc_feather_storm_coa");
}
