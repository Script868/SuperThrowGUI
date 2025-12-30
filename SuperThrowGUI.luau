-- LocalScript
-- SuperThrow + Smart AntiGrab & AntiFling + Aimbot
-- EVERYTHING ENABLES ONLY AFTER PRESSING START

--------------------------------------------------
-- SERVICES
--------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--------------------------------------------------
-- MASTER SWITCH (VERY IMPORTANT)
--------------------------------------------------
local SYSTEM_ENABLED = false

--------------------------------------------------
-- SUPER THROW SETTINGS
--------------------------------------------------
local TARGET_DISTANCE = 900
local IMPULSE_TIME = 0.15
local strength = TARGET_DISTANCE / IMPULSE_TIME

--------------------------------------------------
-- GUI : SUPER THROW (ONLY GUI THAT APPEARS)
--------------------------------------------------
local superGui = Instance.new("ScreenGui")
superGui.Name = "SuperThrowGUI"
superGui.ResetOnSpawn = false
superGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromScale(0.45, 0.35)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
mainFrame.Parent = superGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,28)

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1,0.35)
title.BackgroundTransparency = 1
title.Text = "SUPER THROW"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)
title.Parent = mainFrame

local startButton = Instance.new("TextButton")
startButton.Size = UDim2.fromScale(0.5,0.25)
startButton.Position = UDim2.fromScale(0.5,0.7)
startButton.AnchorPoint = Vector2.new(0.5,0.5)
startButton.BackgroundColor3 = Color3.fromRGB(0,200,90)
startButton.Text = "START"
startButton.Font = Enum.Font.GothamBold
startButton.TextScaled = true
startButton.TextColor3 = Color3.new(1,1,1)
startButton.Parent = mainFrame
Instance.new("UICorner", startButton).CornerRadius = UDim.new(0,22)

--------------------------------------------------
-- START BUTTON
--------------------------------------------------
startButton.MouseButton1Click:Connect(function()
	SYSTEM_ENABLED = true
	startButton.Text = "ENABLED"
	startButton.BackgroundColor3 = Color3.fromRGB(0,140,60)
	task.delay(0.4, function()
		mainFrame.Visible = false
	end)
end)

--------------------------------------------------
-- SMART ANTI GRAB + ANTI FLING (MERGED)
--------------------------------------------------
local CE = ReplicatedStorage:WaitForChild("CharacterEvents")
local StruggleEvent = CE:WaitForChild("Struggle")
local BeingHeld = player:WaitForChild("IsHeld")

local lastSafeCFrame = nil
local lastGroundedTime = 0

local FLING_SPEED = 65
local FLING_ANGULAR = 180
local MAX_AIR_TIME = 3

local function isGrounded(root)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {player.Character}
	params.FilterType = Enum.RaycastFilterType.Blacklist
	return Workspace:Raycast(root.Position, Vector3.new(0,-6,0), params) ~= nil
end

RunService.Heartbeat:Connect(function()
	if not SYSTEM_ENABLED then return end

	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	local speed = root.AssemblyLinearVelocity.Magnitude
	local angular = root.AssemblyAngularVelocity.Magnitude
	local grounded = isGrounded(root)

	-- حفظ مكان آمن حقيقي فقط
	if grounded and not BeingHeld.Value and speed < 12 then
		lastSafeCFrame = root.CFrame
		lastGroundedTime = os.clock()
	end

	-- Anti Grab (ذكي)
	if BeingHeld.Value then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		StruggleEvent:FireServer(player)
	end

	-- Anti Fling (ذكي)
	if lastSafeCFrame
		and not grounded
		and (speed > FLING_SPEED or angular > FLING_ANGULAR)
		and os.clock() - lastGroundedTime >= MAX_AIR_TIME then

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		root.CFrame = lastSafeCFrame
	end
end)

--------------------------------------------------
-- SUPER THROW CORE
--------------------------------------------------
Workspace.ChildAdded:Connect(function(model)
	if not SYSTEM_ENABLED then return end
	if model.Name ~= "GrabParts" then return end

	local grabPart = model:FindFirstChild("GrabPart")
	if not grabPart then return end

	local weld = grabPart:FindFirstChild("WeldConstraint")
	if not weld or not weld.Part1 then return end

	local part = weld.Part1
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.zero
	bv.Parent = part

	local button
	while not button and model.Parent do
		for _, obj in pairs(player.PlayerGui:GetDescendants()) do
			if obj:IsA("ImageLabel")
				and obj.Image == "http://www.roblox.com/asset/?id=9603678090" then
				button = obj.Parent
				break
			end
		end
		RunService.Heartbeat:Wait()
	end

	if button then
		button.MouseButton1Down:Connect(function()
			if not SYSTEM_ENABLED then return end
			bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
			bv.Velocity = Camera.CFrame.LookVector * strength
		end)
	end

	model:GetPropertyChangedSignal("Parent"):Connect(function()
		if not model.Parent then
			Debris:AddItem(bv,1)
		end
	end)
end)

--------------------------------------------------
-- AIMBOT (NO GUI UNTIL START)
--------------------------------------------------
local AIMBOT_ENABLED = true

local function getClosestPlayer()
	local myChar = player.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
	local myPos = myChar.HumanoidRootPart.Position

	local closest, dist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local d = (hrp.Position - myPos).Magnitude
				if d < dist then
					dist = d
					closest = hrp
				end
			end
		end
	end
	return closest
end

RunService.RenderStepped:Connect(function()
	if not SYSTEM_ENABLED or not AIMBOT_ENABLED then return end
	local target = getClosestPlayer()
	if target then
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
	end
end)
