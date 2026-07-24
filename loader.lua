--// MM2 AutoFarm v2.0 - Server Data Counter
--// Счёт по данным сервера, пауза при смерти, 50 макс, авто-продолжение после респавна

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- РЕФЕРЕНСЫ НА КЕРАКТЕР (динамические)
-- ═══════════════════════════════════════════════════════════════
local character = nil
local humanoid = nil
local humanoidRootPart = nil

local function updateCharacterRefs(newChar)
	character = newChar
	if not character then return false end
	humanoid = character:WaitForChild("Humanoid", 3)
	humanoidRootPart = character:WaitForChild("HumanoidRootPart", 3)
	return humanoid ~= nil and humanoidRootPart ~= nil
end

updateCharacterRefs(player.Character or player.CharacterAdded:Wait())

-- ═══════════════════════════════════════════════════════════════
-- АНТИ-КИК (многослойный)
-- ═══════════════════════════════════════════════════════════════
pcall(function()
	local mt = getrawmetatable(game)
	if mt then
		local oldNamecall = mt.__namecall
		local oldIndex = mt.__index
		setreadonly(mt, false)
		
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			if method == "Kick" or method == "kick" then
				return nil
			end
			return oldNamecall(self, ...)
		end)
		
		mt.__index = newcclosure(function(self, key)
			if key == "Kick" or key == "kick" then
				return function() end
			end
			return oldIndex(self, key)
		end)
		
		setreadonly(mt, true)
	end
end)

pcall(function()
	local oldKick = hookfunction(player.Kick, function(self, ...)
		if self == player then
			return nil
		end
		return oldKick(self, ...)
	end)
end)

-- ═══════════════════════════════════════════════════════════════
-- N O C L I P
-- ═══════════════════════════════════════════════════════════════
local noclipConnection = nil

local function enableNoclip()
	if noclipConnection then noclipConnection:Disconnect() end
	noclipConnection = RunService.Stepped:Connect(function()
		if not character then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
end

local function disableNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
	if character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════
-- GUI
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- КОНФИГ
-- ═══════════════════════════════════════════════════════════════
local CONFIG = {
	COIN_TELEPORT_DIST = 3,
	SAFE_DIST_KILLER = 15,
	COOLDOWN = 0.08,
	SPEED = 20,
	JUMP = 50,
	ESP_ENABLED = true,
	NOCLIP = true,
	NEAR_RADIUS = 100,
	MAX_COINS = 50,
}

-- ═══════════════════════════════════════════════════════════════
-- СОСТОЯНИЕ
-- ═══════════════════════════════════════════════════════════════
local isRunning = false
local isAliveFlag = true
local espFolder = nil
local antiAfkConnection = nil
local afkTimer = 0
local startServerCoins = 0
local collectedCoins = 0

-- ═══════════════════════════════════════════════════════════════
-- СЧЁТЧИК ПО ДАННЫМ СЕРВЕРА
-- ═══════════════════════════════════════════════════════════════
local function getServerCoinData()
	-- Метод 1: PlayerData в ReplicatedStorage
	local ok, result = pcall(function()
		local data = ReplicatedStorage:FindFirstChild("PlayerData") or ReplicatedStorage:FindFirstChild("Data")
		if data then
			local plrData = data:FindFirstChild(player.Name) or data:FindFirstChild(tostring(player.UserId))
			if plrData then
				local coins = plrData:FindFirstChild("Coins") or plrData:FindFirstChild("coins") or plrData:FindFirstChild("Money")
				if coins and (coins:IsA("IntValue") or coins:IsA("NumberValue")) then
					return coins.Value
				end
			end
		end
		return nil
	end)
	if ok and result ~= nil then return result end
	
	-- Метод 2: Stats в player
	ok, result = pcall(function()
		local stats = player:FindFirstChild("leaderstats") or player:FindFirstChild("Stats")
		if stats then
			local coins = stats:FindFirstChild("Coins") or stats:FindFirstChild("coins") or stats:FindFirstChild("Money")
			if coins and (coins:IsA("IntValue") or coins:IsA("NumberValue")) then
				return coins.Value
			end
		end
		return nil
	end)
	if ok and result ~= nil then return result end
	
	-- Метод 3: Values в Workspace
	ok, result = pcall(function()
		local values = Workspace:FindFirstChild("Values") or Workspace:FindFirstChild("GameValues")
		if values then
			local coins = values:FindFirstChild("Coins") or values:FindFirstChild("TotalCoins")
			if coins and (coins:IsA("IntValue") or coins:IsA("NumberValue")) then
				return coins.Value
			end
		end
		return nil
	end)
	if ok and result ~= nil then return result end
	
	-- Метод 4: Attributes на player
	ok, result = pcall(function()
		return player:GetAttribute("Coins") or player:GetAttribute("coins") or player:GetAttribute("Money")
	end)
	if ok and result ~= nil then return result end
	
	-- Метод 5: Attributes на character
	ok, result = pcall(function()
		if not character then return nil end
		return character:GetAttribute("Coins") or character:GetAttribute("coins")
	end)
	if ok and result ~= nil then return result end
	
	return 0
end

-- ═══════════════════════════════════════════════════════════════
-- УТИЛИТЫ
-- ═══════════════════════════════════════════════════════════════
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

local function getMurderer()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local bp = p:FindFirstChild("Backpack")
			local char = p.Character
			if (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
				return p
			end
		end
	end
	return nil
end

-- ═══════════════════════════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════════════════════════
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

local function clearESP()
	if espFolder then
		for _, child in ipairs(espFolder:GetChildren()) do
			child:Destroy()
		end
	end
end

-- ═══════════════════════════════════════════════════════════════
-- ПРОВЕРКА МОНЕТЫ
-- ═══════════════════════════════════════════════════════════════
local function isRealCoin(obj)
	if not obj or not obj.Parent then return false end
	if not obj:IsA("BasePart") and not obj:IsA("MeshPart") then return false end
	
	local n = obj.Name
	if n ~= "Coin_Server" and n ~= "CoinVisual" and n ~= "MainCoin" and n ~= "Coin" then
		return false
	end
	
	if character and obj:IsDescendantOf(character) then
		return false
	end
	
	return true
end

-- ═══════════════════════════════════════════════════════════════
-- ПОИСК МОНЕТ
-- ═══════════════════════════════════════════════════════════════
local function findCoins()
	local coins = {}
	local hrp = humanoidRootPart
	
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if isRealCoin(obj) then
			table.insert(coins, obj)
		end
	end
	
	if hrp then
		table.sort(coins, function(a, b)
			if not a or not b then return false end
			return getDistance(hrp.Position, a.Position) < getDistance(hrp.Position, b.Position)
		end)
	end
	
	return coins
end

-- ═══════════════════════════════════════════════════════════════
-- ДВИЖЕНИЕ
-- ═══════════════════════════════════════════════════════════════
local function tpTo(pos)
	if not humanoidRootPart then return end
	humanoidRootPart.CFrame = CFrame.new(pos)
end

local function tweenTo(pos)
	if not humanoidRootPart then return end
	local dist = getDistance(humanoidRootPart.Position, pos)
	if dist < 2 then
		tpTo(pos)
		return
	end
	local tween = TweenService:Create(humanoidRootPart, TweenInfo.new(math.min(dist / 25, 2), Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(pos)
	})
	tween:Play()
	tween.Completed:Wait()
end

-- ═══════════════════════════════════════════════════════════════
-- СБОР МОНЕТЫ
-- ═══════════════════════════════════════════════════════════════
local function collectCoin(coin)
	if not coin or not coin.Parent then return false end
	if not humanoidRootPart then return false end
	if not isRealCoin(coin) then return false end
	
	local coinPos = coin.Position
	local murderer = getMurderer()
	
	if murderer and isAliveCheck(murderer) then
		local mChar = murderer.Character
		local mHrp = mChar and mChar:FindFirstChild("HumanoidRootPart")
		if mHrp and getDistance(coinPos, mHrp.Position) < CONFIG.SAFE_DIST_KILLER then
			return false
		end
	end
	
	local dist = getDistance(humanoidRootPart.Position, coinPos)
	if dist > CONFIG.COIN_TELEPORT_DIST then
		tweenTo(coinPos)
	else
		tpTo(coinPos)
	end
	
	task.wait(0.05)
	
	local success = false
	
	pcall(function()
		firetouchinterest(humanoidRootPart, coin, 0)
		task.wait(0.03)
		firetouchinterest(humanoidRootPart, coin, 1)
		success = true
	end)
	
	pcall(function()
		local prompt = coin:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			fireproximityprompt(prompt, 0)
			success = true
		end
	end)
	
	pcall(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes then
			local collect = remotes:FindFirstChild("CoinCollected") or remotes:FindFirstChild("CollectCoin") or remotes:FindFirstChild("PickupCoin")
			if collect then
				collect:FireServer(coin)
				success = true
			end
		end
	end)
	
	pcall(function()
		local rp = ReplicatedStorage:FindFirstChild("RF") or ReplicatedStorage:FindFirstChild("RE")
		if rp then
			local pickup = rp:FindFirstChild("Pickup") or rp:FindFirstChild("Collect")
			if pickup then
				pickup:InvokeServer(coin)
				success = true
			end
		end
	end)
	
	task.wait(CONFIG.COOLDOWN)
	return success
end

-- ═══════════════════════════════════════════════════════════════
-- АНТИ-AFK
-- ═══════════════════════════════════════════════════════════════
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
	if antiAfkConnection then
		antiAfkConnection:Disconnect()
		antiAfkConnection = nil
	end
end

-- ═══════════════════════════════════════════════════════════════
-- SPEED BOOST
-- ═══════════════════════════════════════════════════════════════
local function applySpeed()
	if humanoid then
		humanoid.WalkSpeed = CONFIG.SPEED
		humanoid.JumpPower = CONFIG.JUMP
	end
end

-- ═══════════════════════════════════════════════════════════════
-- ОБНОВЛЕНИЕ СТАТУСА GUI
-- ═══════════════════════════════════════════════════════════════
local function updateStatus()
	local earned = collectedCoins
	if earned >= CONFIG.MAX_COINS then
		statusLabel.Text = tostring(earned) .. "/" .. tostring(CONFIG.MAX_COINS) .. " ✓"
		statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
	elseif not isAliveFlag then
		statusLabel.Text = tostring(earned) .. "/" .. tostring(CONFIG.MAX_COINS) .. " 💀"
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
	else
		statusLabel.Text = tostring(earned) .. "/" .. tostring(CONFIG.MAX_COINS)
		statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНЫЙ ЦИКЛ (ПАУЗА ПРИ СМЕРТИ, ПРОДОЛЖЕНИЕ ПОСЛЕ РЕСПАВНА)
-- ═══════════════════════════════════════════════════════════════
local function farmLoop()
	createESP()
	local processed = {}
	
	-- Запоминаем стартовое значение
	startServerCoins = getServerCoinData()
	collectedCoins = 0
	print("[MM2AF] Стартовый счёт сервера: " .. startServerCoins)
	
	while isRunning do
		-- ПРОВЕРКА ЖИВ ЛИ
		isAliveFlag = isAliveCheck(player)
		
		-- ПРОВЕРКА ЛИМИТА
		local currentServerCoins = getServerCoinData()
		collectedCoins = currentServerCoins - startServerCoins
		updateStatus()
		
		if collectedCoins >= CONFIG.MAX_COINS then
			print("[MM2AF] Лимит достигнут: " .. collectedCoins)
			stopFarm()
			return
		end
		
		-- ЕСЛИ МЁРТВ — ЖДЁМ РЕСПАВНА, НЕ ОТКЛЮЧАЕМСЯ
		if not isAliveFlag then
			print("[MM2AF] Мёртв — жду респавна...")
			if noclipConnection then disableNoclip() end
			
			-- Ждём пока не воскреснем
			while isRunning and not isAliveCheck(player) do
				task.wait(0.5)
				isAliveFlag = isAliveCheck(player)
				updateStatus()
			end
			
			if not isRunning then return end
			
			-- Обновляем референсы после респавна
			local newChar = player.Character
			if newChar then
				updateCharacterRefs(newChar)
				print("[MM2AF] Респавн — продолжаю фарм")
				if CONFIG.NOCLIP then
					enableNoclip()
				end
				applySpeed()
			end
		end
		
		-- ПРОВЕРКА РЕФЕРЕНСОВ
		if not humanoidRootPart then
			task.wait(0.5)
			continue
		end
		
		-- ПОИСК МОНЕТ
		local allCoins = findCoins()
		local murderer = getMurderer()
		
		local nearbyCoins = {}
		for _, coin in ipairs(allCoins) do
			local dist = getDistance(humanoidRootPart.Position, coin.Position)
			if dist <= CONFIG.NEAR_RADIUS then
				table.insert(nearbyCoins, coin)
			end
			if #nearbyCoins >= 15 then break end
		end
		
		if #nearbyCoins == 0 then
			task.wait(0.5)
			continue
		end
		
		-- СБОР
		for _, coin in ipairs(nearbyCoins) do
			if not isRunning then break end
			
			-- Проверка жив ли (мог умереть во время сбора)
			if not isAliveCheck(player) then
				isAliveFlag = false
				break -- выходим из цикла for, while продолжится и дождётся респавна
			end
			
			-- Проверка лимита
			collectedCoins = getServerCoinData() - startServerCoins
			updateStatus()
			if collectedCoins >= CONFIG.MAX_COINS then
				print("[MM2AF] Лимит достигнут во время сбора")
				stopFarm()
				return
			end
			
			-- Пропуск уже собранных
			local coinId = tostring(coin)
			if processed[coinId] then continue end
			
			-- Проверка безопасности
			if murderer and isAliveCheck(murderer) then
				local mChar = murderer.Character
				local mHrp = mChar and mChar:FindFirstChild("HumanoidRootPart")
				if mHrp and getDistance(coin.Position, mHrp.Position) < CONFIG.SAFE_DIST_KILLER then
					processed[coinId] = true
					continue
				end
			end
			
			-- ESP
			if CONFIG.ESP_ENABLED then
				addESP(coin, "💰")
			end
			
			-- Сбор
			collectCoin(coin)
			processed[coinId] = true
			applySpeed()
		end
		
		-- Чистка processed от удалённых монет
		for id, _ in pairs(processed) do
			local stillExists = false
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if tostring(obj) == id then
					stillExists = true
					break
				end
			end
			if not stillExists then
				processed[id] = nil
			end
		end
		
		task.wait(0.1)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- УПРАВЛЕНИЕ
-- ═══════════════════════════════════════════════════════════════
function startFarm()
	if isRunning then return end
	isRunning = true
	
	startServerCoins = getServerCoinData()
	collectedCoins = 0
	isAliveFlag = isAliveCheck(player)
	
	toggleButton.Text = "⏸"
	statusLabel.Text = "0/" .. tostring(CONFIG.MAX_COINS)
	statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
	stroke.Color = Color3.fromRGB(50, 255, 50)
	
	if CONFIG.NOCLIP then
		enableNoclip()
	end
	
	startAntiAfk()
	applySpeed()
	
	task.spawn(function()
		local ok, err = pcall(farmLoop)
		if not ok then
			warn("[MM2AF] Ошибка в farmLoop: " .. tostring(err))
			stopFarm()
		end
	end)
end

function stopFarm()
	isRunning = false
	isAliveFlag = true
	stopAntiAfk()
	disableNoclip()
	
	toggleButton.Text = "▶"
	statusLabel.Text = "OFF"
	statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	stroke.Color = Color3.fromRGB(255, 50, 50)
	
	if espFolder then
		espFolder:Destroy()
		espFolder = nil
	end
end

-- ═══════════════════════════════════════════════════════════════
-- КЛИК ПО КНОПКЕ
-- ═══════════════════════════════════════════════════════════════
toggleButton.MouseButton1Click:Connect(function()
	if isRunning then
		stopFarm()
	else
		startFarm()
	end
end)

-- Долгое нажатие = закрыть
local pressStart = 0
toggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		pressStart = tick()
	end
end)

toggleButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if tick() - pressStart >= 1.5 then
			stopFarm()
			screenGui:Destroy()
			print("[MM2AF] GUI закрыт")
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- ОБНОВЛЕНИЕ ПРИ РЕСПАВНЕ
-- ═══════════════════════════════════════════════════════════════

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid", 3)
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 3)
    
    if isRunning then
        print("[MM2AF] Респавн — референсы обновлены")
        if CONFIG.NOCLIP then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        if humanoid then
            humanoid.WalkSpeed = CONFIG.SPEED
            humanoid.JumpPower = CONFIG.JUMP
        end
    end
end)

player.CharacterRemoving:Connect(function()
    if isRunning then
        print("[MM2AF] Умер — жду респавна...")
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- СТАРТ
-- ═══════════════════════════════════════════════════════════════
print("MM2 AutoFarm ServerCounter загружен.")
print("Счёт по данным сервера | Пауза при смерти | 50 макс")
