/*
 * Shared pieces for the Zul'Gurub bosses with Ascension's spells.
 *
 * Ascension's ZG casts come in three kinds, and the helpers here cover them:
 *
 *   - a dummy with a cast bar. A server script turned it into the real hit
 *     when the cast finished. The boss AI does that in OnSpellCast.
 *   - a hit whose number is a placeholder (1 or 2). The real number sits in a
 *     "<Boss> - <Spell> - Damage Info" aura, one per difficulty, which the
 *     boss "pulls" its damage from. Info() reads it.
 *   - a normal spell with four difficulty variants. The core picks the
 *     variant by itself (SpellDifficulty.dbc), so casting the first id is
 *     enough.
 */

#ifndef COA_ZG_COMMON_H
#define COA_ZG_COMMON_H

#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

#include <algorithm>
#include <functional>
#include <vector>

namespace coa_zg
{
    // Alive, visible players on the boss's map that pass the test.
    inline std::vector<Player*> Players(Creature* me, std::function<bool(Player*)> const& accept)
    {
        std::vector<Player*> out;
        me->GetMap()->DoForAllPlayers([&](Player* p)
        {
            if (p->IsAlive() && !p->IsGameMaster() && accept(p))
                out.push_back(p);
        });
        return out;
    }

    inline std::vector<Player*> PlayersWithin(Creature* me, float range)
    {
        return Players(me, [&](Player* p) { return me->IsWithinDistInMap(p, range); });
    }

    inline std::vector<Player*> PlayersInFront(Creature* me, float range, float arc)
    {
        return Players(me, [&](Player* p) { return me->IsWithinDistInMap(p, range) && me->isInFront(p, arc); });
    }

    // Value of effect `eff` of the difficulty variant of `baseId` (a Damage
    // Info aura or any spell with SpellDifficulty rows).
    inline int32 Info(Unit const* me, uint32 baseId, uint8 eff = 0)
    {
        uint32 const id = sSpellMgr->GetSpellIdForDifficulty(baseId, me);
        SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
        return info ? info->Effects[eff].BasePoints + 1 : 0;
    }

    // Casts `spell` on `target` with its first (or given) effect set to `amount`.
    inline void Hit(Unit* caster, Unit* target, uint32 spell, int32 amount, uint8 eff = 0)
    {
        if (!target || amount <= 0)
            return;
        int32 bp[3] = { 0, 0, 0 };
        bp[eff] = amount;
        caster->CastCustomSpell(target, spell, eff == 0 ? &bp[0] : nullptr, eff == 1 ? &bp[1] : nullptr,
            eff == 2 ? &bp[2] : nullptr, true);
    }

    // Damage in the name of `spellId` for spells whose own effect cannot carry
    // it (a dummy or a periodic dummy): logged as that spell, dealt directly.
    inline void SpellDamage(Unit* caster, Unit* target, uint32 spellId, uint32 amount, SpellSchoolMask school)
    {
        SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
        if (!info || !target || !amount || !target->IsAlive())
            return;
        SpellNonMeleeDamage log(caster, target, info, school);
        log.damage = std::min<uint32>(amount, target->GetHealth());
        caster->SendSpellNonMeleeDamageLog(&log);
        Unit::DealDamage(caster, target, log.damage, nullptr, SPELL_DIRECT_DAMAGE, school, info, false);
    }

    // Adds one stack of `spell` from `caster`, up to `max`.
    inline void AddStack(Unit* caster, Unit* target, uint32 spell, uint8 max = 100)
    {
        if (Aura* aura = target->GetAura(spell, caster->GetGUID()))
        {
            if (aura->GetStackAmount() < max)
                aura->ModStackAmount(1);
            aura->RefreshDuration();
        }
        else
            caster->AddAura(spell, target);
    }

    // Players in raid order for chain effects: the nearest one to `from` within
    // `range` that is not in `hit` yet.
    inline Player* NextInChain(Creature* me, WorldObject* from, float range, std::vector<Player*> const& hit)
    {
        Player* best = nullptr;
        for (Player* p : Players(me, [&](Player* x) { return from->IsWithinDistInMap(x, range); }))
        {
            if (std::find(hit.begin(), hit.end(), p) != hit.end())
                continue;
            if (!best || from->GetDistance(p) < from->GetDistance(best))
                best = p;
        }
        return best;
    }
}

#endif
