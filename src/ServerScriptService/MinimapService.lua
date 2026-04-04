local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MinimapService = {}

-- ⚙️ CONFIGURATION
local MAX_SCAN_RANGE = 2048 -- Absolute max to look for terrain
local RESOLUTION = 64       -- Number of pixels across (64x64)

MinimapService.CachedMapData = {}

function MinimapService.Init()
    local events = ReplicatedStorage:FindFirstChild("Events")
    local start = os.clock()
    while not events and (os.clock() - start) < 3 do
        task.wait()
        events = ReplicatedStorage:FindFirstChild("Events")
    end
    assert(events, "❌ [MinimapService] Infrastructure Fault: Events missing.")
    
    local remote = events:FindFirstChild("MinimapRemote")
    start = os.clock()
    while not remote and (os.clock() - start) < 3 do
        task.wait()
        remote = events:FindFirstChild("MinimapRemote")
    end
    assert(remote, "❌ [MinimapService] Infrastructure Fault: MinimapRemote missing.")
    
    print("🗺️ [MinimapService] Calculating Dynamic Terrain Extents...")
    MinimapService.GenerateDynamicMapData()
    
    game.Players.PlayerAdded:Connect(function(player)
        task.wait(2)
        if MinimapService.CachedMapData then
            print("📡 [Minimap] Syncing dynamic map to: " .. player.Name)
            remote:FireClient(player, MinimapService.CachedMapData)
        end
    end)
    
    remote:FireAllClients(MinimapService.CachedMapData)
end

function MinimapService.GenerateDynamicMapData()
    local startTime = os.clock()
    local terrain = Workspace.Terrain
    
    -- 1. 🔭 SCAN FOR ACTUAL BOUNDS
    local minX, maxX = 10000, -10000
    local minZ, maxZ = 10000, -10000
    local foundAny = false

    -- Coarse scan to find the island edges
    for x = -MAX_SCAN_RANGE, MAX_SCAN_RANGE, 64 do
        for z = -MAX_SCAN_RANGE, MAX_SCAN_RANGE, 64 do
            local result = Workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -600, 0))
            if result and result.Instance:IsA("Terrain") then
                minX = math.min(minX, x)
                maxX = math.max(maxX, x)
                minZ = math.min(minZ, z)
                maxZ = math.max(maxZ, z)
                foundAny = true
            end
        end
    end

    if not foundAny then
        warn("⚠️ [MinimapService] No terrain detected within range! Defaulting to origin.")
        minX, maxX, minZ, maxZ = -256, 256, -256, 256
    end

    -- Add a small padding (50 studs)
    minX -= 50; maxX += 50
    minZ -= 50; maxZ += 50

    local width = maxX - minX
    local height = maxZ - minZ
    local stepX = width / RESOLUTION
    local stepZ = height / RESOLUTION

    print(string.format("📐 [Minimap] Island Bounds: Min(%d, %d) Max(%d, %d)", minX, minZ, maxX, maxZ))

    -- 2. 🎨 DETAILED SCAN WITHIN BOUNDS
    local map = {}
    for i = 0, RESOLUTION do
        local row = {}
        for j = 0, RESOLUTION do
            local x = minX + (i * stepX)
            local z = minZ + (j * stepZ)
            
            local result = Workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -600, 0))
            if result and result.Instance:IsA("Terrain") then
                row[j] = result.Material.Name
            else
                row[j] = "Empty"
            end
        end
        map[i] = row
        if i % 16 == 0 then task.wait() end
    end
    
    -- Cache metadata for client scaling
    MinimapService.CachedMapData = {
        matrix = map,
        extents = { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ },
        resolution = RESOLUTION
    }
    
    print(string.format("🗺️ [MinimapService] Auto-Fit Matrix complete in %.4f seconds.", os.clock() - startTime))
end

return MinimapService
