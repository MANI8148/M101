local ServerScriptService = game:GetService("ServerScriptService")
local PlayerState = require(ServerScriptService.PlayerState)

local MutationService = {}
local exposures = {} -- [userId] = exposurePoints

-- 🧬 MUTATION TIERS
local THRESHOLDS = {
    [10] = "Thermal Resistance",
    [30] = "Toxic Resistance",
    [60] = "Gamma Pulse",
    [100] = "Apex Predator"
}

function MutationService.Init()
    print("🧬 [MutationService] Stability monitoring active.")
end

function MutationService.Expose(player)
    local id = player.UserId
    if not exposures[id] then exposures[id] = 0 end
    
    -- Start Exposure Loop
    task.spawn(function()
        local ServiceRegistry = require(ServerScriptService.ServiceRegistry)
        local ZoneService = ServiceRegistry:Get("ZoneService")
        
        while player and player.Parent and ZoneService.PlayerZones[player] == "Radiation" do
            exposures[id] = exposures[id] + 1
            PlayerState.Update(player, "Mutation", exposures[id])
            
            -- Check for Tier Upgrades
            for threshold, name in pairs(THRESHOLDS) do
                if exposures[id] == threshold then
                    print(string.format("🧬 [Mutation] %s has evolved: %s unlocked!", player.Name, name))
                    -- Random Stat Bonus
                    local char = player.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    if hum then
                        hum.MaxHealth = hum.MaxHealth + 10
                        hum.Health = hum.MaxHealth
                    end
                end
            end
            
            task.wait(1)
        end
    end)
end

function MutationService.AddMutation(player, code)
    -- Manual/External mutation addition
    local id = player.UserId
    exposures[id] = (exposures[id] or 0) + 10 -- Grant 10 points
    PlayerState.Update(player, "Mutation", exposures[id])
end

return MutationService
