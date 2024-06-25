-- // Services \\ --
local PlayerService = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local StarterPlayer = game:GetService('StarterPlayer')
local TweenService = game:GetService('TweenService')

-- // Variables \\ --
local ToggleRun = false

local Camera = game.Workspace.CurrentCamera
local Character = PlayerService.LocalPlayer.Character or PlayerService.LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChild('Humanoid')
local WalkValues = {StarterPlayer.CharacterWalkSpeed, 80}
local RunValues = {23, 85}

-- // Tweening \\ --
local CameraTweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local Camera_InTween = TweenService:Create(Camera, CameraTweenInfo, {FieldOfView = WalkValues[2]})
local Camera_OutTween = TweenService:Create(Camera, CameraTweenInfo, {FieldOfView = RunValues[2]})

local Active = false


_G.CanRun = true
_G.Running = false

Camera.FieldOfView = 80

local function WalkActions()
    if _G.Running == false or Humanoid.WalkSpeed <= 0 then return end
    Humanoid.WalkSpeed = WalkValues[1]
    Camera_InTween:Play()
    _G.Running = false
end

local function RunActions()
    if _G.Running == true or Humanoid.WalkSpeed <= 0 then return end
    Humanoid.WalkSpeed = RunValues[1]
    Camera_OutTween:Play()
    _G.Running = true
end


UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if not GameProcessed then
        if Input.KeyCode == Enum.KeyCode.LeftShift then
            if ToggleRun then
                if not _G.Running then
                    Active = true
                    if _G.CanRun and Humanoid.MoveDirection.Magnitude > 0 then
                        RunActions()
                    end
                else
                    if _G.Running then
                        WalkActions()
                    end
                end
            else
                Active = true
                if _G.CanRun and Humanoid.MoveDirection.Magnitude > 0 then
                    RunActions()
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input, GameProcessed)
    if ToggleRun then return end
    if Input.KeyCode == Enum.KeyCode.LeftShift then
        Active = false
        if _G.Running then
            WalkActions()
        end
    end
end)

Humanoid:GetPropertyChangedSignal('MoveDirection'):Connect(function()
    if Active then
        if Humanoid.MoveDirection.Magnitude > 0 then
            if not _G.Running and _G.CanRun then
                RunActions()
            end
        else
            WalkActions()
        end 
    end
end)