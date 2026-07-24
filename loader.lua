--// MM2 AutoFarm v2.6 - SPEED 14, не летит вверх

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

local character, humanoid, humanoidRootPart = nil, nil, nil

local function updateCharacterRefs(newChar)
	if not newChar then return false end
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid", 3)
	humanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 3)
	return humanoid ~= nil and humanoidRootPart ~= nil
end

updateCharacterRefs(player.Character or player.CharacterAdded:Wait())

pcall(function()
	local mt = getrawmetatable(game)
	if mt then
		local oldNamecall = mt.__namecall
		local oldIndex = mt.__index
		setreadonly(mt, false)
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			if method == "Kick" or method == "kick" then return nil end
			return oldNamecall(self, ...)
		end)
		mt.__index = newcclosure(function(self, key)
			if key == "Kick" or key == "kick" then return function() end end
			return oldIndex(self, key)
		end)
		setreadonly(mt, true)
	end
end)

pcall(function()
	local oldKick = hookfunction(player.Kick, function(self, ...)
		if self == player then return nil end
		return oldKick(self, ...)
	end)
end)

local noclipConnection = nil

local function enableNoclip()
	if noclipConnection then noclipConnection:Disconnect() end
	noclipConnection = RunService.Stepped:Connect(function()
		if not character then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end)
end

local function disableNoclip()
	if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
	if character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = true end
		end
	end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2AutoFarmGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainButton"
mainFrame.Size = UDim2.new(0, 100, 0, 100)
mainFrame.Position = UDim2.new(0.85, 0, 0.75, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 20)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 50, 50)
stroke.Thickness = 3
stroke.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, 0, 1, 0)
toggleButton.BackgroundTransparency = 1
toggleButton.Text = "▶"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 40
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 1, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "OFF"
statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
statusLabel.TextSize = 16
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = mainFrame

local CONFIG = {
	COIN_TELEPORT_DIST = 3,
	COOLDOWN = 0.15,
	SPEED = 14,
	JUMP = 50,
	ESP_ENABLED = true,
	NOCLIP = true,
	NEAR_RADIUS = 500,
}

local isRunning = false
local espFolder = nil
local antiAfkConnection = nil
local afkTimer = 0

local function getDistance(p1, p2)
	if not p1 or not p2 then return math.huge end
	return (p1 - p2).Magnitude
end

local function isAliveCheck(plr)
	if not plr then return false end
	local char = plr.Character
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function createESP()
	if espFolder then espFolder:Destroy() end
	espFolder = Instance.new("Folder")
	espFolder.Name = "CoinESP"
	espFolder.Parent = Workspace.CurrentCamera
end

local function addESP(part, text)
	if not part or not part.Parent then return end
	if part:FindFirstChild("CoinESP_Billboard") then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "CoinESP_Billboard"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, 80, 0, 40)
	bb.StudsOffset = Vector3.new(0, 1.5, 0)
	bb.Adornee = part
	bb.Parent = espFolder
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	lbl.TextSize = 12
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = bb
end

local function isRealCoin(obj)
	if not obj or not obj.Parent then return false end
	if not obj:IsA("BasePart") and not obj:IsA("MeshPart") then return false end
	local n = obj.Name
	if n ~= "Coin_Server" and n ~= "CoinVisual" and n ~= "MainCoin" and n ~= "Coin" then return false end
	if character and obj:IsDescendantOf(character) then return false end
	return true
end

local function findCoins()
	local coins = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if isRealCoin(obj) then
			table.insert(coins, obj)
		end
	end
	if humanoidRootPart then
		table.sort(coins, function(a, b)
			return getDistance(humanoidRootPart.Position, a.Position) < getDistance(humanoidRootPart.Position, b.Position)
		end)
	end
	return coins
end

local function tpTo(pos)
	if not humanoidRootPart then return end
	humanoidRootPart.CFrame = CFrame.new(pos)
end

local function tweenTo(pos)
	if not humanoidRootPart then return end
	local currentPos = humanoidRootPart.Position
	local dist = getDistance(currentPos, pos)
	if dist < 2 then tpTo(pos); return end
	
	-- Не летим вверх — Y = текущий Y игрока
	local flatPos = Vector3.new(pos.X, currentPos.Y, pos.Z)
	local tween = TweenService:Create(humanoidRootPart, TweenInfo.new(math.min(dist / 25, 1.5), Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(flatPos)
	})
	tween:Play()
	tween.Completed:Wait()
end

local function startAntiAfk()
	antiAfkConnection = RunService.Heartbeat:Connect(function(dt)
		if not isRunning then return end
		afkTimer = afkTimer + dt
		if afkTimer >= 8 then
			afkTimer = 0
			VirtualInputManager:SendMouseMoveEvent(math.random(-5, 5), math.random(-5, 5), game)
		end
	end)
end

local function stopAntiAfk()
	if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
end

local function applySpeed()
	if humanoid then humanoid.WalkSpeed = CONFIG.SPEED; humanoid.JumpPower = CONFIG.JUMP end
end

local function collectCoin(coin)
	if not coin or not coin.Parent then return end
	if not humanoidRootPart then return end
	if not isAliveCheck(player) then return end
	
	local coinPos = coin.Position
	local dist = getDistance(humanoidRootPart.Position, coinPos)
	
	if dist > CONFIG.NEAR_RADIUS then return end
	
	if CONFIG.ESP_ENABLED then addESP(coin, "💰") end
	
	if dist > CONFIG.COIN_TELEPORT_DIST then
		tweenTo(coinPos)
	else
		tpTo(coinPos)
	end
	
	task.wait(0.03)
	
	pcall(function()
		firetouchinterest(humanoidRootPart, coin, 0)
		task.wait(0.02)
		firetouchinterest(humanoidRootPart, coin, 1)
	end)
	
	pcall(function()
		local prompt = coin:FindFirstChildOfClass("ProximityPrompt")
		if prompt then fireproximityprompt(prompt, 0) end
	end)
	
	pcall(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes then
			local collect = remotes:FindFirstChild("CoinCollected") or remotes:FindFirstChild("CollectCoin") or remotes:FindFirstChild("PickupCoin")
			if collect then collect:FireServer(coin) end
		end
	end)
	
	pcall(function()
		local rp = ReplicatedStorage:FindFirstChild("RF") or ReplicatedStorage:FindFirstChild("RE")
		if rp then
			local pickup = rp:FindFirstChild("Pickup") or rp:FindFirstChild("Collect")
			if pickup then pickup:InvokeServer(coin) end
		end
	end)
	
	applySpeed()
	task.wait(CONFIG.COOLDOWN)
end

local function farmLoop()
	createESP()
	
	while isRunning do
		if not isAliveCheck(player) then
			statusLabel.Text = "💀"
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
			if noclipConnection then disableNoclip() end
			while isRunning and not isAliveCheck(player) do task.wait(0.5) end
			if not isRunning then return end
			local newChar = player.Character
			if newChar then
				updateCharacterRefs(newChar)
				statusLabel.Text = "▶"
				statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
				if CONFIG.NOCLIP then enableNoclip() end
				applySpeed()
			end
		end
		
		if not humanoidRootPart then task.wait(0.5); continue end
		
		local coins = findCoins()
		
		if #coins == 0 then
			task.wait(0.5)
			continue
		end
		
		for _, coin in ipairs(coins) do
			if not isRunning then break end
			if not isAliveCheck(player) then break end
			collectCoin(coin)
		end
		
		task.wait(0.1)
	end
end

function startFarm()
	if isRunning then return end
	isRunning = true
	toggleButton.Text = "⏸"
	statusLabel.Text = "▶"
	statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
	stroke.Color = Color3.fromRGB(50, 255, 50)
	if CONFIG.NOCLIP then enableNoclip() end
	startAntiAfk()
	applySpeed()
	task.spawn(function()
		local ok, err = pcall(farmLoop)
		if not ok then warn("[MM2AF] Ошибка: " .. tostring(err)); stopFarm() end
	end)
end

function stopFarm()
	isRunning = false
	stopAntiAfk()
	disableNoclip()
	toggleButton.Text = "▶"
	statusLabel.Text = "OFF"
	statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	stroke.Color = Color3.fromRGB(255, 50, 50)
	if espFolder then espFolder:Destroy(); espFolder = nil end
end

toggleButton.MouseButton1Click:Connect(function()
	if isRunning then stopFarm() else startFarm() end
end)

local pressStart = 0
toggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		pressStart = tick()
	end
end)

toggleButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if tick() - pressStart >= 1.5 then stopFarm(); screenGui:Destroy() end
	end
end)

player.CharacterAdded:Connect(function(newChar)
	updateCharacterRefs(newChar)
	if isRunning then
		if CONFIG.NOCLIP then enableNoclip() end
		applySpeed()
	end
end)

player.CharacterRemoving:Connect(function()
	if isRunning then statusLabel.Text = "💀"; statusLabel.TextColor3 = Color3.fromRGB(255, 100, 0) end
end)

print("MM2 AutoFarm v2.6 загружен. SPEED=14, flat Y")
