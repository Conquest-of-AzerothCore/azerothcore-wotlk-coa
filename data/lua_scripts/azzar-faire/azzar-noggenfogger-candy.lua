--[[ Venture Co / Azzar Faire: NOGGENFOGGER CANDY side effects (Rowan/Claude 2026-11-18, v1.0)
  The Noggenfogger Dealer (371982) sells Noggenfogger Candy (item 558789). Eating one casts spell 255944 'Noggenfogger Candy'
  ("Eat Me."), which in the client data is only a dummy: on live the server picked the side effect. This script does that part:
  one of the four side effects of achievement 90085 'Sweet Side Effect' ("Experience all the side effects of the Noggenfogger
  Candy", criteria 60165-60168, type 110 = cast spell), at random, cast on the eater a moment after the candy:
    255939 Too spicy!        - fire breath visual every 8 s for a minute
    255940 Wonkaverse        - everyone around looks like a Wild Wonka (372010)
    255941 Mushroomorphosis  - you turn into creature 373386 (a spore creature, our stand-in look) at half size, 10 min
    255947 Hypnagogic effect - you turn into creature 379403 (a little mushroom, our stand-in look) at half size, rooted, 10 s
  The core counts a type-110 criterion on every hit of a player's spell (Spell.cpp DoSpellHitOnUnit), triggered casts included,
  so the achievement completes by itself once all four have happened.
  Not used: 255942/255943 'Noggenfogger Elixir: Poo' (summons 99727 'Poo'); it is not one of the achievement's four.
  Needs mod-ale on (all four realms load C:\Games\CoA Server Omega\CoA-Bots\Core\lua_scripts) + azzar-noggenfogger-stall.sql.
  Lines starting with [NoggenCandy] in the server log are from this script. ]]

local CANDY_SPELL = 255944
local EFFECTS = { 255939, 255940, 255941, 255947 }
local NAMES = { [255939] = "Too spicy!", [255940] = "Wonkaverse", [255941] = "Mushroomorphosis", [255947] = "Hypnagogic effect" }
local DELAY_MS = 300   -- cast the side effect after the candy's own cast has finished, not from inside it

local function log(msg) print("[NoggenCandy] " .. msg) end

RegisterPlayerEvent(5, function(event, player, spell, skipCheck)   -- PLAYER_EVENT_ON_SPELL_CAST
  if not spell or spell:GetEntry() ~= CANDY_SPELL then return end
  local pick = EFFECTS[math.random(#EFFECTS)]
  player:RegisterEvent(function(_, _, _, p)
    local ok, err = pcall(function() p:CastSpell(p, pick, true) end)
    if not ok then log("could not cast " .. tostring(pick) .. " on " .. tostring(p and p:GetName()) .. ": " .. tostring(err)) end
  end, DELAY_MS, 1)
end)

log("script loaded v1.0 (side effects: " .. NAMES[255939] .. ", " .. NAMES[255940] .. ", " .. NAMES[255941] .. ", " .. NAMES[255947] .. ")")
