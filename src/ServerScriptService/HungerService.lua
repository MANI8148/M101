local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerStats = require(ReplicatedStorage.Modules.PlayerStats)

local HungerService = {}
HungerService.PlayerProfiles = {}

function HungerService.Init()
    -- Initialize for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        HungerService.PlayerAdded(player)
    end
    
    -- Listen for new players
    Players.PlayerAdded:Connect(HungerService.PlayerAdded)
    Players.PlayerRemoving:Connect(HungerService.PlayerRemoving)
    
    -- Start hunger loop
    task.spawn(HungerService.StartLoop)
end

function HungerService.PlayerAdded(player)
    local stats = PlayerStats.new(player)
    HungerService.PlayerProfiles[player.UserId] = stats
end

function HungerService.PlayerRemoving(player)
    HungerService.PlayerProfiles[player.UserId] = nil
end

function HungerService.GetProfile(player)
    return HungerService.PlayerProfiles[player.UserId]
end

function HungerService.StartLoop()
    if HungerService._running then return end
    HungerService._running = true
    
    while true do
        task.wait(5)
        
        for userId, stats in pairs(HungerService.PlayerProfiles) do
            if stats.Player.Character and stats.Player.Character:FindFirstChild("Humanoid") then
                local humanoid = stats.Player.Character.Humanoid
                if humanoid.Health > 0 then
                    local currentHunger = stats:GetHunger()
                    
                    if currentHunger > 0 then
                        -- Decrease hunger by 5
                        stats:SetHunger(currentHunger - 5)
                    else
                        -- If hunger is 0, decrease health by 5
                        stats:Damage(5)
                    end
                end
            end
        end
    end
end

return HungerService
