/*
 * Garr with Ascension's spells.
 *
 * coa_boss_schedule only ever measured Fierce Blow for him (975011, the
 * "cannot be dodged or parried" hit every boss in this instance shares);
 * nothing in the 42-log corpus caught the rest of his kit. CoaBossAI's own
 * header says a boss that needs adds "keeps its own script" - Garr manages
 * Firesworn, so he gets one, read from db.exil.es's kit export and
 * Spell.dbc (id, description, effect, aura, target) since no combat log
 * ever caught these:
 *
 *   Fierce Blow         tank, first 12s,  every 8.2s   (measured)
 *   Harden               self, every 20s                (designed)
 *     Stacking self-buff ("Garr continues to harden his body, reducing
 *     damage taken"); stops while cracked.
 *   Land Slide           self, first 20s, every 30s      (designed)
 *     A dummy (2105508, self-targeted) followed by its own D0 damage
 *     payload (2105509); 2105510-12 are the clean Heroic/Mythic/Ascended
 *     siblings and get their own SpellDifficulty grouping in this change's
 *     SQL, so the core resolves the right one by itself - the same
 *     dummy-then-effect shape coa_boss_ai uses for the rest of this
 *     instance's casts.
 *   Unstoppable Force    self, first 45s, every 45s      (designed)
 *     "Garr slams into a wall with such force that he cracks himself,
 *     creating a Firesworn." Drops Harden, applies Cracked and Earth Fury
 *     (Spell.dbc: +damage taken / +damage done while cracked) for a 20s
 *     designed recovery, and summons an extra Firesworn.
 *
 * Firesworn (12099, npc_garr_firesworn) keep their own untouched script.
 */

#include "CreatureScript.h"
#include "ScriptedCreature.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/MoltenCore/molten_core.h"

namespace
{
    enum GarrSpells
    {
        SPELL_FIERCE_BLOW       = 975011,
        SPELL_HARDEN            = 2105501,
        SPELL_EARTH_FURY        = 2105502,
        SPELL_CRACKED           = 2105503,
        SPELL_LAND_SLIDE        = 2105508,
        SPELL_LAND_SLIDE_DAMAGE = 2105509,
        SPELL_UNSTOPPABLE_FORCE = 2105515,
    };

    enum GarrEvents
    {
        EVENT_FIERCE_BLOW = 1,
        EVENT_HARDEN,
        EVENT_LAND_SLIDE,
        EVENT_UNSTOPPABLE_FORCE,
        EVENT_RECOVER,
    };

    struct boss_garr_coa : public BossAI
    {
        boss_garr_coa(Creature* creature) : BossAI(creature, DATA_GARR) { }

        void Reset() override
        {
            _Reset();
            _cracked = false;
            _landSlidePending = false;
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _JustEngagedWith();
            events.ScheduleEvent(EVENT_FIERCE_BLOW, 12s);
            events.ScheduleEvent(EVENT_HARDEN, 5s);
            events.ScheduleEvent(EVENT_LAND_SLIDE, 20s);
            events.ScheduleEvent(EVENT_UNSTOPPABLE_FORCE, 45s);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            // The dummy finished: cast the payload it stood for, same
            // shape as coa_boss_ai's own dummy-then-effect casts.
            if (!_landSlidePending || spell->Id != sSpellMgr->GetSpellIdForDifficulty(SPELL_LAND_SLIDE, me))
                return;

            _landSlidePending = false;
            me->CastSpell(me, SPELL_LAND_SLIDE_DAMAGE, true);
        }

        void ExecuteEvent(uint32 eventId) override
        {
            switch (eventId)
            {
                case EVENT_FIERCE_BLOW:
                    DoCastVictim(SPELL_FIERCE_BLOW);
                    events.Repeat(8200ms);
                    break;
                case EVENT_HARDEN:
                    if (!_cracked)
                        DoCastSelf(SPELL_HARDEN, true);
                    events.Repeat(20s);
                    break;
                case EVENT_LAND_SLIDE:
                    _landSlidePending = true;
                    if (me->CastSpell(me, SPELL_LAND_SLIDE, false) != SPELL_CAST_OK)
                        _landSlidePending = false;
                    events.Repeat(30s);
                    break;
                case EVENT_UNSTOPPABLE_FORCE:
                    DoCastSelf(SPELL_UNSTOPPABLE_FORCE, true);
                    me->RemoveAurasDueToSpell(SPELL_HARDEN);
                    DoCastSelf(SPELL_CRACKED, true);
                    DoCastSelf(SPELL_EARTH_FURY, true);
                    _cracked = true;
                    DoSummon(NPC_FIRESWORN, me->GetPosition());
                    events.ScheduleEvent(EVENT_RECOVER, 20s);
                    events.Repeat(45s);
                    break;
                case EVENT_RECOVER:
                    me->RemoveAurasDueToSpell(SPELL_CRACKED);
                    me->RemoveAurasDueToSpell(SPELL_EARTH_FURY);
                    _cracked = false;
                    break;
            }
        }

    private:
        bool _cracked = false;
        bool _landSlidePending = false;
    };
}

void AddCoaGarrScripts()
{
    RegisterMoltenCoreCreatureAI(boss_garr_coa);
}
