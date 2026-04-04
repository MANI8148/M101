local Players = game:GetService("Players")

local PlayerState = {}
local states = {} -- [userId] = { health, hunger, mutation, effects={} }

function PlayerState.Get(player)
    local id = player.UserId
    if not states[id] then
        states[id] = {
            Health = 100,
            Hunger = 100,
            Mutation = 0,
            ActiveEffects = {}
        }
        -- Sync to Attributes for UI
        player:SetAttribute("Health", 100)
        player:SetAttribute("Hunger", 100)
        player:SetAttribute("Mutation", 0)
    end
    return states[id]
end

function PlayerState.Update(player, key, value)
    local state = PlayerState.Get(player)
    state[key] = value
    player:SetAttribute(key, value)
end

function PlayerState.SetEffect(player, effectName, active)
    local state = PlayerState.Get(player)
    state.ActiveEffects[effectName] = active
    
    -- Compact list for UI attribute
    local list = {}
    for name, isActive in pairs(state.ActiveEffects) do
        if isActive then table.insert(list, name) end
    end
    player:SetAttribute("ActiveEffects", table.concat(list, ","))
end

-- Server Cleanup
Players.PlayerRemoving:Connect(function(player)
    states[player.UserId] = nil
end)

return PlayerState
