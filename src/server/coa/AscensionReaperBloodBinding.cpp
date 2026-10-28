/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include <unordered_set>

namespace
{
constexpr uint32 BloodBinding = 805200;
constexpr uint32 BloodBindingDamage = 801334;
constexpr uint32 BloodBindingRoot = 802752;
constexpr uint32 ScytheRush = 500359;
constexpr uint32 Cull = 800930;
constexpr uint32 CullVariant = 800940;

std::unordered_set<ObjectGuid> CulledReapers;

class reaper_blood_binding_sequence : public PlayerScript
{
public:
    reaper_blood_binding_sequence() : PlayerScript("reaper_blood_binding_sequence",
        {PLAYERHOOK_ON_SPELL_CAST, PLAYERHOOK_ON_LOGOUT}) { }

    void OnPlayerSpellCast(Player* player, Spell* spell, bool) override
    {
        if (!player || !spell || spell->IsTriggered() || player->getClass() != CLASS_REAPER)
            return;

        uint32 const spellId = spell->GetSpellInfo()->Id;
        bool const followsCull = CulledReapers.erase(player->GetGUID()) > 0;
        if (!player->HasActiveSpell(BloodBinding))
            return;

        if (spellId == ScytheRush && followsCull)
            player->CastSpell(player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(),
                BloodBindingDamage, true);

        if (spellId == Cull || spellId == CullVariant)
            CulledReapers.insert(player->GetGUID());
    }

    void OnPlayerLogout(Player* player) override
    {
        CulledReapers.erase(player->GetGUID());
    }
};

class spell_ascension_reaper_blood_binding_damage : public SpellScript
{
    PrepareSpellScript(spell_ascension_reaper_blood_binding_damage);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({BloodBindingRoot}); }

    void Bind(SpellEffIndex)
    {
        if (Unit* target = GetHitUnit())
            if (target->IsAlive())
                GetCaster()->CastSpell(target, BloodBindingRoot, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_reaper_blood_binding_damage::Bind, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};
}

void AddSC_AscensionReaperBloodBinding()
{
    new reaper_blood_binding_sequence();
    RegisterSpellScript(spell_ascension_reaper_blood_binding_damage);
}
