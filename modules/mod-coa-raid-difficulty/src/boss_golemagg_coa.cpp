/*
 * Golemagg's Massive Stomp (2105817) is DBC-pure on CoA: Effect0 is a dummy
 * and Effect1 a plain stun, with no damage effect, radius or trigger spell at
 * all, so the raid takes nothing from it today.
 *
 * CoA's own Spell.dbc already ships the real mechanic unused: "Massive Stomp"
 * 2105823 (SCHOOL_DAMAGE, TARGET_UNIT_TARGET_ANY, base points 1 - a Damage
 * Info placeholder exactly like the twelve pairs DamageInfo.cpp already
 * reads) backed by "Massive Stomp - Hidden Damage - No School" 2105819-2105822
 * (SpellDifficulty group 2124, 100 yd radius, real D0-D3 base points
 * 3199/4265/5330/6399). The live Ascension combat-log corpus shows Golemagg
 * casting 2105823 on every nearby raid member a few hundred ms after each
 * Massive Stomp cast.
 *
 * This hooks Massive Stomp's own dummy effect to cast 2105823 at every living,
 * non-GM player within its Hidden Damage radius; coa_spell_damage_info then
 * resolves the real per-difficulty amount the same way every other bound
 * spell does. The stun stays exactly as it is on 2105817's own single target.
 */

#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"

namespace
{
    enum GolemaggMassiveStompSpells
    {
        SPELL_GOLEMAGG_MASSIVE_STOMP_DAMAGE = 2105823,
    };

    constexpr float GolemaggMassiveStompRadius = 100.0f;

    class spell_golemagg_massive_stomp_coa : public SpellScript
    {
        PrepareSpellScript(spell_golemagg_massive_stomp_coa);

        void HandleRaidDamage(SpellEffIndex /*effIndex*/)
        {
            Creature* caster = GetCaster() ? GetCaster()->ToCreature() : nullptr;
            if (!caster || !caster->GetMap())
                return;

            Map::PlayerList const& players = caster->GetMap()->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                Player* player = itr->GetSource();
                if (player && player->IsAlive() && !player->IsGameMaster() &&
                    caster->IsWithinDistInMap(player, GolemaggMassiveStompRadius))
                    caster->CastSpell(player, SPELL_GOLEMAGG_MASSIVE_STOMP_DAMAGE, true);
            }
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_golemagg_massive_stomp_coa::HandleRaidDamage, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };
}

void AddCoaGolemaggScripts()
{
    RegisterSpellScript(spell_golemagg_massive_stomp_coa);
}
