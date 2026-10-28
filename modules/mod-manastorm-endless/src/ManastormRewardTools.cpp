#include "ManastormModuleConfig.h"

#include "Creature.h"
#include "CreatureScript.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "SpellInfo.h"

#include <array>

namespace
{
    // Existing DBC child spells own the sound IDs, costumes, scale and duration.
    constexpr std::array<uint32, 25> MixtapeVoices =
    {
        991544, 991545, 991546, 991547, 991548,
        991549, 991550, 991551, 991552, 991553,
        991554, 991555, 991556, 991557, 991558,
        991559, 991560, 991561, 991562, 991563,
        991564, 991565, 991566, 991567, 991570
    };

    constexpr std::array<uint32, 14> PylonCostumes =
    {
        991585, 991586, 991587, 991588, 991589,
        991590, 991591, 991592, 991593, 991594,
        991595, 991597, 991598, 991600
    };

    class spell_manastorm_reward_random :
        public SpellScript
    {
        PrepareSpellScript(spell_manastorm_reward_random);

        bool Validate(SpellInfo const* /*spellInfo*/) override
        {
            for (uint32 spellId : MixtapeVoices)
                if (!ValidateSpellInfo({spellId}))
                    return false;

            for (uint32 spellId : PylonCostumes)
                if (!ValidateSpellInfo({spellId}))
                    return false;

            return true;
        }

        void HandleRandom(SpellEffIndex effIndex)
        {
            if (!ManastormModuleConfig::Enabled())
                return;

            Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
            if (!player)
                return;

            PreventHitDefaultEffect(effIndex);

            if (GetSpellInfo()->Id == 991542)
            {
                // One existing voice per activation. The source pool's original
                // weights are unavailable; use uniform selection within that pool.
                uint32 const index = urand(0, uint32(MixtapeVoices.size() - 1));
                player->CastSpell(player, MixtapeVoices[index], true);
                return;
            }

            // Repeated pylon use replaces only its own costumes and scale auras.
            // Other transformation spells retain their normal core behavior.
            for (uint32 spellId : PylonCostumes)
                player->RemoveAurasDueToSpell(spellId);

            uint32 const index = urand(0, uint32(PylonCostumes.size() - 1));
            player->CastSpell(player, PylonCostumes[index], true);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(
                spell_manastorm_reward_random::HandleRandom,
                EFFECT_0,
                SPELL_EFFECT_ASCENSION_TRIGGER_RANDOM_SPELL);
        }
    };
    class npc_manastorm_empty_heart : public CreatureScript
    {
    public:
        npc_manastorm_empty_heart() : CreatureScript("npc_manastorm_empty_heart") { }

        struct npc_manastorm_empty_heartAI : public ScriptedAI
        {
            explicit npc_manastorm_empty_heartAI(Creature* creature) : ScriptedAI(creature)
            {
                me->SetReactState(REACT_PASSIVE);
            }

            bool _collected = false;

            void IsSummonedBy(WorldObject* /*summoner*/) override
            {
                if (ManastormModuleConfig::Enabled())
                    me->CastSpell(me, 991511, true); // Existing cosmetic heart visual.
            }

            void AttackStart(Unit* /*target*/) override { }

            void MoveInLineOfSight(Unit* who) override
            {
                if (_collected || !ManastormModuleConfig::Enabled() || !who)
                    return;

                Player* player = who->ToPlayer();
                if (!player || !player->IsAlive() || player->IsBeingTeleported() ||
                    !me->IsWithinDistInMap(player, 2.0f) || !me->IsWithinLOSInMap(player))
                {
                    return;
                }

                // Cosmetic pickup only. Do not call the healing-heart backend,
                // cast 991510, or change health, maximum health or run capacity.
                _collected = true;
                me->DespawnOrUnsummon();
            }
        };

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_manastorm_empty_heartAI(creature);
        }
    };

}

void AddSC_manastorm_reward_tools()
{
    RegisterSpellScript(spell_manastorm_reward_random);
    new npc_manastorm_empty_heart();
}
