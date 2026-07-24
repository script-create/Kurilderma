--// MM2 AutoFarm - Smooth No Lag
--// Без перерывов, плавный сбор, без лагов

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ═══════════════════════════════════════════════════════════════
-- АНТИ-КИК
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
-- GUI КНОПКА
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
-- КОНФИГ (ПЛАВНЫЙ, БЕЗ ЛАГОВ)
-- ═══════════════════════════════════════════════════════════════
local CONFIG = {
    COIN_TELEPORT_DIST = 6,
    SAFE_DIST_KILLER = 20,
    COOLDOWN = 0.08,
    SPEED = 20,
    JUMP = 50,
    ESP_ENABLED = true,
    NOCLIP = true,
    NEAR_RADIUS = 100,
}

-- ═══════════════════════════════════════════════════════════════
-- СОСТОЯНИЕ
-- ═══════════════════════════════════════════════════════════════
local isRunning = false
local espFolder = nil
local antiAfkConnection = nil
local afkTimer = 0

-- ═══════════════════════════════════════════════════════════════
-- УТИЛИТЫ
-- ═══════════════════════════════════════════════════════════════
local function getDistance(p1, p2)
    return (p1 - p2).Magnitude
end

local function isAlive(plr)
    if not plr then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
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

local function getRole()
    local bp = player:FindFirstChild("Backpack")
    local char = player.Character
    if (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
        return "Murderer"
    elseif (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    return "Innocent"
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

-- ═══════════════════════════════════════════════════════════════
-- ПРОВЕРКА МАГАЗИНА
-- ═══════════════════════════════════════════════════════════════
local function isShopItem(obj)
    if not obj or not obj.Parent then return true end
    
    local parent = obj.Parent
    while parent do
        local name = parent.Name:lower()
        if name:find("shop") or name:find("store") or name:find("bundle") or 
           name:find("weapon") or name:find("knife") or name:find("gun") or
           name:find("display") or name:find("showcase") or name:find("lobby") then
            return true
        end
        parent = parent.Parent
    end
    
    local n = obj.Name:lower()
    if n:find("knife") or n:find("gun") or n:find("weapon") or n:find("blade") or 
       n:find("sword") or n:find("axe") or n:find("hammer") then
        return true
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- ПОИСК МОНЕТ
-- ═══════════════════════════════════════════════════════════════
local function findCoins()
    local coins = {}
    local checked = {}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and not checked[obj] then
            checked[obj] = true
            
            if isShopItem(obj) then
                continue
            end
            
            local n = obj.Name:lower()
            
            if n:find("coin") or n:find("diamond") or n:find("gem") or n:find("xp") or 
               n:find("loot") or n:find("candy") or n:find("gold") or n:find("money") or
               n:find("collect") or n:find("drop") or n:find("item") or n:find("spawn") then
                table.insert(coins, obj)
            end
            
            local size = obj.Size
            if size.X < 3 and size.Y < 3 and size.Z < 3 and size.X > 0.1 then
                if n:find("part") or n:find("mesh") or obj:IsA("MeshPart") then
                    if not table.find(coins, obj) then
                        if obj:FindFirstChild("TouchInterest") or obj:FindFirstChildOfClass("ProximityPrompt") then
                            table.insert(coins, obj)
                        end
                    end
                end
            end
        end
    end
    
    local folders = {
        "CoinSpawns", "Coins", "Loot", "Drops", "Map", 
        "SpawnedCoins", "GameCoins", "Collectibles",
        "Workspace", "Items", "Pickups"
    }
    for _, folderName in ipairs(folders) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if obj:IsA("BasePart") and not checked[obj] then
                    if not isShopItem(obj) then
                        checked[obj] = true
                        table.insert(coins, obj)
                    end
                end
            end
        end
    end
    
    table.sort(coins, function(a, b)
        if not a or not b then return false end
        return getDistance(humanoidRootPart.Position, a.Position) < getDistance(humanoidRootPart.Position, b.Position)
    end)
    
    return coins
end

-- ═══════════════════════════════════════════════════════════════
-- ДВИЖЕНИЕ (ПЛАВНОЕ)
-- ═══════════════════════════════════════════════════════════════
local function tpTo(pos)
    if not humanoidRootPart then return end
    humanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)
end

local function tweenTo(pos)
    if not humanoidRootPart then return end
    local dist = getDistance(humanoidRootPart.Position, pos)
    if dist < 5 then
        tpTo(pos)
        return
    end
    local tween = TweenService:Create(humanoidRootPart, TweenInfo.new(math.min(dist / 25, 2), Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)
    })
    tween:Play()
    tween.Completed:Wait()
end

-- ═══════════════════════════════════════════════════════════════
-- СБОР МОНЕТЫ
-- ═══════════════════════════════════════════════════════════════
local function collectCoin(coin)
    if not coin or not coin.Parent then return false end
    
    local coinPos = coin.Position
    local murderer = getMurderer()
    
    if murderer and isAlive(murderer) then
        local mPos = murderer.Character.HumanoidRootPart.Position
        if getDistance(coinPos, mPos) < CONFIG.SAFE_DIST_KILLER then
            return false
        end
    end
    
    local dist = getDistance(humanoidRootPart.Position, coinPos)
    if dist > CONFIG.COIN_TELEPORT_DIST then
        tweenTo(coinPos)
    else
        tpTo(coinPos)
    end
    
    wait(0.05)
    
    local success = false
    
    pcall(function()
        firetouchinterest(humanoidRootPart, coin, 0)
        wait(0.03)
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
    
    wait(CONFIG.COOLDOWN)
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
-- ГЛАВНЫЙ ЦИКЛ (БЕЗ ПЕРЕРЫВОВ, БЕЗ ЛАГОВ)
-- ═══════════════════════════════════════════════════════════════
local function farmLoop()
    createESP()
    local processed = {}
    
    while isRunning do
        if not isRunning then break end
        
        statusLabel.Text = "ON"
        statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
        
        local role = getRole()
        
        if role == "Murderer" then
            wait(1)
            continue
        end
        
        local allCoins = findCoins()
        local murderer = getMurderer()
        
        local coins = {}
        for _, coin in ipairs(allCoins) do
            local dist = getDistance(humanoidRootPart.Position, coin.Position)
            if dist <= CONFIG.NEAR_RADIUS then
                table.insert(coins, coin)
            end
            if #coins >= 15 then
                break
            end
        end
        
        if #coins == 0 then
            wait(1)
            continue
        end
        
        for _, coin in ipairs(coins) do
            if not isRunning then break end
            if processed[coin] then continue end
            
            if murderer and isAlive(murderer) then
                local mPos = murderer.Character.HumanoidRootPart.Position
                if getDistance(coin.Position, mPos) < CONFIG.SAFE_DIST_KILLER then
                    processed[coin] = true
                    continue
                end
            end
            
            if CONFIG.ESP_ENABLED then
                addESP(coin, "💰")
            end
            
            collectCoin(coin)
            processed[coin] = true
            applySpeed()
        end
        
        for coin, _ in pairs(processed) do
            if not coin or not coin.Parent then
                processed[coin] = nil
            end
        end
        
        wait(0.1)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- УПРАВЛЕНИЕ
-- ═══════════════════════════════════════════════════════════════
local function startFarm()
    if isRunning then return end
    isRunning = true
    
    toggleButton.Text = "⏸"
    statusLabel.Text = "ON"
    statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
    stroke.Color = Color3.fromRGB(50, 255, 50)
    
    if CONFIG.NOCLIP then
        enableNoclip()
    end
    
    startAntiAfk()
    applySpeed()
    
    spawn(function()
        pcall(farmLoop)
    end)
end

local function stopFarm()
    isRunning = false
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
-- ПЕРЕТАСКИВАНИЕ КНОПКИ
-- ═══════════════════════════════════════════════════════════════
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
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

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
    if input.UserInputType == Enum.UserInputType.Touch then
        pressStart = tick()
    end
end)

toggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        if tick() - pressStart >= 1.5 then
            stopFarm()
            screenGui:Destroy()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ОБНОВЛЕНИЕ ПРИ РЕСПАВНЕ
-- ═══════════════════════════════════════════════════════════════
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    if isRunning and CONFIG.NOCLIP then
        enableNoclip()
    end
    if isRunning then
        applySpeed()
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- СТАРТ
-- ═══════════════════════════════════════════════════════════════
print("MM2 AutoFarm Smooth загружен. Без лагов, без перерывов.")
