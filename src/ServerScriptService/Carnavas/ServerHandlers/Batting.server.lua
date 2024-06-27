-- // Services \\ --
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerService = game:GetService('Players')

-- // Variables \\ --
local BatterEvent = ReplicatedStorage.Carnavas.Events.BatterEvent
local BatterPosition = game.Workspace:FindFirstChild('BatterPosition', true)
local BallsFolder = game.Workspace:WaitForChild('Balls', 10)
local Count = ReplicatedStorage.Carnavas.Count

local Balls = Count.Balls
local Strikes = Count.Strikes

_G.BatterOn = {false, nil}
local Debounce = {false, 1}

-- Gaussian function (idk what that is lol)
function GetLaunchAngleVelocity(LaunchAngle: number)
    local a = _G.Configs.MaxPower -- Maximum velocity
    local b = 30 -- Angle for maximum velocity
    local c = 15 -- Controls the width of the 'bell'
    local Velocity = a * math.exp(-(LaunchAngle - b)^2 / (2*c^2))
    return Velocity
end

-- local function GetVelocityMultiplier(RelativeY: number)
--     return 1 / (RelativeY^3 + .7)
-- end

BatterPosition.ProximityPrompt.Triggered:Connect(function(Player)
    if _G.BatterOn[1] == false then
        local Character = Player.Character
        if not Character then return end
        if Character.Humanoid.Health <= 0 then return end
        local Bat = ReplicatedStorage.Carnavas.Instances.Bat:Clone()
        local Weld = Instance.new('Weld', Bat.Bat)
        Weld.Part0 = Character.LeftHand
        Weld.Part1 = Bat.Bat
        Bat.Parent = Character.LeftHand

        task.spawn(function()
            for _,v in next, Character:GetDescendants() do
                if v:IsA('BasePart') then
                    if v.Name == 'FieldingHitbox' then
                        v:Destroy()
                    end
                    if v.CanQuery == true then
                        v.CanQuery = false
                    end
                end
            end
        end)

        Weld.C0 = CFrame.new(-0, -0.15, -1.75) * CFrame.Angles(math.rad(-90), 0, 0)
        BatterEvent:FireClient(Player, 'BeginBatting')
        Character.HumanoidRootPart.CFrame = BatterPosition.CFrame
        Character.HumanoidRootPart.Anchored = true
        BatterPosition.ProximityPrompt.Enabled = false
        _G.BatterOn = {true, Player.UserId}
    end
end)

BatterEvent.OnServerEvent:Connect(function(Player, Action, ...)
    if Player.UserId ~= _G.BatterOn[2] then Player:Kick('Don\'t try to exploit please that hurts my feelings :(') return end

    local Args = {...}
    if Action == 'SwingAtBall' then
        local StrikeZone = game.Workspace:FindFirstChild('StrikeZone', true)
        local Angle        = Args[1]
        local BallPosition = Args[2]
        local LaunchAngle  = Args[3]
        local RelativeY    = Args[4]
        local HitBall      = Args[5]
        local SoundPart = Instance.new('Part')
        
        if HitBall then
            local NewLookVector = (StrikeZone.CFrame * CFrame.Angles(math.rad(LaunchAngle), math.rad(Angle), 0)).LookVector
            local Velo = GetLaunchAngleVelocity(LaunchAngle)
            if Velo < 0 then Velo *= -1 end

            SoundPart.Transparency = 1
            SoundPart.CanCollide = false
            SoundPart.CanQuery = false
            SoundPart.CanTouch = false
            SoundPart.Anchored = true
            SoundPart.Parent = game.Workspace
            SoundPart.Position = BallPosition
            
            BatterEvent:FireAllClients('DeletePitchedBalls')

            task.spawn(function()
                for _,v in next, BallsFolder:GetChildren() do
                    if v.Name == "PitchedBall" then
                        v:Destroy()
                    end
                end
            end)

            if _G.Configs.PlayPowerHit then
                if Velo < 95 then -- Not so powerful hit
                    local Sound = ReplicatedStorage.Carnavas.Sounds.Bat.BatHit:Clone()
                    Sound.Parent = SoundPart
                    Sound:Play()
                    task.delay(Sound.TimeLength, function()
                        SoundPart:Destroy()
                    end)
                else-- powerful ahh it
                    local Sound = ReplicatedStorage.Carnavas.Sounds.Bat.BatHit_Power:Clone()
                    Sound.Parent = SoundPart
                    Sound:Play()
                    task.delay(Sound.TimeLength, function()
                        SoundPart:Destroy()
                    end)
                end
            elseif not _G.Configs.PlayPowerHit then
                local Sound = ReplicatedStorage.Carnavas.Sounds.Bat.BatHit:Clone()
                Sound.Parent = SoundPart
                Sound:Play()
                print(Sound.TimeLength)
                game:GetService('Debris'):AddItem(SoundPart, Sound.TimeLength)
                task.delay(Sound.TimeLength, function()
                    SoundPart:Destroy()
                end)
            end        
            local FinalVelo = Velo
            local FinalDrop = _G.Configs.BallDrop

            if not _G.Configs.UseRawPower then
                local Math = FinalVelo / _G.Configs.DividePowerBy
                FinalVelo = math.clamp(Math, _G.Configs.MinPower, _G.Configs.MaxPower)
                FinalDrop /= (_G.Configs.DividePowerBy * _G.Configs.DividePowerBy)
            end
        
            print(`Hit Stats:\nLaunch Angle: {LaunchAngle}\nHit Velocity: {FinalVelo}`)

            local HitBall = _G.BallHandler:CastTheGyattDamnBall(BallPosition, NewLookVector * 2500, FinalVelo, Vector3.new(0, FinalDrop, 0), Player.Character, false, false, tostring(Player.UserId)) -- old drop value: -49.05
            HitBall.Name = 'HitBall'
        else
            
        end


    elseif Action == 'StepOutBattersBox' then
        if Player.Character then
            local Bat = Player.Character:FindFirstChild('Bat', true)
            Bat:Destroy()

            Player.Character.HumanoidRootPart.Anchored = false

            if Player.Team:GetAttribute('Fielding') == true then
                _G.GiveFieldingHitbox(Player)
            end

            for _,v in next, Player.Character:GetDescendants() do
                if v:IsA('BasePart') and not v.Parent:IsA('Accessory') then
                    if v.CanQuery == false then
                        v.CanQuery = true
                    end
                end
            end
            _G.BatterOn = {false, nil}
            task.wait(2)
            BatterPosition.ProximityPrompt.Enabled = true
        end
    end
end)

PlayerService.PlayerRemoving:Connect(function(Player)
    if _G.BatterOn[1] then
        if Player.UserId == _G.BatterOn[2] then
            _G.BatterOn = {false, nil}
            task.wait(2)
            BatterPosition.ProximityPrompt.Enabled = true
        end
    end
end)