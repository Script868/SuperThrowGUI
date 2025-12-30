-- LocalScript
-- Super Throw + Anti Grab + Anti Fling (Exact Return)

--------------------------------------------------
-- SERVICES
--------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

--------------------------------------------------
-- THROW SETTINGS
--------------------------------------------------
local TARGET_DISTANCE = 900
local IMPULSE_TIME = 0.15
local strength = TARGET_DISTANCE / IMPULSE_TIME
local superThrowEnabled = false

--------------------------------------------------
-- GUI
--------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SuperThrowGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromScale(0.45, 0.35)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.Parent = gui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 28)

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.35)
title.BackgroundTransparency = 1
title.Text = "SUPER THROW"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = mainFrame

local startButton = Instance.new("TextButton")
startButton.Size = UDim2.fromScale(0.5, 0.25)
startButton.Position = UDim2.fromScale(0.5, 0.7)
startButton.AnchorPoint = Vector2.new(0.5, 0.5)
startButton.BackgroundColor3 = Color3.fromRGB(0, 200, 90)
startButton.Text = "START"
startButton.Font = Enum.Font.GothamBold
startButton.TextScaled = true
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.Parent = mainFrame
Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 22)

startButton.MouseButton1Click:Connect(function()
	superThrowEnabled = true
	startButton.Text = "ENABLED"
	startButton.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
	task.delay(0.4, function()
		mainFrame.Visible = false
	end)
end)

--------------------------------------------------
-- ANTI GRAB (سريع)
--------------------------------------------------
local CE = ReplicatedStorage:WaitForChild("CharacterEvents")
local StruggleEvent = CE:WaitForChild("Struggle")
local BeingHeld = player:WaitForChild("IsHeld")

local antiGrabConn
local function stopAntiGrab()
	if antiGrabConn then
		antiGrabConn:Disconnect()
		antiGrabConn = nil
	end
end

BeingHeld.Changed:Connect(function(v)
	if v == true then
		local char = player.Character
		if not char then return end
		local root = char:WaitForChild("HumanoidRootPart")

		antiGrabConn = RunService.RenderStepped:Connect(function()
			if not BeingHeld.Value then
				stopAntiGrab()
				return
			end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			StruggleEvent:FireServer(player)
		end)
	else
		stopAntiGrab()
	end
end)

--------------------------------------------------
-- TRUE SAFE ANTI FLING (GROUND-BASED)
--------------------------------------------------
local lastSafeCFrame = nil
local lastGroundedTime = 0

local FLING_SPEED = 70
local FLING_ANGULAR = 200
local MAX_AIR_TIME = 3

local function isGrounded(root)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {player.Character}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(
		root.Position,
		Vector3.new(0, -6, 0),
		params
	)

	return result ~= nil
end

RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local speed = root.AssemblyLinearVelocity.Magnitude
	local angular = root.AssemblyAngularVelocity.Magnitude
	local grounded = isGrounded(root)

	-- حفظ مكان آمن حقيقي فقط
	if grounded and not BeingHeld.Value and speed < 10 then
		lastSafeCFrame = root.CFrame
		lastGroundedTime = os.clock()
	end

	-- كشف fling
	if speed > FLING_SPEED or angular > FLING_ANGULAR then
		-- لو صار في الهواء أكثر من المسموح
		if not grounded and lastSafeCFrame then
			if os.clock() - lastGroundedTime >= MAX_AIR_TIME then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				root.CFrame = lastSafeCFrame
			end
		end
	end
end)

--------------------------------------------------
-- SUPER THROW CORE
--------------------------------------------------
Workspace.ChildAdded:Connect(function(model)
	if model.Name ~= "GrabParts" then return end
	if not superThrowEnabled then return end

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
		for _, obj in pairs(player.PlayerGui:WaitForChild("ContextActionGui"):GetDescendants()) do
			if obj:IsA("ImageLabel") and obj.Image == "http://www.roblox.com/asset/?id=9603678090" then
				button = obj.Parent
				break
			end
		end
		RunService.Heartbeat:Wait()
	end

	if button then
		button.MouseButton1Down:Connect(function()
			bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bv.Velocity = Workspace.CurrentCamera.CFrame.LookVector * strength
		end)
	end

	model:GetPropertyChangedSignal("Parent"):Connect(function()
		if not model.Parent then
			Debris:AddItem(bv, 1)
		end
	end)
end)


--------------------------------------------------
-- AIMBOT + GUI (READY, NO SETUP)
--------------------------------------------------
local AIMBOT_ENABLED = false
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

-- GUI
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(140, 50)
frame.Position = UDim2.fromScale(0.02, 0.45)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255,80,80)

local button = Instance.new("TextButton")
button.Size = UDim2.fromScale(1,1)
button.BackgroundTransparency = 1
button.Text = "AIMBOT : OFF"
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.TextColor3 = Color3.fromRGB(255,80,80)
button.Parent = frame

button.MouseButton1Click:Connect(function()
	AIMBOT_ENABLED = not AIMBOT_ENABLED
	if AIMBOT_ENABLED then
		button.Text = "AIMBOT : ON"
		button.TextColor3 = Color3.fromRGB(0,255,120)
		stroke.Color = Color3.fromRGB(0,255,120)
	else
		button.Text = "AIMBOT : OFF"
		button.TextColor3 = Color3.fromRGB(255,80,80)
		stroke.Color = Color3.fromRGB(255,80,80)
	end
end)

-- Aimbot
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
	if not AIMBOT_ENABLED then return end
	local target = getClosestPlayer()
	if target then
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
	end
end)
