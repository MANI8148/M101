local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local ServerScriptService = game:GetService("ServerScriptService")

local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

local DebugMonitorService = {}
DebugMonitorService.Enabled = true
DebugMonitorService.ExecTimes = {}

function DebugMonitorService.Init()
    if not DebugMonitorService.Enabled then return end
    
    task.spawn(DebugMonitorService.MonitorTick)
end

function DebugMonitorService.LogLoop(name, timeTaken)
    if not DebugMonitorService.Enabled then return end
    DebugMonitorService.ExecTimes[name] = timeTaken
end

function DebugMonitorService.MonitorTick()
    while true do
        task.wait(2)
        local out = "\n==== [DEBUG MONITOR] ====\n"
        out = out .. "Players Online: " .. #Players:GetPlayers() .. "\n"
        out = out .. "Server Memory: " .. math.floor(Stats:GetTotalMemoryUsageMb()) .. " MB\n\n"
        
        local ZoneService = ServiceRegistry:Get("ZoneService")
        local MutationController = ServiceRegistry:Get("MutationController")
        
        if ZoneService then
            out = out .. "--- ACTIVE ZONES ---\n"
            for zoneType, count in pairs(ZoneService.ActiveZones) do
                out = out .. string.format("[%s]: Players = %d\n", zoneType, count)
            end
        end
        
        out = out .. "\n--- EXECUTION TIMES ---\n"
        for name, timing in pairs(DebugMonitorService.ExecTimes) do
            out = out .. string.format("%s: %.4f ms\n", name, timing * 1000)
        end
        out = out .. "=======================\n"
        print(out)
    end
end

return DebugMonitorService
