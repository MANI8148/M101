local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ⚙️ CONFIGURATION
local COLOR_MAP = {
    Snow = Color3.fromRGB(240, 240, 240),
    Grass = Color3.fromRGB(50, 220, 50),
    Sand = Color3.fromRGB(194, 178, 128),
    Lava = Color3.fromRGB(255, 60, 0),
    Mud = Color3.fromRGB(101, 67, 33),
    Water = Color3.fromRGB(20, 120, 255),
    Basalt = Color3.fromRGB(40, 40, 40),
    Rock = Color3.fromRGB(120, 120, 130),
    CrackedLava = Color3.fromRGB(255, 40, 0),
    LeafyGrass = Color3.fromRGB(30, 150, 30),
    Salt = Color3.fromRGB(230, 230, 230)
}

-- Create ScreenGui
local playerGui = player:WaitForChild("PlayerGui", 5)
if not playerGui then warn("⚠️ UI Abort") return end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SurvivalHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 🗺 MINIMAP CONTAINER (210x210)
local minimapFrame = Instance.new("Frame")
minimapFrame.Name = "MinimapFrame"
minimapFrame.Size = UDim2.new(0, 210, 0, 210)
minimapFrame.Position = UDim2.new(0, 15, 0, 15)
minimapFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
minimapFrame.BackgroundTransparency = 0.4
minimapFrame.BorderSizePixel = 2
minimapFrame.BorderColor3 = Color3.fromRGB(200, 200, 255)
minimapFrame.ClipsDescendants = true
minimapFrame.Parent = screenGui

local mapPixelContainer = Instance.new("Frame")
mapPixelContainer.Size = UDim2.new(1, 0, 1, 0)
mapPixelContainer.BackgroundTransparency = 1
mapPixelContainer.Parent = minimapFrame

-- 🛰️ PLAYER POINTER (Green Dot)
local playerDot = Instance.new("Frame")
playerDot.Name = "PlayerPointer"
playerDot.Size = UDim2.new(0, 8, 0, 8)
playerDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
playerDot.BorderSizePixel = 1
playerDot.BorderColor3 = Color3.fromRGB(255, 255, 255)
playerDot.ZIndex = 11
playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
playerDot.Visible = false
playerDot.Parent = minimapFrame
Instance.new("UICorner", playerDot).CornerRadius = UDim.new(1, 0)

-- 🏆 HUD PANEL (Bottom-Right)
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(0, 250, 0, 160)
statsFrame.Position = UDim2.new(1, -270, 1, -180)
statsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
statsFrame.BackgroundTransparency = 0.5
statsFrame.Parent = screenGui
Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 8)

local zoneLabel = Instance.new("TextLabel")
zoneLabel.Size = UDim2.new(1, -20, 0, 40)
zoneLabel.Position = UDim2.new(0, 10, 0, 10)
zoneLabel.BackgroundTransparency = 1
zoneLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
zoneLabel.TextScaled = true
zoneLabel.Font = Enum.Font.GothamBlack
zoneLabel.Text = "Zone: Wilderness"
zoneLabel.Parent = statsFrame

-- 🛰️ DYNAMIC AUTO-FIT RENDERER
local currentExtents = nil
local MinimapRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("MinimapRemote")

local function renderAutoFitMap(data)
    if not data or not data.matrix then return end
    currentExtents = data.extents
    print("📐 [Minimap] Auto-Fitting UI to terrain bounds...")
    
    mapPixelContainer:ClearAllChildren()
    local res = data.resolution or 64
    local pixSize = 210 / res
    
    for i, row in pairs(data.matrix) do
        local iNum = tonumber(i) or 0
        for j, material in pairs(row) do
            local jNum = tonumber(j) or 0
            if material == "Empty" then continue end
            
            local pixel = Instance.new("Frame")
            pixel.BorderSizePixel = 0
            pixel.Size = UDim2.new(0, pixSize + 0.1, 0, pixSize + 0.1)
            pixel.Position = UDim2.new(0, iNum * pixSize, 0, jNum * pixSize)
            pixel.BackgroundColor3 = COLOR_MAP[material] or Color3.fromRGB(60,60,60)
            pixel.Parent = mapPixelContainer
        end
    end
    playerDot.Visible = true
end

MinimapRemote.OnClientEvent:Connect(renderAutoFitMap)

-- 📍 DYNAMIC POINTER SYNC
RunService.RenderStepped:Connect(function()
    if not currentExtents then return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local worldX, worldZ = hrp.Position.X, hrp.Position.Z
    
    -- Normalize position based on dynamic terrain bounds
    local normX = (worldX - currentExtents.minX) / (currentExtents.maxX - currentExtents.minX)
    local normZ = (worldZ - currentExtents.minZ) / (currentExtents.maxZ - currentExtents.minZ)
    
    -- Smoothly Clamp within frame boundaries
    normX = math.clamp(normX, 0, 1)
    normZ = math.clamp(normZ, 0, 1)
    
    playerDot.Position = UDim2.new(normX, 0, normZ, 0)
end)

-- 🌿 HUD SYNC
local function refreshHUD()
    local zone = player:GetAttribute("CurrentZone") or "Wilderness"
    TweenService:Create(zoneLabel, TweenInfo.new(0.3), {TextTransparency = 0.5}):Play()
    task.delay(0.3, function()
        zoneLabel.Text = "Zone: " .. zone
        zoneLabel.TextColor3 = (zone == "Lava" and Color3.fromRGB(255, 80, 80)) or
                              (zone == "Frozen" and Color3.fromRGB(200, 240, 255)) or
                              (zone == "Toxic" and Color3.fromRGB(200, 80, 255)) or
                              Color3.fromRGB(200, 200, 255)
        TweenService:Create(zoneLabel, TweenInfo.new(0.3), {TextTransparency = 0.0}):Play()
    end)
end

player:GetAttributeChangedSignal("CurrentZone"):Connect(refreshHUD)
refreshHUD()
