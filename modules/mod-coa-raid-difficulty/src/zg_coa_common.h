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
#include "ObjectAccessor.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"

#include <algorithm>
#include <functional>
#include <vector>

namespace coa_zg
{
    // Fierce Blow, cast on the tank by the bosses and adds of the CoA log of 2026-08-02 (not by Gri'lek; Mandokir
    // has his own window). First cast: min-max of six bosses' first casts; repeat: the 6-10s window of Molten Core.
    constexpr uint32 SPELL_FIERCE_BLOW = 975011;
    constexpr Milliseconds FIERCE_BLOW_FIRST_MIN = 6700ms;
    constexpr Milliseconds FIERCE_BLOW_FIRST_MAX = 17300ms;
    constexpr Milliseconds FIERCE_BLOW_MIN = 6000ms;
    constexpr Milliseconds FIERCE_BLOW_MAX = 10000ms;

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

    // A Loa Avatar, the loa a High Priest (and later Hakkar) feeds on.
    //
    // The CoA log of 2026-08-02 shows one per priest pull (buffed by players at
    // the pull), friendly to the raid. The live videos of 2026-08 show the
    // Avatars of Bethekk and Shadra standing in their temples before the pull
    // and back at full health after a wipe, so each priest's avatar is a spawn
    // in its temple (rev_20261025_90; the exact spots are estimated) that the
    // priest finds again at every reset and pull. At about half health each
    // priest takes ~1% damage for 3-4 seconds, the time Drain Power (20-24% of
    // the avatar's health per second, -99% damage taken on the caster) needs to
    // kill it, and the priest's second kit starts the moment the avatar dies.
    // The drain itself, the Aspect and the Gift of the Blood God are not in the
    // log, so the order drain -> death -> Aspect + Gift is read from the spells
    // ("Drains the essence from the closest Loa Avatar", "Consumed the Avatar of
    // ...") and from that timing. Hakkar summons his own ring of avatars.
    class LoaAvatar
    {
    public:
        LoaAvatar(uint32 entry, uint32 drain) : _entry(entry), _drain(drain) { }

        void Summon(Creature* owner, Position const& pos)
        {
            Despawn(owner);
            // Without a summoner: BossAI would pull the friendly avatar into combat with the raid.
            if (TempSummon* avatar = owner->GetMap()->SummonCreature(_entry, pos))
            {
                avatar->SetReactState(REACT_PASSIVE);
                _guid = avatar->GetGUID();
            }
        }

        // The priest's own avatar in its temple, brought back if a past pull drained it.
        void Restore(Creature* owner)
        {
            Release(owner);
            Creature* avatar = owner->FindNearestCreature(_entry, TEMPLE_RANGE);
            if (!avatar)
            {
                avatar = owner->FindNearestCreature(_entry, TEMPLE_RANGE, false);
                if (avatar)
                    avatar->Respawn(true);
            }
            if (avatar)
                avatar->SetReactState(REACT_PASSIVE);
            _guid = avatar ? avatar->GetGUID() : ObjectGuid::Empty;
        }

        // A drain that cannot reach the avatar (line of sight) returns false, so the caller moves on without it.
        bool Drain(Creature* owner)
        {
            Creature* avatar = Get(owner);
            if (_draining || !avatar || !avatar->IsAlive())
                return false;
            if (owner->CastSpell(avatar, _drain, true) != SPELL_CAST_OK)
                return false;
            _draining = true;
            return true;
        }

        // True once, when the avatar being drained is gone. The drain's -99% on
        // the caster lasts seven days, so it is taken off here, unless the
        // caster still drains other avatars with the same spell (Hakkar).
        bool Consumed(Creature* owner, bool release = true)
        {
            if (!_draining)
                return false;
            if (Creature* avatar = Get(owner))
                if (avatar->IsAlive())
                    return false;
            _draining = false;
            if (release)
                owner->RemoveAurasDueToSpell(sSpellMgr->GetSpellIdForDifficulty(_drain, owner));
            return true;
        }

        bool Draining() const { return _draining; }

        void Despawn(Creature* owner)
        {
            if (Creature* avatar = Get(owner))
                avatar->DespawnOrUnsummon();
            _guid.Clear();
            Release(owner);
        }

        // Ends a drain without touching the avatar (the priest died or reset).
        void Release(Creature* owner)
        {
            if (_draining)
                owner->RemoveAurasDueToSpell(sSpellMgr->GetSpellIdForDifficulty(_drain, owner));
            _draining = false;
        }

    private:
        static constexpr float TEMPLE_RANGE = 150.0f;

        Creature* Get(Creature* owner) const
        {
            return _guid ? ObjectAccessor::GetCreature(*owner, _guid) : nullptr;
        }

        uint32 _entry;
        uint32 _drain;
        ObjectGuid _guid;
        bool _draining = false;
    };
}

#endif
