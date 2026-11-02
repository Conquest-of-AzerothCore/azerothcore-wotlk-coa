local setUnit = CompactUnitMixin.SetUnit

CompactUnitMixin.SetUnit = function(self, unit)
    if not InCombatLockdown() or not self.disableMouse then
        return setUnit(self, unit)
    end
    local setAttribute = self.SetAttribute
    self.SetAttribute = function() end
    setUnit(self, unit)
    self.SetAttribute = setAttribute
end
