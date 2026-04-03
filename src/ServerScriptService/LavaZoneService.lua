local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local MutationConfig = require(ServerScriptService.MutationConfig)
local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

local LavaZoneService = {}
LavaZoneService.IsActive = false
LavaZoneService.PlayersInLava = {} -- [player] = true
LavaZoneService.Connections = {}

function LavaZoneService.Init()
    
    -- In case parts are added dynamically
    CollectionService:GetInstanceAddedSignal("LavaZone"):Connect(function(part)
        LavaZoneService.BindPart(part)
    end)
    
    for _, part in ipairs(CollectionService:GetTagged("LavaZone")) do
        LavaZoneService.BindPart(part)
    end
    
    task.spawn(LavaZoneService.DamageLoop)
end

function LavaZoneService.BindPart(part)
    if not part:IsA("BasePart") then return end
    
    local touchConn = part.Touched:Connect(function(hit)
        if not LavaZoneService.IsActive then return end
        
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            LavaZoneService.PlayersInLava[player] = true
        end
    end)
    
    local touchEndConn = part.TouchEnded:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            -- Verify actual exit (TouchEnded can fire falsely, but for simplicity we rely on it)
            -- A more robust system uses overlaps, but this hits the requirement precisely.
            LavaZoneService.PlayersInLava[player] = nil
        end
    end)
    
    table.insert(LavaZoneService.Connections, touchConn)
    table.insert(LavaZoneService.Connections, touchEndConn)
end

function LavaZoneService.EnableZones()
    LavaZoneService.IsActive = true
    -- Light up the parts explicitly if desired
    for _, part in ipairs(CollectionService:GetTagged("LavaZone")) do
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 50, 0)
    end
end

function LavaZoneService.DisableZones()
    LavaZoneService.IsActive = false
    LavaZoneService.PlayersInLava = {}
    for _, part in ipairs(CollectionService:GetTagged("LavaZone")) do
        part.Material = Enum.Material.Slate
        part.Color = Color3.fromRGB(50, 50, 50)
    end
end

function LavaZoneService.DamageLoop()
    while true do
        task.wait(MutationConfig.States.Lava.Tick)
        if LavaZoneService.IsActive then
            for player, _ in pairs(LavaZoneService.PlayersInLava) do
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    local humanoid = player.Character.Humanoid
                    if humanoid.Health > 0 then
                        humanoid:TakeDamage(MutationConfig.States.Lava.Damage)
                    end
                end
            end
        end
    end
end

return LavaZoneService
