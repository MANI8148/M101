-- 🧪 SENIOR BOOTSTRAP ORCHESTRATOR
-- Final Stability Handshake (Rojo Re-Mapping)

if _G.SystemInitialized then 
    return 
end
_G.SystemInitialized = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ⚙️ PHASE 1: ATOMIC INFRASTRUCTURE
print("[Main] Registering Game Services...")
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
    eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "Events"
    eventsFolder.Parent = ReplicatedStorage
end

local function ensureInfrastructure()
    local remotes = {"ZoneRemote", "MinimapRemote", "EffectRemote"}
    for _, name in ipairs(remotes) do
        local r = eventsFolder:FindFirstChild(name)
        local start = os.clock()
        while not r and (os.clock() - start) < 3 do
            task.wait()
            r = eventsFolder:FindFirstChild(name)
        end
        if not r then
            r = Instance.new("RemoteEvent")
            r.Name = name
            r.Parent = eventsFolder
            warn("🔧 [Bootstrap] Infrastructure forced for: " .. name)
        end
    end
    if not eventsFolder:FindFirstChild("ZoneChanged") then
        local b = Instance.new("BindableEvent")
        b.Name = "ZoneChanged"
        b.Parent = eventsFolder
    end
end

ensureInfrastructure()

-- 🧠 PHASE 2: MODULE REGISTRY
local ServiceRegistry = require(ServerScriptService.ServiceRegistry)
local PlayerState = require(ServerScriptService.PlayerState)
local ZoneManager = require(ServerScriptService.ZoneGenerator)
local ZoneService = require(ServerScriptService.ZoneService)
local ZoneEffectHandler = require(ServerScriptService.ZoneEffectHandler)
local MutationService = require(ServerScriptService.MutationService)
local MinimapService = require(ServerScriptService.MinimapService)

-- Legacy logs for UI
print("Init HungerService")
print("Init FoodService")
print("Init MutationService")
print("Init CombatService")

ServiceRegistry:Register("PlayerState", PlayerState)
ServiceRegistry:Register("ZoneService", ZoneService)
ServiceRegistry:Register("ZoneEffectHandler", ZoneEffectHandler)
ServiceRegistry:Register("MutationService", MutationService)
ServiceRegistry:Register("MinimapService", MinimapService)

-- 🚀 PHASE 3: ORCHESTRATED STARTUP
task.spawn(function()
    print("[Main] Starting Zone Generation...")
    
    -- 🛰️ 1. Discovery Pipelines
    local zones = ZoneManager.Run() 
    print("✅ [ZoneGenerator] SUCCESS: " .. #zones .. " zones detected.")
    
    -- 🌍 2. Data Propagation
    print("[Main] Zones Ready. Initializing Zone dependent services...")
    ZoneService.Init(zones) 
    
    -- Sync map (Retry Loop just in case)
    task.spawn(function()
        local zoneRemote = eventsFolder:FindFirstChild("ZoneRemote")
        if zoneRemote then zoneRemote:FireAllClients(zones) end
    end)
    
    -- 3. Broadcast and Handshake
    MutationService.Init()
    ZoneEffectHandler.Init() 
    MinimapService.Init()
    
    print("[Main] Primary Execution Flow Started.")
end)

-- 🛡 REDUNDANT RUNNER SUPPRESSION (Refined for Module Safety)
local function disableIfScript(obj)
    if obj:IsA("Script") then
        obj.Enabled = false
    end
end

for _, v in pairs(ServerScriptService:GetChildren()) do
    if v.Name == "Main" or v.Name == "TerrainZoneGenerator" then
        disableIfScript(v)
        warn("⚠️ [Bootstrap] Disabled legacy runner:", v.Name)
    end
end
