local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local parser = require(script.Parent.deps.parser)
local Settings = require(game.Workspace.Sword_Admin.Settings)
local TeleportService = game:GetService("TeleportService")
local EventsFolder = game.ReplicatedStorage:WaitForChild("Events_")

local function setInvisible(plr, invisible)
	local char = plr.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = invisible 
			and Enum.HumanoidDisplayDistanceType.None 
			or Enum.HumanoidDisplayDistanceType.Viewer
	end

	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Name ~= "HumanoidRootPart" then
				obj.Transparency = invisible and 1 or 0
			end

		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = invisible and 1 or 0
		end
	end
end

local function getCharacterParts(plr)
	if not plr or not plr:IsA("Player") then
		return nil
	end

	local character = plr.Character
	if not character or not character.Parent then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")

	return character, humanoid, hrp, head
end

local function getUserIdFromName(name)
	local ok, result = pcall(function()
		return Players:GetUserIdFromNameAsync(name)
	end)

	if ok then
		return result
	end

	return nil
end

local function withCharacter(plr, callback)
	local character, humanoid, hrp, head = getCharacterParts(plr)
	if not character then
		return
	end
	callback(character, humanoid, hrp, head)
end

local function get_conditions(Player, subject)
	return {
		(Player.Name == subject) or (subject == "me") or (subject == nil),
		subject == "all",
		subject == "others"
	}
end

local function exec(Player, subject, code)	
	local conditions = get_conditions(Player, subject)
	
	if conditions[1] then 
		code(Player)
	elseif conditions[2] then
		for _, plr in pairs(game.Players:GetPlayers()) do
			code(plr)
		end
	elseif conditions[3] then
		for _, plr in pairs(game.Players:GetPlayers()) do
			if plr ~= Player then
				code(plr)
			end
		end
	else
		for _, plr in pairs(game.Players:GetPlayers()) do
			if subject == plr.Name:sub(1,#subject):lower() then
				code(plr)
				break
			end
		end
	end
end

local function exec2(Player, subject1, subject2)
	local player1 = {}
	local player2 = {}
	
	local conditions1 = get_conditions(Player, subject1)
	local conditions2 = get_conditions(Player, subject2)
	
	if conditions1[1] then 
		player1 = {Player} 
	elseif conditions1[2] then 
		player1 = game.Players:GetPlayers()
	elseif conditions1[3] then
		for _, plr in pairs(game.Players:GetPlayers()) do
			if plr ~= Player then
				table.insert(player1, plr)
			end
		end
	else
		for _, plr in pairs(game.Players:GetPlayers()) do
			print(subject1, plr.Name, subject1 == plr.Name:sub(1,#subject1):lower())
			if subject1 == plr.Name:sub(1,#subject1):lower() then
				player1 = {plr}
				break
			end
		end	
	end

	if conditions2[1] then 
		player2 = {Player} 
	elseif conditions2[2] then 
		player2 = game.Players:GetPlayers()
	elseif conditions2[3] then
		for _, plr in pairs(game.Players:GetPlayers()) do
			if plr ~= Player then
				table.insert(player1, plr)
			end
		end
	else
		for _, plr in pairs(game.Players:GetPlayers()) do
			if subject2 == plr.Name:sub(1,#subject2):lower() then
				player2 = {plr}
				break
			end
		end	
	end
	
	return {player1, player2}
end

local Commands = {
	["kill"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character:WaitForChild("Humanoid").Health = 0;
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end
		}
	},

	["kick"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr:Kick("'" .. args[2] .. "', by moderator: " .. Player.Name)
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return parser.find_in_bounds(str, "'") end, -- Reason
			function(str) return str end
		}
	},
	
	["gear"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local Gear = InsertService:LoadAsset(args[2])
				Gear = Gear:FindFirstChildWhichIsA("Tool")
				Gear.Parent = Player.Backpack
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return string.split(str, " ")[3] end, -- Reason
			function(str) return str end
		}
	},

	["tp"] = {
		function(Player, args)
			local players = exec2(Player, args[1], args[2])
			
			for _, v in pairs(players[1]) do 
				local Success, Error = pcall(function() 
					v.Character.HumanoidRootPart.CFrame = players[2][1].Character.HumanoidRootPart.CFrame
				end) 
				if not Success then warn(Error) end 
			end
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return string.split(str, " ")[3] end, -- Player
			function(str) return str end
		}
	},
	
	["to"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				if not Player.Character or not plr.Character then return end

				local hrp1 = Player.Character:FindFirstChild("HumanoidRootPart")
				local hrp2 = plr.Character:FindFirstChild("HumanoidRootPart")
				if not hrp1 or not hrp2 then return end

				hrp1.CFrame = hrp2.CFrame + Vector3.new(0, 3, 0)
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return str end,
			function(str) return str end
		}
	},
	
	["spectate"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				EventsFolder.Spectate:FireClient(Player, plr)
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return str end,
			function(str) return str end
		}
	},

	["unspectate"] = {
		function(Player, args)
			EventsFolder.Spectate:FireClient(Player, nil)
		end,
		args = {
			function(str) return str end,
			function(str) return str end,
			function(str) return str end
		}
	},

	["mute"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				EventsFolder.Mute:Fire(plr, Player)
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return str end,
			function(str) return str end
		}
	},

	["unmute"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr:SetAttribute("Muted", false)
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return str end,
			function(str) return str end
		}
	},
	
	["bring"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				if not Player.Character or not plr.Character then return end

				local hrp1 = Player.Character:FindFirstChild("HumanoidRootPart")
				local hrp2 = plr.Character:FindFirstChild("HumanoidRootPart")
				if not hrp1 or not hrp2 then return end

				hrp2.CFrame = hrp1.CFrame + Vector3.new(0, 3, 0)
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return str end,
			function(str) return str end
		}
	},
	
	["heal"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.Health = hum.MaxHealth
				end
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return str end,
			function(str) return str end
		}
	},
	
	["damage"] = {
		function(Player, args)
			local amount = tonumber(args[2]) or 10

			exec(Player, args[1], function(plr)
				local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(amount)
				end
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return string.split(str, " ")[3] end,
			function(str) return str end
		}
	},
	
	["spectate"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				EventsFolder.Spectate:FireClient(Player, plr)
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return str end,
			function(str) return str end
		}
	},

	["unspectate"] = {
		function(Player)
			EventsFolder.Spectate:FireClient(Player, nil)
		end,
		args = {
			function(str) return str end,
			function(str) return str end,
			function(str) return str end
		}
	},

	["leaderstat"] = {
		function(Player, args)
			local leaderstats = game.Players:WaitForChild(args[1]):WaitForChild("leaderstats")
			local leaderstat = leaderstats:WaitForChild(args[2])
			leaderstat.Value = tonumber(args[3]) or args[3]
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return string.split(str, " ")[3] end, -- Leaderstat
			function(str) return string.split(str, " ")[4] end -- Amount
		}
	},

	["sword"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				game.ReplicatedStorage.Assets_.ClassicSword:Clone().Parent = plr.Character
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["print"] = {
		function(Player, args)
			print(args[1])
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Message
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["require"] = {
		function(Player, args)
			require(tonumber(args[1]))
			print(Player.Name .. ' has required module: ' .. args[1])
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Module
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["gravity"] = {
		function(Player, args)
			game.Workspace.Gravity = tonumber(args[1])
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Amount
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["commands"] = {
		function(Player, args)
			EventsFolder.Commands:FireClient(Player)
		end,
		args = {
			function(str) return str end, 
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["help"] = {
		function(Player, args)
			EventsFolder.HelpMenu:FireClient(Player)
		end,
		args = {
			function(str) return str end, 
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["cmds"] = {
		function(Player, args)
			EventsFolder.Commands:FireClient(Player)
		end,
		args = {
			function(str) return str end, 
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["countdown"] = {
		function(Player, args)
			if tonumber(args[1]) < 300 then 
				EventsFolder.Countdown:FireAllClients(Player.Name, tonumber(args[1]))
			else
				EventsFolder.Notification:FireClient(Player, "Error: Value cannot be higher than 200.")
			end		
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Time
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["message"] = {
		function(Player, args)
			local TextService = game:GetService("TextService")
			local Target = TextService:FilterStringAsync(args[1], Player.UserId)
			Target = Target:GetNonChatStringForBroadcastAsync()

			EventsFolder.Message:FireAllClients(Player.Name, Target)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Message
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["music"] = {
		function(Player, args)
			EventsFolder.Music:FireAllClients(tonumber(args[1]))
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- id
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["brightness"] = {
		function(Player, args)
			game.Lighting.Brightness = tonumber(args[1]) or 2
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Amount
			function(str) return str end, 
			function(str) return str end 
		}
	},
	
	["rejoin"] = {
		function(Player, args)
			local ServerCode = TeleportService:ReserveServer(game.PlaceId)
			local PlayertoTP = game.Players:FindFirstChild(Player.Name) 

			if PlayertoTP then 
				TeleportService:TeleportToPrivateServer(
					game.PlaceId, 
					ServerCode, 
					{PlayertoTP}, 
					nil, 
					"SENT_FROM_ADMIN" .. game.JobId
				)
			end		
		end,
		args = {
			function(str) return str end, 
			function(str) return str end, 
			function(str) return str end 
		}
	},
	
	["shutdownserver"] = {
		function(Player, args)
			for _, v in pairs(game.Players:GetPlayers()) do
				EventsFolder.Notification:FireClient(v, "Server shutting down soon...")
			end
			task.wait(5)
			for _, v in pairs(game.Players:GetPlayers()) do
				v:Kick("Server shutdown by: " .. Player.Name)
			end
		end,
		args = {
			function(str) return str end, 
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["faceless"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character.Head.face:Destroy()
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["explode"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local Explosion = Instance.new("Explosion")
				Explosion.Position = plr.Character.Head.Position
				Explosion.Parent = plr.Character.Head
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["fly"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				EventsFolder.Flight:FireClient(plr)
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["noclip"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				EventsFolder.Noclip:FireClient(plr)
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["jail"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local Jail = game.Workspace:FindFirstChild(plr.Name .. " Jail")
				if Jail then
					Jail:Destroy()
				end

				local Jail = game.ReplicatedStorage.Assets_.Jail:Clone()
				Player.RespawnLocation = Jail.tp
				Jail:SetPrimaryPartCFrame(Player.Character.HumanoidRootPart.CFrame)
				Jail.Name = plr.Name .. " Jail"
				Jail.Parent = workspace
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["unjail"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local Jail = game.Workspace:FindFirstChild(plr.Name .. " Jail")
				if Jail then
					Jail:Destroy()
				end
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},
	
	["hipheight"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character.Humanoid.HipHeight = tonumber(args[2])
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return string.split(str, " ")[2] end, -- height
			function(str) return str end 
		}
	},

	["blind"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local Blind = game.ReplicatedStorage.Assets_.Blind:Clone()
				Blind.Parent = Player.PlayerGui
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["unblind"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				if Player.PlayerGui:FindFirstChild("Blind") then
					Player.PlayerGui.Blind:Destroy()
				end
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},
	
	["headless"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character.Head.Transparency = 1
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["invisible"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				setInvisible(plr, true)
			end)
		end,

		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return str end,
			function(str) return str end
		}
	},

	["visible"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				setInvisible(plr, false)
			end)
		end,

		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return str end,
			function(str) return str end
		}
	},

	["fire"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local Fire = Instance.new("Fire")
				Fire.Parent = plr.Character.Head
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},
	
	["smoke"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local Fire = Instance.new("Smoke")
				Fire.Parent = plr.Character.Head
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["sparkles"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local Fire = Instance.new("Sparkles")
				Fire.Parent = plr.Character.Head
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["btools"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local Clone = game.ReplicatedStorage.Assets_["Building Tools"]:Clone()
				Clone.Parent = Player.Backpack
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["fling"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				coroutine.wrap(function()
					local Velocity = Instance.new("BodyVelocity")
					Velocity.Velocity = Vector3.new(9999999,99999999,99999999)					
					Velocity.Parent = Player.Character.HumanoidRootPart
					plr.Character.Humanoid.Jump = true
					wait(5)
					Velocity:Destroy()
				end)()
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["clone"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local NewCharacter = plr.Character:Clone()
				NewCharacter.Name = plr.Name .. "_"
				NewCharacter.Parent = workspace
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["char"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.CharacterAppearanceId = tonumber(args[2])
				plr:LoadCharacter()
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return string.split(str, " ")[3] end, -- id
			function(str) return str end 
		}
	},

	["sit"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character.Humanoid.Sit = true
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},
	
	["unsit"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character.Humanoid.Sit = false
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["ff"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				local ForceField = Instance.new("ForceField")
				ForceField.Parent = plr.Character			
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["unff"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				pcall(function() plr.Character.ForceField:Destroy() end)
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["jumppower"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character.Humanoid.JumpPower = tonumber(args[2])
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return string.split(str, " ")[3] end, -- Amount
			function(str) return str end 
		}
	},
	
	["speed"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character.Humanoid.WalkSpeed = tonumber(args[2])
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return string.split(str, " ")[3] end, -- Amount
			function(str) return str end 
		}
	},

	["freeze"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character.HumanoidRootPart.Anchored = true
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end,
			function(str) return str end 
		}
	},

	["unfreeze"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character.HumanoidRootPart.Anchored = false
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},

	["god"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				plr.Character.Humanoid.MaxHealth = math.huge
				plr.Character.Humanoid.Health = math.huge
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, 
			function(str) return str end 
		}
	},
	
	["health"] = {
		function(Player, args)
			local amount = tonumber(args[2])
			exec(Player, args[1], function(plr)
				if amount > plr.Character.Humanoid.Health then
					plr.Character.Humanoid.MaxHealth = amount;
				end
				plr.Character.Humanoid.Health = amount;
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return string.split(str, " ")[3] end, -- Amount
			function(str) return str end 
		}
	},

	["ban"] = {
		function(Player, args)
			local targetName = args[1]
			if targetName == Player.Name or targetName == nil or targetName == "all" then
				warn("Invalid")
				return
			end

			local userId = getUserIdFromName(targetName)
			if not userId then
				warn("User not found")
				return
			end

			local reason = args[2] or "unspecified"

			local ok, err = pcall(function()
				Players:BanAsync({
					UserIds = {userId},
					ApplyToUniverse = true,
					Duration = -1,
					DisplayReason = reason,
					PrivateReason = "Banned by " .. Player.Name .. " | Reason: " .. reason,
					ExcludeAltAccounts = true,
				})
			end)

			if not ok then
				warn("Failed to ban " .. targetName .. ": " .. tostring(err))
			end
		end,
		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return parser.find_in_bounds(str, "'") end,
			function(str) return str end
		}
	},
	
	["unban"] = {
		function(Player, args)
			local targetName = args[1]

			if not targetName or targetName == "all" or string.lower(targetName) == string.lower(Player.Name) then
				warn("Invalid")
				return
			end

			local userId = getUserIdFromName(targetName)
			if not userId then
				warn("User not found: " .. tostring(targetName))
				return
			end

			local ok, err = pcall(function()
				Players:UnbanAsync({
					UserIds = {userId},
					ApplyToUniverse = true,
				})
			end)

			if not ok then
				warn("Failed to unban " .. targetName .. ": " .. tostring(err))
				return
			end

			print("Unbanned " .. targetName)
		end,

		args = {
			function(str) return string.split(str, " ")[2] end,
			function(str) return str end,
			function(str) return str end
		}
	},

	["tempban"] = {
		function(Player, args)
			local targetName = args[1]
			local reason = args[2] or "unspecified"
			local duration = tonumber(args[3]) / 60

			if not targetName or targetName == "all" or string.lower(targetName) == string.lower(Player.Name) then
				warn("Invalid")
				return
			end

			if not duration or duration <= 0 then
				warn("Invalid temp ban time")
				return
			end

			local userId = getUserIdFromName(targetName)
			if not userId then
				warn("User not found: " .. tostring(targetName))
				return
			end

			local targetPlayer = Players:GetPlayerByUserId(userId)
			if targetPlayer then
				if table.find(Settings.Admins, targetPlayer.UserId)
					or table.find(Settings.Head_Admins, targetPlayer.UserId)
					or table.find(Settings.Admins, targetPlayer.Name)
					or table.find(Settings.Head_Admins, targetPlayer.Name) then
					return
				end
			end

			local ok, err = pcall(function()
				Players:BanAsync({
					UserIds = {userId},
					ApplyToUniverse = true,
					Duration = duration,
					DisplayReason = reason,
					PrivateReason = "Temp banned by " .. Player.Name .. " | Reason: " .. reason,
					ExcludeAltAccounts = true,
				})
			end)

			if not ok then
				warn("Failed to tempban " .. targetName .. ": " .. tostring(err))
				return
			end

			print("Temp banned " .. targetName .. " for " .. tostring(duration) .. " seconds.")
		end,

		args = {
			function(str)
				return string.split(str, " ")[2]
			end,
			function(str)
				return parser.find_in_bounds(str, "'")
			end,
			function(str)
				local match = string.match(str, "'[^']*'%s+(%S+)$")
				return tonumber(match)
			end
		}
	},

	["admin"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)		
				if not table.find(Settings.Admins, plr.UserId) then
					table.insert(Settings.Admins, plr.UserId)
					EventsFolder.AdminAdded:Fire(plr)
				end
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, -- Reason
			function(str) return str end
		}
	},

	["unadmin"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				if table.find(Settings.Admins, plr.UserId) then
					table.remove(Settings.Admins, table.find(Settings.Admins, plr.UserId))
				end
				if table.find(Settings.Admins, plr.Name) then
					table.remove(Settings.Admins, table.find(Settings.Admins, plr.Name))
				end
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, -- Reason
			function(str) return str end
		}
	},

	["tempadmin"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				if not table.find(Settings.Temp_Admins, plr.UserId) then
					table.insert(Settings.Temp_Admins, plr.UserId)					
					EventsFolder.AdminAdded:Fire(plr)
				end
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, -- Reason
			function(str) return str end
		}
	},

	["untempadmin"] = {
		function(Player, args)
			exec(Player, args[1], function(plr)
				if table.find(Settings.Temp_Admins, plr.UserId) then
					table.remove(Settings.Temp_Admins, table.find(Settings.Temp_Admins, plr.UserId))
				end
				if table.find(Settings.Temp_Admins, plr.Name) then
					table.remove(Settings.Temp_Admins, table.find(Settings.Temp_Admins, plr.Name))
				end
			end)
		end,
		args = {
			function(str) return string.split(str, " ")[2] end, -- Player
			function(str) return str end, -- Reason
			function(str) return str end
		}
	},
	
	["privateserver"] = {
		function(Player, args)
			game.ServerScriptService.Server_.PrivateServer.Value = true
			EventsFolder.Message:FireAllClients("Server locked by: " .. Player.Name, "This server has been locked and only admins can join now.")
		end,
		args = {
			function(str) return str end,
			function(str) return str end, 
			function(str) return str end 
		}
	}
	
	
}

return Commands