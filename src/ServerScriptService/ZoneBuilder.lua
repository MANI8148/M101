local Workspace = game:GetService("Workspace")

local ZoneBuilder = {}

function ZoneBuilder.Build(chunks, chunkSize)
    local MAX_CLUSTER_SIZE = 6
    local zonesFolder = Workspace:FindFirstChild("Zones")
    if not zonesFolder then
        zonesFolder = Instance.new("Folder")
        zonesFolder.Name = "Zones"
        zonesFolder.Parent = Workspace
    end

    -- Clustering using a grid hash
    local grid = {} -- [chunkHash] = chunk
    for _, chunk in ipairs(chunks) do
        local hash = math.floor(chunk.Position.X / chunkSize) .. "_" .. math.floor(chunk.Position.Z / chunkSize)
        grid[hash] = chunk
    end

    local visited = {}
    local clusters = {}

    for hash, chunk in pairs(grid) do
        if not visited[hash] then
            -- flood fill component
            local cluster = {Type = chunk.Type, Material = chunk.Material, Chunks = {}}
            local queue = {hash}
            visited[hash] = true

            while #queue > 0 do
                local currentHash = table.remove(queue, 1)
                local currentChunk = grid[currentHash]
                table.insert(cluster.Chunks, currentChunk)

                -- 🛡 Capping cluster size to prevent over-merging
                if #cluster.Chunks >= MAX_CLUSTER_SIZE then
                    continue
                end

                -- check neighbors (up, down, left, right)
                local cx, cz = currentHash:match("^(%-?%d+)_(%-?%d+)$")
                cx, cz = tonumber(cx), tonumber(cz)

                local neighbors = {
                    (cx + 1) .. "_" .. cz, (cx - 1) .. "_" .. cz,
                    cx .. "_" .. (cz + 1), cx .. "_" .. (cz - 1)
                }

                for _, nHash in ipairs(neighbors) do
                    local nChunk = grid[nHash]
                    if nChunk and not visited[nHash] and nChunk.Type == cluster.Type then
                        visited[nHash] = true
                        table.insert(queue, nHash)
                    end
                end
            end
            table.insert(clusters, cluster)
        end
    end

    -- Create 1 part per cluster
    local createdZones = {}
    for _, cluster in ipairs(clusters) do
        -- Calculate bounding box (O(n^2) columns merged into 3D volumes)
        local minX, minZ = math.huge, math.huge
        local maxX, maxZ = -math.huge, -math.huge
        
        -- Fix: Ensure zones are vertically large enough to detect players at any height
        local minY, maxY = -500, 1000 

        for _, chunk in ipairs(cluster.Chunks) do
            local pos = chunk.Position
            minX, minZ = math.min(minX, pos.X - chunkSize/2), math.min(minZ, pos.Z - chunkSize/2)
            maxX, maxZ = math.max(maxX, pos.X + chunkSize/2), math.max(maxZ, pos.Z + chunkSize/2)
        end

        local size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
        local center = Vector3.new((maxX + minX) / 2, (maxY + minY) / 2, (maxZ + minZ) / 2)

        local part = Instance.new("Part")
        part.Name = cluster.Type
        part.Size = size
        part.Position = center
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.CastShadow = false
        part:SetAttribute("ZoneType", cluster.Type)
        part.Parent = zonesFolder
        
        table.insert(createdZones, part)
    end

    print("[ZoneBuilder] Created", #createdZones, "clustered zones.")
    return createdZones
end

return ZoneBuilder
