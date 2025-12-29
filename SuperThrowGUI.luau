-- LocalScript (ضعه داخل StarterPlayerScripts)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local BeingHeld = Player:WaitForChild("IsHeld")

local CE = ReplicatedStorage:WaitForChild("CharacterEvents")
local StruggleEvent = CE:WaitForChild("Struggle")

--------------------------------------------------
-- SUPER THROW SETTINGS
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
gui.Parent = Player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromScale(0.45, 0.35)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5,0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
mainFrame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0,28)
frameCorner.Parent = mainFrame

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

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0,22)
btnCorner.Parent = startButton

--------------------------------------------------
-- START BUTTON
--------------------------------------------------
startButton.MouseButton1Click:Connect(function()
    superThrowEnabled = true
    startButton.Text = "ENABLED"
    startButton.BackgroundColor3 = Color3.fromRGB(0,140,60)
    task.delay(0.4,function()
        mainFrame.Visible = false
    end)
end)

--------------------------------------------------
-- ANTI GRAB CHARACTER (المطور)
--------------------------------------------------
-- منع أي انفجارات تؤثر على اللاعب
Workspace.DescendantAdded:Connect(function(v)
    if v:IsA("Explosion") then
        v.BlastPressure = 0
    end
end)

-- Anti Grab أسرع وأكثر استجابة
BeingHeld.Changed:Connect(function(val)
    if val == true then
        local Event
        Event = RunService.RenderStepped:Connect(function()
            if BeingHeld.Value == true and Character and Character:FindFirstChild("HumanoidRootPart") then
                Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new()
                StruggleEvent:FireServer(Player)
            else
                if Event then Event:Disconnect() end
            end
        end)
    end
end)

-- إعادة ربط الشخصية بعد التجديد
local function reconnect()
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:FindFirstChildWhichIsA("Humanoid") or Character:WaitForChild("Humanoid")
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    local firePart = HumanoidRootPart:FindFirstChild("FirePlayerPart")
    if firePart then firePart:Remove() end

    Humanoid.Changed:Connect(function(prop)
        if prop == "Sit" and Humanoid.Sit == true then
            if Humanoid.SeatPart ~= nil and tostring(Humanoid.SeatPart.Parent) == "CreatureBlobman" then
                return
            elseif Humanoid.SeatPart == nil then
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                Humanoid.Sit = false
            end
        end
    end)
end

reconnect()
Player.CharacterAdded:Connect(reconnect)

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

    local partToImpulse = weld.Part1

    local velocityObj = Instance.new("BodyVelocity")
    velocityObj.MaxForce = Vector3.new(0,0,0)
    velocityObj.Parent = partToImpulse

    local inputButton
    local c1,c2,c3

    -- Find original Throw button
    while not inputButton and model.Parent do
        for _, obj in pairs(Player.PlayerGui:WaitForChild("ContextActionGui"):GetDescendants()) do
            if obj:IsA("ImageLabel") and obj.Image == "http://www.roblox.com/asset/?id=9603678090" then
                inputButton = obj.Parent
                break
            end
        end
        RunService.Heartbeat:Wait()
    end

    if inputButton then
        c1 = inputButton.MouseButton1Down:Connect(function()
            velocityObj.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
            velocityObj.Velocity = Workspace.CurrentCamera.CFrame.LookVector * strength
        end)

        c2 = inputButton.MouseButton1Up:Connect(function()
            velocityObj.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
            velocityObj.Velocity = Workspace.CurrentCamera.CFrame.LookVector * strength
        end)
    end

    c3 = model:GetPropertyChangedSignal("Parent"):Connect(function()
        if model.Parent then return end
        if c1 then c1:Disconnect() end
        if c2 then c2:Disconnect() end
        if c3 then c3:Disconnect() end
        Debris:AddItem(velocityObj,1)
    end)
end)
