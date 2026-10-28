/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionRunemasterTalents.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include <array>

namespace
{
struct Chapter
{
    uint32 AuraId;
    uint32 Damage;
};
constexpr std::array<Chapter, 4> Chapters = {{{525327, 525601}, {525363, 525516}, {525387, 525395}, {525400, 525401}}};
constexpr uint32 TRANSCRIBING = 525609;
constexpr uint32 SELECTED_CHAPTER = 524952;
constexpr uint32 CHAPTER_FIRED = 525616;

uint32 TattooChapter(uint32 id)
{
    if (id == 801106 || (id >= 803749 && id <= 803753))
        return 525327;
    if (id == 801107 || (id >= 803783 && id <= 803785) || (id >= 807834 && id <= 807839))
        return 525363;
    if (id == 801094 || (id >= 803754 && id <= 803758) || id == 802630)
        return 525387;
    if (id == 803748 || (id >= 803759 && id <= 803763))
        return 525400;
    return 0;
}

uint32 AttunedChapter(Player* player)
{
    uint32 selected = 0;
    for (auto const& [key, application] : player->GetAppliedAuras())
    {
        Aura* aura = application->GetBase();
        if (aura->GetCasterGUID() != player->GetGUID())
            continue;
        if (uint32 chapter = TattooChapter(aura->GetId()))
        {
            if (selected && selected != chapter)
                return 0;
            selected = chapter;
        }
    }
    return selected;
}

bool IsChapterReleaser(uint32 id)
{
    return id == 804550 || (id >= 520071 && id <= 520076) || id == 801179 ||
        (id >= 520067 && id <= 520070) || (id >= 572119 && id <= 572122);
}

bool IsDirectChapterCast(SpellInfo const* info, uint8 depth = 0)
{
    if (!info || info->IsChanneled())
        return false;
    for (SpellEffectInfo const& effect : info->Effects)
    {
        if (effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE || effect.Effect == SPELL_EFFECT_WEAPON_DAMAGE ||
            effect.Effect == SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL ||
            effect.Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE ||
            effect.Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG)
            return true;
        if (depth < 2 && (effect.Effect == SPELL_EFFECT_TRIGGER_SPELL ||
            effect.Effect == SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE || effect.Effect == SPELL_EFFECT_FORCE_CAST ||
            effect.Effect == SPELL_EFFECT_FORCE_CAST_WITH_VALUE) &&
            IsDirectChapterCast(sSpellMgr->GetSpellInfo(effect.TriggerSpell), depth + 1))
            return true;
    }
    return false;
}

class runemaster_manuscription_casts : public AllSpellScript
{
public:
    runemaster_manuscription_casts() : AllSpellScript("runemaster_manuscription_casts",
        {ALLSPELLHOOK_ON_PREPARE, ALLSPELLHOOK_ON_BEFORE_EFFECTS,
            ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void SelectChapter(Spell* spell, Unit* caster, SpellInfo const* info)
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || info->SpellFamilyName != 38 ||
            spell->IsTriggered() || spell->GetScriptValue(SELECTED_CHAPTER) || !IsDirectChapterCast(info))
            return;
        for (Chapter const& chapter : Chapters)
            if (Aura* aura = player->GetAura(chapter.AuraId, player->GetGUID()); aura && aura->GetCharges())
            {
                spell->SetScriptValue(SELECTED_CHAPTER, chapter.AuraId);
                spell->SetScriptValue(TRANSCRIBING, chapter.Damage);
                break;
            }
    }

    void OnSpellPrepare(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        SelectChapter(spell, caster, info);
    }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        SelectChapter(spell, caster, info);
    }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || info->SpellFamilyName != 38 || spell->IsTriggered())
            return;
        if (uint32 selected = uint32(spell->GetScriptValue(SELECTED_CHAPTER)))
            if (Aura* aura = player->GetAura(selected, player->GetGUID()))
                aura->DropCharge();
        if (info->Id == 524952)
            player->CastSpell(player, TRANSCRIBING, true);
        else if (IsChapterReleaser(info->Id) && player->HasAura(TRANSCRIBING, player->GetGUID()))
            if (uint32 selected = AttunedChapter(player))
            {
                player->RemoveAurasDueToSpell(TRANSCRIBING, player->GetGUID());
                for (Chapter const& chapter : Chapters)
                    player->RemoveAurasDueToSpell(chapter.AuraId, player->GetGUID());
                player->CastSpell(player, selected, true);
            }
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32, uint32, bool) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || spell->IsTriggered() ||
            miss != SPELL_MISS_NONE || !target || !player->IsValidAttackTarget(target) ||
            spell->GetScriptValue(CHAPTER_FIRED))
            return;
        if (uint32 helper = uint32(spell->GetScriptValue(TRANSCRIBING)))
        {
            spell->SetScriptValue(CHAPTER_FIRED, 1);
            player->CastSpell(target, helper, true);
        }
    }
};
}

void ApplyAscensionManuscriptionContracts(SpellInfo* info)
{
    if (info->SpellFamilyName != 38)
        return;
    if (info->Id == TRANSCRIBING)
    {
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_2].Effect = 0;
        info->ProcFlags = 0;
    }
    for (Chapter const& chapter : Chapters)
        if (info->Id == chapter.AuraId)
        {
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
            info->ProcFlags = 0;
            info->ProcCharges = 10;
        }
}

void AddSC_AscensionRunemasterManuscription()
{
    new runemaster_manuscription_casts();
}
