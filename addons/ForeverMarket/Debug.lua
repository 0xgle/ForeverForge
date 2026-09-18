local _, FM = ...

local D = {
    entries = {},
    maxEntries = 700,
    enabled = true,
    seq = 0,
}
FM.Debug = D

local function now()
    if GetTime then return GetTime() end
    return 0
end

local function bool(v)
    if v == nil then return "nil" end
    return v and "true" or "false"
end

local function scalar(v)
    local t = type(v)
    if t == "nil" then return "nil" end
    if t == "string" then
        v = v:gsub("\n", "\\n")
        if #v > 180 then v = v:sub(1, 177).."..." end
        return '"'..v..'"'
    end
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "table" then
        local parts, n = {}, 0
        for k, x in pairs(v) do
            n = n + 1
            if n > 14 then parts[#parts+1] = "..." break end
            local xt = type(x)
            if xt == "string" or xt == "number" or xt == "boolean" or xt == "nil" then
                parts[#parts+1] = tostring(k).."="..scalar(x)
            end
        end
        return "{"..table.concat(parts, ",").."}"
    end
    return "<"..t..":"..tostring(v)..">"
end

function D:Log(tag, ...)
    if not self.enabled then return end
    self.seq = self.seq + 1
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts+1] = scalar(select(i, ...))
    end
    local line = string.format("%04d  %8.3f  %-25s %s", self.seq, now(), tostring(tag or "LOG"), table.concat(parts, " | "))
    self.entries[#self.entries+1] = line
    if #self.entries > self.maxEntries then table.remove(self.entries, 1) end
    if self.window and self.window:IsShown() then self:RefreshWindow() end
end

function D:Separator(name)
    self:Log("==========", name or "SESSION", "==========")
end

function D:Clear()
    wipe(self.entries)
    self.seq = 0
    self:Log("DEBUG", "log cleared")
end

local function safeCall(label, fn, ...)
    if type(fn) ~= "function" then return "<missing>" end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return "<error:"..tostring(a)..">" end
    local out = { scalar(a), scalar(b), scalar(c), scalar(d) }
    return label.."="..table.concat(out, ",")
end

function D:SnapshotSell(stage)
    self:Separator("SELL SNAPSHOT: "..tostring(stage or "unknown"))
    local build, patch, date, toc = GetBuildInfo()
    self:Log("CLIENT", "build="..tostring(build), "patch="..tostring(patch), "toc="..tostring(toc), "project="..tostring(WOW_PROJECT_ID), "mainline="..tostring(WOW_PROJECT_MAINLINE))
    self:Log("BACKEND", "backend="..tostring(FM:AuctionBackend()), "marketOpen="..bool(FM.Market and FM.Market.open), "ahFrame="..bool(AuctionHouseFrame ~= nil), "ahShown="..bool(AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown()))

    if C_AuctionHouse then
        self:Log("AH_STATE",
            safeCall("throttleReady", C_AuctionHouse.IsThrottledMessageSystemReady),
            safeCall("supportsCopper", C_AuctionHouse.SupportsCopperValues))
    end

    local S = FM.Sell
    local item = S and S.item
    if not item then
        self:Log("SELL_ITEM", "nil")
        return
    end

    self:Log("SELL_ITEM",
        "name="..tostring(item.name), "id="..tostring(item.itemID), "bag="..tostring(item.bag), "slot="..tostring(item.slot),
        "total="..tostring(item.total), "count="..tostring(item.count), "maxStack="..tostring(item.maxStack),
        "isCommodity="..bool(item.isCommodity), "resolvingCommodity="..bool(item.resolvingCommodity), "link="..tostring(item.link))

    local location = item.location
    self:Log("LOCATION", "stored="..bool(location ~= nil), "value="..tostring(location))

    if C_Container and type(C_Container.GetContainerItemInfo) == "function" then
        local ok, info = pcall(C_Container.GetContainerItemInfo, item.bag, item.slot)
        self:Log("BAG_INFO", "ok="..bool(ok), info)
    end

    if location and C_Item then
        if type(C_Item.DoesItemExist) == "function" then self:Log("ITEM_EXISTS", safeCall("exists", C_Item.DoesItemExist, location)) end
        if type(C_Item.IsBound) == "function" then self:Log("ITEM_BOUND", safeCall("bound", C_Item.IsBound, location)) end
    end

    local key
    if C_AuctionHouse and type(C_AuctionHouse.MakeItemKey) == "function" and item.itemID then
        local ok, k = pcall(C_AuctionHouse.MakeItemKey, item.itemID)
        if ok then key = k end
        self:Log("ITEM_KEY", "ok="..bool(ok), k)
    end
    if key and C_AuctionHouse and type(C_AuctionHouse.GetItemKeyInfo) == "function" then
        local ok, info = pcall(C_AuctionHouse.GetItemKeyInfo, key)
        self:Log("ITEM_KEY_INFO", "ok="..bool(ok), info)
    end

    if location and C_AuctionHouse then
        if type(C_AuctionHouse.GetItemCommodityStatus) == "function" then
            self:Log("COMMODITY_STATUS", safeCall("status", C_AuctionHouse.GetItemCommodityStatus, location))
        end
        if type(C_AuctionHouse.GetAvailablePostCount) == "function" then
            self:Log("POST_COUNT", safeCall("available", C_AuctionHouse.GetAvailablePostCount, location))
        end
        if type(C_AuctionHouse.IsSellItemValid) == "function" then
            self:Log("SELL_VALID", safeCall("validFalse", C_AuctionHouse.IsSellItemValid, location, false), safeCall("validTrue", C_AuctionHouse.IsSellItemValid, location, true))
        end
    end

    if S and type(S.Values) == "function" then
        local ok, v, err = pcall(S.Values, S)
        self:Log("FORM_VALUES", "ok="..bool(ok), v, err)
    end

    if AuctionHouseFrame then
        local isf = AuctionHouseFrame.ItemSellFrame
        local csf = AuctionHouseFrame.CommoditiesSellFrame
        self:Log("NATIVE_SELL_FRAMES",
            "itemFrame="..bool(isf ~= nil), "itemShown="..bool(isf and isf.IsShown and isf:IsShown()), "itemCachePending="..bool(isf and type(isf.CachePendingPost)=="function"),
            "commodityFrame="..bool(csf ~= nil), "commodityShown="..bool(csf and csf.IsShown and csf:IsShown()), "commodityCachePending="..bool(csf and type(csf.CachePendingPost)=="function"))
    end
end

function D:RefreshWindow()
    if not self.edit then return end
    local text = table.concat(self.entries, "\n")
    self.edit:SetText(text)
    self.edit:SetCursorPosition(#text)
end

local function makeButton(parent, text, width, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 90, 24)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.13, 0.15, 0.18, 0.98)
    local border = b:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1); border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.35, 0.40, 0.46, 0.7)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER"); fs:SetText(text)
    b:SetScript("OnEnter", function() bg:SetColorTexture(0.20, 0.23, 0.28, 0.98) end)
    b:SetScript("OnLeave", function() bg:SetColorTexture(0.13, 0.15, 0.18, 0.98) end)
    b:SetScript("OnClick", onClick)
    return b
end

function D:CreateWindow()
    if self.window then return self.window end
    local f = CreateFrame("Frame", "ForeverMarketDebugFrame", UIParent)
    f:SetSize(860, 560)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(0.035, 0.045, 0.06, 0.98)
    local top = f:CreateTexture(nil, "ARTWORK")
    top:SetPoint("TOPLEFT", 1, -1); top:SetPoint("TOPRIGHT", -1, -1); top:SetHeight(36)
    top:SetColorTexture(0.08, 0.10, 0.13, 1)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -11)
    title:SetText("ForeverMarket AH Debugger")

    local close = makeButton(f, "X", 30, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", -7, -7)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -48)
    scroll:SetPoint("BOTTOMRIGHT", -32, 48)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal or GameFontHighlightSmall)
    edit:SetWidth(800)
    edit:SetTextInsets(5, 5, 5, 5)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self)
        local h = math.max(430, (self.GetStringHeight and self:GetStringHeight() or 430) + 20)
        self:SetHeight(h)
    end)
    scroll:SetScrollChild(edit)
    self.edit = edit

    local clear = makeButton(f, "Clear", 75, function() D:Clear(); D:RefreshWindow() end)
    clear:SetPoint("BOTTOMLEFT", 14, 12)
    local snap = makeButton(f, "Snapshot", 90, function() D:SnapshotSell("manual"); D:RefreshWindow() end)
    snap:SetPoint("LEFT", clear, "RIGHT", 8, 0)
    local selectAll = makeButton(f, "Select all", 90, function()
        D:RefreshWindow(); edit:SetFocus(); edit:HighlightText(); FM:Print("Debug log selected. Press Ctrl+C, then paste it into ChatGPT.")
    end)
    selectAll:SetPoint("LEFT", snap, "RIGHT", 8, 0)
    local enabled = makeButton(f, "Logging: ON", 110, function(btn)
        D.enabled = not D.enabled
        -- Custom button uses an anonymous font string, so just log state and leave label static.
        D:Log("DEBUG", "logging="..bool(D.enabled))
        FM:Print("ForeverMarket debug logging: "..(D.enabled and "ON" or "OFF"))
    end)
    enabled:SetPoint("LEFT", selectAll, "RIGHT", 8, 0)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMRIGHT", -14, 18)
    hint:SetText("After one failed Post: Snapshot -> Select all -> Ctrl+C")

    self.window = f
    self:RefreshWindow()
    return f
end

function D:Toggle()
    local f = self:CreateWindow()
    if f:IsShown() then f:Hide() else self:RefreshWindow(); f:Show() end
end

-- Log all status changes without changing the runtime behaviour.
local originalStatus = FM.Status
FM.Status = function(self, text)
    if D then D:Log("STATUS", tostring(text)) end
    return originalStatus(self, text)
end

-- Dedicated event recorder. Unknown Forever events are simply skipped.
local eventFrame = CreateFrame("Frame")
local events = {
    "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED",
    "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED", "AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED",
    "AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED", "AUCTION_HOUSE_THROTTLED_MESSAGE_SENT",
    "AUCTION_HOUSE_THROTTLED_SYSTEM_READY",
    "OWNED_AUCTIONS_UPDATED", "NEW_AUCTION_UPDATE", "AUCTION_CANCELED",
    "AUCTION_MULTISELL_START", "AUCTION_MULTISELL_UPDATE", "AUCTION_MULTISELL_FAILURE",
    "AUCTION_HOUSE_POST_ERROR", "AUCTION_HOUSE_POST_WARNING", "AUCTION_HOUSE_SHOW_ERROR",
    "ITEM_SEARCH_RESULTS_UPDATED", "COMMODITY_SEARCH_RESULTS_UPDATED", "ITEM_KEY_ITEM_INFO_RECEIVED",
    "COMMODITY_PRICE_UPDATED", "COMMODITY_PRICE_UNAVAILABLE", "COMMODITY_PURCHASE_SUCCEEDED", "COMMODITY_PURCHASE_FAILED",
    "BAG_UPDATE_DELAYED", "PLAYER_MONEY", "UI_ERROR_MESSAGE",
    "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "MACRO_ACTION_BLOCKED", "MACRO_ACTION_FORBIDDEN",
}
for _, event in ipairs(events) do
    local ok = pcall(eventFrame.RegisterEvent, eventFrame, event)
    if not ok then D:Log("EVENT_UNSUPPORTED", event) end
end
eventFrame:SetScript("OnEvent", function(_, event, ...)
    D:Log("EVENT:"..event, ...)
    if event == "AUCTION_HOUSE_SHOW" then D:Separator("AUCTION HOUSE OPEN") end
    if event == "AUCTION_HOUSE_CLOSED" then D:Separator("AUCTION HOUSE CLOSED") end
end)

SLASH_FOREVERMARKETDEBUG1 = "/fmdebug"
SlashCmdList.FOREVERMARKETDEBUG = function(msg)
    msg = tostring(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "clear" then D:Clear(); D:RefreshWindow(); D:CreateWindow():Show()
    elseif msg == "snap" or msg == "snapshot" then D:SnapshotSell("slash"); D:CreateWindow():Show()
    elseif msg == "off" then D.enabled=false; FM:Print("ForeverMarket debug logging: OFF")
    elseif msg == "on" then D.enabled=true; D:Log("DEBUG", "logging enabled"); FM:Print("ForeverMarket debug logging: ON")
    else D:Toggle() end
end

D:Log("DEBUG_BOOT", "ForeverMarket="..tostring(FM.version), "debug7")
