local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Core.Data)

Players.PlayerAdded:connect(function(player)
	Data.GetPlayerData(player, "Level")
	if player:IsDescendantOf(game) then
		player:LoadCharacter()
	end
end)
