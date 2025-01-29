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
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
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

-- Function to find the closest player to the center of the screen
local function getClosestTarget()
    local closestTarget = nil
    local smallestAngle = math.huge
    local cameraPosition = Camera.CFrame.Position
    local cameraLookVector = Camera.CFrame.LookVector

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local targetPosition = character.HumanoidRootPart.Position
            local directionToTarget = (targetPosition - cameraPosition).Unit
            local angle = math.acos(cameraLookVector:Dot(directionToTarget))

            -- Check if the target is within a reasonable field of view
            if angle < math.rad(45) and angle < smallestAngle then
                closestTarget = character
                smallestAngle = angle
            end
        end
    end

    return closestTarget
end

local function updateAimAssist(deltaTime)
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local targetPosition = CurrentTarget.HumanoidRootPart.Position
        local currentCameraDirection = Camera.CFrame.LookVector
        local desiredDirection = (targetPosition - Camera.CFrame.Position).Unit
        local smoothSpeed = 0.2 -- Lower smooth speed

        -- Interpolating with deltaTime to smooth the movement
        local newDirection = currentCameraDirection:Lerp(desiredDirection, deltaTime * smoothSpeed)

        -- Limiting how much the direction can change in one frame to avoid sudden jerks
        local maxChangeRate = 0.05
        local delta = (desiredDirection - currentCameraDirection).Unit
        if delta.Magnitude > maxChangeRate then
            delta = delta.Unit * maxChangeRate
        end
        newDirection = currentCameraDirection + delta

        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newDirection)
    else
        -- Stop if target is invalid
        stopAimAssist()
    end
end

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
                stopAimAssist()
            end
        end)
    end
end

local function stopAimAssist()
    Locking = false
    CurrentTarget = nil

    if HeartbeatConnection then
        HeartbeatConnection:Disconnect()
        HeartbeatConnection = nil
    end
end

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

-- Toggle Aim Assist with the "J" key
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

-- Start Aim Assist on right mouse button hold
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if AimAssistEnabled then
            startAimAssist()
        end
    end
end)

-- Stop Aim Assist when right mouse button is released
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        stopAimAssist()
    end
end)
