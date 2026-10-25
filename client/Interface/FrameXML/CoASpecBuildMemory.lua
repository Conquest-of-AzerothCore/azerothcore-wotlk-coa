CoASpecBuildMemory = {}

local snapshots = {}
local installed = false

local function Forget()
    for key in pairs(snapshots) do
        snapshots[key] = nil
    end
end

function CoASpecBuildMemory.Install(api)
    if installed or type(api) ~= "table" then
        return false
    end
    for _, name in ipairs({ "SwitchActiveChrSpec", "GetActiveChrSpec", "ExportBuild", "ImportPendingBuild" }) do
        if type(api[name]) ~= "function" then
            return false
        end
    end
    installed = true

    local switch = api.SwitchActiveChrSpec
    api.SwitchActiveChrSpec = function(specID, ...)
        local from = api.GetActiveChrSpec()
        if from and from ~= 0 and from ~= specID then
            local ok, build = pcall(api.ExportBuild, false)
            if ok and type(build) == "string" and build ~= "" then
                snapshots[from] = build
            end
        end
        local results = { switch(specID, ...) }
        local saved = snapshots[specID]
        if saved and from ~= specID then
            snapshots[specID] = nil
            pcall(api.ImportPendingBuild, saved)
        end
        return unpack(results)
    end

    for _, name in ipairs({ "ClearPendingBuild", "ClearPendingBuildByTab" }) do
        local original = api[name]
        if type(original) == "function" then
            api[name] = function(...)
                Forget()
                return original(...)
            end
        end
    end
    return true
end

function CoASpecBuildMemory.OnEvent(event)
    if event == "PLAYER_ENTERING_WORLD" then
        CoASpecBuildMemory.Install(C_CharacterAdvancement)
    else
        Forget()
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("ASCENSION_KNOWN_ENTRY_UPDATED")
driver:RegisterEvent("ASCENSION_KNOWN_ENTRY_REMOVED")
driver:SetScript("OnEvent", function(_, event)
    CoASpecBuildMemory.OnEvent(event)
end)
