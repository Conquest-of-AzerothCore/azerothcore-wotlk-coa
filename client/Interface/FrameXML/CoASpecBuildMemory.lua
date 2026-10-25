CoASpecBuildMemory = { debug = true }

local snapshots = {}
local installed = false

local function Say(text)
    if CoASpecBuildMemory.debug and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ddffCoA spec memory:|r " .. text)
    end
end

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
    Say("active")

    local switch = api.SwitchActiveChrSpec
    api.SwitchActiveChrSpec = function(specID, ...)
        local from = api.GetActiveChrSpec()
        if from and from ~= 0 and from ~= specID then
            local ok, build = pcall(api.ExportBuild, false)
            if ok and type(build) == "string" and build ~= "" then
                snapshots[from] = build
                Say("remembered spec " .. tostring(from) .. " (" .. #build .. " chars)")
            else
                Say("could not export spec " .. tostring(from) .. ": " .. tostring(build))
            end
        end
        local results = { switch(specID, ...) }
        local saved = snapshots[specID]
        if saved and from ~= specID then
            snapshots[specID] = nil
            local ok, imported, reason, entry, rank = pcall(api.ImportPendingBuild, saved)
            Say("restore spec " .. tostring(specID) .. ": " .. tostring(ok) .. " " .. tostring(imported) .. " " ..
                tostring(reason) .. " " .. tostring(entry) .. " " .. tostring(rank))
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
    if event == "ASCENSION_KNOWN_ENTRY_UPDATED" or event == "ASCENSION_KNOWN_ENTRY_REMOVED" then
        Forget()
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
