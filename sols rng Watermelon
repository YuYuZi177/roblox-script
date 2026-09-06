-- 方框ESP + 透视地形脚本 (优化版)
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

-- ============ 配置 ============
local CONFIG = {
    BoxColor = Color3.fromRGB(255, 0, 0),      -- 方框颜色
    BoxThickness = 2,                           -- 方框粗细
    TextColor = Color3.fromRGB(255, 255, 255), -- 文字颜色
    TextSize = 14,                              -- 文字大小
    UpdateInterval = 0.05,                      -- 更新间隔（秒）
}

-- ============ 创建UI ============

-- 创建ScreenGui
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

-- ============ ESP功能 ============

local espObjects = {}
local isESPOn = false
local targetPart = nil

-- 缓存目标引用，避免重复查找
local function getTarget()
    -- 直接用 workspace:FindFirstChild 比递归查找快
    local watermelon = workspace:FindFirstChild("Watermelon")
    if watermelon then
        return watermelon:FindFirstChild("Center")
    end
    return nil
end

-- 预分配表，减少GC压力
local corners = {}
local screenPoints = {}

-- 获取目标在屏幕上的位置和大小
local function getScreenPosition(part)
    if not part or not part.Parent then return nil end
    
    local size = part.Size
    local position = part.Position
    local halfX, halfY, halfZ = size.X/2, size.Y/2, size.Z/2
    local posX, posY, posZ = position.X, position.Y, position.Z
    
    -- 直接计算8个角，避免创建临时Vector3（优化）
    local cornerData = {
        {posX - halfX, posY - halfY, posZ - halfZ},
        {posX + halfX, posY - halfY, posZ - halfZ},
        {posX - halfX, posY + halfY, posZ - halfZ},
        {posX + halfX, posY + halfY, posZ - halfZ},
        {posX - halfX, posY - halfY, posZ + halfZ},
        {posX + halfX, posY - halfY, posZ + halfZ},
        {posX - halfX, posY + halfY, posZ + halfZ},
        {posX + halfX, posY + halfY, posZ + halfZ},
    }
    
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local hasOnScreen = false
    
    for i = 1, 8 do
        local data = cornerData[i]
        -- 直接创建Vector3并转换
        local screenPos, onScreen = camera:WorldToViewportPoint(
            Vector3.new(data[1], data[2], data[3])
        )
        if onScreen then
            hasOnScreen = true
            local x, y = screenPos.X, screenPos.Y
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

-- 创建方框（使用更少的对象）
local function createBox(screenPos)
    if not screenPos then return nil end
    
    -- 方框Frame（容器）
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, screenPos.Width, 0, screenPos.Height)
    frame.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    frame.Visible = true
    
    -- 使用一个Frame + 边框厚度来实现方框（减少对象数量）
    local thickness = CONFIG.BoxThickness
    local color = CONFIG.BoxColor
    
    -- 上边
    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, thickness)
    top.BackgroundColor3 = color
    top.BackgroundTransparency = 0
    top.BorderSizePixel = 0
    top.Parent = frame
    
    -- 下边
    local bottom = Instance.new("Frame")
    bottom.Size = UDim2.new(1, 0, 0, thickness)
    bottom.Position = UDim2.new(0, 0, 1, -thickness)
    bottom.BackgroundColor3 = color
    bottom.BackgroundTransparency = 0
    bottom.BorderSizePixel = 0
    bottom.Parent = frame
    
    -- 左边
    local left = Instance.new("Frame")
    left.Size = UDim2.new(0, thickness, 1, 0)
    left.BackgroundColor3 = color
    left.BackgroundTransparency = 0
    left.BorderSizePixel = 0
    left.Parent = frame
    
    -- 右边
    local right = Instance.new("Frame")
    right.Size = UDim2.new(0, thickness, 1, 0)
    right.Position = UDim2.new(1, -thickness, 0, 0)
    right.BackgroundColor3 = color
    right.BackgroundTransparency = 0
    right.BorderSizePixel = 0
    right.Parent = frame
    
    -- 目标名称标签
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 1, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = CONFIG.TextColor
    nameLabel.TextSize = CONFIG.TextSize
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = "瓜在这"
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = frame
    
    -- 距离标签
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
    
    return {
        frame = frame,
        distLabel = distLabel,
        nameLabel = nameLabel,
    }
end

-- 更新ESP（优化版）
local function updateESP()
    if not isESPOn then return end
    
    targetPart = getTarget()
    if not targetPart or not targetPart.Parent then
        -- 目标不存在，清除所有ESP
        for _, obj in pairs(espObjects) do
            if obj.frame and obj.frame.Parent then
                obj.frame:Destroy()
            end
        end
        espObjects = {}
        return
    end
    
    local screenPos = getScreenPosition(targetPart)
    
    if screenPos then
        if espObjects[1] and espObjects[1].frame then
            local frame = espObjects[1].frame
            frame.Size = UDim2.new(0, screenPos.Width, 0, screenPos.Height)
            frame.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
            frame.Visible = true
            
            if espObjects[1].distLabel then
                local distance = (camera.CFrame.Position - targetPart.Position).Magnitude
                espObjects[1].distLabel.Text = string.format("📏 %.1f 米", distance)
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
            end
        end
    else
        -- 目标在屏幕外，隐藏ESP
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

-- ============ 黑色物体优化（一次性处理，不每帧运行） ============

local function fixDarkParts()
    -- 只运行一次，而不是每帧
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
        -- 关闭ESP
        isESPOn = false
        for _, obj in pairs(espObjects) do
            if obj.frame and obj.frame.Parent then
                obj.frame:Destroy()
            end
        end
        espObjects = {}
        toggleTerrainTransparency(false)
        mainButton.Text = "🔲 开启ESP"
        mainButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        statusLabel.Text = "状态: 关闭"
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        -- 开启ESP
        isESPOn = true
        toggleTerrainTransparency(true)
        fixDarkParts() -- 只处理一次
        mainButton.Text = "🔲 关闭ESP"
        mainButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
        statusLabel.Text = "🟢 ESP开启"
        statusLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
        updateESP()
    end
end

-- ============ 渲染循环（使用节流优化） ============

local lastUpdate = 0
local updateInterval = CONFIG.UpdateInterval

runService.RenderStepped:Connect(function(deltaTime)
    if isESPOn then
        lastUpdate = lastUpdate + deltaTime
        if lastUpdate >= updateInterval then
            lastUpdate = 0
            updateESP()
        end
    end
end)

-- ============ 按钮事件 ============

mainButton.MouseButton1Click:Connect(toggleESP)

-- 键盘快捷键 X
userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.X then
        toggleESP()
    end
end)

-- ============ 初始化 ============

print("🚀 方框ESP + 透视地形脚本已加载（优化版）")
print("📖 按 X 键切换")
