/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBattlegroundBrackets.h"
#include "AscensionBattlegroundBracketsPolicy.h"
#include "AscensionBattlegroundCatchUp.h"
#include "AscensionBattlegroundCombat.h"
#include "AscensionItemLadder.h"
#include "AscensionNativeItemScaling.h"
#include "Battleground.h"
#include "Config.h"
#include "DataMap.h"
#include "Item.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include <algorithm>
#include <limits>

namespace
{
namespace Policy = AscensionBattlegroundBracketsPolicy;

constexpr char LiftKey[] = "AscensionBattlegroundCatchUp.Lift";
uint32 MaxLiftLevels = 0;
bool GearCatchUpEnabled = true;
float GearCatchUpScale = 1.0f;

struct AppliedLift final : DataMap::Base
{
    Policy::Lift lift;
    float ratio = 1.0f;
};

void ApplyModifierDelta(Unit* unit, UnitMods mod, float delta)
{
    if (delta > 0.0f)
        unit->HandleStatFlatModifier(mod, BASE_VALUE, delta, true);
    else if (delta < 0.0f)
        unit->HandleStatFlatModifier(mod, BASE_VALUE, -delta, false);
}

void ApplyArmorLiftDelta(Unit* unit, float oldArmor, float newArmor)
{
    unit->SetBattlegroundArmorLift(newArmor);
    ApplyModifierDelta(unit, UNIT_MOD_ARMOR, newArmor - oldArmor);
}

void DropLift(Unit* unit)
{
    AppliedLift const* applied = unit->CustomData.Get<AppliedLift>(LiftKey);
    if (!applied)
        return;

    Policy::Lift const lift = applied->lift;
    unit->CustomData.Erase(LiftKey);
    unit->SetBattlegroundOutputRatio(1.0f);
    ApplyModifierDelta(unit, UNIT_MOD_HEALTH, -lift.health);
    ApplyArmorLiftDelta(unit, lift.armor, 0.0f);
}

void RemoveLift(Unit* unit)
{
    if (!unit->CustomData.Get<AppliedLift>(LiftKey))
        return;

    uint32 const health = unit->GetHealth();
    uint32 const oldMax = unit->GetMaxHealth();
    DropLift(unit);
    unit->SetHealth(Policy::KeptHealth(health, oldMax, unit->GetMaxHealth()));
}

void ApplyLift(Unit* unit, Policy::Lift const& lift, float ratio, bool preserveHealthPct = true)
{
    if (lift.Empty())
    {
        if (preserveHealthPct)
        {
            RemoveLift(unit);
            return;
        }
        if (!unit->CustomData.Get<AppliedLift>(LiftKey))
            return;
        uint32 const health = unit->GetHealth();
        DropLift(unit);
        uint32 const clamped = std::min(health, unit->GetMaxHealth());
        if (unit->GetHealth() != clamped)
            unit->SetHealth(clamped);
        return;
    }

    AppliedLift* existing = unit->CustomData.Get<AppliedLift>(LiftKey);
    if (existing && existing->lift.health == lift.health && existing->lift.armor == lift.armor &&
        existing->ratio == ratio)
        return;

    Policy::Lift const oldLift = existing ? existing->lift : Policy::Lift{};
    uint32 const health = unit->GetHealth();
    uint32 const oldMax = unit->GetMaxHealth();
    if (!existing)
    {
        existing = new AppliedLift();
        unit->CustomData.Set(LiftKey, existing);
    }
    existing->lift = lift;
    existing->ratio = ratio;
    unit->SetBattlegroundOutputRatio(ratio);
    ApplyModifierDelta(unit, UNIT_MOD_HEALTH, lift.health - oldLift.health);
    ApplyArmorLiftDelta(unit, oldLift.armor, lift.armor);

    uint32 const targetHealth = preserveHealthPct ? Policy::KeptHealth(health, oldMax, unit->GetMaxHealth())
        : std::min(health, unit->GetMaxHealth());
    if (unit->GetHealth() != targetHealth)
        unit->SetHealth(targetHealth);
}

uint32 LiftTargetLevel(Player const* player)
{
    Map const* map = player->FindMap();
    if (!map || !map->IsBattleground())
        return 0;

    Battleground const* battleground = player->GetBattleground();
    if (!battleground || battleground->isArena() || battleground->GetMapId() != map->GetId())
        return 0;

    return AscensionBattlegroundBrackets::WidenedMaxLevel(battleground->GetMapId(), battleground->GetBracketId());
}

Policy::LevelValues PlayerLevelValues(Player const* player, uint8 level)
{
    PlayerClassLevelInfo classInfo;
    sObjectMgr->GetPlayerClassLevelInfo(player->getClass(), level, &classInfo);

    PlayerLevelInfo levelInfo;
    sObjectMgr->GetPlayerLevelInfo(player->getRace(true), player->getClass(), level, &levelInfo);

    Policy::LevelValues values{ classInfo.basehealth, classInfo.basemana, {} };
    for (uint8 stat = STAT_STRENGTH; stat < MAX_STATS; ++stat)
        values.stats[stat] = levelInfo.stats[stat];
    return values;
}

Policy::ArmorTier PlayerArmorTier(Player const* player, uint8 level)
{
    Policy::ArmorTier tier = Policy::ArmorTier::Cloth;
    if (player->HasSkill(SKILL_PLATE_MAIL))
        tier = Policy::ArmorTier::Plate;
    else if (player->HasSkill(SKILL_MAIL))
        tier = Policy::ArmorTier::Mail;
    else if (player->HasSkill(SKILL_LEATHER))
        tier = Policy::ArmorTier::Leather;

    if (level >= 40)
    {
        uint8 const playerClass = player->getClass();
        if (playerClass == CLASS_WARRIOR || playerClass == CLASS_PALADIN)
            tier = Policy::ArmorTier::Plate;
        else if ((playerClass == CLASS_HUNTER || playerClass == CLASS_SHAMAN) && tier < Policy::ArmorTier::Mail)
            tier = Policy::ArmorTier::Mail;
    }
    return tier;
}

bool PlayerUsesRebornArmor(Player const* player)
{
    return NativeItemScaling::RebornArmorActive() && ItemLadder::WearsRebornArmor(player->getClass());
}

Policy::GearValues PlayerGearValues(Player const* player, bool removingOffhand = false)
{
    Policy::GearValues gear;
    gear.health = float(player->GetEquippedGearHealth());
    float const armor = player->GetItemArmorBySubclass(ITEM_SUBCLASS_ARMOR_CLOTH) +
        player->GetItemArmorBySubclass(ITEM_SUBCLASS_ARMOR_LEATHER) +
        player->GetItemArmorBySubclass(ITEM_SUBCLASS_ARMOR_MAIL) +
        player->GetItemArmorBySubclass(ITEM_SUBCLASS_ARMOR_PLATE) +
        float(player->GetEquippedGearBonusArmor());
    gear.armor = std::max(0.0f, armor);
    gear.shieldArmor = std::max(0.0f, player->GetItemArmorBySubclass(ITEM_SUBCLASS_ARMOR_SHIELD));
    if (!removingOffhand)
        if (Item const* offhand = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND))
            if (!offhand->IsBroken())
                if (ItemTemplate const* proto = offhand->GetTemplate())
                    gear.hasShield =
                        proto->Class == ITEM_CLASS_ARMOR && proto->SubClass == ITEM_SUBCLASS_ARMOR_SHIELD;
    return gear;
}

void RefreshPlayerLift(Player* player, bool preserveHealthPct = true, bool removingOffhand = false)
{
    uint8 const level = player->GetLevel();
    uint32 const target = Policy::CappedLiftLevel(level, LiftTargetLevel(player), MaxLiftLevels);
    if (target <= level)
    {
        ApplyLift(player, {}, 1.0f, preserveHealthPct);
        return;
    }

    Policy::LevelValues const own = PlayerLevelValues(player, level);
    Policy::LevelValues const lifted = PlayerLevelValues(player, uint8(target));
    Policy::Lift lift = Policy::PlayerLiftBetween(own, lifted);
    if (GearCatchUpEnabled && GearCatchUpScale > 0.0f)
    {
        Policy::Lift const gear = Policy::PlayerGearLift(level, target, PlayerArmorTier(player, level),
            PlayerArmorTier(player, uint8(target)), PlayerUsesRebornArmor(player),
            PlayerGearValues(player, removingOffhand), GearCatchUpScale);
        lift.health += gear.health;
        lift.armor += gear.armor;
    }
    ApplyLift(player, lift,
        Policy::OutputRatio(Policy::PlayerOutputHealth(own), Policy::PlayerOutputHealth(lifted)), preserveHealthPct);
}

Policy::LevelValues PetLevelValues(PetLevelInfo const& info, bool hasMana)
{
    Policy::LevelValues values{ info.health, hasMana ? info.mana : 0, {} };
    for (uint8 stat = STAT_STRENGTH; stat < MAX_STATS; ++stat)
        values.stats[stat] = info.stats[stat];
    return values;
}

void RefreshPetLift(Pet* pet)
{
    PetType const type = pet->getPetType();
    Player const* owner = pet->GetOwner();
    bool const combatPet = type == HUNTER_PET || type == SUMMON_PET;
    uint8 const level = pet->GetLevel();
    uint32 const target =
        owner && combatPet ? Policy::CappedLiftLevel(level, LiftTargetLevel(owner), MaxLiftLevels) : 0;
    bool const hunterStats = pet->IsHunterPet();
    uint32 const statsCreatureId = hunterStats ? 1 : pet->GetEntry();
    PetLevelInfo const* own = target > level ? sObjectMgr->GetPetLevelInfo(statsCreatureId, level) : nullptr;
    PetLevelInfo const* top = own ? sObjectMgr->GetPetLevelInfo(statsCreatureId, uint8(target)) : nullptr;
    if (!top)
    {
        RemoveLift(pet);
        return;
    }

    ApplyLift(pet, Policy::LiftBetween(PetLevelValues(*own, !hunterStats), PetLevelValues(*top, !hunterStats)),
        Policy::OutputRatio(static_cast<float>(own->health), static_cast<float>(top->health)));
}

void RefreshOwnerLifts(Player* player)
{
    RefreshPlayerLift(player);
    if (Pet* pet = player->GetPet())
        RefreshPetLift(pet);
}

void RemoveOwnerLifts(Player* player)
{
    RemoveLift(player);
    if (Pet* pet = player->GetPet())
        RemoveLift(pet);
}

uint8 BattlegroundCatchUpSkipForSpell(uint32 spellId)
{
    switch (spellId)
    {
        case 12654:
        case 12723:
        case 20625:
        case 22482:
        case 25373:
        case 25997:
        case 29142:
        case 29879:
        case 33619:
        case 35139:
        case 38441:
        case 42393:
        case 45284:
        case 45297:
        case 47496:
        case 49882:
        case 50526:
        case 50536:
        case 51460:
        case 55269:
        case 56578:
        case 56698:
        case 59102:
        case 60532:
        case 61840:
        case 62379:
        case 63468:
        case 64930:
        case 66316:
        case 67100:
        case 67101:
        case 67102:
        case 69034:
        case 69189:
        case 70890:
        case 71023:
        case 71824:
        case 71879:
        case 272355:
        case 277083:
        case 277787:
        case 277820:
        case 278563:
        case 278564:
        case 278662:
        case 280221:
        case 280376:
        case 281051:
        case 300870:
        case 504606:
        case 524091:
        case 525028:
        case 561318:
        case 570050:
        case 570182:
        case 572837:
        case 573242:
        case 574166:
        case 575831:
        case 578346:
        case 583921:
        case 680204:
        case 680532:
        case 680681:
        case 681109:
        case 681308:
        case 681404:
        case 681459:
        case 704974:
        case 705124:
        case 705380:
        case 705425:
        case 705644:
        case 705798:
        case 705929:
        case 706808:
        case 706898:
        case 707469:
        case 707575:
        case 707660:
        case 707708:
        case 707720:
        case 707759:
        case 782754:
        case 782801:
        case 783054:
        case 801129:
        case 801241:
        case 801456:
        case 802608:
        case 802620:
        case 802850:
        case 803287:
        case 803467:
        case 803706:
        case 804934:
        case 805748:
        case 805979:
        case 806112:
        case 806946:
        case 807262:
        case 807347:
        case 807651:
        case 807672:
        case 986053:
        case 1180001:
        case 1180392:
        case 1181271:
        case 1556016:
        case 1571152:
            return BG_CATCH_UP_SKIP_DAMAGE;
        case 15290:
        case 20267:
        case 22845:
        case 23493:
        case 23880:
        case 24379:
        case 26170:
        case 27813:
        case 27817:
        case 27818:
        case 30294:
        case 31616:
        case 34299:
        case 37382:
        case 39373:
        case 45470:
        case 48153:
        case 48210:
        case 48503:
        case 48743:
        case 48843:
        case 48844:
        case 50181:
        case 50454:
        case 50475:
        case 52724:
        case 52752:
        case 54172:
        case 54181:
        case 54203:
        case 54755:
        case 54968:
        case 55533:
        case 56131:
        case 56160:
        case 56161:
        case 58879:
        case 59913:
        case 63106:
        case 64891:
        case 66235:
        case 66922:
        case 67535:
        case 69190:
        case 70677:
        case 70691:
        case 70772:
        case 70809:
        case 98900:
        case 275981:
        case 276986:
        case 280366:
        case 282095:
        case 289262:
        case 301004:
        case 301307:
        case 500522:
        case 500534:
        case 504306:
        case 504565:
        case 504830:
        case 520419:
        case 520793:
        case 520880:
        case 521643:
        case 523526:
        case 524675:
        case 524703:
        case 524972:
        case 560355:
        case 560627:
        case 560747:
        case 560839:
        case 561095:
        case 561308:
        case 570156:
        case 570185:
        case 572374:
        case 572786:
        case 574335:
        case 574337:
        case 653241:
        case 680374:
        case 681032:
        case 681206:
        case 681270:
        case 681463:
        case 706654:
        case 706753:
        case 707302:
        case 707449:
        case 712356:
        case 712433:
        case 712453:
        case 712482:
        case 800179:
        case 802271:
        case 802399:
        case 803331:
        case 804736:
        case 805187:
        case 806073:
        case 807170:
        case 807414:
        case 807420:
        case 807545:
        case 807561:
        case 807652:
        case 807857:
        case 807934:
        case 807942:
        case 810040:
        case 954269:
        case 954283:
        case 1571402:
        case 1581957:
        case 1582343:
        case 1584444:
            return BG_CATCH_UP_SKIP_HEAL;
        case 26470:
        case 47753:
        case 48707:
        case 64413:
        case 70845:
        case 288805:
        case 547574:
        case 560374:
        case 653283:
        case 704277:
        case 706759:
        case 805422:
        case 805718:
            return BG_CATCH_UP_SKIP_ABSORB;
        default:
            return BG_CATCH_UP_SKIP_NONE;
    }
}

class ascension_battleground_catch_up_spell_attr : public GlobalScript
{
public:
    ascension_battleground_catch_up_spell_attr()
        : GlobalScript("ascension_battleground_catch_up_spell_attr", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* spellInfo) override
    {
        if (!spellInfo)
            return;

        if (uint8 const skip = BattlegroundCatchUpSkipForSpell(spellInfo->Id))
            spellInfo->AscensionBattlegroundCatchUpSkip |= skip;
    }
};

class ascension_battleground_wide_brackets_config : public WorldScript
{
public:
    ascension_battleground_wide_brackets_config()
        : WorldScript("ascension_battleground_wide_brackets_config", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            return;

        AscensionBattlegroundBrackets::Configure(
            sConfigMgr->GetOption<bool>("CoA.Battleground.WideBrackets.Enable", true),
            sConfigMgr->GetOption<std::string>("CoA.Battleground.WideBrackets.Ranges", "10-29,30-49,50-59"));
        MaxLiftLevels = uint32(std::max<int32>(
            sConfigMgr->GetOption<int32>("CoA.Battleground.WideBrackets.MaxLiftLevels", 0), 0));
        GearCatchUpEnabled = sConfigMgr->GetOption<bool>("CoA.Battleground.WideBrackets.GearCatchUp.Enable", true);
        GearCatchUpScale = std::max(
            sConfigMgr->GetOption<float>("CoA.Battleground.WideBrackets.GearCatchUp.Scale", 1.0f), 0.0f);
    }
};

class ascension_battleground_catch_up_battleground : public AllBattlegroundScript
{
public:
    ascension_battleground_catch_up_battleground()
        : AllBattlegroundScript("ascension_battleground_catch_up_battleground",
            {ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_ADD_PLAYER,
                ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_REMOVE_PLAYER_AT_LEAVE})
    { }

    void OnBattlegroundAddPlayer(Battleground*, Player* player) override
    {
        RefreshOwnerLifts(player);
    }

    void OnBattlegroundRemovePlayerAtLeave(Battleground*, Player* player) override
    {
        RemoveOwnerLifts(player);
    }
};

class ascension_battleground_catch_up_player : public PlayerScript
{
public:
    ascension_battleground_catch_up_player()
        : PlayerScript("ascension_battleground_catch_up_player",
            {PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_MAP_CHANGED, PLAYERHOOK_ON_LOGOUT,
                PLAYERHOOK_ON_AFTER_APPLY_ITEM_MODS, PLAYERHOOK_ON_AFTER_APPLY_ENCHANTMENT})
    { }

    void OnPlayerLevelChanged(Player* player, uint8) override
    {
        if (player->CustomData.Get<AppliedLift>(LiftKey))
            RefreshPlayerLift(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        RefreshOwnerLifts(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        RemoveOwnerLifts(player);
    }

    void OnPlayerAfterApplyItemMods(Player* player, Item*, uint8 slot, bool apply) override
    {
        if (player->CustomData.Get<AppliedLift>(LiftKey))
            RefreshPlayerLift(player, false, !apply && slot == EQUIPMENT_SLOT_OFFHAND);
    }

    void OnPlayerAfterApplyEnchantment(Player* player, Item*, EnchantmentSlot, bool) override
    {
        if (player->CustomData.Get<AppliedLift>(LiftKey))
            RefreshPlayerLift(player, false);
    }
};

class ascension_battleground_catch_up_pet : public PetScript
{
public:
    ascension_battleground_catch_up_pet()
        : PetScript("ascension_battleground_catch_up_pet",
            {PETHOOK_ON_INIT_STATS_FOR_LEVEL, PETHOOK_ON_PET_ADD_TO_WORLD})
    { }

    void OnInitStatsForLevel(Guardian* guardian, uint8) override
    {
        Pet* pet = guardian->ToPet();
        if (!pet)
            return;

        pet->CustomData.Erase(LiftKey);
        pet->SetBattlegroundOutputRatio(1.0f);
        pet->SetBattlegroundArmorLift(0.0f);
        if (pet->IsInWorld())
            RefreshPetLift(pet);
    }

    void OnPetAddToWorld(Pet* pet) override
    {
        RefreshPetLift(pet);
    }
};

int32 ScaledSigned(Unit const* source, Unit const* target, int32 amount, SpellInfo const* spell, bool healing,
    bool absorb = false)
{
    if (amount <= 0)
        return amount;

    uint32 const scaled = AscensionBattlegroundCombat::ScaledOutput(source, target, uint32(amount), spell, healing,
        absorb);
    return int32(std::min<uint32>(scaled, uint32(std::numeric_limits<int32>::max())));
}

class ascension_battleground_catch_up_output : public UnitScript
{
public:
    ascension_battleground_catch_up_output()
        : UnitScript("ascension_battleground_catch_up_output", true,
            {UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_MELEE_DAMAGE,
                UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_BEFORE_HEAL_ABSORB,
                UNITHOOK_ON_AFTER_AURA_EFFECT_CALCULATE_AMOUNT})
    { }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& amount, SpellInfo const* spell) override
    {
        amount = ScaledSigned(attacker, target, amount, spell, false);
    }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& amount) override
    {
        amount = AscensionBattlegroundCombat::ScaledOutput(attacker, target, amount, nullptr, false);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& amount, SpellInfo const* spell) override
    {
        amount = AscensionBattlegroundCombat::ScaledOutput(attacker, target, amount, spell, false);
    }

    void OnBeforeHealAbsorb(HealInfo& healInfo) override
    {
        healInfo.SetHeal(AscensionBattlegroundCombat::ScaledOutput(healInfo.GetHealer(), healInfo.GetTarget(),
            healInfo.GetHeal(), healInfo.GetSpellInfo(), true));
    }

    void OnAfterAuraEffectCalculateAmount(AuraEffect const* effect, Unit* caster, int32& amount) override
    {
        AuraType const type = effect->GetAuraType();
        if (type != SPELL_AURA_SCHOOL_ABSORB && type != SPELL_AURA_MANA_SHIELD)
            return;

        WorldObject* const owner = effect->GetBase()->GetOwner();
        amount = ScaledSigned(caster, owner ? owner->ToUnit() : nullptr, amount, effect->GetSpellInfo(), true, true);
    }
};
}

namespace AscensionBattlegroundCatchUp
{
float OutputRatio(Unit const* unit)
{
    return AscensionBattlegroundCombat::OutputRatio(unit);
}

uint32 ScaledOutput(Unit const* source, Unit const* target, uint32 amount, SpellInfo const* spell, bool healing,
    bool absorb)
{
    return AscensionBattlegroundCombat::ScaledOutput(source, target, amount, spell, healing, absorb);
}

float UnscaledFactor(Unit const* source, Unit const* target, SpellInfo const* spell, bool healing, bool absorb)
{
    return AscensionBattlegroundCombat::UnscaledFactor(source, target, spell, healing, absorb);
}
}

void AddSC_AscensionBattlegroundCatchUp()
{
    new ascension_battleground_catch_up_spell_attr();
    new ascension_battleground_catch_up_output();
    new ascension_battleground_wide_brackets_config();
    new ascension_battleground_catch_up_battleground();
    new ascension_battleground_catch_up_player();
    new ascension_battleground_catch_up_pet();
}
