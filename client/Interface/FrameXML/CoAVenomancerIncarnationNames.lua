local VENOMANCER_FORMS = {
    [17] = 803183,
    [18] = 800841,
    [19] = 520307,
    [20] = 803212,
    [21] = 805141,
    [22] = 804980,
    [23] = 800912,
}

if type(C_AppearanceCollection) ~= "table" or type(C_AppearanceCollection.GetCategoryInfo) ~= "function" then
    return
end

local GetCategoryInfo = C_AppearanceCollection.GetCategoryInfo

local function WithForm(spellID, name, icon, ...)
    local formName, _, formIcon = GetSpellInfo(spellID)
    if not formName then
        return name, icon, ...
    end
    return formName, formIcon and formIcon:match("[^\\/]+$") or icon, ...
end

function C_AppearanceCollection.GetCategoryInfo(categoryID, ...)
    local spellID = VENOMANCER_FORMS[categoryID]
    if spellID and select(2, UnitClass("player")) == "PROPHET" then
        return WithForm(spellID, GetCategoryInfo(categoryID, ...))
    end
    return GetCategoryInfo(categoryID, ...)
end
