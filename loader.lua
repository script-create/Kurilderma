--// MM2 AutoFarm - GUI Activator (Part 1)
--// Вставляй в один Script или LocalScript

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Создаём ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2AutoFarmGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Основной фрейм кнопки
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainButtonFrame"
mainFrame.Size = UDim2.new(0, 120, 0, 120)
mainFrame.Position = UDim2.new(0.85, 0, 0.75, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.1
mainFrame.Parent = screenGui

-- Скругление углов
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = mainFrame

-- Обводка
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 50, 50)
stroke.Thickness = 3
stroke.Parent = mainFrame

-- Тень
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = -1
shadow.Parent = mainFrame

-- Кнопка включения
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, 0, 1, 0)
toggleButton.BackgroundTransparency = 1
toggleButton.Text = "▶"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 48
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = mainFrame

-- Статус лейбл
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.new(0, 0, 1, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "OFF"
statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
statusLabel.TextSize = 18
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = mainFrame

-- Переменные состояния
local isActive = false
local autoFarmConnection = nil

-- Функция для анимации кнопки
local function animateButton(active)
    local targetColor = active and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    local targetText = active and "⏸" or "▶"
    local targetStatus = active and "ON" or "OFF"
    local targetStatusColor = active and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    
    TweenService:Create(stroke, TweenInfo.new(0.3), {Color = targetColor}):Play()
    toggleButton.Text = targetText
    statusLabel.Text = targetStatus
    statusLabel.TextColor3 = targetStatusColor
end

-- Перетаскивание для планшета
local dragging = false
local dragStart = nil
local startPos = nil

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Переключение автофарма
toggleButton.MouseButton1Click:Connect(function()
    isActive = not isActive
    animateButton(isActive)
    
    if isActive then
        -- Загружаем основной скрипт
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://pastebin.com/raw/ТВОЙ_ЛИНК_НА_ЧАСТЬ_2", true))()
        end)
        
        if not success then
            -- Fallback: загружаем из _G или Shared
            if _G.MM2AutoFarmMain then
                _G.MM2AutoFarmMain()
            else
                warn("Не удалось загрузить основной скрипт: " .. tostring(err))
                isActive = false
                animateButton(false)
            end
        end
    else
        -- Останавливаем автофарм
        if _G.StopMM2AutoFarm then
            _G.StopMM2AutoFarm()
        end
    end
end)

-- Кнопка закрытия (долгое нажатие)
local longPressConnection = nil
local pressStart = 0

toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        pressStart = tick()
        longPressConnection = RunService.Heartbeat:Connect(function()
            if tick() - pressStart >= 1.5 then
                if longPressConnection then
                    longPressConnection:Disconnect()
                end
                screenGui:Destroy()
            end
        end)
    end
end)

toggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        if longPressConnection then
            longPressConnection:Disconnect()
        end
    end
end)

-- Анимация пульсации
spawn(function()
    while mainFrame and mainFrame.Parent do
        if isActive then
            TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
                {Size = UDim2.new(0, 125, 0, 125)}):Play()
            wait(0.5)
            TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
                {Size = UDim2.new(0, 120, 0, 120)}):Play()
            wait(0.5)
        else
            wait(0.5)
        end
    end
end)

print("MM2 AutoFarm GUI загружен. Нажми ▶ для старта. Удерживай 1.5 сек для закрытия.")
--// MM2 AutoFarm - Main Engine (Part 2)
--// Полная логика фарма монет и XP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Конфигурация
local CONFIG = {
    COIN_COLLECT_RADIUS = 15,
    COIN_TELEPORT_DISTANCE = 8,
    SAFE_DISTANCE_FROM_KILLER = 25,
    LOOP_INTERVAL = 0.05,
    MAX_COINS_PER_ROUND = 40,
    COIN_TYPES = {"Coin", "Diamond", "XP", "Gem", "Loot"},
    AVOID_KILLER = true,
    COLLECT_ALL_MAP = true,
    USE_PATHFINDING = true,
    SPEED_BOOST = true,
    SPEED_VALUE = 32,
    JUMP_POWER = 50,
    ANTI_AFK = true,
    AUTO_SHOOT_MURDERER = false,
    SHOOT_DISTANCE = 30,
}

-- Глобальные переменные управления
_G.MM2AutoFarmActive = true
_G.StopMM2AutoFarm = function()
    _G.MM2AutoFarmActive = false
    if _G.AntiAfkConnection then
        _G.AntiAfkConnection:Disconnect()
    end
    if _G.MainLoopConnection then
        _G.MainLoopConnection:Disconnect()
    end
    if _G.CoinESPFolder then
        _G.CoinESPFolder:Destroy()
    end
    print("MM2 AutoFarm остановлен.")
end

-- Утилиты
local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function isAlive(target)
    if not target then return false end
    local char = target.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function getMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Backpack then
            if p.Backpack:FindFirstChild("Knife") or (p.Character and p.Character:FindFirstChild("Knife")) then
                return p
            end
        end
    end
    return nil
end

local function getSheriff()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Backpack then
            if p.Backpack:FindFirstChild("Gun") or (p.Character and p.Character:FindFirstChild("Gun")) then
                return p
            end
        end
    end
    return nil
end

local function getRole()
    local backpack = player.Backpack
    local char = player.Character
    
    if (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
        return "Murderer"
    elseif (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
        return "Sheriff"
    else
        return "Innocent"
    end
end

-- Система ESP для монет
local function createCoinESP()
    if _G.CoinESPFolder then
        _G.CoinESPFolder:Destroy()
    end
    
    local folder = Instance.new("Folder")
    folder.Name = "CoinESP"
    folder.Parent = Workspace.CurrentCamera
    
    _G.CoinESPFolder = folder
    
    local function addESP(obj, color, labelText)
        if not obj or not obj.Parent then return end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "CoinESP"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Parent = folder
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.Parent = billboard
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = color
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.Parent = frame
        
        billboard.Adornee = obj
        
        return billboard
    end
    
    return addESP
end

-- Поиск всех монет на карте
local function findCoins()
    local coins = {}
    local map = Workspace:FindFirstChild("Map") or Workspace
    
    local function scanContainer(container)
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                local name = obj.Name:lower()
                for _, coinType in ipairs(CONFIG.COIN_TYPES) do
                    if name:find(coinType:lower()) then
                        table.insert(coins, obj)
                        break
                    end
                end
            end
        end
    end
    
    scanContainer(map)
    
    -- Проверяем специфичные папки MM2
    local coinSpawns = Workspace:FindFirstChild("CoinSpawns")
    if coinSpawns then
        for _, spawn in ipairs(coinSpawns:GetDescendants()) do
            if spawn:IsA("BasePart") then
                table.insert(coins, spawn)
            end
        end
    end
    
    return coins
end

-- Телепорт/перемещение к монете
local function moveToPosition(targetPos, speed)
    speed = speed or CONFIG.SPEED_VALUE
    if not humanoidRootPart then return end
    
    local currentPos = humanoidRootPart.Position
    local distance = getDistance(currentPos, targetPos)
    
    if distance < CONFIG.COIN_TELEPORT_DISTANCE then
        -- Близко — просто телепортируем
        humanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    else
        -- Далеко — используем твин или pathfinding
        if CONFIG.USE_PATHFINDING and distance > 50 then
            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
                AgentJumpDistance = 10,
                AgentMaxSlope = 45,
            })
            
            local success, err = pcall(function()
                path:ComputeAsync(currentPos, targetPos)
            end)
            
            if success and path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                for _, waypoint in ipairs(waypoints) do
                    if not _G.MM2AutoFarmActive then break end
                    humanoid:MoveTo(waypoint.Position)
                    humanoid.MoveToFinished:Wait()
                end
            else
                -- Fallback на прямое движение
                local direction = (targetPos - currentPos).Unit
                humanoidRootPart.Velocity = direction * speed * 5
                humanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
            end
        else
            -- Прямое перемещение через CFrame
            local tween = TweenService:Create(
                humanoidRootPart,
                TweenInfo.new(distance / (speed * 3), Enum.EasingStyle.Linear),
                {CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))}
            )
            tween:Play()
            tween.Completed:Wait()
        end
    end
end

-- Сбор монеты
local function collectCoin(coin)
    if not coin or not coin.Parent then return false end
    
    local coinPos = coin.Position
    local murderer = getMurderer()
    
    -- Проверяем безопасность
    if CONFIG.AVOID_KILLER and murderer and isAlive(murderer) then
        local murdererPos = murderer.Character.HumanoidRootPart.Position
        if getDistance(coinPos, murdererPos) < CONFIG.SAFE_DISTANCE_FROM_KILLER then
            return false
        end
    end
    
    -- Перемещаемся к монете
    moveToPosition(coinPos)
    wait(0.1)
    
    -- Триггерим сбор (разные методы для разных типов монет)
    pcall(function()
        -- Метод 1: FireTouchInterest
        firetouchinterest(humanoidRootPart, coin, 0)
        wait(0.05)
        firetouchinterest(humanoidRootPart, coin, 1)
    end)
    
    pcall(function()
        -- Метод 2: ProximityPrompt
        local prompt = coin:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end
    end)
    
    pcall(function()
        -- Метод 3: RemoteEvents
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local coinRemote = remotes:FindFirstChild("CoinCollected") or remotes:FindFirstChild("CollectCoin")
            if coinRemote then
                coinRemote:FireServer(coin)
            end
        end
    end)
    
    return true
end

-- Анти-AFK
local function setupAntiAfk()
    if not CONFIG.ANTI_AFK then return end
    
    _G.AntiAfkConnection = RunService.Heartbeat:Connect(function()
        if not _G.MM2AutoFarmActive then return end
        
        -- Симулируем движение мыши
        VirtualInputManager:SendMouseMoveEvent(0, 0, game)
        
        -- Случайный прыжок
        if math.random(1, 500) == 1 then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end)
    
    -- Обход стандартного AFK
    local mt = getrawmetatable and getrawmetatable(game) or nil
    if mt then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" then
                return nil
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end

-- Ускорение персонажа
local function setupSpeedBoost()
    if not CONFIG.SPEED_BOOST then return end
    
    spawn(function()
        while _G.MM2AutoFarmActive and humanoid do
            humanoid.WalkSpeed = CONFIG.SPEED_VALUE
            humanoid.JumpPower = CONFIG.JUMP_POWER
            wait(0.5)
        end
    end)
end

-- Авто-стрельба по убийце (если шериф)
local function autoShootMurderer()
    if not CONFIG.AUTO_SHOOT_MURDERER then return end
    if getRole() ~= "Sheriff" then return end
    
    local murderer = getMurderer()
    if not murderer or not isAlive(murderer) then return end
    
    local murdererHRP = murderer.Character:FindFirstChild("HumanoidRootPart")
    if not murdererHRP then return end
    
    local distance = getDistance(humanoidRootPart.Position, murdererHRP.Position)
    
    if distance <= CONFIG.SHOOT_DISTANCE then
        -- Наводимся и стреляем
        humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, murdererHRP.Position)
        
        local gun = player.Backpack:FindFirstChild("Gun") or character:FindFirstChild("Gun")
        if gun then
            humanoid:EquipTool(gun)
            wait(0.2)
            
            pcall(function()
                local shootRemote = gun:FindFirstChild("Shoot") or gun:FindFirstChild("Fire")
                if shootRemote then
                    shootRemote:FireServer(murdererHRP.Position)
                else
                    -- Альтернативный метод
                    local args = {
                        [1] = murdererHRP.Position,
                        [2] = murdererHRP
                    }
                    ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShootGun"):FireServer(unpack(args))
                end
            end)
        end
    end
end

-- Главный цикл фарма
local function mainLoop()
    local addESP = createCoinESP()
    local collectedCoins = 0
    local processedCoins = {}
    
    while _G.MM2AutoFarmActive do
        local role = getRole()
        
        -- Если мы невиновный — фармим монеты
        if role == "Innocent" or role == "Sheriff" then
            local coins = findCoins()
            local murderer = getMurderer()
            
            -- Сортируем монеты по близости
            table.sort(coins, function(a, b)
                if not a or not b then return false end
                local distA = getDistance(humanoidRootPart.Position, a.Position)
                local distB = getDistance(humanoidRootPart.Position, b.Position)
                return distA < distB
            end)
            
            for _, coin in ipairs(coins) do
                if not _G.MM2AutoFarmActive then break end
                if collectedCoins >= CONFIG.MAX_COINS_PER_ROUND then break end
                if processedCoins[coin] then continue end
                
                processedCoins[coin] = true
                
                -- Проверяем безопасность от убийцы
                if CONFIG.AVOID_KILLER and murderer and isAlive(murderer) then
                    local murdererPos = murderer.Character.HumanoidRootPart.Position
                    local coinPos = coin.Position
                    
                    if getDistance(coinPos, murdererPos) < CONFIG.SAFE_DISTANCE_FROM_KILLER then
                        continue
                    end
                end
                
                -- ESP для монеты
                addESP(coin, Color3.fromRGB(255, 215, 0), "💰")
                
                -- Собираем
                if collectCoin(coin) then
                    collectedCoins = collectedCoins + 1
                    wait(0.15)
                end
            end
            
            -- Если монет не осталось — ждём респавна
            if #coins == 0 then
                wait(2)
            end
            
        elseif role == "Murderer" then
            -- Если мы убийца — можно добавить авто-убийство
            -- Но по умолчанию просто ждём конца раунда
            wait(1)
        end
        
        -- Авто-стрельба если шериф
        if role == "Sheriff" then
            autoShootMurderer()
        end
        
        -- Очистка обработанных монет (если их больше нет)
        for coin, _ in pairs(processedCoins) do
            if not coin or not coin.Parent then
                processedCoins[coin] = nil
            end
        end
        
        wait(CONFIG.LOOP_INTERVAL)
    end
end

-- Инициализация
local function initialize()
    -- Ждём загрузку персонажа
    if not character or not humanoidRootPart then
        player.CharacterAdded:Wait()
        character = player.Character
        humanoid = character:WaitForChild("Humanoid")
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    end
    
    -- Настройки
    setupAntiAfk()
    setupSpeedBoost()
    
    -- Запуск главного цикла
    _G.MainLoopConnection = RunService.Heartbeat:Connect(function()
        if _G.MM2AutoFarmActive then
            pcall(mainLoop)
        end
    end)
    
    -- Перезапуск при респавне
    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        humanoid = newChar:WaitForChild("Humanoid")
        humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
        
        if CONFIG.SPEED_BOOST then
            setupSpeedBoost()
        end
    end)
    
    print("MM2 AutoFarm Engine запущен. Роль: " .. getRole())
end

-- Запуск
initialize()
