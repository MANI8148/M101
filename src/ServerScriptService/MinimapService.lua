local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

local MinimapService = {}

local COLORS = {
    Lava = {255, 69, 0},
    Frozen = {0, 191, 255},
    Jungle = {34, 139, 34},
    Toxic = {57, 255, 20},
    Wilderness = {128, 128, 128}
}

function MinimapService.Init()
    print("[MinimapService] Generating Map Data...")
    MinimapService.GenerateMap()

    -- 🛠 DYNAMIC MAP SYNC: Update when zones added via fallback
    local folder = game.Workspace:FindFirstChild("Zones")
    if folder then
        folder.ChildAdded:Connect(function() 
            task.wait(1) -- Batch updates
            MinimapService.GenerateMap() 
        end)
    end
end

function MinimapService.GenerateMap()
    local ZoneService = ServiceRegistry:Get("ZoneService")
    if not ZoneService or not ZoneService.ZoneRegistry then return end

    local mapData = {}

    -- Project 3D Zones to 2D Map (Top-Down)
    for zoneType, data in pairs(ZoneService.ZoneRegistry) do
        local rgb = COLORS[zoneType] or COLORS.Wilderness
        
        for _, pData in ipairs(data.Parts) do
            local part = pData.Part
            table.insert(mapData, {
                Pos = {part.Position.X, part.Position.Z},
                Size = {part.Size.X, part.Size.Z},
                Color = rgb,
                Type = zoneType
            })
        end
    end

    -- Encode & Bind to ReplicatedStorage Attribute
    local json = HttpService:JSONEncode(mapData)
    ReplicatedStorage:SetAttribute("MinimapData", json)
    
    print("[MinimapService] Map Updated: ", #json, "bytes")
end

return MinimapService
