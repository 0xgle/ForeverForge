local _, FMH = ...
local E = {}; FMH.Engine = E
local function trim(s) return (tostring(s or ''):gsub('\r\n','\n'):gsub('%s+$','')) end
function E:GetCounts()
    if not GetNumMacros then return 0,0 end
    local a,b=GetNumMacros(); return tonumber(a) or 0,tonumber(b) or 0
end
function E:Limits() return MAX_ACCOUNT_MACROS or 120,MAX_CHARACTER_MACROS or 18 end
function E:Records()
    FMH.db.characters=FMH.db.characters or {}
    local key=FMH:CharacterKey()
    FMH.db.characters[key]=FMH.db.characters[key] or {installed={},drafts={}}
    return FMH.db.characters[key]
end
function E:GetIndex(m)
    if not m or not GetMacroInfo then return 0 end
    local base,limit=self:Limits()
    for i=base+1,base+limit do
        local name,_,body=GetMacroInfo(i)
        if name==m.macroName then return i end
    end
    -- Adopt an old name only when its body exactly matches our known template.
    if m.legacyName then
        for i=base+1,base+limit do
            local name,_,body=GetMacroInfo(i)
            if name==m.legacyName and (trim(body)==trim(m.legacyBody) or trim(body)==trim(m.body)) then return i end
        end
    end
    return 0
end
function E:IsOwned(m,index)
    index=index or self:GetIndex(m)
    if index<=0 then return false end
    local name,_,body=GetMacroInfo(index)
    local record=self:Records().installed[m.id]
    if record and record.name==name and trim(record.body)==trim(body) then return true end
    return trim(body)==trim(m.body) or (m.legacyBody and trim(body)==trim(m.legacyBody)) or false
end
function E:IsInstalled(m)
    local idx=self:GetIndex(m)
    if idx>0 then local _,_,body=GetMacroInfo(idx); return true,body end
    return false,nil
end
function E:Validate(m,body)
    if not m then return false,'Select a macro first.' end
    if not FMH:CanModifyMacros() then return false,'Unavailable during combat.' end
    if not FMH.isClassicEra then return false,'This build installs macros on Classic Era only.' end
    if m.class~='GENERAL' and m.class~=FMH:PlayerClass() then return false,'Browse all classes; install only for your current class.' end
    if GetLocale and GetLocale()~='enUS' and GetLocale()~='enGB' then return false,'English game client required for these spell names.' end
    if type(CreateMacro)~='function' or type(EditMacro)~='function' then return false,'Macro API unavailable.' end
    body=trim(body)
    if body=='' then return false,'Macro body is empty.' end
    if #body>255 then return false,'Macro body exceeds 255 bytes.' end
    local idx=self:GetIndex(m)
    if idx>0 and not self:IsOwned(m,idx) then return false,'Name conflict or external edit. Rename that macro in /macro first; it will be preserved.' end
    local _,n=self:GetCounts();local _,limit=self:Limits()
    if idx==0 and n>=limit then return false,'Character macro slots are full. Free a slot in /macro.' end
    return true
end
function E:Install(m,overrideBody)
    local body=trim(overrideBody or m and m.body)
    local valid,err=self:Validate(m,body); if not valid then return false,err end
    local index=self:GetIndex(m); local existed=index>0
    local ok,result
    if existed then ok,result=pcall(EditMacro,index,m.macroName,134400,body)
    else ok,result=pcall(CreateMacro,m.macroName,134400,body,true) end
    if not ok then return false,tostring(result) end
    -- Do not trust a nil return or a successful pcall: verify stored bytes.
    local actual=self:GetIndex(m)
    local name,_,saved
    if actual>0 then name,_,saved=GetMacroInfo(actual) end
    if name~=m.macroName or trim(saved)~=body then return false,'The client did not save the macro. No success was recorded.' end
    self:Records().installed[m.id]={name=name,body=body}
    self:Records().drafts[m.id]=nil
    FMH:Fire('MACROS_CHANGED')
    return true,existed and 'updated' or 'created'
end
function E:Delete(m,expectedBody)
    if not m or not FMH:CanModifyMacros() or not DeleteMacro then return false,'Unavailable during combat.' end
    local idx=self:GetIndex(m)
    if idx<=0 or not self:IsOwned(m,idx) then return false,'This macro is not managed by ForeverMacroHelper.' end
    local _,_,body=GetMacroInfo(idx)
    if expectedBody and trim(body)~=trim(expectedBody) then return false,'Macro changed since confirmation. Please try again.' end
    local ok,err=pcall(DeleteMacro,idx)
    if not ok then return false,tostring(err) end
    if self:GetIndex(m)>0 then return false,'The client did not delete the macro.' end
    self:Records().installed[m.id]=nil
    FMH:Fire('MACROS_CHANGED');return true
end
function E:MatchesMode(m,mode) return mode=='ALL' or m.mode=='BOTH' or m.mode==mode end
function E:GetPack(mode)
    local result={}
    for _,m in ipairs(FMH.Macros) do
        if m.recommended and (m.class==FMH:PlayerClass() or m.class=='GENERAL') and self:MatchesMode(m,mode) then result[#result+1]=m end
    end
    table.sort(result,function(a,b) if a.class~=b.class then return a.class~='GENERAL' end return a.title<b.title end)
    return result
end
function E:PlanPack(mode)
    local plan={create={},preserved=0,mode=mode}
    for _,m in ipairs(self:GetPack(mode)) do
        if self:GetIndex(m)>0 then plan.preserved=plan.preserved+1
        else plan.create[#plan.create+1]=m end
    end
    local _,used=self:GetCounts();local _,limit=self:Limits();plan.free=math.max(0,limit-used)
    return plan
end
function E:InstallPack(mode)
    local plan=self:PlanPack(mode)
    if #plan.create>plan.free then return 0,#plan.create,'Need '..#plan.create..' free character slots; only '..plan.free..' available. Install individual macros instead.' end
    for _,m in ipairs(plan.create) do local ok,err=self:Validate(m,m.body);if not ok then return 0,#plan.create,err end end
    local done=0
    for _,m in ipairs(plan.create) do
        local ok,err=self:Install(m)
        if not ok then return done,#plan.create,err end
        done=done+1
    end
    return done,#plan.create,nil,plan.preserved
end
function E:Draft(m)
    local installed,body=self:IsInstalled(m)
    return self:Records().drafts[m.id] or (installed and body) or m.body
end
