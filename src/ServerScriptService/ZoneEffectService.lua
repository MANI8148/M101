local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

local ZoneEffectService = {}

function ZoneEffectService.Init()
    print("[ZoneEffectService] Initialized.")
    
    -- Start Global Loop
    task.spawn(function()
        while true do
            task.wait(1)
            ZoneEffectService.ApplyTick()
        end
    end)
end

function ZoneEffectService.ApplyTick()
    local ZoneService = ServiceRegistry:Get("ZoneService")
    if not ZoneService or not ZoneService.ZoneRegistry then return end

    -- Iterating only zones found in registry
    for zoneType, data in pairs(ZoneService.ZoneRegistry) do
        local playersInZone = data.Players or {}
        
        for player, _ in pairs(playersInZone) do
            local char = player.Character
            local humanoid = char and char:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end

            -- Damage Effects
            if zoneType == "Lava" then
                humanoid:TakeDamage(5)
            elseif zoneType == "Toxic" then
                humanoid:TakeDamage(2)
            end

            -- Speed Effects
            if zoneType == "Frozen" then
                humanoid.WalkSpeed = 8
            else
                humanoid.WalkSpeed = 16
            end
        end
    end
end

return ZoneEffectService
