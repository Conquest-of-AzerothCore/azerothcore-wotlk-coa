/*
 * Jin'do the Hexxer with Ascension's spells.
 *
 * Kit: Ascension's block 2118500-2118562. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json.
 *
 *   Delusions of Jin'do   first 14s, every 20s    random player: sees the
 *                                                 Other Side, a Shade of Jin'do
 *                                                 hunts them, Shadow damage every
 *                                                 5s that doubles every 10s,
 *                                                 +350% damage against undead
 *   Brain Wash Totem      first 17s, every 60s    the totem takes over a player
 *   Animate Bones         first 23s, every 30s    the Sacrificed Trolls in the
 *                                                 Blood Pit rise again
 *   Healing Stream Totem  first 202s, every 120s  heals him while it stands
 *   Friends On the Other Side  +2% damage for every shade alive
 *
 * From stock: the shade, the totems, the teleport into the pit (Banish) and
 * Hex, and the dance when the raid wipes.
 *
 * Decided here, not in the data:
 *   - the totems are stock creatures and do what they did in stock (the brain
 *     wash is a mind control, the ward heals); Ascension's cast bars start them;
 *   - Hex and the teleport stay: instant casts do not show in the video, and
 *     Animate Bones only makes sense with players sent into the pit;
 *   - Seeking Shadow Bolts (in the block, never seen) is left out.
 */

#include "CreatureScript.h"
#include "GameTime.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "TaskScheduler.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

#include <list>
#include <map>

using namespace coa_zg;

namespace
{
    enum Say
    {
        SAY_AGGRO = 1
    };

    enum Spells
    {
        SPELL_BRAIN_WASH_TOTEM         = 24262,
        SPELL_POWERFULL_HEALING_WARD   = 24309,
        SPELL_HEX                      = 17172,
        SPELL_SUMMON_SHADE_OF_JINDO    = 24308,
        SPELL_BANISH                   = 24466,

        SPELL_SUMMON_BRAIN_WASH        = 2118501,
        SPELL_SUMMON_HEALING_STREAM    = 2118503,
        SPELL_DELUSIONS                = 2118510,
        SPELL_DELUSIONS_VISION         = 2118511,
        SPELL_DELUSIONS_DOT            = 2118512,
        SPELL_FRIENDS_ON_THE_OTHER_SIDE = 2118518,
        SPELL_ANIMATE_BONES            = 2118560,
    };

    enum Events
    {
        EVENT_DELUSIONS = 1,
        EVENT_BRAIN_WASH,
        EVENT_ANIMATE_BONES,
        EVENT_HEALING_STREAM,
        EVENT_HEX,
        EVENT_TELEPORT,
        EVENT_DELUSIONS_GROW,
    };

    constexpr Milliseconds DELUSIONS_DOUBLING = 10s;

    struct boss_jindo_coa : public BossAI
    {
        boss_jindo_coa(Creature* creature) : BossAI(creature, DATA_JINDO) { }

        void Reset() override
        {
            BossAI::Reset();
            _delusions.clear();
            _shades = 0;
            me->RemoveAurasDueToSpell(SPELL_FRIENDS_ON_THE_OTHER_SIDE);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(SAY_AGGRO);
            me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NONE);
            _scheduler.CancelAll();

            events.ScheduleEvent(EVENT_TELEPORT, 5s);
            events.ScheduleEvent(EVENT_HEX, 8s);
            events.ScheduleEvent(EVENT_DELUSIONS, 14s);
            events.ScheduleEvent(EVENT_BRAIN_WASH, 17s);
            events.ScheduleEvent(EVENT_ANIMATE_BONES, 23s);
            events.ScheduleEvent(EVENT_HEALING_STREAM, 202s);
            events.ScheduleEvent(EVENT_DELUSIONS_GROW, 1s);
        }

        void JustSummoned(Creature* summon) override
        {
            BossAI::JustSummoned(summon);
            if (summon->GetEntry() == NPC_BRAIN_WASH_TOTEM)
            {
                summon->SetReactState(REACT_PASSIVE);
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, me->GetThreatMgr().GetThreatListSize() > 1 ? 1 : 0))
                    summon->CastSpell(target, summon->m_spells[0], true);
            }
        }

        // +2% damage per shade alive.
        void UpdateFriends()
        {
            // The shades are summoned by the cursed players, not by him.
            std::list<Creature*> found;
            me->GetCreatureListWithEntryInGrid(found, NPC_SHADE_OF_JINDO, 200.0f);
            uint8 shades = 0;
            for (Creature* c : found)
                if (c->IsAlive())
                    ++shades;
            if (shades == _shades)
                return;
            _shades = shades;

            me->RemoveAurasDueToSpell(SPELL_FRIENDS_ON_THE_OTHER_SIDE);
            if (!shades)
                return;
            // CastCustomSpell adds the spell's one point of dice on top.
            int32 bonus = Info(me, SPELL_FRIENDS_ON_THE_OTHER_SIDE, 1) * shades - 1;
            me->CastCustomSpell(me, SPELL_FRIENDS_ON_THE_OTHER_SIDE, nullptr, &bonus, nullptr, true);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_DELUSIONS:
                    if (Unit* target = ObjectAccessor::GetUnit(*me, _target))
                    {
                        me->AddAura(SPELL_DELUSIONS_VISION, target);
                        me->CastSpell(target, SPELL_DELUSIONS_DOT, true);
                        target->CastSpell(target, SPELL_SUMMON_SHADE_OF_JINDO, true);
                        _delusions[target->GetGUID()] = GameTime::GetGameTimeMS();
                    }
                    break;
                case SPELL_SUMMON_BRAIN_WASH:
                    DoCastSelf(SPELL_BRAIN_WASH_TOTEM, true);
                    break;
                case SPELL_SUMMON_HEALING_STREAM:
                    DoCastSelf(SPELL_POWERFULL_HEALING_WARD, true);
                    break;
                case SPELL_ANIMATE_BONES:
                {
                    std::list<Creature*> trolls;
                    me->GetCreatureListWithEntryInGrid(trolls, NPC_SACRIFICED_TROLL, 150.0f);
                    for (Creature* troll : trolls)
                        if (!troll->IsAlive())
                            troll->Respawn(true);
                    break;
                }
                default:
                    break;
            }
        }

        // The Delusions damage doubles every 10 seconds on each target.
        void GrowDelusions()
        {
            uint32 const now = GameTime::GetGameTimeMS().count();
            for (auto it = _delusions.begin(); it != _delusions.end();)
            {
                Unit* target = ObjectAccessor::GetUnit(*me, it->first);
                AuraEffect* dot = target ? target->GetAuraEffect(sSpellMgr->GetSpellIdForDifficulty(SPELL_DELUSIONS_DOT, me), EFFECT_0) : nullptr;
                if (!dot)
                {
                    it = _delusions.erase(it);
                    continue;
                }
                uint32 const steps = (now - uint32(it->second.count())) / uint32(DELUSIONS_DOUBLING.count());
                int32 const base = Info(me, SPELL_DELUSIONS_DOT);
                int32 const wanted = base << std::min<uint32>(steps, 5);
                if (dot->GetAmount() != wanted)
                    dot->ChangeAmount(wanted);
                ++it;
            }
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            if (CreatureAI::_EnterEvadeMode(why))
            {
                Reset();
                me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_DANCE);
                _scheduler.Schedule(4s, [this](TaskContext)
                {
                    me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NONE);
                    me->AddUnitState(UNIT_STATE_EVADE);
                    me->GetMotionMaster()->MoveTargetedHome();
                });
            }
        }

        void UpdateAI(uint32 diff) override
        {
            _scheduler.Update(diff);

            if (!UpdateVictim())
                return;

            events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_DELUSIONS:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true, true, -int32(SPELL_DELUSIONS_VISION)))
                        {
                            _target = target->GetGUID();
                            DoCast(target, SPELL_DELUSIONS);
                        }
                        events.ScheduleEvent(EVENT_DELUSIONS, 20s);
                        break;
                    case EVENT_BRAIN_WASH:
                        DoCastSelf(SPELL_SUMMON_BRAIN_WASH);
                        events.ScheduleEvent(EVENT_BRAIN_WASH, 60s);
                        break;
                    case EVENT_ANIMATE_BONES:
                        DoCastSelf(SPELL_ANIMATE_BONES);
                        events.ScheduleEvent(EVENT_ANIMATE_BONES, 30s);
                        break;
                    case EVENT_HEALING_STREAM:
                        DoCastSelf(SPELL_SUMMON_HEALING_STREAM);
                        events.ScheduleEvent(EVENT_HEALING_STREAM, 120s);
                        break;
                    case EVENT_HEX:
                        if (me->GetThreatMgr().GetThreatListSize() > 1)
                            DoCastVictim(SPELL_HEX, true);
                        events.ScheduleEvent(EVENT_HEX, 12s, 20s);
                        break;
                    case EVENT_TELEPORT:
                        DoCastRandomTarget(SPELL_BANISH);
                        events.ScheduleEvent(EVENT_TELEPORT, 15s, 23s);
                        break;
                    case EVENT_DELUSIONS_GROW:
                        GrowDelusions();
                        UpdateFriends();
                        events.ScheduleEvent(EVENT_DELUSIONS_GROW, 1s);
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
        TaskScheduler _scheduler;
        ObjectGuid _target;
        std::map<ObjectGuid, Milliseconds> _delusions;
        uint8 _shades = 0;
    };
}

void AddCoaJindoScripts()
{
    RegisterZulGurubCreatureAI(boss_jindo_coa);
}
