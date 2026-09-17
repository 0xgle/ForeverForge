local _, FMH = ...
local L=FMH.L

local CLASS_ORDER={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","MAGE","WARLOCK","DRUID","SHAMAN"}
local CLASS_LABEL={WARRIOR="Warrior",PALADIN="Paladin",HUNTER="Hunter",ROGUE="Rogue",PRIEST="Priest",MAGE="Mage",WARLOCK="Warlock",DRUID="Druid",SHAMAN="Shaman",GENERAL="General",ALL="All classes"}
local CATEGORY_ORDER={"ALL","OFFENSE","DEFENSE","HEALING","CC","UTILITY","PET","TARGETING"}
local CATEGORY_LABEL={ALL="All roles",OFFENSE="Offense",DEFENSE="Defense",HEALING="Healing",CC="CC",UTILITY="Utility",PET="Pet",TARGETING="Targeting"}
local MODE_LABEL={ALL="All",PVE="PvE",PVP="PvP"}
local SORTS={"TITLE","CATEGORY","MODE"}
local SORT_LABEL={TITLE="A–Z",CATEGORY="Role",MODE="PvE/PvP"}

local function NewFrame(t,n,p)
    return CreateFrame(t or "Frame",n,p,BackdropTemplateMixin and "BackdropTemplate" or nil)
end
local function Button(parent,w,h,label)
    local b=NewFrame("Button",nil,parent); b:SetSize(w,h); FMH.Media:SetButton(b,false)
    local tx=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); tx:SetPoint("CENTER"); tx:SetText(label or ""); b.text=tx
    b:SetScript("OnEnter",function(self) if not self.active then FMH.Media:SetButton(self,true) end end)
    b:SetScript("OnLeave",function(self) FMH.Media:SetButton(self,self.active,self.danger) end)
    return b
end
local function Label(parent,text,font)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal"); t:SetText(text or ""); return t
end
local function SetActive(b,v,danger) b.active=v and true or false; b.danger=danger and true or false; FMH.Media:SetButton(b,b.active,b.danger) end
local function modeColor(mode)
    if mode=="PVE" then return 0.28,0.9,0.52 end
    if mode=="PVP" then return 1.0,0.42,0.35 end
    return 0.35,0.78,1.0
end

function FMH:GetFilteredMacros()
    local out={}; local q=self:Normalize(self.searchText or "")
    for i=1,#self.Macros do
        local m=self.Macros[i]
        local classOk
        if self.selectedClass=="ALL" then classOk=true
        elseif self.selectedClass=="GENERAL" then classOk=m.class=="GENERAL"
        else classOk=m.class==self.selectedClass or (self.settings.showGeneral and m.class=="GENERAL") end
        local modeOk=self.Engine:MatchesMode(m,self.selectedMode or "ALL")
        local catOk=(self.selectedCategory=="ALL" or m.category==self.selectedCategory)
        local favOk=(not self.onlyFavorites or self:IsFavorite(m.id))
        local searchOk=true
        if q~="" then
            local hay=self:Normalize(m.title.." "..m.description.." "..m.body.." "..m.class.." "..m.category.." "..table.concat(m.tags or {}," "))
            searchOk=hay:find(q,1,true)~=nil
        end
        if classOk and modeOk and catOk and favOk and searchOk then out[#out+1]=m end
    end
    local sort=self.sortMode or "TITLE"
    table.sort(out,function(a,b)
        if sort=="CATEGORY" and a.category~=b.category then return a.category<b.category end
        if sort=="MODE" and a.mode~=b.mode then return a.mode<b.mode end
        if a.class~=b.class and self.selectedClass=="ALL" then return a.class<b.class end
        return a.title<b.title
    end)
    return out
end

function FMH:BuildMainFrame()
    if self.frame then return self.frame end
    self.selectedClass=self.selectedClass or self:PlayerClass()
    self.selectedMode=self.settings.mode or "ALL"
    self.selectedCategory=self.settings.category or "ALL"
    self.sortMode="TITLE"; self.onlyFavorites=false; self.searchText=self.settings.search or ""

    local f=NewFrame("Frame","ForeverMacroHelperFrame",UIParent)
    f:SetSize(1080,690); f:SetPoint("CENTER"); f:SetFrameStrata("HIGH"); f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    FMH.Media:SetBackdrop(f,0.985); table.insert(UISpecialFrames,"ForeverMacroHelperFrame"); self.frame=f
    f:SetScale(self.settings.scale or 1)
    if self.db.windowPoint then local p=self.db.windowPoint; f:ClearAllPoints(); f:SetPoint(p.point or "CENTER",UIParent,p.relPoint or "CENTER",p.x or 0,p.y or 0) end
    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing(); local p,_,rp,x,y=self:GetPoint(1); FMH.db.windowPoint={point=p,relPoint=rp,x=x,y=y}
    end)

    local ico=f:CreateTexture(nil,"ARTWORK"); ico:SetSize(48,48); ico:SetPoint("TOPLEFT",16,-12); ico:SetTexture("Interface\\Icons\\INV_Misc_Note_02")
    local title=Label(f,"ForeverMacroHelper","GameFontNormalHuge"); title:SetPoint("TOPLEFT",ico,"TOPRIGHT",8,-4); title:SetTextColor(1,0.82,0.35)
    local sub=Label(f,L.SUBTITLE,"GameFontHighlightSmall"); sub:SetPoint("TOPLEFT",title,"BOTTOMLEFT",1,-4); sub:SetTextColor(0.45,0.78,0.9)
    local by=Label(f,L.BY,"GameFontDisableSmall"); by:SetPoint("LEFT",title,"RIGHT",9,-1)

    local close=Button(f,34,34,""); close:SetPoint("TOPRIGHT",-12,-12); local ctex=close:CreateTexture(nil,"ARTWORK"); ctex:SetAllPoints(); ctex:SetTexture(FMH.Media:Icon("close")); close:SetScript("OnClick",function() f:Hide() end)
    local set=Button(f,34,34,""); set:SetPoint("RIGHT",close,"LEFT",-8,0); local stex=set:CreateTexture(nil,"ARTWORK"); stex:SetAllPoints(); stex:SetTexture(FMH.Media:Icon("settings")); set:SetScript("OnClick",function() FMH:ToggleSettings() end)

    local search=NewFrame("EditBox",nil,f); search:SetSize(300,34); search:SetPoint("RIGHT",set,"LEFT",-12,0); search:SetAutoFocus(false); search:SetFontObject(ChatFontNormal); search:SetTextInsets(35,8,0,0); search:SetText(self.searchText)
    FMH.Media:SetPanel(search,0.92); local si=search:CreateTexture(nil,"ARTWORK"); si:SetSize(26,26); si:SetPoint("LEFT",5,0); si:SetTexture(FMH.Media:Icon("search"))
    local ph=Label(search,L.SEARCH,"GameFontDisableSmall"); ph:SetPoint("LEFT",35,0); ph:SetShown(self.searchText==""); search.placeholder=ph
    search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end); search:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    search:SetScript("OnTextChanged",function(self,user) if not user then return end; FMH.searchText=self:GetText() or ""; FMH.settings.search=FMH.searchText; self.placeholder:SetShown(FMH.searchText==""); FMH:RefreshList() end); self.searchBox=search

    -- LEFT: class + role filters
    local left=NewFrame("Frame",nil,f); left:SetPoint("TOPLEFT",14,-76); left:SetPoint("BOTTOMLEFT",14,62); left:SetWidth(202); FMH.Media:SetPanel(left,0.84)
    local lh=Label(left,"CLASS","GameFontNormalSmall"); lh:SetPoint("TOPLEFT",10,-10); lh:SetTextColor(1,0.82,0.35)
    self.classButtons={}
    local all=Button(left,182,30,"All classes"); all:SetPoint("TOPLEFT",10,-30); all.id="ALL"; self.classButtons.ALL=all
    local gen=Button(left,182,30,"General"); gen:SetPoint("TOPLEFT",10,-64); gen.id="GENERAL"; self.classButtons.GENERAL=gen
    for i,cls in ipairs(CLASS_ORDER) do
        local col=(i-1)%2; local row=math.floor((i-1)/2); local b=Button(left,88,30,CLASS_LABEL[cls]); b:SetPoint("TOPLEFT",10+col*94,-98-row*34); b.id=cls; self.classButtons[cls]=b
        local colr=RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]; if colr then b.text:SetTextColor(colr.r,colr.g,colr.b) end
    end
    for _,b in pairs(self.classButtons) do b:SetScript("OnClick",function(btn) FMH.selectedClass=btn.id; FMH:Refresh() end) end

    local cy=-280; local ch=Label(left,"ROLE","GameFontNormalSmall"); ch:SetPoint("TOPLEFT",10,cy); ch:SetTextColor(1,0.82,0.35); cy=cy-20
    self.categoryButtons={}
    for i,cat in ipairs(CATEGORY_ORDER) do local col=(i-1)%2; local row=math.floor((i-1)/2); local b=Button(left,88,28,CATEGORY_LABEL[cat]); b:SetPoint("TOPLEFT",10+col*94,cy-row*32); b.id=cat; self.categoryButtons[cat]=b; b:SetScript("OnClick",function(btn) FMH.selectedCategory=btn.id; FMH.settings.category=btn.id; FMH:Refresh() end) end
    local fav=Button(left,182,30,"★  Favorites only"); fav:SetPoint("BOTTOMLEFT",10,12); fav:SetScript("OnClick",function() FMH.onlyFavorites=not FMH.onlyFavorites; FMH:Refresh() end); self.favoriteFilter=fav

    -- CENTER: mode chips + sort + macro list
    local center=NewFrame("Frame",nil,f); center:SetPoint("TOPLEFT",left,"TOPRIGHT",10,0); center:SetPoint("BOTTOMLEFT",left,"BOTTOMRIGHT",10,0); center:SetWidth(390); FMH.Media:SetPanel(center,0.84)
    self.modeButtons={}; local last=nil
    for _,mode in ipairs({"ALL","PVE","PVP"}) do local b=Button(center,75,30,MODE_LABEL[mode]); if not last then b:SetPoint("TOPLEFT",10,-10) else b:SetPoint("LEFT",last,"RIGHT",6,0) end; b.id=mode; self.modeButtons[mode]=b; last=b; b:SetScript("OnClick",function(btn) FMH.selectedMode=btn.id; FMH.settings.mode=btn.id; FMH:Refresh() end) end
    local sort=Button(center,123,30,"Sort: A–Z"); sort:SetPoint("TOPRIGHT",-10,-10); sort:SetScript("OnClick",function()
        local idx=1; for i,v in ipairs(SORTS) do if v==FMH.sortMode then idx=i break end end; FMH.sortMode=SORTS[(idx%#SORTS)+1]; sort.text:SetText("Sort: "..SORT_LABEL[FMH.sortMode]); FMH:RefreshList()
    end); self.sortButton=sort
    local count=Label(center,"","GameFontDisableSmall"); count:SetPoint("TOPLEFT",10,-47); self.resultCount=count
    local scroll=CreateFrame("ScrollFrame","ForeverMacroHelperListScroll",center,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",8,-65); scroll:SetPoint("BOTTOMRIGHT",-28,8)
    local child=CreateFrame("Frame",nil,scroll); child:SetSize(348,500); scroll:SetScrollChild(child); self.listScroll=scroll; self.listChild=child; self.rows={}

    -- RIGHT: details
    local right=NewFrame("Frame",nil,f); right:SetPoint("TOPLEFT",center,"TOPRIGHT",10,0); right:SetPoint("BOTTOMRIGHT",-14,62); FMH.Media:SetPanel(right,0.84); self.detailPanel=right
    local empty=Label(right,L.CLICK_SELECT,"GameFontDisableLarge"); empty:SetPoint("CENTER",0,50); self.emptyDetail=empty
    local dt=Label(right,"","GameFontNormalLarge"); dt:SetPoint("TOPLEFT",16,-16); dt:SetPoint("RIGHT",-16,0); dt:SetJustifyH("LEFT"); dt:SetTextColor(1,0.82,0.35); self.detailTitle=dt
    local badges=Label(right,"","GameFontNormalSmall"); badges:SetPoint("TOPLEFT",dt,"BOTTOMLEFT",0,-7); self.detailBadges=badges
    local desc=Label(right,"","GameFontHighlightSmall"); desc:SetPoint("TOPLEFT",badges,"BOTTOMLEFT",0,-10); desc:SetPoint("RIGHT",-16,0); desc:SetWidth(390); desc:SetJustifyH("LEFT"); desc:SetJustifyV("TOP"); self.detailDescription=desc
    local macroName=Label(right,"","GameFontDisableSmall"); macroName:SetPoint("TOPLEFT",desc,"BOTTOMLEFT",0,-10); self.detailMacroName=macroName
    local codeLabel=Label(right,"MACRO BODY","GameFontNormalSmall"); codeLabel:SetPoint("TOPLEFT",16,-175); codeLabel:SetTextColor(0.45,0.78,0.9); self.codeLabel=codeLabel
    local codeFrame=NewFrame("Frame",nil,right); codeFrame:SetPoint("TOPLEFT",16,-194); codeFrame:SetPoint("TOPRIGHT",-16,-194); codeFrame:SetHeight(190); FMH.Media:SetPanel(codeFrame,0.98); self.codeFrame=codeFrame
    local codeScroll=CreateFrame("ScrollFrame",nil,codeFrame,"UIPanelScrollFrameTemplate"); codeScroll:SetPoint("TOPLEFT",8,-8); codeScroll:SetPoint("BOTTOMRIGHT",-27,8)
    local editor=CreateFrame("EditBox",nil,codeScroll); editor:SetMultiLine(true); editor:SetAutoFocus(false); editor:SetFontObject(ChatFontNormal); editor:SetWidth(370); editor:SetHeight(170); editor:SetTextInsets(2,2,2,2); codeScroll:SetScrollChild(editor); self.editor=editor
    local chars=Label(right,"0 / 255","GameFontDisableSmall"); chars:SetPoint("TOPRIGHT",-18,-390); self.charCount=chars
    editor:SetScript("OnTextChanged",function(self)
        local n=#(self:GetText() or ""); FMH.charCount:SetText(n.." / 255"); if n>255 then FMH.charCount:SetTextColor(1,0.25,0.2) else FMH.charCount:SetTextColor(0.65,0.65,0.65) end; FMH:RefreshCreateButton()
    end)
    editor:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)

    local favBtn=Button(right,115,32,"☆ Favorite"); favBtn:SetPoint("BOTTOMLEFT",16,58); favBtn:SetScript("OnClick",function() if FMH.selectedMacro then FMH:ToggleFavorite(FMH.selectedMacro.id); FMH:Refresh() end end); self.detailFavorite=favBtn
    local reset=Button(right,105,32,"Reset body"); reset:SetPoint("LEFT",favBtn,"RIGHT",7,0); reset:SetScript("OnClick",function() if FMH.selectedMacro then FMH.editor:SetText(FMH.selectedMacro.body) end end); self.resetBody=reset
    local del=Button(right,95,32,"Delete"); del:SetPoint("LEFT",reset,"RIGHT",7,0); del:SetScript("OnClick",function() if FMH.selectedMacro and FMH.Engine:Delete(FMH.selectedMacro) then FMH:Print("Macro deleted: "..FMH.selectedMacro.macroName); FMH:Refresh() end end); self.deleteButton=del
    local create=Button(right,318,40,L.CREATE); create:SetPoint("BOTTOM",0,10); create:SetScript("OnClick",function()
        if not FMH.selectedMacro then return end; local ok,msg=FMH.Engine:Install(FMH.selectedMacro,FMH.editor:GetText()); if ok then FMH:Print((msg=="updated" and "Updated " or "Created ")..FMH.selectedMacro.macroName) else FMH:Print(msg) end; FMH:Refresh()
    end); self.createButton=create

    -- FOOTER
    local footer=NewFrame("Frame",nil,f); footer:SetPoint("BOTTOMLEFT",14,12); footer:SetPoint("BOTTOMRIGHT",-14,12); footer:SetHeight(40); FMH.Media:SetPanel(footer,0.94)
    local pve=Button(footer,155,30,L.INSTALL_PVE); pve:SetPoint("LEFT",6,0); pve:SetScript("OnClick",function() FMH:InstallPack("PVE") end)
    local pvp=Button(footer,155,30,L.INSTALL_PVP); pvp:SetPoint("LEFT",pve,"RIGHT",6,0); pvp:SetScript("OnClick",function() FMH:InstallPack("PVP") end)
    local rec=Button(footer,180,30,L.INSTALL_RECOMMENDED); rec:SetPoint("LEFT",pvp,"RIGHT",6,0); rec:SetScript("OnClick",function() FMH:InstallPack(FMH.selectedMode or "ALL") end)
    self.packButtons={pve,pvp,rec}
    local stats=Label(footer,"","GameFontNormalSmall"); stats:SetPoint("RIGHT",-10,0); stats:SetJustifyH("RIGHT"); self.stats=stats

    -- Compact settings popover
    local sp=NewFrame("Frame",nil,f); sp:SetSize(330,215); sp:SetPoint("TOPRIGHT",-54,-52); sp:SetFrameLevel(f:GetFrameLevel()+30); FMH.Media:SetBackdrop(sp,0.995); sp:Hide(); self.settingsPanel=sp
    local sht=Label(sp,"FOREVER SETTINGS","GameFontNormal"); sht:SetPoint("TOPLEFT",14,-14); sht:SetTextColor(1,0.82,0.35)
    local mm=Button(sp,300,34,""); mm:SetPoint("TOPLEFT",15,-44); mm:SetScript("OnClick",function() FMH.settings.minimap=not FMH.settings.minimap; FMH.Minimap:Refresh(); FMH:RefreshSettingsPanel() end); self.settingMinimap=mm
    local gp=Button(sp,300,34,""); gp:SetPoint("TOPLEFT",15,-83); gp:SetScript("OnClick",function() FMH.settings.showGeneral=not FMH.settings.showGeneral; FMH:RefreshSettingsPanel(); FMH:Refresh() end); self.settingGeneral=gp
    local minus=Button(sp,92,32,"Scale -"); minus:SetPoint("TOPLEFT",15,-126); minus:SetScript("OnClick",function() FMH.settings.scale=math.max(0.8,(FMH.settings.scale or 1)-0.05); f:SetScale(FMH.settings.scale); FMH:RefreshSettingsPanel() end)
    local plus=Button(sp,92,32,"Scale +"); plus:SetPoint("LEFT",minus,"RIGHT",8,0); plus:SetScript("OnClick",function() FMH.settings.scale=math.min(1.25,(FMH.settings.scale or 1)+0.05); f:SetScale(FMH.settings.scale); FMH:RefreshSettingsPanel() end)
    local rst=Button(sp,100,32,"Reset pos."); rst:SetPoint("LEFT",plus,"RIGHT",8,0); rst:SetScript("OnClick",function() FMH.db.windowPoint=nil; f:ClearAllPoints(); f:SetPoint("CENTER") end)
    local sc=Label(sp,"","GameFontDisableSmall"); sc:SetPoint("BOTTOMLEFT",15,12); self.settingScale=sc

    f:SetScript("OnShow",function() FMH:Refresh() end)
    self:Refresh()
    return f
end

function FMH:RefreshSettingsPanel()
    if not self.settingsPanel then return end
    self.settingMinimap.text:SetText((self.settings.minimap~=false and "✓  " or "□  ").."Minimap button")
    self.settingGeneral.text:SetText((self.settings.showGeneral~=false and "✓  " or "□  ").."Include General with class")
    self.settingScale:SetText(string.format("Scale: %d%%   •   © 2026 0xgle",math.floor((self.settings.scale or 1)*100+0.5)))
end
function FMH:ToggleSettings()
    if not self.frame then self:BuildMainFrame() end
    self:RefreshSettingsPanel(); self.settingsPanel:SetShown(not self.settingsPanel:IsShown())
end

function FMH:RefreshFilterButtons()
    if not self.frame then return end
    for id,b in pairs(self.classButtons) do SetActive(b,id==self.selectedClass) end
    for id,b in pairs(self.modeButtons) do SetActive(b,id==self.selectedMode) end
    for id,b in pairs(self.categoryButtons) do SetActive(b,id==self.selectedCategory) end
    SetActive(self.favoriteFilter,self.onlyFavorites)
end

function FMH:GetRow(i)
    local r=self.rows[i]; if r then return r end
    r=NewFrame("Button",nil,self.listChild); r:SetHeight(44); FMH.Media:SetButton(r,false)
    local star=Label(r,"☆","GameFontNormal"); star:SetPoint("LEFT",8,0); star:SetTextColor(1,0.82,0.35); r.star=star
    local title=Label(r,"","GameFontNormal"); title:SetPoint("TOPLEFT",28,-6); title:SetPoint("RIGHT",-80,0); title:SetJustifyH("LEFT"); r.title=title
    local meta=Label(r,"","GameFontDisableSmall"); meta:SetPoint("BOTTOMLEFT",28,6); meta:SetPoint("RIGHT",-70,0); meta:SetJustifyH("LEFT"); r.meta=meta
    local mode=Label(r,"","GameFontNormalSmall"); mode:SetPoint("RIGHT",-8,0); r.mode=mode
    r:SetScript("OnClick",function(self) if self.macro then FMH:SelectMacro(self.macro) end end)
    r:SetScript("OnEnter",function(self) FMH.Media:SetButton(self,true); if self.macro then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine(self.macro.title,1,0.82,0.35); GameTooltip:AddLine(self.macro.description,0.9,0.9,0.9,true); GameTooltip:Show() end end)
    r:SetScript("OnLeave",function(self) FMH.Media:SetButton(self,FMH.selectedMacro==self.macro); GameTooltip:Hide() end)
    self.rows[i]=r; return r
end

function FMH:RefreshList()
    if not self.frame then return end
    local list=self:GetFilteredMacros(); self.filtered=list; self.resultCount:SetText(#list.." macros")
    for i=1,#self.rows do self.rows[i]:Hide() end
    local y=-2
    for i,m in ipairs(list) do
        local r=self:GetRow(i); r:ClearAllPoints(); r:SetPoint("TOPLEFT",0,y); r:SetPoint("RIGHT",-2,0); r.macro=m
        r.title:SetText(m.title); r.star:SetText(self:IsFavorite(m.id) and "★" or "☆"); r.meta:SetText((CLASS_LABEL[m.class] or m.class).."  •  "..(CATEGORY_LABEL[m.category] or m.category))
        r.mode:SetText(m.mode=="BOTH" and "P+P" or (m.mode=="PVE" and "PvE" or "PvP")); local rr,gg,bb=modeColor(m.mode); r.mode:SetTextColor(rr,gg,bb)
        local installed=self.Engine:IsInstalled(m); if installed then r.title:SetTextColor(0.35,0.92,0.63) else r.title:SetTextColor(0.95,0.95,0.95) end
        SetActive(r,self.selectedMacro==m); r:Show(); y=y-48
    end
    self.listChild:SetHeight(math.max(500,-y+4))
end

function FMH:SelectMacro(m)
    self.selectedMacro=m; self.editor:SetText(m.body or ""); self.editor:SetCursorPosition(0); self:Refresh()
end

function FMH:RefreshCreateButton()
    if not self.createButton then return end
    if not self.selectedMacro then self.createButton:Disable(); self.createButton.text:SetText(L.CREATE); return end
    local installed=self.Engine:IsInstalled(self.selectedMacro); local n=#(self.editor:GetText() or "")
    local blocked=not self:CanModifyMacros() or n>255
    if blocked then self.createButton:Disable(); self.createButton:SetAlpha(0.45); self.createButton.text:SetText(not self:CanModifyMacros() and L.IN_COMBAT or "Macro too long")
    else self.createButton:Enable(); self.createButton:SetAlpha(1); self.createButton.text:SetText(installed and L.UPDATE or L.CREATE) end
end

function FMH:RefreshDetail()
    if not self.frame then return end
    local m=self.selectedMacro; local show=m~=nil
    self.emptyDetail:SetShown(not show)
    for _,w in ipairs({self.detailTitle,self.detailBadges,self.detailDescription,self.detailMacroName,self.codeLabel,self.codeFrame,self.charCount,self.detailFavorite,self.resetBody,self.deleteButton,self.createButton}) do w:SetShown(show) end
    if not m then return end
    self.detailTitle:SetText(m.title)
    local r,g,b=modeColor(m.mode); self.detailBadges:SetText((CLASS_LABEL[m.class] or m.class).."   •   "..(m.mode=="BOTH" and "PvE + PvP" or MODE_LABEL[m.mode]).."   •   "..(CATEGORY_LABEL[m.category] or m.category)); self.detailBadges:SetTextColor(r,g,b)
    self.detailDescription:SetText(m.description); self.detailMacroName:SetText("Macro name: |cffffffff"..m.macroName.."|r")
    self.detailFavorite.text:SetText(self:IsFavorite(m.id) and "★ Favorite" or "☆ Favorite")
    local installed=self.Engine:IsInstalled(m); self.deleteButton:SetShown(installed); self:RefreshCreateButton()
end

function FMH:RefreshFooter()
    if not self.frame then return end
    local g,c=self.Engine:GetCounts(); local cls=CLASS_LABEL[self:PlayerClass()] or self:PlayerClass(); self.stats:SetText(string.format("%s: %d   •   Global: %d   •   %s",L.CHAR_MACROS,c,g,cls))
    local combat=not self:CanModifyMacros(); for _,b in ipairs(self.packButtons) do if combat then b:Disable(); b:SetAlpha(0.45) else b:Enable(); b:SetAlpha(1) end end
end

function FMH:Refresh()
    if not self.frame then return end
    self.frame:SetScale(self.settings.scale or 1); self:RefreshFilterButtons(); self:RefreshList(); self:RefreshDetail(); self:RefreshFooter(); self:RefreshSettingsPanel()
end

function FMH:InstallPack(mode)
    local done,total,err=self.Engine:InstallPack(mode); if err then self:Print(string.format("Installed %d/%d. %s",done,total,err)) else self:Print(string.format("Installed/updated %d recommended %s macros.",done,mode)) end; self:Refresh()
end

function FMH:Toggle()
    local f=self:BuildMainFrame(); f:SetShown(not f:IsShown())
end

FMH:On("LOGIN",function()
    FMH:BuildMainFrame()
    SLASH_FOREVERMACROHELPER1="/fmh"; SLASH_FOREVERMACROHELPER2="/forevermacro"
    SlashCmdList.FOREVERMACROHELPER=function(msg)
        msg=(msg or ""):lower()
        if msg=="pve" then FMH:BuildMainFrame():Show(); FMH.selectedMode="PVE"; FMH:Refresh()
        elseif msg=="pvp" then FMH:BuildMainFrame():Show(); FMH.selectedMode="PVP"; FMH:Refresh()
        elseif msg=="settings" then FMH:BuildMainFrame():Show(); FMH:ToggleSettings()
        elseif msg=="reset" then FMH.db.windowPoint=nil; if FMH.frame then FMH.frame:ClearAllPoints(); FMH.frame:SetPoint("CENTER") end
        else FMH:Toggle() end
    end
end)
FMH:On("FILTER_CHANGED",function() FMH:Refresh() end)
FMH:On("MACROS_CHANGED",function() FMH:Refresh() end)
FMH:On("COMBAT_CHANGED",function() FMH:Refresh() end)
