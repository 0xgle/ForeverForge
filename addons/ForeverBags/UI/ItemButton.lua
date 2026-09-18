local _, FB = ...
FB.ItemButton = FB.ItemButton or {}
local IB = FB.ItemButton

IB.nativeSlots = IB.nativeSlots or {}
local nativeCounter = 0

local function NewBackdropButton(parent)
    return CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
end

local function SlotKey(bag, slot)
    return tostring(bag) .. ":" .. tostring(slot)
end

local function CreatePhysicalNativeSlot(parent, bag, slot)
    -- ContainerFrameItemButtonTemplate is Blizzard's live bag-slot implementation.
    -- Classic Era 1.15.9 uses the modern shared container UI too. The important
    -- detail is that the template is initialized against a dedicated parent whose
    -- ID is the bag ID, and each physical button is bound to one bag/slot only.
    if InCombatLockdown and InCombatLockdown() then return nil end

    nativeCounter = nativeCounter + 1
    local baseName = "ForeverBagsPhysicalSlot" .. nativeCounter
    local holder = CreateFrame("Frame", baseName .. "Holder", parent or UIParent)
    holder:SetID(bag)
    holder.IsCombinedBagContainer = function() return false end
    holder:SetSize(42, 42)
    holder:Hide()

    local ok, native = pcall(CreateFrame, "ItemButton", baseName, holder, "ContainerFrameItemButtonTemplate")
    if not ok or not native then
        ok, native = pcall(CreateFrame, "Button", baseName, holder, "ContainerFrameItemButtonTemplate")
    end
    if not ok or not native then
        holder:Hide()
        return nil
    end

    native:SetAllPoints(holder)
    native:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    if native.RegisterForDrag then native:RegisterForDrag("LeftButton") end

    -- Classic Era 1.15.9 uses the shared container template, but the exact
    -- initializer differs between branches/addons. Always seed every form of
    -- slot identity Blizzard may consult when handling a click.
    native:SetID(slot)
    native.bagID = bag
    if native.SetBagID then pcall(native.SetBagID, native, bag) end

    if native.Init then
        -- Current shared-UI style used by bag replacements such as
        -- BetterCombinedBag. bankType=0 is the normal character inventory.
        pcall(native.Init, native, bag, slot, 0)
    elseif native.Initialize then
        pcall(native.Initialize, native, bag, slot)
    end

    -- Re-apply after initialization in case the template reset either value.
    native:SetID(slot)
    native.bagID = bag
    if native.SetBagID then pcall(native.SetBagID, native, bag) end

    -- ContainerFrameItemButtonTemplate can be born hidden. 0.9.3 showed only
    -- its holder, then disabled mouse on the ForeverBags visual button. That
    -- left the item looking correct but with no live frame receiving clicks.
    -- Keep Blizzard's button hidden visually via alpha, not via :Hide().
    native:SetAlpha(0.001)
    native:EnableMouse(true)
    native:Hide()

    local record = {holder = holder, native = native, bag = bag, slot = slot, visual = nil}

    native:HookScript("OnEnter", function()
        local visual = record.visual
        if not visual then return end
        visual.hover:SetAlpha(0.85)
        local item = visual.item
        if item and FB.Ownership then
            FB.Ownership:AddTooltip(GameTooltip, item)
            if GameTooltip:IsShown() then GameTooltip:Show() end
        end
    end)
    native:HookScript("OnLeave", function()
        local visual = record.visual
        if visual then visual.hover:SetAlpha(0) end
    end)
    native:HookScript("OnMouseDown", function()
        local visual = record.visual
        local item = visual and visual.item
        if item and item.live then FB.API:RemoveNewItem(item.bag, item.slot) end
    end)

    return record
end

function IB:GetNativeSlot(parent, bag, slot)
    local key = SlotKey(bag, slot)
    local record = self.nativeSlots[key]
    if record then return record end
    record = CreatePhysicalNativeSlot(parent, bag, slot)
    if record then self.nativeSlots[key] = record end
    return record
end

function IB:DetachNative(button)
    local record = button.nativeRecord
    if not record then return end
    if record.visual == button then record.visual = nil end
    record.native:Hide()
    record.holder:Hide()
    record.holder:ClearAllPoints()
    button.nativeRecord = nil
end

function IB:AttachNative(button, item)
    self:DetachNative(button)
    if not item or not item.live or item.bag == nil or not item.slot then return false end

    local record = self:GetNativeSlot(button:GetParent(), item.bag, item.slot)
    if not record then return false end

    -- A physical slot can only be displayed in one place at once.
    if record.visual and record.visual ~= button then
        record.visual.nativeRecord = nil
    end
    record.visual = button
    button.nativeRecord = record

    if record.holder:GetParent() ~= button:GetParent() and not (InCombatLockdown and InCombatLockdown()) then
        record.holder:SetParent(button:GetParent())
    end
    record.holder:ClearAllPoints()
    record.holder:SetAllPoints(button)
    record.holder:SetFrameLevel(button:GetFrameLevel() + 20)

    -- The physical Blizzard button itself must be shown. Showing only its
    -- holder is not sufficient when the inherited template starts hidden.
    record.native:SetID(item.slot)
    record.native.bagID = item.bag
    if record.native.SetBagID then pcall(record.native.SetBagID, record.native, item.bag) end
    record.native:SetAlpha(0.001)
    record.native:EnableMouse(true)
    record.native:Show()
    record.holder:Show()
    return true
end

function IB:PrewarmInventory()
    if InCombatLockdown and InCombatLockdown() then return end
    local parent = FB.scrollChild or UIParent
    for bag = 0, (tonumber(NUM_BAG_SLOTS) or 4) do
        -- 40 covers current Classic Era bag capacities and prevents dynamic
        -- secure-template allocation when bag contents change during combat.
        for slot = 1, 40 do
            self:GetNativeSlot(parent, bag, slot)
        end
    end
end

function IB:PrewarmBank()
    if InCombatLockdown and InCombatLockdown() then return end
    local parent = FB.scrollChild or UIParent
    local bags = FB.API:GetBankRange()
    for i = 1, #bags do
        local bag = bags[i]
        local slots = math.max(FB.API:GetNumSlots(bag), bag == -1 and 28 or 0)
        for slot = 1, slots do self:GetNativeSlot(parent, bag, slot) end
    end
end

function IB:Create(parent)
    local b = NewBackdropButton(parent)
    b:SetSize(FB.settings and FB.settings.iconSize or 42, FB.settings and FB.settings.iconSize or 42)
    -- Clean, standard item slot. Rarity is communicated by the thin border only;
    -- the previous decorative frame/new-item glow made every item look highlighted.
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    b:SetBackdropColor(0.02,0.027,0.033,1)
    b:SetBackdropBorderColor(0.4,0.4,0.4,0.9)

    -- Intentionally do not create the old slot_frame texture here.
    -- That artwork contains the cyan bloom seen in older releases.
    -- Regular slots are now only the dark backdrop + thin rarity border.

    b.icon = b:CreateTexture(nil, "ARTWORK", nil, 1)
    b.icon:SetPoint("TOPLEFT", 5, -5)
    b.icon:SetPoint("BOTTOMRIGHT", -5, 5)
    b.icon:SetTexCoord(0.07,0.93,0.07,0.93)

    -- A border-only highlight keeps the real item artwork visible on hover.
    b.hover = CreateFrame("Frame", nil, b, BackdropTemplateMixin and "BackdropTemplate" or nil)
    b.hover:EnableMouse(false)
    b.hover:SetPoint("TOPLEFT", -1, 1)
    b.hover:SetPoint("BOTTOMRIGHT", 1, -1)
    b.hover:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    b.hover:SetBackdropBorderColor(1,0.9,0.65,1)
    b.hover:SetAlpha(0)

    b.count = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.count:SetPoint("BOTTOMRIGHT", -4, 4)
    b.count:SetJustifyH("RIGHT")
    b.count:SetTextColor(1,1,1)
    b.count:SetShadowColor(0,0,0,1); b.count:SetShadowOffset(1,-1)

    b.itemLevel = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.itemLevel:SetPoint("TOPLEFT", 4, -3)
    b.itemLevel:SetTextColor(1,0.82,0.3)

    b.badge = b:CreateTexture(nil, "OVERLAY")
    b.badge:SetSize(18,18)
    b.badge:SetPoint("TOPRIGHT", 4, 4)
    b.badge:Hide()

    b.metaButton = CreateFrame("Button", nil, b)
    b.metaButton:SetSize(17,17)
    b.metaButton:SetPoint("BOTTOMLEFT", -2, -1)
    b.metaButton:SetFrameLevel(b:GetFrameLevel() + 50)
    b.metaButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b.favorite = b.metaButton:CreateTexture(nil, "OVERLAY")
    b.favorite:SetAllPoints()
    b.favorite:SetTexture(FB.Media:Icon("favorite"))
    b.favorite:SetAlpha(0.22)
    b.metaButton:SetScript("OnEnter", function(self)
        b.favorite:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("ForeverBags", 1, 0.82, 0.35)
        GameTooltip:AddLine("Left-click: favorite", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click: cycle Keep / Sell / Bank", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    b.metaButton:SetScript("OnLeave", function()
        b.favorite:SetAlpha((b.item and b.item.favorite) and 1 or 0.22)
        GameTooltip:Hide()
    end)
    b.metaButton:SetScript("OnClick", function(_, mouseButton)
        if not b.item then return end
        if mouseButton == "LeftButton" then
            FB:ToggleFavorite(b.item.itemID)
        elseif mouseButton == "RightButton" then
            local tag = FB:CycleTag(b.item.itemID)
            FB:Print((b.item.name or "Item") .. " → " .. (tag or "none"))
        end
    end)

    -- No permanent new-item texture is created. New-item state remains data-only
    -- for Recent/search filtering, so it cannot accidentally tint every slot blue.

    b:SetScript("OnEnter", function(self)
        self.hover:SetAlpha(0.85)
        IB:OnEnter(self)
    end)
    b:SetScript("OnLeave", function(self)
        self.hover:SetAlpha(0)
        GameTooltip:Hide()
    end)
    b:RegisterForClicks("AnyUp")
    b:SetScript("OnClick", function(self, mouseButton)
        IB:OnVisualClick(self, mouseButton)
    end)
    b:HookScript("OnHide", function(self) IB:DetachNative(self) end)

    return b
end

function IB:SetItem(button, item)
    button.item = item
    button.icon:SetTexture(item.icon or 134400)
    button.count:SetText((item.count and item.count > 1) and tostring(item.count) or "")
    button.itemLevel:SetText((item.itemLevel and item.itemLevel > 1 and item.category == "equipment") and tostring(item.itemLevel) or "")
    local c = FB.Media.quality[item.quality or 1] or FB.Media.quality[1]
    button:SetBackdropBorderColor(c[1],c[2],c[3],1)
    button.favorite:Show()
    button.favorite:SetAlpha(item.favorite and 1 or 0.22)
    button.badge:Hide()
    if item.tag == "keep" then
        button.badge:SetTexture(FB.Media:Icon("keep")); button.badge:Show()
    elseif item.tag == "sell" then
        button.badge:SetTexture(FB.Media:Icon("sell")); button.badge:Show()
    elseif item.tag == "bank" then
        button.badge:SetTexture(FB.Media:Icon("bank_badge")); button.badge:Show()
    end
    button.icon:SetDesaturated(item.locked and true or false)
    button:SetAlpha(item.locked and 0.6 or 1)

    local native = self:AttachNative(button, item)
    button:EnableMouse(not native)
    button.metaButton:EnableMouse(true)
    button.metaButton:SetFrameLevel(button:GetFrameLevel() + 50)
end

function IB:OnEnter(button)
    local item = button.item
    if not item then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local shown = false
    if item.live and item.bag ~= nil and item.slot and GameTooltip.SetBagItem then
        local ok = pcall(GameTooltip.SetBagItem, GameTooltip, item.bag, item.slot)
        shown = ok
    end
    if not shown and item.link then pcall(GameTooltip.SetHyperlink, GameTooltip, item.link) end
    if not item.link then GameTooltip:AddLine(item.name or ("Item "..tostring(item.itemID or "?"))) end
    if FB.Ownership then FB.Ownership:AddTooltip(GameTooltip, item) end
    GameTooltip:Show()
end

function IB:OnVisualClick(button, mouseButton)
    local item = button.item
    if not item then return end
    if mouseButton == "MiddleButton" then
        if IsAltKeyDown() then
            local tag = FB:CycleTag(item.itemID)
            FB:Print((item.name or "Item") .. " → " .. (tag or "none"))
        else
            FB:ToggleFavorite(item.itemID)
        end
        return
    end
    if not item.live then return end
    if IsShiftKeyDown() and item.link and HandleModifiedItemClick then
        if HandleModifiedItemClick(item.link) then return end
    end
    if not IB._warnedNoNative then
        IB._warnedNoNative = true
        FB:Print("Native bag slot was unavailable. Live item actions stay disabled rather than using a tainted direct container call.")
    end
end

FB:On("LOGIN", function()
    C_Timer.After(0, function() IB:PrewarmInventory() end)
end)
FB:On("BANK_OPEN", function()
    C_Timer.After(0, function() IB:PrewarmBank() end)
end)
FB:On("PLAYER_REGEN_ENABLED", function()
    IB:PrewarmInventory()
    if FB.state.bankOpen then IB:PrewarmBank() end
end)
