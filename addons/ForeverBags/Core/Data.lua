local _, FB = ...
FB.Data = FB.Data or {}
local Data = FB.Data

local CATEGORY_ORDER = {"equipment", "consumables", "materials", "quest", "misc", "junk"}
Data.categoryOrder = CATEGORY_ORDER

local function CategoryFrom(item)
    if item.isQuest or item.classID == 12 then return "quest" end
    if item.quality == 0 then return "junk" end
    local classID = tonumber(item.classID)
    if classID == 2 or classID == 4 then return "equipment" end
    if classID == 0 then return "consumables" end
    if classID == 3 or classID == 5 or classID == 6 or classID == 7 or classID == 8 or classID == 9 then return "materials" end
    return "misc"
end

function Data:Enrich(item)
    if not item then return nil end
    local static = FB.API:GetItemStatic(item.itemID, item.link)
    for k, v in pairs(static or {}) do if item[k] == nil or item[k] == "" then item[k] = v end end
    item.name = item.name or (item.link and item.link:match("%[(.-)%]")) or ("Item " .. tostring(item.itemID or "?"))
    item.quality = tonumber(item.quality or static.quality) or 1
    item.icon = item.icon or static.icon or 134400
    item.sellPrice = tonumber(item.sellPrice or static.sellPrice) or 0
    item.itemLevel = tonumber(item.itemLevel or static.itemLevel) or 0
    item.favorite = FB:IsFavorite(item.itemID)
    item.tag = FB:GetTag(item.itemID)
    local d = FB.db and FB.db.discoveries and FB.db.discoveries[FB:ItemKey(item.itemID)]
    if d then item.firstSeen = item.firstSeen or d.firstSeen; item.lastSeen = item.lastSeen or d.lastSeen end
    item.category = CategoryFrom(item)
    return item
end

function Data:ScanBags(bagList, source)
    local out, free, total = {}, 0, 0
    for i = 1, #bagList do
        local bag = bagList[i]
        local slots = FB.API:GetNumSlots(bag)
        total = total + slots
        for slot = 1, slots do
            local info = FB.API:GetItemInfo(bag, slot)
            if info and info.itemID then
                local isQuest = FB.API:GetQuestInfo(bag, slot)
                local item = {
                    source = source or "bags", bag = bag, slot = slot, itemID = info.itemID,
                    link = info.link or FB.API:GetItemLink(bag, slot), icon = info.icon, count = info.count or 1,
                    quality = info.quality, locked = info.locked, readable = info.readable, lootable = info.lootable,
                    noValue = info.noValue, bound = info.bound,
                    isQuest = isQuest and true or false, isNew = FB.API:IsNewItem(bag, slot), live = true,
                    order = (#out + 1),
                }
                self:Enrich(item)
                table.insert(out, item)
                if FB.Discoveries then FB.Discoveries:Observe(item) end
            else
                free = free + 1
            end
        end
    end
    return out, free, total
end

function Data:Snapshot(items)
    local snap = {}
    for i = 1, #items do
        local it = items[i]
        table.insert(snap, {
            itemID = it.itemID, link = it.link, icon = it.icon, count = it.count, quality = it.quality,
            bag = it.bag, slot = it.slot, name = it.name, itemType = it.itemType, itemSubType = it.itemSubType,
            classID = it.classID, subClassID = it.subClassID, itemLevel = it.itemLevel, sellPrice = it.sellPrice,
            category = it.category, isQuest = it.isQuest,
        })
    end
    return snap
end

function Data:RestoreSnapshot(snap, source)
    local out = {}
    for i = 1, #(snap or {}) do
        local it = FB:ShallowCopy(snap[i]); it.source = source; it.live = false; it.order = i
        self:Enrich(it); table.insert(out, it)
    end
    return out
end

function Data:GetBags()
    local items, free, total = self:ScanBags(FB.API:GetBagRange(), "bags")
    if FB.char then
        FB.char.inventory = self:Snapshot(items)
        FB.char.money = GetMoney and GetMoney() or 0
        FB.char.lastSeen = FB:Now()
    end
    return items, free, total
end

function Data:GetBank()
    if FB.state.bankOpen then
        local items, free, total = self:ScanBags(FB.API:GetBankRange(), "bank")
        if FB.char then FB.char.bank = self:Snapshot(items); FB.char.bankUpdated = FB:Now() end
        return items, free, total, false
    end
    return self:RestoreSnapshot(FB.char and FB.char.bank, "bank-cache"), 0, 0, true
end

function Data:GetAlts()
    local aggregate, map = {}, {}
    local current = FB:CharacterKey()
    for charKey, char in pairs(FB.db.characters or {}) do
        if charKey ~= current then
            local function addList(list, where)
                for i = 1, #(list or {}) do
                    local src = list[i]
                    local key = FB:ItemKey(src.itemID)
                    local item = map[key]
                    if not item then
                        item = FB:ShallowCopy(src); item.count = 0; item.owners = {}; item.source = "alts"; item.live = false
                        self:Enrich(item); map[key] = item; table.insert(aggregate, item)
                    end
                    local amount = tonumber(src.count) or 1
                    item.count = item.count + amount
                    item.owners[charKey] = (item.owners[charKey] or 0) + amount
                end
            end
            addList(char.inventory, "bags"); addList(char.bank, "bank")
        end
    end
    return aggregate, 0, #aggregate, false
end

function Data:GetDiscoveries()
    local items = {}
    for _, d in pairs(FB.db.discoveries or {}) do
        local it = {
            itemID = d.itemID, link = d.link, icon = d.icon, name = d.name, quality = d.quality,
            count = d.lastCount or 1, firstSeen = d.firstSeen, lastSeen = d.lastSeen, discoveryZone = d.zone,
            discoverySource = d.source, source = "discoveries", live = false,
        }
        self:Enrich(it); table.insert(items, it)
    end
    table.sort(items, function(a,b) return (a.firstSeen or 0) > (b.firstSeen or 0) end)
    return items, 0, #items, false
end

local SORTS = {"slot", "name", "quality", "count", "value"}
function Data:CycleSort()
    local current = FB.settings.sort
    local idx = 1
    for i = 1, #SORTS do if SORTS[i] == current then idx = i break end end
    FB.settings.sort = SORTS[(idx % #SORTS) + 1]
    FB:Fire("FILTER_CHANGED")
end

function Data:Sort(items)
    local mode = FB.settings.sort or "slot"
    table.sort(items, function(a,b)
        if mode == "name" then
            local av,bv = string.lower(a.name or ""), string.lower(b.name or "")
            if av ~= bv then return av < bv end
        elseif mode == "quality" then
            local av,bv = tonumber(a.quality) or 0, tonumber(b.quality) or 0
            if av ~= bv then return av > bv end
        elseif mode == "count" then
            local av,bv = tonumber(a.count) or 0, tonumber(b.count) or 0
            if av ~= bv then return av > bv end
        elseif mode == "value" then
            local av = (tonumber(a.sellPrice) or 0) * (tonumber(a.count) or 1)
            local bv = (tonumber(b.sellPrice) or 0) * (tonumber(b.count) or 1)
            if av ~= bv then return av > bv end
        else
            local ab,bb = tonumber(a.bag) or 999, tonumber(b.bag) or 999
            if ab ~= bb then return ab < bb end
            local as,bs = tonumber(a.slot) or 999, tonumber(b.slot) or 999
            if as ~= bs then return as < bs end
        end
        return (tonumber(a.itemID) or 0) < (tonumber(b.itemID) or 0)
    end)
end

function Data:GetView(view)
    if view == "bank" then return self:GetBank() end
    if view == "alts" then return self:GetAlts() end
    if view == "discoveries" then return self:GetDiscoveries() end
    return self:GetBags()
end

local function ScheduleRefresh()
    FB:Debounce("scan", 0.05, function() FB:Fire("DATA_CHANGED") end)
end
FB:On("BAG_UPDATE_DELAYED", ScheduleRefresh)
FB:On("PLAYERBANKSLOTS_CHANGED", ScheduleRefresh)
FB:On("PLAYERREAGENTBANKSLOTS_CHANGED", ScheduleRefresh)
FB:On("GET_ITEM_INFO_RECEIVED", ScheduleRefresh)
FB:On("ITEM_LOCK_CHANGED", ScheduleRefresh)
FB:On("PLAYER_MONEY", ScheduleRefresh)
FB:On("BANK_OPEN", ScheduleRefresh)
FB:On("BANK_CLOSE", ScheduleRefresh)
FB:On("WORLD", ScheduleRefresh)
FB:On("PLAYER_LOGOUT", function()
    if FB.char then FB.char.lastSeen = FB:Now(); FB.char.money = GetMoney and GetMoney() or FB.char.money end
end)
