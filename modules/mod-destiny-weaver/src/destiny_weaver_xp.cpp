/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

// Experience Bonus Control: the character asked to progress at the base rate.
//
// The bonus sources the live NPC named - Potions of Experience, Auras of Experience and the
// recruit-a-friend bonus - are all paid out through Player::GiveXP, but two of them are folded
// into the amount *before* any script sees it:
//
//   * creature kills: KillRewarder::_RewardPlayer applies SPELL_AURA_MOD_XP_PCT (the potions and
//                     the party Aura of Experience, spell 818059) and then calls the
//                     PLAYERHOOK_ON_GIVE_EXP hook;
//   * quests:         Player::CalculateQuestRewardXP applies SPELL_AURA_MOD_XP_QUEST_PCT, and
//                     Player::RewardQuest calls the same hook.
//
// So the hook divides those multipliers straight back out, which leaves the base award the realm
// rates produced - the realm's own XP rate and our dynamic-XP presets are untouched, because
// neither of them is one of the sources being disabled. Only the *positive* side is taken out:
// this realm also carries aura 200/291 effects that are drawbacks (+0% and negative amounts, such
// as XP Lock, Callowness or a challenge's own penalty), and a character who switches the bonuses
// off should still feel those.
//
// The recruit-a-friend bonus works the other way round: Player::GiveXP adds it after the hook
// (bonus_xp = 2 * xp), so when the character is eligible the hook hands over a third of the
// base and the payout lands on the base amount.
//
// A character whose flag is off is not touched at all: the hook returns before reading anything.
#include "destiny_weaver.h"

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraDefines.h"
#include "SpellAuraEffects.h"

#include <algorithm>

namespace
{
    /// CoA's party Aura of Experience (818059) explicitly excludes the recruit-a-friend bonus, so
    /// the multiplier has to be read with the very filter its callers use - otherwise the wrong
    /// number would be taken out and the payout would drift.
    constexpr uint32 SPELL_AURA_OF_EXPERIENCE = 818059;

    /// Everything the two callers' multipliers are built from, minus the effects that are not
    /// bonuses: GetTotalAuraMultiplier multiplies by (1 + amount/100) per effect, so reading only
    /// the positive ones yields exactly the bonus factor to divide back out, and the penalties that
    /// were in the award stay in it.
    bool IsBonusEffect(AuraEffect const* effect, bool recruitAFriend)
    {
        if (effect->GetAmount() <= 0)
            return false;
        return effect->GetId() != SPELL_AURA_OF_EXPERIENCE || !recruitAFriend;
    }

    uint32 StripBonus(uint32 amount, float bonusFactor)
    {
        if (bonusFactor <= 1.0f)
            return amount;

        // Rounding down may cost a single point of experience; never dropping to zero for an
        // award that was worth something keeps a small kill from paying nothing at all.
        return std::max<uint32>(1, uint32(amount / bonusFactor));
    }
}

class destiny_weaver_xp_script : public PlayerScript
{
public:
    destiny_weaver_xp_script() : PlayerScript("destiny_weaver_xp_script", { PLAYERHOOK_ON_GIVE_EXP }) { }

    void OnPlayerGiveXP(Player* player, uint32& amount, Unit* /*victim*/, uint8 xpSource) override
    {
        if (!player || !amount || !DestinyWeaver::ExperienceBonusControlEnabled(player))
            return;

        // A NO_BONUS_EXPERIENCE challenge already makes Player::GiveXP and the aura sites
        // drop every positive bonus; stripping again would divide a base award.
        if (sScriptMgr->OnPlayerHasNoBonusExperience(player))
            return;

        bool const recruitAFriend = player->GetsRecruitAFriendBonus(true);
        std::function<bool(AuraEffect const*)> const include =
            [recruitAFriend](AuraEffect const* effect)
            {
                return IsBonusEffect(effect, recruitAFriend);
            };

        switch (xpSource)
        {
            case PlayerXPSource::XPSOURCE_KILL:
                amount = StripBonus(amount, player->GetTotalAuraMultiplier(SPELL_AURA_MOD_XP_PCT, include));
                break;
            case PlayerXPSource::XPSOURCE_QUEST:
            case PlayerXPSource::XPSOURCE_QUEST_DF:
                amount = StripBonus(amount, player->GetTotalAuraMultiplier(SPELL_AURA_MOD_XP_QUEST_PCT, include));
                break;
            default:
                // Exploration and battleground awards carry no bonus aura of their own.
                break;
        }

        if (recruitAFriend)
            amount = std::max<uint32>(1, amount / 3);
    }
};

void AddSC_destiny_weaver_xp()
{
    new destiny_weaver_xp_script();
}
