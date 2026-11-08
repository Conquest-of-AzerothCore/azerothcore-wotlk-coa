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
 *   Brain Wash Totems     first 16s, every 60s    three around him (five above
 *                                                 Normal), each casts Brainwash
 *                                                 on a player: stunned and
 *                                                 pacified while it stands
 *   Healing Stream Totem  first 21s, every 60s    casts Healing Stream on him:
 *                                                 every second 1% of his missing
 *                                                 health while it stands
 *   Animate Bones         first 23s, every 30s    eight Sacrificed Trolls rise
 *                                                 in the Blood Pit and join the
 *                                                 fight; they Fierce Blow too
 *   Fierce Blow           first 8s, every 8s      on the tank
 *   Friends On the Other Side  +2% damage for every shade alive
 *
 *   Every hit takes one health from a totem: a Brain Wash Totem has 5, the
 *   ward 15 (25 above Normal). The pit is empty before the fight, and he casts
 *   neither Hex nor Banish (tester, live).
 *
 * From stock: the shade's invisibility and random aggro, the totems and the
 * dance when the raid wipes.
 *
 * Decided here, not in the data:
 *   - the totems are the stock creatures, summoned by Ascension's cast bars;
 *     that the brain wash totem casts Brainwash and the ward casts Healing
 *     Stream is read from the spells' names and targets. Both auras last
 *     seven days in the data, so they end when their totem dies or despawns;
 *   - the totems stand ten yards from him, spread evenly; Mythic and Ascended
 *     use the Heroic totem counts and health;
 *   - the Shade of Jin'do neither swings nor casts Shadow Shock: in the CoA logs
 *     of 2026-08-02 and 2026-08-24 it only casts Seeking Shadow Bolts (2118556,
 *     4s, interruptible) over and over, while every 4s each player takes a
 *     Seeking Shadow Bolt (2118551 by difficulty) until the shade dies; an
 *     interrupted cast does not stop them.
 */

#include "CreatureScript.h"
#include "GameTime.h"
#include "PassiveAI.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "TemporarySummon.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

#include <array>
#include <list>
#include <map>
#include <vector>

using namespace coa_zg;

namespace
{
    enum Say
    {
        SAY_AGGRO = 1
    };

    enum Spells
    {
        SPELL_SUMMON_SHADE_OF_JINDO    = 24308,
        SPELL_DELUSIONS_OF_JINDO       = 24306,

        SPELL_SUMMON_BRAIN_WASH        = 2118501,
        SPELL_BRAINWASH                = 2118502,
        SPELL_SUMMON_HEALING_STREAM    = 2118503,
        SPELL_HEALING_STREAM           = 2118504,
        SPELL_HEALING_STREAM_HEAL      = 2118506,
        SPELL_DELUSIONS                = 2118510,
        SPELL_DELUSIONS_VISION         = 2118511,
        SPELL_DELUSIONS_DOT            = 2118512,
        SPELL_FRIENDS_ON_THE_OTHER_SIDE = 2118518,
        SPELL_ANIMATE_BONES            = 2118560,

        SPELL_SHADE_OF_JINDO_PASSIVE   = 24307,
        SPELL_SHADE_OF_JINDO_VISUAL    = 24313,
        SPELL_RANDOM_AGGRO             = 23878,
        SPELL_SEEKING_SHADOW_BOLT      = 2118551,
        SPELL_SEEKING_SHADOW_BOLTS_BAR = 2118556,
    };

    enum Events
    {
        EVENT_DELUSIONS = 1,
        EVENT_BRAIN_WASH,
        EVENT_ANIMATE_BONES,
        EVENT_HEALING_STREAM,
        EVENT_FIERCE_BLOW,
        EVENT_DELUSIONS_GROW,
    };

    enum Npcs
    {
        NPC_POWERFUL_HEALING_WARD = 14987
    };

    constexpr Milliseconds DELUSIONS_DOUBLING = 10s;
    constexpr Milliseconds TOTEM_LIFETIME     = 240s;
    constexpr Milliseconds TROLL_CORPSE_DECAY = 5s;
    constexpr Milliseconds JINDO_FIERCE_BLOW  = 8s;
    constexpr float TOTEM_DISTANCE            = 10.0f;
    constexpr uint8 BRAIN_WASH_TOTEMS_NORMAL  = 3;
    constexpr uint8 BRAIN_WASH_TOTEMS_HEROIC  = 5;
    constexpr uint32 BRAIN_WASH_TOTEM_HEALTH  = 5;
    constexpr uint32 HEALING_WARD_HEALTH_NORMAL = 15;
    constexpr uint32 HEALING_WARD_HEALTH_HEROIC = 25;
    constexpr uint8 ANIMATED_TROLLS           = 8;
    constexpr Milliseconds SEEKING_SHADOW_BOLTS = 4s;
    constexpr float SEEKING_SHADOW_BOLTS_RANGE  = 200.0f;

    std::array<Position, 10> const BloodPitTrolls =
    { {
        { -11584.2f, -1252.21f, 77.6299f, 0.959931f },
        { -11582.5f, -1250.32f, 77.6299f, 3.90954f },
        { -11581.5f, -1252.54f, 77.6299f, 2.61799f },
        { -11583.2f, -1254.83f, 77.6299f, 1.67552f },
        { -11586.4f, -1253.92f, 77.6299f, 0.750492f },
        { -11586.6f, -1250.72f, 77.6299f, 6.07375f },
        { -11585.1f, -1248.76f, 77.6299f, 5.23599f },
        { -11582.3f, -1247.86f, 77.6299f, 4.36332f },
        { -11580.2f, -1250.6f, 77.6299f, 3.36848f },
        { -11580.6f, -1254.79f, 77.6299f, 2.28638f },
    } };

    bool AboveNormal(Unit const* unit)
    {
        return unit->GetMap()->GetSpawnMode() > 0;
    }

    struct boss_jindo_coa : public BossAI
    {
        boss_jindo_coa(Creature* creature) : BossAI(creature, DATA_JINDO) { }

        void Reset() override
        {
            BossAI::Reset();
            _delusions.clear();
            _shades = 0;
            me->RemoveAurasDueToSpell(SPELL_FRIENDS_ON_THE_OTHER_SIDE);
            ReleaseTotemAuras(true);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(SAY_AGGRO);
            me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NONE);

            events.ScheduleEvent(EVENT_FIERCE_BLOW, JINDO_FIERCE_BLOW);
            events.ScheduleEvent(EVENT_DELUSIONS, 14s);
            events.ScheduleEvent(EVENT_BRAIN_WASH, 16s);
            events.ScheduleEvent(EVENT_HEALING_STREAM, 21s);
            events.ScheduleEvent(EVENT_ANIMATE_BONES, 23s);
            events.ScheduleEvent(EVENT_DELUSIONS_GROW, 1s);
        }

        void JustSummoned(Creature* summon) override
        {
            BossAI::JustSummoned(summon);
            if (summon->GetEntry() == NPC_BRAIN_WASH_TOTEM)
            {
                summon->SetReactState(REACT_PASSIVE);
                if (Unit* target = BrainwashTarget())
                    summon->CastSpell(target, SPELL_BRAINWASH, false);
            }
            else if (summon->GetEntry() == NPC_POWERFUL_HEALING_WARD)
                summon->CastSpell(me, SPELL_HEALING_STREAM, false);
            else if (summon->GetEntry() == NPC_SACRIFICED_TROLL)
                DoZoneInCombat(summon);
        }

        Unit* BrainwashTarget()
        {
            uint32 const skipTank = me->GetThreatMgr().GetThreatListSize() > 1 ? 1 : 0;
            if (Unit* fresh = SelectTarget(SelectTargetMethod::Random, skipTank, 0.0f, true, true, -int32(SPELL_BRAINWASH)))
                return fresh;
            return SelectTarget(SelectTargetMethod::Random, skipTank, 0.0f, true);
        }

        void SummonAround(uint32 entry, uint8 count)
        {
            float const step = 2.0f * float(M_PI) / count;
            float const start = frand(0.0f, step);
            for (uint8 i = 0; i < count; ++i)
            {
                Position pos = me->GetNearPosition(TOTEM_DISTANCE, start + step * i);
                me->SummonCreature(entry, pos, TEMPSUMMON_TIMED_DESPAWN, TOTEM_LIFETIME.count());
            }
        }

        void AnimateBones()
        {
            std::vector<Position> spots(BloodPitTrolls.begin(), BloodPitTrolls.end());
            Acore::Containers::RandomResize(spots, ANIMATED_TROLLS);
            for (Position const& spot : spots)
                me->SummonCreature(NPC_SACRIFICED_TROLL, spot, TEMPSUMMON_CORPSE_TIMED_DESPAWN, TROLL_CORPSE_DECAY.count());
        }

        // Totems do not report their despawn, so the auras are checked against their caster.
        void ReleaseTotemAuras(bool all)
        {
            auto orphaned = [all](Aura const* aura)
            {
                Unit* totem = aura->GetCaster();
                return all || !totem || !totem->IsAlive();
            };
            me->GetMap()->DoForAllPlayers([&](Player* player)
            {
                if (Aura* aura = player->GetAura(SPELL_BRAINWASH))
                    if (orphaned(aura))
                        player->RemoveAura(aura);
            });
            if (Aura* aura = me->GetAura(SPELL_HEALING_STREAM))
                if (orphaned(aura))
                    me->RemoveAura(aura);
        }

        void JustDied(Unit* killer) override
        {
            BossAI::JustDied(killer);
            ReleaseTotemAuras(true);
            DespawnShades();
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

        void TrackShades(Unit* summoner)
        {
            std::list<Creature*> shades;
            summoner->GetCreatureListWithEntryInGrid(shades, NPC_SHADE_OF_JINDO, 5.0f);
            for (Creature* shade : shades)
                if (shade->IsSummon() && shade->ToTempSummon()->GetSummonerGUID() == summoner->GetGUID())
                    _shadeGuids.insert(shade->GetGUID());
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
                        // 2118511/2118512 carry the vision and the damage but not the detection the
                        // Shade of Jin'do's own invisibility (24307, type 2) needs; vanilla's Delusions
                        // of Jin'do (24306) already paired the curse with that detection as its third
                        // effect, so reuse only that effect here.
                        me->AddAura(sSpellMgr->GetSpellInfo(SPELL_DELUSIONS_OF_JINDO), 1 << EFFECT_2, target);
                        me->CastSpell(target, SPELL_DELUSIONS_DOT, true);
                        target->CastSpell(target, SPELL_SUMMON_SHADE_OF_JINDO, true);
                        TrackShades(target);
                        _delusions[target->GetGUID()] = GameTime::GetGameTimeMS();
                    }
                    break;
                case SPELL_SUMMON_BRAIN_WASH:
                    SummonAround(NPC_BRAIN_WASH_TOTEM, AboveNormal(me) ? BRAIN_WASH_TOTEMS_HEROIC : BRAIN_WASH_TOTEMS_NORMAL);
                    break;
                case SPELL_SUMMON_HEALING_STREAM:
                    SummonAround(NPC_POWERFUL_HEALING_WARD, 1);
                    break;
                case SPELL_ANIMATE_BONES:
                    AnimateBones();
                    break;
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

        void DespawnShades()
        {
            for (ObjectGuid const& guid : _shadeGuids)
                if (Creature* shade = ObjectAccessor::GetCreature(*me, guid))
                    shade->DespawnOrUnsummon();
            _shadeGuids.clear();
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            if (CreatureAI::_EnterEvadeMode(why))
            {
                DespawnShades();
                Reset();
                me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_DANCE);
                Creature* jindo = me;
                me->m_Events.AddEventAtOffset([jindo]()
                {
                    jindo->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NONE);
                    jindo->GetMotionMaster()->MoveTargetedHome();
                }, 4s);
            }
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
                        events.ScheduleEvent(EVENT_HEALING_STREAM, 60s);
                        break;
                    case EVENT_FIERCE_BLOW:
                        DoCastVictim(SPELL_FIERCE_BLOW);
                        events.ScheduleEvent(EVENT_FIERCE_BLOW, JINDO_FIERCE_BLOW);
                        break;
                    case EVENT_DELUSIONS_GROW:
                        GrowDelusions();
                        UpdateFriends();
                        ReleaseTotemAuras(false);
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
        ObjectGuid _target;
        std::map<ObjectGuid, Milliseconds> _delusions;
        uint8 _shades = 0;
        GuidSet _shadeGuids;
    };

    struct npc_jindo_coa_totem : public NullCreatureAI
    {
        npc_jindo_coa_totem(Creature* creature) : NullCreatureAI(creature) { }

        void IsSummonedBy(WorldObject* /*summoner*/) override
        {
            uint32 const health = me->GetEntry() == NPC_BRAIN_WASH_TOTEM ? BRAIN_WASH_TOTEM_HEALTH
                : AboveNormal(me) ? HEALING_WARD_HEALTH_HEROIC : HEALING_WARD_HEALTH_NORMAL;
            me->SetMaxHealth(health);
            me->SetHealth(health);
        }

        void DamageTaken(Unit* /*attacker*/, uint32& damage, DamageEffectType /*type*/, SpellSchoolMask /*school*/) override
        {
            if (damage)
                damage = 1;
        }
    };

    struct npc_shade_of_jindo_coa : public ScriptedAI
    {
        npc_shade_of_jindo_coa(Creature* creature) : ScriptedAI(creature) { }

        void IsSummonedBy(WorldObject* /*summoner*/) override
        {
            DoZoneInCombat();
            DoCastSelf(SPELL_SHADE_OF_JINDO_PASSIVE, true);
            DoCastSelf(SPELL_SHADE_OF_JINDO_VISUAL, true);
            DoCastAOE(SPELL_RANDOM_AGGRO, true);
            _scheduler.Schedule(SEEKING_SHADOW_BOLTS, [this](TaskContext volley)
            {
                for (Player* player : PlayersWithin(me, SEEKING_SHADOW_BOLTS_RANGE))
                    me->CastSpell(player, SPELL_SEEKING_SHADOW_BOLT, true);
                volley.Repeat();
            }).Schedule(0ms, [this](TaskContext bar)
            {
                if (!me->HasUnitState(UNIT_STATE_CASTING))
                    if (Unit* target = me->GetVictim() ? me->GetVictim() : SelectTarget(SelectTargetMethod::Random, 0))
                        DoCast(target, SPELL_SEEKING_SHADOW_BOLTS_BAR);
                bar.Repeat(500ms);
            }).Schedule(1s, [this](TaskContext aggro)
            {
                DoCastAOE(SPELL_RANDOM_AGGRO, true);
                aggro.Repeat();
            });
        }

        void UpdateAI(uint32 diff) override
        {
            _scheduler.Update(diff);
        }

    private:
        TaskScheduler _scheduler;
    };

    // Healing Stream: every second its first value in percent of the target's missing health.
    class spell_jindo_coa_healing_stream : public AuraScript
    {
        PrepareAuraScript(spell_jindo_coa_healing_stream);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            return ValidateSpellInfo({ SPELL_HEALING_STREAM_HEAL });
        }

        void HandlePeriodic(AuraEffect const* /*aurEff*/)
        {
            PreventDefaultAction();
            Unit* caster = GetCaster();
            Unit* target = GetTarget();
            if (!caster || target->IsFullHealth())
                return;
            int32 heal = int32(CalculatePct(target->GetMaxHealth() - target->GetHealth(),
                GetSpellInfo()->Effects[EFFECT_0].CalcValue(caster)));
            if (heal > 0)
                caster->CastCustomSpell(target, SPELL_HEALING_STREAM_HEAL, &heal, nullptr, nullptr, true);
        }

        void Register() override
        {
            OnEffectPeriodic += AuraEffectPeriodicFn(spell_jindo_coa_healing_stream::HandlePeriodic, EFFECT_1,
                SPELL_AURA_PERIODIC_TRIGGER_SPELL);
        }
    };
}

void AddCoaJindoScripts()
{
    RegisterZulGurubCreatureAI(boss_jindo_coa);
    RegisterZulGurubCreatureAI(npc_jindo_coa_totem);
    RegisterZulGurubCreatureAI(npc_shade_of_jindo_coa);
    RegisterSpellScript(spell_jindo_coa_healing_stream);
}
