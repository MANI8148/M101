local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

local function onPlayerAdded(player)
    player.Chatted:Connect(function(message)
        local args = string.split(message, " ")
        local command = args[1]
        
        local zoneService = ServiceRegistry:Get("ZoneService")
        local generator = _G.ZoneGenerator -- Updated global
        
        if command == "/printZones" then
            if not zoneService then return end
            print("--- Registered Zones ---")
            for zoneType, data in pairs(zoneService.ZoneRegistry) do
                print(string.format("[%s] Parts: %d, Players: %d", zoneType, #data.Parts, zoneService.ActiveZones[zoneType] or 0))
            end
            
        elseif command == "/regenZones" then
            print("--- Manually Regenerating Zones ---")
            local ZoneGenerator = require(ServerScriptService.ZoneGenerator)
            if ZoneGenerator and ZoneGenerator.Run then
                ZoneGenerator.Run()
            else
                warn("ZoneGenerator module not found or missing .Run()")
            end
            
        elseif command == "/debugZones" then
            if not zoneService then return end
            print("--- Debugging ALL Zone Objects ---")
            local zones = workspace:FindFirstChild("Zones")
            if zones then
                for _, child in ipairs(zones:GetChildren()) do
                    print(string.format("Part: %s | Size: %s | Pos: %s", child.Name, tostring(child.Size), tostring(child.Position)))
                end
            else
                warn("No Zones folder found in workspace!")
            end
            
        elseif command == "/checkClusters" then
            if not zoneService then return end
            print("--- Spatial Grid Status ---")
            if zoneService.Grid then
                local cellCount = 0
                for _ in pairs(zoneService.Grid) do cellCount = cellCount + 1 end
                print(string.format("Total active grid cells: %d", cellCount))
            else
                print("No spatial grid initialized in ZoneService.")
            end
        end
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
