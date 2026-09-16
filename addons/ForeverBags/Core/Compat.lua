local _, FB = ...
FB.API = FB.API or {}
local API = FB.API

function API:GetNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    end
    return (GetContainerNumSlots and GetContainerNumSlots(bag)) or 0
end

function API:GetItemInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if not info then return nil end
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
        }
    end
    if GetContainerItemInfo then
        local texture, count, locked, quality, readable, lootable, link, filtered, noValue, itemID = GetContainerItemInfo(bag, slot)
        if not texture then return nil end
        return { icon = texture, count = count or 1, locked = locked, quality = quality, readable = readable, lootable = lootable, link = link, filtered = filtered, noValue = noValue, itemID = itemID }
    end
end

function API:GetItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then return C_Container.GetContainerItemLink(bag, slot) end
    if GetContainerItemLink then return GetContainerItemLink(bag, slot) end
end

function API:PickupItem(bag, slot)
    if C_Container and C_Container.PickupContainerItem then return C_Container.PickupContainerItem(bag, slot) end
    if PickupContainerItem then return PickupContainerItem(bag, slot) end
end

function API:UseItem(bag, slot)
    if C_Container and C_Container.UseContainerItem then return C_Container.UseContainerItem(bag, slot) end
    if UseContainerItem then return UseContainerItem(bag, slot) end
end

function API:IsNewItem(bag, slot)
    if C_NewItems and C_NewItems.IsNewItem then
        local ok, value = pcall(C_NewItems.IsNewItem, bag, slot)
        if ok then return value end
    end
    return false
end

function API:RemoveNewItem(bag, slot)
    if C_NewItems and C_NewItems.RemoveNewItem then pcall(C_NewItems.RemoveNewItem, bag, slot) end
end

function API:GetQuestInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemQuestInfo then
        local q = C_Container.GetContainerItemQuestInfo(bag, slot)
        if q then return q.isQuestItem or q.questID ~= nil, q.questID end
    end
    if GetContainerItemQuestInfo then
        local isQuest, questID, isActive = GetContainerItemQuestInfo(bag, slot)
        return isQuest or isActive, questID
    end
    return false, nil
end

function API:GetItemStatic(itemID, link)
    local query = link or itemID
    local name, itemLink, quality, itemLevel, minLevel, itemType, itemSubType, stackCount, equipLoc, texture, sellPrice, classID, subClassID, bindType, expacID, setID, isCraftingReagent = GetItemInfo(query)
    if not name and GetItemInfoInstant then
        local iid, iType, iSubType, iEquipLoc, icon, iClassID, iSubClassID = GetItemInfoInstant(query)
        return {
            itemID = iid or itemID, name = nil, link = link, quality = nil, itemLevel = nil,
            itemType = iType, itemSubType = iSubType, equipLoc = iEquipLoc, icon = icon,
            sellPrice = 0, classID = iClassID, subClassID = iSubClassID, crafting = false,
        }
    end
    return {
        itemID = itemID, name = name, link = itemLink or link, quality = quality, itemLevel = itemLevel,
        minLevel = minLevel, itemType = itemType, itemSubType = itemSubType, stackCount = stackCount,
        equipLoc = equipLoc, icon = texture, sellPrice = sellPrice or 0, classID = classID,
        subClassID = subClassID, bindType = bindType, expacID = expacID, setID = setID,
        crafting = isCraftingReagent,
    }
end

function API:GetBagRange()
    -- Backpack + equipped bags. Forever may expose more, so probe a few positive bag IDs safely.
    local bags = {0, 1, 2, 3, 4}
    for bag = 5, 8 do
        if self:GetNumSlots(bag) > 0 and not FB.state.bankOpen then
            -- Some clients use IDs >=5 only for bank bags. Outside the bank, ignore them.
        end
    end
    return bags
end

function API:GetBankRange()
    local bags = {-1}
    -- Classic-style bank containers. Empty/unavailable IDs simply report 0 slots.
    for bag = 5, 13 do
        if self:GetNumSlots(bag) > 0 then table.insert(bags, bag) end
    end
    -- Some modern branches expose reagent/account bank IDs as negative enum values. Probe cautiously.
    for _, bag in ipairs({-3, -4, -5}) do
        if self:GetNumSlots(bag) > 0 then table.insert(bags, bag) end
    end
    return bags
end
