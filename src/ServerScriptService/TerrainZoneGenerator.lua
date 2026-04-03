local ServerScriptService = game:GetService("ServerScriptService")
local TerrainAnalyzer = require(ServerScriptService.TerrainAnalyzer)
local ZoneBuilder = require(ServerScriptService.ZoneBuilder)

-- Configuration Constants
local CHUNK_SIZE = 48
local VOXEL_RESOLUTION = 4
local VOXEL_THRESHOLD = 30
local DEBUG = true

-- Material mapping (Enum.Material -> ZoneType)
local MATERIAL_MAP = {
    [Enum.Material.Neon] = "Lava",
    [Enum.Material.Snow] = "Frozen",
    [Enum.Material.Grass] = "Jungle",
    [Enum.Material.Sand] = "Toxic",
    [Enum.Material.Mud] = "Toxic",
}

local TerrainZoneGenerator = {}

function TerrainZoneGenerator.Run()

    local zonesFolder = workspace:FindFirstChild("Zones")
    if zonesFolder then
        print("[TerrainGenerator] Clearing old zones...")
        for _, obj in ipairs(zonesFolder:GetChildren()) do
            obj:Destroy()
        end
    else
        zonesFolder = Instance.new("Folder")
        zonesFolder.Name = "Zones"
        zonesFolder.Parent = workspace
    end

    print("[TerrainGenerator] Zones after cleanup:", #zonesFolder:GetChildren())
    print("🔥 Terrain Zone Generator FALLBACK STARTED")

    -- 🌍 Dynamic map bounds (AUTO)
    local terrain = workspace.Terrain
    -- Optimized map bounds
    local mapMin = Vector3.new(-256, 0, -256)
    local mapMax = Vector3.new(256, 128, 256)

    -- 🔍 STEP 1: Scan
    local chunks = TerrainAnalyzer.Scan(
        mapMin,
        mapMax,
        CHUNK_SIZE,
        VOXEL_RESOLUTION,
        MATERIAL_MAP,
        VOXEL_THRESHOLD -- ✅ FIXED
    )

    -- 🧱 STEP 2: Build clustered zones
    local zones = ZoneBuilder.Build(chunks, CHUNK_SIZE)

    -- 🏷️ Event-Driven Sync (User Requirement)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local events = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder")
    events.Name = "Events"
    events.Parent = ReplicatedStorage

    local zonesReadyEvent = events:FindFirstChild("ZonesReady") or Instance.new("BindableEvent")
    zonesReadyEvent.Name = "ZonesReady"
    zonesReadyEvent.Parent = events

    print("[TerrainGenerator] Zones fully built. Firing event...")
    zonesReadyEvent:Fire()

    -- 📊 Debug
    if DEBUG then
        print("===== TERRAIN SCAN COMPLETE =====")
        print("Zones Created:", #zones)
    end
end

return TerrainZoneGenerator
