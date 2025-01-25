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

-- Function to find the closest target player near you
local function getClosestTarget()
    local closestTarget = nil
    local closestDistance = math.huge
    local playerPosition = LocalPlayer.Character.HumanoidRootPart.Position

    -- Check all players for the closest one
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local targetPosition = player.Character.Head.Position
            local distance = (playerPosition - targetPosition).Magnitude

            if distance < closestDistance and distance < 50 then -- Adjust 50 to your desired range
                closestDistance = distance
                closestTarget = player.Character.Head
            end
        end
    end

    return closestTarget
end

-- Function to update the camera's aim
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

-- Start the aim assist when right-click is held
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

-- Stop the aim assist
local function stopAimAssist()
    Locking = false
    CurrentTarget = nil

    if HeartbeatConnection then
        HeartbeatConnection:Disconnect()
        HeartbeatConnection = nil
    end
end

-- Show and hide the message label
local function slideUpLabel()
    messageLabel.Visible = true
    local startPos = messageLabel.Position
    local targetPos = UDim2.new(0.5, -125, 0.1, 0)

    for i = 0, 1, 0.05 do
        messageLabel.Position = startPos:Lerp(targetPos, i)
        wait(0.01)
    end
end

local function slideDownLabel()
    local startPos = messageLabel.Position
    local targetPos = UDim2.new(0.5, -125, 1, 0)

    for i = 0, 1, 0.05 do
        messageLabel.Position = startPos:Lerp(targetPos, i)
        wait(0.01)
    end
    messageLabel.Visible = false
end

-- Toggle the aim assist on and off when pressing "J"
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.J then
        AimAssistEnabled = not AimAssistEnabled
        if AimAssistEnabled then
            messageLabel.Text = "Aim Assist is ON"
            slideUpLabel()
        else
            messageLabel.Text = "Aim Assist is OFF"
            slideDownLabel()
        end
    end
end)

-- Trigger aim assist on right-click (MouseButton2)
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if AimAssistEnabled then
            startAimAssist()
        end
    end
end)

-- Stop aim assist when right-click is released
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        stopAimAssist()
    end
end)
