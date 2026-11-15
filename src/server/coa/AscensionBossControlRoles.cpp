/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBossControlRolesPolicy.h"
#include "AscensionSpecialization.h"
#include "BossControlTargeting.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"

class AscensionBossControlRole : public PlayerScript
{
public:
    AscensionBossControlRole() : PlayerScript("AscensionBossControlRole",
        { PLAYERHOOK_ON_HOLDS_TANK_OR_HEALER_ROLE }) { }

    bool OnPlayerHoldsTankOrHealerRole(Player const* player) override
    {
        return player && BossControlRoles::TanksOrHeals(GetAscensionActiveSpecialization(player));
    }
};

class AscensionBossControlGuard : public AllSpellScript
{
public:
    AscensionBossControlGuard() : AllSpellScript("AscensionBossControlGuard",
        { ALLSPELLHOOK_ON_SPELL_CHECK_CAST }) { }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& res) override
    {
        if (res != SPELL_CAST_OK || !spell)
            return;

        if (BossControl::ForbidsCast(spell->GetCaster(), spell->m_targets.GetUnitTarget(),
            spell->GetSpellInfo()))
            res = SPELL_FAILED_BAD_TARGETS;
    }
};

void AddSC_AscensionBossControlRoles()
{
    new AscensionBossControlRole();
    new AscensionBossControlGuard();
}
