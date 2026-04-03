print("🔥 Terrain Generator STARTED")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

-- Configuration
local CHUNK_SIZE = 64 -- Read 64x64x64 studs per batch
local VOXEL_RESOLUTION = 4

-- Map Terrain material to ZoneType strings
local MATERIAL_MAP = {
    [Enum.Material.Lava] = "Lava",
    [Enum.Material.Snow] = "Frozen",
    [Enum.Material.Grass] = "Jungle",
    [Enum.Material.Sand] = "Toxic",
    [Enum.Material.Mud] = "Toxic",
}

local function buildTerrainZones()
    print("[TerrainZoneGenerator] Starting map voxel scan...")
    local startTime = os.clock()
    
    -- Robustness: Ensure terrain exists before scanning
    local terrain = Workspace:FindFirstChildWhichIsA("Terrain")
    if not terrain then
        warn("[TerrainZoneGenerator] CRITICAL: Failed to find Terrain in Workspace. Aborting generator.")
        return
    end
    
    -- Ensure the Zones folder exists in Workspace securely
    local zonesFolder = Workspace:FindFirstChild("Zones")
    if not zonesFolder then
        zonesFolder = Instance.new("Folder")
        zonesFolder.Name = "Zones"
        zonesFolder.Parent = Workspace
    end

    -- Scanning bounded area dynamically. Maps heavily isolated server-stress limits efficiently
    local mapMin = Vector3.new(-1024, -128, -1024)
    local mapMax = Vector3.new(1024, 256, 1024)

    local partCount = 0

    for x = mapMin.X, mapMax.X, CHUNK_SIZE do
        for y = mapMin.Y, mapMax.Y, CHUNK_SIZE do
            for z = mapMin.Z, mapMax.Z, CHUNK_SIZE do
                local minCoord = Vector3.new(x, y, z)
                local maxCoord = Vector3.new(x + CHUNK_SIZE, y + CHUNK_SIZE, z + CHUNK_SIZE)
                
                -- Error Avoidance: Region3 for voxel reads MUST be bounded strictly to voxel grids correctly
                local region = Region3.new(minCoord, maxCoord):ExpandToGrid(VOXEL_RESOLUTION)
                
                -- Robustness: Guarding against read failure and malformed server arrays preventing runtime crashes
                local success, materials, occupancies = pcall(function()
                    return terrain:ReadVoxels(region, VOXEL_RESOLUTION)
                end)

                if success and materials and occupancies then
                    -- Map: Material Enum -> {min=Vector3, max=Vector3}
                    local materialBounds = {}
                    
                    local sizeX = materials.Size.X
                    local sizeY = materials.Size.Y
                    local sizeZ = materials.Size.Z
                    
                    if sizeX and sizeY and sizeZ then
                        -- Optimization: Calculate local offset to convert voxel indices directly back into world positions efficiently mathematically 
                        local regionMin = region.CFrame.Position - (region.Size / 2)
                        
                        for vx = 1, sizeX do
                            for vy = 1, sizeY do
                                for vz = 1, sizeZ do
                                    -- Error Handling: Safety check against nil array indexing natively causing out of bounds crash vectors
                                    local matCol = materials[vx]
                                    local occCol = occupancies[vx]
                                    
                                    if matCol and occCol and matCol[vy] and occCol[vy] then
                                        local mat = matCol[vy][vz]
                                        local occ = occCol[vy][vz]
                                        
                                        -- Optimization: Filter out low surface occupancy geometry traces (< 0.5 solid mass) and validate our dictionary array strictly
                                        if occ and occ > 0.5 and mat and MATERIAL_MAP[mat] then
                                            local worldPos = regionMin + Vector3.new(
                                                (vx - 0.5) * VOXEL_RESOLUTION,
                                                (vy - 0.5) * VOXEL_RESOLUTION,
                                                (vz - 0.5) * VOXEL_RESOLUTION
                                            )
                                            
                                            -- Aggregate min/max coordinates globally binding the entire chunk to bounds
                                            if not materialBounds[mat] then
                                                materialBounds[mat] = {min = worldPos, max = worldPos}
                                            else
                                                local bMin = materialBounds[mat].min
                                                local bMax = materialBounds[mat].max
                                                materialBounds[mat].min = Vector3.new(
                                                    math.min(bMin.X, worldPos.X),
                                                    math.min(bMin.Y, worldPos.Y),
                                                    math.min(bMin.Z, worldPos.Z)
                                                )
                                                materialBounds[mat].max = Vector3.new(
                                                    math.max(bMax.X, worldPos.X),
                                                    math.max(bMax.Y, worldPos.Y),
                                                    math.max(bMax.Z, worldPos.Z)
                                                )
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Group the gathered boundaries logically forming 1 single Part rendering for all of a material spread into the entire 64x64 sub-chunk inherently achieving optimal server part handling.
                        for mat, bound in pairs(materialBounds) do
                            local zoneType = MATERIAL_MAP[mat]
                            
                            -- Padded margin achieving bounded limits across the full 4 stud width exactly isolating edges natively
                            local size = (bound.max - bound.min) + Vector3.new(VOXEL_RESOLUTION, VOXEL_RESOLUTION, VOXEL_RESOLUTION)
                            local center = (bound.max + bound.min) / 2
                            
                            -- Ignore completely redundant / minuscule micro parts natively mapping under limits
                            if size.Magnitude > VOXEL_RESOLUTION then
                                local part = Instance.new("Part")
                                part.Name = zoneType
                                part.Size = size
                                part.Position = center
                                
                                part.Anchored = true
                                part.CanCollide = false
                                part.Transparency = 1
                                part.CastShadow = false
                                
                                -- Binding attributes explicitly natively utilized across the server
                                part:SetAttribute("ZoneType", zoneType)
                                
                                -- Sync hooks natively to the broader codebase ZoneService tracker pattern 
                                CollectionService:AddTag(part, "Zone")
                                
                                -- Explicitly attach for specialized hook targeting with Lava properties
                                if zoneType == "Lava" then
                                    CollectionService:AddTag(part, "LavaZone")
                                end
                                
                                part.Parent = zonesFolder
                                partCount = partCount + 1
                            end
                        end
                    end
                else
                    warn(string.format("[TerrainZoneGenerator] Debug Fail: Array chunk read failed gracefully at %s using pcall.", tostring(minCoord)))
                end
                
                -- Optimization yielding batches allowing heartbeat stability natively against main thread spikes 
                task.wait()
            end
        end
    end
    print(string.format("[TerrainZoneGenerator] Successfully baked %d zones dynamically into Workspace in %.2f seconds natively!", partCount, os.clock() - startTime))
end

task.spawn(buildTerrainZones)
