#include "ManastormModuleConfig.h"
#include "ManastormClientBridge.h"
#include "ManastormMgr.h"

#include "AllCreatureScript.h"
#include "UnitScript.h"
#include "AllMapScript.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "PlayerScript.h"
#include <limits>
#include "Language.h"
#include <string>
#include "SpellScript.h"
#include "Chat.h"
#include "ScriptedGossip.h"

void AddSC_manastorm_commandscript();

namespace
{
    constexpr char const* LOG_FILTER = "module.manastorm.endless";
    constexpr char const* CLIENT_ADDON_PREFIX = "MANASTORM\t";

    bool ParsePositiveDepth(
        std::string const& text,
        uint32& depth)
    {
        if (text.empty())
            return false;

        uint64 value = 0;

        uint64 const maxValue =
            std::numeric_limits<uint32>::max();

        for (char character : text)
        {
            if (character < '0' ||
                character > '9')
            {
                return false;
            }

            uint32 const digit =
                uint32(character - '0');

            if (value >
                (maxValue - digit) / 10)
            {
                return false;
            }

            value =
                (value * 10) +
                digit;
        }

        if (!value)
            return false;

        depth = uint32(value);

        return true;
    }

    class spell_manastorm_baseline_tool :
        public SpellScript
    {
        PrepareSpellScript(spell_manastorm_baseline_tool);

        bool _matrixChargeConsumed = false;

        SpellCastResult CheckCast()
        {
            Player* player =
                GetCaster()
                ? GetCaster()->ToPlayer()
                : nullptr;

            if (!player)
                return SPELL_FAILED_BAD_TARGETS;

            ManastormMgr& mgr =
                ManastormMgr::Instance();

            //
            // ALL THREE baseline tools are Manastorm/Endless-only.
            //
            if (!mgr.IsPlayerInActiveEndlessStage(
                player))
            {
                return SPELL_FAILED_NOT_HERE;
            }

            switch (GetSpellInfo()->Id)
            {
            case ManastormBaseline::SpellPotion:
            {
                if (!mgr.HasManastormPotionCharge(
                    player))
                {
                    return SPELL_FAILED_NOT_READY;
                }

                break;
            }

            case ManastormBaseline::
            SpellRegenerationMatrix:
            {
                //
                // Recovered spell restriction.
                //
                if (player->IsInCombat())
                    return SPELL_FAILED_AFFECTING_COMBAT;

                Unit* explicitTarget =
                    GetExplTargetUnit();

                Player* target =
                    explicitTarget
                    ? explicitTarget->ToPlayer()
                    : nullptr;

                //
                // Must be a dead member of this exact Endless
                // run and exact current stage instance.
                //
                if (!target ||
                    !mgr.IsValidRegenerationMatrixTarget(
                        player,
                        target))
                {
                    return SPELL_FAILED_BAD_TARGETS;
                }

                ManastormRun const* run =
                    mgr.GetRunFor(player);

                if (!run ||
                    !run->HasResurrectionCharges())
                {
                    return SPELL_FAILED_NOT_READY;
                }

                break;
            }

            case ManastormBaseline::
            SpellMagicalEscape:
                break;

            default:
                break;
            }

            return SPELL_CAST_OK;
        }

        void HandleAfterCast()
        {
            Player* player =
                GetCaster()
                ? GetCaster()->ToPlayer()
                : nullptr;

            if (!player)
                return;

            ManastormMgr& mgr =
                ManastormMgr::Instance();

            switch (GetSpellInfo()->Id)
            {
            case ManastormBaseline::SpellPotion:
            {
                //
                // Effect 136 / 137 remain native:
                //
                // 136 = heal percentage
                // 137 = energize percentage
                //
                // We reconstruct the missing custom
                // charge behavior here.
                //
                if (!mgr.ConsumeManastormPotionCharge(
                    player))
                {
                    return;
                }

                //
                // Recovered secondary Potion aura:
                // restores Energy/Rage every second.
                //
                player->CastSpell(
                    player,
                    ManastormBaseline::
                    SpellPotionResourceRegen,
                    true);

                break;
            }

            case ManastormBaseline::
            SpellMagicalEscape:
            {
                //
                // Recovered player-facing behavior:
                //
                // remove movement impairing effects,
                // loss-of-control mechanics,
                // disarms,
                // silences,
                // including banish-style control.
                //
                uint32 mechanicMask =
                    IMMUNE_TO_MOVEMENT_IMPAIRMENT_AND_LOSS_CONTROL_MASK |
                    (1u << MECHANIC_DISARM) |
                    (1u << MECHANIC_SILENCE);

                player->RemoveAurasWithMechanic(
                    mechanicMask);

                break;
            }

            case ManastormBaseline::
            SpellRegenerationMatrix:
            default:
                //
                // Spell 93309 already uses the core's
                // native resurrection spell effect.
                //
                break;
            }
        }

        void HandleAfterHit()
        {
            if (_matrixChargeConsumed ||
                GetSpellInfo()->Id !=
                ManastormBaseline::
                SpellRegenerationMatrix)
            {
                return;
            }

            Player* caster =
                GetCaster()
                ? GetCaster()->ToPlayer()
                : nullptr;

            Player* target =
                GetHitPlayer();

            if (!caster || !target)
                return;

            //
            // This hook runs after the native resurrection effect
            // successfully reaches its target.
            //
            // Therefore a failed cast does NOT consume a resource.
            //
            if (ManastormMgr::Instance()
                .ConsumeRegenerationMatrixCharge(
                    caster,
                    target))
            {
                _matrixChargeConsumed = true;
            }
        }

        void Register() override
        {
            OnCheckCast +=
                SpellCheckCastFn(
                    spell_manastorm_baseline_tool::
                    CheckCast);

            AfterCast +=
                SpellCastFn(
                    spell_manastorm_baseline_tool::
                    HandleAfterCast);

            AfterHit +=
                SpellHitFn(
                    spell_manastorm_baseline_tool::
                    HandleAfterHit);
        }
    };

class manastorm_worldscript : public WorldScript
{
public:
    manastorm_worldscript()
        : WorldScript("manastorm_worldscript")
    {
    }

    void OnAfterConfigLoad(bool reload) override
    {
        ManastormModuleConfig::Load(reload);
    }

    void OnStartup() override
    {
        ManastormModuleConfig::LogConfiguration();

        if (!ManastormModuleConfig::Enabled())
        {
            LOG_INFO(LOG_FILTER, "Manastorm is disabled by configuration.");
            return;
        }

        if (ManastormMgr::Instance().ReloadData())
        {
            LOG_INFO(LOG_FILTER,
                "Shared Manastorm backend initialized.");
        }
        else
        {
            LOG_ERROR(LOG_FILTER,
                "Manastorm started without a valid datastore. "
                "Apply the world SQL before using `.manastorm start`.");
        }
    }
    void OnUpdate(uint32 diff) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance().Update(diff);
    }
};

class manastorm_creaturescript : public AllCreatureScript
{
public:
    manastorm_creaturescript()
        : AllCreatureScript("manastorm_creaturescript")
    {
    }

    void OnBeforeCreatureSelectLevel(
        CreatureTemplate const* /*creatureTemplate*/,
        Creature* creature,
        uint8& level) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance()
            .OnBeforeCreatureSelectLevel(
                creature,
                level);
    }

    void OnCreatureSelectLevel(
        CreatureTemplate const* /*creatureTemplate*/,
        Creature* creature) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance()
            .OnCreatureSelectLevel(
                creature);
    }

    void OnCreatureAddWorld(
        Creature* creature) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance()
            .OnCreatureAddWorld(creature);
    }

    bool CanCreatureGossipHello(Player* player, Creature* creature) override
    {
        return ManastormModuleConfig::Enabled() &&
            ManastormMgr::Instance().HandleGuideGossip(player, creature, 0);
    }

    bool CanCreatureGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        return ManastormModuleConfig::Enabled() && sender == GOSSIP_SENDER_MAIN &&
            ManastormMgr::Instance().HandleGuideGossip(player, creature, action);
    }

    void OnCreatureRemoveWorld(
        Creature* creature) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance()
            .OnCreatureRemoveWorld(creature);
    }
};

class manastorm_unitscript : public UnitScript
{
public:
    manastorm_unitscript()
        : UnitScript(
            "manastorm_unitscript",
            true,
            {
                UNITHOOK_ON_DAMAGE,
                UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK,
                UNITHOOK_MODIFY_MELEE_DAMAGE,
                UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
                UNITHOOK_ON_UNIT_DEATH
            })
    {
    }

    void OnDamage(
        Unit* attacker,
        Unit* victim,
        uint32& damage) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance().OnDamage(
            attacker,
            victim,
            damage);
    }

    void ModifyMeleeDamage(
        Unit* target,
        Unit* attacker,
        uint32& damage) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        damage =
            ManastormMgr::Instance().ScaleCreatureDamage(
                attacker,
                target,
                damage,
                DIRECT_DAMAGE);
    }

    void ModifySpellDamageTaken(
        Unit* target,
        Unit* attacker,
        int32& damage,
        SpellInfo const* /*spellInfo*/) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        if (damage <= 0)
            return;

        uint32 const scaled =
            ManastormMgr::Instance().ScaleCreatureDamage(
                attacker,
                target,
                uint32(damage),
                SPELL_DIRECT_DAMAGE);

        damage =
            scaled >
            uint32(std::numeric_limits<int32>::max())
            ? std::numeric_limits<int32>::max()
            : int32(scaled);
    }

    void ModifyPeriodicDamageAurasTick(
        Unit* target,
        Unit* attacker,
        uint32& damage,
        SpellInfo const* /*spellInfo*/) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        damage =
            ManastormMgr::Instance().ScaleCreatureDamage(
                attacker,
                target,
                damage,
                DOT);
    }

    void OnUnitDeath(
        Unit* unit,
        Unit* killer) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance().OnUnitDeath(
            unit,
            killer);
    }
};

class manastorm_playerscript : public PlayerScript
{
public:
    manastorm_playerscript()
        : PlayerScript(
            "manastorm_playerscript",
            {
                PLAYERHOOK_ON_LOGIN,
                PLAYERHOOK_ON_LEVEL_CHANGED,
                PLAYERHOOK_ON_GIVE_EXP,
                PLAYERHOOK_ON_BEFORE_SEND_CHAT_MESSAGE
            })
    {
    }

    void OnPlayerLogin(Player* player) override
    {
        if (ManastormModuleConfig::Enabled())
            ManastormMgr::Instance().OnPlayerLogin(player);
        // Native mode publishes false flags when disabled; Mode 1 sends no native configs.
        ManastormClientBridge::Instance().Login(player);
    }

    void OnPlayerLevelChanged(
        Player* player,
        uint8 oldLevel) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance()
            .OnPlayerLevelChanged(player, oldLevel);
    }

    void OnPlayerGiveXP(
        Player* player,
        uint32& amount,
        Unit* victim,
        uint8 xpSource) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance()
            .OnPlayerGiveXP(
                player,
                amount,
                victim,
                xpSource);
    }

    void OnPlayerBeforeSendChatMessage(
        Player* player,
        uint32& type,
        uint32& lang,
        std::string& msg) override
    {
        if (!ManastormModuleConfig::Enabled() ||
            !ManastormModuleConfig::IsReconstructedClientMode())
        {
            return;
        }

        if (!player ||
            type != CHAT_MSG_WHISPER ||
            lang != LANG_ADDON)
        {
            return;
        }

        std::string const prefix =
            CLIENT_ADDON_PREFIX;

        if (msg.size() < prefix.size() ||
            msg.compare(
                0,
                prefix.size(),
                prefix) != 0)
        {
            return;
        }

        std::string const payload =
            msg.substr(
                prefix.size());

        ManastormMgr& mgr =
            ManastormMgr::Instance();

        //
        // Existing ObjectiveTracker / UI state request.
        //
        if (payload == "REQUEST")
        {
            mgr.SyncClientState(
                player);

            return;
        }

        //
        // Standalone Manastorm UI:
        //
        // ENTER|<startingDepth>
        //
        if (payload.compare(
            0,
            6,
            "ENTER|") == 0)
        {
            uint32 depth = 0;

            if (!ParsePositiveDepth(
                payload.substr(6),
                depth))
            {
                ChatHandler(
                    player->GetSession())
                    .SendSysMessage(
                        "Manastorm: invalid starting depth.");

                return;
            }

            std::string error;

            if (!mgr.StartRun(
                player,
                depth,
                error))
            {
                ChatHandler(
                    player->GetSession())
                    .PSendSysMessage(
                        "Manastorm: {}",
                        error);
            }

            return;
        }

        //
        // Standalone Manastorm UI:
        //
        // LEAVE
        //
        if (payload == "LEAVE")
        {
            std::string error;

            if (!mgr.StopRun(
                player,
                error))
            {
                ChatHandler(
                    player->GetSession())
                    .PSendSysMessage(
                        "Manastorm: {}",
                        error);
            }

            return;
        }
    }
};

class manastorm_mapscript : public AllMapScript
{
public:
    manastorm_mapscript()
        : AllMapScript("manastorm_mapscript")
    {
    }

    void OnPlayerEnterAll(Map* map, Player* player) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance().OnPlayerEnterMap(map, player);
    }
};
}

void AddSC_manastorm()
{
    new manastorm_worldscript();
    new manastorm_creaturescript();
    new manastorm_unitscript();
    new manastorm_playerscript();
    new manastorm_mapscript();

    RegisterSpellScript(spell_manastorm_baseline_tool);

    AddSC_manastorm_commandscript();
}
