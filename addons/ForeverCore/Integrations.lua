local _,F=...
F.modules.ForeverCore={title="ForeverCore",description="The control room for your Forever collection.",icon=1,open=function() F:Toggle() end}
F.modules.ForeverBags={title="ForeverBags",description="Your inventory, beautifully organized.",icon=2,
    open=function() if ForeverBags and ForeverBags.Toggle then ForeverBags:Toggle() else F:Print("This ForeverBags version has no compatible launcher.") end end,
    settings=function() if ForeverBags and ForeverBags.SettingsUI then ForeverBags.SettingsUI:Toggle() else F:Print("Settings are unavailable in this version.") end end}
F.modules.ForeverGather={title="ForeverGather",description="Gathering journal, routes and your expedition HUD.",icon=3,
    open=function() if ForeverGather and ForeverGather.ToggleUI then ForeverGather:ToggleUI() else F:Print("This ForeverGather version has no compatible launcher.") end end}

-- Legacy suite addons can opt in simply by exposing /<folder-name>.
function F:DiscoverLauncher(id)
    if not id:lower():match("^forever") then return nil end
    local icon=id:lower():find("chat",1,true) and 4 or (id:lower():find("macro",1,true) and 15 or 16)
    for key,fn in pairs(SlashCmdList) do
        if type(fn)=="function" then
            for i=1,10 do
                local command=_G["SLASH_"..key..i]
                if not command then break end
                if command:lower()=="/"..id:lower() then
                    local callback=fn
                    local spec={title=id,icon=icon,description="Forever collection addon. Open its own panel for settings.",open=function() callback("") end}
                    self.modules[id]=spec; return spec
                end
            end
        end
    end
end
