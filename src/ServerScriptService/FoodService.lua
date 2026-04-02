local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local HungerService = require(ServerScriptService.HungerService)
local MutationService = require(ServerScriptService.MutationService)

local FoodService = {}
FoodService.Cooldowns = {}

-- Define food items and their hunger restore values
FoodService.FoodItems = {
    ["Apple"] = { RestoreAmount = 15 },
    ["Bread"] = { RestoreAmount = 30 },
    ["CookedMeat"] = { RestoreAmount = 50 },
    ["RadioactiveApple"] = { RestoreAmount = 10, Mutation = "SpeedBoost" },
    ["StrangeMushroom"] = { RestoreAmount = 5, Mutation = "JumpBoost" }
}

function FoodService.Init()
    -- Ensure Events folder exists
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "Events"
        eventsFolder.Parent = ReplicatedStorage
    end
    
    -- Create RemoteEvent for UI based consumption and Feedback
    local consumeEvent = Instance.new("RemoteEvent")
    consumeEvent.Name = "ConsumeFood"
    consumeEvent.Parent = eventsFolder
    
    local consumeFeedbackEvent = Instance.new("RemoteEvent")
    consumeFeedbackEvent.Name = "ConsumeFeedback"
    consumeFeedbackEvent.Parent = eventsFolder
    
    consumeEvent.OnServerEvent:Connect(FoodService.OnConsumeFoodRequest)
    
    FoodService.FeedbackEvent = consumeFeedbackEvent
end

function FoodService.OnConsumeFoodRequest(player, foodName)
    -- Add Rate Limiting (Anti-Spam)
    local lastConsume = FoodService.Cooldowns[player.UserId] or 0
    if os.clock() - lastConsume < 1 then
        return -- Debounced!
    end
    FoodService.Cooldowns[player.UserId] = os.clock()

    FoodService.Consume(player, foodName)
end

function FoodService.Consume(player, foodName)
    -- Validate Player State (Edge Case)
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return false
    end
    
    -- Server-side validation
    local foodData = FoodService.FoodItems[foodName]
    if not foodData then
        warn("Player " .. player.Name .. " attempted to consume unknown food: " .. tostring(foodName))
        return false
    end
    
    local profile = HungerService.GetProfile(player)
    if profile then
        local currentHunger = profile:GetHunger()
        
        -- Optional: prevent eating if already perfectly full
        if currentHunger >= 100 then
            return false
        end
        
        -- Increase hunger (PlayerStats:SetHunger automatically clamps to max 100)
        profile:SetHunger(currentHunger + foodData.RestoreAmount)
        print(player.Name .. " consumed " .. foodName .. " (+ " .. foodData.RestoreAmount .. " Hunger)")
        
        -- Consumption Feedback: Sound
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://9125628522" -- Munch sound
        sound.Parent = player.Character.Head
        sound.PlayOnRemove = true
        sound:Destroy()
        
        -- Consumption Feedback: UI flash
        if FoodService.FeedbackEvent then
            FoodService.FeedbackEvent:FireClient(player)
        end
        
        -- Integrate with MutationService
        if foodData.Mutation then
            MutationService.AddMutation(player, foodData.Mutation)
        end
        
        -- In a full game, you would also remove the item from the player's inventory here.
        return true
    end
    return false
end

-- World Context: Create a part in the workspace that can be clicked to eat
function FoodService.CreateWorldFood(part, foodName)
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Parent = part
    
    clickDetector.MouseClick:Connect(function(player)
        -- Validate distance
        if player:DistanceFromCharacter(part.Position) > 15 then return end
        
        -- Rate Limiting
        local lastConsume = FoodService.Cooldowns[player.UserId] or 0
        if os.clock() - lastConsume < 1 then return end
        FoodService.Cooldowns[player.UserId] = os.clock()

        local success = FoodService.Consume(player, foodName)
        if success then
            part:Destroy() -- Consume the physical object
        end
    end)
end

return FoodService
