local ServerScriptService = game:GetService("ServerScriptService")
local PlayerState = require(ServerScriptService.PlayerState)

local EffectService = {}
local activeTimers = {} -- [userId] = { [effectName] = timerId }

-- 🩹 EFFECT DEFINITIONS
local EFFECTS = {
    Burn = { tick = 1, damage = 5, visual = "🔥" },
    Poison = { tick = 2, damage = 3, visual = "💀" },
    Slow = { speed = 8, visual = "❄️" },
    Regen = { tick = 2, heal = 4, visual = "🌿" },
}

-- 🧪 ZONE TO EFFECT MAP
local ZONE_EFFECT_MAP = {
    Lava = "Burn",
    Toxic = "Poison",
    Frozen = "Slow",
    Jungle = "Regen",
}

function EffectService.Apply(player, name, duration)
    local config = EFFECTS[name]
    if not config then return end
    
    local userId = player.UserId
    if not activeTimers[userId] then activeTimers[userId] = {} end
    
    -- 🛡 Comparison vs Nil protection
    local lastTickTime = activeTimers[userId][name] or 0
    local now = tick()
    
    if lastTickTime > 0 then
        -- Refresh existing effect
        activeTimers[userId][name] = now
    else
        -- Start New Effect Logic Loop
        activeTimers[userId][name] = now
        PlayerState.SetEffect(player, name, true)
        
        task.spawn(function()
            local startTime = now
            local expireAt = startTime + duration
            
            while player and player.Parent and tick() < expireAt do
                local timer = activeTimers[userId][name] or 0
                if timer > startTime then return end
                
                local char = player.Character
                local hum = char and char:FindFirstChild("Humanoid")
                
                if hum then
                    if config.damage then hum:TakeDamage(config.damage) end
                    if config.heal then hum.Health = math.min(hum.MaxHealth, hum.Health + config.heal) end
                    if config.speed then hum.WalkSpeed = config.speed end
                end
                
                task.wait(config.tick or 1)
            end
            
            EffectService.Remove(player, name)
        end)
    end
end

function EffectService.Remove(player, name)
    local id = player.UserId
    if activeTimers[id] and activeTimers[id][name] then
        activeTimers[id][name] = nil
        PlayerState.SetEffect(player, name, false)
        
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then
             local config = EFFECTS[name]
             if config and config.speed then hum.WalkSpeed = 16 end
        end
    end
end

-- ⚡ ADDED AT LEUSER REQUEST: CLEAR ALL EFFECTS
function EffectService.ClearAll(player)
    local id = player.UserId
    if activeTimers[id] then
        for name, _ in pairs(activeTimers[id]) do
            EffectService.Remove(player, name)
        end
    end
end

return EffectService
