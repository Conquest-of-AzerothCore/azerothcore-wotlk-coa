local C = require("pb_core")
local D = require("pb_data")
local R = require("pb_retail")
local Rules = require("pb_rules")

local function count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local presentation = {}
for entry in pairs(D.species) do
    local rows = {}
    for _, row in ipairs(C.Kit(entry)) do
        local a = row.ability
        rows[#rows + 1] = {
            slot = row.slot, option = row.opt, unlock = row.unlock, ability = a.id, name = a.name,
            retailName = a.retailName, icon = a.icon, text = a.text or "", vis = a.vis or 0,
            ranged = a.ranged and 1 or 0, vmode = a.vmode or "", vpre = a.vpre or 0, vhop = a.vhop and 1 or 0,
            vdmg = a.vdmg and 1 or 0, priority = a.priority and 1 or 0,
        }
    end
    presentation[entry] = rows
end

return {
    species = D.species,
    kits = R.species,
    abilities = R.abilities,
    effects = R.effects,
    stateNames = R.stateNames,
    states = R.states,
    xp = R.xp,
    zones = D.zones,
    families = Rules.FAMILIES,
    zoneSpecies = require("pb_zone_species"),
    modelSizes = require("pb_scale_caps"),
    displaySizes = require("pb_scale_displays"),
    presentation = presentation,
    luaCounts = {
        species = count(D.species), kits = count(R.species), abilities = count(R.abilities),
        auraStates = count(R.states), zones = count(D.zones),
    },
}
