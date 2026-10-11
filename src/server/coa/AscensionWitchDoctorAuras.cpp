/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchDoctorCompletion.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "ThreatManager.h"
#include <algorithm>
#include <array>

namespace AscensionWitchDoctor
{
void SyncReplacements(Player* player)
{
    std::vector<uint32> known;
    for (auto const& [id, state] : player->GetSpellMap())
        if (state->State != PLAYERSPELL_REMOVED)
            known.push_back(id);
    for (uint32 id : known)
    {
        SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
        uint32 child = 0;
        bool selected = false;
        if (Family(info, 1, 4) && id != Volley)
        {
            selected = true;
            if ((player->HasAura(VolleyReady) || (player->HasAura(Gift) && HasSummon(player, NpcMimic))) &&
                id == KnownRank(player, id))
                child = Volley;
        }
        else if (IsHex(info))
        {
            selected = true;
            if (player->HasAura(UmbralReady))
                child = Umbral;
        }
        else if (Family(info, 1, 32768) && !IsArrow(info) && id != HexfireWrath)
        {
            selected = true;
            if (player->HasAura(HexfireReady))
                child = HexfireWrath;
            else if (player->HasAura(Shadowhunter) || player->HasAura(ArrowTalent))
            {
                child = Arrow;
                for (uint32 next = sSpellMgr->GetNextSpellInChain(child); next;
                     next = sSpellMgr->GetNextSpellInChain(child))
                {
                    if (sSpellMgr->GetSpellRank(next) > sSpellMgr->GetSpellRank(id))
                        break;
                    child = next;
                }
            }
        }
        else if (IsBottle(info))
        {
            selected = true;
            if (player->HasAura(TikiTalent) && (player->HasAura(Crystal) || player->HasAura(Beast)))
                child = Tiki;
        }
        else if (id == CallSseratusChannel)
        {
            selected = true;
            if (player->HasAura(ViperTalent))
                child = ViperWard;
        }
        else if (id == Allcure)
        {
            selected = true;
            if (player->HasAura(MassAllcureTalent))
                child = MassAllcure;
        }
        if (!selected)
            continue;
        if (child && !player->HasSpell(child))
            player->learnSpell(child, true);
        player->SetTemporarySpellReplacement(id, child, child != Volley);
    }
}
}

namespace
{
using namespace AscensionWitchDoctor;
bool Wuju(SpellInfo const* info)
{
    return Family(info, 0, 256) || Family(info, 2, 16777216);
}
bool Jinx(SpellInfo const* info)
{
    return Family(info, 2, 32);
}

class aura_ascension_witch_doctor_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_witch_doctor_lifecycle);
    std::array<uint64, 5> _debt = {};
    uint8 _payment = 0;
    uint8 _spirits = 0;
    uint32 _ticks = 0;
    uint32 _splash = 0;
    bool _paying = false;
    bool _released = false;

    bool First(AuraEffect const* effect) const
    {
        for (uint8 i = 0; i < effect->GetEffIndex(); ++i)
            if (GetEffect(i))
                return false;
        return true;
    }
    void Calculate(AuraEffect const* effect, int32& amount, bool& recalculate)
    {
        Player* player = Owner(GetCaster());
        if (GetId() == BeastShield && effect->GetEffIndex() == EFFECT_0)
        {
            amount = -1;
            recalculate = false;
        }
        if (!player)
            return;
        if (GetId() == Gift && effect->GetEffIndex() == EFFECT_0)
            amount = HasSummon(player, NpcMimic) ? Amount(Gift) : 0;
        if (GetId() == SpiritPickupBuff && effect->GetEffIndex() == EFFECT_0)
        {
            amount = Amount(SpiritPickup, EFFECT_1) +
                     std::max(0, player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)) * 0.04f +
                     player->GetTotalAttackPowerValue(BASE_ATTACK) * 0.02f;
            recalculate = false;
        }
        if ((Family(GetSpellInfo(), 0, 536870912) || Family(GetSpellInfo(), 0, 8)) && effect->GetEffIndex() == EFFECT_0)
        {
            amount = player->SpellDamageBonusDone(GetUnitOwner(), GetSpellInfo(), std::max(0, amount),
                                                  SPELL_DIRECT_DAMAGE, EFFECT_0);
            recalculate = false;
        }
        if (GetId() == WarGolem && effect->GetEffIndex() == EFFECT_1)
        {
            amount = std::max(1, int32(player->GetStat(STAT_INTELLECT) * 8));
            recalculate = false;
        }
        if (GetId() == SpiritStats)
        {
            if (effect->GetEffIndex() == EFFECT_1)
                amount = player->HasAura(SoulFeeder) ? Amount(SoulFeeder, EFFECT_1) : 0;
            if (effect->GetEffIndex() == EFFECT_2)
                amount = player->HasAura(LoaSpiritsTwo) ? 4 : player->HasAura(LoaSpiritsOne) ? 2 : 0;
        }
        if (GetId() == Frenzy)
        {
            uint8 count = Spirits(player);
            amount = effect->GetEffIndex() == EFFECT_0   ? 10 * count
                     : effect->GetEffIndex() == EFFECT_1 ? 5 * count
                                                         : 2 * count;
            recalculate = false;
        }
        if (GetId() == Voice && effect->GetEffIndex() == EFFECT_2)
            amount = player->HasAura(PriceOfPower) ? 100 : 0;
        if (Family(GetSpellInfo(), 0, 33554432) && effect->GetEffIndex() == EFFECT_2)
            amount = -int32(player->GetLevel() + 1);
    }
    void Periodic(AuraEffect const* effect, bool& periodic, int32& amplitude)
    {
        uint32 id = GetId();
        if ((id == Frenzy && effect->GetEffIndex() == EFFECT_2) || (First(effect) && (id == Mirage || id == Avatar)))
        {
            periodic = true;
            amplitude = 1000;
        }
        if (Family(GetSpellInfo(), 0, 8) && effect->GetEffIndex() == EFFECT_0)
            if (Player* player = Owner(GetCaster()))
                if (player->HasAura(VoodooMind))
                    amplitude = amplitude * 100 / (100 + 10 * Spirits(player));
    }
    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (IsHex(GetSpellInfo()) && effect->GetAuraType() == SPELL_AURA_PERIODIC_DAMAGE)
            if (Unit* caster = GetCaster())
                if (AuraEffect* periodic = GetEffect(effect->GetEffIndex()))
                {
                    SpellInfo const* info = GetSpellInfo();
                    float chance = caster->SpellDoneCritChance(nullptr, info, info->GetSchoolMask(), BASE_ATTACK, true);
                    periodic->SetCritChance(GetTarget()->SpellTakenCritChance(caster, info, info->GetSchoolMask(),
                        chance, BASE_ATTACK, true));
                }
        if (!First(effect))
            return;
        uint32 id = GetId();
        Unit* target = GetTarget();
        Player* player = Owner(GetCaster());
        if (id == ConcoctionsBuff)
            GetAura()->SetCharges(3);
        if (Wuju(GetSpellInfo()) || Jinx(GetSpellInfo()))
        {
            std::vector<std::pair<uint32, ObjectGuid>> remove;
            for (auto const& [key, app] : target->GetAppliedAuras())
            {
                Aura* aura = app->GetBase();
                if (aura != GetAura() && ((Wuju(GetSpellInfo()) && Wuju(aura->GetSpellInfo())) ||
                                          (Jinx(GetSpellInfo()) && Jinx(aura->GetSpellInfo()))))
                    remove.emplace_back(aura->GetId(), aura->GetCasterGUID());
            }
            for (auto const& [spell, guid] : remove)
                target->RemoveAurasDueToSpell(spell, guid);
        }
        if (!player)
            return;
        if (IsIngredient(id) && target == player)
            IngredientChanged(player, id, true);
        if (id == Spirit && target == player)
            SyncSpirits(player);
        if (id == Shadowhunter && target == player)
            Cast(player, player, ShadowhunterCost);
        if (id == Crystal || id == Beast)
        {
            if (player == target)
                player->RemoveAurasDueToSpell(id == Beast ? Crystal : Beast);
            if (id == Beast)
                Cast(player, target, BeastShield);
        }
        if (Family(GetSpellInfo(), 0, 536870912))
        {
            _spirits = Spirits(player);
            _splash = player->SpellDamageBonusDone(
                target, GetSpellInfo(),
                uint32(std::max(0, Amount(EclipseSplash)) +
                       std::max(0, player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)) * 0.15f +
                       player->GetTotalAttackPowerValue(RANGED_ATTACK) * 0.15f),
                SPELL_DIRECT_DAMAGE, EFFECT_0);
            player->ApplySpellMod(EclipseSplash, SPELLMOD_DAMAGE, _splash);
        }
        if (id == SenjinBuff)
            GetAura()->SetCharges(2);
        if (id == Marionette)
            Summon(player, Marionette, player, player->GetPosition());
        if (id == MarionetteStacks && GetStackAmount() >= 20)
        {
            Cast(player, player, MarionetteTransform);
            ExplodeClones(player);
            Remove();
        }
    }
    void Pay(uint64 amount)
    {
        Unit* target = GetTarget();
        if (!amount || !target->IsInWorld() || !target->IsAlive())
            return;
        _paying = true;
        Unit::DealDamage(target, target, uint32(std::min<uint64>(amount, UINT32_MAX)), nullptr, DOT,
                         SPELL_SCHOOL_MASK_NORMAL, nullptr, false);
        _paying = false;
    }
    void Tick(AuraEffect const* effect)
    {
        uint32 id = GetId();
        Player* player = Owner(GetCaster());
        if (id == BeastShield && effect->GetEffIndex() == EFFECT_1)
        {
            PreventDefaultAction();
            uint64 amount = _debt[_payment];
            _debt[_payment] = 0;
            _payment = (_payment + 1) % _debt.size();
            Pay(amount);
            return;
        }
        if (!player)
            return;
        if (id == Spirit && effect->GetEffIndex() == EFFECT_2)
        {
            PreventDefaultAction();
            SyncSpirits(player);
        }
        if (Family(GetSpellInfo(), 0, 8) && effect->GetEffIndex() == EFFECT_0)
        {
            PreventDefaultAction();
            player->CastCustomSpell(PuppetHit, SPELLVALUE_BASE_POINT0, effect->GetAmount(), GetTarget(), true, nullptr,
                                    effect);
            GainSpirit(player);
        }
        if (Family(GetSpellInfo(), 0, 536870912) && effect->GetEffIndex() == EFFECT_0)
        {
            PreventDefaultAction();
            if (!_spirits || _ticks >= _spirits)
            {
                Remove();
                return;
            }
            ++_ticks;
            player->CastCustomSpell(EclipseHit, SPELLVALUE_BASE_POINT0, effect->GetAmount(), GetTarget(), true, nullptr,
                                    effect);
            uint32 hits = 0;
            for (Unit* enemy : Nearby(GetTarget(), 10.0f))
                if (enemy != GetTarget() && player->IsValidAttackTarget(enemy))
                {
                    Copy(player, enemy, EclipseSplash, _splash);
                    if (++hits == 5)
                        break;
                }
        }
        if (id == SpiritPickupBuff && effect->GetEffIndex() == EFFECT_0)
        {
            PreventDefaultAction();
            Copy(player, player, LoaEchoHeal, std::max(0, effect->GetAmount()));
            player->EnergizeBySpell(player, id, std::max(0, effect->GetAmount()), POWER_MANA);
        }
        if (id == Veil && effect->GetEffIndex() == EFFECT_1)
        {
            PreventDefaultAction();
            SpellInfo const* helper = sSpellMgr->GetSpellInfo(VeilDamage);
            if (player->IsWithinDistInMap(GetTarget(), helper->GetMaxRange(false, player)) &&
                player->IsWithinLOSInMap(GetTarget()))
                Cast(player, GetTarget(), VeilDamage);
        }
        if (id == Vigil && effect->GetEffIndex() == EFFECT_1)
        {
            PreventDefaultAction();
            Cast(player, player, VigilHeal);
        }
        if (id == Frenzy && effect->GetEffIndex() == EFFECT_2)
        {
            PreventDefaultAction();
            GainSpirit(player);
        }
        if (id == StalkerSpeed && effect->GetEffIndex() == EFFECT_1)
        {
            PreventDefaultAction();
            if (player->HasAura(Hunger) && (player->HasAura(Shadowstalker) || player->HasAura(Mirage)))
                Cast(player, player, HungerBuff);
        }
        if (id == Mirage && First(effect))
        {
            PreventDefaultAction();
            for (Unit* enemy : Nearby(player, 100.0f))
                if (enemy->CanHaveThreatList())
                    enemy->GetThreatMgr().ModifyThreatByPercent(player, -20);
        }
        if (id == Avatar && First(effect))
        {
            PreventDefaultAction();
            if (player->HasAura(VoljinBlessing))
            {
                uint32 glaive = KnownRank(player, Glaive);
                Reduce(player, Glaive, player->GetSpellCooldownDelay(glaive) / 5);
            }
        }
    }
    void Absorb(AuraEffect*, DamageInfo& damage, uint32& absorb)
    {
        if (GetId() == WarGolem)
        {
            if (Player* player = Owner(GetCaster()); !player || !HasSummon(player, NpcGolem))
                absorb = 0;
            return;
        }
        if (GetId() != BeastShield)
            return;
        absorb = 0;
        if (_paying || damage.GetDamageType() == DOT || !(damage.GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL))
            return;
        absorb = uint64(damage.GetDamage()) * 15 / 100;
        for (uint8 i = 0; i < _debt.size(); ++i)
            _debt[(_payment + i) % _debt.size()] += absorb / _debt.size() + (i < absorb % _debt.size());
    }
    void Removed(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (!First(effect))
            return;
        Player* player = Owner(GetCaster());
        uint32 id = GetId();
        if (id == BeastShield)
        {
            uint64 remaining = 0;
            for (uint64 amount : _debt)
                remaining += amount;
            _debt = {};
            Pay(remaining);
        }
        if (!player)
            return;
        if (id == Threads && !_released)
        {
            _released = true;
            Copy(player, GetTarget(), ThreadsDamage, std::max(0, effect->GetAmount()));
        }
        if (IsIngredient(id) && player == GetTarget())
            IngredientChanged(player, id, false);
        if (id == Spirit && player == GetTarget())
        {
            for (uint32 helper : {SpiritStats, SpiritCast, SpiritChance, SpiritSpeed, SpiritOrbOne, SpiritOrbTwo,
                                  SpiritOrbThree, SpiritOrbFour, SpiritOrbFive})
                player->RemoveAurasDueToSpell(helper);
        }
        if (IsHex(GetSpellInfo()))
            GetTarget()->RemoveAurasDueToSpell(GrowingDebuff, player->GetGUID());
        if (id == Shadowhunter)
            player->RemoveAurasDueToSpell(ShadowhunterCost);
        if (id == Beast)
            GetTarget()->RemoveAurasDueToSpell(BeastShield, player->GetGUID());
        if ((id == Shadowstalker || id == Mirage) && !player->HasAura(Shadowstalker) && !player->HasAura(Mirage))
            player->RemoveAurasDueToSpell(StalkerSpeed);
        if (id == Slither)
            player->RemoveAurasDueToSpell(SlitherAvoid);
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
        {
            if (Family(GetSpellInfo(), 0, 33554432) && player->HasAura(Godslayer))
            {
                Cast(player, GetTarget(), GlaiveExplosion);
                for (Unit* enemy : Nearby(GetTarget(), 10.0f))
                    if (enemy != GetTarget() && player->IsValidAttackTarget(enemy))
                        Cast(player, enemy, GlaiveExplosion);
            }
            if (id == Avatar && player->HasAura(Residual))
                Cast(player, player, LesserAvatar);
        }
    }
    void Dispel(DispelInfo* dispel)
    {
        Player* player = Owner(GetCaster());
        if (player && player->HasAura(LatentCurse) && Jinx(GetSpellInfo()) &&
            (GetId() == Shrinking || (GetId() >= 807829 && GetId() <= 807833)))
            Cast(player, dispel->GetDispeller(), Misery);
    }
    void Register() override
    {
        DoEffectCalcAmount +=
            AuraEffectCalcAmountFn(aura_ascension_witch_doctor_lifecycle::Calculate, EFFECT_ALL, SPELL_AURA_ANY);
        DoEffectCalcPeriodic +=
            AuraEffectCalcPeriodicFn(aura_ascension_witch_doctor_lifecycle::Periodic, EFFECT_ALL, SPELL_AURA_ANY);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_witch_doctor_lifecycle::Apply, EFFECT_ALL, SPELL_AURA_ANY,
                                              AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic +=
            AuraEffectPeriodicFn(aura_ascension_witch_doctor_lifecycle::Tick, EFFECT_ALL, SPELL_AURA_ANY);
        if (sSpellMgr->GetSpellInfo(m_scriptSpellId)->HasAura(SPELL_AURA_SCHOOL_ABSORB))
            OnEffectAbsorb +=
                AuraEffectAbsorbFn(aura_ascension_witch_doctor_lifecycle::Absorb, EFFECT_ALL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_witch_doctor_lifecycle::Removed, EFFECT_ALL,
                                                SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        AfterDispel += AuraDispelFn(aura_ascension_witch_doctor_lifecycle::Dispel);
    }
};

class witch_doctor_update : public UnitScript
{
  public:
    witch_doctor_update() : UnitScript("witch_doctor_update", true, {UNITHOOK_ON_UNIT_UPDATE}) {}
    void OnUnitUpdate(Unit* unit, uint32 diff) override
    {
        Player* player = Owner(unit);
        if (!player || player != unit)
            return;
        auto& state = State(player);
        state.update += diff;
        if (state.update < 500)
            return;
        state.update = 0;
        PruneSummons(player);
        SyncIngredients(player);
        SyncReplacements(player);
        if (AuraEffect* gift = player->GetAuraEffect(Gift, EFFECT_0))
            gift->ChangeAmount(HasSummon(player, NpcMimic) ? Amount(Gift) : 0);
        if (AuraEffect* voice = player->GetAuraEffect(Voice, EFFECT_2))
            voice->ChangeAmount(player->HasAura(PriceOfPower) ? 100 : 0);
        if (player->HasAura(Shadowhunter) && !player->HasSpell(AutoShot))
            player->learnSpell(AutoShot, true);
        if (player->HasAura(Shadowhunter) && !player->HasAura(ShadowhunterCost))
            Cast(player, player, ShadowhunterCost);
        if (!player->HasAura(Shadowhunter))
            player->RemoveAurasDueToSpell(ShadowhunterCost);
        if (player->HasAura(MarionetteStacks) && player->GetAura(MarionetteStacks)->GetStackAmount() >= 20)
        {
            Cast(player, player, MarionetteTransform);
            player->RemoveAurasDueToSpell(MarionetteStacks);
            ExplodeClones(player);
        }
        if (player->HasAura(BeamCost) && !player->GetCurrentSpell(CURRENT_CHANNELED_SPELL))
            player->RemoveAurasDueToSpell(BeamCost);
    }
};
}
void AddAscensionWitchDoctorAuraScripts()
{
    RegisterSpellScript(aura_ascension_witch_doctor_lifecycle);
    new witch_doctor_update();
}
