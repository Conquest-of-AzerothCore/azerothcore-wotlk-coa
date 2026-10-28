/*
 * Kurinnaxx as Ascension rebuilt him.
 *
 * Kit: Ascension's block 2112200-2112232. No logs or video exist for
 * Ahn'Qiraj; every timer here is designed.
 *
 * Rapid Evolution. His carapace adapts to the schools of magic that hit him:
 * every 2% of his health dealt by one school (not by auto attacks) adds a
 * stack of Adaptive Carapace for that school, -9% damage taken from it, up to
 * 8 stacks. Spells of several schools count evenly towards each.
 *
 * Sandreaver Broodlings burrow up around him. Where one dies it leaves
 * Corroding Acid; a player drenched in it corrodes the carapace: each of
 * their hits may strip a stack of the school it used, and where no stack is
 * left, adds Elemental Corrosion (+10% damage taken from that school, up to
 * 5). Every broodling that dies also gives him A Mother's Grief, +3% physical
 * damage for 30s per stack.
 *
 *   Mortal Wound   first 6s,  every 9s    tank, 150% weapon damage, -10%
 *                                        healing taken, stacks to 10
 *   Sand Trap      first 10s, every 12s   random player: Nature damage and
 *                                        knockback within 8 yards, sand in
 *                                        the eyes (less hit, dodge, parry)
 *   Wide Slash     first 15s, every 20s   4s cast, both claws in a 15-yard
 *                                        cone, -50% armour for 10s
 *   Broodlings     first 20s, every 30s   three
 *   Tunneling      first 45s, every 45s   burrows for 3s and surfaces under a
 *                                        random player with a Sand Trap
 *   Frenzy         at 30%
 *
 * Decided here, not in the data: every timer, the 2% step and 8-stack cap,
 * the 25% corrosion chance, three broodlings per wave, and Tunneling's use.
 * The broodling is a new creature, 9780023; the data names it only in the
 * acid's tooltip.
 */

#include "CreatureScript.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "../../../src/server/scripts/Kalimdor/RuinsOfAhnQiraj/ruins_of_ahnqiraj.h"
#include "zg_coa_common.h"

#include <array>

using namespace coa_zg;

namespace
{
    enum Spells
    {
        SPELL_SUMMON_PLAYER      = 26446,

        SPELL_RAPID_EVOLUTION    = 2112200,
        SPELL_CARAPACE_FIRST     = 2112201,   // + school index, physical .. arcane
        SPELL_CORROSION_FIRST    = 2112208,   // + school index
        SPELL_MORTAL_WOUND       = 2112215,
        SPELL_WIDE_SLASH         = 2112216,
        SPELL_CRUSHED_ARMOR      = 2112219,
        SPELL_SAND_IN_EYES       = 2112220,
        SPELL_SAND_TRAP          = 2112221,
        SPELL_FRENZY             = 2112225,
        SPELL_MOTHERS_GRIEF      = 2112226,
        SPELL_CORRODING_ACID_DOT = 2112228,
        SPELL_TUNNELING          = 2112232,
    };

    enum Events
    {
        EVENT_MORTAL_WOUND = 1,
        EVENT_SAND_TRAP,
        EVENT_WIDE_SLASH,
        EVENT_BROODLINGS,
        EVENT_TUNNEL,
        EVENT_SURFACE,
    };

    enum Misc
    {
        NPC_SANDREAVER_BROODLING = 9780023,
        NPC_WORLD_TRIGGER        = 12999,
        SAY_KURINNAXX_DEATH      = 5,        // yelled by Ossirian
        SCHOOLS                  = 7
    };

    constexpr float STEP_PCT        = 2.0f;
    constexpr uint8 MAX_CARAPACE    = 8;
    constexpr uint8 MAX_CORROSION   = 5;
    constexpr uint32 CORRODE_CHANCE = 25;
    constexpr float SLASH_RANGE     = 15.0f;
    constexpr float SLASH_ARC       = float(M_PI) / 2;

    struct boss_kurinnaxx_coa : public BossAI
    {
        boss_kurinnaxx_coa(Creature* creature) : BossAI(creature, DATA_KURINNAXX) { }

        void InitializeAI() override
        {
            me->m_CombatDistance = 50.0f;
            BossAI::InitializeAI();
        }

        void Reset() override
        {
            BossAI::Reset();
            _taken.fill(0.0f);
            _frenzied = false;
            me->RemoveAurasDueToSpell(SPELL_FRENZY);
            me->RemoveAurasDueToSpell(SPELL_MOTHERS_GRIEF);
            for (uint8 i = 0; i < SCHOOLS; ++i)
            {
                me->RemoveAurasDueToSpell(SPELL_CARAPACE_FIRST + i);
                me->RemoveAurasDueToSpell(SPELL_CORROSION_FIRST + i);
            }
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            DoCastSelf(SPELL_RAPID_EVOLUTION, true);
            events.ScheduleEvent(EVENT_MORTAL_WOUND, 6s);
            events.ScheduleEvent(EVENT_SAND_TRAP, 10s);
            events.ScheduleEvent(EVENT_WIDE_SLASH, 15s);
            events.ScheduleEvent(EVENT_BROODLINGS, 20s);
            events.ScheduleEvent(EVENT_TUNNEL, 45s);
        }

        // From stock: Andorov comes for the Rajaxx event, Ossirian speaks.
        void JustDied(Unit* killer) override
        {
            if (killer)
                if (Player* player = killer->GetCharmerOrOwnerPlayerOrPlayerItself())
                    if (Creature* andorov = player->SummonCreature(NPC_ANDOROV, -8538.177f, 1486.0956f, 32.39054f, 3.7638654f, TEMPSUMMON_CORPSE_DESPAWN, 0))
                        andorov->setActive(true);
            if (Creature* ossirian = instance->GetCreature(DATA_OSSIRIAN))
            {
                ossirian->setActive(true);
                if (ossirian->GetAI())
                    ossirian->AI()->Talk(SAY_KURINNAXX_DEATH);
            }
            BossAI::JustDied(killer);
        }

        uint8 Stacks(uint32 spell) const
        {
            AuraEffect const* eff = me->GetAuraEffect(spell, EFFECT_0);
            int32 const step = Info(me, spell);
            return eff && step ? uint8(std::abs(eff->GetAmount() / step)) : 0;
        }

        // Sets a per-school aura to `stacks` times its step (0 removes it).
        void SetSchoolAura(uint32 spell, uint8 stacks)
        {
            if (!stacks)
            {
                me->RemoveAurasDueToSpell(spell);
                return;
            }
            if (!me->HasAura(spell))
                me->AddAura(spell, me);
            if (AuraEffect* eff = me->GetAuraEffect(spell, EFFECT_0))
                eff->ChangeAmount(Info(me, spell) * stacks);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask mask) override
        {
            BossAI::DamageTaken(attacker, damage, type, mask);

            if (!_frenzied && me->HealthBelowPctDamaged(30, damage))
            {
                _frenzied = true;
                DoCastSelf(SPELL_FRENZY, true);
            }

            if (!damage || type == DIRECT_DAMAGE)   // auto attacks do not count
                return;

            std::vector<uint8> schools;
            for (uint8 i = 0; i < SCHOOLS; ++i)
                if (mask & (1 << i))
                    schools.push_back(i);
            if (schools.empty())
                return;

            Player* player = attacker ? attacker->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
            bool const drenched = player && player->HasAura(sSpellMgr->GetSpellIdForDifficulty(SPELL_CORRODING_ACID_DOT, me));

            float const step = me->GetMaxHealth() * STEP_PCT / 100.0f;
            for (uint8 s : schools)
            {
                if (drenched && roll_chance_i(CORRODE_CHANCE))
                {
                    if (uint8 have = Stacks(SPELL_CARAPACE_FIRST + s))
                        SetSchoolAura(SPELL_CARAPACE_FIRST + s, have - 1);
                    else
                        SetSchoolAura(SPELL_CORROSION_FIRST + s, std::min<uint8>(Stacks(SPELL_CORROSION_FIRST + s) + 1, MAX_CORROSION));
                    continue;
                }

                _taken[s] += float(damage) / schools.size();
                while (_taken[s] >= step)
                {
                    _taken[s] -= step;
                    uint8 const have = Stacks(SPELL_CARAPACE_FIRST + s);
                    if (have < MAX_CARAPACE)
                        SetSchoolAura(SPELL_CARAPACE_FIRST + s, have + 1);
                }
            }
        }

        // A broodling dies: acid where it fell, and a mother's grief.
        void SummonedCreatureDies(Creature* summon, Unit* killer) override
        {
            BossAI::SummonedCreatureDies(summon, killer);
            if (summon->GetEntry() != NPC_SANDREAVER_BROODLING)
                return;
            AddStack(me, me, SPELL_MOTHERS_GRIEF);
            if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, summon->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 60000))
            {
                spot->SetFaction(me->GetFaction());
                spot->CastSpell(spot, SPELL_CORRODING_ACID_DOT, true, nullptr, nullptr, me->GetGUID());
            }
        }

        void SandTrap(Unit* target)
        {
            me->CastSpell(target, SPELL_SAND_TRAP, true);
            me->CastSpell(target, SPELL_SAND_IN_EYES, true);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);
            if (spell->Id == SPELL_WIDE_SLASH)
                for (Player* p : PlayersInFront(me, SLASH_RANGE, SLASH_ARC))
                    me->CastSpell(p, SPELL_CRUSHED_ARMOR, true);
        }

        bool OnTeleportUnreacheablePlayer(Player* player) override
        {
            DoCast(player, SPELL_SUMMON_PLAYER, true);
            return true;
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
                    case EVENT_MORTAL_WOUND:
                        DoCastVictim(SPELL_MORTAL_WOUND);
                        events.ScheduleEvent(EVENT_MORTAL_WOUND, 9s);
                        break;
                    case EVENT_SAND_TRAP:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                            SandTrap(target);
                        events.ScheduleEvent(EVENT_SAND_TRAP, 12s);
                        break;
                    case EVENT_WIDE_SLASH:
                        DoCastSelf(SPELL_WIDE_SLASH);
                        events.ScheduleEvent(EVENT_WIDE_SLASH, 20s);
                        break;
                    case EVENT_BROODLINGS:
                        for (uint8 i = 0; i < 3; ++i)
                            if (Creature* brood = me->SummonCreature(NPC_SANDREAVER_BROODLING, me->GetRandomNearPosition(15.0f), TEMPSUMMON_CORPSE_TIMED_DESPAWN, 10000))
                                brood->SetInCombatWithZone();
                        events.ScheduleEvent(EVENT_BROODLINGS, 30s);
                        break;
                    case EVENT_TUNNEL:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 60.0f, true))
                        {
                            _surfaceAt = target->GetGUID();
                            DoCastSelf(SPELL_TUNNELING, true);
                            me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
                            me->SetReactState(REACT_PASSIVE);
                            me->AttackStop();
                            events.DelayEvents(3s);
                            events.ScheduleEvent(EVENT_SURFACE, 3s);
                        }
                        events.ScheduleEvent(EVENT_TUNNEL, 45s);
                        break;
                    case EVENT_SURFACE:
                        if (Unit* target = ObjectAccessor::GetUnit(*me, _surfaceAt))
                        {
                            me->NearTeleportTo(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), me->GetOrientation());
                            SandTrap(target);
                        }
                        me->RemoveAurasDueToSpell(SPELL_TUNNELING);
                        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
                        me->SetReactState(REACT_AGGRESSIVE);
                        break;
                    default:
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            if (!me->HasAura(SPELL_TUNNELING))
                DoMeleeAttackIfReady();
        }

    private:
        std::array<float, SCHOOLS> _taken{};
        bool _frenzied = false;
        ObjectGuid _surfaceAt;
    };
}

void AddCoaKurinnaxxScripts()
{
    RegisterRuinsOfAhnQirajCreatureAI(boss_kurinnaxx_coa);
}
