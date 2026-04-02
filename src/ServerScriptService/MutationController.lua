local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MutationConfig = require(ServerScriptService.MutationConfig)
local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

local MutationController = {}
MutationController.ZoneStates = {} -- [zoneName] = "Normal"
MutationController._zoneTransitions = {} 

MutationController.States = {"Normal", "Jungle", "Lava", "Frozen", "Toxic"}

function MutationController.Init()
    ServiceRegistry:Register("MutationController", MutationController)

    local stateFolder = ReplicatedStorage:FindFirstChild("ZoneStates")
    if not stateFolder then
        stateFolder = Instance.new("Folder")
        stateFolder.Name = "ZoneStates"
        stateFolder.Parent = ReplicatedStorage
    end
    MutationController.StateFolder = stateFolder

    local ZoneService = ServiceRegistry:Get("ZoneService")
    
    ZoneService.PlayerEnteredZone.Event:Connect(function(player, zoneName)
        local state = MutationController.ZoneStates[zoneName] or "Normal"
        if state ~= "Normal" then
            MutationController.ApplyPlayerState(player, state)
        end
    end)
    
    ZoneService.PlayerLeftZone.Event:Connect(function(player, zoneName)
        local state = MutationController.ZoneStates[zoneName] or "Normal"
        if state ~= "Normal" then
            MutationController.RemovePlayerState(player, state)
        end
    end)
    
    task.spawn(MutationController.StartLoop)
    task.spawn(MutationController.StartEffectTick)
end

function MutationController.StartLoop()
    while true do
        task.wait(1)
        local ZoneService = ServiceRegistry:Get("ZoneService")
        if ZoneService then
            for zoneName, _ in pairs(ZoneService.ZoneParts) do
                if not MutationController.ZoneStates[zoneName] then
                    MutationController.ZoneStates[zoneName] = "Normal"
                    
                    local strVal = Instance.new("StringValue")
                    strVal.Name = zoneName
                    strVal.Value = "Normal"
                    strVal.Parent = MutationController.StateFolder
                    
                    task.spawn(function()
                        while true do
                            task.wait(math.random(30, 40))
                            MutationController.ChangeZoneState(zoneName)
                        end
                    end)
                end
            end
        end
    end
end

function MutationController.ChangeZoneState(zoneName)
    if MutationController._zoneTransitions[zoneName] then return end
    MutationController._zoneTransitions[zoneName] = true
    
    local Debug = ServiceRegistry:Get("DebugMonitorService")
    local startTick = os.clock()
    
    local currentState = MutationController.ZoneStates[zoneName]
    local newState = currentState
    while newState == currentState do
        newState = MutationController.States[math.random(1, #MutationController.States)]
    end
    
    local ZoneService = ServiceRegistry:Get("ZoneService")
    
    -- Optimized Array Mapping: Directly process ONLY batch players trapped specifically within the relevant Zone dictionary
    local affectedPlayers = ZoneService.ZonePlayers[zoneName] or {}
    
    for player, _ in pairs(affectedPlayers) do
        if currentState ~= "Normal" then
            MutationController.RemovePlayerState(player, currentState)
        end
    end
    
    local val = MutationController.StateFolder:FindFirstChild(zoneName)
    if val then val.Value = newState end
    MutationController.ZoneStates[zoneName] = newState
    
    for player, _ in pairs(affectedPlayers) do
        if newState ~= "Normal" then
            MutationController.ApplyPlayerState(player, newState)
        end
    end
    
    print("Zone " .. zoneName .. " mutated into State - " .. newState)
    MutationController._zoneTransitions[zoneName] = false
    
    if Debug then Debug.LogLoop("MutationTransition_"..zoneName, os.clock() - startTick) end
end

function MutationController.ApplyPlayerState(player, state)
    local MutationService = ServiceRegistry:Get("MutationService")
    if state == "Frozen" and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = MutationConfig.States.Frozen.WalkSpeed
    elseif state == "Toxic" then
        local buffs = MutationConfig.States.Toxic.Buffs
        local randIdx = math.random(1, #buffs)
        if MutationService then
            MutationService.AddMutation(player, buffs[randIdx])
        end
    end
end

function MutationController.RemovePlayerState(player, state)
    local MutationService = ServiceRegistry:Get("MutationService")
    if state == "Frozen" and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = MutationConfig.States.Frozen.DefaultWalkSpeed
    elseif state == "Toxic" then
        local buffs = MutationConfig.States.Toxic.Buffs
        for _, mut in ipairs(buffs) do
            if MutationService then
                MutationService.RemoveMutation(player, mut)
            end
        end
    end
end

function MutationController.StartEffectTick()
    while true do
        task.wait(MutationConfig.States.Lava.Tick)
        
        local ZoneService = ServiceRegistry:Get("ZoneService")
        local Debug = ServiceRegistry:Get("DebugMonitorService")
        local startTick = os.clock()
        
        if ZoneService then
            for zoneName, state in pairs(MutationController.ZoneStates) do
                if state == "Lava" then
                    -- Process effects asynchronously relying directly on strict grouped caching
                    local playersHere = ZoneService.ZonePlayers[zoneName] or {}
                    for player, _ in pairs(playersHere) do
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
        
        if Debug then Debug.LogLoop("GlobalEffectTick", os.clock() - startTick) end
    end
end

return MutationController
