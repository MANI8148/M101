local Workspace = game:GetService("Workspace")

local TerrainScanner = {}

-- ⚙️ CONFIGURATION
local SCAN_GRID = 32 -- Spacing between raycasts
local MAP_BOUNDS = 1024 
local RAY_HEIGHT = 1000

function TerrainScanner.Scan()
    local startTime = os.clock()
    print("🛰️ [Scanner] Optimized RayDiscovery Initiated (X,Z only)...")
    
    local terrain = Workspace.Terrain
    local nodes = {}
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {terrain}

    for x = -MAP_BOUNDS, MAP_BOUNDS, SCAN_GRID do
        -- Batch yielding manually to target <2s scan time
        for z = -MAP_BOUNDS, MAP_BOUNDS, SCAN_GRID do
            local startPos = Vector3.new(x, RAY_HEIGHT, z)
            local result = Workspace:Raycast(startPos, Vector3.new(0, -RAY_HEIGHT * 2, 0), params)
            
            if result and result.Material then
                table.insert(nodes, {
                    p = {result.Position.X, result.Position.Y, result.Position.Z},
                    m = result.Material.Name
                })
            end
        end
        if (x/SCAN_GRID) % 5 == 0 then task.wait() end
    end

    print(string.format("🛰️ [Scanner] Scan complete. Found %d nodes in %.4f seconds.", #nodes, os.clock() - startTime))
    return nodes
end

return TerrainScanner
