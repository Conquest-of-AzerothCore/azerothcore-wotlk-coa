/*
 * Ossirian the Unscarred as Ascension rebuilt him.
 *
 * Kit: Ascension's block 2112700-2112751. No logs or video exist for
 * Ahn'Qiraj; every timer and number here is designed.
 *
 * The crystals are gone. The twelve places they used to appear at now hold six
 * Sun Conduits and six obelisk sites.
 *
 * Fury of the Sands. A sandstorm rages over the whole ruin: every second
 * outside shelter adds a stack (up to 20, +5% speed each), and every 3 seconds
 * it deals its damage times the stacks. Shelter is within 30 yards of an
 * active Obelisk; three stand at a time. Every 45 seconds one overloads, knocks
 * everyone near it away and goes dark, and another one lights up elsewhere.
 * The two Sand Vortices of the original wander the ruin and add stacks to
 * whoever they touch.
 *
 * The Sun Disc. Every second Ossirian draws one Solar Power from every Sun
 * Conduit in front of him (120 degrees, 80 yards). A hundred charge a Sun Orb:
 * he is Supreme for 20 seconds (+5% damage, larger), and from the first orb on
 * he uses his solar abilities, faster with each further orb. With all six he
 * gathers six times as fast and stacks Supreme every 5 seconds for good. Tanks
 * turn him away from the conduits.
 *
 *   Solar Fire + Solar Beam   every 7s, -1s per orb beyond the first: a
 *                             random player burns, the ground under them too
 *   Solar Radiance            every 20s, -3s per orb beyond the first: Fire
 *                             damage to everyone within 100 yards
 *   Meteor                    first 30s, every 30s: a player is marked for 8s,
 *                             then the impact's damage is split between
 *                             everyone within 8 yards; the crater burns
 *   Locust Plague             first 20s, every 25s: a swarm on a random
 *                             player that jumps to everyone within 8 yards
 *                             every 5 seconds
 *
 * Decided here, not in the data: which crystal places become conduits or
 * obelisks, three active obelisks and the 45s overload, the disc's arc and
 * range, Supreme's 20s, every timer, and using Ascension's two crystal objects
 * (210312, 210313) to show obelisks and conduits.
 */

#include "Containers.h"
#include "CreatureScript.h"
#include "GameObject.h"
#include "InstanceScript.h"
#include "MiscPackets.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "../../../src/server/scripts/Kalimdor/RuinsOfAhnQiraj/ruins_of_ahnqiraj.h"
#include "zg_coa_common.h"

#include <array>
#include <list>

using namespace coa_zg;

namespace
{
    enum Texts
    {
        SAY_SUPREME = 0,
        SAY_INTRO   = 1,
        SAY_AGGRO   = 2,
        SAY_SLAY    = 3,
        SAY_DEATH   = 4
    };

    enum Spells
    {
        SPELL_OBELISK        = 2112700,
        SPELL_FURY           = 2112701,
        SPELL_EXPOSURE       = 2112705,
        SPELL_FURY_HIT       = 2112706,
        SPELL_SUN_BEAM       = 2112707,
        SPELL_LOAD_SUN_DISC  = 2112708,
        SPELL_SUN_DISC       = 2112709,
        SPELL_SOLAR_POWER    = 2112710,
        SPELL_SOLAR_FIRE     = 2112712,
        SPELL_SOLAR_BEAM     = 2112717,
        SPELL_SOLAR_RADIANCE = 2112722,
        SPELL_SUPREME        = 2112726,
        SPELL_METEOR_MARK    = 2112727,
        SPELL_METEOR_IMPACT  = 2112728,
        SPELL_OVERLOAD       = 2112736,
        SPELL_SOLAR_CHARGE   = 2112740,
        SPELL_SAND_STORM     = 2112741,
        SPELL_LOCUST_FIRST   = 2112745,   // + difficulty, 2112745..2112748
    };

    enum Events
    {
        EVENT_STORM = 1,
        EVENT_STORM_HIT,
        EVENT_DISC,
        EVENT_OVERLOAD,
        EVENT_SOLAR_FIRE,
        EVENT_RADIANCE,
        EVENT_METEOR,
        EVENT_METEOR_IMPACT,
        EVENT_LOCUSTS,
        EVENT_LOCUST_SPREAD,
        EVENT_SUPREME_END,
        EVENT_SUPREME_STACK,
    };

    enum Misc
    {
        NPC_WORLD_TRIGGER = 12999,
        GO_OBELISK        = 210312,
        GO_CONDUIT        = 210313,
        ORBS              = 6,
        POWER_PER_ORB     = 100,
        MAX_EXPOSURE      = 20
    };

    constexpr float SHELTER_RANGE  = 30.0f;
    constexpr float DISC_RANGE     = 80.0f;
    constexpr float DISC_ARC       = float(M_PI) * 2 / 3;
    constexpr float METEOR_RADIUS  = 8.0f;
    constexpr float LOCUST_RANGE   = 8.0f;

    // The original crystal places: the first six are conduits, the rest obelisk sites.
    Position const Places[12] =
    {
        { -9407.72f, 1960.21f, 85.639f, 0.0f }, { -9388.44f, 1940.21f, 85.639f, 0.0f },
        { -9357.86f, 1929.08f, 85.639f, 0.0f }, { -9383.29f, 2012.68f, 85.651f, 0.0f },
        { -9248.41f, 1974.83f, 85.639f, 0.0f }, { -9432.40f, 1782.53f, 85.639f, 0.0f },
        { -9299.73f, 1748.45f, 85.639f, 0.0f }, { -9406.10f, 1862.38f, 85.639f, 0.0f },
        { -9506.19f, 1865.57f, 85.639f, 0.0f }, { -9282.08f, 1887.34f, 85.639f, 0.0f },
        { -9244.41f, 1808.98f, 85.639f, 0.0f }, { -9367.17f, 1780.89f, 85.639f, 0.0f }
    };

    Position const VortexPositions[2] =
    {
        { -9524.06f, 1881.9224f, 85.64029f, 0.0f },
        { -9228.479f, 1925.3331f, 85.64147f, 0.0f }
    };

    struct boss_ossirian_coa : public BossAI
    {
        boss_ossirian_coa(Creature* creature) : BossAI(creature, DATA_OSSIRIAN) { }

        void Reset() override
        {
            BossAI::Reset();
            ClearObjects();
            _power = 0;
            _orbs = 0;
            for (uint32 s : { SPELL_SUN_DISC, SPELL_SOLAR_POWER, SPELL_SOLAR_CHARGE, SPELL_SUPREME, SPELL_FURY })
                me->RemoveAurasDueToSpell(s);
        }

        void MoveInLineOfSight(Unit* who) override
        {
            if (!_saidIntro)
            {
                Talk(SAY_INTRO);
                _saidIntro = true;
            }
            BossAI::MoveInLineOfSight(who);
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(SAY_AGGRO);
            me->AddAura(SPELL_SUN_DISC, me);

            if (me->GetMap()->IsDungeon())
            {
                WorldPackets::Misc::Weather weather(WEATHER_STATE_HEAVY_SANDSTORM, 1.0f);
                me->GetMap()->SendToPlayers(weather.Write());
            }

            // Conduits at the first six places.
            for (uint8 i = 0; i < 6; ++i)
                if (Creature* conduit = me->SummonCreature(NPC_WORLD_TRIGGER, Places[i], TEMPSUMMON_MANUAL_DESPAWN))
                {
                    _conduits.push_back(conduit->GetGUID());
                    if (GameObject* go = conduit->SummonGameObject(GO_CONDUIT, Places[i].GetPositionX(), Places[i].GetPositionY(), Places[i].GetPositionZ(), 0, 0, 0, 0, 0, 0))
                        _objects.push_back(go->GetGUID());
                    conduit->AddAura(SPELL_SUN_BEAM, conduit);
                }
            // Three obelisks among the other six.
            _sites = { 6, 7, 8, 9, 10, 11 };
            Acore::Containers::RandomShuffle(_sites);
            for (uint8 i = 0; i < 3; ++i)
                LightObelisk(_sites[i]);

            std::list<uint32> paths = { 1446800, 1446790 };
            for (Position const& pos : VortexPositions)
                if (Creature* vortex = me->SummonCreature(NPC_SAND_VORTEX, pos))
                {
                    vortex->AddAura(SPELL_SAND_STORM, vortex);
                    vortex->GetMotionMaster()->MoveWaypoint(paths.front(), true);
                    paths.reverse();
                }

            events.ScheduleEvent(EVENT_STORM, 1s);
            events.ScheduleEvent(EVENT_STORM_HIT, 3s);
            events.ScheduleEvent(EVENT_DISC, 1s);
            events.ScheduleEvent(EVENT_LOCUSTS, 20s);
            events.ScheduleEvent(EVENT_LOCUST_SPREAD, 5s);
            events.ScheduleEvent(EVENT_METEOR, 30s);
            events.ScheduleEvent(EVENT_OVERLOAD, 45s);
        }

        void KilledUnit(Unit* /*victim*/) override
        {
            Talk(SAY_SLAY);
        }

        void JustDied(Unit* killer) override
        {
            Talk(SAY_DEATH);
            ClearObjects();
            instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_EXPOSURE);
            BossAI::JustDied(killer);
        }

        void EnterEvadeMode(EvadeReason why) override
        {
            ClearObjects();
            instance->DoRemoveAurasDueToSpellOnPlayers(SPELL_EXPOSURE);
            BossAI::EnterEvadeMode(why);
        }

        void ClearObjects()
        {
            for (ObjectGuid const& guid : _objects)
                if (GameObject* go = ObjectAccessor::GetGameObject(*me, guid))
                    go->Delete();
            _objects.clear();
            _conduits.clear();
            _obelisks.clear();
        }

        void LightObelisk(uint8 site)
        {
            Position const& pos = Places[site];
            if (Creature* obelisk = me->SummonCreature(NPC_WORLD_TRIGGER, pos, TEMPSUMMON_MANUAL_DESPAWN))
            {
                obelisk->SetFaction(me->GetFaction());
                obelisk->CastSpell(obelisk, SPELL_OBELISK, true);
                ObjectGuid go;
                if (GameObject* object = obelisk->SummonGameObject(GO_OBELISK, pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), 0, 0, 0, 0, 0, 0))
                {
                    _objects.push_back(object->GetGUID());
                    go = object->GetGUID();
                }
                _obelisks.push_back({ obelisk->GetGUID(), go, site });
            }
        }

        // One active obelisk overloads and a dark one lights up.
        void Overload()
        {
            if (_obelisks.empty())
                return;
            auto it = _obelisks.begin();
            std::advance(it, urand(0, _obelisks.size() - 1));
            if (Creature* obelisk = ObjectAccessor::GetCreature(*me, it->trigger))
            {
                obelisk->CastSpell(obelisk, SPELL_OVERLOAD, true);
                obelisk->DespawnOrUnsummon(1s);
            }
            if (GameObject* go = ObjectAccessor::GetGameObject(*me, it->object))
                go->Delete();
            uint8 const freed = it->site;
            _obelisks.erase(it);

            std::vector<uint8> dark;
            for (uint8 site : _sites)
                if (site != freed && std::none_of(_obelisks.begin(), _obelisks.end(), [site](Obelisk const& o) { return o.site == site; }))
                    dark.push_back(site);
            if (!dark.empty())
                LightObelisk(Acore::Containers::SelectRandomContainerElement(dark));
        }

        bool Sheltered(Player* p)
        {
            for (Obelisk const& o : _obelisks)
                if (Creature* obelisk = ObjectAccessor::GetCreature(*me, o.trigger))
                    if (obelisk->IsWithinDist(p, SHELTER_RANGE))
                        return true;
            return false;
        }

        // Every second: exposure outside shelter.
        void Storm()
        {
            for (Player* p : Players(me, [](Player*) { return true; }))
            {
                if (Sheltered(p))
                    p->RemoveAurasDueToSpell(SPELL_EXPOSURE);
                else
                    AddStack(me, p, SPELL_EXPOSURE, MAX_EXPOSURE);
            }
        }

        // Every 3 seconds: the storm's damage times the stacks.
        void StormHit()
        {
            int32 const base = Info(me, SPELL_FURY);
            for (Player* p : Players(me, [](Player*) { return true; }))
                if (Aura* exposure = p->GetAura(SPELL_EXPOSURE))
                    Hit(me, p, SPELL_FURY_HIT, base * exposure->GetStackAmount());
        }

        void Disc()
        {
            uint32 facing = 0;
            for (ObjectGuid const& guid : _conduits)
                if (Creature* conduit = ObjectAccessor::GetCreature(*me, guid))
                    if (me->IsWithinDist(conduit, DISC_RANGE) && me->isInFront(conduit, DISC_ARC))
                    {
                        ++facing;
                        conduit->CastSpell(me, SPELL_LOAD_SUN_DISC, true);
                    }
            // With all six orbs lit he stacks Supreme on his own clock.
            if (!facing || _orbs >= ORBS)
                return;

            _power += facing;
            while (_power >= POWER_PER_ORB && _orbs < ORBS)
            {
                _power -= POWER_PER_ORB;
                ChargeOrb();
            }
            if (Aura* aura = me->GetAura(SPELL_SOLAR_POWER))
                aura->SetStackAmount(std::max<uint32>(_power, 1));
            else if (_power)
                me->AddAura(SPELL_SOLAR_POWER, me);
        }

        void ChargeOrb()
        {
            ++_orbs;
            Talk(SAY_SUPREME);
            if (AuraEffect* charge = me->GetAuraEffect(SPELL_SOLAR_CHARGE, EFFECT_0))
                charge->ChangeAmount(_orbs);
            else if (me->AddAura(SPELL_SOLAR_CHARGE, me))
                if (AuraEffect* fresh = me->GetAuraEffect(SPELL_SOLAR_CHARGE, EFFECT_0))
                    fresh->ChangeAmount(_orbs);

            AddStack(me, me, SPELL_SUPREME);
            if (_orbs >= ORBS)
            {
                events.CancelEvent(EVENT_SUPREME_END);
                events.ScheduleEvent(EVENT_SUPREME_STACK, 5s);
            }
            else
                events.RescheduleEvent(EVENT_SUPREME_END, 20s);

            if (_orbs == 1)
            {
                events.ScheduleEvent(EVENT_SOLAR_FIRE, 2s);
                events.ScheduleEvent(EVENT_RADIANCE, 5s);
            }
        }

        Milliseconds SolarFireEvery() const { return Seconds(std::max<int32>(7 - int32(_orbs) + 1, 2)); }
        Milliseconds RadianceEvery() const { return Seconds(std::max<int32>(20 - 3 * (int32(_orbs) - 1), 5)); }

        void SpotCast(Position const& pos, uint32 spell, uint32 lifeMs, int32 const* bp = nullptr)
        {
            if (Creature* spot = me->SummonCreature(NPC_WORLD_TRIGGER, pos, TEMPSUMMON_TIMED_DESPAWN, lifeMs))
            {
                spot->SetFaction(me->GetFaction());
                if (bp)
                    spot->CastCustomSpell(spot, spell, bp, nullptr, nullptr, true, nullptr, nullptr, me->GetGUID());
                else
                    spot->CastSpell(spot, spell, true, nullptr, nullptr, me->GetGUID());
            }
        }

        // The locust swarm hops to everyone within 8 yards of a carrier.
        void SpreadLocusts()
        {
            uint32 const locust = SPELL_LOCUST_FIRST + std::min<uint8>(uint8(me->GetMap()->GetSpawnMode()), 3);
            std::vector<Player*> carriers = Players(me, [locust](Player* p) { return p->HasAura(locust); });
            for (Player* carrier : carriers)
                for (Player* p : Players(me, [&](Player* x) { return !x->HasAura(locust) && carrier->IsWithinDist(x, LOCUST_RANGE); }))
                    me->AddAura(locust, p);
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
                    case EVENT_STORM:
                        Storm();
                        events.ScheduleEvent(EVENT_STORM, 1s);
                        break;
                    case EVENT_STORM_HIT:
                        StormHit();
                        events.ScheduleEvent(EVENT_STORM_HIT, 3s);
                        break;
                    case EVENT_DISC:
                        Disc();
                        events.ScheduleEvent(EVENT_DISC, 1s);
                        break;
                    case EVENT_OVERLOAD:
                        Overload();
                        events.ScheduleEvent(EVENT_OVERLOAD, 45s);
                        break;
                    case EVENT_SOLAR_FIRE:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                        {
                            me->CastSpell(target, SPELL_SOLAR_FIRE, true);
                            me->AddAura(SPELL_SOLAR_BEAM, target);
                        }
                        events.ScheduleEvent(EVENT_SOLAR_FIRE, SolarFireEvery());
                        break;
                    case EVENT_RADIANCE:
                        DoCastSelf(SPELL_SOLAR_RADIANCE, true);
                        events.ScheduleEvent(EVENT_RADIANCE, RadianceEvery());
                        break;
                    case EVENT_METEOR:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                        {
                            me->AddAura(SPELL_METEOR_MARK, target);
                            _meteorAt = target->GetPosition();
                            events.ScheduleEvent(EVENT_METEOR_IMPACT, 8s);
                        }
                        events.ScheduleEvent(EVENT_METEOR, 30s);
                        break;
                    case EVENT_METEOR_IMPACT:
                    {
                        // Split between everyone in the crater.
                        size_t const hit = std::max<size_t>(1, Players(me, [this](Player* p) { return p->GetExactDist(&_meteorAt) <= METEOR_RADIUS; }).size());
                        uint32 const impact = sSpellMgr->GetSpellIdForDifficulty(SPELL_METEOR_IMPACT, me);
                        SpellInfo const* info = sSpellMgr->GetSpellInfo(impact);
                        uint32 const crater = info ? info->Effects[EFFECT_0].TriggerSpell : 0;
                        int32 const share = Info(me, crater ? crater : impact) / int32(hit);
                        if (crater)
                            SpotCast(_meteorAt, crater, 30000, &share);
                        break;
                    }
                    case EVENT_LOCUSTS:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                            me->AddAura(SPELL_LOCUST_FIRST + std::min<uint8>(uint8(me->GetMap()->GetSpawnMode()), 3), target);
                        events.ScheduleEvent(EVENT_LOCUSTS, 25s);
                        break;
                    case EVENT_LOCUST_SPREAD:
                        SpreadLocusts();
                        events.ScheduleEvent(EVENT_LOCUST_SPREAD, 5s);
                        break;
                    case EVENT_SUPREME_END:
                        me->RemoveAurasDueToSpell(SPELL_SUPREME);
                        break;
                    case EVENT_SUPREME_STACK:
                        AddStack(me, me, SPELL_SUPREME);
                        events.ScheduleEvent(EVENT_SUPREME_STACK, 5s);
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
        struct Obelisk
        {
            ObjectGuid trigger;
            ObjectGuid object;
            uint8 site;
        };

        bool _saidIntro = false;
        uint32 _power = 0;
        uint8 _orbs = 0;
        Position _meteorAt;
        GuidVector _conduits;
        GuidVector _objects;
        std::vector<Obelisk> _obelisks;
        std::vector<uint8> _sites;
    };
}

void AddCoaOssirianScripts()
{
    RegisterRuinsOfAhnQirajCreatureAI(boss_ossirian_coa);
}
