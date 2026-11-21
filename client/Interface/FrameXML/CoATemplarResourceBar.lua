if not IsCustomClass() or C_Player:GetClass() ~= "MONK" or not ClassMixinTemplar then return end

local TemplarResourceBar = {}

function TemplarResourceBar:Refresh()
    ClassMixinTemplar:OnPlayerAura()
end

function TemplarResourceBar:UNIT_AURA(unit)
    if unit == "player" then
        self:Refresh()
    end
end

function TemplarResourceBar:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    self:Refresh()
end

function TemplarResourceBar:ASCENSION_SPELLS_UPDATED()
    self:Refresh()
end

function TemplarResourceBar:PLAYER_ENTERING_WORLD()
    ClassMixinTemplar:OnLoad()
    C_Hook:Unregister(self, "PLAYER_ENTERING_WORLD")
end

C_Hook:Register(TemplarResourceBar,
    "UNIT_AURA, PLAYER_ENTERING_WORLD, CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED, ASCENSION_SPELLS_UPDATED")
C_Hook:RegisterBucket(TemplarResourceBar, {"SPELLS_CHANGED", "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED",
    "PLAYER_SPECIALIZATION_CHANGED", "ASCENSION_HIDDEN_SPELL_LEARNED", "ASCENSION_HIDDEN_SPELL_UNLEARNED"}, 0.1,
    "Refresh")
