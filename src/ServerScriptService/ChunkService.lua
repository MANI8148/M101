local Terrain = workspace.Terrain
local ChunkConfig = require(game.ReplicatedStorage.Shared.ChunkConfig)

local ChunkService = {}

local CHUNK_SIZE = ChunkConfig.CHUNK_SIZE
local CHUNK_HEIGHT = ChunkConfig.CHUNK_HEIGHT

-- 🔥 Stores ALL chunk data
local ChunkData = {}

-- Convert world position → chunk ID
local function getChunkId(x, z)
    local cx = math.floor(x / CHUNK_SIZE)
    local cz = math.floor(z / CHUNK_SIZE)
    return cx .. "_" .. cz
end

-- Get chunk center position
local function getChunkPosition(cx, cz)
    return Vector3.new(
        cx * CHUNK_SIZE,
        CHUNK_HEIGHT / 2,
        cz * CHUNK_SIZE
    )
end

-- CREATE CHUNK
function ChunkService.CreateChunk(cx, cz, material)
    local id = cx .. "_" .. cz
    if ChunkData[id] then return end

    local position = getChunkPosition(cx, cz)

    -- 🧱 Create terrain
    Terrain:FillBlock(
        CFrame.new(position),
        Vector3.new(CHUNK_SIZE, CHUNK_HEIGHT, CHUNK_SIZE),
        material
    )

    -- 🧠 Store logic data
    ChunkData[id] = {
        Material = material.Name,
        Position = position,
        Mutation = "None"
    }
end

-- GET CHUNK FROM POSITION
function ChunkService.GetChunkAt(position)
    local id = getChunkId(position.X, position.Z)
    return ChunkData[id], id
end

-- EXPOSE DATA
function ChunkService.GetAllChunks()
    return ChunkData
end

return ChunkService
