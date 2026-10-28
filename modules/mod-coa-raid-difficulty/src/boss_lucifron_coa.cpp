/*
 * Shadow of Lucifron (12268 + variants), the add the player remembers appearing
 * "a few seconds after the start of the fight" (report, this session).
 *
 * Lucifron himself keeps the generic `coa_boss_ai` engine (his own Impending Doom/
 * Curse of Lucifron/Suppressing Shadows/Shadow Bolt schedule, already measured and
 * validated on branch, is untouched) - CoaBossAI.cpp only grew one small, generic,
 * data-driven hook (rev_20260930_92): a boss entry can have a row in the dedicated
 * `coa_boss_summon` table naming a one-shot summon entry, delay and buff spell. This
 * file is only the add's own AI and the one spell script its kit needs; there is no
 * boss_lucifron_coa BossAI here on purpose.
 *
 * Evidence (Spell.dbc, read directly this session, coa-dbc-viewer):
 *  - 12268 has no static creature_spawn row anywhere in the export and no SUMMON
 *    effect exists anywhere in Lucifron's own kit (1604/579322/975011/2105201-07/
 *    2105212-13/2105218-23) that targets it - the "schedule row with a summon
 *    spell" the task preferred does not exist, hence the tiny generic hook above.
 *  - Kit (export creature.csv.gz, id 12268/112268/212268/312268): {579322, 975011,
 *    2105254, 2105255, 2105256, 2105257}. 579322 "Fetid Mark" and 975011 "Fierce
 *    Blow" are the same unmatched-kit-entries-stay-unused case as Ragnaros/
 *    Magmadar's body (no log or DBC evidence either casts here) - left unused.
 *  - 2105254 Shadow Bolt: SPELL_EFFECT_DUMMY on TARGET_UNIT_TARGET_ENEMY -> 2105255
 *    Shadow Bolt: SPELL_EFFECT_SCHOOL_DAMAGE, base points 1 (placeholder); already
 *    bound to real damage via coa_spell_damage_info 2105250-53 "Flamewaker - Shadow
 *    Bolt Damage Info" (rev_20260930_83) and spell_script_names ->
 *    spell_coa_damage_info_hit, so only the dummy needs a chain handler here.
 *  - 2105256 Shadow Cleave: SPELL_EFFECT_WEAPON_PERCENT_DAMAGE, base points 44,
 *    target enemy + a cone (EffectRadiusIndex 13) - direct cast, real effect, no
 *    dummy wrapper, no per-difficulty variant.
 *  - 2105257 Dark Sundering: SPELL_EFFECT_WEAPON_PERCENT_DAMAGE (44%) and
 *    SPELL_EFFECT_APPLY_AURA (SPELL_AURA_MOD_RESISTANCE_PCT, base points -11,
 *    misc value 1 = Physical), both on the current target, single spell, no
 *    dummy wrapper.
 *  - 2105223 "Shadow of Lucifron" (the buff, distinct from the creature of the
 *    same name): APPLY_AURA x2, SPELL_AURA_MOD_DAMAGE_PERCENT_DONE +39% school
 *    mask 32 (Shadow); effect 0 targets TARGET_UNIT_TARGET_ANY (the caster's
 *    spell target), effect 1 targets TARGET_UNIT_CASTER. Cast by Lucifron *at*
 *    the newly summoned Shadow, this lands the +39% on the Shadow (effect 0,
 *    its spell target) and on Lucifron himself (effect 1, the caster) in one
 *    cast - exactly "increases his and his master's Shadow damage done",
 *    confirming the DBC does support both targets from a single cast.
 *
 * Health, level, faction and model: creature_template's own health_min/max (1),
 * faction_template_id (0) and min/max_level (1) in the export are the same kind of
 * placeholder already documented for Magmadar's heads (rev_20260930_91) - not
 * usable. Designed instead: level 63/faction 54 copied from Lucifron (its master);
 * health is [designed] 25% of Lucifron's own per-player coa_boss_flex figures (the
 * nearest real ratio on record for a Lucifron-room reinforcement add is Flamewaker
 * Protector's own HealthModifier against Lucifron's, 57.7568/219.026 = 26.4%;
 * rounded to a clean 25% here). model_id 13031 in the export *is* measured and is
 * not a placeholder - it is Lucifron's own display id (mc-ascdb-report.md: "12118
 * Lucifron ... modelid1 13031"), so the Shadow is, literally, a shadow copy of him.
 *
 * Despawn: DoSummon() (from the generic engine) enrolls the Shadow in Lucifron's
 * own `summons` list, so BossAI::Reset()/JustDied() despawns it automatically on
 * a wipe or a kill, the same as every other MC add in this module.
 */

#include "CreatureScript.h"
#include "ScriptedCreature.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/MoltenCore/molten_core.h"

namespace
{
    enum ShadowOfLucifronSpells
    {
        SPELL_SHADOW_BOLT_DUMMY   = 2105254,
        SPELL_SHADOW_BOLT_HIT     = 2105255, // coa_spell_damage_info: 2105250-53
        SPELL_SHADOW_CLEAVE       = 2105256,
        SPELL_DARK_SUNDERING      = 2105257,
    };

    enum ShadowOfLucifronEvents
    {
        EVENT_SHADOW_BOLT = 1,
        EVENT_SHADOW_CLEAVE,
        EVENT_DARK_SUNDERING,
    };

    struct npc_shadow_of_lucifron_coa : public ScriptedAI
    {
        npc_shadow_of_lucifron_coa(Creature* creature) : ScriptedAI(creature) { }

        void JustEngagedWith(Unit* /*who*/) override
        {
            // Designed: no log or export data times this add's own kit; staggered so
            // the three casts do not all land on the same tick.
            events.ScheduleEvent(EVENT_SHADOW_BOLT, 3s);
            events.ScheduleEvent(EVENT_SHADOW_CLEAVE, 8s);
            events.ScheduleEvent(EVENT_DARK_SUNDERING, 12s);
        }

        void ExecuteEvent(uint32 eventId)
        {
            switch (eventId)
            {
                case EVENT_SHADOW_BOLT:
                    DoCastVictim(SPELL_SHADOW_BOLT_DUMMY);
                    events.Repeat(6s, 9s);
                    break;
                case EVENT_SHADOW_CLEAVE:
                    DoCastVictim(SPELL_SHADOW_CLEAVE);
                    events.Repeat(12s, 16s);
                    break;
                case EVENT_DARK_SUNDERING:
                    DoCastVictim(SPELL_DARK_SUNDERING);
                    events.Repeat(15s, 20s);
                    break;
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
                ExecuteEvent(eventId);

            DoMeleeAttackIfReady();
        }

    private:
        EventMap events;
    };
}

// 2105254 Shadow Bolt - Hit Dummy
class spell_shadow_of_lucifron_shadow_bolt : public SpellScript
{
    PrepareSpellScript(spell_shadow_of_lucifron_shadow_bolt);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_SHADOW_BOLT_HIT });
    }

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        if (Unit* caster = GetCaster())
            if (Unit* target = GetHitUnit())
                caster->CastSpell(target, SPELL_SHADOW_BOLT_HIT, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_shadow_of_lucifron_shadow_bolt::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

void AddCoaLucifronScripts()
{
    RegisterMoltenCoreCreatureAI(npc_shadow_of_lucifron_coa);

    RegisterSpellScript(spell_shadow_of_lucifron_shadow_bolt);
}
