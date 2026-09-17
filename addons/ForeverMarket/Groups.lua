local _,FM=...
local G={};FM.Groups=G

local defaultOperation={
    name="Default Auctioning",
    minPrice="70% FMMarket",
    normalPrice="100% FMMarket",
    maxPrice="130% FMMarket",
    undercut=1,stackSize=0,postCap=5,keepQuantity=0,belowMin="normal",enabled=true,
}

local function clone(src)
    local t={};for k,v in pairs(src) do t[k]=v end;return t
end

function G:Ensure()
    local d=FM.Data;if not d then return end
    d.groups=d.groups or {};d.operations=d.operations or {};d.itemGroups=d.itemGroups or {}
    if not d.operations.default then d.operations.default=clone(defaultOperation) end
    if not d.groups.default then d.groups.default={name="Ungrouped",operation="default",created=time(),system=true} end
end
function G:All()
    self:Ensure();local rows={}
    for id,g in pairs(FM.Data.groups) do rows[#rows+1]={id=id,name=g.name or id,operation=g.operation or "default",system=g.system} end
    table.sort(rows,function(a,b) if a.system~=b.system then return a.system end;return a.name:lower()<b.name:lower() end)
    return rows
end
function G:Create(name)
    self:Ensure();name=tostring(name or ""):match("^%s*(.-)%s*$")
    if name=="" then return nil,"Enter a group name." end
    local base=name:lower():gsub("[^%w]+","-"):gsub("^-+",""):gsub("-+$","")
    if base=="" then base="group" end
    local id=base;local n=2;while FM.Data.groups[id] do id=base.."-"..n;n=n+1 end
    local opId="op-"..id;FM.Data.operations[opId]=clone(defaultOperation);FM.Data.operations[opId].name=name.." Auctioning"
    FM.Data.groups[id]={name=name,operation=opId,created=time()}
    return id
end
function G:Delete(id)
    self:Ensure();if not id or id=="default" or not FM.Data.groups[id] then return false end
    local op=FM.Data.groups[id].operation
    for key,gid in pairs(FM.Data.itemGroups) do if gid==id then FM.Data.itemGroups[key]=nil end end
    FM.Data.groups[id]=nil
    local used=false;for _,g in pairs(FM.Data.groups) do if g.operation==op then used=true end end
    if op and not used then FM.Data.operations[op]=nil end
    return true
end
function G:Assign(key,id)
    self:Ensure();if not key then return false end
    if id and id~="default" and not FM.Data.groups[id] then return false end
    FM.Data.itemGroups[key]=(id and id~="default") and id or nil;return true
end
function G:GroupFor(key)
    self:Ensure();local id=FM.Data.itemGroups[key] or "default";return id,FM.Data.groups[id] or FM.Data.groups.default
end
function G:OperationFor(key)
    local id,g=self:GroupFor(key);local opId=(g and g.operation) or "default"
    return FM.Data.operations[opId] or FM.Data.operations.default,opId,id,g
end
function G:Count(id)
    local n=0;for _,gid in pairs(FM.Data.itemGroups or {}) do if gid==id then n=n+1 end end;return n
end
function G:SaveOperation(opId,values)
    self:Ensure();local op=FM.Data.operations[opId];if not op then return nil,"Operation not found." end
    for k,v in pairs(values or {}) do op[k]=v end
    return op
end
