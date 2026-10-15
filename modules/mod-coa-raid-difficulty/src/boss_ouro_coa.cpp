/*
 * Ouro as Ascension rebuilt him.
 *
 * Kit: Ascension's block 2116801-2116854. No logs or video exist for
 * Ahn'Qiraj; every timer here is designed.
 *
 * From stock: he rises from the spawner, submerges every 90 seconds (or when
 * nobody stands in his reach for ten seconds), the dirt mounds chase the raid
 * while he is gone and one of them brings him back, and the last 20% without
 * submerging. The mounds and the spawner keep their stock scripts.
 *
 * Sand Coat. Sand abilities ignore armour and cannot be avoided; each stacks
 * Sand Coat (-5% speed). Twenty stacks turn a player to stone for 10 seconds.
 *
 *   Sand Breath        first 15s, every 20s   2s cast, a cone of sand for 3s,
 *                                             up to six stacks of Sand Coat;
 *                                             the tank loses his threat (stock)
 *   Whirling Sweep     first 22s, every 22s   15 yards, knocks back
 *   Acidic Breath      first 30s, every 30s   2s cast, a cone of acid, +5%
 *                                             Nature damage taken, stacking
 *   Poison Spit        first 8s,  every 12s   3s cast, a random player,
 *                                             stacking poison
 *   Massive Sandstone Boulder  whenever nobody is in his reach, at a random
 *                              player: a stack of Sand Coat
 *   While submerged    the mounds tunnel (damage and knock-up along their
 *                      path, a slowing trail) and two Dust Devils roam,
 *                      coating everyone they touch
 *   Below 20%          Enrage (+100% attack speed) and Seismic Activity: the
 *                      earth shakes everyone every second, harder every 15s
 *
 * Decided here, not in the data: every timer, two Dust Devils, which abilities
 * belong to him and which to his mounds, and Seismic Activity as the 20% phase.
 */

#include "Cell.h"
#include "CellImpl.h"
#include "Containers.h"
#include "CreatureScript.h"
#include "GameObject.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/Kalimdor/TempleOfAhnQiraj/temple_of_ahnqiraj.h"
#include "zg_coa_common.h"

#include <list>

using namespace coa_zg;

namespace
{
    enum Spells
    {
        SPELL_GROUND_RUPTURE       = 26100,
        SPELL_OURO_SUBMERGE_VISUAL = 26063,
        SPELL_SUMMON_SANDWORM_BASE = 26133,
        SPELL_BIRTH                = 26586,
        SPELL_SUMMON_OURO_MOUNDS   = 26058,
        SPELL_SUMMON_OURO_AURA     = 26642,

        SPELL_BOULDER        = 2116801,
        SPELL_SWEEP          = 2116802,
        SPELL_SAND_BREATH    = 2116803,
        SPELL_SAND_COAT      = 2116808,
        SPELL_STONED         = 2116809,
        SPELL_SEISMIC        = 2116810,
        SPELL_POISON_SPIT    = 2116830,
        SPELL_ACIDIC_BREATH  = 2116835,
        SPELL_TUNNELING      = 2116845,
        SPELL_RUPTURE        = 2116846,
        SPELL_ENRAGE         = 2116852,
        SPELL_DUST_DEVIL     = 2116853,
    };

    enum Misc
    {
        GROUP_EMERGED          = 0,
        GROUP_PHASE_TRANSITION = 1,
        NPC_DIRT_MOUND         = 15712,
        NPC_WORLD_TRIGGER      = 12999,
        GO_SANDWORM_BASE       = 180795,
        DATA_OURO_HEALTH       = 0,
        STONE_AT               = 20
    };

    struct boss_ouro_coa : public BossAI
    {
        boss_ouro_coa(Creature* creature) : BossAI(creature, DATA_OURO)
        {
            me->SetCombatMovement(false);
            me->SetControlled(true, UNIT_STATE_ROOT);
        }

        bool CanAIAttack(Unit const* victim) const override
        {
            return me->IsWithinMeleeRange(victim);
        }

        void Reset() override
        {
            instance->SetBossState(DATA_OURO, NOT_STARTED);
            scheduler.CancelAll();
            _submergeMelee = 0;
            _submerged = false;
            _enraged = false;
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);
            if (_enraged || !me->HealthBelowPctDamaged(20, damage))
                return;
            _enraged = true;
            DoCastSelf(SPELL_ENRAGE, true);
            DoCastSelf(SPELL_SEISMIC, true);
            scheduler.CancelGroup(GROUP_PHASE_TRANSITION);
            scheduler.Schedule(20s, [this](TaskContext context)
            {
                DoCastSelf(SPELL_SUMMON_OURO_MOUNDS, true);
                TunnelMounds();
                context.Repeat();
            });
        }

        // The mounds tunnel through the raid.
        void TunnelMounds()
        {
            std::list<Creature*> mounds;
            me->GetCreatureListWithEntryInGrid(mounds, NPC_DIRT_MOUND, 200.0f);
            for (Creature* mound : mounds)
                if (!mound->HasAura(SPELL_TUNNELING))
                    mound->AddAura(SPELL_TUNNELING, mound);
        }

        void DustDevils()
        {
            for (uint8 i = 0; i < 2; ++i)
                if (Creature* devil = me->SummonCreature(NPC_WORLD_TRIGGER, me->GetRandomNearPosition(30.0f), TEMPSUMMON_TIMED_DESPAWN, 30000))
                {
                    devil->SetFaction(me->GetFaction());
                    devil->AddAura(SPELL_DUST_DEVIL, devil);
                    devil->SetWalk(false);
                    devil->GetMotionMaster()->MoveRandom(40.0f);
                }
        }

        void Submerge()
        {
            if (_enraged || _submerged)
                return;
            me->AttackStop();
            me->SetReactState(REACT_PASSIVE);
            me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            _submergeMelee = 0;
            _submerged = true;
            DoCastSelf(SPELL_OURO_SUBMERGE_VISUAL);
            scheduler.CancelGroup(GROUP_EMERGED);
            scheduler.CancelGroup(GROUP_PHASE_TRANSITION);
            if (GameObject* base = me->FindNearestGameObject(GO_SANDWORM_BASE, 10.0f))
            {
                base->Use(me);
                base->DespawnOrUnsummon(6s);
            }
            DoCastSelf(SPELL_SUMMON_OURO_MOUNDS, true);
            TunnelMounds();
            DustDevils();

            // From stock: one mound carries him back, with his health.
            std::list<Creature*> mounds;
            me->GetCreatureListWithEntryInGrid(mounds, NPC_DIRT_MOUND, 200.0f);
            if (!mounds.empty())
                if (Creature* mound = Acore::Containers::SelectRandomContainerElement(mounds))
                {
                    mound->AddAura(SPELL_SUMMON_OURO_AURA, mound);
                    mound->AI()->SetData(DATA_OURO_HEALTH, me->GetHealth());
                }
            me->DespawnOrUnsummon(1s);
        }

        void GroundRupture()
        {
            std::list<WorldObject*> targets;
            Acore::AllWorldObjectsInRange checker(me, 10.0f);
            Acore::WorldObjectListSearcher<Acore::AllWorldObjectsInRange> searcher(me, targets, checker);
            Cell::VisitObjects(me, searcher, 10.0f);
            for (WorldObject* target : targets)
                if (Unit* unit = target->ToUnit())
                    if (unit->IsHostileTo(me))
                        DoCast(unit, SPELL_GROUND_RUPTURE, true);
            DoCastSelf(SPELL_RUPTURE, true);
        }

        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            // From stock: whoever the breath catches loses his threat.
            if (target && spell->Id == sSpellMgr->GetSpellIdForDifficulty(SPELL_SAND_BREATH + 1, me))
                me->GetThreatMgr().ModifyThreatByPercent(target, -100);
        }

        // Twenty stacks of Sand Coat: stone.
        void Petrify()
        {
            for (Player* p : Players(me, [](Player* x) { return x->HasAura(SPELL_SAND_COAT); }))
                if (Aura* coat = p->GetAura(SPELL_SAND_COAT))
                    if (coat->GetStackAmount() >= STONE_AT)
                    {
                        p->RemoveAurasDueToSpell(SPELL_SAND_COAT);
                        me->AddAura(SPELL_STONED, p);
                    }
        }

        void Emerge()
        {
            DoCastSelf(SPELL_BIRTH);
            DoCastSelf(SPELL_SUMMON_SANDWORM_BASE, true);
            me->SetReactState(REACT_AGGRESSIVE);
            GroundRupture();

            scheduler.Schedule(15s, GROUP_EMERGED, [this](TaskContext context)
            {
                if (Unit* target = SelectTarget(SelectTargetMethod::MaxThreat, 0, 0.0f, true))
                    me->SetTarget(target->GetGUID());
                DoCastVictim(SPELL_SAND_BREATH);
                context.Repeat(20s);
            }).Schedule(22s, GROUP_EMERGED, [this](TaskContext context)
            {
                DoCastSelf(SPELL_SWEEP);
                context.Repeat(22s);
            }).Schedule(30s, GROUP_EMERGED, [this](TaskContext context)
            {
                DoCastVictim(SPELL_ACIDIC_BREATH);
                context.Repeat(30s);
            }).Schedule(8s, GROUP_EMERGED, [this](TaskContext context)
            {
                if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                    DoCast(target, SPELL_POISON_SPIT);
                context.Repeat(12s);
            }).Schedule(1s, [this](TaskContext context)
            {
                if (!me->IsWithinMeleeRange(me->GetVictim()) && !me->HasUnitState(UNIT_STATE_CASTING))
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                        DoCast(target, SPELL_BOULDER);
                Petrify();
                context.Repeat(1s);
            }).Schedule(90s, GROUP_PHASE_TRANSITION, [this](TaskContext)
            {
                Submerge();
            }).Schedule(3s, GROUP_PHASE_TRANSITION, [this](TaskContext context)
            {
                if (_enraged)
                    return;
                if (!me->IsWithinMeleeRange(me->GetVictim()) && !_submerged)
                {
                    if (++_submergeMelee >= 10)
                    {
                        Submerge();
                        _submergeMelee = 0;
                    }
                }
                else
                    _submergeMelee = 0;
                if (!_submerged)
                    context.Repeat(1s);
            });
        }

        void EnterEvadeMode(EvadeReason /*why*/) override
        {
            if (me->GetThreatMgr().IsThreatListEmpty())
            {
                DoCastSelf(SPELL_OURO_SUBMERGE_VISUAL);
                me->DespawnOrUnsummon(1s);
                instance->SetBossState(DATA_OURO, FAIL);
                if (GameObject* base = me->FindNearestGameObject(GO_SANDWORM_BASE, 200.0f))
                    base->DespawnOrUnsummon();
            }
        }

        void JustEngagedWith(Unit* who) override
        {
            Emerge();
            BossAI::JustEngagedWith(who);
        }

        void UpdateAI(uint32 diff) override
        {
            UpdateVictim();
            if (me->HasUnitState(UNIT_STATE_CASTING))
            {
                scheduler.Update(diff);
                return;
            }
            scheduler.Update(diff, [this] { DoMeleeAttackIfReady(); });
        }

    private:
        bool _enraged = false;
        uint8 _submergeMelee = 0;
        bool _submerged = false;
    };
}

void AddCoaOuroScripts()
{
    RegisterTempleOfAhnQirajCreatureAI(boss_ouro_coa);
}
