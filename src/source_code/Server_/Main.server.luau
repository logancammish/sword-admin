print("Initializing Sword Admin v8...")

local DataStoreService = game:GetService("DataStoreService")
local MarketPlaceService = game:GetService("MarketplaceService")

local SettingsFolder = workspace.Sword_Admin.Settings
local Settings = require(SettingsFolder)
local PowerUserSettings = require(SettingsFolder.PowerUserSettings)
local CustomCommands = require(SettingsFolder.CustomCommands)

local AdminsDataStore = DataStoreService:GetDataStore("Admins_sav")
local TempAdminsDataStore = DataStoreService:GetDataStore("TAdmins_sav")

local Parser = require(script.Parent.deps.parser)
local CommandHandler = require(script.Parent.CommandHandler)

local saving = false

local function saveAdmins()
	if saving then
		print("Already saving admins...")
		return
	end

	saving = true
	print("Saving admins...")

	local success1, err1 = pcall(function()
		AdminsDataStore:UpdateAsync(1, function()
			return Settings.Admins
		end)
	end)

	local success2, err2 = pcall(function()
		TempAdminsDataStore:UpdateAsync(1, function()
			return Settings.Temp_Admins
		end)
	end)

	if not success1 then
		warn("Failed to save Admins:", err1)
	end

	if not success2 then
		warn("Failed to save Temp Admins:", err2)
	end

	print("Saved admins.")
	saving = false
end


for _, command in pairs(CustomCommands) do
	table.insert(CommandHandler, command)
end

local function cloneArray(tbl)
	local new = {}
	for i, v in ipairs(tbl) do
		new[i] = v
	end
	return new
end

local function contains(tbl, value)
	for _, v in ipairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
end

local function merge(base, defaults)
	local changed = false

	for _, v in ipairs(defaults) do
		if not contains(base, v) then
			table.insert(base, v)
			changed = true
		end
	end

	return base, changed
end

-- TEMP ADMINS
local TempAdmins
local success, result = pcall(function()
	return TempAdminsDataStore:GetAsync(1)
end)

if success and result then
	TempAdmins = cloneArray(result)
else
	TempAdmins = cloneArray(Settings.Temp_Admins)
end

TempAdmins, tempChanged = merge(TempAdmins, Settings.Temp_Admins)
Settings.Temp_Admins = TempAdmins

if tempChanged then
	pcall(function()
		TempAdminsDataStore:SetAsync(1, TempAdmins)
	end)
end

for _, v in ipairs(Settings.Temp_Admins) do
	print("Tempadmin:", v)
end

local Admins
local success2, result2 = pcall(function()
	return AdminsDataStore:GetAsync(1)
end)

if success2 and result2 then
	Admins = cloneArray(result2)
else
	Admins = cloneArray(Settings.Admins)
end

Admins, adminChanged = merge(Admins, Settings.Admins)
Settings.Admins = Admins

if adminChanged then
	pcall(function()
		AdminsDataStore:SetAsync(1, Admins)
	end)
end

for _, v in ipairs(Settings.Admins) do
	print("Admin:", v)
end



print("Initialized Sword Admin v8 successfully.")

local EventsFolder = game.ReplicatedStorage:WaitForChild("Events_")

local function refreshAdminStatus(player)
	if not player or not player.Parent then
		return
	end

	local rank = CheckAdmin.AdminRank(player)

	if Settings.adminJoinMessage == true then
		if rank > 0 then
			EventsFolder.IsAdmin:FireClient(player, tostring(rank))
		else
			EventsFolder.IsAdmin:FireClient(player, "0")
		end
	end
end

local function tableHas(tbl, value)
	for _, v in ipairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
end

local function isExperienceDeveloper(plr)
	if not Settings.DevelopersAdmin then
		return false
	end

	if not plr or not plr:IsA("Player") then
		return false
	end

	if game.CreatorType == Enum.CreatorType.User then
		return plr.UserId == game.CreatorId
	end

	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function()
			return plr:GetRankInGroup(game.CreatorId)
		end)

		if not ok then
			warn("Failed to check group rank for " .. plr.Name)
			return false
		end

		return tableHas(Settings.DeveloperGroupRanks or {}, rank)
	end

	return false
end

CheckAdmin = {
	PurchasedRank = function(Player)
		local PlayerPurchasedRank = 0
		if Player.MembershipType == Enum.MembershipType.Premium
			and Settings.PremiumAdmin == true then
			PlayerPurchasedRank = Settings.PremiumRank
		end
		local Success, Error = pcall(function() 
			if MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, Settings.GamePassId) then
				PlayerPurchasedRank = Settings.GamePassRank
			end
		end)
		if Settings.GamePassId > 0 and not Success then
			warn("Sword Admin: Error checking if user owns gamepass. Is your ID correct?")
		end
		
		return PlayerPurchasedRank
	end,
	IsAdmin = function(Player) 
		return CheckAdmin.AdminRank(Player) > 0
	end,
	AdminRank = function(plr)
		if not plr or not plr:IsA("Player") then
			return 0
		end

		local playerName = string.lower(plr.Name)
		local userId = plr.UserId
		local purchasedRank = CheckAdmin.PurchasedRank(plr) or 0

		local function inList(list)
			return table.find(list, userId) ~= nil or table.find(list, playerName) ~= nil
		end
		
		if isExperienceDeveloper(plr) and Settings.DevelopersAdmin == true then
			return 3
		end

		if userId == game.CreatorId or purchasedRank >= 3 or inList(Settings.Head_Admins) then
			return 3
		end

		if purchasedRank >= 2 or inList(Settings.Admins) then
			return 2
		end

		if Settings.freeAdmin or purchasedRank >= 1 or inList(Settings.Temp_Admins) then
			return 1
		end

		return 0
	end
}

local lastCommandTime = {}
local COMMAND_COOLDOWN = 0.25
local MAX_MESSAGE_LEN = 2000

function ParseMessage(player, message)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end
	if typeof(message) ~= "string" then
		return
	end
	if #message > MAX_MESSAGE_LEN then		
		EventsFolder.Notification:FireClient(player, "SECURITY: That command is too long.")
		return
	end

	local now = os.clock()
	local last = lastCommandTime[player]
	if last and (now - last) < COMMAND_COOLDOWN then
		EventsFolder.Notification:FireClient(player, "SECURITY: Sorry, you're sending commands too fast.")
		return
	end
	lastCommandTime[player] = now

	if message:sub(1, #Settings.prefix) ~= Settings.prefix then
		return
	end

	local rank = CheckAdmin.AdminRank(player)
	local commandString = Parser.get_command(message)

	local commandDef = CommandHandler[commandString]
	if typeof(commandString) ~= "string" or not commandDef then		
		EventsFolder.Notification:FireClient(player, "Command is invalid: did you write a command?")
		return
	end

	if PowerUserSettings.server.CommandHandler.disabled_commands
		and table.find(PowerUserSettings.server.CommandHandler.disabled_commands, commandString) then
		EventsFolder.Notification:FireClient(player, "That command is manually disabled.")
		return
	end

	local allowed = false
	if rank == 3 then
		allowed = true
	elseif rank == 2 and table.find(Settings.Admin_Commands, commandString) then
		allowed = true
	elseif (rank == 1 or commandString == "help") and table.find(Settings.Temp_AdminCommands, commandString) then
		allowed = true
	end

	if not allowed then
		return
	end

	local ok, err = pcall(function()
		commandDef[1](player, {
			commandDef.args[1](message),
			commandDef.args[2](message),
			commandDef.args[3](message),
		})
	end)

	if not ok then
		warn(("Command %s failed for %s: %s"):format(commandString, player.Name, tostring(err)))
		EventsFolder.Notification:FireClient(player, "Command failed.")
	end
end

local function DoPlayer(Player)
	local adminStatus = CheckAdmin.IsAdmin(Player)
	
	if adminStatus then 
		EventsFolder.Notification:FireClient(Player, "Welcome " .. Player.Name .. "!")
	end
	
	local PlayerPurchasedRank = CheckAdmin.PurchasedRank(Player)
	
	if script.Parent.PrivateServer.Value == true then
		if not adminStatus then
			Player:Kick("This server is locked to Admins only.")
		end
	end
	
	local Success, Error = pcall(function()
		if table.find(Settings.BanLand, Player.Name) or table.find(Settings.BanLand, Player.UserId) then
			Player:Kick("You are banned.")
		end
	end)
	if not Success then
		warn("Sword Admin ban check failed: " .. tostring(Error))
	end
	
	if CheckAdmin.IsAdmin(Player) then
		EventsFolder.IsAdmin:FireClient(Player, tostring(CheckAdmin.AdminRank(Player)), Settings.adminJoinMessage)
	end

	Player.Chatted:Connect(function(Message)
		ParseMessage(Player, Message)
	end)
end

EventsFolder.CommandBar.OnServerEvent:Connect(function(player, message)
	ParseMessage(player, message)
end)

for _, v in pairs (game.Players:GetPlayers()) do 
	DoPlayer(v)
end

game.Players.PlayerAdded:Connect(function(Player)
	DoPlayer(Player)
end)

EventsFolder.AdminAdded.Event:Connect(function(Player) 
	DoPlayer(Player)
	saveAdmins()
end)

game:BindToClose(function()
	saveAdmins()

	task.wait(2)
end)

game.Players.PlayerRemoving:Connect(function()
	saveAdmins()
end)

MarketPlaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if not wasPurchased then
		return
	end

	if gamePassId ~= Settings.GamePassId then
		return
	end

	task.defer(function()
		local success, ownsPass = pcall(function()
			return MarketPlaceService:UserOwnsGamePassAsync(player.UserId, Settings.GamePassId)
		end)

		if success and ownsPass then
			refreshAdminStatus(player)
		end
	end)
end)

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local TextChannels = TextChatService:FindFirstChild("TextChannels")

local function isMuted(userId)
	local plr = Players:GetPlayerByUserId(userId)
	return plr and plr:GetAttribute("Muted") == true
end

local function applyMuteToChannel(channel)
	if not channel:IsA("TextChannel") then
		return
	end

	channel.ShouldDeliverCallback = function(message, targetTextSource)
		local senderSource = message.TextSource

		if not senderSource then
			return true
		end

		if isMuted(senderSource.UserId) then
			return false
		end

		return true
	end
end

for _, channel in ipairs(TextChannels:GetChildren()) do
	applyMuteToChannel(channel)
end

TextChannels.ChildAdded:Connect(applyMuteToChannel)

EventsFolder.Mute.Event:Connect(function(plr, admin)
	if typeof(plr) ~= "Instance" then return end
	if not plr:IsA("Player") then return end
	if not admin:IsA("Player") then return end	
	
	if CheckAdmin.AdminRank(plr) > 2 then 
		EventsFolder.Notification:FireClient(admin, "Sorry, you can't mute a head admin")
		return 
	end
	
	EventsFolder.Notification:FireClient(plr, "You have been muted.")
	plr:SetAttribute("Muted", true)
	
end)