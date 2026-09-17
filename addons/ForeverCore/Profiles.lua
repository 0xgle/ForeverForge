local _,F=...
local function clean(s) return (s or ""):match("^%s*(.-)%s*$") end
function F:SaveProfile(name, scope)
    name=clean(name)
    if #name<1 or #name>40 or name:find("[\r\n|]") then return false,"Use 1-40 characters without | or line breaks." end
    if self.db.profiles[name] then return false,"This name exists. Use a new name or delete the old profile." end
    local n=0; for _ in pairs(self.db.profiles) do n=n+1 end
    if n>=50 then return false,"Maximum 50 profiles." end
    self.db.profiles[name]={states=self:Snapshot(scope),scope=scope or "suite",created=date("%Y-%m-%d")}
    self:Record("Saved profile: "..name); return true
end
function F:ExportProfile(name)
    local p=self.db.profiles[name]; if not p then return "" end
    local ids={}; for id in pairs(p.states) do ids[#ids+1]=id end; table.sort(ids)
    local lines={"FCORE1|"..name.."|"..(p.scope or "suite")}
    for _,id in ipairs(ids) do lines[#lines+1]=id.."="..(p.states[id] and "1" or "0") end
    return table.concat(lines,"\n")
end
function F:ImportProfile(text)
    if type(text)~="string" or #text>64000 then return false,"Import is too large (64 KB maximum)." end
    text=text:gsub("\r","")
    local header,body=text:match("^([^\n]+)\n(.*)$")
    if not header then header=text; body="" end
    local name,scope=header:match("^FCORE1|([^|]+)|(%a+)$")
    if not name or #name>40 or (scope~="suite" and scope~="all") then return false,"Invalid ForeverCore profile header." end
    if self.db.profiles[name] then return false,"A profile named "..name.." already exists." end
    local count=0; for _ in pairs(self.db.profiles) do count=count+1 end
    if count>=50 then return false,"Maximum 50 profiles." end
    local states,n={},0
    for line in body:gmatch("[^\n]+") do
        local id,v=line:match("^([%w_%-%.]+)=([01])$")
        if not id or #id>120 or states[id]~=nil then return false,"Invalid or duplicate addon entry." end
        n=n+1; if n>500 then return false,"Maximum 500 addon entries." end
        if id~=self.name then states[id]=v=="1" end
    end
    self.db.profiles[name]={states=states,scope=scope,created=date("%Y-%m-%d")}
    self:Record("Imported profile: "..name)
    return true,name
end
