local _, F = ...
function F:Scan()
    self.addons, self.byID = {}, {}
    for i=1,self.A.GetNumAddOns() do
        local id, title, notes, loadable, reason = self.A.GetAddOnInfo(i)
        if id then
            local spec = self.modules[id] or self:DiscoverLauncher(id)
            local a = {id=id, index=i, title=spec and spec.title or title or id,
                notes=spec and spec.description or notes or "", loaded=not not self.A.IsAddOnLoaded(id),
                enabled=self.A.Enabled(id), version=self.A.GetAddOnMetadata(id,"Version") or "?",
                reason=reason, loadable=loadable, spec=spec,
                suite=id:lower():match("^forever") ~= nil or self.A.GetAddOnMetadata(id,"X-Forever-Suite") == "1" or spec ~= nil,
                deps={self.A.GetAddOnDependencies(id)}, lod=self.A.IsAddOnLoadOnDemand(id)}
            self.byID[id]=a; self.addons[#self.addons+1]=a
        end
    end
    table.sort(self.addons, function(a,b)
        local fa,fb=self.db.favorites[a.id],self.db.favorites[b.id]
        if not not fa ~= not not fb then return not not fa end
        if a.suite ~= b.suite then return a.suite end
        return a.id:lower() < b.id:lower()
    end)
end
function F:Desired(id)
    if self.pending[id] ~= nil then return self.pending[id] end
    local a=self.byID[id]; return a and a.enabled or false
end
function F:Stage(id, enabled)
    if not self:Guard() then return false end
    self:Scan()
    if not self.byID[id] or id == self.name then return false end
    local plan, visiting = self:Copy(self.pending), {}
    local function desired(n)
        if plan[n] ~= nil then return plan[n] end
        return self.byID[n] and self.byID[n].enabled
    end
    local function enable(n)
        if visiting[n] then return true end
        visiting[n]=true
        local a=self.byID[n]
        if not a then return false,"Missing required dependency: "..n end
        plan[n]=true
        for _,dep in ipairs(a.deps) do
            local ok,err=enable(dep); if not ok then return false,err end
        end
        return true
    end
    if enabled then
        local ok,err=enable(id); if not ok then self:Print(err); return false end
    else
        plan[id]=false
        local changed=true
        while changed do
            changed=false
            for _,a in ipairs(self.addons) do
                if desired(a.id) then
                    for _,dep in ipairs(a.deps) do
                        if plan[dep] == false then
                            if a.id == self.name then self:Print("ForeverCore needs this dependency."); return false end
                            plan[a.id]=false; changed=true; break
                        end
                    end
                end
            end
        end
    end
    for n,v in pairs(plan) do if self.byID[n] and self.byID[n].enabled == v then plan[n]=nil end end
    plan[self.name]=nil; self.pending=plan; self.stagedProfile=nil; self:Refresh(); return true
end
function F:Snapshot(scope)
    self:Scan(); local states={}
    for _,a in ipairs(self.addons) do
        if a.id ~= self.name and (scope == "all" or a.suite) then states[a.id]=self:Desired(a.id) end
    end
    return states
end
function F:StageSnapshot(states)
    if not self:Guard() then return false end
    self:Scan()
    local original=self.pending; local plan={}; local missing=0
    for id,v in pairs(states) do
        if self.byID[id] and id ~= self.name then plan[id]=v
        elseif not self.byID[id] then missing=missing+1 end
    end
    -- A profile is a complete plan for its named entries. Untouched addons retain their state.
    local function desired(id)
        if plan[id] ~= nil then return plan[id] end
        return self.byID[id] and self.byID[id].enabled
    end
    local changed=true
    while changed do
        changed=false
        for _,a in ipairs(self.addons) do
            if desired(a.id) then
                for _,dep in ipairs(a.deps) do
                    if not self.byID[dep] then
                        self:Print("Missing dependency: "..dep); self.pending=original; return false
                    elseif not desired(dep) then
                        if plan[dep] == false then
                            self:Print(a.id.." needs "..dep..". Resolve the profile conflict first."); return false
                        end
                        plan[dep]=true; changed=true
                    end
                end
            end
        end
    end
    for id,v in pairs(plan) do if self.byID[id].enabled == v then plan[id]=nil end end
    plan[self.name]=nil; self.pending=plan; self.stagedProfile=nil
    if missing > 0 then self:Print(missing.." uninstalled addons skipped.") end
    self:Refresh(); return true
end
function F:Apply()
    if not self:Guard() then return false end
    self:Scan()
    local before={}
    for id in pairs(self.pending) do
        if not self.byID[id] or id == self.name then self:Print("Addon list changed. Discard and retry."); return false end
        before[id]=self.byID[id].enabled
    end
    for _,a in ipairs(self.addons) do
        if self:Desired(a.id) then
            for _,dep in ipairs(a.deps) do
                if not self:Desired(dep) then self:Print(a.id.." needs "..dep); return false end
            end
        end
    end
    local function set(id,v)
        local fn=v and self.A.EnableAddOn or self.A.DisableAddOn
        fn(id, UnitName("player"))
        assert(self.A.Enabled(id)==v,"Could not change "..id)
    end
    local ok,err=pcall(function() for id,v in pairs(self.pending) do set(id,v) end end)
    if not ok then
        local restored=true
        for id,v in pairs(before) do local rok=pcall(set,id,v); if not rok then restored=false end end
        self:Print((restored and "Apply failed; previous states restored: " or "Apply and rollback failed; check the game addon list: ")..tostring(err)); self:Scan(); return false
    end
    local count=0; for _ in pairs(before) do count=count+1 end
    if count>0 then
        self.db.undo=before; self.char.reload=true
        self:Record("Applied "..count.." addon changes on this character")
    end
    self.pending={}; self:Refresh(); return true
end
function F:Discard() self.pending={}; self.stagedProfile=nil; self:Refresh() end
function F:OpenModule(id, settings)
    if not self:Guard() then return end
    self:Scan(); local a=self.byID[id]; if not a then return end
    if not a.loaded then
        if not a.enabled or not a.lod then self:Print("Enable this addon, apply changes and reload first."); return end
        local ok,reason=self.A.LoadAddOn(id)
        if not ok then self:Print("Could not load "..id..": "..tostring(reason)); return end
        self:Scan(); a=self.byID[id]
    end
    local spec=self.modules[id]; local fn=spec and (settings and spec.settings or spec.open)
    if not fn then self:Print("This addon has no registered launcher."); return end
    self:SafeCall(id,fn)
end
function F:DiagnosticReport()
    self:Scan()
    local v,build,_,interface=GetBuildInfo()
    local lines={"ForeverCore "..self.version.." | by 0xgle", "Client: "..tostring(v).." / "..tostring(build).." / "..tostring(interface),
        "Project: "..tostring(WOW_PROJECT_ID).." | Locale: "..GetLocale(),
        "Profile: "..(self.char.profile or "Custom").." | Combat: "..tostring(InCombatLockdown()),
        "Memory: last manual sample (not CPU usage).", ""}
    for _,a in ipairs(self.addons) do
        if a.suite then
            lines[#lines+1]=string.format("%s %s | enabled=%s loaded=%s | %.0f KB | %s",a.id,a.version,tostring(a.enabled),tostring(a.loaded),(self.memory and self.memory[a.id]) or 0,a.reason or "OK")
        end
    end
    lines[#lines+1]="\nCore callback errors (this session):"
    for _,e in ipairs(self.errors) do lines[#lines+1]=e end
    if #self.errors==0 then lines[#lines+1]="None recorded. This does not monitor all Lua errors." end
    return table.concat(lines,"\n")
end
function F:SampleMemory()
    if not self:Guard() then return end
    local update=C_AddOns and C_AddOns.UpdateAddOnMemoryUsage or UpdateAddOnMemoryUsage
    local get=C_AddOns and C_AddOns.GetAddOnMemoryUsage or GetAddOnMemoryUsage
    self.memory={}; self:Scan()
    if update and get then
        update(); for _,a in ipairs(self.addons) do self.memory[a.id]=get(a.index) or 0 end
        self.sampleTime=date("%H:%M:%S")
    end
end
