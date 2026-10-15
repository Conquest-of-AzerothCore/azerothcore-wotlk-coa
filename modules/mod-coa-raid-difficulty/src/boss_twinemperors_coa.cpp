/*
 * The Twin Emperors as Ascension rebuilt them.
 *
 * Kit: Ascension's block 2116600-2116668. No logs or video exist for
 * Ahn'Qiraj; every timer here is designed.
 *
 * From stock: the intro when the raid enters, the swap of places, the enrage
 * at 15 minutes, Vek'lor keeping his distance. The bugs are gone.
 *
 * The Emperor's Bond. Within 50 yards of each other they restore 1% of their
 * health every second, and half of what either takes also hits the other.
 * Vek'lor takes 33% less physical damage, Vek'nilash 33% less magic damage.
 * Whoever has more health holds the upper hand; at every swap he gains a
 * stack of The Emperor's Strength (Vek'nilash) or Wit (Vek'lor), +5% damage
 * and speed.
 *
 *   The Emperor's Passage  first 30s, every 35s   3s cast by Vek'lor, then
 *                                                 they swap places
 *   Vek'nilash
 *     Unbalancing Strike   first 12s, every 15s   4s cast, alternately a cone
 *                          in front (5 impacts) and a ring around him (8
 *                          impacts, 26 yards). The impact spots show for the
 *                          whole cast. Hit: weapon damage and +10% physical
 *                          damage taken, stacking. Dodged: a stack of Momentum;
 *                          five give Opportunity, and the next special attack
 *                          becomes an Opportunistic Strike.
 *   Vek'lor
 *     Bolt of Destruction  first 4s, every 4s     3s cast, 4 yards around his
 *                                                 target
 *     Test of Faith        first 20s, every 20s   4s cast, tentacles under six
 *                          players. Hit: Shadow damage and +10% shadow damage
 *                          taken, stacking. Passed: a stack of Favour; five
 *                          give The Master's Pleasure, and the next special
 *                          attack applies The Master's Rebuke.
 *
 * Decided here, not in the data: every timer, the number and layout of impact
 * spots, who counts as having dodged (everyone within reach who was not hit),
 * and leaving out the block's Breath of the Old God, Reanimate Anubisath and
 * Blast Wave: nothing ties them to the emperors.
 */

#include "Containers.h"
#include "CreatureScript.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "../../../src/server/scripts/Kalimdor/TempleOfAhnQiraj/temple_of_ahnqiraj.h"
#include "zg_coa_common.h"

using namespace coa_zg;

namespace
{
    enum Spells
    {
        SPELL_TWIN_TELEPORT_1      = 800,
        SPELL_TWIN_TELEPORT_VISUAL = 26638,
        SPELL_FRENZY               = 27897,
        SPELL_BERSERK              = 27680,

        SPELL_BOND_HEAL       = 2116600,
        SPELL_PASSAGE         = 2116601,
        SPELL_STRENGTH        = 2116604,
        SPELL_WIT             = 2116605,
        SPELL_GIFT_VEKLOR     = 2116606,
        SPELL_GIFT_VEKNILASH  = 2116607,
        SPELL_UPPER_HAND      = 2116608,
        SPELL_STRIKE_CONE     = 2116610,
        SPELL_STRIKE_SPOT     = 2116611,
        SPELL_STRIKE_HIT      = 2116613,
        SPELL_MOMENTUM        = 2116617,
        SPELL_OPPORTUNITY     = 2116618,
        SPELL_STRIKE_RING     = 2116623,
        SPELL_BOND            = 2116630,
        SPELL_TEST_OF_FAITH   = 2116650,
        SPELL_FAITH_SPOT      = 2116651,
        SPELL_FAITH_HIT       = 2116652,
        SPELL_FAVOUR          = 2116658,
        SPELL_PLEASURE        = 2116659,
        SPELL_BOLT            = 2116664,
    };

    enum Actions
    {
        ACTION_START_INTRO    = 0,
        ACTION_CANCEL_INTRO   = 1,
        ACTION_AFTER_TELEPORT = 2
    };

    enum Say
    {
        SAY_INTRO_0  = 0,
        SAY_INTRO_1  = 1,
        SAY_INTRO_2  = 2,
        SAY_KILL     = 3,
        SAY_DEATH    = 4,
        EMOTE_ENRAGE = 5
    };

    enum Misc
    {
        GROUP_INTRO       = 0,
        NPC_WORLD_TRIGGER = 12999,
        SOUND_VK_AGGRO    = 8657,
        SOUND_VN_AGGRO    = 8661,
        STACKS_FOR_REWARD = 5
    };

    constexpr float BOND_RANGE   = 50.0f;
    constexpr float IMPACT_RANGE = 4.0f;
    constexpr float FAITH_RANGE  = 5.0f;
    constexpr float veklorOrientationIntro    = 2.241519f;
    constexpr float veknilashOrientationIntro = 1.144451f;

    // Everyone within reach who was not hit builds up a reward stack.
    void Reward(Creature* me, std::vector<Player*> const& inReach, std::vector<Player*> const& hit, uint32 stack, uint32 reward)
    {
        for (Player* p : inReach)
        {
            if (std::find(hit.begin(), hit.end(), p) != hit.end())
                continue;
            AddStack(me, p, stack);
            Aura* a = p->GetAura(stack);
            if (a && a->GetStackAmount() >= STACKS_FOR_REWARD)
            {
                p->RemoveAurasDueToSpell(stack);
                me->AddAura(reward, p);
            }
        }
    }

    struct boss_twin_coa : public BossAI
    {
        boss_twin_coa(Creature* creature) : BossAI(creature, DATA_TWIN_EMPERORS)
        {
            me->SetStandState(UNIT_STAND_STATE_KNEEL);
        }

        virtual bool IAmVeklor() const = 0;

        Creature* GetTwin()
        {
            return instance->GetCreature(IAmVeklor() ? DATA_VEKNILASH : DATA_VEKLOR);
        }

        void Reset() override
        {
            BossAI::Reset();
            for (uint32 s : { SPELL_STRENGTH, SPELL_WIT, SPELL_UPPER_HAND })
                me->RemoveAurasDueToSpell(s);
        }

        // Half of what either emperor takes also hits his brother.
        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);
            if (!attacker || !damage)
                return;
            if (attacker->GetEntry() == NPC_VEKLOR || attacker->GetEntry() == NPC_VEKNILASH)
            {
                me->LowerPlayerDamageReq(damage);
                return;
            }
            if (Creature* twin = GetTwin())
                if (twin->IsAlive())
                    Unit::DealDamage(me, twin, damage / 2, nullptr, type, school, nullptr, false);
        }

        void KilledUnit(Unit* victim) override
        {
            if (victim && victim->IsPlayer())
                Talk(SAY_KILL);
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            BossAI::EnterEvadeMode(why);
            if (Creature* twin = GetTwin())
                if (!twin->IsInEvadeMode())
                    twin->AI()->EnterEvadeMode(why);
        }

        void JustDied(Unit* killer) override
        {
            if (Creature* twin = GetTwin())
                if (twin->IsAlive())
                    Unit::Kill(me, twin);
            Talk(SAY_DEATH);
            BossAI::JustDied(killer);
        }

        // From stock: the intro, and settling in after a swap.
        void DoAction(int32 action) override
        {
            if (action == ACTION_CANCEL_INTRO)
            {
                _introDone = true;
                scheduler.CancelGroup(GROUP_INTRO);
                return;
            }
            if (action == ACTION_AFTER_TELEPORT)
            {
                DoResetThreatList();
                me->SetReactState(REACT_PASSIVE);
                DoCastSelf(SPELL_TWIN_TELEPORT_VISUAL, true);
                scheduler.DelayAll(2300ms);
                scheduler.Schedule(2s, [this](TaskContext)
                {
                    me->SetReactState(REACT_AGGRESSIVE);
                    me->SetControlled(false, UNIT_STATE_ROOT);
                    if (Unit* victim = me->SelectNearestTarget())
                    {
                        me->AddThreat(victim, 2000.0f);
                        AttackStart(victim);
                    }
                });
                return;
            }
            if (action != ACTION_START_INTRO)
                return;

            scheduler.Schedule(5s, [this](TaskContext)
            {
                me->SetStandState(UNIT_STAND_STATE_STAND);
                me->LoadEquipment(1, true);
            });
            bool const vl = IAmVeklor();
            scheduler.Schedule(vl ? 12s : 17s, GROUP_INTRO, [this](TaskContext) { Talk(SAY_INTRO_0); })
                .Schedule(vl ? 20s : 23s, GROUP_INTRO, [this](TaskContext) { Talk(SAY_INTRO_1); })
                .Schedule(28s, GROUP_INTRO, [this](TaskContext) { me->HandleEmoteCommand(EMOTE_ONESHOT_ROAR); })
                .Schedule(vl ? 30s : 32s, GROUP_INTRO, [this, vl](TaskContext)
                {
                    me->SetFacingTo(vl ? veklorOrientationIntro : veknilashOrientationIntro);
                    Talk(SAY_INTRO_2);
                })
                .Schedule(33s, GROUP_INTRO, [this](TaskContext)
                {
                    me->HandleEmoteCommand(EMOTE_ONESHOT_POINT);
                    _introDone = true;
                });
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            if (!_introDone)
            {
                DoAction(ACTION_CANCEL_INTRO);
                if (Creature* twin = GetTwin())
                    twin->AI()->DoAction(ACTION_CANCEL_INTRO);
            }
            if (Creature* twin = GetTwin())
                if (!twin->IsInCombat())
                    twin->AI()->AttackStart(who);

            me->AddAura(SPELL_BOND, me);
            me->AddAura(IAmVeklor() ? SPELL_GIFT_VEKLOR : SPELL_GIFT_VEKNILASH, me);

            scheduler.Schedule(15min, [this](TaskContext)
            {
                if (IAmVeklor())
                {
                    DoCastSelf(SPELL_FRENZY, true);
                    Talk(EMOTE_ENRAGE);
                }
                else
                    DoCastSelf(SPELL_BERSERK, true);
            }).Schedule(1s, [this](TaskContext context)
            {
                // The bond heals while they stand together; the upper hand is
                // whoever has more health.
                Creature* twin = GetTwin();
                if (twin && twin->IsAlive() && me->IsWithinDist(twin, BOND_RANGE))
                    me->CastSpell(me, SPELL_BOND_HEAL, true);
                bool const upper = twin && me->GetHealthPct() > twin->GetHealthPct();
                if (upper && !me->HasAura(SPELL_UPPER_HAND))
                    me->AddAura(SPELL_UPPER_HAND, me);
                else if (!upper)
                    me->RemoveAurasDueToSpell(SPELL_UPPER_HAND);
                context.Repeat();
            });
        }

        // After every swap the one holding the upper hand grows stronger.
        void AfterSwap()
        {
            if (me->HasAura(SPELL_UPPER_HAND))
                AddStack(me, me, IAmVeklor() ? SPELL_WIT : SPELL_STRENGTH);
            DoAction(ACTION_AFTER_TELEPORT);
        }

        void SpotCast(Position const& pos, uint32 spell, uint32 lifeMs)
        {
            if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, pos, TEMPSUMMON_TIMED_DESPAWN, lifeMs))
            {
                spot->SetFaction(me->GetFaction());
                spot->CastSpell(spot, spell, true, nullptr, nullptr, me->GetGUID());
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim() && _introDone)
                return;

            scheduler.Update(diff, [this]
            {
                if (!IAmVeklor())
                    DoMeleeAttackIfReady();
            });
        }

    protected:
        bool _introDone = false;
    };

    struct boss_veknilash_coa : public boss_twin_coa
    {
        boss_veknilash_coa(Creature* creature) : boss_twin_coa(creature) { }

        bool IAmVeklor() const override { return false; }

        void JustEngagedWith(Unit* who) override
        {
            boss_twin_coa::JustEngagedWith(who);
            DoPlaySoundToSet(me, SOUND_VN_AGGRO);
            scheduler.Schedule(12s, [this](TaskContext context)
            {
                Strike();
                context.Repeat(15s);
            });
        }

        // Mark the impact spots for the whole cast, then strike them.
        void Strike()
        {
            bool const ring = _ring;
            _ring = !_ring;
            _spots.clear();
            uint8 const count = ring ? 8 : 5;
            for (uint8 i = 0; i < count; ++i)
            {
                Position pos = me->GetPosition();
                float const angle = ring ? 2 * float(M_PI) * i / count + frand(-0.2f, 0.2f)
                                         : frand(-float(M_PI) / 6, float(M_PI) / 6);
                me->MovePosition(pos, ring ? frand(8.0f, 26.0f) : 6.0f + 5.0f * i, angle);
                _spots.push_back(pos);
                SpotCast(pos, SPELL_STRIKE_SPOT, 5000);
            }
            _reach = ring ? 26.0f : 30.0f;
            DoCastVictim(ring ? SPELL_STRIKE_RING : SPELL_STRIKE_CONE);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);
            if (spell->Id != SPELL_STRIKE_CONE && spell->Id != SPELL_STRIKE_RING)
                return;

            std::vector<Player*> hit;
            for (Player* p : PlayersWithin(me, _reach))
                for (Position const& spot : _spots)
                    if (p->GetExactDist(&spot) <= IMPACT_RANGE)
                    {
                        me->CastSpell(p, SPELL_STRIKE_HIT, true);
                        hit.push_back(p);
                        break;
                    }
            Reward(me, PlayersWithin(me, _reach), hit, SPELL_MOMENTUM, SPELL_OPPORTUNITY);
        }

    private:
        bool _ring = false;
        float _reach = 30.0f;
        std::vector<Position> _spots;
    };

    struct boss_veklor_coa : public boss_twin_coa
    {
        boss_veklor_coa(Creature* creature) : boss_twin_coa(creature) { }

        bool IAmVeklor() const override { return true; }

        void JustEngagedWith(Unit* who) override
        {
            boss_twin_coa::JustEngagedWith(who);
            DoPlaySoundToSet(me, SOUND_VK_AGGRO);
            scheduler.Schedule(4s, [this](TaskContext context)
            {
                if (Unit* victim = me->GetVictim())
                {
                    if (!me->IsWithinDist(victim, 45.0f))
                        me->GetMotionMaster()->MoveChase(victim, 45.0f, 0);
                    else
                    {
                        me->StopMoving();
                        me->GetMotionMaster()->Clear();
                    }
                }
                DoCastVictim(SPELL_BOLT);
                context.Repeat(4s);
            }).Schedule(20s, [this](TaskContext context)
            {
                Faith();
                context.Repeat(20s);
            }).Schedule(30s, [this](TaskContext context)
            {
                DoCastSelf(SPELL_PASSAGE);
                context.Repeat(35s);
            });
        }

        void Faith()
        {
            _spots.clear();
            std::vector<Player*> players = PlayersWithin(me, 60.0f);
            Acore::Containers::RandomResize(players, 6);
            for (Player* p : players)
            {
                _spots.push_back(p->GetPosition());
                SpotCast(p->GetPosition(), SPELL_FAITH_SPOT, 5000);
            }
            DoCastSelf(SPELL_TEST_OF_FAITH);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);
            if (spell->Id == SPELL_TEST_OF_FAITH)
            {
                std::vector<Player*> hit;
                for (Position const& spot : _spots)
                {
                    SpotCast(spot, SPELL_FAITH_HIT, 2000);
                    for (Player* p : PlayersWithin(me, 100.0f))
                        if (p->GetExactDist(&spot) <= FAITH_RANGE && std::find(hit.begin(), hit.end(), p) == hit.end())
                            hit.push_back(p);
                }
                Reward(me, PlayersWithin(me, 60.0f), hit, SPELL_FAVOUR, SPELL_PLEASURE);
            }
            else if (spell->Id == SPELL_PASSAGE)
                Swap();
        }

        // From stock: they trade places.
        void Swap()
        {
            Creature* veknilash = GetTwin();
            if (!veknilash)
                return;
            DoCastSelf(SPELL_TWIN_TELEPORT_1, true);
            me->SetControlled(true, UNIT_STATE_ROOT);
            Position mine = me->GetPosition();
            Position his = veknilash->GetPosition();
            me->NearTeleportTo(his);
            veknilash->CastSpell(veknilash, SPELL_TWIN_TELEPORT_1, true);
            veknilash->SetControlled(true, UNIT_STATE_ROOT);
            veknilash->NearTeleportTo(mine);
            if (auto* ai = dynamic_cast<boss_twin_coa*>(veknilash->AI()))
                ai->AfterSwap();
            AfterSwap();
        }

        // From stock: Vek'lor does not melee.
        void AttackStart(Unit* who) override
        {
            if (who && who->isTargetableForAttack() && me->GetReactState() != REACT_PASSIVE)
                if (me->Attack(who, false))
                {
                    me->GetMotionMaster()->MoveChase(who, 45.0f, 0);
                    me->AddThreat(who, 0.0f);
                }
        }

    private:
        std::vector<Position> _spots;
    };
}

void AddCoaTwinEmperorsScripts()
{
    RegisterTempleOfAhnQirajCreatureAI(boss_veknilash_coa);
    RegisterTempleOfAhnQirajCreatureAI(boss_veklor_coa);
}
