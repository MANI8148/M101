local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local MutationConfig = require(ServerScriptService.MutationConfig)
local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

local MutationService = {}
MutationService.ActiveBuffs = {} -- Stores [player] = { ["MutationName"] = true }

-- Central table mapping mutations to effects using Config
MutationService.Mutations = {
    ["SpeedBoost"] = {
        Apply = function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = humanoid.WalkSpeed + MutationConfig.Mutations.SpeedBoost.Amount
            end
        end,
        Remove = function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = humanoid.WalkSpeed - MutationConfig.Mutations.SpeedBoost.Amount
            end
        end,
        AllowStacking = false
    },
    ["JumpBoost"] = {
        Apply = function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.UseJumpPower = true
                humanoid.JumpPower = humanoid.JumpPower + MutationConfig.Mutations.JumpBoost.Amount
            end
        end,
        Remove = function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.UseJumpPower = true
                humanoid.JumpPower = humanoid.JumpPower - MutationConfig.Mutations.JumpBoost.Amount
            end
        end,
        AllowStacking = false
    }
}

function MutationService.Init()
    ServiceRegistry:Register("MutationService", MutationService)

    -- Clean up memory properly 
    Players.PlayerRemoving:Connect(function(player)
        MutationService.ActiveBuffs[player] = nil
    end)
    
    -- Reapply mutations when player respawns automatically
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid", 10)
            if humanoid then
                local buffs = MutationService.ActiveBuffs[player]
                if buffs then
                    for mutationName, active in pairs(buffs) do
                        if active then
                            local mutData = MutationService.Mutations[mutationName]
                            if mutData and mutData.Apply then
                                mutData.Apply(character)
                            end
                        end
                    end
                end
            end
        end)
    end)
end

function MutationService.AddMutation(player, mutationName)
    local mutData = MutationService.Mutations[mutationName]
    if not mutData then return false end
    
    if not MutationService.ActiveBuffs[player] then
        MutationService.ActiveBuffs[player] = {}
    end
    
    local activeMutations = MutationService.ActiveBuffs[player]
    if activeMutations[mutationName] and not mutData.AllowStacking then
        warn("Player " .. player.Name .. " already has mutation " .. mutationName)
        return false -- Prevent duplicate stacking seamlessly
    end
    
    activeMutations[mutationName] = true
    
    if player.Character then
        mutData.Apply(player.Character)
    end
    
    print(player.Name .. " gained mutation: " .. mutationName)
    return true
end

function MutationService.RemoveMutation(player, mutationName)
    local mutData = MutationService.Mutations[mutationName]
    if not mutData then return false end
    
    if not MutationService.ActiveBuffs[player] then return false end
    
    -- Only remove buffs that explicitly exist in the player's table
    if MutationService.ActiveBuffs[player][mutationName] then
        MutationService.ActiveBuffs[player][mutationName] = nil
        
        if player.Character then
            mutData.Remove(player.Character)
        end
        
        print(player.Name .. " lost mutation: " .. mutationName)
        return true
    end
    return false
end

return MutationService
