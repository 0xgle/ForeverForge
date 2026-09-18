local _, FB = ...
FB.API = FB.API or {}
local API = FB.API

-- Forever currently exposes the modern container namespace, but the same addon
-- should still survive on Classic-style branches. Keep every read behind one
-- compatibility layer and derive bag IDs from Blizzard constants instead of
-- hardcoding a particular expansion layout.
API.BACKPACK = tonumber(BACKPACK_CONTAINER) or 0
API.REGULAR_BAG_MAX = tonumber(NUM_BAG_SLOTS) or 4

local totalEquipped = tonumber(NUM_TOTAL_EQUIPPED_BAG_SLOTS)
if totalEquipped and totalEquipped >= API.REGULAR_BAG_MAX then
    API.PLAYER_BAG_MAX = totalEquipped
else
    API.PLAYER_BAG_MAX = API.REGULAR_BAG_MAX
end

local enumReagent = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
if type(enumReagent) == "number" then
    API.REAGENT_BAG = enumReagent
    API.PLAYER_BAG_MAX = math.max(API.PLAYER_BAG_MAX, enumReagent)
elseif CharacterReagentBag0Slot then
    API.REAGENT_BAG = API.REGULAR_BAG_MAX + 1
    API.PLAYER_BAG_MAX = math.max(API.PLAYER_BAG_MAX, API.REAGENT_BAG)
elseif API.PLAYER_BAG_MAX > API.REGULAR_BAG_MAX then
    API.REAGENT_BAG = API.PLAYER_BAG_MAX
end

local function tryCall(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r = pcall(fn, ...)
    if not ok then return false end
    return true, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r
end

function API:GetNumSlots(bag)
    bag = tonumber(bag)
    if bag == nil then return 0 end

    if C_Container and C_Container.GetContainerNumSlots then
        local ok, value = tryCall(C_Container.GetContainerNumSlots, bag)
        if ok then return tonumber(value) or 0 end
    end

    if GetContainerNumSlots then
        local ok, value = tryCall(GetContainerNumSlots, bag)
        if ok then return tonumber(value) or 0 end
    end

    return 0
end

function API:GetItemInfo(bag, slot)
    bag, slot = tonumber(bag), tonumber(slot)
    if bag == nil or slot == nil then return nil end

    if C_Container and C_Container.GetContainerItemInfo then
        local ok, info = tryCall(C_Container.GetContainerItemInfo, bag, slot)
        if ok and info then
            return {
                icon = info.iconFileID,
                count = info.stackCount or 1,
                locked = info.isLocked,
                quality = info.quality,
                readable = info.isReadable,
                lootable = info.hasLoot,
                link = info.hyperlink,
                filtered = info.isFiltered,
                noValue = info.hasNoValue,
                itemID = info.itemID,
                bound = info.isBound,
                itemName = info.itemName,
            }
        end
        return nil
    end

    if GetContainerItemInfo then
        local ok, texture, count, locked, quality, readable, lootable, link, filtered, noValue, itemID =
            tryCall(GetContainerItemInfo, bag, slot)
        if ok and texture then
            return {
                icon = texture,
                count = count or 1,
                locked = locked,
                quality = quality,
                readable = readable,
                lootable = lootable,
                link = link,
                filtered = filtered,
                noValue = noValue,
                itemID = itemID,
            }
        end
    end
end

function API:GetItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        local ok, link = tryCall(C_Container.GetContainerItemLink, bag, slot)
        if ok then return link end
    end
    if GetContainerItemLink then
        local ok, link = tryCall(GetContainerItemLink, bag, slot)
        if ok then return link end
    end
end

function API:GetQuestInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemQuestInfo then
        local ok, info = tryCall(C_Container.GetContainerItemQuestInfo, bag, slot)
        if ok and info then
            return (info.isQuestItem or info.questID ~= nil) and true or false, info.questID
        end
    end

    if GetContainerItemQuestInfo then
        local ok, isQuest, questID, isActive = tryCall(GetContainerItemQuestInfo, bag, slot)
        if ok then return (isQuest or isActive) and true or false, questID end
    end

    return false, nil
end

function API:IsNewItem(bag, slot)
    if C_NewItems and C_NewItems.IsNewItem then
        local ok, value = tryCall(C_NewItems.IsNewItem, bag, slot)
        if ok then return value and true or false end
    end
    return false
end

function API:RemoveNewItem(bag, slot)
    if C_NewItems and C_NewItems.RemoveNewItem then
        pcall(C_NewItems.RemoveNewItem, bag, slot)
    end
end

function API:IsPlayerContainer(bag)
    bag = tonumber(bag)
    return bag ~= nil and bag >= self.BACKPACK and bag <= self.PLAYER_BAG_MAX
end

function API:GetBagRange()
    local bags = {}
    for bag = self.BACKPACK, self.PLAYER_BAG_MAX do
        bags[#bags + 1] = bag
    end
    return bags
end

function API:GetCooldown(bag, slot)
    bag, slot = tonumber(bag), tonumber(slot)
    if bag == nil or slot == nil then return 0, 0, 0 end

    if C_Container and C_Container.GetContainerItemCooldown then
        local ok, start, duration, enable = tryCall(C_Container.GetContainerItemCooldown, bag, slot)
        if ok then return tonumber(start) or 0, tonumber(duration) or 0, tonumber(enable) or 0 end
    end

    if GetContainerItemCooldown then
        local ok, start, duration, enable = tryCall(GetContainerItemCooldown, bag, slot)
        if ok then return tonumber(start) or 0, tonumber(duration) or 0, tonumber(enable) or 0 end
    end

    return 0, 0, 0
end

function API:GetItemStatic(itemID, link)
    local query = itemID or link
    if not query then
        return {itemID = itemID, link = link, sellPrice = 0, crafting = false}
    end

    local getInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    local getInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant

    local name, itemLink, quality, itemLevel, minLevel, itemType, itemSubType,
          stackCount, equipLoc, texture, sellPrice, classID, subClassID, bindType,
          expacID, setID, isCraftingReagent

    if getInfo then
        local ok
        ok, name, itemLink, quality, itemLevel, minLevel, itemType, itemSubType,
        stackCount, equipLoc, texture, sellPrice, classID, subClassID, bindType,
        expacID, setID, isCraftingReagent = tryCall(getInfo, query)
        if not ok then name = nil end
    end

    if (not name or not classID) and getInstant then
        local ok, iid, iType, iSubType, iEquipLoc, icon, iClassID, iSubClassID = tryCall(getInstant, query)
        if ok then
            itemID = iid or itemID
            itemType = itemType or iType
            itemSubType = itemSubType or iSubType
            equipLoc = equipLoc or iEquipLoc
            texture = texture or icon
            classID = classID or iClassID
            subClassID = subClassID or iSubClassID
        end
    end

    return {
        itemID = itemID,
        name = name,
        link = itemLink or link,
        quality = quality,
        itemLevel = itemLevel,
        minLevel = minLevel,
        itemType = itemType,
        itemSubType = itemSubType,
        stackCount = stackCount,
        equipLoc = equipLoc,
        icon = texture,
        sellPrice = sellPrice or 0,
        classID = classID,
        subClassID = subClassID,
        bindType = bindType,
        expacID = expacID,
        setID = setID,
        crafting = isCraftingReagent or false,
    }
end

-- Bank is intentionally not abstracted by ForeverBags. The native WoW bank UI
-- owns bank browsing and interaction; this prevents bag replacement code from
-- entering modern bank/tab protected paths.
function API:DebugContainers()
    local rows = {
        "api=" .. ((C_Container and "C_Container") or "legacy"),
        "playerMax=" .. tostring(self.PLAYER_BAG_MAX),
        "reagent=" .. tostring(self.REAGENT_BAG or "none"),
    }
    for bag = self.BACKPACK, self.PLAYER_BAG_MAX do
        rows[#rows + 1] = string.format("%d=%d", bag, self:GetNumSlots(bag))
    end
    return table.concat(rows, "  ")
end
