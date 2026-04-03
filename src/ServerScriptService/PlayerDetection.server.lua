local ChunkService = require(game.ServerScriptService.ChunkService)

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local hrp = char:WaitForChild("HumanoidRootPart")

        while true do
            task.wait(1)

            local chunk, id = ChunkService.GetChunkAt(hrp.Position)

            if chunk and chunk.Material == "Lava" then
                print(player.Name .. " is in lava!")
                -- damage logic here
            end
        end
    end)
end)
