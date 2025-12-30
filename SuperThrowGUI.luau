-- LocalScript
-- Super Throw + Anti Grab + Anti Fling محسّن + Safe Reposition مع انتظار 3 ثواني

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
-- GUI CREATION
--------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SuperThrowGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.fromScale(0.45, 0.35)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)

local frameCorner = Instance.new("UICorner", mainFrame)
frameCorner.CornerRadius = UDim.new(0, 28)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.fromScale(1, 0.35)
title.BackgroundTransparency = 1
title.Text = "SUPER THROW"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)

local startButton = Instance.new("TextButton", mainFrame)
startButton.Size = UDim2.fromScale(0.5, 0.25)
startButton.Position = UDim2.fromScale(0.5, 0.7)
startButton.AnchorPoint = Vector2.new(0.5, 0.5)
startButton.BackgroundColor3 = Color3.fromRGB(0, 200, 90)
startButton.Text = "START"
startButton.Font = Enum.Font.GothamBold
startButton.TextScaled = true
startButton.TextColor3 = Color3.new(1, 1, 1)

local btnCorner = Instance.new("UICorner", startButton)
btnCorner.CornerRadius = UDim.new(0, 22)

startButton.MouseButton1Click:Connect(function()
	superThrowEnabled = true
	startButton.Text = "ENABLED"
	startButton.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
	task.delay(0.4, function() mainFrame.Visible = false end)
end)

--------------------------------------------------
-- ANTI GRAB
--------------------------------------------------
local CE = ReplicatedStorage:WaitForChild("CharacterEvents")
local StruggleEvent = CE:WaitForChild("Struggle")
local BeingHeld = player:WaitForChild("IsHeld")
local struggleConnection

local function stopAntiGrab()
	if struggleConnection then
		struggleConnection:Disconnect()
		struggleConnection = nil
	end
end

local function startAntiGrab()
	if struggleConnection then return end
	local char = player.Character
	if not char then return end
	local root = char:WaitForChild("HumanoidRootPart")
	struggleConnection = RunService.RenderStepped:Connect(function()
		if BeingHeld.Value ~= true then
			stopAntiGrab()
			return
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		StruggleEvent:FireServer(player)
	end)
end

BeingHeld.Changed:Connect(function(value)
	if value then
		startAntiGrab()
	else
		stopAntiGrab()
	end
end)

player.CharacterAdded:Connect(function(char)
	task.wait(0.25)
	local root = char:WaitForChild("HumanoidRootPart")
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	stopAntiGrab()
end)

--------------------------------------------------
-- SAFE REPOSITION + ANTI FLING محسّن + انتظار 3 ثواني
--------------------------------------------------
local lastSafeCFrame = nil
local WAIT_TIME = 3
local WALK_SPEED_THRESHOLD = 16
local JUMP_SPEED_THRESHOLD = 50
local flungTime = 0

local function isGrounded(root)
	local ray = Ray.new(root.Position, Vector3.new(0, -5, 0))
	local part = Workspace:FindPartOnRay(ray, player.Character)
	return part ~= nil
end

RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- تحديث الموقع الآمن فقط إذا لم يتم الإمساك بك
	if BeingHeld.Value == false then
		lastSafeCFrame = root.CFrame
	end

	local linearMag = root.AssemblyLinearVelocity.Magnitude
	local angularMag = root.AssemblyAngularVelocity.Magnitude

	if lastSafeCFrame and (linearMag > JUMP_SPEED_THRESHOLD or angularMag > 200) then
		if isGrounded(root) then
			-- إذا فيه بلوكة تحت الشخصية ننتظر 3 ثواني قبل إعادة مكانها
			flungTime = flungTime + RunService.Heartbeat:Wait()
			if flungTime >= WAIT_TIME then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				root.CFrame = lastSafeCFrame
				flungTime = 0
			end
		else
			-- إذا ما فيه بلوكة تحتها نرجع فوراً
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			root.CFrame = lastSafeCFrame
			flungTime = 0
		end
	else
		flungTime = 0
	end
end)

--------------------------------------------------
-- SUPER THROW CORE (NEW MODEL)
--------------------------------------------------
Workspace.ChildAdded:Connect(function(model)
	if model.Name ~= "GrabParts" then return end
	if not superThrowEnabled then return end

	local grabPart = model:FindFirstChild("GrabPart")
	if not grabPart then return end
	local weld = grabPart:FindFirstChild("WeldConstraint")
	if not weld or not weld.Part1 then return end

	local partToImpulse = weld.Part1
	local velocityObj = Instance.new("BodyVelocity")
	velocityObj.MaxForce = Vector3.new(0, 0, 0)
	velocityObj.Parent = partToImpulse

	local inputButton
	local c1, c2, c3

	while not inputButton and model.Parent do
		local contextGui = player.PlayerGui:FindFirstChild("ContextActionGui")
		if contextGui then
			for _, obj in pairs(contextGui:GetDescendants()) do
				if obj:IsA("ImageLabel") and obj.Image == "http://www.roblox.com/asset/?id=9603678090" then
					inputButton = obj.Parent
					break
				end
			end
		end
		RunService.Heartbeat:Wait()
	end

	if inputButton then
		c1 = inputButton.MouseButton1Down:Connect(function()
			velocityObj.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			velocityObj.Velocity = Workspace.CurrentCamera.CFrame.LookVector * strength
		end)
		c2 = inputButton.MouseButton1Up:Connect(function()
			velocityObj.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			velocityObj.Velocity = Workspace.CurrentCamera.CFrame.LookVector * strength
		end)
	end

	c3 = model:GetPropertyChangedSignal("Parent"):Connect(function()
		if model.Parent then return end
		if c1 then c1:Disconnect() end
		if c2 then c2:Disconnect() end
		if c3 then c3:Disconnect() end
		Debris:AddItem(velocityObj, 1)
	end)
end)
