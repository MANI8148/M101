local ServerScriptService = game:GetService("ServerScriptService")

local ZoneMutationService = {}

-- ⚙️ CONFIGURATION
local MUTATION_CHANCE = 0.1 -- 10% chance per zone per cycle
local INTERVAL = 60 -- Every minute

local TYPES = {"Lava", "Frozen", "Toxic", "Radiation", "Jungle"}

local VISUALS = {
    Lava = { Material = Enum.Material.CrackedLava, Color = Color3.fromRGB(200, 50, 50) },
    Frozen = { Material = Enum.Material.Snow, Color = Color3.fromRGB(150, 200, 255) },
    Toxic = { Material = Enum.Material.Mud, Color = Color3.fromRGB(100, 50, 150) },
    Radiation = { Material = Enum.Material.Neon, Color = Color3.fromRGB(50, 200, 50) },
    Jungle = { Material = Enum.Material.Grass, Color = Color3.fromRGB(50, 150, 50) }
}

function ZoneMutationService.Init()
    print("🧬 [Mutation] Initialization... Advanced infection mode active.")
    
    task.spawn(function()
        while true do
            task.wait(INTERVAL)
            ZoneMutationService.RunMutationCycle()
            print("🧬 [Mutation] Spread cycle complete.")
        end
    end)
end

function ZoneMutationService.RunMutationCycle()
    local ZoneManager = require(ServerScriptService.ZoneGenerator)
    local clusters = ZoneManager.Clusters
    if not clusters or #clusters == 0 then return end

    local zonesFolder = workspace:FindFirstChild("Zones")
    if not zonesFolder then return end

    -- 🧬 Probability-based spread on existing cluster set
    for _, clusterData in ipairs(clusters) do
        if math.random() < MUTATION_CHANCE then
            -- Mutation Logic
            local newType = TYPES[math.random(1, #TYPES)]
            
            -- Find the physical part associated with this cluster
            local part = nil
            for _, obj in ipairs(zonesFolder:GetChildren()) do
                if obj:GetAttribute("ClusterId") == clusterData.id then
                    part = obj
                    break
                end
            end

            if part then
                ZoneMutationService.ChangeZoneType(clusterData, part, newType)
            end
        end
    end
end

function ZoneMutationService.ChangeZoneType(cluster, part, newType)
    -- 🛡 DATA SYNC
    cluster.type = newType
    part:SetAttribute("ZoneType", newType)
    part.Name = newType .. "_Zone"

    -- 🧱 VISUAL SYNC
    local visual = VISUALS[newType]
    if visual then
        part.Material = visual.Material
        part.Color = visual.Color
    end

    -- ⚡ REGISTRY RESET: Service registry logic triggered via attribute change 
    -- if any listeners are attached, but Cluster list updated in-memory above.
end

return ZoneMutationService
