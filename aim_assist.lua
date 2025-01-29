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

-- Function to check if a player is visible using raycasting, ensuring no obstructions (walls/glass)
local function isPlayerVisible(targetCharacter)
    if not targetCharacter then return false end
    local targetTorso = targetCharacter:FindFirstChild("HumanoidRootPart")
    local playerTorso = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if targetTorso and playerTorso then
        local direction = (targetTorso.Position - playerTorso.Position).Unit
        local ray = workspace:Raycast(playerTorso.Position, direction * 500)  -- Increase raycast distance

        -- Check if the ray hit the target's HumanoidRootPart and not something else like a wall
        if ray then
            local hitPart = ray.Instance
            -- Ensure the ray hit the target and not an obstruction
            if hitPart:IsDescendantOf(targetCharacter) then
                return true
            end
        end
    end

    return false
end

-- Function to find the closest player to the center of the screen, excluding teammates
local function getClosestTarget()
    local closestTarget = nil
    local smallestAngle = math.huge
    local cameraPosition = Camera.CFrame.Position
    local cameraLookVector = Camera.CFrame.LookVector

    for _, player in ipairs(Players:GetPlayers()) do
        -- Exclude the local player and players on the same team
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local targetPosition = character.HumanoidRootPart.Position
            local directionToTarget = (targetPosition - cameraPosition).Unit
            local angle = math.acos(cameraLookVector:Dot(directionToTarget))

            -- Check if the target is within a reasonable field of view and is visible (no obstructions)
            if angle < math.rad(45) and isPlayerVisible(character) and angle < smallestAngle then
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
        local smoothSpeed = 0.3

        local newDirection = currentCameraDirection:Lerp(desiredDirection, smoothSpeed)
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newDirection)
    else
        -- Stop if target is invalid or no longer visible
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
