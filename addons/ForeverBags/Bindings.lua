BINDING_HEADER_FOREVERBAGS = "ForeverBags"
BINDING_NAME_FOREVERBAGS_TOGGLE = "Toggle inventory"

function ForeverBags_Toggle()
    if ForeverBags and ForeverBags.Toggle then
        ForeverBags:Toggle()
    end
end
