/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AllSpellScript.h"
#include "CellImpl.h"
#include "Containers.h"
#include "CreatureScript.h"
#include "DBCStores.h"
#include "DynamicObject.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Group.h"
#include "Item.h"
#include "ObjectAccessor.h"
#include "Pet.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "UnitScript.h"
#include <algorithm>
#include <array>
#include <list>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
enum MysticMechanicsSpells : uint32
{
    SPELL_ABJURERS_WARD_ARCANE          = 1587962,
    SPELL_ABJURERS_WARD_FIRE            = 1587982,
    SPELL_HOLY_RADIANCE_HEAL            = 1571402,
    SPELL_ARMOR_OF_FAITH_HEAL           = 1582343,
    SPELL_PURGATION_HOLY_FIRE           = 1181271,
    SPELL_FRUGAL_DISPOSITION_HOT        = 1581957,
    SPELL_CONSECRATED_ZEAL_BUFF         = 1584024,
    SPELL_ELEMENTAL_EQUILIBRIUM_BUFF    = 1589160,
    SPELL_FIRE_ESSENCE                  = 1589162,
    SPELL_FROST_ESSENCE                 = 1589163,
    SPELL_NATURE_ESSENCE                = 1589164,
    SPELL_SHADOW_SIPHON                 = 1180660,
    SPELL_SHADOW_SIPHON_HEAL            = 1180661,
    SPELL_BIDING_TIME                   = 1584080,
    SPELL_IMPECCABLE_TIMING_BUFF        = 1584081,
    SPELL_BLADE_FLURRY                  = 1113877,
    SPELL_BLADE_VORTEX                  = 1589905,
    SPELL_ABJURERS_WARD_FROST           = 1588050,
    SPELL_RESURGENT_WAVES               = 1180560,
    SPELL_ECHOING_SHADOWS               = 1181250,
    SPELL_SHADOW_ORB                    = 1544913,
    SPELL_INFUSED_GEMS                  = 1585312,
    SPELL_SHADOW_OF_DEATH_BURST         = 1571152,
    SPELL_VIGILANCE                     = 1150720,
    SPELL_VANGUARD_CHARGE               = 1181454,
    SPELL_VANGUARD_ATTACK               = 1181453,
    SPELL_BLOOD_SOAKED_MUTILATION       = 1590974,
    SPELL_GARROTE_SILENCE_STOCK         = 1330,
    SPELL_PREDATORS_WRATH               = 1572260,
    SPELL_PREDATORS_SWIFTNESS_STOCK     = 69369,
    SPELL_WRATHFUL_STRIKES_READY        = 1572240,
    SPELL_WRATHFUL_STRIKES_STACK        = 1572261,
    SPELL_ICICLE                        = 1570530,
    SPELL_GUARDIANS_OF_THE_GROVE        = 1567585,
    SPELL_REJUVENATION_FIRST            = 1100774,
    SPELL_REGROWTH_FIRST                = 1108936,
    SPELL_GLYPH_OF_MENDING_IMAGES       = 1100163,
    SPELL_MINDSHIFT                     = 1122520,
    SPELL_MENDING_IMAGES_HEAL           = 1100169,
    SPELL_DRACONIC_KNOWLEDGE            = 1435693,
    SPELL_DRACONIC_KNOWLEDGE_CRIT       = 1445681,
    SPELL_DRACONIC_KNOWLEDGE_HASTE      = 1445684,
    SPELL_DRACONIC_KNOWLEDGE_SPELL_POWER = 1445686,
};

enum MysticMechanicsCreatures : uint32
{
    NPC_FORCE_OF_NATURE_TREANT          = 1101964,
    NPC_MIRROR_IMAGE                    = 1131216,
};

constexpr std::array<uint32, 2> PRESENCE_OF_MIND = { 1112043, 1212043 };
constexpr std::array<uint32, 2> COMBUSTION = { 1111129, 1211129 };
constexpr std::array<uint32, 2> COLD_SNAP = { 1111958, 1211958 };
constexpr uint32 SHAMAN_WATER_SHIELD_FLAG1 = 0x20;
constexpr uint32 PRIEST_MIND_BLAST_FLAG0 = 0x2000;
constexpr uint8 ECHOING_SHADOWS_ORBS = 3;
constexpr uint8 RESURGENT_WAVES_CHARGES = 2;
constexpr std::array<uint32, 3> IMPACT_BUFFS = { 64343, 1164343, 1264343 };
constexpr std::array<uint32, 2> SHADOWBURN_SHARD = { 29341, 1129341 };
constexpr std::array<uint32, 3> ESSENCES = { SPELL_FIRE_ESSENCE, SPELL_FROST_ESSENCE, SPELL_NATURE_ESSENCE };
constexpr uint32 PRIEST_RENEW_FLAG0 = 0x40;
constexpr uint32 MAGE_PYROBLAST_FLAG0 = 0x400000;
constexpr uint32 MAGE_IGNITE_FLAG0 = 0x8000000;
constexpr uint32 MAGE_LIVING_BOMB_FLAG1 = 0x30000;
constexpr uint32 MAGE_REPLENISH_MANA_FLAG1 = 0x100;
constexpr uint32 ROGUE_AMBUSH_FLAG0 = 0x200;
constexpr uint32 ROGUE_RUPTURE_FLAG0 = 0x100000;
constexpr uint32 WARRIOR_THUNDER_CLAP_FLAG0 = 0x80;
constexpr uint32 WARRIOR_SHOCKWAVE_FLAG1 = 0x8000;
constexpr int32 SHADOW_OF_DEATH_PVP_PCT = 20;
constexpr int32 THUNDERING_BLOW_CDR_MS = 1000;
constexpr int32 THUNDERING_BLOW_MAX_CDR_MS = 5000;
constexpr float VANGUARD_RANGE = 25.0f;
constexpr std::string_view FOCUSED_FIRE_NAME = "Focused Fire";
constexpr uint32 HUNTER_KILL_COMMAND_FLAG1 = 0x800;
constexpr uint32 ROGUE_GARROTE_FLAG0 = 0x100;
constexpr uint32 ROGUE_CRIMSON_TEMPEST_FLAG2 = 0x20000000;
constexpr int32 BLOOD_SOAKED_PCT_PER_COMBO = 20;
constexpr uint32 DRUID_WRATH_FLAG0 = 0x1;
constexpr uint32 MAGE_ICE_LANCE_FLAG0 = 0x20000;
constexpr std::array<uint32, 5> ICICLES = { 985142, 985140, 985138, 985156, 985158 };
constexpr float GUARDIANS_HEAL_BELOW_PCT = 90.0f;
constexpr float MINION_HEAL_RANGE = 40.0f;
constexpr Milliseconds MINION_BEHAVIOUR_INTERVAL = 2s;
constexpr Milliseconds MINION_FIRST_TICK = 500ms;
constexpr Milliseconds DRACONIC_KNOWLEDGE_REFRESH = 5s;
constexpr int32 HOLY_RADIANCE_PCT = 30;
constexpr uint32 ARMOR_OF_FAITH_ALLIES = 4;
constexpr float ARMOR_OF_FAITH_RADIUS = 15.0f;
constexpr float PURGATION_RADIUS = 8.0f;
constexpr uint32 PURGATION_TARGETS = 3;
constexpr float IMPACT_RADIUS = 12.0f;
constexpr float BLADE_VORTEX_PCT_PER_POINT = 20.0f;
constexpr int32 BLADE_VORTEX_COOLDOWN = -5000;

std::list<Unit*> FriendsNear(WorldObject* center, Unit* caster, float range)
{
    std::list<Unit*> units;
    Acore::AnyFriendlyUnitInObjectRangeCheck check(center, caster, range);
    Acore::UnitListSearcher<Acore::AnyFriendlyUnitInObjectRangeCheck> searcher(center, units, check);
    Cell::VisitObjects(center, searcher, range);
    return units;
}

std::list<Unit*> EnemiesNear(WorldObject* center, Unit* caster, float range)
{
    std::list<Unit*> units;
    Acore::AnyUnfriendlyUnitInObjectRangeCheck check(center, caster, range);
    Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(center, units, check);
    Cell::VisitObjects(center, searcher, range);
    units.remove_if([caster](Unit* unit) { return !caster->IsValidAttackTarget(unit); });
    return units;
}

class spell_ascension_mystic_abjurers_ward : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_abjurers_ward);

    template <std::size_t N>
    static void Cut(Player* player, uint32 enchant, std::array<uint32, N> const& spells)
    {
        if (AuraEffect const* effect = player->GetAuraEffect(enchant, EFFECT_0))
            for (uint32 spell : spells)
                if (player->HasSpellCooldown(spell))
                    player->ModifySpellCooldown(spell, effect->GetAmount());
    }

    void AfterAbsorb(AuraEffect*, DamageInfo&, uint32& absorbAmount)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !absorbAmount)
            return;
        Cut(player, SPELL_ABJURERS_WARD_ARCANE, PRESENCE_OF_MIND);
        Cut(player, SPELL_ABJURERS_WARD_FIRE, COMBUSTION);
        Cut(player, SPELL_ABJURERS_WARD_FROST, COLD_SNAP);
    }

    void Register() override
    {
        AfterEffectAbsorb += AuraEffectAbsorbFn(spell_ascension_mystic_abjurers_ward::AfterAbsorb, EFFECT_0);
    }
};

class spell_ascension_mystic_holy_radiance : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_holy_radiance);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        HealInfo const* heal = eventInfo.GetHealInfo();
        return heal && heal->GetHeal();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        int32 amount = CalculatePct(int32(eventInfo.GetHealInfo()->GetHeal()), HOLY_RADIANCE_PCT);
        if (amount <= 0)
            return;
        float const range = sSpellMgr->AssertSpellInfo(SPELL_HOLY_RADIANCE_HEAL)->GetMaxRange(true, caster);
        for (Unit* ally : FriendsNear(caster, caster, std::max(range, 40.0f)))
            if (ally->GetAuraEffect(SPELL_AURA_PERIODIC_HEAL, SPELLFAMILY_PRIEST, PRIEST_RENEW_FLAG0, 0, 0, caster->GetGUID()))
                caster->CastCustomSpell(ally, SPELL_HOLY_RADIANCE_HEAL, &amount, nullptr, nullptr, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_holy_radiance::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_holy_radiance::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_mystic_armor_of_faith : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_armor_of_faith);

    void AfterRemove(AuraEffect const* aurEff, AuraEffectHandleModes)
    {
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_DEATH)
            return;
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        int32 amount = aurEff->GetAmount();
        if (!caster || amount <= 0)
            return;
        caster->CastCustomSpell(target, SPELL_ARMOR_OF_FAITH_HEAL, &amount, nullptr, nullptr, true, nullptr, aurEff);
        std::list<Unit*> allies = FriendsNear(target, caster, ARMOR_OF_FAITH_RADIUS);
        allies.remove(target);
        allies.sort(Acore::ObjectDistanceOrderPred(target));
        allies.resize(std::min<std::size_t>(allies.size(), ARMOR_OF_FAITH_ALLIES));
        for (Unit* ally : allies)
            caster->CastCustomSpell(ally, SPELL_ARMOR_OF_FAITH_HEAL, &amount, nullptr, nullptr, true, nullptr, aurEff);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_mystic_armor_of_faith::AfterRemove, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_mystic_purgation_by_light : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_purgation_by_light);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && eventInfo.GetActionTarget() && eventInfo.GetSpellInfo() &&
            damage->GetDamageType() == SPELL_DIRECT_DAMAGE;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        int32 amount = CalculatePct(int32(eventInfo.GetDamageInfo()->GetDamage()), aurEff->GetAmount());
        std::list<Unit*> enemies = EnemiesNear(target, caster, PURGATION_RADIUS);
        enemies.remove(target);
        Acore::Containers::RandomResize(enemies, PURGATION_TARGETS);
        for (Unit* enemy : enemies)
        {
            if (amount > 0)
                caster->CastCustomSpell(enemy, SPELL_PURGATION_HOLY_FIRE, &amount, nullptr, nullptr, true, nullptr, aurEff);
            caster->AddAura(eventInfo.GetSpellInfo()->Id, enemy);
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_purgation_by_light::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_purgation_by_light::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_mystic_frugal_disposition : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_frugal_disposition);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        HealInfo const* heal = eventInfo.GetHealInfo();
        return heal && heal->GetHeal() > heal->GetEffectiveHeal() && eventInfo.GetActionTarget();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        HealInfo const* heal = eventInfo.GetHealInfo();
        SpellInfo const* hot = sSpellMgr->AssertSpellInfo(SPELL_FRUGAL_DISPOSITION_HOT);
        uint32 const amplitude = hot->Effects[EFFECT_0].Amplitude;
        uint32 const ticks = amplitude && hot->GetMaxDuration() > 0 ? std::max<uint32>(1, hot->GetMaxDuration() / amplitude) : 1;
        int32 amount = std::max<int32>(1, int32((heal->GetHeal() - heal->GetEffectiveHeal()) / 2 / ticks));
        GetTarget()->CastCustomSpell(eventInfo.GetActionTarget(), SPELL_FRUGAL_DISPOSITION_HOT, &amount, nullptr, nullptr, true,
            nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_frugal_disposition::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_frugal_disposition::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_mystic_consecrated_zeal : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_consecrated_zeal);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        DynamicObject* ground = spell ? GetTarget()->GetDynObject(spell->Id) : nullptr;
        return ground && GetTarget()->IsWithinDist(ground, ground->GetRadius());
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), SPELL_CONSECRATED_ZEAL_BUFF, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_consecrated_zeal::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_consecrated_zeal::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_mystic_glyph_of_impact : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_glyph_of_impact);

    bool CheckProc(ProcEventInfo&)
    {
        return std::any_of(IMPACT_BUFFS.begin(), IMPACT_BUFFS.end(), [this](uint32 buff) { return GetTarget()->HasAura(buff); });
    }

    static bool Spreads(Aura const* aura)
    {
        SpellInfo const* info = aura->GetSpellInfo();
        return info->SpellFamilyName == SPELLFAMILY_MAGE && info->HasAura(SPELL_AURA_PERIODIC_DAMAGE) &&
            ((info->SpellFamilyFlags[0] & (MAGE_PYROBLAST_FLAG0 | MAGE_IGNITE_FLAG0)) ||
             (info->SpellFamilyFlags[1] & MAGE_LIVING_BOMB_FLAG1));
    }

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Spell const* spell = eventInfo.GetProcSpell();
        Unit* target = spell ? spell->m_targets.GetUnitTarget() : nullptr;
        if (!target)
            return;
        std::vector<Aura const*> spread;
        for (auto const& [id, application] : target->GetAppliedAuras())
            if (application->GetBase()->GetCasterGUID() == caster->GetGUID() && Spreads(application->GetBase()))
                spread.push_back(application->GetBase());
        if (spread.empty())
            return;
        std::list<Unit*> enemies = EnemiesNear(target, caster, IMPACT_RADIUS);
        enemies.remove(target);
        for (Unit* enemy : enemies)
            for (Aura const* source : spread)
                if (Aura* copy = caster->AddAura(source->GetId(), enemy))
                {
                    for (uint8 effect = 0; effect < MAX_SPELL_EFFECTS; ++effect)
                        if (AuraEffect const* from = source->GetEffect(effect))
                            if (AuraEffect* to = copy->GetEffect(effect))
                                to->ChangeAmount(from->GetAmount());
                    copy->SetDuration(source->GetDuration());
                }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_glyph_of_impact::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_glyph_of_impact::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class AscensionMysticEnchantEquilibrium final : public UnitScript
{
public:
    AscensionMysticEnchantEquilibrium() : UnitScript("AscensionMysticEnchantEquilibrium", true, { UNITHOOK_ON_AURA_APPLY }) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (std::find(ESSENCES.begin(), ESSENCES.end(), aura->GetId()) == ESSENCES.end() ||
            !std::all_of(ESSENCES.begin(), ESSENCES.end(), [unit](uint32 essence) { return unit->HasAura(essence); }))
            return;
        for (uint32 essence : ESSENCES)
            unit->RemoveAurasDueToSpell(essence);
        unit->CastSpell(unit, SPELL_ELEMENTAL_EQUILIBRIUM_BUFF, true);
    }
};

class spell_ascension_mystic_blade_vortex : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_blade_vortex);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        Player* player = GetTarget()->ToPlayer();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!player || !spell || !spell->NeedsComboPoints() || spell->DmgClass != SPELL_DAMAGE_CLASS_MELEE || !damage ||
            !damage->GetDamage())
            return false;
        return roll_chance_f(BLADE_VORTEX_PCT_PER_POINT * player->GetComboPoints());
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        if (player->HasSpellCooldown(SPELL_BLADE_FLURRY))
            player->ModifySpellCooldown(SPELL_BLADE_FLURRY, BLADE_VORTEX_COOLDOWN);
        if (player->HasAura(SPELL_BLADE_FLURRY) && eventInfo.GetActionTarget())
            player->CastSpell(eventInfo.GetActionTarget(), SPELL_BLADE_VORTEX, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_blade_vortex::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_blade_vortex::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_mystic_impeccable_timing : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_impeccable_timing);

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        if (target->HasAura(SPELL_BIDING_TIME))
            return;
        target->CastSpell(target, SPELL_BIDING_TIME, true, nullptr, aurEff);
        target->CastSpell(target, SPELL_IMPECCABLE_TIMING_BUFF, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_ascension_mystic_impeccable_timing::HandlePeriodic, EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class AscensionMysticEnchantEchoingShadows final : public AllSpellScript
{
public:
    AscensionMysticEnchantEchoingShadows() : AllSpellScript("AscensionMysticEnchantEchoingShadows", { ALLSPELLHOOK_ON_CAST }) { }

    void OnSpellCast(Spell*, Unit* caster, SpellInfo const* spellInfo, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || !spellInfo || spellInfo->SpellFamilyName != SPELLFAMILY_PRIEST ||
            !(spellInfo->SpellFamilyFlags[0] & PRIEST_MIND_BLAST_FLAG0) || !player->HasAura(SPELL_ECHOING_SHADOWS))
            return;
        Aura const* orbs = player->GetAura(SPELL_SHADOW_ORB);
        if (!orbs || orbs->GetStackAmount() < ECHOING_SHADOWS_ORBS)
            return;
        uint32 const mindBlast = spellInfo->Id;
        ObjectGuid const guid = player->GetGUID();
        player->m_Events.AddEventAtOffset([guid, mindBlast]()
        {
            if (Player* owner = ObjectAccessor::FindPlayer(guid))
                owner->RemoveSpellCooldown(mindBlast, true);
        }, 1ms);
    }
};

class AscensionMysticEnchantResurgentWaves final : public UnitScript
{
public:
    AscensionMysticEnchantResurgentWaves() : UnitScript("AscensionMysticEnchantResurgentWaves", true, { UNITHOOK_ON_AURA_APPLY }) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        SpellInfo const* info = aura->GetSpellInfo();
        if (info->SpellFamilyName == SPELLFAMILY_SHAMAN && (info->SpellFamilyFlags[1] & SHAMAN_WATER_SHIELD_FLAG1) &&
            aura->GetCharges() && aura->GetCasterGUID() == unit->GetGUID() && unit->HasAura(SPELL_RESURGENT_WAVES))
            aura->SetCharges(aura->GetCharges() + RESURGENT_WAVES_CHARGES);
    }
};

class AscensionMysticEnchantShadowSiphon final : public UnitScript
{
public:
    AscensionMysticEnchantShadowSiphon() : UnitScript("AscensionMysticEnchantShadowSiphon", true, { UNITHOOK_ON_AURA_REMOVE }) { }

    void OnAuraRemove(Unit*, AuraApplication* application, AuraRemoveMode mode) override
    {
        Aura const* aura = application->GetBase();
        if (mode != AURA_REMOVE_BY_DEATH ||
            std::find(SHADOWBURN_SHARD.begin(), SHADOWBURN_SHARD.end(), aura->GetId()) == SHADOWBURN_SHARD.end())
            return;
        Unit* caster = aura->GetCaster();
        if (caster && caster->IsAlive() && caster->HasAura(SPELL_SHADOW_SIPHON))
            caster->CastSpell(caster, SPELL_SHADOW_SIPHON_HEAL, true);
    }
};

class AscensionMysticEnchantInfusedGems final : public PlayerScript
{
public:
    AscensionMysticEnchantInfusedGems() : PlayerScript("AscensionMysticEnchantInfusedGems",
        { PLAYERHOOK_CAN_CAST_ITEM_USE_SPELL }) { }

    bool OnPlayerCanCastItemUseSpell(Player* player, Item* item, SpellCastTargets const&, uint8,
        uint32) override
    {
        if (!player->HasAura(SPELL_INFUSED_GEMS))
            return true;
        ItemTemplate const* proto = item->GetTemplate();
        for (uint8 i = 0; i < MAX_ITEM_PROTO_SPELLS; ++i)
        {
            SpellInfo const* use = sSpellMgr->GetSpellInfo(proto->Spells[i].SpellId);
            if (use && proto->Spells[i].SpellCharges && use->SpellFamilyName == SPELLFAMILY_MAGE &&
                (use->SpellFamilyFlags[1] & MAGE_REPLENISH_MANA_FLAG1) &&
                item->GetSpellCharges(i) != proto->Spells[i].SpellCharges)
            {
                item->SetSpellCharges(i, proto->Spells[i].SpellCharges);
                item->SetState(ITEM_CHANGED, player);
            }
        }
        return true;
    }
};

class spell_ascension_mystic_shadow_of_death : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_shadow_of_death);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Unit* target = eventInfo.GetActionTarget();
        if (!spell || !damage || !damage->GetDamage() || !target || spell->SpellFamilyName != SPELLFAMILY_ROGUE ||
            !(spell->SpellFamilyFlags[0] & ROGUE_AMBUSH_FLAG0))
            return false;
        return target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_ROGUE, ROGUE_RUPTURE_FLAG0, 0, 0,
            GetTarget()->GetGUID()) != nullptr;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        int32 const pct = target->IsPlayer() ? SHADOW_OF_DEATH_PVP_PCT : aurEff->GetAmount();
        int32 const basePoints = std::max(1, int32(CalculatePct(eventInfo.GetDamageInfo()->GetDamage(), pct)));
        SpellCastTargets targets;
        targets.SetDst(*target);
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, basePoints);
        caster->CastSpell(targets, sSpellMgr->GetSpellInfo(SPELL_SHADOW_OF_DEATH_BURST), &values, TRIGGERED_FULL_MASK,
            nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_shadow_of_death::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_shadow_of_death::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_mystic_thundering_blow : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_thundering_blow);

    Spell const* _shockwave = nullptr;
    int32 _reduced = 0;

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Unit* target = eventInfo.GetActionTarget();
        if (!spell || !damage || !damage->GetDamage() || !target || spell->SpellFamilyName != SPELLFAMILY_WARRIOR ||
            !(spell->SpellFamilyFlags[1] & WARRIOR_SHOCKWAVE_FLAG1))
            return false;
        for (auto const& [slot, application] : *target->GetVisibleAuras())
        {
            Aura const* aura = application->GetBase();
            SpellInfo const* info = aura->GetSpellInfo();
            if (aura->GetCasterGUID() == GetTarget()->GetGUID() && info->SpellFamilyName == SPELLFAMILY_WARRIOR &&
                (info->SpellFamilyFlags[0] & WARRIOR_THUNDER_CLAP_FLAG0))
                return true;
        }
        return false;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        uint32 const school = aurEff->GetMiscValue() > 0 ? uint32(aurEff->GetMiscValue()) : uint32(SPELL_SCHOOL_MASK_NATURE);
        SpellNonMeleeDamage strike(caster, target, GetSpellInfo(), school);
        caster->CalculateSpellDamageTaken(&strike, int32(CalculatePct(eventInfo.GetDamageInfo()->GetDamage(),
            aurEff->GetAmount())), GetSpellInfo());
        Unit::DealDamageMods(target, strike.damage, &strike.absorb);
        caster->SendSpellNonMeleeDamageLog(&strike);
        caster->DealSpellDamage(&strike, true);

        Player* player = caster->ToPlayer();
        Spell const* shockwave = eventInfo.GetProcSpell();
        if (!player || !shockwave)
            return;
        if (shockwave != _shockwave)
        {
            _shockwave = shockwave;
            _reduced = 0;
        }
        if (_reduced >= THUNDERING_BLOW_MAX_CDR_MS)
            return;
        _reduced += THUNDERING_BLOW_CDR_MS;
        player->ModifySpellCooldown(shockwave->GetSpellInfo()->Id, -THUNDERING_BLOW_CDR_MS);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_thundering_blow::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_thundering_blow::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_mystic_vanguard : public SpellScript
{
    PrepareSpellScript(spell_ascension_mystic_vanguard);

    Unit* VigilanceTarget()
    {
        Unit* caster = GetCaster();
        Player* player = caster->ToPlayer();
        Group* group = player ? player->GetGroup() : nullptr;
        if (!group)
            return nullptr;
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            if (Player* member = ref->GetSource())
                if (member != caster && member->IsInMap(caster) && caster->IsWithinDistInMap(member, VANGUARD_RANGE) &&
                    member->HasAuraOrTwin(SPELL_VIGILANCE, caster->GetGUID()))
                    return member;
        return nullptr;
    }

    SpellCastResult CheckCast()
    {
        return VigilanceTarget() ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }

    void HandleDummy(SpellEffIndex)
    {
        if (Unit* ally = VigilanceTarget())
            GetCaster()->CastSpell(ally, SPELL_VANGUARD_CHARGE, true);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_mystic_vanguard::CheckCast);
        OnEffectHit += SpellEffectFn(spell_ascension_mystic_vanguard::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_ascension_mystic_vigilant_vanguard : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_vigilant_vanguard);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* warrior = GetCaster();
        Unit* victim = eventInfo.GetActionTarget();
        return warrior && victim && warrior->IsAlive() && victim->IsAlive() && warrior->IsWithinMeleeRange(victim);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (Unit* warrior = GetCaster())
            warrior->CastSpell(eventInfo.GetActionTarget(), SPELL_VANGUARD_ATTACK, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_vigilant_vanguard::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_vigilant_vanguard::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class AscensionMysticEnchantFocusedFire final : public AllSpellScript
{
    static bool KillCommandActive(Player const* owner)
    {
        for (auto const& [id, application] : owner->GetAppliedAuras())
        {
            SpellInfo const* info = application->GetBase()->GetSpellInfo();
            if (info->SpellFamilyName == SPELLFAMILY_HUNTER && (info->SpellFamilyFlags[1] & HUNTER_KILL_COMMAND_FLAG1) &&
                !info->IsPassive())
                return true;
        }
        return false;
    }

public:
    AscensionMysticEnchantFocusedFire() : AllSpellScript("AscensionMysticEnchantFocusedFire",
        { ALLSPELLHOOK_ON_CRIT_CHANCE }) { }

    void OnSpellCritChance(Spell* spell, Unit*, float& chance) override
    {
        Unit* pet = spell->GetCaster();
        if (!pet || !pet->IsPet() || spell->GetSpellInfo()->IsPassive() || spell->IsTriggered())
            return;
        Player* owner = pet->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (!owner || !KillCommandActive(owner))
            return;
        for (AuraEffect const* effect : owner->GetAuraEffectsByType(SPELL_AURA_DUMMY))
            if (effect->GetEffIndex() == EFFECT_1 && effect->GetSpellInfo()->SpellFamilyName == SPELLFAMILY_HUNTER &&
                effect->GetSpellInfo()->SpellName[LOCALE_enUS] &&
                std::string_view(effect->GetSpellInfo()->SpellName[LOCALE_enUS]) == FOCUSED_FIRE_NAME)
            {
                chance += float(effect->GetAmount());
                return;
            }
    }
};

class AscensionMysticEnchantBloodSoaked final : public AllSpellScript
{
public:
    AscensionMysticEnchantBloodSoaked() : AllSpellScript("AscensionMysticEnchantBloodSoaked",
        { ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_CAN_IGNORE_SHAPESHIFT }) { }

    static bool IsCrimsonTempest(SpellInfo const* info)
    {
        return info->SpellFamilyName == SPELLFAMILY_ROGUE && (info->SpellFamilyFlags[2] & ROGUE_CRIMSON_TEMPEST_FLAG2);
    }

    static bool IsGarrote(SpellInfo const* info)
    {
        return info->SpellFamilyName == SPELLFAMILY_ROGUE && (info->SpellFamilyFlags[0] & ROGUE_GARROTE_FLAG0) &&
            !info->IsPassive();
    }

    bool CanIgnoreShapeshift(Spell const* spell) override
    {
        return IsGarrote(spell->GetSpellInfo()) && _permission.contains(spell->GetCaster()->GetGUID());
    }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || spell->IsTriggered())
            return;
        if (IsCrimsonTempest(info))
            if (auto const points = _comboPoints.extract(player->GetGUID()))
                if (roll_chance_i(BLOOD_SOAKED_PCT_PER_COMBO * points.mapped()))
                    _permission.insert(player->GetGUID());
        if (!IsGarrote(info))
            return;
        if (!player->HasStealthAura() && _permission.erase(player->GetGUID()))
            _unstealthedGarrote.insert(player->GetGUID());
        else
            _unstealthedGarrote.erase(player->GetGUID());
    }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& res) override
    {
        Unit* caster = spell->GetCaster();
        if (res == SPELL_CAST_OK && caster && caster->IsPlayer() && !spell->IsTriggered() &&
            IsCrimsonTempest(spell->GetSpellInfo()) && caster->HasAura(SPELL_BLOOD_SOAKED_MUTILATION))
            _comboPoints[caster->GetGUID()] = caster->ToPlayer()->GetComboPoints();
        if (res != SPELL_CAST_OK || !spell->GetCaster() ||
            sSpellMgr->GetSpellTwinSource(spell->GetSpellInfo()->Id) != SPELL_GARROTE_SILENCE_STOCK)
            return;
        if (_unstealthedGarrote.erase(spell->GetCaster()->GetGUID()))
            res = SPELL_FAILED_DONT_REPORT;
    }

private:
    std::unordered_set<ObjectGuid> _permission;
    std::unordered_map<ObjectGuid, uint8> _comboPoints;
    std::unordered_set<ObjectGuid> _unstealthedGarrote;
};

class AscensionMysticEnchantPredatorsWrath final : public AllSpellScript
{
public:
    AscensionMysticEnchantPredatorsWrath() : AllSpellScript("AscensionMysticEnchantPredatorsWrath",
        { ALLSPELLHOOK_CAN_IGNORE_SHAPESHIFT }) { }

    bool CanIgnoreShapeshift(Spell const* spell) override
    {
        SpellInfo const* info = spell->GetSpellInfo();
        Unit const* caster = spell->GetCaster();
        return info->SpellFamilyName == SPELLFAMILY_DRUID && (info->SpellFamilyFlags[0] & DRUID_WRATH_FLAG0) &&
            caster->GetShapeshiftForm() == FORM_CAT && caster->HasAura(SPELL_WRATHFUL_STRIKES_READY);
    }
};

class AscensionMysticEnchantPredatorsWrathUnit final : public UnitScript
{
public:
    AscensionMysticEnchantPredatorsWrathUnit() : UnitScript("AscensionMysticEnchantPredatorsWrathUnit", true,
        { UNITHOOK_ON_AURA_APPLY, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN }) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (unit->IsPlayer() && sSpellMgr->GetSpellTwinSource(aura->GetId()) == SPELL_PREDATORS_SWIFTNESS_STOCK &&
            unit->HasAura(SPELL_PREDATORS_WRATH))
            unit->CastSpell(unit, SPELL_WRATHFUL_STRIKES_READY, true);
    }

    void ModifySpellDamageTaken(Unit*, Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (!attacker || !info || damage <= 0 || info->SpellFamilyName != SPELLFAMILY_DRUID ||
            !(info->SpellFamilyFlags[0] & DRUID_WRATH_FLAG0) || attacker->GetShapeshiftForm() != FORM_CAT)
            return;
        AuraEffect const* ready = attacker->GetAuraEffect(SPELL_WRATHFUL_STRIKES_READY, EFFECT_0);
        if (!ready)
            return;
        damage += int32(CalculatePct(attacker->GetTotalAttackPowerValue(BASE_ATTACK), ready->GetAmount()));
        attacker->RemoveAurasDueToSpell(SPELL_WRATHFUL_STRIKES_READY);
        attacker->CastSpell(attacker, SPELL_WRATHFUL_STRIKES_STACK, true);
    }
};

class spell_ascension_mystic_ice_barrage : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_ice_barrage);

    static uint8 Stored(Unit const* mage)
    {
        for (uint8 count = ICICLES.size(); count > 0; --count)
            if (mage->HasAura(ICICLES[count - 1]))
                return count;
        return 0;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && eventInfo.GetSpellInfo() && eventInfo.GetActionTarget();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* mage = GetTarget();
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        uint8 const stored = Stored(mage);
        if (spell->SpellFamilyFlags[0] & MAGE_ICE_LANCE_FLAG0)
        {
            if (!stored)
                return;
            mage->RemoveAurasDueToSpell(ICICLES[stored - 1]);
            for (uint8 i = 0; i < stored; ++i)
                mage->CastSpell(eventInfo.GetActionTarget(), SPELL_ICICLE, true, nullptr, aurEff);
            return;
        }
        if (stored >= ICICLES.size())
            return;
        if (stored)
            mage->RemoveAurasDueToSpell(ICICLES[stored - 1]);
        mage->AddAura(ICICLES[stored], mage);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_ice_barrage::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_ice_barrage::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class MinionBehaviourEvent final : public BasicEvent
{
public:
    using Tick = void (*)(Creature* minion, Player* owner);

    MinionBehaviourEvent(Creature* minion, uint32 enchant, Milliseconds interval, Tick tick)
        : _minion(minion), _enchant(enchant), _interval(interval), _tick(tick) { }

    bool Execute(uint64, uint32) override
    {
        Player* owner = _minion->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (!_minion->IsAlive() || !owner || !owner->IsInMap(_minion) || !owner->HasAura(_enchant))
            return true;
        _tick(_minion, owner);
        _minion->m_Events.AddEventAtOffset(new MinionBehaviourEvent(_minion, _enchant, _interval, _tick), _interval);
        return true;
    }

private:
    Creature* _minion;
    uint32 _enchant;
    Milliseconds _interval;
    Tick _tick;
};

std::vector<Unit*> InjuredAllies(Creature* minion, Player* owner, float belowPct)
{
    std::vector<Unit*> allies;
    auto consider = [&](Player* ally)
    {
        if (ally && ally->IsAlive() && ally->IsInMap(minion) && minion->IsWithinDistInMap(ally, MINION_HEAL_RANGE) &&
            minion->IsWithinLOSInMap(ally) && ally->GetHealthPct() < belowPct)
            allies.push_back(ally);
    };
    consider(owner);
    if (Group* group = owner->GetGroup())
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            if (ref->GetSource() != owner)
                consider(ref->GetSource());
    std::sort(allies.begin(), allies.end(), [](Unit const* a, Unit const* b) { return a->GetHealthPct() < b->GetHealthPct(); });
    return allies;
}

void TreantHeals(Creature* treant, Player* owner)
{
    std::vector<Unit*> const allies = InjuredAllies(treant, owner, GUARDIANS_HEAL_BELOW_PCT);
    if (allies.empty() || treant->HasUnitState(UNIT_STATE_CASTING))
        return;
    Unit* ally = allies.front();
    uint32 const rejuvenation = sSpellMgr->GetLastSpellInChain(SPELL_REJUVENATION_FIRST);
    uint32 const regrowth = sSpellMgr->GetLastSpellInChain(SPELL_REGROWTH_FIRST);
    treant->CastSpell(ally, ally->HasAura(rejuvenation, treant->GetGUID()) ? regrowth : rejuvenation, true);
}

void MirrorImageMends(Creature* image, Player* owner)
{
    if (!owner->HasAuraOrTwin(SPELL_MINDSHIFT))
        return;
    std::vector<Unit*> const allies = InjuredAllies(image, owner, 100.0f);
    if (!allies.empty())
        image->CastSpell(allies.front(), SPELL_MENDING_IMAGES_HEAL, true, nullptr, nullptr, owner->GetGUID());
}

uint32 DraconicKnowledgeHelper(Creature const* dragon)
{
    CreatureFamilyEntry const* family = sCreatureFamilyStore.LookupEntry(dragon->GetCreatureTemplate()->family);
    std::string_view const name = family && family->Name[LOCALE_enUS] ? family->Name[LOCALE_enUS] : "";
    if (name.starts_with("Blue") || name.starts_with("Bronze"))
        return SPELL_DRACONIC_KNOWLEDGE_HASTE;
    if (name.starts_with("Red") || name.starts_with("Green"))
        return SPELL_DRACONIC_KNOWLEDGE_CRIT;
    return SPELL_DRACONIC_KNOWLEDGE_SPELL_POWER;
}

void DraconicKnowledge(Creature* dragon, Player* owner)
{
    uint32 const helper = DraconicKnowledgeHelper(dragon);
    SpellInfo const* info = sSpellMgr->GetSpellInfo(helper);
    if (!info)
        return;
    int32 const amount = std::max(1, int32(CalculatePct(dragon->GetStat(STAT_INTELLECT), info->Effects[EFFECT_0].CalcValue())));
    AuraEffect const* current = owner->GetAuraEffect(helper, EFFECT_0, dragon->GetGUID());
    if (current && current->GetAmount() == amount)
        return;
    dragon->CastCustomSpell(dragon, helper, &amount, nullptr, nullptr, true);
}

void StartMinionBehaviour(Creature* minion, Player* owner)
{
    if (minion->GetEntry() == NPC_FORCE_OF_NATURE_TREANT && owner->HasAura(SPELL_GUARDIANS_OF_THE_GROVE))
    {
        minion->SetReactState(REACT_PASSIVE);
        minion->AttackStop();
        minion->SetMaxHealth(std::max<uint32>(1, minion->GetMaxHealth() / 2));
        minion->SetHealth(minion->GetMaxHealth());
        minion->m_Events.AddEventAtOffset(new MinionBehaviourEvent(minion, SPELL_GUARDIANS_OF_THE_GROVE,
            MINION_BEHAVIOUR_INTERVAL, TreantHeals), MINION_FIRST_TICK);
    }
    else if (minion->GetEntry() == NPC_MIRROR_IMAGE && owner->HasAura(SPELL_GLYPH_OF_MENDING_IMAGES))
    {
        AuraEffect const* glyph = owner->GetAuraEffect(SPELL_GLYPH_OF_MENDING_IMAGES, EFFECT_0);
        Milliseconds const interval(glyph && glyph->GetAmount() > 0 ? glyph->GetAmount() : 2000);
        minion->m_Events.AddEventAtOffset(new MinionBehaviourEvent(minion, SPELL_GLYPH_OF_MENDING_IMAGES, interval,
            MirrorImageMends), MINION_FIRST_TICK);
    }
    else if (minion->IsPet() && minion->GetCreatureTemplate()->type == CREATURE_TYPE_DRAGONKIN &&
        owner->HasAura(SPELL_DRACONIC_KNOWLEDGE))
        minion->m_Events.AddEventAtOffset(new MinionBehaviourEvent(minion, SPELL_DRACONIC_KNOWLEDGE,
            DRACONIC_KNOWLEDGE_REFRESH, DraconicKnowledge), MINION_FIRST_TICK);
}

class AscensionMysticEnchantMinionBehaviour final : public AllCreatureScript
{
public:
    AscensionMysticEnchantMinionBehaviour() : AllCreatureScript("AscensionMysticEnchantMinionBehaviour") { }

    void OnCreatureAddWorld(Creature* creature) override
    {
        if (!creature->IsSummon() || creature->IsPet())
            return;
        if (Player* owner = creature->GetCharmerOrOwnerPlayerOrPlayerItself())
            StartMinionBehaviour(creature, owner);
    }
};

class AscensionMysticEnchantPetBehaviour final : public PetScript
{
public:
    AscensionMysticEnchantPetBehaviour() : PetScript("AscensionMysticEnchantPetBehaviour",
        { PETHOOK_ON_PET_ADD_TO_WORLD }) { }

    void OnPetAddToWorld(Pet* pet) override
    {
        if (Player* owner = pet->GetOwner())
            StartMinionBehaviour(pet, owner);
    }
};
}

void AddSC_AscensionMysticEnchantMechanics()
{
    RegisterSpellScript(spell_ascension_mystic_abjurers_ward);
    RegisterSpellScript(spell_ascension_mystic_holy_radiance);
    RegisterSpellScript(spell_ascension_mystic_armor_of_faith);
    RegisterSpellScript(spell_ascension_mystic_purgation_by_light);
    RegisterSpellScript(spell_ascension_mystic_frugal_disposition);
    RegisterSpellScript(spell_ascension_mystic_consecrated_zeal);
    RegisterSpellScript(spell_ascension_mystic_glyph_of_impact);
    RegisterSpellScript(spell_ascension_mystic_impeccable_timing);
    RegisterSpellScript(spell_ascension_mystic_blade_vortex);
    new AscensionMysticEnchantEquilibrium();
    new AscensionMysticEnchantShadowSiphon();
    new AscensionMysticEnchantEchoingShadows();
    new AscensionMysticEnchantResurgentWaves();
    new AscensionMysticEnchantInfusedGems();
    RegisterSpellScript(spell_ascension_mystic_shadow_of_death);
    RegisterSpellScript(spell_ascension_mystic_thundering_blow);
    RegisterSpellScript(spell_ascension_mystic_vanguard);
    RegisterSpellScript(spell_ascension_mystic_vigilant_vanguard);
    new AscensionMysticEnchantFocusedFire();
    new AscensionMysticEnchantBloodSoaked();
    new AscensionMysticEnchantPredatorsWrath();
    new AscensionMysticEnchantPredatorsWrathUnit();
    RegisterSpellScript(spell_ascension_mystic_ice_barrage);
    new AscensionMysticEnchantMinionBehaviour();
    new AscensionMysticEnchantPetBehaviour();
}
