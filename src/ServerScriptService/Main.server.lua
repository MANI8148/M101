local ServerScriptService = game:GetService("ServerScriptService")
local ServiceRegistry = require(ServerScriptService.ServiceRegistry)

-- 1. Require all services
local HungerService = require(ServerScriptService.HungerService)
local FoodService = require(ServerScriptService.FoodService)
local MutationService = require(ServerScriptService.MutationService)
local MutationController = require(ServerScriptService.MutationController)
local LavaZoneService = require(ServerScriptService.LavaZoneService)
local ZoneService = require(ServerScriptService.ZoneService)
local CombatService = require(ServerScriptService.CombatService)
local DebugMonitorService = require(ServerScriptService.DebugMonitorService)
local MinimapService = require(ServerScriptService.MinimapService)
local ZoneEffectService = require(ServerScriptService.ZoneEffectService)

-- 2. Register all services
print("[Main] Registering Game Services...")
ServiceRegistry:Register("MutationController", MutationController)
ServiceRegistry:Register("MutationService", MutationService)
ServiceRegistry:Register("ZoneService", ZoneService)
ServiceRegistry:Register("LavaZoneService", LavaZoneService)
ServiceRegistry:Register("HungerService", HungerService)
ServiceRegistry:Register("FoodService", FoodService)
ServiceRegistry:Register("CombatService", CombatService)
ServiceRegistry:Register("DebugMonitorService", DebugMonitorService)
ServiceRegistry:Register("MinimapService", MinimapService)
ServiceRegistry:Register("ZoneEffectService", ZoneEffectService)

-- 3. Initialize Game Services (Strict Order Required)
print("[Main] Initializing Game Services...")

local function SafeInit(name, service)
    print("Init " .. name)
    if service and service.Init then
        service.Init()
    else
        warn("[Main] Service missing Init: " .. name)
    end
end

-- 🛡 CRITICAL: ZoneService MUST initialize first to build the Registry
SafeInit("ZoneService", ZoneService)

-- 🧠 Next, Controller & Mutations consume ZoneRegistry
SafeInit("MutationController", MutationController)

-- 🌍 Then project the Map from the built Registry
SafeInit("MinimapService", MinimapService)

-- 🔥 Finally, start the gameplay effect loop
SafeInit("ZoneEffectService", ZoneEffectService)

-- Other services
SafeInit("DebugMonitorService", DebugMonitorService)
SafeInit("HungerService", HungerService)
SafeInit("FoodService", FoodService)
SafeInit("MutationService", MutationService)
SafeInit("LavaZoneService", LavaZoneService)
SafeInit("CombatService", CombatService)

print("[Main] Game Services Initialized!")

-- 4. AFTER that, run TerrainZoneGenerator in background (Fallback)
task.spawn(function()
    local TerrainZoneGeneratorModule = require(ServerScriptService:FindFirstChild("TerrainZoneGenerator"))
    TerrainZoneGeneratorModule.Run()

    print("[Main] Waiting for zones to be generated...")

    local zonesFolder

    repeat
        zonesFolder = workspace:FindFirstChild("Zones")
        task.wait(0.3)
    until zonesFolder and #zonesFolder:GetChildren() > 0

    print("[Main] Zones generated. Re-initializing ZoneService...")

    -- RESET REGISTRY
    ZoneService.ZoneRegistry = {}
    ZoneService.PlayerZones = {} -- Intentionally used PlayerZones instead of ZonePlayers to match the variable inside ZoneService.lua
    ZoneService.ActiveZones = {}

    -- RE-INIT
    ZoneService.Init()
    MinimapService.Init()
end)

print("[Main] Execution Flow Complete.")