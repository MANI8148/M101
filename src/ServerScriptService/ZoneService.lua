local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local ZoneService = {}

-- Configurations
local CHECK_INTERVAL = 0.5
local STICKY_INTERVAL = 0.5 -- Debounce
local PRIORITY = {
    Lava = 4,
    Toxic = 3,
    Frozen = 2,
    Jungle = 1,
    Wilderness = 0
}

ZoneService.ZoneRegistry = {} 
ZoneService.PlayerZones = {} 
ZoneService.ActiveZones = {} 
ZoneService.LastZoneChangeTime = {} 

ZoneService.ZoneChanged = nil 

-- Helper: Find or Create Zones Folder
local function getZonesFolder()
    local folder = Workspace:FindFirstChild("Zones")
    if not folder then
        local map = Workspace:FindFirstChild("Map")
        if map then folder = map:FindFirstChild("Zones") end
    end
    
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Zones"
        folder.Parent = Workspace
    end
    return folder
end

function ZoneService.Init()
    print("[ZoneService] Initializing Production Architecture...")
    
    local events = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder")
    events.Name = "Events"
    events.Parent = ReplicatedStorage

    ZoneService.ZoneChanged = events:FindFirstChild("ZoneChanged") or Instance.new("BindableEvent")
    ZoneService.ZoneChanged.Name = "ZoneChanged"
    ZoneService.ZoneChanged.Parent = events

    local zonesFolder = getZonesFolder()
    print("[ZoneService] Using folder:", zonesFolder.Name)
    ZoneService.BuildRegistry(zonesFolder)

    -- Player Tracking
    local function startTracking(player)
        local function onCharacterAdded(character)
            task.spawn(function()
                while character.Parent do
                    task.wait(CHECK_INTERVAL)
                    ZoneService.CheckPlayer(player)
                end
                ZoneService.CleanupPlayer(player)
            end)
        end
        player.CharacterAdded:Connect(onCharacterAdded)
        if player.Character then onCharacterAdded(player.Character) end
    end

    for _, player in pairs(Players:GetPlayers()) do startTracking(player) end
    Players.PlayerAdded:Connect(startTracking)
    Players.PlayerRemoving:Connect(function(p) ZoneService.CleanupPlayer(p) end)

    print("[ZoneService] Ready.")
end

function ZoneService.BuildRegistry(folder)
    ZoneService.ZoneRegistry = {}
    ZoneService.ActiveZones = { Wilderness = 0 }
    ZoneService.ZoneRegistry["Wilderness"] = { Parts = {}, Players = {}, State = "Normal" }

    local count = 0
    for _, part in pairs(folder:GetChildren()) do
        if part:IsA("BasePart") then
            local zoneType = part:GetAttribute("ZoneType") or part.Name
            
            print("[ZoneService] Registering:", part.Name, zoneType)

            if not ZoneService.ZoneRegistry[zoneType] then
                ZoneService.ZoneRegistry[zoneType] = { Parts = {}, Players = {}, State = "Normal" }
                ZoneService.ActiveZones[zoneType] = 0
            end

            local min = part.Position - (part.Size / 2)
            local max = part.Position + (part.Size / 2)

            table.insert(ZoneService.ZoneRegistry[zoneType].Parts, {
                Part = part,
                Min = min,
                Max = max
            })
            count = count + 1
        end
    end
    print(string.format("[ZoneService] Registered %d zone parts", count))
end

local function isInside(pos, min, max)
    return pos.X >= min.X and pos.X <= max.X
       and pos.Y >= min.Y and pos.Y <= max.Y
       and pos.Z >= min.Z and pos.Z <= max.Z
end

function ZoneService.GetPlayerZone(player)
    local char = player.Character
    if not char then return "Wilderness" end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return "Wilderness" end

    local pos = root.Position
    local matchedZones = {}

    for zoneType, zoneData in pairs(ZoneService.ZoneRegistry) do
        for _, entry in ipairs(zoneData.Parts) do
            if isInside(pos, entry.Min, entry.Max) then
                table.insert(matchedZones, zoneType)
                break
            end
        end
    end

    -- Pick highest priority
    local finalZone = "Wilderness"
    local highestP = -1
    for _, zt in ipairs(matchedZones) do
        local p = PRIORITY[zt] or 0
        if p > highestP then
            highestP = p
            finalZone = zt
        end
    end

    return finalZone
end

function ZoneService.CheckPlayer(player)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 🛡 Stickiness/Debounce
    local now = os.clock()
    if now - (ZoneService.LastZoneChangeTime[player] or 0) < STICKY_INTERVAL then return end

    local finalZone = ZoneService.GetPlayerZone(player)
    local oldZone = ZoneService.PlayerZones[player] or "Wilderness"

    if finalZone ~= oldZone then
        ZoneService.TransitionPlayer(player, oldZone, finalZone)
        ZoneService.LastZoneChangeTime[player] = now
    end
end

function ZoneService.TransitionPlayer(player, oldZone, newZone)
    print(string.format("[ZoneService] %s: %s -> %s", player.Name, oldZone, newZone))
    
    if ZoneService.ZoneRegistry[oldZone] then 
        ZoneService.ZoneRegistry[oldZone].Players[player] = nil
        ZoneService.ActiveZones[oldZone] = math.max(0, (ZoneService.ActiveZones[oldZone] or 0) - 1)
    end

    if ZoneService.ZoneRegistry[newZone] then 
        ZoneService.ZoneRegistry[newZone].Players[player] = true 
        ZoneService.ActiveZones[newZone] = (ZoneService.ActiveZones[newZone] or 0) + 1
    end

    ZoneService.PlayerZones[player] = newZone
    if ZoneService.ZoneChanged then ZoneService.ZoneChanged:Fire(player, newZone, oldZone) end
end

function ZoneService.CleanupPlayer(player)
    local current = ZoneService.PlayerZones[player]
    if current then ZoneService.TransitionPlayer(player, current, "Wilderness") end
    ZoneService.PlayerZones[player] = nil
    ZoneService.LastZoneChangeTime[player] = nil
end

return ZoneService
