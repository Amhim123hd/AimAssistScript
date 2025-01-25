local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Locking = false
local CurrentTarget = nil
local HeartbeatConnection = nil
local AimAssistEnabled = false

local FOV_RADIUS = 150 -- Radius of the FOV circle
local FOV_CIRCLE_COLOR = Color3.fromRGB(255, 255, 0) -- Color of the FOV circle
local FOV_CIRCLE_THICKNESS = 2 -- Thickness of the circle's border

-- Create GUI elements
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

local fovCircle = Instance.new("Frame")
fovCircle.Parent = screenGui
fovCircle.Size = UDim2.new(0, FOV_RADIUS * 2, 0, FOV_RADIUS * 2)
fovCircle.Position = UDim2.new(0.5, -FOV_RADIUS, 0.5, -FOV_RADIUS)
fovCircle.BackgroundTransparency = 1

local circleOutline = Instance.new("UICorner")
circleOutline.CornerRadius = UDim.new(1, 0)
circleOutline.Parent = fovCircle

local circleImage = Instance.new("ImageLabel")
circleImage.Parent = fovCircle
circleImage.Size = UDim2.new(1, 0, 1, 0)
circleImage.Position = UDim2.new(0, 0, 0, 0)
circleImage.BackgroundTransparency = 1
circleImage.Image = "rbxassetid://7969513254" -- Circular image
circleImage.ImageColor3 = FOV_CIRCLE_COLOR
circleImage.ImageTransparency = 0.5
circleImage.BorderSizePixel = 0

local function findTargets()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            table.insert(targets, player.Character.Head)
        end
    end
    return targets
end

local function getClosestTarget()
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closestTarget = nil
    local closestDistance = math.huge

    for _, target in ipairs(findTargets()) do
        local screenPoint = Camera:WorldToScreenPoint(target.Position)
        local targetPosition = Vector2.new(screenPoint.X, screenPoint.Y)
        local distanceFromCenter = (targetPosition - centerScreen).Magnitude

        -- Check if the target is within the FOV circle
        if distanceFromCenter < closestDistance and distanceFromCenter < FOV_RADIUS then
            closestDistance = distanceFromCenter
            closestTarget = target
        end
    end

    return closestTarget
end

local function updateAimAssist(deltaTime)
    if CurrentTarget then
        local targetPosition = CurrentTarget.Position
        local currentCameraDirection = Camera.CFrame.LookVector
        local desiredDirection = (targetPosition - Camera.CFrame.Position).Unit
        local smoothSpeed = 0.3

        local newDirection = currentCameraDirection:Lerp(desiredDirection, smoothSpeed)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newDirection)
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
                HeartbeatConnection:Disconnect()
                HeartbeatConnection = nil
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

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if AimAssistEnabled then
            startAimAssist()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        stopAimAssist()
    end
end)
