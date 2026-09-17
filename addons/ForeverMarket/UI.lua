local _,FM=...
local T,M=FM.T,FM.Market
local U={offset=0,sort="unit",ascending=true,activeTab="Market"};FM.UI=U
local tabs={{"Market","Market","search"},{"Deals","Deals","coins"},{"Sell","Sell","sell"},{"Owned","My auctions","bank"},{"Shopping","Shopping lists","favorite"},{"History","Price history","discovery"},{"Settings","Settings","settings"}}
function U:ApplyPosition()
    if not self.frame then return end
    local scale=math.min(FM.DB.settings.scale or 1,(UIParent:GetWidth()-24)/1160,(UIParent:GetHeight()-24)/760)
    self.frame:SetScale(math.max(.5,scale));self.frame:ClearAllPoints()
    local p=FM.DB.settings.position
    if p then self.frame:SetPoint(p[1],UIParent,p[2],p[3],p[4]) else self.frame:SetPoint("CENTER") end
end
function U:Build()
    if self.frame then return end
    local f=CreateFrame("Frame","ForeverMarketFrame",UIParent,"BackdropTemplate");self.frame=f
    f:Hide();f:SetSize(1160,760);f:SetFrameStrata("HIGH");f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true)
    local art=f:CreateTexture(nil,"BACKGROUND");art:SetAllPoints();art:SetTexture(FM.media.."Panel.tga")
    local bar=CreateFrame("Frame",nil,f);bar:SetPoint("TOPLEFT",20,-12);bar:SetSize(990,68);bar:EnableMouse(true);bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart",function() f:StartMoving() end)
    bar:SetScript("OnDragStop",function() f:StopMovingOrSizing();local p,_,r,x,y=f:GetPoint();FM.DB.settings.position={p,r,x,y} end)
    T:Icon(f,"coins",56,24,19)
    T:Text(f,"FOREVER  |cffd4ad6bMARKET|r",24,94,27,600,T.text)
    T:Text(f,"FOREVERFORGE  /  AUCTION HOUSE",10,96,58,410,T.muted)
    self.money=T:Text(f,"",14,880,32,208,T.gold);self.money:SetJustifyH("RIGHT")
    T:Button(f,"x",28,28,1106,24,function() U:Hide() end)
    self.connection=T:Text(f,"",10,845,60,242,T.teal);self.connection:SetJustifyH("RIGHT")
    self.nav={}
    for i,v in ipairs(tabs) do
        local name=v[1];local b=T:Button(f,v[2],178,42,24,116+(i-1)*49,function() U:SetTab(name) end)
        b.label:ClearAllPoints();b.label:SetPoint("LEFT",42,0);b.label:SetWidth(127);b.label:SetJustifyH("LEFT")
        T:Icon(b,v[3],26,9,8);self.nav[name]=b
    end
    local note=T:Panel(f,178,142,24,480)
    T:Text(note,"LOCAL MARKET",10,13,14,155,T.gold)
    self.realm=T:Text(note,FM.realmKey,11,13,36,153,T.muted);self.realm:SetWordWrap(true);self.realm:SetHeight(34)
    self.sideStats=T:Text(note,"",11,13,79,153,T.text);self.sideStats:SetWordWrap(true);self.sideStats:SetHeight(54)
    T:Button(f,"Scan market",178,32,24,638,function() M:FullScan() end,true)
    T:Button(f,"Blizzard",178,28,24,678,function() FM.Native:SwitchToBlizzard() end)
    T:Text(f,"by 0xgle  /  "..FM.version,10,26,724,250,T.muted)
    self.status=T:Text(f,"Ready",11,260,726,870,T.muted)
    self.body=CreateFrame("Frame",nil,f);self.body:SetSize(916,604);self.body:SetPoint("TOPLEFT",220,-110)
    self.panels={};self:BuildMarket();self:BuildSell();self:BuildShopping();self:BuildHistory();self:BuildSettings();self:BuildConfirm()
    f:SetScript("OnHide",function()
        U:DismissConfirm()
        if not U.suppressClose and M.open and FM.Native.saved then
            FM.Native:Restore();CloseAuctionHouse()
        end
    end)
    UISpecialFrames[#UISpecialFrames+1]="ForeverMarketFrame"
    self:ApplyPosition();self:SetTab("Market")
end
function U:SetStatus(text) if self.status then self.status:SetText(text or "") end end
function U:Show()
    self:Build();self.frame:Show();FM.Native.manual=false
    if M.open and FM:Supported() then FM.Native:Hook();FM.Native:Takeover() end
    self:Refresh()
end
function U:Hide() if self.frame then self.frame:Hide() end end
function U:Toggle() if self.frame and self.frame:IsShown() then self:Hide() else self:Show() end end
function U:SetTab(name)
    self.activeTab=name;self.offset=0;self.selected=nil
    for k,b in pairs(self.nav) do b.active=k==name;b:Paint() end
    for k,p in pairs(self.panels) do p:SetShown(k==name or (k=="Market" and (name=="Deals" or name=="Owned"))) end
    if name=="Owned" and M.open then M:RefreshOwned() end
    if name=="Sell" then FM.Inventory:Scan();if M.open then FM.Sell:ReadSlot() end end
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
    local function search() U.search:ClearFocus();M:Search(U.search:GetText(),0,U.exact) end
    self.search:SetScript("OnEnterPressed",search)
    T:Button(p,"Search",96,32,406,36,search,true)
    self.exactButton=T:Button(p,"Exact name: NO",180,32,510,36,function(b) U.exact=not U.exact;b.label:SetText("Exact name: "..(U.exact and "YES" or "NO")) end)
    T:Button(p,"Stop",74,32,698,36,function() M:Stop();FM:Status("Stopped. Search again to resume trading.");FM:Refresh() end)
    self.refreshOwned=T:Button(p,"Refresh",112,32,780,36,function() if U.activeTab=="Owned" then M:RefreshOwned() else search() end end)
    self.filter=T:Edit(p,262,28,0,80,"");T:Tip(self.filter,"Filter loaded results","Enter part of an item name. Filters the loaded page without a new server query.")
    self.filter:SetScript("OnTextChanged",function() U.offset=0;U:RefreshMarket() end)
    T:Text(p,"Max / item",11,276,88,82,T.muted)
    self.maxPrice=T:Edit(p,126,28,356,80,"");self.maxPrice:SetScript("OnTextChanged",function() U.offset=0;U:RefreshMarket() end)
    self.onlyBuy=T:Button(p,"Buyout only: NO",154,28,490,80,function(b) U.buyoutOnly=not U.buyoutOnly;b.label:SetText("Buyout only: "..(U.buyoutOnly and "YES" or "NO"));U.offset=0;U:RefreshMarket() end)
    self.filterHint=T:Text(p,"Shift-click: watch item",10,660,88,230,T.muted)
    local head=T:Panel(p,892,24,0,120)
    local cols={{"ITEM","name",8,264},{"QTY","count",280,44},{"UNIT PRICE","unit",330,112},{"STACK PRICE","buyout",450,112},{"MARKET %","deal",570,92},{"SELLER","owner",670,124}}
    for _,v in ipairs(cols) do
        local key=v[2];local b=T:Button(head,v[1],v[4],22,v[3],1,function() if U.sort==key then U.ascending=not U.ascending else U.sort=key;U.ascending=true end;U:RefreshMarket() end)
        b.label:SetFont(STANDARD_TEXT_FONT,9,"")
    end
    self.rows={}
    for i=1,10 do
        local r=CreateFrame("Button",nil,p,"BackdropTemplate");r:SetSize(892,35);r:SetPoint("TOPLEFT",0,-(148+(i-1)*36))
        r:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});r:SetBackdropColor(.025,.048,.056,i%2==0 and .95 or .7)
        r.icon=r:CreateTexture(nil,"ARTWORK");r.icon:SetSize(28,28);r.icon:SetPoint("LEFT",7,0);r.icon:SetTexCoord(.07,.93,.07,.93)
        r.name=T:Text(r,"",12,44,10,222);r.qty=T:Text(r,"",11,280,10,45)
        r.unit=T:Text(r,"",11,330,10,114);r.total=T:Text(r,"",11,450,10,114)
        r.deal=T:Text(r,"",11,578,10,85,T.teal);r.owner=T:Text(r,"",11,670,10,125,T.muted)
        r.buy=T:Button(r,"Buy",44,25,800,5,function() if r.data then if U.activeTab=="Owned" then M:Cancel(r.data) else M:Buy(r.data) end end end,true)
        r.bid=T:Button(r,"Bid",40,25,848,5,function() if r.data then M:Buy(r.data,true) end end)
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
    scroll:SetOrientation("VERTICAL");scroll:SetSize(14,354);scroll:SetPoint("TOPLEFT",899,-150);scroll:SetMinMaxValues(0,0);scroll:SetValueStep(1);scroll:SetObeyStepOnDrag(true)
    scroll:SetScript("OnValueChanged",function(_,v) U.offset=math.floor(v+.5);U:RefreshMarket() end);self.scroll=scroll
    p:EnableMouseWheel(true);p:SetScript("OnMouseWheel",function(_,d) U.scroll:SetValue(U.offset-d*3) end)
    self.empty=T:Text(p,"",14,55,256,790,T.muted);self.empty:SetJustifyH("CENTER");self.empty:SetWordWrap(true);self.empty:SetHeight(100)
    self.paging=T:Text(p,"",11,0,528,430,T.muted)
    self.prev=T:Button(p,"< AH page",112,28,650,518,function() if U.activeTab~="Owned" then M:Search(M.query,M.page-1,M.exact) end end)
    self.next=T:Button(p,"AH page >",122,28,770,518,function() if U.activeTab~="Owned" then M:Search(M.query,M.page+1,M.exact) end end)
    local detail=T:Panel(p,892,48,0,555)
    self.detail=T:Text(detail,"Select an item to see its details.",11,12,10,598,T.muted);self.detail:SetHeight(32);self.detail:SetWordWrap(true)
    T:Button(detail,"Watch",112,28,642,10,function() if U.selected then FM:ToggleWatch(U.selected);U:RefreshMarket() end end)
    T:Button(detail,"Search",112,28,766,10,function() if U.selected then U.search:SetText(U.selected.name);M:Search(U.selected.name,0,true) end end)
end
function U:MarketData()
    local data={};local owned=self.activeTab=="Owned"
    local filter=self.filter and self.filter:GetText():lower() or ""
    local limit=self.maxPrice and FM:ParseMoney(self.maxPrice:GetText())
    for _,r in ipairs(owned and M.owned or M.results) do
        local valid=(filter=="" or r.name:lower():find(filter,1,true)) and (not limit or limit<=0 or (r.unit>0 and r.unit<=limit))
        if self.buyoutOnly and r.buyout<=0 then valid=false end
        if self.activeTab=="Deals" and (not r.deal or r.deal>FM.DB.settings.dealThreshold or M:IsMine(r.owner)) then valid=false end
        if valid then data[#data+1]=r end
    end
    local key,asc=self.sort,self.ascending
    table.sort(data,function(a,b)
        local av,bv=a[key],b[key]
        if key=="unit" or key=="deal" then av=av and av>0 and av or math.huge;bv=bv and bv>0 and bv or math.huge end
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
    self.marketTitle:SetText(owned and "My auctions" or self.activeTab=="Deals" and "Deals / local price comparison" or "Market / find an item")
    self.empty:SetShown(#data==0)
    if not M.open then
        self.empty:SetText("Open the Auction House to search and trade.\nShopping lists and price history are also available on the go.")
    elseif owned then
        self.empty:SetText(M.ownerLoading and "Loading your auctions..." or "No active auctions found.\nClick Refresh after posting if the server has not updated the list yet.")
    else
        self.empty:SetText(M.request and "Loading auctions..." or "No results. Enter a name and click Search.\nFilters and Deals apply only to loaded auctions.")
    end
    for i,r in ipairs(self.rows) do
        local d=data[self.offset+i];r.data=d;r:SetShown(d~=nil)
        if d then
            r.icon:SetTexture(d.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            r.name:SetText((FM.Data.watchlist[d.key] and "|cffd4ad6b* |r" or "")..d.name)
            local color=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[d.quality];if color then r.name:SetTextColor(color.r,color.g,color.b) end
            r.qty:SetText(d.count);r.unit:SetText(d.unit>0 and FM:Money(d.unit) or "-");r.total:SetText(d.buyout>0 and FM:Money(d.buyout) or "No buyout")
            r.deal:SetText(owned and (d.saleStatus==1 and "Sold" or ({"<30m","<2h","<12h",">12h"})[d.timeLeft] or "-") or d.deal and string.format("%.0f%%",d.deal*100) or "-")
            r.owner:SetText(owned and (d.bid>0 and ("Bid "..FM:Money(d.bid)) or "No bids") or d.owner)
            r.bid:SetShown(not owned);r.buy.label:SetText(owned and "Cancel" or "Buy");r.buy:SetWidth(owned and 88 or 44)
            local enabled=M.open and not M.request and not M.queued and not M.transaction and (owned or (d.actionable and d.generation==M.generation and not M:IsMine(d.owner)))
            r.buy:SetEnabled(enabled and (owned or d.buyout>0));r.bid:SetEnabled(enabled)
        end
    end
    local page=owned and 0 or M.page;local total=owned and (M.ownerTotal or #data) or M.total
    if owned then
        self.paging:SetText(string.format("%d active auctions | showing %d-%d",total,#data>0 and self.offset+1 or 0,math.min(#data,self.offset+10)))
    else
        self.paging:SetText(string.format("%d results | showing %d-%d | AH page %d",#data,#data>0 and self.offset+1 or 0,math.min(#data,self.offset+10),page+1))
    end
    local can=M.open and not M.request and not M.queued and not M.transaction and not owned and M.mode=="search"
    self.prev:SetEnabled(can and page>0);self.next:SetEnabled(can and (page+1)*50<total)
    if self.selected then local d=self.selected;self.detail:SetText(d.name.." | Stack: "..FM:Money(d.buyout).."\n"..(d.reference and ("Reference: "..FM:Money(d.reference).." / "..d.referenceSource) or "No reliable reference price available.")) end
end
