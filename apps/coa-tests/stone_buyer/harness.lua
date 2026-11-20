local source = assert(arg[1], "path to extracted client Lua")
local failures = 0

local function check(condition, message)
    if not condition then
        failures = failures + 1
        io.stderr:write("FAIL: " .. message .. "\n")
    end
end

local function loadChunk(prices, extras)
    local env = {}
    setmetatable(env, { __index = _G })
    env._G = env
    env.PRICES = prices or {}
    env.YES = "Yes"
    env.NO = "No"
    env.StaticPopupDialogs = {}
    env.chat = {}
    env.purchases = {}
    env.popups = {}
    env.owned = extras and extras.owned or {}
    env.tokens = extras and extras.tokens or 0
    env.shift = extras and extras.shift or false
    env.ctrl = extras and extras.ctrl or false
    env.areaName = extras and extras.areaName or nil
    env.mapInfo = extras and extras.mapInfo or nil
    env.tooltip = extras and extras.tooltip or nil
    env.hooks = {}

    env.DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, message)
            table.insert(env.chat, message)
        end
    }
    env.GetItemCount = function(itemId)
        check(itemId == 975001, "token count should query item 975001")
        return env.tokens
    end
    env.IsShiftKeyDown = function()
        return env.shift
    end
    env.IsControlKeyDown = function()
        return env.ctrl
    end
    env.C_VanityCollection = {
        IsCollectionItemOwned = function(itemId)
            return env.owned[itemId] == true
        end,
        PurchaseCollectionItem = function(itemId)
            table.insert(env.purchases, itemId)
            return true
        end
    }
    env.WorldMapFrame = setmetatable({}, {
        __index = function(_, key)
            if key == "areaName" then
                return env.areaName
            end
        end
    })
    env.GetMapInfo = function()
        return env.mapInfo
    end
    env.WorldMapTooltip = {
        IsShown = function()
            return env.tooltip ~= nil
        end
    }
    env.WorldMapTooltipTextLeft1 = {
        GetText = function()
            return env.tooltip
        end
    }
    env.hooksecurefunc = function(name, fn)
        env.hooks[name] = fn
    end
    env.WorldMapButton_OnClick = function()
    end
    env.StaticPopup_Show = function(which, arg1, arg2)
        table.insert(env.popups, { which = which, arg1 = arg1, arg2 = arg2 })
        local dialog = env.StaticPopupDialogs[which]
        if dialog and dialog.OnAccept then
            dialog.OnAccept()
        end
    end
    env.CreateFrame = function()
        return {
            RegisterEvent = function() end,
            SetScript = function() end
        }
    end
    env.SlashCmdList = {}

    local body = assert(io.open(source, "r")):read("*a")
    local priceItems = {}
    for itemId, cost in pairs(env.PRICES) do
        table.insert(priceItems, string.format("[%s]=%s", itemId, cost))
    end
    body = "local PRICES = {" .. table.concat(priceItems, ",") .. "}\n" .. body
    local chunk = assert(loadstring(body))
    setfenv(chunk, env)
    chunk()
    return env
end

local function lastChat(env)
    return env.chat[#env.chat] or ""
end

do
    local env = loadChunk({ [1780051] = 250, [1880045] = 250, [777003] = 350 })
    env.tokens = 1000
    env.SlashCmdList.STONEBUYER("Elwynn Forest")
    check(#env.purchases == 1 and env.purchases[1] == 1780051,
        "Elwynn Forest should buy the Goldshire stone")
    check(env.popups[1] and env.popups[1].which == "STONEBUYER_CONFIRM" and env.popups[1].arg2 == "250",
        "priced confirm popup should show the injected token cost")
    check(lastChat(env):find("1780051", 1, true) and lastChat(env):find("250", 1, true),
        "purchase chat should name the item and cost")
end

do
    local env = loadChunk({ [777003] = 350 })
    env.tokens = 1000
    env.SlashCmdList.STONEBUYER("Stormwind City")
    check(#env.purchases == 1 and env.purchases[1] == 777003,
        "Stormwind City should buy the Stormwind stone")
end

do
    local env = loadChunk({})
    env.tokens = 0
    env.SlashCmdList.STONEBUYER("Goldshire")
    check(#env.purchases == 1 and env.purchases[1] == 1780051,
        "unpriced stones should still request a purchase and let the server decide")
    check(env.popups[1] and env.popups[1].which == "STONEBUYER_CONFIRM_UNPRICED",
        "missing realm prices should use the unpriced confirm popup")
end

do
    local env = loadChunk({ [1780051] = 250, [1880045] = 250 })
    env.tokens = 100
    env.SlashCmdList.STONEBUYER("Goldshire")
    check(#env.purchases == 0, "should not purchase when the player has too few tokens")
    check(lastChat(env):find("100", 1, true) and lastChat(env):find("250", 1, true),
        "too-few-tokens chat should show the cost and the player's count")
end

do
    local env = loadChunk({ [1780051] = 250, [1880045] = 250 }, { owned = { [1780051] = true, [1880045] = true } })
    env.tokens = 1000
    env.SlashCmdList.STONEBUYER("Goldshire")
    check(#env.purchases == 0, "should not purchase a stone the player already owns")
    check(lastChat(env):find("already own", 1, true), "already-owned chat is missing")
end

do
    local env = loadChunk({})
    env.SlashCmdList.STONEBUYER("Not A Place")
    check(#env.purchases == 0, "unknown names should not purchase")
    check(lastChat(env):find("No Stone of Retreat", 1, true), "unknown zone should say no stone is listed")
end

do
    local env = loadChunk({ [102201] = 250 })
    env.tokens = 1000
    env.SlashCmdList.STONEBUYER("Zangarmarsh")
    check(#env.purchases == 1 and env.purchases[1] == 102194,
        "Zangarmarsh should start with Telredor, then Zabra'jin")
    env.owned[102194] = true
    env.owned[102201] = false
    env.purchases = {}
    env.SlashCmdList.STONEBUYER("Zangarmarsh")
    check(#env.purchases == 1 and env.purchases[1] == 102201,
        "Zangarmarsh should use the Zabra'jin stone id after Telredor is owned")
end

do
    local env = loadChunk({ [1780051] = 250, [1880045] = 250 })
    env.tokens = 1000
    env.shift = true
    env.ctrl = false
    env.areaName = "Elwynn Forest"
    check(env.hooks.WorldMapButton_OnClick, "WorldMapButton_OnClick should be hooked")
    env.hooks.WorldMapButton_OnClick(nil, "LeftButton")
    check(#env.purchases == 0, "plain shift-click must not buy a stone")
end

do
    local env = loadChunk({ [1780051] = 250, [1880045] = 250 })
    env.tokens = 1000
    env.shift = true
    env.ctrl = true
    env.areaName = "Elwynn Forest"
    env.hooks.WorldMapButton_OnClick(nil, "LeftButton")
    check(#env.purchases == 1 and env.purchases[1] == 1780051,
        "Ctrl+Shift-click on Elwynn Forest should buy the Goldshire stone")
end

do
    local env = loadChunk({ [1780051] = 250 })
    env.tokens = 1000
    env.shift = true
    env.ctrl = true
    env.areaName = "Unknown Zone"
    env.tooltip = "Stone of Retreat: Goldshire"
    env.hooks.WorldMapButton_OnClick(nil, "LeftButton")
    check(#env.purchases == 1 and env.purchases[1] == 1780051,
        "a pin tooltip named Stone of Retreat: Goldshire should buy that stone")
end

do
    local env = loadChunk({})
    env.SlashCmdList.STONEBUYER("help")
    check(#env.purchases == 0, "help should not purchase")
    check(lastChat(env):find("/stonebuyer", 1, true), "help should mention the slash command")
    check(not lastChat(env):find("250", 1, true), "help must not hardcode a token price")
end

if failures > 0 then
    os.exit(1)
end
print("PASS: " .. "zone aliases, map clicks, confirmations, ownership, prices and slash commands")
