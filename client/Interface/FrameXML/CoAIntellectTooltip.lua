local setStat = PaperDollFrame_SetStat

PaperDollFrame_SetStat = function(statFrame, statIndex, unit)
    setStat(statFrame, statIndex, unit)
    unit = unit or "player"
    if statIndex ~= 4 or unit ~= "player" or UnitHasMana(unit) or statFrame.tooltip2 then
        return
    end
    local tooltip = _G["DEFAULT_STAT4_TOOLTIP"]
    local newLineIndex = tooltip and strfind(tooltip, "|n")
    if not newLineIndex then
        return
    end
    statFrame.tooltip2 = format(strsub(tooltip, newLineIndex + 2), GetSpellCritChanceFromIntellect(unit))
end
