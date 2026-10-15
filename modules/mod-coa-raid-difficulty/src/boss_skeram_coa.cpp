/*
 * The Prophet Skeram as Ascension rebuilt him.
 *
 * Kit: Ascension's block 2116000-2116056. No logs or video exist for
 * Ahn'Qiraj; every timer and number here is designed.
 *
 * From stock: his images at 75%, 50% and 25%, and the shuffle when they
 * appear. Ascension's own clone auras make them fragile: they take 250%, 500%
 * and 750% more damage (first, second, third split) and deal 75% less.
 *
 * Living Nightmare, first at 45s, every 90s. Skeram traps every mind in a
 * nightmare: each player is given a phobia (Murlocs, Spiders, Bees, Cats) and
 * sees only the others who share it, and the nightmare creatures of that fear.
 * In a raid of 15 or more, up to five players face the greatest fear known to
 * man instead: the Nightmarish Monstrosity, a stepmother who argues, drinks and
 * lectures. While any nightmare stands, Skeram feasts on it behind the
 * Nightmare Veil, immune. A group that kills its creatures wakes up. After 60
 * seconds whoever is still trapped wakes insane: his for 10 seconds.
 *
 *   Nightmare Touch   every 2.5s   his melee: weapon damage as Shadow; every
 *                                  fourth a Fierce Nightmare Touch that cannot
 *                                  be avoided
 *   Maddening Gaze    first 10s, every 12s   Shadow damage and a DoT on a
 *                                  random player and those within 5 yards;
 *                                  gazed again while still turning insane:
 *                                  Insanity, his for 10s
 *   Psychic Shock     first 15s, every 15s   the ground under a player
 *                                  darkens for 5s, then Shadow damage and a 2s
 *                                  disable within 2 yards
 *   True Fulfillment  first 25s, every 25s   the nearest non-tank worships
 *                                  him for 30s: pacified, rooted, and 25% of
 *                                  the damage he takes goes to them
 *
 * Decided here, not in the data: every timer, all players trapped at once,
 * that he and his images stand in every nightmare while veiled (Ascension's
 * "Skeram Phasing" auras point the same way), the group sizes and creature
 * health (3% of his per two players, 10% per player for the Monstrosity), the 60s
 * limit and its insanity, the gaze rule, and the split-damage share handled
 * in code. The five nightmare creatures are new (9780024-9780028) with models
 * of murloc, spider, wasp, panther and Lady Prestor. Vanquished-nightmare
 * buffs are left out: their auras move players into other phases.
 */

#include "Containers.h"
#include "CreatureScript.h"
#include "InstanceScript.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "../../../src/server/scripts/Kalimdor/TempleOfAhnQiraj/temple_of_ahnqiraj.h"
#include "zg_coa_common.h"

#include <array>
#include <map>

using namespace coa_zg;

namespace
{
    enum Yells
    {
        SAY_AGGRO = 0,
        SAY_SLAY  = 1,
        SAY_SPLIT = 2,
        SAY_DEATH = 3
    };

    enum Spells
    {
        SPELL_INITIALIZE_IMAGE = 3730,
        SPELL_SUMMON_IMAGES    = 747,
        SPELL_BIRTH            = 34115,

        SPELL_NIGHTMARE_FIRST  = 2116000,   // + phobia 0..4
        SPELL_VANQUISHED_COUNT = 2116011,
        SPELL_LIVING_NIGHTMARE = 2116025,
        SPELL_AMPLIFY_750      = 2116029,
        SPELL_AMPLIFY_500      = 2116030,
        SPELL_AMPLIFY_250      = 2116031,
        SPELL_CLONE_WEAKNESS   = 2116032,
        SPELL_MADDENING_GAZE   = 2116033,
        SPELL_INSANITY         = 2116037,
        SPELL_INSANITY_GUARD   = 2116038,
        SPELL_TURNING_INSANE   = 2116039,
        SPELL_PSYCHIC_MARK     = 2116040,
        SPELL_PSYCHIC_SHOCK    = 2116041,
        SPELL_NIGHTMARE_VEIL   = 2116045,
        SPELL_FULFILLMENT      = 2116046,
        SPELL_FULFILLMENT_GUARD = 2116047,
        SPELL_WORSHIP          = 2116048,
        SPELL_HARSH_LESSON     = 2116049,
        SPELL_DRINK_WINE       = 2116050,
        SPELL_HARSH_WORDS      = 2116051,
        SPELL_WHO_DO_YOU_THINK = 2116052,
        SPELL_GROUNDED         = 2116054,
        SPELL_NIGHTMARE_TOUCH  = 2116055,
        SPELL_FIERCE_TOUCH     = 2116056,
    };

    enum Events
    {
        EVENT_TOUCH = 1,
        EVENT_GAZE,
        EVENT_PSYCHIC,
        EVENT_PSYCHIC_HIT,
        EVENT_FULFILLMENT,
        EVENT_NIGHTMARE,
        EVENT_NIGHTMARE_CHECK,
        EVENT_NIGHTMARE_TIMEOUT,
        EVENT_TELEPORT,
        EVENT_INIT_IMAGE,
        EVENT_BLINK,
    };

    enum Misc
    {
        NPC_WORLD_TRIGGER = 12999,
        NPC_NIGHTMARE_FIRST = 9780024,      // + phobia 0..4
        PHOBIAS           = 5,
        STEPMOM           = 4,
        ALL_NIGHTMARES    = 1 | 4 | 8 | 16 | 32 | 64
    };

    // Phase masks of the five nightmares, as the auras set them.
    uint32 const NightmarePhase[PHOBIAS] = { 4, 8, 16, 32, 64 };
    uint32 const BlinkSpells[3] = { 4801, 8195, 20449 };

    constexpr uint32 WORSHIP_PCT = 25;
    constexpr float GAZE_RADIUS  = 5.0f;
    constexpr float SHOCK_RADIUS = 2.0f;

    struct boss_skeram_coa : public BossAI
    {
        boss_skeram_coa(Creature* creature) : BossAI(creature, DATA_SKERAM) { }

        void Reset() override
        {
            _Reset();
            _flag = 0;
            _hpct = 75.0f;
            _split = 0;
            _touches = 0;
            me->SetReactState(REACT_AGGRESSIVE);
            me->SetImmuneToAll(false);
            me->SetControlled(false, UNIT_STATE_ROOT);
            me->RemoveAurasDueToSpell(SPELL_NIGHTMARE_VEIL);
            EndNightmares(false);
        }

        void KilledUnit(Unit* /*victim*/) override
        {
            Talk(SAY_SLAY);
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            EndNightmares(false);
            ScriptedAI::EnterEvadeMode(why);
            if (me->IsSummon())
                me->ToTempSummon()->UnSummon();
        }

        // From stock, with Ascension's clone auras.
        void JustSummoned(Creature* creature) override
        {
            BossAI::JustSummoned(creature);
            if (creature->GetEntry() != me->GetEntry())
                return;
            float const share = me->GetHealthPct() < 25.0f ? 0.50f : me->GetHealthPct() < 50.0f ? 0.20f : 0.10f;
            creature->SetMaxHealth(uint32(me->GetMaxHealth() * share));
            creature->SetHealth(uint32(creature->GetMaxHealth() * (me->GetHealthPct() / 100.0f)));
            creature->CastSpell(creature, SPELL_BIRTH, true);
            creature->SetControlled(true, UNIT_STATE_ROOT);
            creature->SetReactState(REACT_PASSIVE);
            creature->SetImmuneToAll(true, true);
            uint32 const amplify = _split <= 1 ? SPELL_AMPLIFY_250 : _split == 2 ? SPELL_AMPLIFY_500 : SPELL_AMPLIFY_750;
            creature->AddAura(amplify, creature);
            creature->AddAura(SPELL_CLONE_WEAKNESS, creature);
            _copies.push_back(creature->GetGUID());
        }

        void DoTeleport(Creature* creature)
        {
            uint8 rand = 0;
            if (_flag != 0)
            {
                while (_flag & (1 << rand))
                    rand = urand(0, 2);
                DoCast(me, BlinkSpells[rand]);
                _flag |= (1 << rand);
                _flag |= (1 << 7);
            }
            while (_flag & (1 << rand))
                rand = urand(0, 2);
            creature->SetReactState(REACT_AGGRESSIVE);
            creature->SetImmuneToAll(false);
            creature->SetControlled(false, UNIT_STATE_ROOT);
            creature->CastSpell(creature, BlinkSpells[rand], true);
            _flag |= (1 << rand);
            if (_flag & (1 << 7))
                _flag = 0;
            events.ScheduleEvent(EVENT_INIT_IMAGE, 400ms);
        }

        void JustDied(Unit* /*killer*/) override
        {
            if (me->IsSummon())
            {
                me->RemoveCorpse();
                return;
            }
            EndNightmares(false);
            _JustDied();
            Talk(SAY_DEATH);
            if (me->GetMap() && me->GetMap()->ToInstanceMap())
                me->GetMap()->ToInstanceMap()->PermBindAllPlayers();
        }

        void JustEngagedWith(Unit* who) override
        {
            _JustEngagedWith();
            events.Reset();
            events.ScheduleEvent(EVENT_TOUCH, 2500ms);
            events.ScheduleEvent(EVENT_GAZE, 10s);
            events.ScheduleEvent(EVENT_PSYCHIC, 15s);
            events.ScheduleEvent(EVENT_FULFILLMENT, 25s);
            events.ScheduleEvent(EVENT_BLINK, 30s, 45s);
            if (!me->IsSummon())
            {
                events.ScheduleEvent(EVENT_NIGHTMARE, 45s);
                Unit* puller = who->GetCharmerOrOwnerPlayerOrPlayerItself();
                Talk(SAY_AGGRO, puller ? puller : who);
            }
        }

        // Worship: a quarter of what he takes goes to his worshipper.
        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);
            Unit* worshipper = ObjectAccessor::GetUnit(*me, _worshipper);
            if (!damage || !worshipper || !worshipper->IsAlive() || !worshipper->HasAura(SPELL_WORSHIP))
                return;
            uint32 const moved = damage * WORSHIP_PCT / 100;
            damage -= moved;
            Unit::DealDamage(attacker ? attacker : me, worshipper, moved, nullptr, type, school, nullptr, false);
        }

        // ---- Living Nightmare ------------------------------------------------

        void StartNightmares()
        {
            std::vector<Player*> raid = Players(me, [](Player*) { return true; });
            if (raid.empty())
                return;
            Acore::Containers::RandomShuffle(raid);

            size_t stepmom = raid.size() >= 15 ? std::min<size_t>(5, raid.size() / 4) : 0;
            std::array<std::vector<Player*>, PHOBIAS> groups;
            for (size_t i = 0; i < raid.size(); ++i)
                groups[i < stepmom ? STEPMOM : (i % 4)].push_back(raid[i]);

            me->InterruptNonMeleeSpells(false);
            DoCastSelf(SPELL_LIVING_NIGHTMARE, true);
            Veil(me, true);
            for (ObjectGuid const& guid : _copies)
                if (Creature* image = ObjectAccessor::GetCreature(*me, guid))
                    Veil(image, true);

            for (uint8 f = 0; f < PHOBIAS; ++f)
            {
                if (groups[f].empty())
                    continue;
                Position center = groups[f].front()->GetPosition();
                for (Player* p : groups[f])
                {
                    me->AddAura(SPELL_NIGHTMARE_FIRST + f, p);
                    _trapped[p->GetGUID()] = f;
                }
                uint32 const count = f == STEPMOM ? 1 : std::max<uint32>(1, uint32(groups[f].size() + 1) / 2);
                for (uint32 i = 0; i < count; ++i)
                {
                    Position pos = center;
                    me->MovePosition(pos, frand(5.0f, 12.0f), frand(0.0f, 2 * float(M_PI)));
                    if (Creature* dread = me->SummonCreature(NPC_NIGHTMARE_FIRST + f, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 5000))
                    {
                        dread->SetPhaseMask(NightmarePhase[f], true);
                        uint32 const hp = uint32(me->GetMaxHealth() * (f == STEPMOM ? 0.10f : 0.03f) * (f == STEPMOM ? groups[f].size() : 2));
                        dread->SetMaxHealth(std::max<uint32>(hp, 1));
                        dread->SetFullHealth();
                        _dreads[f].push_back(dread->GetGUID());
                        if (Player* victim = Acore::Containers::SelectRandomContainerElement(groups[f]))
                            dread->AI()->AttackStart(victim);
                    }
                }
            }

            events.ScheduleEvent(EVENT_NIGHTMARE_CHECK, 1s);
            events.ScheduleEvent(EVENT_NIGHTMARE_TIMEOUT, 60s);
        }

        // A phobia whose creatures are all dead wakes its players.
        void CheckNightmares()
        {
            for (uint8 f = 0; f < PHOBIAS; ++f)
            {
                if (_dreads[f].empty())
                    continue;
                bool alive = false;
                for (ObjectGuid const& guid : _dreads[f])
                    if (Creature* dread = ObjectAccessor::GetCreature(*me, guid))
                        if (dread->IsAlive())
                            alive = true;
                if (alive)
                    continue;
                _dreads[f].clear();
                for (auto it = _trapped.begin(); it != _trapped.end();)
                {
                    if (it->second != f)
                    {
                        ++it;
                        continue;
                    }
                    if (Player* p = ObjectAccessor::GetPlayer(*me, it->first))
                    {
                        p->RemoveAurasDueToSpell(SPELL_NIGHTMARE_FIRST + f);
                        AddStack(me, p, SPELL_VANQUISHED_COUNT);
                    }
                    it = _trapped.erase(it);
                }
            }
            if (_trapped.empty())
                EndNightmares(true);
        }

        void EndNightmares(bool resume)
        {
            for (auto const& [guid, f] : _trapped)
                if (Player* p = ObjectAccessor::GetPlayer(*me, guid))
                    p->RemoveAurasDueToSpell(SPELL_NIGHTMARE_FIRST + f);
            _trapped.clear();
            for (auto& list : _dreads)
            {
                for (ObjectGuid const& guid : list)
                    if (Creature* dread = ObjectAccessor::GetCreature(*me, guid))
                        dread->DespawnOrUnsummon();
                list.clear();
            }
            events.CancelEvent(EVENT_NIGHTMARE_CHECK);
            events.CancelEvent(EVENT_NIGHTMARE_TIMEOUT);
            if (!me->HasAura(SPELL_NIGHTMARE_VEIL))
                return;
            Veil(me, false);
            for (ObjectGuid const& guid : _copies)
                if (Creature* image = ObjectAccessor::GetCreature(*me, guid))
                    Veil(image, false);
            if (resume)
                if (Unit* target = SelectTarget(SelectTargetMethod::MaxThreat, 0))
                    AttackStart(target);
        }

        // Behind the veil he (and his images) stand in every nightmare at once,
        // so no trapped player loses sight of him and the fight holds.
        static void Veil(Creature* who, bool on)
        {
            if (on)
            {
                who->AddAura(SPELL_NIGHTMARE_VEIL, who);
                who->SetPhaseMask(ALL_NIGHTMARES, true);
                who->AttackStop();
                who->SetReactState(REACT_PASSIVE);
                who->SetControlled(true, UNIT_STATE_ROOT);
            }
            else
            {
                who->RemoveAurasDueToSpell(SPELL_NIGHTMARE_VEIL);
                who->SetPhaseMask(PHASEMASK_NORMAL, true);
                who->SetReactState(REACT_AGGRESSIVE);
                who->SetControlled(false, UNIT_STATE_ROOT);
            }
        }

        // Time is up: whoever is still trapped wakes insane.
        void NightmareTimeout()
        {
            std::vector<ObjectGuid> late;
            for (auto const& [guid, f] : _trapped)
                late.push_back(guid);
            EndNightmares(true);
            for (ObjectGuid const& guid : late)
                if (Player* p = ObjectAccessor::GetPlayer(*me, guid))
                    MakeInsane(p);
        }

        void MakeInsane(Unit* target)
        {
            me->CastSpell(target, SPELL_INSANITY, true);
            me->CastSpell(target, SPELL_INSANITY_GUARD, true);
        }

        // ---- abilities --------------------------------------------------------

        void Gaze()
        {
            Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true);
            if (!target)
                return;
            for (Player* p : Players(me, [&](Player* x) { return target->IsWithinDist(x, GAZE_RADIUS); }))
            {
                bool const again = p->HasAura(SPELL_TURNING_INSANE);
                me->CastSpell(p, SPELL_MADDENING_GAZE, true);
                if (again)
                    MakeInsane(p);
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
            {
                // While veiled he has nothing to attack; keep the nightmare clock going.
                if (me->HasAura(SPELL_NIGHTMARE_VEIL))
                    events.Update(diff);
                else
                    return;
            }
            else
                events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            bool const veiled = me->HasAura(SPELL_NIGHTMARE_VEIL);
            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_TOUCH:
                        if (!veiled)
                            if (Unit* tank = me->GetVictim())
                                if (me->IsWithinMeleeRange(tank))
                                    me->CastSpell(tank, ++_touches % 4 ? SPELL_NIGHTMARE_TOUCH : SPELL_FIERCE_TOUCH, true);
                        events.ScheduleEvent(EVENT_TOUCH, 2500ms);
                        break;
                    case EVENT_GAZE:
                        if (!veiled)
                            Gaze();
                        events.ScheduleEvent(EVENT_GAZE, 12s);
                        break;
                    case EVENT_PSYCHIC:
                        if (!veiled)
                            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                            {
                                _shockAt = target->GetPosition();
                                if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, _shockAt, TEMPSUMMON_TIMED_DESPAWN, 6000))
                                {
                                    spot->SetFaction(me->GetFaction());
                                    spot->CastSpell(spot, SPELL_PSYCHIC_MARK, true);
                                    _shockSpot = spot->GetGUID();
                                }
                                events.ScheduleEvent(EVENT_PSYCHIC_HIT, 5s);
                            }
                        events.ScheduleEvent(EVENT_PSYCHIC, 15s);
                        break;
                    case EVENT_PSYCHIC_HIT:
                        if (Creature* spot = ObjectAccessor::GetCreature(*me, _shockSpot))
                            spot->CastSpell(spot, SPELL_PSYCHIC_SHOCK, true, nullptr, nullptr, me->GetGUID());
                        break;
                    case EVENT_FULFILLMENT:
                        if (!veiled)
                            if (Unit* target = SelectTarget(SelectTargetMethod::MinDistance, 1, 0.0f, true))
                            {
                                _worshipper = target->GetGUID();
                                for (uint32 s : { SPELL_FULFILLMENT, SPELL_FULFILLMENT_GUARD, SPELL_WORSHIP })
                                    me->CastSpell(target, s, true);
                            }
                        events.ScheduleEvent(EVENT_FULFILLMENT, 25s);
                        break;
                    case EVENT_BLINK:
                        if (!veiled)
                        {
                            DoCast(me, BlinkSpells[urand(0, 2)]);
                            DoResetThreatList();
                        }
                        events.ScheduleEvent(EVENT_BLINK, 10s, 30s);
                        break;
                    case EVENT_NIGHTMARE:
                        StartNightmares();
                        events.ScheduleEvent(EVENT_NIGHTMARE, 90s);
                        break;
                    case EVENT_NIGHTMARE_CHECK:
                        CheckNightmares();
                        if (!_trapped.empty())
                            events.ScheduleEvent(EVENT_NIGHTMARE_CHECK, 1s);
                        break;
                    case EVENT_NIGHTMARE_TIMEOUT:
                        NightmareTimeout();
                        break;
                    case EVENT_TELEPORT:
                        me->SetReactState(REACT_AGGRESSIVE);
                        me->SetImmuneToAll(false);
                        me->SetControlled(false, UNIT_STATE_ROOT);
                        for (ObjectGuid const& guid : _copies)
                            if (Creature* image = ObjectAccessor::GetCreature(*me, guid))
                                DoTeleport(image);
                        DoResetThreatList();
                        events.RescheduleEvent(EVENT_BLINK, 10s, 30s);
                        break;
                    case EVENT_INIT_IMAGE:
                        me->CastSpell(me, SPELL_INITIALIZE_IMAGE, true);
                        break;
                    default:
                        break;
                }
            }

            // From stock: the split at 75, 50 and 25%.
            if (!me->IsSummon() && !veiled && me->GetHealthPct() < _hpct)
            {
                ++_split;
                _copies.clear();
                DoCast(me, SPELL_SUMMON_IMAGES, true);
                me->SetReactState(REACT_PASSIVE);
                me->SetImmuneToAll(true, true);
                me->SetControlled(true, UNIT_STATE_ROOT);
                Talk(SAY_SPLIT);
                _hpct -= 25.0f;
                events.ScheduleEvent(EVENT_TELEPORT, 2s);
            }

            if (!veiled)
                DoMeleeAttackIfReady();
        }

    private:
        float _hpct = 75.0f;
        uint8 _flag = 0;
        uint8 _split = 0;
        uint32 _touches = 0;
        GuidVector _copies;
        ObjectGuid _worshipper;
        ObjectGuid _shockSpot;
        Position _shockAt;
        std::map<ObjectGuid, uint8> _trapped;
        std::array<GuidVector, PHOBIAS> _dreads;
    };

    // The nightmare creatures. The Monstrosity has a kit of her own.
    struct npc_skeram_nightmare_coa : public ScriptedAI
    {
        npc_skeram_nightmare_coa(Creature* creature) : ScriptedAI(creature) { }

        void Reset() override
        {
            _events.Reset();
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            if (me->GetEntry() != NPC_NIGHTMARE_FIRST + STEPMOM)
                return;
            _events.ScheduleEvent(1, 8s);     // Harsh Lesson
            _events.ScheduleEvent(2, 15s);    // Harsh Words
            _events.ScheduleEvent(3, 20s);    // Grounded
            _events.ScheduleEvent(4, 25s);    // Who Do You Think You Are!
            _events.ScheduleEvent(5, 30s);    // Drink Wine
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            _events.Update(diff);
            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = _events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case 1:
                        DoCastVictim(SPELL_HARSH_LESSON);
                        _events.ScheduleEvent(1, 10s);
                        break;
                    case 2:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 1, 40.0f, true))
                            DoCast(target, SPELL_HARSH_WORDS);
                        _events.ScheduleEvent(2, 15s);
                        break;
                    case 3:
                        if (Unit* target = SelectTarget(SelectTargetMethod::MaxDistance, 0, 60.0f, true))
                            DoCast(target, SPELL_GROUNDED);
                        _events.ScheduleEvent(3, 20s);
                        break;
                    case 4:
                        DoCastSelf(SPELL_WHO_DO_YOU_THINK);
                        _events.ScheduleEvent(4, 30s);
                        break;
                    case 5:
                        DoCastSelf(SPELL_DRINK_WINE);
                        _events.ScheduleEvent(5, 30s);
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
        EventMap _events;
    };
}

void AddCoaSkeramScripts()
{
    RegisterTempleOfAhnQirajCreatureAI(boss_skeram_coa);
    RegisterTempleOfAhnQirajCreatureAI(npc_skeram_nightmare_coa);
}
