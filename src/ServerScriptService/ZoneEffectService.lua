local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

local ZoneEffectService = {}

-- Configurations
local TICK_INTERVAL = 1.0

function ZoneEffectService.Init()
    print("⚡ [ZoneEffectService] Core Loop Initialized.")
    
    task.spawn(function()
        while true do
            task.wait(TICK_INTERVAL)
            ZoneEffectService.ApplyTick()
        end
    end)
end

function ZoneEffectService.ApplyTick()
    local ZoneService = ServiceRegistry:Get("ZoneService")
    local MutationService = ServiceRegistry:Get("MutationService")
    
    if not ZoneService or not ZoneService.ZoneRegistry then return end

    -- Optimize: Only process zones with active populations
    for zoneType, data in pairs(ZoneService.ZoneRegistry) do
        local playersInZone = data.Players or {}
        local hasPlayers = false
        for _ in pairs(playersInZone) do hasPlayers = true break end
        if not hasPlayers then continue end

        for player, _ in pairs(playersInZone) do
            local char = player.Character
            local humanoid = char and char:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end

            -- 🛡 EFFECT HANDLER
            if zoneType == "Lava" then
                -- 🔥 REQUIREMENT: Lava → damage
                humanoid:TakeDamage(5)
                
            elseif zoneType == "Frozen" then
                -- ❄️ REQUIREMENT: Snow (Frozen) → slow
                humanoid.WalkSpeed = 8
                
            elseif zoneType == "Radiation" then
                -- ☢️ REQUIREMENT: Radiation → mutation
                if MutationService then
                    MutationService.AddMutation(player, "Gamma_Exp")
                end
                
            else
                -- 🟢 Normal State Reversion
                humanoid.WalkSpeed = 16
            end
        end
    end
end

return ZoneEffectService
