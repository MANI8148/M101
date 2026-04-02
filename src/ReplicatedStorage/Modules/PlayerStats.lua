local PlayerStats = {}
PlayerStats.__index = PlayerStats

function PlayerStats.new(player)
    local self = setmetatable({}, PlayerStats)
    self.Player = player
    
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    local hunger = Instance.new("IntValue")
    hunger.Name = "Hunger"
    hunger.Value = 100
    hunger.Parent = leaderstats
    
    local health = Instance.new("IntValue")
    health.Name = "Health"
    health.Value = 100
    health.Parent = leaderstats
    
    local kills = Instance.new("IntValue")
    kills.Name = "Kills"
    kills.Value = 0
    kills.Parent = leaderstats
    
    local score = Instance.new("IntValue")
    score.Name = "Score"
    score.Value = 0
    score.Parent = leaderstats
    
    local function setupCharacter(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then
            -- Persist stats on respawn
            humanoid.Health = health.Value
            
            -- Detect when player takes damage or heals
            humanoid.HealthChanged:Connect(function(newHealth)
                health.Value = newHealth
            end)
        end
    end
    
    if player.Character then
        setupCharacter(player.Character)
    end
    player.CharacterAdded:Connect(setupCharacter)
    
    return self
end

function PlayerStats:GetHunger()
    local leaderstats = self.Player:FindFirstChild("leaderstats")
    if leaderstats then
        local hunger = leaderstats:FindFirstChild("Hunger")
        if hunger then return hunger.Value end
    end
    return 0
end

function PlayerStats:SetHunger(amount)
    local leaderstats = self.Player:FindFirstChild("leaderstats")
    if leaderstats then
        local hunger = leaderstats:FindFirstChild("Hunger")
        if hunger then
            hunger.Value = math.clamp(amount, 0, 100)
        end
    end
end

function PlayerStats:Damage(amount)
    local character = self.Player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:TakeDamage(amount)
        end
    end
end

return PlayerStats
