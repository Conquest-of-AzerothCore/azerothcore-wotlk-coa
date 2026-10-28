/*
 * Vaelastrasz the Corrupt, rebuilt as Ascension redesigned him.
 *
 * No combat logs exist for Blackwing Lair, so this fight is designed, not
 * measured - but here Ascension left an unusual amount in its DBC. The block
 * 2110600-2110645 spells out a fight the stock script knows nothing about:
 *
 *   Orbs of Corruption  a player who takes one gets Corruption, 10% more damage
 *                       taken per stack; if Vaelastrasz takes one, he deals
 *                       more damage instead. Every new stack breaks his
 *                       Concentrating.
 *   Concentrating       15 seconds on himself: 90% less damage taken, one
 *                       stack of Corruption washed off everyone every second,
 *                       and at the end Essence of the Red for the raid. In the
 *                       original that buff was free at the pull; here it is a
 *                       reward.
 *   Burning Adrenaline  120 seconds. Every second one more stack: +1% damage
 *                       done, and that many percent of current health as fire
 *                       damage. Dying with it explodes on everyone nearby.
 *                       Afterwards Burn Out: not again for a minute.
 *
 * The DBC holds the pieces; the script that tied them together is not in the
 * client. What is left to decide was decided with the raid designer:
 *
 *   orbs                3 every 30s, spread around him, drifting towards him
 *   Concentrating       every 60s, first after 30s
 *   Burning Adrenaline  every 20s, alternating a random player and the tank
 *   Rage Eruption       every 15s      Scorching Breath   every 12s
 *   Draconic Cleave     every 8s       Tail Sweep         every 20s
 *   Fierce Blow         every 8.5s
 *
 * The orb itself exists nowhere in Ascension's data. It is a new creature
 * (9780020), shown with the client's own void corruption orb model.
 *
 * The stock intro stays: the gossip, Nefarius's speech, the pull at 30% health.
 */

#include "CreatureScript.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/BlackwingLair/blackwing_lair.h"

#include <algorithm>
#include <functional>
#include <set>
#include <vector>

namespace
{
    constexpr float aNefariusSpawnLoc[4] = { -7466.16f, -1040.80f, 412.053f, 2.14675f };

    enum Says
    {
        SAY_LINE1       = 0,
        SAY_LINE2       = 1,
        SAY_LINE3       = 2,
        SAY_HALFLIFE    = 3,
        SAY_KILLTARGET  = 4
    };

    enum Spells
    {
        // stock intro
        SPELL_NEFARIUS_CORRUPTION       = 23642,
        SPELL_RED_LIGHTNING             = 19484,

        // Ascension
        SPELL_FIERCE_BLOW               = 975011,
        SPELL_DRACONIC_CLEAVE_CAST      = 2110601,
        SPELL_DRACONIC_CLEAVE           = 2110602,
        SPELL_TAIL_SWEEP_HIT            = 2110604,
        SPELL_SCORCHING_BREATH_CAST     = 2110606,
        SPELL_SCORCHING_BREATH          = 2110608,  // first of a tier row
        SPELL_SCORCHED                  = 2110612,  // first of a tier row
        SPELL_RAGE_ERUPTION             = 2110617,
        SPELL_BURNING_ADRENALINE        = 2110621,
        SPELL_BURNING_ADRENALINE_STACK  = 2110622,  // first of a tier row
        SPELL_BURNING_ADRENALINE_BURN   = 2110626,
        SPELL_BURN_OUT                  = 2110627,
        SPELL_BURNING_ADRENALINE_BLAST  = 2110628,  // first of a tier row
        SPELL_CORRUPTION_PLAYER         = 2110640,
        SPELL_CORRUPTION_VAEL           = 2110641,
        SPELL_CONCENTRATING             = 2110642,
        SPELL_CONCENTRATING_PULSE       = 2110643,
    };

    enum Npcs
    {
        NPC_CORRUPTION_ORB  = 9780020,
    };

    enum Actions
    {
        ACTION_CORRUPTION_GAINED = 100,
    };

    enum Events
    {
        EVENT_SPEECH_1 = 1,
        EVENT_SPEECH_2,
        EVENT_SPEECH_3,
        EVENT_SPEECH_4,
        EVENT_SPEECH_5,
        EVENT_SPEECH_6,
        EVENT_SPEECH_7,

        EVENT_FIERCE_BLOW,
        EVENT_CLEAVE,
        EVENT_TAIL_SWEEP,
        EVENT_SCORCHING_BREATH,
        EVENT_RAGE_ERUPTION,
        EVENT_BURNING_ADRENALINE,
        EVENT_CONCENTRATE,
        EVENT_ORBS,

        EVENT_BREATH_PULSE,
        EVENT_SECOND,
    };

    constexpr uint8  MAX_STACKS             = 100;
    constexpr float  CONE_ARC               = float(M_PI) / 2;
    constexpr float  CLEAVE_RANGE           = 20.0f;   // from the dummy's own radius
    constexpr float  BREATH_RANGE           = 20.0f;
    constexpr float  TAIL_RANGE             = 30.0f;   // from Tail Sweep's radius
    constexpr uint8  BREATH_PULSES          = 6;       // 3s aura, one pulse every 0.5s
    constexpr uint8  ORBS_PER_WAVE          = 3;
    constexpr float  ORB_SPAWN_MIN          = 12.0f;
    constexpr float  ORB_SPAWN_MAX          = 28.0f;

    // Sets an aura's stack count; adds the aura when it is missing and
    // removes it at zero. Several of these spells carry no stack limit in the
    // DBC and would otherwise just refresh.
    void SetStacks(Unit* caster, Unit* target, uint32 spellId, int32 stacks)
    {
        uint32 const id = sSpellMgr->GetSpellIdForDifficulty(spellId, caster);
        stacks = std::clamp<int32>(stacks, 0, MAX_STACKS);

        Aura* aura = target->GetAura(id);
        if (!stacks)
        {
            if (aura)
                target->RemoveAurasDueToSpell(id);
            return;
        }
        if (!aura)
        {
            caster->CastSpell(target, id, true);
            aura = target->GetAura(id);
        }
        if (aura)
            aura->SetStackAmount(uint8(stacks));
    }

    int32 Stacks(Unit* caster, Unit* target, uint32 spellId)
    {
        Aura* aura = target->GetAura(sSpellMgr->GetSpellIdForDifficulty(spellId, caster));
        return aura ? aura->GetStackAmount() : 0;
    }

    struct boss_vaelastrasz_coa : public BossAI
    {
        boss_vaelastrasz_coa(Creature* creature) : BossAI(creature, DATA_VAELASTRAZ_THE_CORRUPT)
        {
            Initialize();
        }

        void Initialize()
        {
            _playerGUID.Clear();
            _hasYelled = false;
            _introDone = false;
            _adrenalineOnTank = false;
            me->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            me->SetNpcFlag(UNIT_NPC_FLAG_QUESTGIVER);
            me->SetFaction(FACTION_FRIENDLY);
            me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        }

        void Reset() override
        {
            _Reset();
            CleanUpPlayers();
            _adrenaline.clear();
            _clock.Reset();
            me->SetHealth(me->CountPctFromMaxHealth(30));

            if (!_introDone)
            {
                me->SetStandState(UNIT_STAND_STATE_DEAD);
                me->SetReactState(REACT_PASSIVE);
                Initialize();
                _eventsIntro.Reset();
            }
            else
            {
                _hasYelled = false;
                _adrenalineOnTank = false;
            }
        }

        void JustDied(Unit* /*killer*/) override
        {
            _JustDied();
            CleanUpPlayers();
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            // No Essence of the Red at the pull: on Ascension it is earned.
            me->ResetPlayerDamageReq();

            events.ScheduleEvent(EVENT_FIERCE_BLOW, 6s);
            events.ScheduleEvent(EVENT_CLEAVE, 8s);
            events.ScheduleEvent(EVENT_SCORCHING_BREATH, 12s);
            events.ScheduleEvent(EVENT_RAGE_ERUPTION, 15s);
            events.ScheduleEvent(EVENT_TAIL_SWEEP, 20s);
            events.ScheduleEvent(EVENT_BURNING_ADRENALINE, 20s);
            events.ScheduleEvent(EVENT_ORBS, 20s);
            events.ScheduleEvent(EVENT_CONCENTRATE, 30s);
            // On its own clock, so a cast bar cannot hold it up.
            _clock.ScheduleEvent(EVENT_SECOND, 1s);
        }

        // Corruption and adrenaline stay on players otherwise.
        void CleanUpPlayers()
        {
            me->GetMap()->DoForAllPlayers([&](Player* player)
            {
                player->RemoveAurasDueToSpell(SPELL_CORRUPTION_PLAYER);
                player->RemoveAurasDueToSpell(SPELL_BURNING_ADRENALINE);
                for (uint32 id = SPELL_BURNING_ADRENALINE_STACK; id < SPELL_BURNING_ADRENALINE_STACK + 4; ++id)
                    player->RemoveAurasDueToSpell(id);
            });
        }

        void BeginSpeech(Unit* target)
        {
            _playerGUID = target->GetGUID();
            me->RemoveNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            _eventsIntro.ScheduleEvent(EVENT_SPEECH_1, 1s);
        }

        void KilledUnit(Unit* victim) override
        {
            if (!(rand32() % 5))
                Talk(SAY_KILLTARGET, victim);
        }

        void JustSummoned(Creature* summoned) override
        {
            if (summoned->GetEntry() == NPC_VICTOR_NEFARIUS)
            {
                summoned->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
                _nefariusGUID = summoned->GetGUID();
                return;
            }
            summons.Summon(summoned);
        }

        void sGossipSelect(Player* player, uint32 sender, uint32 action) override
        {
            if (sender == GOSSIP_ID && action == 0)
            {
                CloseGossipMenuFor(player);
                BeginSpeech(player);
            }
        }

        // An orb reached someone. Fresh corruption breaks his focus.
        void DoAction(int32 action) override
        {
            if (action == ACTION_CORRUPTION_GAINED)
                me->RemoveAurasDueToSpell(SPELL_CONCENTRATING);
        }

        // Each pulse of Concentrating washes one stack off every player it
        // reaches; the DBC's pulse is a dummy, so this is where that happens.
        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_CONCENTRATING_PULSE && target->IsPlayer())
                SetStacks(me, target, SPELL_CORRUPTION_PLAYER, Stacks(me, target, SPELL_CORRUPTION_PLAYER) - 1);
        }

        std::vector<Player*> Players(std::function<bool(Player*)> const& accept)
        {
            std::vector<Player*> out;
            me->GetMap()->DoForAllPlayers([&](Player* player)
            {
                if (player->IsAlive() && !player->IsGameMaster() && accept(player))
                    out.push_back(player);
            });
            return out;
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_DRACONIC_CLEAVE_CAST:
                    for (Player* p : Players([&](Player* x) { return me->IsWithinDistInMap(x, CLEAVE_RANGE) && me->isInFront(x, CONE_ARC); }))
                        me->CastSpell(p, SPELL_DRACONIC_CLEAVE, true);
                    break;
                case SPELL_SCORCHING_BREATH_CAST:
                    _breathPulses = BREATH_PULSES;
                    _clock.ScheduleEvent(EVENT_BREATH_PULSE, 0ms);
                    break;
                default:
                    break;
            }
        }

        void BreathPulse()
        {
            for (Player* p : Players([&](Player* x) { return me->IsWithinDistInMap(x, BREATH_RANGE) && me->isInFront(x, CONE_ARC); }))
            {
                me->CastSpell(p, SPELL_SCORCHING_BREATH, true);
                me->CastSpell(p, SPELL_SCORCHED, true);
            }
            if (--_breathPulses)
                _clock.ScheduleEvent(EVENT_BREATH_PULSE, 500ms);
        }

        void TailSweep()
        {
            for (Player* p : Players([&](Player* x) { return me->IsWithinDistInMap(x, TAIL_RANGE) && !me->isInFront(x, float(M_PI) * 1.5f); }))
            {
                me->CastSpell(p, SPELL_TAIL_SWEEP_HIT, true);
                p->KnockbackFrom(me->GetPositionX(), me->GetPositionY(), 15.0f, 7.0f);
            }
        }

        void BurningAdrenaline()
        {
            auto usable = [&](Unit* u) { return u && u->IsPlayer() && !u->HasAura(SPELL_BURN_OUT) && !u->HasAura(SPELL_BURNING_ADRENALINE); };

            Unit* target = nullptr;
            if (_adrenalineOnTank && usable(me->GetVictim()))
                target = me->GetVictim();
            else
                target = SelectTarget(SelectTargetMethod::Random, 0, [&](Unit* u) { return usable(u) && u != me->GetVictim(); });
            _adrenalineOnTank = !_adrenalineOnTank;

            if (!target)
                return;
            me->CastSpell(target, SPELL_BURNING_ADRENALINE, true);
            _adrenaline.insert(target->GetGUID());
        }

        // Once a second: adrenaline stacks and burn, and Vaelastrasz washing
        // his own corruption off while he concentrates.
        void EverySecond()
        {
            for (auto it = _adrenaline.begin(); it != _adrenaline.end();)
            {
                Player* player = ObjectAccessor::GetPlayer(*me, *it);
                if (!player)
                {
                    it = _adrenaline.erase(it);
                    continue;
                }

                if (!player->IsAlive())
                {
                    me->CastSpell(player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), SPELL_BURNING_ADRENALINE_BLAST, true);
                    player->RemoveAurasDueToSpell(SPELL_BURNING_ADRENALINE);
                    SetStacks(me, player, SPELL_BURNING_ADRENALINE_STACK, 0);
                    it = _adrenaline.erase(it);
                    continue;
                }

                Aura* aura = player->GetAura(SPELL_BURNING_ADRENALINE);
                if (!aura)
                {
                    // Ran out alive.
                    SetStacks(me, player, SPELL_BURNING_ADRENALINE_STACK, 0);
                    me->CastSpell(player, SPELL_BURN_OUT, true);
                    it = _adrenaline.erase(it);
                    continue;
                }

                int32 const stacks = std::min<int32>((aura->GetMaxDuration() - aura->GetDuration()) / IN_MILLISECONDS + 1, MAX_STACKS);
                SetStacks(me, player, SPELL_BURNING_ADRENALINE_STACK, stacks);
                int32 burn = int32(uint64(player->GetHealth()) * uint32(stacks) / 100);
                if (burn > 0)
                    me->CastCustomSpell(player, SPELL_BURNING_ADRENALINE_BURN, &burn, nullptr, nullptr, true);
                ++it;
            }

            if (me->HasAura(SPELL_CONCENTRATING))
                SetStacks(me, me, SPELL_CORRUPTION_VAEL, Stacks(me, me, SPELL_CORRUPTION_VAEL) - 1);
        }

        void SummonOrbs()
        {
            Position const& home = me->GetHomePosition();
            for (uint8 i = 0; i < ORBS_PER_WAVE; ++i)
            {
                float const angle = frand(0.0f, 2 * float(M_PI));
                float const dist = frand(ORB_SPAWN_MIN, ORB_SPAWN_MAX);
                float x = home.GetPositionX() + std::cos(angle) * dist;
                float y = home.GetPositionY() + std::sin(angle) * dist;
                float z = home.GetPositionZ();
                me->UpdateGroundPositionZ(x, y, z);
                me->SummonCreature(NPC_CORRUPTION_ORB, x, y, z, 0.0f, TEMPSUMMON_TIMED_DESPAWN, 60000);
            }
        }

        void UpdateAI(uint32 diff) override
        {
            events.Update(diff);
            _eventsIntro.Update(diff);
            _clock.Update(diff);

            if (!_introDone)
                UpdateIntro();

            if (!UpdateVictim())
                return;

            while (uint32 tick = _clock.ExecuteEvent())
            {
                if (tick == EVENT_BREATH_PULSE)
                    BreathPulse();
                else if (tick == EVENT_SECOND)
                {
                    EverySecond();
                    _clock.ScheduleEvent(EVENT_SECOND, 1s);
                }
            }

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
                        DoCastVictim(SPELL_DRACONIC_CLEAVE_CAST);
                        events.ScheduleEvent(EVENT_CLEAVE, 8s);
                        break;
                    case EVENT_TAIL_SWEEP:
                        TailSweep();
                        events.ScheduleEvent(EVENT_TAIL_SWEEP, 20s);
                        break;
                    case EVENT_SCORCHING_BREATH:
                        DoCastVictim(SPELL_SCORCHING_BREATH_CAST);
                        events.ScheduleEvent(EVENT_SCORCHING_BREATH, 12s);
                        break;
                    case EVENT_RAGE_ERUPTION:
                        DoCastSelf(SPELL_RAGE_ERUPTION, true);
                        events.ScheduleEvent(EVENT_RAGE_ERUPTION, 15s);
                        break;
                    case EVENT_BURNING_ADRENALINE:
                        BurningAdrenaline();
                        events.ScheduleEvent(EVENT_BURNING_ADRENALINE, 20s);
                        break;
                    case EVENT_CONCENTRATE:
                        DoCastSelf(SPELL_CONCENTRATING, true);
                        events.ScheduleEvent(EVENT_CONCENTRATE, 60s);
                        break;
                    case EVENT_ORBS:
                        SummonOrbs();
                        events.ScheduleEvent(EVENT_ORBS, 30s);
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            if (HealthBelowPct(15) && !_hasYelled)
            {
                Talk(SAY_HALFLIFE);
                _hasYelled = true;
            }

            DoMeleeAttackIfReady();
        }

        // The stock intro, unchanged.
        void UpdateIntro()
        {
            while (uint32 eventId = _eventsIntro.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_SPEECH_1:
                        me->SetStandState(UNIT_STAND_STATE_STAND);
                        me->SummonCreature(NPC_VICTOR_NEFARIUS, aNefariusSpawnLoc[0], aNefariusSpawnLoc[1], aNefariusSpawnLoc[2], aNefariusSpawnLoc[3], TEMPSUMMON_TIMED_DESPAWN, 26000);
                        _eventsIntro.ScheduleEvent(EVENT_SPEECH_2, 1s);
                        me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
                        break;
                    case EVENT_SPEECH_2:
                        if (Creature* nefarius = me->GetMap()->GetCreature(_nefariusGUID))
                        {
                            nefarius->CastSpell(me, SPELL_NEFARIUS_CORRUPTION, TRIGGERED_CAST_DIRECTLY);
                            nefarius->Yell(SAY_NEFARIAN_VAEL_INTRO);
                            nefarius->SetStandState(UNIT_STAND_STATE_STAND);
                        }
                        _eventsIntro.ScheduleEvent(EVENT_SPEECH_3, 18s);
                        break;
                    case EVENT_SPEECH_3:
                        if (Creature* nefarius = me->GetMap()->GetCreature(_nefariusGUID))
                            nefarius->CastSpell(me, SPELL_RED_LIGHTNING, TRIGGERED_NONE);
                        _eventsIntro.ScheduleEvent(EVENT_SPEECH_4, 2s);
                        break;
                    case EVENT_SPEECH_4:
                        Talk(SAY_LINE1);
                        me->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
                        _eventsIntro.ScheduleEvent(EVENT_SPEECH_5, 12s);
                        break;
                    case EVENT_SPEECH_5:
                        Talk(SAY_LINE2);
                        me->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
                        _eventsIntro.ScheduleEvent(EVENT_SPEECH_6, 12s);
                        break;
                    case EVENT_SPEECH_6:
                        Talk(SAY_LINE3);
                        me->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
                        _eventsIntro.ScheduleEvent(EVENT_SPEECH_7, 17s);
                        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
                        break;
                    case EVENT_SPEECH_7:
                        me->SetFaction(FACTION_DRAGONFLIGHT_BLACK);
                        if (Unit* player = ObjectAccessor::GetUnit(*me, _playerGUID))
                            AttackStart(player);
                        me->SetReactState(REACT_AGGRESSIVE);
                        _introDone = true;
                        break;
                }
            }
        }

    private:
        enum { GOSSIP_ID = 21334 };

        ObjectGuid _playerGUID;
        ObjectGuid _nefariusGUID;
        bool _hasYelled;
        bool _introDone;
        bool _adrenalineOnTank;
        uint8 _breathPulses = 0;
        EventMap _eventsIntro;
        EventMap _clock;        // breath pulses and the one-second tick
        std::set<ObjectGuid> _adrenaline;
    };

    /*
     * An Orb of Corruption. It drifts towards Vaelastrasz; the first player it
     * touches takes a stack of Corruption, and if it reaches him first, he
     * does. Either way his Concentrating breaks.
     */
    struct npc_vael_corruption_orb : public ScriptedAI
    {
        npc_vael_corruption_orb(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            me->SetReactState(REACT_PASSIVE);
            me->SetWalk(true);
            _check = 0;
            _move = 0;
        }

        Creature* Vael()
        {
            InstanceScript* instance = me->GetInstanceScript();
            return instance ? instance->GetCreature(DATA_VAELASTRAZ_THE_CORRUPT) : nullptr;
        }

        void Absorb(Unit* into)
        {
            Creature* vael = Vael();
            if (!vael)
                return;

            uint32 const spell = into == vael ? SPELL_CORRUPTION_VAEL : SPELL_CORRUPTION_PLAYER;
            SetStacks(vael, into, spell, Stacks(vael, into, spell) + 1);
            vael->AI()->DoAction(ACTION_CORRUPTION_GAINED);
            me->DespawnOrUnsummon();
        }

        void UpdateAI(uint32 diff) override
        {
            Creature* vael = Vael();
            if (!vael || !vael->IsInCombat())
            {
                me->DespawnOrUnsummon();
                return;
            }

            _move += diff;
            if (_move >= 1000)
            {
                _move = 0;
                me->GetMotionMaster()->MovePoint(0, vael->GetPositionX(), vael->GetPositionY(), vael->GetPositionZ());
            }

            _check += diff;
            if (_check < 250)
                return;
            _check = 0;

            if (me->IsWithinDistInMap(vael, 3.0f))
            {
                Absorb(vael);
                return;
            }

            Player* touched = nullptr;
            me->GetMap()->DoForAllPlayers([&](Player* player)
            {
                if (!touched && player->IsAlive() && !player->IsGameMaster() && me->IsWithinDistInMap(player, 2.5f))
                    touched = player;
            });
            if (touched)
                Absorb(touched);
        }

    private:
        uint32 _check = 0;
        uint32 _move = 0;
    };
}

void AddCoaVaelastraszScripts()
{
    RegisterBlackwingLairCreatureAI(boss_vaelastrasz_coa);
    RegisterBlackwingLairCreatureAI(npc_vael_corruption_orb);
}
