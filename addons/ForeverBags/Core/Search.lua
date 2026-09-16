local _, FB = ...
FB.Search = FB.Search or {}
local Search = FB.Search

local function lower(v) return string.lower(tostring(v or "")) end

function Search:Tokenize(text)
    local tokens = {}
    text = text or ""
    local i, n = 1, #text
    while i <= n do
        while i <= n and text:sub(i,i):match("%s") do i = i + 1 end
        if i > n then break end
        if text:sub(i,i) == '"' then
            local j = text:find('"', i + 1, true) or (n + 1)
            table.insert(tokens, text:sub(i + 1, j - 1))
            i = j + 1
        else
            local j = text:find("%s", i) or (n + 1)
            table.insert(tokens, text:sub(i, j - 1))
            i = j + 1
        end
    end
    return tokens
end

local function compareNumber(actual, expr)
    actual = tonumber(actual) or 0
    local op, num = expr:match("^(>=)(%-?%d+)$")
    if not op then op, num = expr:match("^(<=)(%-?%d+)$") end
    if not op then op, num = expr:match("^(>)(%-?%d+)$") end
    if not op then op, num = expr:match("^(<)(%-?%d+)$") end
    if not op then op, num = expr:match("^(=)(%-?%d+)$") end
    if not op then num = expr:match("^(%-?%d+)$"); op = "=" end
    num = tonumber(num)
    if not num then return true end
    if op == ">=" then return actual >= num end
    if op == "<=" then return actual <= num end
    if op == ">" then return actual > num end
    if op == "<" then return actual < num end
    return actual == num
end

function Search:Matches(item, query)
    if not query or query == "" then return true end
    local hay = table.concat({item.name or "", item.itemType or "", item.itemSubType or "", item.category or "", item.tag or ""}, " "):lower()
    local tokens = self:Tokenize(lower(query))
    for i = 1, #tokens do
        local token = tokens[i]
        local key, value = token:match("^([%a]+):(.*)$")
        if key then
            if key == "q" or key == "quality" then
                local names = {poor=0, common=1, uncommon=2, rare=3, epic=4, legendary=5}
                local wanted = names[value] or tonumber(value)
                if wanted ~= nil and tonumber(item.quality or 0) ~= wanted then return false end
            elseif key == "type" then
                if not (lower(item.itemType):find(value,1,true) or lower(item.itemSubType):find(value,1,true) or lower(item.category):find(value,1,true)) then return false end
            elseif key == "bag" then
                if tostring(item.bag) ~= value then return false end
            elseif key == "count" then
                if not compareNumber(item.count, value) then return false end
            elseif key == "ilvl" then
                if not compareNumber(item.itemLevel, value) then return false end
            elseif key == "fav" then
                local want = value == "1" or value == "true" or value == "yes"
                if item.favorite ~= want then return false end
            elseif key == "new" then
                local want = value == "1" or value == "true" or value == "yes"
                if item.isNew ~= want then return false end
            elseif key == "tag" then
                if lower(item.tag) ~= value then return false end
            elseif key == "id" then
                if tostring(item.itemID) ~= value then return false end
            end
        else
            if not hay:find(token, 1, true) then return false end
        end
    end
    return true
end
