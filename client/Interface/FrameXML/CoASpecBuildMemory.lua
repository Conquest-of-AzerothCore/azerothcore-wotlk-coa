CoASpecBuildMemory = { debug = false }

local knownSpec
local installed = false

local function Say(text)
    if CoASpecBuildMemory.debug and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ddffCoA spec memory:|r " .. text)
    end
end

function CoASpecBuildMemory.Install(api)
    if installed or type(api) ~= "table" then
        return false
    end
    for _, name in ipairs({ "SwitchActiveChrSpec", "GetActiveChrSpec", "IsPending", "CancelPendingBuild" }) do
        if type(api[name]) ~= "function" then
            return false
        end
    end
    installed = true
    Say("active")

    local switch = api.SwitchActiveChrSpec
    api.SwitchActiveChrSpec = function(specID, ...)
        local from = api.GetActiveChrSpec()
        local ok, dirty = pcall(api.IsPending)
        if from and from ~= 0 and ok and dirty == false then
            knownSpec = from
        end
        local results = { switch(specID, ...) }
        if knownSpec and specID == knownSpec and from ~= specID then
            Say("back on saved spec " .. tostring(specID) .. ", restoring its build")
            RefreshFromCancel = true
            api.CancelPendingBuild()
        end
        return unpack(results)
    end
    return true
end

function CoASpecBuildMemory.OnEvent(event)
    if event == "ASCENSION_KNOWN_ENTRY_UPDATED" or event == "ASCENSION_KNOWN_ENTRY_REMOVED" then
        knownSpec = nil
    else
        CoASpecBuildMemory.Install(C_CharacterAdvancement)
    end
end

local driver = CreateFrame("Frame")
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "ASCENSION_KNOWN_ENTRY_UPDATED",
                         "ASCENSION_KNOWN_ENTRY_REMOVED" }) do
    driver:RegisterEvent(event)
end
driver:SetScript("OnEvent", function(_, event)
    CoASpecBuildMemory.OnEvent(event)
end)
local waited = 0
driver:SetScript("OnUpdate", function(self, elapsed)
    waited = waited + elapsed
    if waited < 1 then
        return
    end
    waited = 0
    if installed or CoASpecBuildMemory.Install(C_CharacterAdvancement) then
        self:SetScript("OnUpdate", nil)
    end
end)
