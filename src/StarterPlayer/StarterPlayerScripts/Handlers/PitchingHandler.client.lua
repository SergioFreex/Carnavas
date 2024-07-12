repeat task.wait() until game:IsLoaded()

-- // Services \\ --
local PlayerService = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local StarterGui = game:GetService('StarterGui')
local ContentProvider = game:GetService('ContentProvider')

-- // Variables \\ --
local LocalPlayer = PlayerService.LocalPlayer
local PitchingUI = LocalPlayer.PlayerGui:WaitForChild('Carnavas', 10).Pitching
local Mouse = LocalPlayer:GetMouse()
local Camera = game.Workspace.CurrentCamera
local PitcherEvent = ReplicatedStorage.Carnavas.Events.PitcherEvent
local Connections = {}
local Cooldown = {false, 6}

local Main_DefaultPos = UDim2.new(1, -260, .5, 0)
local Main_ClosedPos = UDim2.new(1, 200, 0.5, 0)

-- // Tweening \\ --
local Camera_TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local Main_TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local Camera_ZoomIn = TweenService:Create(Camera, Camera_TweenInfo, {FieldOfView = 10})
local Camera_ZoomOut = TweenService:Create(Camera, Camera_TweenInfo, {FieldOfView = 80})

local Main_Open  = TweenService:Create(PitchingUI.Main, Main_TweenInfo, {Position = Main_DefaultPos})
local Main_Close = TweenService:Create(PitchingUI.Main, Main_TweenInfo, {Position = Main_ClosedPos})

-- // Animations \\ --
local PitchingAnimations = ReplicatedStorage.Carnavas.Animations.PitchingAnimations
local Idle = PitchingAnimations.Idle
local Throwing = PitchingAnimations.Throwing

ContentProvider:PreloadAsync({Idle.AnimationId, Throwing.AnimationId})

local Animations = {Idle = nil, Throwing = nil}
local CurrentPitchSelected = nil

local Keycodes = {
    [Enum.KeyCode.W] = 'CU',
    [Enum.KeyCode.A] = '4SFB',
    [Enum.KeyCode.D] = 'SL'
}

local function KillAllListeners()
    for key,_ in next, Connections do
        if Connections[key].Connected == true then
            local Connection = Connections[key]
            Connection:Disconnect()
            Connection = nil
        end
    end
end

local function Disengage(Humanoid)
    if Animations.Idle then
        if Animations.Idle.IsPlaying == true then
            Animations.Idle:Stop()
        end
    end
    PitcherEvent:FireServer('Disengage')
    Camera.CameraType = Enum.CameraType.Custom
    Camera_ZoomOut:Play()

    Humanoid.AutoRotate = true
   
    PitchingUI.Thingy.Visible = false

    if PitchingUI.Main.Position ~= Main_ClosedPos then
        Main_Close:Play()
        Main_Close.Completed:Connect(function(playbackState)
            PitchingUI.Visible = false
        end)
        CurrentPitchSelected = nil
    end

    StarterGui:SetCore('ResetButtonCallback', true)
    KillAllListeners()
end

UserInputService.InputChanged:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.Touch then
        PitchingUI.Thingy.Text = 'Tap here to step off the rubber.'
    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
        PitchingUI.Thingy.Text = 'Press E to step off the rubber.'
    end
end)

PitcherEvent.OnClientEvent:Connect(function(Action, ...)
    local Args = {...}
    if Action == 'BeginPitching' then
        if LocalPlayer.Character then
            local Character = LocalPlayer.Character
            local Humanoid = Character:FindFirstChildOfClass('Humanoid')
            local Pitching = false

            StarterGui:SetCore('ResetButtonCallback', false)

            PitchingUI.Visible = true
            PitchingUI.Main.Position = Main_ClosedPos
            Main_Open:Play()
            PitchingUI.Main.CurrentPitch.Text = '<b>No Pitch Selected</b>'
            
            for _,v in next, PitchingUI.Main:GetChildren() do
                if v:IsA('ImageLabel') then
                    local Keybind = v:FindFirstChildOfClass('TextButton')
                    if Keybind then
                        Connections[v.Name] = Keybind.MouseButton1Click:Connect(function()
                            CurrentPitchSelected = v.Name
                            PitchingUI.Main.CurrentPitch.Text = '<b>Current Pitch</b>: ' .. v.Name
                        end)
                    end
                end
            end
            
            if Humanoid and Humanoid:FindFirstChildOfClass('Animator') then
                local Animator = Humanoid.Animator
                Humanoid.AutoRotate = false
                Animations.Idle = Animator:LoadAnimation(Idle)
                Animations.Throwing = Animator:LoadAnimation(Throwing)
            end

            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = Character.HumanoidRootPart.CFrame * CFrame.new(5, 2, 50) * CFrame.Angles(math.rad(-2), 0, 0)
            PitchingUI.Thingy.Visible = true
            Camera_ZoomIn:Play()
            Animations.Idle:Play(.5)

            Camera_ZoomIn.Completed:Wait()

            Connections.InputListener = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
                if not GameProcessed then
                    local KeyCode = Input.KeyCode
                    if KeyCode == Enum.KeyCode.E then
                        Disengage(Humanoid)
                    else
                        for code,_ in next, Keycodes do
                            if KeyCode == code then
                                CurrentPitchSelected = Keycodes[code]
                                PitchingUI.Main.CurrentPitch.Text = '<b>Current Pitch</b>: ' .. Keycodes[code]
                                break
                            end
                        end
                    end
                end
            end)

            Connections.ButtonListener = PitchingUI.Thingy.MouseButton1Click:Connect(function()
                Disengage(Humanoid)
            end)

            Connections.MouseListener = Mouse.Button1Down:Connect(function()
                if Pitching then return end
                if CurrentPitchSelected == nil then return end
                if not Mouse.Target:FindFirstAncestor('Batting') then return end
                Pitching = true
                Connections.InputListener:Disconnect()
                Connections.InputListener = nil
                PitcherEvent:FireServer('ThrowPitch', CurrentPitchSelected, Mouse.Hit, 1.38)
                Animations.Throwing:Play()
                Animations.Idle:Stop()
                Main_Close:Play()
                Animations.Throwing.Ended:Wait()
                Disengage(Humanoid)
            end)
        end
    end
end)