local _, FMH = ...
FMH.Engine = FMH.Engine or {}
local E = FMH.Engine

function E:GetCounts()
    if not GetNumMacros then return 0,0 end
    local a,b = GetNumMacros()
    return tonumber(a) or 0, tonumber(b) or 0
end

function E:GetIndex(macro)
    if not macro or not GetMacroIndexByName then return 0 end
    return GetMacroIndexByName(macro.macroName) or 0
end

function E:IsInstalled(macro)
    local idx = self:GetIndex(macro)
    if idx and idx > 0 and GetMacroInfo then
        local name, _, body = GetMacroInfo(idx)
        return name == macro.macroName, body
    end
    return false, nil
end

function E:Icon()
    return 134400 -- INV_Misc_QuestionMark; accepted as iconFileID by current macro API.
end

function E:Install(macro, overrideBody)
    if not macro then return false, "No macro selected." end
    if not FMH:CanModifyMacros() then return false, "Macros cannot be changed during combat." end
    if type(CreateMacro) ~= "function" or type(EditMacro) ~= "function" then return false, "Macro API is unavailable on this client." end
    local body = tostring(overrideBody or macro.body or "")
    if #body > 255 then return false, "Macro body is longer than 255 characters." end
    local idx = self:GetIndex(macro)
    local ok, result
    if idx and idx > 0 then
        ok, result = pcall(EditMacro, idx, macro.macroName, self:Icon(), body)
        if not ok then return false, tostring(result) end
        FMH.db.installed[macro.id] = { name=macro.macroName, updated=time and time() or 0 }
        FMH:Fire("MACROS_CHANGED")
        return true, "updated"
    end
    ok, result = pcall(CreateMacro, macro.macroName, self:Icon(), body, true)
    if not ok or not result then
        -- Some legacy Classic builds were more permissive with texture names than file IDs.
        ok, result = pcall(CreateMacro, macro.macroName, "INV_Misc_QuestionMark", body, true)
    end
    if not ok or not result then return false, "Could not create macro. Your character macro slots may be full." end
    FMH.db.installed[macro.id] = { name=macro.macroName, created=time and time() or 0 }
    FMH:Fire("MACROS_CHANGED")
    return true, "created"
end

function E:Delete(macro)
    if not macro or not FMH:CanModifyMacros() then return false end
    local idx = self:GetIndex(macro)
    if not idx or idx <= 0 or type(DeleteMacro) ~= "function" then return false end
    local ok = pcall(DeleteMacro, idx)
    if ok then FMH.db.installed[macro.id]=nil; FMH:Fire("MACROS_CHANGED") end
    return ok
end

function E:MatchesMode(macro, mode)
    if mode == "ALL" then return true end
    return macro.mode == "BOTH" or macro.mode == mode
end

function E:GetPack(mode)
    local cls = FMH:PlayerClass()
    local result = {}
    for i=1,#FMH.Macros do
        local m = FMH.Macros[i]
        if m.recommended and (m.class == cls or m.class == "GENERAL") and self:MatchesMode(m, mode) then
            result[#result+1]=m
        end
    end
    table.sort(result,function(a,b)
        if a.class ~= b.class then return a.class == "GENERAL" end
        return a.title < b.title
    end)
    return result
end

function E:InstallPack(mode)
    if not FMH:CanModifyMacros() then return 0,0,"Macros cannot be changed during combat." end
    local pack=self:GetPack(mode)
    local done=0
    local lastError=nil
    for i=1,#pack do
        local ok,err=self:Install(pack[i])
        if ok then done=done+1 else lastError=err; break end
    end
    return done,#pack,lastError
end
