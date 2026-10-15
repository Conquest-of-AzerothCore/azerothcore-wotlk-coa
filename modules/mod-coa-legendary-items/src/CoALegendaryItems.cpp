#include "CoALegendaryCatalog.h"
#include "AscensionClientSpellPatches.h"
#include "DBCStores.h"
#include "GameTime.h"
#include "Config.h"
#include "Creature.h"
#include "Item.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <array>
#include <atomic>
#include <cmath>

namespace
{
    using namespace CoALegendary;

    char const* const PlayerStateKey = "CoALegendaryItems.Player";
    char const* const LootRollKey = "CoALegendaryItems.LootRoll";

    std::atomic<bool> enabled{ false };
    std::atomic<bool> dataReady{ false };
    std::atomic<float> dropChance{ 0.5f };
    std::atomic<uint32> stopDropLevel{ 60 };
    std::atomic<uint32> configVersion{ 0 };

    struct PlayerState : DataMap::Base
    {
        std::array<uint32, EQUIPMENT_SLOT_END> equippedEntries{};
        std::array<uint8, DesignCount> appliedLevels{};
        uint64 killExpiresAt = 0;
        uint32 configVersion = 0;
        bool refreshing = false;
    };

    struct LootRoll : DataMap::Base
    {
        bool attempted = false;
    };

    using EquippedLevels = std::array<uint8, DesignCount>;

    bool IsEnabled() { return enabled.load(); }

    flag96 SignatureMask(Design const& design)
    {
        flag96 mask;
        mask[design.signatureMaskBit / 32] = uint32(1) << (design.signatureMaskBit % 32);
        return mask;
    }

    uint32 KillPowerRemaining(PlayerState const& state)
    {
        uint64 const now = GameTime::GetGameTimeMS().count();
        return state.killExpiresAt > now ? uint32(state.killExpiresAt - now) : 0;
    }

    EquippedLevels GetEquippedLevels(Player* player, PlayerState const& state)
    {
        EquippedLevels levels{};
        if (!enabled.load() || !dataReady.load() || !player->IsAlive() || !IsCustomClass(player->getClass()))
            return levels;

        for (uint32 entry : state.equippedEntries)
            if (auto variant = DecodeEntry(entry))
                if (FitsClass(Catalog[variant->design], player->getClass()) &&
                    variant->requiredLevel <= player->GetLevel())
                    levels[variant->design] = std::max(levels[variant->design], uint8(variant->requiredLevel));
        return levels;
    }

    void ApplyPower(Player* player, uint32 designIndex, uint32 level, uint32 killRemaining)
    {
        Design const& design = Catalog[designIndex];
        int32 first = design.magnitude;
        int32 second = 0;
        int32 third = 0;
        if (design.power == Power::Offense)
        {
            first = AttackPowerBonus(level);
            second = first;
            if (design.profile == Profile::Caster)
                first = second = SpellPowerBonus(level);
            else if (design.profile == Profile::StrengthHybrid || design.profile == Profile::AgilityHybrid ||
                design.profile == Profile::IntellectHybrid)
                second = third = SpellPowerBonus(level);
        }
        uint32 const auraId = AuraEntryBase + designIndex;
        player->CastCustomSpell(player, auraId, &first, &second, &third, true);
        if (design.condition == CoALegendary::Condition::AfterKill)
            if (Aura* aura = player->GetAura(auraId, player->GetGUID()))
                aura->SetDuration(int32(killRemaining));
    }

    void RefreshPowers(Player* player, PlayerState& state)
    {
        if (state.refreshing || !player->IsInWorld())
            return;
        state.refreshing = true;
        state.configVersion = configVersion.load();
        EquippedLevels const levels = GetEquippedLevels(player, state);
        uint32 const killRemaining = KillPowerRemaining(state);
        for (uint32 index = 0; index < DesignCount; ++index)
        {
            Design const& design = Catalog[index];
            bool const active = levels[index] && ConditionActive(design.condition,
                player->GetHealthPct(), player->IsInCombat(), killRemaining);
            uint32 const auraId = AuraEntryBase + index;
            if (!active)
            {
                bool const remove = state.appliedLevels[index] != 0;
                state.appliedLevels[index] = 0;
                if (remove)
                    player->RemoveAurasDueToSpell(auraId, player->GetGUID());
                continue;
            }

            if (state.appliedLevels[index] != levels[index] || !player->HasAura(auraId, player->GetGUID()))
            {
                state.appliedLevels[index] = 0;
                player->RemoveAurasDueToSpell(auraId, player->GetGUID());
                ApplyPower(player, index, levels[index], killRemaining);
                state.appliedLevels[index] = player->HasAura(auraId, player->GetGUID()) ? levels[index] : 0;
            }
        }
        state.refreshing = false;
    }

    void RefreshPowers(Player* player)
    {
        if (PlayerState* state = player->CustomData.Get<PlayerState>(PlayerStateKey))
            RefreshPowers(player, *state);
    }

    void UpdateEquipmentSlot(Player* player, Item* item, uint8 slot, bool apply)
    {
        if (slot >= EQUIPMENT_SLOT_END || !player->IsInWorld())
            return;
        PlayerState* state = player->CustomData.Get<PlayerState>(PlayerStateKey);
        if (!state)
        {
            if (!IsCustomClass(player->getClass()) || !item || !DecodeEntry(item->GetEntry()))
                return;
            state = player->CustomData.GetDefault<PlayerState>(PlayerStateKey);
        }
        state->equippedEntries[slot] = apply && item && !item->IsBroken() ? item->GetEntry() : 0;
        RefreshPowers(player, *state);
    }

    class LegendaryMetadataScript final : public GlobalScript
    {
    public:
        LegendaryMetadataScript() : GlobalScript("coa_legendary_items_metadata",
            { GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR, GLOBALHOOK_ON_SPELL_MOD_FAMILY_MASK }) { }

        void OnLoadSpellCustomAttr(SpellInfo* info) override
        {
            if (info->Id >= AuraEntryBase && info->Id < AuraEntryBase + DesignCount)
                info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;

            for (Design const& design : Catalog)
                if (design.power == Power::Signature && info->SpellFamilyName == uint32(design.classId) + 6 &&
                    sSpellMgr->GetFirstSpellInChain(info->Id) == sSpellMgr->GetFirstSpellInChain(design.signatureSpell))
                {
                    flag96 const mask = SignatureMask(design);
                    Ascension::ClientSpellPatches::Instance().Register(info->Id,
                        { mask[0], mask[1], mask[2] }, IsEnabled);
                    break;
                }
        }
        void OnSpellModFamilyMask(SpellInfo const* affectSpell, SpellInfo const* checkSpell,
            SpellModifier const*, bool& affected) override
        {
            if (affectSpell->Id < AuraEntryBase || affectSpell->Id >= AuraEntryBase + DesignCount)
                return;
            Design const& design = Catalog[affectSpell->Id - AuraEntryBase];
            if (design.power != Power::Signature)
                return;
            affected = enabled.load() && dataReady.load() &&
                affectSpell->SpellFamilyName == checkSpell->SpellFamilyName &&
                sSpellMgr->GetFirstSpellInChain(design.signatureSpell) ==
                    sSpellMgr->GetFirstSpellInChain(checkSpell->Id);
        }
    };

    bool TryAddLegendary(Creature* creature, Player* owner, Loot* loot)
    {
        if (!owner || !enabled.load() || !dataReady.load() || !creature->GetLootMode() ||
            creature->IsLootRewardDisabled() || creature->GetOwnerGUID() || creature->GetCharmerGUID() ||
            loot->items.size() >= MAX_NR_LOOT_ITEMS)
            return false;

        uint32 const level = creature->getLevelForTarget(owner);
        if (!CanDrop(owner->getClass(), owner->GetLevel(), level, stopDropLevel.load(),
            owner->isHonorOrXPTarget(creature)) || !roll_chance_f(dropChance.load()))
            return false;

        std::array<uint32, 4> candidates{};
        uint32 count = 0;
        for (uint32 index = 0; index < DesignCount; ++index)
            if (FitsClass(Catalog[index], owner->getClass()))
                candidates[count++] = index;
        if (!count)
            return false;

        uint32 const entry = EntryForLevel(candidates[urand(0, count - 1)], level);
        loot->lootOwnerGUID = owner->GetGUID();
        std::size_t const before = loot->items.size();
        loot->AddItem(LootStoreItem(entry, 0, 100.0f, false, creature->GetLootMode(), 0, 1, 1));
        return loot->items.size() > before;
    }

    class LegendaryWorldScript final : public WorldScript
    {
    public:
        LegendaryWorldScript() : WorldScript("coa_legendary_items_world",
            { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP,
              WORLDHOOK_ON_BEFORE_FINALIZE_PLAYER_WORLD_SESSION }) { }

        void OnAfterConfigLoad(bool) override
        {
            enabled.store(sConfigMgr->GetOption<bool>("CoALegendaryItems.Enable", false));
            float const configuredChance = sConfigMgr->GetOption<float>("CoALegendaryItems.DropChance", 0.5f);
            dropChance.store(std::isfinite(configuredChance) ? std::clamp(configuredChance, 0.0f, 100.0f) : 0.0f);
            stopDropLevel.store(std::clamp(
                sConfigMgr->GetOption<uint32>("CoALegendaryItems.StopDropLevel", 60), 1u, MaximumCreatureLevel + 1));
            ++configVersion;
        }

        void OnBeforeFinalizePlayerWorldSession(uint32& cacheVersion) override
        {
            if (enabled.load() && dataReady.load())
                ++cacheVersion;
        }

        void OnStartup() override
        {
            uint32 invalid = 0;
            for (uint32 index = 0; index < DesignCount; ++index)
            {
                Design const& design = Catalog[index];
                for (uint32 level = 1; level <= MaximumCreatureLevel; ++level)
                {
                    ItemTemplate const* item = sObjectMgr->GetItemTemplate(EntryForLevel(index, level));
                    uint32 const tooltipId = TooltipForLevel(index, level);
                    if (!item || item->RequiredLevel != level || item->ItemLevel != ItemLevel(level) ||
                        item->Quality != ITEM_QUALITY_LEGENDARY || item->ItemSet ||
                        item->InventoryType != design.inventoryType || !item->Description.empty() ||
                        item->Spells[0].SpellId != int32(tooltipId) ||
                        item->Spells[0].SpellTrigger != ITEM_SPELLTRIGGER_ON_EQUIP)
                        ++invalid;
                    SpellInfo const* tooltip = sSpellMgr->GetSpellInfo(tooltipId);
                    if (!tooltip || std::any_of(tooltip->Effects.begin(), tooltip->Effects.end(),
                        [](SpellEffectInfo const& effect) { return effect.IsEffect(); }))
                        ++invalid;
                }
                if (!sSpellMgr->GetSpellInfo(AuraEntryBase + index))
                    ++invalid;
                if (design.power == Power::Signature && !sSpellMgr->GetSpellInfo(design.signatureSpell))
                    ++invalid;
            }
            for (SpellEntry const* entry : sSpellStore)
            {
                SpellInfo const* info = sSpellMgr->GetSpellInfo(entry->Id);
                if (!info || info->SpellFamilyName < 18 || info->SpellFamilyName > 38)
                    continue;
                bool const direct = std::any_of(info->Effects.begin(), info->Effects.end(),
                    [](SpellEffectInfo const& effect)
                    {
                        switch (effect.Effect)
                        {
                            case SPELL_EFFECT_SCHOOL_DAMAGE:
                            case SPELL_EFFECT_HEALTH_LEECH:
                            case SPELL_EFFECT_HEAL:
                            case SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL:
                            case SPELL_EFFECT_WEAPON_PERCENT_DAMAGE:
                            case SPELL_EFFECT_WEAPON_DAMAGE:
                            case SPELL_EFFECT_HEAL_MECHANICAL:
                            case SPELL_EFFECT_NORMALIZED_WEAPON_DMG:
                            case SPELL_EFFECT_HEAL_PCT:
                                return true;
                            default:
                                return false;
                        }
                    });
                if (info->Id >= AuraEntryBase && info->Id < AuraEntryBase + DesignCount)
                    continue;
                for (Design const& design : Catalog)
                {
                    if (design.power != Power::Signature || info->SpellFamilyName != uint32(design.classId) + 6)
                        continue;
                    flag96 const mask = SignatureMask(design);
                    if (direct && (info->SpellFamilyFlags & mask) &&
                        sSpellMgr->GetFirstSpellInChain(info->Id) !=
                            sSpellMgr->GetFirstSpellInChain(design.signatureSpell))
                    {
                        ++invalid;
                        LOG_ERROR("module", "CoA Legendary Items: signature selector {} also matches spell {}",
                            design.name, info->Id);
                    }
                    SpellInfo const* signature = sSpellMgr->GetSpellInfo(design.signatureSpell);
                    if (!signature)
                        continue;
                    flag96 const original = signature->SpellFamilyFlags;
                    for (SpellEffectInfo const& effect : info->Effects)
                        if (effect.IsEffect() && (effect.SpellClassMask & mask) && !(effect.SpellClassMask & original))
                        {
                            ++invalid;
                            LOG_ERROR("module", "CoA Legendary Items: signature selector {} overlaps modifier {}",
                                design.name, info->Id);
                        }
                }
            }
            dataReady.store(invalid == 0);
            if (invalid)
                LOG_ERROR("module", "CoA Legendary Items: {} missing or invalid records; apply the module world "
                    "migration. Drops and powers are disabled until the data is available.", invalid);
            else
                LOG_INFO("module", "CoA Legendary Items: {} designs, {} level variants; drop chance {}%, cutoff {}.",
                    DesignCount, DesignCount * MaximumCreatureLevel, dropChance.load(), stopDropLevel.load());
        }
    };

    class LegendaryLootScript final : public MiscScript
    {
    public:
        LegendaryLootScript() : MiscScript("coa_legendary_items_loot",
            { MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS }) { }

        void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const*, LootStore const& store,
            Player* owner, bool, bool, uint16) override
        {
            if (&store != &LootTemplates_Creature || !owner)
                return;
            Creature* creature = owner->GetMap()->GetCreature(loot->sourceWorldObjectGUID);
            if (!creature || !creature->IsAlive() || loot != &creature->loot)
                return;

            creature->CustomData.GetDefault<LootRoll>(LootRollKey)->attempted = true;
            TryAddLegendary(creature, owner, loot);
        }
    };

    class LegendaryPlayerScript final : public PlayerScript
    {
    public:
        LegendaryPlayerScript() : PlayerScript("coa_legendary_items_player",
            { PLAYERHOOK_ON_EQUIP, PLAYERHOOK_ON_AFTER_APPLY_ITEM_MODS, PLAYERHOOK_ON_LOGIN,
              PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_PLAYER_RESURRECT,
              PLAYERHOOK_ON_PLAYER_ENTER_COMBAT, PLAYERHOOK_ON_PLAYER_LEAVE_COMBAT, PLAYERHOOK_ON_UPDATE,
              PLAYERHOOK_CAN_APPLY_EQUIP_SPELL }) { }

        bool OnPlayerCanApplyEquipSpell(Player*, SpellInfo const* info, Item*, bool, bool) override
        {
            return info->Id < TooltipEntryBase ||
                !DecodeEntry(info->Id - TooltipEntryBase + ItemEntryBase);
        }

        void OnPlayerEquip(Player* player, Item* item, uint8 bag, uint8 slot, bool) override
        {
            if (bag == INVENTORY_SLOT_BAG_0)
                UpdateEquipmentSlot(player, item, slot, true);
        }

        void OnPlayerAfterApplyItemMods(Player* player, Item* item, uint8 slot, bool apply) override
        {
            UpdateEquipmentSlot(player, item, slot, apply);
        }

        void OnPlayerLogin(Player* player) override
        {
            if (!IsCustomClass(player->getClass()))
                return;
            PlayerState* state = player->CustomData.GetDefault<PlayerState>(PlayerStateKey);
            state->equippedEntries.fill(0);
            for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
                if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    if (!item->IsBroken())
                        state->equippedEntries[slot] = item->GetEntry();
            RefreshPowers(player, *state);
        }

        void OnPlayerLevelChanged(Player* player, uint8) override { RefreshPowers(player); }
        void OnPlayerResurrect(Player* player, float, bool&) override { RefreshPowers(player); }
        void OnPlayerEnterCombat(Player* player, Unit*) override { RefreshPowers(player); }
        void OnPlayerLeaveCombat(Player* player) override { RefreshPowers(player); }

        void OnPlayerUpdate(Player* player, uint32) override
        {
            if (PlayerState* state = player->CustomData.Get<PlayerState>(PlayerStateKey))
                if (state->configVersion != configVersion.load())
                    RefreshPowers(player, *state);
        }

        void OnPlayerLogout(Player* player) override
        {
            if (PlayerState* state = player->CustomData.Get<PlayerState>(PlayerStateKey))
            {
                state->equippedEntries.fill(0);
                state->killExpiresAt = 0;
                RefreshPowers(player, *state);
            }
            player->CustomData.Erase(PlayerStateKey);
        }
    };

    class LegendaryUnitScript final : public UnitScript
    {
    public:
        LegendaryUnitScript() : UnitScript("coa_legendary_items_unit", true,
            { UNITHOOK_ON_UNIT_DEATH, UNITHOOK_ON_HEALTH_CHANGED, UNITHOOK_ON_AURA_REMOVE }) { }

        void OnUnitDeath(Unit* unit, Unit* killer) override
        {
            Creature* creature = unit->ToCreature();
            if (!creature)
            {
                if (Player* player = unit->ToPlayer())
                {
                    if (PlayerState* state = player->CustomData.Get<PlayerState>(PlayerStateKey))
                        state->killExpiresAt = 0;
                    RefreshPowers(player);
                }
                return;
            }

            LootRoll* roll = creature->CustomData.Get<LootRoll>(LootRollKey);
            if ((!roll || !roll->attempted) && creature->GetLootRecipient() &&
                creature->IsDamageEnoughForLootingAndReward())
            {
                Player* owner = ObjectAccessor::FindPlayer(creature->loot.lootOwnerGUID);
                if (!owner)
                    owner = creature->GetLootRecipient();
                if (TryAddLegendary(creature, owner, &creature->loot))
                {
                    creature->loot.FillNotNormalLootFor(owner);
                    creature->RemoveUnitFlag(UNIT_FLAG_SKINNABLE);
                    creature->SetCorpseRemoveTime(creature->GetCorpseDelay());
                    creature->SetDynamicFlag(UNIT_DYNFLAG_LOOTABLE);
                }
            }
            creature->CustomData.Erase(LootRollKey);

            Player* player = killer ? killer->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
            if (player && enabled.load() && dataReady.load() && IsCustomClass(player->getClass()) &&
                player->isHonorOrXPTarget(creature) && creature->GetLootRecipient() &&
                !creature->GetOwnerGUID() && !creature->GetCharmerGUID())
            {
                PlayerState* state = player->CustomData.GetDefault<PlayerState>(PlayerStateKey);
                state->killExpiresAt = GameTime::GetGameTimeMS().count() + KillPowerDurationMs;
                RefreshPowers(player, *state);
                for (uint32 index = 0; index < DesignCount; ++index)
                    if (Catalog[index].condition == CoALegendary::Condition::AfterKill && state->appliedLevels[index])
                        if (Aura* aura = player->GetAura(AuraEntryBase + index, player->GetGUID()))
                            aura->SetDuration(int32(KillPowerRemaining(*state)));
            }
        }

        void OnHealthChanged(Unit* unit) override
        {
            if (Player* player = unit->ToPlayer())
                RefreshPowers(player);
        }

        void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
        {
            Player* player = unit->ToPlayer();
            uint32 const id = application->GetBase()->GetId();
            if (player && id >= AuraEntryBase && id < AuraEntryBase + DesignCount &&
                application->GetBase()->GetCasterGUID() == player->GetGUID())
                if (PlayerState* state = player->CustomData.Get<PlayerState>(PlayerStateKey))
                    state->appliedLevels[id - AuraEntryBase] = 0;
        }

    };
}

void AddSC_coa_legendary_items()
{
    if (!sConfigMgr->GetOption<bool>("CoALegendaryItems.Enable", false))
        return;
    enabled.store(true);
    for (uint32 index = 0; index < DesignCount; ++index)
    {
        Ascension::ClientSpellPatches::Instance().Register(AuraEntryBase + index, {}, IsEnabled);
        for (uint32 level = 1; level <= MaximumCreatureLevel; ++level)
        {
            Ascension::ClientItemPatches::Instance().Register(EntryForLevel(index, level), {}, IsEnabled);
            Ascension::ClientSpellPatches::Instance().Register(TooltipForLevel(index, level), {}, IsEnabled,
                Ascension::ClientSpellPatches::Delivery::Item);
        }
    }
    new LegendaryMetadataScript();
    new LegendaryWorldScript();
    new LegendaryLootScript();
    new LegendaryPlayerScript();
    new LegendaryUnitScript();
}
