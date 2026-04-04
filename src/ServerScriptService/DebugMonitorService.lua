local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local ServerScriptService = game:GetService("ServerScriptService")

local DebugMonitorService = {}
DebugMonitorService.Enabled = true

function DebugMonitorService.Init()
    if not DebugMonitorService.Enabled then return end
    print("🖥️ [DebugMonitorService] Monitoring System Latency and Zone Activity...")
    task.spawn(DebugMonitorService.MonitorTick)
end

function DebugMonitorService.MonitorTick()
    -- Wait for initial generation to finish
    task.wait(3) 

    while true do
        local ServiceRegistry = require(ServerScriptService.ServiceRegistry)
        local ZoneManager = require(ServerScriptService.ZoneGenerator)
        local ZoneService = ServiceRegistry:Get("ZoneService")
        
        local out = "\n📈 ==== [ZONE ANALYTICS MONITOR] ==== 📉\n"
        out = out .. "Total Players: " .. #Players:GetPlayers() .. "\n"
        out = out .. "Server FPS: " .. math.floor(1 / task.wait(2)) .. " (Est.)\n"
        out = out .. "Server Mem: " .. math.floor(Stats:GetTotalMemoryUsageMb()) .. " MB\n\n"
        
        -- 🛰️ CLUSTER PROGRESS
        if ZoneManager and ZoneManager.Clusters then
            out = out .. "--- GENERATION ---\n"
            out = out .. string.format("Parts Scan: %d clusters online\n", #ZoneManager.Clusters)
        end
        
        -- 📍 PLAYER ACTIVITY
        if ZoneService and ZoneService.PlayerZones then
            out = out .. "\n--- ACTIVE PLAYER ZONES ---\n"
            local activeCounts = {}
            local totalActive = 0
            
            for _, data in pairs(ZoneService.PlayerZones) do
                local zType = data.zone or "Wilderness"
                if zType ~= "Wilderness" then
                    activeCounts[zType] = (activeCounts[zType] or 0) + 1
                    totalActive = totalActive + 1
                end
            end
            
            for zType, count in pairs(activeCounts) do
                out = out .. string.format("[%s]: %d Players\n", zType, count)
            end
            
            if totalActive == 0 then out = out .. "(All players in Wilderness)\n" end
        end
        
        -- 🌍 STATIC ANALYSIS
        out = out .. "\n--- ZONES PER TYPE ---\n"
        if ZoneManager and ZoneManager.Clusters then
            local typeStats = {}
            for _, cl in ipairs(ZoneManager.Clusters) do
                typeStats[cl.type] = (typeStats[cl.type] or 0) + 1
            end
            for zType, count in pairs(typeStats) do
                out = out .. string.format("%s: %d clusters registered\n", zType, count)
            end
        end

        out = out .. "\nLast Update: " .. os.date("%X") .. "\n"
        out = out .. "========================================\n"
        
        print(out)
    end
end

return DebugMonitorService
