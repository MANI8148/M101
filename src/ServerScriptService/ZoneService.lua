local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

local ZoneService = {}
ZoneService.PlayerZones = {} -- [player] = "ZoneName"
ZoneService.ZonePlayers = {} -- [zoneName] = { [player] = true }
ZoneService.ZoneParts = {} -- Name -> Part
ZoneService.LastPositions = {} -- [player] = Vector3

ZoneService.PlayerEnteredZone = Instance.new("BindableEvent")
ZoneService.PlayerLeftZone = Instance.new("BindableEvent")

function ZoneService.Init()
    ServiceRegistry:Register("ZoneService", ZoneService)
    
    local events = ReplicatedStorage:FindFirstChild("Events")
    local zoneUpdateEvent = events:FindFirstChild("ZoneUpdate") or Instance.new("RemoteEvent")
    zoneUpdateEvent.Name = "ZoneUpdate"
    zoneUpdateEvent.Parent = events
    ZoneService.ZoneUpdateEvent = zoneUpdateEvent
    
    CollectionService:GetInstanceAddedSignal("Zone"):Connect(function(part)
        ZoneService.RegisterZone(part)
    end)
    for _, part in ipairs(CollectionService:GetTagged("Zone")) do
        ZoneService.RegisterZone(part)
    end
    
    -- Cleanup Data securely against leaks
    Players.PlayerRemoving:Connect(function(player)
        local oldZone = ZoneService.PlayerZones[player]
        if oldZone and ZoneService.ZonePlayers[oldZone] then
            ZoneService.ZonePlayers[oldZone][player] = nil
        end
        ZoneService.PlayerZones[player] = nil
        ZoneService.LastPositions[player] = nil
    end)
    
    task.spawn(ZoneService.DetectionTick)
end

function ZoneService.RegisterZone(part)
    local name = part.Name
    ZoneService.ZoneParts[name] = part
    if not ZoneService.ZonePlayers[name] then
        ZoneService.ZonePlayers[name] = {}
    end
end

function ZoneService.DetectionTick()
    -- Restructure to inherently drastically strip polling physics costs
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Include
    
    while true do
        task.wait(0.5)
        
        local Debug = ServiceRegistry:Get("DebugMonitorService")
        local startTick = os.clock()
        
        local zonePartList = {}
        for _, part in pairs(ZoneService.ZoneParts) do
            table.insert(zonePartList, part)
        end
        overlapParams.FilterDescendantsInstances = zonePartList
        
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentPos = hrp.Position
                local lastPos = ZoneService.LastPositions[player]
                
                -- Strict threshold reduction for expensive Physics loops
                if not lastPos or (currentPos - lastPos).Magnitude >= 5 then
                    ZoneService.LastPositions[player] = currentPos
                    
                    local foundZone = "Wilderness"
                    local parts = workspace:GetPartsInPart(hrp, overlapParams)
                    if #parts > 0 then
                        foundZone = parts[1].Name
                    end
                    
                    local oldZone = ZoneService.PlayerZones[player]
                    if foundZone ~= oldZone then
                        ZoneService.PlayerZones[player] = foundZone
                        
                        if oldZone then
                            local cachedGroup = ZoneService.ZonePlayers[oldZone]
                            if cachedGroup then cachedGroup[player] = nil end
                            ZoneService.PlayerLeftZone:Fire(player, oldZone)
                        end
                        
                        if foundZone ~= "Wilderness" then
                            if not ZoneService.ZonePlayers[foundZone] then
                                ZoneService.ZonePlayers[foundZone] = {}
                            end
                            ZoneService.ZonePlayers[foundZone][player] = true
                            ZoneService.PlayerEnteredZone:Fire(player, foundZone)
                        end
                        
                        ZoneService.ZoneUpdateEvent:FireClient(player, foundZone)
                    end
                end
            end
        end
        
        if Debug then Debug.LogLoop("ZoneDetectionTick", os.clock() - startTick) end
    end
end

return ZoneService
