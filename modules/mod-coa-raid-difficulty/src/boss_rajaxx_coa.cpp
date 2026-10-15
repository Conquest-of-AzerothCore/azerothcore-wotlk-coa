/*
 * General Rajaxx and his legion as Ascension rebuilt them.
 *
 * Kit: Ascension's block 2112300-2112338. No logs or video exist for
 * Ahn'Qiraj; every timer here is designed.
 *
 * The waves are the stock event (the instance calls the next squad every two
 * minutes or when one falls). What changed is the officers: each wears a
 * badge that teaches one ability, and the privates fight with the legion's
 * own kit.
 *
 *   Privates (Qiraji Warrior)     Charge on engaging, Devastate every 8s (a
 *                                 stack of Sunder Armor, up to 20), Thunder
 *                                 Clap every 20s, Enrage below 25%
 *   Privates (Swarmguard Needler) Cleave every 6s, Bladestorm every 25s
 *   Officers, besides Cleave and Devastate, one badge each, every 15s:
 *     Captain Qeez       Frightening Shout   50 yards, 5s
 *     Captain Tuubid     Battle Shout        allies within 20 yards +10%
 *                                            damage, stacks
 *     Captain Drenn      Lightning Cloud     at a random player, 15s
 *     Captain Xurrem     Sweeping Slam       cone, knocked into the air
 *     Major Pakkon       Earthquake          10s of quakes around him
 *     Major Yeggeth      Reflective Shield   absorbs everything for 4s and
 *                                            reflects part of it
 *     Colonel Zerran     Attack Order        beetles burst from the ground
 *                                            under three players after 2s
 *
 *   General Rajaxx
 *     General's Command  +5% damage for every squad still standing
 *     Decimate           first 20s, every 30s   6s cast, everyone within 100
 *                                               yards loses 90% of their
 *                                               current health and is knocked
 *                                               back; it cannot kill
 *     Cleave, Devastate  as his privates
 *
 * Decided here, not in the data: every timer, three beetle strikes per order,
 * how much Yeggeth's shield reflects (30%), and Decimate working on current
 * health: the data says 90% of maximum health and to grow with every cast,
 * which would kill the raid on the second one.
 */

#include "Containers.h"
#include "CreatureScript.h"
#include "InstanceScript.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "../../../src/server/scripts/Kalimdor/RuinsOfAhnQiraj/ruins_of_ahnqiraj.h"
#include "zg_coa_common.h"

#include <list>

using namespace coa_zg;

namespace
{
    enum Spells
    {
        SPELL_CENARION_REPUTATION = 26342,

        SPELL_BADGE_QEEZ          = 2112300,
        SPELL_BADGE_TUUBID        = 2112301,
        SPELL_BADGE_DRENN         = 2112302,
        SPELL_BADGE_XURREM        = 2112303,
        SPELL_BADGE_PAKKON        = 2112304,
        SPELL_BADGE_YEGGETH       = 2112305,
        SPELL_BADGE_ZERRAN        = 2112306,
        SPELL_BADGE_RAJAXX        = 2112307,
        SPELL_GENERALS_COMMAND    = 2112308,
        SPELL_CLEAVE              = 2112310,
        SPELL_DEVASTATE           = 2112311,
        SPELL_SUNDER_ARMOR        = 2112312,
        SPELL_THUNDER_CLAP        = 2112313,
        SPELL_BLADESTORM          = 2112314,
        SPELL_ENRAGE              = 2112316,
        SPELL_CHARGE              = 2112317,
        SPELL_FRIGHTENING_SHOUT   = 2112318,
        SPELL_LIGHTNING_CLOUD     = 2112319,
        SPELL_SWEEPING_SLAM       = 2112323,
        SPELL_BATTLE_SHOUT        = 2112324,
        SPELL_REFLECTIVE_SHIELD   = 2112325,
        SPELL_SHIELD_REFLECT      = 2112326,
        SPELL_EARTHQUAKE          = 2112327,
        SPELL_ATTACK_ORDER        = 2112332,
        SPELL_BEETLE_EMERGE       = 2112333,
        SPELL_BEETLE_JUICE        = 2112334,
        SPELL_DECIMATE            = 2112338,
    };

    enum Npcs
    {
        NPC_QIRAJI_WARRIOR    = 15387,
        NPC_SWARMGUARD_NEEDLER = 15344,
        NPC_WORLD_TRIGGER     = 12999
    };

    enum Says
    {
        SAY_DEATH          = 9,
        SAY_WARRIOR_ENRAGE = 0
    };

    enum Events
    {
        EVENT_CLEAVE = 1,
        EVENT_DEVASTATE,
        EVENT_THUNDER_CLAP,
        EVENT_BLADESTORM,
        EVENT_BADGE,
        EVENT_BEETLES,
        EVENT_DECIMATE,
        EVENT_COMMAND,
    };

    constexpr uint8 SUNDER_STACKS      = 20;
    constexpr uint8 BATTLE_SHOUT_STACKS = 10;
    constexpr uint32 DECIMATE_PCT      = 90;
    constexpr uint32 REFLECT_PCT       = 30;
    constexpr float CLEAVE_RANGE       = 10.0f;
    constexpr float SLAM_RANGE         = 15.0f;
    constexpr float CONE_ARC           = float(M_PI) / 2;

    uint32 const Officers[] = { NPC_QUUEZ, NPC_TUUBID, NPC_DRENN, NPC_XURREM, NPC_PAKKON, NPC_YEGGETH, NPC_ZERRAN };

    uint32 BadgeOf(uint32 entry)
    {
        switch (entry)
        {
            case NPC_QUUEZ:   return SPELL_BADGE_QEEZ;
            case NPC_TUUBID:  return SPELL_BADGE_TUUBID;
            case NPC_DRENN:   return SPELL_BADGE_DRENN;
            case NPC_XURREM:  return SPELL_BADGE_XURREM;
            case NPC_PAKKON:  return SPELL_BADGE_PAKKON;
            case NPC_YEGGETH: return SPELL_BADGE_YEGGETH;
            case NPC_ZERRAN:  return SPELL_BADGE_ZERRAN;
            default:          return 0;
        }
    }

    // Cleave and Devastate, shared by officers and the general.
    void LegionMelee(Creature* me, EventMap& events, uint32 eventId)
    {
        if (eventId == EVENT_CLEAVE)
        {
            me->CastSpell(me->GetVictim(), SPELL_CLEAVE, false);
            events.ScheduleEvent(EVENT_CLEAVE, 6s);
        }
        else if (eventId == EVENT_DEVASTATE)
        {
            if (Unit* tank = me->GetVictim())
            {
                me->CastSpell(tank, SPELL_DEVASTATE, false);
                AddStack(me, tank, SPELL_SUNDER_ARMOR, SUNDER_STACKS);
            }
            events.ScheduleEvent(EVENT_DEVASTATE, 8s);
        }
    }

    // Officers and privates of the Qiraji legion.
    struct npc_rajaxx_legion_coa : public ScriptedAI
    {
        npc_rajaxx_legion_coa(Creature* creature) : ScriptedAI(creature), _instance(creature->GetInstanceScript()) { }

        void Reset() override
        {
            _events.Reset();
            _enraged = false;
            if (uint32 badge = BadgeOf(me->GetEntry()))
                me->AddAura(badge, me);
        }

        void JustEngagedWith(Unit* who) override
        {
            // From stock: an officer engaging starts the two-minute wave clock.
            if (BadgeOf(me->GetEntry()) && _instance)
                _instance->SetData(1, me->GetEntry());

            switch (me->GetEntry())
            {
                case NPC_QIRAJI_WARRIOR:
                    DoCast(who, SPELL_CHARGE, true);
                    _events.ScheduleEvent(EVENT_DEVASTATE, 8s);
                    _events.ScheduleEvent(EVENT_THUNDER_CLAP, 20s);
                    break;
                case NPC_SWARMGUARD_NEEDLER:
                    _events.ScheduleEvent(EVENT_CLEAVE, 6s);
                    _events.ScheduleEvent(EVENT_BLADESTORM, 25s);
                    break;
                default:    // officers
                    _events.ScheduleEvent(EVENT_CLEAVE, 4s);
                    _events.ScheduleEvent(EVENT_DEVASTATE, 8s);
                    _events.ScheduleEvent(EVENT_BADGE, 10s);
                    break;
            }
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            ScriptedAI::DamageTaken(attacker, damage, type, school);

            if (!_enraged && me->GetEntry() == NPC_QIRAJI_WARRIOR && me->HealthBelowPctDamaged(25, damage))
            {
                _enraged = true;
                DoCastSelf(SPELL_ENRAGE, true);
                Talk(SAY_WARRIOR_ENRAGE);
            }
        }

        void Badge()
        {
            switch (me->GetEntry())
            {
                case NPC_QUUEZ:
                    DoCastSelf(SPELL_FRIGHTENING_SHOUT);
                    break;
                case NPC_TUUBID:
                {
                    std::list<Creature*> allies;
                    me->GetCreatureListWithEntryInGrid(allies, NPC_QIRAJI_WARRIOR, 20.0f);
                    std::list<Creature*> needlers;
                    me->GetCreatureListWithEntryInGrid(needlers, NPC_SWARMGUARD_NEEDLER, 20.0f);
                    allies.splice(allies.end(), needlers);
                    allies.push_back(me);
                    for (Creature* ally : allies)
                        if (ally->IsAlive())
                            AddStack(me, ally, SPELL_BATTLE_SHOUT, BATTLE_SHOUT_STACKS);
                    me->HandleEmoteCommand(EMOTE_ONESHOT_BATTLE_ROAR);
                    break;
                }
                case NPC_DRENN:
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 60.0f, true))
                        me->CastSpell(target, SPELL_LIGHTNING_CLOUD, false);
                    break;
                case NPC_XURREM:
                    DoCastVictim(SPELL_SWEEPING_SLAM);
                    break;
                case NPC_PAKKON:
                    DoCastSelf(SPELL_EARTHQUAKE);
                    break;
                case NPC_YEGGETH:
                    DoCastSelf(SPELL_REFLECTIVE_SHIELD);
                    break;
                case NPC_ZERRAN:
                    DoCastSelf(SPELL_ATTACK_ORDER);
                    _events.ScheduleEvent(EVENT_BEETLES, 2s);
                    break;
                default:
                    break;
            }
        }

        // Colonel Zerran's ground strike: beetles burst up under three players.
        void Beetles()
        {
            std::vector<Player*> players = PlayersWithin(me, 40.0f);
            Acore::Containers::RandomResize(players, 3);
            for (Player* p : players)
                if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, p->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, 5000))
                {
                    spot->SetFaction(me->GetFaction());
                    spot->CastSpell(spot, SPELL_BEETLE_EMERGE, true);
                    spot->CastSpell(spot, SPELL_BEETLE_JUICE, true, nullptr, nullptr, me->GetGUID());
                }
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
                    case EVENT_CLEAVE:
                    case EVENT_DEVASTATE:
                        LegionMelee(me, _events, eventId);
                        break;
                    case EVENT_THUNDER_CLAP:
                        DoCastSelf(SPELL_THUNDER_CLAP);
                        _events.ScheduleEvent(EVENT_THUNDER_CLAP, 20s);
                        break;
                    case EVENT_BLADESTORM:
                        DoCastSelf(SPELL_BLADESTORM);
                        _events.ScheduleEvent(EVENT_BLADESTORM, 25s);
                        break;
                    case EVENT_BADGE:
                        Badge();
                        _events.ScheduleEvent(EVENT_BADGE, 15s);
                        break;
                    case EVENT_BEETLES:
                        Beetles();
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
        InstanceScript* _instance;
        EventMap _events;
        bool _enraged = false;
    };

    struct boss_rajaxx_coa : public BossAI
    {
        boss_rajaxx_coa(Creature* creature) : BossAI(creature, DATA_RAJAXX) { }

        void Reset() override
        {
            BossAI::Reset();
            me->AddAura(SPELL_BADGE_RAJAXX, me);
            me->RemoveAurasDueToSpell(SPELL_GENERALS_COMMAND);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            events.ScheduleEvent(EVENT_COMMAND, 1s);
            events.ScheduleEvent(EVENT_CLEAVE, 5s);
            events.ScheduleEvent(EVENT_DEVASTATE, 9s);
            events.ScheduleEvent(EVENT_DECIMATE, 20s);
        }

        // From stock: Andorov opens his shop, and the raid earns reputation for
        // every elite of his who lived.
        void JustDied(Unit* /*killer*/) override
        {
            Talk(SAY_DEATH);
            _JustDied();

            Creature* andorov = instance->instance->GetCreature(instance->GetGuidData(DATA_ANDOROV));
            if (andorov)
            {
                andorov->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP | UNIT_NPC_FLAG_VENDOR);
                andorov->ForceValuesUpdateAtIndex(UNIT_NPC_FLAGS);
            }
            std::list<Creature*> elites;
            me->GetCreatureListWithEntryInGrid(elites, NPC_KALDOREI_ELITE, 200.0f);
            elites.remove_if([](Creature* c) { return !c->IsAlive(); });
            bool const andorovAlive = andorov && andorov->IsAlive();
            me->GetMap()->DoForAllPlayers([&](Player* player)
            {
                for (size_t i = 0; i < elites.size() + (andorovAlive ? 1 : 0); ++i)
                    player->CastSpell(player, SPELL_CENARION_REPUTATION, true);
            });
        }

        // +5% damage for every squad whose officer still stands.
        void UpdateCommand()
        {
            int32 squads = 0;
            for (uint32 entry : Officers)
            {
                std::list<Creature*> found;
                me->GetCreatureListWithEntryInGrid(found, entry, 300.0f);
                for (Creature* c : found)
                    if (c->IsAlive())
                        ++squads;
            }
            AuraEffect* eff = me->GetAuraEffect(SPELL_GENERALS_COMMAND, EFFECT_0);
            if (!squads)
            {
                me->RemoveAurasDueToSpell(SPELL_GENERALS_COMMAND);
                return;
            }
            if (!eff)
            {
                me->AddAura(SPELL_GENERALS_COMMAND, me);
                eff = me->GetAuraEffect(SPELL_GENERALS_COMMAND, EFFECT_0);
            }
            if (eff)
                eff->ChangeAmount(Info(me, SPELL_GENERALS_COMMAND) * squads);
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);
            if (spell->Id != SPELL_DECIMATE)
                return;

            // 90% of current health, nature damage; never kills.
            for (Player* p : PlayersWithin(me, 100.0f))
            {
                uint32 dmg = uint32(p->GetHealth() * DECIMATE_PCT / 100);
                if (dmg >= p->GetHealth())
                    dmg = p->GetHealth() - 1;
                if (!dmg)
                    continue;
                SpellNonMeleeDamage log(me, p, spell, SPELL_SCHOOL_MASK_NATURE);
                log.damage = dmg;
                me->SendSpellNonMeleeDamageLog(&log);
                Unit::DealDamage(me, p, dmg, nullptr, SPELL_DIRECT_DAMAGE, SPELL_SCHOOL_MASK_NATURE, spell, false);
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
                    case EVENT_CLEAVE:
                    case EVENT_DEVASTATE:
                        LegionMelee(me, events, eventId);
                        break;
                    case EVENT_DECIMATE:
                        DoCastSelf(SPELL_DECIMATE);
                        events.ScheduleEvent(EVENT_DECIMATE, 30s);
                        break;
                    case EVENT_COMMAND:
                        UpdateCommand();
                        events.ScheduleEvent(EVENT_COMMAND, 2s);
                        break;
                    default:
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }
    };

    // Major Yeggeth's Reflective Shield sends part of what it absorbs back.
    class spell_rajaxx_coa_reflective_shield : public AuraScript
    {
        PrepareAuraScript(spell_rajaxx_coa_reflective_shield);

        void AfterAbsorb(AuraEffect* /*aurEff*/, DamageInfo& dmgInfo, uint32& absorbAmount)
        {
            Unit* owner = GetTarget();
            Unit* attacker = dmgInfo.GetAttacker();
            if (owner && attacker && attacker != owner && absorbAmount)
                Hit(owner, attacker, SPELL_SHIELD_REFLECT, int32(absorbAmount * REFLECT_PCT / 100));
        }

        void Register() override
        {
            AfterEffectAbsorb += AuraEffectAbsorbFn(spell_rajaxx_coa_reflective_shield::AfterAbsorb, EFFECT_0);
        }
    };
}

void AddCoaRajaxxScripts()
{
    RegisterRuinsOfAhnQirajCreatureAI(boss_rajaxx_coa);
    RegisterRuinsOfAhnQirajCreatureAI(npc_rajaxx_legion_coa);
    RegisterSpellScript(spell_rajaxx_coa_reflective_shield);
}
