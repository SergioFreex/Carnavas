repeat task.wait() until game:IsLoaded()

-- // Services \\ --
local PlayerService = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local DebrisService = game:GetService('Debris')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local StarterPlayer = game:GetService('StarterPlayer')
local ContentProvider = game:GetService('ContentProvider')

-- // Variables \\ --
local LocalPlayer: Player = PlayerService.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local StrikeZone = game.Workspace.Carnavas.Batting:WaitForChild('StrikeZone', 10)
local Camera = game.Workspace.CurrentCamera
local BatterEvent = ReplicatedStorage.Carnavas.Events.BatterEvent
local CountBindEvent = ReplicatedStorage.Carnavas.Events.CountBindEvent
local CountEvent = ReplicatedStorage.Carnavas.Events.CountEvent

local BattingUI = LocalPlayer.PlayerGui:WaitForChild('Carnavas', 10).Batting
local BallsFolder: Folder = game.Workspace:WaitForChild('Balls', 10)

local Batting = false
local SwungAtPreviousPitch = {false, false} -- SwungAtPrevious, Contact

local Connections = {}

local PreviousCameraCFrame = nil

local ballrayParams = RaycastParams.new()

ballrayParams.FilterDescendantsInstances = {game.Workspace:WaitForChild('Carnavas', 10):WaitForChild('Batting', 10)}
ballrayParams.FilterType = Enum.RaycastFilterType.Include

-- // Tweening \\ --
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local Camera_ZoomIn = TweenService:Create(Camera, tweenInfo, {FieldOfView = 50})
local Camera_ZoomOut = TweenService:Create(Camera, tweenInfo, {FieldOfView = 80})

-- // Animations \\ --
local AnimationsFolder = ReplicatedStorage.Carnavas.Animations.BattingAnimations
local I = AnimationsFolder.Idle
local L = AnimationsFolder.Load
local S = AnimationsFolder.Swing

if LocalPlayer.UserId == 148749705 then I = AnimationsFolder:WaitForChild('Woated', 10) end

ContentProvider:PreloadAsync({I.AnimationId, L.AnimationId, S.AnimationId})

local Animations = {
    Idle = nil,
    Load = nil,
    Swing = nil
}

local function StepOut()
    local Humanoid = LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
    Batting = false
    Animations.Idle:Stop(.4)
    Animations.Load:Stop(.4)
    task.delay(.3, function()
        Animations.Swing:Stop(.4)
    end)
    Camera_ZoomOut:Play()
    Camera.CFrame = PreviousCameraCFrame
    Camera.CameraType = Enum.CameraType.Custom

    if Humanoid and Humanoid:FindFirstChildOfClass('Animator') then
        local Animator = Humanoid.Animator
        Humanoid.AutoRotate = true
    end

    Mouse.TargetFilter = nil
    UserInputService.MouseIconEnabled = true
    BattingUI.Visible = false

    BatterEvent:FireServer('StepOutBattersBox')
    PreviousCameraCFrame = nil

    for key,_ in next, Connections do
        Connections[key]:Disconnect()
    end
end

-- if you see this, i (s_ilversun) am a femboy and i love wearing skirts, thigh highs, and tights :3

local function CalculateLaunchAngle(RelativeY: number, HalfSize: number)
    if RelativeY > 0 then
        return 45 + 50 * (RelativeY / HalfSize)
    else
        return 20 - 30 * ((RelativeY * -1) / HalfSize)
    end
end


local function HitBall(RelativeY, AngleTowards, HalfSize, BallPosition)
    local LaunchAngle = CalculateLaunchAngle(RelativeY, HalfSize)
    -- local LaunchAngle = (RelativeY / HalfSize) * -80


    -- local LaunchAngle = math.clamp((math.round((RelativeY) * 100)) * -1, -15, 250)
    -- print('Launch Angle: '.. LaunchAngle)
    -- print('Relative Y: ' .. RelativeY)
    -- print('Relative X: ' .. Relative.X)

    print(`Client Hit Stats:\nRelative Y: {RelativeY}\nLaunch Angle: {LaunchAngle}`)
    SwungAtPreviousPitch = {true, true}
    BatterEvent:FireServer('SwingAtBall', AngleTowards, BallPosition, LaunchAngle, RelativeY, true)
    task.delay(.5, function()
        StepOut()
    end)
end

UserInputService.InputChanged:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.Touch then
        BattingUI.Thingy.Text = 'Tap here to step out of the box.'
        BattingUI.BattingReticle.Visible = false
    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
        BattingUI.Thingy.Text = 'Press E to step out of the box.'
        BattingUI.BattingReticle.Visible = true
    end
end)

BattingUI.Thingy.MouseButton1Click:Connect(function()
    StepOut()
end)

BatterEvent.OnClientEvent:Connect(function(Action, ...)
    if Action == 'BeginBatting' then
        if LocalPlayer.Character then
            local Humanoid = LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
            Batting = true

            if Humanoid and Humanoid:FindFirstChildOfClass('Animator') then
                local Animator = Humanoid.Animator
                Humanoid.AutoRotate = false
                Animations.Idle = Animator:LoadAnimation(I)
                Animations.Load = Animator:LoadAnimation(L)
                Animations.Swing = Animator:LoadAnimation(S)
            end

            PreviousCameraCFrame = Camera.CFrame

            Camera.CameraType = Enum.CameraType.Scriptable
            if StrikeZone:IsA('Model') then
                local ActualPart = StrikeZone:FindFirstChild('StrikeZone')
                if StrikeZone then
                    Camera.CFrame = ActualPart.CFrame * CFrame.new(0, 0, 9) -- old y value was 1.2
                end
            else
                Camera.CFrame = StrikeZone.CFrame * CFrame.new(0, 0, 9) -- old y value was 1.2
            end
            Camera_ZoomIn:Play()
            Animations.Idle:Play(.5)
            Mouse.TargetFilter = game.Workspace.Carnavas.Batting

            Connections.ChildAddedConnection = BallsFolder.ChildAdded:Connect(function(Child)
                if Child.Name == 'PitchedBall' then
                    Animations.Load:Play(.65)
                end
            end)

            BattingUI.Visible = true
            UserInputService.MouseIconEnabled = false
            Connections.Connection2 = RunService.RenderStepped:Connect(function(Delta)
                local Reticle = BattingUI.BattingReticle

                Reticle.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
            end)

            Connections.Connection3 = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
                if not GameProcessed then
                    if Input.KeyCode == Enum.KeyCode.E then
                        if not Animations.Load.IsPlaying then
                            StepOut()
                        end
                    end
                end
            end)

            Connections.Connection = Mouse.Button1Down:Connect(function()
                if not Animations.Load.IsPlaying then return end
                -- SwungAtPreviousPitch = {true, false}
                if not Animations.Swing.IsPlaying then
                    Animations.Swing:Play()
                    task.wait(.1) -- offset
                    local Target = Mouse.Target
                    if Target then
                        if Target.Name == 'PitchedBall' then
                            -- // Strikezone Things
                            local cframeSpot = StrikeZone.CFrame * CFrame.new(0, -.5, 0)
                            local SweetSpot = Vector3.new(cframeSpot.X, cframeSpot.Y, cframeSpot.Z)
                            local MaxDistanceZ, MaxDistanceY = (StrikeZone.Size.X / 2) + .5, (StrikeZone.Size.Y / 2) + 1

                            -- // Swing stuff
                            local HalfSize = Target.Size.X / 2
                            local BallPosition = Target.Position
                            local HitPosition = Mouse.Hit.Position
                            local Relative = Target.CFrame:PointToObjectSpace(HitPosition)
                            local Distance = (math.round((SweetSpot - Target.Position).Magnitude * 100) / 100)
                            local Point1, Point2 = (cframeSpot + cframeSpot.LookVector), (cframeSpot + cframeSpot.LookVector * -1)
                            local Magnitude1, Magnitude2 = (Point1.Position - BallPosition).Magnitude, (Point2.Position - BallPosition).Magnitude
                            local Southernplayalisticadillacmuzik = Relative.Y * -1

                            local BALL_POSITION = Vector3.new(0, BallPosition.Y, BallPosition.Z)
                            local ZONE_POSITION = Vector3.new(0, StrikeZone.Position.Y, StrikeZone.Position.Z)
                            local DistanceFromStrikeZone = (BALL_POSITION - ZONE_POSITION)
                            local DistanceZ, DistanceY = DistanceFromStrikeZone.Z, DistanceFromStrikeZone.Y
                            if DistanceZ < 0 then DistanceZ *= -1 end
                            if DistanceY < 0 then DistanceY *= -1 end

                            if DistanceZ <= MaxDistanceZ and DistanceY <= MaxDistanceY then
                                if not (Magnitude1 <= Magnitude2) then -- If the ball is behind the sweetspot then
                                    --print('Behind Sweetspot')
                                    if Distance > 5 then
                                        print('Swing and a miss, bud! (too late)')
                                        SwungAtPreviousPitch = {true, false}
                                        task.wait(1)
                                        Animations.Swing:Stop(.5)
                                    else
                                        local AngleTowards = (Distance / 5) * -90
                                        HitBall(Southernplayalisticadillacmuzik, AngleTowards, HalfSize, BallPosition)
                                    end
                                else                                   -- If the ball is in front of the sweetspot then
                                    --print('Front of Sweetspot')
                                    if Distance > 8 then
                                        print('Swing and a miss, bud! (too early)')
                                        SwungAtPreviousPitch = {true, false}
                                        task.wait(1)
                                        Animations.Swing:Stop(.5)
                                    else
                                        local AngleTowards = (Distance / 8) * 90
                                        HitBall(Southernplayalisticadillacmuzik, AngleTowards, HalfSize, BallPosition)
                                    end
                                end
                            else
                                print('Swing and a miss, bud! (ball out of hitting zone)')
                            end
                        else
                            print('Swing and a miss, bud! (you missed)')
                            SwungAtPreviousPitch = {true, false}
                            task.wait(1)
                            Animations.Swing:Stop(.5)
                        end
                    end
                end
            end)
        end
    elseif Action == 'DeletePitchedBalls' then
        for _,v in next, BallsFolder:GetChildren() do
            if v.Name == 'PitchedBall' then
                v:Destroy()
            end
        end
    end
end)

CountBindEvent.Event:Connect(function(Strike: boolean)
    if Batting then
        task.wait(.5)
        if SwungAtPreviousPitch[1] then
            local ContactMade = SwungAtPreviousPitch[2]
            if not ContactMade then
                CountEvent:FireServer(true)
            end
        else
            if not Strike then
                CountEvent:FireServer(false)
            else
                CountEvent:FireServer(true)
            end
        end
        SwungAtPreviousPitch = {false, false}
    end
end)