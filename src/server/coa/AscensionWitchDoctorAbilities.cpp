/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchDoctorCompletion.h"
#include "Creature.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <cstdlib>

namespace
{
using namespace AscensionWitchDoctor;
constexpr uint32 BuffSnapshotKey = 0;
void RefreshOwnedHex(Player* player, Unit* target)
{
    if (Aura* hex = OwnedHex(player, target))
        hex->RefreshDuration();
}

class witch_doctor_casts : public AllSpellScript
{
  public:
    witch_doctor_casts()
        : AllSpellScript("witch_doctor_casts",
                         {ALLSPELLHOOK_ON_PREPARE, ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_HIT_RESULT,
                          ALLSPELLHOOK_ON_CALCULATED_TARGET, ALLSPELLHOOK_ON_BEFORE_EFFECTS,
                          ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_CALC_MAX_DURATION})
    {
    }

    static void SnapshotBuffs(Spell* spell, Unit* caster)
    {
        if (spell->IsTriggered() || spell->GetScriptValue(BuffSnapshotKey))
            return;
        spell->SetScriptValue(BuffSnapshotKey, 1);
        for (uint32 id : {MojoFree, PriceReady, DambalaReady, TrueSpiritReady, OverflowBuff, VolleyReady,
                          UmbralReady, HexfireReady, MojoThistle, MojoFish, MojoShrooms})
            if (caster->HasAura(id))
                spell->SetScriptValue(id, 1);
        if (AuraEffect* effect = caster->GetAuraEffect(ConcoctionsBuff, EFFECT_0))
        {
            spell->SetScriptValue(ConcoctionsBuff, std::max(0, effect->GetAmount()));
            spell->SetScriptValue(ConcoctionsHeal, effect->GetCasterGUID().GetRawValue());
        }
    }

    void OnSpellPrepare(Spell* spell, Unit* caster, SpellInfo const*) override
    {
        if (spell->IsTriggered())
            return;
        if (Player* player = Owner(caster); player == caster)
            spell->SetScriptValue(IngredientMarker, IngredientMask(player));
        SnapshotBuffs(spell, caster);
    }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        SnapshotBuffs(spell, spell->GetCaster());
        Player* player = Owner(spell->GetCaster());
        if (!player || spell->GetCaster() != player || spell->IsTriggered() || result != SPELL_CAST_OK)
            return;
        SpellInfo const* info = spell->GetSpellInfo();
        uint32 id = info->Id;
        if ((Family(info, 0, 536870912) || id == Frenzy) && !Spirits(player))
            result = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        if ((IsPotion(info) || IsSplash(info)) && State(player).ingredients.empty())
            result = SPELL_FAILED_CASTER_AURASTATE;
        if ((id == Umbral && !player->HasAura(UmbralReady) && !spell->GetScriptValue(UmbralReady)) ||
            (id == HexfireWrath && !player->HasAura(HexfireReady)) ||
            (id == Volley && !player->HasAura(VolleyReady) && !spell->GetScriptValue(VolleyReady) &&
             !(player->HasAura(Gift) && HasSummon(player, NpcMimic))) ||
            (id == Tiki && (!player->HasAura(TikiTalent) || (!player->HasAura(Crystal) && !player->HasAura(Beast)))) ||
            (id == ViperWard && !player->HasAura(ViperTalent)) ||
            (id == MassAllcure && !player->HasAura(MassAllcureTalent)) ||
            (IsArrow(info) && !player->HasAura(Shadowhunter) && !player->HasAura(ArrowTalent)) ||
            (id == AutoShot && !player->HasAura(Shadowhunter)))
            result = SPELL_FAILED_CASTER_AURASTATE;
        if (id == BigVoodoo && player->HasAura(BigVoodooLock))
            result = SPELL_FAILED_CASTER_AURASTATE;
        if ((IsHex(info) && player->HasAura(UmbralReady)) ||
            (Family(info, 1, 32768) && !IsArrow(info) && id != HexfireWrath &&
             (player->HasAura(HexfireReady) || player->HasAura(Shadowhunter) || player->HasAura(ArrowTalent))) ||
            (IsBottle(info) && player->HasAura(TikiTalent) && (player->HasAura(Crystal) || player->HasAura(Beast))) ||
            (id == CallSseratus && player->HasAura(ViperTalent)) ||
            (id == Allcure && player->HasAura(MassAllcureTalent)))
            result = SPELL_FAILED_CASTER_AURASTATE;
    }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || player != caster || spell->IsTriggered())
            return;
        spell->SetScriptValue(Spirit, Spirits(player));
        if (IsBottle(info) && player->HasAura(OutOfBottle) && player->CanCastDuringChannel(info))
            if (Unit* target = spell->m_targets.GetUnitTarget())
            {
                auto allies = Allies(player, target, 15.0f);
                allies.remove(target);
                uint32 added = 0;
                for (Unit* ally : allies)
                    if (player->IsWithinDistInMap(ally, 40.0f))
                    {
                        spell->AddUnitTargetForScript(ally, 1 << EFFECT_0);
                        if (++added == 2)
                            break;
                    }
            }
        if (info->Id == HexfireWrath || info->Id == Umbral)
            if (Unit* target = spell->m_targets.GetUnitTarget())
            {
                uint32 added = 0;
                uint32 mask = info->Id == HexfireWrath ? (1 << EFFECT_0) | (1 << EFFECT_1) : 1 << EFFECT_0;
                for (Unit* unit : Nearby(target, 10.0f))
                    if (unit != target && player->IsValidAttackTarget(unit) && player->IsWithinLOSInMap(unit))
                    {
                        spell->AddUnitTargetForScript(unit, mask);
                        if (++added == 2)
                            break;
                    }
            }
        if (player->HasAura(DarkEffigy) && (IsJuju(info) || Family(info, 1, 262144)))
            if (Unit* target = spell->m_targets.GetUnitTarget())
            {
                uint32 added = 0;
                for (Unit* unit : Nearby(target, 10.0f))
                    if (unit != target && player->IsValidAttackTarget(unit) && player->IsWithinLOSInMap(unit))
                    {
                        spell->AddUnitTargetForScript(unit, 1 << EFFECT_0);
                        if (++added == 2)
                            break;
                    }
            }
    }

    void OnCalcMaxDuration(Aura const* aura, int32& duration) override
    {
        Player* player = Owner(aura->GetCaster());
        if (!player)
            return;
        if (Family(aura->GetSpellInfo(), 0, 536870912))
            duration = 250 * Spirits(player);
        if (aura->GetId() == Frenzy)
            duration = 4000 * Spirits(player);
        if (Family(aura->GetSpellInfo(), 0, 8) && player->HasAura(VoodooMind))
            duration = duration * (100 + Spirits(player) * Amount(VoodooMind, EFFECT_1)) / 100;
    }

    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || player != spell->GetCaster() || !target)
            return;
        SpellInfo const* info = spell->GetSpellInfo();
        float factor = 1.0f;
        if (OwnedHex(player, target) && (IsJuju(info) || Family(info, 1, 32768 | 262144)))
        {
            int32 percent = player->HasAura(RitualTwo)   ? Amount(RitualTwo)
                            : player->HasAura(RitualOne) ? Amount(RitualOne)
                                                         : 0;
            factor *= 1.0f + float(percent) / 100;
        }
        if ((Family(info, 0, 4) || info->Id == ShadowflareHit) && player->HasAura(DarkEffigy) &&
            target->HasAura(Threads, player->GetGUID()))
            factor *= 1.5f;
        if (info->Id == Volley && player->HasAura(Gift))
            factor *= 1.0f + Spirits(player) * 0.02f;
        hit.damage = int32(hit.damage * factor);
        hit.damageBeforeTakenMods = int32(hit.damageBeforeTakenMods * factor);
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32 healing,
                          bool) override
    {
        Unit* caster = spell->GetCaster();
        if (target && miss == SPELL_MISS_NONE && !spell->IsTriggered() && !spell->GetSpellInfo()->IsPositive())
            if (Aura* aura = target->GetAura(spell->GetSpellInfo()->Id, caster->GetGUID()))
            {
                aura->SetScriptValue(ConcoctionsBuff, spell->GetScriptValue(ConcoctionsBuff));
                aura->SetScriptValue(ConcoctionsHeal, spell->GetScriptValue(ConcoctionsHeal));
            }
        if (damage && spell->GetScriptValue(ConcoctionsBuff))
        {
            Unit* doctor = ObjectAccessor::GetUnit(*caster, ObjectGuid(spell->GetScriptValue(ConcoctionsHeal)));
            Copy(doctor ? doctor : caster, caster, ConcoctionsHeal,
                 uint32(std::min<uint64>(UINT32_MAX, uint64(damage) * spell->GetScriptValue(ConcoctionsBuff) / 100)));
        }
        Player* player = Owner(caster);
        if (!player || player != caster || miss != SPELL_MISS_NONE || !target)
            return;
        SpellInfo const* info = spell->GetSpellInfo();
        uint32 id = info->Id;
        if (Family(info, 1, 131072))
        {
            HealThroughEffigies(player, target, healing);
            auto& state = State(player);
            if (!spell->IsTriggered() && state.previousBrew != target->GetGUID())
            {
                if (Unit* previous = ObjectAccessor::GetUnit(*player, state.previousBrew))
                    if (Friendly(player, previous) && player->IsWithinDistInMap(previous, 40.0f))
                        Copy(player, previous, LoaEchoHeal, healing / 2);
                state.previousBrew = target->GetGUID();
            }
            if (healing && player->HasAura(LoaBlessing))
            {
                uint32 blessings[] = {BlessingOne, BlessingTwo, BlessingThree, BlessingFour};
                Cast(player, target, blessings[urand(0, 3)]);
            }
        }
        if (healing && IsBottle(info))
        {
            uint32 count = 0;
            for (Unit* unit : Nearby(target, 5.0f))
                if (player->IsValidAttackTarget(unit))
                {
                    Copy(player, unit, BottleDamage, uint64(healing) * 4 / 100);
                    if (++count >= sSpellMgr->GetSpellInfo(BottleDamage)->MaxAffectedTargets)
                        break;
                }
        }
        if (Family(info, 1, 131072) || IsBottle(info))
            if (Aura* unstable = target->GetAura(UnstableDebuff, player->GetGUID()))
            {
                unstable->Remove();
                for (Unit* ally : Allies(player, target, 10.0f, 5))
                    Cast(player, ally, UnstableHeal);
            }
        if ((healing || target->IsAlive()) && (IsPotion(info) || IsSplash(info)))
        {
            uint32 mojo = spell->GetScriptValue(MojoThistle)   ? MojoThistle
                          : spell->GetScriptValue(MojoFish)    ? MojoFish
                          : spell->GetScriptValue(MojoShrooms) ? MojoShrooms
                                                               : 0;
            PotionEffects(player, target, IsSplash(info), mojo, uint32(spell->GetScriptValue(IngredientMarker)));
            if (IsPotion(info) && player->HasAura(Unstable))
                Cast(player, target, UnstableDebuff);
        }
        if (damage && IsArrow(info) && player->HasAura(Shadowhunter))
            Copy(player, player, DevotionHeal, uint64(damage) * 40 / 100);
        if (damage && IsArrow(info) && player->HasAura(Guile))
            Copy(player, target, GuileDamage, uint64(damage) * Amount(Guile, EFFECT_1) / 100);
        if (damage && IsJuju(info))
        {
            bool hexed = false;
            for (auto const& [key, app] : target->GetAppliedAuras())
                hexed |= IsHex(app->GetBase()->GetSpellInfo());
            if (hexed)
                Cast(player, target, MarkOfMalice);
            if (player->HasAura(Strings) && target->HasAura(Threads, player->GetGUID()))
                Copy(player, target, StringsDamage, uint64(damage) * 30 / 100);
        }
        if (damage && Family(info, 1, 262144) && player->HasAura(VoodooSpirits))
            if (Aura* threads = target->GetAura(Threads, player->GetGUID()))
            {
                Copy(player, target, ThreadsDamage, std::max(0, threads->GetEffect(EFFECT_0)->GetAmount()));
                threads->GetEffect(EFFECT_0)->ChangeAmount(0);
                threads->Remove();
                GainSpirit(player);
            }
        if (damage && (Family(info, 0, 4) || id == ShadowflareHit) && !target->IsAlive())
            GainSpirit(player);
        if (damage && id == BottleDamage && player->HasAura(Touch))
            Cast(player, target, TouchDebuff);
        if (id == Umbral)
            RefreshOwnedHex(player, target);
        if (id == RageBrew)
            Cast(player, target, RageBrewBuff);
        if (id == Shock && !target->IsPlayer())
            Cast(player, target, ShockInterrupt);
        if ((damage || healing) && id != Spirit && !Family(info, 0, 8) && !spell->IsTriggered())
            player->RemoveAurasDueToSpell(Mirage);
    }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (!spell->IsTriggered() && !info->IsPositive() && spell->GetScriptValue(ConcoctionsBuff))
            if (Aura* buff = caster->GetAura(ConcoctionsBuff))
                buff->DropCharge();
        if (!spell->IsTriggered())
        {
            std::vector<std::pair<ObjectGuid, uint32>> jinxes;
            for (auto const& [key, app] : caster->GetAppliedAuras())
                if (app->GetBase()->GetId() == MalignantJinx)
                    jinxes.emplace_back(app->GetBase()->GetCasterGUID(), app->GetBase()->GetId());
            for (auto const& [guid, id] : jinxes)
            {
                caster->RemoveAurasDueToSpell(id, guid);
                if (Unit* doctor = ObjectAccessor::GetUnit(*caster, guid))
                    Cast(doctor, caster, JinxSilence);
            }
        }
        Player* player = Owner(caster);
        if (!player || player != caster || spell->IsTriggered())
            return;
        uint32 id = info->Id;
        uint8 count = uint8(spell->GetScriptValue(Spirit));
        Unit* target = spell->m_targets.GetUnitTarget();
        if (Family(info, 1, 4) || id == Volley)
        {
            GainSpirit(player);
            if (Family(info, 1, 4) && id != Volley && player->HasAura(LoaEcho) && target && roll_chance_i(count * 5))
                Cast(player, target, id);
            if (id == Volley)
                Reduce(player, Glaive, std::abs(Amount(VolleyCooldown)));
        }
        if (IsArrow(info) && player->HasAura(SpiritHunting) && roll_chance_i(count * 15))
            GainSpirit(player);
        if ((IsArrow(info) || (Family(info, 1, 4) && id != Volley)) && player->HasAura(VolleyTalent) &&
            roll_chance_i(30))
            Cast(player, player, VolleyReady);
        if (Family(info, 1, 262144) && player->HasAura(HexfireAdept))
            Cast(player, player, HexfireReady);
        if (IsBottle(info) && player->HasAura(OutOfBottle))
            GainSpirit(player);
        if ((IsBottle(info) || IsPotion(info)) && player->HasAura(Senjin))
        {
            Cast(player, player, SenjinBuff);
            if (Aura* buff = player->GetAura(SenjinBuff))
                buff->SetCharges(2);
        }
        if (Family(info, 1, 131072) && player->HasAura(SplashOnEm))
            Reduce(player, Beam, 2000);
        if (id == Frenzy)
        {
            player->RemoveAurasDueToSpell(Spirit);
            SyncSpirits(player);
        }
        else if (Family(info, 0, 536870912))
        {
            if (count == 5 && player->HasAura(PriceToPay))
            {
                Reduce(player, Glaive, INT32_MAX);
                Cast(player, player, PriceReady);
            }
            if (player->HasAura(Dambala))
                Cast(player, player, DambalaReady);
        }
        if (id == Mirage)
            GainSpirit(player, 5);
        if (id == Slither)
        {
            player->RemoveMovementImpairingAuras(true);
            Cast(player, player, SlitherAvoid);
        }
        if (id == Shadowstalker || id == Mirage)
            Cast(player, player, StalkerSpeed);
        if (id == MojoThistle || id == MojoFish || id == MojoShrooms)
            Mix(player, id);
        if (id == Tiki)
            Cast(player, player, player->HasAura(Beast) ? TikiCrit : TikiShield);
        if (id == HexfireWrath && target)
            Summon(player, WrathWard, target, target->GetPosition());
        if (IsJuju(info) && player->HasAura(Unleashed))
            Reduce(player, Puppets, 5000);
        if (IsBeam(info) && player->HasAura(Wave))
            for (Unit* ally : Allies(player, player, 40.0f, 10))
                Cast(player, ally, Replenishment);
        auto consume = [spell, player](uint32 buff, bool eligible)
        {
            if (eligible && spell->GetScriptValue(buff))
                player->RemoveAurasDueToSpell(buff);
        };
        consume(MojoFree, true);
        consume(PriceReady, Family(info, 0, 33554432));
        if (Family(info, 0, 33554432) && spell->GetScriptValue(PriceReady))
            Reduce(player, Shadowstalker, std::abs(Amount(PriceCooldown)));
        consume(DambalaReady, Family(info, 0, 4));
        consume(TrueSpiritReady, Family(info, 0, 33554432 | 536870912));
        consume(OverflowBuff, IsJuju(info));
        consume(VolleyReady, id == Volley);
        consume(UmbralReady, id == Umbral);
        consume(HexfireReady, id == HexfireWrath);
        for (uint32 mojo : {MojoThistle, MojoFish, MojoShrooms})
            consume(mojo, IsPotion(info) || IsSplash(info));
        if (target)
            Mirror(player, target, id);
        SyncReplacements(player);
    }
};

class spell_ascension_witch_doctor_dark_incantation : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_doctor_dark_incantation);

    bool Validate(SpellInfo const* info) override
    {
        return Family(info, 0, 4) && ValidateSpellInfo({DarkIncantation, Hex});
    }

    void ApplyHex()
    {
        Player* player = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        if (!player || !target || !player->HasAura(DarkIncantation) || GetHitDamage() <= 0 ||
            player->IsFriendlyTo(target))
            return;

        if (_hitCount < _previous.size())
            _previous[_hitCount] = target->GetGUID();
        if (++_hitCount < 3)
            return;

        uint32 const hex = KnownRank(player, Hex);
        if (_hitCount == 3)
            for (ObjectGuid const& guid : _previous)
                if (Unit* previous = ObjectAccessor::GetUnit(*player, guid))
                    Cast(player, previous, hex);
        Cast(player, target, hex);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_ascension_witch_doctor_dark_incantation::ApplyHex);
    }

    std::array<ObjectGuid, 2> _previous{};
    uint32 _hitCount = 0;
};

class witch_doctor_spell_contracts : public GlobalScript
{
  public:
    witch_doctor_spell_contracts()
        : GlobalScript("witch_doctor_spell_contracts", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR})
    {
    }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->Id != OverflowingJuju)
            return;

        if (info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_BONUS_MULTIPLIER &&
            info->Effects[EFFECT_0].SpellClassMask == flag96(4, 33792, 0))
            info->Effects[EFFECT_0].SpellClassMask = flag96(4 | 1024, 33792, 0);
    }
};
}
void AddAscensionWitchDoctorAbilityScripts()
{
    new witch_doctor_casts();
    RegisterSpellScript(spell_ascension_witch_doctor_dark_incantation);
    new witch_doctor_spell_contracts();
}
