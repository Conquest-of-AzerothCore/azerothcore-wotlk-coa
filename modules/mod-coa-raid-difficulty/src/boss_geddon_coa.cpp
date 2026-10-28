/*
 * Baron Geddon's Living Bomb (2105701 dummy -> 2105702..05 periodic carrier aura, ticking
 * 2105706 self-damage) explodes when the carrier aura expires naturally (not a dispel, not the
 * carrier's death). Ascension's combat logs (2026-05-28, 08-09, 08-16, 08-23) show one
 * "Living Bomb Explosion" per carrier at the aura-removal millisecond, dealt to the carrier
 * itself and to a pet standing within the hidden hit trigger's 5 yd (2105707, SpellRadius 8),
 * immediately followed by a "Burning Ground" aura on the same carrier at the same millisecond
 * (2026-05-28 fight 317: Ascended 2105716; 2026-08-16/08-23 fights 1630/1752: Mythic 2105715).
 * The DBC carries the whole kit: the per-difficulty explosion 2105708/09/10/11 (damage is its
 * own EffectBasePoints/EffectDieSides), 2105712 Knock Up (vertical KNOCK_BACK plus Feather
 * Fall), and the per-difficulty ground fire 2105713/14/15/16 (SPELL_EFFECT_PERSISTENT_AREA_AURA,
 * SpellRadius 7 = 2 yd, SPELL_AURA_PERIODIC_DAMAGE every 1000 ms, DBC damage 800/1067/1333/1600).
 * Only the trigger on expiry is missing, so it casts those spells: carrier aura id 2105702 + n
 * maps to explosion 2105708 + n and to ground fire 2105713 + n.
 *
 * Inferno's per-wave damage (2105741 Normal, 2105742 Heroic, 2105743 Mythic, 2105744 Ascended,
 * grouped by SpellDifficulty.dbc row 2119, EffectTriggerSpell[1] of the channel 2105740) is real
 * DBC damage, not a placeholder; it cannot be edited in the DBC itself. The user judged it too
 * light on Ascended (near-zero raid frame drops, no deaths to it) and asked for +20% on every
 * difficulty, since nothing in the data distinguishes one tier as already correct. The single
 * tunable is INFERNO_DAMAGE_MULTIPLIER below.
 *
 * Each Inferno wave also gives Geddon one charge of Heating Up (2105746, +1% damage per charge):
 * in the four logged pulls the aura (first) or the dose (after) lands 1-3 ms after every Inferno
 * damage wave, 10 per Inferno and 60.0s apart, 50 charges at the end of a 285s pull.
 */

#include "Cell.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "Unit.h"

#include <list>

namespace
{
    enum GeddonLivingBombSpells
    {
        SPELL_LIVING_BOMB_CARRIER_NORMAL   = 2105702,
        SPELL_LIVING_BOMB_EXPLOSION_NORMAL = 2105708,
        SPELL_LIVING_BOMB_KNOCK_UP         = 2105712,
        SPELL_LIVING_BOMB_BURNING_GROUND_NORMAL = 2105713,
        SPELL_HEATING_UP                   = 2105746,
    };

    constexpr float EXPLOSION_RADIUS = 5.0f;

    constexpr float INFERNO_DAMAGE_MULTIPLIER = 1.20f;

    class spell_geddon_living_bomb_explosion_coa : public AuraScript
    {
        PrepareAuraScript(spell_geddon_living_bomb_explosion_coa);

        void HandleExpire(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            AuraApplication const* application = GetTargetApplication();
            if (!application || application->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
                return;

            Unit* carrier = GetTarget();
            Unit* source = GetCaster();
            if (!carrier || !source)
                return;

            uint32 const offset = GetId() - SPELL_LIVING_BOMB_CARRIER_NORMAL;
            uint32 const explosion = SPELL_LIVING_BOMB_EXPLOSION_NORMAL + offset;
            uint32 const burningGround = SPELL_LIVING_BOMB_BURNING_GROUND_NORMAL + offset;

            std::list<Unit*> targets;
            Acore::AnyUnfriendlyUnitInObjectRangeCheck check(carrier, source, EXPLOSION_RADIUS);
            Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(carrier, targets, check);
            Cell::VisitObjects(carrier, searcher, EXPLOSION_RADIUS);

            for (Unit* target : targets)
                source->CastSpell(target, explosion, true);

            source->CastSpell(carrier, SPELL_LIVING_BOMB_KNOCK_UP, true);
            source->CastSpell(carrier->GetPositionX(), carrier->GetPositionY(), carrier->GetPositionZ(), burningGround, true);
        }

        void Register() override
        {
            AfterEffectRemove += AuraEffectRemoveFn(spell_geddon_living_bomb_explosion_coa::HandleExpire, EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE, AURA_EFFECT_HANDLE_REAL);
        }
    };

    class spell_geddon_inferno_damage_coa : public SpellScript
    {
        PrepareSpellScript(spell_geddon_inferno_damage_coa);

        void ScaleDamage(SpellEffIndex /*effIndex*/)
        {
            SetHitDamage(int32(GetHitDamage() * INFERNO_DAMAGE_MULTIPLIER));
        }

        void AddHeatingUp()
        {
            if (Unit* caster = GetCaster())
                caster->CastSpell(caster, SPELL_HEATING_UP, true);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_geddon_inferno_damage_coa::ScaleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
            AfterCast += SpellCastFn(spell_geddon_inferno_damage_coa::AddHeatingUp);
        }
    };
}

void AddCoaGeddonScripts()
{
    RegisterSpellScript(spell_geddon_living_bomb_explosion_coa);
    RegisterSpellScript(spell_geddon_inferno_damage_coa);
}
