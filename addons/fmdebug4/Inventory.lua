local _,FM=...
local I={items={},byKey={}};FM.Inventory=I

-- Forever can expose container APIs from the modern client while omitting the
-- legacy global GetItemInfo alias. Keep this compatibility local to inventory
-- so the proven Marketplace/UI startup path remains untouched.
local function GetItemInfoCompat(item)
    if type(_G.GetItemInfo)=="function" then
        local ok,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q=pcall(_G.GetItemInfo,item)
        if ok and a~=nil then return a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q end
    end
    if C_Item and type(C_Item.GetItemInfo)=="function" then
        local ok,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q=pcall(C_Item.GetItemInfo,item)
        if ok then return a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q end
    end
    return nil
end

local function RequestItemData(item)
    if not (C_Item and type(C_Item.RequestLoadItemDataByID)=="function") then return end
    local id=type(item)=="number" and item or tonumber(tostring(item or ""):match("item:(%d+)"))
    if id then pcall(C_Item.RequestLoadItemDataByID,id) end
end
function I:Info(bag,slot)
    local info
    if C_Container and C_Container.GetContainerItemInfo then info=C_Container.GetContainerItemInfo(bag,slot)
    elseif GetContainerItemInfo then
        local icon,count,locked,quality,_,loot,link,_,noValue,id=GetContainerItemInfo(bag,slot)
        if icon then info={iconFileID=icon,stackCount=count,isLocked=locked,quality=quality,hyperlink=link,itemID=id,hasLoot=loot,hasNoValue=noValue} end
    end
    if not info or not info.hyperlink then return nil end
    local name,link,quality,_,_,_,_,maxStack,_,texture,_,classID,_,bindType=GetItemInfoCompat(info.hyperlink)
    if not name then
        RequestItemData(info.itemID or info.hyperlink)
        return nil,"uncached"
    end
    local bound=info.isBound
    if bound==nil and C_Item and type(C_Item.IsBound)=="function" and ItemLocation and type(ItemLocation.CreateFromBagAndSlot)=="function" then
        local okLoc,loc=pcall(ItemLocation.CreateFromBagAndSlot,ItemLocation,bag,slot)
        if okLoc and loc then
            local okBound,isBound=pcall(C_Item.IsBound,loc)
            if okBound then bound=isBound end
        end
    end
    local quest=classID==12 or bindType==4
    if C_Container and C_Container.GetContainerItemQuestInfo then
        local q=C_Container.GetContainerItemQuestInfo(bag,slot);quest=quest or (q and q.isQuestItem)
    end
    if bound or quest or info.hasLoot or bindType==1 then return nil,"excluded" end
    return {name=name,link=info.hyperlink,itemID=info.itemID,texture=info.iconFileID or texture,quality=quality or info.quality or 1,
        count=info.stackCount or 1,locked=info.isLocked,bag=bag,slot=slot,maxStack=maxStack or 1,
        inventoryKey=info.hyperlink,key=FM:ItemKey(info.hyperlink,name)}
end
function I:Scan()
    local groups={};local skipped,uncached=0,0
    local slots=C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    if not slots then return end
    -- Only backpack and equipped bags: no bank/equipment/keyring.
    for bag=0,4 do
        for slot=1,(slots(bag) or 0) do
            local item,reason=self:Info(bag,slot)
            if item then
                local row=groups[item.inventoryKey]
                if not row then row=item;row.total=0;row.sources={};row.available=false;groups[item.inventoryKey]=row end
                row.total=row.total+item.count;row.sources[#row.sources+1]={bag=bag,slot=slot}
                if not item.locked then row.available=true end
            elseif reason=="uncached" then uncached=uncached+1 elseif reason then skipped=skipped+1 end
        end
    end
    self.items={};self.byKey=groups;self.skipped=skipped;self.uncached=uncached
    for _,r in pairs(groups) do self.items[#self.items+1]=r end
    table.sort(self.items,function(a,b) if a.name==b.name then return a.inventoryKey<b.inventoryKey end;return a.name<b.name end)
    if FM.Ledger then FM.Ledger:CaptureBags() end
    if FM.UI and FM.UI.bagRows then FM.UI:RefreshInventory() end
end
function I:Schedule()
    if self.scheduled then return end
    self.scheduled=true
    FM:After(.15,function()
        I.scheduled=false
        if FM.UI and FM.UI.frame and FM.UI.frame:IsShown() and FM.UI.activeTab=="Sell" then
            I:Scan()
            if FM.Market.open then FM.Sell:ReadSlot() end
        end
    end)
end
function I:Select(row)
    if not FM.Market:Ready() or not row then return end
    if GetCursorInfo() then FM:Status("Put down the item on your cursor first.");return end
    local pickup=C_Container and C_Container.PickupContainerItem or PickupContainerItem
    if not pickup then FM:Status("Bag API is unavailable in this client.");return end
    self:Scan();local current=self.byKey[row.inventoryKey]
    if not current then FM:Status("This item is no longer in your bags.");return end
    local source
    for _,s in ipairs(current.sources) do
        local live=self:Info(s.bag,s.slot)
        if live and not live.locked and live.inventoryKey==row.inventoryKey then source=live;break end
    end
    if not source then FM:Status("This item is temporarily locked. Try again.");return end
    FM.UI:DismissConfirm()
    if FM:IsModernAH() and FM.Sell and FM.Sell.SelectLocation then
        self.selectedKey=source.inventoryKey
        FM.Sell:SelectLocation(source.bag,source.slot,source)
        self:Scan();FM.UI:RefreshSell()
        return
    end
    local ok,err=pcall(pickup,source.bag,source.slot)
    if not ok then FM:Status(tostring(err));return end
    local kind,_,link=GetCursorInfo()
    if kind~="item" or link~=source.link then
        if kind and ClearCursor then ClearCursor() end
        FM:Status("Your bags have changed. Select the item again.");self:Scan();return
    end
    FM.Sell:AcceptCursor()
    if GetCursorInfo() and ClearCursor then ClearCursor() end
    if FM.Sell.item and FM.Sell.item.link==source.link then
        self.selectedKey=source.inventoryKey
        if not FM.Data.presets[FM.Sell.item.key] then FM.Sell:Suggest(true) end
        FM:Status("Selected "..source.name..". Check the price and confirm posting.")
    end
    self:Scan();FM.UI:RefreshSell()
end
FM:On("BAG_UPDATE_DELAYED",function() I:Schedule() end)
FM:On("ITEM_LOCK_CHANGED",function() I:Schedule() end)
FM:On("GET_ITEM_INFO_RECEIVED",function() I:Schedule() end)
FM:On("ITEM_DATA_LOAD_RESULT",function() I:Schedule() end)
FM:On("AUCTION_HOUSE_SHOW",function() I:Scan() end)
FM:On("AUCTION_HOUSE_CLOSED",function() I.selectedKey=nil end)
