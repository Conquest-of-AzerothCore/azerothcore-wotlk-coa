/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "CreatureScript.h"
#include "ObjectAccessor.h"
#include "ScriptedCreature.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "molten_core.h"
#include <list>

enum Texts
{
    EMOTE_MASS_ERRUPTION                = 0,
};

enum Spells
{
    // Garr
    SPELL_ANTIMAGIC_PULSE               = 19492,    // Dispels magic on nearby enemies, removing 1 beneficial spell
    SPELL_MAGMA_SHACKLES                = 19496,    // Reduces the movement speed of nearby enemies by 60%
    SPELL_SEPARATION_ANXIETY            = 23487,    // Garr's aura on the Firesworn; one over 40 yd casts 23492
    SPELL_FRENZY                        = 19516,    // Increases the caster's attack speed by 9 + scale. Stacks up to 10 times

    // Fireworn
    SPELL_SEPARATION_ANXIETY_MINION     = 23492,    // Increases damage done by 300% and applied banish immunity
    SPELL_ERUPTION                      = 19497,    // Deals fire aoe damage and knockbacks nearby enemies
    SPELL_MASSIVE_ERUPTION              = 20483,    // Deals fire aoe damage, knockbacks nearby enemies and kills caster
    SPELL_ERUPTION_TRIGGER              = 20482,    // Removes banish auras and applied immunity to banish (server side)
    SPELL_ENRAGE_TRIGGER                = 19515,    // Server side. Triggers 19516 on hit
};

enum Events
{
    EVENT_ANTIMAGIC_PULSE               = 1,
    EVENT_MAGMA_SHACKLES,
};

struct boss_garr : public BossAI
{
    boss_garr(Creature* creature) : BossAI(creature, DATA_GARR),
        massEruptionTimer(600000)   // 10 mins
    {
    }

    void Reset() override
    {
        _Reset();
        massEruptionTimer = 600000;
    }

    void JustEngagedWith(Unit* /*attacker*/) override
    {
        _JustEngagedWith();
        DoCastSelf(SPELL_SEPARATION_ANXIETY, true);

        // The client defines Separation Anxiety as a plain aura with no tick, so Garr checks its holders every second.
        firesworn.clear();
        std::list<Creature*> nearby;
        me->GetCreatureListWithEntryInGrid(nearby, NPC_FIRESWORN, 100.0f);
        for (Creature* add : nearby)
            firesworn.insert(add->GetGUID());

        scheduler.CancelAll();
        scheduler.Schedule(1s, [this](TaskContext context)
        {
            for (ObjectGuid const& guid : firesworn)
                EnrageIfSeparated(ObjectAccessor::GetCreature(*me, guid));
            context.Repeat();
        });

        events.ScheduleEvent(EVENT_ANTIMAGIC_PULSE, 15s);
        events.ScheduleEvent(EVENT_MAGMA_SHACKLES, 10s);
        massEruptionTimer = 600000; // 10 mins
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        scheduler.Update(diff);

        // This should always process
        if (massEruptionTimer <= diff)
        {
            Talk(EMOTE_MASS_ERRUPTION, me);
            DoCastAOE(SPELL_ERUPTION_TRIGGER, true);
            massEruptionTimer = 20000;
        }
        else
        {
            massEruptionTimer -= diff;
        }

        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 const eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_ANTIMAGIC_PULSE:
                {
                    DoCastSelf(SPELL_ANTIMAGIC_PULSE);
                    events.Repeat(20s);
                    break;
                }
                case EVENT_MAGMA_SHACKLES:
                {
                    DoCastSelf(SPELL_MAGMA_SHACKLES);
                    events.Repeat(15s);
                    break;
                }
            }

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;
        }

        DoMeleeAttackIfReady();
    }

private:
    void EnrageIfSeparated(Creature* add)
    {
        if (add && add->IsAlive() && add->HasAura(SPELL_SEPARATION_ANXIETY, me->GetGUID()) &&
            add->GetDistance(me) > 40.0f && !add->HasAura(SPELL_SEPARATION_ANXIETY_MINION))
            add->CastSpell(add, SPELL_SEPARATION_ANXIETY_MINION, true);
    }

    uint32 massEruptionTimer;
    GuidSet firesworn;
};

struct npc_garr_firesworn : public ScriptedAI
{
    npc_garr_firesworn(Creature* creature) : ScriptedAI(creature) {}

    void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType /*damagetype*/, SpellSchoolMask /*damageSchoolMask*/ ) override
    {
        if (damage >= me->GetHealth())
        {
            // Prevent double damage because Firesworn can kill himself with Massive Eruption
            if (me != attacker)
                DoCastSelf(SPELL_ERUPTION, true);

            DoCastAOE(SPELL_ENRAGE_TRIGGER);
        }
    }
};

// Firesworn's on-death Eruption (19497, Mythic/Ascended sibling 350126) is a self-centered AoE whose
// DBC radius (SpellRadius.dbc id 12, 100 yd) covers effectively the whole Garr room; filtering it down
// here keeps the vanilla radius id untouched (it is shared by other, unrelated spells) while matching
// the encounter's own "dies, hits whoever is close to it" design. The radius is a flat, designed 12 yd
// exact distance (not a measured value): the prior combat-reach-relative melee-range filter (~7-9 yd
// for two average hitboxes) read as too small a zone per the user's own report.
class spell_firesworn_eruption_melee_coa : public SpellScript
{
    PrepareSpellScript(spell_firesworn_eruption_melee_coa);

    static constexpr float ERUPTION_RADIUS = 12.0f;

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        targets.remove_if([caster](WorldObject* target)
        {
            Unit* unit = target->ToUnit();
            return !unit || caster->GetExactDist(unit) > ERUPTION_RADIUS;
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_firesworn_eruption_melee_coa::FilterTargets, EFFECT_0, TARGET_UNIT_DEST_AREA_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_firesworn_eruption_melee_coa::FilterTargets, EFFECT_1, TARGET_UNIT_DEST_AREA_ENEMY);
    }
};

//19515 Frenzy (SERVERSIDE)
class spell_garr_frenzy : public SpellScript
{
    PrepareSpellScript(spell_garr_frenzy);

    bool Validate(SpellInfo const* /*spell*/) override
    {
        return ValidateSpellInfo({ SPELL_FRENZY });
    }

    void HandleHit(SpellEffIndex /*effIndex*/)
    {
        if (Unit* target = GetHitUnit())
            target->CastSpell(target, SPELL_FRENZY);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_garr_frenzy::HandleHit, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

void AddSC_boss_garr()
{
    RegisterMoltenCoreCreatureAI(boss_garr);
    RegisterMoltenCoreCreatureAI(npc_garr_firesworn);

    // Spells
    RegisterSpellScript(spell_garr_frenzy);
    RegisterSpellScript(spell_firesworn_eruption_melee_coa);
}
