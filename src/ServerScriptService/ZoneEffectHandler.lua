local ServerScriptService = game:GetService("ServerScriptService")
local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

local ZoneEffectHandler = {}

-- ⚙️ EFFECT CONFIGURATION
function ZoneEffectHandler.Init()
    print("✨ [ZoneEffectHandler] Legacy Registry Transitioning to Blended Logic Mode...")
    
    local ZoneService = ServiceRegistry:Get("ZoneService")
    -- 🛡️ RESILIENCE HANDSHAKE
    local start = os.clock()
    while not ZoneService and (os.clock() - start) < 3 do
        task.wait()
        ZoneService = ServiceRegistry:Get("ZoneService")
    end

    if not ZoneService or not ZoneService.ZoneChanged then
        warn("⚠️ [ZoneEffectHandler] Signal missing! Disabling legacy listeners.")
        return
    end

    -- Radiation handler for Mutation
    ZoneService.ZoneChanged.Event:Connect(function(player, newZone, oldZone)
        if newZone == "Radiation" then
             local MutationService = ServiceRegistry:Get("MutationService")
             if MutationService then MutationService.Expose(player) end
        end
    end)
end

return ZoneEffectHandler
