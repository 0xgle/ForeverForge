local _, FB = ...
FB.ItemButton = FB.ItemButton or {}
local IB = FB.ItemButton

-- ForeverBags deliberately keeps Blizzard's own ContainerFrameItemButtonTemplate
-- for live inventory slots. We only change presentation and non-protected tooltip
-- behavior. Click, drag, receive-drag and modified-click scripts are left intact.
IB.liveBySlot = IB.liveBySlot or {}
IB.bagParents = IB.bagParents or {}
IB.staticPool = IB.staticPool or {}

local function NewBackdrop(parent)
    return CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
end

local function SafeHide(region)
    if region and region.Hide then region:Hide() end
end

local function SetupSkin(button)
    if button.fbSkin then return end

    local skin = NewBackdrop(button)
    skin:SetAllPoints(button)
    skin:SetFrameLevel(button:GetFrameLevel() + 8)
    skin:EnableMouse(false)
    skin:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    skin:SetBackdropColor(0.018, 0.025, 0.032, 0.98)
    skin:SetBackdropBorderColor(0.34, 0.38, 0.40, 0.95)

    local icon = skin:CreateTexture(nil, "ARTWORK", nil, 1)
    icon:SetPoint("TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", -4, 4)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local shade = skin:CreateTexture(nil, "ARTWORK", nil, 2)
    shade:SetPoint("TOPLEFT", icon, "TOPLEFT")
    shade:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    shade:SetColorTexture(0, 0, 0, 0)

    local hover = skin:CreateTexture(nil, "OVERLAY", nil, 2)
    hover:SetPoint("TOPLEFT", -1, 1)
    hover:SetPoint("BOTTOMRIGHT", 1, -1)
    hover:SetColorTexture(1, 0.84, 0.42, 0.13)
    hover:Hide()

    local count = skin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    count:SetPoint("BOTTOMRIGHT", -4, 3)
    count:SetJustifyH("RIGHT")
    count:SetTextColor(1, 1, 1)
    count:SetShadowColor(0, 0, 0, 1)
    count:SetShadowOffset(1, -1)

    local itemLevel = skin:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemLevel:SetPoint("TOPLEFT", 4, -3)
    itemLevel:SetTextColor(1, 0.82, 0.30)
    itemLevel:SetShadowColor(0, 0, 0, 1)
    itemLevel:SetShadowOffset(1, -1)

    local badge = skin:CreateTexture(nil, "OVERLAY", nil, 4)
    badge:SetSize(17, 17)
    badge:SetPoint("TOPRIGHT", 3, 3)
    badge:Hide()

    local favorite = skin:CreateTexture(nil, "OVERLAY", nil, 4)
    favorite:SetSize(15, 15)
    favorite:SetPoint("BOTTOMLEFT", -1, -1)
    favorite:SetTexture(FB.Media:Icon("favorite"))
    favorite:SetAlpha(0.20)

    local cooldown = CreateFrame("Cooldown", nil, skin, "CooldownFrameTemplate")
    cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT")
    cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    cooldown:Hide()

    button.fbSkin = skin
    button.fbIcon = icon
    button.fbShade = shade
    button.fbHover = hover
    button.fbCount = count
    button.fbItemLevel = itemLevel
    button.fbBadge = badge
    button.fbFavorite = favorite
    button.fbCooldown = cooldown
end

local function ShowLiveTooltip(button)
    button.fbHover:Show()

    local bag, slot = button.fbBag, button:GetID()
    if bag == nil or not slot or slot <= 0 then return end

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local shown = false
    if GameTooltip.SetBagItem then
        local ok = pcall(GameTooltip.SetBagItem, GameTooltip, bag, slot)
        shown = ok
    end
    if not shown and button.fbItem and button.fbItem.link then
        pcall(GameTooltip.SetHyperlink, GameTooltip, button.fbItem.link)
    end
    if FB.Ownership and button.fbItem then
        FB.Ownership:AddTooltip(GameTooltip, button.fbItem)
    end
    GameTooltip:Show()
end

local function HideTooltip(button)
    if button.fbHover then button.fbHover:Hide() end
    GameTooltip:Hide()
    if ResetCursor then ResetCursor() end
end

local function CreateLive(parent, bag, slot)
    -- This mirrors the working pattern used by established bag addons: the live
    -- slot itself is the Blizzard container item button. There is no proxy button,
    -- no transparent click catcher and no custom OnClick/OnDrag script.
    local name = string.format("ForeverBagsLiveItem_%d_%d", bag, slot)
    local button = CreateFrame("ItemButton", name, parent, "ContainerFrameItemButtonTemplate")
    button.fbLive = true
    button.fbBag = bag
    button.bag = bag
    button:SetID(slot)
    button:Hide()

    -- Disable Blizzard's automatic display refresh only. Keep protected/native
    -- interaction scripts exactly as the template created them.
    button:SetScript("OnEvent", nil)
    button:SetScript("OnShow", nil)

    button.UpdateTooltip = function(self) ShowLiveTooltip(self) end
    button:SetScript("OnEnter", ShowLiveTooltip)
    button:SetScript("OnLeave", HideTooltip)

    SetupSkin(button)

    -- The native template is kept for its click/drag behaviour, but its default
    -- quick-slot artwork must not bleed through the ForeverBags skin. Some
    -- Forever builds expose the stock Normal/Highlight textures differently,
    -- so mute them without replacing the button or any protected scripts.
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal and normal.SetAlpha then normal:SetAlpha(0) end
    local pushed = button.GetPushedTexture and button:GetPushedTexture()
    if pushed and pushed.SetAlpha then pushed:SetAlpha(0) end
    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight and highlight.SetAlpha then highlight:SetAlpha(0) end
    local checked = button.GetCheckedTexture and button:GetCheckedTexture()
    if checked and checked.SetAlpha then checked:SetAlpha(0) end

    -- Cover the remaining stock artwork with our own skin. These are visual
    -- regions only; the Blizzard item-button interaction path stays untouched.
    SafeHide(button.IconBorder)
    SafeHide(button.IconOverlay)
    SafeHide(button.NewItemTexture)
    SafeHide(button.BattlepayItemTexture)
    SafeHide(button.JunkIcon)

    return button
end

local function CreateStatic(parent, index)
    local button = CreateFrame("Button", "ForeverBagsStaticItem" .. tostring(index), parent,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    button.fbLive = false
    button:Hide()
    SetupSkin(button)
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnEnter", function(self)
        self.fbHover:Show()
        local item = self.fbItem
        if not item then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if item.link then
            pcall(GameTooltip.SetHyperlink, GameTooltip, item.link)
        else
            GameTooltip:AddLine(item.name or ("Item " .. tostring(item.itemID or "?")))
        end
        if FB.Ownership then FB.Ownership:AddTooltip(GameTooltip, item) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", HideTooltip)
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton ~= "MiddleButton" or not self.fbItem then return end
        if IsAltKeyDown() then
            local tag = FB:CycleTag(self.fbItem.itemID)
            FB:Print((self.fbItem.name or "Item") .. " -> " .. (tag or "none"))
        else
            FB:ToggleFavorite(self.fbItem.itemID)
        end
    end)
    return button
end

function IB:GetBagParent(root, bag)
    local proxy = self.bagParents[bag]
    if proxy then return proxy end
    if InCombatLockdown and InCombatLockdown() then return nil end

    proxy = CreateFrame("Frame", "ForeverBagsBagProxy" .. tostring(bag), root or UIParent)
    proxy:SetID(bag)
    proxy:SetSize(1, 1)
    proxy:SetPoint("TOPLEFT", root or UIParent, "TOPLEFT", 0, 0)
    proxy:Show()
    self.bagParents[bag] = proxy
    return proxy
end

function IB:GetLive(root, bag, slot)
    local key = tostring(bag) .. ":" .. tostring(slot)
    local button = self.liveBySlot[key]
    if button then return button end
    if InCombatLockdown and InCombatLockdown() then return nil end

    local proxy = self:GetBagParent(root, bag)
    if not proxy then return nil end
    button = CreateLive(proxy, bag, slot)
    self.liveBySlot[key] = button
    return button
end

function IB:GetStatic(parent, index)
    local button = self.staticPool[index]
    if not button then
        button = CreateStatic(parent, index)
        self.staticPool[index] = button
    elseif button:GetParent() ~= parent then
        button:SetParent(parent)
    end
    return button
end

local function UpdateDecoration(button, item)
    button.fbItem = item
    if item then
        button.fbIcon:SetTexture(item.icon)
        button.fbIcon:SetAlpha(1)
    else
        -- Empty live slots stay interactive, but visually remain a clean dark
        -- cell instead of showing a pale frame texture.
        button.fbIcon:SetTexture(nil)
        button.fbIcon:SetAlpha(0)
    end
    button.fbCount:SetText(item and item.count and item.count > 1 and tostring(item.count) or "")
    button.fbItemLevel:SetText(item and item.itemLevel and item.itemLevel > 1 and item.category == "equipment" and tostring(item.itemLevel) or "")

    local quality = item and item.quality or 1
    local c = FB.Media.quality[quality] or FB.Media.quality[1]
    button.fbSkin:SetBackdropBorderColor(c[1], c[2], c[3], item and 0.92 or 0.38)

    button.fbFavorite:SetAlpha(item and item.favorite and 1 or 0.20)
    button.fbBadge:Hide()
    if item then
        if item.tag == "keep" then
            button.fbBadge:SetTexture(FB.Media:Icon("keep")); button.fbBadge:Show()
        elseif item.tag == "sell" then
            button.fbBadge:SetTexture(FB.Media:Icon("sell")); button.fbBadge:Show()
        elseif item.tag == "bank" then
            button.fbBadge:SetTexture(FB.Media:Icon("bank_badge")); button.fbBadge:Show()
        end
    end

    local locked = item and item.locked
    if button.fbIcon.SetDesaturated then button.fbIcon:SetDesaturated(locked and true or false) end
    button:SetAlpha(locked and 0.60 or 1)

    if button.fbCooldown then
        if item and item.live and item.bag ~= nil and item.slot then
            local start, duration, enable = FB.API:GetCooldown(item.bag, item.slot)
            if duration and duration > 0 then
                if CooldownFrame_Set then
                    CooldownFrame_Set(button.fbCooldown, start or 0, duration or 0, enable or 0)
                elseif button.fbCooldown.SetCooldown then
                    button.fbCooldown:SetCooldown(start or 0, duration or 0)
                end
                button.fbCooldown:Show()
            else
                button.fbCooldown:Hide()
            end
        else
            button.fbCooldown:Hide()
        end
    end
end

function IB:SetLive(button, item)
    if not button or not item or item.bag == nil or not item.slot then return end

    -- Bag identity lives on the parent proxy and slot identity is assigned once
    -- when this physical slot button is created. Never rewrite secure identity.
    button.hasItem = item.itemID ~= nil
    button.readable = item.readable and true or false

    -- Keep stock state coherent for Blizzard's own click/drag code. Visuals are
    -- still drawn by the ForeverBags skin on top.
    if SetItemButtonTexture then
        SetItemButtonTexture(button, item.icon or "Interface\\PaperDoll\\UI-Backpack-EmptySlot")
    end
    if SetItemButtonCount then
        SetItemButtonCount(button, item.count or 0)
    end
    if SetItemButtonDesaturated then
        SetItemButtonDesaturated(button, item.locked and true or false)
    end

    UpdateDecoration(button, item)
end

function IB:SetEmpty(button, empty)
    if not button or not empty or empty.bag == nil or not empty.slot then return end

    button.hasItem = false
    button.readable = false

    if SetItemButtonTexture then
        SetItemButtonTexture(button, "Interface\\PaperDoll\\UI-Backpack-EmptySlot")
    end
    if SetItemButtonCount then SetItemButtonCount(button, 0) end
    if SetItemButtonDesaturated then SetItemButtonDesaturated(button, false) end

    UpdateDecoration(button, nil)
end

function IB:SetStatic(button, item)
    if not button then return end
    UpdateDecoration(button, item)
end

function IB:HideAll()
    for _, button in pairs(self.liveBySlot) do button:Hide() end
    for i = 1, #self.staticPool do self.staticPool[i]:Hide() end
end

function IB:Prewarm(parent)
    if InCombatLockdown and InCombatLockdown() then return end
    local bags = FB.API:GetBagRange()
    for i = 1, #bags do
        local bag = bags[i]
        local slots = FB.API:GetNumSlots(bag) or 0
        for slot = 1, slots do
            self:GetLive(parent or UIParent, bag, slot)
        end
    end
end
