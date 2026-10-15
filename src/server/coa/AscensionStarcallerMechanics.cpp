/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionStarcaller.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
namespace
{
using namespace AscensionStarcaller;
class starcaller_reflect : public AllSpellScript
{
  public:
    starcaller_reflect() : AllSpellScript("starcaller_reflect", {ALLSPELLHOOK_ON_BEFORE_EFFECTS}) {}
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const*) override
    {
        for (TargetInfo const& target : *spell->GetUniqueTargetInfo())
            if (target.missCondition == SPELL_MISS_REFLECT)
                if (Player* player = Owner(ObjectAccessor::GetUnit(*caster, target.targetGUID)))
                    if (player->HasAura(570231))
                    {
                        player->RemoveAurasDueToSpell(570231);
                        bool old = State(player).event;
                        State(player).event = true;
                        Cast(player, caster, 806233);
                        State(player).event = old;
                    }
    }
};
class starcaller_periodic : public UnitScript
{
  public:
    starcaller_periodic() : UnitScript("starcaller_periodic", true, {UNITHOOK_ON_PERIODIC_DAMAGE_RESULT}) {}
    void OnPeriodicDamageResult(Unit* target, Unit* caster, uint32 damage, SpellInfo const* info) override
    {
        if (Player* player = Owner(caster); player && info && info->Id == 803264 && damage)
            Stars(player, target);
    }
};
class starcaller_resources : public PlayerScript
{
  public:
    starcaller_resources()
        : PlayerScript("starcaller_resources",
                       {PLAYERHOOK_ON_AFTER_UPDATE_MAX_POWER, PLAYERHOOK_ON_PLAYER_HAS_ACTIVE_POWER_TYPE})
    {
    }
    bool OnPlayerHasActivePowerType(Player const* player, Powers power) override
    {
        return Owner(player) && (power == POWER_MANA || power == POWER_ENERGY);
    }
    void OnPlayerAfterUpdateMaxPower(Player* player, Powers& power, float& value) override
    {
        if (power != POWER_MANA && power != POWER_RAGE && power != POWER_ENERGY && power != POWER_FOCUS &&
            power != POWER_RUNIC_POWER)
            return;
        for (auto const& pair : player->GetAppliedAuras())
            if (Aura* aura = pair.second->GetBase(); aura->GetId() == 560634 && Owner(aura->GetCaster()))
            {
                value *= 1.1f;
                break;
            }
    }
};
}
void AddSC_AscensionStarcallerMechanics()
{
    new starcaller_reflect();
    new starcaller_periodic();
    new starcaller_resources();
}
