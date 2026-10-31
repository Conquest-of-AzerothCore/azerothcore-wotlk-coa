/*
 * Hakkar the Soulflayer with Ascension's spells.
 *
 * Kit: Ascension's block 2118600-2118705. Hakkar has no cast bars in the video,
 * so the timings come from the Bronzebeard player's DBM (berserk 10 min, first
 * Blood Siphon at 90s, Will of Hakkar at 45s) and from the Heart of Hakkar
 * appearing on screen every 80-90 seconds. Blood Siphon, Blood Scythe and
 * Fierce Blow follow the CoA combat log of 2026-08-02.
 *
 *   Blood Siphon       first 59.5s,           20 seconds of draining everyone:
 *                      every 79.5s            Shadow damage every 2s, a stack of
 *                                             Anemia (-1% healing), Hakkar heals
 *                                             for it. A player with poisoned
 *                                             blood hurts him instead. While he
 *                                             drains, his Heart is exposed:
 *                                             damage to it goes to him, and 10%
 *                                             of his health dealt through it ends
 *                                             the siphon early.
 *   Corrupted Blood    first 25s, every 30s   everyone: stacking Plague damage
 *                                             that heals him; when it ends, a
 *                                             Pool of Corrupted Blood stays
 *   Will of Hakkar     first 45s, every 45s   a player feels it for 5s, then is
 *                                             his for 15s
 *   Blood Scythe       first 10s, every 15s   cone in front, -10% armour, stacks 10
 *   Sons of Hakkar     first 45s, every 60s   two join; where one dies its blood
 *                                             pools and poisons those inside
 *   Aspects            one for each High Priest still alive, +25% damage and
 *                      -10% damage taken each: at the pull he drains the Avatar
 *                      of each living priest's loa (Drain Power, -99% damage
 *                      taken while any of them lives) and gains its Aspect when
 *                      it dies
 *   Fierce Blow        tank, first 6.7-17.3s, then every 6-10s
 *   Berserk            at 10 minutes
 *
 * Decided here, not in the data:
 *   - the siphon's length, the heart's 10% and where the heart appears;
 *   - the DBM bar "Pet Wind Serpent" (every 60s) is read as the wave of Sons of
 *     Hakkar: the siphon mechanic needs poisoned blood, and the data says it
 *     comes from a Son of Hakkar. Two per wave;
 *   - the Aspects are Ascension's buffs instead of the stock aspect spells;
 *   - the avatars stand in a ring 10 yards around him (nothing in the data says
 *     where; his Drain Power has no range limit);
 *   - Animate Blood and Rain of Blood are left out (the
 *     Orb of Corrupted Blood exists nowhere in the data).
 * The Heart is creature 92005, as in the log: the stock one (15069) despawns itself.
 */

#include "CreatureScript.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

#include <algorithm>
#include <array>
#include <list>

using namespace coa_zg;

namespace
{
    enum Says
    {
        SAY_AGGRO = 0,
        SAY_EVADE = 7
    };

    enum Spells
    {
        SPELL_BERSERK             = 26662,
        SPELL_POISONOUS_BLOOD     = 24321,
        SPELL_POISONOUS_CLOUD     = 24320,

        SPELL_CORRUPTED_BLOOD     = 2118601,
        SPELL_CORRUPTED_BLOOD_HEAL = 2118605,
        SPELL_POOL_OF_CORRUPTED_BLOOD = 2118606,
        SPELL_BLOOD_SIPHON        = 2118615,
        SPELL_BLOOD_SIPHON_HIT    = 2118618,
        SPELL_BLOOD_SIPHON_HEAL   = 2118622,
        SPELL_ANEMIA              = 2118623,
        SPELL_POISONED_BLOOD      = 2118624,
        SPELL_BLOOD_SCYTHE        = 2118630,
        SPELL_BLOOD_SCYTHE_HIT    = 2118631,
        SPELL_BLOOD_SCYTHE_ARMOR  = 2118632,
        SPELL_WILL_SLIPPING       = 2118633,
        SPELL_WILL_CONTROL        = 2118634,
        SPELL_WILL_SHIELD         = 2118635,
        SPELL_WILL_RELEASED       = 2118636,
        SPELL_HEART_EXPOSED       = 2118650,
        SPELL_POOL_OF_POISONED_BLOOD = 2118675,
        SPELL_DRAIN_POWER         = 2118700,
        SPELL_ASPECT_OF_HIREEK    = 2118701,
        SPELL_ASPECT_OF_HETHISS   = 2118702,
        SPELL_ASPECT_OF_SHADRA    = 2118703,
        SPELL_ASPECT_OF_SHIRVALLAH = 2118704,
        SPELL_ASPECT_OF_BETHEKK   = 2118705,
    };

    enum Npcs
    {
        NPC_SON_OF_HAKKAR   = 11357,
        NPC_WORLD_TRIGGER   = 12999,
        NPC_HEART_OF_HAKKAR = 92005,
        NPC_AVATAR_OF_BETHEKK    = 666988,
        NPC_AVATAR_OF_SHIRVALLAH = 666989,
        NPC_AVATAR_OF_SHADRA     = 666990,
        NPC_AVATAR_OF_HETHISS    = 666991,
        NPC_AVATAR_OF_HIREEK     = 666992
    };

    enum Events
    {
        EVENT_BLOOD_SIPHON = 1,
        EVENT_SIPHON_TICK,
        EVENT_SIPHON_END,
        EVENT_CORRUPTED_BLOOD,
        EVENT_WILL_OF_HAKKAR,
        EVENT_WILL_CONTROL,
        EVENT_WILL_RELEASE,
        EVENT_BLOOD_SCYTHE,
        EVENT_SONS,
        EVENT_BERSERK,
        EVENT_FIERCE_BLOW,
    };

    enum Actions
    {
        ACTION_HEART_DAMAGE = 1
    };

    constexpr Milliseconds SIPHON_LENGTH = 20s;
    constexpr uint32 HEART_BREAK_PCT     = 10;
    constexpr float SCYTHE_RANGE         = 20.0f;
    constexpr float SCYTHE_ARC           = float(M_PI) / 2;
    constexpr float POOL_RADIUS          = 5.0f;
    constexpr uint8 SCYTHE_STACKS        = 10;
    constexpr float AVATAR_RING          = 10.0f;

    // The launch-day Normal kill (youtube c7iqfz04PmI) gives each player 2500 Runes of Ascension in one loot slot,
    // more than a loot row's 8-bit count holds, so they are handed out at his death instead.
    constexpr uint32 ITEM_RUNE_OF_ASCENSION = 375250;
    constexpr uint32 HAKKAR_RUNES           = 2500;

    struct PriestLoa
    {
        uint32 priest;
        uint32 aspect;
        LoaAvatar avatar;
    };

    struct boss_hakkar_coa : public BossAI
    {
        boss_hakkar_coa(Creature* creature) : BossAI(creature, DATA_HAKKAR) { }

        bool CheckInRoom() override
        {
            if (me->GetPositionZ() < 52.f || me->GetPositionZ() > 57.28f)
            {
                BossAI::EnterEvadeMode(EVADE_REASON_BOUNDARY);
                return false;
            }
            return true;
        }

        // From stock: a stack of Hakkar's Power for each High Priest alive.
        void ApplyHakkarPowerStacks()
        {
            me->RemoveAurasDueToSpell(SPELL_HAKKAR_POWER);
            for (int i = DATA_JEKLIK; i < DATA_HAKKAR; i++)
                if (instance->GetBossState(i) != DONE)
                    DoCastSelf(SPELL_HAKKAR_POWER, true);
        }

        void Reset() override
        {
            _Reset();
            ApplyHakkarPowerStacks();
            for (PriestLoa& loa : _loas)
            {
                loa.avatar.Despawn(me);
                me->RemoveAurasDueToSpell(loa.aspect);
            }
            _siphoning = false;
            _heartDamage = 0;
            _pools.clear();
            _clock.Reset();
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _JustEngagedWith();
            Talk(SAY_AGGRO);

            DrainLivingPriestsLoas();

            events.ScheduleEvent(EVENT_BLOOD_SCYTHE, 10s);
            events.ScheduleEvent(EVENT_CORRUPTED_BLOOD, 25s);
            events.ScheduleEvent(EVENT_WILL_OF_HAKKAR, 45s);
            events.ScheduleEvent(EVENT_SONS, 45s);
            events.ScheduleEvent(EVENT_BLOOD_SIPHON, 59500ms);
            events.ScheduleEvent(EVENT_FIERCE_BLOW, FIERCE_BLOW_FIRST_MIN, FIERCE_BLOW_FIRST_MAX);
            events.ScheduleEvent(EVENT_BERSERK, 10min);
        }

        // Ascension's aspects: one for each priest still standing, taken from its avatar.
        void DrainLivingPriestsLoas()
        {
            float angle = 0.0f;
            for (PriestLoa& loa : _loas)
            {
                if (instance->GetBossState(loa.priest) == DONE)
                    continue;
                loa.avatar.Summon(me, me->GetNearPosition(AVATAR_RING, angle));
                angle += 2 * float(M_PI) / _loas.size();
                if (!loa.avatar.Drain(me))
                    DoCastSelf(loa.aspect, true);
            }
        }

        void TakeConsumedAspects()
        {
            bool consumed = false;
            for (PriestLoa& loa : _loas)
            {
                if (!loa.avatar.Consumed(me, false))
                    continue;
                consumed = true;
                DoCastSelf(loa.aspect, true);
            }
            if (consumed && std::none_of(_loas.begin(), _loas.end(), [](PriestLoa const& loa) { return loa.avatar.Draining(); }))
                me->RemoveAurasDueToSpell(sSpellMgr->GetSpellIdForDifficulty(SPELL_DRAIN_POWER, me));
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            for (PriestLoa& loa : _loas)
                loa.avatar.Despawn(me);
            ClearWill();
            BossAI::EnterEvadeMode(why);
            Talk(SAY_EVADE);
        }

        void JustDied(Unit* killer) override
        {
            for (PriestLoa& loa : _loas)
                loa.avatar.Despawn(me);
            ClearWill();
            BossAI::JustDied(killer);
            GrantRunes();
        }

        void GrantRunes()
        {
            me->GetMap()->DoForAllPlayers([&](Player* player)
            {
                if (!player->IsGameMaster() && me->isTappedBy(player))
                    player->AddItem(ITEM_RUNE_OF_ASCENSION, HAKKAR_RUNES);
            });
        }

        // Where a Son of Hakkar dies, his blood pools.
        void SummonedCreatureDies(Creature* summon, Unit* killer) override
        {
            BossAI::SummonedCreatureDies(summon, killer);
            if (summon->GetEntry() != NPC_SON_OF_HAKKAR)
                return;
            if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, summon->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 20000))
            {
                spot->SetFaction(me->GetFaction());
                spot->CastSpell(spot, SPELL_POOL_OF_POISONED_BLOOD, true, nullptr, nullptr, me->GetGUID());
                _pools.push_back(spot->GetGUID());
            }
        }

        // The heart reports what it took.
        void SetData(uint32 type, uint32 value) override
        {
            if (type != ACTION_HEART_DAMAGE || !_siphoning)
                return;
            _heartDamage += value;
            if (_heartDamage >= me->CountPctFromMaxHealth(HEART_BREAK_PCT))
            {
                _clock.CancelEvent(EVENT_SIPHON_END);
                _clock.ScheduleEvent(EVENT_SIPHON_END, 0ms);
            }
        }

        bool PoisonedBlood(Player* p)
        {
            if (p->HasAura(SPELL_POISONOUS_BLOOD) || p->HasAura(SPELL_POISONOUS_CLOUD))
                return true;
            for (ObjectGuid const& guid : _pools)
                if (Creature* pool = ObjectAccessor::GetCreature(*me, guid))
                    if (pool->IsInWorld() && pool->IsWithinDist(p, POOL_RADIUS))
                        return true;
            return false;
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_BLOOD_SIPHON:
                {
                    _siphoning = true;
                    _heartDamage = 0;
                    Position pos = me->GetNearPosition(12.0f, 0.0f);
                    if (Creature* heart = me->SummonCreature(NPC_HEART_OF_HAKKAR, pos, TEMPSUMMON_MANUAL_DESPAWN))
                    {
                        heart->AddAura(SPELL_HEART_EXPOSED, heart);
                        _heart = heart->GetGUID();
                    }
                    _clock.ScheduleEvent(EVENT_SIPHON_TICK, 2s);
                    _clock.ScheduleEvent(EVENT_SIPHON_END, SIPHON_LENGTH);
                    break;
                }
                case SPELL_BLOOD_SCYTHE:
                    for (Player* p : PlayersInFront(me, SCYTHE_RANGE, SCYTHE_ARC))
                    {
                        me->CastSpell(p, SPELL_BLOOD_SCYTHE_HIT, true);
                        AddStack(me, p, SPELL_BLOOD_SCYTHE_ARMOR, SCYTHE_STACKS);
                    }
                    break;
                default:
                    break;
            }
        }

        void SiphonTick()
        {
            int32 const amount = Info(me, SPELL_BLOOD_SIPHON_HIT);
            int32 heal = 0;
            for (Player* p : Players(me, [](Player*) { return true; }))
            {
                if (PoisonedBlood(p))
                {
                    // The poison hurts him instead.
                    Hit(p, me, SPELL_POISONED_BLOOD, amount);
                    continue;
                }
                me->CastSpell(p, SPELL_BLOOD_SIPHON_HIT, true);
                AddStack(me, p, SPELL_ANEMIA);
                heal += amount;
            }
            if (heal > 0)
                me->CastCustomSpell(me, SPELL_BLOOD_SIPHON_HEAL, &heal, nullptr, nullptr, true);
        }

        void EndSiphon()
        {
            _siphoning = false;
            _clock.CancelEvent(EVENT_SIPHON_TICK);
            me->InterruptSpell(CURRENT_CHANNELED_SPELL);
            if (Creature* heart = ObjectAccessor::GetCreature(*me, _heart))
                heart->DespawnOrUnsummon();
            _heart.Clear();
        }

        void ClearWill()
        {
            if (Unit* target = ObjectAccessor::GetUnit(*me, _willTarget))
            {
                target->RemoveAurasDueToSpell(SPELL_WILL_SLIPPING);
                target->RemoveAurasDueToSpell(SPELL_WILL_CONTROL);
                target->RemoveAurasDueToSpell(SPELL_WILL_SHIELD);
            }
            _willTarget.Clear();
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim() || !CheckInRoom())
                return;

            TakeConsumedAspects();

            events.Update(diff);
            _clock.Update(diff);

            while (uint32 tick = _clock.ExecuteEvent())
            {
                switch (tick)
                {
                    case EVENT_SIPHON_TICK:
                        SiphonTick();
                        _clock.ScheduleEvent(EVENT_SIPHON_TICK, 2s);
                        break;
                    case EVENT_SIPHON_END:
                        EndSiphon();
                        break;
                    default:
                        break;
                }
            }

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_BLOOD_SIPHON:
                        DoCastSelf(SPELL_BLOOD_SIPHON);
                        events.ScheduleEvent(EVENT_BLOOD_SIPHON, 79500ms);
                        break;
                    case EVENT_CORRUPTED_BLOOD:
                        DoCastSelf(SPELL_CORRUPTED_BLOOD, true);
                        events.ScheduleEvent(EVENT_CORRUPTED_BLOOD, 30s);
                        break;
                    case EVENT_WILL_OF_HAKKAR:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 1, 60.0f, true))
                        {
                            _willTarget = target->GetGUID();
                            me->CastSpell(target, SPELL_WILL_SLIPPING, true);
                            events.ScheduleEvent(EVENT_WILL_CONTROL, 5s);
                        }
                        events.ScheduleEvent(EVENT_WILL_OF_HAKKAR, 45s);
                        break;
                    case EVENT_WILL_CONTROL:
                        if (Unit* target = ObjectAccessor::GetUnit(*me, _willTarget))
                            if (target->IsAlive())
                            {
                                me->CastSpell(target, SPELL_WILL_CONTROL, true);
                                me->CastSpell(target, SPELL_WILL_SHIELD, true);
                                events.ScheduleEvent(EVENT_WILL_RELEASE, 15s);
                            }
                        break;
                    case EVENT_WILL_RELEASE:
                        if (Unit* target = ObjectAccessor::GetUnit(*me, _willTarget))
                        {
                            target->RemoveAurasDueToSpell(SPELL_WILL_CONTROL);
                            target->RemoveAurasDueToSpell(SPELL_WILL_SHIELD);
                            if (target->IsAlive())
                                me->CastSpell(target, SPELL_WILL_RELEASED, true);
                        }
                        _willTarget.Clear();
                        break;
                    case EVENT_BLOOD_SCYTHE:
                        DoCastVictim(SPELL_BLOOD_SCYTHE);
                        events.ScheduleEvent(EVENT_BLOOD_SCYTHE, 15s);
                        break;
                    case EVENT_SONS:
                        for (uint8 i = 0; i < 2; ++i)
                        {
                            Position pos = me->GetRandomNearPosition(25.0f);
                            if (Creature* son = me->SummonCreature(NPC_SON_OF_HAKKAR, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 30000))
                                son->SetInCombatWithZone();
                        }
                        events.ScheduleEvent(EVENT_SONS, 60s);
                        break;
                    case EVENT_BERSERK:
                        DoCastSelf(SPELL_BERSERK, true);
                        break;
                    case EVENT_FIERCE_BLOW:
                        DoCastVictim(SPELL_FIERCE_BLOW);
                        events.Repeat(FIERCE_BLOW_MIN, FIERCE_BLOW_MAX);
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
        std::array<PriestLoa, 5> _loas
        {{
            { DATA_JEKLIK, SPELL_ASPECT_OF_HIREEK, { NPC_AVATAR_OF_HIREEK, SPELL_DRAIN_POWER } },
            { DATA_VENOXIS, SPELL_ASPECT_OF_HETHISS, { NPC_AVATAR_OF_HETHISS, SPELL_DRAIN_POWER } },
            { DATA_MARLI, SPELL_ASPECT_OF_SHADRA, { NPC_AVATAR_OF_SHADRA, SPELL_DRAIN_POWER } },
            { DATA_THEKAL, SPELL_ASPECT_OF_SHIRVALLAH, { NPC_AVATAR_OF_SHIRVALLAH, SPELL_DRAIN_POWER } },
            { DATA_ARLOKK, SPELL_ASPECT_OF_BETHEKK, { NPC_AVATAR_OF_BETHEKK, SPELL_DRAIN_POWER } }
        }};
        EventMap _clock;
        bool _siphoning = false;
        uint32 _heartDamage = 0;
        ObjectGuid _heart;
        ObjectGuid _willTarget;
        GuidVector _pools;
    };

    // The Heart of Hakkar: whatever hits it hits Hakkar.
    struct npc_heart_of_hakkar_coa : public ScriptedAI
    {
        npc_heart_of_hakkar_coa(Creature* creature) : ScriptedAI(creature)
        {
            me->SetReactState(REACT_PASSIVE);
            me->SetControlled(true, UNIT_STATE_ROOT);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask /*school*/) override
        {
            uint32 const dealt = damage;
            damage = 0;
            if (!dealt || !attacker)
                return;
            InstanceScript* instance = me->GetInstanceScript();
            Creature* hakkar = instance ? instance->GetCreature(DATA_HAKKAR) : nullptr;
            if (!hakkar || !hakkar->IsAlive())
                return;
            Unit::DealDamage(attacker, hakkar, dealt, nullptr, type, SPELL_SCHOOL_MASK_NORMAL, nullptr, false);
            hakkar->AI()->SetData(ACTION_HEART_DAMAGE, dealt);
        }

        void UpdateAI(uint32 /*diff*/) override { }
    };

    // Corrupted Blood heals Hakkar for what it deals, and leaves a pool when it ends.
    class spell_hakkar_coa_corrupted_blood : public AuraScript
    {
        PrepareAuraScript(spell_hakkar_coa_corrupted_blood);

        void OnPeriodic(AuraEffect const* aurEff)
        {
            if (Unit* caster = GetCaster())
                if (caster->IsAlive())
                {
                    int32 heal = aurEff->GetAmount();
                    caster->CastCustomSpell(caster, SPELL_CORRUPTED_BLOOD_HEAL, &heal, nullptr, nullptr, true);
                }
        }

        void AfterRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
        {
            Unit* caster = GetCaster();
            Unit* target = GetTarget();
            if (!caster || !caster->IsAlive() || !caster->IsInCombat() || !target)
                return;
            if (Creature* boss = caster->ToCreature())
                if (Creature* spot = boss->SummonCreature(NPC_WORLD_TRIGGER, target->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 300000))
                {
                    spot->SetFaction(boss->GetFaction());
                    spot->CastSpell(spot, SPELL_POOL_OF_CORRUPTED_BLOOD, true, nullptr, nullptr, boss->GetGUID());
                }
        }

        void Register() override
        {
            OnEffectPeriodic += AuraEffectPeriodicFn(spell_hakkar_coa_corrupted_blood::OnPeriodic, EFFECT_1, SPELL_AURA_PERIODIC_DAMAGE);
            AfterEffectRemove += AuraEffectRemoveFn(spell_hakkar_coa_corrupted_blood::AfterRemove, EFFECT_1, SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL);
        }
    };
}

void AddCoaHakkarScripts()
{
    RegisterZulGurubCreatureAI(boss_hakkar_coa);
    RegisterZulGurubCreatureAI(npc_heart_of_hakkar_coa);
    RegisterSpellScript(spell_hakkar_coa_corrupted_blood);
}
