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
-- TRUE ANTI FLING (يرجعك لنفس المكان)
--------------------------------------------------
local savedBeforeFling
local flingStarted = false
local flingStartTime = 0
local WAIT_TIME = 3

local function hasGroundBelow(root)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {player.Character}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	return workspace:Raycast(root.Position, Vector3.new(0, -8, 0), params) ~= nil
end

RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local speed = root.AssemblyLinearVelocity.Magnitude
	local angular = root.AssemblyAngularVelocity.Magnitude
	local isFlung = speed > 70 or angular > 200

	-- حفظ المكان الطبيعي فقط
	if not isFlung and not BeingHeld.Value then
		savedBeforeFling = root.CFrame
		flingStarted = false
		return
	end

	-- بداية الطيران
	if isFlung and not flingStarted and savedBeforeFling then
		flingStarted = true
		flingStartTime = os.clock()
	end

	if flingStarted and savedBeforeFling then
		if not hasGroundBelow(root) or os.clock() - flingStartTime >= WAIT_TIME then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			root.CFrame = savedBeforeFling
			flingStarted = false
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
