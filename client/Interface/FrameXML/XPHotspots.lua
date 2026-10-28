local H = { rows = {}, pins = {}, fills = {}, outlines = {}, queue = {}, page = 1, merge = {} }
XPHotspots = H
local frame = CreateFrame("Frame")
local selected, draft, hovered, panel, enabled, gm, announcements
local generalPanel
local clockOffset = 0
local chunks, chunkNext, chunkCount
local snapshot, incoming
local function N(v) return tonumber(v) or 0 end
local function B(v) return v == true or v == "true" or v == 1 or v == "1" end
function H.ShowFeedback()
    if not gm or not WorldMapFrame:IsShown() or
        not (panel and panel:IsShown() or generalPanel and generalPanel:IsShown()) then
        if H.feedback then H.feedback:Hide() end
        return false
    end
    if not H.feedback then
        local f=CreateFrame("Frame",nil,WorldMapFrame);H.feedback=f
        f:SetSize(390,150);f:SetPoint("BOTTOMLEFT",WorldMapFrame,"BOTTOMLEFT",20,35)
        f:SetFrameStrata("DIALOG");f:SetFrameLevel(WorldMapFrame:GetFrameLevel()+25)
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        f:SetBackdropColor(0.025,0.07,0.11,0.95);f:SetBackdropBorderColor(0.8,0.6,0.2,1)
        f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart",function(self) self:StartMoving() end)
        f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
        local title=f:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",10,-8);title:SetText("XP Hotspot Messages")
        local log=CreateFrame("ScrollingMessageFrame",nil,f);H.feedbackLog=log
        log:SetPoint("TOPLEFT",10,-28);log:SetPoint("BOTTOMRIGHT",-10,10)
        log:SetFontObject(GameFontHighlightSmall);log:SetJustifyH("LEFT")
        log:SetMaxLines(100);log:SetFading(false);log:EnableMouseWheel(true)
        log:SetScript("OnMouseWheel",function(self,delta)
            if delta>0 then self:ScrollUp() else self:ScrollDown() end
        end)
        for _,message in ipairs(H.feedbackHistory or {}) do log:AddMessage(message) end
    end
    H.feedback:Show()
    return true
end
local function Notify(text)
    H.feedbackHistory=H.feedbackHistory or {}
    H.feedbackHistory[#H.feedbackHistory+1]=text
    if #H.feedbackHistory>100 then table.remove(H.feedbackHistory,1) end
    if H.feedbackLog then H.feedbackLog:AddMessage(text) end
    if not H.ShowFeedback() then DEFAULT_CHAT_FRAME:AddMessage("|cffb080ffHotspots:|r " .. text) end
end
local function Send(text)
    if #text > 240 then Notify("Request too long."); return end
    if #H.queue >= 128 then Notify("Please wait for pending hotspot requests.");return end
    H.queue[#H.queue + 1] = text
    return true
end
local function Now() return time() + clockOffset end
local function View()
    local area = GetCurrentMapAreaID()
    if not C_WorldMap or not area then return end
    if area==0 then return 4294967295,0 end
    local map = C_WorldMap.GetMapIDByAreaID(area)
    local zone = C_WorldMap.GetZoneIDByAreaID(area) or 0
    local top, left = C_WorldMap.GetWorldPosition(area, 0, 0)
    local bottom, right = C_WorldMap.GetWorldPosition(area, 1, 1)
    if not map or not top or top == bottom or left == right then return end
    return map, zone, top, bottom, left, right
end
local function Overview()
    local area=GetCurrentMapAreaID()
    return area==0 or GetCurrentMapZone()==0
end
local function VisibleOnMap(r, map)
    local continent=GetCurrentMapContinent()
    if continent==-1 then return false end
    if not Overview() then return N(r.map)==map end
    local sourceMap,zone=N(r.map),N(r.zone)
    local destination
    if sourceMap==0 then destination=2
    elseif sourceMap==1 then destination=1
    elseif sourceMap==571 then destination=4
    elseif sourceMap==530 then
        if zone==3430 or zone==3433 or zone==3487 then destination=2
        elseif zone==3524 or zone==3525 or zone==3557 then destination=1
        else destination=3 end
    end
    if continent==0 then return destination==1 or destination==2 or destination==4 end
    return destination==continent
end
local function Position(x, y, sourceMap)
    local map, zone, top, bottom, left, right = View()
    if not map then return end
    if Overview() then
        if not C_WorldMap.GetMapPosition then return end
        local px,py=C_WorldMap.GetMapPosition(sourceMap,x,y,0)
        if px and py and px~=0 and py~=0 then return px,py end
        return
    end
    return (y - left) / (right - left), (x - top) / (bottom - top)
end
local function AtCursor()
    local map, zone, top, bottom, left, right = View()
    if not top then return end
    local x, y = GetCursorPosition()
    local scale = WorldMapButton:GetEffectiveScale()
    x = (x / scale - WorldMapButton:GetLeft()) / WorldMapButton:GetWidth()
    y = (WorldMapButton:GetTop() - y / scale) / WorldMapButton:GetHeight()
    return top + y * (bottom-top), left + x * (right-left)
end
local function Inside(r, x, y)
    if r.kind == "union" then
        for _,part in ipairs(type(r.parts)=="table" and r.parts or {}) do
            if Inside(part,x,y) then return true end
        end
        return false
    end
    if r.kind == "circle" then return (x-N(r.x))^2 + (y-N(r.y))^2 <= N(r.radius)^2 end
    if r.kind == "zone" then
        if type(r.mask)~="table" or type(r.bounds)~="table" then return false end
        local top,bottom,left,right=N(r.bounds[1]),N(r.bounds[2]),N(r.bounds[3]),N(r.bounds[4])
        if top==bottom or left==right then return false end
        local row=math.floor((x-top)/(bottom-top)*64)+1
        local col=math.floor((y-left)/(right-left)*64)+1
        return row>=1 and row<=64 and col>=1 and col<=64 and
            type(r.mask[row])=="string" and r.mask[row]:sub(col,col)=="1"
    end
    local points = type(r.points) == "table" and r.points or {}
    local inside, j = false, #points
    for i=1,#points do
        local a,b=points[i],points[j]
        local ax,ay,bx,by=N(a.x),N(a.y),N(b.x),N(b.y)
        if (ay>y) ~= (by>y) and x < (bx-ax)*(y-ay)/(by-ay)+ax then inside=not inside end
        j=i
    end
    return inside
end
function H.Refresh(page)
    if not enabled or not WorldMapFrame:IsShown() then return end
    H.Draw()
    if H.refreshPending then
        H.refreshAgain=true
        if type(page)=="number" then H.nextPage=page end
        return
    end
    local map, zone = View()
    if not map then return end
    H.page=type(page)=="number" and math.max(1,page) or H.page or 1
    H.rows={}
    H.refreshPending=true
    H.refreshStarted=GetTime()
    H.viewMap,H.viewZone=map,zone
    if gm and H.catalog and H.allMaps then map,zone=4294967295,0 end
    Send((gm and H.catalog and "list " or "sync ") .. map .. " " .. zone .. " " .. H.page .. " " .. (H.search or ""))
end
local function Tooltip(r, owner)
    WorldMapTooltip:SetOwner(owner,"ANCHOR_RIGHT")
    WorldMapTooltip:ClearLines()
    WorldMapTooltip:AddLine(r.name or "Hotspot",1,1,1)
    WorldMapTooltip:AddLine("+" .. N(r.xp) .. "% monster-kill experience",0.7,1,0.4)
    WorldMapTooltip:AddLine("Any eligible creature kill while you are inside this area.",0.7,0.8,1,true)
    local remaining=math.max(0,N(r.ends)-Now())
    WorldMapTooltip:AddLine(remaining>0 and SecondsToTime(remaining) .. " remaining" or "Inactive",1,0.82,0)
    if r.kind == "zone" then WorldMapTooltip:AddLine("Entire zone",0.7,0.8,1) end
    if gm and r.geometrySource=="approximate-spawn-circle" then
        WorldMapTooltip:AddLine("Approximate spawn area; no usable quest polygon recovered.",1,0.7,0.3,true)
    end
    if B(r.outlineUnavailable) then WorldMapTooltip:AddLine("Zone boundary preview unavailable",1,0.7,0.3,true) end
    if gm then
        WorldMapTooltip:AddLine("ID " .. N(r.id) .. " | " .. (B(r.enabled) and "Enabled" or "Disabled"),0.8,0.8,0.8)
        if not B(r.allowed) and not B(r.draft) then
            WorldMapTooltip:AddLine("Unavailable: map restriction or unresolved geometry",1,0.4,0.4,true)
        end
        WorldMapTooltip:AddLine("Click to select and manage",0.7,0.8,1)
    end
    WorldMapTooltip:Show()
end
function H.Highlight(r)
    for _,t in ipairs(H.fills) do t:Hide() end
    if not r or not B(r.highlight) or H.menuClosed and N(r.ends)<=Now() then return end
    local map, zone, top, bottom, left, right=View()
    if map~=N(r.map) then return end
    local w,h=WorldMapButton:GetWidth(),WorldMapButton:GetHeight()
    local count=0
    local function Fill(row,first,last)
        first,last=math.max(0,first),math.min(1,last)
        if last<=first then return end
        count=count+1
        local t=H.fills[count]
        if not t then t=WorldMapButton:CreateTexture(nil,"OVERLAY");H.fills[count]=t end
        if H.paintInvalid then t:SetTexture(1,0.1,0.1,0.4) else t:SetTexture(0.35,0.45,1,0.25) end
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT",WorldMapButton,"TOPLEFT",first*w,-row*h/66)
        t:SetSize((last-first)*w,h/66+0.5);t:Show()
    end
    local function Interval(row,a,b)
        a,b=(a-left)/(right-left),(b-left)/(right-left)
        Fill(row,math.min(a,b),math.max(a,b))
    end
    local points=type(r.points)=="table" and r.points or {}
    for row=0,65 do
        local x=top+(row+0.5)/66*(bottom-top)
        if r.kind=="circle" then
            local square=N(r.radius)^2-(x-N(r.x))^2
            if square>0 then
                local half=math.sqrt(square);Interval(row,N(r.y)-half,N(r.y)+half)
            end
        elseif r.kind=="polygon" then
            local hits={}
            for i=1,#points do
                local a,b=points[i],points[i%#points+1]
                local ax,bx=N(a.x),N(b.x)
                if (ax>x)~=(bx>x) then hits[#hits+1]=N(a.y)+(x-ax)*(N(b.y)-N(a.y))/(bx-ax) end
            end
            table.sort(hits)
            for i=1,#hits-1,2 do Interval(row,hits[i],hits[i+1]) end
        else
            local first
            for col=0,100 do
                local hit=col<100 and Inside(r,x,left+(col+0.5)/100*(right-left))
                if hit and not first then first=col end
                if first and not hit then Fill(row,first/100,col/100);first=nil end
            end
        end
    end
end
function H.Outline(r)
    local map,zone,top,bottom,left,right=View()
    if H.menuClosed or not r or r.kind=="zone" or map~=N(r.map) then return end
    local w,h=WorldMapButton:GetWidth(),WorldMapButton:GetHeight()
    local cols,rows=192,128
    local grid={}
    for row=-1,rows do
        grid[row]={}
        local x=top+(row+0.5)/rows*(bottom-top)
        local hits={}
        if r.kind=="polygon" then
            local points=type(r.points)=="table" and r.points or {}
            for i,a in ipairs(points) do
                local b=points[i%#points+1]
                if (N(a.x)>x)~=(N(b.x)>x) then
                    hits[#hits+1]=N(a.y)+(x-N(a.x))*(N(b.y)-N(a.y))/(N(b.x)-N(a.x))
                end
            end
            table.sort(hits)
        end
        for col=-1,cols do
            local y=left+(col+0.5)/cols*(right-left)
            if r.kind=="polygon" then
                local hit=false
                for i=1,#hits-1,2 do if y>=hits[i] and y<=hits[i+1] then hit=true;break end end
                grid[row][col]=hit
            else grid[row][col]=Inside(r,x,y) end
        end
    end
    local function Edge(x,y,width,height)
        H.outlineCount=(H.outlineCount or 0)+1
        local t=H.outlines[H.outlineCount]
        if not t then t=WorldMapButton:CreateTexture(nil,"OVERLAY");H.outlines[H.outlineCount]=t end
        t:SetTexture(1,0.8,0.2,1);t:ClearAllPoints()
        t:SetPoint("TOPLEFT",WorldMapButton,"TOPLEFT",x,y)
        t:SetSize(width,height);t:Show()
    end
    for row=0,rows-1 do
        for col=0,cols-1 do
            if grid[row][col] then
                if not grid[row-1][col] then Edge(col*w/cols,-row*h/rows,w/cols,1.5) end
                if not grid[row+1][col] then Edge(col*w/cols,-(row+1)*h/rows,w/cols,1.5) end
                if not grid[row][col-1] then Edge(col*w/cols,-row*h/rows,1.5,h/rows) end
                if not grid[row][col+1] then Edge((col+1)*w/cols,-row*h/rows,1.5,h/rows) end
            end
        end
    end
end
function H.ToggleMerge(r)
    if not gm or not r or r.kind=="zone" or N(r.id)==0 or B(r.draft) then return end
    local id=N(r.id)
    H.merge[id]=not H.merge[id] and N(r.revision) or nil
    H.Draw()
end
function H.Draw()
    for _,p in ipairs(H.pins) do p:Hide() end
    for _,t in ipairs(H.fills) do t:Hide() end
    for _,t in ipairs(H.outlines) do t:Hide() end
    H.outlineCount=0
    if not enabled or not WorldMapFrame:IsShown() then return end
    local map,zone=View()
    if not map then return end
    local rows={}
    for _,r in pairs(H.rows) do
        if (H.menuClosed or not draft or N(draft.id)~=N(r.id)) and
            (not H.menuClosed or N(r.ends)>Now()) then rows[#rows+1]=r end
    end
    if draft and not H.menuClosed then rows[#rows+1]=draft end
    local count=0
    for _,r in ipairs(rows) do
        if VisibleOnMap(r,map) and (B(r.icon) or gm and H.catalog or B(r.draft)) then
            local x,y=Position(N(r.x),N(r.y),N(r.map))
            if x and x>=0 and x<=1 and y>=0 and y<=1 then
                count=count+1
                local p=H.pins[count]
                if not p then
                    p=CreateFrame("Button",nil,WorldMapButton)
                    p:SetSize(24,24)
                    p:SetFrameLevel(WorldMapButton:GetFrameLevel()+8)
                    p:SetNormalAtlas("hotspot-xp")
                    p:RegisterForClicks("LeftButtonUp","RightButtonUp")
                    p:SetScript("OnEnter",function(self)
                        hovered=self.row;H.hoverOwner=self;Tooltip(self.row,self);H.Highlight(self.row)
                        if self.row.kind=="zone" and not self.row.mask and not self.row.outlineRequested then
                            self.row.outlineRequested=true;Send("outline "..N(self.row.id))
                        end
                    end)
                    p:SetScript("OnLeave",function()
                        hovered=nil;H.hoverOwner=nil;WorldMapTooltip:Hide();H.Highlight(selected or draft)
                    end)
                    p:SetScript("OnClick",function(self)
                        if gm and IsShiftKeyDown() then H.ToggleMerge(self.row);return end
                        H.Select(self.row)
                    end)
                    H.pins[count]=p
                end
                p:EnableMouse(not (H.paintMode and H.paintMode~="Points"))
                p.row=r
                local chosen=selected and N(selected.id)==N(r.id)
                p:SetSize(24,24)
                if not p.selection then
                    p.selection=p:CreateTexture(nil,"OVERLAY")
                    p.selection:SetPoint("CENTER",p,"CENTER",0,0)
                    p.selection:SetSize(64,64)
                    p.selection:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                    p.selection:SetBlendMode("ADD")
                    p.selection:SetVertexColor(1,0.8,0.2,1)
                end
                if chosen and r.kind=="zone" then p.selection:Show() else p.selection:Hide() end
                p:ClearAllPoints()
                p:SetPoint("CENTER",WorldMapButton,"TOPLEFT",x*WorldMapButton:GetWidth(),-y*WorldMapButton:GetHeight())
                p:SetAlpha(N(r.ends)>Now() and 1 or 0.5)
                p:Show()
            end
        end
    end
    H.Highlight(H.menuClosed and hovered or (not H.menuClosed and (hovered or selected or draft)))
    if gm and not H.menuClosed then
        H.Outline(selected or draft)
        for id in pairs(H.merge) do
            if not selected or id~=N(selected.id) then H.Outline(H.rows[id]) end
        end
    end
    if H.DrawBrowser then H.DrawBrowser() end
    if H.RebuildLocalPaint then H.RebuildLocalPaint() end
end
local function Button(parent,text,x,y,width,click)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width or 130,22);b:SetPoint("TOPLEFT",x,y);b:SetText(text);b:SetScript("OnClick",click)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    b:SetBackdropColor(0.03,0.11,0.17,1);b:SetBackdropBorderColor(0.78,0.60,0.27,1)
    b:SetNormalTexture("");b:SetPushedTexture("")
    local glow=b:CreateTexture(nil,"HIGHLIGHT");glow:SetAllPoints();glow:SetTexture(0.90,0.70,0.30,0.16)
    b:SetHighlightTexture(glow)
    b:SetNormalFontObject("GameFontNormalSmall");b:SetHighlightFontObject("GameFontHighlightSmall")
    return b
end
local fields={}
local browser
local generalFields, generalRevision, generalDirty
function H.CloseWindows()
    if H.closingWindows or H.switchingMenu then return end
    H.closingWindows=true
    H.menuClosed=true
    if H.EndPaint then H.EndPaint() end
    H.paintMode="Points";H.paintConsumed=nil;H.cursorKey=nil
    for _,window in pairs({panel,generalPanel,browser,H.paintPanel,H.feedback}) do window:Hide() end
    for _,texture in ipairs(H.brushDots or {}) do texture:Hide() end
    hovered=nil;H.hoverOwner=nil;WorldMapTooltip:Hide()
    StaticPopup_Hide("XP_HOTSPOT_DELETE")
    H.catalog=false;H.allMaps=false;H.search="";H.searchAt=nil;H.page=1
    if H.searchBox then H.searchBox:SetText("") end
    H.searchAt=nil
    H.closingWindows=nil
    H.Draw()
    H.Refresh(1)
end
function H.DrawBrowser()
    if not browser then return end
    if not enabled or not gm or not H.catalog or not panel or not panel:IsShown() or
        generalPanel and generalPanel:IsShown() then browser:Hide();return end
    local rows={}
    for _,r in pairs(H.rows) do rows[#rows+1]=r end
    table.sort(rows,function(a,b) return N(a.id)<N(b.id) end)
    for i,b in ipairs(browser.rows) do
        local r=rows[i]
        b.row=r
        if r then
            b:SetText((N(r.ends)>Now() and "|cff80ff80" or B(r.enabled) and "|cffffffff" or "|cff888888") ..
                (selected and N(selected.id)==N(r.id) and "[SELECTED] " or "")..
                (H.merge[N(r.id)] and "[+] " or "")..N(r.id).." "..(r.name or "").."|r")
            b:Show()
        else b:Hide() end
    end
    browser.page:SetText("Page "..(H.page or 1).." / "..(H.pages or 1))
    browser:Show()
end
local function ShowBrowser()
    if not browser then
        browser=CreateFrame("Frame",nil,WorldMapFrame)
        browser:SetSize(260,469);browser:SetPoint("TOPLEFT",WorldMapFrame,"TOPLEFT",12,-65)
        browser:SetFrameStrata("DIALOG");browser:EnableMouse(true)
        browser:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
        browser:SetBackdropColor(0.03,0.11,0.17,0.97)
        browser:SetBackdropBorderColor(0.78,0.60,0.27,1)
        local title=browser:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",12,-12);title:SetText("XP Hotspots")
        title:SetTextColor(0.95,0.76,0.39)
        browser.title=title
        local search=CreateFrame("EditBox",nil,browser)
        search:SetFontObject("GameFontHighlightSmall")
        search:SetTextInsets(6,6,2,2)
        search:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        search:SetBackdropColor(0.02,0.03,0.06,1);search:SetBackdropBorderColor(0.65,0.53,0.3,1)
        search:SetPoint("TOPLEFT",12,-36);search:SetSize(190,20);search:SetAutoFocus(false);search:SetMaxLetters(100)
        H.searchBox=search
        local function Search() H.searchAt=nil;H.search=search:GetText();H.Refresh(1) end
        search:SetScript("OnTextChanged",function(self,user)
            if user then H.searchAt=GetTime()+0.4 end
        end)
        search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        search:SetScript("OnEnterPressed",function(self) self:ClearFocus();Search() end)
        Button(browser,"Find",205,-34,45,Search)
        browser.rows={}
        for i=1,12 do
            local b=Button(browser,"",10,-64-(i-1)*27,240,function(self)
                if IsShiftKeyDown() and self.row and self.row.kind~="zone" then
                    H.ToggleMerge(self.row);return
                end
                H.Select(self.row)
            end)
            b:SetScript("OnEnter",function(self)
                if not self.row then return end
                hovered=self.row;H.hoverOwner=self;Tooltip(self.row,self);H.Highlight(self.row)
                if self.row.kind=="zone" and not self.row.mask then Send("outline "..N(self.row.id)) end
            end)
            b:SetScript("OnLeave",function()
                hovered=nil;H.hoverOwner=nil;WorldMapTooltip:Hide();H.Highlight(selected or draft)
            end)
            browser.rows[i]=b
        end
        Button(browser,"Previous",10,-393,100,function() H.Refresh(math.max(1,(H.page or 1)-1)) end)
        Button(browser,"Next",150,-393,100,function() H.Refresh(math.min(H.pages or 1,(H.page or 1)+1)) end)
        browser.page=browser:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        browser.page:SetPoint("TOP",0,-424)
        Button(browser,"This map / all locations",10,-440,240,function() H.allMaps=not H.allMaps;H.Refresh(1) end)
    end
    H.DrawBrowser()
end
local function Input(parent)
    local edit=CreateFrame("EditBox",nil,parent)
    edit:SetFontObject("GameFontHighlightSmall");edit:SetTextInsets(5,5,2,2)
    edit:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    edit:SetBackdropColor(0.02,0.06,0.10,1);edit:SetBackdropBorderColor(0.78,0.60,0.27,1)
    edit:SetAutoFocus(false)
    return edit
end
local function Field(label,y,default)
    local text=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    text:SetPoint("TOPLEFT",10,y);text:SetText(label)
    local edit=Input(panel)
    edit:SetSize(225,20);edit:SetPoint("TOPLEFT",115,y+3)
    edit:SetText(default);edit:SetMaxLetters(100);fields[label]=edit
    return edit
end
local function SelectedCommand(action)
    if not selected then Notify("Select a hotspot marker first.");return end
    Send(action .. " " .. N(selected.id) .. " " .. N(selected.revision))
end
local function ApplyFields()
    if H.localSaving then return false end
    if H.localStrokes and #H.localStrokes>0 then Notify("Settings will be submitted with Save Draft.");return true end
    if not draft or selected and N(selected.id)~=N(draft.id) then Notify("Click Edit selected first.");return false end
    if H.canDesign then Send("name "..fields.Name:GetText()) end
    Send("settings "..fields["XP bonus %"]:GetText().." "..N(fields.Minutes:GetText())*60 .." "..
        fields.Weight:GetText().." "..N(fields["Cooldown min"]:GetText())*60 .." "..
        (fields.icon:GetChecked() and "1" or "0").." "..(fields.fill:GetChecked() and "1" or "0"))
    if H.canDesign and draft.kind=="circle" then Send("radius "..fields["Radius yards"]:GetText()) end
    return true
end
local generalLabels={
    {2,"Total active",20},{6,"Eastern Kingdoms",20},{7,"Kalimdor",20},
    {8,"Outland",20},{9,"Northrend",20},{10,"Alliance areas",20},
    {11,"Horde areas",20},{12,"Neutral / contested",20},{3,"Default XP bonus %",1000},
    {4,"Default duration (min)",1440},{5,"Default cooldown (min)",10080}
}
local function PopulateGeneral()
    if not generalPanel or not H.general or generalDirty then return end
    for _,entry in ipairs(generalLabels) do
        local index=entry[1]
        generalFields[index]:SetText(H.general[index]/((index==4 or index==5) and 60 or 1))
    end
    generalFields[1]:SetChecked(H.general[1]==1)
    generalFields[14]:SetChecked(H.general[14]==1)
    generalRevision=H.general[13]
end
function H.ShowGeneral()
    if not gm or not enabled then return end
    H.menuClosed=nil
    H.switchingMenu=true
    if panel then panel:Hide() end
    H.switchingMenu=nil
    if H.EndPaint then H.EndPaint() end
    if H.paintPanel then H.paintPanel:Hide() end
    H.paintMode="Points"
    for _,texture in ipairs(H.brushDots or {}) do texture:Hide() end
    if browser then browser:Hide() end
    if not generalPanel then
        generalPanel=CreateFrame("Frame",nil,WorldMapFrame)
        generalPanel:SetScript("OnHide",H.CloseWindows)
        generalPanel:SetScript("OnShow",H.ShowFeedback)
        generalPanel:SetSize(360,600);generalPanel:SetPoint("TOPRIGHT",WorldMapFrame,"TOPRIGHT",-12,-55)
        generalPanel:SetFrameStrata("DIALOG");generalPanel:EnableMouse(true)
        generalPanel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
        generalPanel:SetBackdropColor(0.03,0.11,0.17,0.97)
        generalPanel:SetBackdropBorderColor(0.78,0.60,0.27,1)
        local title=generalPanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",12,-12);title:SetText("XP Hotspots â€” General Settings")
        Button(generalPanel,"X",325,-5,25,function() generalPanel:Hide() end)
        Button(generalPanel,"Locations",12,-35,150,H.ShowPanel)
        Button(generalPanel,"General Settings",180,-35,165,function() end)
        generalFields={}
        for row,entry in ipairs(generalLabels) do
            local index=entry[1]
            local label=generalPanel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
            label:SetPoint("TOPLEFT",12,-70-(row-1)*28);label:SetText(entry[2])
            local edit=Input(generalPanel)
            edit:SetSize(90,20);edit:SetPoint("TOPLEFT",240,-67-(row-1)*28)
            edit:SetAutoFocus(false);edit:SetMaxLetters(8)
            edit:SetScript("OnTextChanged",function(_,user) if user then generalDirty=true end end)
            generalFields[index]=edit
        end
        local function Check(text,y)
            local check=CreateFrame("CheckButton",nil,generalPanel,"UICheckButtonTemplate")
            check:SetPoint("TOPLEFT",10,y);check:SetSize(24,24)
            local label=generalPanel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
            label:SetPoint("LEFT",check,"RIGHT",0,0);label:SetText(text)
            return check
        end
        generalFields[1]=Check("Global start announcements",-382)
        generalFields[1]:SetScript("OnClick",function() generalDirty=true end)
        generalFields[14]=Check("Full-zone hotspots only",-409)
        generalFields[14]:SetScript("OnClick",function() generalDirty=true end)
        generalFields.apply=Check("Apply defaults to all existing hotspots",-436)
        generalFields.apply:SetChecked(false)
        local hint=generalPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT",12,-465);hint:SetWidth(334)
        hint:SetText("Counts are maximums (0 excludes, 20 unrestricted). Lower limits stop excess events. "..
            "Applying defaults overwrites XP, duration and cooldown, including active events; "..
            "duration is measured from their original start. Full-zone only stops other active shapes; "..
            "turn it off to restore normal eligibility.")
        Button(generalPanel,"Save general settings",12,-535,200,function()
            if not gm or not generalRevision then return end
            local values={generalFields[1]:GetChecked() and 1 or 0}
            for _,entry in ipairs(generalLabels) do
                local index=entry[1]
                local value=tonumber(generalFields[index]:GetText())
                if not value or value<0 or value>entry[3] or value~=math.floor(value) or index==4 and value<1 then
                    Notify("Invalid value: "..entry[2]);return
                end
                values[index]=value*((index==4 or index==5) and 60 or 1)
            end
            values[13]=generalRevision;values[14]=generalFields[14]:GetChecked() and 1 or 0
            values[15]=generalFields.apply:GetChecked() and 1 or 0
            Send("general "..table.concat(values," "))
            H.generalSaving=true
        end)
        Button(generalPanel,"Reload",230,-535,110,function()
            generalDirty=false;Send("general")
        end)
    end
    PopulateGeneral();generalPanel:Show();Send("general")
end
function H.Select(row)
    selected=row
    if gm then H.ShowPanel() end
    H.Draw()
end
StaticPopupDialogs["XP_HOTSPOT_DELETE"]={
    text="Permanently delete hotspot %s?\n\nThis cannot be reversed.",
    button1="Delete",button2=CANCEL or "Cancel",timeout=0,whileDead=true,hideOnEscape=true,
    OnHide=function(self)
        local saved=self.hotspotPresentation
        self.hotspotPresentation=nil
        if saved then
            self:SetParent(saved.parent)
            self:SetFrameStrata(saved.strata);self:SetFrameLevel(saved.level)
            self:ClearAllPoints()
            for _,point in ipairs(saved.points) do self:SetPoint(unpack(point)) end
        end
    end,
    OnAccept=function(self)
        local r=self.data
        if gm and r then Send("delete "..N(r.id).." "..N(r.revision)) end
    end,
}
function H.ShowPanel()
    if not gm then return end
    H.menuClosed=nil
    H.switchingMenu=true
    if generalPanel then generalPanel:Hide() end
    H.switchingMenu=nil
    if not panel then
        panel=CreateFrame("Frame",nil,WorldMapFrame)
        panel:SetScript("OnHide",H.CloseWindows)
        panel:SetScript("OnShow",H.ShowFeedback)
        panel:SetSize(360,600);panel:SetPoint("TOPRIGHT",WorldMapFrame,"TOPRIGHT",-12,-55)
        panel:SetFrameStrata("DIALOG");panel:EnableMouse(true)
        panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
        panel:SetBackdropColor(0.03,0.11,0.17,0.97)
        panel:SetBackdropBorderColor(0.78,0.60,0.27,1)
        local title=panel:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",10,-12);title:SetText("XP Hotspot Manager")
        title:SetTextColor(0.95,0.76,0.39)
        panel.title=title
        Button(panel,"X",325,-5,25,function() panel:Hide();if browser then browser:Hide() end end)
        Button(panel,"Locations",12,-35,150,function() end)
        Button(panel,"General Settings",180,-35,165,H.ShowGeneral)
        Field("Name",-100,"New Hotspot")
        Field("XP bonus %",-125,"150")
        Field("Minutes",-150,"60")
        Field("Weight",-175,"1")
        Field("Cooldown min",-200,"60")
        Field("Radius yards",-225,"150")
        local icon=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate")
        icon:SetPoint("TOPLEFT",12,-525);icon:SetSize(24,24);icon:SetChecked(true)
        local iconText=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        iconText:SetPoint("LEFT",icon,"RIGHT",0,0);iconText:SetText("Show XP icon")
        local fill=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate")
        fill:SetPoint("TOPLEFT",180,-525);fill:SetSize(24,24);fill:SetChecked(true)
        local fillText=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        fillText:SetPoint("LEFT",fill,"RIGHT",0,0);fillText:SetText("Show highlight")
        fields.icon,fields.fill=icon,fill
        H.designButtons={}
        local function DesignButton(...)
            local b=Button(panel,...);H.designButtons[#H.designButtons+1]=b;return b
        end
        DesignButton("New Draft",12,-65,150,function() H.NewDraft() end)
        DesignButton("Circle",12,-255,102,function() H.StartShape("circle") end)
        DesignButton("Whole zone",126,-255,102,function() H.StartShape("zone") end)
        DesignButton("Polygon",240,-255,102,function() H.StartShape("polygon") end)
        Button(panel,"Edit selected",12,-285,150,function()
            H.vertex=nil;H.newKind=nil;H.awaitingNewDraft=nil;H.expectedDraft=nil
            if H.localSaving or H.localStrokes and #H.localStrokes>0 then Notify("Save or cancel the local drawing first.");return end
            if selected then Send("edit "..N(selected.id)) end
        end)
        DesignButton("Merge selection",180,-285,165,function()
            local ids={};for id in pairs(H.merge) do ids[#ids+1]=id end;table.sort(ids)
            if #ids<2 or #ids>8 then Notify("SHIFT-click 2 to 8 area markers or browser rows to merge.");return end
            local command="merge"
            for _,id in ipairs(ids) do command=command.." "..id.." "..H.merge[id] end
            Send(command);H.newKind=nil;H.vertex=nil
        end)
        Button(panel,"Apply settings",12,-315,150,ApplyFields)
        Button(panel,"Save draft",180,-65,165,function()
            if H.stroke or H.paintPending then Notify("Wait for the drawing preview before saving.");return end
            if not draft or selected and N(selected.id)~=N(draft.id) then Notify("Click Edit selected first.");return end
            H.SaveLocalPaint(fields["XP bonus %"]:GetText().." "..N(fields.Minutes:GetText())*60 .." "..
                fields.Weight:GetText().." "..N(fields["Cooldown min"]:GetText())*60 .." "..
                (fields.icon:GetChecked() and "1" or "0").." "..(fields.fill:GetChecked() and "1" or "0")..
                " "..fields["Radius yards"]:GetText().." "..fields.Name:GetText())
        end)
        Button(panel,"Enable selected",12,-345,150,function() SelectedCommand("enable") end)
        Button(panel,"Disable selected",180,-345,165,function() SelectedCommand("disable") end)
        Button(panel,"Move to next",12,-375,150,function() SelectedCommand("next") end)
        Button(panel,"Stop selected",180,-375,165,function() SelectedCommand("stop") end)
        Button(panel,"Teleport to center",12,-465,333,function() SelectedCommand("teleport") end)
        H.deleteButton=Button(panel,"Delete selected",180,-405,165,function()
            if not H.canDelete then Notify("Level 3 GM required to permanently delete hotspots.");return end
            if not selected or B(selected.draft) or N(selected.id)==0 then
                Notify("Select a saved hotspot first.");return
            end
            local popup=StaticPopup_Show("XP_HOTSPOT_DELETE",selected.name or N(selected.id),nil,
                {id=N(selected.id),revision=N(selected.revision)})
            if popup then
                local points={}
                for i=1,popup:GetNumPoints() do points[i]={popup:GetPoint(i)} end
                popup.hotspotPresentation={parent=popup:GetParent(),strata=popup:GetFrameStrata(),
                    level=popup:GetFrameLevel(),points=points}
                popup:SetParent(WorldMapFrame)
                popup:ClearAllPoints();popup:SetPoint("CENTER",WorldMapFrame,"CENTER",0,0)
                popup:SetFrameStrata("TOOLTIP")
                popup:SetFrameLevel(math.max(WorldMapFrame:GetFrameLevel(),panel:GetFrameLevel())+20)
                popup:Raise()
            else
                Notify("Delete confirmation could not open. Close another dialog and try again.")
            end
        end)
        Button(panel,"Browse / active",12,-495,333,function()
            H.catalog=not H.catalog;ShowBrowser();H.Refresh(1)
        end)
        fields.announce=Button(panel,"Announcements",12,-405,150,function()
            Send("announce "..(announcements and "0" or "1"))
        end)
        Button(panel,"Cancel draft",180,-315,165,function()
            if H.localSaving then Notify("Wait for the save result.");return end
            H.ClearLocalPaint()
            if selected then selected=H.rows[N(selected.id)] end
            draft=nil;H.awaitingNewDraft=nil;H.expectedDraft=nil;H.newKind=nil;H.newCenter=nil;H.vertex=nil;H.merge={};Send("cancel");H.Draw();H.DrawBrowser()
        end)
        Button(panel,"Refresh",12,-435,150,H.Refresh)
        DesignButton("Drawing tools",180,-435,165,function() H.ShowPaintTools() end)
        local hint=panel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT",12,-555);hint:SetWidth(333)
        panel.hint=hint
        hint:SetText("CTRL-click starts a circle. Choose Polygon to map its boundary. Editing: CTRL-click moves center/adds vertex; "..
            "ALT-click selects vertex; CTRL-right undoes. Drawing tools: CTRL-drag to trace or brush. Save, then Enable.")
    end
    local r=selected or draft
    panel.title:SetText(r and ("Selected Hotspot #"..N(r.id)) or "XP Hotspot Manager")
    if r then
        fields.Name:SetText(r.name or "")
        fields["XP bonus %"]:SetText(N(r.xp));fields.Minutes:SetText(N(r.duration)/60)
        fields.Weight:SetText(N(r.weight));fields["Cooldown min"]:SetText(N(r.cooldown)/60)
        fields["Radius yards"]:SetText(N(r.radius))
        fields.icon:SetChecked(B(r.icon));fields.fill:SetChecked(B(r.highlight))
    end
    H.UpdateDesignAccess()
    panel:Show()
    fields.announce:SetText(announcements and "Announce: ON" or "Announce: OFF")
    ShowBrowser()
end
function H.NewDraft()
    if H.localSaving or H.localStrokes and #H.localStrokes>0 then Notify("Save or cancel the local drawing first.");return end
    if not H.canDesign then Notify("Level 2 GM required to create hotspots.");return end
    if draft then Send("cancel") end
    H.stroke=nil;H.paintMode="Points";H.paintConsumed=nil;H.paintPending=nil
    H.awaitingNewDraft=true;H.expectedDraft=nil
    if H.paintPanel then H.paintPanel:Hide() end
    selected=nil;draft=nil;H.newKind=nil;H.newCenter=nil;H.vertex=nil;H.merge={}
    H.ShowPanel()
    fields.Name:SetText("New Hotspot")
    fields["XP bonus %"]:SetText(H.general and H.general[3] or 150)
    fields.Minutes:SetText((H.general and H.general[4] or 3600)/60)
    fields["Cooldown min"]:SetText((H.general and H.general[5] or 3600)/60)
    fields.Weight:SetText(1);fields["Radius yards"]:SetText(150)
    fields.icon:SetChecked(true);fields.fill:SetChecked(true)
    H.Draw();Notify("CTRL-click a zone map to start a circular draft. Choose Polygon to map a boundary.")
end
function H.StartShape(kind)
    if H.localSaving or H.localStrokes and #H.localStrokes>0 then Notify("Save or cancel the local drawing first.");return end
    if not H.canDesign then Notify("Level 2 GM required to change boundaries.");return end
    if draft and N(draft.id)~=0 and (kind=="circle" or kind=="polygon") then
        if Send("shape "..kind) then H.paintPending=true end;return
    end
    if draft then
        if N(draft.id)~=0 then Notify("Click New Draft before creating a different shape.");return end
        H.newCenter={map=N(draft.map),zone=N(draft.zone),x=N(draft.x),y=N(draft.y)}
        draft=nil;selected=nil
    elseif selected then
        H.NewDraft()
    end
    H.newKind=kind
    local c=H.newCenter
    if not c then Notify("CTRL-click a zone map to set the new center.");return end
    H.newKind=nil;H.newCenter=nil;H.vertex=nil
    H.expectedDraft={map=c.map,zone=c.zone,x=c.x,y=c.y,kind=kind,radius=fields["Radius yards"]:GetText()}
    H.awaitingNewDraft=true
    H.draftRequestedAt=GetTime()
    Notify("Requesting "..kind.." draft on map "..c.map..", zone "..c.zone..". Waiting for server response.")
    Send("newmap "..kind.." "..c.map.." "..c.zone.." "..c.x.." "..c.y.." "..fields.Name:GetText())

end
function H.SetPaintMode(mode)
    if H.stroke then H.EndPaint() end
    H.paintMode=mode;H.Draw();if H.RebuildLocalPaint then H.RebuildLocalPaint() end
    if H.paintLabel then H.paintLabel:SetText("Mode: "..mode.." | CTRL-drag on a zone map") end
end
function H.ShowPaintTools()
    if not gm or not H.canDesign then return end
    if not H.paintPanel then
        local f=CreateFrame("Frame",nil,WorldMapFrame);H.paintPanel=f
        f:SetSize(330,190);f:SetPoint("CENTER",WorldMapFrame,"CENTER",-170,100)
        f:SetFrameStrata("DIALOG");f:SetFrameLevel(WorldMapFrame:GetFrameLevel()+15)
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        f:SetBackdropColor(0.025,0.07,0.11,0.98);f:SetBackdropBorderColor(0.8,0.6,0.2,1)
        f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart",function(self) self:StartMoving() end)
        f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
        local title=f:CreateFontString(nil,"OVERLAY","GameFontNormal")
        title:SetPoint("TOPLEFT",10,-10);title:SetText("Polygon drawing tools")
        Button(f,"X",292,-4,28,function() f:Hide();H.SetPaintMode("Points") end)
        Button(f,"Points",10,-35,96,function() H.SetPaintMode("Points") end)
        Button(f,"Trace perimeter",112,-35,105,function() H.SetPaintMode("Trace") end)
        Button(f,"Brush / fill",223,-35,96,function() H.SetPaintMode("Brush") end)
        H.brushKind="round";H.brushRadius=75
        local shape
        shape=Button(f,"Brush: Round",10,-70,145,function()
            H.brushKind=H.brushKind=="round" and "square" or "round"
            shape:SetText("Brush: "..(H.brushKind=="round" and "Round" or "Square"))
        end)
        local label=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        label:SetPoint("TOPLEFT",165,-72);label:SetText("Radius (yards)")
        local radius=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
        radius:SetSize(55,20);radius:SetPoint("TOPLEFT",255,-70);radius:SetAutoFocus(false)
        radius:SetText("75");radius:SetMaxLetters(4)
        radius:SetScript("OnTextChanged",function(self) H.brushRadius=math.max(5,math.min(1000,N(self:GetText()))) end)
        Button(f,"Undo stroke",10,-105,145,function() H.UndoLocalPaint() end)
        H.paintLabel=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        H.paintLabel:SetPoint("TOPLEFT",10,-138);H.paintLabel:SetWidth(305)
        local hint=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT",10,-158);hint:SetWidth(305)
        hint:SetText("Brush adds area; Trace replaces it. Up to 20 yards smoothing keeps a single perimeter. Red means a limit or invalid boundary.")
    end
    H.paintPanel:Show();H.SetPaintMode(H.paintMode or "Points")
end
local function PaintCursor(x,y)
    local key=tostring(x)..":"..tostring(y)..":"..tostring(H.brushRadius)..":"..tostring(H.brushKind)..":"..tostring(H.paintMode)..":"..tostring(GetCurrentMapAreaID())..":"..tostring(H.paintInvalid)
    if key==H.cursorKey then return end
    H.cursorKey=key
    H.brushDots=H.brushDots or {}
    for _,t in ipairs(H.brushDots) do t:Hide() end
    if not x or H.paintMode~="Brush" then return end
    local map,zone,top,bottom,left,right=View()
    if not top then return end
    for i=1,48 do
        local a=i*math.pi*2/48;local dx,dy=math.cos(a),math.sin(a)
        if H.brushKind=="square" then local m=math.max(math.abs(dx),math.abs(dy));dx,dy=dx/m,dy/m end
        local px=(y+dy*(H.brushRadius or 75)-left)/(right-left)
        local py=(x+dx*(H.brushRadius or 75)-top)/(bottom-top)
        if px and px>=0 and px<=1 and py>=0 and py<=1 then
            local t=H.brushDots[i]
            if not t then t=WorldMapButton:CreateTexture(nil,"OVERLAY");H.brushDots[i]=t end
            if H.paintInvalid then t:SetTexture(1,0.1,0.1,0.9) else t:SetTexture(1,0.75,0.15,0.9) end;t:ClearAllPoints()
            t:SetPoint("CENTER",WorldMapButton,"TOPLEFT",px*WorldMapButton:GetWidth(),-py*WorldMapButton:GetHeight())
            t:SetSize(3,3);t:Show()
        end
    end
end
local function PaintPosition()
    if not gm or not H.canDesign or not draft or draft.kind~="polygon" or not H.paintPanel or not H.paintPanel:IsShown() or
        not WorldMapFrame:IsShown() or Overview() then return end
    local map,zone,top,bottom,left,right=View()
    if map~=N(draft.map) or zone~=N(draft.zone) then return end
    local x,y=AtCursor()
    if x and x>=math.min(top,bottom) and x<=math.max(top,bottom) and
        y>=math.min(left,right) and y<=math.max(left,right) then return x,y end
end
local function LocalCount()
    local n=0
    for _,stroke in ipairs(H.localStrokes or {}) do n=n+(stroke.mode=="Trace" and #stroke.points+1 or #stroke.points) end
    return n
end
function H.ClearLocalPaint()
    H.stroke=nil;H.localStrokes={};H.localBase=nil;H.localGrid={};H.localSaving=nil;H.paintInvalid=nil
    for _,t in ipairs(H.paintFills or {}) do t:Hide() end
end
local function MarkBrush(stroke,from,to)
    local map,zone,top,bottom,left,right=View()
    if not top then return end
    H.localGrid=H.localGrid or {}
    local radius=stroke.radius
    local dx,dy=to.x-from.x,to.y-from.y;local length=dx*dx+dy*dy
    for row=0,63 do
        local x=top+(row+0.5)/64*(bottom-top)
        if x>=math.min(from.x,to.x)-radius and x<=math.max(from.x,to.x)+radius then
            H.localGrid[row]=H.localGrid[row] or {}
            for col=0,95 do
                local y=left+(col+0.5)/96*(right-left)
                if y>=math.min(from.y,to.y)-radius and y<=math.max(from.y,to.y)+radius then
                    local hit
                    if stroke.kind=="square" then
                        local low,high=0,1
                        for _,v in ipairs({{x-from.x,dx},{y-from.y,dy}}) do
                            if math.abs(v[2])<0.000001 then
                                if math.abs(v[1])>radius then high=-1 end
                            else
                                local a,b=(v[1]-radius)/v[2],(v[1]+radius)/v[2]
                                low=math.max(low,math.min(a,b));high=math.min(high,math.max(a,b))
                            end
                        end
                        hit=low<=high
                    else
                        local t=length>0 and math.max(0,math.min(1,((x-from.x)*dx+(y-from.y)*dy)/length)) or 0
                        hit=(x-from.x-t*dx)^2+(y-from.y-t*dy)^2<=radius^2
                    end
                    if hit then H.localGrid[row][col]=true end
                end
            end
        end
    end
end
local function RenderPaint()
    H.paintFills=H.paintFills or {}
    for _,t in ipairs(H.paintFills) do t:Hide() end
    local count=0;local w,h=WorldMapButton:GetWidth(),WorldMapButton:GetHeight()
    for row=0,63 do
        local cells=H.localGrid and H.localGrid[row] or {};local first
        for col=0,96 do
            local hit=col<96 and cells[col]
            if hit and not first then first=col end
            if first and not hit then
                count=count+1;local t=H.paintFills[count]
                if not t then t=WorldMapButton:CreateTexture(nil,"OVERLAY");H.paintFills[count]=t end
                if H.paintInvalid then t:SetTexture(1,0.1,0.1,0.5) else t:SetTexture(0.3,0.7,1,0.35) end;t:ClearAllPoints()
                t:SetPoint("TOPLEFT",WorldMapButton,"TOPLEFT",first*w/96,-row*h/64)
                t:SetSize((col-first)*w/96,h/64+0.5);t:Show();first=nil
            end
        end
    end
end
function H.RebuildLocalPaint()
    H.localGrid={}
    if H.menuClosed or not H.localBase then RenderPaint();return end
    local map,zone=View()
    if map~=N(H.localBase.map) or zone~=N(H.localBase.zone) or Overview() then RenderPaint();return end
    H.Highlight(H.localBase)
    for _,stroke in ipairs(H.localStrokes or {}) do
        if stroke.mode=="Trace" then
            H.localGrid={};H.Highlight({kind="polygon",map=map,points=stroke.points,highlight=true})
        else
            for i,p in ipairs(stroke.points) do MarkBrush(stroke,stroke.points[i-1] or p,p) end
        end
    end
    RenderPaint()
end
function H.PaintLimit(reason,silent)
    H.paintInvalid=reason
    if H.paintLabel then H.paintLabel:SetText("|cffff3030"..reason.."|r") end
    H.RebuildLocalPaint()
    if not silent then Notify(reason) end
end
function H.UndoLocalPaint()
    if H.localSaving or H.stroke then return end
    if H.localStrokes and #H.localStrokes>0 then table.remove(H.localStrokes);H.paintInvalid=nil;if H.paintLabel then H.paintLabel:SetText("Mode: "..(H.paintMode or "Brush").." | CTRL-drag on a zone map") end;H.RebuildLocalPaint() end
end
function H.SaveLocalPaint(settings)
    if H.localSaving or H.stroke then Notify("Finish drawing or wait for the save result.");return end
    if not H.localStrokes or #H.localStrokes==0 then Send("save "..settings);return end
    if #H.queue>0 then Notify("Wait for pending requests, then Save Draft again.");return end
    local requests={}
    local part=""
    local function Add(op)
        if #part+#op>215 then requests[#requests+1]=part;part="" end
        part=part..op
    end
    for _,stroke in ipairs(H.localStrokes) do
        if stroke.mode=="Trace" then Add("T;") end
        for i,p in ipairs(stroke.points) do
            if stroke.mode=="Trace" then Add(string.format("P %.3f %.3f;",p.x,p.y))
            else
                local from=stroke.points[i-1] or p
                Add(string.format("B %.3f %.3f %.3f %.3f %.2f %d;",from.x,from.y,p.x,p.y,stroke.radius,stroke.kind=="square" and 1 or 0))
            end
        end
    end
    if #part>0 then requests[#requests+1]=part end
    local count=#requests
    for i,text in ipairs(requests) do requests[i]="localpart "..(i-1).." "..text end
    table.insert(requests,1,"localbegin "..N(H.localBase.id).." "..N(H.localBase.revision).." "..count)
    requests[#requests+1]="localsave "..settings
    if #requests>128 then H.PaintLimit("Drawing exceeds upload capacity. Undo a stroke and retry.");return end
    for _,text in ipairs(requests) do if #text>240 then Notify("Save request too long. Shorten the name.");return end end
    for _,text in ipairs(requests) do Send(text) end
    H.localSaving=true;H.localSaveAt=GetTime()
end
function H.EndPaint()
    local stroke=H.stroke
    if not stroke then return end
    H.stroke=nil
    if stroke.mode=="Trace" and #stroke.points<3 or #stroke.points==0 then
        if H.localStrokes[#H.localStrokes]==stroke then table.remove(H.localStrokes) end
        Notify("Trace at least three boundary points.")
    end
    H.RebuildLocalPaint()
end
function H.SamplePaint()
    local x,y=PaintPosition();PaintCursor(x,y)
    local stroke=H.stroke
    if not stroke then return end
    if not x or not IsControlKeyDown() then H.EndPaint();return end
    local last=stroke.points[#stroke.points]
    local distance=last and math.sqrt((x-last.x)^2+(y-last.y)^2) or 999999
    if distance<(stroke.mode=="Brush" and stroke.radius/3 or 5) then return end
    if LocalCount()>=192 then
        H.EndPaint();H.PaintLimit("192 drawing samples reached. Last addition blocked; Save or Undo before continuing.");return
    end
    if math.abs(x)>19000 or math.abs(y)>19000 or distance>5000 and last then
        H.EndPaint();H.PaintLimit("Map coordinate or 5000-yard stroke limit reached. Last addition blocked.");return
    end
    if H.paintInvalid and H.paintLabel then H.paintLabel:SetText("Mode: "..(H.paintMode or "Brush").." | CTRL-drag on a zone map") end
    H.paintInvalid=nil
    local point={x=x,y=y};stroke.points[#stroke.points+1]=point
    if stroke.mode=="Brush" then MarkBrush(stroke,last or point,point);RenderPaint()
    else H.Highlight({kind="polygon",map=draft.map,points=stroke.points,highlight=true}) end
end
function H.UpdateDesignAccess()
    if not panel then return end
    for _,key in ipairs({"Name","Radius yards"}) do
        if fields[key] then fields[key]:EnableMouse(H.canDesign==true);fields[key]:EnableKeyboard(H.canDesign==true) end
    end
    for _,button in ipairs(H.designButtons or {}) do
        if H.canDesign then button:Enable() else button:Disable() end
    end
    if H.deleteButton then
        if H.canDelete then H.deleteButton:Enable() else H.deleteButton:Disable() end
    end
    if not H.canDesign then
        H.stroke=nil;H.paintMode="Points"
        if H.paintPanel then H.paintPanel:Hide() end
    end
end
local function Receive(text)
    if text=="LOCALSAVED" then H.ClearLocalPaint();return end
    if text=="PAINTREADY" then H.paintPending=nil;return end
    local access=text:match("^ACCESS|(%d+)$")
    if access then H.canDesign=N(access)>=2;H.canDelete=N(access)>=3;H.UpdateDesignAccess();return end
    if text:sub(1,13)=="DRAFTCLEARED|" then
        if selected and B(selected.draft) then selected=nil end
        draft=nil;H.merge={};H.newKind=nil;H.newCenter=nil;H.vertex=nil
        Notify(text:sub(14));H.Draw();return
    end
    local deleted=text:match("^DELETED|(%d+)$")
    if deleted then
        deleted=N(deleted);H.rows[deleted]=nil;H.merge[deleted]=nil
        if selected and N(selected.id)==deleted then selected=nil end
        if draft and N(draft.id)==deleted then draft=nil end
        if hovered and N(hovered.id)==deleted then hovered=nil;WorldMapTooltip:Hide() end
        H.Draw();if panel and panel:IsShown() then H.ShowPanel() end
        H.Refresh();return
    end
    if text:sub(1,2)=="G|" then
        local values={}
        for value in text:gmatch("|(%d+)") do values[#values+1]=tonumber(value) end
        if #values==14 then
            H.general=values
            PopulateGeneral()
        end
        return
    end
    if text:sub(1,6)=="BRAND|" then return end
    if text=="OFF" then
        enabled=false;gm=false;H.canDesign=false;H.canDelete=false;H.UpdateDesignAccess();H.rows={};H.queue={};H.refreshPending=false;H.refreshAgain=false
        selected=nil;draft=nil;hovered=nil;snapshot=nil;incoming=nil;chunks=nil
        if H.feedback then H.feedback:Hide() end
        if panel then panel:Hide() end
        if browser then browser:Hide() end
        if generalPanel then generalPanel:Hide() end
        H.general=nil;generalRevision=nil;H.generalSaving=nil;generalDirty=false
        WorldMapTooltip:Hide()
        H.Draw();return
    end
    if text:match("^CHANGED|") then enabled=true;H.Refresh();return end
    local g,isGM,a,now,page,pages=text:match("^B|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)$")
    if g then
        enabled=true;gm=isGM=="1"
        if not gm and generalPanel then generalPanel:Hide() end
        announcements=a=="1";clockOffset=N(now)-time()
        if fields.announce then fields.announce:SetText(announcements and "Announce: ON" or "Announce: OFF") end
        snapshot={generation=N(g),page=N(page),pages=N(pages)};incoming={};return
    end
    local index,total,data=text:match("^R|(%d+)|(%d+)|(.*)$")
    if index then
        index,total=N(index),N(total)
        if total>256 or total<1 then return end
        if index==0 then chunks={};chunkNext=0;chunkCount=total end
        if not chunks or index~=chunkNext or total~=chunkCount then chunks=nil;return end
        chunks[#chunks+1]=data;chunkNext=chunkNext+1
        if chunkNext==chunkCount then
            local ok,r=pcall(C_Serialize.FromJSON,C_Serialize,table.concat(chunks));chunks=nil
            if ok and type(r)=="table" then
                if B(r.outline) then
                    if draft and N(draft.zone)==N(r.zone) then
                        draft.mask=r.mask;draft.bounds=r.bounds;draft.outlineUnavailable=r.outlineUnavailable
                    end
                    H.Draw()
                elseif B(r.draft) then
                    if H.awaitingNewDraft then
                        local c=H.expectedDraft
                        if not c or N(r.id)~=0 or N(r.map)~=c.map or N(r.zone)~=c.zone or
                            math.abs(N(r.x)-c.x)>0.1 or math.abs(N(r.y)-c.y)>0.1 then return end
                        H.awaitingNewDraft=nil;H.expectedDraft=nil;H.draftRequestedAt=nil
                        if c.kind=="polygon" then Send("point "..c.x.." "..c.y)
                        elseif c.kind=="circle" then Send("radius "..c.radius) end
                    end
                    if H.localStrokes and #H.localStrokes>0 then return end
                    draft=r;selected=r
                    if r.kind=="union" and N(r.id)>0 then H.merge={} end
                    if not H.menuClosed then H.ShowPanel() end;H.Draw()
                elseif incoming then incoming[N(r.id)]=r end
            end
        end
        return
    end
    if text=="E" and snapshot then
        H.rows=incoming
        if selected and not B(selected.draft) then selected=H.rows[N(selected.id)] end
        if hovered and H.rows[N(hovered.id)] then hovered=H.rows[N(hovered.id)] end
        local s=snapshot;snapshot=nil;incoming=nil
        H.page,H.pages=s.page,s.pages
        H.Draw()
        H.refreshPending=false
        if H.refreshAgain then
            local nextPage=H.nextPage;H.nextPage=nil;H.refreshAgain=false;H.Refresh(nextPage)
        end
        return
    end
    if text:match("^ERROR|") then H.generalSaving=nil end
    if text:match("^OK|General settings saved") then
        H.generalSaving=nil;generalDirty=false
        if generalFields then generalFields.apply:SetChecked(false) end
        PopulateGeneral()
    end
    if text:match("^ERROR|") then
        local painting=H.localSaving
        H.draftRequestedAt=nil;H.stroke=nil;H.paintPending=nil;H.localSaving=nil
        if painting then H.PaintLimit(text:sub(7),true) end
    end
    if text:match("^ERROR|") or text:match("^OK|") then Notify(text:sub(text:find("|",1,true)+1)) end
end
frame:RegisterEvent("PLAYER_LOGIN");frame:RegisterEvent("CHAT_MSG_ADDON");frame:RegisterEvent("WORLD_MAP_UPDATE")
frame:SetScript("OnEvent",function(_,event,prefix,text,channel,sender)
    if event=="CHAT_MSG_ADDON" then
        if prefix=="XPHOT" and channel=="WHISPER" and sender==UnitName("player") then Receive(text) end
    elseif event=="PLAYER_LOGIN" then
        Send("sync")
        WorldMapFrame:HookScript("OnShow",function() H.Refresh();if panel and panel:IsShown() then H.ShowFeedback() end end)
        local filters=WorldMapButton.Filters
        if filters and filters.DropDown and not H.filterInstalled then
            local dropdown=filters.DropDown
            local initialize=dropdown.initialize
            if type(initialize)=="function" then
                UIDropDownMenu_Initialize(dropdown,function(self,level,menuList)
                    initialize(self,level,menuList)
                    if enabled and gm and filters:IsVisible() and (not level or level==1) then
                        local info=UIDropDownMenu_CreateInfo()
                        info.text="XP Hotspot Menu";info.notCheckable=true
                        info.func=function() if enabled and gm then H.ShowPanel() end end
                        UIDropDownMenu_AddButton(info,level)
                    end
                end,"MENU")
                H.filterInstalled=true
            end
        end
        WorldMapFrame:HookScript("OnHide",function()
            H.CloseWindows();PaintCursor()
        end)
        local priorClick=WorldMapButton:GetScript("OnClick")
        WorldMapButton:SetScript("OnClick",function(self,button,...)
            if gm and H.canDesign and IsControlKeyDown() then return end
            if priorClick then priorClick(self,button,...) end
        end)
        local priorMouseDown=WorldMapButton:GetScript("OnMouseDown")
        WorldMapButton:SetScript("OnMouseDown",function(self,button,...)
            if gm and IsControlKeyDown() and button=="LeftButton" and
                (H.paintMode=="Brush" or H.paintMode=="Trace") then
                local x=PaintPosition()
                if not x then Notify("Select the hotspot, click Edit selected, then Polygon before painting. Open that hotspot's zone map.");H.paintConsumed=true;return end
                if #H.queue>0 or H.paintPending or H.localSaving then Notify("Wait for pending hotspot requests.");H.paintConsumed=true;return end
                H.paintConsumed=true
                H.stroke={mode=H.paintMode,points={},radius=H.brushRadius or 75,kind=H.brushKind or "round"}
                H.localStrokes=H.localStrokes or {};if #H.localStrokes==0 then H.localBase=draft end
                H.localStrokes[#H.localStrokes+1]=H.stroke
                H.SamplePaint();return
            end
            if gm and H.canDesign and IsControlKeyDown() then return end
            if priorMouseDown then priorMouseDown(self,button,...) end
        end)
        local priorMouseUp=WorldMapButton:GetScript("OnMouseUp")
        WorldMapButton:SetScript("OnMouseUp",function(self,button,...)
            if H.paintConsumed then H.SamplePaint();H.EndPaint();H.paintConsumed=nil;return end
            if H.localSaving or H.localStrokes and #H.localStrokes>0 and IsControlKeyDown() then
                Notify("Save or cancel the local drawing before point editing.");return
            end
            if H.draftRequestedAt and IsControlKeyDown() then
                Notify("Waiting for the server to create the draft before editing.");return
            end
            if gm and H.canDesign and not draft and IsControlKeyDown() and button=="LeftButton" then
                local map,zone=View();local x,y=AtCursor()
                if not x or not zone or zone==0 or Overview() then Notify("Open a zone map first.");return end
                if selected then H.NewDraft() else H.ShowPanel() end
                H.newCenter={map=map,zone=zone,x=x,y=y};H.vertex=nil
                H.StartShape(H.newKind or "circle")
                return
            end
            if gm and H.canDesign and draft and draft.kind=="polygon" and IsAltKeyDown() and button=="LeftButton" then
                local map=View();local x,y=AtCursor();local best
                if map~=N(draft.map) or not x then return end
                for i,p in ipairs(type(draft.points)=="table" and draft.points or {}) do
                    local distance=(x-N(p.x))^2+(y-N(p.y))^2
                    if not best or distance<best then H.vertex=i;best=distance end
                end
                if best then Notify("Vertex "..H.vertex.." selected. CTRL-click its new position.") end
                return
            end
            if gm and H.canDesign and draft and IsControlKeyDown() and button=="RightButton" and draft.kind=="polygon" then
                H.vertex=nil;Send("undo");return
            end
            if gm and H.canDesign and draft and IsControlKeyDown() and button=="LeftButton" then
                local map=View()
                if map~=N(draft.map) then
                    Notify("Open the map where this draft belongs.");return
                end
                local x,y=AtCursor()
                if x then
                    local command=H.vertex and "vertex "..H.vertex.." " or draft.kind=="polygon" and "point " or "center "
                    Send(command..x.." "..y);H.vertex=nil
                end
                return
            end
            if priorMouseUp then priorMouseUp(self,button,...) end
        end)
    elseif enabled then H.EndPaint();H.Refresh();H.RebuildLocalPaint() end
end)
local elapsed,paintElapsed=0,0
frame:SetScript("OnUpdate",function(_,diff)
    paintElapsed=paintElapsed+diff
    if paintElapsed>=0.06 then
        paintElapsed=0;H.SamplePaint()
        if H.stroke and IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then H.EndPaint() end
    end
    if H.localSaving and GetTime()-(H.localSaveAt or GetTime())>60 and #H.queue==0 then
        H.localSaving=nil;Notify("Save response timed out. Local drawing retained; refresh the hotspot before retrying.")
    end
    elapsed=elapsed+diff
    if elapsed<0.3 then return end
    elapsed=0
    if H.draftRequestedAt and GetTime()-H.draftRequestedAt>15 and #H.queue==0 then
        H.draftRequestedAt=nil
        Notify("No draft response from server. Reopen a zone map and retry; report the map and zone shown above if it repeats.")
    end
    if H.searchAt and GetTime()>=H.searchAt then
        H.searchAt=nil;H.search=H.searchBox:GetText();H.Refresh(1)
    end
    if hovered and H.hoverOwner and H.tooltipSecond~=Now() then
        H.tooltipSecond=Now();Tooltip(hovered,H.hoverOwner)
    end
    if H.refreshPending and GetTime()-(H.refreshStarted or GetTime())>15 then
        H.refreshPending=false;H.refreshAgain=false;H.Refresh()
    end
    if #H.queue>0 then SendAddonMessage("XPHOT",table.remove(H.queue,1),"WHISPER",UnitName("player")) end
end)
