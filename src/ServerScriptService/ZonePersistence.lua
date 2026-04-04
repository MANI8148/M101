local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local ZonePersistence = {}

local KEY = "INTERNAL_ZONE_CACHE"

-- Memory-based caching (Sub-0.1s lookup)
ZonePersistence._cache = nil

function ZonePersistence.Save(data)
    ZonePersistence._cache = data
    
    -- Sync to Internal Storage
    local success, json = pcall(function() return HttpService:JSONEncode(data) end)
    if success then
        local storage = ServerStorage:FindFirstChild(KEY) or Instance.new("StringValue")
        storage.Name = KEY
        storage.Value = json
        storage.Parent = ServerStorage
        print("💾 [Persistence] Cached zone layout saved to internal storage.")
    else
        warn("💾 [Persistence] Caching failed! JSON Serialization error.")
    end
end

function ZonePersistence.Load()
    if ZonePersistence._cache then return ZonePersistence._cache end
    
    local storage = ServerStorage:FindFirstChild(KEY)
    if not storage or storage.Value == "" then return nil end
    
    local success, data = pcall(function() return HttpService:JSONDecode(storage.Value) end)
    if success then
        ZonePersistence._cache = data
        print("💾 [Persistence] Instant load from Internal Cache.")
        return data
    end
    return nil
end

return ZonePersistence
