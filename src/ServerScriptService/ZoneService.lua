local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ZoneService = {
    Zones = {},
    LastSwitchTime = {},
    LastZone = {},
    _initialized = false
}

-- ⚙️ CONFIGURATION
local TICK_RATE = 0.5  
local SCAN_RATE = 0.2 
local SWITCH_DELAY = 1.0 

local MATERIAL_EFFECT_MAP = {
    Lava = { Poison = 1.0, Cold = 0, Regen = 0 },
    Toxic = { Poison = 0.5, Cold = 0, Regen = 0 },
    Frozen = { Poison = 0, Cold = 1.0, Regen = 0 },
    Jungle = { Poison = 0, Cold = 0, Regen = 1.0 },
    Radiation = { Poison = 1.0, Cold = 0, Regen = 0 }
}

local MATERIAL_TO_TYPE = {
    [Enum.Material.Snow] = "Frozen",
    [Enum.Material.Sand] = "Toxic",
    [Enum.Material.CrackedLava] = "Lava",
    [Enum.Material.Mud] = "Toxic",
    [Enum.Material.Basalt] = "Lava",
    [Enum.Material.Slate] = "Radiation",
    [Enum.Material.Grass] = "Jungle",
    [Enum.Material.LeafyGrass] = "Jungle"
}

function ZoneService.Init(zones)
    if ZoneService._initialized then return end
    ZoneService._initialized = true
    ZoneService.Zones = zones
    print(string.format("🌊 [ZoneService] Blended Gameplay Engine Online..."))

    task.spawn(function()
        while true do
            for _, player in ipairs(Players:GetPlayers()) do
                ZoneService.UpdateInfluences(player)
            end
            task.wait(SCAN_RATE)
        end
    end)

    task.spawn(function()
        while true do
            for _, player in ipairs(Players:GetPlayers()) do
                ZoneService.ApplyTick(player)
            end
            task.wait(TICK_RATE)
        end
    end)
end

-- 🌿 PERSISTENT GROUND DETECTION (Exclude Character Fix)
local function getTerrainInfluence(player, pos)
    local char = player.Character
    if not char then return nil end

    local rayDirection = Vector3.new(0, -300, 0)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char} -- 🛡️ DO NOT HIT THE PLAYER
    rayParams.FilterType = Enum.RaycastFilterType.Exclude 
    
    local result = Workspace:Raycast(pos, rayDirection, rayParams)
    if result and result.Instance:IsA("Terrain") then
        return MATERIAL_TO_TYPE[result.Material]
    end
    return nil
end

function ZoneService.UpdateInfluences(player)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local id = player.UserId
    local pos = hrp.Position
    local influences = {}
    local totalWeight = 0

    for _, zone in ipairs(ZoneService.Zones) do
        local dist = (pos - zone.position).Magnitude
        local radius = zone.size.X / 2
        if dist < radius then
            local weight = 1 - (dist / radius)
            totalWeight = totalWeight + weight
            table.insert(influences, { type = zone.type, weight = weight })
        end
    end

    -- 🔍 2. GROUND STICKINESS (Fixed: Passing player for exclusion)
    local terrainType = getTerrainInfluence(player, pos)
    if terrainType then
        totalWeight = totalWeight + 1.5 
        table.insert(influences, { type = terrainType, weight = 1.5 })
    end

    local poison, cold, regen = 0, 0, 0
    local dominant = "Wilderness"
    local maxW = 0

    for _, z in ipairs(influences) do
        local normWeight = z.weight / (totalWeight > 0 and totalWeight or 1)
        local stats = MATERIAL_EFFECT_MAP[z.type]
        if stats then
            poison = poison + (stats.Poison * normWeight)
            cold = cold + (stats.Cold * normWeight)
            regen = regen + (stats.Regen * normWeight)
        end
        if normWeight > maxW then
            maxW = normWeight
            dominant = z.type
        end
    end

    -- 🛡️ HYSTERESIS SWITCH
    local timeNow = os.clock()
    if dominant ~= ZoneService.LastZone[id] then
        if not ZoneService.LastSwitchTime[id] or (timeNow - ZoneService.LastSwitchTime[id]) > SWITCH_DELAY then
            ZoneService.LastSwitchTime[id] = timeNow
            ZoneService.LastZone[id] = dominant
            player:SetAttribute("CurrentZone", dominant)
            print(string.format("🔄 [ZoneService] Stable Switch: %s → %s", player.Name, dominant))
        end
    end

    player:SetAttribute("PoisonLevel", poison)
    player:SetAttribute("ColdLevel", cold)
    player:SetAttribute("RegenLevel", regen)
end

function ZoneService.ApplyTick(player)
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local poison = player:GetAttribute("PoisonLevel") or 0
    local cold = player:GetAttribute("ColdLevel") or 0
    local regen = player:GetAttribute("RegenLevel") or 0

    local totalDamage = (poison * 1.5) + (cold * 0.8)
    local totalHeal = (regen * 1.5)

    if totalDamage > 0 then humanoid:TakeDamage(totalDamage) end
    if totalHeal > 0 and humanoid.Health < humanoid.MaxHealth then
        humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + totalHeal)
    end
end

return ZoneService
