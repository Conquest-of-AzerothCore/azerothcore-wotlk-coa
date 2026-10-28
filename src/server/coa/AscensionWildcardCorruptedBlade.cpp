/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionWildcard.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <list>
#include <optional>

namespace
{
enum CorruptedBladeSpells : uint32
{
    SPELL_CORRUPTED_BLADE = 281492,
    SPELL_CORRUPTED_BLADE_SPREAD = 281493,
    SPELL_SINISTER_STRIKE = 1752
};

struct CorruptionSnapshot
{
    uint32 spellId = 0;
    uint8 stacks = 0;
    int32 maxDuration = 0;
    int32 duration = 0;
    std::array<std::optional<int32>, MAX_SPELL_EFFECTS> amounts;
};

class wildcard_corrupted_blade : public SpellScript
{
    PrepareSpellScript(wildcard_corrupted_blade);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({SPELL_CORRUPTED_BLADE, SPELL_CORRUPTED_BLADE_SPREAD}) &&
            (sSpellMgr->GetFirstSpellInChain(info->Id) == SPELL_SINISTER_STRIKE ||
                (info->SpellFamilyName == SPELLFAMILY_ROGUE && (info->SpellFamilyFlags[2] & 0x80000000)));
    }

    void Capture(SpellMissInfo miss)
    {
        _snapshots = {};
        _source.Clear();
        Unit* caster = GetCaster();
        Player* player = caster ? caster->ToPlayer() : nullptr;
        Unit* source = GetHitUnit();
        if (miss != SPELL_MISS_NONE || !player || !AscensionWildcard::IsWildcardHero(player) ||
            GetSpell()->IsTriggered() || !player->HasAura(SPELL_CORRUPTED_BLADE, player->GetGUID()) ||
            !source || !source->IsAlive() || !player->IsValidAttackTarget(source))
            return;

        SpellInfo const* spread = sSpellMgr->GetSpellInfo(SPELL_CORRUPTED_BLADE_SPREAD);
        if (!spread)
            return;

        _source = source->GetGUID();
        std::array<uint32, 2> roots = {spread->Effects[EFFECT_0].TriggerSpell,
            spread->Effects[EFFECT_1].TriggerSpell};
        for (std::size_t slot = 0; slot < roots.size(); ++slot)
            if (Aura const* original = source->GetAuraOfRankedSpell(roots[slot], player->GetGUID());
                original && original->GetDuration() > 0)
            {
                CorruptionSnapshot& snapshot = _snapshots[slot];
                snapshot.spellId = original->GetId();
                snapshot.stacks = original->GetStackAmount();
                snapshot.maxDuration = original->GetMaxDuration();
                snapshot.duration = original->GetDuration();
                for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
                    if (AuraEffect const* effect = original->GetEffect(index))
                        snapshot.amounts[index] = effect->GetAmount();
            }
    }

    void Spread()
    {
        Unit* caster = GetCaster();
        Player* player = caster ? caster->ToPlayer() : nullptr;
        Unit* source = GetHitUnit();
        SpellInfo const* spread = sSpellMgr->GetSpellInfo(SPELL_CORRUPTED_BLADE_SPREAD);
        if (!player || !source || source->GetGUID() != _source || !spread ||
            std::none_of(_snapshots.begin(), _snapshots.end(),
                [](CorruptionSnapshot const& snapshot) { return snapshot.spellId != 0; }))
            return;

        float const radius = spread->Effects[EFFECT_0].CalcRadius(player);
        std::list<Unit*> targets;
        Acore::AnyUnitInObjectRangeCheck check(source, radius);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(source, targets, check);
        Cell::VisitObjects(source, search, radius);
        targets.remove_if([player, source, radius](Unit* target)
        {
            return target == source || !target->IsAlive() || target->IsTotem() ||
                !player->IsValidAttackTarget(target) || !source->InSamePhase(target) ||
                !source->IsWithinDistInMap(target, radius) || !source->IsWithinLOSInMap(target) ||
                (target->IsPlayer() && (target->HasUnitState(UNIT_STATE_CONTROLLED | UNIT_STATE_ROOT) ||
                    target->HasBreakableByDamageCrowdControlAura()));
        });
        targets.sort([source](Unit* first, Unit* second)
        {
            float const firstDistance = source->GetExactDist(first);
            float const secondDistance = source->GetExactDist(second);
            return firstDistance != secondDistance ? firstDistance < secondDistance :
                first->GetGUID() < second->GetGUID();
        });
        if (spread->MaxAffectedTargets && targets.size() > spread->MaxAffectedTargets)
            targets.resize(spread->MaxAffectedTargets);

        for (CorruptionSnapshot const& snapshot : _snapshots)
        {
            if (!snapshot.spellId)
                continue;
            for (Unit* target : targets)
                if (Aura* copy = player->AddAura(snapshot.spellId, target))
                {
                    copy->SetStackAmount(snapshot.stacks);
                    copy->SetMaxDuration(snapshot.maxDuration);
                    copy->SetDuration(snapshot.duration);
                    for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
                        if (AuraEffect* effect = copy->GetEffect(index))
                            if (snapshot.amounts[index])
                                effect->ChangeAmount(*snapshot.amounts[index]);
                }
        }
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(wildcard_corrupted_blade::Capture);
        AfterHit += SpellHitFn(wildcard_corrupted_blade::Spread);
    }

    ObjectGuid _source;
    std::array<CorruptionSnapshot, 2> _snapshots;
};
}

void AddSC_AscensionWildcardCorruptedBlade()
{
    RegisterSpellScript(wildcard_corrupted_blade);
}
