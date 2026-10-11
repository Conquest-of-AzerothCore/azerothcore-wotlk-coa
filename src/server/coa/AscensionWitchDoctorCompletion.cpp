/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchDoctorCompletion.h"
#include "AscensionWitchDoctorCoefficients.h"
#include "CellImpl.h"
#include "DBCStores.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <memory>
#include <mutex>
#include <unordered_map>

namespace AscensionWitchDoctor
{
namespace
{
std::unordered_map<ObjectGuid, std::unique_ptr<DoctorState>> states;
std::mutex stateMutex;
}

Player* Owner(Unit const* unit)
{
    Player* player = unit ? unit->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    return player && player->getClass() == CLASS_WITCH_DOCTOR ? player : nullptr;
}
DoctorState& State(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return *states.try_emplace(player->GetGUID(), std::make_unique<DoctorState>()).first->second;
}
void Forget(Player* player)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    states.erase(player->GetGUID());
}

std::list<Unit*> Nearby(Unit* center, float range)
{
    std::list<Unit*> units;
    if (!center || !center->IsInWorld())
        return units;
    Acore::AnyUnitInObjectRangeCheck check(center, range);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center, units, check);
    Cell::VisitObjects(center, search, range);
    units.remove_if([center](Unit* unit) { return !unit->IsAlive() || !center->InSamePhase(unit); });
    return units;
}
bool Friendly(Player* player, Unit* target)
{
    return player && target && target->IsAlive() && player->IsInMap(target) && player->InSamePhase(target) &&
           player->IsFriendlyTo(target) && (player == target || player->IsInRaidWith(target));
}
std::list<Unit*> Allies(Player* player, Unit* center, float range, uint32 cap)
{
    auto units = Nearby(center, range);
    units.remove_if([player, center](Unit* unit)
                    { return !Friendly(player, unit) || !center->IsWithinLOSInMap(unit); });
    units.sort(
        [](Unit* a, Unit* b)
        {
            if (a->GetHealthPct() != b->GetHealthPct())
                return a->GetHealthPct() < b->GetHealthPct();
            return a->GetGUID() < b->GetGUID();
        });
    if (cap && units.size() > cap)
        units.resize(cap);
    return units;
}
int32 Amount(uint32 id, uint8 effect, Unit* caster)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    return info ? info->Effects[effect].CalcValue(caster) : 0;
}
void Cast(Unit* caster, Unit* target, uint32 id)
{
    if (caster && target && target->IsAlive())
        caster->CastSpell(target, id, true);
}
void Copy(Unit* caster, Unit* target, uint32 id, uint32 amount)
{
    if (caster && target && target->IsAlive() && amount)
        caster->CastCustomSpell(id, SPELLVALUE_BASE_POINT0, int32(std::min(amount, uint32(INT32_MAX))), target, true);
}
uint8 Spirits(Player* player)
{
    Aura const* aura = player ? player->GetAura(Spirit) : nullptr;
    return aura ? aura->GetStackAmount() : 0;
}
void SyncSpirits(Player* player)
{
    uint8 count = Spirits(player);
    for (uint32 id : {SpiritStats, SpiritCast, SpiritChance})
    {
        if (!count)
            player->RemoveAurasDueToSpell(id);
        else
        {
            Aura* aura = player->GetAura(id);
            if (!aura)
                aura = player->AddAura(id, player);
            if (aura)
            {
                aura->SetStackAmount(count);
                aura->RecalculateAmountOfEffects();
            }
        }
    }
    uint8 orbIndex = 0;
    for (uint32 orb : {SpiritOrbOne, SpiritOrbTwo, SpiritOrbThree, SpiritOrbFour, SpiritOrbFive})
    {
        if (orbIndex++ >= count)
            player->RemoveAurasDueToSpell(orb);
        else if (Aura* shown = player->GetAura(orb))
            shown->RefreshDuration();
        else
            player->AddAura(orb, player);
    }
    if (AuraEffect* effect = player->GetAuraEffect(JujuSpirits, EFFECT_0))
        effect->ChangeAmount(Amount(JujuSpirits) * count);
    if (count && player->HasAura(SpiritWalk))
    {
        if (Aura* speed = player->AddAura(SpiritSpeed, player))
            speed->SetStackAmount(count);
    }
    else
        player->RemoveAurasDueToSpell(SpiritSpeed);
}
void GainSpirit(Player* player, uint8 count)
{
    if (!player || !player->IsAlive())
        return;
    for (uint8 i = 0; i < count; ++i)
    {
        Cast(player, player, Spirit);
        if (player->HasAura(TrueSpirit))
            Cast(player, player, TrueSpiritReady);
        if (player->HasAura(SpiritDevotee))
            Cast(player, player, SpiritMana);
    }
    SyncSpirits(player);
}
uint32 KnownRank(Player* player, uint32 root)
{
    uint32 result = root;
    for (auto const& [id, state] : player->GetSpellMap())
        if (state->State != PLAYERSPELL_REMOVED && state->Active &&
            sSpellMgr->GetFirstSpellInChain(id) == sSpellMgr->GetFirstSpellInChain(root) &&
            sSpellMgr->GetSpellRank(id) > sSpellMgr->GetSpellRank(result))
            result = id;
    return result;
}
void Reduce(Player* player, uint32 root, int32 milliseconds)
{
    if (!player)
        return;
    for (auto const& [id, state] : player->GetSpellMap())
        if (state->State != PLAYERSPELL_REMOVED &&
            sSpellMgr->GetFirstSpellInChain(id) == sSpellMgr->GetFirstSpellInChain(root))
        {
            if (milliseconds == INT32_MAX)
                player->RemoveSpellCooldown(id, true);
            else
                player->ModifySpellCooldown(id, -milliseconds);
        }
}
Aura* OwnedHex(Player* player, Unit* target)
{
    for (auto const& [key, app] : target->GetAppliedAuras())
        if (Aura* aura = app->GetBase(); aura->GetCasterGUID() == player->GetGUID() && IsHex(aura->GetSpellInfo()))
            return aura;
    return nullptr;
}
void SpreadHex(Player* player, Unit* target)
{
    Aura* source = OwnedHex(player, target);
    if (!source)
        return;
    for (Unit* unit : Nearby(target, 10.0f))
        if (unit != target && player->IsValidAttackTarget(unit) && !OwnedHex(player, unit) &&
            target->IsWithinLOSInMap(unit))
            if (Aura* copy = player->AddAura(source->GetId(), unit))
            {
                copy->SetDuration(source->GetDuration());
                if (AuraEffect* effect = copy->GetEffect(EFFECT_0))
                    if (AuraEffect* original = source->GetEffect(EFFECT_0))
                    {
                        effect->ChangeAmount(original->GetAmount());
                        effect->SetPeriodicTimer(original->GetPeriodicTimer());
                    }
                break;
            }
}

void ApplyContracts(SpellInfo* info)
{
    if (!info || (info->SpellFamilyName != 19 && info->Id != BeamMarker))
        return;
    uint32 id = info->Id;
    auto dummy = [info](uint8 index)
    {
        info->Effects[index].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[index].TriggerSpell = 0;
    };
    auto periodic = [info](uint8 index, uint32 amplitude)
    {
        info->Effects[index].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[index].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
        info->Effects[index].Amplitude = amplitude;
        info->Effects[index].TriggerSpell = 0;
    };
    if (id == Shadowhunter)
        dummy(EFFECT_1);
    if (id == PuppeteersGrasp)
        dummy(EFFECT_0);
    if ((id == ChosenOne || id == MojoHigh) &&
        info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
        info->Effects[EFFECT_0].MiscValue == SPELLMOD_EFFECT3)
        info->Effects[EFFECT_0].SpellClassMask = flag96(512, 0, 0);
    if (id == Mimic && info->Effects[EFFECT_2].Effect == SPELL_EFFECT_SUMMON)
        info->Effects[EFFECT_2].BasePoints = 1;
    if (Family(info, 0, 4))
    {
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_SCHOOL_DAMAGE;
        info->Effects[EFFECT_0].TriggerSpell = 0;
    }
    if (id == CallSseratus && info->Effects[EFFECT_1].TriggerSpell == TrueSpiritReady)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == ShadowhunterCost)
        info->Effects[EFFECT_0].Effect = info->Effects[EFFECT_1].Effect = 0;
    if (id == Spirit)
        periodic(EFFECT_2, 500);
    if (id == SpiritCast || id == SpiritChance || id == SpiritVisual)
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            dummy(i);
    if (id == SpiritStats)
    {
        dummy(EFFECT_0);
        info->Effects[EFFECT_1].SpellClassMask = flag96(536870912, 2147483648, 0);
    }
    if (id == JujuSpirits)
    {
        info->Effects[EFFECT_0].MiscValue = SPELLMOD_CRITICAL_CHANCE;
        info->Effects[EFFECT_0].SpellClassMask = flag96(0, 1024, 2);
    }
    if (id == VoodooMind || id == SoulFeeder || id == RitualOne || id == RitualTwo || id == Gift)
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            dummy(i);
    if (id == Gift)
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_RANGED_HASTE;
    if (id == OutOfBottle)
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            dummy(i);
    if (id == Veil)
        periodic(EFFECT_1, 1500);
    if (id == SpiritPickupBuff)
    {
        periodic(EFFECT_0, 2000);
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        info->Effects[EFFECT_2].Effect = 0;
    }
    if (id == SpiritPickup)
        info->Effects[EFFECT_1].Effect = info->Effects[EFFECT_2].Effect = 0;
    if (id == LoaSpiritsOne || id == LoaSpiritsTwo)
        dummy(EFFECT_1);
    if (id == SpiritWalkerOne)
        info->Effects[EFFECT_1].BasePoints = 9;
    if (id == Threads)
    {
        dummy(EFFECT_1);
        dummy(EFFECT_2);
    }
    if (IsJuju(info))
        info->Effects[EFFECT_1].Effect = 0;
    if (id == PuppetHit)
        info->Effects[EFFECT_1].Effect = 0;
    if (Family(info, 0, 8))
    {
        periodic(EFFECT_0, info->Effects[EFFECT_0].Amplitude);
        info->Effects[EFFECT_1].Effect = 0;
    }
    if (Family(info, 0, 536870912) && id != EclipseHit && id != EclipseSplash)
    {
        periodic(EFFECT_0, 250);
        info->DurationEntry = sSpellDurationStore.LookupEntry(1);
        info->Effects[EFFECT_1].Effect = 0;
        info->Speed = 0.0f;
    }
    if (id == EclipseHit || id == EclipseSplash || id == PuppetHit)
    {
        info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        for (SpellEffectInfo& effect : info->Effects)
        {
            effect.RealPointsPerLevel = 0.0f;
            effect.BonusMultiplier = 0.0f;
        }
    }
    if (Family(info, 0, 33554432))
    {
        dummy(EFFECT_1);
        if (info->Effects[EFFECT_2].ApplyAuraName == SPELL_AURA_MOD_RESISTANCE_EXCLUSIVE)
            info->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_MOD_RESISTANCE;
    }
    if (id == Frenzy)
    {
        dummy(EFFECT_2);
        info->DurationEntry = sSpellDurationStore.LookupEntry(1);
    }
    if (IsBeam(info))
    {
        periodic(EFFECT_0, 500);
        info->Effects[EFFECT_1].Effect = info->Effects[EFFECT_2].Effect = 0;
        info->AttributesEx5 &= ~SPELL_ATTR5_SPELL_HASTE_AFFECTS_PERIODIC;
    }
    if (id == BeamMarker)
        dummy(EFFECT_0);
    if (id == BeamCost)
    {
        info->Effects[EFFECT_0].SpellClassMask = flag96(0, 2048, 536870913);
        info->Effects[EFFECT_1].MiscValue = SPELLMOD_CASTING_TIME;
        info->Effects[EFFECT_1].BasePoints = -10001;
        info->Effects[EFFECT_1].SpellClassMask = info->Effects[EFFECT_0].SpellClassMask;
        info->Effects[EFFECT_2].Effect = 0;
    }
    if (IsSplash(info))
        info->Effects[EFFECT_1].Effect = info->Effects[EFFECT_2].Effect = 0;
    if (id == Tiki)
    {
        info->Effects[EFFECT_1].Effect = info->Effects[EFFECT_2].Effect = 0;
        info->Effects[EFFECT_0].TriggerSpell = 0;
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_HEAL;
    }
    if (id == PotionThistle || id == SplashThistle || id == ConcoctionsBuff || id == Devotion || id == BottleLink)
        dummy(EFFECT_0);
    if (id == ThistleHeal || id == FrenzyHeal || id == ConcoctionsHeal)
    {
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_HEAL;
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        info->Effects[EFFECT_0].BasePoints = 0;
        info->Effects[EFFECT_0].DieSides = 1;
    }
    if (id == MojoFish || id == MojoShrooms || id == MojoThistle)
        for (SpellEffectInfo& effect : info->Effects)
            if (!effect.IsAura())
                effect.Effect = 0;
    if (id == JungleBooms &&
        info->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
        info->Effects[EFFECT_1].MiscValue == 34 &&
        info->Effects[EFFECT_1].BasePoints == -4 && info->Effects[EFFECT_1].DieSides == 1)
    {
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_MAX_AFFECTED_TARGETS;
        info->Effects[EFFECT_1].SpellClassMask = flag96(0, 0, 2048);
    }
    if (IsIngredient(id))
    {
        info->StackAmount = 1;
        info->DurationEntry = sSpellDurationStore.LookupEntry(21);
    }
    if (id == Crystal)
        dummy(EFFECT_0);
    if (id == Beast)
    {
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_APPLY_AREA_AURA_RAID;
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        info->Effects[EFFECT_0].TriggerSpell = 0;
    }
    if (id == BeastShield)
        periodic(EFFECT_1, 1000);
    if (id == Vigil)
        periodic(EFFECT_1, 1000);
    if (id == Slither)
        info->AttributesCu &= ~SPELL_ATTR0_CU_NEGATIVE;
    if (id == StalkerSpeed)
        periodic(EFFECT_1, 500);
    if (id == Mirage)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == SenjinSwiftness)
        info->Effects[EFFECT_1].SpellClassMask = flag96(0, 0, 1073741824);
    if (id == SenjinWisdom)
        info->Effects[EFFECT_0].SpellClassMask = flag96(0, 0, 1073741824);
    if (id == RageBrewBuff)
        info->Effects[EFFECT_1].BasePoints = 14;
    if (id == Voice)
        info->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_MOD_PERCENT_STAT;
    if (id == Marionette)
    {
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_ROOT;
        info->Effects[EFFECT_1].Effect = info->Effects[EFFECT_2].Effect = 0;
    }
    if (id == MarionetteStacks)
    {
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_HASTE_SPELLS;
        info->Effects[EFFECT_0].BasePoints = 0;
        info->Effects[EFFECT_0].DieSides = 1;
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        info->Effects[EFFECT_1].Effect = 0;
    }
    if (id == MarionetteExplosion)
        info->Effects[EFFECT_2].Effect = 0;
    if (id == MalignantJinx)
        dummy(EFFECT_0);
    if (id == PriceReady || id == DambalaReady)
        info->Effects[EFFECT_2].Effect = 0;
    if (id == SenjinBuff)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == SenjinBuff || id == MojoFree || id == OtherSideBuff || id == PriceReady || id == DambalaReady ||
        id == TrueSpiritReady || id == OverflowBuff || id == ConcoctionsBuff)
        info->ProcCharges = 0;
    if (id == Volley)
    {
        info->Effects[EFFECT_1].Effect = info->Effects[EFFECT_2].Effect = 0;
        info->SpellFamilyFlags[1] |= 4;
    }
    if (id == Umbral)
    {
        info->Effects[EFFECT_1].Effect = 0;
        info->SpellFamilyFlags[1] |= 33554432;
        info->AttributesEx5 &= ~SPELL_ATTR5_EXTRA_INITIAL_PERIOD;
        info->StartRecoveryTime = 0;
        info->StartRecoveryCategory = 0;
    }
    if (id == HexfireWrath || id == Umbral)
    {
        info->MaxAffectedTargets = 3;
        for (SpellEffectInfo& effect : info->Effects)
        {
            effect.TargetB = SpellImplicitTargetInfo();
            effect.ChainTarget = 1;
        }
    }
    if (id == HexfireWrath)
        info->Effects[EFFECT_2].Effect = 0;
    if (id == BigVoodoo)
        info->Effects[EFFECT_1].Effect = info->Effects[EFFECT_2].Effect = 0;
    if (id == VoodooCauldron)
        info->Effects[EFFECT_2].Effect = 0;
    if (id == WarGolem)
    {
        SpellEffectInfo& absorb = info->Effects[EFFECT_1];
        absorb.Effect = SPELL_EFFECT_APPLY_AURA;
        absorb.ApplyAuraName = SPELL_AURA_SCHOOL_ABSORB;
        absorb.MiscValue = SPELL_SCHOOL_MASK_ALL;
        absorb.BasePoints = 0;
        absorb.DieSides = 1;
        absorb.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
    }
    for (uint32 child : {WardHeal, SpiritManaTick, Cleanse, SereneField, DarkField, JungleFieldSpell, SwiftField,
                         CauldronBuff, BigVoodooField, VoodooProtectionSpell})
        if (id == child)
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.IsEffect())
                {
                    if (effect.IsAura())
                        effect.Effect = SPELL_EFFECT_APPLY_AURA;
                    effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
                    effect.TargetB = SpellImplicitTargetInfo();
                }
    for (uint32 child : {ShadowField, ShadowSlow, GravenField, CursedField, SentryRevealSpell, EclipseSplash,
                         GlaiveExplosion, VoodooFire, ViperFire})
        if (id == child)
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.IsEffect())
                {
                    if (effect.IsAura())
                        effect.Effect = SPELL_EFFECT_APPLY_AURA;
                    effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
                    effect.TargetB = SpellImplicitTargetInfo();
                }
    if (id == ShadowField)
    {
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK;
        info->Effects[EFFECT_1].Effect = 0;
    }
    if (id == WardHaste)
    {
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_HASTE_SPELLS;
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
    }
    if (id == VoodooProtectionSpell)
        info->Effects[EFFECT_0].BasePoints = -21;
    if (id == JungleThistle)
    {
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_TRIGGER_SPELL;
        info->Effects[EFFECT_0].TriggerSpell = JungleProtection;
        info->Effects[EFFECT_2].BasePoints = 19;
    }
    if (id == SentryRevealSpell)
    {
        for (SpellEffectInfo& effect : info->Effects)
            effect.Effect = 0;
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_APPLY_AURA;
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_STALKED;
    }
    if (id == Stasis)
        info->Effects[EFFECT_1].Effect = 0;
    for (SpellEffectInfo& effect : info->Effects)
        if (effect.Effect == SPELL_EFFECT_SUMMON)
            effect.MiscValueB = 64;
    if (id == UnstableHeal)
    {
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
        info->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo();
    }
    if (id == MarionetteTransform)
    {
        info->Effects[EFFECT_0].SpellClassMask[2] |= 2;
        info->Effects[EFFECT_1].SpellClassMask[2] |= 2;
    }
    if (id == Hexed)
    {
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_CONFUSE;
        info->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_MOD_ROOT;
        info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE;
    }
    if (id == Amphibimorph)
        info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE;
    if (IsBeam(info))
        info->ManaPerSecond = 0;
    if (id == Frenzy)
        info->Effects[EFFECT_1].MiscValueB = 0;
    for (DoctorCoefficient const& coefficient : DoctorCoefficients)
        if (coefficient.id == id)
            info->Effects[coefficient.effect].BonusMultiplier = 0.0f;
    for (uint32 child : {ThreadsDamage, BottleDamage, LoaEchoHeal, WaveHeal, ThistleHeal, ConcoctionsHeal, DevotionHeal,
                         FrenzyHeal, EclipseHit, ShadowflareHit, PuppetHit})
        if (id == child)
            for (SpellEffectInfo& effect : info->Effects)
                effect.BonusMultiplier = 0.0f;
    for (uint32 child : {ThreadsDamage, BottleDamage, LoaEchoHeal, WaveHeal, ThistleHeal, ConcoctionsHeal, DevotionHeal,
                         FrenzyHeal, StringsDamage, GuileDamage})
        if (id == child)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.IsEffect())
                {
                    bool heal = effect.Effect == SPELL_EFFECT_HEAL;
                    effect.TargetA = SpellImplicitTargetInfo(heal ? TARGET_UNIT_TARGET_ALLY : TARGET_UNIT_TARGET_ENEMY);
                    effect.TargetB = SpellImplicitTargetInfo();
                }
            info->_InitializeExplicitTargetMask();
        }
    if (id == JungleSecretsHeal)
    {
        info->DmgClass = SPELL_DAMAGE_CLASS_NONE;
        info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
        info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        info->AscensionInheritsResolvedAmount = true;
        info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
        info->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo();
        info->_InitializeExplicitTargetMask();
    }
}
}

namespace
{
using namespace AscensionWitchDoctor;
class witch_doctor_scaling : public UnitScript
{
  public:
    witch_doctor_scaling()
        : UnitScript("witch_doctor_scaling", true,
                     {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE, UNITHOOK_ON_PERIODIC_DAMAGE_RESULT})
    {
    }
    void OnPeriodicDamageResult(Unit* target, Unit* attacker, uint32 damage, SpellInfo const* info) override
    {
        if (!target || !attacker || !info || !damage)
            return;
        Aura* aura = target->GetAura(info->Id, attacker->GetGUID());
        if (!aura || !aura->GetScriptValue(ConcoctionsBuff))
            return;
        Unit* doctor = ObjectAccessor::GetUnit(*attacker, ObjectGuid(aura->GetScriptValue(ConcoctionsHeal)));
        Copy(doctor ? doctor : attacker, attacker, ConcoctionsHeal,
             uint32(std::min<uint64>(UINT32_MAX, uint64(damage) * aura->GetScriptValue(ConcoctionsBuff) / 100)));
    }
    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = Owner(caster);
        if (!player)
            return;
        for (DoctorCoefficient const& c : DoctorCoefficients)
            if (c.id == info->Id && c.effect == index)
            {
                float sp = float(c.healing        ? player->SpellBaseHealingBonusDone(SpellSchoolMask(c.school))
                                 : c.school == 12 ? std::max(player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE),
                                                             player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE))
                                                  : player->SpellBaseDamageBonusDone(SpellSchoolMask(c.school)));
                value += std::max(0.0f, sp) * c.sp + player->GetStat(STAT_SPIRIT) * c.spirit +
                         player->GetTotalAttackPowerValue(RANGED_ATTACK) * c.rap +
                         player->GetTotalAttackPowerValue(BASE_ATTACK) * c.ap;
            }
    }
};
class witch_doctor_sessions : public PlayerScript
{
  public:
    witch_doctor_sessions() : PlayerScript("witch_doctor_sessions", {PLAYERHOOK_ON_LOGOUT}) {}
    void OnPlayerLogout(Player* player) override { Forget(player); }
};
}
void AddAscensionWitchDoctorCompletionScripts()
{
    new witch_doctor_scaling();
    new witch_doctor_sessions();
}
