local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local assets = ReplicatedStorage:WaitForChild("Events")
local zoneRemote = assets:WaitForChild("ZoneRemote")

-- Create Minimalist UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZoneDebugUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 80)
frame.Position = UDim2.new(1, -210, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.5
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 1, -20)
label.Position = UDim2.new(0, 10, 0, 10)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(240, 240, 240)
label.TextSize = 18
label.Font = Enum.Font.GothamBold
label.Text = "Zone: Wilderness\nEffect: None"
label.Parent = frame

-- Effect mappings
local EFFECT_MAP = {
    Lava = "🔥 Burning",
    Frozen = "❄️ Slowed",
    Radiation = "☢️ Mutating",
    Toxic = "💀 Poisoned",
    Wilderness = "None"
}

local function safeZoneName(zoneData)
    -- If it's an array (init packet), ignore it for the label
    if typeof(zoneData) == "table" and #zoneData > 0 then
        return "Wilderness"
    elseif typeof(zoneData) == "table" then
        return zoneData.type or "Wilderness"
    end
    return tostring(zoneData)
end

zoneRemote.OnClientEvent:Connect(function(newZone)
    local zoneName = safeZoneName(newZone)
    local effect = EFFECT_MAP[zoneName] or "None"
    
    label.Text = string.format("Zone: %s\nEffect: %s", zoneName, effect)
    
    -- Visual local feedback
    frame.BackgroundColor3 = (zoneName == "Lava" and Color3.fromRGB(150, 20, 20)) or
                             (zoneName == "Frozen" and Color3.fromRGB(20, 100, 150)) or
                             (zoneName == "Radiation" and Color3.fromRGB(20, 150, 20)) or
                             Color3.fromRGB(30, 30, 30)
end)
