#include "ManastormModuleConfig.h"
#include "ManastormClientBridge.h"
#include "ManastormClientUIFixes.h"
#include "ManastormMobilityClient.h"
#include "ManastormPotionClient.h"
#include "ManastormMgr.h"

#include "AllCreatureScript.h"
#include "GlobalScript.h"
#include "AllSpellScript.h"
#include "DBCStructure.h"
#include "UnitScript.h"
#include "AllMapScript.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "QuestDef.h"
#include "ScriptMgr.h"
#include "PlayerScript.h"
#include <algorithm>
#include <limits>
#include "Language.h"
#include <string>
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Chat.h"
#include "AscensionManastormGadgets.h"

void AddSC_manastorm_commandscript();
void AddSC_manastorm_greedy_demon();
void AddSC_manastorm_reward_tools();

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

            uint32 const spellId =
                GetSpellInfo()->Id;

            //
            // Cogsley (93418) is a native non-combat companion summon.
            // Its recovered item text says it only works in the Manastorm.
            //
            // Unlike combat tools, the companion is useful while the player
            // is still preparing inside the private stage, so validate exact
            // run/map ownership rather than requiring ACTIVE state.
            //
            if (spellId == 93418)
            {
                ManastormRun const* run =
                    mgr.GetRunFor(player);

                Map const* map =
                    player->FindMap();

                if (!run ||
                    !map ||
                    run->GetState() == ManastormRunState::Failed ||
                    run->GetState() == ManastormRunState::Finished ||
                    map->GetId() != run->GetSegment().MapId ||
                    map->GetInstanceId() != run->GetInstanceId())
                {
                    return SPELL_FAILED_NOT_HERE;
                }

                return SPELL_CAST_OK;
            }

            if (!mgr.IsPlayerInUsableEndlessStage(
                player))
            {
                return SPELL_FAILED_NOT_HERE;
            }

            switch (spellId)
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

        void SuppressLegacyPotionReserve(SpellEffIndex effIndex)
        {
            // Effect 183 runs at launch in this core. The shared backend owns
            // the reserve; do not also start 762608's cooldown/stack chain.
            if (GetSpellInfo()->Id == ManastormBaseline::SpellPotion &&
                effIndex == EFFECT_2 &&
                GetSpellInfo()->Effects[effIndex].Effect == 183)
            {
                PreventHitDefaultEffect(effIndex);
            }
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
            // This script also handles Matrix, Escape and Cogsley. ANY keeps
            // their registrations valid; the handler only suppresses Potion.
            OnEffectLaunch += SpellEffectFn(
                spell_manastorm_baseline_tool::SuppressLegacyPotionReserve,
                EFFECT_ALL, SPELL_EFFECT_ANY);

            OnEffectLaunchTarget += SpellEffectFn(
                spell_manastorm_baseline_tool::SuppressLegacyPotionReserve,
                EFFECT_ALL, SPELL_EFFECT_ANY);

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

class manastorm_safety_spells : public GlobalScript
{
public:
    manastorm_safety_spells() : GlobalScript("manastorm_safety_spells", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* spell) override
    {
        if (!ManastormModuleConfig::Enabled() || !spell)
            return;

        if (spell->Id == 93306)
        {
            spell->AuraInterruptFlags = 0;
            return;
        }

        if (spell->Id != 93307)
            return;

        spell->Effects[EFFECT_0].Effect = SPELL_EFFECT_APPLY_AURA;
        spell->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_SCHOOL_IMMUNITY;
        spell->Effects[EFFECT_0].MiscValue = SPELL_SCHOOL_MASK_ALL;
        spell->Effects[EFFECT_0].BasePoints = 0;
        spell->Effects[EFFECT_1].Effect = SPELL_EFFECT_APPLY_AURA;
        spell->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_UNATTACKABLE;
        spell->Attributes |= SPELL_ATTR0_NO_AURA_CANCEL;
        spell->AttributesEx3 &= ~SPELL_ATTR3_ONLY_ON_PLAYER;
        spell->AttributesCu |= SPELL_ATTR0_CU_POSITIVE;
        spell->AuraInterruptFlags = 0;
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

        ManastormMobilityClient::Load();
        ManastormPotionClient::Load();

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
                UNITHOOK_ON_AURA_APPLY,
                UNITHOOK_ON_AURA_REMOVE,
                UNITHOOK_RESOLVE_SPELL_CAST,
                UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE,
                UNITHOOK_MODIFY_HEAL_RECEIVED,
                UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK,
                UNITHOOK_MODIFY_MELEE_DAMAGE,
                UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
                UNITHOOK_ON_UNIT_ENTER_COMBAT,
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

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (unit && aura && ManastormMobilityClient::IsMixture(aura->GetId()))
            if (Player* player = unit->ToPlayer())
                ManastormMobilityClient::SyncAuras(player);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode /*mode*/) override
    {
        if (unit && application && ManastormMobilityClient::IsMixture(application->GetBase()->GetId()))
            if (Player* player = unit->ToPlayer())
                ManastormMobilityClient::OnMixtureRemoved(player);
    }

    void ResolveSpellCast(Unit* caster, SpellInfo const*& spellInfo) override
    {
        if (!ManastormModuleConfig::Enabled() || !spellInfo ||
            spellInfo->Id == 93378 || spellInfo->Id == 93380 || spellInfo->Id == 93412)
        {
            return;
        }

        uint32 const rankedSpell = ManastormMgr::Instance().ResolveAffixRankSpell(caster, spellInfo->Id);
        if (rankedSpell != spellInfo->Id)
            if (SpellInfo const* rankedInfo = sSpellMgr->GetSpellInfo(rankedSpell))
                spellInfo = rankedInfo;
    }

    void ModifySpellEffectBaseValue(
        Unit const* caster,
        SpellInfo const* spellInfo,
        uint8 effectIndex,
        float& value) override
    {
        if (!ManastormModuleConfig::Enabled() ||
            !caster ||
            !spellInfo ||
            effectIndex != EFFECT_0 ||
            (spellInfo->Id != 93378 && spellInfo->Id != 93380 && spellInfo->Id != 93412))
        {
            return;
        }

        // Preserve Fungal's summon gate, Toxic Spores' bounded lifetime and
        // the cosmetic Energy helper's target shape; only their amount is ranked.
        uint32 const rankedSpell = ManastormMgr::Instance().ResolveAffixRankSpell(caster, spellInfo->Id);
        if (rankedSpell == spellInfo->Id)
            return;

        SpellInfo const* rankedInfo = sSpellMgr->GetSpellInfo(rankedSpell);
        if (!rankedInfo || rankedInfo->Effects[EFFECT_0].RealPointsPerLevel != 0.0f)
            return;

        // Sample raw rank data; the original CalcValue applies caster modifiers once.
        value = float(rankedInfo->Effects[EFFECT_0].CalcValue(nullptr));
    }

    void ModifyHealReceived(
        Unit* target,
        Unit* healer,
        uint32& heal,
        SpellInfo const* spellInfo) override
    {
        if (!ManastormModuleConfig::Enabled() ||
            !spellInfo ||
            spellInfo->Id != 991510 ||
            !target ||
            target != healer ||
            !heal)
        {
            return;
        }

        Player* player = target->ToPlayer();
        if (!player ||
            !player->IsInWorld() ||
            !player->IsAlive() ||
            player->IsBeingTeleported())
        {
            return;
        }

        ManastormRun const* run =
            ManastormMgr::Instance().GetRunFor(player);

        Map const* map = player->FindMap();
        if (!run ||
            !map ||
            (run->GetState() != ManastormRunState::Active &&
             run->GetState() != ManastormRunState::StageComplete) ||
            map->GetId() != run->GetSegment().MapId ||
            map->GetInstanceId() != run->GetInstanceId())
        {
            return;
        }

        // Apply only the highest learned Hearty Heal rank (93467-93476).
        // The donor bonus is 25% per rank; preserve the native heart spell's
        // level/stat healing, absorb handling, combat log and mana effect.
        uint32 rank = 0;
        for (uint32 spellId = 93476; spellId >= 93467; --spellId)
        {
            if (player->HasSpell(spellId))
            {
                rank = spellId - 93467 + 1;
                break;
            }
        }

        uint64 const upgradedHeal = uint64(heal) * (4 + rank) / 4;
        heal = uint32(std::min<uint64>(
            upgradedHeal,
            std::numeric_limits<uint32>::max()));
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

        ManastormMgr::Instance().OnMeleeDamage(
            attacker,
            target,
            damage);
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

    void OnUnitEnterCombat(
        Unit* unit,
        Unit* victim) override
    {
        if (!ManastormModuleConfig::Enabled())
            return;

        ManastormMgr::Instance()
            .OnUnitEnterCombat(
                unit,
                victim);
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
                PLAYERHOOK_ON_MAP_CHANGED,
                PLAYERHOOK_ON_LEVEL_CHANGED,
                PLAYERHOOK_ON_GIVE_EXP,
                PLAYERHOOK_ON_BEFORE_SEND_CHAT_MESSAGE,
                PLAYERHOOK_PASSED_QUEST_KILLED_MONSTER_CREDIT,
                PLAYERHOOK_ON_BEFORE_CRITERIA_PROGRESS,
                PLAYERHOOK_ON_SEND_SPELL_CHARGE_STATES,
                PLAYERHOOK_CAN_REPOP_AT_GRAVEYARD
            })
    {
    }

    void OnPlayerLogin(Player* player) override
    {
        if (ManastormModuleConfig::Enabled())
            ManastormMgr::Instance().OnPlayerLogin(player);
        // Native mode publishes false flags when disabled; Mode 1 sends no native configs.
        ManastormClientBridge::Instance().Login(player);
        ManastormMobilityClient::Sync(player);
        ManastormMgr::Instance().SyncManastormPotionCharges(player);
        ManastormClientUIFixes::ScheduleLoginPush(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        ManastormMobilityClient::SyncAuras(player);
        ManastormMgr::Instance().SyncManastormPotionCharges(player);
    }

    bool OnPlayerCanRepopAtGraveyard(Player* player) override
    {
        if (ManastormModuleConfig::Enabled() &&
            ManastormMgr::Instance().HandleReleaseAfterWipe(player))
            return false;

        return true;
    }

    void OnPlayerSendSpellChargeStates(Player const* player) override
    {
        ManastormMgr::Instance().SyncManastormPotionCharges(player);
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

    bool OnPlayerPassedQuestKilledMonsterCredit(
        Player* player,
        Quest const* /*quest*/,
        uint32 /*entry*/,
        uint32 /*realEntry*/,
        ObjectGuid /*guid*/) override
    {
        if (!ManastormModuleConfig::Enabled() ||
            !player)
        {
            return true;
        }

        ManastormRun const* run =
            ManastormMgr::Instance()
                .GetRunFor(player);

        if (!run)
            return true;

        bool const currentStage =
            player->GetMapId() ==
                run->GetSegment().MapId &&
            player->GetInstanceId() ==
                run->GetInstanceId();

        bool const previousStage =
            run->HasPreviousStage() &&
            player->GetMapId() ==
                run->GetPreviousSegment().MapId &&
            player->GetInstanceId() ==
                run->GetPreviousInstanceId();

        return !(currentStage ||
            previousStage);
    }

    bool OnPlayerBeforeCriteriaProgress(
        Player* player,
        AchievementCriteriaEntry const* criteria) override
    {
        if (!ManastormModuleConfig::Enabled() ||
            !player ||
            !criteria ||
            criteria->requiredType !=
                ACHIEVEMENT_CRITERIA_TYPE_KILL_CREATURE)
        {
            return true;
        }

        ManastormRun const* run =
            ManastormMgr::Instance()
                .GetRunFor(player);

        if (!run)
            return true;

        bool const currentStage =
            player->GetMapId() ==
                run->GetSegment().MapId &&
            player->GetInstanceId() ==
                run->GetInstanceId();

        bool const previousStage =
            run->HasPreviousStage() &&
            player->GetMapId() ==
                run->GetPreviousSegment().MapId &&
            player->GetInstanceId() ==
                run->GetPreviousInstanceId();

        return !(currentStage ||
            previousStage);
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

class manastorm_affix_spell_guard : public AllSpellScript
{
public:
    manastorm_affix_spell_guard()
        : AllSpellScript(
            "manastorm_affix_spell_guard",
            {ALLSPELLHOOK_ON_SPELL_CHECK_CAST})
    {
    }

    void OnSpellCheckCast(
        Spell* spell,
        bool /*strict*/,
        SpellCastResult& result) override
    {
        if (!ManastormModuleConfig::Enabled() ||
            result != SPELL_CAST_OK ||
            !spell ||
            !spell->GetCaster() ||
            spell->GetSpellInfo()->Id != 93378)
        {
            return;
        }

        Creature* caster =
            spell->GetCaster()->ToCreature();

        if (!caster ||
            !caster->HasAura(93377))
        {
            return;
        }

        // Recovered Fungal gate:
        //
        // 93378 also applies 293370 "Fungal Eruption" (enabled window).
        // At its terminal tick 293370 applies 293371, the disabled window.
        // Without the original server gate, 93377's one-second periodic
        // trigger refreshes 293370 forever and summons a mushroom every
        // second. Suppress the summon while either gate marker is active.
        if (caster->HasAura(293370) ||
            caster->HasAura(293371))
        {
            result =
                SPELL_FAILED_DONT_REPORT;
        }
    }
};

class manastorm_gadget_spells : public AllSpellScript
{
public:
    manastorm_gadget_spells()
        : AllSpellScript(
            "manastorm_gadget_spells",
            {ALLSPELLHOOK_ON_SPELL_CHECK_CAST})
    {
    }

    void OnSpellCheckCast(
        Spell* spell,
        bool /*strict*/,
        SpellCastResult& result) override
    {
        if (!ManastormModuleConfig::Enabled() ||
            !spell ||
            !spell->GetCaster())
        {
            return;
        }

        Player* player =
            spell->GetCaster()->ToPlayer();

        if (!player)
            return;

        if (spell->GetSpellInfo()->Id ==
            ManastormBaseline::SpellPotionChargeSystem)
        {
            if (!ManastormMgr::Instance()
                    .IsPlayerInUsableEndlessStage(player))
            {
                result =
                    SPELL_FAILED_NOT_HERE;
            }

            return;
        }

        Ascension::Manastorm::Gadget const* gadget =
            nullptr;

        for (auto const& candidate :
            Ascension::Manastorm::Gadgets)
        {
            if (candidate.spell ==
                spell->GetSpellInfo()->Id)
            {
                gadget =
                    &candidate;

                break;
            }
        }

        if (!gadget ||
            gadget->passive)
        {
            return;
        }

        ManastormRun const* run =
            ManastormMgr::Instance()
                .GetRunFor(player);

        if (!run ||
            (run->GetState() !=
                ManastormRunState::Preparing &&
             run->GetState() !=
                ManastormRunState::Active &&
             run->GetState() !=
                ManastormRunState::StageComplete))
        {
            result =
                SPELL_FAILED_NOT_HERE;

            return;
        }

        if (player->GetMapId() !=
                run->GetSegment().MapId ||
            player->GetInstanceId() !=
                run->GetInstanceId())
        {
            result =
                SPELL_FAILED_NOT_HERE;

            return;
        }

        if (!run->IsGadgetEquipped(
                player->GetGUID()
                    .GetCounter(),
                gadget->spell))
        {
            result =
                SPELL_FAILED_NOT_READY;
        }
    }
};

class npc_manastorm_stage_portal : public CreatureScript
{
public:
    npc_manastorm_stage_portal()
        : CreatureScript(
            "npc_manastorm_stage_portal")
    {
    }

    bool OnGossipHello(
        Player* player,
        Creature* creature) override
    {
        //
        // 80910 is an invisible controller carrying the recovered 93305
        // Manastorm Portal Effect. A direct interaction advances the shared
        // run immediately; returning true suppresses an empty gossip window.
        //
        if (!ManastormModuleConfig::Enabled())
            return true;

        std::string error;

        if (!ManastormMgr::Instance()
            .UseStagePortal(
                player,
                creature,
                error))
        {
            if (player &&
                player->GetSession() &&
                !error.empty())
            {
                ChatHandler(
                    player->GetSession())
                    .PSendSysMessage(
                        "Manastorm: {}",
                        error);
            }
        }

        return true;
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
        ManastormMobilityClient::PrepareEntry(player);
        ManastormMgr::Instance().SyncManastormPotionCharges(player);
    }
};
}

void AddSC_manastorm()
{
    new manastorm_safety_spells();
    new manastorm_worldscript();
    new manastorm_creaturescript();
    new manastorm_unitscript();
    new manastorm_playerscript();
    new manastorm_affix_spell_guard();
    new manastorm_gadget_spells();
    new npc_manastorm_stage_portal();
    new manastorm_mapscript();

    RegisterSpellScript(spell_manastorm_baseline_tool);

    AddSC_manastorm_greedy_demon();
    AddSC_manastorm_reward_tools();
    AddSC_manastorm_commandscript();
}
