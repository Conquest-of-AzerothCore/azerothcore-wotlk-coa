for i = 1, 19 do
    local tab = AscensionSpellbookFrame.SideBar["Tab" .. i]
    if tab then
        local setInfo = tab.SetInfo
        tab.SetInfo = function(self, id, ...)
            setInfo(self, id, ...)
            if id and id > 1 and not self.Class then
                self.Class = true
            end
        end
    end
end
