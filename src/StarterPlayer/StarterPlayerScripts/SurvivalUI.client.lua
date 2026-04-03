local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local hungerStat = leaderstats:WaitForChild("Hunger")
local healthStat = leaderstats:WaitForChild("Health")

-- Create ScreenGui
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SurvivalUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create Main UI Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 140)
frame.Position = UDim2.new(1, -270, 1, -160)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.5
frame.BorderSizePixel = 0
frame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = frame

-- Island State Label
local islandStateLabel = Instance.new("TextLabel")
islandStateLabel.Size = UDim2.new(1, -20, 0, 30)
islandStateLabel.Position = UDim2.new(0, 10, 0, 10)
islandStateLabel.BackgroundTransparency = 1
islandStateLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
islandStateLabel.TextScaled = true
islandStateLabel.Font = Enum.Font.GothamBlack
islandStateLabel.TextXAlignment = Enum.TextXAlignment.Left
islandStateLabel.Text = "Island: Normal"
islandStateLabel.Parent = frame

-- Hunger Bar Background
local hungerBg = Instance.new("Frame")
hungerBg.Size = UDim2.new(1, -20, 0, 25)
hungerBg.Position = UDim2.new(0, 10, 0, 50)
hungerBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hungerBg.Parent = frame
local hBgCorner = Instance.new("UICorner"); hBgCorner.CornerRadius = UDim.new(0, 4); hBgCorner.Parent = hungerBg

-- Hunger Bar Fill
local hungerFill = Instance.new("Frame")
hungerFill.Size = UDim2.new(hungerStat.Value / 100, 0, 1, 0)
hungerFill.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
hungerFill.Parent = hungerBg
local hFillCorner = Instance.new("UICorner"); hFillCorner.CornerRadius = UDim.new(0, 4); hFillCorner.Parent = hungerFill

-- Hunger Text
local hungerText = Instance.new("TextLabel")
hungerText.Size = UDim2.new(1, 0, 1, 0)
hungerText.BackgroundTransparency = 1
hungerText.TextColor3 = Color3.fromRGB(255, 255, 255)
hungerText.TextScaled = true
hungerText.Font = Enum.Font.GothamBold
hungerText.Text = "Hunger: " .. hungerStat.Value .. "/100"
hungerText.Parent = hungerBg

-- Health Bar Background
local healthBg = Instance.new("Frame")
healthBg.Size = UDim2.new(1, -20, 0, 25)
healthBg.Position = UDim2.new(0, 10, 0, 85)
healthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
healthBg.Parent = frame
local hpBgCorner = Instance.new("UICorner"); hpBgCorner.CornerRadius = UDim.new(0, 4); hpBgCorner.Parent = healthBg

-- Health Bar Fill
local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.new(healthStat.Value / 100, 0, 1, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
healthFill.Parent = healthBg
local hpFillCorner = Instance.new("UICorner"); hpFillCorner.CornerRadius = UDim.new(0, 4); hpFillCorner.Parent = healthFill

-- Health Text
local healthText = Instance.new("TextLabel")
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.BackgroundTransparency = 1
healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
healthText.TextScaled = true
healthText.Font = Enum.Font.GothamBold
healthText.Text = "Health: " .. math.floor(healthStat.Value) .. "/100"
healthText.Parent = healthBg

-- Efficient Event-Driven Updates
local function updateBar(fillFrame, textLabel, value, maxVal, prefix)
    print("[UI DEBUG] Updating " .. prefix .. " bar to " .. value)
    local targetSize = UDim2.new(math.clamp(value / maxVal, 0, 1), 0, 1, 0)
    local tween = TweenService:Create(fillFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
    tween:Play()
    textLabel.Text = prefix .. ": " .. math.floor(value) .. "/" .. maxVal
end

hungerStat.Changed:Connect(function(newVal)
    updateBar(hungerFill, hungerText, newVal, 100, "Hunger")
end)

healthStat.Changed:Connect(function(newVal)
    updateBar(healthFill, healthText, newVal, 100, "Health")
end)

-- Zone Updates & Events
local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
local statesFolder = ReplicatedStorage:WaitForChild("ZoneStates", 10)

-- Function to handle zone visuals
local function updateZoneVisuals(zoneName, state)
    print("[UI DEBUG] Zone Visuals Updating: " .. zoneName .. " is now " .. state)
    islandStateLabel.Text = zoneName .. " [" .. state .. "]"
                        
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

if eventsFolder then
    local zoneUpdateEvent = eventsFolder:WaitForChild("ZoneUpdate", 10)
    if zoneUpdateEvent and statesFolder then
        local currentZoneConnection = nil
        zoneUpdateEvent.OnClientEvent:Connect(function(newZone)
            print("[UI DEBUG] Player entered new zone: " .. newZone)
            if currentZoneConnection then currentZoneConnection:Disconnect() end
            
            local stateValue = statesFolder:FindFirstChild(newZone)
            if not stateValue then
                stateValue = statesFolder:WaitForChild(newZone, 10)
            end
            
            if stateValue then
                updateZoneVisuals(newZone, stateValue.Value)
                currentZoneConnection = stateValue.Changed:Connect(function(newState)
                    updateZoneVisuals(newZone, newState)
                end)
            end
        end)
    end
    
    -- Kill Feed
    local killFeedEvent = eventsFolder:WaitForChild("KillFeed", 10)
    if killFeedEvent then
        local killFeedLabel = Instance.new("TextLabel")
        killFeedLabel.Size = UDim2.new(1, 0, 0, 30)
        killFeedLabel.Position = UDim2.new(0, 0, 0, 10)
        killFeedLabel.BackgroundTransparency = 1
        killFeedLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
        killFeedLabel.TextScaled = true
        killFeedLabel.Font = Enum.Font.GothamBlack
        killFeedLabel.Text = ""
        killFeedLabel.Parent = screenGui

        killFeedEvent.OnClientEvent:Connect(function(killer, victim)
            print("[UI DEBUG] KillFeed Log: " .. killer .. " killed " .. victim)
            killFeedLabel.Text = killer .. " eliminated " .. victim .. "!"
            task.delay(4, function()
                if killFeedLabel.Text == killer .. " eliminated " .. victim .. "!" then
                    killFeedLabel.Text = ""
                end
            end)
        end)
    end
    
    -- Feedback Flash
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
            print("[UI DEBUG] Food consumed! Flashing screen.")
            flashFrame.BackgroundTransparency = 0.5
            local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(flashFrame, info, {BackgroundTransparency = 1})
            tween:Play()
        end)
    end
end
