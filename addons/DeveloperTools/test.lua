unpack=table.unpack
local now=1000
local timers={}
C_Timer={After=function(delay,fn) timers[#timers+1]={t=now+delay,fn=fn} end}
function advance(dt)
    local untilTime=now+dt;local steps=0
    while true do
        table.sort(timers,function(a,b) return a.t<b.t end)
        if not timers[1] or timers[1].t>untilTime then break end
        local task=table.remove(timers,1);now=task.t;task.fn();steps=steps+1;assert(steps<10000,"timer loop")
    end
    now=untilTime
end
function GetTime() return now end
function time() return 1789632000+math.floor(now) end
date=os.date
local calls={query={},buy={},post={},cancel={}}
local frames={}
local Obj={}
Obj.__index=Obj
local function object(kind,name,parent)
    local o=setmetatable({kind=kind,nameID=name,parent=parent,shown=true,enabled=true,alpha=1,scale=1,points={},scripts={},hooks={},w=0,h=0,level=1},Obj)
    frames[#frames+1]=o;if name then _G[name]=o end;return o
end
function CreateFrame(kind,name,parent,template) return object(kind,name,parent) end
function Obj:CreateFontString(name,layer,template) local t=object("FontString",name,self);t.layer=layer;return t end
function Obj:CreateTexture(name,layer) local t=object("Texture",name,self);t.layer=layer;return t end
function Obj:SetScript(event,fn) self.scripts[event]=fn end
function Obj:HookScript(event,fn) self.hooks[event]=self.hooks[event] or {};table.insert(self.hooks[event],fn) end
function Obj:Fire(event,...) if self.scripts[event] then self.scripts[event](self,...) end;for _,fn in ipairs(self.hooks[event] or {}) do fn(self,...) end end
function Obj:RegisterEvent(event) self.events=self.events or {};self.events[event]=true end
function emit(event,...) for _,f in ipairs(frames) do if f.events and f.events[event] then f:Fire("OnEvent",event,...) end end end
function Obj:SetSize(w,h) self.w,self.h=w,h end
function Obj:SetWidth(w) self.w=w end
function Obj:SetHeight(h) self.h=h end
function Obj:GetWidth() return self.w end
function Obj:GetHeight() return self.h end
function Obj:SetPoint(...) self.points[1]={...} end
function Obj:GetPoint(i) return unpack(self.points[i or 1] or {}) end
function Obj:GetNumPoints() return #self.points end
function Obj:ClearAllPoints() self.points={} end
function Obj:SetAllPoints(relative) self.all=relative or self.parent end
function Obj:SetAlpha(a) self.alpha=a end
function Obj:GetAlpha() return self.alpha end
function Obj:EnableMouse(on) self.mouse=on end
function Obj:IsMouseEnabled() return self.mouse or false end
function Obj:SetClampedToScreen(on) self.clamp=on end
function Obj:IsClampedToScreen() return self.clamp or false end
function Obj:IsShown() return self.shown end
function Obj:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Obj:Show() if not self.shown then self.shown=true;self:Fire("OnShow") end end
function Obj:Hide() if self.shown then self.shown=false;self:Fire("OnHide") end end
function Obj:SetShown(on) if on then self:Show() else self:Hide() end end
function Obj:SetEnabled(on) local b=not not on;if self.enabled~=b then self.enabled=b;self:Fire(b and "OnEnable" or "OnDisable") end end
function Obj:SetBackdrop(b) self.backdrop=b end
function Obj:SetBackdropColor(...) self.bg={...} end
function Obj:SetBackdropBorderColor(...) self.border={...} end
function Obj:SetText(s) s=tostring(s or "");if s~=self.text then self.text=s;self:Fire("OnTextChanged",false) end end
function Obj:GetText() return self.text or "" end
function Obj:SetTexture(t) self.texture=t end
function Obj:SetFont(path,size,flags) self.fontSize=size;return true end
function Obj:SetTextColor(...) self.color={...} end
function Obj:SetJustifyH(j) self.justify=j end
function Obj:SetWordWrap(v) self.wrap=v end
function Obj:SetFrameLevel(level) self.level=level end
function Obj:GetFrameLevel() return self.level end
function Obj:SetMinMaxValues(a,b) self.min,self.max=a,b end
function Obj:SetValue(n) n=math.max(self.min or 0,math.min(self.max or 0,n));if self.value~=n then self.value=n;self:Fire("OnValueChanged",n) end end
function Obj:GetValue() return self.value or 0 end
function Obj:SetScale(s) self.scale=s end
function Obj:GetItem() return "Peacebloom","item:2447::::::::" end
for _,name in ipairs({"SetFrameStrata","SetMovable","RegisterForDrag","StartMoving","StopMovingOrSizing","SetAutoFocus","SetFontObject","SetTextInsets","SetMaxLetters","SetJustifyV","ClearFocus","SetTexCoord","SetOrientation","SetValueStep","SetObeyStepOnDrag","EnableMouseWheel","SetOwner","SetHyperlink","AddLine"}) do Obj[name]=function() end end
UIParent=CreateFrame("Frame","UIParent");UIParent:SetSize(1600,1000)
GameTooltip=CreateFrame("Frame","GameTooltip")
AuctionFrame=CreateFrame("Frame","AuctionFrame",UIParent);AuctionFrame:SetSize(800,600);AuctionFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",20,-20);AuctionFrame:EnableMouse(true);AuctionFrame:SetClampedToScreen(true);AuctionFrame:Hide()
UISpecialFrames={};STANDARD_TEXT_FONT="font.ttf";ChatFontNormal={};SlashCmdList={}
ITEM_QUALITY_COLORS={[1]={r=.9,g=.9,b=.9},[2]={r=.2,g=1,b=.2}}
DEFAULT_CHAT_FRAME={AddMessage=function() end}
function geterrorhandler() return function(e) error(e) end end
function GetRealmName() return "Stitches" end
function UnitFactionGroup() return "Alliance" end
function UnitFullName() return "0xgle","Stitches" end
function UnitName() return "0xgle" end
local money=200000000
function GetMoney() return money end
function InCombatLockdown() return false end
function GetBuildInfo() return "1.15.9","69722","",11509 end
function IsShiftKeyDown() return false end
function hooksecurefunc(a,b,c)
    local target,key,fn
    if type(a)=="string" then target,key,fn=_G,a,b else target,key,fn=a,b,c end
    local old=target[key];assert(type(old)=="function","missing hook "..key)
    target[key]=function(...) local values={old(...)};fn(...);return unpack(values) end
end
local canQuery,canAll=true,true
function CanSendAuctionQuery() return canQuery,canAll end
function QueryAuctionItems(...) calls.query[#calls.query+1]={...} end
local browse,owned={},{}
function GetNumAuctionItems(kind) local rows=kind=="list" and browse or owned;return #rows,kind=="list" and 120 or #rows end
function GetAuctionItemInfo(kind,index)
    local r=(kind=="list" and browse or owned)[index];if not r then return end
    return r.name,"icon",r.count,1,true,1,nil,r.minBid or 100,1,r.buyout,r.bid or 0,false,nil,r.owner,r.owner,r.saleStatus or 0,r.id or 2447,r.complete~=false
end
function GetAuctionItemLink(kind,index) local r=(kind=="list" and browse or owned)[index];return r and (r.link or "item:2447::::::::") end
function GetAuctionItemTimeLeft() return 3 end
function PlaceAuctionBid(...) calls.buy[#calls.buy+1]={...} end
function GetOwnerAuctionItems(...) assert(select("#",...)==0,"GetOwnerAuctionItems takes no arguments");calls.ownerRefresh=(calls.ownerRefresh or 0)+1 end
function CanCancelAuction() return true end
function CancelAuction(...) calls.cancel[#calls.cancel+1]={...} end
function CloseAuctionHouse() calls.closed=(calls.closed or 0)+1;AuctionFrame:Hide();emit("AUCTION_HOUSE_CLOSED") end
local cursor,slot
function GetCursorInfo() if cursor then return "item",2447,"item:2447::::::::" end end
function ClickAuctionSellItemButton() slot={name="Peacebloom",id=2447};cursor=nil end
function GetAuctionSellItemInfo() if slot then return slot.name,"icon",5,1,true,10,2,20,40,slot.id end end
function GetAuctionDeposit(_,_,_,stack,count) return stack*count*5 end
function GetItemInfo() return "Peacebloom","item:2447::::::::",1,1,1,"Trade Goods","Herb",20,nil,"icon" end
function StartAuction(...) calls.post[#calls.post+1]={...} end
ERR_AUCTION_STARTED="Auction created.";ERR_AUCTION_BID_PLACED="Bid accepted.";ERR_AUCTION_REMOVED="Auction cancelled."
local FM={}
for line in io.lines("build/ForeverMarket/ForeverMarket.toc") do if line:match("%.lua$") then assert(loadfile("build/ForeverMarket/"..line))("ForeverMarket",FM) end end
local assertions=0
local function check(value,msg) assertions=assertions+1;assert(value,msg) end
ForeverMarketDB={history={old={{p=999,t=1}}},watchlist={old={name="Old"}},stats={bought=99}}
emit("ADDON_LOADED","ForeverMarket");emit("PLAYER_LOGIN")
check(FM.DB.legacy.history.old~=nil and FM.Data.history.old==nil,"legacy preservation/isolation")
check(FM:ParseMoney("2g 50s 1c")==25001,"money units")
check(FM:ParseMoney("2.5g")==25000,"fractional gold")
check(FM:ParseMoney("1foo")==nil and FM:ParseMoney("-5")==nil,"invalid money rejected")
check(FM:ItemKey("item:123:0:0:0:0:0:-9:42:30")~="item:123","suffix identity preserved")
FM.UI:Show();check(FM.UI.frame:IsShown(),"UI opens")
for _,tab in ipairs({"Market","Deals","Sell","Owned","Shopping","History","Settings"}) do FM.UI:SetTab(tab);check(FM.UI.panels[tab=="Deals" or tab=="Owned" and "Market" or tab]~=false,"tab builds") end
FM.UI:SetTab("Market")
AuctionFrame:Show();emit("AUCTION_HOUSE_SHOW");advance(.1)
check(FM.Native.saved~=nil and AuctionFrame:GetAlpha()==0,"native parked")
check(AuctionFrame:IsShown() and (calls.closed or 0)==0,"native session remains open")
AuctionFrame:SetPoint("CENTER");check(select(4,AuctionFrame:GetPoint())==-10000,"native reposition reparks")
FM.Native:SwitchToBlizzard();check(AuctionFrame:GetAlpha()==1 and not FM.UI.frame:IsShown(),"native restored")
check((calls.closed or 0)==0,"switching does not close session")
FM.UI:Show();FM.UI:Hide();check(calls.closed==1 and not FM.Market.open,"custom close closes session")
AuctionFrame:Show();emit("AUCTION_HOUSE_SHOW");advance(.1)
local function populate(n)
    browse={};for i=1,n do browse[i]={name="Peacebloom",count=5,buyout=500+i*5,owner="Seller"..i} end
end
populate(50)
FM.Market:Search("Peacebloom",0,true);emit("AUCTION_ITEM_LIST_UPDATE");advance(.1)
check(#FM.Market.results==50,"entire page retained")
FM.UI.scroll:SetValue(40);check(FM.UI.rows[10].data~=nil,"all results reachable")
local r=FM.Market.results[1];check(r.unit==101,"unit normalization")
FM.Market:Buy(r);check(#calls.buy==0 and FM.UI.confirmAction,"buy requires confirmation")
browse[1].buyout=999
FM.UI.confirmAccept:Fire("OnClick");check(#calls.buy==0,"changed price refused")
FM.Market:Search("Peacebloom");emit("AUCTION_ITEM_LIST_UPDATE");advance(.1)
r=FM.Market.results[1];FM.Market:Buy(r);FM.UI.confirmAccept:Fire("OnClick")
check(#calls.buy==1 and FM.Market.transaction~=nil,"valid buy sends one action")
check(FM.Data.log[#FM.Data.log].status=="request sent","request not success")
emit("CHAT_MSG_SYSTEM",ERR_AUCTION_BID_PLACED);check(not FM.Market.transaction and FM.Data.log[#FM.Data.log].status=="accepted by server","server confirms")
FM.Market:Buy(r);QueryAuctionItems("foreign");check(not FM.UI.confirmAction and #FM.Market.results==0,"foreign query invalidates confirmation/results")
FM.Market:Buy(r);check(#calls.buy==1 and not FM.UI.confirmAction,"stale row rejected")
canAll=false;local n=#calls.query;FM.Market:FullScan();check(#calls.query==n,"full-scan cooldown respected")
canAll=true;FM.Market:FullScan();emit("AUCTION_ITEM_LIST_UPDATE");advance(.1)
check(not FM.Market.results[1].actionable,"full-scan results cannot be purchased by index")
FM.Market:Buy(FM.Market.results[1]);check(not FM.UI.confirmAction,"full-scan buy refused")
canQuery=false;FM.Market:Search("Peacebloom");local n=#calls.query;advance(.6);check(#calls.query==n,"query throttle respected")
canQuery=true;advance(.3);check(#calls.query==n+1,"queued query dispatched")
emit("AUCTION_ITEM_LIST_UPDATE");advance(.1)
owned={{name="Peacebloom",count=5,buyout=1000,owner="0xgle"}}
local ownerRefreshBefore=calls.ownerRefresh or 0;FM.Market:RefreshOwned();check((calls.ownerRefresh or 0)==ownerRefreshBefore+1,"owner query uses Classic zero-argument API");emit("AUCTION_OWNED_LIST_UPDATE")
check(#FM.Market.owned==1 and FM.Market.ownerPage==0,"owned auctions load without fake server paging")
FM.Market.owned={};FM.Market:RefreshOwned();advance(.4);check(#FM.Market.owned==1 and not FM.Market.ownerLoading,"owned cache fallback works without an update event")
FM.Market:Cancel(FM.Market.owned[1]);check(#calls.cancel==0 and FM.UI.confirmAction,"cancel requires confirmation")
FM.UI.confirmAccept:Fire("OnClick");check(#calls.cancel==1,"cancel dispatched")
emit("CHAT_MSG_SYSTEM",ERR_AUCTION_REMOVED)
FM.UI:SetTab("Sell");cursor=true;FM.Sell:AcceptCursor()
check(FM.Sell.item and FM.Sell.item.total==40,"native sell slot adopted")
FM.UI.sellPrice:SetText("2g");FM.UI.sellStack:SetText("5");FM.UI.sellCount:SetText("2")
local v=FM.Sell:Values();check(v.buyout==100000 and v.deposit==50,"unit/stack/deposit")
FM.UI.sellStack:SetText("100");check(FM.Sell:Values()==nil,"invalid stack rejected")
FM.UI.sellStack:SetText("5");FM.UI.sellFloor:SetText("3g");check(FM.Sell:Values()==nil,"floor enforced")
FM.UI.sellFloor:SetText("1g");FM.Sell:SavePreset();check(FM.Data.presets[FM.Sell.item.key].unit==20000,"preset saved")
FM.Sell:Post();check(#calls.post==0 and FM.UI.confirmAction,"post requires confirmation")
FM.UI.confirmAccept:Fire("OnClick");check(#calls.post==1 and calls.post[1][2]==100000,"post uses price per stack")
local refreshAfterPost=calls.ownerRefresh or 0;emit("CHAT_MSG_SYSTEM",ERR_AUCTION_STARTED);advance(.3);check((calls.ownerRefresh or 0)>refreshAfterPost,"successful post refreshes owned auctions")
FM.Market:BeginTransaction("Purchase",{name="X",count=1},100);advance(13)
check(FM.Data.log[#FM.Data.log].status=="unconfirmed","no false transaction success")
FM.UI:SetTab("Shopping");FM.UI.shopName:SetText("Peacebloom")
for _,f in ipairs(frames) do if f.kind=="Button" and f.label and f.label:GetText()=="Save" then f:Fire("OnClick") end end
check(FM.Data.shopping["raid/peacebloom"]~=nil,"shopping list saved")
FM.UI:SetTab("History");FM.UI:SetTab("Settings")
check(FM.Data.history["item:2447"] and #FM.Data.history["item:2447"]==1,"history coalesces repeated query samples")
FM:After(1,function() end)
-- Render trees exported for layout review using actual Lua frame geometry.
local function q(s) return string.format("%q",tostring(s or "")):gsub("\\\n","\\n") end
function dump(path)
    local file=assert(io.open(path,"w"));file:write("[")
    for i,f in ipairs(frames) do
        local parent=0;for j,p in ipairs(frames) do if p==f.parent then parent=j end end
        local p=f.points[1] or {};local relative=parent;local point=p[1] or "TOPLEFT";local relPoint=point;local x,y=0,0
        if type(p[2])=="table" then for j,obj in ipairs(frames) do if obj==p[2] then relative=j end end;relPoint=p[3];x,y=p[4] or 0,p[5] or 0 else x,y=p[2] or 0,p[3] or 0 end
        local all=0;for j,obj in ipairs(frames) do if obj==f.all then all=j end end
        local function array(t) local parts={};for _,v in ipairs(t or {}) do parts[#parts+1]=tostring(v) end;return "["..table.concat(parts,",").."]" end
        file:write((i>1 and "," or "")..'{"id":'..i..',"parent":'..parent..',"kind":'..q(f.kind)..',"name":'..q(f.nameID)..',"visible":'..tostring(f:IsVisible())..',"w":'..f.w..',"h":'..f.h..',"x":'..x..',"y":'..y..',"point":'..q(point)..',"relPoint":'..q(relPoint)..',"relative":'..relative..',"all":'..all..',"text":'..q(f.text)..',"texture":'..q(f.texture)..',"bg":'..array(f.bg)..',"color":'..array(f.color)..',"border":'..array(f.border)..',"fontSize":'..(f.fontSize or 12)..',"wrap":'..tostring(f.wrap or false)..',"justify":'..q(f.justify)..'}')
    end
    file:write("]");file:close()
end
-- Inventory-first selling: read-only scan and click-only preparation.
local bagData={[0]={},[1]={}}
local herb="item:2447::::::::"
local function bagItem(id,count,extra)
    local d={itemID=id,hyperlink="item:"..id.."::::::::",stackCount=count,iconFileID="icon",quality=1,isBound=false,isLocked=false}
    for k,v in pairs(extra or {}) do d[k]=v end;return d
end
bagData[0][1]=bagItem(2447,5);bagData[1][1]=bagItem(2447,35)
bagData[0][2]=bagItem(10,1,{isBound=true})
bagData[0][3]=bagItem(11,1)
bagData[0][4]=bagItem(12,2,{isLocked=true})
bagData[0][5]=bagItem(13,1,{hasLoot=true})
for i=6,18 do bagData[0][i]=bagItem(3000+i,1) end
local oldGetInfo=GetItemInfo
GetItemInfo=function(query)
    local id=tonumber(tostring(query):match("item:(%d+)")) or tonumber(query)
    if not id or id==2447 then return oldGetInfo() end
    return "Item "..id,"item:"..id.."::::::::",1,1,1,"Trade Goods","Other",20,nil,"icon",1,id==11 and 12 or 7,0,0
end
local picks=0
C_Container={
    GetContainerNumSlots=function(bag) return bagData[bag] and #bagData[bag] or 0 end,
    GetContainerItemInfo=function(bag,pos) return bagData[bag] and bagData[bag][pos] end,
    GetContainerItemQuestInfo=function(bag,pos) local d=bagData[bag] and bagData[bag][pos];return {isQuestItem=d and d.itemID==11} end,
    PickupContainerItem=function(bag,pos) picks=picks+1;local d=bagData[bag][pos];cursor={id=d.itemID,link=d.hyperlink} end,
}
GetCursorInfo=function() if type(cursor)=="table" then return "item",cursor.id,cursor.link elseif cursor then return "item",2447,herb end end
ClearCursor=function() cursor=nil end
ClickAuctionSellItemButton=function()
    local _,id=GetCursorInfo();if id then slot={name=select(1,GetItemInfo(id)),id=id};cursor=nil end
end
FM.UI:SetTab("Sell")
local I=FM.Inventory
check(I.byKey[herb].total==40,"same item aggregated across backpack and bags")
check(I.skipped==3 and not I.byKey["item:10::::::::"] and not I.byKey["item:11::::::::"],"bound/quest/loot items filtered")
check(not I.byKey["item:12::::::::"].available,"locked item disabled")
check(picks==0,"inventory scans never move or sell items")
local postsBefore=#calls.post
local chosen=I.byKey[herb]
I:Select(chosen)
check(picks==1 and FM.Sell.item.name=="Peacebloom","one click loads native sell slot")
check(#calls.post==postsBefore,"selecting an item does not post")
check(FM.UI.sellPrice:GetText()==FM:PlainMoney(20000),"selection prefills saved price")
cursor={id=99,link="item:99::::::::"};I:Select(chosen)
check(picks==1 and cursor.id==99,"occupied cursor preserved")
cursor=nil
I:Select(I.byKey["item:12::::::::"]);check(picks==1,"locked source never picked up")
bagData[0][1].itemID=999;bagData[0][1].hyperlink="item:999::::::::"
I:Select(chosen);check(picks==2 and FM.Sell.item.itemID==2447,"selection reacquires moved matching item")
bagData[1][1]=bagItem(999,1);I:Select(chosen);check(picks==2,"removed item cannot be selected from stale list")
bagData[0][1]=bagItem(2447,5);bagData[1][1]=bagItem(2447,35)
emit("BAG_UPDATE_DELAYED");advance(.2);check(I.byKey[herb].total==40,"bag event automatically refreshes inventory")
I:Select(I.byKey[herb]);FM.UI.sellPrice:SetText("2g");FM.UI.sellFloor:SetText("1g");FM.UI.sellStack:SetText("5");FM.UI.sellCount:SetText("1")
FM.Sell:Post();check(FM.UI.confirmAction and #calls.post==postsBefore,"inventory selection still requires sale confirmation")
emit("BAG_UPDATE_DELAYED");advance(.2);check(FM.UI.confirmAction~=nil,"unchanged bag event preserves pending confirmation")
FM.UI.confirmAccept:Fire("OnClick");check(#calls.post==postsBefore+1,"confirmed inventory sale posts once")
emit("CHAT_MSG_SYSTEM",ERR_AUCTION_STARTED)
FM.UI.bagOffset=9;FM.UI:RefreshInventory();check(FM.UI.bagRows[1].data~=nil,"additional bag pages reachable")
FM.UI.bagSearch:SetText("Peacebloom");check(FM.UI.bagRows[1].data.name=="Peacebloom" and not FM.UI.bagRows[2]:IsShown(),"inventory name filter")
FM.UI.bagSearch:SetText("")
for _,tab in ipairs({"Market","Sell","Shopping","History","Settings"}) do FM.UI:SetTab(tab);dump("build/DeveloperTools/layout-"..tab..".json") end
print("PASS: "..assertions.." assertions; Lua load, all panels, native session, query throttle, stale rows, confirmations, selling and migration.")
