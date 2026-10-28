#ifndef ASCENSION_REMOVED_SPELL_ACTION_BARS_H
#define ASCENSION_REMOVED_SPELL_ACTION_BARS_H

#include "Player.h"
#include "ScriptMgr.h"
#include <set>

namespace AscensionRemovedSpellActionBars
{
inline std::set<uint32> Capture(Player* player)
{
    std::set<uint32> spells;
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
        if (ActionButton const* action = player->GetActionButton(button);
            action && action->GetType() == ACTION_BUTTON_SPELL && player->HasSpell(action->GetAction()))
            spells.insert(action->GetAction());
    return spells;
}

inline void Reconcile(Player* player, std::set<uint32> const& before)
{
    bool removed = false;
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
    {
        ActionButton const* action = player->GetActionButton(button);
        if (!action || action->GetType() != ACTION_BUTTON_SPELL ||
            !before.contains(action->GetAction()) || player->HasSpell(action->GetAction()))
            continue;
        player->removeActionButton(button);
        removed = true;
    }
    if (removed)
        player->SendActionButtons(1);
}
struct Pending : DataMap::Base
{
    std::set<uint32> Spells;
};

class Script final : public PlayerScript
{
public:
    explicit Script(bool (*applies)(Player const*)) : PlayerScript("AscensionRemovedSpellActionBars",
        { PLAYERHOOK_ON_FORGOT_SPELL, PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_SAVE }), Applies(applies) { }

    void OnPlayerForgotSpell(Player* player, uint32 spell) override
    {
        if (Applies(player) && player->IsInWorld())
            player->CustomData.GetDefault<Pending>("coa.removed_spell_action_bars")->Spells.insert(spell);
    }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        Flush(player);
    }

    void OnPlayerSave(Player* player) override
    {
        Flush(player);
    }

private:
    void Flush(Player* player)
    {
        auto* pending = player->CustomData.Get<Pending>("coa.removed_spell_action_bars");
        if (!Applies(player) || !pending || pending->Spells.empty())
            return;
        Reconcile(player, pending->Spells);
        pending->Spells.clear();
    }

    bool (*Applies)(Player const*);
};

}

#endif
