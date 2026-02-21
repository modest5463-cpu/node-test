local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Rayfield 불러오기 (인터넷 필요)
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- 설정 초기값
local TEXT_SIZE = 12
local BOX_COLOR = Color3.fromRGB(255, 0, 0)
local FOV_COLOR = Color3.fromRGB(255, 0, 0)
local FOV_THICKNESS = 2
local FOV_SIZE = 90
local aiming = false

-- Rayfield GUI 생성
local Window = Rayfield:CreateWindow({
    Name = "에임봇 + FOV 설정",
    LoadingTitle = "로딩 중...",
    ConfigurationSaving = { Enabled = false }
})

local AimSection = Window:CreateSection("에임봇 제어")

-- 에임봇 온오프 토글
AimSection:CreateToggle({
    Name = "에임봇 켜기/끄기",
    CurrentValue = false,
    Callback = function(value)
        aiming = value
    end,
})

-- FOV 크기 조절 슬라이더
AimSection:CreateSlider({
    Name = "FOV 크기",
    Min = 30,
    Max = 180,
    Increment = 1,
    Suffix = "도",
    CurrentValue = FOV_SIZE,
    Callback = function(value)
        FOV_SIZE = value
        updateFOVCircle()
    end,
})

-- FOV 원 생성
local gui = Instance.new("ScreenGui")
gui.Name = "FOV_GUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local circle = Instance.new("Frame")
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.new(0.5, 0, 0.5, 0)
circle.BackgroundTransparency = 1
circle.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = circle

local stroke = Instance.new("UIStroke")
stroke.Color = FOV_COLOR
stroke.Thickness = FOV_THICKNESS
stroke.Transparency = 0.4
stroke.Parent = circle

-- FOV 원 크기 업데이트 함수
function updateFOVCircle()
    local viewport = camera.ViewportSize
    local radius = (FOV_SIZE / camera.FieldOfView) * (viewport.X / 2)
    circle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
end

updateFOVCircle()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFOVCircle)
camera:GetPropertyChangedSignal("FieldOfView"):Connect(updateFOVCircle)

-- 오른쪽 클릭 감지로 에임봇 on/off
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

-- ESP 생성 함수
local function createESP(character)
    if character:FindFirstChild("ClientESP") then return end
    if character == player.Character then return end

    local tag = Instance.new("BoolValue")
    tag.Name = "ClientESP"
    tag.Parent = character

    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")
    local head = character:WaitForChild("Head")

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESP_Box"
    box.Adornee = root
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = BOX_COLOR
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Parent = root

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextScaled = false
    label.TextSize = TEXT_SIZE
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard

    RunService.RenderStepped:Connect(function()
        if humanoid.Health <= 0 then return end
        if not player.Character then return end

        local distance = (player.Character.HumanoidRootPart.Position - root.Position).Magnitude

        label.Text =
            character.Name ..
            "\nHP: " .. math.floor(humanoid.Health) ..
            "\nD: " .. math.floor(distance)
    end)
end

-- 플레이어 감지 및 ESP 적용
local function setupPlayer(p)
    if p == player then return end

    p.CharacterAdded:Connect(function(char)
        createESP(char)
    end)

    if p.Character then
        createESP(p.Character)
    end
end

for _, p in pairs(Players:GetPlayers()) do
    setupPlayer(p)
end

Players.PlayerAdded:Connect(setupPlayer)

-- 에임봇 작동 (FOV 내 가장 가까운 적 조준)
RunService.RenderStepped:Connect(function()
    if not aiming then
        updateFOVCircle()
        return
    end

    local closestTarget = nil
    local closestDistance = math.huge
    local viewportSize = camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local radius = (FOV_SIZE / camera.FieldOfView) * (viewportSize.X / 2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local headPos = p.Character.HumanoidRootPart.Position
            local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if dist < closestDistance and dist <= radius then
                    closestDistance = dist
                    closestTarget = p.Character.HumanoidRootPart
                end
            end
        end
    end

    if closestTarget then
        local direction = (closestTarget.Position - camera.CFrame.Position).Unit
        camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + direction)
    end
end)
