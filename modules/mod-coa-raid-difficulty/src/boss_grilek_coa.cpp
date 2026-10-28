/*
 * Gri'lek (Edge of Madness) with Ascension's spells.
 *
 * Kit: Ascension's block 2118800-2118810. No cast bars in the video; the
 * timings are the Bronzebeard player's DBM bars and boss emotes:
 * "Gri'lek sets his sights on <player>!" with a 20s Fixate bar, and "Next
 * Ground Tremor" every 11-15s.
 *
 *   Relentless Pursuit  from the pull, a new player every 20s (at once when
 *                       the hunted one dies): he ignores everyone else
 *   Avatar              the whole fight: +100% damage, -50% speed, he is
 *                       meant to be kited
 *   Ground Slam         first 13s, every 13s   everyone: Physical damage and
 *                                              an 8s bleed (Trauma); those within
 *                                              20 yards are stunned 2s (Ground
 *                                              Tremor)
 *
 * Decided here, not in the data:
 *   - Avatar for the whole fight (the kit has it, the video cannot show when);
 *   - Ground Slam and Ground Tremor fire together: DBM calls the bar "Ground
 *     Tremor", the kit's damage is the slam;
 *   - the video sometimes shows two fixates at once; here there is one.
 * Hazza'rah, Renataki and Wushoolay keep stock: Ascension has no spells for them.
 */

#include "CreatureScript.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

using namespace coa_zg;

namespace
{
    enum Spells
    {
        SPELL_AVATAR             = 83068,
        SPELL_GROUND_TREMOR      = 6524,
        SPELL_PURSUIT            = 2118801,
        SPELL_TRAUMA             = 2118802,
        SPELL_GROUND_SLAM        = 2118806,
        SPELL_GROUND_SLAM_HIT    = 2118807,
    };

    enum Events
    {
        EVENT_PURSUIT = 1,
        EVENT_GROUND_SLAM,
    };

    constexpr float PURSUIT_THREAT = 1000000.0f;

    struct boss_grilek_coa : public BossAI
    {
        boss_grilek_coa(Creature* creature) : BossAI(creature, DATA_EDGE_OF_MADNESS) { }

        void Reset() override
        {
            StopPursuit();
            BossAI::Reset();
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            DoCastSelf(SPELL_AVATAR, true);
            events.ScheduleEvent(EVENT_PURSUIT, 1s);
            events.ScheduleEvent(EVENT_GROUND_SLAM, 13s);
        }

        void JustDied(Unit* killer) override
        {
            StopPursuit();
            BossAI::JustDied(killer);
        }

        void KilledUnit(Unit* victim) override
        {
            if (victim->GetGUID() == _hunted)
            {
                events.CancelEvent(EVENT_PURSUIT);
                events.ScheduleEvent(EVENT_PURSUIT, 1s);
            }
        }

        void StopPursuit()
        {
            if (Unit* hunted = ObjectAccessor::GetUnit(*me, _hunted))
            {
                hunted->RemoveAurasDueToSpell(SPELL_PURSUIT);
                if (me->GetThreatMgr().GetThreat(hunted) >= PURSUIT_THREAT)
                    me->GetThreatMgr().AddThreat(hunted, -PURSUIT_THREAT);
            }
            _hunted.Clear();
        }

        void Pursue()
        {
            Unit* previous = ObjectAccessor::GetUnit(*me, _hunted);
            StopPursuit();
            Unit* target = SelectTarget(SelectTargetMethod::Random, 0, [previous](Unit* u) { return u->IsPlayer() && u != previous; });
            if (!target)
                target = previous;
            if (!target || !target->IsAlive())
                return;

            _hunted = target->GetGUID();
            me->AddAura(SPELL_PURSUIT, target);
            me->GetThreatMgr().AddThreat(target, PURSUIT_THREAT);
            me->TextEmote("Gri'lek sets his sights on " + target->GetName() + "!", nullptr, true);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);
            if (spell->Id != SPELL_GROUND_SLAM)
                return;
            for (Player* p : Players(me, [](Player*) { return true; }))
            {
                me->CastSpell(p, SPELL_GROUND_SLAM_HIT, true);
                me->CastSpell(p, SPELL_TRAUMA, true);
            }
            DoCastSelf(SPELL_GROUND_TREMOR, true);
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_PURSUIT:
                        Pursue();
                        events.ScheduleEvent(EVENT_PURSUIT, 20s);
                        break;
                    case EVENT_GROUND_SLAM:
                        DoCastSelf(SPELL_GROUND_SLAM);
                        events.ScheduleEvent(EVENT_GROUND_SLAM, 13s);
                        break;
                    default:
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        ObjectGuid _hunted;
    };
}

void AddCoaGrilekScripts()
{
    RegisterZulGurubCreatureAI(boss_grilek_coa);
}
