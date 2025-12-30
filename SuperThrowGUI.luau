--[[ 
	SUPER THROW + SMART ANTI GRAB + SMART ANTI FLING + AIMBOT + ANTI LAG + ANTI AFK
	ALL DISABLED UNTIL START
]]

--------------------------------------------------
-- SERVICES
--------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--------------------------------------------------
-- MAIN SWITCH
--------------------------------------------------
local SYSTEM_ENABLED = false

--------------------------------------------------
-- THROW SETTINGS
--------------------------------------------------
local TARGET_DISTANCE = 900
local IMPULSE_TIME = 0.15
local strength = TARGET_DISTANCE / IMPULSE_TIME

--------------------------------------------------
-- SUPER THROW GUI (ONLY GUI AT START)
--------------------------------------------------
local superGui = Instance.new("ScreenGui")
superGui.Name = "SuperThrowGUI"
superGui.ResetOnSpawn = false
superGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame", superGui)
mainFrame.Size = UDim2.fromScale(0.45, 0.35)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,28)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.fromScale(1,0.35)
title.BackgroundTransparency = 1
title.Text = "SUPER THROW"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

local startButton = Instance.new("TextButton", mainFrame)
startButton.Size = UDim2.fromScale(0.5,0.25)
startButton.Position = UDim2.fromScale(0.5,0.7)
startButton.AnchorPoint = Vector2.new(0.5,0.5)
startButton.BackgroundColor3 = Color3.fromRGB(0,200,90)
startButton.Text = "START"
startButton.Font = Enum.Font.GothamBold
startButton.TextScaled = true
startButton.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", startButton).CornerRadius = UDim.new(0,22)

--------------------------------------------------
-- AIMBOT GUI (CREATED AFTER START)
--------------------------------------------------
local AIMBOT_ENABLED = false
local function createAimbotGUI()
	if player.PlayerGui:FindFirstChild("AimbotGUI") then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AimbotGUI"
	gui.ResetOnSpawn = false
	gui.Parent = player.PlayerGui

	local frame = Instance.new("Frame", gui)
	frame.Size = UDim2.fromOffset(160,50)
	frame.Position = UDim2.fromScale(0.02,0.45)
	frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255,80,80)

	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.fromScale(1,1)
	btn.BackgroundTransparency = 1
	btn.Text = "AIMBOT : OFF"
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.TextColor3 = Color3.fromRGB(255,80,80)

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
	if SYSTEM_ENABLED then return end
	SYSTEM_ENABLED = true

	startButton.Text = "ENABLED"
	startButton.BackgroundColor3 = Color3.fromRGB(0,140,60)
	task.delay(0.4, function()
		mainFrame.Visible = false
	end)

	createAimbotGUI()
end)

--------------------------------------------------
-- SMART ANTI GRAB + SMART ANTI FLING
--------------------------------------------------
local CE = ReplicatedStorage:WaitForChild("CharacterEvents")
local StruggleEvent = CE:WaitForChild("Struggle")
local BeingHeld = player:WaitForChild("IsHeld")
local lastSafeCFrame, airStart

local function grounded(root)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {player.Character}
	params.FilterType = Enum.RaycastFilterType.Blacklist
	return Workspace:Raycast(root.Position, Vector3.new(0,-6,0), params) ~= nil
end

RunService.Heartbeat:Connect(function()
	if not SYSTEM_ENABLED then return end

	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	local speed = root.AssemblyLinearVelocity.Magnitude

	-- Anti Grab
	if BeingHeld.Value then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		StruggleEvent:FireServer(player)
	end

	-- Save safe ground
	if grounded(root) and speed < 10 and not BeingHeld.Value then
		lastSafeCFrame = root.CFrame
		airStart = nil
	end

	-- Detect fling and return to last safe position
	if speed > 70 and not grounded(root) then
		if not airStart then
			airStart = os.clock()
		elseif os.clock() - airStart >= 3 and lastSafeCFrame then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			root.CFrame = lastSafeCFrame
			airStart = nil
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
	local bv = Instance.new("BodyVelocity", part)
	bv.MaxForce = Vector3.zero

	while model.Parent do
		for _,obj in pairs(player.PlayerGui:WaitForChild("ContextActionGui"):GetDescendants()) do
			if obj:IsA("ImageLabel") and obj.Image == "http://www.roblox.com/asset/?id=9603678090" then
				obj.Parent.MouseButton1Down:Connect(function()
					bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
					bv.Velocity = Camera.CFrame.LookVector * strength
				end)
				return
			end
		end
		RunService.Heartbeat:Wait()
	end
end)

--------------------------------------------------
-- AIMBOT LOGIC
--------------------------------------------------
local function getClosestPlayer()
	local myChar = player.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
	local myPos = myChar.HumanoidRootPart.Position

	local closest, dist = nil, math.huge
	for _,plr in ipairs(Players:GetPlayers()) do
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

--------------------------------------------------
-- ANTI LAG (CLEAR EXPLOSIONS)
--------------------------------------------------
Workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Explosion") then
		obj.BlastPressure = 0
	end
end)

--------------------------------------------------
-- ANTI AFK (PREVENT IDLE)
--------------------------------------------------
Players.LocalPlayer.Idled:Connect(function()
	-- simulate input
	UserInputService.InputBegan:Fire({UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.W})
end)
