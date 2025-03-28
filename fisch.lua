local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local InfiniteJumpEnabled = false
local JumpConnection = nil -- Variabel untuk menyimpan koneksi event
local plr = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local vim = game:GetService("VirtualInputManager")
local teleportLocations = {
	None = nil,
	Moosewod = Vector3.new(391, 135, 249),
	Roslit = Vector3.new(-1470, 133, 700),
	Forsaken = Vector3.new(-2483, 133, 1562),
	GrandReef = Vector3.new(-3576, 151, 522),
	["Atlantean Storm"] = Vector3.new(-3642, 131, 773),
	Spike = Vector3.new(-1281, 140, 1526),
	Therapin = Vector3.new(-175, 143, 1924),
	Ancient = Vector3.new(6058, 196, 303),
	Mushgrove = Vector3.new(2498, 134, -773),
	Arch = Vector3.new(1007, 135, -1254),
	Enchant = Vector3.new(1310, -802, -83),
	Atlantis = Vector3.new(-4259, -603, 1813),
	["Zeus Room"] = Vector3.new(-4309, -619, 2674),
	["Kraken Pool"] = Vector3.new(-4396, -995, 2046),
	["Poseidon Trial"] = Vector3.new(-3832, -545, 1025),
	["Poseidon Room"] = Vector3.new(-4033, -558, 907),
	["Ethereal Abyss Room"] = Vector3.new(-3798, -564, 1838),
	Snowcap = Vector3.new(2625, 143, 2466),
	["Snowcap Upper"] = Vector3.new(2815, 280, 2558),
	["Snowcap Cave"] = Vector3.new(2806, 136, 2732),
	["Sunken Pool"] = Vector3.new(-4996, -581, 1847),
	["Sunken Trial"] = Vector3.new(-4625, -598, 1844),
	["Kraken Door"] = Vector3.new(-4389, -984, 1808),
	["Podium 1"] = Vector3.new(-3405, -2263, 3825),
	["Podium 2"] = Vector3.new(-768, -3283, -688),
	["Podium 3"] = Vector3.new(-13538, -11050, 129),
	
}

local selectedLocation; 
local autoCastEnabled = false -- Status Auto Cast
local autoCastRunning = false -- Untuk mencegah loop ganda 
-- Fungsi untuk mengecek apakah tombol "shake button" ada di UI
local function isShakeButtonExist() 
	while true do 
		local player = game:GetService("Players").LocalPlayer
		if not player then return false end

		local playerGui = player:WaitForChild("PlayerGui")
		if not playerGui then return false end

		local shakeUI = playerGui:WaitForChild("shakeui")
		if not shakeUI then return false end

		local safezone = shakeUI:WaitForChild("safezone")
		if not safezone then return false end

		local button = safezone:WaitForChild("button")
		return button ~= nil -- True jika tombol ditemukan, False jika tidak ada
		
	end	
	wait(1)
end

local function isRodEquipped()
	local player = game.Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") and string.find(string.lower(tool.Name), "rod") then
			return true -- Rod sudah di-equip
		end
	end
	return false -- Rod belum di-equip
end
local selectedFishName = nil
local function getRodPath()
	local backpack = plr:FindFirstChild("Backpack")
	if not backpack then 
		warn("Backpack tidak ditemukan!") 
		return nil 
	end

	-- Cek isi Backpack
	for _, item in ipairs(backpack:GetChildren()) do
		print("Ditemukan item:", item.Name, item:IsA("Tool"))

		if item:IsA("Tool") and item.Name and string.find(string.lower(item.Name), "rod") then
			print("Rod ditemukan:", item.Name)
			return item:GetFullName()
		end
	end

	warn("Tidak ada Rod di Backpack!")
	return nil
end


local function isRodExist()
	return getRodPath() ~= nil -- Jika getRodName() mengembalikan nama, berarti Rod ada
end
local rodName = getRodPath()

-- Fungsi Auto Cast
local function cast()
	for _, item in ipairs(plr.Character:GetChildren()) do
		if item:IsA("Tool") and item.Name and string.find(string.lower(item.Name), "rod") then
			print("Rod ditemukan di Character:", item.Name)

			local rod = plr.Character:FindFirstChild(item.Name)
			if rod then
				local events = rod:FindFirstChild("events")
				if events then
					local castEvent = events:FindFirstChild("cast")
					if castEvent then
						castEvent:FireServer(100, 1) 
					else
						warn("Event 'cast' tidak ditemukan di Rod!")
					end
				else
					warn("Folder 'events' tidak ditemukan di Rod!")
				end
			end
		end
	end
end

local function sell()
	game:GetService('ReplicatedStorage').events.Sell:InvokeServer()
end
local loopSellActivated = false
local function Loopsell()
	while loopSellActivated do
		game:GetService('ReplicatedStorage').events.Sell:InvokeServer()
		wait()
	end
end

local function sellAll()
	game:GetService('ReplicatedStorage').events.SellAll:InvokeServer()
end
local loopSellAllactivated = false
local function loopSellAll(delaynum)
	if loopSellAllactivated then return end
	loopSellAllactivated = true
	while loopSellAllactivated do
		game:GetService('ReplicatedStorage').events.SellAll:InvokeServer()
		wait(delaynum)
	end
end 
local function stopLoopSell()
	loopSellActivated = false
end
-- Fungsi untuk memulai Auto Cast
local function StartAutoCast()
	if autoCastRunning then return end -- Cegah loop ganda
	if isRodEquipped() then return end
	autoCastRunning = true
		while autoCastEnabled do
		if not isShakeButtonExist() or isReelExist() then
			cast()
		else
			print("Shake button atau reel ui ditemukan! Tidak Auto Cast.")
		end
		task.wait(0.35)
	end
end

-- Fungsi untuk menghentikan Auto Cast
local function StopAutoCast()
	autoCastEnabled = false
	print("Auto Cast Dihentikan!")
end

local autoShakeEnabled = false -- Status Auto Shake
local autoShakeRunning = false -- Untuk mencegah loop ganda
local activated = true
function isReelExist()
	while activated do
		local reelui = plr.PlayerGui:WaitForChild("reel")
		if reelui then
			print("Reel ditemukan! Auto Shake dihentikan.")
		else
			warn("Reel not found!")
		end
		wait(0.5)
	end
end

-- Fungsi untuk mendapatkan posisi tombol "shake button"
local function getShakeButtonPosition()
	local player = game:GetService("Players").LocalPlayer
	if not player then return nil end

	local playerGui = player:WaitForChild("PlayerGui")
	if not playerGui then return nil end

	local shakeUI = playerGui:WaitForChild("shakeui")
	if not shakeUI then return nil end

	local safezone = shakeUI:WaitForChild("safezone")
	if not safezone then return nil end

	local button = safezone:WaitForChild("button")
	if not button or not button:IsA("GuiObject") then return nil end

	-- Karena AnchorPoint sudah 0.5, maka AbsolutePosition sudah menunjukkan titik tengahnya
	local buttonPos = button.AbsolutePosition
	return Vector2.new(buttonPos.X, buttonPos.Y)
end
local function DebugENDSREEL()
	game.ReplicatedStorage.events["reelfinished" .. ' ']:FireServer(100, true)
end
local function AutoShake()
	if not isShakeButtonExist() then return end
	local buttonPos = getShakeButtonPosition()
	if not buttonPos then return end
	while autoShakeEnabled do
		local shakeButton = isShakeButtonExist()
		if shakeButton then
			shakeButton.Position = UDim2.new(0, buttonPos.X, 0, buttonPos.Y)
		else
			print("Shake button not found! Auto Shake dihentikan.")
			break
		end
		wait(0.1)
	end
end
local function disable()
	for _, any in ipairs(plr.Character:GetChildren()) do
		if any:IsA("LocalScript") or any:IsA("Script") then
			any.Enabled = false
		end
	end
end
local SGUI = Instance.new("ScreenGui")
SGUI.ResetOnSpawn = false
SGUI.Parent = gethui()
local instantReel = false
-- idk but test
local function Instantreel()
	if instantReel then return end
	instantReel = true
	while instantReel do
	if isReelExist() then
		game:GetService("ReplicatedStorage").events["reelfinished" .. ' ']:FireServer(100, true)
	end
		wait(0.25)
	end
end
local function appraiseHand()
	local rf = game.Workspace.world.npcs.Appraiser.appraiser.appraise
	rf:InvokeServer()
end
-- Variabel global untuk menyimpan nama ikan yang dipilih
local selectedFishName = "None"

local function Appraise(fishName)
	local rf = game:GetService("Workspace"):WaitForChild("world")
		:WaitForChild("npcs"):WaitForChild("Appraiser")
		:WaitForChild("appraiser"):WaitForChild("appraise")

	if not rf then
		warn("Remote Function 'appraise' tidak ditemukan!")
		return
	end

	if not plr or not plr.Character then
		warn("Player atau Character tidak ditemukan!")
		return
	end

	local backpack = plr:FindFirstChild("Backpack")
	if not backpack then
		warn("Backpack tidak ditemukan!")
		return
	end

	local fish = backpack:FindFirstChild(fishName)
	if not fish then
		warn("Ikan tidak ditemukan di Backpack:", fishName)
		Fluent:Notify({
			Title = "Errno",
			Content = "The fish '" .. fishName .. "' is not in your inventory!",
			Duration = 8
		})
		return
	end

	local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("Humanoid tidak ditemukan!")
		return
	end

	humanoid:EquipTool(fish) -- Equip ikan sebelum appraisal
	rf:InvokeServer() -- Panggil server untuk menilai ikan
	print("Appraising:", fishName)
end
local function stopInstantReel()
	instantReel = false
	print("Auto Reel Dihentikan!")
end
local failReelrunning = false
local function Failreel()
	if failReelrunning then return end
	failReelrunning = true
	if isShakeButtonExist() then return end
	if not isShakeButtonExist() then 
		while failReelrunning do
			if isReelExist() then
				game:GetService('ReplicatedStorage').events["reelfinished" .. ' ']:FireServer(50, false)
			end
			wait(0.25)
		end
	end
end
local bigBarRunning = false -- Status loop
local function bigBar()
	if bigBarRunning then return end -- Cegah loop ganda
	bigBarRunning = true

	task.spawn(function()
		local plr = game.Players.LocalPlayer

		while bigBarRunning do
			local playerGui = plr:WaitForChild("PlayerGui")
			local reel = playerGui and playerGui:WaitForChild("reel")
			local bar = reel and reel:WaitForChild("bar")
			local playerbar = bar and bar:WaitForChild("playerbar")

			if playerbar then
				-- Ubah ukuran jika playerbar ada
				playerbar.Size = UDim2.new(1.1, 0, 1.1, 0)
			end

			wait(0.25)
		end
	end)
end
local function stopBigBar()
	bigBarRunning = false -- Menghentikan loop saat iterasi berikutnya
end
local selectedMode = "None"
local function autoReel(mode)
	if mode == "Instant" then
		Instantreel() -- Instant sukses tanpa delay
	elseif mode == "Legit" then
		bigBar() -- Auto sukses dengan delay
	elseif mode == "Fail" then
		Failreel() -- Langsung gagal (snap)
	end
end
local shakeNoDelay = 0.1

-- Fungsi untuk memulai Auto Shake
local function StartAutoShake()
	if autoShakeRunning then return end -- Cegah loop ganda
	autoShakeRunning = true

	task.spawn(function()
		while autoShakeEnabled do
			AutoShake()
			task.wait(shakeNoDelay) -- Tunggu sebelum melakukan klik lagi
		end
		autoShakeRunning = false -- Reset status saat loop berhenti
	end)
end

-- Fungsi untuk menghentikan Auto Shake
local function StopAutoShake()
	autoShakeEnabled = false
	print("Auto Shake Dihentikan!")
end

local function teleportToLocation(locationName)
	if plr and plr.Character then
		local hrp = plr.Character:WaitForChild("HumanoidRootPart")
		if hrp and teleportLocations[locationName] then
			hrp.CFrame = CFrame.new(teleportLocations[locationName])
		end
	end
end

local function setSpeed(speed)
	local player = game.Players.LocalPlayer
	if player and player.Character and player.Character:WaitForChild("Humanoid") then
		player.Character.Humanoid.WalkSpeed = speed
		print("Speed changed to:", speed)
	else
		warn("Player or Humanoid not found!")
	end
end
local autoReelEnabled = false
local originalSize = nil -- Simpan ukuran asli sebelum diubah
local autoEquipRodBool = false
local function autoEquipRod()
	local player = game.Players.LocalPlayer
	local backpack = player:FindFirstChild("Backpack")

	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and string.find(tool.Name:lower(), "rod") then
				while autoEquipRodBool do
				player.Character.Humanoid:EquipTool(tool)
				wait(0.2)
				end
			end
		end
	end
end


local function ToggleInfiniteJump(Player)
	InfiniteJumpEnabled = not InfiniteJumpEnabled
	print("Infinite Jump:", InfiniteJumpEnabled and "Aktif" or "Nonaktif")

	if InfiniteJumpEnabled then
		-- Aktifkan Infinite Jump
		JumpConnection = UserInputService.JumpRequest:Connect(function()
			local Character = Player.Character or Player.CharacterAdded:Wait()
			local Humanoid = Character:WaitForChildWhichIsA("Humanoid")
			if Humanoid then
				Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	else
		-- Nonaktifkan Infinite Jump
		if JumpConnection then
			JumpConnection:Disconnect()
			JumpConnection = nil
		end
	end
end
local function hopserver()
	local serv = game:GetService("TeleportService")
	if plr then
		serv:TeleportToPlaceInstance(game.PlaceId, plr)
	end
end
local function rj()
	local tpService = game:GetService("TeleportService")
	local player = game.Players.LocalPlayer
	local placeId = game.PlaceId
	local jobId = game.JobId
	if player then
		tpService:TeleportToPlaceInstance(placeId, jobId, player)
	end
end
local function stopAutoEquip()
	autoEquipRodBool = false
end
local PyroVersion = "1.1.5"

local locationNames = {}
for name, _ in pairs(teleportLocations) do
	table.insert(locationNames, name)
end

local Window = Fluent:CreateWindow({
	Title = "Pyro Hub " .. PyroVersion,
	SubTitle = "by dzkkkr",
	TabWidth = 160,
	Size = UDim2.fromOffset(480, 360),
	Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})


--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
	LocalPlayer = Window:AddTab({ Title = "Tab LocalPlayer", Icon = "" }),
	Main = Window:AddTab({ Title = " Tab Main", Icon = "" }),
	Inventory = Window:AddTab({ Title = "Tab Inventory", Icon = "" }),
	Teleport = Window:AddTab({ Title = "Tab Teleport", Icon = "" }),	
	Misc = Window:AddTab({ Title = "Tab Misc", Icon = "" }),
	Debug = Window:AddTab({ Title = "Tab Debug", Icon = "" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "" })
}


local Options = Fluent.Options

do
	Fluent:Notify({
		Title = "Notification",
		Content = "Thanks For trying this script!",
		Duration = 10 -- Set to nil to make the notification not disappear
	})



	Tabs.LocalPlayer:AddParagraph({
		Title = "LocalPlayer",
		Content = "You can change speed or smth else in this tab"
	})


	Tabs.LocalPlayer:AddButton({
		Title = "Rejoin",
		Description = "Rejoin The Game",
		Callback = function()
			Window:Dialog({
				Title = "Rejoin",
				Content = "Are You Sure Want To Rejoin?",
				Buttons = {
					{
						Title = "Confirm",
						Callback = function()
							print("Confirmed the dialog.")
							wait()
							rj()
						end
					},
					{
						Title = "Cancel",
						Callback = function()
							print("Cancelled the dialog.")
						end
					}
				}
			})
		end
	})
	Tabs.LocalPlayer:AddButton({
		Title = "Load Infinite Yield",
		Description = "Load Infinite Yield Admin Commands!",
		Callback = function()
			Window:Dialog({
				Title = "Load IY",
				Content = "Load The Infinite Yield",
				Buttons = {
					{
						Title = "Confirm",
						Callback = function()
							loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
						end
					},
					{
						Title = "Cancel",
						Callback = function()
							return print("Cancelled the dialog.")
						end
					}
				}
			})

		end
	})
	
	Tabs.LocalPlayer:AddButton({
		Title = "Load Keyboard",
		Description = "Load Keyboard Script",
		Callback = function()
			Window:Dialog({
				Title = "Load Keyboard Script",
				Content = "Load Script?",
				Buttons = {
					{
						Title = "Confirm",
						Callback = function()
							loadstring(game:HttpGet("https://raw.githubusercontent.com/Xxtan31/Ata/main/deltakeyboardcrack.txt", true))()
						end
					},
					{
						Title = "Cancel",
						Callback = function()
							print("Cancelled the dialog.")
						end
					}
				}
			})
		end
	})


	Tabs.LocalPlayer:AddButton({
		Title = "Hop Server",
		Description = "Hop To Random Server",
		Callback = function()
			Window:Dialog({
				Title = "Hop Server",
				Content = "Are You Sure Want To Continue?",
				Buttons = {
					{
						Title = "Confirm",
						Callback = function()
							print("Confirmed the dialog.")
							wait()
							hopserver()
						end
					},
					{
						Title = "Cancel",
						Callback = function()
							print("Cancelled the dialog.")
						end
					}
				}
			})
		end
	})

	local Toggle = Tabs.LocalPlayer:AddToggle("MyToggle", {Title = "Infinite Jump", Default = false })

	Toggle:OnChanged(function()
		print("Toggle changed:", Options.MyToggle.Value)
		if Options.MyToggle.Value == false  then
			ToggleInfiniteJump(plr)
		end
		if Options.MyToggle.Value == true then
			ToggleInfiniteJump(plr)
		end
	end)

	Options.MyToggle:SetValue(false)

	local function setSpeed(speed)
		local player = game.Players.LocalPlayer
		if player and player.Character and player.Character:WaitForChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = speed
			print("Speed changed to:", speed)
		else
			warn("Player or Humanoid not found!")
		end
	end

	-- Input Box untuk memasukkan angka kecepatan
	local Input = Tabs.LocalPlayer:AddInput("SpeedInput", {
		Title = "Speed Changer",
		Default = "16",
		Placeholder = "Enter Speed",
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			if Options.SpeedToggle.Value then
				local speed = tonumber(Value) or 16
				setSpeed(speed)
			end
		end
	})


	-- Toggle untuk mengaktifkan/mematikan speed changer
	local Toggle = Tabs.LocalPlayer:AddToggle("SpeedToggle", {
		Title = "Change Speed",
		Default = false,
		Callback = function(state)
			if state then
				local speed = tonumber(Options.SpeedInput.Value) or 16
				setSpeed(speed)
			else
				setSpeed(16) -- Reset ke default speed
			end
		end
	})

	Options.SpeedToggle:SetValue(false)
	
	Tabs.Main:AddParagraph({
		Title = "Fisch",
		Content = "For Fisch Game, can tp and new feature is coming soon!"
	})
	
	local Dropdown = Tabs.Teleport:AddDropdown("Dropdown", {
		Title = "Teleport to...",
		Description = "Select a location to teleport",
		Values = locationNames, -- Menggunakan nama lokasi sebagai opsi dropdown
		Multi = false,
		Default = "None",
		Callback = function(value)
			selectedLocation = value -- Simpan lokasi yang dipilih
		end
	})

	Tabs.Teleport:AddButton({
		Title = "Teleport",
		Description = "Teleport To Your Selected Place",
		Callback = function()
			if selectedLocation and selectedLocation ~= "None" then
				teleportLocations(selectedLocation) -- Kirim lokasi ke fungsi teleport
			else
				error('lol');
			end
		end
	})
	local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
		Title = "Mode Auto Reel",
		Description = "Select Mode Auto Reel",
		Values = { "Instant", "Legit", "Fail", "None" },
		Multi = false,
		Default = "None",
		Callback = function(value)
			selectedMode = value -- Simpan nilai mode yang dipilih
			print("Mode Auto Reel diubah ke:", selectedMode)
		end,
	})
	local autoEquip = Tabs.Main:AddToggle("AutoEquip", {
		Title = "Auto Equip Rod",
		Default = false,
		Callback = function(value)
			autoEquipRodBool = value
			if value then
				autoEquipRod()
			else
				stopAutoEquip()
			end
		end,
	})
	
	local toggle = Tabs.Main:AddToggle("AutoCast", {
		Title = "Auto Cast",
		Default = false,
		Callback = function(value)
			autoCastEnabled = value
			if value then
				StartAutoCast()
			else
				StopAutoCast()
			end
		end,
	})
	
	Options.AutoCast:SetValue(false)
	local autoShake = Tabs.Main:AddToggle("AutoShake", {
		Title = "Auto Shake",
		Default = false,
		Callback = function(value)
			autoShakeEnabled = value
			if autoShakeEnabled then
				StartAutoShake()
			else
				StopAutoShake()
			end
		end,
	})
	local Toggle = Tabs.Main:AddToggle("AutoReel", {
		Title = "Auto Reel",
		Default = false,
		Callback = function(value)
			if value then
				print("Auto Reel diaktifkan dalam mode:", selectedMode)
				autoReel(selectedMode) -- Jalankan mode yang dipilih
			else
				stopInstantReel()
				stopBigBar()
				failReelrunning = false -- Hentikan Fail Reel loop
				print("Auto Reel dimatikan")
			end
		end,
	})
	Tabs.Inventory:AddButton({
		Title = "Sell All",
		Description = "Sell Your Fish, if not selling all goto menu scroll down and activate your fish rarity",
		Callback = function()
			sellAll()
		end
	})
	Tabs.Inventory:AddButton({
		Title = "Sell Hand",
		Description = "Sell fish in your hand!",
		Callback = function()
			sell()
		end,
	})
	local toggle = Tabs.Inventory:AddToggle("AutoSell",{
		Title = "Auto Sell Hand",
		Default = false,
		Callback = function(value)
			loopSellActivated = value
			if value then
				Loopsell()
			else 
				stopLoopSell()
			end
		end,
	})
	Tabs.Inventory:AddInput("DelaySellAll", {
		Title = "Delay Sell All",
		Default = "0.5",
		Placeholder = "Enter Delay",
		Numeric = true,
		Finished = true,
		Callback = function(Value)
			local delay = tonumber(Value) or 3
			if loopSellAllactivated then
				loopSellAllactivated = false -- Hentikan loop sebelumnya
				task.wait(0.1) -- Beri jeda kecil sebelum memulai ulang
				loopSellAll(delay) -- Mulai loop baru dengan delay baru
			end
		end
	})

	local toggle = Tabs.Inventory:AddToggle("LoopSellAll",{
		Title = "Loop Sell All",
		Default = false,
		Callback = function(state)
			if state then
				local delay = tonumber(Options.DelaySellAll.Value) or 3
				loopSellAll(delay)
			else
				loopSellAllactivated = false -- Hentikan loop
			end
		end
	})
	Tabs.Inventory:AddParagraph({
		Title = "Appraise",
		Content = "Appraise Your Fish"
	})
	Tabs.Inventory:AddInput("TypeFishName", { 
		Title = "Input name",
		Default = "None",
		Placeholder = "Enter specific name",
		Numeric = false,
		Finished = true,
		Callback = function(state)
			if state and state ~= "" then
				selectedFishName = state
				print("Selected Fish:", selectedFishName)
			end
		end,
	})

	-- Tombol untuk memulai proses auto appraise
	Tabs.Inventory:AddButton({
		Title = "Auto Appraise",
		Default = false,
		Callback = function()
			if selectedFishName ~= "None" and selectedFishName ~= "" then
				Appraise(selectedFishName) 
			else
				Fluent:Notify({
					Title = "Errno",
					Content = "Please Input The Specific Fish Name!",
					Duration = 8
				})
			end
		end,
	})
	Tabs.Inventory:AddDropdown("AppraiseUntilMutation",{
		Title = "Select Mutation...",
		Description = "Select Mutation For Auto Appraise",
		Values = { "Lunar", "Mythical", "Greedy", "Fossillized", "Abyssal", "Hexed","Midas", "Glossy","Silver", "Mosaic","Electric", "Scorched","Darkened", "Translucent","Frozen", "Negative","Albino", "Amber" }
	})
	Tabs.Inventory:AddDropdown("Attribute1",{
		Title = "Select Attribute 1...",
		Description = "Select Attribute 1, Select Shiny or Sparkling",
		Values = { "Sparkling", "Shiny" }
	})
	Tabs.Inventory:AddDropdown("Attribute2",{
		Title = "Select Attribute 2...",
		Description = "Select Attribute 2, Select Big or Giant",
		Values = { "Giant", "Big" }
	})
	Tabs.Inventory:AddButton({
		Title = "Appraise Hand",
		Description = "Appraise Fish on your hand",
		Callback = function()
			appraiseHand()
		end,
	})
	Tabs.Misc:AddButton({
		Title = "Disable All",
		Description = "Will Disable oxygen, oxygen(peaks), temperature, temperature(heat)",
		Callback = function()
			disable()
		end,
	})
	Tabs.Debug:AddParagraph({
		Title = "DEBUG Tab",
		Content = "This Is Debug Tab If You Got Bugged May You Can Debug In this Tab."
	})
	Tabs.Debug:AddButton({
		Title = "Ends Reel",
		Description = "Ending Reel",
		Callback = function()
			DebugENDSREEL()
		end,
	})
	Tabs.Debug:AddButton({
		Title = "Reset",
		Description = "Reset Your Char.",
		Callback = function()
			Window:Dialog({
				Title = "Reset Char.",
				Content = "Are You Sure Want To Continue?",
				Buttons = {
					{
						Title = "Confirm",
						Callback = function()
							print("Confirmed the dialog.")
							wait()
							plr.Character:FindFirstChildOfClass("Humanoid").Health = 0
						end
					},
					{
						Title = "Cancel",
						Callback = function()
							print("Cancelled the dialog.")
						end
					}
				}
			})
		end,
	})
	
end


-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- InterfaceManager (Allows you to have a interface managment system)

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


Window:SelectTab(1)

Fluent:Notify({
	Title = "Fluent",
	Content = "The script has been loaded.",
	Duration = 8
})

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()