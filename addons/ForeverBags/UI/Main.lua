local _, FB = ...
local L = FB.L

local CATEGORY_META = {
    {id="all", label=function() return L.ALL_ITEMS end, icon="allitems"},
    {id="favorites", label=function() return L.FAVORITES end, icon="favorite"},
    {id="recent", label=function() return L.RECENT end, icon="new"},
    {id="equipment", label=function() return L.EQUIPMENT end, icon="equipment"},
    {id="consumables", label=function() return L.CONSUMABLES end, icon="potion"},
    {id="materials", label=function() return L.MATERIALS end, icon="herbs"},
    {id="quest", label=function() return L.QUEST end, icon="quest"},
    {id="misc", label=function() return L.MISC end, icon="favorite"},
    {id="junk", label=function() return L.JUNK end, icon="junk"},
}

local SECTION_LABELS = {
    equipment=function() return L.EQUIPMENT end,
    consumables=function() return L.CONSUMABLES end,
    materials=function() return L.MATERIALS end,
    quest=function() return L.QUEST end,
    misc=function() return L.MISC end,
    junk=function() return L.JUNK end,
}

local function NewFrame(frameType, name, parent)
    return CreateFrame(frameType or "Frame", name, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
end

local function MakeButton(parent, w, h)
    local b = NewFrame("Button", nil, parent)
    b:SetSize(w, h)
    FB.Media:SetButtonBackdrop(b, false)
    return b
end

local function AddText(button, text, font)
    local fs = button:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    fs:SetPoint("CENTER"); fs:SetText(text or "")
    button.text = fs
    return fs
end

function FB:BuildMainFrame()
    if self.frame then return self.frame end
    local f = NewFrame("Frame", "ForeverBagsFrame", UIParent)
    f:SetSize(890, 640)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    FB.Media:SetBackdrop(f, 0.985)
    FB.Media:ApplyWindowArt(f)
    table.insert(UISpecialFrames, "ForeverBagsFrame")
    self.frame = f
    self.currentView = self.currentView or "bags"
    self.currentCategory = self.currentCategory or "all"
    self.searchText = self.searchText or ""
    self.itemButtons, self.headerPool, self.emptySlots = {}, {}, {}

    if self.settings.windowPoint then
        local p = self.settings.windowPoint
        f:ClearAllPoints(); f:SetPoint(p.point or "CENTER", UIParent, p.relPoint or "CENTER", p.x or 0, p.y or 0)
    end
    f:SetScale(self.settings.scale or 1)
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint(1)
        FB.settings.windowPoint = {point=point, relPoint=relPoint, x=x, y=y}
    end)

    local titleIcon = f:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(54,54); titleIcon:SetPoint("TOPLEFT", 14, -10); titleIcon:SetTexture(FB.Media:Icon("bag"))
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", titleIcon, "TOPRIGHT", 4, -6); title:SetText("ForeverBags"); title:SetTextColor(0.96,0.85,0.62)
    title:SetShadowColor(0,0,0,1); title:SetShadowOffset(1,-1)
    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 2, -3); sub:SetText("inventory • bank • alts • discoveries"); sub:SetTextColor(0.57,0.67,0.68)
    local credit = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    credit:SetPoint("LEFT", title, "RIGHT", 8, -1); credit:SetText("by 0xgle")
    credit:SetWidth(58); credit:SetWordWrap(false); credit:SetJustifyH("LEFT")
    credit:SetTextColor(0.58,0.58,0.58)

    local close = MakeButton(f, 34, 34); close:SetPoint("TOPRIGHT", -12, -12)
    local ct = close:CreateTexture(nil, "ARTWORK"); ct:SetSize(24,24); ct:SetPoint("CENTER"); ct:SetTexture(FB.Media:Icon("close"))
    close:SetScript("OnClick", function() f:Hide() end)

    local settings = MakeButton(f, 34, 34); settings:SetPoint("RIGHT", close, "LEFT", -8, 0)
    local st = settings:CreateTexture(nil, "ARTWORK"); st:SetSize(26,26); st:SetPoint("CENTER"); st:SetTexture(FB.Media:Icon("settings"))
    settings:SetScript("OnClick", function() FB.SettingsUI:Toggle() end)

    local sort = MakeButton(f, 126, 34); sort:SetPoint("RIGHT", settings, "LEFT", -10, 0)
    local sortIcon = sort:CreateTexture(nil, "ARTWORK"); sortIcon:SetSize(24,24); sortIcon:SetPoint("LEFT", 5,0); sortIcon:SetTexture(FB.Media:Icon("sort_up"))
    sort.text = sort:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); sort.text:SetPoint("LEFT", sortIcon, "RIGHT", 3,0); sort.text:SetPoint("RIGHT", -5,0); sort.text:SetJustifyH("LEFT")
    sort:SetScript("OnClick", function() FB.Data:CycleSort() end)
    self.sortButton = sort

    local search = NewFrame("EditBox", nil, f)
    search:SetSize(285, 34); search:SetPoint("RIGHT", sort, "LEFT", -10, 0)
    search:SetAutoFocus(false); search:SetFontObject("GameFontHighlight"); search:SetTextInsets(34,10,0,0)
    search:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    search:SetBackdropColor(0.02,0.03,0.04,0.98); search:SetBackdropBorderColor(0.32,0.42,0.46,1)
    local si = search:CreateTexture(nil,"ARTWORK"); si:SetSize(25,25); si:SetPoint("LEFT",5,0); si:SetTexture(FB.Media:Icon("search"))
    search.placeholder = search:CreateFontString(nil,"OVERLAY","GameFontDisable"); search.placeholder:SetPoint("LEFT",34,0); search.placeholder:SetText(L.SEARCH)
    search:SetScript("OnTextChanged", function(self)
        FB.searchText = self:GetText() or ""
        self.placeholder:SetShown(FB.searchText == "" and not self:HasFocus())
        FB:Debounce("search", 0.04, function() FB:Refresh() end)
    end)
    search:SetScript("OnEditFocusGained", function(self) self.placeholder:Hide(); self:SetBackdropBorderColor(0.65,0.57,0.37,1) end)
    search:SetScript("OnEditFocusLost", function(self) self.placeholder:SetShown((self:GetText() or "") == ""); self:SetBackdropBorderColor(0.32,0.42,0.46,1) end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    self.searchBox = search

    local sidebar = NewFrame("Frame", nil, f)
    sidebar:SetPoint("TOPLEFT", 14, -78); sidebar:SetPoint("BOTTOMLEFT", 14, 62); sidebar:SetWidth(172)
    FB.Media:SetBackdrop(sidebar, 0.72)
    self.sidebar = sidebar
    self.categoryButtons = {}
    local y = -10
    for i = 1, #CATEGORY_META do
        local meta = CATEGORY_META[i]
        local b = MakeButton(sidebar, 152, 42); b:SetPoint("TOPLEFT", 10, y); y = y - 46
        local icon = b:CreateTexture(nil,"ARTWORK"); icon:SetSize(30,30); icon:SetPoint("LEFT",5,0); icon:SetTexture(FB.Media:Icon(meta.icon))
        local txt = b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); txt:SetPoint("LEFT",icon,"RIGHT",5,0); txt:SetPoint("RIGHT",-29,0); txt:SetJustifyH("LEFT"); txt:SetText(meta.label())
        txt:SetWordWrap(true); txt:SetHeight(32); b.text=txt
        b.count=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        b.count:SetPoint("RIGHT",-6,0); b.count:SetWidth(24); b.count:SetJustifyH("RIGHT"); b.count:SetTextColor(0.55,0.65,0.65)
        b.id=meta.id
        b:SetScript("OnClick", function(self) FB.currentCategory=self.id; FB:Refresh() end)
        self.categoryButtons[meta.id]=b
    end

    local wallet = NewFrame("Frame", nil, sidebar)
    wallet:SetPoint("BOTTOMLEFT", 10, 10); wallet:SetPoint("BOTTOMRIGHT", -10, 10); wallet:SetHeight(48)
    FB.Media:SetBackdrop(wallet, 0.85)
    local walletLabel = wallet:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    walletLabel:SetPoint("TOPLEFT",8,-7); walletLabel:SetText(L.YOUR_MONEY or "Your money")
    walletLabel:SetTextColor(0.68,0.72,0.70)
    self.walletValue = wallet:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    self.walletValue:SetPoint("BOTTOMLEFT",8,8); self.walletValue:SetPoint("BOTTOMRIGHT",-6,8)
    self.walletValue:SetJustifyH("LEFT"); self.walletValue:SetWordWrap(false)
    self:RefreshMoney()

    local scroll = CreateFrame("ScrollFrame", "ForeverBagsScrollFrame", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 12, 0)
    scroll:SetPoint("BOTTOMRIGHT", -34, 64)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(650, 500)
    scroll:SetScrollChild(child)
    self.scroll = scroll; self.scrollChild = child

    local footer = NewFrame("Frame", nil, f)
    footer:SetPoint("BOTTOMLEFT", 14, 12); footer:SetPoint("BOTTOMRIGHT", -14, 12); footer:SetHeight(40)
    FB.Media:SetBackdrop(footer, 0.9)
    self.footer = footer

    self.viewButtons = {}
    local viewMeta = {{"bags",L.BAGS,"bag"},{"bank",L.BANK,"bank"},{"alts",L.ALTS,"alts"},{"discoveries",L.DISCOVERIES,"discovery"}}
    local last
    for i=1,#viewMeta do
        local id,label,iconName = unpack(viewMeta[i])
        local b=MakeButton(footer, 108, 30)
        if not last then b:SetPoint("LEFT",6,0) else b:SetPoint("LEFT",last,"RIGHT",5,0) end
        local ic=b:CreateTexture(nil,"ARTWORK"); ic:SetSize(24,24); ic:SetPoint("LEFT",4,0); ic:SetTexture(FB.Media:Icon(iconName))
        local tx=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); tx:SetPoint("LEFT",ic,"RIGHT",2,0); tx:SetPoint("RIGHT",-3,0); tx:SetText(label); b.text=tx
        b.id=id; b:SetScript("OnClick", function(self) FB.currentView=self.id; FB.currentCategory="all"; FB:Refresh() end)
        self.viewButtons[id]=b; last=b
    end

    local stats = footer:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    stats:SetWidth(270); stats:SetHeight(32); stats:SetPoint("RIGHT", footer, "RIGHT", -10, 0); stats:SetJustifyH("RIGHT"); stats:SetTextColor(0.72,0.77,0.77)
    self.stats = stats

    -- Merchant action belongs inside the footer so it never covers category bars/items.
    local sell = MakeButton(footer, 105, 30); sell:SetPoint("RIGHT", footer, "RIGHT", -6, 0); AddText(sell, L.SELL_JUNK, "GameFontNormalSmall")
    sell:SetScript("OnClick", function() FB.Merchant:SellJunk(IsShiftKeyDown()) end)
    self.sellButton = sell

    self.noItems = child:CreateFontString(nil,"OVERLAY","GameFontDisableLarge")
    self.noItems:SetPoint("TOP", 0, -80); self.noItems:SetWidth(560); self.noItems:SetJustifyH("CENTER"); self.noItems:SetText(L.NO_ITEMS); self.noItems:Hide()

    f:SetScript("OnShow", function() FB:Refresh() end)
    return f
end

function FB:GetCategoryLabel(id)
    if id == "favorites" then return L.FAVORITES end
    if id == "recent" then return L.RECENT end
    local fn = SECTION_LABELS[id]
    return fn and fn() or id
end

function FB:CategoryMatch(item, category)
    if category == "all" then return true end
    if category == "favorites" then return item.favorite end
    if category == "recent" then return item.isNew or (item.firstSeen and (self:Now()-item.firstSeen <= (self.settings.recentSeconds or 600))) end
    return item.category == category
end

function FB:GetPooledItemButton(index)
    local b=self.itemButtons[index]
    if not b then b=FB.ItemButton:Create(self.scrollChild); self.itemButtons[index]=b end
    return b
end

function FB:GetPooledHeader(index)
    local h=self.headerPool[index]
    if not h then
        h=CreateFrame("Frame",nil,self.scrollChild,BackdropTemplateMixin and "BackdropTemplate" or nil)
        h:SetHeight(24); h:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); h:SetBackdropColor(0.07,0.105,0.115,0.85)
        h.text=h:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); h.text:SetPoint("LEFT",10,0); h.text:SetPoint("RIGHT",-45,0); h.text:SetJustifyH("LEFT"); h.text:SetTextColor(0.85,0.78,0.61)
        h.count=h:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); h.count:SetPoint("RIGHT",-10,0); h.count:SetTextColor(0.55,0.66,0.67)
        local line=h:CreateTexture(nil,"ARTWORK"); line:SetColorTexture(0.46,0.40,0.27,0.38); line:SetHeight(1); line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT")
        self.headerPool[index]=h
    end
    return h
end

function FB:GetEmptySlot(index)
    local e=self.emptySlots[index]
    if not e then
        e=CreateFrame("Frame",nil,self.scrollChild,BackdropTemplateMixin and "BackdropTemplate" or nil)
        e:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        e:SetBackdropColor(0.025,0.035,0.045,0.75); e:SetBackdropBorderColor(0.17,0.22,0.24,0.9)
        local tx=e:CreateTexture(nil,"ARTWORK"); tx:SetAllPoints(); tx:SetTexture(FB.Media:Texture("slot_frame")); tx:SetAlpha(0.12)
        self.emptySlots[index]=e
    end
    return e
end

function FB:RefreshMoney()
    if not self.walletValue then return end
    local copper = math.max(0, math.floor(tonumber(GetMoney and GetMoney()) or (self.char and self.char.money) or 0))
    self.walletValue:SetText(string.format("|cffffd36a%dg|r  |cffd5dce5%02ds|r  |cffdca175%02dc|r",
        math.floor(copper/10000), math.floor(copper/100)%100, copper%100))
end

function FB:Refresh()
    if not self.frame then return end
    self:RefreshMoney()
    self.frame:SetScale(self.settings.scale or 1)
    for id,b in pairs(self.categoryButtons) do FB.Media:SetButtonBackdrop(b, id==self.currentCategory) end
    for id,b in pairs(self.viewButtons) do FB.Media:SetButtonBackdrop(b, id==self.currentView) end

    local sortLabels={slot=L.SORT_BAGS,name=L.SORT_NAME,quality=L.SORT_QUALITY,count=L.SORT_COUNT,value=L.SORT_VALUE}
    self.sortButton.text:SetText(sortLabels[self.settings.sort] or L.SORT_BAGS)

    local items, free, total, cached = self.Data:GetView(self.currentView)
    local filtered={}
    local categoryCounts={}
    for id in pairs(self.categoryButtons) do categoryCounts[id]=0 end
    for i=1,#items do
        local it=items[i]
        self.Data:Enrich(it)
        it.favorite=self:IsFavorite(it.itemID); it.tag=self:GetTag(it.itemID)
        if self.Search:Matches(it,self.searchText) then
            for id in pairs(categoryCounts) do
                if self:CategoryMatch(it,id) then categoryCounts[id]=categoryCounts[id]+1 end
            end
            if self:CategoryMatch(it,self.currentCategory) then table.insert(filtered,it) end
        end
    end
    for id,b in pairs(self.categoryButtons) do
        local count=categoryCounts[id] or 0
        b.count:SetText(count > 999 and "999+" or tostring(count))
    end
    self.Data:Sort(filtered)

    for i=1,#self.itemButtons do self.itemButtons[i]:Hide() end
    for i=1,#self.headerPool do self.headerPool[i]:Hide() end
    for i=1,#self.emptySlots do self.emptySlots[i]:Hide() end

    local child=self.scrollChild
    local width=child:GetWidth()
    if width < 100 then width=650 end
    local size=self.settings.iconSize or 42
    local gap=6
    local columns=math.max(1,math.min(self.settings.columns or 10, math.floor((width-8)/(size+gap))))
    local x0,y=4,-4
    local buttonIndex,headerIndex,emptyIndex=0,0,0

    local function layoutGroup(label, list)
        if #list==0 then return end
        if self.settings.sectioned and self.currentCategory=="all" and self.currentView~="discoveries" then
            headerIndex=headerIndex+1
            local h=self:GetPooledHeader(headerIndex); h:SetPoint("TOPLEFT",x0,y); h:SetPoint("TOPRIGHT",-4,y); h.text:SetText(label); h.count:SetText(tostring(#list)); h:Show(); y=y-30
        end
        local col=0
        for i=1,#list do
            buttonIndex=buttonIndex+1
            local b=self:GetPooledItemButton(buttonIndex); b:SetSize(size,size); b:ClearAllPoints(); b:SetPoint("TOPLEFT",x0+col*(size+gap),y); FB.ItemButton:SetItem(b,list[i]); b:Show()
            col=col+1
            if col>=columns then col=0; y=y-size-gap end
        end
        if col>0 then y=y-size-gap end
        y=y-4
    end

    if self.settings.sectioned and self.currentCategory=="all" and self.currentView~="discoveries" then
        local groups={}
        for _,id in ipairs(self.Data.categoryOrder) do groups[id]={} end
        for i=1,#filtered do
            local id=filtered[i].category or "misc"
            groups[id]=groups[id] or {}; table.insert(groups[id],filtered[i])
        end
        for _,id in ipairs(self.Data.categoryOrder) do layoutGroup(self:GetCategoryLabel(id),groups[id]) end
    else
        layoutGroup(self.currentCategory=="all" and (self.currentView=="discoveries" and L.DISCOVERIES or L.ALL_ITEMS) or self:GetCategoryLabel(self.currentCategory),filtered)
    end

    if self.currentView=="bags" and self.settings.showEmptySlots and free and free>0 and self.currentCategory=="all" and self.searchText=="" then
        local col=0
        for i=1,math.min(free,40) do
            emptyIndex=emptyIndex+1
            local e=self:GetEmptySlot(emptyIndex); e:SetSize(size,size); e:ClearAllPoints(); e:SetPoint("TOPLEFT",x0+col*(size+gap),y); e:Show()
            col=col+1; if col>=columns then col=0; y=y-size-gap end
        end
        if col>0 then y=y-size-gap end
    end

    child:SetHeight(math.max(450,-y+10))
    self.noItems:SetShown(#filtered==0)
    if self.currentView=="bags" then
        local junk=FB.Merchant:GetJunkValue()
        self.stats:SetText(string.format("%s: %d / %d\n%s: %s",L.FREE_SLOTS,free or 0,total or 0,L.JUNK_VALUE,FB:FormatMoney(junk)))
    elseif self.currentView=="bank" then
        self.stats:SetText((cached and (L.BANK_CACHED.."   •   ") or "")..tostring(#filtered).." items")
    else
        self.stats:SetText(tostring(#filtered).." items")
    end
    local showSell = self.state.merchantOpen and self.currentView=="bags"
    self.sellButton:SetShown(showSell)
    self.stats:ClearAllPoints()
    if showSell then
        self.stats:SetPoint("RIGHT", self.sellButton, "LEFT", -12, 0)
    else
        self.stats:SetPoint("RIGHT", self.footer, "RIGHT", -10, 0)
    end
end

function FB:Toggle()
    local f=self:BuildMainFrame()
    if f:IsShown() then f:Hide() else f:Show() end
end

FB:On("LOGIN", function()
    FB:BuildMainFrame()
    SLASH_FOREVERBAGS1="/fb"
    SLASH_FOREVERBAGS2="/foreverbags"
    SlashCmdList.FOREVERBAGS=function(msg)
        msg=(msg or ""):lower()
        if msg=="settings" or msg=="config" then FB.SettingsUI:Toggle()
        elseif msg=="bank" then FB.currentView="bank"; FB:BuildMainFrame():Show(); FB:Refresh()
        elseif msg=="reset" then FB.settings.windowPoint=nil; if FB.frame then FB.frame:ClearAllPoints(); FB.frame:SetPoint("CENTER") end
        elseif msg=="version" then
            FB:Print(FB.version .. " • Interface " .. tostring(select(4, GetBuildInfo())) .. " • project " .. tostring(WOW_PROJECT_ID))
        elseif msg=="native" then
            FB:Print("native integration=" .. tostring(FB.settings.nativeBagIntegration ~= false) .. " • ToggleBackpack=" .. tostring(type(_G.ToggleBackpack) == "function") .. " • C_Container=" .. tostring(C_Container ~= nil))
        else FB:Toggle() end
    end
end)

FB:On("DATA_CHANGED", function() if FB.frame and FB.frame:IsShown() then FB:Refresh() end end)
FB:On("FILTER_CHANGED", function() if FB.frame and FB.frame:IsShown() then FB:Refresh() end end)
FB:On("SETTINGS_CHANGED", function() if FB.frame then FB:Refresh() end end)
FB:On("MERCHANT_OPEN", function() if FB.frame and FB.frame:IsShown() then FB:Refresh() end end)
FB:On("MERCHANT_CLOSE", function() if FB.frame and FB.frame:IsShown() then FB:Refresh() end end)
FB:On("PLAYER_MONEY", function() FB:RefreshMoney() end)
