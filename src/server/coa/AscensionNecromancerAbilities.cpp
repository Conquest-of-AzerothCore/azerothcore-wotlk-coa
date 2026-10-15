/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionNecromancer.h"
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

namespace AscensionNecromancer
{
void CorpseExplosion(Player* player, Unit* center)
{
    std::list<Creature*> corpses;
    center->GetDeadCreatureListInGrid(corpses, 15.0f, true);
    for (Creature* corpse : corpses)
        if (corpse->getDeathState() == DeathState::Corpse && corpse->GetDisplayId() == corpse->GetNativeDisplayId() &&
            corpse->GetCreatureType() != CREATURE_TYPE_MECHANICAL &&
            corpse->GetCreatureType() != CREATURE_TYPE_ELEMENTAL && center->InSamePhase(corpse) &&
            center->IsWithinLOSInMap(corpse))
        {
            auto targets = Nearby(corpse, 10.0f);
            corpse->SendPlaySpellVisual(10290);
            corpse->SendPlaySpellVisual(220);
            bool halved = roll_chance_i(50);
            corpse->SetDisplayId(halved ? 25539 : 25538);
            if (halved)
                corpse->SetObjectScale(corpse->GetObjectScale() * 0.5f);
            for (Unit* target : targets)
                if (player->IsValidAttackTarget(target))
                    Copy(player, target, 533240, std::max(1, Amount(KnownRank(player, 533236), 0, player)));
        }
}
}
namespace
{
using namespace AscensionNecromancer;
void Ready(Player* player, uint32 id, uint8 charges = 1)
{
    Cast(player, player, id);
    if (Aura* aura = player->GetAura(id))
    {
        aura->SetCharges(charges);
        aura->SetScriptValue(805011, ++State(player).sequence);
    }
}
void Virulency(Player* player, Unit* target)
{
    if (!target || !target->IsAlive())
        return;
    auto& state = State(player);
    if (player->HasAura(803782) && !state.diseases.empty())
    {
        for (auto const& saved : state.diseases)
            if (Aura* copy = player->AddAura(saved.spell, target))
            {
                copy->SetStackAmount(saved.stacks);
                copy->SetMaxDuration(saved.maximum);
                copy->SetDuration(saved.duration);
                copy->SetScriptValue(801747, saved.permafrost);
                for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
                    if (AuraEffect* effect = copy->GetEffect(index))
                    {
                        effect->ChangeAmount(saved.amounts[index]);
                        effect->SetPeriodicTimer(saved.timers[index]);
                    }
            }
        if (Aura* infestation = player->GetAura(803782); infestation && infestation->GetCharges())
        {
            infestation->SetCharges(infestation->GetCharges() - 1);
            return;
        }
        state.diseases.clear();
        player->RemoveAurasDueToSpell(803782);
        player->SetTemporarySpellReplacement(801938, 0);
        return;
    }
    state.diseases.clear();
    for (auto const& [key, application] : target->GetAppliedAuras())
    {
        Aura* aura = application->GetBase();
        if (aura->GetCasterGUID() != player->GetGUID() || !Disease(aura->GetSpellInfo()))
            continue;
        aura->RefreshDuration();
        DiseaseSnapshot saved = {aura->GetId(),
                                 aura->GetStackAmount(),
                                 aura->GetDuration(),
                                 aura->GetMaxDuration(),
                                 aura->GetScriptValue(801747),
                                 {},
                                 {}};
        for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
            if (AuraEffect* effect = aura->GetEffect(index))
            {
                saved.amounts[index] = effect->GetAmount();
                saved.timers[index] = effect->GetPeriodicTimer();
            }
        state.diseases.push_back(saved);
    }
    if (!state.diseases.empty())
    {
        Cast(player, player, 803782);
        if (!player->HasSpell(803781))
            player->learnSpell(803781, true);
        player->SetTemporarySpellReplacement(801938, 803781);
    }
}
class necromancer_casts : public AllSpellScript
{
  public:
    necromancer_casts()
        : AllSpellScript("necromancer_casts",
                         {ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_CAST,
                          ALLSPELLHOOK_ON_CALC_MAX_DURATION, ALLSPELLHOOK_ON_SUCCESSFUL_INTERRUPT,
                           ALLSPELLHOOK_ON_CALCULATED_TARGET, ALLSPELLHOOK_ON_HIT_RESULT})
    {
    }
    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32, uint32,
                          bool) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || player != spell->GetCaster() || !target || miss != SPELL_MISS_NONE || spell->IsTriggered())
            return;
        if (Aura* aura = target->GetAura(spell->GetSpellInfo()->Id, player->GetGUID()))
        {
            aura->SetScriptValue(801747, spell->GetScriptValue(801747));
            if (Named(spell->GetSpellInfo(), 500217))
            {
                aura->SetScriptValue(359505, spell->GetScriptValue(359505));
                aura->SetScriptValue(500217, 1);
            }
        }
    }
    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || player != spell->GetCaster() || spell->IsTriggered() || result != SPELL_CAST_OK)
            return;
        SpellInfo const* info = spell->GetSpellInfo();
        uint32 id = info->Id;
        Unit* target = spell->m_targets.GetUnitTarget();
        if (player->HasAura(500730))
            result = SPELL_FAILED_CASTER_AURASTATE;
        if (Cost(player, id) && int32(Capacity(player)) - Used(player) < Cost(player, id))
            result = SPELL_FAILED_ALREADY_HAVE_SUMMON;
        if (Command(info) && (player->HasAura(500983) ||
            (!Named(info, 504868) && Minions(player).empty())))
            result = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        if ((id == 500443 || id == 801938) && !player->HasAura(803782) && !Diseases(player, target))
            result = SPELL_FAILED_TARGET_AURASTATE;
        if (id == 803781 && (!player->HasAura(803782) || State(player).diseases.empty()))
            result = SPELL_FAILED_CASTER_AURASTATE;
        if ((id == 704355 || (id >= 707399 && id <= 707402)) && target && !target->HasAuraState(AURA_STATE_FROZEN) &&
            !player->HasAura(801747))
            result = SPELL_FAILED_TARGET_AURASTATE;
        if (id == 802121 && Minions(player).empty())
            result = SPELL_FAILED_NO_PET;
        if (id == 807098)
        {
            bool ritual = false;
            for (auto const& row : State(player).minions)
                if (Creature* circle = ObjectAccessor::GetCreature(*player, row.guid))
                    ritual |= circle->GetEntry() == 575091 && circle->IsAlive() && player->IsInMap(circle) &&
                              player->InSamePhase(circle) && circle->GetOwnerGUID() == player->GetGUID();
            if (!ritual)
                result = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        }
    }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || player != caster)
            return;
        for (uint32 id : {801747, 800979, 707176, 807856, 572777})
            if (Aura* aura = player->GetAura(id))
            {
                if (!aura->GetScriptValue(805011))
                    aura->SetScriptValue(805011, ++State(player).sequence);
                spell->SetScriptValue(id, aura->GetScriptValue(805011));
            }
        if (SpellInfo const* parent = spell->GetTriggeredByAuraSpellInfo())
            if (Unit* target = spell->m_targets.GetUnitTarget())
                if (Aura const* aura = target->GetAura(parent->Id, player->GetGUID()))
                    if (aura->GetScriptValue(801747))
                        spell->SetScriptValue(801747, aura->GetScriptValue(801747));
        spell->SetScriptValue(359505, std::max(0, spell->GetPowerCost()));
        if (info->Id == 707592 || info->Id == 706450 || info->Id == 706662)
            spell->SetScriptValue(707592, 0);
    }
    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || !target)
            return;
        uint32 id = spell->GetSpellInfo()->Id;
        if (id == 706450 || id == 706662)
        {
            uint64 count = spell->GetScriptValue(707592);
            float factor = std::max(0.0f, 1.0f - 0.12f * count);
            hit.damage = int32(hit.damage * factor);
            hit.damageBeforeTakenMods = int32(hit.damageBeforeTakenMods * factor);
            spell->SetScriptValue(707592, count + 1);
        }
    }
    void OnCalcMaxDuration(Aura const* aura, int32& duration) override
    {
        Player* player = Owner(aura->GetCaster());
        if (!player)
            return;
        uint32 id = aura->GetId();
        if ((id == 803741 || id == 800706) && player->HasAura(302923))
            duration = duration * 125 / 100;
        if (aura->GetType() == UNIT_AURA_TYPE && aura->GetUnitOwner() && aura->GetUnitOwner()->IsPlayer())
        {
            if (id == 504845)
                duration = std::min(duration, 8000);
            if (id == 803741 || id == 800706)
                duration = std::min(duration, player->HasAura(302923) ? 9000 : 8000);
        }
    }
    void OnSpellSuccessfulInterrupt(Spell* spell, Unit* target) override
    {
        if (Player* player = Owner(spell->GetCaster()); player && Named(spell->GetSpellInfo(), 801739))
        {
            Cast(player, target, 803677);
        }
    }
    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = Owner(caster);
        if (!player || player != caster || spell->IsTriggered())
            return;
        uint32 id = info->Id;
        Unit* target = spell->m_targets.GetUnitTarget();
        auto consume = [spell, player](uint32 buff, bool eligible)
        {
            if (eligible && spell->GetScriptValue(buff))
                if (Aura* aura = player->GetAura(buff);
                    aura && aura->GetScriptValue(805011) == spell->GetScriptValue(buff))
                    aura->DropCharge();
        };
        consume(801747, true);
        consume(800979, Named(info, 801760));
        consume(707176, Lichfrost(info) || Family(info, 2, 8192));
        consume(807856, Lichfrost(info));
        consume(572777, Command(info));
        if (Chance(player, 704681))
            Ready(player, 801747, 2);
        if (Chance(player, 92122))
            Cast(player, player, 707421);
        if (player->HasAura(704723))
            Cast(player, player, 706504);
        if (Command(info))
        {
            if (Chance(player, 300940))
            {
                Reduce(player, 801760, INT32_MAX);
                Ready(player, 800979);
            }
            if (player->HasAura(300941))
                Reduce(player, 805029, std::abs(Amount(301238)));
            if (player->HasAura(561215))
            {
                std::vector<uint32> animates;
                for (auto const& [known, value] : player->GetSpellMap())
                    if (value->State != PLAYERSPELL_REMOVED)
                        if (SpellInfo const* summon = sSpellMgr->GetSpellInfo(known))
                            if (summon->SpellFamilyName == 29 &&
                                ((summon->HasEffect(SPELL_EFFECT_SUMMON) && !Raised(summon)) ||
                                 Named(summon, 805040) || Named(summon, 504315)))
                                animates.push_back(known);
                for (uint32 animate : animates)
                    player->ModifySpellCooldown(animate, -std::abs(Amount(302910, 1)));
            }
            if (player->HasAura(704701))
            {
                Cast(player, player, 302516);
                if (player->GetAuraCount(302516) >= 10)
                {
                    player->RemoveAurasDueToSpell(302516);
                    std::vector<uint32> animates;
                    for (uint32 animate : {805032, 805044, 805048})
                        if (player->HasSpell(animate))
                            animates.push_back(animate);
                    if (!animates.empty())
                        Reduce(player, animates[urand(0, uint32(animates.size() - 1))], std::abs(Amount(302517)));
                    Summon(player, 525380, target, player->GetPosition());
                }
            }
            if (Chance(player, 707175))
                Ready(player, 707176);
            if (Chance(player, 704724))
                Ready(player, 572777);
            if (Chance(player, 805649))
                player->EnergizeBySpell(player, 359505, int32(spell->GetScriptValue(359505)), POWER_RUNIC_POWER);
            uint32 count = ++State(player).commands;
            if (count % 3 == 0)
            {
                if (target && player->HasAura(801733))
                    Cast(player, target, 704860);
                if (player->HasAura(803797))
                    Ready(player, 807856);
            }
            if (target && player->IsValidAttackTarget(target))
            {
                if (player->HasAura(806328))
                    Plague(player, target);
                if (player->HasAura(806324))
                    Cast(player, target, 806325);
                if (player->HasAura(500572))
                {
                    uint32 countPlagues = 0;
                    uint32 maximum = std::max(1u, sSpellMgr->GetSpellInfo(500573)->MaxAffectedTargets);
                    for (Unit* unit : Nearby(target, 10.0f))
                        if (player->IsValidAttackTarget(unit))
                        {
                            Plague(player, unit);
                            if (++countPlagues >= maximum)
                                break;
                        }
                }
                if (player->HasAura(707133))
                    for (uint8 stack = 0; stack < 3; ++stack)
                        Cast(player, target, 707133);
                if (player->HasAura(705754))
                    Cast(player, target, 500443);
            }
        }
        if ((Command(info) || (info->HasEffect(SPELL_EFFECT_SUMMON) && !Raised(info))) && player->HasAura(805674))
            BuffArmy(player, 805786, true);
        if (id == 805029)
        {
            if (player->HasAura(805427))
                Summon(player, 805426, target, player->GetPosition(),
                       player->GetAura(805029) ? player->GetAura(805029)->GetDuration() : info->GetDuration());
            if (player->HasAura(704721))
                for (int32 i = 0; i < std::min(10, Amount(302912)); ++i)
                    Summon(player, 525380, target, player->GetPosition());
        }
        if (id == 801938 && player->HasAura(805675))
            Cast(player, player, 573223);
    }
};

class spell_ascension_necromancer_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_necromancer_ability);
    bool _handled = false;
    void Hit(SpellEffIndex index)
    {
        Player* player = Owner(GetCaster());
        if (!player || player != GetCaster())
            return;
        uint32 id = GetSpellInfo()->Id;
        if (id == 805031 || id == 801545 || id == 525388)
            return;
        PreventHitDefaultEffect(index);
        if (_handled)
            return;
        _handled = true;
        Unit* target = GetExplTargetUnit();
        if (Command(GetSpellInfo()) || id == 500991 || id == 805871)
            Order(player, target, id);
        if (id == 570132)
            Plague(player, target);
        if (id == 801938 || id == 803781)
            Virulency(player, target);
        if (Named(GetSpellInfo(), 533236))
            CorpseExplosion(player, player);
        if (Family(GetSpellInfo(), 2, 67108864))
        {
            for (Creature* minion : Minions(player))
            {
                int32 heal = Amount(id, 0, player);
                if (player->HasAura(704684))
                    heal = player->CountPctFromMaxHealth(Amount(704684));
                minion->KillSelf();
                Copy(player, player, 805031, std::max(1, heal), 1);
            }
            Sync(player);
        }
        if (id == 802121)
        {
            uint64 stolen = 0;
            for (Creature* unit : Minions(player))
            {
                uint32 sacrifice = CalculatePct(unit->GetHealth(), 40);
                unit->ModifyHealth(-int32(sacrifice));
                stolen += sacrifice;
            }
            Copy(player, player, 802122, uint32(std::min<uint64>(INT32_MAX, stolen / 2)));
        }
        if (id == 803767)
            player->ModifyHealth((player->GetMaxHealth() - player->GetHealth()) * 30 / 100);
        if (id == 803773)
            player->EnergizeBySpell(
                player, id, (player->GetMaxPower(POWER_MANA) - player->GetPower(POWER_MANA)) * 30 / 100, POWER_MANA);
        if (id == 500443 && target && Diseases(player, target))
        {
            Cast(player, target, 573233);
            if (player->HasAura(300236))
                ExtendWorms(player, target, Amount(300236) * 1000);
            if (target->HealthBelowPct(20) && player->HasAura(704598))
                Spread(player, target, false, false, 3);
        }
        if (id == 807098)
            for (auto const& row : State(player).minions)
                if (Creature* ritual = ObjectAccessor::GetCreature(*player, row.guid))
                    if (ritual->GetEntry() == 575091 && ritual->IsAlive() && player->IsInMap(ritual) &&
                        player->InSamePhase(ritual) && ritual->GetOwnerGUID() == player->GetGUID())
                    {
                        player->NearTeleportTo(ritual->GetPositionX(), ritual->GetPositionY(), ritual->GetPositionZ(),
                                               ritual->GetOrientation());
                        Cast(player, player, 807125);
                        player->RemoveMovementImpairingAuras(true);
                        break;
                    }
    }
    void Filter(std::list<WorldObject*>& targets)
    {
        Player* player = Owner(GetCaster());
        if (!player)
        {
            targets.clear();
            return;
        }
        targets.remove_if([player](WorldObject* object)
                          { return !object->ToUnit() || !IsMinion(player, object->ToUnit()); });
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_necromancer_ability::Hit, EFFECT_ALL, SPELL_EFFECT_ANY);
        for (auto const& effect : sSpellMgr->GetSpellInfo(m_scriptSpellId)->Effects)
            if (effect.TargetA.GetTarget() == TARGET_UNIT_SRC_AREA_ALLY ||
                effect.TargetB.GetTarget() == TARGET_UNIT_SRC_AREA_ALLY)
            {
                OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_necromancer_ability::Filter,
                                                                          EFFECT_ALL, TARGET_UNIT_SRC_AREA_ALLY);
                break;
            }
    }
};

class aura_ascension_necromancer_transfer_life : public AuraScript
{
    PrepareAuraScript(aura_ascension_necromancer_transfer_life);

    bool Check(Unit* target)
    {
        Player* player = Owner(GetCaster());
        if (!player || !target || !target->IsAlive())
            return false;
        if (target == player)
            return true;
        if (!IsMinion(player, target, true))
            return false;
        auto count = GetAura()->GetApplicationMap().size();
        if (GetAura()->GetApplicationOfTarget(player->GetGUID()))
            --count;
        return GetAura()->GetApplicationOfTarget(target->GetGUID()) ||
            !GetSpellInfo()->MaxAffectedTargets || count < GetSpellInfo()->MaxAffectedTargets;
    }

    void Register() override
    {
        DoCheckAreaTarget += AuraCheckAreaTargetFn(aura_ascension_necromancer_transfer_life::Check);
    }
};
}
void AddAscensionNecromancerAbilityScripts()
{
    new necromancer_casts();
    RegisterSpellScript(spell_ascension_necromancer_ability);
    RegisterSpellScript(aura_ascension_necromancer_transfer_life);
}
