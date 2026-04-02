local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServiceRegistry = require(ServerScriptService.ServiceRegistry)
local MutationConfig = require(ServerScriptService.MutationConfig)

local CombatService = {}
CombatService.Cooldowns = {}

function CombatService.Init()
    ServiceRegistry:Register("CombatService", CombatService)
    
    -- Cleanup Data securely against memory leaks
    Players.PlayerRemoving:Connect(function(player)
        CombatService.Cooldowns[player.UserId] = nil
    end)
    
    local events = ReplicatedStorage:FindFirstChild("Events")
    local attackEvent = events:FindFirstChild("MeleeAttack") or Instance.new("RemoteEvent")
    attackEvent.Name = "MeleeAttack"
    attackEvent.Parent = events
    
    local killFeedEvent = events:FindFirstChild("KillFeed") or Instance.new("RemoteEvent")
    killFeedEvent.Name = "KillFeed"
    killFeedEvent.Parent = events
    
    CombatService.KillFeedEvent = killFeedEvent
    attackEvent.OnServerEvent:Connect(CombatService.OnAttackRequest)
end

function CombatService.OnAttackRequest(attacker, hitCharacter)
    -- Native Server-Side Anticheat Server-Side Rate Limiter Validation
    local lastAttack = CombatService.Cooldowns[attacker.UserId] or 0
    if os.clock() - lastAttack < 0.5 then
        return
    end
    CombatService.Cooldowns[attacker.UserId] = os.clock()
    
    if not attacker.Character or not hitCharacter then return end
    
    local attackerHrp = attacker.Character:FindFirstChild("HumanoidRootPart")
    local victimHrp = hitCharacter:FindFirstChild("HumanoidRootPart")
    local victimHumanoid = hitCharacter:FindFirstChild("Humanoid")
    
    if attackerHrp and victimHrp and victimHumanoid and victimHumanoid.Health > 0 then
        local distance = (attackerHrp.Position - victimHrp.Position).Magnitude
        if distance <= 10 then 
            local victimPlayer = Players:GetPlayerFromCharacter(hitCharacter)
            CombatService.DealDamage(attacker, victimPlayer, victimHumanoid, 20)
        end
    end
end

function CombatService.DealDamage(attacker, victimPlayer, victimHumanoid, amount)
    local tag = Instance.new("ObjectValue")
    tag.Name = "creator"
    tag.Value = attacker
    tag.Parent = victimHumanoid
    game.Debris:AddItem(tag, 3)
    
    victimHumanoid:TakeDamage(amount)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid.Died:Connect(function()
                local tag = humanoid:FindFirstChild("creator")
                if tag and tag.Value and tag.Value:IsA("Player") then
                    local killer = tag.Value
                    CombatService.ExecuteKill(killer, player)
                end
            end)
        end
    end)
end)

function CombatService.ExecuteKill(killer, victim)
    local ZoneService = ServiceRegistry:Get("ZoneService")
    local MutationController = ServiceRegistry:Get("MutationController")
    local riskMultiplier = 1
    
    if ZoneService and MutationController then
        local killZone = ZoneService.PlayerZones[victim]
        if killZone then
            local state = MutationController.ZoneStates[killZone]
            if state then
                local riskLevel = MutationConfig.States[state].RiskLevel
                if riskLevel == "Medium" then riskMultiplier = 1.5
                elseif riskLevel == "High" then riskMultiplier = 2.0
                elseif riskLevel == "Extreme" then riskMultiplier = 3.0
                end
            end
        end
    end
    
    local leaderstats = killer:FindFirstChild("leaderstats")
    if leaderstats then
        if leaderstats:FindFirstChild("Kills") then
            leaderstats.Kills.Value = leaderstats.Kills.Value + 1
        end
        if leaderstats:FindFirstChild("Score") then
            leaderstats.Score.Value = leaderstats.Score.Value + math.floor(10 * riskMultiplier) 
        end
    end
    
    if CombatService.KillFeedEvent then
        CombatService.KillFeedEvent:FireAllClients(killer.Name, victim.Name)
    end
end

return CombatService
