local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Locking = false
local CurrentTarget = nil
local HeartbeatConnection = nil
local AimAssistEnabled = false

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = LocalPlayer.PlayerGui
local messageLabel = Instance.new("TextLabel")
messageLabel.Parent = screenGui
messageLabel.Size = UDim2.new(0, 250, 0, 50)
messageLabel.Position = UDim2.new(0.5, -125, 0.1, 0)
messageLabel.Text = "Aim Assist is OFF"
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
messageLabel.BackgroundTransparency = 0.5
messageLabel.Font = Enum.Font.GothamBold
messageLabel.TextSize = 20
messageLabel.TextStrokeTransparency = 0.8
messageLabel.Visible = false

-- Function to find all potential targets
local function findTargets()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            table.insert(targets, player.Character.Head)
        end
    end
    return targets
end

-- Function to get the closest target
local function getClosestTarget()
    local mouse = LocalPlayer:GetMouse()
    local closestTarget = nil
    local closestDistance = math.huge

    for _, target in ipairs(findTargets()) do
        local screenPoint = Camera:WorldToScreenPoint(target.Position)
        local mousePos = Vector2.new(mouse.X, mouse.Y)
        local distance = (mousePos - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude

        if distance < closestDistance and distance < 150 then
            closestDistance = distance
            closestTarget = target
        end
    end

    return closestTarget
end

-- Function to update aim assist
local function updateAimAssist(deltaTime)
    if CurrentTarget then
        local targetPosition = CurrentTarget.Position
        local currentCameraDirection = Camera.CFrame.LookVector
        local desiredDirection = (targetPosition - Camera.CFrame.Position).Unit
        local smoothSpeed = 0.050

        local newDirection = currentCameraDirection:Lerp(desiredDirection, smoothSpeed)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newDirection)
    end
end

-- Start aim assist
local function startAimAssist()
    Locking = true
    CurrentTarget = getClosestTarget()

    if HeartbeatConnection then
        HeartbeatConnection:Disconnect()
        HeartbeatConnection = nil
    end

    if CurrentTarget then
        HeartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if Locking then
                updateAimAssist(deltaTime)
            else
                HeartbeatConnection:Disconnect()
                HeartbeatConnection = nil
            end
        end)
    end
end

-- Stop aim assist
local function stopAimAssist()
    Locking = false
    CurrentTarget = nil

    if HeartbeatConnection then
        HeartbeatConnection:Disconnect()
        HeartbeatConnection = nil
    end
end

-- Function to slide up the label (visibility)
local function slideUpLabel()
    messageLabel.Visible = true
    local startPos = messageLabel.Position
    local targetPos = UDim2.new(0.5, -125, 0.1, 0)

    for i = 0, 1, 0.05 do
        messageLabel.Position = startPos:Lerp(targetPos, i)
        wait(0.01)
    end
end

-- Function to slide down the label (hide)
local function slideDownLabel()
    local startPos = messageLabel.Position
    local targetPos = UDim2.new(0.5, -125, 1, 0)

    for i = 0, 1, 0.05 do
        messageLabel.Position = startPos:Lerp(targetPos, i)
        wait(0.01)
    end
    messageLabel.Visible = false
end

-- Toggle aim assist on/off when E key is pressed
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.E then
        AimAssistEnabled = not AimAssistEnabled
        if AimAssistEnabled then
            messageLabel.Text = "Aim Assist is ON"
            slideUpLabel()
            startAimAssist()  -- Automatically start aim assist when E is pressed
        else
            messageLabel.Text = "Aim Assist is OFF"
            slideDownLabel()
            stopAimAssist()  -- Automatically stop aim assist when E is pressed again
        end
    end
end)

-- Stop aim assist when E key is released
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.E then
        stopAimAssist()
    end
end)

