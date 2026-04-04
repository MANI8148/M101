local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local Scanner = require(ServerScriptService.TerrainScanner)
local Persistence = require(ServerScriptService.ZonePersistence)

local ZoneManager = {
    IsGenerating = false,
    Clusters = {}, 
    StartupTime = 0
}

-- ⚙️ CONFIGURATION
local CLUSTER_RADIUS = 24 
local ZONE_HEIGHT = 800

-- Material -> ZoneType mapping (Realistic Distribution)
local MATERIAL_MAP = {
    [Enum.Material.Grass] = "Jungle",
    [Enum.Material.Sand] = "Toxic",
    [Enum.Material.Snow] = "Frozen",
    [Enum.Material.CrackedLava] = "Lava",
    [Enum.Material.Basalt] = "Lava",
    [Enum.Material.Mud] = "Toxic",
    [Enum.Material.Slate] = "Radiation",
    [Enum.Material.Neon] = "Radiation"
}

function ZoneManager.Run()
    if ZoneManager.IsGenerating then return end
    ZoneManager.IsGenerating = true
    
    local startTime = os.clock()
    print("🛰️ [ZoneManager] Running Logic-Only Zone Discovery...")

    -- 🔍 STEP 1: Attempt Load
    local data = Persistence.Load()
    if not data then
        data = Scanner.Scan()
        Persistence.Save(data)
    end

    if not data or #data == 0 then
        warn("🚫 [ZoneManager] No zones detected!")
        ZoneManager.IsGenerating = false
        return {}
    end

    -- 🧱 STEP 2: Strict Material Separation
    local nodesByZone = {} 
    for _, node in ipairs(data) do
        local mat = Enum.Material[node.m]
        local zType = MATERIAL_MAP[mat] or "Wilderness"
        if zType ~= "Wilderness" then
            if not nodesByZone[zType] then nodesByZone[zType] = {} end
            table.insert(nodesByZone[zType], Vector3.new(node.p[1], node.p[2], node.p[3]))
        end
    end

    local clusterList = {}
    for zType, positions in pairs(nodesByZone) do
        local speciesClusters = {} 
        
        for _, pos in ipairs(positions) do
            local found = false
            for _, cl in ipairs(speciesClusters) do
                if (pos - (cl.pSum / cl.count)).Magnitude < CLUSTER_RADIUS then
                    cl.pSum = cl.pSum + pos
                    cl.count = cl.count + 1
                    cl.min = Vector3.new(math.min(cl.min.X, pos.X), math.min(cl.min.Y, pos.Y), math.min(cl.min.Z, pos.Z))
                    cl.max = Vector3.new(math.max(cl.max.X, pos.X), math.max(cl.max.Y, pos.Y), math.max(cl.max.Z, pos.Z))
                    found = true
                    break
                end
            end
            if not found then
                table.insert(speciesClusters, {pSum = pos, count = 1, min = pos, max = pos})
            end
        end

        for _, cl in ipairs(speciesClusters) do
            local center = (cl.min + cl.max) / 2
            local size = (cl.max - cl.min) + Vector3.new(CLUSTER_RADIUS, ZONE_HEIGHT, CLUSTER_RADIUS)
            
            local cInfo = {
                id = os.clock() .. "_" .. math.random(100,999),
                position = Vector3.new(center.X, (ZONE_HEIGHT / 2) - 50, center.Z),
                size = size,
                type = zType,
                nodeCount = cl.count
            }
            
            table.insert(clusterList, cInfo)
        end
    end

    ZoneManager.Clusters = clusterList
    ZoneManager.IsGenerating = false
    ZoneManager.StartupTime = os.clock() - startTime
    
    -- 🔥 CRITICAL: RETURN zones list for Bootstrap pipe
    return clusterList
end

return ZoneManager
