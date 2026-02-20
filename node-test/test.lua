-- =========================
-- 👁 CLIENT ESP + FOV CIRCLE
-- =========================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- 🔧 설정
local TEXT_SIZE = 12
local BOX_COLOR = Color3.fromRGB(255,0,0)

local FOV_ENABLED = true
local FOV_SIZE = 90 -- 시야각 (도)
local FOV_COLOR = Color3.fromRGB(255,0,0)
local FOV_THICKNESS = 2

-- =========================
-- 👁 FOV 원 생성
-- =========================
if FOV_ENABLED then
	local gui = Instance.new("ScreenGui")
	gui.Name = "FOV_GUI"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local circle = Instance.new("Frame")
	circle.AnchorPoint = Vector2.new(0.5,0.5)
	circle.Position = UDim2.new(0.5,0,0.5,0)
	circle.BackgroundTransparency = 1
	circle.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1,0)
	corner.Parent = circle

	local stroke = Instance.new("UIStroke")
	stroke.Color = FOV_COLOR
	stroke.Thickness = FOV_THICKNESS
	stroke.Transparency = 0.4
	stroke.Parent = circle

	local function updateCircle()
		local viewport = camera.ViewportSize
		local radius = (FOV_SIZE / camera.FieldOfView) * (viewport.X / 2)
		circle.Size = UDim2.new(0, radius*2, 0, radius*2)
	end

	updateCircle()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCircle)
	camera:GetPropertyChangedSignal("FieldOfView"):Connect(updateCircle)
end

-- =========================
-- 👁 ESP 생성 함수
-- =========================
local function createESP(character)
	if character:FindFirstChild("ClientESP") then return end
	if character == player.Character then return end
	
	local tag = Instance.new("BoolValue")
	tag.Name = "ClientESP"
	tag.Parent = character
	
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	local head = character:WaitForChild("Head")

	-- 📦 박스
	local box = Instance.new("BoxHandleAdornment")
	box.Name = "ESP_Box"
	box.Adornee = root
	box.Size = Vector3.new(4,6,2)
	box.Color3 = BOX_COLOR
	box.Transparency = 0.5
	box.AlwaysOnTop = true
	box.ZIndex = 10
	box.Parent = root

	-- 🏷 이름 + 체력 + 거리
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_Billboard"
	billboard.Size = UDim2.new(0,100,0,40)
	billboard.StudsOffset = Vector3.new(0,3,0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,0,1,0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1,1,1)
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
			"\nHP: "..math.floor(humanoid.Health)..
			"\nD: "..math.floor(distance)
	end)
end

-- =========================
-- 플레이어 감지
-- =========================
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