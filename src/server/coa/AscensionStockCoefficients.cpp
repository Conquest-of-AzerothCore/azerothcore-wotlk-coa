/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionStockCoefficientData.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"

#include <algorithm>

namespace
{
class ascension_stock_coefficients : public GlobalScript
{
public:
    ascension_stock_coefficients() : GlobalScript("ascension_stock_coefficients",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || !std::binary_search(AscensionCompatData::StockCoefficientSpells.begin(),
                AscensionCompatData::StockCoefficientSpells.end(), info->Id))
            return;

        for (SpellEffectInfo& effect : info->Effects)
            effect.BonusMultiplier = 0.0f;
    }
};
}

void AddAscensionStockCoefficientScripts()
{
    new ascension_stock_coefficients();
}
