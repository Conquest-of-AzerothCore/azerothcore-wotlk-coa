/*
 * Broodlord Lashlayer with Ascension's spells.
 *
 * No combat logs exist for Blackwing Lair; the kit is Ascension's (db.exil.es,
 * Spell.dbc), the timings were set with the raid designer:
 *
 *   Blast Wave      every 20s   20 yards around him, knockback, slow
 *   Mortal Strike   every 15s   on the tank
 *   Cleave          every 8s    cone in front
 *   Knock Away      every 30s   on the tank, and halves the tank's threat as
 *                               in stock
 *   Fierce Blow     every 8.5s  on the tank
 *   Arcane Bolt     every 2s, but only while no one is in melee range. It
 *                               comes from Ascension's shared bolt library, and
 *                               on a melee boss that reads as the answer to
 *                               being kited.
 *
 * What stays from stock: the leash at 150 yards and switching off the
 * suppression devices in the corridor when he dies.
 */

#include "CreatureScript.h"
#include "GameObject.h"
#include "GameObjectAI.h"
#include "Map.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/BlackwingLair/blackwing_lair.h"

#include <list>

namespace
{
    enum Say
    {
        SAY_AGGRO   = 0,
        SAY_LEASH   = 1
    };

    enum Spells
    {
        SPELL_FIERCE_BLOW   = 975011,
        SPELL_CLEAVE        = 2100004,
        SPELL_ARCANE_BOLT   = 2101036,
        SPELL_BLAST_WAVE    = 2101040,
        SPELL_MORTAL_STRIKE = 24573,
        SPELL_KNOCK_AWAY    = 25778,
    };

    enum Events
    {
        EVENT_CLEAVE = 1,
        EVENT_BLAST_WAVE,
        EVENT_MORTAL_STRIKE,
        EVENT_KNOCK_AWAY,
        EVENT_FIERCE_BLOW,
        EVENT_ARCANE_BOLT,
        EVENT_CHECK,
    };

    // The suppression devices' own action, from the stock script.
    constexpr int32 ACTION_DEACTIVATE = 0;

    constexpr float CLEAVE_RANGE = 10.0f;   // the spell's own radius
    constexpr float CLEAVE_ARC   = float(M_PI) / 2;
    constexpr float LEASH_RANGE  = 150.0f;

    struct boss_broodlord_coa : public BossAI
    {
        boss_broodlord_coa(Creature* creature) : BossAI(creature, DATA_BROODLORD_LASHLAYER) { }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(SAY_AGGRO);

            events.ScheduleEvent(EVENT_FIERCE_BLOW, 6s);
            events.ScheduleEvent(EVENT_CLEAVE, 8s);
            events.ScheduleEvent(EVENT_MORTAL_STRIKE, 15s);
            events.ScheduleEvent(EVENT_BLAST_WAVE, 20s);
            events.ScheduleEvent(EVENT_KNOCK_AWAY, 30s);
            events.ScheduleEvent(EVENT_ARCANE_BOLT, 2s);
            events.ScheduleEvent(EVENT_CHECK, 1s);
        }

        void JustDied(Unit* /*killer*/) override
        {
            _JustDied();

            std::list<GameObject*> devices;
            GetGameObjectListWithEntryInGrid(devices, me, GO_SUPPRESSION_DEVICE, 200.0f);
            for (GameObject* device : devices)
                device->AI()->DoAction(ACTION_DEACTIVATE);
        }

        void Cleave()
        {
            std::list<Player*> hit;
            me->GetMap()->DoForAllPlayers([&](Player* p)
            {
                if (p->IsAlive() && !p->IsGameMaster() && me->IsWithinDistInMap(p, CLEAVE_RANGE) && me->isInFront(p, CLEAVE_ARC))
                    hit.push_back(p);
            });
            for (Player* p : hit)
                me->CastSpell(p, SPELL_CLEAVE, true);
        }

        // Only when he cannot reach anyone.
        void ArcaneBolt()
        {
            bool anyoneInMelee = false;
            me->GetMap()->DoForAllPlayers([&](Player* p)
            {
                if (p->IsAlive() && !p->IsGameMaster() && me->IsWithinMeleeRange(p))
                    anyoneInMelee = true;
            });
            if (anyoneInMelee)
                return;

            if (Unit* target = SelectTarget(SelectTargetMethod::MinDistance, 0, 0.0f, true))
                DoCast(target, SPELL_ARCANE_BOLT);
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
                    case EVENT_FIERCE_BLOW:
                        DoCastVictim(SPELL_FIERCE_BLOW);
                        events.ScheduleEvent(EVENT_FIERCE_BLOW, 8500ms);
                        break;
                    case EVENT_CLEAVE:
                        Cleave();
                        events.ScheduleEvent(EVENT_CLEAVE, 8s);
                        break;
                    case EVENT_BLAST_WAVE:
                        DoCastSelf(SPELL_BLAST_WAVE);
                        events.ScheduleEvent(EVENT_BLAST_WAVE, 20s);
                        break;
                    case EVENT_MORTAL_STRIKE:
                        DoCastVictim(SPELL_MORTAL_STRIKE);
                        events.ScheduleEvent(EVENT_MORTAL_STRIKE, 15s);
                        break;
                    case EVENT_KNOCK_AWAY:
                        DoCastVictim(SPELL_KNOCK_AWAY);
                        if (DoGetThreat(me->GetVictim()))
                            DoModifyThreatByPercent(me->GetVictim(), -50);
                        events.ScheduleEvent(EVENT_KNOCK_AWAY, 30s);
                        break;
                    case EVENT_ARCANE_BOLT:
                        ArcaneBolt();
                        events.ScheduleEvent(EVENT_ARCANE_BOLT, 2s);
                        break;
                    case EVENT_CHECK:
                        if (me->GetDistance(me->GetHomePosition()) > LEASH_RANGE)
                        {
                            Talk(SAY_LEASH);
                            EnterEvadeMode();
                            return;
                        }
                        events.ScheduleEvent(EVENT_CHECK, 1s);
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }
    };
}

void AddCoaBroodlordScripts()
{
    RegisterBlackwingLairCreatureAI(boss_broodlord_coa);
}
