-- // Services \\ --
local PlayerService = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeamService = game:GetService('Teams')

-- // Variables \\ --
local PitcherEvent = ReplicatedStorage.Carnavas.Events.PitcherEvent
local BallsFolder = game.Workspace:WaitForChild('Balls', 10)
local Rubber = game.Workspace:FindFirstChild('RubberPitch', true)

local PitchCounts = {}

_G.PitcherOn = {false, nil}
local Cooldown = false

local PitchOffsets = ReplicatedStorage.Carnavas.PitchOffsets
local PitchSpeeds = ReplicatedStorage.Carnavas.PitchSpeeds
local PitchDrops = ReplicatedStorage.Carnavas.PitchDrops

local function CountPitch(UserID)
    local PitchCount = PitchCounts[UserID]
    if PitchCount then
        PitchCounts[UserID] += 1
    else
        PitchCounts[UserID] = 1
    end
end

--Stadium.ReflectWall:Destroy()

PlayerService.PlayerAdded:Connect(function(Player)
    Player.CharacterAdded:Connect(function(Character)
        task.wait(.05)
        local RightHand = Character:FindFirstChild('RightHand')
        if RightHand then
            local FakeBall = ReplicatedStorage.Carnavas.Balls.FakeBall:Clone()
            local Weld = Instance.new('Weld', FakeBall)
            FakeBall.Parent = RightHand
            FakeBall.Transparency = 1
            Weld.Part0 = RightHand
            Weld.Part1 = FakeBall
            
            Weld.C0 = CFrame.new(-0.32, -0.165, -0) * CFrame.Angles(0, -0.023, 0)
        end
    end)
end)

Rubber.Touched:Connect(function(BasePart)
    if _G.PitcherOn[1] or Cooldown then return end
    if BasePart.Name == "FieldingHitbox" then return end
    local Character = BasePart.Parent
    local Humanoid = Character:FindFirstChildOfClass('Humanoid')
    
    if Humanoid then
        local Player = PlayerService:GetPlayerFromCharacter(Character)
        if not Player then return end
        if not table.find(_G.Configs.Whitelist_Teams, Player.Team.Name) then print(Player.Name .. 'attempted to pitch without being on a whitelisted team.') return end
        if Character.Humanoid.Health <= 0 then return end
        if (Character.HumanoidRootPart.Position - Rubber.Position).Magnitude >= 6 then print("too far") return end
        
        for _,team in next, TeamService:GetTeams() do
            if team ~= Player.Team then
                team:SetAttribute('Fielding', false)
            end
        end

        for _,v in next, BallsFolder:GetChildren() do
            v:Destroy()
        end
        
        if Player.Team:GetAttribute('Fielding') == false then
            Player.Team:SetAttribute('Fielding', true)
        end
        
        PitcherEvent:FireClient(Player, 'BeginPitching')
        Character.HumanoidRootPart.CFrame = Rubber.CFrame * CFrame.new(0, 3, 0)
        Character.HumanoidRootPart.Anchored = true
        _G.PitcherOn = {true, Player.UserId}
    end
end)

PitcherEvent.OnServerEvent:Connect(function(Player, Action, ...)
    if Player.UserId ~= _G.PitcherOn[2] then Player:Kick('Don\'t try to exploit please that hurts my feelings :(') return end
    local Args = {...}
    if Action == 'ThrowPitch' then
        local FakeBall = Player.Character.RightHand.FakeBall
        local PitchType = Args[1]
        local EndCFrame = Args[2]
        
        FakeBall.Transparency = 0
        task.wait(Args[3])
        local StartPos = FakeBall.Position
        FakeBall.Transparency = 1
        
            -- // Curveball
        if PitchType == 'CU' then
            local endCFrame = EndCFrame * CFrame.new(PitchOffsets:GetAttribute(PitchType))
            local PitchSpeed = PitchSpeeds:GetAttribute(PitchType)
            local PitchDrop = PitchDrops:GetAttribute(PitchType)
            local EndPosition = Vector3.new(endCFrame.X, endCFrame.Y, endCFrame.Z)
            
            _G.BallHandler:CastTheGyattDamnBall(StartPos, EndPosition, PitchSpeed, PitchDrop, Player.Character, true, true, tostring(Player.UserId))
            
            -- // Fastball
        elseif PitchType == '4SFB' then
            local endCFrame = EndCFrame * CFrame.new(PitchOffsets:GetAttribute(PitchType))
            local PitchSpeed = PitchSpeeds:GetAttribute(PitchType)
            local PitchDrop = PitchDrops:GetAttribute(PitchType)
            local EndPosition = Vector3.new(endCFrame.X, endCFrame.Y, endCFrame.Z)
            
            local NewBall = _G.BallHandler:CastTheGyattDamnBall(StartPos, EndPosition, PitchSpeed, PitchDrop, Player.Character, true, true, tostring(Player.UserId))
            
            -- // Slider
        elseif PitchType == 'SL' then
            local endCFrame = EndCFrame * CFrame.new(PitchOffsets:GetAttribute(PitchType))
            local PitchSpeed = PitchSpeeds:GetAttribute(PitchType)
            local PitchDrop = PitchDrops:GetAttribute(PitchType)
            local EndPosition = Vector3.new(endCFrame.X, endCFrame.Y, endCFrame.Z)

            local NewBall = _G.BallHandler:CastTheGyattDamnBall(StartPos, EndPosition, PitchSpeed, PitchDrop, Player.Character, true, true, tostring(Player.UserId))
        end
        if _G.BatterOn[1] == true then
            CountPitch(Player.UserId)
        end
        
    elseif Action == 'Disengage' then
        local Character = Player.Character
        if Character then
            if Character:FindFirstChild('HumanoidRootPart') then
                Character.HumanoidRootPart.Anchored = false
            end
        end
        _G.PitcherOn = {false, nil}
        Cooldown = true
        task.wait(5)
        Cooldown = false
    end
end)

PlayerService.PlayerRemoving:Connect(function(Player)
    if _G.PitcherOn[1] then
        if Player.UserId == _G.PitcherOn[2] then
            _G.PitcherOn = {false, nil}
        end
    end
end)