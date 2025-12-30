-- LocalScript
--------------------------------------------------
-- SERVICES
--------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--------------------------------------------------
-- GLOBAL STATE
--------------------------------------------------
local SYSTEM_ENABLED = false
local AIMBOT_ENABLED = false

--------------------------------------------------
-- THROW SETTINGS
--------------------------------------------------
local TARGET_DISTANCE = 900
local IMPULSE_TIME = 0.15
local strength = TARGET_DISTANCE / IMPULSE_TIME

--------------------------------------------------
-- SUPER THROW GUI (ONLY GUI ON START)
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
-- AIMBOT GUI (CREATED AFTER START)
--------------------------------------------------
local function createAimbotGUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AimbotGUI"
	gui.ResetOnSpawn = false
	gui.Parent = player.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(150,50)
	frame.Position = UDim2.fromScale(0.02,0.45)
	frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255,80,80)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromScale(1,1)
	btn.BackgroundTransparency = 1
	btn.Text = "AIMBOT : OFF"
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.TextColor3 = Color3.fromRGB(255,80,80)
	btn.Parent = frame

	btn.MouseButton1Click:Connect(function()
		AIMBOT_ENABLED = not AIMBOT_ENABLED
		if AIMBOT_ENABLED then
			btn.Text = "AIMBOT : ON"
			btn.TextColor3 = Color3.fromRGB(0,255,120)
			stroke.Color = Color3.fromRGB(0,255,120)
		else
			btn.Text = "AIMBOT : OFF"
			btn.TextColor3 = Color3.fromRGB(255,80,80)
			stroke.Color = Color3.fromRGB(255,80,80)
		end
	end)
end

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

	createAimbotGUI()
end)

--------------------------------------------------
-- ANTI GRAB + ANTI FLING (SMART MERGED)
--------------------------------------------------
local CE = ReplicatedStorage:WaitForChild("CharacterEvents")
local StruggleEvent = CE:WaitForChild("Struggle")
local BeingHeld = player:WaitForChild("IsHeld")

local lastSafeCFrame
local lastGroundedTime = 0
local MAX_AIR_TIME = 3
local FLING_SPEED = 70

local function grounded(root)
	local p = RaycastParams.new()
	p.FilterDescendantsInstances = {player.Character}
	p.FilterType = Enum.RaycastFilterType.Blacklist
	return Workspace:Raycast(root.Position, Vector3.new(0,-6,0), p) ~= nil
end

RunService.Heartbeat:Connect(function()
	if not SYSTEM_ENABLED then return end

	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not root or not hum then return end

	local speed = root.AssemblyLinearVelocity.Magnitude
	local onGround = grounded(root)

	if BeingHeld.Value then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		StruggleEvent:FireServer(player)
		return
	end

	if onGround and speed < 10 then
		lastSafeCFrame = root.CFrame
		lastGroundedTime = os.clock()
	end

	if speed > FLING_SPEED and not onGround and lastSafeCFrame then
		if os.clock() - lastGroundedTime >= MAX_AIR_TIME then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			root.CFrame = lastSafeCFrame
		end
	end
end)

--------------------------------------------------
-- SUPER THROW CORE
--------------------------------------------------
Workspace.ChildAdded:Connect(function(model)
	if not SYSTEM_ENABLED then return end
	if model.Name ~= "GrabParts" then return end

	local grab = model:FindFirstChild("GrabPart")
	if not grab then return end
	local weld = grab:FindFirstChild("WeldConstraint")
	if not weld or not weld.Part1 then return end

	local part = weld.Part1
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.zero
	bv.Parent = part

	local button
	while not button and model.Parent do
		for _,v in ipairs(player.PlayerGui:WaitForChild("ContextActionGui"):GetDescendants()) do
			if v:IsA("ImageLabel") and v.Image:find("9603678090") then
				button = v.Parent
				break
			end
		end
		RunService.Heartbeat:Wait()
	end

	if button then
		button.MouseButton1Down:Connect(function()
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
-- AIMBOT CORE
--------------------------------------------------
local function getClosest()
	local myChar = player.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
	local pos = myChar.HumanoidRootPart.Position

	local target, dist = nil, math.huge
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local d = (hrp.Position - pos).Magnitude
				if d < dist then
					dist = d
					target = hrp
				end
			end
		end
	end
	return target
end

RunService.RenderStepped:Connect(function()
	if not SYSTEM_ENABLED or not AIMBOT_ENABLED then return end
	local t = getClosest()
	if t then
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
	end
end)
