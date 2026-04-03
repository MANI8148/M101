local Workspace = game:GetService("Workspace")

local TerrainAnalyzer = {}

function TerrainAnalyzer.Scan(boundsMin, boundsMax, chunkSize, resolution, materialMap, voxelThreshold)
    local terrain = Workspace:FindFirstChildWhichIsA("Terrain")
    if not terrain then return {} end

    local threshold = voxelThreshold or 50
    local chunks = {}
    local yieldCount = 0

    for x = boundsMin.X, boundsMax.X, chunkSize do
        for z = boundsMin.Z, boundsMax.Z, chunkSize do
            -- O(n^2) Optimized: We only scan X and Z, then look at the highest voxels
            local minCoord = Vector3.new(x, boundsMin.Y, z)
            local maxCoord = Vector3.new(x + chunkSize, boundsMax.Y, z + chunkSize)
            local region = Region3.new(minCoord, maxCoord):ExpandToGrid(resolution)

            local success, materials, occupancies = pcall(function()
                return terrain:ReadVoxels(region, resolution)
            end)

            if success and materials and occupancies then
                local counts = {}
                local sizeX, sizeY, sizeZ = materials.Size.X, materials.Size.Y, materials.Size.Z
                
                -- Optimization: Process surface-level materials (Top-Down)
                for vx = 1, sizeX do
                    for vz = 1, sizeZ do
                        yieldCount = yieldCount + 1
                        if yieldCount % 500 == 0 then task.wait() end

                        -- Find topmost voxel in this column
                        for vy = sizeY, 1, -1 do
                            local mat = materials[vx][vy][vz]
                            local occ = occupancies[vx][vy][vz]
                            
                            if occ > 0.5 and materialMap[mat] then
                                counts[mat] = (counts[mat] or 0) + 1
                                break -- Next (vx, vz) column
                            elseif occ > 0.5 then
                                break -- Found solid ground but NOT a zone material (e.g. Rock), skip this column
                            end
                        end
                    end
                end

                -- Determine dominant material
                local dominantMat = nil
                local maxCount = 0
                for mat, count in pairs(counts) do
                    if count > maxCount then
                        maxCount = count
                        dominantMat = mat
                    end
                end

                if dominantMat and maxCount > threshold then
                    table.insert(chunks, {
                        Position = minCoord + Vector3.new(chunkSize/2, (boundsMax.Y - boundsMin.Y)/2, chunkSize/2),
                        Material = dominantMat,
                        Type = materialMap[dominantMat]
                    })
                end
            end
            
            task.wait() -- Cooperative yield per large chunk column
        end
    end

    return chunks
end

return TerrainAnalyzer
