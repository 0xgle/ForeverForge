local _,FM=...
local T,M=FM.T,FM.Market
local U={offset=0,sort="unit",ascending=true,activeTab="Market"};FM.UI=U
local tabs={{"Market","Market","search"},{"Deals","Deals","coins"},{"Sell","Sell","sell"},{"Owned","My auctions","bank"},{"Bids","My bids","coins"},{"Shopping","Shopping","favorite"},{"Flips","Flip Finder","coins"},{"Trader","Trader Engine","trade"},{"Advisor","Advisor","discovery"},{"Ledger","Ledger","bank"},{"History","History","discovery"},{"Settings","Settings","settings"}}
function U:ApplyPosition()
    if not self.frame then return end
    -- Keep ForeverMarket inside the native AuctionHouseFrame. This preserves
    -- the exact Auction House interaction context used by working modern-AH
    -- addons, while the frame itself may still be larger than Blizzard's UI.
    local host=AuctionHouseFrame or UIParent
    if self.frame:GetParent()~=host then self.frame:SetParent(host) end
    local userScale=(FM.DB and FM.DB.settings and FM.DB.settings.scale) or 1
    local fit=math.min((UIParent:GetWidth()-24)/1160,(UIParent:GetHeight()-24)/760)
    self.frame:SetScale(math.max(.5,math.min(userScale,fit)))
    self.frame:ClearAllPoints()
    local p=FM.DB and FM.DB.settings and FM.DB.settings.position
    if p then self.frame:SetPoint(p[1],UIParent,p[2],p[3],p[4]) else self.frame:SetPoint("CENTER") end
    self.frame:SetMovable(true)
end
function U:Build()
    if self.frame then return end
    local f=CreateFrame("Frame","ForeverMarketFrame",AuctionHouseFrame or UIParent,"BackdropTemplate");self.frame=f
    f:Hide();f:SetSize(1160,760);f:SetFrameStrata("DIALOG");f:SetFrameLevel(((AuctionHouseFrame and AuctionHouseFrame:GetFrameLevel()) or 0)+200);f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true)
    local art=f:CreateTexture(nil,"BACKGROUND");art:SetAllPoints();art:SetTexture(FM.media.."Panel.tga")
    local bar=CreateFrame("Frame",nil,f);bar:SetPoint("TOPLEFT",20,-12);bar:SetSize(990,68);bar:EnableMouse(true);bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart",function() f:StartMoving() end)
    bar:SetScript("OnDragStop",function()
        f:StopMovingOrSizing();local p,_,r,x,y=f:GetPoint();FM.DB.settings.position={p,r,x,y}
    end)
    T:Icon(f,"coins",56,24,19)
    T:Text(f,"FOREVER  |cffd4ad6bMARKET|r",24,94,27,600,T.text)
    T:Text(f,"FOREVER  /  AUCTION HOUSE",10,96,58,410,T.muted)
    self.money=T:Text(f,"",14,880,32,208,T.gold);self.money:SetJustifyH("RIGHT")
    T:Button(f,"x",28,28,1106,24,function()
        if FM.Market.open and FM.Native and FM.Native.CloseAuctionHouse then FM.Native:CloseAuctionHouse() else U:Hide() end
    end)
    self.connection=T:Text(f,"",10,845,60,242,T.teal);self.connection:SetJustifyH("RIGHT")
    self.nav={}
    for i,v in ipairs(tabs) do
        local name=v[1];local b=T:Button(f,v[2],178,27,24,100+(i-1)*30,function() U:SetTab(name) end)
        b.label:ClearAllPoints();b.label:SetPoint("LEFT",38,0);b.label:SetWidth(131);b.label:SetJustifyH("LEFT")
        T:Icon(b,v[3],20,9,4);self.nav[name]=b
        if name=="Bids" and FM:IsModernAH() then b:Hide() end
    end
    local note=T:Panel(f,178,142,24,470)
    T:Text(note,"LOCAL MARKET",10,13,14,155,T.gold)
    self.realm=T:Text(note,FM.realmKey,11,13,36,153,T.muted);self.realm:SetWordWrap(true);self.realm:SetHeight(34)
    self.sideStats=T:Text(note,"",11,13,79,153,T.text);self.sideStats:SetWordWrap(true);self.sideStats:SetHeight(54)
    T:Button(f,"Scan market",178,32,24,626,function() M:FullScan() end,true)
    T:Button(f,"Blizzard AH",178,28,24,664,function() FM.Native:SwitchToBlizzard() end)
    T:Text(f,"by 0xgle  /  "..FM.version,10,26,724,250,T.muted)
    self.status=T:Text(f,"Ready",11,260,726,870,T.muted)
    self.body=CreateFrame("Frame",nil,f);self.body:SetSize(916,604);self.body:SetPoint("TOPLEFT",220,-110)
    self.panels={};self:BuildMarket();self:BuildBids();self:BuildSell();self:BuildShopping();self:BuildFlips();self:BuildTrader();self:BuildAdvisor();self:BuildLedger();self:BuildHistory();self:BuildSettings();self:BuildConfirm()
    f:SetScript("OnHide",function()
        U:DismissConfirm()
    end)
    self:ApplyPosition();self:SetTab("Market")
end
function U:SetStatus(text) if self.status then self.status:SetText(text or "") end end
function U:Show()
    if not M.open then
        FM:Print("Open the Auction House at an auctioneer first.")
        return
    end
    self:Build();self:ApplyPosition();self.frame:Show()
    self:Refresh()
end
function U:Hide() if self.frame then self.frame:Hide() end end
function U:Toggle()
    if self.frame and self.frame:IsShown() then
        if FM.Native then FM.Native:SwitchToBlizzard() else self:Hide() end
    else
        if FM.Native and FM.Native.SelectForeverMarket then FM.Native:SelectForeverMarket() else self:Show() end
    end
end
function U:SetTab(name)
    self.activeTab=name;self.offset=0;self.selected=nil
    for k,b in pairs(self.nav) do b.active=k==name;b:Paint() end
    for k,p in pairs(self.panels) do p:SetShown(k==name or (k=="Market" and (name=="Deals" or name=="Owned"))) end
    if name=="Owned" and M.open then M:RefreshOwned() end
    if name=="Bids" and M.open then M:RefreshBids() end
    if name=="Sell" then
        FM.Inventory:Scan();if M.open then FM.Sell:ReadSlot() end
        if FM.Sell.item then FM:Status("Review the item, price and quantity, then post when SERVER READY.")
        else FM:Status("Select an item from your bags to create an auction.") end
    end
    self:Refresh()
end
function U:NewPanel(name,title,sub)
    local p=CreateFrame("Frame",nil,self.body);p:SetAllPoints();p:Hide();self.panels[name]=p
    T:Text(p,title,20,0,0,890,T.gold)
    if sub then T:Text(p,sub,11,0,28,890,T.muted) end
    return p
end
function U:BuildMarket()
    local p=self:NewPanel("Market"," ");self.marketTitle=T:Text(p,"Market",20,0,0,600,T.gold)
    self.search=T:Edit(p,398,32,0,36,"")
    U.browseClass=nil;U.browseSub=nil;U.browseQuality=nil;U.browseUsable=false
    local function num(e) local v=tonumber(e and e:GetText() or "");return v and math.max(0,math.floor(v)) or nil end
    local function filters() return {classID=U.browseClass,subClassID=U.browseSub,minLevel=num(U.minLevel),maxLevel=num(U.maxLevel),quality=U.browseQuality,usable=U.browseUsable} end
    local function search() U.search:ClearFocus();M:Search(U.search:GetText(),0,U.exact,filters()) end
    U.marketSearch=search
    self.search:SetScript("OnEnterPressed",search)
    T:Button(p,"Search",96,32,406,36,search,true)
    self.exactButton=T:Button(p,"Exact name: NO",180,32,510,36,function(b) U.exact=not U.exact;b.label:SetText("Exact name: "..(U.exact and "YES" or "NO")) end)
    T:Button(p,"Stop",74,32,698,36,function() M:Stop();FM:Status("Stopped. Search again to resume trading.");FM:Refresh() end)
    self.refreshOwned=T:Button(p,"Refresh",112,32,780,36,function() if U.activeTab=="Owned" then M:RefreshOwned() else search() end end)

    local function drop(label,w,x,y,getItems,onPick)
        local b=T:Button(p,label,w,28,x,y,function(btn)
            if btn.menu and btn.menu:IsShown() then btn.menu:Hide();return end
            if U.openBrowseMenu and U.openBrowseMenu~=btn.menu then U.openBrowseMenu:Hide() end
            local items=getItems();local h=math.min(320,8+#items*24)
            local m=btn.menu or T:Panel(p,w,h,x,y+30);btn.menu=m;m:SetFrameStrata("DIALOG");m:SetFrameLevel(p:GetFrameLevel()+20)
            for _,c in ipairs(m.children or {}) do c:Hide() end;m.children={};m:SetHeight(h)
            for i,it in ipairs(items) do
                if i>13 then break end
                local r=T:Button(m,it.label,w-8,22,4,4+(i-1)*24,function() onPick(it);m:Hide() end)
                r.label:SetJustifyH("LEFT");m.children[#m.children+1]=r
            end
            m:Show();U.openBrowseMenu=m
        end)
        return b
    end
    local function classItems()
        local a={{label="All categories",id=nil}}
        for id=0,20 do local n=FM:GetItemClassName(id);if n and n~="" then a[#a+1]={label=n,id=id} end end
        return a
    end
    local function subItems()
        local a={{label="All subcategories",id=nil}};if U.browseClass==nil then return a end
        for id=0,40 do local n=FM:GetItemSubClassName(U.browseClass,id);if n and n~="" then a[#a+1]={label=n,id=id} end end
        return a
    end
    -- Browse controls are intentionally split into two clearly labelled rows.
    -- The previous compact 2-row layout was functional, but visually dense at common UI scales.
    T:Text(p,"BROWSE AUCTION HOUSE",9,0,78,180,T.gold)
    T:Text(p,"Category",9,0,94,120,T.muted)
    T:Text(p,"Subcategory",9,198,94,120,T.muted)
    T:Text(p,"Min level",9,396,94,68,T.muted)
    T:Text(p,"Max level",9,472,94,68,T.muted)
    T:Text(p,"Quality",9,548,94,120,T.muted)

    self.classDrop=drop("All categories",190,0,108,classItems,function(it) U.browseClass=it.id;U.browseSub=nil;U.classDrop.label:SetText(it.label);U.subDrop.label:SetText("All subcategories") end)
    self.subDrop=drop("All subcategories",190,198,108,subItems,function(it) U.browseSub=it.id;U.subDrop.label:SetText(it.label) end)
    self.minLevel=T:Edit(p,68,28,396,108,"");self.minLevel:SetMaxLetters(3);T:Tip(self.minLevel,"Min level","Optional minimum item level for the Auction House query.")
    self.maxLevel=T:Edit(p,68,28,472,108,"");self.maxLevel:SetMaxLetters(3);T:Tip(self.maxLevel,"Max level","Optional maximum item level for the Auction House query.")
    local qualities={{label="Any quality",id=nil},{label="Poor",id=0},{label="Common",id=1},{label="Uncommon",id=2},{label="Rare",id=3},{label="Epic",id=4},{label="Legendary",id=5}}
    self.qualityDrop=drop("Any quality",142,548,108,function() return qualities end,function(it) U.browseQuality=it.id;U.qualityDrop.label:SetText(it.label) end)
    self.usableButton=T:Button(p,"Usable: NO",100,28,698,108,function(b) U.browseUsable=not U.browseUsable;b.label:SetText("Usable: "..(U.browseUsable and "YES" or "NO")) end)
    T:Button(p,"Browse",86,28,806,108,function() U.search:SetText("");U.exact=false;U.exactButton.label:SetText("Exact name: NO");search() end,true)

    T:Text(p,"LOCAL RESULT FILTERS",9,0,148,180,T.gold)
    T:Text(p,"Name contains",9,0,164,120,T.muted)
    T:Text(p,"Max / item",9,276,164,82,T.muted)
    self.filter=T:Edit(p,262,28,0,178,"");T:Tip(self.filter,"Filter loaded results","Enter part of an item name. Filters the loaded page without a new server query.")
    self.filter:SetScript("OnTextChanged",function() U.offset=0;U:RefreshMarket() end)
    self.maxPrice=T:Edit(p,126,28,276,178,"");self.maxPrice:SetScript("OnTextChanged",function() U.offset=0;U:RefreshMarket() end)
    self.onlyBuy=T:Button(p,"Buyout only: NO",154,28,414,178,function(b)
        if U.activeTab=="Owned" then U.ownerUndercutOnly=not U.ownerUndercutOnly else U.buyoutOnly=not U.buyoutOnly end
        U.offset=0;U:RefreshMarket()
    end)
    self.filterHint=T:Text(p,"Shift-click: watch item",10,590,186,250,T.muted)
    local head=T:Panel(p,892,24,0,222)

    local cols={{"ITEM","name",8,264},{"QTY","count",280,44},{"UNIT PRICE","unit",330,112},{"STACK PRICE","buyout",450,112},{"MARKET %","deal",570,92},{"SELLER","owner",670,124}}
    self.marketHeaders={}
    for _,v in ipairs(cols) do
        local key=v[2];local b=T:Button(head,v[1],v[4],22,v[3],1,function() if U.sort==key then U.ascending=not U.ascending else U.sort=key;U.ascending=true end;U:RefreshMarket() end)
        b.label:SetFont(STANDARD_TEXT_FONT,9,"");self.marketHeaders[key]=b
    end
    self.rows={}
    for i=1,10 do
        local r=CreateFrame("Button",nil,p,"BackdropTemplate");r:SetSize(892,31);r:SetPoint("TOPLEFT",0,-(250+(i-1)*32))
        r:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});r:SetBackdropColor(.025,.048,.056,i%2==0 and .95 or .7)
        r.icon=r:CreateTexture(nil,"ARTWORK");r.icon:SetSize(28,28);r.icon:SetPoint("LEFT",7,0);r.icon:SetTexCoord(.07,.93,.07,.93)
        r.name=T:Text(r,"",12,44,8,222);r.qty=T:Text(r,"",11,280,8,45)
        r.unit=T:Text(r,"",11,330,8,114);r.total=T:Text(r,"",11,450,8,114)
        r.deal=T:Text(r,"",11,578,8,85,T.teal);r.owner=T:Text(r,"",11,670,8,125,T.muted)
        r.buy=T:Button(r,"Buy",44,25,800,3,function() if r.data then if U.activeTab=="Owned" then M:Cancel(r.data) else M:Buy(r.data) end end end,true)
        r.bid=T:Button(r,"Bid",40,25,848,3,function() if r.data then M:Buy(r.data,true) end end)
        r:SetScript("OnClick",function()
            if not r.data then return end
            U.selected=r.data
            if IsShiftKeyDown() then FM:ToggleWatch(r.data) end
            U:RefreshMarket()
        end)
        r:SetScript("OnEnter",function()
            if not r.data then return end
            GameTooltip:SetOwner(r,"ANCHOR_RIGHT")
            if r.data.link then GameTooltip:SetHyperlink(r.data.link) else GameTooltip:SetText(r.data.name) end
            if r.data.reference then GameTooltip:AddLine("Reference: "..FM:Money(r.data.reference).." ("..r.data.referenceSource..")",.55,.83,.76) end
            GameTooltip:AddLine("Shift-click: watch | Stack price = total buyout cost",.65,.72,.74,true);GameTooltip:Show()
        end)
        r:SetScript("OnLeave",function() GameTooltip:Hide() end)
        self.rows[i]=r
    end
    local scroll=CreateFrame("Slider",nil,p,"OptionsSliderTemplate")
    scroll:SetOrientation("VERTICAL");scroll:SetSize(14,314);scroll:SetPoint("TOPLEFT",899,-250);scroll:SetMinMaxValues(0,0);scroll:SetValueStep(1);scroll:SetObeyStepOnDrag(true)
    scroll:SetScript("OnValueChanged",function(_,v) U.offset=math.floor(v+.5);U:RefreshMarket() end);self.scroll=scroll
    p:EnableMouseWheel(true);p:SetScript("OnMouseWheel",function(_,d) U.scroll:SetValue(U.offset-d*3) end)
    self.empty=T:Text(p,"",14,55,326,790,T.muted);self.empty:SetJustifyH("CENTER");self.empty:SetWordWrap(true);self.empty:SetHeight(100)
    self.paging=T:Text(p,"",11,0,598,430,T.muted)
    self.prev=T:Button(p,"< AH page",112,28,650,588,function() if U.activeTab~="Owned" then M:Search(M.query,M.page-1,M.exact,M.filters) end end)
    self.next=T:Button(p,"AH page >",122,28,770,588,function() if U.activeTab~="Owned" then M:Search(M.query,M.page+1,M.exact,M.filters) end end)
    local detail=T:Panel(p,892,48,0,625)
    self.detail=T:Text(detail,"Select an item to see its details.",11,12,10,598,T.muted);self.detail:SetHeight(32);self.detail:SetWordWrap(true)
    self.detailWatch=T:Button(detail,"Watch",112,28,642,10,function() if U.selected then FM:ToggleWatch(U.selected);U:RefreshMarket() end end)
    self.detailSearch=T:Button(detail,"Search",112,28,766,10,function()
        if not U.selected then return end
        if U.activeTab=="Owned" then M:CheckOwned(U.selected) else U.search:SetText(U.selected.name);M:Search(U.selected.name,0,true) end
    end)
end
function U:MarketData()
    local data={};local owned=self.activeTab=="Owned"
    local filter=self.filter and self.filter:GetText():lower() or ""
    local limit=self.maxPrice and FM:ParseMoney(self.maxPrice:GetText())
    for _,r in ipairs(owned and M.owned or M.results) do
        local valid=(filter=="" or r.name:lower():find(filter,1,true)) and (not limit or limit<=0 or (r.unit>0 and r.unit<=limit))
        if (not owned and self.buyoutOnly) and r.buyout<=0 then valid=false end
        if owned and self.ownerUndercutOnly and M:OwnerStatus(r)~="UNDERCUT" then valid=false end
        if self.activeTab=="Deals" and (not r.deal or r.deal>FM.DB.settings.dealThreshold or M:IsMine(r.owner)) then valid=false end
        if valid then data[#data+1]=r end
    end
    local key,asc=self.sort,self.ascending
    table.sort(data,function(a,b)
        local av,bv=a[key],b[key]
        if owned and key=="deal" then av,bv=M:OwnerStatus(a),M:OwnerStatus(b)
        elseif owned and key=="owner" then av,bv=a.timeLeft or 99,b.timeLeft or 99
        elseif key=="unit" or key=="deal" then av=av and av>0 and av or math.huge;bv=bv and bv>0 and bv or math.huge end
        if av==bv then return a.index<b.index end
        if type(av)=="string" then av=av:lower();bv=bv:lower() end
        if asc then return av<bv else return av>bv end
    end)
    return data
end
function U:RefreshMarket()
    if not self.rows then return end
    local owned=self.activeTab=="Owned";local data=self:MarketData();local max=math.max(0,#data-10)
    self.offset=math.min(self.offset,max)
    self.scroll:SetMinMaxValues(0,max)
    if self.scroll:GetValue()~=self.offset then self.scroll:SetValue(self.offset) end
    self.marketTitle:SetText(owned and "My auctions / price checks" or self.activeTab=="Deals" and "Deals / local price comparison" or "Market / find an item")
    if self.marketHeaders then
        self.marketHeaders.deal.label:SetText(owned and "STATUS" or "MARKET %")
        self.marketHeaders.owner.label:SetText(owned and "TIME / BID" or "SELLER")
        if self.marketHeaders.buyout then self.marketHeaders.buyout.label:SetText((FM:IsModernAH() and not owned) and "MIN PRICE" or "STACK PRICE") end
    end
    if self.onlyBuy then self.onlyBuy.label:SetText(owned and ("Undercut only: "..(self.ownerUndercutOnly and "YES" or "NO")) or ("Buyout only: "..(self.buyoutOnly and "YES" or "NO"))) end
    if self.filterHint then self.filterHint:SetText(owned and "Select auction -> Check price" or "Shift-click: watch item") end
    if self.detailSearch then self.detailSearch.label:SetText(owned and "Check price" or "Search") end
    if self.detailWatch then self.detailWatch:SetShown(not owned) end
    self.empty:SetShown(#data==0)
    if not M.open then
        self.empty:SetText("Open the Auction House to search and trade.\nShopping lists and price history are also available on the go.")
    elseif owned then
        self.empty:SetText(M.ownerLoading and "Loading your auctions..." or (self.ownerUndercutOnly and "No checked auctions are currently marked UNDERCUT.\nSelect an auction, click Check price, then enable this filter." or "No auctions found.\nClick Refresh after posting if the server has not updated the list yet."))
    else
        self.empty:SetText(M.request and "Loading auctions..." or "No results. Enter a name and click Search.\nFilters and Deals apply only to loaded auctions.")
    end
    for i,r in ipairs(self.rows) do
        local d=data[self.offset+i];r.data=d;r:SetShown(d~=nil)
        if d then
            r.icon:SetTexture(d.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            r.name:SetText((FM.Data.watchlist[d.key] and "|cffd4ad6b* |r" or "")..d.name)
            local color=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[d.quality];if color then r.name:SetTextColor(color.r,color.g,color.b) end
            r.qty:SetText(owned and d.saleStatus==1 and "-" or d.count);r.unit:SetText(d.unit>0 and FM:Money(d.unit) or "-")
            if d.summary and FM:IsModernAH() then r.total:SetText(d.unit>0 and FM:Money(d.unit) or "-") else r.total:SetText(d.buyout>0 and FM:Money(d.buyout) or "No buyout") end
            if owned then
                local status=M:OwnerStatus(d);r.deal:SetText(status)
                local timeText=({"<30m","<2h","<12h",">12h"})[d.timeLeft] or "-"
                r.owner:SetText(d.saleStatus==1 and "SOLD" or (timeText..(d.bid>0 and (" | "..FM:Money(d.bid)) or " | no bid")))
            else
                r.deal:SetText(d.deal and string.format("%.0f%%",d.deal*100) or "-");r.owner:SetText(d.owner or (d.containsOwnerItem and "Includes yours" or "Market"))
            end
            r.bid:SetShown(not owned and not FM:IsModernAH());r.buy.label:SetText(owned and (d.saleStatus==1 and "Sold" or "Cancel") or "Buy");r.buy:SetWidth(owned and 88 or 44)
            local enabled=M.open and not M.request and not M.queued and not M.transaction and (owned or (d.actionable and d.generation==M.generation and not M:IsMine(d.owner)))
            r.buy:SetEnabled(enabled and (owned and d.saleStatus~=1 or (not owned and d.buyout>0)));r.bid:SetEnabled(enabled)
        end
    end
    local page=owned and 0 or M.page;local total=owned and (M.ownerTotal or #data) or M.total
    if owned then
        local sold,under=0,0;for _,d in ipairs(M.owned) do if d.saleStatus==1 then sold=sold+1 end;if M:OwnerStatus(d)=="UNDERCUT" then under=under+1 end end
        self.paging:SetText(string.format("%d auctions | %d sold | %d undercut | showing %d-%d",total,sold,under,#data>0 and self.offset+1 or 0,math.min(#data,self.offset+10)))
    else
        if FM:IsModernAH() then
            self.paging:SetText(string.format("%d results | showing %d-%d | live Auction House",#data,#data>0 and self.offset+1 or 0,math.min(#data,self.offset+10)))
        else
            self.paging:SetText(string.format("%d results | showing %d-%d | AH page %d",#data,#data>0 and self.offset+1 or 0,math.min(#data,self.offset+10),page+1))
        end
    end
    local can=M.open and not M.request and not M.queued and not M.transaction and not owned and M.mode=="search" and not FM:IsModernAH()
    self.prev:SetShown(not FM:IsModernAH());self.next:SetShown(not FM:IsModernAH())
    self.prev:SetEnabled(can and page>0);self.next:SetEnabled(can and (page+1)*50<total)
    if self.selected then
        local d=self.selected
        if owned then self.detail:SetText(d.name.." | "..M:OwnerStatus(d).."\n"..M:OwnerCheckText(d))
        else
            local flip=d.flipPlan and ("\nFLIP REVIEW: exit "..FM:Money(d.flipPlan.exitUnit).." / item | net "..(d.flipPlan.profit>=0 and "+" or "-")..FM:Money(math.abs(d.flipPlan.profit)).." | ROI "..string.format("%.0f%%",d.flipPlan.roi*100)) or ""
            if d.summary and FM:IsModernAH() then
                self.detail:SetText(d.name.." | Available: "..tostring(d.availableQuantity or d.count or 0).." | Minimum: "..FM:Money(d.unit).."\n"..(d.reference and ("Reference: "..FM:Money(d.reference).." / "..d.referenceSource) or "No reliable reference price available.")..flip)
            else
                self.detail:SetText(d.name.." | Stack: "..FM:Money(d.buyout).."\n"..(d.reference and ("Reference: "..FM:Money(d.reference).." / "..d.referenceSource) or "No reliable reference price available.")..flip)
            end
        end
    else self.detail:SetText(owned and "Select an auction, then click Check price to compare it with the current loaded market page." or "Select an item to see its details.") end
end
