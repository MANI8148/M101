local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for leaderstats to be created
local leaderstats = player:WaitForChild("leaderstats")
local hungerStat = leaderstats:WaitForChild("Hunger")
local healthStat = leaderstats:WaitForChild("Health")

-- Create ScreenGui
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SurvivalUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create UI Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 110)
frame.Position = UDim2.new(1, -220, 1, -130)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.5
frame.BorderSizePixel = 0
frame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = frame

-- Island State Label
local islandStateLabel = Instance.new("TextLabel")
islandStateLabel.Size = UDim2.new(1, -20, 0.33, 0)
islandStateLabel.Position = UDim2.new(0, 10, 0, 0)
islandStateLabel.BackgroundTransparency = 1
islandStateLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
islandStateLabel.TextScaled = true
islandStateLabel.Font = Enum.Font.GothamBlack
islandStateLabel.TextXAlignment = Enum.TextXAlignment.Left
islandStateLabel.Text = "Island: Normal"
islandStateLabel.Parent = frame

-- Hunger Label
local hungerLabel = Instance.new("TextLabel")
hungerLabel.Size = UDim2.new(1, -20, 0.33, 0)
hungerLabel.Position = UDim2.new(0, 10, 0.33, 0)
hungerLabel.BackgroundTransparency = 1
hungerLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
hungerLabel.TextScaled = true
hungerLabel.Font = Enum.Font.GothamBold
hungerLabel.TextXAlignment = Enum.TextXAlignment.Left
hungerLabel.Text = "Hunger: " .. hungerStat.Value
hungerLabel.Parent = frame

-- Health Label
local healthLabel = Instance.new("TextLabel")
healthLabel.Size = UDim2.new(1, -20, 0.33, 0)
healthLabel.Position = UDim2.new(0, 10, 0.66, 0)
healthLabel.BackgroundTransparency = 1
healthLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
healthLabel.TextScaled = true
healthLabel.Font = Enum.Font.GothamBold
healthLabel.TextXAlignment = Enum.TextXAlignment.Left
healthLabel.Text = "Health: " .. healthStat.Value
healthLabel.Parent = frame

-- Update UI on change (Debounced explicitly)
hungerStat.Changed:Connect(function(newVal)
    local updatedText = "Hunger: " .. tostring(newVal)
    if hungerLabel.Text ~= updatedText then
        hungerLabel.Text = updatedText
    end
end)

healthStat.Changed:Connect(function(newVal)
    local updatedText = "Health: " .. tostring(math.floor(newVal))
    if healthLabel.Text ~= updatedText then
        healthLabel.Text = updatedText
    end
end)

-- Feedback Effects & Network Hooks
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)

-- Kill Feed UI
local killFeedLabel = Instance.new("TextLabel")
killFeedLabel.Size = UDim2.new(1, 0, 0, 30)
killFeedLabel.Position = UDim2.new(0, 0, 0, 10)
killFeedLabel.BackgroundTransparency = 1
killFeedLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
killFeedLabel.TextScaled = true
killFeedLabel.Font = Enum.Font.GothamBlack
killFeedLabel.Text = ""
killFeedLabel.Parent = screenGui

if eventsFolder then
    local zoneUpdateEvent = eventsFolder:WaitForChild("ZoneUpdate", 10)
    if zoneUpdateEvent then
        local currentZoneConnection = nil
        zoneUpdateEvent.OnClientEvent:Connect(function(newZone)
            if currentZoneConnection then currentZoneConnection:Disconnect() end
            
            local statesFolder = ReplicatedStorage:WaitForChild("ZoneStates", 10)
            if statesFolder then
                local stateValue = statesFolder:WaitForChild(newZone, 10)
                if stateValue then
                    local function updateZoneUI()
                        local state = stateValue.Value
                        islandStateLabel.Text = newZone .. " [" .. state .. "]"
                        
                        if state == "Lava" then
                            islandStateLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
                        elseif state == "Toxic" then
                            islandStateLabel.TextColor3 = Color3.fromRGB(180, 75, 255)
                        elseif state == "Jungle" then
                            islandStateLabel.TextColor3 = Color3.fromRGB(75, 255, 75)
                        elseif state == "Frozen" then
                            islandStateLabel.TextColor3 = Color3.fromRGB(150, 255, 255)
                        else
                            islandStateLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
                        end
                    end
                    updateZoneUI()
                    currentZoneConnection = stateValue.Changed:Connect(updateZoneUI)
                end
            end
        end)
    end
    
    local killFeedEvent = eventsFolder:WaitForChild("KillFeed", 10)
    if killFeedEvent then
        killFeedEvent.OnClientEvent:Connect(function(killer, victim)
            killFeedLabel.Text = killer .. " eliminated " .. victim .. "!"
            task.delay(4, function()
                if killFeedLabel.Text == killer .. " eliminated " .. victim .. "!" then
                    killFeedLabel.Text = ""
                end
            end)
        end)
    end
end

-- Warning UI
local warningLabel = Instance.new("TextLabel")
warningLabel.Size = UDim2.new(1, 0, 0, 50)
warningLabel.Position = UDim2.new(0, 0, 0.2, 0)
warningLabel.BackgroundTransparency = 1
warningLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
warningLabel.TextScaled = true
warningLabel.Font = Enum.Font.GothamBlack
warningLabel.Text = ""
warningLabel.Parent = screenGui

task.spawn(function()
    local warningValue = ReplicatedStorage:WaitForChild("MutationWarning", 10)
    if warningValue then
        warningValue.Changed:Connect(function(newWarning)
            warningLabel.Text = newWarning
        end)
    end
end)

-- Feedback Effects
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
if eventsFolder then
    local consumeFeedbackEvent = eventsFolder:WaitForChild("ConsumeFeedback", 10)
    if consumeFeedbackEvent then
        local flashFrame = Instance.new("Frame")
        flashFrame.Size = UDim2.new(1, 0, 1, 0)
        flashFrame.BackgroundColor3 = Color3.fromRGB(150, 255, 150)
        flashFrame.BackgroundTransparency = 1
        flashFrame.BorderSizePixel = 0
        flashFrame.ZIndex = -1
        flashFrame.Parent = screenGui
        
        consumeFeedbackEvent.OnClientEvent:Connect(function()
            -- Flash screen UI
            flashFrame.BackgroundTransparency = 0.5
            local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(flashFrame, info, {BackgroundTransparency = 1})
            tween:Play()
        end)
    end
end
