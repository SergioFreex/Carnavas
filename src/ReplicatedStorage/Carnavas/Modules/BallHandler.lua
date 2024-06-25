-- // Services \\ --
local PlayerService = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local DebrisService = game:GetService('Debris')

-- // Variables \\ --
local FastCast = require(ReplicatedStorage.Carnavas.Modules.FastCastRedux)
local CountHandler

if RunService:IsServer() then
    CountHandler = require(game:GetService("ServerScriptService").Carnavas.Modules.Count)

    ReplicatedStorage.Carnavas.ClientVisuals.Value = _G.Configs.RenderBallOnClient
end

local BallEvent = ReplicatedStorage.Carnavas.Events.BallEvent
local RemoteFunction = ReplicatedStorage.Carnavas.Events.RF
local BallsFolder = game.Workspace:WaitForChild('Balls', 10)

local GloveSounds = ReplicatedStorage.Carnavas.Sounds.Glove

local ClientCasters = {}
local ServerCasters = {}

local module = {}

local function StrikeZone_PierceFunction(Raycast, Result, SegmentVelocity)
    local instance = Result.Instance
    
    if instance:FindFirstAncestor('Batting') then
        if instance.Name == "StrikeZone" then
            local BallPos = Result.Position
            local fakeBall = ReplicatedStorage.Carnavas.Balls.Baseball:Clone()
            fakeBall.Name = 'SZ_Ball'
            fakeBall.Anchored = true
            fakeBall.Parent = BallsFolder
            fakeBall.Position = BallPos
            fakeBall.Transparency = 1
            fakeBall.Highlight.Enabled = false
            DebrisService:AddItem(fakeBall, 4)
            if RunService:IsServer() then
                local CountHandler = require(game.ServerScriptService.Carnavas.Modules.Count)
                local Highlight = fakeBall.StrikeZoneHighlight
                fakeBall.Transparency = 0
                Highlight.FillTransparency = 0
                CountHandler.HandleCount(true)
                Highlight.Enabled = true
            end
        elseif instance.Parent.Name == "StrikeZone" then
            local BallPos = Result.Position
            local fakeBall = ReplicatedStorage.Carnavas.Balls.Baseball:Clone()
            fakeBall.Name = 'SZ_Ball'
            fakeBall.Anchored = true
            fakeBall.Parent = BallsFolder
            fakeBall.Position = BallPos
            fakeBall.Transparency = 1
            fakeBall.Highlight.Enabled = false

            fakeBall.CanCollide = false
            fakeBall.CanQuery = false
            fakeBall.CanTouch = false

            DebrisService:AddItem(fakeBall, 4)
            if RunService:IsServer() then
                local CountHandler = require(game.ServerScriptService.Carnavas.Modules.Count)
                local Highlight = fakeBall.StrikeZoneHighlight
                fakeBall.Transparency = 0
                Highlight.FillTransparency = 1
                CountHandler.HandleCount(false)
                Highlight.Enabled = true
            end
        end
        return true
    end

    if RunService:IsServer() then
        local CountHandler = require(game.ServerScriptService.Carnavas.Modules.Count)
        CountHandler.HandleCount(false)
    end

    return false
end

local function CreateCaster(CastID)
    if RunService:IsClient() then
        local Caster = FastCast.new()
        --local Behavior = FastCast.newBehavior()

        ClientCasters[tostring(CastID)] = {Caster}
    elseif RunService:IsServer() then
        local Caster = FastCast.new()
        --local Behavior = FastCast.newBehavior()

        ServerCasters[tostring(CastID)] = {Caster}
    end
end

if RunService:IsClient() then
    for _,plr in next, PlayerService:GetPlayers() do
        if ClientCasters[tostring(plr.UserId)] == nil then
            CreateCaster(tostring(plr.UserId))
        end
    end
    
    if ClientCasters['Server'] == nil then
        CreateCaster('Server')
    end

    PlayerService.PlayerAdded:Connect(function(Plr)
        if Plr ~= PlayerService.LocalPlayer then
            local FindPreviousCaster = ClientCasters[tostring(Plr.UserId)]
            if not FindPreviousCaster then
                CreateCaster(tostring(Plr.UserId))
            end
        end
    end)
elseif RunService:IsServer() then
    CreateCaster('Server')

    RemoteFunction.OnServerInvoke = function(Plr, Function, ...)
        local Args = {...}
        if Function == 'GetCasters' then
            return ServerCasters
        end
    end
end

local function CaughtByPlayer(instance)
    local Player = false
    if instance.Parent then
        if instance.Parent:FindFirstChildOfClass('Humanoid') then
            if PlayerService:GetPlayerFromCharacter(instance.Parent) then
                return PlayerService:GetPlayerFromCharacter(instance.Parent)
            end
        end
        if instance:FindFirstAncestorOfClass('Model') then
            local Parent = instance:FindFirstAncestorOfClass('Model')
            if Parent:FindFirstChildOfClass('Humanoid') then
                if PlayerService:GetPlayerFromCharacter(Parent) then
                    return PlayerService:GetPlayerFromCharacter(Parent)
                end
            end
        end
    end
    return nil
end

local function CreateIgnoreList(Receive)
    local IgnoreList = {BallsFolder}

    for _,v in next, Receive do
        table.insert(IgnoreList, v)
    end

    for _,team in next, game.Teams:GetTeams() do
        if not team:GetAttribute('Fielding') then
            for _,plr in next, PlayerService:GetPlayers() do
                if plr.Team == team then
                    if plr.Character then
                        table.insert(IgnoreList, plr.Character)
                    end
                end
            end
            break
        end
    end
    return IgnoreList
end

local function GetCaster(CasterID)
    if RunService:IsServer() then
        for key,cast in next, ServerCasters do
            if tostring(key) == tostring(CasterID) then
                return ServerCasters[tostring(key)]
            end
        end
    elseif RunService:IsClient() then
        for key,cast in next, ClientCasters do
            if tostring(key) == tostring(CasterID) then
                return ClientCasters[tostring(key)]
            end
        end
    end
    return nil
end

function module:CastTheGyattDamnBall(...)
    local Args = {...}
    local StartPosition = Args[1]
    local EndPosition = Args[2]
    local Speed = Args[3]
    local Drop = Args[4]
    local Playa = Args[5]
    local DeleteOnTouch = Args[6]
    local PitchingBall = Args[7]
    local CasterName = Args[8]

    local RayHitConnection = nil
    local LengthChangedConnection = nil

    if not GetCaster(CasterName) then print('couldn\'t find caster.') return end
    if RunService:IsServer() then
        BallEvent:FireAllClients(...)
    end

    -- // Fastcast Things
    local CasterInfo = GetCaster(CasterName)
    local Caster = CasterInfo[1]
    local Behavior = FastCast.newBehavior()
    local Direction = (EndPosition - StartPosition).Unit
    local raycastParams = RaycastParams.new()

    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local InitialBall
    if not PitchingBall then
        local Send = {Playa, game.Workspace.Carnavas.Batting}
        raycastParams.FilterDescendantsInstances = CreateIgnoreList(Send)
        InitialBall = ReplicatedStorage.Carnavas.Balls.Baseball:Clone()
    else
        local Send = {Playa}
        Behavior.CanPierceFunction = StrikeZone_PierceFunction
        raycastParams.FilterDescendantsInstances = CreateIgnoreList(Send)
        InitialBall = ReplicatedStorage.Carnavas.Balls.PitchedBall:Clone()
    end

    Behavior.RaycastParams = raycastParams
    Behavior.Acceleration = Drop
    Behavior.MaxDistance = math.huge

    CasterInfo[1]:Fire(StartPosition, Direction, Speed, Behavior)

    if RunService:IsServer() then
        if ReplicatedStorage.Carnavas.ClientVisuals.Value == true then
            InitialBall.Parent = game.ServerStorage
        else
            InitialBall.Parent = BallsFolder
            InitialBall.Position = StartPosition
            LengthChangedConnection = CasterInfo[1].LengthChanged:Connect(function(Cast, LastPoint, Dir, Length)
                local HalfSize = InitialBall.Size.Z / 2
                local Offset = CFrame.new(0, 0, -(Length - HalfSize))
                InitialBall.CFrame = CFrame.lookAt(LastPoint, LastPoint+Dir):ToWorldSpace(Offset)
            end)
        end
    elseif RunService:IsClient() then
        InitialBall.Parent = BallsFolder
        InitialBall.Position = StartPosition
        LengthChangedConnection = CasterInfo[1].LengthChanged:Connect(function(Cast, LastPoint, Dir, Length)
            local HalfSize = InitialBall.Size.Z / 2
            local Offset = CFrame.new(0, 0, -(Length - HalfSize))
            InitialBall.CFrame = CFrame.lookAt(LastPoint, LastPoint+Dir):ToWorldSpace(Offset)
        end)
    end

    RayHitConnection = CasterInfo[1].RayHit:Connect(function(Cast, Results)
        if RunService:IsServer() then
            if not DeleteOnTouch then
                if Results then
                    local Plr = CaughtByPlayer(Results.Instance)
                    if not Plr then
                        local IsActive = true
                        local Connection
                        local NewBall = ReplicatedStorage.Carnavas.Balls.Baseball:Clone()
                        local NewHitbox = Instance.new('Part')
                        -- local Weld = Instance.new('Weld', NewHitbox)
                        local a = Instance.new('Attachment')
                        local ap = Instance.new('AlignPosition')
                        InitialBall:Destroy()

                        NewBall.Position = Results.Position
                        NewBall.Massless = true
                        NewBall.Anchored = false
                        NewBall.CanCollide = true
                        NewBall.CanQuery = true
                        NewBall.CanTouch = false
                        NewBall.Parent = BallsFolder

                        local Distance = (StartPosition - Results.Position).Magnitude

                        if Distance >= 220 then
                            NewBall:ApplyImpulse((Vector3.new(Direction.X, math.rad(15), Direction.Z)) * (Speed / 35))
                        else
                            NewBall:ApplyImpulse((Vector3.new(Direction.X, math.rad(15), Direction.Z)) * (Speed / 15))
                        end
                        

                        NewHitbox.Size = Vector3.new(_G.Configs.BallHitboxSize, _G.Configs.BallHitboxSize, _G.Configs.BallHitboxSize)
                        NewHitbox.Transparency = 1
                        NewHitbox.Massless = true
                        NewHitbox.Position = Results.Position
                        NewHitbox.Anchored = false
                        NewHitbox.CanCollide = false
                        NewHitbox.CanQuery = false
                        NewHitbox.CanTouch = true

                        a.Parent = NewHitbox
                        ap.Parent = NewHitbox
                        ap.Attachment0 = a
                        ap.Attachment1 = NewBall.Attachment0

                        ap.MaxForce = math.huge
                        ap.Responsiveness = math.huge

                        NewHitbox.Parent = NewBall

                        task.spawn(function()
                            if InitialBall.Name == 'HitBall' then
                                if _G.Configs.UseRawPower then
                                    task.wait(Speed / 100)
                                else
                                    local actualSpeed = Speed * _G.Configs.DividePowerBy
                                    task.wait(actualSpeed / 100)
                                end
                            else
                                task.wait(Speed / 140)
                            end
                            task.delay(4, function()
                                IsActive = false
                            end)
                            repeat
                                NewBall.AssemblyLinearVelocity = 0.6 * NewBall.AssemblyLinearVelocity
                                NewBall.AssemblyAngularVelocity = 0.6 * NewBall.AssemblyAngularVelocity

                                task.wait(.3)
                            until not IsActive
                        end)

                        if not NewBall or not NewBall.Parent then return end

                        local KeepListening = true
                        Connection = NewHitbox.Touched:Connect(function(BasePart)
                            local Plr_1 = CaughtByPlayer(BasePart)
                            if Plr_1 then
                                if Plr_1:GetAttribute('Fielding') == false and Plr_1.Team:GetAttribute('Fielding') == true and Plr_1 ~= Playa then
                                    local Character = Plr_1.Character
                                    if not Character then return end
                                    local Humanoid = Character:FindFirstChildOfClass('Humanoid')
                                    if Humanoid.Health > 0 then
                                        KeepListening = false
                                        NewBall:Destroy()
                                        ReplicatedStorage.Carnavas.Events.FieldingEvent:FireClient(Plr_1, 'BeginFielding')
                                        if Character:FindFirstChild('FakeBall', true) then
                                            local FakeBall = Character:FindFirstChild('FakeBall', true)
                                            local GloveFielded_Sound = GloveSounds.Fielded:Clone()
                                            FakeBall.BallHighlight.Enabled = true
                                            FakeBall.Transparency = 0
                                            GloveFielded_Sound.Parent = FakeBall
                                            GloveFielded_Sound:Play()
                                            DebrisService:AddItem(GloveFielded_Sound, GloveFielded_Sound.TimeLength)
                                        end
                                        Plr_1:SetAttribute('Fielding', true)
                                        Connection:Disconnect()
                                    end
                                end
                            end
                        end)

                        if _G.Configs.AutoDeleteBalls then
                            DebrisService:AddItem(NewBall, _G.Configs.DeleteBallsDuration)
                        end
                    else
                        if Plr:GetAttribute('Fielding') == false and Plr.Team:GetAttribute('Fielding') == true then
                            local Character = Plr.Character
                            if not Character then return end
                            local Humanoid = Character:FindFirstChildOfClass('Humanoid')
                            if Humanoid.Health > 0 then
                                local CaughtBillboard = ReplicatedStorage.Carnavas.Instances.CaughtBillboard:Clone()
                                InitialBall:Destroy()
                                ReplicatedStorage.Carnavas.Events.FieldingEvent:FireClient(Plr, 'BeginFielding')
                                if Character:FindFirstChild('FakeBall', true) then
                                    local FakeBall = Character:FindFirstChild('FakeBall', true)
                                    local GloveCaught_Sound = GloveSounds.Caught:Clone()
                                    FakeBall.BallHighlight.Enabled = true
                                    CaughtBillboard.Parent = FakeBall
                                    FakeBall.Transparency = 0
                                    GloveCaught_Sound.Parent = FakeBall
                                    GloveCaught_Sound:Play()
                                    DebrisService:AddItem(GloveCaught_Sound, GloveCaught_Sound.TimeLength)
                                    DebrisService:AddItem(CaughtBillboard, 5)
                                end
                                Plr:SetAttribute('Fielding', true)
                            end
                        end
                    end
                end
            else
                InitialBall:Destroy()
            end
        elseif RunService:IsClient() then
            InitialBall:Destroy()
        end
    end)

    task.spawn(function()
        CasterInfo[1].RayHit:Wait()
        
        if RunService:IsClient() or ReplicatedStorage.Carnavas.ClientVisuals.Value == false then LengthChangedConnection:Disconnect() end
        RayHitConnection:Disconnect()
    end)

    return InitialBall
end

if RunService:IsClient() then
    BallEvent.OnClientEvent:Connect(function(...)
        if ReplicatedStorage.Carnavas.ClientVisuals.Value == true then
            module:CastTheGyattDamnBall(...)
        end
    end)
end

PlayerService.PlayerAdded:Connect(function(Plr)
    if RunService:IsServer() then
        local FindPreviousCaster = ServerCasters[tostring(Plr.UserId)]
        if not FindPreviousCaster then
            ServerCasters[tostring(Plr.UserId)] = {FastCast.new(), FastCast.newBehavior()}
        end
    end
end)

return module