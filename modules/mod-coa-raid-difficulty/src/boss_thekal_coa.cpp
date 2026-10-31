/*
 * High Priest Thekal with Ascension's spells.
 *
 * Kit: Ascension's block 2118200-2118243. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json. Disrupting Shout's repeat
 * and Fierce Blow follow the CoA combat log of 2026-08-02.
 *
 * From stock: the fight with Zealot Lor'Khan and Zealot Zath. The zealots keep
 * their stock scripts, with the spells of the log.
 *
 * Not from stock, after the CoA log of 2026-08-02: no false death, no zealots
 * rising again and no tiger phase at full health. In the log Lor'Khan and Zath
 * died and stayed dead, Thekal never fell to zero, and he went from about 46%
 * into his tiger kit without being healed. As the other priests, at 50% he
 * drains the Avatar of Shirvallah (see LoaAvatar), taking ~1% damage while it
 * dies; then the Gift of the Blood God and his tiger form (Shredding Claws in
 * the log 0.3 seconds before the avatar's death).
 *
 *   Troll form
 *     Mortal Cleave    first 4s,  every 13s   cone in front, -25% healing taken
 *     Disrupting Shout first 9s,  every 25.8s 20 yards, interrupts
 *     Bloodlust        first 16s, every 30s   himself or a zealot
 *
 *   Tiger form (his Aspect of Shirvallah), when the avatar dies
 *     Rending Swipe    first 4s,  every 14s   cone in front, bleeds (Rip)
 *     War Stomp        first 12s, every 40s   50 yards, knocks back
 *     Speed Slash      first 14s, every 40s   runs through the raid for 8s,
 *                                             cutting everyone he passes
 *     Shredding Claws  passive, armour down on hit
 *     Summon Tigers, frenzy every 30s and enrage at 20% from stock
 *
 *   Both forms
 *     Fierce Blow      first 6.7-17.3s, every 6-10s   on the tank
 *
 * Decided here, not in the data:
 *   - which spells belong to which form. The video shows all of them in one
 *     stretch below 75%; the split follows the spell names (troll priest,
 *     tiger claws);
 *   - Speed Slash ends after 8 seconds (its aura never runs out by itself);
 *   - Force Punch and the stock charge are gone, the tiger kit replaces them.
 */

#include "CreatureScript.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

using namespace coa_zg;

namespace
{
    enum Says
    {
        SAY_AGGRO = 0,
        SAY_DEATH = 1
    };

    enum Spells
    {
        SPELL_SUMMONTIGERS               = 24183,
        SPELL_FRENZY                     = 8269,

        SPELL_MORTAL_CLEAVE        = 2118201,
        SPELL_MORTAL_CLEAVE_HIT    = 2118202,
        SPELL_MORTAL_WOUND         = 2118203,
        SPELL_BLOODLUST            = 2118204,
        SPELL_DISRUPTING_SHOUT     = 2118205,
        SPELL_DISRUPTING_SHOUT_HIT = 2118206,
        SPELL_DRAIN_POWER          = 2118222,
        SPELL_ASPECT_OF_SHIRVALLAH = 2118223,
        SPELL_GIFT_OF_THE_BLOOD_GOD = 2118224,
        SPELL_SHREDDING_CLAWS      = 2118225,
        SPELL_WAR_STOMP            = 2118227,
        SPELL_WAR_STOMP_HIT        = 2118228,
        SPELL_SPEED_SLASH          = 2118232,
        SPELL_RENDING_SWIPE        = 2118238,
        SPELL_RENDING_SWIPE_HIT    = 2118239,
        SPELL_RIP                  = 2118240,

        SPELL_SINISTER_STRIKE      = 2118250,
        SPELL_SINISTER_STRIKE_HIT  = 2118251,
        SPELL_BLIND                = 2118252,
        SPELL_BLIND_HIT            = 2118253,
        SPELL_STORM_SHIELD_AURA    = 2118262,
        SPELL_STORM_SHIELD_HIT     = 2118263,
    };

    constexpr uint32 NPC_AVATAR_OF_SHIRVALLAH = 666989;

    constexpr uint32 GROUP_TROLL = 1;
    constexpr uint32 GROUP_TIGER = 2;

    constexpr float CLEAVE_RANGE = 10.0f;
    constexpr float CLEAVE_ARC   = float(M_PI) / 2;

    constexpr uint8 STORM_SHIELD_CHARGES = 20;

    struct boss_thekal_coa : public BossAI
    {
        boss_thekal_coa(Creature* creature) : BossAI(creature, DATA_THEKAL) { }

        void Reset() override
        {
            _Reset();
            _drained = false;
            _avatar.Restore(me);
            scheduler.CancelAll();
            me->RemoveAurasDueToSpell(SPELL_FRENZY);
            me->RemoveAurasDueToSpell(SPELL_GIFT_OF_THE_BLOOD_GOD);
            me->RemoveAurasDueToSpell(SPELL_ASPECT_OF_SHIRVALLAH);
            me->RemoveAurasDueToSpell(SPELL_SHREDDING_CLAWS);
            me->RemoveAurasDueToSpell(SPELL_SPEED_SLASH);
            me->LoadEquipment(1, true);

            if (Creature* zealot = instance->GetCreature(DATA_LORKHAN))
                zealot->AI()->Reset();
            if (Creature* zealot = instance->GetCreature(DATA_ZATH))
                zealot->AI()->Reset();
        }

        void JustDied(Unit* /*killer*/) override
        {
            _JustDied();
            _avatar.Release(me);
            Talk(SAY_DEATH);
            if (Creature* zealot = instance->GetCreature(DATA_LORKHAN))
                zealot->Kill(zealot, zealot);
            if (Creature* zealot = instance->GetCreature(DATA_ZATH))
                zealot->Kill(zealot, zealot);
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _JustEngagedWith();
            _avatar.Restore(me);
            scheduler.CancelAll();
            ScheduleTroll();
        }

        void ScheduleTroll()
        {
            scheduler.Schedule(4s, GROUP_TROLL, [this](TaskContext context)
            {
                DoCastVictim(SPELL_MORTAL_CLEAVE);
                context.Repeat(13s);
            }).Schedule(9s, GROUP_TROLL, [this](TaskContext context)
            {
                DoCastSelf(SPELL_DISRUPTING_SHOUT);
                context.Repeat(25800ms);
            }).Schedule(16s, GROUP_TROLL, [this](TaskContext context)
            {
                Bloodlust();
                context.Repeat(30s);
            });
            ScheduleFierceBlow(GROUP_TROLL);
        }

        void ScheduleFierceBlow(uint32 group)
        {
            scheduler.Schedule(FIERCE_BLOW_FIRST_MIN, FIERCE_BLOW_FIRST_MAX, group, [this](TaskContext context)
            {
                DoCastVictim(SPELL_FIERCE_BLOW);
                context.Repeat(FIERCE_BLOW_MIN, FIERCE_BLOW_MAX);
            });
        }

        void ScheduleTiger()
        {
            scheduler.Schedule(4s, [this](TaskContext context)
            {
                DoCastVictim(SPELL_RENDING_SWIPE);
                context.Repeat(14s);
            }).Schedule(12s, [this](TaskContext context)
            {
                DoCastSelf(SPELL_WAR_STOMP);
                context.Repeat(40s);
            }).Schedule(14s, [this](TaskContext context)
            {
                DoCastSelf(SPELL_SPEED_SLASH);
                context.Schedule(10s, [this](TaskContext)
                {
                    me->RemoveAurasDueToSpell(SPELL_SPEED_SLASH);
                });
                context.Repeat(40s);
            }).Schedule(30s, [this](TaskContext context)
            {
                DoCastSelf(SPELL_FRENZY);
                context.Repeat();
            }).Schedule(25s, [this](TaskContext context)
            {
                DoCastVictim(SPELL_SUMMONTIGERS, true);
                context.Repeat(10s, 14s);
            });
            ScheduleFierceBlow(GROUP_TIGER);
            ScheduleHealthCheckEvent(20, [this]
            {
                DoCastSelf(SPELL_FRENZY);
            });
        }

        // Bloodlust goes on whoever of the three is lowest.
        void Bloodlust()
        {
            Unit* target = me;
            for (uint32 data : { DATA_LORKHAN, DATA_ZATH })
                if (Creature* zealot = instance->GetCreature(data))
                    if (zealot->IsAlive() && zealot->IsInCombat() && zealot->GetHealthPct() < target->GetHealthPct())
                        target = zealot;
            DoCast(target, SPELL_BLOODLUST);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_MORTAL_CLEAVE:
                    for (Player* p : PlayersInFront(me, CLEAVE_RANGE, CLEAVE_ARC))
                    {
                        me->CastSpell(p, SPELL_MORTAL_CLEAVE_HIT, true);
                        me->CastSpell(p, SPELL_MORTAL_WOUND, true);
                    }
                    break;
                case SPELL_RENDING_SWIPE:
                    for (Player* p : PlayersInFront(me, CLEAVE_RANGE, CLEAVE_ARC))
                    {
                        me->CastSpell(p, SPELL_RENDING_SWIPE_HIT, true);
                        me->CastSpell(p, SPELL_RIP, true);
                    }
                    break;
                case SPELL_DISRUPTING_SHOUT:
                    me->CastSpell(me, SPELL_DISRUPTING_SHOUT_HIT, true);
                    break;
                case SPELL_WAR_STOMP:
                    me->CastSpell(me, SPELL_WAR_STOMP_HIT, true);
                    break;
                default:
                    break;
            }
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            _avatar.Release(me);
            BossAI::EnterEvadeMode(why);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);

            if (_drained || !me->HealthBelowPctDamaged(50, damage))
                return;

            _drained = true;
            if (!_avatar.Drain(me))
                TakeTigerForm();
        }

        void TakeTigerForm()
        {
            me->InterruptNonMeleeSpells(false);
            scheduler.CancelGroup(GROUP_TROLL);
            Talk(SAY_AGGRO);
            DoCastSelf(SPELL_GIFT_OF_THE_BLOOD_GOD, true);
            DoCastSelf(SPELL_ASPECT_OF_SHIRVALLAH, true);
            DoCastSelf(SPELL_SHREDDING_CLAWS, true);
            me->LoadEquipment(0, true);
            DoResetThreatList();
            ScheduleTiger();
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            if (_avatar.Consumed(me))
                TakeTigerForm();

            scheduler.Update(diff, [this]
            {
                DoMeleeAttackIfReady();
            });
        }

    private:
        bool _drained = false;
        LoaAvatar _avatar{ NPC_AVATAR_OF_SHIRVALLAH, SPELL_DRAIN_POWER };
    };

    // Zath's Sinister Strike and Blind are dummies with a cast bar; the hit lands with the cast.
    class spell_thekal_coa_zath_strike : public SpellScript
    {
        PrepareSpellScript(spell_thekal_coa_zath_strike);

        void HandleDummy(SpellEffIndex /*effIndex*/)
        {
            uint32 const hit = GetSpellInfo()->Id == SPELL_BLIND ? SPELL_BLIND_HIT : SPELL_SINISTER_STRIKE_HIT;
            if (Unit* target = GetHitUnit())
                GetCaster()->CastSpell(target, hit, true);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_thekal_coa_zath_strike::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };

    // Lor'Khan's Storm Shield puts 20 charges of lightning on its target, as in the log.
    class spell_thekal_coa_storm_shield : public SpellScript
    {
        PrepareSpellScript(spell_thekal_coa_storm_shield);

        void HandleDummy(SpellEffIndex /*effIndex*/)
        {
            Unit* target = GetHitUnit();
            if (!target)
                return;
            GetCaster()->CastSpell(target, SPELL_STORM_SHIELD_AURA, true);
            if (Aura* shield = target->GetAura(SPELL_STORM_SHIELD_AURA, GetCaster()->GetGUID()))
                shield->SetStackAmount(STORM_SHIELD_CHARGES);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_thekal_coa_storm_shield::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };

    // Each harmful spell on the shielded zealot costs a charge and strikes the attacker with lightning.
    class spell_thekal_coa_storm_shield_charge : public AuraScript
    {
        PrepareAuraScript(spell_thekal_coa_storm_shield_charge);

        bool CheckProc(ProcEventInfo& eventInfo)
        {
            Unit* attacker = eventInfo.GetActor();
            return attacker && attacker != GetTarget() && attacker->IsAlive()
                && GetTarget()->IsValidAttackTarget(attacker);
        }

        void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
        {
            PreventDefaultAction();
            GetTarget()->CastSpell(eventInfo.GetActor(), SPELL_STORM_SHIELD_HIT, true);
            ModStackAmount(-1);
        }

        void Register() override
        {
            DoCheckProc += AuraCheckProcFn(spell_thekal_coa_storm_shield_charge::CheckProc);
            OnEffectProc += AuraEffectProcFn(spell_thekal_coa_storm_shield_charge::HandleProc, EFFECT_0,
                SPELL_AURA_DUMMY);
        }
    };
}

void AddCoaThekalScripts()
{
    RegisterZulGurubCreatureAI(boss_thekal_coa);
    RegisterSpellScript(spell_thekal_coa_zath_strike);
    RegisterSpellScript(spell_thekal_coa_storm_shield);
    RegisterSpellScript(spell_thekal_coa_storm_shield_charge);
}
