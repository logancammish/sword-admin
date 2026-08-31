game.Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)
		local Scripts = game.ReplicatedStorage:WaitForChild("CharacterScripts_")
		for _, v in pairs (Scripts:GetChildren()) do 
			v.Parent = Character
		end
	end)
end)