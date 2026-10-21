/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCreaturePreset.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "UnitScript.h"
#include "WorldPacket.h"

namespace
{
CreatureDisplayPreset const* TransformPreset(Player const* player, Aura const* aura)
{
    for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
        if (AuraEffect const* effect = aura->GetEffect(index))
            if (effect->GetAuraType() == SPELL_AURA_TRANSFORM && effect->GetMiscValue() > 0)
                if (CreatureDisplayPreset const* preset =
                    sAscensionPresets->GetPresetByGender(uint32(effect->GetMiscValue()), player->getGender()))
                    return preset;
    return nullptr;
}

void SendPresetLook(Player* player, CreatureDisplayPreset const& preset)
{
    WorldPacket look(SMSG_MIRRORIMAGE_DATA, 68);
    look << player->GetGUID() << uint32(preset.display_id) << uint8(preset.race) << uint8(preset.gender)
         << uint8(preset.class_id) << uint8(preset.skin) << uint8(preset.face) << uint8(preset.hair)
         << uint8(preset.haircolor) << uint8(preset.facialhair) << uint32(preset.guild_id);
    for (uint32 item : preset.items)
        look << uint32(item);
    player->SendMessageToSet(&look, true);
}
}

class coa_transform_presets : public UnitScript
{
public:
    coa_transform_presets() : UnitScript("coa_transform_presets", true,
        { UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE }) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = unit->ToPlayer();
        if (!player || player->getTransForm() != aura->GetId())
            return;

        CreatureDisplayPreset const* preset = TransformPreset(player, aura);
        if (!preset)
            return;

        sAscensionPresets->SetActivePresetOverride(player->GetGUID(), preset->entry, preset->display_id);
        player->SetDisplayId(preset->display_id);
        player->SetUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
        if (player->IsInWorld())
            SendPresetLook(player, *preset);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        Player* player = unit->ToPlayer();
        if (!player)
            return;

        CreatureDisplayPreset const* preset = TransformPreset(player, application->GetBase());
        if (!preset || sAscensionPresets->GetActivePresetOverride(player->GetGUID()) != preset)
            return;

        sAscensionPresets->ClearActivePresetOverride(player->GetGUID());
        player->RemoveUnitFlag2(UNIT_FLAG2_MIRROR_IMAGE);
    }
};

void AddSC_AscensionTransformPresets()
{
    new coa_transform_presets();
}
