--基本是AI写的
--有问题联系我🐧2366410597


-- 方框ESP + 透视地形脚本 (优化版 + 原地连续拾取 + 丝滑渲染)
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local virtualInput = game:GetService("VirtualInputManager")   -- 用于模拟按E

-- ============ 配置 ============
local CONFIG = {
    BoxColor = Color3.fromRGB(255, 0, 0),      -- 方框颜色
    BoxThickness = 2,                           -- 方框粗细
    TextColor = Color3.fromRGB(255, 255, 255), -- 文字颜色
    TextSize = 14,                              -- 文字大小
    UpdateInterval = 0.016,                     -- 更新间隔（约60FPS）
    PickupRange = 9,                            -- 拾取触发距离（米）
    PickupInterval = 0.1,                       -- 按E间隔（秒，即每秒10次）
    Smoothing = 0.3,                            -- 平滑系数 (0-1, 越大越平滑)
}

-- ============ 创建UI ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESPGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 主按钮
local mainButton = Instance.new("TextButton")
mainButton.Size = UDim2.new(0, 160, 0, 45)
mainButton.Position = UDim2.new(0, 10, 0, 10)
mainButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
mainButton.BackgroundTransparency = 0.1
mainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mainButton.TextSize = 16
mainButton.Font = Enum.Font.SourceSansBold
mainButton.Text = "🔲 开启ESP"
mainButton.BorderSizePixel = 2
mainButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainButton

-- 状态标签
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 160, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 60)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.BackgroundTransparency = 0.6
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Text = "状态: 关闭"
statusLabel.BorderSizePixel = 0
statusLabel.Parent = screenGui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 5)
statusCorner.Parent = statusLabel

-- 快捷键提示
local hotkeyLabel = Instance.new("TextLabel")
hotkeyLabel.Size = UDim2.new(0, 160, 0, 18)
hotkeyLabel.Position = UDim2.new(0, 10, 0, 88)
hotkeyLabel.BackgroundTransparency = 1
hotkeyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
hotkeyLabel.TextSize = 11
hotkeyLabel.Font = Enum.Font.SourceSans
hotkeyLabel.Text = "快捷键: X 切换"
hotkeyLabel.TextXAlignment = Enum.TextXAlignment.Center
hotkeyLabel.Parent = screenGui

-- ============ 自动拾取提示UI ============
local pickupFrame = Instance.new("Frame")
pickupFrame.Size = UDim2.new(0, 250, 0, 50)
pickupFrame.Position = UDim2.new(0.5, -125, 0.5, -25)
pickupFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
pickupFrame.BackgroundTransparency = 0.7
pickupFrame.BorderSizePixel = 2
pickupFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
pickupFrame.Visible = false
pickupFrame.Parent = screenGui

local pickupCorner = Instance.new("UICorner")
pickupCorner.CornerRadius = UDim.new(0, 10)
pickupCorner.Parent = pickupFrame

local pickupLabel = Instance.new("TextLabel")
pickupLabel.Size = UDim2.new(1, 0, 0.6, 0)
pickupLabel.Position = UDim2.new(0, 0, 0, 0)
pickupLabel.BackgroundTransparency = 1
pickupLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
pickupLabel.TextSize = 18
pickupLabel.Font = Enum.Font.SourceSansBold
pickupLabel.Text = "🍉 等待拾取..."
pickupLabel.Parent = pickupFrame

local pickupSubLabel = Instance.new("TextLabel")
pickupSubLabel.Size = UDim2.new(1, 0, 0.4, 0)
pickupSubLabel.Position = UDim2.new(0, 0, 0.6, 0)
pickupSubLabel.BackgroundTransparency = 1
pickupSubLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
pickupSubLabel.TextSize = 13
pickupSubLabel.Font = Enum.Font.SourceSans
pickupSubLabel.Text = "距离: 9.0 米"
pickupSubLabel.Parent = pickupFrame

local pickupProgress = Instance.new("Frame")
pickupProgress.Size = UDim2.new(0, 0, 0, 3)
pickupProgress.Position = UDim2.new(0, 0, 1, -3)
pickupProgress.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
pickupProgress.BackgroundTransparency = 0
pickupProgress.BorderSizePixel = 0
pickupProgress.Parent = pickupFrame

-- ============ ESP功能 ============
local espObjects = {}
local isESPOn = false
local targetPart = nil
local watermelonRef = nil
local pickupCount = 0

-- 平滑数据
local smoothData = {
    X = 0,
    Y = 0,
    Width = 0,
    Height = 0,
    initialized = false,
}

-- ============ 辅助函数 ============
local function getWatermelon()
    if not watermelonRef or not watermelonRef.Parent then
        watermelonRef = workspace:FindFirstChild("Watermelon")
    end
    return watermelonRef
end

local function getTarget()
    local watermelon = getWatermelon()
    if watermelon then
        return watermelon:FindFirstChild("Center")
    end
    return nil
end

-- 获取角色位置（用于距离计算）
local function getPlayerPosition()
    local character = player.Character
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        return root.Position
    end
    return nil
end

-- ============ 原地拾取函数（不移动） ============
local function pressEOnce()
    -- 方法1: 模拟键盘E键
    virtualInput:SendKeyEvent(true, "E", false, game)
    task.wait(0.02)
    virtualInput:SendKeyEvent(false, "E", false, game)
end

local function performPickup()
    -- 使用多种方法提高兼容性
    pressEOnce()  -- 主要使用虚拟按键

    -- 额外尝试 ClickDetector 和 RemoteEvent（与原有脚本一致）
    local watermelon = getWatermelon()
    if watermelon then
        local clickDetector = watermelon:FindFirstChild("ClickDetector")
        if clickDetector and clickDetector:IsA("ClickDetector") then
            fireclickdetector(clickDetector)
        end
        for _, child in pairs(watermelon:GetDescendants()) do
            if child:IsA("RemoteEvent") then
                local name = child.Name:lower()
                if name:find("pickup") or name:find("collect") or name:find("click") or name:find("interact") then
                    child:FireServer()
                end
            end
        end
        local parent = watermelon.Parent
        if parent then
            for _, child in pairs(parent:GetDescendants()) do
                if child:IsA("RemoteEvent") then
                    local name = child.Name:lower()
                    if name:find("pickup") or name:find("collect") or name:find("click") or name:find("interact") then
                        child:FireServer()
                    end
                end
            end
        end
        for _, child in pairs(watermelon:GetDescendants()) do
            if child:IsA("Tool") then
                child:Activate()
            end
        end
    end
    pickupCount = pickupCount + 1
end

-- ============ 检查并自动拾取（原地连续按E） ============
local function checkAndAutoPickup()
    if not isESPOn then
        pickupFrame.Visible = false
        return
    end

    local playerPos = getPlayerPosition()
    if not playerPos then
        pickupFrame.Visible = false
        return
    end

    local watermelon = getWatermelon()
    if not watermelon then
        pickupFrame.Visible = false
        return
    end

    local center = watermelon:FindFirstChild("Center")
    if not center then
        pickupFrame.Visible = false
        return
    end

    local distance = (playerPos - center.Position).Magnitude

    -- 更新UI
    pickupFrame.Visible = true
    local progress = math.clamp(1 - (distance / CONFIG.PickupRange), 0, 1)
    pickupProgress.Size = UDim2.new(progress, 0, 0, 3)
    pickupSubLabel.Text = string.format("📏 %.1f 米 | 按E次数: %d", distance, pickupCount)

    if distance <= CONFIG.PickupRange then
        pickupLabel.Text = "🍉 自动拾取中..."
        pickupLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
        pickupFrame.BorderColor3 = Color3.fromRGB(76, 175, 80)

        -- 执行拾取
        performPickup()

        if distance < 2 then
            pickupLabel.Text = "✅ 拾取成功！"
            pickupLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            pickupFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
            pickupProgress.Size = UDim2.new(1, 0, 0, 3)
        end
    else
        pickupLabel.Text = "🍉 靠近西瓜 (9米内自动拾取)"
        pickupLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        pickupFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
    end
end

-- ============ 丝滑的屏幕位置计算 ============
local function getScreenPosition(part)
    if not part or not part.Parent then return nil end

    local size = part.Size
    local position = part.Position
    local halfX, halfY, halfZ = size.X/2, size.Y/2, size.Z/2
    local posX, posY, posZ = position.X, position.Y, position.Z

    local corners = {
        Vector3.new(posX - halfX, posY - halfY, posZ - halfZ),
        Vector3.new(posX + halfX, posY - halfY, posZ - halfZ),
        Vector3.new(posX - halfX, posY + halfY, posZ - halfZ),
        Vector3.new(posX + halfX, posY + halfY, posZ - halfZ),
        Vector3.new(posX - halfX, posY - halfY, posZ + halfZ),
        Vector3.new(posX + halfX, posY - halfY, posZ + halfZ),
        Vector3.new(posX - halfX, posY + halfY, posZ + halfZ),
        Vector3.new(posX + halfX, posY + halfY, posZ + halfZ),
    }

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local hasOnScreen = false

    local cam = camera
    local viewportX, viewportY = camera.ViewportSize.X, camera.ViewportSize.Y

    for i = 1, 8 do
        local screenPos, onScreen = cam:WorldToViewportPoint(corners[i])
        if onScreen then
            hasOnScreen = true
            local x, y = screenPos.X, screenPos.Y
            x = math.clamp(x, -50, viewportX + 50)
            y = math.clamp(y, -50, viewportY + 50)
            if x < minX then minX = x end
            if x > maxX then maxX = x end
            if y < minY then minY = y end
            if y > maxY then maxY = y end
        end
    end

    if not hasOnScreen then return nil end

    local padding = 5
    return {
        X = minX - padding,
        Y = minY - padding,
        Width = maxX - minX + padding * 2,
        Height = maxY - minY + padding * 2,
    }
end

local function applySmoothing(current, target, smoothFactor)
    if not smoothData.initialized then
        smoothData.initialized = true
        return target
    end
    local factor = math.clamp(smoothFactor or CONFIG.Smoothing, 0, 1)
    return current + (target - current) * factor
end

-- ============ 创建丝滑方框 ============
local function createBox(screenPos)
    if not screenPos then return nil end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, screenPos.Width, 0, screenPos.Height)
    frame.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    frame.Visible = true

    local thickness = CONFIG.BoxThickness
    local color = CONFIG.BoxColor

    local borders = {}

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, thickness)
    top.BackgroundColor3 = color
    top.BackgroundTransparency = 0
    top.BorderSizePixel = 0
    top.Parent = frame
    borders.top = top

    local bottom = Instance.new("Frame")
    bottom.Size = UDim2.new(1, 0, 0, thickness)
    bottom.Position = UDim2.new(0, 0, 1, -thickness)
    bottom.BackgroundColor3 = color
    bottom.BackgroundTransparency = 0
    bottom.BorderSizePixel = 0
    bottom.Parent = frame
    borders.bottom = bottom

    local left = Instance.new("Frame")
    left.Size = UDim2.new(0, thickness, 1, 0)
    left.BackgroundColor3 = color
    left.BackgroundTransparency = 0
    left.BorderSizePixel = 0
    left.Parent = frame
    borders.left = left

    local right = Instance.new("Frame")
    right.Size = UDim2.new(0, thickness, 1, 0)
    right.Position = UDim2.new(1, -thickness, 0, 0)
    right.BackgroundColor3 = color
    right.BackgroundTransparency = 0
    right.BorderSizePixel = 0
    right.Parent = frame
    borders.right = right

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 1, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = CONFIG.TextColor
    nameLabel.TextSize = CONFIG.TextSize
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = "🍉 西瓜"
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = frame

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 16)
    distLabel.Position = UDim2.new(0, 0, 0, -18)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextSize = 12
    distLabel.Font = Enum.Font.SourceSans
    distLabel.Text = ""
    distLabel.TextXAlignment = Enum.TextXAlignment.Center
    distLabel.Parent = frame

    local pickupHint = Instance.new("TextLabel")
    pickupHint.Size = UDim2.new(1, 0, 0, 16)
    pickupHint.Position = UDim2.new(0, 0, 1, 22)
    pickupHint.BackgroundTransparency = 1
    pickupHint.TextColor3 = Color3.fromRGB(255, 215, 0)
    pickupHint.TextSize = 11
    pickupHint.Font = Enum.Font.SourceSans
    pickupHint.Text = "🔄 9米内自动连续按E"
    pickupHint.TextXAlignment = Enum.TextXAlignment.Center
    pickupHint.Visible = false
    pickupHint.Parent = frame

    return {
        frame = frame,
        borders = borders,
        distLabel = distLabel,
        nameLabel = nameLabel,
        pickupHint = pickupHint,
    }
end

-- ============ 更新ESP（丝滑版） ============
local function updateESP()
    if not isESPOn then return end

    targetPart = getTarget()
    if not targetPart or not targetPart.Parent then
        for _, obj in pairs(espObjects) do
            if obj.frame and obj.frame.Parent then
                obj.frame:Destroy()
            end
        end
        espObjects = {}
        smoothData.initialized = false
        return
    end

    local screenPos = getScreenPosition(targetPart)

    if screenPos then
        local smoothX = applySmoothing(smoothData.X, screenPos.X, CONFIG.Smoothing)
        local smoothY = applySmoothing(smoothData.Y, screenPos.Y, CONFIG.Smoothing)
        local smoothWidth = applySmoothing(smoothData.Width, screenPos.Width, CONFIG.Smoothing)
        local smoothHeight = applySmoothing(smoothData.Height, screenPos.Height, CONFIG.Smoothing)

        smoothData.X = smoothX
        smoothData.Y = smoothY
        smoothData.Width = smoothWidth
        smoothData.Height = smoothHeight

        if espObjects[1] and espObjects[1].frame then
            local frame = espObjects[1].frame
            frame.Size = UDim2.new(0, smoothWidth, 0, smoothHeight)
            frame.Position = UDim2.new(0, smoothX, 0, smoothY)
            frame.Visible = true

            if espObjects[1].distLabel then
                local distance = (camera.CFrame.Position - targetPart.Position).Magnitude
                espObjects[1].distLabel.Text = string.format("📏 %.1f 米", distance)

                if espObjects[1].pickupHint then
                    if distance <= CONFIG.PickupRange then
                        espObjects[1].pickupHint.Visible = true
                        espObjects[1].pickupHint.Text = "🔄 自动拾取中..."
                        espObjects[1].pickupHint.TextColor3 = Color3.fromRGB(76, 175, 80)
                    else
                        espObjects[1].pickupHint.Visible = false
                    end
                end
            end
        else
            local newESP = createBox(screenPos)
            if newESP then
                for _, obj in pairs(espObjects) do
                    if obj.frame and obj.frame.Parent then
                        obj.frame:Destroy()
                    end
                end
                espObjects = {newESP}
                smoothData.X = screenPos.X
                smoothData.Y = screenPos.Y
                smoothData.Width = screenPos.Width
                smoothData.Height = screenPos.Height
                smoothData.initialized = true
            end
        end
    else
        for _, obj in pairs(espObjects) do
            if obj.frame and obj.frame.Parent then
                obj.frame.Visible = false
            end
        end
    end
end

-- ============ 透视地形功能 ============
local terrainRef = nil
local function getTerrain()
    if not terrainRef or not terrainRef.Parent then
        terrainRef = workspace:FindFirstChild("Terrain") or workspace:FindFirstChildOfClass("Terrain")
    end
    return terrainRef
end

local function toggleTerrainTransparency(enable)
    local terrain = getTerrain()
    if terrain then
        if enable then
            terrain.WaterTransparency = 0.3
            terrain.WaterReflectance = 0
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
        else
            terrain.WaterTransparency = 0.7
            terrain.WaterReflectance = 0.5
        end
    end
end

-- ============ 黑色物体优化 ============
local function fixDarkParts()
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("Part") or obj:IsA("MeshPart")) then
            local color = obj.Color
            if color.r < 0.1 and color.g < 0.1 and color.b < 0.1 then
                obj.Color = Color3.fromRGB(255, 255, 255)
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            end
        end
    end
end

-- ============ 切换ESP ============
local function toggleESP()
    if isESPOn then
        isESPOn = false
        for _, obj in pairs(espObjects) do
            if obj.frame and obj.frame.Parent then
                obj.frame:Destroy()
            end
        end
        espObjects = {}
        smoothData.initialized = false
        toggleTerrainTransparency(false)
        pickupFrame.Visible = false
        mainButton.Text = "🔲 开启ESP"
        mainButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        statusLabel.Text = "状态: 关闭"
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        isESPOn = true
        toggleTerrainTransparency(true)
        fixDarkParts()
        pickupCount = 0
        mainButton.Text = "🔲 关闭ESP"
        mainButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
        statusLabel.Text = "🟢 ESP开启 | 9米自动连续拾取"
        statusLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
        updateESP()
    end
end

-- ============ 渲染循环（高频更新） ============
local lastUpdate = 0
local lastPickupCheck = 0
local updateInterval = CONFIG.UpdateInterval

runService.Heartbeat:Connect(function(deltaTime)
    if isESPOn then
        lastUpdate = lastUpdate + deltaTime
        if lastUpdate >= updateInterval then
            lastUpdate = 0
            updateESP()
        end
    end

    lastPickupCheck = lastPickupCheck + deltaTime
    if lastPickupCheck >= CONFIG.PickupInterval then
        lastPickupCheck = 0
        checkAndAutoPickup()   -- 原地连续拾取（不移动）
    end
end)

-- ============ 按钮事件 ============
mainButton.MouseButton1Click:Connect(toggleESP)

userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.X then
        toggleESP()
    end
end)

-- ============ 初始化 ============
print("🚀 方框ESP + 透视地形脚本已加载（原地连续拾取版）")
print("📖 按 X 键切换ESP")
print("🍉 距离西瓜9米内自动连续按E（每秒10次）")
print("✨ 启用丝滑平滑渲染，方框更流畅")
