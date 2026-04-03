local Terrain = workspace.Terrain
local ChunkService = require(game.ServerScriptService.ChunkService)
local ChunkConfig = require(game.ReplicatedStorage.Shared.ChunkConfig)

local MutationService = {}

local CHUNK_SIZE = ChunkConfig.CHUNK_SIZE
local CHUNK_HEIGHT = ChunkConfig.CHUNK_HEIGHT

function MutationService.Init()
    print("[MutationService] Initialized")
end

function MutationService.MutateChunk(id, newMaterial)
    local chunks = ChunkService.GetAllChunks()
    local chunk = chunks[id]
    if not chunk then return end

    -- 🌍 Replace terrain visually
    Terrain:FillBlock(
        CFrame.new(chunk.Position),
        Vector3.new(CHUNK_SIZE, CHUNK_HEIGHT, CHUNK_SIZE),
        newMaterial
    )

    -- 🧠 Update logic
    chunk.Material = newMaterial.Name
    chunk.Mutation = "Mutated"
end

return MutationService
